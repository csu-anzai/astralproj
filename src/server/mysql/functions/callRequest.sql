BEGIN
	DECLARE userID, callID, callsCount INT(11);
	DECLARE connectionValid TINYINT(1);
	DECLARE userSip VARCHAR(20);
	DECLARE connectionApiID VARCHAR(32);
	DECLARE companyPhone VARCHAR(120);
	DECLARE responce JSON;
	SET responce = JSON_ARRAY();
	SET connectionValid = checkConnection(connectionHash);
	IF connectionValid
		THEN BEGIN
			SELECT user_sip, user_id, connection_api_id INTO userSip, userID, connectionApiID FROM users_connections_view WHERE connection_hash = connectionHash;
			SELECT COUNT(*) INTO callsCount FROM active_calls_view WHERE user_id = userID;
			IF callsCount IS NOT NULL AND callsCount = 0
				THEN BEGIN
					SELECT company_phone INTO companyPhone FROM companies WHERE company_id = companyID;
					INSERT INTO calls (user_id, company_id, call_internal_type_id, call_destination_type_id, call_predicted) VALUES (userID, companyID, 33, 33, IF(predicted IS NULL, 0, predicted));
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
								"to", companyPhone,
								"predicted", predicted
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
								"message", "Вы не можете начать новый разговор, пока не закончился предыдущий",
								"messageType", "error" 
							)
						))
					)
				));
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