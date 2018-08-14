BEGIN
	DECLARE fileStatistic TINYINT(1);
	DECLARE responce JSON;
	DECLARE userID INT(11);
	SET responce = JSON_ARRAY();
	UPDATE files SET file_name = fileName, type_id = 21 WHERE file_id = fileID;
	UPDATE companies SET type_id = 21 WHERE file_id = fileID;
	SELECT user_id, file_statistic INTO userID, fileStatistic FROM files WHERE file_id = fileID;
	SET responce = JSON_MERGE(responce, sendToAllUserSockets(userID, JSON_ARRAY(
		JSON_OBJECT(
			"type", "mergeDeep",
			"data", JSON_OBJECT(
				IF(!fileStatistic, "download", "statistic"), JSON_OBJECT(
					"fileURL", fileName,
					"message", "Файл успешно создан",
					"companiesCount", 0
				)
			)
		)
	)));
	IF !fileStatistic 
		THEN SET responce = JSON_MERGE(responce, JSON_OBJECT(
			"type", "merge",
			"data", JSON_OBJECT(
				"files", getUserFiles(userID)
			)
		));
	END IF;
	RETURN responce;
END