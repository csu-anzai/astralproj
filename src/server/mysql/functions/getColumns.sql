BEGIN
	DECLARE columnID INT(11);
	DECLARE columnName VARCHAR(128);
	DECLARE responce JSON;
	DECLARE done TINYINT(1);
	DECLARE columnsCursor CURSOR FOR SELECT column_id, translate_to FROM columns_translates_view;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
	SET responce = JSON_ARRAY();
	OPEN columnsCursor;
		columnsLoop: LOOP
			FETCH columnsCursor INTO columnID, columnName;
			IF done 
				THEN LEAVE columnsLoop;
			END IF;
			SET responce = JSON_MERGE(responce, JSON_OBJECT(
				"name", columnName,
				"id", columnID
			));
			ITERATE columnsLoop;
		END LOOP;
	CLOSE columnsCursor;
	RETURN responce;
END