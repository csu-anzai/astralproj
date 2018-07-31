BEGIN
	SET NEW.connection_date_update = NOW();
  IF NEW.connection_end
  	THEN SET NEW.connection_date_disconnect = NOW();
  END IF;
  IF NEW.user_id IS NOT NULL AND (NEW.user_id != OLD.user_id OR OLD.user_id IS NULL)
  	THEN BEGIN 
  		DELETE FROM states WHERE connection_id = NEW.connection_id;
  		INSERT INTO states (connection_id, user_id) VALUES (NEW.connection_id, NEW.user_id);
  	END;
  END IF;
END