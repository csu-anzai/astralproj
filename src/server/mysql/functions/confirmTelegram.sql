BEGIN
	DECLARE userID INT(11);
	DECLARE responce JSON;
	SET responce = JSON_ARRAY();
	SELECT user_id INTO userID FROM connections WHERE connection_hash = hash;
	IF userID IS NULL
		THEN SET responce = JSON_MERGE(responce, JSON_OBJECT(
			"type", "sendToTelegram",
			"data", JSON_OBJECT(
				"chatID", chatID,
				"message", "Авторизация не удалась, попробуйте другой ключ"
			)
		));
		ELSE BEGIN
			UPDATE users SET user_telegram = chatID WHERE user_id = userID;
			SET responce = JSON_MERGE(responce, JSON_OBJECT(
				"type", "sendToTelegram",
				"data", JSON_OBJECT(
					"chatID", chatID,
					"message", "Авторизация прошла успешно"
				)
			));
		END;
	END IF;
	RETURN responce;
END