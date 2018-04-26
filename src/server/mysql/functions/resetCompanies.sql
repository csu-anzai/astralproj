BEGIN
	DECLARE userID INT(11);
	DECLARE connectionValid TINYINT(1);
	DECLARE connectionApiID VARCHAR(128);
	DECLARE responce JSON;
	SET responce = JSON_ARRAY();
	SET connectionValid = checkConnection(connectionHash);
	SELECT connection_api_id, user_id INTO connectionApiID, userID FROM users_connections_view WHERE connection_hash = connectionHash;
	IF connectionValid
		THEN BEGIN
			UPDATE companies SET type_id = 10 AND user_id = NULL WHERE user_id = userID AND type_id = typeID;
			SET responce = JSON_MERGE(responce, sendToAllUserSockets(userID, JSON_ARRAY(JSON_OBJECT(
				"type", "merge",
				"data", JSON_OBJECT(
					"companies", getActiveBankUserCompanies(userID)
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