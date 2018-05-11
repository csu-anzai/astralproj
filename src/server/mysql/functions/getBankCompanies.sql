BEGIN
	DECLARE companyID, companiesLength, connectionID, userID, timeID INT(11);
	DECLARE connectionValid TINYINT(1);
	DECLARE connectionApiID VARCHAR(128);
	DECLARE responce, companiesArray JSON;
	SET connectionValid = checkConnection(connectionHash);
	SELECT connection_api_id, connection_id, user_id INTO connectionApiID, connectionID, userID FROM users_connections_view WHERE connection_hash = connectionHash;
	SET responce = JSON_ARRAY();
	IF connectionValid
		THEN BEGIN
			SET timeID = getTimeID(bankID);
			UPDATE companies SET user_id = NULL, type_id = 10 WHERE user_id = userID AND type_id IN (9, 35);
			UPDATE companies c JOIN (SELECT company_id FROM (SELECT company_id FROM bank_cities_time_priority_companies_view WHERE type_id = 10 AND old_type_id = 36 AND weekday(company_date_update) = weekday(now()) AND time_id = timeID AND bank_id = bankID ORDER BY company_date_create DESC) dialing_companies UNION SELECT company_id FROM bank_cities_time_priority_companies_view WHERE bank_id = bankID AND date(company_date_create) = date(now()) AND time_id = timeID AND user_id IS NULL AND type_id = 10 AND (old_type_id IS NULL OR old_type_id != 36) LIMIT rows) bc on bc.company_id = c.company_id SET c.user_id = userID, c.type_id = 9;
			SET companiesArray = getActiveBankUserCompanies(connectionID);
			SET companiesLength = JSON_LENGTH(companiesArray);
			SET responce = JSON_MERGE(responce, sendToAllUserSockets(userID, JSON_ARRAY(JSON_OBJECT(
				"type", "merge",
				"data", JSON_OBJECT(
					"companies", companiesArray,
					"messageType", IF(companiesLength > 0, "success", "error"),
					"message", IF(companiesLength > 0, CONCAT("Загружено компаний: ", companiesLength), CONCAT("Не удалось найти ни одной компании для сортировки на данное время"))
				)
			))));
			SET responce = JSON_MERGE(responce, JSON_OBJECT(
				"type", "procedure",
				"data", JSON_OBJECT(
					"query", "refreshBankSupervisors",
					"values", JSON_ARRAY(
						bankID
					)
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