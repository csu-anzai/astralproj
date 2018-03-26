BEGIN
	DECLARE innLength INT(11);
	SET NEW.company_date_create = NOW();
	SET innLength = CHAR_LENGTH(NEW.company_inn);
	IF innLength = 9 OR innLength = 11
		THEN SET NEW.company_inn = CONCAT("0", NEW.company_inn);
	END IF;
END