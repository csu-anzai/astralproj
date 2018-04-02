BEGIN
	DECLARE connectionApiID VARCHAR(128);
	DECLARE done TINYINT(1);
	DECLARE responce JSON;
	DECLARE socketsCursor CURSOR FOR SELECT connection_api_id FROM users_connections_view WHERE user_id = userID AND connection_type_id = 3 AND connection_end = 0;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
	SET responce = JSON_ARRAY();
	OPEN socketsCursor;
		socketsLoop: LOOP
			FETCH socketsCursor INTO connectionApiID;
			IF done
				THEN LEAVE socketsLoop;
			END IF; 
			SET responce = JSON_MERGE(responce, JSON_OBJECT(
				"type", "sendToSocket",
				"data", JSON_OBJECT(
					"socketID", connectionApiID,
					"data", sendArray
				)
			));
			ITERATE socketsLoop;
		END LOOP;
	CLOSE socketsCursor;
	RETURN responce;
END