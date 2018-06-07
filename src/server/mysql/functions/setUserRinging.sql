BEGIN
	DECLARE userID INT(11);
	DECLARE connectionValid TINYINT(1);
	DECLARE responce JSON;
	SET responce = JSON_ARRAY();
	SET connectionValid = checkConnection(connectionHash);
	IF connectionValid 
		THEN BEGIN
			SELECT user_id INTO userID FROM connections WHERE connection_hash = connectionHash;
			UPDATE users SET user_ringing = ringing WHERE user_id = userID;
			SET responce = JSON_MERGE(responce, sendToAllUserSockets(userID, JSON_ARRAY(
				JSON_OBJECT(
					"type", "merge",
					"data", JSON_OBJECT(
						"ringing", ringing
					)
				)
			)));
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