BEGIN
	DECLARE userID INT(11);
	DECLARE done TINYINT(1);
	DECLARE responce JSON;
	DECLARE usersCursor CURSOR FOR SELECT user_id FROM users_connections_view WHERE IF(bankID IS NOT NULL, bank_id = bankID, 1) AND connection_end = 0 AND type_id IN (1, 18);
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
	SET responce = JSON_ARRAY();
	OPEN usersCursor;
		usersLoop: LOOP
			FETCH usersCursor INTO userID;
			IF done
				THEN LEAVE usersLoop;
			END IF;
			SET responce = JSON_MERGE(responce, refreshUserCompanies(userID));
			ITERATE usersLoop;
		END LOOP;
	CLOSE usersCursor;
	RETURN responce;
END