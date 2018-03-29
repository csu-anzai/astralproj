BEGIN
	DECLARE connectionHash VARCHAR(32);
    INSERT INTO connections (type_id, connection_api_id) VALUES (typeID, connectionApiID);
    SELECT connection_hash INTO connectionHash FROM connections ORDER BY connection_id DESC LIMIT 1;
    RETURN JSON_ARRAY(JSON_OBJECT(
    	"type", "sendToSocket",
        "data", JSON_OBJECT(
            "socketID", connectionApiID,
            "data", JSON_ARRAY(
                JSON_OBJECT(
                    "type", "save",
                    "data", JSON_OBJECT(
                        "connectionHash", connectionHash
                    )
                ),
                JSON_OBJECT(
                    "type", "set",
                    "data", JSON_OBJECT(
                        "connectionHash", connectionHash
                    )
                )
            )
       	)
    ));
END