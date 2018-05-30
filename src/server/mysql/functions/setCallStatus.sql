BEGIN
	DECLARE callID, userID INT(11);
	DECLARE typeTranslate VARCHAR(128);
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
	SET responce = JSON_MERGE(responce, refreshUserCompanies(userID));
	SET responce = JSON_MERGE(responce, sendToAllUserSockets(userID, JSON_ARRAY(JSON_OBJECT(
		"type", "mergeDeep",
		"data", JSON_OBJECT(
			"message", CONCAT("соединение с ", companyPhone, " имеет статус: ", typeTranslate),
			"messageType", IF(typeID NOT IN (40, 41, 42), "success", "error")
		)
	))));
	RETURN responce;
END