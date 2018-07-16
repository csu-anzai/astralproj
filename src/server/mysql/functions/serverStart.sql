BEGIN
	UPDATE connections SET connection_end = 1;
	UPDATE calls c SET call_internal_type_id = 42, call_destination_type_id = 42 WHERE call_internal_type_id NOT IN (38,40,41,42,46,47,48,49,50,51,52,53) AND call_destination_type_id NOT IN (38,40,41,42,46,47,48,49,50,51,52,53);
	RETURN 1;
END