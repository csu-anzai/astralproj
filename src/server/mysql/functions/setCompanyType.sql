BEGIN
	DECLARE userID, bankID, connectionID, lastTypeID INT(11);
	DECLARE connectionValid TINYINT(1);
	DECLARE connectionApiID VARCHAR(128);
	DECLARE responce JSON;
	SET connectionValid = checkConnection(connectionHash);
	SELECT connection_api_id, user_id, bank_id, connection_id INTO connectionApiID, userID, bankID, connectionID FROM users_connections_view WHERE connection_hash = connectionHash;
	SET responce = JSON_ARRAY();
	IF connectionValid
		THEN BEGIN
			SELECT type_id INTO lastTypeID FROM companies WHERE company_id = companyID;
			IF typeID = 23
				THEN UPDATE companies SET type_id = typeID, company_date_call_back = dateParam, user_id = userID, company_date_update = NOW() WHERE company_id = companyID;
				ELSE UPDATE companies SET type_id = typeID, user_id = userID, company_date_update = NOW() WHERE company_id = companyID;
			END IF;
			IF typeID = 36 OR lastTypeID = 36 
				THEN SET responce = JSON_MERGE(responce, refreshUsersCompanies(bankID));
				ELSE SET responce = JSON_MERGE(responce, refreshUserCompanies(userID));
			END IF;
			SET responce = JSON_MERGE(responce, JSON_ARRAY(
				JSON_OBJECT(
					"type", "sendToSocket",
					"data", JSON_OBJECT(
						"socketID", connectionApiID,
						"data", JSON_ARRAY(
							JSON_OBJECT(
								"type", "merge",
								"data", JSON_OBJECT(
									"message", ""
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
						"loginMessage", "Требуется ручной вход в систему"
					)
				))
			)
		));
	END IF;
	RETURN responce;
END