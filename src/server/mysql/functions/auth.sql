BEGIN
	DECLARE userHash VARCHAR(32);
    DECLARE connectionApiID VARCHAR(128);
    DECLARE userID, connectionID, activeCompaniesLength, typeID INT(11);
    DECLARE connectionEnd TINYINT(1);
    DECLARE responce, activeCompanies, downloadFilters JSON;
    SET responce = JSON_ARRAY();
    SET activeCompanies = JSON_ARRAY();
    SELECT user_id, type_id INTO userID, typeID FROM users WHERE LOWER(user_email) = LOWER(email) AND user_password = pass;
    SELECT connection_id, connection_end, connection_api_id INTO connectionID, connectionEnd, connectionApiID FROM connections WHERE connection_hash = connectionHash;
    IF userID IS NOT NULL AND connectionID IS NOT NULL AND connectionEnd = 0
        THEN BEGIN 
            UPDATE users SET user_auth = 1 WHERE user_id = userID;
            UPDATE connections SET user_id = userID WHERE connection_id = connectionID;
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
                )
            );
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
                    SET responce = JSON_MERGE(responce, JSON_OBJECT(
                        "type", "procedure",
                        "data", JSON_OBJECT(
                            "query", "getBankStatistic",
                            "values", JSON_ARRAY(
                                CONCAT(connectionHash)
                            )
                        )
                    ));
                END;
            END IF;
            IF typeID = 1
                THEN BEGIN
                    SELECT state_json ->> "$.download" INTO downloadFilters FROM states WHERE user_id = userID ORDER BY state_id DESC LIMIT 1;
                    SET responce = JSON_MERGE(responce, JSON_ARRAY(
                        JSON_OBJECT(
                            "type", "sendToSocket",
                            "data", JSON_OBJECT(
                                "socketID", connectionApiID,
                                "data", JSON_ARRAY(
                                    JSON_OBJECT(
                                        "type", "merge",
                                        "data", JSON_OBJECT(
                                            "download", downloadFilters,
                                            "banks", getBanks(),
                                            "regions", getRegions(),
                                            "columns", getColumns(),
                                            "files", getUserFiles(userID)
                                        )
                                    )
                                )
                            )
                        )
                    ));
                    SET responce = JSON_MERGE(responce, JSON_OBJECT(
                        "type", "procedure",
                        "data", JSON_OBJECT(
                            "query", "getDownloadPreview",
                            "values", JSON_ARRAY(
                                userID
                            )
                        )
                    ));
                END;
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