BEGIN
	IF NEW.bank_id IS NOT NULL
		THEN BEGIN 
			INSERT INTO company_banks (company_id, bank_id) VALUES (NEW.company_id, 1), (NEW.company_id, 2), (NEW.company_id, 3), (NEW.company_id, 4);
		END;
	END IF;
END