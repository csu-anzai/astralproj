BEGIN
	DECLARE connectionID, userID, connectionUserID INT(11);
    DECLARE connectionApiID VARCHAR(128);
    DECLARE userAuth, connectionEnd TINYINT(1);
    DECLARE responce JSON;
    SET responce = JSON_ARRAY();
	SELECT connection_id, userID, connection_end, connection_api_id INTO connectionID, connectionUserID, connectionEnd, connectionApiID FROM connections WHERE connection_hash = connectionHash;
    SELECT user_id, user_auth INTO userID, userAuth FROM users WHERE user_hash = userHash;
    IF userID IS NULL OR connectionID IS NULL OR userAuth = 0 OR (connectionUserID IS NOT NULL AND connectionUserID != userID) OR connectionEnd = 1
    	THEN SET responce = JSON_MERGE(responce, JSON_OBJECT(
        	"type", "sendToSocket",
            "data", JSON_OBJECT(
                "socketID", connectionApiID,
                "data", JSON_ARRAY(JSON_OBJECT(
                	"type", "merge",
                    "data", JSON_OBJECT(
                        "loginMessage", "Требуется ручная авторизация",
                        "auth", 0
                    )
                ))
            )
      	));
        ELSE BEGIN
            IF connectionUserID != userID
                THEN UPDATE connections SET user_id = userID WHERE connection_id = connectionID;
            END IF;
            SET responce = JSON_MERGE(responce, JSON_OBJECT(
            	"type", "sendToSocket",
                "data", JSON_OBJECT(
                    "socketID", connectionApiID,
                    "data", JSON_ARRAY(
                        JSON_OBJECT(
                        	"type", "merge",
                            "data", JSON_OBJECT(
                                "loginMessage", "Авторизация прошла успешно",
                                "auth", 1
                            )
                        ),
                        JSON_OBJECT(
                            "type", "save",
                            "data", JSON_OBJECT(
                                "userHash", userHash
                            )
                        )
                    )
                )
            ));
        END;
    END IF;
    RETURN responce;
END