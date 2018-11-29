BEGIN
	DECLARE companiesLength, bankID, companiesIterator, banksIterator, banksLength, companyID, statusTypeID, statusID, companyBankID, negativeCompaniesLength INT(11);
	DECLARE connectionHash VARCHAR(32);
	DECLARE statusText VARCHAR(256);
	DECLARE responce, company, companyBanksArray, companyBank JSON;
	SET responce = JSON_ARRAY();
	SET companiesLength = JSON_LENGTH(companiesArray);
	SET negativeCompaniesLength = 0;
	SET companiesIterator = 0;
	companiesLoop: LOOP
		IF companiesIterator >= companiesLength
			THEN LEAVE companiesLoop;
		END IF;
		SET company = JSON_UNQUOTE(JSON_EXTRACT(companiesArray, CONCAT("$[", companiesIterator, "]")));
		SET companyID = JSON_UNQUOTE(JSON_EXTRACT(company, "$.company_id"));
		SET companyBanksArray = JSON_UNQUOTE(JSON_EXTRACT(company, "$.banks"));
		SET banksIterator = 0;
		SET banksLength = JSON_LENGTH(companyBanksArray);
		companyBanksLoop: LOOP
			IF banksIterator >= banksLength
				THEN LEAVE companyBanksLoop;
			END IF;
			SET companyBank = JSON_UNQUOTE(JSON_EXTRACT(companyBanksArray, CONCAT("$[", banksIterator, "]")));
			SET statusText = JSON_UNQUOTE(JSON_EXTRACT(companyBank, "$.status_text"));
			SET bankID = JSON_UNQUOTE(JSON_EXTRACT(companyBank, "$.bank_id"));
			CALL checkBanksStatuses(JSON_ARRAY(bankID), JSON_ARRAY(statusText));
			SELECT type_id, bank_status_id INTO statusTypeID, statusID FROM bank_statuses WHERE bank_id = bankID AND bank_status_text = statusText;
			SET companyBankID = (SELECT company_bank_id FROM company_banks WHERE bank_id = bankID AND company_id = companyID);
			IF companyBankID IS NOT NULL
				THEN UPDATE company_banks SET bank_status_id = statusID WHERE company_bank_id = companyBankID;
				ELSE UPDATE companies c LEFT JOIN translates tr ON tr.translate_from = statusText JOIN banks b ON b.bank_id = bankID SET c.company_json = JSON_SET(c.company_json, CONCAT("$.company_banks.b", bankID), JSON_OBJECT(
					"bank_id", b.bank_id,
					"bank_name", b.bank_name,
					"company_bank_status", IF(tr.translate_to IS NOT NULL, tr.translate_to, statusText),
					"type_id", statusTypeID,
					"bank_suits", 0
				)) WHERE company_id = companyID;
			END IF;
			IF statusTypeID = 17
				THEN BEGIN 
					UPDATE companies SET type_id = 13 WHERE company_id = companyID;
					SET negativeCompaniesLength = negativeCompaniesLength + 1;
				END;
			END IF;
			SET banksIterator = banksIterator + 1;
			ITERATE companyBanksLoop;
		END LOOP;
		SET companiesIterator = companiesIterator + 1;
		ITERATE companiesLoop;
	END LOOP;
	UPDATE companies SET type_id = 9 WHERE user_id = userID AND type_id = 44;
	SELECT bank_id, connection_hash INTO bankID, connectionHash FROM users_connections_view WHERE user_id = userID AND connection_end = 0 LIMIT 1;
	SET responce = JSON_MERGE(responce, refreshUserCompanies(userID));
	SET responce = JSON_MERGE(responce, sendToAllUserSockets(userID, JSON_ARRAY(JSON_OBJECT(
		"type", "merge",
		"data", JSON_OBJECT(
			"message", IF(negativeCompaniesLength = 0, "Окончание наполнения рабочего списка", CONCAT("Добавлено в рабочий список ", (companiesLength - negativeCompaniesLength) ," компаний.На проверке ещё ", negativeCompaniesLength, " компаний")),
			"messageType", IF(negativeCompaniesLength = 0, "success", "")
		)
	))));
	IF negativeCompaniesLength > 0
		THEN SET responce = JSON_MERGE(responce, getBankCompanies(connectionHash, negativeCompaniesLength, 0));
	END IF;
	RETURN responce;
END