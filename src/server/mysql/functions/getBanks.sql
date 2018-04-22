BEGIN
	DECLARE bankID INT(11);
	DECLARE bankName VARCHAR(128);
	DECLARE responce JSON;
	DECLARE done TINYINT(1);
	DECLARE banksCursor CURSOR FOR SELECT bank_id, bank_name FROM banks;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
	SET responce = JSON_ARRAY();
	OPEN banksCursor;
		banksLoop: LOOP
			FETCH banksCursor INTO bankID, bankName;
			IF done 
				THEN LEAVE banksLoop;
			END IF;
			SET responce = JSON_MERGE(responce, JSON_OBJECT(
				"name", bankName,
				"id", bankID
			));
			ITERATE banksLoop;
		END LOOP;
	CLOSE banksCursor;
	RETURN responce;
END