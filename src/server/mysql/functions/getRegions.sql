BEGIN
	DECLARE regionID INT(11);
	DECLARE regionName VARCHAR(128);
	DECLARE responce JSON;
	DECLARE done TINYINT(1);
	DECLARE regionsCursor CURSOR FOR SELECT region_id, region_name FROM regions;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
	SET responce = JSON_ARRAY();
	OPEN regionsCursor;
		regionsLoop: LOOP
			FETCH regionsCursor INTO regionID, regionName;
			IF done 
				THEN LEAVE regionsLoop;
			END IF;
			SET responce = JSON_MERGE(responce, JSON_OBJECT(
				"name", regionName,
				"id", regionID
			));
			ITERATE regionsLoop;
		END LOOP;
	CLOSE regionsCursor;
	RETURN responce;
END