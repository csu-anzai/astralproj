BEGIN
	DECLARE callID, userID, companyTypeID, companyOldTypeID, callCount, companyID, callInternalTypeID, callDestinationTypeID INT(11);
	DECLARE typeTranslate VARCHAR(128);
	DECLARE nextPhone, companyPhone VARCHAR(120);
	DECLARE ringing, notDial, callEnd, callProcess TINYINT(1);
	DECLARE responce JSON;
	SET responce = JSON_ARRAY();
	SELECT call_id, user_id INTO callID, userID FROM calls_view WHERE user_sip = userSip OR call_api_id_internal = callApiID OR call_api_id_destination = callApiID ORDER BY call_id DESC LIMIT 1;
	SELECT user_sip, user_ringing INTO userSip, ringing FROM users WHERE user_id = userID;
	UPDATE calls SET 
		call_internal_type_id = IF(
			(
				call_api_id_internal IS NOT NULL AND 
				call_api_id_internal = callApiID
			) OR 
			(
				call_api_id_internal IS NULL AND (
					(
						call_api_id_destination IS NULL AND 
						call_predicted = 0
					) OR (
						call_api_id_destination IS NOT NULL AND 
						call_api_id_destination != callApiID
					)
				)
			),
			typeID,
			call_internal_type_id
		),
		call_destination_type_id = IF(
			(
				call_api_id_destination IS NOT NULL AND 
				call_api_id_destination = callApiID
			) OR 
			(
				call_api_id_destination IS NULL AND (
					(
						call_api_id_internal IS NULL AND 
						call_predicted = 1
					) OR (
						call_api_id_internal IS NOT NULL AND 
						call_api_id_internal != callApiID
					)
				)
			),
			typeID,
			call_destination_type_id
		),
		call_api_id_internal = IF(
			call_api_id_internal IS NULL AND 
			((
				call_api_id_destination IS NULL AND
				call_predicted = 0
			) OR (
				call_api_id_destination IS NOT NULL AND
				call_api_id_destination != callApiID
			)),
			callApiID,
			call_api_id_internal
		),
		call_api_id_destination = IF(
			call_api_id_destination IS NULL AND 
			((
				call_api_id_internal IS NULL AND
				call_predicted = 1
			) OR (
				call_api_id_internal IS NOT NULL AND 
				call_api_id_internal != callApiID
			)),
			callApiID,
			call_api_id_destination
		),
		call_internal_api_id_with_rec = IF(
			call_api_id_internal = callApiID,
			callApiIDWithRec,
			call_internal_api_id_with_rec
		),
		call_destination_api_id_with_rec = IF(
			call_api_id_destination = callApiID,
			callApiIDWithRec,
			call_destination_api_id_with_rec
		)
	WHERE call_id = callID;
	SELECT call_internal_type_id, call_destination_type_id, company_id INTO callInternalTypeID, callDestinationTypeID, companyID FROM calls WHERE call_id = callID;
	SET callEnd = IF(callDestinationTypeID IN (38,40,41,42,46,47,48,49,50,51,52,53,33) AND callInternalTypeID IN (38,40,41,42,46,47,48,49,50,51,52,53,33), 1, 0);
	SET callProcess = IF(callDestinationTypeID = 34, 1, 0);
	SET notDial = IF((callInternalTypeID IN (42,47,48,49,50) OR callDestinationTypeID IN (42,47,48,49,50)) AND callEnd = 1, 1, 0);
	UPDATE companies SET type_id = IF(notDial = 1, IF(type_id = 9, 35, 36), IF(type_id IN (35, 36) AND callEnd = 1, 9, type_id)), company_ringing = IF(ringing = 1 AND callEnd = 1, IF(type_id = 35, 0, 1), 0) WHERE company_id = companyID;
	SELECT type_id, old_type_id, company_id, company_phone INTO companyTypeID, companyOldTypeID, companyID, companyPhone FROM companies WHERE call_id = callID;
	SELECT tr.translate_to INTO typeTranslate FROM translates tr JOIN types t ON t.type_id = typeID AND t.type_name = tr.translate_from;
	IF companyTypeID = 36
		THEN SET responce = JSON_MERGE(responce, refreshUsersCompanies());
		ELSE SET responce = JSON_MERGE(responce, refreshUserCompanies(userID));
	END IF;
	SET responce = JSON_MERGE(responce, sendToAllUserSockets(userID, JSON_ARRAY(JSON_OBJECT(
		"type", "mergeDeep",
		"data", JSON_OBJECT(
			"message", CONCAT("соединение с ", companyPhone, " имеет статус: ", typeTranslate),
			"messageType", IF(typeID IN (39, 33, 34, 43), "success", "error")
		)
	))));
	IF callProcess = 1 AND callEnd = 0 
		THEN BEGIN 
			UPDATE users SET user_ringing = 0 WHERE user_id = userID;
			SET ringing = 0;
		END;
	END IF;
	IF companyOldTypeID IN (9, 35, 10) AND callEnd = 1 AND companyTypeID IN (9, 35, 36) AND ringing = 1
		THEN BEGIN
			SELECT COUNT(*) INTO callCount FROM active_calls_view WHERE user_id = userID;
			IF callCount = 0
				THEN BEGIN
					SELECT REPLACE(company_phone, "+", ""), company_id INTO nextPhone, companyID FROM companies WHERE user_id = userID AND type_id IN (9, 35) AND company_ringing = 0 ORDER BY type_id LIMIT 1;
					IF nextPhone IS NOT NULL
						THEN BEGIN
							INSERT INTO calls (user_id, company_id, call_internal_type_id, call_destination_type_id, call_predicted) VALUES (userID, companyID, 33, 33, 1);
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
							SET responce = JSON_MERGE(responce, sendToAllUserSockets(userID, JSON_ARRAY(JSON_OBJECT(
								"type", "mergeDeep",
								"data", JSON_OBJECT(
									"message", CONCAT("соединение с ", nextPhone, " имеет статус: ожидание ответа от АТС")
								)
							))));
						END;
					END IF;
				END;
			END IF;
		END;
	END IF;
	RETURN responce;
END