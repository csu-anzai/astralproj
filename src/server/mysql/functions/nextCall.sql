BEGIN
	DECLARE connectionApiID VARCHAR(120);
	DECLARE companyID, userID INT(11);
	DECLARE validConnection TINYINT(1);
	DECLARE userSip VARCHAR(20);
	DECLARE companyPhone VARCHAR(120);
	DECLARE responce JSON;
	SET responce = JSON_ARRAY();
	SET validConnection = checkConnection(connectionHash);
	SELECT user_id, connection_api_id INTO userID, connectionApiID FROM connections WHERE connection_hash = connectionHash;
	IF validConnection 
		THEN BEGIN
			SELECT user_sip INTO userSip FROM users WHERE user_id = userID;
			SELECT company_json ->> "$.company_id" INTO companyID FROM working_user_company_view WHERE user_id = userID LIMIT 1;
			IF companyID IS NOT NULL 
				THEN UPDATE companies SET company_ringing = 1 WHERE company_id = companyID;
			END IF;
			SELECT company_phone, company_id INTO companyPhone, companyID FROM companies WHERE user_id = userID AND type_id IN (9, 35) AND company_ringing = 0 ORDER BY type_id ASC, company_date_registration DESC, company_date_create DESC LIMIT 1;
			IF companyPhone IS NOT NULL
				THEN BEGIN 
					INSERT INTO calls (user_id, company_id, call_internal_type_id, call_destination_type_id, call_predicted) VALUES (userID, companyID, 33, 33, 1);
					UPDATE users SET user_ringing = 1 WHERE user_id = userID;
					SET responce = JSON_MERGE(responce, JSON_OBJECT(
						"type", "sendToZadarma",
						"data", JSON_OBJECT(
							"options", JSON_OBJECT(
								"from", userSip,
								"to", companyPhone,
								"predicted", 1
							),
							"method", "request/callback",
							"type", "GET"
						)
					));
					SET responce = JSON_MERGE(responce, refreshUserCompanies(userID));
					SET responce = JSON_MERGE(responce, sendToAllUserSockets(userID, JSON_ARRAY(JSON_OBJECT(
						"type", "mergeDeep",
						"data", JSON_OBJECT(
							"message", CONCAT("соединение с ", companyPhone, " имеет статус: ожидание ответа от АТС")
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