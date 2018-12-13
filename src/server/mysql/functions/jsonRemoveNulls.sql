BEGIN
	DECLARE arrLength, iterator INT(11);
	DECLARE responce JSON;
	SET arrLength = JSON_LENGTH(arr);
	SET responce = JSON_ARRAY();
	SET iterator = 0;
	arrLoop: LOOP
		IF iterator >= arrLength
			THEN LEAVE arrLoop;
		END IF;
		IF JSON_UNQUOTE(JSON_EXTRACT(arr, CONCAT("$[", iterator, "]"))) != "null"
			THEN SET responce = JSON_MERGE(responce, JSON_UNQUOTE(JSON_EXTRACT(arr, CONCAT("$[", iterator, "]"))));
		END IF;
		SET iterator = iterator + 1;
		ITERATE arrLoop;
	END LOOP;
	RETURN responce;
END