BEGIN
	DECLARE userID, typeID, bankID INT(11);
	DECLARE connectionValid TINYINT(1);
	DECLARE connectionApiID VARCHAR(128);
	DECLARE responce JSON;
	SET connectionValid = checkConnection(connectionHash);
	SELECT connection_api_id, user_id, bank_id INTO connectionApiID, userID, bankID FROM users_connections_view WHERE connection_hash = connectionHash;
	SET responce = JSON_ARRAY();
	IF connectionValid
		THEN BEGIN
			SET typeID = IF(companyValidation, 13, 14);
			UPDATE companies SET type_id = typeID WHERE company_id = companyID AND user_id = userID;
			SET responce = JSON_MERGE(responce, sendToAllUserSockets(userID, JSON_ARRAY(
				JSON_OBJECT(
					"type", "updateArray",
					"data", JSON_OBJECT(
						"name", "companies",
						"search", JSON_OBJECT(
							"company_id", companyID
						), 
						"values", JSON_OBJECT(
							"type_id", typeID
						)
					)
				),
				JSON_OBJECT(
					"type", "merge",
					"data", JSON_OBJECT(
						"message", ""
					)
				)
			)));
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