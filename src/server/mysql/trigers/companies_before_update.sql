BEGIN
	SET NEW.company_date_update = NOW();
	SET NEW.company_json = JSON_SET(NEW.company_json,
		"$.type_id", NEW.type_id,
		"$.company_date_update", NEW.company_date_update,
		"$.company_comment", NEW.company_comment
	);
END