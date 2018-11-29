BEGIN
	DECLARE responce, arrayItem, customObject JSON;
	DECLARE arrayIterator, keysIterator, arrayLength, keysLength INT(11);
	DECLARE keyName TEXT;
	SET responce = JSON_ARRAY();
	SET arrayIterator = 0;
	SET arrayLength = JSON_LENGTH(array);
	SET keysLength = JSON_LENGTH(keysArray);
	arrayLoop: LOOP
		IF arrayIterator >= arrayLength
			THEN LEAVE arrayLoop;
		END IF;
		IF keysLength > 1
			THEN BEGIN
				SET arrayItem = JSON_UNQUOTE(JSON_EXTRACT(array, CONCAT("$[", arrayIterator, "]"))); 
				SET customObject = JSON_OBJECT();
				SET keysIterator = 0;
				keysLoop: LOOP
					IF keysIterator >= keysLength
						THEN LEAVE keysLoop;
					END IF;
					SET keyName = JSON_UNQUOTE(JSON_EXTRACT(keysArray, CONCAT("$[", keysIterator, "]")));
					SET customObject = JSON_SET(customObject, CONCAT("$.", keyName), JSON_UNQUOTE(JSON_EXTRACT(arrayItem, CONCAT("$.", keyName))));
					SET keysIterator = keysIterator + 1;
					ITERATE keysLoop;
				END LOOP;
				SET responce = JSON_MERGE(responce, customObject);
			END;
			ELSE BEGIN 
				SET keyName = JSON_UNQUOTE(JSON_EXTRACT(keysArray, "$[0]"));
				SET responce = JSON_MERGE(responce, JSON_ARRAY(JSON_UNQUOTE(JSON_EXTRACT(array, CONCAT("$[", arrayIterator, "].", keyName)))));
			END;
		END IF;
		SET arrayIterator = arrayIterator + 1;
		ITERATE arrayLoop;
	END LOOP;
	RETURN responce;
END