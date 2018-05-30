BEGIN
	IF NEW.company_id IS NOT NULL
		THEN UPDATE companies SET call_id = NEW.call_id WHERE company_id = NEW.company_id;
	END IF;
END