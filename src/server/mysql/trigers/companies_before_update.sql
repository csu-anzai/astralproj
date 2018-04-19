BEGIN
	SET NEW.company_date_update = NOW();
	SET NEW.company_json = JSON_SET(
		NEW.company_json,
		"$.typeID", NEW.type_id,
		"$.companyDateUpdate", NEW.company_date_update
	);
END