BEGIN
	DECLARE callID, userID, companyTypeID, bankID, callCount, companyID INT(11);
	DECLARE typeTranslate VARCHAR(128);
	DECLARE nextPhone VARCHAR(120);
	DECLARE ringing TINYINT(1);
	DECLARE responce JSON;
	SET responce = JSON_ARRAY();
	SELECT call_id, user_id INTO callID, userID FROM active_calls_view WHERE company_phone = companyPhone AND user_sip = userSip ORDER BY call_id DESC LIMIT 1;
	SELECT tr.translate_to INTO typeTranslate FROM translates tr JOIN types t ON t.type_id = typeID AND t.type_name = tr.translate_from;
	UPDATE calls SET 
		type_id = typeID, 
		call_api_id_1 = IF(call_api_id_1 IS NULL AND (call_api_id_2 IS NULL OR call_api_id_2 != callApiID), callApiID, call_api_id_1), 
		call_api_id_2 = IF(call_api_id_2 IS NULL AND (call_api_id_1 IS NULL OR call_api_id_1 != callApiID), callApiID, call_api_id_2),
		call_api_id_with_rec = callApiIDWithRec
	WHERE call_id = callID;
	SELECT type_id, bank_id INTO companyTypeID, bankID FROM companies WHERE call_id = callID;
	IF companyTypeID = 36 AND bankID
		THEN SET responce = JSON_MERGE(responce, refreshUsersCompanies(bankID));
		ELSE SET responce = JSON_MERGE(responce, refreshUserCompanies(userID));
	END IF;
	SET responce = JSON_MERGE(responce, sendToAllUserSockets(userID, JSON_ARRAY(JSON_OBJECT(
		"type", "mergeDeep",
		"data", JSON_OBJECT(
			"message", CONCAT("соединение с ", companyPhone, " имеет статус: ", typeTranslate),
			"messageType", IF(typeID NOT IN (40, 41, 42), "success", "error")
		)
	))));
	IF companyTypeID IN (9, 35) AND typeID IN (40, 41, 42)
		THEN BEGIN
			SELECT user_ringing INTO ringing FROM users WHERE user_id = userID;
			IF ringing = 1
				THEN BEGIN
					SELECT COUNT(*) INTO callCount FROM calls WHERE user_id = userID AND type_id NOT IN (40, 41, 42);
					IF callCount = 0
						THEN BEGIN
							SELECT REPLACE(company_phone, "+", ""), company_id INTO nextPhone, companyID FROM companies WHERE user_id = userID AND type_id IN (9, 35) AND company_ringing = 0 ORDER BY type_id LIMIT 1;
							IF type_namextPhone IS NOT NULL
								THEN BEGIN
									INSERT INTO calls (user_id, company_id, type_id) VALUES (userID, companyID, 33);
									SET responce = JSON_MERGE(responce, refreshUserCompanies(userID));
									SET responce = JSON_MERGE(responce, JSON_OBJECT(
										"type", "sendToZadarma",
										"data", JSON_OBJECT(
											"options", JSON_OBJECT(
												"from", userSip,
												"to", nextPhone,
												"predicted", true
											),
											"method", "request/callback",
											"type", "GET"
										)
									));
									UPDATE companies SET company_ringing = 1 WHERE company_id = companyID;
								END;
							END IF;
						END;
					END IF;
				END;
			END IF;
		END;
	END IF;
	RETURN responce;
END