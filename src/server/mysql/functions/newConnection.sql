BEGIN
	DECLARE connectionHash VARCHAR(32);
    INSERT INTO connections (type_id, connection_api_id) VALUES (typeID, connectionApiID);
    SELECT connection_hash INTO connectionHash FROM connections ORDER BY connection_id DESC LIMIT 1;
    RETURN JSON_ARRAY(JSON_OBJECT(
    	"type", "responce",
        "data", JSON_OBJECT(
        	"connectionType", typeID,
            "connectionID", connectionApiID,
            "responce", JSON_OBJECT(
            	"connectionHash", connectionHash
           	)
       	)
    ));
END