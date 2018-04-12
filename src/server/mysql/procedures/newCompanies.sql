BEGIN
	DECLARE templateID, oldTemplateID, iterator, iterator2, columnsKeysCount, companiesLength, deleteCount, deleteCount2, deleteCount3, errorLength, banksCount, bankID INT(11);
	DECLARE templateSuccess, duplicate TINYINT(1);
	DECLARE TemplateColumnName, columnName VARCHAR(128);
	DECLARE message TEXT;
	DECLARE columnLetters VARCHAR(3);
	DECLARE columns, columnsKeys, company, columnKeysObj, errorColumns, errorObj, refreshResponce JSON;
	SET responce = JSON_ARRAY();
	SET templateSuccess = 1;
	SET companiesLength = JSON_LENGTH(companies);
	SET errorColumns = JSON_ARRAY();
	SET deleteCount = 0;
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
						SET @newCompaniesQuery = CONCAT(@newCompaniesQuery, IF(iterator > 2, ",", ""),"(");
						SET company = JSON_EXTRACT(companies, CONCAT("$.r", iterator));
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
						SET iterator = iterator + 1;
						ITERATE rowsQueryLoop;
					END LOOP;
					PREPARE newCompaniesQuery FROM @newCompaniesQuery;
					EXECUTE newCompaniesQuery;
					DEALLOCATE PREPARE newCompaniesQuery;
					SELECT COUNT(*) INTO deleteCount FROM companies a, companies b WHERE a.company_id > b.company_id AND (a.company_ogrn = b.company_ogrn OR a.company_inn = b.company_inn);
					IF deleteCount > 0
						THEN DELETE a FROM companies a, companies b WHERE a.company_id > b.company_id AND (a.company_ogrn = b.company_ogrn OR a.company_inn = b.company_inn);
					END IF;
					SELECT COUNT(*) INTO deleteCount2 FROM companies WHERE (company_phone IS NULL OR company_inn IS NULL) AND bank_id IS NOT NULL;
					IF deleteCount2 > 0
						THEN DELETE FROM companies WHERE (company_phone IS NULL OR company_inn IS NULL) AND bank_id IS NOT NULL;
					END IF;
					SELECT COUNT(*) INTO deleteCount3 FROM companies WHERE company_inn IS NULL AND bank_id IS NULL;
					IF deleteCount3 > 0
						THEN DELETE FROM companies WHERE company_inn IS NULL AND bank_id IS NULL;
					END IF;
					SET companiesLength = companiesLength - 1 - (deleteCount + deleteCount2 + deleteCount3);
					SET responce = JSON_MERGE(responce,
						JSON_OBJECT(
							"type", "print",
							"data", JSON_OBJECT(
								"message", CONCAT("added ", companiesLength, " companies in the base")
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