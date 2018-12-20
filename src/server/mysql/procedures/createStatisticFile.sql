BEGIN
	DECLARE connectionID, fileID, userID INT(11);
	DECLARE connectionApiID VARCHAR(128);
	DECLARE dateStart, dateEnd VARCHAR(10);
	DECLARE state, types, company, companies, statistic, users, banks, statuses JSON;
	DECLARE done TINYINT(1);
	DECLARE companiesCursor CURSOR FOR SELECT company_json FROM custom_statistic_file_view;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
	SET responce = JSON_ARRAY();
	SET companies = JSON_ARRAY(JSON_ARRAY(
		"Название компании",
		"Ф.И.О",
		"Телефон",
		"ИНН",
		"Дата создания",
		"Дата обновления",
		"Статус"
	));
	SELECT connection_id, connection_api_id INTO connectionID, connectionApiID FROM connections WHERE connection_hash = connectionHash;
	SELECT state_json ->> "$.statistic" INTO statistic FROM states WHERE connection_id = connectionID;
	SET users = JSON_UNQUOTE(JSON_EXTRACT(statistic, "$.users"));
	SET types = JSON_UNQUOTE(JSON_EXTRACT(statistic, "$.types"));
	SET banks = JSON_UNQUOTE(JSON_EXTRACT(statistic, "$.banks[*].bank_id"));
	SET statuses = JSON_UNQUOTE(JSON_EXTRACT(statistic, "$.bankStatuses"));
	SET dateStart = JSON_UNQUOTE(JSON_EXTRACT(statistic, "$.dateStart"));
	SET dateEnd = JSON_UNQUOTE(JSON_EXTRACT(statistic, "$.dateEnd"));
	SET @mysqlText = CONCAT("CREATE VIEW custom_statistic_file_view AS 
		SELECT JSON_ARRAY(
			c.company_organization_name,
			RTRIM(LTRIM(CONCAT(
				IF(c.company_person_name IS NOT NULL, c.company_person_name, ''),
				IF(c.company_person_surname IS NOT NULL, CONCAT(' ', c.company_person_surname, ' '), ''),
				IF(c.company_person_patronymic IS NOT NULL, c.company_person_patronymic, '')
			))),
			c.company_phone,
			c.company_inn,
			c.company_date_create,
			c.company_date_update,
			IF(tr.translate_to IS NOT NULL, tr.translate_to, t.type_name)
		) company_json 
		FROM  
			companies c  
			JOIN types t ON t.type_id = c.type_id  
			LEFT JOIN translates tr ON tr.translate_from = t.type_name
		WHERE 
			c.type_id != 10 AND 
			DATE(c.company_date_update) BETWEEN DATE('", dateStart, "') AND DATE('", dateEnd, "')", 
			IF(users IS NOT NULL AND JSON_LENGTH(users) > 0, CONCAT(" AND JSON_CONTAINS('",users,"', JSON_ARRAY(c.user_id))"), ""),
			IF(types IS NOT NULL AND JSON_LENGTH(types) > 0, CONCAT(" AND JSON_CONTAINS('",types,"', JSON_ARRAY(c.type_id))"), ""),
			IF(banks IS NOT NULL AND JSON_LENGTH(banks) > 0, CONCAT(" AND jsonContainsLeastOne('",banks,"', c.company_json ->> '$.company_banks.*.bank_id')"), ""),
			IF(statuses IS NOT NULL AND JSON_LENGTH(statuses) > 0, CONCAT(" AND jsonContainsLeastOne('",statuses,"', c.company_json ->> '$.company_banks.*.bank_status_id')"), "")
	);
	PREPARE mysqlPrepare FROM @mysqlText;
	EXECUTE mysqlPrepare;
	DEALLOCATE PREPARE mysqlPrepare;
	SET done = 0;
	OPEN companiesCursor;
		companiesLoop: LOOP
			FETCH companiesCursor INTO company;
			IF done 
				THEN LEAVE companiesLoop;
			END IF;
			SET companies = JSON_MERGE(companies, JSON_ARRAY(company));
			ITERATE companiesLoop;
		END LOOP;
	CLOSE companiesCursor;
	DROP VIEW IF EXISTS custom_statistic_file_view;
	IF JSON_LENGTH(companies) > 1
		THEN BEGIN
			SELECT user_id INTO userID FROM connections WHERE connection_hash = connectionHash;
			INSERT INTO files (type_id, user_id, file_statistic) VALUES (22, userID, 1);
			SELECT file_id INTO fileID FROM files ORDER BY file_id DESC LIMIT 1;
			SET responce = JSON_MERGE(responce, JSON_OBJECT(
				"type", "xlsxCreate",
				"data", JSON_OBJECT(
					"name", DATE(NOW()),
					"data", companies,
					"fileID", fileID
				)
			));
		END;
		ELSE SET responce = JSON_MERGE(responce, JSON_OBJECT(
			"type", "sendToSocket",
			"data", JSON_OBJECT(
				"socketID", connectionApiID,
				"data", JSON_ARRAY(JSON_OBJECT(
					"type", "mergeDeep",
					"data", JSON_OBJECT(
						"message", "Нет компаний для формирования файла по текущим фильтрам"
					)
				))
			)
		));
	END IF;
END