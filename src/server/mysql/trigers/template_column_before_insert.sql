BEGIN
	IF (SELECT COUNT(*) FROM template_columns WHERE column_id = NEW.column_id AND template_id = NEW.template_id) > 0
  	THEN SET NEW.template_column_duplicate = 1;
  END IF;
END