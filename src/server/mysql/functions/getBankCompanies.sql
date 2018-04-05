BEGIN
	DECLARE companyID, companiesLength INT(11);
	DECLARE userID INT(11) DEFAULT (SELECT user_id FROM users_connections_view WHERE connection_hash = connectionHash);
	DECLARE timeID INT(11) DEFAULT getTimeID(1);
	DECLARE connectionApiID VARCHAR(128);
	DECLARE responce, companiesArray, company JSON;
	DECLARE done, connectionValid TINYINT(1);
	DECLARE companiesCursor CURSOR FOR SELECT company_json, company_id FROM bank_cities_time_priority_companies_view WHERE bank_id = bankID AND date(company_date_create) = date(now()) AND time_id = timeID AND user_id IS NULL LIMIT rows;
	DECLARE userCompaniesCursor CURSOR FOR SELECT DISTINCT company_json FROM bank_cities_time_priority_companies_view WHERE bank_id = bankID AND user_id = userID AND date(company_date_create) = date(now()) AND type_id != 9;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
	SET connectionValid = checkConnection(connectionHash);
	SELECT connection_api_id INTO connectionApiID FROM users_connections_view WHERE connection_hash = connectionHash;
	SET responce = JSON_ARRAY();
	IF connectionValid
		THEN BEGIN
			SET companiesArray = JSON_ARRAY();
			UPDATE companies SET user_id = NULL, type_id = 10 WHERE user_id = userID AND type_id = 9;
			SET done = 0;
			OPEN companiesCursor;
				companiesLoop: LOOP
					FETCH companiesCursor INTO company, companyID;
					IF done 
						THEN LEAVE companiesLoop;
					END IF;
					SET companiesArray = JSON_MERGE(companiesArray, company);
					UPDATE companies SET user_id = userID, type_id = 9 WHERE company_id = companyID;
					ITERATE companiesLoop;
				END LOOP;
			CLOSE companiesCursor;
			SET done = 0;
			SET companiesLength = JSON_LENGTH(companiesArray);
			OPEN userCompaniesCursor;
				userCompaniesLoop: LOOP
					FETCH userCompaniesCursor INTO company;
					IF done 
						THEN LEAVE userCompaniesLoop;
					END IF;
					SET companiesArray = JSON_MERGE(companiesArray, company);
					ITERATE userCompaniesLoop;
				END LOOP;
			CLOSE userCompaniesCursor;
			SET responce = JSON_MERGE(responce, sendToAllUserSockets(userID, JSON_ARRAY(JSON_OBJECT(
				"type", "merge",
				"data", JSON_OBJECT(
					"companies", companiesArray,
					"messageType", IF(companiesLength > 0, "success", "error"),
					"message", IF(companiesLength > 0, CONCAT("Загружено компаний для сортировки: ", companiesLength), CONCAT("Не удалось найти ни одной компании для сортировки на данное время"))
				)
			))));
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