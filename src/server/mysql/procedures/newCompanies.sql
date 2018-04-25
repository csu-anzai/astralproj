BEGIN
	DECLARE companiesLength, templateID, templateСoncurrences, companiesKeysLength, iterator, iterator2, errCount, secondsDiff, microsecondsDiff, emptyCompanies, banksCount, bankID INT(11);
	DECLARE message, columnValue TEXT;
	DECLARE columnName VARCHAR(128);
	DECLARE templateColumnLetters VARCHAR(3);
	DECLARE endDate, startDate VARCHAR(26);
	DECLARE columns, companiesKeys, company, refreshResponce JSON;
	DECLARE done TINYINT(1);
	DECLARE templateCursor CURSOR FOR SELECT column_name, template_column_letters FROM custom_template_columns_view;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
	DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET errCount = errCount + 1;
	SET startDate = NOW(6);
	SET errCount = 0;
	SET companiesLength = JSON_LENGTH(companies);
	SET responce = JSON_ARRAY();
	IF companies IS NOT NULL AND companiesLength > 1
		THEN BEGIN
			SET columns = JSON_EXTRACT(companies, "$.columns");
			SET companies = JSON_REMOVE(companies, "$.columns");
			SET companiesLength = companiesLength - 1;
			SET companiesKeys = JSON_KEYS(columns);
			SET companiesKeysLength = JSON_LENGTH(companiesKeys);
			SELECT template_id, COUNT(template_column_name) weight INTO templateID, templateСoncurrences FROM template_columns WHERE JSON_CONTAINS(companiesKeys, JSON_ARRAY(template_column_letters)) AND template_column_name = JSON_UNQUOTE(JSON_EXTRACT(columns, CONCAT("$.", template_column_letters))) group by template_id order by weight desc limit 1;
			IF templateID IS NOT NULL 
				THEN BEGIN
					IF templateСoncurrences = companiesKeysLength
						THEN BEGIN
							SET @mysqlText = CONCAT(
								"CREATE VIEW custom_template_columns_view AS SELECT column_name, template_column_letters FROM template_columns_view WHERE template_id = ",
								templateID,
								" AND template_column_duplicate = 0 AND JSON_CONTAINS('",
								companiesKeys,
								"', JSON_ARRAY(template_column_letters))"
							);
							PREPARE mysqlPrepare FROM @mysqlText;
							EXECUTE mysqlPrepare;
							DEALLOCATE PREPARE mysqlPrepare;
							SET done = 0;
							SET companiesKeys = JSON_ARRAY();
							OPEN templateCursor;
								templateLoop: LOOP
									FETCH templateCursor INTO columnName, templateColumnLetters;
									IF done 
										THEN LEAVE templateLoop;
									END IF;
									SET companiesKeys = JSON_MERGE(companiesKeys, JSON_OBJECT(
										"letters", templateColumnLetters, 
										"column", columnName
									));
									ITERATE templateLoop;
								END LOOP;
							CLOSE templateCursor;
							DROP VIEW IF EXISTS custom_template_columns_view;
							SET iterator = 0;
							SET companiesKeysLength = JSON_LENGTH(companiesKeys);
							companiesLoop: LOOP
								IF iterator >= companiesLength
									THEN LEAVE companiesLoop;
								END IF;
								SET company = JSON_EXTRACT(companies, CONCAT("$.r", iterator + 1));
								SET iterator2 = 0;
								SET @mysqlText = "INSERT INTO companies (template_id, ";
								companiesKeysLoop: LOOP
									IF iterator2 >= companiesKeysLength
										THEN LEAVE companiesKeysLoop;
									END IF;
									SET @mysqlText = CONCAT(
										@mysqlText,
										IF(iterator2 = 0, "", ","),
										JSON_UNQUOTE(JSON_EXTRACT(companiesKeys, CONCAT("$[", iterator2, "].column")))
									);
									SET iterator2 = iterator2 + 1;
									ITERATE companiesKeysLoop;
								END LOOP;
								SET @mysqlText = CONCAT(@mysqlText, ") VALUES (", templateID, ", ");
								SET iterator2 = 0;
								companyLoop: LOOP
									IF iterator2 >= companiesKeysLength
										THEN LEAVE companyLoop;
									END IF;
									SET templateColumnLetters = JSON_UNQUOTE(JSON_EXTRACT(companiesKeys, CONCAT("$[", iterator2, "].letters")));
									SET columnValue = JSON_UNQUOTE(JSON_EXTRACT(company, CONCAT("$.", templateColumnLetters)));
									SET @mysqlText = CONCAT(
										@mysqlText,
										IF(iterator2 = 0, "", ","),
										IF(columnValue IS NULL, "NULL", CONCAT("'", columnValue, "'"))
									);
									SET iterator2 = iterator2 + 1;
									ITERATE companyLoop;
								END LOOP;
								SET @mysqlText = CONCAT(@mysqlText, ")");
								PREPARE mysqlPrepare FROM @mysqlText;
								EXECUTE mysqlPrepare;
								DEALLOCATE PREPARE mysqlPrepare;
								SET iterator = iterator + 1;
								ITERATE companiesLoop;
							END LOOP;
							SELECT COUNT(*) INTO emptyCompanies FROM empty_companies_view;
							delete c from companies c, empty_companies_view ecv where c.company_id = ecv.company_id;
							UPDATE companies SET company_json = JSON_SET(company_json, "$.company_id", company_id) WHERE state_json ->> "$.company_id" = 0;
							SET message = CONCAT(
								"Добавленно ",
								companiesLength - errCount - emptyCompanies,
								" компаний из ",
								companiesLength,
								". Дубликатов ",
								errCount,
								", пустых ",
								emptyCompanies
							);
							SET companiesLength = companiesLength - errCount - emptyCompanies;
							SELECT COUNT(DISTINCT bank_id) INTO banksCount FROM (SELECT bank_id FROM companies ORDER BY company_id DESC LIMIT companiesLength) companies WHERE bank_id IS NOT NULL;
							SET iterator = 0;
							banksLoop: LOOP						
								IF iterator >= banksCount
									THEN LEAVE banksLoop;
								END IF;
								SELECT DISTINCT bank_id INTO bankID FROM (SELECT bank_id FROM companies ORDER BY company_id DESC LIMIT companiesLength) companies WHERE bank_id IS NOT NULL LIMIT 1 OFFSET iterator;
								SET refreshResponce = JSON_ARRAY();
								CALL refreshBankSupervisors(bankID, refreshResponce);
								IF JSON_LENGTH(refreshResponce) > 0 
									THEN SET responce = JSON_MERGE(responce, refreshResponce);
								END IF;
								SET iterator = iterator + 1;
								ITERATE banksLoop;
							END LOOP;
						END;
						ELSE SET message = CONCAT("Не все колонки соответствуют шаблону ", templateID, " (", templateСoncurrences, "/", companiesKeysLength, ")");
					END IF;
				END;
				ELSE SET message = "Не удалось обнаружить шаблон";
			END IF;
		END;
		ELSE SET message = "Нет компаний для загрузки";
	END IF;
	SET endDate = SYSDATE(6);
	SET secondsDiff = TO_SECONDS(endDate) - TO_SECONDS(startDate);
	IF secondsDiff = 0
		THEN SET microsecondsDiff = MICROSECOND(endDate) - MICROSECOND(startDate);
		ELSE BEGIN
			SET secondsDiff = secondsDiff - 1;
			SET microsecondsDiff = 1000000 - MICROSECOND(startDate) + MICROSECOND(endDate);
			SET secondsDiff = secondsDiff + TRUNCATE(microsecondsDiff / 1000000, 0);
			SET microsecondsDiff = microsecondsDiff % 1000000;
		END;
	END IF;
	SET message = CONCAT(message, ". Затраченное время в секундах: ", secondsDiff, ".", microsecondsDiff);
	SET responce = JSON_MERGE(responce, JSON_OBJECT(
		"type", "print",
		"data", JSON_OBJECT(
			"message", message
		)
	));
END