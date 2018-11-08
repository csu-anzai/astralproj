BEGIN
	DECLARE banksNames JSON DEFAULT JSON_UNQUOTE(JSON_EXTRACT(NEW.company_json, "$.company_banks"));
	DECLARE done TINYINT(1);
	DECLARE bankID INT(11);
	DECLARE banksCursor CURSOR FOR SELECT bank_id FROM banks WHERE JSON_CONTAINS(banksNames, JSON_ARRAY(bank_name));
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
	IF JSON_LENGTH(banksNames) > 0
		THEN BEGIN
			OPEN banksCursor;
				banksLoop: LOOP
					FETCH banksCursor INTO bankID;
					IF done 
						THEN LEAVE banksLoop;
					END IF;
					INSERT INTO company_banks (bank_id, company_id) VALUES (bankID, NEW.company_id);
					ITERATE banksLoop;
				END LOOP;
			CLOSE banksCursor;
		END;
	END IF;
END