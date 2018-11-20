BEGIN
	DECLARE typesLength, regionsLength, nullColumnsLength, notNullColumnsLength, ordersLength, columnID, regionID, limitOption, offsetOption, iterator, companyID, banksLength, userID INT(11);
	DECLARE type INT(2);
	DECLARE columnName, connectionApiID VARCHAR(128);
	DECLARE regionName VARCHAR(60);
	DECLARE types, regions, nullColumns, notNullColumns, company, companies, allColumns, allRegions, orders, orderObject, companiesID, banks JSON;
	DECLARE dateStart, dateEnd VARCHAR(10);
	DECLARE done, descOption, connectionValid TINYINT(1);
	DECLARE companiesCursor CURSOR FOR SELECT company_json, company_id FROM custom_download_view;
	DECLARE columnsCursor CURSOR FOR SELECT column_name FROM custom_columns_view;
	DECLARE allColumnsCursor CURSOR FOR SELECT column_id, column_name FROM columns;
	DECLARE allRegionsCursor CURSOR FOR SELECT region_id, region_name FROM regions;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
	SET connectionValid = checkRootConnection(connectionHash);
	SELECT user_id, connection_api_id INTO userID, connectionApiID FROM users_connections_view WHERE connection_hash = connectionHash;
	SET responce = JSON_ARRAY();
	IF connectionValid
		THEN BEGIN
			SET companies = JSON_ARRAY();
			SET companiesID = JSON_ARRAY();
			SET allRegions = JSON_ARRAY();
			SET allColumns = JSON_ARRAY();
			UPDATE companies SET type_id = IF(type_id = 20, 10, type_id), user_id = IF(type_id = 20, NULL, user_id), company_file_user = NULL, company_file_type = NULL WHERE company_file_user = userID AND company_file_type = 20;
			SELECT 
				state_json ->> "$.download.types",
				state_json ->> "$.download.dateStart",
				state_json ->> "$.download.dateEnd",
				state_json ->> "$.download.regions",
				state_json ->> "$.download.nullColumns",
				state_json ->> "$.download.notNullColumns",
				state_json ->> "$.download.type",
				state_json ->> "$.download.count",		
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
				banks
			FROM states WHERE user_id = userID ORDER BY state_id DESC LIMIT 1;
			SET typesLength = JSON_LENGTH(types);
			SET regionsLength = JSON_LENGTH(regions);
			SET nullColumnsLength = JSON_LENGTH(nullColumns);
			SET notNullColumnsLength = JSON_LENGTH(notNullColumns);
			SET ordersLength = JSON_LENGTH(orders);
			SET banksLength = JSON_LENGTH(banks);	
			SET @mysqlText = CONCAT(
				"UPDATE companies SET company_file_user = ", userID,", company_file_type = 20 WHERE DATE(company_date_create)",
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
								@mysqlText, 
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
								@mysqlText, 
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
			SET @mysqlText = CONCAT(@mysqlText, " LIMIT ", limitOption);
			PREPARE mysqlPrepare FROM @mysqlText;
			EXECUTE mysqlPrepare;
			DEALLOCATE PREPARE mysqlPrepare;
			CALL getDownloadPreview(userID, responce);
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