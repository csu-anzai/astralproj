BEGIN
	DECLARE companyID, companiesLength, connectionID, userID, timeID, companiesCount INT(11);
	DECLARE connectionValid TINYINT(1);
	DECLARE connectionApiID VARCHAR(128);
	DECLARE today, yesterday, hours, weekdaynow, friday VARCHAR(19);
	DECLARE responce, companiesArray JSON;
	SET connectionValid = checkConnection(connectionHash);
	SELECT connection_api_id, connection_id, user_id INTO connectionApiID, connectionID, userID FROM users_connections_view WHERE connection_hash = connectionHash;
	SET responce = JSON_ARRAY();
	IF connectionValid
		THEN BEGIN
			SET today = DATE(NOW());
			SET yesterday = SUBDATE(today, INTERVAL 1 DAY);
			SET hours = HOUR(NOW());
			SET friday = SUBDATE(today, INTERVAL 3 DAY);
			SET weekdaynow = WEEKDAY(today);
			IF clearWorkList
				THEN BEGIN
					UPDATE companies SET user_id = NULL, type_id = 10 WHERE user_id = userID AND type_id IN (9, 35, 44);
					SET responce = JSON_MERGE(responce, refreshUserCompanies(userID));
					SET responce = JSON_MERGE(responce, JSON_MERGE(responce, sendToAllUserSockets(userID, JSON_ARRAY(
						JSON_OBJECT(
							"type", "merge",
							"data", JSON_OBJECT(
								"message", CONCAT("Рабочий список сброшен. На проверке ", rows, " компаний."),
								"messageType", ""
							)
						)
					))));
				END;
			END IF;
			UPDATE
				companies c
				JOIN (
					SELECT
						company_id,
						IF(type_id = 10 AND old_type_id = 36, 1, 2) type
					FROM
						regions_companies_view
					WHERE
						(
							company_banks_length > 0 AND
							(hours + region_msc_timezone) BETWEEN 10 AND 18
						) AND
						(
							(
								IF(
									DATE(company_date_registration) IS NOT NULL,
									DATE(company_date_registration) IN (today, IF(weekdaynow = 0, friday, yesterday)),
									DATE(company_date_create) IN (today, IF(weekdaynow = 0, friday, yesterday))
								) AND
								user_id IS NULL AND
								type_id = 10 AND
								(old_type_id IS NULL OR old_type_id != 36) AND
								IF(
									DATE(company_date_registration) IS NOT NULL,
									IF(
										DATE(company_date_registration) = IF(weekdaynow = 0, friday, yesterday),
										IF(
											hours BETWEEN 9 AND 16,
											1,
											0
										),
										1
									),
									IF(
										DATE(company_date_create) = IF(weekdaynow = 0, friday, yesterday),
										IF(
											hours BETWEEN 9 AND 16,
											1,
											0
										),
										1
									)
								)
							)
							OR
							(
								type_id = 10 AND
								old_type_id = 36 AND
								date(company_date_update) = today
							)
						)
					ORDER BY type ASC, date(company_date_registration) DESC, date(company_date_create) DESC, region_priority ASC, time(company_date_create) DESC LIMIT rows
				) bc ON bc.company_id = c.company_id
			SET c.user_id = userID, c.type_id = 44;
			SELECT COUNT(*) INTO companiesCount FROM companies WHERE user_id = userID AND type_id = 44;
			IF companiesCount > 0
				THEN SET responce = JSON_MERGE(responce, checkCompaniesInn(userID));
				ELSE BEGIN
					SET responce = JSON_MERGE(responce, refreshUserCompanies(userID));
					SET responce = JSON_MERGE(responce, JSON_MERGE(responce, sendToAllUserSockets(userID, JSON_ARRAY(
						JSON_OBJECT(
							"type", "merge",
							"data", JSON_OBJECT(
								"message", "Не удалось найти ни одной компании для сортировки на данное время",
								"messageType", "error"
							)
						)
					))));
				END;
			END IF;
		END;
		ELSE SET responce = JSON_MERGE(responce, JSON_OBJECT(
			"type", "sendToSocket",
			"data", JSON_OBJECT(
				"socketID", connectionApiID,
				"data", JSON_ARRAY(JSON_OBJECT(
					"type", "merge",
					"data", JSON_OBJECT(
						"auth", 0,
						"loginMessage", "Требуется ручной вход в систему"
					)
				))
			)
		));
	END IF;
	RETURN responce;
END
