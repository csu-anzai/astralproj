BEGIN
	DECLARE templateID, oldTemplateID, iterator, iterator2, columnsKeysCount, companiesLength, errorLength, banksCount, bankID, duplicateCount, emptyCount, secondsDiff, microsecondsDiff, emtyInArrayLength INT(11);
	DECLARE templateSuccess, duplicate TINYINT(1);
	DECLARE TemplateColumnName, columnName VARCHAR(128);
	DECLARE endDate, startDate VARCHAR(26);
	DECLARE message TEXT;
	DECLARE columnLetters VARCHAR(3);
	DECLARE columns, columnsKeys, company, columnKeysObj, errorColumns, errorObj, refreshResponce, cleaningResponce JSON;
	SET startDate = NOW(6);
	SET responce = JSON_ARRAY();
	SET templateSuccess = 1;
	SET companiesLength = JSON_LENGTH(companies);
	SET errorColumns = JSON_ARRAY();
	SET emtyInArrayLength = 0;
	IF companies IS NOT NULL AND companiesLength > 1
		THEN BEGIN
			SET columns = JSON_EXTRACT(companies, "$.columns");
			SET columnsKeys = JSON_KEYS(columns);
			SET columnsKeysCount = JSON_LENGTH(columnsKeys);
			SET iterator = 0;
			columnsLoop: LOOP
				IF iterator >= columnsKeysCount OR templateSuccess = 0
					THEN LEAVE columnsLoop;
				END IF;
				SET columnLetters = JSON_UNQUOTE(JSON_EXTRACT(columnsKeys, CONCAT("$[", iterator, "]")));
				SET TemplateColumnName = JSON_UNQUOTE(JSON_EXTRACT(columns, CONCAT("$.", columnLetters)));
				SET templateID = (SELECT template_id FROM template_columns_view WHERE template_column_name = TemplateColumnName AND template_column_letters = columnLetters);
				IF iterator = 0 
					THEN SET oldTemplateID = templateID;
				END IF;
				IF templateID IS NULL OR templateID != oldTemplateID
					THEN BEGIN 
						SET templateSuccess = 0;
						SET errorColumns = JSON_MERGE(errorColumns, JSON_OBJECT(
							"name", TemplateColumnName,
							"letters", columnLetters
						));
					END;
				END IF;
				SET iterator = iterator + 1;
				ITERATE columnsLoop;
			END LOOP;
			IF templateSuccess AND templateID IS NOT NULL
				THEN BEGIN
					SET @newCompaniesQuery = "INSERT INTO companies (";
					SET iterator = 0;
					columnsQueryLoop: LOOP
						IF iterator >= columnsKeysCount
							THEN LEAVE columnsQueryLoop;
						END IF;
						SET columnLetters = JSON_UNQUOTE(JSON_EXTRACT(columnsKeys, CONCAT("$[", iterator, "]")));
						SELECT column_name, template_column_duplicate INTO columnName, duplicate FROM template_columns_view WHERE template_id = templateID AND template_column_letters = columnLetters;
						IF duplicate = 0
							THEN SET @newCompaniesQuery = CONCAT(@newCompaniesQuery, IF(iterator > 0, ",", ""), columnName);
						END IF;
						SET columnsKeys = JSON_SET(columnsKeys, CONCAT("$[", iterator, "]"), JSON_OBJECT(
							"key", JSON_EXTRACT(columnsKeys, CONCAT("$[", iterator, "]")),
							"dup", duplicate
						));
						SET iterator = iterator + 1;
						ITERATE columnsQueryLoop;
					END LOOP;
					SET @newCompaniesQuery = CONCAT(@newCompaniesQuery, ",template_id) VALUES ");
					SET iterator = 2;
					rowsQueryLoop: LOOP
						IF iterator > companiesLength
							THEN LEAVE rowsQueryLoop;
						END IF;
						SET company = JSON_EXTRACT(companies, CONCAT("$.r", iterator));
						IF company IS NOT NULL
							THEN BEGIN
								SET @newCompaniesQuery = CONCAT(@newCompaniesQuery, IF(iterator > 2, ",", ""),"(");
								SET iterator2 = 0;
								colsQueryLoop: LOOP
									IF iterator2 >= columnsKeysCount
										THEN LEAVE colsQueryLoop;
									END IF;
									SET columnKeysObj = JSON_UNQUOTE(JSON_EXTRACT(columnsKeys, CONCAT("$[", iterator2, "]")));
									SET duplicate = JSON_EXTRACT(columnKeysObj, "$.dup");
									IF duplicate = 0
										THEN BEGIN 
											SET columnLetters = JSON_UNQUOTE(JSON_EXTRACT(columnKeysObj, "$.key"));
											SET @newCompaniesQuery = CONCAT(@newCompaniesQuery, IF(iterator2 > 0, ",", ""), IF(JSON_EXTRACT(company, CONCAT("$.", columnLetters)) IS NULL, "NULL", JSON_EXTRACT(company, CONCAT("$.", columnLetters))));
										END;
									END IF;
									SET iterator2 = iterator2 + 1;
									ITERATE colsQueryLoop;
								END LOOP;
								SET @newCompaniesQuery = CONCAT(@newCompaniesQuery, ",",templateID,")");
							END;
							ELSE SET emtyInArrayLength = emtyInArrayLength + 1;
						END IF;
						SET iterator = iterator + 1;
						ITERATE rowsQueryLoop;
					END LOOP;
					PREPARE newCompaniesQuery FROM @newCompaniesQuery;
					EXECUTE newCompaniesQuery;
					DEALLOCATE PREPARE newCompaniesQuery;
					UPDATE companies SET company_json = JSON_SET(company_json, "$.company_id", company_id) WHERE company_json ->> "$.company_id" = 0;
					SET cleaningResponce = companiesCleaning();
					SET duplicateCount = JSON_UNQUOTE(JSON_EXTRACT(cleaningResponce, "$.deleteDuplicateCompanies"));
					SET emptyCount = JSON_UNQUOTE(JSON_EXTRACT(cleaningResponce, "$.deleteEmptyCompanies"));
					SET companiesLength = companiesLength - 1 - (duplicateCount + emptyCount + emtyInArrayLength);
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
					SET responce = JSON_MERGE(responce,
						JSON_OBJECT(
							"type", "print",
							"data", JSON_OBJECT(
								"message", CONCAT("added ", companiesLength, " companies in the base. ", emtyInArrayLength," items in array be null. Delete ", emptyCount, " empty companies and ", duplicateCount, " duplicate companies. Seconds ", secondsDiff, ".", microsecondsDiff)
							)
						)
					);
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
				ELSE BEGIN
					SET message = "error in template for column: ";
					SET errorLength = JSON_LENGTH(errorColumns);
					SET iterator = 0;
					errorLoop: LOOP
						IF iterator >= errorLength
							THEN LEAVE errorLoop;
						END IF;
						SET errorObj = JSON_EXTRACT(errorColumns, CONCAT("$[", iterator, "]"));
						SET message = CONCAT(message, "'", JSON_UNQUOTE(JSON_EXTRACT(errorObj, "$.name")), " - ", JSON_UNQUOTE(JSON_EXTRACT(errorObj, "$.letters")), "' ");
						SET iterator = iterator + 1;
						ITERATE errorLoop;
					END LOOP;
					SET responce = JSON_MERGE(responce, JSON_OBJECT(
						"type", "print",
						"data", JSON_OBJECT(
							"message", message
						)
					));
				END;
			END IF;
		END;
	END IF;
END