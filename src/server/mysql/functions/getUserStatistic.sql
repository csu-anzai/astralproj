BEGIN
	DECLARE connectionID, bankID, userID, user INT(11);
	DECLARE connectionValid, bank, free TINYINT(1);
	DECLARE connectionApiID VARCHAR(128);
	DECLARE dateStart, dateEnd, dataDateStart, dataDateEnd VARCHAR(19);
	DECLARE responce, state, statistic, types JSON;
	SET responce = JSON_ARRAY();
	SET connectionValid = checkConnection(connectionHash);
	SELECT connection_api_id INTO connectionApiID FROM connections WHERE connection_hash = connectionHash;
	IF connectionValid
		THEN BEGIN
			SELECT connection_id, bank_id, user_id INTO connectionID, bankID, userID FROM users_connections_view WHERE connection_hash = connectionHash;
			SELECT state_json INTO state FROM states WHERE connection_id = connectionID;
			IF statisticType IN ("working", "data")
				THEN BEGIN
					SET types = JSON_EXTRACT(state, "$.statistic.types");
					SET user = JSON_EXTRACT(state, "$.statistic.user");
					SET dateStart = JSON_UNQUOTE(JSON_EXTRACT(state, "$.statistic.dateStart"));
					SET dateEnd = JSON_UNQUOTE(JSON_EXTRACT(state, "$.statistic.dateEnd"));
					SET dataDateStart = JSON_UNQUOTE(JSON_EXTRACT(state, "$.statistic.dataDateStart"));
					SET dataDateEnd = JSON_UNQUOTE(JSON_EXTRACT(state, "$.statistic.dataDateEnd"));
					SET bank = JSON_EXTRACT(state, "$.statistic.dataBank");
					SET free = JSON_EXTRACT(state, "$.statistic.dataFree");
					SET statistic = JSON_OBJECT(
						"typeToView", JSON_EXTRACT(state, "$.statistic.typeToView"),
						"period", JSON_EXTRACT(state, "$.statistic.period"),
						"dateStart", dateStart,
						"dateEnd", dateEnd,
						"user", user,
						"dataFree", free,
						"dataBank", bank,
						"dataDateStart", dataDateStart,
						"dataDateEnd", dataDateEnd,
						"dataPeriod", JSON_EXTRACT(state, "$.statistic.dataPeriod"),
						"users", getUsers(bankID)
					);
					IF statisticType = "working"
						THEN SET statistic = JSON_SET(statistic, "$.working", getWorkingBankStatistic(bankID, dateStart, dateEnd, types, user));
					END IF;
					IF statisticType = "data"
						THEN SET statistic = JSON_SET(statistic, "$.data", getDataStatistic(dataDateStart,dataDateEnd, IF(bank, bankID, NULL), free));
					END IF;
					SET responce = JSON_MERGE(responce, JSON_OBJECT(
						"type", "sendToSocket",
						"data", JSON_OBJECT(
							"socketID", connectionApiID,
							"data", JSON_ARRAY(JSON_OBJECT(
								"type", "mergeDeep",
								"data", JSON_OBJECT(
									"statistic", statistic
								)
							))
						)
					));
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