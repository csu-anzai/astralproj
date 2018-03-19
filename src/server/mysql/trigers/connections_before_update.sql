BEGIN
	SET NEW.connection_date_update = NOW();
    IF NEW.connection_end
    	THEN SET NEW.connection_date_disconnect = NOW();
    END IF;
END