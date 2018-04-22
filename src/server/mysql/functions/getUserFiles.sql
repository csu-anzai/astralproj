BEGIN
	DECLARE fileName VARCHAR(128);
	DECLARE responce JSON;
	DECLARE done TINYINT(1);
	DECLARE filesCursor CURSOR FOR SELECT file_name FROM files WHERE type_id = 21 AND user_id = userID ORDER BY file_id DESC;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
	SET responce = JSON_ARRAY();
	OPEN filesCursor;
		filesLoop: LOOP
			FETCH filesCursor INTO fileName;
			IF done 
				THEN LEAVE filesLoop;
			END IF;
			SET responce = JSON_MERGE(responce, JSON_OBJECT(
				"name", fileName
			));
			ITERATE filesLoop;
		END LOOP;
	CLOSE filesCursor;
	RETURN responce;
END