BEGIN
	DECLARE userID INT(11);
	DECLARE connectionHash VARCHAR(32);
	DECLARE done TINYINT(1);
	DECLARE responce JSON;
	DECLARE usersCursor CURSOR FOR SELECT user_id, connection_hash FROM users_connections_view WHERE connection_end = 0 AND connection_type_id = 3 AND type_id IN (1, 19) AND bank_id = bankID;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
	SET responce = JSON_ARRAY();
	OPEN usersCursor;
		usersLoop: LOOP
			FETCH usersCursor INTO userID, connectionHash;
			IF done
				THEN LEAVE usersLoop;
			END IF;
			SET responce = JSON_MERGE(responce, getBankStatistic(connectionHash));
			ITERATE usersLoop;
		END LOOP;
	CLOSE usersCursor;
	RETURN responce;
END