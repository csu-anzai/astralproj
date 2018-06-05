BEGIN
	IF NEW.company_id IS NOT NULL
		THEN UPDATE companies SET call_id = NEW.call_id, type_id = IF((NEW.call_api_id_1 IS NULL OR NEW.call_api_id_2 IS NULL) AND NEW.type_id IN (40, 41, 42), IF(type_id = 35, 36, 35), type_id) WHERE company_id = NEW.company_id;	
	END IF;
END