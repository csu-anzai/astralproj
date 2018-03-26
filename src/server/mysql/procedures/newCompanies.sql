BEGIN
	DECLARE templateID, oldTemplateID, iterator, iterator2, columnsKeysCount, companiesLength, deleteCount INT(11);
	DECLARE templateSuccess, duplicate TINYINT(1);
	DECLARE TemplateColumnName, columnName VARCHAR(128);
	DECLARE columnLetters VARCHAR(3);
	DECLARE columns, columnsKeys, company, columnKeysObj JSON;
	SET responce = JSON_OBJECT();
	SET templateSuccess = 1;
	SET companiesLength = JSON_LENGTH(companies);
	SET deleteCount = 0;
	IF companies IS NOT NULL AND companiesLength > 1
		THEN BEGIN
			SET columns = JSON_EXTRACT(companies, "$.columns");
			SET columnsKeys = JSON_KEYS(columns);
			SET columnsKeysCount = JSON_LENGTH(columnsKeys);
			SET iterator = 0;
			culumnsLoop: LOOP
				IF iterator >= columnsKeysCount OR templateSuccess = 0
					THEN LEAVE culumnsLoop;
				END IF;
				SET columnLetters = JSON_UNQUOTE(JSON_EXTRACT(columnsKeys, CONCAT("$[", iterator, "]")));
				SET TemplateColumnName = JSON_UNQUOTE(JSON_EXTRACT(columns, CONCAT("$.", columnLetters)));
				SET templateID = (SELECT template_id FROM template_columns_view WHERE template_column_name = TemplateColumnName AND template_column_letters = columnLetters);
				IF iterator = 0 
					THEN SET oldTemplateID = templateID;
				END IF;
				IF templateID IS NULL OR templateID != oldTemplateID
					THEN SET templateSuccess = 0;
				END IF;
				SET iterator = iterator + 1;
				ITERATE culumnsLoop;
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
					SET responce = JSON_OBJECT(
						"message", CONCAT("added ", companiesLength - 1 - deleteCount, " companies in the base")
					);
				END;
			END IF;
		END;
	END IF;
END