BEGIN
	DECLARE responce JSON;
	DECLARE telegramID INT(11);
	SET responce = JSON_ARRAY();
	SELECT telegram_id INTO telegramID FROM telegrams WHERE telegram_chat_id = chatID;
	IF telegramID IS NOT NULL
		THEN SET responce = JSON_MERGE(responce, JSON_OBJECT(
			"type", "sendToTelegram",
			"data", JSON_OBJECT(
				"chats", JSON_ARRAY(chatID),
				"message", "Вы уже зарегестрированы в системе"
			)
		));
		ELSE BEGIN
			INSERT INTO telegrams (telegram_chat_id) VALUES (chatID);
			SET responce = JSON_MERGE(responce, JSON_OBJECT(
				"type", "sendToTelegram",
				"data", JSON_OBJECT(
					"chats", JSON_ARRAY(chatID),
					"message", "Подписка на обновления установлена"
				)
			));
		END;
	END IF;
	RETURN responce;
END