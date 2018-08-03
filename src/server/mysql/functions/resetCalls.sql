BEGIN
	DECLARE responce, usersArray JSON;
	DECLARE callsCountBefore, callsCountAfter, userID, iterator, usersLength INT(11);
	DECLARE done TINYINT(1);
	DECLARE usersCursor CURSOR FOR SELECT DISTINCT user_id FROM active_calls_view;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
	SET responce = JSON_ARRAY();
	SET usersArray = JSON_ARRAY();
	OPEN usersCursor;
		usersLoop: LOOP
			FETCH usersCursor INTO userID;
			IF done 
				THEN LEAVE usersLoop; 
			END IF;
			SET usersArray = JSON_MERGE(usersArray, CONCAT(userID));
			ITERATE usersLoop;
		END LOOP;
	CLOSE usersCursor;
	SELECT count(*) INTO callsCountBefore FROM active_calls_view;
	UPDATE calls c SET call_internal_type_id = 42, call_destination_type_id = 42 WHERE call_internal_type_id NOT IN (38,40,41,42,46,47,48,49,50,51,52,53) AND call_destination_type_id NOT IN (38,40,41,42,46,47,48,49,50,51,52,53);
	SELECT count(*) INTO callsCountAfter FROM active_calls_view;
	SET usersLength = JSON_LENGTH(usersArray);
	IF usersLength > 0
		THEN BEGIN
			SET iterator = 0;
			usersLoop: LOOP
				IF iterator >= usersLength
					THEN LEAVE usersLoop;
				END IF;
				SET userID = JSON_UNQUOTE(JSON_EXTRACT(usersArray, CONCAT("$[", iterator, "]")));
				SET responce = JSON_MERGE(responce, refreshUserCompanies(userID));
				SET iterator = iterator + 1;
				ITERATE usersLoop;
			END LOOP;
		END;
	END IF;
	SET responce = JSON_MERGE(responce, JSON_OBJECT(
		"type", "print",
		"data", JSON_OBJECT(
			"message", CONCAT("Число активных звонков (до | после) сброса: ", callsCountBefore, " | ", callsCountAfter),
			"telegram", 1
		)
	));
	RETURN responce;
END