BEGIN
	SET NEW.bank_status_date_create = NOW();
	IF NEW.type_id IS NULL
		THEN SET NEW.type_id = 15;
	END IF;
END