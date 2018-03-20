BEGIN
	DECLARE userHash VARCHAR(32);
    DECLARE userID, connectionID INT(11);
    DECLARE connectionEnd TINYINT(1);
    DECLARE responce JSON;
    SET responce = JSON_ARRAY();
    SELECT user_id INTO userID FROM users WHERE user_email = email AND user_password = pass;
    SELECT connection_id, conncetion_end INTO connectionID, connectionEnd FROM connections WHERE connection_hash = connectionHash;
    IF userID IS NOT NULL AND connectionID IS NOT NULL AND connectionEnd = 0
    	THEN BEGIN 
            UPDATE users SET user_auth = 1 WHERE user_id = userID;
            SELECT user_hash INTO userHash FROM users WHERE user_id = userID;
            UPDATE connections SET user_id = userID WHERE connectionID = connectionID;
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
                "message", "Не верный email или пароль"
            )
       	));
    END IF;
    RETURN responce;
END