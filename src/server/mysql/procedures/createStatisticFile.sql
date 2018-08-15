BEGIN
	DECLARE userID, connectionID, fileID INT(11);
	DECLARE connectionApiID VARCHAR(128);
	DECLARE dateStart, dateEnd VARCHAR(10);
	DECLARE state, types, company, companies, statistic JSON;
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
	SET userID = JSON_UNQUOTE(JSON_EXTRACT(statistic, "$.user"));
	SET types = JSON_EXTRACT(statistic, "$.types");
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
			JOIN translates tr ON tr.translate_from = t.type_name  
		WHERE 
			JSON_CONTAINS('", types, "', CONCAT(c.type_id)) AND 
			DATE(c.company_date_update) BETWEEN DATE('", dateStart, "') AND DATE('", dateEnd, "') AND ", 
			IF(userID IS NOT NULL AND userID > 0, CONCAT("c.user_id = ", userID), "1")
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