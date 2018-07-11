BEGIN
	DECLARE connectionValid TINYINT(1);
	DECLARE keyName VARCHAR(128);
	DECLARE connectionApiID VARCHAR(32);
	DECLARE keysLength, iterator, stateID, userID, connectionID INT(11);
	DECLARE userFilters, responce, filtersKeys JSON;
	SET connectionValid = checkConnection(connectionHash);
	SET responce = JSON_ARRAY();
	SELECT user_id, connection_id, connection_api_id INTO userID, connectionID, connectionApiID FROM users_connections_view WHERE connection_hash = connectionHash;
	IF connectionValid
		THEN BEGIN	
			SET filtersKeys = JSON_KEYS(filters);
			SET keysLength = JSON_LENGTH(filtersKeys);
			SET iterator = 0;
			SELECT state_json ->> "$.statistic", state_id INTO userFilters, stateID FROM states WHERE user_id = userID AND connection_id = connectionID LIMIT 1;
			keysLoop: LOOP
				IF iterator >= keysLength
					THEN LEAVE keysLoop;
				END IF;
				SET keyName = JSON_UNQUOTE(JSON_EXTRACT(filtersKeys, CONCAT("$[", iterator, "]")));
				SET userFilters = JSON_SET(userFilters, CONCAT("$.", keyName), JSON_UNQUOTE(JSON_EXTRACT(filters, CONCAT("$.", keyName))));
				SET iterator = iterator + 1;
				ITERATE keysLoop;
			END LOOP;
			UPDATE states SET state_json = JSON_SET(state_json, "$.statistic", userFilters) WHERE state_id = stateID;
			SET responce = JSON_MERGE(responce, getBankStatistic(connectionHash));
		END;
		ELSE SET responce = JSON_MERGE(responce, JSON_OBJECT(
			"type", "sendToSocket",
			"data", JSON_OBJECT(
				"socketID", connectionApiID,
				"data", JSON_ARRAY(JSON_OBJECT(
					"type", "merge",
					"data", JSON_OBJECT(
						"auth", 0,
						"loginMessage", "Требуется ручной вход в систему"
					)
				))
			)
		));
	END IF;
	RETURN responce;
END