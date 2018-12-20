BEGIN
	IF NEW.company_bank_date_send IS NULL AND NEW.bank_status_id IS NOT NULL AND OLD.bank_status_id IS NULL
		THEN SET NEW.company_bank_date_send = NOW();
	END IF;
	SET NEW.company_bank_date_update = NOW();
	IF NEW.bank_status_id IS NOT NULL AND IF(OLD.bank_status_id IS NOT NULL, NEW.bank_status_id != OLD.bank_status_id, 1)
		THEN UPDATE companies c LEFT JOIN bank_statuses bs ON bs.bank_status_id = NEW.bank_status_id LEFT JOIN translates tr ON tr.translate_from = bs.bank_status_text SET c.company_json = JSON_SET(c.company_json, CONCAT("$.company_banks.b", NEW.bank_id, ".company_bank_status"), IF(tr.translate_to IS NOT NULL, tr.translate_to, bs.bank_status_text), CONCAT("$.company_banks.b", NEW.bank_id, ".type_id"), bs.type_id, CONCAT("$.company_banks.b", NEW.bank_id, ".bank_status_id"), bs.bank_status_id) WHERE c.company_id = NEW.company_id;
	END IF;
END