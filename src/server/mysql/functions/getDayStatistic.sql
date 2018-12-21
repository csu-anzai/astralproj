BEGIN	
	DECLARE done TINYINT(1);
	DECLARE translateTo, searchResult, searchResult2 VARCHAR(128);
	DECLARE userName VARCHAR(64);
	DECLARE userID, countLength, companyBanksLength,bankTypesLength, iterator, companyBankType, userObjectBanksTypeCount INT(11);
	DECLARE responce, userObject, typesArray, companyBanksTypes, companyBank, userObjectBanksTypes JSON;
	DECLARE companiesCursor CURSOR FOR SELECT translate_to, user_name, user_id, count FROM day_statistic_view;
	DECLARE statusesCursor CURSOR FOR SELECT user_id, jsonRemoveNulls(company_json ->> "$.company_banks.*.type_id") FROM companies WHERE DATE(company_date_update) = DATE(NOW()) AND JSON_LENGTH(jsonRemoveNulls(company_json ->> "$.company_banks.*.type_id")) > 0 AND user_id IS NOT NULL AND type_id = 13;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
	SET responce = JSON_ARRAY();
	OPEN companiesCursor;
		companiesLoop: LOOP
			FETCH companiesCursor INTO translateTo, userName, userID, countLength;
			IF done 
				THEN LEAVE companiesLoop;
			END IF;
			SET searchResult = REPLACE(JSON_UNQUOTE(JSON_SEARCH(responce, "one", CONCAT(userID), NULL, "$[*].user_id")), ".user_id", "");
			IF searchResult IS NULL
				THEN SET responce = JSON_MERGE(responce, JSON_OBJECT(
					"user_id", CONCAT(userID),
					"user_name", userName,
					"types", JSON_ARRAY(JSON_OBJECT(
						"type_name", translateTo,
						"count", countLength
					)),
					"bank_types", JSON_ARRAY()
				));
				ELSE BEGIN 
					SET userObject = JSON_UNQUOTE(JSON_EXTRACT(responce, searchResult));
					SET typesArray = JSON_UNQUOTE(JSON_EXTRACT(userObject, "$.types"));
					SET userObject = JSON_SET(userObject, "$.types", JSON_MERGE(typesArray, JSON_OBJECT(
						"type_name", translateTo,
						"count", countLength
					)));
					SET responce = JSON_SET(responce, searchResult, userObject);
				END;
			END IF;
			SET done = 0;
			ITERATE companiesLoop;
		END LOOP;
	CLOSE companiesCursor;
	SET done = 0;
	OPEN statusesCursor;
		statusesLoop: LOOP
			FETCH statusesCursor INTO userID, companyBanksTypes;
			IF done 
				THEN LEAVE statusesLoop;
			END IF;
			SET searchResult = REPLACE(JSON_UNQUOTE(JSON_SEARCH(responce, "one", CONCAT(userID), NULL, "$[*].user_id")), ".user_id", "");
			SET userObject = JSON_UNQUOTE(JSON_EXTRACT(responce, searchResult));
			SET userObjectBanksTypes = JSON_UNQUOTE(JSON_EXTRACT(userObject, "$.bank_types"));
			SET iterator = 0;
			SET bankTypesLength = JSON_LENGTH(companyBanksTypes);
			bankTypesLoop: LOOP
				IF iterator >= bankTypesLength
					THEN LEAVE bankTypesLoop;
				END IF;
				SET companyBankType = JSON_UNQUOTE(JSON_EXTRACT(companyBanksTypes, CONCAT("$[", iterator, "]")));
				SET searchResult2 = REPLACE(JSON_UNQUOTE(JSON_SEARCH(userObjectBanksTypes, "one", CONCAT(companyBankType), NULL, "$[*].type_id")), ".type_id", "");
				IF searchResult2 IS NULL
					THEN SET userObjectBanksTypes = JSON_MERGE(userObjectBanksTypes, JSON_OBJECT(
						"type_id", CONCAT(companyBankType),
						"count", 1
					));
					ELSE BEGIN
						SET userObjectBanksTypeCount = JSON_UNQUOTE(JSON_EXTRACT(userObjectBanksTypes, CONCAT(searchResult2, ".count")));
						SET userObjectBanksTypeCount = userObjectBanksTypeCount + 1;
						SET userObjectBanksTypes = JSON_SET(userObjectBanksTypes, CONCAT(searchResult2, ".count"), userObjectBanksTypeCount);
					END;
				END IF;
				SET iterator = iterator + 1;
				ITERATE bankTypesLoop;
			END LOOP;
			SET userObject = JSON_SET(userObject, "$.bank_types", userObjectBanksTypes);
			SET responce = JSON_SET(responce, searchResult, userObject);
			SET done = 0;
			ITERATE statusesLoop;
		END LOOP;
	CLOSE statusesCursor;
	RETURN responce;
END