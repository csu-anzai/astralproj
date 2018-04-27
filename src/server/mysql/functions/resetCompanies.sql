BEGIN
	DECLARE userID, connectionID INT(11);
	DECLARE connectionValid TINYINT(1);
	DECLARE connectionApiID VARCHAR(128);
	DECLARE dateStart, dateEnd VARCHAR(19);
	DECLARE responce, filter JSON;
	SET responce = JSON_ARRAY();
	SET connectionValid = checkConnection(connectionHash);
	SELECT connection_api_id, user_id, connection_id INTO connectionApiID, userID, connectionID FROM users_connections_view WHERE connection_hash = connectionHash;
	IF connectionValid
		THEN BEGIN
			IF typeID = 14 OR typeID = 23
				THEN BEGIN 
					SELECT JSON_EXTRACT(state_json, CONCAT("$.distribution.", IF(typeID = 14, "invalidate", "callBack"))) INTO filter FROM states WHERE connection_id = connectionID;
					SET dateStart = JSON_UNQUOTE(JSON_EXTRACT(filter, "$.dateStart"));
					SET dateEnd = JSON_UNQUOTE(JSON_EXTRACT(filter, "$.dateEnd"));
				END;
				ELSE BEGIN
					SET dateStart = NOW();
					SET dateEnd = NOW();
				END;
			END IF;
			UPDATE companies SET type_id = 10 AND user_id = NULL WHERE user_id = userID AND type_id = typeID AND DATE(company_date_create) BETWEEN DATE(dateStart) AND DATE(dateEnd);
			SET responce = JSON_MERGE(responce, refreshUserCompanies(userID));
			SET responce = JSON_MERGE(responce, sendToAllUserSockets(userID, JSON_ARRAY(JSON_OBJECT(
				"type", "merge",
				"data", JSON_OBJECT(
					"message", "Список удачно очищен"
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