BEGIN
	DECLARE innLength, templateType, bankID INT(11);
	DECLARE cityID INT(11) DEFAULT (SELECT city_id FROM fns_codes WHERE fns_code_value = SUBSTRING(NEW.company_inn, 1, 4));
	DECLARE companyBanks JSON;
	DECLARE bankName VARCHAR(128);
	DECLARE done TINYINT(1);
	DECLARE banksCursor CURSOR FOR SELECT DISTINCT bank_id FROM bank_cities WHERE city_id = cityID OR city_id IS NULL;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
	SET companyBanks = JSON_OBJECT();
	OPEN banksCursor;
		banksLoop: LOOP
			FETCH banksCursor INTO bankID;
			IF done
				THEN LEAVE banksLoop;
			END IF;
			SELECT bank_name INTO bankName FROM banks WHERE bank_id = bankID;
			SET companyBanks = JSON_SET(companyBanks, CONCAT("$.b", bankID), JSON_OBJECT("bank_id", bankID, "bank_name", bankName, "company_bank_status", NULL, "bank_status_id", NULL));
			ITERATE banksLoop;
		END LOOP;
	CLOSE banksCursor;
	SET NEW.company_date_create = NOW();
	SET innLength = CHAR_LENGTH(NEW.company_inn);
	IF innLength = 9 OR innLength = 11
		THEN SET NEW.company_inn = CONCAT("0", NEW.company_inn);
	END IF;
	SET NEW.city_id = cityID;
	SET NEW.region_id = (SELECT region_id FROM codes WHERE code_value = SUBSTRING(NEW.company_inn, 1, 2));
	SELECT type_id INTO templateType FROM templates WHERE template_id = NEW.template_id;
	IF NEW.company_organization_name IS NULL AND templateType = 11
		THEN SET NEW.company_organization_name = CONCAT(
			IF(NEW.company_person_name IS NOT NULL OR NEW.company_person_surname IS NOT NULL OR NEW.company_person_patronymic IS NOT NULL, "ИП", ""),
			IF(NEW.company_person_surname IS NOT NULL, CONCAT(" ", NEW.company_person_surname, " "), ""),
			IF(NEW.company_person_name IS NOT NULL, CONCAT(NEW.company_person_name, " "), ""),
			IF(NEW.company_person_patronymic IS NOT NULL, CONCAT(NEW.company_person_patronymic, " "), "")
		);
	END IF;
	SET NEW.company_json = json_object(
		'city_name', (SELECT city_name FROM cities WHERE city_id = NEW.city_id),
		'region_name', (SELECT region_name FROM regions WHERE region_id = NEW.region_id),
		'type_id', NEW.type_id,
		'company_id', NEW.company_id,
		'template_id', NEW.template_id,
		'template_type_id', (SELECT type_id FROM templates WHERE template_id = NEW.template_id),
		'city_id', NEW.city_id,
		'region_id', NEW.region_id,
		'company_date_create', NEW.company_date_create,
		'company_date_update', NEW.company_date_update,
		'company_ogrn', NEW.company_ogrn,
		'company_ogrn_date', NEW.company_ogrn_date,
		'company_person_birthday', NEW.company_person_birthday,
		'company_doc_date', NEW.company_doc_date,
		'company_person_name', NEW.company_person_name,
		'company_person_surname', NEW.company_person_surname,
		'company_person_patronymic', NEW.company_person_patronymic,
		'company_person_birthplace', NEW.company_person_birthplace,
		'company_address', NEW.company_address,
		'company_organization_name', NEW.company_organization_name,
		'company_email', NEW.company_email,
		'company_inn', NEW.company_inn,
		'company_doc_number', NEW.company_doc_number,
		'company_innfl', NEW.company_innfl,
		'company_organization_code', NEW.company_organization_code,
		'company_phone', NEW.company_phone,
		'company_house', NEW.company_house,
		'company_doc_house', NEW.company_doc_house,
		'company_okved_code', NEW.company_okved_code,
		'company_okved_name', NEW.company_okved_name,
		'company_kpp', NEW.company_kpp,
		'company_index', NEW.company_index,
		'company_region_type', NEW.company_region_type,
		'company_doc_region_type', NEW.company_doc_region_type,
		'company_region_name', NEW.company_region_name,
		'company_doc_name', NEW.company_doc_name,
		'company_doc_region_name', NEW.company_doc_region_name,
		'company_area_type', NEW.company_area_type,
		'company_area_name', NEW.company_area_name,
		'company_locality_type', NEW.company_locality_type,
		'company_locality_name', NEW.company_locality_name,
		'company_street_type', NEW.company_street_type,
		'company_street_name', NEW.company_street_name,
		'company_person_position_type', NEW.company_person_position_type,
		'company_person_position_name', NEW.company_person_position_name,
		'company_doc_area_type', NEW.company_doc_area_type,
		'company_doc_area_name', NEW.company_doc_area_name,
		'company_doc_locality_type', NEW.company_doc_locality_type,
		'company_doc_locality_name', NEW.company_doc_locality_name,
		'company_doc_street_type', NEW.company_doc_street_type,
		'company_doc_street_name', NEW.company_doc_street_name,
		'company_doc_gifter', NEW.company_doc_gifter,
		'company_doc_code', NEW.company_doc_code,
		'company_doc_flat', NEW.company_doc_flat,
		"company_date_call_back", NEW.company_date_call_back,
		"company_banks", companyBanks
	);
END