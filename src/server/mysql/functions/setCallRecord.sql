BEGIN
	DECLARE responce JSON;
	SET responce = JSON_ARRAY();
	UPDATE calls SET call_record = 1 WHERE call_api_id_with_rec = callApiIDWithRec OR call_api_id_1 = callApiID OR call_api_id_2 = callApiID;
	RETURN responce;
END 