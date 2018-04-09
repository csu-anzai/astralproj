BEGIN
	SET NEW.connection_date_update = NOW();
  IF NEW.connection_end
  	THEN SET NEW.connection_date_disconnect = NOW();
  END IF;
  IF NEW.user_id IS NOT NULL
  	THEN INSERT INTO states (connection_id, user_id) VALUES (NEW.connection_id, NEW.user_id);
  END IF;
END