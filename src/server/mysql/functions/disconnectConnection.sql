BEGIN
	IF connectionApiID IS NOT NULL
		THEN UPDATE connections SET connection_end = 1 WHERE connection_api_id = connectionApiID;
	END IF;
	IF connectionHash IS NOT NULL
		THEN UPDATE connections SET connection_end = 1 WHERE connection_hash = connectionHash;
	END IF;
  RETURN JSON_ARRAY();
END