BEGIN
	DECLARE userTelegram VARCHAR(128);
	DECLARE done TINYINT(1);
	DECLARE responce JSON;
	DECLARE usersCursor CURSOR FOR SELECT user_telegram FROM users WHERE type_id = 1 AND user_telegram IS NOT NULL;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
	SET responce = JSON_ARRAY();
	OPEN usersCursor;
		usersLoop: LOOP
			FETCH usersCursor INTO userTelegram;
			IF done
				THEN LEAVE usersLoop;
			END IF;
			SET responce = JSON_MERGE(responce, JSON_OBJECT(
				"type", "sendToTelegram",
				"data", JSON_OBJECT(
					"chatID", userTelegram,
					"message", message
				)
			));
			ITERATE usersLoop;
		END LOOP;
	CLOSE usersCursor;
	RETURN responce;
END