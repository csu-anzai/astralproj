BEGIN
	DECLARE userID INT(11);
	DECLARE connectionValid, oldRinging TINYINT(1);
	DECLARE responce JSON;
	SET responce = JSON_ARRAY();
	SET connectionValid = checkConnection(connectionHash);
	IF connectionValid 
		THEN BEGIN
			SELECT user_id INTO userID FROM connections WHERE connection_hash = connectionHash;
			SELECT user_ringing INTO oldRinging FROM users WHERE user_id = userID;
			IF ringing != oldRinging
				THEN BEGIN
					UPDATE users SET user_ringing = ringing WHERE user_id = userID;
					UPDATE companies SET company_ringing = 0 WHERE user_id = userID AND type_id IN (9, 35);
					SET responce = JSON_MERGE(responce, sendToAllUserSockets(userID, JSON_ARRAY(
						JSON_OBJECT(
							"type", "merge",
							"data", JSON_OBJECT(
								"ringing", ringing
							)
						)
					)));
				END;
			END IF;
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