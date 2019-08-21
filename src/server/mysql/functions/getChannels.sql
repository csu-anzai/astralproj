BEGIN
  DECLARE channelID BIGINT(20);
  DECLARE channelDescription VARCHAR(256);
  DECLARE channelPriority INT(11);
  DECLARE responce JSON;
  DECLARE done TINYINT(1);
  DECLARE channelsCursor CURSOR FOR SELECT channel_id, channel_description, channel_priority FROM channels;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
  SET responce = JSON_ARRAY();
  OPEN channelsCursor;
    channelsLoop: LOOP
      FETCH channelsCursor INTO channelID, channelDescription, channelPriority;
      IF done
        THEN LEAVE channelsLoop;
      END IF;
      SET responce = JSON_MERGE(responce, JSON_OBJECT(
        "channel_description", channelDescription,
        "channel_id", channelID,
        "channel_priority", channelPriority
      ));
      ITERATE channelsLoop;
    END LOOP;
  CLOSE channelsCursor;
  RETURN responce;
END
