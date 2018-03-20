BEGIN
	DECLARE connectionID, userID, connectionUserID INT(11);
    DECLARE userAuth, connectionEnd TINYINT(1);
    DECLARE responce JSON;
    SET responce = JSON_ARRAY();
	SELECT connection_id, userID, connection_end INTO connectionID, connectionUserID, connectionEnd FROM connections WHERE connection_hash = connectionHash;
    SELECT user_id, user_auth INTO userID, userAuth FROM users WHERE user_hash = userHash;
    IF userID IS NULL OR connectionID IS NULL OR userAuth = 0 OR (connectionUserID IS NOT NULL AND connectionUserID != userID) OR connectionEnd = 1
    	THEN SET responce = JSON_MERGE(responce, JSON_OBJECT(
        	"type", "responce",
            "data", JSON_OBJECT(
            	"type", "error",
                "message", "Требуется ручная авторизация"
            )
      	));
        ELSE BEGIN
            IF connectionUserID != userID
                THEN UPDATE connections SET user_id = userID WHERE connection_id = connectionID;
            END IF;
            SET responce = JSON_MERGE(responce, JSON_OBJECT(
            	"type", "responce",
                "data", JSON_OBJECT(
                	"type", "success",
                    "message", "Авторизация прошла успешно"
                )
            ));
        END;
    END IF;
    RETURN responce;
END