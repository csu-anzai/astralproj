BEGIN
	DECLARE companiesLength, companiesCount, bankID INT(11);
	DECLARE connectionHash VARCHAR(32);
	DECLARE responce JSON;
	SET responce = JSON_ARRAY();
	SET companiesLength = JSON_LENGTH(companiesArray);
	IF companiesLength > 0
		THEN BEGIN
			SELECT COUNT(*) INTO companiesCount FROM companies WHERE user_id = userID AND type_id = 44;
			UPDATE companies SET type_id = 24 WHERE JSON_CONTAINS(companiesArray, CONCAT(company_id));
			UPDATE companies SET type_id = 9 WHERE user_id = userID AND type_id = 44;
			SET responce = JSON_MERGE(responce, JSON_ARRAY(
				JSON_OBJECT(
					"type", "print",
					"data", JSON_OBJECT(
						"message", CONCAT(companiesLength, "/", companiesCount, " дубликаты")
					)
				)
			));
			SELECT bank_id, connection_hash INTO bankID, connectionHash FROM users_connections_view WHERE user_id = userID AND connection_end = 0 LIMIT 1;
			SET responce = JSON_MERGE(responce, getBankCompanies(connectionHash, bankID, companiesLength, 0));
		END;
		ELSE BEGIN
			UPDATE companies SET type_id = 9 WHERE user_id = userID AND type_id = 44;
			SET responce = JSON_MERGE(responce, refreshUserCompanies(userID));
			SET responce = JSON_MERGE(responce, sendToAllUserSockets(userID, JSON_ARRAY(JSON_OBJECT(
				"type", "merge",
				"data", JSON_OBJECT(
					"message", CONCAT("Рабочий список сброшен и обновлён."),
					"messageType", "success"
				)
			))));					
		END;
	END IF;
	RETURN responce;
END