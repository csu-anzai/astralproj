BEGIN
	DECLARE callID, userID, companyTypeID, companyOldTypeID, bankID, callCount, companyID, typeID INT(11);
	DECLARE typeTranslate VARCHAR(128);
	DECLARE nextPhone, companyPhone VARCHAR(120);
	DECLARE ringing TINYINT(1);
	DECLARE responce JSON;
	SET responce = JSON_ARRAY();
	SELECT call_id, user_id INTO callID, userID FROM active_calls_view WHERE user_sip = userSip ORDER BY call_id DESC LIMIT 1;
	UPDATE calls SET 
		type_id = IF(
			call_api_id_internal IS NULL AND call_api_id_destination IS NULL, 
			IF(
				callApiID IS NOT NULL,
				IF(
					call_predicted = 1, 
					38, 
					34
				),
				IF(
					errorStatus = 1,
					42,
					43
				)
			), 
			IF(
				callApiID IS NOT NULL AND (call_api_id_internal IS NOT NULL OR call_api_id_destination IS NOT NULL) AND type_id IN (34, 38, 39), 
				IF(
					call_api_id_internal IS NOT NULL AND call_api_id_internal = callApiID,
					IF(
						type_id = 34,
						40,
						IF(
							errorStatus IS NOT NULL,
							39,
							38
						)
					), 
					IF(
						type_id = 38 AND call_api_id_destination IS NOT NULL AND call_api_id_destination = callApiID,
						41,
						IF(
							errorStatus IS NOT NULL,
							39,
							34
						)
					)
				),
				type_id
			)
		), 
		call_api_id_internal = IF(
			call_api_id_internal IS NULL,
			IF(
				call_predicted = 1,
				IF(
					call_api_id_destination IS NOT NULL,
					callApiID,
					call_api_id_internal
				),
				IF(
					call_api_id_destination IS NULL,
					callApiID,
					call_api_id_internal
				)
			),
			call_api_id_internal
		),
		call_api_id_destination = IF(
			call_api_id_destination IS NULL,
			IF(
				call_predicted = 1,
				IF(
					call_api_id_internal IS NULL,
					callApiID,
					call_api_id_destination
				),
				IF(
					call_api_id_internal IS NOT NULL,
					callApiID,
					call_api_id_destination
				)
			),
			call_api_id_destination
		),
		call_api_id_with_rec = IF(
			call_api_id_with_rec IS NULL AND callApiIDWithRec IS NOT NULL,
			callApiIDWithRec,
			call_api_id_with_rec
		)
	WHERE call_id = callID;
	SELECT type_id INTO typeID FROM calls WHERE call_id = callID;
	SELECT type_id, old_type_id, bank_id, company_id, company_phone INTO companyTypeID, companyOldTypeID, bankID, companyID, companyPhone FROM companies WHERE call_id = callID;
	SELECT tr.translate_to INTO typeTranslate FROM translates tr JOIN types t ON t.type_id = typeID AND t.type_name = tr.translate_from;
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
	IF companyOldTypeID IN (9, 35, 10) AND typeID IN (40, 41, 42) AND companyTypeID IN (9, 35, 36)
		THEN BEGIN
			SELECT user_ringing INTO ringing FROM users WHERE user_id = userID;
			IF ringing = 1
				THEN BEGIN
					UPDATE companies SET company_ringing = IF(type_id = 35 AND old_type_id = 9, 0, 1) WHERE company_id = companyID;
					SELECT COUNT(*) INTO callCount FROM calls WHERE user_id = userID AND type_id NOT IN (40, 41, 42);
					IF callCount = 0
						THEN BEGIN
							SELECT REPLACE(company_phone, "+", ""), company_id INTO nextPhone, companyID FROM companies WHERE user_id = userID AND type_id IN (9, 35) AND company_ringing = 0 ORDER BY type_id LIMIT 1;
							IF nextPhone IS NOT NULL
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