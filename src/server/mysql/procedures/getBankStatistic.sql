BEGIN
	DECLARE typeID, templateID, templateItemsCount, userID, bankID, statisticCount, connectionID, typeToView, periodToView INT(11);
	DECLARE period VARCHAR(15);
	DECLARE dateStart, dateEnd VARCHAR(19);
	DECLARE typeName, searchResult, connectionApiID VARCHAR(128);
	DECLARE done, connectionValid TINYINT(1);
	DECLARE periodName VARCHAR(24);
	DECLARE labels, templates, templateItems, types JSON;
	DECLARE companiesCursor CURSOR FOR SELECT * FROM custom_statistic_view;
	DECLARE templatesCursor CURSOR FOR SELECT template_id, type_name FROM templates_view; 
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
	SET connectionValid = checkConnection(connectionHash);
	SELECT connection_api_id, user_id, connection_id INTO connectionApiID, userID, connectionID FROM users_connections_view WHERE connection_hash = connectionHash;
	SET responce = JSON_ARRAY();
	IF connectionValid 
		THEN BEGIN
			SELECT bank_id INTO bankID FROM users WHERE user_id = userID;
			SELECT 
				state_json ->> "$.statistic.dateStart", 
				state_json ->> "$.statistic.dateEnd", 
				state_json ->> "$.statistic.types",
				state_json ->> "$.statistic.typeToView",
				state_json ->> "$.statistic.period"
			INTO
				dateStart,
				dateEnd,
				types,
				typeToView,
				periodToView
			FROM states WHERE connection_id = connectionID AND user_id = userID LIMIT 1;
			IF date(dateStart) = date(dateEnd)
				THEN SET periodName = "CONCAT(HOUR(time),':00')";
				ELSE BEGIN
					SELECT COUNT(DISTINCT date) INTO statisticCount FROM statistic_view WHERE bank_id = bankID AND date BETWEEN DATE(dateStart) AND DATE(dateEnd) AND JSON_CONTAINS(types, JSON_ARRAY(type_id)) > 0;
					IF statisticCount <= 1
						THEN SET periodName = "CONCAT(HOUR(time),':00')";
						ELSE SET periodName = "date";
					END IF;
				END;
			END IF;
			SET @mysqlText = CONCAT("CREATE VIEW custom_statistic_view AS SELECT ", periodName," FROM statistic_view WHERE bank_id = ", bankID, " AND date BETWEEN DATE('", dateStart, "') AND DATE('", dateEnd, "') AND JSON_CONTAINS('", types,"', JSON_ARRAY(type_id)) > 0 GROUP BY ", periodName);
			SET labels = JSON_ARRAY();
			SET templates = JSON_ARRAY();
			PREPARE mysqlPrepare FROM @mysqlText;
			EXECUTE mysqlPrepare;
			DEALLOCATE PREPARE mysqlPrepare;
			OPEN companiesCursor;
				companiesLoop: LOOP
					FETCH companiesCursor INTO period;
					IF done 
						THEN LEAVE companiesLoop;
					END IF;
					SET labels = JSON_MERGE(labels, JSON_ARRAY(REPLACE(period, ".000000", "")));
					OPEN templatesCursor;
						templatesLoop: LOOP
							FETCH templatesCursor INTO templateID, typeName;
							IF done 
								THEN LEAVE templatesLoop;
							END IF;
							IF periodName = "date"
								THEN SELECT COUNT(*) INTO templateItemsCount FROM companies WHERE DATE(company_date_update) = DATE(period) AND JSON_CONTAINS(types, JSON_ARRAY(type_id)) > 0 AND template_id = templateID;
								ELSE SELECT COUNT(*) INTO templateItemsCount FROM companies WHERE TIME(company_date_update) = TIME(period) AND JSON_CONTAINS(types, JSON_ARRAY(type_id)) > 0 AND template_id = templateID;
							END IF;
							SET searchResult = JSON_UNQUOTE(JSON_SEARCH(templates, "one", typeName, NULL, "$[*].name"));
							SET searchResult = REPLACE(searchResult, ".name", ".items");
							IF searchResult IS NULL
								THEN SET templates = JSON_MERGE(templates, JSON_OBJECT(
									"name", typeName,
									"items", JSON_ARRAY(templateItemsCount)
								));
								ELSE BEGIN
									SET templateItems = JSON_EXTRACT(templates, searchResult);
									SET templateItems = JSON_MERGE(templateItems, JSON_ARRAY(templateItemsCount));
									SET templates = JSON_SET(templates, searchResult, templateItems);
								END;
							END IF;
							ITERATE templatesLoop;
						END LOOP;
					CLOSE templatesCursor;
					SET done = 0;
					ITERATE companiesLoop;
				END LOOP;
			CLOSE companiesCursor;
			DROP VIEW custom_statistic_view;
			SET responce = JSON_MERGE(responce, JSON_OBJECT(
				"type", "sendToSocket",
				"data", JSON_OBJECT(
					"socketID", connectionApiID,
					"data", JSON_ARRAY(
						JSON_OBJECT(
							"type", "merge",
							"data", JSON_OBJECT(
								"statistic", JSON_OBJECT(
									"labels", labels,
									"templates", templates,
									"typeToView", typeToView,
									"period", periodToView
								)
							)
						)
					)
				)
			));
		END;
		ELSE SET responce = JSON_MERGE(responce, JSON_OBJECT(
			"type", "sendToSocket",
			"data", JSON_OBJECT(
				"socketID", connectionApiID,
				"data", JSON_ARRAY(JSON_OBJECT(
					"type", "merge",
					"data", JSON_OBJECT(
						"auth", 0,
						"loginMessage", "Требуется ручной вход в систему"
					)
				))
			)
		));
	END IF;
END