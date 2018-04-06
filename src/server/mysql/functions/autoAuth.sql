BEGIN
	DECLARE connectionID, userID, activeCompaniesLength, typeID INT(11);
    DECLARE connectionApiID VARCHAR(128);
    DECLARE userAuth, connectionEnd TINYINT(1);
    DECLARE responce, activeCompanies, statistic JSON;
    SET responce = JSON_ARRAY();
	SELECT connection_id, connection_end, connection_api_id INTO connectionID, connectionEnd, connectionApiID FROM connections WHERE connection_hash = connectionHash;
    SELECT user_id, user_auth, type_id INTO userID, userAuth, typeID FROM users WHERE user_hash = userHash;
    IF connectionID IS NULL OR userAuth = 0 OR connectionEnd = 1 OR userID IS NULL
    	THEN SET responce = JSON_MERGE(responce, JSON_OBJECT(
        	"type", "sendToSocket",
            "data", JSON_OBJECT(
                "socketID", connectionApiID,
                "data", JSON_ARRAY(JSON_OBJECT(
                	"type", "merge",
                    "data", JSON_OBJECT(
                        "loginMessage", "Требуется ручная авторизация",
                        "auth", 0,
                        "try", 1
                    )
                ))
            )
      	));
        ELSE BEGIN
            UPDATE connections SET user_id = userID WHERE connection_id = connectionID;
            SELECT user_hash INTO userHash FROM users WHERE user_id = userID;
            SET responce = JSON_MERGE(responce, JSON_OBJECT(
            	"type", "sendToSocket",
                "data", JSON_OBJECT(
                    "socketID", connectionApiID,
                    "data", JSON_ARRAY(
                        JSON_OBJECT(
                        	"type", "merge",
                            "data", JSON_OBJECT(
                                "loginMessage", "Авторизация прошла успешно",
                                "auth", 1,
                                "userType", typeID
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
            IF typeID = 1 OR typeID = 18 
                THEN BEGIN
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
            END IF; 
            IF typeID = 1 OR typeID = 19
                THEN BEGIN
                    SET statistic = getBankStatistic(1, SUBDATE(NOW(), INTERVAL 1 WEEK), NOW());
                    SET responce = JSON_MERGE(responce, JSON_OBJECT(
                        "type", "sendToSocket",
                        "data", JSON_OBJECT(
                            "socketID", connectionApiID,
                            "data", JSON_ARRAY(JSON_OBJECT(
                                "type", "merge",
                                "data", JSON_OBJECT(
                                    "statistic", statistic
                                )
                            ))
                        )
                    ));
                END;
            END IF;
        END;
    END IF;
    RETURN responce;
END