BEGIN
	DECLARE connectionValid TINYINT(1);
	DECLARE callID, userID, typeID, bankID INT(11);
	DECLARE responce JSON;
	SET responce = JSON_ARRAY();
	SET connectionValid = checkConnection(connectionHash);
	IF connectionValid
		THEN BEGIN
			SELECT call_id, user_id, type_id, bank_id INTO callID, userID, typeID, bankID FROM companies WHERE company_id = companyID;
			IF callID IS NOT NULL
				THEN BEGIN
					UPDATE calls SET call_destination_type_id = 42, call_internal_type_id = 42 WHERE call_id = callID;
					IF typeID = 36
						THEN SET responce = JSON_MERGE(responce, refreshUsersCompanies(bankID));
						ELSE SET responce = JSON_MERGE(responce, refreshUserCompanies(userID));
					END IF;
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