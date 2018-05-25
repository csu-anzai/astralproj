BEGIN
	DECLARE userID, callID INT(11);
	DECLARE connectionValid TINYINT(1);
	DECLARE userSip VARCHAR(20);
	DECLARE companyPhone VARCHAR(120);
	DECLARE responce JSON;
	SET responce = JSON_ARRAY();
	SET connectionValid = checkConnection(connectionHash);
	IF connectionValid
		THEN BEGIN
			SELECT user_sip, user_id INTO userSip, userID FROM users_connections_view WHERE connection_hash = connectionHash;
			SELECT company_phone INTO companyPhone FROM companies WHERE company_id = companyID;
			INSERT INTO calls (user_id, company_id, type_id) VALUES (userID, companyID, 33);
			SET responce = JSON_MERGE(responce, refreshUserCompanies(userID));
			SET responce = JSON_MERGE(responce, sendToAllUserSockets(userID, JSON_ARRAY(JSON_OBJECT(
				"type", "mergeDeep",
				"data", JSON_OBJECT(
					"message", CONCAT("соединение с ", companyPhone, " имеет статус: ожидание ответа от АТС")
				)
			))));
			SET responce = JSON_MERGE(responce, JSON_OBJECT(
				"type", "sendToZadarma",
				"data", JSON_OBJECT(
					"options", JSON_OBJECT(
						"from", userSip,
						"to", companyPhone
					),
					"method", "request/callback",
					"type", "GET"
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