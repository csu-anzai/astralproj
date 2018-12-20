BEGIN
	DECLARE statusExist TINYINT(1);
	DECLARE statusText VARCHAR(256);
	DECLARE bankID, statusesLength, banksLength, statusesIterator, banksIterator INT(11);
	SET banksLength = JSON_LENGTH(banksArray),
			statusesLength = JSON_LENGTH(statusesArray);
	IF statusesLength > 0 AND banksLength > 0
		THEN BEGIN
			SET statusesIterator = 0;
			statusesLoop: LOOP
				IF statusesIterator >= statusesLength
					THEN LEAVE statusesLoop;
				END IF;
				SET banksIterator = 0;
				SET statusText = JSON_UNQUOTE(JSON_EXTRACT(statusesArray, CONCAT("$[", statusesIterator, "]")));
				banksLoop: LOOP
					IF banksIterator >= banksLength
						THEN LEAVE banksLoop;
					END IF;
					SET bankID = JSON_UNQUOTE(JSON_EXTRACT(banksArray, CONCAT("$[", banksIterator, "]")));
					SET statusExist = 0;
					SELECT 1 INTO statusExist FROM bank_statuses WHERE bank_id = bankID AND bank_status_text = statusText;
					IF statusExist = 0
						THEN INSERT INTO bank_statuses (bank_id, bank_status_text) VALUES (bankID, statusText);
					END IF;
					SET banksIterator = banksIterator + 1;
					ITERATE banksLoop;
				END LOOP;
				SET statusesIterator = statusesIterator + 1;
				ITERATE statusesLoop;
			END LOOP;
		END;
	END IF;
END