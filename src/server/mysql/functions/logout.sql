BEGIN
	DECLARE connectionValid TINYINT(1);
	DECLARE connectionApiID VARCHAR(128);
	DECLARE userID, connectionID, bankID INT(11);
	DECLARE responce JSON;
	SET responce = JSON_ARRAY();
	SET connectionValid = checkConnection(connectionHash);
	SELECT user_id, connection_api_id, connection_id, bank_id INTO userID, connectionApiID, connectionID, bankID FROM users_connections_view WHERE connection_hash = connectionHash;
	IF connectionValid
		THEN BEGIN
			UPDATE connections SET user_id = NULL WHERE connection_id = connectionID;
			UPDATE users SET user_auth = 0 WHERE user_id = userID;
			SET responce = JSON_MERGE(responce, 
				JSON_OBJECT(
					"type", "sendToSocket",
					"data", JSON_OBJECT(
						"socketID", connectionApiID,
						"data", JSON_ARRAY(JSON_OBJECT(
							"type", "set",
							"data", JSON_OBJECT(
								"auth", 0,
								"try", 1,
								"loginMessage", "Вы успешно вышли из системы",
								"connectionHash", connectionHash
							)
						))
					)
				),
				JSON_OBJECT(
					"type", "procedure",
					"data", JSON_OBJECT(
						"query", "refreshBankSupervisors",
						"values", JSON_ARRAY(
							bankID
						)
					)
				)
			);
			SET responce = JSON_MERGE(responce, sendToAllUserSockets(userID, JSON_ARRAY(JSON_OBJECT(
				"type", "set",
				"data", JSON_OBJECT(
					"auth", 0,
					"try", 1,
					"loginMessage", "Был произведен выход из другого места.",
					"connectionHash", connectionHash
				)
			))));
		END;
		ELSE SET responce = JSON_MERGE(responce, JSON_OBJECT(
			"type", "sendToSocket",
			"data", JSON_OBJECT(
				"socketID", connectionApiID,
				"data", JSON_ARRAY(JSON_OBJECT(
					"type", "set",
					"data", JSON_OBJECT(
						"auth", 0,
						"try", 1,
						"loginMessage", "Требуется ручной вход в систему",
						"connectionHash", connectionHash
					)
				))
			)
		));
	END IF;
	RETURN responce;
END