BEGIN
	DECLARE innLength INT(11);
	SET NEW.company_date_create = NOW();
	SET innLength = CHAR_LENGTH(NEW.company_inn);
	IF innLength = 9 OR innLength = 11
		THEN SET NEW.company_inn = CONCAT("0", NEW.company_inn);
	END IF;
	SET NEW.region_id = (SELECT region_id FROM codes WHERE code_value = SUBSTRING(NEW.company_inn, 1, 2));
	SET NEW.city_id = (SELECT city_id FROM fns_codes WHERE fns_code_value = SUBSTRING(NEW.company_inn, 1, 4));
	SET NEW.bank_id = (SELECT bank_id FROM bank_cities WHERE city_id = NEW.city_id LIMIT 1);
	SET NEW.company_phone = REPLACE(CONCAT("+", REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(NEW.company_phone, "(", ""), ")",""), " ", ""), "-", ""), "—", ""), "+", "")), "+8", "+7");
	IF NEW.bank_id = 1 AND (NEW.company_phone IS NULL OR NEW.company_inn IS NULL)
		THEN SET NEW.bank_id = NULL;
	END IF;
END