BEGIN
	DECLARE userPassword, connectionApiID VARCHAR(128);
	DECLARE responce JSON;
	SET responce = JSON_ARRAY();
	SELECT user_password INTO userPassword FROM users WHERE user_email = userEmail;
	SELECT connection_api_id INTO connectionApiID FROM connections WHERE connection_hash = connectionHash;
	IF userPassword IS NOT NULL
		THEN SET responce = JSON_MERGE(responce, JSON_ARRAY(
			JSON_OBJECT(
				"type", "sendEmail",
				"data", JSON_OBJECT(
					"emails", JSON_ARRAY(
						userEmail
					),
					"subject", "Восстановление пароля",
					"text", CONCAT("Ваш пароль: ", userPassword)
				)
			),
			JSON_OBJECT(
				"type", "sendToSocket",
				"data", JSON_OBJECT(
					"socketID", connectionApiID,
					"data", JSON_ARRAY(
						JSON_OBJECT(
							"type", "merge",
							"loginMessage", "Сообщение направлено на почту"
						)
					)
				)
			)
		));
		ELSE SET responce = JSON_MERGE(responce, JSON_OBJECT(
			"type", "sendToSocket",
			"data", JSON_OBJECT(
				"socketID", connectionApiID,
				"data", JSON_ARRAY(
					JSON_OBJECT(
						"type", "merge",
						"loginMessage", CONCAT("Пользователь с таким email не существует: ", userEmail)
					)
				)
			)
		)); 
	END IF;
	RETURN responce;
END