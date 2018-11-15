BEGIN
	DECLARE done, connectionValid TINYINT(1);
	DECLARE filialName VARCHAR(256);
	DECLARE connectionApiID VARCHAR(128);
	DECLARE bankFilialID INT(11);
	DECLARE responce, bankCityFilials JSON;
	DECLARE filialsCursor CURSOR FOR SELECT bank_filial_name, bank_filial_id FROM bank_filials WHERE bank_id = bankID AND city_id = cityID;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
	SELECT connection_api_id INTO connectionApiID FROM connections WHERE connection_hash = connectionHash;
	SET connectionValid = checkConnection(connectionHash);
	SET responce = JSON_ARRAY();
	SET bankCityFilials = JSON_ARRAY();
	IF connectionValid
		THEN BEGIN
			OPEN filialsCursor;
				filialsLoop: LOOP
					FETCH filialsCursor INTO filialName, bankFilialID;
					IF done
						THEN LEAVE filialsLoop;
					END IF;
					SET bankCityFilials = JSON_MERGE(bankCityFilials, JSON_OBJECT(
						"bank_filial_name", filialName,
						"bank_filial_id", bankFilialID
					));
					ITERATE filialsLoop;
				END LOOP;
			CLOSE filialsCursor;
			SET responce = JSON_MERGE(responce, JSON_ARRAY(JSON_OBJECT(
				"type", "sendToSocket",
				"data", JSON_OBJECT(
					"socketID", connectionApiID,
					"data", JSON_ARRAY(JSON_OBJECT(
						"type", "merge",
						"data", JSON_OBJECT(
							"bankFilials", bankCityFilials
						)
					))
				)
			)));
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