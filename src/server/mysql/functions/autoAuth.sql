BEGIN
	DECLARE connectionID, userID, activeCompaniesLength, typeID, bankID INT(11);
    DECLARE connectionApiID VARCHAR(128);
    DECLARE userName VARCHAR(64);
    DECLARE userEmail VARCHAR(512);
    DECLARE userAuth, connectionEnd, ringing TINYINT(1);
    DECLARE responce, activeCompanies, activeCompany, downloadFilters, distributionFilters, statisticFilters JSON;
    SET responce = JSON_ARRAY();
	SELECT connection_id, connection_end, connection_api_id INTO connectionID, connectionEnd, connectionApiID FROM connections WHERE connection_hash = connectionHash;
    SELECT user_id, user_auth, type_id, user_name, user_email, bank_id INTO userID, userAuth, typeID, userName, userEmail, bankID FROM users WHERE user_hash = userHash;
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
                                "userType", typeID,
                                "userName", userName,
                                "userEmail", userEmail
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
                    SET activeCompanies = getActiveBankUserCompanies(connectionID);
                    SET activeCompaniesLength = JSON_LENGTH(activeCompanies);
                    SET activeCompany = JSON_OBJECT();
                    SELECT company_json INTO activeCompany FROM working_user_company_view WHERE user_id = userID LIMIT 1;
                    SELECT user_ringing INTO ringing FROM users WHERE user_id = userID;
                    SELECT state_json ->> "$.distribution" INTO distributionFilters FROM states WHERE connection_id = connectionID;
                    IF activeCompaniesLength > 0
                        THEN SET responce = JSON_MERGE(responce, JSON_OBJECT(
                            "type", "sendToSocket",
                            "data", JSON_OBJECT(
                                "socketID", connectionApiID,
                                "data", JSON_ARRAY(JSON_OBJECT(
                                    "type", "merge",
                                    "data", JSON_OBJECT(
                                        "companies", activeCompanies,
                                        "activeCompany", activeCompany,
                                        "distribution", distributionFilters,
                                        "message", CONCAT("Загружено компаний: ", activeCompaniesLength),
                                        "ringing", ringing,
                                        "cities", getCities()
                                    )
                                ))
                            )
                        ));
                        ELSE SET responce = JSON_MERGE(responce, JSON_OBJECT(
                            "type", "sendToSocket",
                            "data", JSON_OBJECT(
                                "socketID", connectionApiID,
                                "data", JSON_ARRAY(JSON_OBJECT(
                                    "type", "merge",
                                    "data", JSON_OBJECT(
                                        "distribution", distributionFilters
                                    )
                                ))
                            )
                        ));
                    END IF;
                END;
            END IF;
            IF typeID = 1 OR typeID = 19
                THEN BEGIN
                    SELECT state_json ->> "$.statistic" INTO statisticFilters FROM states WHERE connection_id = connectionID;
                    SET statisticFilters = JSON_SET(statisticFilters, "$.users", getUsers(bankID));
                    SET responce = JSON_MERGE(responce, JSON_OBJECT(
                        "type", "sendToSocket",
                        "data", JSON_OBJECT(
                            "socketID", connectionApiID,
                            "data", JSON_ARRAY(JSON_OBJECT(
                                "type", "merge",
                                "data", JSON_OBJECT(
                                    "statistic", statisticFilters
                                )
                            ))
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
                                            "files", getUserFiles(userID),
                                            "channels", getChannels()
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
    END IF;
    RETURN responce;
END
