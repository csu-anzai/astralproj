BEGIN
	UPDATE connections SET connection_end = 1;
	RETURN 1;
END