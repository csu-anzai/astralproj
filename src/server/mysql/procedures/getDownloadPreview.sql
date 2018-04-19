BEGIN
	DECLARE typesLength, regionsLength, nullColumnsLength, notNullColumnsLength, ordersLength, columnID, regionID, limitOption, offsetOption, iterator, companyID, banksLength INT(11);
	DECLARE type INT(2);
	DECLARE columnName VARCHAR(128);
	DECLARE regionName VARCHAR(60);
	DECLARE types, regions, nullColumns, notNullColumns, company, companies, allColumns, allRegions, orders, orderObject, companiesID, banks JSON;
	DECLARE dateStart, dateEnd VARCHAR(10);
	DECLARE done, descOption TINYINT(1);
	DECLARE companiesCursor CURSOR FOR SELECT company_json, company_id FROM custom_download_view;
	DECLARE columnsCursor CURSOR FOR SELECT column_name FROM custom_columns_view;
	DECLARE allColumnsCursor CURSOR FOR SELECT column_id, column_name FROM columns;
	DECLARE allRegionsCursor CURSOR FOR SELECT region_id, region_name FROM regions;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
	SET responce = JSON_ARRAY();
	SET companies = JSON_ARRAY();
	SET companiesID = JSON_ARRAY();
	SET allRegions = JSON_ARRAY();
	SET allColumns = JSON_ARRAY();
	UPDATE companies SET type_id = 10, user_id = NULL WHERE user_id = userID AND type_id = 20;
	SELECT 
		state_json ->> "$.download.types",
		state_json ->> "$.download.dateStart",
		state_json ->> "$.download.dateEnd",
		state_json ->> "$.download.regions",
		state_json ->> "$.download.nullColumns",
		state_json ->> "$.download.notNullColumns",
		state_json ->> "$.download.type",
		state_json ->> "$.download.limit",
		state_json ->> "$.download.offset",
		state_json ->> "$.download.orders",
		state_json ->> "$.download.banks"
	INTO  
		types,
		dateStart,
		dateEnd,
		regions,
		nullColumns,
		notNullColumns,
		type,
		limitOption,
		offsetOption,
		orders,
		banks
	FROM states WHERE user_id = userID ORDER BY state_id DESC LIMIT 1;
	SET typesLength = JSON_LENGTH(types);
	SET regionsLength = JSON_LENGTH(regions);
	SET nullColumnsLength = JSON_LENGTH(nullColumns);
	SET notNullColumnsLength = JSON_LENGTH(notNullColumns);
	SET ordersLength = JSON_LENGTH(orders);
	SET banksLength = JSON_LENGTH(banks);
	SET @mysqlText = CONCAT(
		"CREATE VIEW custom_download_view AS SELECT company_json, company_id FROM companies WHERE DATE(company_date_create)",
		IF(dateStart = dateEnd, "=", " BETWEEN "),
		IF(dateStart = dateEnd, CONCAT("DATE('", dateStart, "')"), CONCAT("DATE('", dateStart, "') AND DATE('", dateEnd, "')")),
		IF(typesLength > 0, CONCAT(" AND JSON_CONTAINS('", types, "', JSON_ARRAY(type_id))"), ""),
		IF(regionsLength > 0, CONCAT(" AND JSON_CONTAINS('", regions, "', JSON_ARRAY(region_id))"), ""),
		IF(banksLength > 0, CONCAT(" AND JSON_CONTAINS('", banks, "', JSON_ARRAY(bank_id))"), "")
	);
	IF nullColumnsLength > 0 
		THEN BEGIN
			SET done = 0;
			SET @mysqlText2 = CONCAT(
				"CREATE VIEW custom_columns_view AS SELECT column_name FROM columns WHERE JSON_CONTAINS('",
				nullColumns,
				"', JSON_ARRAY(column_id))"
			);
			PREPARE mysqlPrepare FROM @mysqlText2;
			EXECUTE mysqlPrepare;
			DEALLOCATE PREPARE mysqlPrepare;
			OPEN columnsCursor;
				columnsLoop: LOOP
					FETCH columnsCursor INTO columnName;
					IF done 
						THEN LEAVE columnsLoop;
					END IF;
					SET @mysqlText = CONCAT(
						mysqlText, 
						" AND ",
						columnName,
						" IS NULL"
					);
					ITERATE columnsLoop;
				END LOOP;
			CLOSE columnsCursor;
			DROP VIEW IF EXISTS custom_columns_view;
		END;
	END IF;
	IF notNullColumnsLength > 0 
		THEN BEGIN
			SET done = 0;
			SET @mysqlText2 = CONCAT(
				"CREATE VIEW custom_columns_view AS SELECT column_name FROM columns WHERE JSON_CONTAINS('",
				notNullColumns,
				"', JSON_ARRAY(column_id))"
			);
			PREPARE mysqlPrepare FROM @mysqlText2;
			EXECUTE mysqlPrepare;
			DEALLOCATE PREPARE mysqlPrepare;
			OPEN columnsCursor;
				columnsLoop: LOOP
					FETCH columnsCursor INTO columnName;
					IF done 
						THEN LEAVE columnsLoop;
					END IF;
					SET @mysqlText = CONCAT(
						mysqlText, 
						" AND ",
						columnName,
						" IS NOT NULL"
					);
					ITERATE columnsLoop;
				END LOOP;
			CLOSE columnsCursor;
			DROP VIEW IF EXISTS custom_columns_view;
		END;
	END IF;
	IF ordersLength > 0
		THEN BEGIN
			SET iterator = 0;
			SET @mysqlText = CONCAT(@mysqlText, " ORDER BY");
			ordersLoop: LOOP
				IF iterator >= ordersLength
					THEN LEAVE ordersLoop;
				END IF;
				SET orderObject = JSON_EXTRACT(orders, CONCAT("$[", iterator, "]"));
				SET columnName = JSON_UNQUOTE(JSON_EXTRACT(orderObject, "$.name"));
				SET descOption = JSON_UNQUOTE(JSON_EXTRACT(orderObject, "$.desc"));
				SET @mysqlText = CONCAT(
					@mysqlText,
					IF(iterator = 0, " ", ","),
					columnName,
					IF(descOption, " DESC", "")
				);
				SET iterator = iterator + 1;
				ITERATE ordersLoop;
			END LOOP;
		END;
	END IF;
	SET @mysqlText = CONCAT(@mysqlText, " LIMIT ", limitOption);
	SET @mysqlText = CONCAT(@mysqlText, " OFFSET ", offsetOption);
	PREPARE mysqlPrepare FROM @mysqlText;
	EXECUTE mysqlPrepare;
	DEALLOCATE PREPARE mysqlPrepare;
	SET done = 0;
	OPEN companiesCursor;
		companiesLoop: LOOP
			FETCH companiesCursor INTO company, companyID;
			IF done
				THEN LEAVE companiesLoop;
			END IF;
			SET companies = JSON_MERGE(companies, company);
			SET companiesID = JSON_MERGE(companiesID, JSON_ARRAY(companyID));
			ITERATE companiesLoop;
		END LOOP;
	CLOSE companiesCursor;
	DROP VIEW IF EXISTS custom_download_view;
	IF JSON_LENGTH(companiesID) > 0
		THEN UPDATE companies SET type_id = 20, user_id = userID WHERE JSON_CONTAINS(companiesID, JSON_ARRAY(company_id));
	END IF;
	SET done = 0;
	OPEN allColumnsCursor;
		columnsLoop: LOOP
			FETCH allColumnsCursor INTO columnID, columnName;
			IF done 
				THEN LEAVE columnsLoop;
			END IF;
			SET allColumns = JSON_MERGE(allColumns, JSON_OBJECT(
				"name", columnName,
				"id", columnID
			));
			ITERATE columnsLoop;
		END LOOP;
	CLOSE allColumnsCursor;
	SET done = 0;
	OPEN allRegionsCursor;
		regionsLoop: LOOP
			FETCH allRegionsCursor INTO regionID, regionName;
			IF done 
				THEN LEAVE regionsLoop;
			END IF;
			SET allRegions = JSON_MERGE(allRegions, JSON_OBJECT(
				"name", regionName,
				"id", regionID
			));
			ITERATE regionsLoop;
		END LOOP;
	CLOSE allRegionsCursor;
	SET responce = JSON_MERGE(responce, sendToAllUserSockets(userID, JSON_ARRAY(JSON_OBJECT(
		"type", "merge",
		"data", JSON_OBJECT(
			"download", JSON_OBJECT(
				"companies", companies,
				"dataStart", dateStart,
				"dataEnd", dateEnd,
				"regions", regions,
				"type", type,
				"nullColumns", nullColumns,
				"notNullColumns", notNullColumns,
				"banks", banks
			),
			"regions", allRegions,
			"columns", allColumns
		)
	))));
END