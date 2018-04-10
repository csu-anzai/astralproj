BEGIN
	DECLARE responce JSON;
	DECLARE done TINYINT(1);
	DECLARE userID INT(11);
	DECLARE userName VARCHAR(64);
	DECLARE usersCursor CURSOR FOR SELECT user_id, user_name FROM users WHERE IF(bankID IS NOT NULL AND bankID > 0, bank_id = bankID, bank_id IS NULL);
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
	SET responce = JSON_ARRAY();
	OPEN usersCursor;
		usersLoop: LOOP
			FETCH usersCursor INTO userID, userName;
			IF done
				THEN LEAVE usersLoop;
			END IF;
			SET responce = JSON_MERGE(responce, JSON_OBJECT(
				"userName", userName,
				"userID", userID
			));
			ITERATE usersLoop;
		END LOOP;
	CLOSE usersCursor;
	RETURN responce;
END
