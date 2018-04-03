BEGIN
	UPDATE companies SET type_id = IF(responce, 16, 17) WHERE company_id = companyID;
	RETURN JSON_ARRAY();
END