BEGIN
	DECLARE connectionValid, done, translateDone TINYINT(1);
	DECLARE responce, companies, company, companyKeys, translateNames, companyArray JSON;
	DECLARE fileID, iterator, keysLength INT(11);
	DECLARE keyName, translateTo, connectionApiID VARCHAR(128);
	DECLARE userID INT(11) DEFAULT (SELECT user_id FROM connections WHERE connection_hash = connectionHash);
	DECLARE companiesCursor CURSOR FOR SELECT company_json FROM companies WHERE user_id = userID AND type_id = 20;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
	SET responce = JSON_ARRAY();
	SET connectionValid = checkRootConnection(connectionHash);
	SELECT connection_api_id INTO connectionApiID FROM connections WHERE connection_hash = connectionHash;
	IF connectionValid 
		THEN BEGIN
			SET companies = JSON_ARRAY();
			SET translateNames = JSON_ARRAY();
			INSERT INTO files (type_id, user_id) VALUES (22, userID);
			SELECT file_id INTO fileID FROM files WHERE user_id = userID AND type_id = 22 ORDER BY file_id DESC LIMIT 1;
			SET done = 0;
			SET translateDone = 0;
			OPEN companiesCursor;
				companiesLoop: LOOP
					FETCH companiesCursor INTO company;
					IF done
						THEN LEAVE companiesLoop;
					END IF;
					SET company = JSON_REMOVE(company, 
						"$.cityID",
						"$.companyID",
						"$.regionID",
						"$.templateID",
						"$.typeID"
					);
					SET companyKeys = JSON_KEYS(company);
					SET iterator = 0;
					SET keysLength = JSON_LENGTH(companyKeys);
					SET companyArray = JSON_ARRAY();
					companyKeysLoop: LOOP
						IF iterator >= keysLength
							THEN LEAVE companyKeysLoop;
						END IF;
						SET keyName = JSON_EXTRACT(companyKeys, CONCAT("$[", iterator, "]"));
						SET companyArray = JSON_MERGE(companyArray, JSON_ARRAY(JSON_EXTRACT(company, CONCAT("$.", keyName))));
						IF !translateDone
							THEN BEGIN
								SELECT translate_to INTO translateTo FROM translates WHERE translate_from = keyName;
								SET translateNames = JSON_MERGE(translateNames, JSON_ARRAY(translateTo));
							END;
						END IF;
						SET iterator = iterator + 1;
						ITERATE companyKeysLoop;
					END LOOP;
					IF !translateDone
						THEN BEGIN
							SET translateDone = 1;
							SET companies = JSON_MERGE(companies, JSON_ARRAY(translateNames));
						END;
					END IF;
					SET companies = JSON_MERGE(companies, JSON_ARRAY(companyArray));
					ITERATE companiesLoop;
				END LOOP;
			CLOSE companiesCursor;
			UPDATE companies SET type_id = 22 WHERE user_id = userID AND type_id = 20;
			SET responce = JSON_MERGE(responce, JSON_OBJECT(
				"type", "xlsxCreate",
				"data", JSON_OBJECT(
					"name", DATE(NOW()),
					"data", companies
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
	RETURN responce;
END