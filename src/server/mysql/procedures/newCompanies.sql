BEGIN
	DECLARE templateID, oldTemplateID, iterator, iterator2, columnsKeysCount, companiesLength INT(11);
	DECLARE templateSuccess TINYINT(1);
	DECLARE TemplateColumnName, columnName VARCHAR(128);
	DECLARE columnLetters VARCHAR(3);
	DECLARE columns, columnsKeys, company JSON;
	SET responce = JSON_ARRAY();
	SET templateSuccess = 1;
	SET companiesLength = JSON_LENGTH(companies);
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
						SELECT column_name INTO columnName FROM template_columns_view WHERE template_id = templateID AND template_column_letters = columnLetters;
						SET @newCompaniesQuery = CONCAT(@newCompaniesQuery, IF(iterator > 0, ",", ""), columnName);
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
							SET columnLetters = JSON_UNQUOTE(JSON_EXTRACT(columnsKeys, CONCAT("$[", iterator2, "]")));
							SET @newCompaniesQuery = CONCAT(@newCompaniesQuery, IF(iterator2 > 0, ",", ""), IF(JSON_EXTRACT(company, CONCAT("$.", columnLetters)) IS NULL, "NULL", JSON_EXTRACT(company, CONCAT("$.", columnLetters))));
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
					SET responce = JSON_MERGE(responce, JSON_OBJECT(
						"type", "print",
						"data", JSON_OBJECT(
							"message", "all items save in base"
						)
					));
				END;
			END IF;
		END;
	END IF;
END