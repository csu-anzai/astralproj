BEGIN
	DECLARE responce JSON;
	DECLARE connectionsBeforeCount, connectionsAfterCount INT(11);
	SET responce = JSON_ARRAY();
	SELECT count(*) INTO connectionsBeforeCount FROM connections WHERE connection_end = 0;
	UPDATE connections SET connection_end = 1;
	SELECT count(*) INTO connectionsAfterCount FROM connections WHERE connection_end = 0;
	SET responce = JSON_MERGE(responce, resetCalls());
	SET responce = JSON_MERGE(responce, JSON_OBJECT(
		"type", "print",
		"data", JSON_OBJECT(
			"message", CONCAT("число активных соединений (до | после) сброса: ", connectionsBeforeCount, " | ", connectionsAfterCount),
			"telegram", 1
		)
	));
	RETURN responce;
END