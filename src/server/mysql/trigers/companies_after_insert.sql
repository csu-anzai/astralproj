BEGIN
	DECLARE iterator, banksLength, bankID INT(11);
	DECLARE bankKey VARCHAR(12);
	DECLARE banks, banksKeys JSON;
	SET banks = JSON_UNQUOTE(JSON_EXTRACT(NEW.company_json, "$.company_banks"));
	SET iterator = 0;
	SET banksKeys = JSON_KEYS(banks);
	SET banksLength = JSON_LENGTH(banksKeys);
	IF banksLength > 0
		THEN BEGIN
			banksLoop: LOOP
				IF iterator >= banksLength
					THEN LEAVE banksLoop;
				END IF;
				SET bankKey = JSON_UNQUOTE(JSON_EXTRACT(banksKeys, CONCAT("$[", iterator, "]")));
				SET bankID = JSON_UNQUOTE(JSON_EXTRACT(banks, CONCAT("$.", bankKey, ".bank_id")));
				INSERT INTO company_banks (company_id, bank_id) VALUES (NEW.company_id, bankID);
				SET iterator = iterator + 1;
				ITERATE banksLoop;
			END LOOP;
		END;
	END IF;
END