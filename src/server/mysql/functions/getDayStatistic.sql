BEGIN	
	DECLARE done TINYINT(1);
	DECLARE translateTo, searchResult, searchResult2, bankName VARCHAR(128);
	DECLARE userName VARCHAR(64);
	DECLARE userID, countLength, companyBanksLength, bankTypesLength, iterator, companyBankType, userObjectBanksTypeCount INT(11);
	DECLARE responce, userObject, typesArray, companyBanks, companyBank, userObjectBanks JSON;
	DECLARE companiesCursor CURSOR FOR SELECT translate_to, user_name, user_id, count FROM day_types_statistic_view;
	DECLARE statusesCursor CURSOR FOR SELECT user_id, bank_name, count FROM day_banks_statistic_view;
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
					"banks", JSON_ARRAY()
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
			FETCH statusesCursor INTO userID, bankName, countLength;
			IF done 
				THEN LEAVE statusesLoop;
			END IF;
			SET searchResult = REPLACE(JSON_UNQUOTE(JSON_SEARCH(responce, "one", CONCAT(userID), NULL, "$[*].user_id")), ".user_id", "");
			SET userObject = JSON_UNQUOTE(JSON_EXTRACT(responce, searchResult));
			SET userObjectBanks = JSON_UNQUOTE(JSON_EXTRACT(userObject, "$.banks"));
			SET userObjectBanks = JSON_MERGE(userObjectBanks, JSON_OBJECT(
				"bank_name", bankName,
				"count", countLength
			));
			SET userObject = JSON_SET(userObject, "$.banks", userObjectBanks);
			SET responce = JSON_SET(responce, searchResult, userObject);
			ITERATE statusesLoop;
		END LOOP;
	CLOSE statusesCursor;
	RETURN responce;
END