BEGIN
	DECLARE typeID, templateID, templateItemsCount, templateInfoItemsCount, templatePeriodItemsCount, userID, user, bankID, statisticCount, connectionID, typeToView, periodToView, dataPeriod, templatesPeriodsLength, iterator INT(11);
	DECLARE period VARCHAR(15);
	DECLARE dateStart, dateEnd, dataDateStart, dataDateEnd VARCHAR(19);
	DECLARE typeName, searchResult, connectionApiID VARCHAR(128);
	DECLARE done, connectionValid, dataBank, dataFree TINYINT(1);
	DECLARE periodName, dataPeriodName VARCHAR(24);
	DECLARE labels, templates, templateItems, templateInfoItems, types, users, templatesPeriods JSON;
	DECLARE companiesCursor CURSOR FOR SELECT * FROM custom_statistic_view;
	DECLARE templatesCursor CURSOR FOR SELECT template_id, type_name FROM templates_view;
	DECLARE templatesPeriodsCursor CURSOR FOR SELECT * FROM custom_data_view;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
	SET connectionValid = checkConnection(connectionHash);
	SELECT connection_api_id, user_id, connection_id INTO connectionApiID, userID, connectionID FROM users_connections_view WHERE connection_hash = connectionHash;
	SET responce = JSON_ARRAY();
	SET templatesPeriods = JSON_ARRAY();
	IF connectionValid 
		THEN BEGIN
			SELECT bank_id INTO bankID FROM users WHERE user_id = userID;
			SELECT 
				state_json ->> "$.statistic.dateStart", 
				state_json ->> "$.statistic.dateEnd", 
				state_json ->> "$.statistic.types",
				state_json ->> "$.statistic.typeToView",
				state_json ->> "$.statistic.period",
				state_json ->> "$.statistic.user",
				state_json ->> "$.statistic.dataDateStart",
				state_json ->> "$.statistic.dataDateEnd",
				state_json ->> "$.statistic.dataPeriod",
				state_json ->> "$.statistic.dataBank",
				state_json ->> "$.statistic.dataFree"
			INTO
				dateStart,
				dateEnd,
				types,
				typeToView,
				periodToView,
				user,
				dataDateStart,
				dataDateEnd,
				dataPeriod,
				dataBank,
				dataFree
			FROM states WHERE connection_id = connectionID AND user_id = userID LIMIT 1;
			IF DATE(dateStart) = DATE(dateEnd)
				THEN SET periodName = "CONCAT(HOUR(time),':00')";
				ELSE BEGIN
					SELECT COUNT(DISTINCT date) INTO statisticCount FROM statistic_view WHERE bank_id = bankID AND date BETWEEN DATE(dateStart) AND DATE(dateEnd) AND JSON_CONTAINS(types, JSON_ARRAY(type_id)) > 0;
					IF statisticCount <= 1
						THEN BEGIN
							SET periodName = "CONCAT(HOUR(time),':00')";
							SELECT DISTINCT DATE(date), DATE(date) INTO dateStart, dateEnd FROM statistic_view WHERE bank_id = bankID AND date BETWEEN DATE(dateStart) AND DATE(dateEnd) AND JSON_CONTAINS(types, JSON_ARRAY(type_id)) > 0;
						END;
						ELSE SET periodName = "date";
					END IF;
				END;
			END IF;
			IF DATE(dataDateStart) = DATE(dataDateEnd)
				THEN BEGIN
					SET dataPeriodName = "time";
					SET @mysqlText2 = CONCAT("CREATE VIEW custom_data_view AS SELECT CONCAT(HOUR(company_date_create),':',MINUTE(company_date_create)) time FROM companies WHERE IF(", dataFree, ", type_id = 10, 1) AND IF(", dataBank, ", bank_id = ", bankID, ", 1) AND DATE(company_date_create) = DATE('", dataDateStart, "') GROUP BY time");
				END;
				ELSE BEGIN 
					SET dataPeriodName = "date";
					SET @mysqlText2 = CONCAT("CREATE VIEW custom_data_view AS SELECT DATE(company_date_create) date FROM companies WHERE IF(", dataFree, ", type_id = 10, 1) AND IF(", dataBank, ", bank_id = ", bankID, ", 1) AND DATE(company_date_create) BETWEEN DATE('", dataDateStart, "') AND DATE('", dataDateEnd, "') GROUP BY date");
				END;
			END IF;
			SET @mysqlText = CONCAT("CREATE VIEW custom_statistic_view AS SELECT ", periodName," period FROM statistic_view WHERE bank_id = ", bankID, " AND date BETWEEN DATE('", dateStart, "') AND DATE('", dateEnd, "') AND JSON_CONTAINS('", types,"', JSON_ARRAY(type_id)) > 0 GROUP BY period");
			SET labels = JSON_ARRAY();
			SET templates = JSON_ARRAY();
			PREPARE mysqlPrepare FROM @mysqlText;
			EXECUTE mysqlPrepare;
			DEALLOCATE PREPARE mysqlPrepare;
			PREPARE mysqlPrepare FROM @mysqlText2;
			EXECUTE mysqlPrepare;
			DEALLOCATE PREPARE mysqlPrepare;
			SET done = 0;
			OPEN templatesPeriodsCursor;
				templatesPeriodsLoop: LOOP
					FETCH templatesPeriodsCursor INTO period;
					IF done
						THEN LEAVE templatesPeriodsLoop;
					END IF;
					SET templatesPeriods = JSON_MERGE(templatesPeriods, JSON_ARRAY(period));
					ITERATE templatesPeriodsLoop;
				END LOOP;
			CLOSE templatesPeriodsCursor;
			SET templatesPeriodsLength = JSON_LENGTH(templatesPeriods);
			DROP VIEW IF EXISTS custom_data_view;
			SET done = 0;
			OPEN templatesCursor;
				templatesLoop: LOOP
					FETCH templatesCursor INTO templateID, typeName;
					IF done
						THEN LEAVE templatesLoop;
					END IF;
					SET searchResult = JSON_SEARCH(templates, "one", typeName, NULL, "$[*].name");
					SET templateInfoItems = JSON_ARRAY();
					SET iterator = 0;
					templatePeriodsLoop: LOOP
						IF iterator >= templatesPeriodsLength
							THEN LEAVE templatePeriodsLoop;
						END IF;
						SET period = JSON_UNQUOTE(JSON_EXTRACT(templatesPeriods, CONCAT("$[", iterator, "]")));
						IF dataPeriodName = "date"
							THEN SELECT COUNT(*) INTO templatePeriodItemsCount FROM companies WHERE template_id = templateID AND IF(dataBank, bank_id = bankID, 1) AND IF(dataFree, type_id = 10, 1) AND DATE(company_date_create) = DATE(period);
							ELSE SELECT COUNT(*) INTO templatePeriodItemsCount FROM companies WHERE template_id = templateID AND IF(dataBank, bank_id = bankID, 1) AND IF(dataFree, type_id = 10, 1) AND DATE(company_date_create) = DATE(dataDateStart) AND HOUR(company_date_create) = HOUR(period) AND MINUTE(company_date_create) = MINUTE(period);
						END IF;
						SET templateInfoItems = JSON_MERGE(templateInfoItems, JSON_ARRAY(templatePeriodItemsCount));
						SET iterator = iterator + 1;
						ITERATE templatePeriodsLoop;
					END LOOP;
					IF searchResult IS NULL
						THEN SET templates = JSON_MERGE(templates, JSON_OBJECT(
							"name", typeName,
							"infoItems", templateInfoItems,
							"items", JSON_ARRAY()
						));
						ELSE BEGIN
							SET searchResult = REPLACE(searchResult, ".name", ".infoItems");
							SET templateInfoItemsCount = templateInfoItemsCount + JSON_UNQUOTE(JSON_EXTRACT(templates, searchResult));
							SET templates = JSON_SET(templates, searchResult, templateInfoItemsCount);
						END;
					END IF;
					ITERATE templatesLoop;
				END LOOP;
			CLOSE templatesCursor;
			SET done = 0;
			OPEN companiesCursor;
				companiesLoop: LOOP
					FETCH companiesCursor INTO period;
					IF done 
						THEN LEAVE companiesLoop;
					END IF;
					IF periodName != "date"
						THEN SET labels = JSON_MERGE(labels, JSON_ARRAY(CONCAT(HOUR(period), " - ", HOUR(period) + 1)));
						ELSE SET labels = JSON_MERGE(labels, JSON_ARRAY(period));
					END IF;
					OPEN templatesCursor;
						templatesLoop: LOOP
							FETCH templatesCursor INTO templateID, typeName;
							IF done 
								THEN LEAVE templatesLoop;
							END IF;
							IF periodName = "date"
								THEN SELECT COUNT(*) INTO templateItemsCount FROM companies WHERE DATE(company_date_update) = DATE(period) AND JSON_CONTAINS(types, JSON_ARRAY(type_id)) > 0 AND template_id = templateID AND bank_id = bankID AND IF(user > 0, user_id = user, 1);
								ELSE SELECT COUNT(*) INTO templateItemsCount FROM companies WHERE HOUR(company_date_update) = HOUR(period) AND DATE(company_date_update) BETWEEN DATE(dateStart) AND DATE(dateEnd) AND JSON_CONTAINS(types, JSON_ARRAY(type_id)) > 0 AND template_id = templateID AND bank_id = bankID AND IF(user > 0, user_id = user, 1);
							END IF;
							SET searchResult = JSON_UNQUOTE(JSON_SEARCH(templates, "one", typeName, NULL, "$[*].name"));
							SET searchResult = REPLACE(searchResult, ".name", ".items");
							SET templateItems = JSON_EXTRACT(templates, searchResult);
							SET templateItems = JSON_MERGE(templateItems, JSON_ARRAY(templateItemsCount));
							SET templates = JSON_SET(templates, searchResult, templateItems);
							ITERATE templatesLoop;
						END LOOP;
					CLOSE templatesCursor;
					SET done = 0;
					ITERATE companiesLoop;
				END LOOP;
			CLOSE companiesCursor;
			DROP VIEW IF EXISTS custom_statistic_view;
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
									"period", periodToView,
									"dateStart", date(dateStart),
									"dateEnd", date(dateEnd),
									"user", user,
									"users", getUsers(bankID),
									"dataLabels", templatesPeriods,
									"dataPeriod", dataPeriod,
									"dataFree", dataFree,
									"dataBank", dataBank,
									"dataDateStart", dataDateStart,
									"dataDateEnd", dataDateEnd
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