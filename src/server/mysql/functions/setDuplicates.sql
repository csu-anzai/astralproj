BEGIN
	DECLARE companiesLength INT(11);
	DECLARE responce JSON;
	SET responce = JSON_ARRAY();
	SET companiesLength = JSON_LENGTH(companiesArray);
	UPDATE companies SET type_id = 24 WHERE JSON_CONTAINS(companiesArray, CONCAT(company_id));
	SET responce = JSON_MERGE(responce, JSON_OBJECT(
		"type", "print",
		"data", JSON_OBJECT(
			"message", CONCAT("Компании дубликаты: ", companiesLength)
		)
	));
	RETURN responce;
END