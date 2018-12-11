BEGIN
	DECLARE responce TINYINT(1);
	DECLARE iterator, array1Length, array2Length, minArrayLength INT(11);
	DECLARE minArray, maxArray JSON;
	IF JSON_CONTAINS(array1, array2) OR JSON_CONTAINS(array2, array1)
		THEN SET responce = 1;
		ELSE BEGIN
			SET iterator = 0;
			SET array1Length = JSON_LENGTH(array1);
			SET array2Length = JSON_LENGTH(array2);
			IF array1Length = array2Length OR array1Length < array2Length
				THEN SET minArray = array1, maxArray = array2;
				ELSE SET minArray = array2, maxArray = array1;
			END IF;
			SET minArrayLength = JSON_LENGTH(minArray);
			minArrayLoop: LOOP
				IF iterator >= minArrayLength OR responce
					THEN LEAVE minArrayLoop;
				END IF;
				SET responce = JSON_CONTAINS(maxArray, JSON_UNQUOTE(JSON_EXTRACT(minArray, CONCAT("$[", iterator, "]"))));
				SET iterator = iterator + 1;
				ITERATE minArrayLoop;
			END LOOP;
		END;
	END IF;
	RETURN responce;
END