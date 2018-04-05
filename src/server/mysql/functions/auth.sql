BEGIN
	DECLARE userHash VARCHAR(32);
    DECLARE connectionApiID VARCHAR(128);
    DECLARE userID, connectionID, activeCompaniesLength INT(11);
    DECLARE connectionEnd TINYINT(1);
    DECLARE responce, activeCompanies JSON;
    SET responce = JSON_ARRAY();
    SET activeCompanies = JSON_ARRAY();
    SELECT user_id INTO userID FROM users WHERE LOWER(user_email) = LOWER(email) AND user_password = pass;
    SELECT connection_id, connection_end, connection_api_id INTO connectionID, connectionEnd, connectionApiID FROM connections WHERE connection_hash = connectionHash;
    IF userID IS NOT NULL AND connectionID IS NOT NULL AND connectionEnd = 0
        THEN BEGIN 
            UPDATE users SET user_auth = 1 WHERE user_id = userID;
            UPDATE connections SET user_id = userID WHERE connectionID = connectionID;
            SELECT user_hash INTO userHash FROM users WHERE user_id = userID;
            SET responce = JSON_MERGE(responce, 
                JSON_OBJECT(
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
                )
            );
            SET activeCompanies = getActiveBankUserCompanies(userID);
            SET activeCompaniesLength = JSON_LENGTH(activeCompanies);
            IF activeCompaniesLength > 0
                THEN SET responce = JSON_MERGE(responce, JSON_OBJECT(
                    "type", "sendToSocket",
                    "data", JSON_OBJECT(
                        "socketID", connectionApiID,
                        "data", JSON_ARRAY(JSON_OBJECT(
                            "type", "merge",
                            "data", JSON_OBJECT(
                                "companies", activeCompanies,
                                "message", CONCAT("Загружено компаний: ", activeCompaniesLength)
                            )
                        ))
                    )
                ));
            END IF;
        END;
        ELSE SET responce = JSON_MERGE(responce, 
            JSON_OBJECT(
            	"type", "sendToSocket",
                "data", JSON_OBJECT(
                    "socketID", connectionApiID,
                    "data", JSON_ARRAY(
                        JSON_OBJECT(
                        	"type", "merge",
                            "data", JSON_OBJECT(
                                "loginMessage", "Не верный email или пароль",
                                "auth", 0
                            )
                        )
                    ) 
                )
           	)
        );
    END IF;
    RETURN responce;
END