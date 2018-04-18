BEGIN
	DECLARE innLength, templateType INT(11);
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
	SELECT type_id INTO templateType FROM templates WHERE template_id = NEW.template_id;
	IF NEW.company_organization_name IS NULL AND templateType = 11
		THEN SET NEW.company_organization_name = CONCAT(
			IF(NEW.company_person_name IS NOT NULL OR NEW.company_person_surname IS NOT NULL OR NEW.company_person_patronymic IS NOT NULL, "ИП", ""),
			IF(NEW.company_person_surname IS NOT NULL, CONCAT(" ", NEW.company_person_surname, " "), ""),
			IF(NEW.company_person_name IS NOT NULL, CONCAT(NEW.company_person_name, " "), ""),
			IF(NEW.company_person_patronymic IS NOT NULL, CONCAT(NEW.company_person_patronymic, " "), "")
		);
	END IF;
END