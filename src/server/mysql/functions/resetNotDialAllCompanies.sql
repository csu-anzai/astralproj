BEGIN	
	DECLARE companiesCount INT(11) DEFAULT 0;
	DECLARE responce JSON;
	SET responce = JSON_ARRAY();
	SELECT COUNT(*) INTO companiesCount FROM companies WHERE type_id = 36 AND bank_id = bankID;
	UPDATE companies SET type_id = 10, user_id = NULL WHERE type_id = 36 AND bank_id = bankID;
	SET responce = JSON_MERGE(responce, refreshUsersCompanies(bankID));
	SET responce = JSON_MERGE(responce, JSON_OBJECT(
		"type", "print",
		"data", JSON_OBJECT(
			"message", CONCAT("Сброшено в свободный доступ ", companiesCount, " компаний. Дата: ", NOW())
		)
	));
	RETURN responce;
END