BEGIN
	DECLARE connectionApiID VARCHAR(128);
	DECLARE typeID, bankID, userID INT(11);
	DECLARE connectionValid TINYINT(1);
	DECLARE responce JSON;
	SET responce = JSON_ARRAY();
	SET connectionValid = checkConnection(connectionHash);
	SELECT connection_api_id, user_id INTO connectionApiID, userID FROM connections WHERE connection_hash = connectionHash; 
	IF connectionValid
		THEN BEGIN
			SELECT type_id, bank_id INTO typeID, bankID FROM companies WHERE company_id = companyID;
			DELETE FROM companies WHERE company_id = companyID;
			IF typeID = 36
				THEN SET responce = JSON_MERGE(responce, refreshUsersCompanies(bankID));
				ELSE BEGIN 
					SET responce = JSON_MERGE(responce, refreshUserCompanies(userID));
					SET responce = JSON_MERGE(responce, sendToAllUserSockets(userID, JSON_ARRAY(JSON_OBJECT(
						"type", "mergeDeep",
						"data", JSON_OBJECT(
							"message", "компания успешно удалена",
							"messageType", "success"
						)
					))));
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