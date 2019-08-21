BEGIN
	DECLARE connectionID, bankID, userID, user, workingCompaniesLimit, workingCompaniesOffset INT(11);
	DECLARE connectionValid, free TINYINT(1);
	DECLARE connectionApiID VARCHAR(128);
	DECLARE dateStart, dateEnd, dataDateStart, dataDateEnd VARCHAR(19);
	DECLARE responce, state, statistic, types, banks, statuses, users, dataBanks, channels, dataChannels JSON;
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
					SET channels = JSON_EXTRACT(state, "$.statistic.channels");
					SET banks = JSON_EXTRACT(state, "$.statistic.banks[*].bank_id");
					SET statuses = JSON_EXTRACT(state, "$.statistic.bankStatuses");
					SET users = JSON_EXTRACT(state, "$.statistic.selectedUsers");
					SET dateStart = JSON_UNQUOTE(JSON_EXTRACT(state, "$.statistic.dateStart"));
					SET dateEnd = JSON_UNQUOTE(JSON_EXTRACT(state, "$.statistic.dateEnd"));
					SET dataDateStart = JSON_UNQUOTE(JSON_EXTRACT(state, "$.statistic.dataDateStart"));
					SET dataDateEnd = JSON_UNQUOTE(JSON_EXTRACT(state, "$.statistic.dataDateEnd"));
					SET dataBanks = JSON_EXTRACT(state, "$.statistic.dataBanks");
					SET dataChannels = JSON_EXTRACT(state, "$.statistic.dataChannels");
					SET free = JSON_EXTRACT(state, "$.statistic.dataFree");
					SET workingCompaniesLimit = JSON_EXTRACT(state, "$.statistic.workingCompaniesLimit");
					SET workingCompaniesOffset = JSON_EXTRACT(state, "$.statistic.workingCompaniesOffset");
					SET statistic = JSON_OBJECT(
						"period", JSON_EXTRACT(state, "$.statistic.period"),
						"dateStart", dateStart,
						"dateEnd", dateEnd,
						"user", user,
						"dataFree", free,
						"dataBanks", dataBanks,
						"dataDateStart", dataDateStart,
						"dataDateEnd", dataDateEnd,
						"dataPeriod", JSON_EXTRACT(state, "$.statistic.dataPeriod"),
						"dataChannels", dataChannels,
						"users", getUsers(bankID),
						"workingCompaniesLimit", workingCompaniesLimit,
						"workingCompaniesOffset", workingCompaniesOffset
					);
					IF statisticType = "working"
						THEN SET statistic = JSON_SET(statistic,
							"$.working", getWorkingBankStatistic(dateStart, dateEnd, types, users, banks, statuses, channels),
							"$.workingCompanies", getWorkingStatisticCompanies(dateStart, dateEnd, types, users, banks, statuses, channels, workingCompaniesLimit, workingCompaniesOffset)
						);
					END IF;
					IF statisticType = "data"
						THEN SET statistic = JSON_SET(statistic, "$.data", getDataStatistic(dataDateStart, dataDateEnd, dataBanks, dataChannels, free));
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
