BEGIN
	DECLARE userID, typeID INT(11);
	DECLARE connectionValid TINYINT(1);
	DECLARE connectionApiID VARCHAR(128);
	DECLARE responce JSON;
	SET connectionValid = checkConnection(connectionHash);
	SELECT connection_api_id, user_id INTO connectionApiID, userID FROM users_connections_view WHERE connection_hash = connectionHash;
	SET responce = JSON_ARRAY();
	IF connectionValid
		THEN BEGIN
			SET typeID = IF(companyValidation, 13, 14);
			UPDATE companies SET type_id = typeID WHERE company_id = companyID AND user_id = userID;
			SET responce = JSON_MERGE(responce, JSON_OBJECT(
				"type", "sendToSocket",
				"data", JSON_OBJECT(
					"socketID", connectionApiID,
					"data", JSON_ARRAY(
						JSON_OBJECT(
							"type", "updateArray",
							"data", JSON_OBJECT(
								"name", "companies",
								"search", JSON_OBJECT(
									"companyID", companyID
								), 
								"values", JSON_ARRAY(
									"typeID", typeID
								)
							)
						)
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
						"loginMessage", "Требуется вход ручной вход в систему"
					)
				))
			)
		));
	END IF;
	RETURN responce;
END