BEGIN
	DECLARE limitOption, offsetOption, ordersLength, iterator, keysLength, companiesCount INT(11);
	DECLARE done TINYINT(1);
	DECLARE translateTo VARCHAR(128);
	DECLARE company, orders, orderObject, companies, keysNames, files JSON;
	DECLARE companiesCursor CURSOR FOR SELECT company_json FROM custom_download_view;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
	SET responce = JSON_ARRAY();
	SET companies = JSON_ARRAY();
	SET files = JSON_ARRAY();
	SELECT 
		state_json ->> "$.download.limit",
		state_json ->> "$.download.offset",
		state_json ->> "$.download.orders"
	INTO 
		limitOption,
		offsetOption,
		orders
	FROM 
		states
	WHERE user_id = userID ORDER BY state_id DESC LIMIT 1;
	SET ordersLength = JSON_LENGTH(orders);
	SET @mysqlText = CONCAT(
		"CREATE VIEW custom_download_view AS SELECT company_json FROM companies WHERE user_id = ",
		userID,
		" AND type_id = 20"
	);
	IF ordersLength > 0
		THEN BEGIN
			SET iterator = 0;
			SET @mysqlText = CONCAT(
				@mysqlText,
				" ORDER BY"
			);
			ordersLoop: LOOP
				IF iterator >= ordersLength
					THEN LEAVE ordersLoop;
				END IF;
				SET orderObject = JSON_EXTRACT(orders, CONCAT("$[", iterator, "]"));
				SET @mysqlText = CONCAT(
					@mysqlText,
					IF(iterator = 0, " ", ", "),
					JSON_UNQUOTE(JSON_EXTRACT(orderObject, "$.name")),
					IF(JSON_UNQUOTE(JSON_EXTRACT(orderObject, "$.desc")), " DESC", "")
				);
				SET iterator = iterator + 1;
				ITERATE ordersLoop;
			END LOOP;
		END;
	END IF;
	SET @mysqlText = CONCAT(
		@mysqlText,
		" LIMIT ",
		limitOption,
		" OFFSET ",
		offsetOption
	);
	PREPARE mysqlPrepare FROM @mysqlText;
	EXECUTE mysqlPrepare;
	DEALLOCATE PREPARE mysqlPrepare;
	SET done = 0;
	OPEN companiesCursor;
		companiesLoop: LOOP
			FETCH companiesCursor INTO company;
			IF done
				THEN LEAVE companiesLoop;
			END IF;
			SET company = JSON_REMOVE(company,
				"$.city_id",
				"$.region_id",
				"$.type_id",
				"$.company_id",
				"$.template_id",
				"$.company_comment",
				"$.company_date_call_back"
			);
			SET companies = JSON_MERGE(companies, company);
			ITERATE companiesLoop;
		END LOOP;
	CLOSE companiesCursor;
	DROP VIEW IF EXISTS custom_download_view;
	IF company IS NOT NULL
		THEN BEGIN
			SET keysNames = JSON_KEYS(company);
			SET keysLength = JSON_LENGTH(keysNames);
			SET iterator = 0;
			translateLoop: LOOP
				IF iterator >= keysLength
					THEN LEAVE translateLoop;
				END IF;
				SET translateTo = (SELECT translate_to FROM translates WHERE translate_from = JSON_UNQUOTE(JSON_EXTRACT(keysNames, CONCAT("$[", iterator, "]"))));
				IF translateTo IS NOT NULL
					THEN SET keysNames = JSON_SET(keysNames, CONCAT("$[", iterator, "]"), JSON_OBJECT(
						"param", JSON_UNQUOTE(JSON_EXTRACT(keysNames, CONCAT("$[", iterator, "]"))),
						"name", translateTo
					));
				END IF;
				SET iterator = iterator + 1;
				ITERATE translateLoop;
			END LOOP;
			SELECT count(*) INTO companiesCount FROM companies WHERE user_id = userID AND type_id = 20;
			SET responce = sendToAllUserSockets(userID, JSON_ARRAY(
				JSON_OBJECT(
					"type", "merge",
					"data", JSON_OBJECT(
						"downloadCompanies", companies,
						"downloadCompaniesColumnsNames", keysNames
					)
				),
				JSON_OBJECT(
					"type", "mergeDeep",
					"data", JSON_OBJECT(
						"download", JSON_OBJECT(
							"companiesCount", companiesCount
						)
					)
				)
			));
		END;
		ELSE SET responce = sendToAllUserSockets(userID, JSON_ARRAY(
			JSON_OBJECT(
				"type", "mergeDeep",
				"data", JSON_OBJECT(
					"download", JSON_OBJECT(
						"message", "Компаний для формирования файла не обнаружено"
					)
				)
			),
			JSON_OBJECT(
				"type", "merge",
				"data", JSON_OBJECT(
					"downloadCompanies", JSON_ARRAY(),
					"downloadCompaniesColumnsNames", JSON_ARRAY()
				)
			)
		));
	END IF;
END