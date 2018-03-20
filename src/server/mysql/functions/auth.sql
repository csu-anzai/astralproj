BEGIN
	DECLARE userHash VARCHAR(32);
    DECLARE userID INT(11);
    DECLARE responce JSON;
    SET responce = JSON_ARRAY();
    SELECT user_id INTO userID FROM users WHERE user_email = email AND user_password = pass;
    IF userID IS NOT NULL
    	THEN BEGIN 
            UPDATE users SET user_auth = 1 WHERE user_id = userID;
            SELECT user_hash INTO userHash FROM users WHERE user_id = userID;
            SET responce = JSON_MERGE(responce, JSON_OBJECT(
                "type", "responce",
                "data", JSON_OBJECT(
                    "type", "success",
                    "userHash", userHash,
                    "message", "Авторизация прошла успешно"
                )
            ));
        END;
        ELSE SET responce = JSON_MERGE(responce, JSON_OBJECT(
        	"type", "responce",
            "data", JSON_OBJECT(
            	"type", "error",
                "message", "Не верны email или пароль"
            )
       	));
    END IF;
    RETURN responce;
END