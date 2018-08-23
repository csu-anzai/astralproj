BEGIN
	DECLARE interator, companiesLength, userID, typeID, companyID, usersLength INT(11);
	DECLARE applicationID VARCHAR(128);
	DECLARE responce, company, users JSON;
	SET responce = JSON_ARRAY();
	SET users = JSON_ARRAY();
	SET companiesLength = JSON_LENGTH(companies);
	SET interator = 0;
	companiesLoop: LOOP
		IF interator >= companiesLength
			THEN LEAVE companiesLoop;
		END IF;
		SET company = JSON_EXTRACT(companies, CONCAT("$[", interator, "]"));
		SET typeID = JSON_UNQUOTE(JSON_EXTRACT(company, "$.type_id"));
		SET applicationID = JSON_UNQUOTE(JSON_EXTRACT(company, "$.company_application_id"));
		SELECT user_id, company_id INTO userID, companyID FROM companies WHERE company_application_id = applicationID;
		UPDATE LOW_PRIORITY IGNORE companies SET type_id = typeID WHERE company_id = companyID;
		IF JSON_CONTAINS(users, CONCAT(userID)) = 0
			THEN SET users = JSON_MERGE(users, CONCAT(userID));
		END IF;
		SET interator = interator + 1;
		ITERATE companiesLoop;
	END LOOP;
	SET usersLength = JSON_LENGTH(users);
	IF usersLength > 0
		THEN BEGIN
			SET interator = 0;
			usersLoop: LOOP
				IF interator >= usersLength
					THEN LEAVE usersLoop;
				END IF;
				SET userID = JSON_UNQUOTE(JSON_EXTRACT(users, CONCAT("$[", interator, "]")));
				SET responce = JSON_MERGE(responce, refreshUserCompanies(userID));
				SET responce = JSON_MERGE(responce, sendToAllUserSockets(userID, JSON_ARRAY(JSON_OBJECT(
					"type", "mergeDeep",
					"data", JSON_OBJECT(
						"message", "статусы компаний обновлены",
						"messageType", "success"
					)
				))));
				SET interator = interator + 1;
				ITERATE usersLoop;
			END LOOP;
		END;
	END IF;
	SET responce = JSON_MERGE(responce, JSON_OBJECT(
		"type", "print",
		"data", JSON_OBJECT(
			"message", CONCAT(companiesLength, " компаний успешно обработаны")
		)
	));
	RETURN responce;
END