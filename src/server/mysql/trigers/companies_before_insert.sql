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
	SET NEW.company_json = json_object(
		'cityName', (SELECT city_name FROM cities WHERE city_id = NEW.city_id),
		'regionName', (SELECT region_name FROM regions WHERE region_id = NEW.region_id),
		'typeID', NEW.type_id,
		'companyID', NEW.company_id,
		'templateID', NEW.template_id,
		'cityID', NEW.city_id,
		'regionID', NEW.region_id,
		'companyDateCreate', NEW.company_date_create,
		'companyDateUpdate', NEW.company_date_update,
		'companyOgrn', NEW.company_ogrn,
		'companyOgrnDate', NEW.company_ogrn_date,
		'companyPersonBirthday', NEW.company_person_birthday,
		'companyDocDate', NEW.company_doc_date,
		'companyPersonName', NEW.company_person_name,
		'companyPersonSurname', NEW.company_person_surname,
		'companyPersonPatronymic', NEW.company_person_patronymic,
		'companyPersonBirthplace', NEW.company_person_birthplace,
		'companyAddress', NEW.company_address,
		'companyOrganizationName', NEW.company_organization_name,
		'companyEmail', NEW.company_email,
		'companyInn', NEW.company_inn,
		'companyDocNumber', NEW.company_doc_number,
		'companyInnfl', NEW.company_innfl,
		'companyOrganizationCode', NEW.company_organization_code,
		'companyPhone', NEW.company_phone,
		'companyHouse', NEW.company_house,
		'companyDocHouse', NEW.company_doc_house,
		'companyOkvedCode', NEW.company_okved_code,
		'companyOkvedName', NEW.company_okved_name,
		'companyKpp', NEW.company_kpp,
		'companyIndex', NEW.company_index,
		'companyRegionType', NEW.company_region_type,
		'companyDocRegionType', NEW.company_doc_region_type,
		'companyRegionName', NEW.company_region_name,
		'companyDocName', NEW.company_doc_name,
		'companyDocRegionName', NEW.company_doc_region_name,
		'companyAreaType', NEW.company_area_type,
		'companyAreaName', NEW.company_area_name,
		'companyLocalityType', NEW.company_locality_type,
		'companyLocalityName', NEW.company_locality_name,
		'companyStreetType', NEW.company_street_type,
		'companyStreetName', NEW.company_street_name,
		'companyPersonPositionType', NEW.company_person_position_type,
		'companyPersonPositionName', NEW.company_person_position_name,
		'companyDocAreaType', NEW.company_doc_area_type,
		'companyDocAreaName', NEW.company_doc_area_name,
		'companyDocLocalityType', NEW.company_doc_locality_type,
		'companyDocLocalityName', NEW.company_doc_locality_name,
		'companyDocStreetType', NEW.company_doc_street_type,
		'companyDocStreetName', NEW.company_doc_street_name,
		'companyDocGifter', NEW.company_doc_gifter,
		'companyDocCode', NEW.company_doc_code,
		'companyDocFlat', NEW.company_doc_flat
	);
END