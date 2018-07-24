BEGIN
	DECLARE chatID VARCHAR(128);
	DECLARE done TINYINT(1);
	DECLARE responce, telegramsArray JSON;
	DECLARE telegramCursor CURSOR FOR SELECT telegram_chat_id FROM telegrams WHERE telegram_chat_id IS NOT NULL;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
	SET responce = JSON_ARRAY();
	SET telegramsArray = JSON_ARRAY();
	OPEN telegramCursor;
		telegramLoop: LOOP
			FETCH telegramCursor INTO chatID;
			IF done
				THEN LEAVE telegramLoop;
			END IF;
			SET telegramsArray = JSON_MERGE(telegramsArray, CONCAT(chatID));
			ITERATE telegramLoop;
		END LOOP;
	CLOSE telegramCursor;
	IF JSON_LENGTH(telegramsArray) > 0
		THEN SET responce = JSON_MERGE(responce, JSON_OBJECT(
			"type", "sendToTelegram",
			"data", JSON_OBJECT(
				"chats", telegramsArray,
				"message", message
			)
		));
		ELSE SET responce = JSON_MERGE(responce, JSON_OBJECT(
			"type", "print",
			"data", JSON_OBJECT(
				"message", CONCAT("нет чатов для рассылки в телеграм (", message, ")")
			)
		));
	END IF;
	RETURN responce;
END