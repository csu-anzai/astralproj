SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;


DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getBankStatistic` (IN `connectionHash` VARCHAR(32) CHARSET utf8, OUT `responce` JSON)  NO SQL
BEGIN
  DECLARE typeID, templateID, templateItemsCount, templateInfoItemsCount, templatePeriodItemsCount, userID, user, bankID, statisticCount, connectionID, typeToView, periodToView, dataPeriod, templatesPeriodsLength, iterator INT(11);
  DECLARE period VARCHAR(15);
  DECLARE dateStart, dateEnd, dataDateStart, dataDateEnd VARCHAR(19);
  DECLARE typeName, searchResult, connectionApiID VARCHAR(128);
  DECLARE done, connectionValid, dataBank, dataFree TINYINT(1);
  DECLARE periodName, dataPeriodName VARCHAR(24);
  DECLARE labels, templates, templateItems, templateInfoItems, types, users, templatesPeriods JSON;
  DECLARE companiesCursor CURSOR FOR SELECT * FROM custom_statistic_view;
  DECLARE templatesCursor CURSOR FOR SELECT template_id, type_name FROM templates_view;
  DECLARE templatesPeriodsCursor CURSOR FOR SELECT * FROM custom_data_view;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
  SET connectionValid = checkConnection(connectionHash);
  SELECT connection_api_id, user_id, connection_id INTO connectionApiID, userID, connectionID FROM users_connections_view WHERE connection_hash = connectionHash;
  SET responce = JSON_ARRAY();
  SET templatesPeriods = JSON_ARRAY();
  IF connectionValid 
    THEN BEGIN
      SELECT bank_id INTO bankID FROM users WHERE user_id = userID;
      SELECT 
        state_json ->> "$.statistic.dateStart", 
        state_json ->> "$.statistic.dateEnd", 
        state_json ->> "$.statistic.types",
        state_json ->> "$.statistic.typeToView",
        state_json ->> "$.statistic.period",
        state_json ->> "$.statistic.user",
        state_json ->> "$.statistic.dataDateStart",
        state_json ->> "$.statistic.dataDateEnd",
        state_json ->> "$.statistic.dataPeriod",
        state_json ->> "$.statistic.dataBank",
        state_json ->> "$.statistic.dataFree"
      INTO
        dateStart,
        dateEnd,
        types,
        typeToView,
        periodToView,
        user,
        dataDateStart,
        dataDateEnd,
        dataPeriod,
        dataBank,
        dataFree
      FROM states WHERE connection_id = connectionID AND user_id = userID LIMIT 1;
      IF DATE(dateStart) = DATE(dateEnd)
        THEN SET periodName = "CONCAT(HOUR(time),':00')";
        ELSE BEGIN
          SELECT COUNT(DISTINCT date) INTO statisticCount FROM statistic_view WHERE bank_id = bankID AND date BETWEEN DATE(dateStart) AND DATE(dateEnd) AND JSON_CONTAINS(types, JSON_ARRAY(type_id)) > 0;
          IF statisticCount <= 1
            THEN BEGIN
              SET periodName = "CONCAT(HOUR(time),':00')";
              SELECT DISTINCT DATE(date), DATE(date) INTO dateStart, dateEnd FROM statistic_view WHERE bank_id = bankID AND date BETWEEN DATE(dateStart) AND DATE(dateEnd) AND JSON_CONTAINS(types, JSON_ARRAY(type_id)) > 0;
            END;
            ELSE SET periodName = "date";
          END IF;
        END;
      END IF;
      IF DATE(dataDateStart) = DATE(dataDateEnd)
        THEN BEGIN
          SET dataPeriodName = "time";
          SET @mysqlText2 = CONCAT("CREATE VIEW custom_data_view AS SELECT CONCAT(HOUR(company_date_create),':',MINUTE(company_date_create)) time FROM companies WHERE IF(", dataFree, ", type_id = 10, 1) AND IF(", dataBank, ", bank_id = ", bankID, ", 1) AND DATE(company_date_create) = DATE('", dataDateStart, "') GROUP BY time");
        END;
        ELSE BEGIN 
          SET dataPeriodName = "date";
          SET @mysqlText2 = CONCAT("CREATE VIEW custom_data_view AS SELECT DATE(company_date_create) date FROM companies WHERE IF(", dataFree, ", type_id = 10, 1) AND IF(", dataBank, ", bank_id = ", bankID, ", 1) AND DATE(company_date_create) BETWEEN DATE('", dataDateStart, "') AND DATE('", dataDateEnd, "') GROUP BY date");
        END;
      END IF;
      SET @mysqlText = CONCAT("CREATE VIEW custom_statistic_view AS SELECT ", periodName," period FROM statistic_view WHERE bank_id = ", bankID, " AND date BETWEEN DATE('", dateStart, "') AND DATE('", dateEnd, "') AND JSON_CONTAINS('", types,"', JSON_ARRAY(type_id)) > 0 GROUP BY period");
      SET labels = JSON_ARRAY();
      SET templates = JSON_ARRAY();
      PREPARE mysqlPrepare FROM @mysqlText;
      EXECUTE mysqlPrepare;
      DEALLOCATE PREPARE mysqlPrepare;
      PREPARE mysqlPrepare FROM @mysqlText2;
      EXECUTE mysqlPrepare;
      DEALLOCATE PREPARE mysqlPrepare;
      SET done = 0;
      OPEN templatesPeriodsCursor;
        templatesPeriodsLoop:LOOP
          FETCH templatesPeriodsCursor INTO period;
          IF done
            THEN LEAVE templatesPeriodsLoop;
          END IF;
          SET templatesPeriods = JSON_MERGE(templatesPeriods, JSON_ARRAY(period));
          ITERATE templatesPeriodsLoop;
        END LOOP;
      CLOSE templatesPeriodsCursor;
      SET templatesPeriodsLength = JSON_LENGTH(templatesPeriods);
      DROP VIEW IF EXISTS custom_data_view;
      SET done = 0;
      OPEN templatesCursor;
        templatesLoop: LOOP
          FETCH templatesCursor INTO templateID, typeName;
          IF done
            THEN LEAVE templatesLoop;
          END IF;
          SET searchResult = JSON_SEARCH(templates, "one", typeName, NULL, "$[*].name");
          SET templateInfoItems = JSON_ARRAY();
          SET iterator = 0;
          templatePeriodsLoop:LOOP
            IF iterator >= templatesPeriodsLength
              THEN LEAVE templatePeriodsLoop;
            END IF;
            SET period = JSON_UNQUOTE(JSON_EXTRACT(templatesPeriods, CONCAT("$[", iterator, "]")));
            IF dataPeriodName = "date"
              THEN SELECT COUNT(*) INTO templatePeriodItemsCount FROM companies WHERE template_id = templateID AND IF(dataBank, bank_id = bankID, 1) AND IF(dataFree, type_id = 10, 1) AND DATE(company_date_create) = DATE(period);
              ELSE SELECT COUNT(*) INTO templatePeriodItemsCount FROM companies WHERE template_id = templateID AND IF(dataBank, bank_id = bankID, 1) AND IF(dataFree, type_id = 10, 1) AND DATE(company_date_create) = DATE(dataDateStart) AND HOUR(company_date_create) = HOUR(period) AND MINUTE(company_date_create) = MINUTE(period);
            END IF;
            SET templateInfoItems = JSON_MERGE(templateInfoItems, JSON_ARRAY(templatePeriodItemsCount));
            SET iterator = iterator + 1;
            ITERATE templatePeriodsLoop;
          END LOOP;
          IF searchResult IS NULL
            THEN SET templates = JSON_MERGE(templates, JSON_OBJECT(
              "name", typeName,
              "infoItems", templateInfoItems,
              "items", JSON_ARRAY()
            ));
            ELSE BEGIN
              SET searchResult = REPLACE(searchResult, ".name", ".infoItems");
              SET templateInfoItemsCount = templateInfoItemsCount + JSON_UNQUOTE(JSON_EXTRACT(templates, searchResult));
              SET templates = JSON_SET(templates, searchResult, templateInfoItemsCount);
            END;
          END IF;
          ITERATE templatesLoop;
        END LOOP;
      CLOSE templatesCursor;
      SET done = 0;
      OPEN companiesCursor;
        companiesLoop: LOOP
          FETCH companiesCursor INTO period;
          IF done 
            THEN LEAVE companiesLoop;
          END IF;
          IF periodName != "date"
            THEN SET labels = JSON_MERGE(labels, JSON_ARRAY(CONCAT(HOUR(period), " - ", HOUR(period) + 1)));
            ELSE SET labels = JSON_MERGE(labels, JSON_ARRAY(period));
          END IF;
          OPEN templatesCursor;
            templatesLoop: LOOP
              FETCH templatesCursor INTO templateID, typeName;
              IF done 
                THEN LEAVE templatesLoop;
              END IF;
              IF periodName = "date"
                THEN SELECT COUNT(*) INTO templateItemsCount FROM companies WHERE DATE(company_date_update) = DATE(period) AND JSON_CONTAINS(types, JSON_ARRAY(type_id)) > 0 AND template_id = templateID AND bank_id = bankID AND IF(user > 0, user_id = user, 1);
                ELSE SELECT COUNT(*) INTO templateItemsCount FROM companies WHERE HOUR(company_date_update) = HOUR(period) AND DATE(company_date_update) BETWEEN DATE(dateStart) AND DATE(dateEnd) AND JSON_CONTAINS(types, JSON_ARRAY(type_id)) > 0 AND template_id = templateID AND bank_id = bankID AND IF(user > 0, user_id = user, 1);
              END IF;
              SET searchResult = JSON_UNQUOTE(JSON_SEARCH(templates, "one", typeName, NULL, "$[*].name"));
              SET searchResult = REPLACE(searchResult, ".name", ".items");
              SET templateItems = JSON_EXTRACT(templates, searchResult);
              SET templateItems = JSON_MERGE(templateItems, JSON_ARRAY(templateItemsCount));
              SET templates = JSON_SET(templates, searchResult, templateItems);
              ITERATE templatesLoop;
            END LOOP;
          CLOSE templatesCursor;
          SET done = 0;
          ITERATE companiesLoop;
        END LOOP;
      CLOSE companiesCursor;
      DROP VIEW IF EXISTS custom_statistic_view;
      SET responce = JSON_MERGE(responce, JSON_OBJECT(
        "type", "sendToSocket",
        "data", JSON_OBJECT(
          "socketID", connectionApiID,
          "data", JSON_ARRAY(
            JSON_OBJECT(
              "type", "merge",
              "data", JSON_OBJECT(
                "statistic", JSON_OBJECT(
                  "labels", labels,
                  "templates", templates,
                  "typeToView", typeToView,
                  "period", periodToView,
                  "dateStart", date(dateStart),
                  "dateEnd", date(dateEnd),
                  "user", user,
                  "users", getUsers(bankID),
                  "dataLabels", templatesPeriods,
                  "dataPeriod", dataPeriod,
                  "dataFree", dataFree,
                  "dataBank", dataBank,
                  "dataDateStart", dataDateStart,
                  "dataDateEnd", dataDateEnd
                )
              )
            )
          )
        )
      ));
    END;
    ELSE SET responce = JSON_MERGE(responce, JSON_OBJECT(
      "type", "sendToSocket",
      "data", JSON_OBJECT(
        "socketID", connectionApiID,
        "data", JSON_ARRAY(JSON_OBJECT(
          "type", "merge",
          "data", JSON_OBJECT(
            "auth", 0,
            "loginMessage", "Требуется ручной вход в систему"
          )
        ))
      )
    ));
  END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getDownloadPreview` (IN `userID` INT(11), OUT `responce` JSON)  NO SQL
BEGIN
  DECLARE limitOption, offsetOption, ordersLength, iterator, keysLength, companiesCount INT(11);
  DECLARE done TINYINT(1);
  DECLARE translateTo VARCHAR(128);
  DECLARE company, orders, orderObject, companies, keysNames, files JSON;
  DECLARE companiesCursor CURSOR FOR SELECT company_json FROM custom_download_view;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
  SET responce = JSON_ARRAY();
  SET companies = JSON_ARRAY();
  SET files = JSON_ARRAY();
  SELECT 
    state_json ->> "$.download.limit",
    state_json ->> "$.download.offset",
    state_json ->> "$.download.orders"
  INTO 
    limitOption,
    offsetOption,
    orders
  FROM 
    states
  WHERE user_id = userID ORDER BY state_id DESC LIMIT 1;
  SET ordersLength = JSON_LENGTH(orders);
  SET @mysqlText = CONCAT(
    "CREATE VIEW custom_download_view AS SELECT company_json FROM companies WHERE user_id = ",
    userID,
    " AND type_id = 20"
  );
  IF ordersLength > 0
    THEN BEGIN
      SET iterator = 0;
      SET @mysqlText = CONCAT(
        @mysqlText,
        " ORDER BY"
      );
      ordersLoop: LOOP
        IF iterator >= ordersLength
          THEN LEAVE ordersLoop;
        END IF;
        SET orderObject = JSON_EXTRACT(orders, CONCAT("$[", iterator, "]"));
        SET @mysqlText = CONCAT(
          @mysqlText,
          IF(iterator = 0, " ", ", "),
          JSON_UNQUOTE(JSON_EXTRACT(orderObject, "$.name")),
          IF(JSON_UNQUOTE(JSON_EXTRACT(orderObject, "$.desc")), " DESC", "")
        );
        SET iterator = iterator + 1;
        ITERATE ordersLoop;
      END LOOP;
    END;
  END IF;
  SET @mysqlText = CONCAT(
    @mysqlText,
    " LIMIT ",
    limitOption,
    " OFFSET ",
    offsetOption
  );
  PREPARE mysqlPrepare FROM @mysqlText;
  EXECUTE mysqlPrepare;
  DEALLOCATE PREPARE mysqlPrepare;
  SET done = 0;
  OPEN companiesCursor;
    companiesLoop: LOOP
      FETCH companiesCursor INTO company;
      IF done
        THEN LEAVE companiesLoop;
      END IF;
      SET company = JSON_REMOVE(company,
        "$.city_id",
        "$.region_id",
        "$.type_id",
        "$.company_id",
        "$.template_id",
        "$.company_comment",
        "$.company_date_call_back",
        "$.call_type"
      );
      SET companies = JSON_MERGE(companies, company);
      ITERATE companiesLoop;
    END LOOP;
  CLOSE companiesCursor;
  DROP VIEW IF EXISTS custom_download_view;
  IF company IS NOT NULL
    THEN BEGIN
      SET keysNames = JSON_KEYS(company);
      SET keysLength = JSON_LENGTH(keysNames);
      SET iterator = 0;
      translateLoop: LOOP
        IF iterator >= keysLength
          THEN LEAVE translateLoop;
        END IF;
        SET translateTo = (SELECT translate_to FROM translates WHERE translate_from = JSON_UNQUOTE(JSON_EXTRACT(keysNames, CONCAT("$[", iterator, "]"))));
        IF translateTo IS NOT NULL
          THEN SET keysNames = JSON_SET(keysNames, CONCAT("$[", iterator, "]"), JSON_OBJECT(
            "param", JSON_UNQUOTE(JSON_EXTRACT(keysNames, CONCAT("$[", iterator, "]"))),
            "name", translateTo
          ));
        END IF;
        SET iterator = iterator + 1;
        ITERATE translateLoop;
      END LOOP;
      SELECT count(*) INTO companiesCount FROM companies WHERE user_id = userID AND type_id = 20;
      SET responce = sendToAllUserSockets(userID, JSON_ARRAY(
        JSON_OBJECT(
          "type", "merge",
          "data", JSON_OBJECT(
            "downloadCompanies", companies,
            "downloadCompaniesColumnsNames", keysNames
          )
        ),
        JSON_OBJECT(
          "type", "mergeDeep",
          "data", JSON_OBJECT(
            "download", JSON_OBJECT(
              "companiesCount", companiesCount
            )
          )
        )
      ));
    END;
    ELSE SET responce = sendToAllUserSockets(userID, JSON_ARRAY(
      JSON_OBJECT(
        "type", "mergeDeep",
        "data", JSON_OBJECT(
          "download", JSON_OBJECT(
            "message", "Компаний для формирования файла не обнаружено"
          )
        )
      ),
      JSON_OBJECT(
        "type", "merge",
        "data", JSON_OBJECT(
          "downloadCompanies", JSON_ARRAY(),
          "downloadCompaniesColumnsNames", JSON_ARRAY()
        )
      )
    ));
  END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `newCompanies` (IN `companies` JSON, OUT `responce` JSON)  NO SQL
BEGIN
  DECLARE companiesLength, templateID, templateСoncurrences, companiesKeysLength, iterator, iterator2, secondsDiff, microsecondsDiff, banksCount, bankID, insertCompaniesCount INT(11);
  DECLARE message, columnValue TEXT;
  DECLARE columnName VARCHAR(128);
  DECLARE templateColumnLetters VARCHAR(3);
  DECLARE endDate, startDate VARCHAR(26);
  DECLARE columns, companiesKeys, company, refreshResponce JSON;
  DECLARE done TINYINT(1);
  DECLARE templateCursor CURSOR FOR SELECT column_name, template_column_letters FROM custom_template_columns_view;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
  SET startDate = NOW(6);
  SET companiesLength = JSON_LENGTH(companies);
  SET responce = JSON_ARRAY();
  IF companies IS NOT NULL AND companiesLength > 1
    THEN BEGIN
      SET columns = JSON_EXTRACT(companies, "$.columns");
      SET companies = JSON_REMOVE(companies, "$.columns");
      SET companiesLength = companiesLength - 1;
      SET companiesKeys = JSON_KEYS(columns);
      SET companiesKeysLength = JSON_LENGTH(companiesKeys);
      SELECT template_id, COUNT(template_column_name) weight INTO templateID, templateСoncurrences FROM template_columns WHERE JSON_CONTAINS(companiesKeys, JSON_ARRAY(template_column_letters)) AND template_column_name = JSON_UNQUOTE(JSON_EXTRACT(columns, CONCAT("$.", template_column_letters))) group by template_id order by weight desc limit 1;
      IF templateID IS NOT NULL 
        THEN BEGIN
          IF templateСoncurrences = companiesKeysLength
            THEN BEGIN
              SET @mysqlText = CONCAT(
                "CREATE VIEW custom_template_columns_view AS SELECT column_name, template_column_letters FROM template_columns_view WHERE template_id = ",
                templateID,
                " AND template_column_duplicate = 0 AND JSON_CONTAINS('",
                companiesKeys,
                "', JSON_ARRAY(template_column_letters))"
              );
              PREPARE mysqlPrepare FROM @mysqlText;
              EXECUTE mysqlPrepare;
              DEALLOCATE PREPARE mysqlPrepare;
              SET done = 0;
              SET companiesKeys = JSON_ARRAY();
              SET @mysqlText = "INSERT LOW_PRIORITY IGNORE INTO companies (template_id, ";
              OPEN templateCursor;
                templateLoop: LOOP
                  FETCH templateCursor INTO columnName, templateColumnLetters;
                  IF done 
                    THEN LEAVE templateLoop;
                  END IF;
                  SET companiesKeys = JSON_MERGE(companiesKeys, JSON_OBJECT(
                    "letters", templateColumnLetters, 
                    "column", columnName
                  ));
                  SET @mysqlText = CONCAT(
                    @mysqlText,
                    ",",
                    columnName
                  );
                  ITERATE templateLoop;
                END LOOP;
              CLOSE templateCursor;
              SET @mysqlText = REPLACE(@mysqlText, "template_id, ,", "template_id,");
              SET @mysqlText = CONCAT(@mysqlText, ") VALUES ");
              DROP VIEW IF EXISTS custom_template_columns_view;
              SET iterator = 0;
              SET companiesKeysLength = JSON_LENGTH(companiesKeys);
              companiesLoop: LOOP
                IF iterator >= companiesLength
                  THEN LEAVE companiesLoop;
                END IF;
                SET company = JSON_EXTRACT(companies, CONCAT("$.r", iterator + 1));
                SET @mysqlText = CONCAT(@mysqlText, "(", templateID, ", ");
                SET iterator2 = 0;
                companyLoop: LOOP
                  IF iterator2 >= companiesKeysLength
                    THEN LEAVE companyLoop;
                  END IF;
                  SET templateColumnLetters = JSON_UNQUOTE(JSON_EXTRACT(companiesKeys, CONCAT("$[", iterator2, "].letters")));
                  SET columnValue = JSON_UNQUOTE(JSON_EXTRACT(company, CONCAT("$.", templateColumnLetters)));
                  SET @mysqlText = CONCAT(
                    @mysqlText,
                    IF(iterator2 = 0, "", ","),
                    IF(columnValue IS NULL, "NULL", CONCAT("'", columnValue, "'"))
                  );
                  SET iterator2 = iterator2 + 1;
                  ITERATE companyLoop;
                END LOOP;
                SET @mysqlText = CONCAT(@mysqlText, ")", IF(iterator = companiesLength - 1, "", ","));
                SET iterator = iterator + 1;
                ITERATE companiesLoop;
              END LOOP;
              SELECT company_id INTO insertCompaniesCount FROM companies ORDER BY company_id DESC LIMIT 1;
              PREPARE mysqlPrepare FROM @mysqlText;
              EXECUTE mysqlPrepare;
              DEALLOCATE PREPARE mysqlPrepare;
              DELETE LOW_PRIORITY c from companies c, empty_companies_view ecv where c.company_id = ecv.company_id;
              SELECT count(*) INTO insertCompaniesCount FROM companies WHERE company_id > insertCompaniesCount;
              UPDATE LOW_PRIORITY companies SET company_json = JSON_SET(company_json, "$.company_id", company_id) WHERE company_json ->> "$.company_id" = 0;
              SET message = CONCAT(
                "Добавленно ",
                insertCompaniesCount,
                " компаний из ",
                companiesLength,
                ". Удалено ",
                companiesLength - insertCompaniesCount
              );
              SELECT COUNT(DISTINCT bank_id) INTO banksCount FROM (SELECT bank_id FROM companies ORDER BY company_id DESC LIMIT insertCompaniesCount) companies WHERE bank_id IS NOT NULL;
              SET iterator = 0;
              banksLoop: LOOP           
                IF iterator >= banksCount
                  THEN LEAVE banksLoop;
                END IF;
                SELECT DISTINCT bank_id INTO bankID FROM (SELECT bank_id FROM companies ORDER BY company_id DESC LIMIT insertCompaniesCount) companies WHERE bank_id IS NOT NULL LIMIT 1 OFFSET iterator;
                SET refreshResponce = JSON_ARRAY();
                CALL refreshBankSupervisors(bankID, refreshResponce);
                IF JSON_LENGTH(refreshResponce) > 0 
                  THEN SET responce = JSON_MERGE(responce, refreshResponce);
                END IF;
                SET iterator = iterator + 1;
                ITERATE banksLoop;
              END LOOP;
            END;
            ELSE SET message = CONCAT("Не все колонки соответствуют шаблону ", templateID, " (", templateСoncurrences, "/", companiesKeysLength, ")");
          END IF;
        END;
        ELSE SET message = "Не удалось обнаружить шаблон";
      END IF;
    END;
    ELSE SET message = "Нет компаний для загрузки";
  END IF;
  SET endDate = SYSDATE(6);
  SET secondsDiff = TO_SECONDS(endDate) - TO_SECONDS(startDate);
  IF secondsDiff = 0
    THEN SET microsecondsDiff = MICROSECOND(endDate) - MICROSECOND(startDate);
    ELSE BEGIN
      SET secondsDiff = secondsDiff - 1;
      SET microsecondsDiff = 1000000 - MICROSECOND(startDate) + MICROSECOND(endDate);
      SET secondsDiff = secondsDiff + TRUNCATE(microsecondsDiff / 1000000, 0);
      SET microsecondsDiff = microsecondsDiff % 1000000;
    END;
  END IF;
  SET message = CONCAT(message, ". Затраченное время в секундах: ", secondsDiff, ".", microsecondsDiff);
  SET responce = JSON_MERGE(responce, JSON_OBJECT(
    "type", "print",
    "data", JSON_OBJECT(
      "message", message
    )
  ));
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `refreshBankSupervisors` (IN `bankID` INT(11), OUT `responce` JSON)  NO SQL
BEGIN
  DECLARE userID INT(11);
  DECLARE connectionHash VARCHAR(32);
  DECLARE done TINYINT(1);
  DECLARE statisticResponce JSON;
  DECLARE usersCursor CURSOR FOR SELECT user_id, connection_hash FROM users_connections_view WHERE connection_end = 0 AND connection_type_id = 3 AND type_id IN (1, 19) AND bank_id = bankID;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
  SET responce = JSON_ARRAY();
  OPEN usersCursor;
    usersLoop: LOOP
      FETCH usersCursor INTO userID, connectionHash;
      IF done
        THEN LEAVE usersLoop;
      END IF;
      CALL getBankStatistic(connectionHash, statisticResponce);
      SET responce = JSON_MERGE(responce, statisticResponce);
      ITERATE usersLoop;
    END LOOP;
  CLOSE usersCursor;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `reserveCompanies` (IN `connectionHash` VARCHAR(32) CHARSET utf8, OUT `responce` JSON)  NO SQL
BEGIN
  DECLARE typesLength, regionsLength, nullColumnsLength, notNullColumnsLength, ordersLength, columnID, regionID, limitOption, offsetOption, iterator, companyID, banksLength, userID INT(11);
  DECLARE type INT(2);
  DECLARE columnName, connectionApiID VARCHAR(128);
  DECLARE regionName VARCHAR(60);
  DECLARE types, regions, nullColumns, notNullColumns, company, companies, allColumns, allRegions, orders, orderObject, companiesID, banks JSON;
  DECLARE dateStart, dateEnd VARCHAR(10);
  DECLARE done, descOption, connectionValid TINYINT(1);
  DECLARE companiesCursor CURSOR FOR SELECT company_json, company_id FROM custom_download_view;
  DECLARE columnsCursor CURSOR FOR SELECT column_name FROM custom_columns_view;
  DECLARE allColumnsCursor CURSOR FOR SELECT column_id, column_name FROM columns;
  DECLARE allRegionsCursor CURSOR FOR SELECT region_id, region_name FROM regions;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
  SET connectionValid = checkRootConnection(connectionHash);
  SELECT user_id, connection_api_id INTO userID, connectionApiID FROM users_connections_view WHERE connection_hash = connectionHash;
  SET responce = JSON_ARRAY();
  IF connectionValid
    THEN BEGIN
      SET companies = JSON_ARRAY();
      SET companiesID = JSON_ARRAY();
      SET allRegions = JSON_ARRAY();
      SET allColumns = JSON_ARRAY();
      UPDATE companies SET type_id = 10, user_id = NULL WHERE user_id = userID AND type_id = 20;
      SELECT 
        state_json ->> "$.download.types",
        state_json ->> "$.download.dateStart",
        state_json ->> "$.download.dateEnd",
        state_json ->> "$.download.regions",
        state_json ->> "$.download.nullColumns",
        state_json ->> "$.download.notNullColumns",
        state_json ->> "$.download.type",
        state_json ->> "$.download.count",    
        state_json ->> "$.download.banks"
      INTO  
        types,
        dateStart,
        dateEnd,
        regions,
        nullColumns,
        notNullColumns,
        type,
        limitOption,
        banks
      FROM states WHERE user_id = userID ORDER BY state_id DESC LIMIT 1;
      SET typesLength = JSON_LENGTH(types);
      SET regionsLength = JSON_LENGTH(regions);
      SET nullColumnsLength = JSON_LENGTH(nullColumns);
      SET notNullColumnsLength = JSON_LENGTH(notNullColumns);
      SET ordersLength = JSON_LENGTH(orders);
      SET banksLength = JSON_LENGTH(banks); 
      SET @mysqlText = CONCAT(
        "UPDATE companies SET type_id = 20, user_id = ", userID, " WHERE DATE(company_date_create)",
        IF(dateStart = dateEnd, "=", " BETWEEN "),
        IF(dateStart = dateEnd, CONCAT("DATE('", dateStart, "')"), CONCAT("DATE('", dateStart, "') AND DATE('", dateEnd, "')")),
        IF(typesLength > 0, CONCAT(" AND JSON_CONTAINS('", types, "', JSON_ARRAY(type_id))"), ""),
        IF(regionsLength > 0, CONCAT(" AND JSON_CONTAINS('", regions, "', JSON_ARRAY(region_id))"), ""),
        IF(banksLength > 0, CONCAT(" AND JSON_CONTAINS('", banks, "', JSON_ARRAY(bank_id))"), "")
      );
      IF nullColumnsLength > 0 
        THEN BEGIN
          SET done = 0;
          SET @mysqlText2 = CONCAT(
            "CREATE VIEW custom_columns_view AS SELECT column_name FROM columns WHERE JSON_CONTAINS('",
            nullColumns,
            "', JSON_ARRAY(column_id))"
          );
          PREPARE mysqlPrepare FROM @mysqlText2;
          EXECUTE mysqlPrepare;
          DEALLOCATE PREPARE mysqlPrepare;
          OPEN columnsCursor;
            columnsLoop: LOOP
              FETCH columnsCursor INTO columnName;
              IF done 
                THEN LEAVE columnsLoop;
              END IF;
              SET @mysqlText = CONCAT(
                @mysqlText, 
                " AND ",
                columnName,
                " IS NULL"
              );
              ITERATE columnsLoop;
            END LOOP;
          CLOSE columnsCursor;
          DROP VIEW IF EXISTS custom_columns_view;
        END;
      END IF;
      IF notNullColumnsLength > 0 
        THEN BEGIN
          SET done = 0;
          SET @mysqlText2 = CONCAT(
            "CREATE VIEW custom_columns_view AS SELECT column_name FROM columns WHERE JSON_CONTAINS('",
            notNullColumns,
            "', JSON_ARRAY(column_id))"
          );
          PREPARE mysqlPrepare FROM @mysqlText2;
          EXECUTE mysqlPrepare;
          DEALLOCATE PREPARE mysqlPrepare;
          OPEN columnsCursor;
            columnsLoop: LOOP
              FETCH columnsCursor INTO columnName;
              IF done 
                THEN LEAVE columnsLoop;
              END IF;
              SET @mysqlText = CONCAT(
                @mysqlText, 
                " AND ",
                columnName,
                " IS NOT NULL"
              );
              ITERATE columnsLoop;
            END LOOP;
          CLOSE columnsCursor;
          DROP VIEW IF EXISTS custom_columns_view;
        END;
      END IF;
      SET @mysqlText = CONCAT(@mysqlText, " LIMIT ", limitOption);
      PREPARE mysqlPrepare FROM @mysqlText;
      EXECUTE mysqlPrepare;
      DEALLOCATE PREPARE mysqlPrepare;
      CALL getDownloadPreview(userID, responce);
    END;
    ELSE SET responce = JSON_MERGE(responce, JSON_OBJECT(
      "type", "sendToSocket",
      "data", JSON_OBJECT(
        "socketID", connectionApiID,
        "data", JSON_ARRAY(JSON_OBJECT(
          "type", "merge",
          "data", JSON_OBJECT(
            "auth", 0,
            "loginMessage", "Требуется ручной вход в систему"
          )
        ))
      )
    ));
  END IF;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `auth` (`connectionHash` VARCHAR(32) CHARSET utf8, `email` VARCHAR(512) CHARSET utf8, `pass` VARCHAR(128) CHARSET utf8) RETURNS JSON NO SQL
BEGIN
  DECLARE userHash VARCHAR(32);
    DECLARE connectionApiID VARCHAR(128);
    DECLARE userID, connectionID, activeCompaniesLength, typeID INT(11);
    DECLARE connectionEnd, ringing TINYINT(1);
    DECLARE responce, activeCompanies, downloadFilters, distributionFilters JSON;
    SET responce = JSON_ARRAY();
    SET activeCompanies = JSON_ARRAY();
    SELECT user_id, type_id INTO userID, typeID FROM users WHERE LOWER(user_email) = LOWER(email) AND user_password = pass;
    SELECT connection_id, connection_end, connection_api_id INTO connectionID, connectionEnd, connectionApiID FROM connections WHERE connection_hash = connectionHash;
    IF userID IS NOT NULL AND connectionID IS NOT NULL AND connectionEnd = 0
        THEN BEGIN 
            UPDATE users SET user_auth = 1 WHERE user_id = userID;
            UPDATE connections SET user_id = userID WHERE connection_id = connectionID;
            SELECT user_hash INTO userHash FROM users WHERE user_id = userID;
            SET responce = JSON_MERGE(responce, 
                JSON_OBJECT(
                    "type", "sendToSocket",
                    "data", JSON_OBJECT(
                        "socketID", connectionApiID,
                        "data", JSON_ARRAY(
                            JSON_OBJECT(
                                "type", "merge",
                                "data", JSON_OBJECT(
                                    "loginMessage", "Авторизация прошла успешно",
                                    "auth", 1,
                                    "userType", typeID
                                )
                            ),
                            JSON_OBJECT(
                                "type", "save",
                                "data", JSON_OBJECT(
                                    "userHash", userHash
                                )
                            )
                        )
                    )
                )
            );
            IF typeID = 1 OR typeID = 18 
                THEN BEGIN
                    SET activeCompanies = getActiveBankUserCompanies(connectionID);
                    SET activeCompaniesLength = JSON_LENGTH(activeCompanies);
                    SELECT user_ringing INTO ringing FROM users WHERE user_id = userID;
                    SELECT state_json ->> "$.distribution" INTO distributionFilters FROM states WHERE connection_id = connectionID;
                    IF activeCompaniesLength > 0
                        THEN SET responce = JSON_MERGE(responce, JSON_OBJECT(
                            "type", "sendToSocket",
                            "data", JSON_OBJECT(
                                "socketID", connectionApiID,
                                "data", JSON_ARRAY(JSON_OBJECT(
                                    "type", "merge",
                                    "data", JSON_OBJECT(
                                        "companies", activeCompanies,
                                        "distribution", distributionFilters,
                                        "message", CONCAT("Загружено компаний: ", activeCompaniesLength),
                                        "ringing", ringing
                                    )
                                ))
                            )
                        ));
                        ELSE SET responce = JSON_MERGE(responce, JSON_OBJECT(
                            "type", "sendToSocket",
                            "data", JSON_OBJECT(
                                "socketID", connectionApiID,
                                "data", JSON_ARRAY(JSON_OBJECT(
                                    "type", "merge",
                                    "data", JSON_OBJECT(
                                        "distribution", distributionFilters
                                    )
                                ))
                            )
                        ));
                    END IF;
                END;
            END IF; 
            IF typeID = 1 OR typeID = 19
                THEN BEGIN
                    SET responce = JSON_MERGE(responce, JSON_OBJECT(
                        "type", "procedure",
                        "data", JSON_OBJECT(
                            "query", "getBankStatistic",
                            "values", JSON_ARRAY(
                                CONCAT(connectionHash)
                            )
                        )
                    ));
                END;
            END IF;
            IF typeID = 1
                THEN BEGIN
                    SELECT state_json ->> "$.download" INTO downloadFilters FROM states WHERE user_id = userID ORDER BY state_id DESC LIMIT 1;
                    SET responce = JSON_MERGE(responce, JSON_ARRAY(
                        JSON_OBJECT(
                            "type", "sendToSocket",
                            "data", JSON_OBJECT(
                                "socketID", connectionApiID,
                                "data", JSON_ARRAY(
                                    JSON_OBJECT(
                                        "type", "merge",
                                        "data", JSON_OBJECT(
                                            "download", downloadFilters,
                                            "banks", getBanks(),
                                            "regions", getRegions(),
                                            "columns", getColumns(),
                                            "files", getUserFiles(userID)
                                        )
                                    )
                                )
                            )
                        )
                    ));
                    SET responce = JSON_MERGE(responce, JSON_OBJECT(
                        "type", "procedure",
                        "data", JSON_OBJECT(
                            "query", "getDownloadPreview",
                            "values", JSON_ARRAY(
                                userID
                            )
                        )
                    ));
                END;
            END IF;
        END;
        ELSE SET responce = JSON_MERGE(responce, 
            JSON_OBJECT(
              "type", "sendToSocket",
                "data", JSON_OBJECT(
                    "socketID", connectionApiID,
                    "data", JSON_ARRAY(
                        JSON_OBJECT(
                          "type", "merge",
                            "data", JSON_OBJECT(
                                "loginMessage", "Не верный email или пароль",
                                "auth", 0
                            )
                        )
                    ) 
                )
            )
        );
    END IF;
    RETURN responce;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `autoAuth` (`userHash` VARCHAR(32) CHARSET utf8, `connectionHash` VARCHAR(32) CHARSET utf8) RETURNS JSON NO SQL
BEGIN
  DECLARE connectionID, userID, activeCompaniesLength, typeID INT(11);
    DECLARE connectionApiID VARCHAR(128);
    DECLARE userAuth, connectionEnd, ringing TINYINT(1);
    DECLARE responce, activeCompanies, downloadFilters, distributionFilters JSON;
    SET responce = JSON_ARRAY();
  SELECT connection_id, connection_end, connection_api_id INTO connectionID, connectionEnd, connectionApiID FROM connections WHERE connection_hash = connectionHash;
    SELECT user_id, user_auth, type_id INTO userID, userAuth, typeID FROM users WHERE user_hash = userHash;
    IF connectionID IS NULL OR userAuth = 0 OR connectionEnd = 1 OR userID IS NULL
      THEN SET responce = JSON_MERGE(responce, JSON_OBJECT(
          "type", "sendToSocket",
            "data", JSON_OBJECT(
                "socketID", connectionApiID,
                "data", JSON_ARRAY(JSON_OBJECT(
                  "type", "merge",
                    "data", JSON_OBJECT(
                        "loginMessage", "Требуется ручная авторизация",
                        "auth", 0,
                        "try", 1
                    )
                ))
            )
        ));
        ELSE BEGIN
            UPDATE connections SET user_id = userID WHERE connection_id = connectionID;
            SELECT user_hash INTO userHash FROM users WHERE user_id = userID;
            SET responce = JSON_MERGE(responce, JSON_OBJECT(
              "type", "sendToSocket",
                "data", JSON_OBJECT(
                    "socketID", connectionApiID,
                    "data", JSON_ARRAY(
                        JSON_OBJECT(
                          "type", "merge",
                            "data", JSON_OBJECT(
                                "loginMessage", "Авторизация прошла успешно",
                                "auth", 1,
                                "userType", typeID
                            )
                        ),
                        JSON_OBJECT(
                            "type", "save",
                            "data", JSON_OBJECT(
                                "userHash", userHash
                            )
                        )
                    )
                )
            ));
            IF typeID = 1 OR typeID = 18 
                THEN BEGIN
                    SET activeCompanies = getActiveBankUserCompanies(connectionID);
                    SET activeCompaniesLength = JSON_LENGTH(activeCompanies);
                    SELECT user_ringing INTO ringing FROM users WHERE user_id = userID;
                    SELECT state_json ->> "$.distribution" INTO distributionFilters FROM states WHERE connection_id = connectionID;
                    IF activeCompaniesLength > 0
                        THEN SET responce = JSON_MERGE(responce, JSON_OBJECT(
                            "type", "sendToSocket",
                            "data", JSON_OBJECT(
                                "socketID", connectionApiID,
                                "data", JSON_ARRAY(JSON_OBJECT(
                                    "type", "merge",
                                    "data", JSON_OBJECT(
                                        "companies", activeCompanies,
                                        "distribution", distributionFilters,
                                        "message", CONCAT("Загружено компаний: ", activeCompaniesLength),
                                        "ringing", ringing
                                    )
                                ))
                            )
                        ));
                        ELSE SET responce = JSON_MERGE(responce, JSON_OBJECT(
                            "type", "sendToSocket",
                            "data", JSON_OBJECT(
                                "socketID", connectionApiID,
                                "data", JSON_ARRAY(JSON_OBJECT(
                                    "type", "merge",
                                    "data", JSON_OBJECT(
                                        "distribution", distributionFilters
                                    )
                                ))
                            )
                        ));
                    END IF;
                END;
            END IF; 
            IF typeID = 1 OR typeID = 19
                THEN BEGIN
                    SET responce = JSON_MERGE(responce, JSON_OBJECT(
                        "type", "procedure",
                        "data", JSON_OBJECT(
                            "query", "getBankStatistic",
                            "values", JSON_ARRAY(
                                CONCAT(connectionHash)
                            )
                        )
                    ));
                END;
            END IF;
            IF typeID = 1
                THEN BEGIN
                    SELECT state_json ->> "$.download" INTO downloadFilters FROM states WHERE user_id = userID ORDER BY state_id DESC LIMIT 1;
                    SET responce = JSON_MERGE(responce, JSON_ARRAY(
                        JSON_OBJECT(
                            "type", "sendToSocket",
                            "data", JSON_OBJECT(
                                "socketID", connectionApiID,
                                "data", JSON_ARRAY(
                                    JSON_OBJECT(
                                        "type", "merge",
                                        "data", JSON_OBJECT(
                                            "download", downloadFilters,
                                            "banks", getBanks(),
                                            "regions", getRegions(),
                                            "columns", getColumns(),
                                            "files", getUserFiles(userID)
                                        )
                                    )
                                )
                            )
                        )
                    ));
                    SET responce = JSON_MERGE(responce, JSON_OBJECT(
                        "type", "procedure",
                        "data", JSON_OBJECT(
                            "query", "getDownloadPreview",
                            "values", JSON_ARRAY(
                                userID
                            )
                        )
                    ));
                END;
            END IF;
        END;
    END IF;
    RETURN responce;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `callRequest` (`connectionHash` VARCHAR(32) CHARSET utf8, `companyID` INT(11)) RETURNS JSON NO SQL
BEGIN
  DECLARE userID, callID INT(11);
  DECLARE connectionValid TINYINT(1);
  DECLARE userSip VARCHAR(20);
  DECLARE companyPhone VARCHAR(120);
  DECLARE responce JSON;
  SET responce = JSON_ARRAY();
  SET connectionValid = checkConnection(connectionHash);
  IF connectionValid
    THEN BEGIN
      SELECT user_sip, user_id INTO userSip, userID FROM users_connections_view WHERE connection_hash = connectionHash;
      SELECT company_phone INTO companyPhone FROM companies WHERE company_id = companyID;
      INSERT INTO calls (user_id, company_id, type_id) VALUES (userID, companyID, 33);
      SET responce = JSON_MERGE(responce, refreshUserCompanies(userID));
      SET responce = JSON_MERGE(responce, sendToAllUserSockets(userID, JSON_ARRAY(JSON_OBJECT(
        "type", "mergeDeep",
        "data", JSON_OBJECT(
          "message", CONCAT("соединение с ", companyPhone, " имеет статус: ожидание ответа от АТС")
        )
      ))));
      SET responce = JSON_MERGE(responce, JSON_OBJECT(
        "type", "sendToZadarma",
        "data", JSON_OBJECT(
          "options", JSON_OBJECT(
            "from", userSip,
            "to", companyPhone,
            "predicted", true
          ),
          "method", "request/callback",
          "type", "GET"
        )
      ));
    END;
    ELSE SET responce = JSON_MERGE(responce, JSON_OBJECT(
      "type", "sendToSocket",
      "data", JSON_OBJECT(
        "socketID", connectionApiID,
        "data", JSON_ARRAY(JSON_OBJECT(
          "type", "merge",
          "data", JSON_OBJECT(
            "auth", 0,
            "loginMessage", "Требуется ручной вход в систему"
          )
        ))
      )
    ));
  END IF;
  RETURN responce;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `checkCompaniesInn` (`userID` INT(11)) RETURNS JSON NO SQL
BEGIN
  DECLARE companyID INT(11);
  DECLARE companyInn VARCHAR(12);
  DECLARE responce, company, companies JSON;
  DECLARE done TINYINT(1);
  DECLARE companiesCursor CURSOR FOR SELECT company_id, company_inn FROM companies WHERE user_id = userID AND type_id = 44;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
  SET responce = JSON_ARRAY();
  SET companies = JSON_ARRAY();
  OPEN companiesCursor;
    companiesLoop: LOOP
      FETCH companiesCursor INTO companyID, companyInn;
      IF done
        THEN LEAVE companiesLoop;
      END IF;
      SET company = JSON_OBJECT(
        "company_id", companyID,
        "company_inn", companyInn
      );
      SET companies = JSON_MERGE(companies, company);
      ITERATE companiesLoop;
    END LOOP;
  CLOSE companiesCursor;
  IF JSON_LENGTH(companies) > 0
    THEN SET responce = JSON_MERGE(responce, JSON_OBJECT(
      "type", "checkDuplicates",
      "data", JSON_OBJECT(
        "companies", companies,
        "user_id", userID
      )
    ));
  END IF;
  RETURN responce;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `checkConnection` (`connectionHash` VARCHAR(32) CHARSET utf8) RETURNS TINYINT(1) NO SQL
BEGIN
  DECLARE userID, userAuth INT(11);
  DECLARE connectionEnd, responce TINYINT(1);
  SELECT user_id, user_auth, connection_end INTO userID, userAuth, connectionEnd FROM users_connections_view WHERE connection_hash = connectionHash;
  IF userID IS NOT NULL AND userAuth = 1 AND connectionEnd = 0
    THEN SET responce = 1;
    ELSE SET responce = 0;
  END IF;
  RETURN responce;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `checkRootConnection` (`connectionHash` VARCHAR(32) CHARSET utf8) RETURNS TINYINT(1) NO SQL
BEGIN
  DECLARE userID, userAuth, typeID INT(11);
  DECLARE connectionEnd, responce TINYINT(1);
  SELECT user_id, user_auth, connection_end INTO userID, userAuth, connectionEnd FROM users_connections_view WHERE connection_hash = connectionHash;
  SELECT type_id INTO typeID FROM users WHERE user_id = userID;
  IF userID IS NOT NULL AND userAuth = 1 AND connectionEnd = 0 AND typeID = 1
    THEN SET responce = 1;
    ELSE SET responce = 0;
  END IF;
  RETURN responce;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `companiesCleaning` () RETURNS JSON NO SQL
BEGIN
  DECLARE responce JSON;
  DECLARE companyInn VARCHAR(12);
  DECLARE companyOgrn VARCHAR(15);
  DECLARE companiesLength, deleteDuplicateCompaniesLength INT(11);
  DECLARE done TINYINT(1);
  DECLARE innCursor CURSOR FOR SELECT company_inn, length FROM duplicate_companies_inn_view;
  DECLARE ogrnCursor CURSOR FOR SELECT company_ogrn, length FROM duplicate_companies_ogrn_view;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
  SET deleteDuplicateCompaniesLength = 0;
  SET responce = JSON_OBJECT();
  OPEN innCursor;
    innLoop: LOOP
      FETCH innCursor INTO companyInn, companiesLength;
      IF done 
        THEN LEAVE innLoop;
      END IF;
      SET companiesLength = companiesLength - 1;
      DELETE FROM companies WHERE company_inn = companyInn ORDER BY company_date_create DESC LIMIT companiesLength;
      SET deleteDuplicateCompaniesLength = deleteDuplicateCompaniesLength + companiesLength;
      ITERATE innLoop;
    END LOOP;
  CLOSE innCursor;
  SET done = 0;
  OPEN ogrnCursor;
    innLoop: LOOP
      FETCH ogrnCursor INTO companyOgrn, companiesLength;
      IF done 
        THEN LEAVE innLoop;
      END IF;
      SET companiesLength = companiesLength - 1;
      DELETE FROM companies WHERE company_ogrn = companyOgrn ORDER BY company_date_create DESC LIMIT companiesLength;
      SET deleteDuplicateCompaniesLength = deleteDuplicateCompaniesLength + companiesLength;
      ITERATE innLoop;
    END LOOP;
  CLOSE ogrnCursor;
  SELECT COUNT(*) INTO companiesLength FROM empty_companies_view;
  DELETE c FROM empty_companies_view ecv JOIN companies c ON c.company_id = ecv.company_id;
  SET responce = JSON_SET(responce,
    "$.deleteDuplicateCompanies", deleteDuplicateCompaniesLength,
    "$.deleteEmptyCompanies", companiesLength
  );
  RETURN responce;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `createDownloadFile` (`connectionHash` VARCHAR(32) CHARSET utf8) RETURNS JSON NO SQL
BEGIN
  DECLARE connectionValid, done, translateDone TINYINT(1);
  DECLARE responce, companies, company, companyKeys, translateNames, companyArray JSON;
  DECLARE fileID, iterator, keysLength INT(11);
  DECLARE keyName, translateTo, connectionApiID VARCHAR(128);
  DECLARE userID INT(11) DEFAULT (SELECT user_id FROM connections WHERE connection_hash = connectionHash);
  DECLARE companiesCursor CURSOR FOR SELECT company_json FROM companies WHERE user_id = userID AND type_id = 20;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
  SET responce = JSON_ARRAY();
  SET connectionValid = checkRootConnection(connectionHash);
  SELECT connection_api_id INTO connectionApiID FROM connections WHERE connection_hash = connectionHash;
  IF connectionValid 
    THEN BEGIN
      SET companies = JSON_ARRAY();
      SET translateNames = JSON_ARRAY();
      INSERT INTO files (type_id, user_id) VALUES (22, userID);
      SELECT file_id INTO fileID FROM files WHERE user_id = userID AND type_id = 22 ORDER BY file_id DESC LIMIT 1;
      SET done = 0;
      SET translateDone = 0;
      OPEN companiesCursor;
        companiesLoop: LOOP
          FETCH companiesCursor INTO company;
          IF done
            THEN LEAVE companiesLoop;
          END IF;
          SET company = JSON_REMOVE(company, 
            "$.city_id",
            "$.company_id",
            "$.region_id",
            "$.template_id",
            "$.type_id"
          );
          SET companyKeys = JSON_KEYS(company);
          SET iterator = 0;
          SET keysLength = JSON_LENGTH(companyKeys);
          SET companyArray = JSON_ARRAY();
          companyKeysLoop:LOOP
            IF iterator >= keysLength
              THEN LEAVE companyKeysLoop;
            END IF;
            SET keyName = JSON_UNQUOTE(JSON_EXTRACT(companyKeys, CONCAT("$[", iterator, "]")));
            SET companyArray = JSON_MERGE(companyArray, JSON_ARRAY(JSON_EXTRACT(company, CONCAT("$.", keyName))));
            IF !translateDone
              THEN BEGIN
                SET translateTo = (SELECT translate_to FROM translates WHERE translate_from = keyName);
                IF translateTo IS NULL
                  THEN SET translateTo = keyName;
                END IF;
                SET translateNames = JSON_MERGE(translateNames, JSON_ARRAY(translateTo));
              END;
            END IF;
            SET iterator = iterator + 1;
            ITERATE companyKeysLoop;
          END LOOP;
          IF !translateDone
            THEN BEGIN
              SET translateDone = 1;
              SET companies = JSON_MERGE(companies, JSON_ARRAY(translateNames));
            END;
          END IF;
          SET companies = JSON_MERGE(companies, JSON_ARRAY(companyArray));
          ITERATE companiesLoop;
        END LOOP;
      CLOSE companiesCursor;
      UPDATE companies SET type_id = 22, file_id = fileID WHERE user_id = userID AND type_id = 20;
      SET responce = JSON_MERGE(responce, JSON_OBJECT(
        "type", "xlsxCreate",
        "data", JSON_OBJECT(
          "name", DATE(NOW()),
          "data", companies,
          "fileID", fileID
        )
      ));
      SET responce = JSON_MERGE(responce, sendToAllUserSockets(userID, JSON_ARRAY(
        JSON_OBJECT(
          "type", "merge",
          "data", JSON_OBJECT(
            "downloadCompanies", JSON_ARRAY(),
            "downloadCompaniesColumnsNames", JSON_ARRAY() 
          )
        ),
        JSON_OBJECT(
          "type", "mergeDeep",
          "data", JSON_OBJECT(
            "download", JSON_OBJECT(
              "message", "Компании отправленны на запись в файл"
            )
          )
        )
      )));
    END;
    ELSE SET responce = JSON_MERGE(responce, JSON_OBJECT(
      "type", "sendToSocket",
      "data", JSON_OBJECT(
        "socketID", connectionApiID,
        "data", JSON_ARRAY(JSON_OBJECT(
          "type", "merge",
          "data", JSON_OBJECT(
            "auth", 0,
            "loginMessage", "Требуется ручной вход в систему"
          )
        ))
      )
    ));
  END IF;
  RETURN responce;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `disconnectAll` () RETURNS TINYINT(4) NO SQL
BEGIN
  UPDATE connections SET connection_end = 1;
    RETURN 1;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `disconnectConnection` (`connectionApiID` VARCHAR(128) CHARSET utf8, `connectionHash` VARCHAR(32) CHARSET utf8) RETURNS JSON NO SQL
BEGIN
  DECLARE responce JSON;
  DECLARE userID, bankID INT(11);
  DECLARE userOnline TINYINT(1);
  SET responce = JSON_ARRAY();
  IF connectionApiID IS NOT NULL
    THEN BEGIN 
      SELECT user_id INTO userID FROM users_connections_view WHERE connection_api_id = connectionApiID;
      UPDATE connections SET connection_end = 1 WHERE connection_api_id = connectionApiID;
    END;
  END IF;
  IF connectionHash IS NOT NULL
    THEN BEGIN 
      SELECT user_id INTO userID FROM users_connections_view WHERE connection_hash = connectionHash;
      UPDATE connections SET connection_end = 1 WHERE connection_hash = connectionHash;
    END;
  END IF;
  IF userID IS NOT NULL
    THEN BEGIN 
      SELECT user_online, bank_id INTO userOnline, bankID FROM users WHERE user_id = userID;
      IF !userOnline AND bankID IS NOT NULL
        THEN SET responce = JSON_MERGE(responce, JSON_OBJECT(
          "type", "procedure",
          "data", JSON_OBJECT(
            "query", "refreshBankSupervisors",
            "values", JSON_ARRAY(
              bankID
            )
          )
        ));
      END IF;
    END;
  END IF;
  RETURN responce;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `getActiveBankUserCompanies` (`connectionID` INT(11)) RETURNS JSON NO SQL
BEGIN
  DECLARE userID INT(11) DEFAULT (SELECT user_id FROM connections WHERE connection_id = connectionID);
  DECLARE responce, type, company JSON;
  DECLARE distributionFilters JSON DEFAULT (SELECT state_json ->> "$.distribution" FROM states WHERE connection_id = connectionID);
  DECLARE done TINYINT(1);
  DECLARE companiesCursor CURSOR FOR 
    SELECT 
      company_json
    FROM (
      SELECT 
        company_json, 
        @apiCount:=IF(type_id IN (15,16,17,24,25,26,27,28,29,30,31,32), @apiCount+1, @apiCount) apiCount, 
        @invalidateCount:=IF(type_id = 14, @invalidateCount+1, @invalidateCount) invalidateCount, 
        @difficultCount:=IF(type_id = 37, @difficultCount+1, @difficultCount) difficultCount, 
        @callbackCount:=IF(type_id = 23, @callbackCount+1, @callbackCount) callbackCount, 
        @inworkCount:=IF(type_id IN (9, 35), @inworkCount+1, @inworkCount) inworkCount, 
        @dialCount:=IF(type_id = 36, @dialCount+1, @dialCount) dialCount,
        type_id
      FROM 
        companies 
      WHERE 
        (
          (
            (type_id IN (15,16,17,24,25,26,27,28,29,30,31,32) AND DATE(company_date_create) BETWEEN DATE(@apiDateStart) AND DATE(@apiDateEnd)) OR 
            (type_id = 14 AND DATE(company_date_create) BETWEEN DATE(@invalidateDateStart) AND DATE(@invalidateDateEnd)) OR 
            (type_id = 37 AND DATE(company_date_create) BETWEEN DATE(@difficultDateStart) AND DATE(@difficultDateEnd)) OR 
            (type_id = 23 AND DATE(company_date_create) BETWEEN DATE(@callbackDateStart) AND DATE(@callbackDateEnd)) OR 
            (type_id IN (9, 35))
          ) AND user_id = userID
        ) OR 
        (type_id = 36 AND DATE(company_date_create) BETWEEN DATE(@dialDateStart) AND DATE(@dialDateEnd))
      ORDER BY type_id ASC, company_date_registration DESC
    ) c
    WHERE 
      (apiCount BETWEEN @apiRowStart AND @apiRowLimit AND type_id IN (15,16,17,24,25,26,27,28,29,30,31,32)) OR
      (invalidateCount BETWEEN @invalidateRowStart AND @invalidateRowLimit AND type_id = 14) OR
      (difficultCount BETWEEN @difficultRowStart AND @difficultRowLimit AND type_id = 37) OR
      (callbackCount BETWEEN @callbackRowStart AND @callbackRowLimit AND type_id = 23) OR
      (inworkCount BETWEEN @inworkRowStart AND @inworkRowLimit AND type_id IN (9, 35)) OR
      (dialCount BETWEEN @dialRowStart AND @dialRowLimit AND type_id = 36);
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
  SET responce = JSON_ARRAY();
  IF distributionFilters IS NOT NULL
    THEN BEGIN
      UPDATE companies SET type_id = 9, company_date_call_back = NULL WHERE user_id = userID AND type_id = 23 AND NOW() >= company_date_call_back;
      SET @apiCount = 0,
          @invalidateCount = 0,
          @difficultCount = 0,
          @callbackCount = 0,
          @dialCount = 0,
          @inworkCount = 0,
          @apiRowStart = JSON_EXTRACT(distributionFilters, "$.api.rowStart"),
          @apiRowLimit = JSON_EXTRACT(distributionFilters, "$.api.rowLimit"),
          @apiDateStart = JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.api.dateStart")),
          @apiDateEnd = JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.api.dateEnd")),
          @invalidateRowStart = JSON_EXTRACT(distributionFilters, "$.invalidate.rowStart"),
          @invalidateRowLimit = JSON_EXTRACT(distributionFilters, "$.invalidate.rowLimit"),
          @invalidateDateStart = JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.invalidate.dateStart")),
          @invalidateDateEnd = JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.invalidate.dateEnd")),
          @difficultRowStart = JSON_EXTRACT(distributionFilters, "$.difficult.rowStart"),
          @difficultRowLimit = JSON_EXTRACT(distributionFilters, "$.difficult.rowLimit"),
          @difficultDateStart = JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.difficult.dateStart")),
          @difficultDateEnd = JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.difficult.dateEnd")),
          @callbackRowStart = JSON_EXTRACT(distributionFilters, "$.callBack.rowStart"),
          @callbackRowLimit = JSON_EXTRACT(distributionFilters, "$.callBack.rowLimit"),
          @callbackDateStart = JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.callBack.dateStart")),
          @callbackDateEnd = JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.callBack.dateEnd")),
          @dialRowStart = JSON_EXTRACT(distributionFilters, "$.notDial.rowStart"),
          @dialRowLimit = JSON_EXTRACT(distributionFilters, "$.notDial.rowLimit"),
          @dialDateStart = JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.notDial.dateStart")),
          @dialDateEnd = JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.notDial.dateEnd")),
          @inworkRowStart = JSON_EXTRACT(distributionFilters, "$.work.rowStart"),
          @inworkRowLimit = JSON_EXTRACT(distributionFilters, "$.work.rowLimit");
      SET @apiRowLimit = @apiRowLimit + @apiRowStart - 1,
          @invalidateRowLimit = @invalidateRowLimit + @invalidateRowStart - 1,
          @difficultRowLimit = @difficultRowLimit + @difficultRowStart - 1,
          @callbackRowLimit = @callbackRowLimit + @callbackRowStart - 1,
          @inworkRowLimit = @inworkRowLimit + @inworkRowStart - 1,
          @dialRowLimit = @dialRowLimit + @dialRowStart - 1;
      OPEN companiesCursor;
        companiesLoop: LOOP
          FETCH companiesCursor INTO company;
          IF done 
            THEN LEAVE companiesLoop;
          END IF;
          SET responce = JSON_MERGE(responce, company);
          ITERATE companiesLoop;
        END LOOP;
      CLOSE companiesCursor;
    END;
  END IF;
  RETURN responce;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `getBankCompanies` (`connectionHash` VARCHAR(32) CHARSET utf8, `bankID` INT(11), `rows` INT(11), `clearWorkList` BOOLEAN) RETURNS JSON NO SQL
BEGIN
  DECLARE companyID, companiesLength, connectionID, userID, timeID, companiesCount INT(11);
  DECLARE connectionValid TINYINT(1);
  DECLARE connectionApiID VARCHAR(128);
  DECLARE responce, companiesArray JSON;
  SET connectionValid = checkConnection(connectionHash);
  SELECT connection_api_id, connection_id, user_id INTO connectionApiID, connectionID, userID FROM users_connections_view WHERE connection_hash = connectionHash;
  SET responce = JSON_ARRAY();
  IF connectionValid
    THEN BEGIN
      SET timeID = getTimeID(bankID);
      IF clearWorkList 
        THEN UPDATE companies SET user_id = NULL, type_id = 10 WHERE user_id = userID AND type_id IN (9, 35);
      END IF;
      UPDATE 
        companies c 
        JOIN (
          SELECT 
            company_id 
          FROM (
            SELECT 
              company_id 
            FROM 
              bank_cities_time_priority_companies_view 
            WHERE 
              type_id = 10 AND 
              old_type_id = 36 AND 
              weekday(company_date_update) = weekday(NOW()) AND 
              time_id = timeID AND 
              bank_id = bankID 
            ORDER BY company_date_create DESC
          ) dialing_companies 
          UNION 
          (SELECT 
            company_id 
          FROM 
            bank_cities_time_priority_companies_view 
          WHERE 
            bank_id = bankID AND 
            IF(DATE(company_date_registration) IS NOT NULL, DATE(company_date_registration) = DATE(NOW()), DATE(company_date_create) = DATE(NOW())) AND
            time_id = timeID AND 
            user_id IS NULL AND 
            type_id = 10 AND 
            (old_type_id IS NULL OR old_type_id != 36) 
          ORDER BY company_date_registration DESC)
          LIMIT rows
        ) bc ON bc.company_id = c.company_id 
      SET c.user_id = userID, c.type_id = 44;
      SELECT COUNT(*) INTO companiesCount FROM companies WHERE user_id = userID AND type_id = 44;
      IF companiesCount > 0
        THEN SET responce = JSON_MERGE(responce, checkCompaniesInn(userID));
        ELSE BEGIN 
          SET responce = JSON_MERGE(responce, refreshUserCompanies(userID));
          SET responce = JSON_MERGE(responce, JSON_MERGE(responce, sendToAllUserSockets(userID, JSON_ARRAY(
            JSON_OBJECT(
              "type", "merge",
              "data", JSON_OBJECT(
                "message", "Не удалось найти ни одной компании для сортировки на данное время",
                "messageType", "error"
              )
            )
          ))));
        END;
      END IF;
    END;
    ELSE SET responce = JSON_MERGE(responce, JSON_OBJECT(
      "type", "sendToSocket",
      "data", JSON_OBJECT(
        "socketID", connectionApiID,
        "data", JSON_ARRAY(JSON_OBJECT(
          "type", "merge",
          "data", JSON_OBJECT(
            "auth", 0,
            "loginMessage", "Требуется ручной вход в систему"
          )
        ))
      )
    ));
  END IF;
  RETURN responce;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `getBanks` () RETURNS JSON NO SQL
BEGIN
  DECLARE bankID INT(11);
  DECLARE bankName VARCHAR(128);
  DECLARE responce JSON;
  DECLARE done TINYINT(1);
  DECLARE banksCursor CURSOR FOR SELECT bank_id, bank_name FROM banks;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
  SET responce = JSON_ARRAY();
  OPEN banksCursor;
    banksLoop: LOOP
      FETCH banksCursor INTO bankID, bankName;
      IF done 
        THEN LEAVE banksLoop;
      END IF;
      SET responce = JSON_MERGE(responce, JSON_OBJECT(
        "name", bankName,
        "id", bankID
      ));
      ITERATE banksLoop;
    END LOOP;
  CLOSE banksCursor;
  RETURN responce;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `getColumns` () RETURNS JSON NO SQL
BEGIN
  DECLARE columnID INT(11);
  DECLARE columnName VARCHAR(128);
  DECLARE responce JSON;
  DECLARE done TINYINT(1);
  DECLARE columnsCursor CURSOR FOR SELECT column_id, translate_to FROM columns_translates_view;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
  SET responce = JSON_ARRAY();
  OPEN columnsCursor;
    columnsLoop: LOOP
      FETCH columnsCursor INTO columnID, columnName;
      IF done 
        THEN LEAVE columnsLoop;
      END IF;
      SET responce = JSON_MERGE(responce, JSON_OBJECT(
        "name", columnName,
        "id", columnID
      ));
      ITERATE columnsLoop;
    END LOOP;
  CLOSE columnsCursor;
  RETURN responce;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `getCompaniesToCheckStatus` () RETURNS JSON NO SQL
BEGIN
  DECLARE done TINYINT(1);
  DECLARE responce, company JSON;
  DECLARE companiesCursor CURSOR FOR SELECT JSON_OBJECT("companyID", company_id, "applicationID", company_application_id) FROM companies WHERE type_id in (16, 25, 26, 27, 28, 29) AND company_application_id IS NOT NULL;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
  SET responce = JSON_ARRAY();
  OPEN companiesCursor;
    companiesLoop: LOOP
      FETCH companiesCursor INTO company;
      IF done
        THEN LEAVE companiesLoop;
      END IF;
      SET responce = JSON_MERGE(responce, company);
      ITERATE companiesLoop;
    END LOOP;
  CLOSE companiesCursor;
  SET responce = JSON_OBJECT(
    "companies", responce
  );
  RETURN responce;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `getHash` (`max` INT(3)) RETURNS VARCHAR(999) CHARSET utf8 NO SQL
BEGIN
  DECLARE symbol VARCHAR(1);
    DECLARE str VARCHAR(999) DEFAULT "";
    DECLARE iterator INT(11) DEFAULT 0;
    generation: LOOP
      SET symbol = LOWER(CONV(CEIL(RAND()*0xF),10,16)),
          iterator = iterator + 1;
        IF CEIL(RAND()*2) = 1 
          THEN SET symbol = UPPER(symbol);
        END IF;
        SET str = CONCAT(str, symbol);
        IF iterator < max
          THEN ITERATE generation;
          ELSE LEAVE generation;
        END IF;
    END LOOP;
    RETURN str;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `getRegions` () RETURNS JSON NO SQL
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
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `getTimeID` (`bankID` INT(11)) RETURNS INT(11) NO SQL
BEGIN
  DECLARE timeID INT(11); 
  SELECT time_id INTO timeID FROM bank_times_view WHERE TIME(time_value) = TIME(now()) AND bank_id = bankID ORDER BY TIME(time_value) LIMIT 1;
  IF timeID IS NULL
    THEN SELECT time_id INTO timeID FROM bank_times_view WHERE TIME(time_value) < TIME(NOW()) AND bank_id = bankID ORDER BY TIME(time_value) DESC LIMIT 1;
  END IF;
  IF timeID IS NULL
    THEN SELECT time_id INTO timeID FROM bank_times_view WHERE TIME(time_value) > TIME(NOW()) AND bank_id = bankID ORDER BY TIME(time_value) DESC LIMIT 1;
  END IF;
  RETURN timeID;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `getUserFiles` (`userID` INT(11)) RETURNS JSON NO SQL
BEGIN
  DECLARE fileName VARCHAR(128);
  DECLARE responce JSON;
  DECLARE done TINYINT(1);
  DECLARE filesCursor CURSOR FOR SELECT file_name FROM files WHERE type_id = 21 AND user_id = userID ORDER BY file_id DESC;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
  SET responce = JSON_ARRAY();
  OPEN filesCursor;
    filesLoop: LOOP
      FETCH filesCursor INTO fileName;
      IF done 
        THEN LEAVE filesLoop;
      END IF;
      SET responce = JSON_MERGE(responce, JSON_OBJECT(
        "name", fileName
      ));
      ITERATE filesLoop;
    END LOOP;
  CLOSE filesCursor;
  RETURN responce;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `getUsers` (`bankID` INT(11)) RETURNS JSON NO SQL
BEGIN
  DECLARE responce JSON;
  DECLARE done TINYINT(1);
  DECLARE userID INT(11);
  DECLARE userName VARCHAR(64);
  DECLARE usersCursor CURSOR FOR SELECT user_id, user_name FROM users WHERE IF(bankID IS NOT NULL AND bankID > 0, bank_id = bankID, bank_id IS NULL);
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
  SET responce = JSON_ARRAY();
  OPEN usersCursor;
    usersLoop: LOOP
      FETCH usersCursor INTO userID, userName;
      IF done
        THEN LEAVE usersLoop;
      END IF;
      SET responce = JSON_MERGE(responce, JSON_OBJECT(
        "userName", userName,
        "userID", userID
      ));
      ITERATE usersLoop;
    END LOOP;
  CLOSE usersCursor;
  RETURN responce;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `logout` (`connectionHash` VARCHAR(32) CHARSET utf8) RETURNS JSON NO SQL
BEGIN
  DECLARE connectionValid TINYINT(1);
  DECLARE connectionApiID VARCHAR(128);
  DECLARE userID, connectionID, bankID INT(11);
  DECLARE responce JSON;
  SET responce = JSON_ARRAY();
  SET connectionValid = checkConnection(connectionHash);
  SELECT user_id, connection_api_id, connection_id, bank_id INTO userID, connectionApiID, connectionID, bankID FROM users_connections_view WHERE connection_hash = connectionHash;
  IF connectionValid
    THEN BEGIN
      UPDATE connections SET user_id = NULL WHERE connection_id = connectionID;
      UPDATE users SET user_auth = 0 WHERE user_id = userID;
      SET responce = JSON_MERGE(responce, 
        JSON_OBJECT(
          "type", "sendToSocket",
          "data", JSON_OBJECT(
            "socketID", connectionApiID,
            "data", JSON_ARRAY(JSON_OBJECT(
              "type", "set",
              "data", JSON_OBJECT(
                "auth", 0,
                "try", 1,
                "loginMessage", "Вы успешно вышли из системы",
                "connectionHash", connectionHash
              )
            ))
          )
        ),
        JSON_OBJECT(
          "type", "procedure",
          "data", JSON_OBJECT(
            "query", "refreshBankSupervisors",
            "values", JSON_ARRAY(
              bankID
            )
          )
        )
      );
      SET responce = JSON_MERGE(responce, sendToAllUserSockets(userID, JSON_ARRAY(JSON_OBJECT(
        "type", "set",
        "data", JSON_OBJECT(
          "auth", 0,
          "try", 1,
          "loginMessage", "Был произведен выход из другого места.",
          "connectionHash", connectionHash
        )
      ))));
    END;
    ELSE SET responce = JSON_MERGE(responce, JSON_OBJECT(
      "type", "sendToSocket",
      "data", JSON_OBJECT(
        "socketID", connectionApiID,
        "data", JSON_ARRAY(JSON_OBJECT(
          "type", "set",
          "data", JSON_OBJECT(
            "auth", 0,
            "try", 1,
            "loginMessage", "Требуется ручной вход в систему",
            "connectionHash", connectionHash
          )
        ))
      )
    ));
  END IF;
  RETURN responce;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `newConnection` (`typeID` INT(11), `connectionApiID` VARCHAR(128) CHARSET utf8) RETURNS JSON NO SQL
BEGIN
  DECLARE connectionHash VARCHAR(32);
    INSERT INTO connections (type_id, connection_api_id) VALUES (typeID, connectionApiID);
    SELECT connection_hash INTO connectionHash FROM connections ORDER BY connection_id DESC LIMIT 1;
    RETURN JSON_ARRAY(JSON_OBJECT(
      "type", "sendToSocket",
        "data", JSON_OBJECT(
            "socketID", connectionApiID,
            "data", JSON_ARRAY(
                JSON_OBJECT(
                    "type", "save",
                    "data", JSON_OBJECT(
                        "connectionHash", connectionHash
                    )
                ),
                JSON_OBJECT(
                    "type", "set",
                    "data", JSON_OBJECT(
                        "connectionHash", connectionHash
                    )
                )
            )
        )
    ));
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `refreshUserCompanies` (`userID` INT(11)) RETURNS JSON NO SQL
BEGIN
  DECLARE responce JSON;
  DECLARE connectionApiID VARCHAR(128);
  DECLARE connectionID INT(11);
  DECLARE done TINYINT(1);
  DECLARE connectionsCursor CURSOR FOR SELECT connection_id, connection_api_id FROM connections WHERE user_id = userID AND connection_end = 0;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
  SET responce = JSON_ARRAY();
  OPEN connectionsCursor;
    connectionsLoop:LOOP
      FETCH connectionsCursor INTO connectionID, connectionApiID;
      IF done
        THEN LEAVE connectionsLoop; 
      END IF;
      SET responce = JSON_MERGE(responce, JSON_OBJECT(
        "type", "sendToSocket",
        "data", JSON_OBJECT(
          "socketID", connectionApiID,
          "data", JSON_ARRAY(
            JSON_OBJECT(
              "type", "merge",
              "data", JSON_OBJECT(
                "companies", getActiveBankUserCompanies(connectionID)
              )
            )
          )
        )
      ));
      ITERATE connectionsLoop;
    END LOOP;
  CLOSE connectionsCursor;
  RETURN responce;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `refreshUsersCompanies` (`bankID` INT(11)) RETURNS JSON NO SQL
BEGIN
  DECLARE userID INT(11);
  DECLARE done TINYINT(1);
  DECLARE responce JSON;
  DECLARE usersCursor CURSOR FOR SELECT user_id FROM users_connections_view WHERE IF(bankID IS NOT NULL, bank_id = bankID, 1) AND connection_end = 0 AND type_id IN (1, 18);
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
  SET responce = JSON_ARRAY();
  OPEN usersCursor;
    usersLoop: LOOP
      FETCH usersCursor INTO userID;
      IF done
        THEN LEAVE usersLoop;
      END IF;
      SET responce = JSON_MERGE(responce, refreshUserCompanies(userID));
      ITERATE usersLoop;
    END LOOP;
  CLOSE usersCursor;
  RETURN responce;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `resetCompanies` (`connectionHash` VARCHAR(32) CHARSET utf8, `typeID` INT(11)) RETURNS JSON NO SQL
BEGIN
  DECLARE userID, connectionID INT(11);
  DECLARE connectionValid TINYINT(1);
  DECLARE connectionApiID VARCHAR(128);
  DECLARE dateStart, dateEnd VARCHAR(19);
  DECLARE responce, filter JSON;
  SET responce = JSON_ARRAY();
  SET connectionValid = checkConnection(connectionHash);
  SELECT connection_api_id, user_id, connection_id INTO connectionApiID, userID, connectionID FROM users_connections_view WHERE connection_hash = connectionHash;
  IF connectionValid
    THEN BEGIN
      IF typeID = 14 OR typeID = 23
        THEN BEGIN 
          SELECT JSON_EXTRACT(state_json, CONCAT("$.distribution.", IF(typeID = 14, "invalidate", "callBack"))) INTO filter FROM states WHERE connection_id = connectionID;
          SET dateStart = JSON_UNQUOTE(JSON_EXTRACT(filter, "$.dateStart"));
          SET dateEnd = JSON_UNQUOTE(JSON_EXTRACT(filter, "$.dateEnd"));
        END;
        ELSE BEGIN
          SET dateStart = NOW();
          SET dateEnd = NOW();
        END;
      END IF;
      UPDATE companies SET type_id = 10 AND user_id = NULL WHERE user_id = userID AND type_id = typeID AND DATE(company_date_create) BETWEEN DATE(dateStart) AND DATE(dateEnd);
      SET responce = JSON_MERGE(responce, refreshUserCompanies(userID));
      SET responce = JSON_MERGE(responce, sendToAllUserSockets(userID, JSON_ARRAY(JSON_OBJECT(
        "type", "merge",
        "data", JSON_OBJECT(
          "message", "Список удачно очищен"
        )
      ))));
    END;
    ELSE SET responce = JSON_MERGE(responce, JSON_OBJECT(
      "type", "sendToSocket",
      "data", JSON_OBJECT(
        "socketID", connectionApiID,
        "data", JSON_ARRAY(JSON_OBJECT(
          "type", "merge",
          "data", JSON_OBJECT(
            "auth", 0,
            "loginMessage", "Требуется ручной вход в систему"
          )
        ))
      )
    ));
  END IF;
  RETURN responce;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `resetNotDialAllCompanies` (`bankID` INT(11)) RETURNS JSON NO SQL
BEGIN 
  DECLARE companiesCount INT(11) DEFAULT 0;
  DECLARE responce JSON;
  SET responce = JSON_ARRAY();
  SELECT COUNT(*) INTO companiesCount FROM companies WHERE type_id = 36 AND bank_id = bankID;
  UPDATE companies SET type_id = 10, user_id = NULL WHERE type_id = 36 AND bank_id = bankID;
  SET responce = JSON_MERGE(responce, refreshUsersCompanies(bankID));
  SET responce = JSON_MERGE(responce, JSON_OBJECT(
    "type", "print",
    "data", JSON_OBJECT(
      "message", CONCAT("Сброшено в свободный доступ ", companiesCount, " компаний. Дата: ", NOW())
    )
  ));
  RETURN responce;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `sendPasswordToEmail` (`connectionHash` VARCHAR(32) CHARSET utf8, `userEmail` VARCHAR(512) CHARSET utf8) RETURNS JSON NO SQL
BEGIN
  DECLARE userPassword, connectionApiID VARCHAR(128);
  DECLARE responce JSON;
  SET responce = JSON_ARRAY();
  SELECT user_password INTO userPassword FROM users WHERE user_email = userEmail;
  SELECT connection_api_id INTO connectionApiID FROM connections WHERE connection_hash = connectionHash;
  IF userPassword IS NOT NULL
    THEN SET responce = JSON_MERGE(responce, JSON_ARRAY(
      JSON_OBJECT(
        "type", "sendEmail",
        "data", JSON_OBJECT(
          "emails", JSON_ARRAY(
            userEmail
          ),
          "subject", "Восстановление пароля",
          "text", CONCAT("Ваш пароль: ", userPassword)
        )
      ),
      JSON_OBJECT(
        "type", "sendToSocket",
        "data", JSON_OBJECT(
          "socketID", connectionApiID,
          "data", JSON_ARRAY(
            JSON_OBJECT(
              "type", "merge",
              "data", JSON_OBJECT(
                "loginMessage", CONCAT("Сообщение направлено на почту: ", userEmail) 
              )
            )
          )
        )
      )
    ));
    ELSE SET responce = JSON_MERGE(responce, JSON_OBJECT(
      "type", "sendToSocket",
      "data", JSON_OBJECT(
        "socketID", connectionApiID,
        "data", JSON_ARRAY(
          JSON_OBJECT(
            "type", "merge",
            "data", JSON_OBJECT(
              "loginMessage", CONCAT("Пользователь с таким email не существует: ", userEmail)
            )
          )
        )
      )
    )); 
  END IF;
  RETURN responce;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `sendToAllUserSockets` (`userID` INT(11), `sendArray` JSON) RETURNS JSON NO SQL
BEGIN
  DECLARE connectionApiID VARCHAR(128);
  DECLARE done TINYINT(1);
  DECLARE responce JSON;
  DECLARE socketsCursor CURSOR FOR SELECT connection_api_id FROM users_connections_view WHERE user_id = userID AND connection_type_id = 3 AND connection_end = 0;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
  SET responce = JSON_ARRAY();
  OPEN socketsCursor;
    socketsLoop: LOOP
      FETCH socketsCursor INTO connectionApiID;
      IF done
        THEN LEAVE socketsLoop;
      END IF; 
      SET responce = JSON_MERGE(responce, JSON_OBJECT(
        "type", "sendToSocket",
        "data", JSON_OBJECT(
          "socketID", connectionApiID,
          "data", sendArray
        )
      ));
      ITERATE socketsLoop;
    END LOOP;
  CLOSE socketsCursor;
  RETURN responce;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `sendToApi` (`connectionHash` VARCHAR(32) CHARSET utf8, `companyID` INT(11), `comment` TEXT CHARSET utf8) RETURNS JSON NO SQL
BEGIN
  DECLARE userID INT(11);
  DECLARE connectionValid TINYINT(1);
  DECLARE connectionApiID VARCHAR(128);
  DECLARE responce, company JSON;
  SET responce = JSON_ARRAY();
  SET connectionValid = checkConnection(connectionHash);
  SELECT connection_api_id, user_id INTO connectionApiID, userID FROM connections WHERE connection_hash = connectionHash;
  IF connectionValid 
    THEN BEGIN
      UPDATE companies SET company_comment = comment, type_id = 15 WHERE company_id = companyID;
      SELECT 
        JSON_OBJECT(
          "companyID", company_id,
          "companyPersonName", company_person_name,
          "companyPersonSurname", company_person_surname,
          "companyPersonPatronymic", company_person_patronymic,
          "companyPhone", company_phone,
          "companyOrganizationName", company_organization_name,
          "companyInn", company_inn,
          "companyOgrn", company_ogrn,
          "companyComment", company_comment
        ) 
      INTO company FROM companies WHERE company_id = companyID;
      SET responce = JSON_MERGE(responce, refreshUserCompanies(userID));
      SET responce = JSON_MERGE(responce,
        JSON_OBJECT(
          "type", "sendToApi",
          "data", company
        )
      );
    END;
    ELSE SET responce = JSON_MERGE(responce, JSON_OBJECT(
      "type", "sendToSocket",
      "data", JSON_OBJECT(
        "socketID", connectionApiID,
        "data", JSON_ARRAY(JSON_OBJECT(
          "type", "merge",
          "data", JSON_OBJECT(
            "auth", 0,
            "loginMessage", "Требуется ручной вход в систему"
          )
        ))
      )
    ));
  END IF;
  RETURN responce;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `setApiResponce` (`companyID` INT(11), `applicationID` VARCHAR(128) CHARSET utf8, `requestID` VARCHAR(128) CHARSET utf8, `success` TINYINT(1)) RETURNS JSON NO SQL
BEGIN
  DECLARE userID, typeID INT(11);
  DECLARE responce, company JSON;
  SET responce = JSON_ARRAY();
  SELECT user_id INTO userID FROM companies WHERE company_id = companyID;
  SET typeID = IF(!success, 17, IF(applicationID = "false", 24, 16));
  UPDATE companies SET type_id = typeID, company_api_request_id = requestID, company_application_id = IF(applicationID = "false", NULL, applicationID) WHERE company_id = companyID;
  SET responce = JSON_MERGE(responce, refreshUserCompanies(userID));
  RETURN responce;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `setBankStatisticFilter` (`connectionHash` VARCHAR(32) CHARSET utf8, `filters` JSON) RETURNS JSON NO SQL
BEGIN
  DECLARE connectionValid TINYINT(1);
  DECLARE keyName VARCHAR(128);
  DECLARE connectionApiID VARCHAR(32);
  DECLARE keysLength, iterator, stateID, userID, connectionID INT(11);
  DECLARE userFilters, responce, filtersKeys JSON;
  SET connectionValid = checkConnection(connectionHash);
  SET responce = JSON_ARRAY();
  SELECT user_id, connection_id, connection_api_id INTO userID, connectionID, connectionApiID FROM users_connections_view WHERE connection_hash = connectionHash;
  IF connectionValid
    THEN BEGIN  
      SET filtersKeys = JSON_KEYS(filters);
      SET keysLength = JSON_LENGTH(filtersKeys);
      SET iterator = 0;
      SELECT state_json ->> "$.statistic", state_id INTO userFilters, stateID FROM states WHERE user_id = userID AND connection_id = connectionID LIMIT 1;
      keysLoop: LOOP
        IF iterator >= keysLength
          THEN LEAVE keysLoop;
        END IF;
        SET keyName = JSON_UNQUOTE(JSON_EXTRACT(filtersKeys, CONCAT("$[", iterator, "]")));
        SET userFilters = JSON_SET(userFilters, CONCAT("$.", keyName), JSON_UNQUOTE(JSON_EXTRACT(filters, CONCAT("$.", keyName))));
        SET iterator = iterator + 1;
        ITERATE keysLoop;
      END LOOP;
      UPDATE states SET state_json = JSON_SET(state_json, "$.statistic", userFilters) WHERE state_id = stateID;
      SET responce = JSON_MERGE(responce, JSON_OBJECT(
        "type", "procedure",
        "data", JSON_OBJECT(
          "query", "getBankStatistic",
          "values", JSON_ARRAY(
            connectionHash
          )
        )
      ));
    END;
    ELSE SET responce = JSON_MERGE(responce, JSON_OBJECT(
      "type", "sendToSocket",
      "data", JSON_OBJECT(
        "socketID", connectionApiID,
        "data", JSON_ARRAY(JSON_OBJECT(
          "type", "merge",
          "data", JSON_OBJECT(
            "auth", 0,
            "loginMessage", "Требуется ручной вход в систему"
          )
        ))
      )
    ));
  END IF;
  RETURN responce;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `setCallRecord` (`callApiIDWithRec` VARCHAR(128) CHARSET utf8, `callApiID` VARCHAR(128) CHARSET utf8) RETURNS JSON NO SQL
BEGIN
  DECLARE responce JSON;
  SET responce = JSON_ARRAY();
  UPDATE calls SET call_record = 1 WHERE call_api_id_with_rec = callApiIDWithRec OR call_api_id_1 = callApiID OR call_api_id_2 = callApiID;
  RETURN responce;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `setCallStatus` (`userSip` VARCHAR(20) CHARSET utf8, `companyPhone` VARCHAR(120) CHARSET utf8, `typeID` INT, `callApiID` VARCHAR(128) CHARSET utf8, `callApiIDWithRec` VARCHAR(128) CHARSET utf8) RETURNS JSON NO SQL
BEGIN
  DECLARE callID, userID, companyTypeID, companyOldTypeID, bankID, callCount, companyID INT(11);
  DECLARE typeTranslate VARCHAR(128);
  DECLARE nextPhone VARCHAR(120);
  DECLARE ringing TINYINT(1);
  DECLARE responce JSON;
  SET responce = JSON_ARRAY();
  SELECT call_id, user_id INTO callID, userID FROM active_calls_view WHERE company_phone = companyPhone AND user_sip = userSip ORDER BY call_id DESC LIMIT 1;
  SELECT tr.translate_to INTO typeTranslate FROM translates tr JOIN types t ON t.type_id = typeID AND t.type_name = tr.translate_from;
  UPDATE calls SET 
    type_id = typeID, 
    call_api_id_1 = IF(call_api_id_1 IS NULL AND (call_api_id_2 IS NULL OR call_api_id_2 != callApiID), callApiID, call_api_id_1), 
    call_api_id_2 = IF(call_api_id_2 IS NULL AND (call_api_id_1 IS NULL OR call_api_id_1 != callApiID), callApiID, call_api_id_2),
    call_api_id_with_rec = callApiIDWithRec
  WHERE call_id = callID;
  SELECT type_id, old_type_id, bank_id INTO companyTypeID, companyOldTypeID, bankID FROM companies WHERE call_id = callID;
  IF companyTypeID = 36 AND bankID
    THEN SET responce = JSON_MERGE(responce, refreshUsersCompanies(bankID));
    ELSE SET responce = JSON_MERGE(responce, refreshUserCompanies(userID));
  END IF;
  SET responce = JSON_MERGE(responce, sendToAllUserSockets(userID, JSON_ARRAY(JSON_OBJECT(
    "type", "mergeDeep",
    "data", JSON_OBJECT(
      "message", CONCAT("соединение с ", companyPhone, " имеет статус: ", typeTranslate),
      "messageType", IF(typeID NOT IN (40, 41, 42), "success", "error")
    )
  ))));
  IF companyOldTypeID IN (9, 35) AND typeID IN (40, 41, 42)
    THEN BEGIN
      SELECT user_ringing INTO ringing FROM users WHERE user_id = userID;
      IF ringing = 1
        THEN BEGIN
          SELECT COUNT(*) INTO callCount FROM calls WHERE user_id = userID AND type_id NOT IN (40, 41, 42);
          IF callCount = 0
            THEN BEGIN
              SELECT REPLACE(company_phone, "+", ""), company_id INTO nextPhone, companyID FROM companies WHERE user_id = userID AND type_id IN (9, 35) AND company_ringing = 0 ORDER BY type_id LIMIT 1;
              IF nextPhone IS NOT NULL
                THEN BEGIN
                  INSERT INTO calls (user_id, company_id, type_id) VALUES (userID, companyID, 33);
                  SET responce = JSON_MERGE(responce, refreshUserCompanies(userID));
                  SET responce = JSON_MERGE(responce, JSON_OBJECT(
                    "type", "sendToZadarma",
                    "data", JSON_OBJECT(
                      "options", JSON_OBJECT( 
                        "from", userSip,
                        "to", nextPhone,
                        "predicted", true
                      ),
                      "method", "request/callback",
                      "type", "GET"
                    )
                  ));
                  UPDATE companies SET company_ringing = 1 WHERE company_id = companyID;
                END;
              END IF;
            END;
          END IF;
        END;
      END IF;
    END;
  END IF;
  RETURN responce;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `setCheckResponce` (`companies` JSON) RETURNS JSON NO SQL
BEGIN
  DECLARE interator, companiesLength, userID, typeID, companyID, usersLength INT(11);
  DECLARE applicationID VARCHAR(128);
  DECLARE responce, company, users JSON;
  SET responce = JSON_ARRAY();
  SET users = JSON_ARRAY();
  SET companiesLength = JSON_LENGTH(companies);
  SET interator = 0;
  companiesLoop: LOOP
    IF interator >= companiesLength
      THEN LEAVE companiesLoop;
    END IF;
    SET company = JSON_EXTRACT(companies, CONCAT("$[", interator, "]"));
    SET typeID = JSON_UNQUOTE(JSON_EXTRACT(company, "$.type_id"));
    SET applicationID = JSON_UNQUOTE(JSON_EXTRACT(company, "$.company_application_id"));
    SELECT user_id, company_id INTO userID, companyID FROM companies WHERE company_application_id = applicationID;
    UPDATE LOW_PRIORITY IGNORE companies SET type_id = typeID WHERE company_id = companyID;
    IF JSON_CONTAINS(users, CONCAT(userID)) = 0
      THEN SET users = JSON_MERGE(users, CONCAT(userID));
    END IF;
    SET interator = interator + 1;
    ITERATE companiesLoop;
  END LOOP;
  SET usersLength = JSON_LENGTH(users);
  IF usersLength > 0
    THEN BEGIN
      SET interator = 0;
      usersLoop: LOOP
        IF interator >= usersLength
          THEN LEAVE usersLoop;
        END IF;
        SET userID = JSON_UNQUOTE(JSON_EXTRACT(users, CONCAT("$[", interator, "]")));
        SET responce = JSON_MERGE(responce, refreshUserCompanies(userID));
        SET interator = interator + 1;
        ITERATE usersLoop;
      END LOOP;
    END;
  END IF;
  SET responce = JSON_MERGE(responce, JSON_OBJECT(
    "type", "print",
    "data", JSON_OBJECT(
      "message", CONCAT(companiesLength, " компаний успешно обработаны")
    )
  ));
  RETURN responce;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `setCompanyType` (`connectionHash` VARCHAR(32) CHARSET utf8, `companyID` INT(11), `typeID` INT(11), `dateParam` VARCHAR(19) CHARSET utf8) RETURNS JSON NO SQL
BEGIN
  DECLARE userID, bankID, connectionID, lastTypeID INT(11);
  DECLARE connectionValid TINYINT(1);
  DECLARE connectionApiID VARCHAR(128);
  DECLARE responce JSON;
  SET connectionValid = checkConnection(connectionHash);
  SELECT connection_api_id, user_id, bank_id, connection_id INTO connectionApiID, userID, bankID, connectionID FROM users_connections_view WHERE connection_hash = connectionHash;
  SET responce = JSON_ARRAY();
  IF connectionValid
    THEN BEGIN
      SELECT type_id INTO lastTypeID FROM companies WHERE company_id = companyID;
      IF typeID = 23
        THEN UPDATE companies SET type_id = typeID, company_date_call_back = dateParam, user_id = userID WHERE company_id = companyID;
        ELSE UPDATE companies SET type_id = typeID, user_id = userID WHERE company_id = companyID;
      END IF;
      IF typeID = 36 OR lastTypeID = 36 
        THEN SET responce = JSON_MERGE(responce, refreshUsersCompanies(bankID));
        ELSE SET responce = JSON_MERGE(responce, refreshUserCompanies(userID));
      END IF;
      SET responce = JSON_MERGE(responce, JSON_ARRAY(
        JSON_OBJECT(
          "type", "sendToSocket",
          "data", JSON_OBJECT(
            "socketID", connectionApiID,
            "data", JSON_ARRAY(
              JSON_OBJECT(
                "type", "merge",
                "data", JSON_OBJECT(
                  "message", ""
                )
              )
            )
          )
        )
      ));
    END;
    ELSE SET responce = JSON_MERGE(responce, JSON_OBJECT(
      "type", "sendToSocket",
      "data", JSON_OBJECT(
        "socketID", connectionApiID,
        "data", JSON_ARRAY(JSON_OBJECT(
          "type", "merge",
          "data", JSON_OBJECT(
            "auth", 0,
            "loginMessage", "Требуется ручной вход в систему"
          )
        ))
      )
    ));
  END IF;
  RETURN responce;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `setDistributionFilter` (`connectionHash` VARCHAR(32) CHARSET utf8, `filters` JSON) RETURNS JSON NO SQL
BEGIN
  DECLARE connectionValid TINYINT(1);
  DECLARE keyName VARCHAR(128);
  DECLARE connectionApiID VARCHAR(32);
  DECLARE userID, connectionID, keysLength, iterator, stateID INT(11);
  DECLARE responce, filtersKeys, userFilters JSON;
  SELECT user_id, connection_id, connection_api_id INTO userID, connectionID, connectionApiID FROM users_connections_view WHERE connection_hash = connectionHash;
  SET connectionValid = checkConnection(connectionHash);
  SET responce = JSON_ARRAY();
  IF connectionValid
    THEN BEGIN
      SET filtersKeys = JSON_KEYS(filters);
      SET keysLength = JSON_LENGTH(filtersKeys);
      SET iterator = 0;
      SELECT state_json ->> "$.distribution", state_id INTO userFilters, stateID FROM states WHERE user_id = userID AND connection_id = connectionID LIMIT 1;
      keysLoop: LOOP
        IF iterator >= keysLength
          THEN LEAVE keysLoop;
        END IF;
        SET keyName = JSON_UNQUOTE(JSON_EXTRACT(filtersKeys, CONCAT("$[", iterator, "]")));
        SET userFilters = JSON_REMOVE(userFilters, CONCAT("$.", keyName));
        SET iterator = iterator + 1;
        ITERATE keysLoop;
      END LOOP;
      SET userFilters = JSON_MERGE(userFilters, filters);
      UPDATE states SET state_json = JSON_SET(state_json, "$.distribution", userFilters) WHERE state_id = stateID;
      SELECT state_json ->> "$.distribution" INTO userFilters FROM states WHERE state_id = stateID;
      SET responce = JSON_MERGE(responce, JSON_OBJECT(
        "type", "sendToSocket",
        "data", JSON_OBJECT(
          "socketID", connectionApiID,
          "data", JSON_ARRAY(
            JSON_OBJECT(
              "type", "merge",
              "data", JSON_OBJECT(
                "distribution", userFilters,
                "companies", getActiveBankUserCompanies(connectionID)
              )
            )
          )
        )
      ));
    END;
    ELSE SET responce = JSON_MERGE(responce, JSON_OBJECT(
      "type", "sendToSocket",
      "data", JSON_OBJECT(
        "socketID", connectionApiID,
        "data", JSON_ARRAY(JSON_OBJECT(
          "type", "merge",
          "data", JSON_OBJECT(
            "auth", 0,
            "loginMessage", "Требуется ручной вход в систему"
          )
        ))
      )
    ));
  END IF;
  RETURN responce;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `setDownloadFilter` (`connectionHash` VARCHAR(32) CHARSET utf8, `filters` JSON) RETURNS JSON NO SQL
BEGIN
  DECLARE connectionValid TINYINT(1);
  DECLARE keyName VARCHAR(128);
  DECLARE connectionApiID VARCHAR(32);
  DECLARE userID, connectionID, keysLength, iterator, stateID INT(11);
  DECLARE responce, filtersKeys, userFilters JSON;
  SELECT user_id, connection_id, connection_api_id INTO userID, connectionID, connectionApiID FROM users_connections_view WHERE connection_hash = connectionHash;
  SET connectionValid = checkConnection(connectionHash);
  SET responce = JSON_ARRAY();
  IF connectionValid
    THEN BEGIN
      SET filtersKeys = JSON_KEYS(filters);
      SET keysLength = JSON_LENGTH(filtersKeys);
      SET iterator = 0;
      SELECT state_json ->> "$.download", state_id INTO userFilters, stateID FROM states WHERE user_id = userID AND connection_id = connectionID LIMIT 1;
      keysLoop: LOOP
        IF iterator >= keysLength
          THEN LEAVE keysLoop;
        END IF;
        SET keyName = JSON_UNQUOTE(JSON_EXTRACT(filtersKeys, CONCAT("$[", iterator, "]")));
        SET userFilters = JSON_REMOVE(userFilters, CONCAT("$.", keyName));
        SET iterator = iterator + 1;
        ITERATE keysLoop;
      END LOOP;
      SET userFilters = JSON_MERGE(userFilters, filters);
      UPDATE states SET state_json = JSON_SET(state_json, "$.download", userFilters) WHERE state_id = stateID;
      SET responce = JSON_MERGE(responce, sendToAlluserSockets(userID, JSON_ARRAY(JSON_OBJECT(
        "type", "merge",
        "data", JSON_OBJECT(
          "download", userFilters
        )
      ))));
      IF JSON_CONTAINS(filtersKeys, JSON_ARRAY("limit")) OR JSON_CONTAINS(filtersKeys, JSON_ARRAY("offset"))
        THEN SET responce = JSON_MERGE(responce, JSON_OBJECT(
          "type", "procedure",
          "data", JSON_OBJECT(
            "query", "getDownloadPreview",
            "values", JSON_ARRAY(
              userID
            )
          )
        ));
      END IF;
    END;
    ELSE SET responce = JSON_MERGE(responce, JSON_OBJECT(
      "type", "sendToSocket",
      "data", JSON_OBJECT(
        "socketID", connectionApiID,
        "data", JSON_ARRAY(JSON_OBJECT(
          "type", "merge",
          "data", JSON_OBJECT(
            "auth", 0,
            "loginMessage", "Требуется ручной вход в систему"
          )
        ))
      )
    ));
  END IF;
  RETURN responce;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `setDuplicates` (`userID` INT(11), `companiesArray` JSON) RETURNS JSON NO SQL
BEGIN
  DECLARE companiesLength, companiesCount, bankID INT(11);
  DECLARE connectionHash VARCHAR(32);
  DECLARE responce JSON;
  SET responce = JSON_ARRAY();
  SET companiesLength = JSON_LENGTH(companiesArray);
  IF companiesLength > 0
    THEN BEGIN
      SELECT COUNT(*) INTO companiesCount FROM companies WHERE user_id = userID AND type_id = 44;
      UPDATE companies SET type_id = 24 WHERE JSON_CONTAINS(companiesArray, CONCAT(company_id));
      UPDATE companies SET type_id = 9 WHERE user_id = userID AND type_id = 44;
      SET responce = JSON_MERGE(responce, JSON_ARRAY(
        JSON_OBJECT(
          "type", "print",
          "data", JSON_OBJECT(
            "message", CONCAT(companiesLength, "/", companiesCount, " дубликаты")
          )
        )
      ));
      SELECT bank_id, connection_hash INTO bankID, connectionHash FROM users_connections_view WHERE user_id = userID AND connection_end = 0 LIMIT 1;
      SET responce = JSON_MERGE(responce, getBankCompanies(connectionHash, bankID, companiesLength, 0));
    END;
    ELSE BEGIN
      UPDATE companies SET type_id = 9 WHERE user_id = userID AND type_id = 44;
      SET responce = JSON_MERGE(responce, refreshUserCompanies(userID));
      SET responce = JSON_MERGE(responce, sendToAllUserSockets(userID, JSON_ARRAY(JSON_OBJECT(
        "type", "merge",
        "data", JSON_OBJECT(
          "message", CONCAT("Рабочий список сброшен и обновлён."),
          "messageType", "success"
        )
      ))));         
    END;
  END IF;
  RETURN responce;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `setRecordFile` (`userSip` VARCHAR(128) CHARSET utf8, `companyPhone` VARCHAR(128) CHARSET utf8, `fileName` VARCHAR(128) CHARSET utf8, `filePath` VARCHAR(128) CHARSET utf8) RETURNS JSON NO SQL
BEGIN
  DECLARE callID, userID, fileID INT(11);
  DECLARE responce JSON;
  SET responce = JSON_ARRAY();
  SELECT call_id, user_id INTO callID, userID FROM end_calls_view WHERE company_phone = companyPhone AND user_sip = userSip ORDER BY call_id DESC LIMIT 1;
  IF callID IS NOT NULL
    THEN BEGIN
      INSERT INTO files (file_name, type_id, user_id) VALUES (filePath, 45, userID);
      SELECT file_id INTO fileID FROM files ORDER BY file_id DESC LIMIT 1;
      UPDATE calls SET file_id = fileID WHERE call_id = callID;
      SET responce = JSON_MERGE(responce, JSON_OBJECT(
        "type", "moveFile",
        "data", JSON_OBJECT(
          "fileName", fileName,
          "from", "attachments",
          "to", "files"
        )
      ));
    END;
  END IF;
  RETURN responce;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `setUserRinging` (`connectionHash` VARCHAR(32) CHARSET utf8, `ringing` BOOLEAN) RETURNS JSON NO SQL
BEGIN
  DECLARE userID INT(11);
  DECLARE connectionValid TINYINT(1);
  DECLARE responce JSON;
  SET responce = JSON_ARRAY();
  SET connectionValid = checkConnection(connectionHash);
  IF connectionValid 
    THEN BEGIN
      SELECT user_id INTO userID FROM connections WHERE connection_hash = connectionHash;
      UPDATE users SET user_ringing = ringing WHERE user_id = userID;
      SET responce = JSON_MERGE(responce, sendToAllUserSockets(userID, JSON_ARRAY(
        JSON_OBJECT(
          "type", "merge",
          "data", JSON_OBJECT(
            "ringing", ringing
          )
        )
      )));
    END;
    ELSE SET responce = JSON_MERGE(responce, JSON_OBJECT(
      "type", "sendToSocket",
      "data", JSON_OBJECT(
        "socketID", connectionApiID,
        "data", JSON_ARRAY(JSON_OBJECT(
          "type", "merge",
          "data", JSON_OBJECT(
            "auth", 0,
            "loginMessage", "Требуется ручной вход в систему"
          )
        ))
      )
    ));
  END IF;
  RETURN responce;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `successCompaniesArray` () RETURNS JSON NO SQL
BEGIN
  DECLARE done TINYINT(1);
  DECLARE responce, company JSON;
    DECLARE companiesCursor CURSOR FOR SELECT JSON_OBJECT("requestID", company_api_request_id, "applicationID", company_application_id) FROM companies WHERE type_id = 16 and date(company_date_create) = date(now());
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    SET responce = JSON_ARRAY();
    OPEN companiesCursor;
      companiesLoop: LOOP
          FETCH companiesCursor INTO company;
            IF done
              THEN LEAVE companiesLoop;
            END IF;
            SET responce = JSON_MERGE(responce, company);
            ITERATE companiesLoop;
        END LOOP;
    CLOSE companiesCursor;
    RETURN responce;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `updateFileName` (`fileID` INT(11), `fileName` VARCHAR(128) CHARSET utf8) RETURNS JSON NO SQL
BEGIN
  DECLARE responce JSON;
  DECLARE userID INT(11);
  SET responce = JSON_ARRAY();
  UPDATE files SET file_name = fileName, type_id = 21 WHERE file_id = fileID;
  UPDATE companies SET type_id = 21 WHERE file_id = fileID;
  SELECT user_id INTO userID FROM files WHERE file_id = fileID;
  SET responce = JSON_MERGE(responce, sendToAllUserSockets(userID, JSON_ARRAY(
    JSON_OBJECT(
      "type", "mergeDeep",
      "data", JSON_OBJECT(
        "download", JSON_OBJECT(
          "fileURL", fileName,
          "message", "Файл успешно создан",
          "companiesCount", 0
        )
      )
    ),
    JSON_OBJECT(
      "type", "merge",
      "data", JSON_OBJECT(
        "files", getUserFiles(userID)
      )
    )
  )));
  RETURN responce;
END$$

DELIMITER ;
CREATE TABLE `active_calls_view` (
`call_id` int(11)
,`type_id` int(11)
,`user_sip` varchar(20)
,`company_phone` varchar(359)
,`user_id` int(11)
,`company_id` int(11)
);

CREATE TABLE `banks` (
  `bank_id` int(11) NOT NULL,
  `bank_name` varchar(128) COLLATE utf8_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

CREATE TABLE `bank_cities` (
  `bank_city_id` int(11) NOT NULL,
  `bank_id` int(11) NOT NULL,
  `city_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

CREATE TABLE `bank_cities_time_priority` (
  `bank_city_time_priority_id` int(11) NOT NULL,
  `bank_id` int(11) NOT NULL,
  `time_id` int(11) NOT NULL,
  `city_id` int(11) NOT NULL,
  `priority` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
CREATE TABLE `bank_cities_time_priority_companies_view` (
`time_id` int(11)
,`time_value` varchar(5)
,`priority` int(11)
,`region_name` varchar(60)
,`city_name` varchar(60)
,`company_id` int(11)
,`user_id` int(11)
,`company_date_create` varchar(19)
,`type_id` int(11)
,`old_type_id` int(11)
,`company_date_update` varchar(19)
,`company_discount` int(11)
,`company_discount_percent` tinyint(1)
,`company_ogrn` varchar(15)
,`company_ogrn_date` varchar(10)
,`company_person_name` varchar(128)
,`company_person_surname` varchar(128)
,`company_person_patronymic` varchar(128)
,`company_person_birthday` varchar(10)
,`company_person_birthplace` varchar(1024)
,`company_inn` varchar(12)
,`company_address` varchar(1024)
,`company_doc_number` varchar(120)
,`company_doc_date` varchar(10)
,`company_organization_name` varchar(1024)
,`company_organization_code` varchar(20)
,`company_phone` varchar(120)
,`company_email` varchar(1024)
,`company_okved_code` varchar(8)
,`company_okved_name` varchar(2048)
,`purchase_id` int(11)
,`template_id` int(11)
,`company_kpp` varchar(9)
,`company_index` varchar(9)
,`company_house` varchar(128)
,`company_region_type` varchar(50)
,`company_region_name` varchar(120)
,`company_area_type` varchar(60)
,`company_area_name` varchar(60)
,`company_locality_type` varchar(60)
,`company_locality_name` varchar(60)
,`company_street_type` varchar(60)
,`company_street_name` varchar(60)
,`company_innfl` varchar(12)
,`company_person_position_type` varchar(60)
,`company_person_position_name` varchar(512)
,`company_doc_name` varchar(120)
,`company_doc_gifter` varchar(256)
,`company_doc_code` varchar(7)
,`company_doc_house` varchar(128)
,`company_doc_flat` varchar(40)
,`company_doc_region_type` varchar(50)
,`company_doc_region_name` varchar(120)
,`company_doc_area_type` varchar(60)
,`company_doc_area_name` varchar(60)
,`company_doc_locality_type` varchar(60)
,`company_doc_locality_name` varchar(60)
,`company_doc_street_type` varchar(60)
,`company_doc_street_name` varchar(60)
,`city_id` int(11)
,`region_id` int(11)
,`bank_id` int(11)
,`company_date_registration` varchar(10)
,`company_person_sex` int(1)
,`company_ip_type` varchar(1024)
,`company_json` json
);
CREATE TABLE `bank_times_view` (
`time_id` int(11)
,`time_value` varchar(5)
,`bank_id` int(11)
);

CREATE TABLE `calls` (
  `call_id` int(11) NOT NULL,
  `type_id` int(11) DEFAULT NULL,
  `company_id` int(11) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `call_date_create` varchar(19) COLLATE utf8_bin NOT NULL,
  `file_id` int(11) DEFAULT NULL,
  `call_api_id_with_rec` varchar(128) COLLATE utf8_bin DEFAULT NULL,
  `call_date_update` varchar(19) COLLATE utf8_bin DEFAULT NULL,
  `call_api_id_1` varchar(128) COLLATE utf8_bin DEFAULT NULL,
  `call_api_id_2` varchar(128) COLLATE utf8_bin DEFAULT NULL,
  `call_record` tinyint(1) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
DELIMITER $$
CREATE TRIGGER `calls_after_insert` AFTER INSERT ON `calls` FOR EACH ROW BEGIN
  IF NEW.company_id IS NOT NULL
    THEN UPDATE companies SET call_id = NEW.call_id WHERE company_id = NEW.company_id;
  END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `calls_after_update` AFTER UPDATE ON `calls` FOR EACH ROW BEGIN
  IF NEW.company_id IS NOT NULL
    THEN UPDATE companies SET call_id = NEW.call_id, type_id = IF((NEW.call_api_id_1 IS NULL OR NEW.call_api_id_2 IS NULL) AND NEW.type_id IN (40, 41, 42), IF(type_id = 35, 36, 35), type_id) WHERE company_id = NEW.company_id; 
  END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `calls_before_insert` BEFORE INSERT ON `calls` FOR EACH ROW BEGIN
  SET NEW.call_date_create = NOW();
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `calls_before_update` BEFORE UPDATE ON `calls` FOR EACH ROW BEGIN
  SET NEW.call_date_update = NOW();
END
$$
DELIMITER ;
CREATE TABLE `calls_file_view` (
`call_id` int(11)
,`file_id` int(11)
,`file_name` varchar(128)
);

CREATE TABLE `cities` (
  `city_id` int(11) NOT NULL,
  `city_name` varchar(60) COLLATE utf8_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

CREATE TABLE `codes` (
  `code_id` int(11) NOT NULL,
  `code_value` int(3) NOT NULL,
  `region_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

CREATE TABLE `columns` (
  `column_id` int(11) NOT NULL,
  `column_price` int(11) NOT NULL DEFAULT '0',
  `column_name` varchar(128) COLLATE utf8_bin NOT NULL,
  `column_blocked` tinyint(1) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
CREATE TABLE `columns_translates_view` (
`column_id` int(11)
,`translate_to` varchar(128)
,`column_name` varchar(128)
);

CREATE TABLE `companies` (
  `company_id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `company_date_create` varchar(19) COLLATE utf8_bin NOT NULL,
  `type_id` int(11) DEFAULT '10',
  `company_date_update` varchar(19) COLLATE utf8_bin DEFAULT NULL,
  `company_discount` int(11) DEFAULT '0',
  `company_discount_percent` tinyint(1) NOT NULL DEFAULT '0',
  `company_ogrn` varchar(15) COLLATE utf8_bin DEFAULT NULL,
  `company_ogrn_date` varchar(10) COLLATE utf8_bin DEFAULT NULL,
  `company_person_name` varchar(128) COLLATE utf8_bin DEFAULT NULL,
  `company_person_surname` varchar(128) COLLATE utf8_bin DEFAULT NULL,
  `company_person_patronymic` varchar(128) COLLATE utf8_bin DEFAULT NULL,
  `company_person_birthday` varchar(10) COLLATE utf8_bin DEFAULT NULL,
  `company_person_birthplace` varchar(1024) COLLATE utf8_bin DEFAULT NULL,
  `company_inn` varchar(12) COLLATE utf8_bin DEFAULT NULL,
  `company_address` varchar(1024) COLLATE utf8_bin DEFAULT NULL,
  `company_doc_number` varchar(120) COLLATE utf8_bin DEFAULT NULL,
  `company_doc_date` varchar(10) COLLATE utf8_bin DEFAULT NULL,
  `company_organization_name` varchar(1024) COLLATE utf8_bin DEFAULT NULL,
  `company_organization_code` varchar(20) COLLATE utf8_bin DEFAULT NULL,
  `company_phone` varchar(120) COLLATE utf8_bin DEFAULT NULL,
  `company_email` varchar(1024) COLLATE utf8_bin DEFAULT NULL,
  `company_okved_code` varchar(8) COLLATE utf8_bin DEFAULT NULL,
  `company_okved_name` varchar(2048) COLLATE utf8_bin DEFAULT NULL,
  `purchase_id` int(11) DEFAULT NULL,
  `template_id` int(11) DEFAULT NULL,
  `company_kpp` varchar(9) COLLATE utf8_bin DEFAULT NULL,
  `company_index` varchar(9) COLLATE utf8_bin DEFAULT NULL,
  `company_house` varchar(128) COLLATE utf8_bin DEFAULT NULL,
  `company_region_type` varchar(50) COLLATE utf8_bin DEFAULT NULL,
  `company_region_name` varchar(120) COLLATE utf8_bin DEFAULT NULL,
  `company_area_type` varchar(60) COLLATE utf8_bin DEFAULT NULL,
  `company_area_name` varchar(60) COLLATE utf8_bin DEFAULT NULL,
  `company_locality_type` varchar(60) COLLATE utf8_bin DEFAULT NULL,
  `company_locality_name` varchar(60) COLLATE utf8_bin DEFAULT NULL,
  `company_street_type` varchar(60) COLLATE utf8_bin DEFAULT NULL,
  `company_street_name` varchar(60) COLLATE utf8_bin DEFAULT NULL,
  `company_innfl` varchar(12) COLLATE utf8_bin DEFAULT NULL,
  `company_person_position_type` varchar(60) COLLATE utf8_bin DEFAULT NULL,
  `company_person_position_name` varchar(512) COLLATE utf8_bin DEFAULT NULL,
  `company_doc_name` varchar(120) COLLATE utf8_bin DEFAULT NULL,
  `company_doc_gifter` varchar(256) COLLATE utf8_bin DEFAULT NULL,
  `company_doc_code` varchar(7) COLLATE utf8_bin DEFAULT NULL,
  `company_doc_house` varchar(128) COLLATE utf8_bin DEFAULT NULL,
  `company_doc_flat` varchar(40) COLLATE utf8_bin DEFAULT NULL,
  `company_doc_region_type` varchar(50) COLLATE utf8_bin DEFAULT NULL,
  `company_doc_region_name` varchar(120) COLLATE utf8_bin DEFAULT NULL,
  `company_doc_area_type` varchar(60) COLLATE utf8_bin DEFAULT NULL,
  `company_doc_area_name` varchar(60) COLLATE utf8_bin DEFAULT NULL,
  `company_doc_locality_type` varchar(60) COLLATE utf8_bin DEFAULT NULL,
  `company_doc_locality_name` varchar(60) COLLATE utf8_bin DEFAULT NULL,
  `company_doc_street_type` varchar(60) COLLATE utf8_bin DEFAULT NULL,
  `company_doc_street_name` varchar(60) COLLATE utf8_bin DEFAULT NULL,
  `city_id` int(11) DEFAULT NULL,
  `region_id` int(11) DEFAULT NULL,
  `bank_id` int(11) DEFAULT NULL,
  `company_date_registration` varchar(10) COLLATE utf8_bin DEFAULT NULL,
  `company_person_sex` int(1) DEFAULT NULL,
  `company_ip_type` varchar(1024) COLLATE utf8_bin DEFAULT NULL,
  `company_json` json DEFAULT NULL,
  `file_id` int(11) DEFAULT NULL,
  `company_comment` text COLLATE utf8_bin,
  `company_api_request_id` varchar(128) COLLATE utf8_bin DEFAULT NULL,
  `company_application_id` varchar(128) COLLATE utf8_bin DEFAULT NULL,
  `company_region_code` varchar(128) COLLATE utf8_bin DEFAULT NULL,
  `company_house_block` varchar(128) COLLATE utf8_bin DEFAULT NULL,
  `company_apartment` varchar(128) COLLATE utf8_bin DEFAULT NULL,
  `company_date_call_back` varchar(19) COLLATE utf8_bin DEFAULT NULL,
  `old_type_id` int(11) DEFAULT NULL,
  `call_id` int(11) DEFAULT NULL,
  `company_ringing` tinyint(1) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
DELIMITER $$
CREATE TRIGGER `companies_before_insert` BEFORE INSERT ON `companies` FOR EACH ROW BEGIN
  DECLARE innLength, templateType INT(11);
  SET NEW.company_date_create = NOW();
  SET innLength = CHAR_LENGTH(NEW.company_inn);
  IF innLength = 9 OR innLength = 11
    THEN SET NEW.company_inn = CONCAT("0", NEW.company_inn);
  END IF;
  SET NEW.region_id = (SELECT region_id FROM codes WHERE code_value = SUBSTRING(NEW.company_inn, 1, 2));
  SET NEW.city_id = (SELECT city_id FROM fns_codes WHERE fns_code_value = SUBSTRING(NEW.company_inn, 1, 4));
  SET NEW.bank_id = (SELECT bank_id FROM bank_cities WHERE city_id = NEW.city_id LIMIT 1);
  SET NEW.company_phone = REPLACE(CONCAT("+", REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(NEW.company_phone, "(", ""), ")",""), " ", ""), "-", ""), "—", ""), "+", "")), "+8", "+7");
  IF NEW.bank_id = 1 AND (NEW.company_phone IS NULL OR NEW.company_inn IS NULL)
    THEN SET NEW.bank_id = NULL;
  END IF;
  SELECT type_id INTO templateType FROM templates WHERE template_id = NEW.template_id;
  IF NEW.company_organization_name IS NULL AND templateType = 11
    THEN SET NEW.company_organization_name = CONCAT(
      IF(NEW.company_person_name IS NOT NULL OR NEW.company_person_surname IS NOT NULL OR NEW.company_person_patronymic IS NOT NULL, "ИП", ""),
      IF(NEW.company_person_surname IS NOT NULL, CONCAT(" ", NEW.company_person_surname, " "), ""),
      IF(NEW.company_person_name IS NOT NULL, CONCAT(NEW.company_person_name, " "), ""),
      IF(NEW.company_person_patronymic IS NOT NULL, CONCAT(NEW.company_person_patronymic, " "), "")
    );
  END IF;
  SET NEW.company_json = json_object(
    'city_name', (SELECT city_name FROM cities WHERE city_id = NEW.city_id),
    'region_name', (SELECT region_name FROM regions WHERE region_id = NEW.region_id),
    'type_id', NEW.type_id,
    'company_id', NEW.company_id,
    'template_id', NEW.template_id,
    'city_id', NEW.city_id,
    'region_id', NEW.region_id,
    'company_date_create', NEW.company_date_create,
    'company_date_update', NEW.company_date_update,
    'company_ogrn', NEW.company_ogrn,
    'company_ogrn_date', NEW.company_ogrn_date,
    'company_person_birthday', NEW.company_person_birthday,
    'company_doc_date', NEW.company_doc_date,
    'company_person_name', NEW.company_person_name,
    'company_person_surname', NEW.company_person_surname,
    'company_person_patronymic', NEW.company_person_patronymic,
    'company_person_birthplace', NEW.company_person_birthplace,
    'company_address', NEW.company_address,
    'company_organization_name', NEW.company_organization_name,
    'company_email', NEW.company_email,
    'company_inn', NEW.company_inn,
    'company_doc_number', NEW.company_doc_number,
    'company_innfl', NEW.company_innfl,
    'company_organization_code', NEW.company_organization_code,
    'company_phone', NEW.company_phone,
    'company_house', NEW.company_house,
    'company_doc_house', NEW.company_doc_house,
    'company_okved_code', NEW.company_okved_code,
    'company_okved_name', NEW.company_okved_name,
    'company_kpp', NEW.company_kpp,
    'company_index', NEW.company_index,
    'company_region_type', NEW.company_region_type,
    'company_doc_region_type', NEW.company_doc_region_type,
    'company_region_name', NEW.company_region_name,
    'company_doc_name', NEW.company_doc_name,
    'company_doc_region_name', NEW.company_doc_region_name,
    'company_area_type', NEW.company_area_type,
    'company_area_name', NEW.company_area_name,
    'company_locality_type', NEW.company_locality_type,
    'company_locality_name', NEW.company_locality_name,
    'company_street_type', NEW.company_street_type,
    'company_street_name', NEW.company_street_name,
    'company_person_position_type', NEW.company_person_position_type,
    'company_person_position_name', NEW.company_person_position_name,
    'company_doc_area_type', NEW.company_doc_area_type,
    'company_doc_area_name', NEW.company_doc_area_name,
    'company_doc_locality_type', NEW.company_doc_locality_type,
    'company_doc_locality_name', NEW.company_doc_locality_name,
    'company_doc_street_type', NEW.company_doc_street_type,
    'company_doc_street_name', NEW.company_doc_street_name,
    'company_doc_gifter', NEW.company_doc_gifter,
    'company_doc_code', NEW.company_doc_code,
    'company_doc_flat', NEW.company_doc_flat,
    "company_date_call_back", NEW.company_date_call_back
  );
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `companies_before_update` BEFORE UPDATE ON `companies` FOR EACH ROW BEGIN
  DECLARE callType INT(11);
  DECLARE fileName VARCHAR(128);
  IF NEW.call_id IS NOT NULL
    THEN BEGIN
      SELECT type_id INTO callType FROM calls WHERE call_id = NEW.call_id;
      SELECT file_name INTO fileName FROM calls_file_view WHERE call_id = NEW.call_id;
    END;
  END IF;
  SET NEW.company_date_update = NOW();
  SET NEW.company_json = JSON_SET(NEW.company_json,
    "$.type_id", NEW.type_id,
    "$.company_date_update", NEW.company_date_update,
    "$.company_comment", NEW.company_comment,
    "$.company_date_call_back", NEW.company_date_call_back,
    "$.call_type", callType,
    "$.file_name", fileName
  );
  IF NEW.type_id != OLD.type_id 
    THEN SET NEW.old_type_id = OLD.type_id;
  END IF;
END
$$
DELIMITER ;

CREATE TABLE `connections` (
  `connection_id` int(11) NOT NULL,
  `connection_hash` varchar(32) COLLATE utf8_bin NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `connection_date_create` varchar(19) COLLATE utf8_bin NOT NULL,
  `connection_date_update` varchar(19) COLLATE utf8_bin DEFAULT NULL,
  `connection_date_disconnect` varchar(19) COLLATE utf8_bin DEFAULT NULL,
  `type_id` int(11) DEFAULT NULL,
  `connection_api_id` varchar(128) COLLATE utf8_bin DEFAULT NULL,
  `connection_end` tinyint(1) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
DELIMITER $$
CREATE TRIGGER `connections_after_insert` AFTER INSERT ON `connections` FOR EACH ROW BEGIN
  IF NEW.user_id IS NOT NULL
      THEN UPDATE users SET user_connections_count = (SELECT COUNT(*) FROM connections WHERE user_id = NEW.user_id AND connection_end = 0) WHERE user_id = NEW.user_id;
  END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `connections_after_update` AFTER UPDATE ON `connections` FOR EACH ROW BEGIN
  IF NEW.user_id IS NOT NULL
      THEN UPDATE users SET user_connections_count = (SELECT COUNT(*) FROM connections WHERE user_id = NEW.user_id AND connection_end = 0) WHERE user_id = NEW.user_id;
  END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `connections_before_insert` BEFORE INSERT ON `connections` FOR EACH ROW BEGIN
  SET NEW.connection_date_create = NOW();
    IF NEW.connection_end 
      THEN SET NEW.connection_date_disconnect = NOW();
    END IF;
    hashLoop: LOOP
      SET NEW.connection_hash = getHash(32);
      IF (SELECT COUNT(*) FROM connections WHERE connection_hash = NEW.connection_hash) > 0
          THEN ITERATE hashLoop;
            ELSE LEAVE hashLoop;
        END IF;
    END LOOP;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `connections_before_update` BEFORE UPDATE ON `connections` FOR EACH ROW BEGIN
  SET NEW.connection_date_update = NOW();
  IF NEW.connection_end
    THEN SET NEW.connection_date_disconnect = NOW();
  END IF;
  IF NEW.user_id IS NOT NULL AND (NEW.user_id != OLD.user_id OR OLD.user_id IS NULL)
    THEN INSERT INTO states (connection_id, user_id) VALUES (NEW.connection_id, NEW.user_id);
  END IF;
END
$$
DELIMITER ;
CREATE TABLE `empty_companies_view` (
`company_id` int(11)
,`company_date_create` varchar(19)
);
CREATE TABLE `end_calls_view` (
`call_id` int(11)
,`type_id` int(11)
,`user_sip` varchar(20)
,`company_phone` varchar(120)
,`user_id` int(11)
,`company_id` int(11)
,`file_id` int(11)
);

CREATE TABLE `files` (
  `file_id` int(11) NOT NULL,
  `file_name` varchar(128) COLLATE utf8_bin DEFAULT NULL,
  `type_id` int(11) DEFAULT NULL,
  `file_date_create` varchar(19) COLLATE utf8_bin NOT NULL,
  `purchase_id` int(11) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
DELIMITER $$
CREATE TRIGGER `files_before_insert` BEFORE INSERT ON `files` FOR EACH ROW BEGIN
  SET NEW.file_date_create = NOW();
END
$$
DELIMITER ;

CREATE TABLE `fns_codes` (
  `fns_code_id` int(11) NOT NULL,
  `region_id` int(11) DEFAULT NULL,
  `fns_code_value` int(2) NOT NULL,
  `city_id` int(11) DEFAULT NULL,
  `fns_name` varchar(128) COLLATE utf8_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

CREATE TABLE `purchases` (
  `purchase_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `purchase_date_create` varchar(19) COLLATE utf8_bin NOT NULL,
  `purchase_date_update` varchar(19) COLLATE utf8_bin DEFAULT NULL,
  `purchase_date_buy` varchar(19) COLLATE utf8_bin DEFAULT NULL,
  `purchase_price` int(11) NOT NULL,
  `purchase_filter_date_start` varchar(19) COLLATE utf8_bin NOT NULL,
  `purchase_filter_date_end` varchar(19) COLLATE utf8_bin NOT NULL,
  `purchase_filter_items_count` int(11) NOT NULL,
  `purchase_filter_ogrnip` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_ogrnip_null` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_ogrnip_date` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_ogrnip_date_null` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_discount` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_person_name` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_person_name_null` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_person_surname` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_person_surname_null` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_person_patronymic` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_person_patronymic_null` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_person_birthday` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_person_birthday_null` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_person_birthplace` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_person_birthplace_null` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_inn` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_inn_null` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_address` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_address_null` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_doc_number` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_doc_number_null` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_doc_date` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_doc_date_null` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_organization_name` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_organization_name_null` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_organization_code` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_organization_code_null` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_phone` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_phone_null` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_email` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_email_null` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_okved_code` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_okved_code_null` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_okved_name` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_filter_okved_name_null` tinyint(1) NOT NULL DEFAULT '0',
  `transaction_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
DELIMITER $$
CREATE TRIGGER `purchases_before_insert` BEFORE INSERT ON `purchases` FOR EACH ROW BEGIN
  SET NEW.purchase_date_create = NOW();
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `purchases_before_update` BEFORE UPDATE ON `purchases` FOR EACH ROW BEGIN
  SET NEW.purchase_date_update = NOW();
END
$$
DELIMITER ;

CREATE TABLE `regions` (
  `region_id` int(11) NOT NULL,
  `region_name` varchar(60) COLLATE utf8_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

CREATE TABLE `states` (
  `state_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `connection_id` int(11) NOT NULL,
  `state_json` json NOT NULL,
  `state_date_create` varchar(19) COLLATE utf8_bin NOT NULL,
  `state_date_update` varchar(19) COLLATE utf8_bin DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
DELIMITER $$
CREATE TRIGGER `state_before_insert` BEFORE INSERT ON `states` FOR EACH ROW BEGIN
  DECLARE typeID INT(11);
  SET NEW.state_date_create = NOW();
  SELECT type_id INTO typeID FROM users WHERE user_id = NEW.user_id;
  IF typeID = 1 OR typeID = 19 OR typeID = 18
    THEN BEGIN
      SET NEW.state_json = JSON_OBJECT(); 
      IF typeID = 1 OR typeID = 19
        THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic", 
          JSON_OBJECT(
            "dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 WEEK)),
            "dateEnd", DATE(NOW()),
            "typeToView", 3,
            "period", 0,
            "types", JSON_ARRAY(
              16
            ),
            "user", 0,
            "dataDateStart", DATE(SUBDATE(NOW(), INTERVAL 1 WEEK)),
            "dataDateEnd", DATE(NOW()),
            "dataPeriod", 0,
            "dataBank", 1,
            "dataFree", 1
          )
        );
      END IF;
      IF typeID = 1
        THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download", JSON_OBJECT(
          "dateStart", DATE(NOW()),
          "dateEnd", DATE(NOW()),
          "type", 10,
          "types", JSON_ARRAY(
            10
          ),
          "regions", JSON_ARRAY(),
          "banks", JSON_ARRAY(NULL),
          "nullColumns", JSON_ARRAY(),
          "notNullColumns", JSON_ARRAY(),
          "limit", 50,
          "offset", 0,
          "orders", JSON_ARRAY(
            JSON_OBJECT(
              "name", "company_date_create",
              "desc", 1
            )
          ),
          "count", 100
        ));
      END IF;
      IF typeID = 1 OR typeID = 18
        THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution", 
          JSON_OBJECT(
            "work", JSON_OBJECT(
              "rowStart", 1,
              "rowLimit", 10
            ),
            "invalidate", JSON_OBJECT(
              "dateStart", DATE(NOW()),
              "dateEnd", DATE(NOW()),
              "type", 0,
              "rowStart", 1,
              "rowLimit", 10
            ),
            "callBack", JSON_OBJECT(
              "dateStart", DATE(NOW()),
              "dateEnd", DATE(NOW()),
              "type", 0,
              "rowStart", 1,
              "rowLimit", 10
            ),
            "api", JSON_OBJECT(
              "dateStart", DATE(NOW()),
              "dateEnd", DATE(NOW()),
              "type", 0,
              "rowStart", 1,
              "rowLimit", 10
            ),
            "notDial", JSON_OBJECT(
              "dateStart", DATE(NOW()),
              "dateEnd", DATE(NOW()),
              "type", 0,
              "rowStart", 1,
              "rowLimit", 10
            ),
            "difficult", JSON_OBJECT(
              "dateStart", DATE(NOW()),
              "dateEnd", DATE(NOW()),
              "type", 0,
              "rowStart", 1,
              "rowLimit", 10
            )
          )
        );
      END IF;
    END;
  END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `state_before_update` BEFORE UPDATE ON `states` FOR EACH ROW BEGIN
  DECLARE typeToView, period, bankID, type INT(11);
  DECLARE firstDate VARCHAR(19);
  DECLARE dataFree, dataBank, ringing TINYINT(11);
  DECLARE types JSON;
  SELECT bank_id INTO bankID FROM users WHERE user_id = NEW.user_id;
  SET NEW.state_date_update = NOW();
  IF JSON_EXTRACT(NEW.state_json, "$.statistic") IS NOT NULL
    THEN BEGIN
      SET typeToView = JSON_EXTRACT(NEW.state_json, "$.statistic.typeToView");
      SET period = JSON_EXTRACT(NEW.state_json, "$.statistic.period");
      CASE typeToView
        WHEN 0 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(9, 13, 14, 15, 16, 17, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 35, 36, 37));
        WHEN 1 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(17, 24, 31, 32));
        WHEN 2 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(15));
        WHEN 3 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(16, 25, 26, 27, 28, 29, 30));
        WHEN 4 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(13));
        WHEN 5 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(14));
        WHEN 6 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(9));
        WHEN 7 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(15, 16, 17, 24, 25, 26, 27, 28, 29, 30, 31, 32));
        WHEN 8 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(13, 14, 23, 35, 36, 37));
        WHEN 9 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(13, 14, 15, 16, 17, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 35, 36, 37));
        WHEN 10 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(23));
        WHEN 11 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(24));
        WHEN 12 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(25));
        WHEN 13 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(26));
        WHEN 14 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(27));
        WHEN 15 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(28));
        WHEN 16 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(29));
        WHEN 17 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(30));
        WHEN 18 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(31));
        WHEN 19 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(32));
        WHEN 20 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(17));
        WHEN 21 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(16));
        WHEN 22 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(35));
        WHEN 23 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(36));
        WHEN 24 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(37));
        ELSE SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.types", JSON_ARRAY(9, 13, 14, 15, 16, 17, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 35, 36, 37));
      END CASE;
      SET types = JSON_EXTRACT(NEW.state_json, "$.statistic.types");
      CASE period
        WHEN 0 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 WEEK)), "$.statistic.dateEnd", DATE(NOW()));
        WHEN 1 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 MONTH)), "$.statistic.dateEnd", DATE(NOW()));
        WHEN 2 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 YEAR)), "$.statistic.dateEnd", DATE(NOW()));
        WHEN 3 THEN BEGIN 
          SELECT company_date_update INTO firstDate FROM companies WHERE JSON_CONTAINS(types, JSON_ARRAY(type_id)) AND bank_id = bankID ORDER BY company_date_update LIMIT 1;
          IF firstDate IS NULL
            THEN SET firstDate = DATE(NOW());
          END IF;
          SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.dateStart", DATE(firstDate), "$.statistic.dateEnd", DATE(NOW()));
        END;
        WHEN 4 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.dateStart", DATE(NOW()), "$.statistic.dateEnd", DATE(NOW()));
        WHEN 5 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 DAY)), "$.statistic.dateEnd", DATE(SUBDATE(NOW(), INTERVAL 1 DAY)));
        WHEN 6 THEN BEGIN END;
        ELSE SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 WEEK)), "$.statistic.dateEnd", DATE(NOW()));
      END CASE;
      SET period = JSON_EXTRACT(NEW.state_json, "$.statistic.dataPeriod");
      CASE period
        WHEN 0 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.dataDateStart", DATE(SUBDATE(NOW(), INTERVAL 1 WEEK)), "$.statistic.dataDateEnd", DATE(NOW()));
        WHEN 1 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.dataDateStart", DATE(SUBDATE(NOW(), INTERVAL 1 MONTH)), "$.statistic.dataDateEnd", DATE(NOW()));
        WHEN 2 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.dataDateStart", DATE(SUBDATE(NOW(), INTERVAL 1 YEAR)), "$.statistic.dataDateEnd", DATE(NOW()));
        WHEN 3 THEN BEGIN
          SET dataFree = JSON_UNQUOTE(JSON_EXTRACT(NEW.state_json, "$.statistic.dataFree"));
          SET dataBank = JSON_UNQUOTE(JSON_EXTRACT(NEW.state_json, "$.statistic.dataBank"));
          SELECT company_date_create INTO firstDate FROM companies WHERE IF(dataFree, type_id = 10, 1) AND IF(dataBank, bank_id = bankID, 1) ORDER BY company_date_create LIMIT 1;
          SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.dataDateStart", DATE(firstDate), "$.statistic.dataDateEnd", DATE(NOW()));
        END;
        WHEN 4 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.dataDateStart", DATE(SUBDATE(NOW(), INTERVAL 1 DAY)), "$.statistic.dataDateEnd", DATE(SUBDATE(NOW(), INTERVAL 1 DAY)));
        WHEN 5 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.dataDateStart", DATE(NOW()), "$.statistic.dataDateEnd", DATE(NOW()));
        WHEN 6 THEN BEGIN END;
      END CASE;
    END;
  END IF;
  IF JSON_EXTRACT(NEW.state_json, "$.download") IS NOT NULL
    THEN BEGIN
      SET type = JSON_EXTRACT(NEW.state_json, "$.download.type");
      CASE type
        WHEN 0 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(9, 13, 14, 15, 16, 17, 10, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 35, 36, 37));
        WHEN 1 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(17, 24, 31, 32));
        WHEN 2 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(15));
        WHEN 3 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(16, 25, 26, 27, 28, 29, 30));
        WHEN 4 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(13));
        WHEN 5 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(14));
        WHEN 6 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(9));
        WHEN 7 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(15, 16, 17, 24, 25, 26, 27, 28, 29, 30, 31, 32));
        WHEN 8 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(13, 14, 23, 35, 36, 37));
        WHEN 9 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(13, 14, 15, 16, 17, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 35, 36, 37));
        WHEN 10 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(10));
        WHEN 11 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(23));
        WHEN 12 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(24));
        WHEN 13 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(25));
        WHEN 14 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(26));
        WHEN 15 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(27));
        WHEN 16 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(28));
        WHEN 17 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(29));
        WHEN 18 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(30));
        WHEN 19 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(31));
        WHEN 20 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(32));
        WHEN 21 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(17));
        WHEN 22 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(16));
        WHEN 23 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(35));
        WHEN 24 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(36));
        WHEN 25 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(37));
        ELSE SET NEW.state_json = JSON_SET(NEW.state_json, "$.download.types", JSON_ARRAY(9, 13, 14, 15, 16, 17, 10, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 35, 36, 37));
      END CASE;
    END;
  END IF;
  IF JSON_EXTRACT(NEW.state_json, "$.distribution") IS NOT NULL
    THEN BEGIN
      SET type = JSON_EXTRACT(NEW.state_json, "$.distribution.invalidate.type");
      CASE type
        WHEN 0 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.invalidate.dateStart", DATE(NOW()), "$.distribution.invalidate.dateEnd", DATE(NOW()));
        WHEN 1 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.invalidate.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 WEEK)), "$.distribution.invalidate.dateEnd", DATE(NOW()));
        WHEN 2 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.invalidate.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 MONTH)), "$.distribution.invalidate.dateEnd", DATE(NOW()));
        WHEN 3 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.invalidate.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 YEAR)), "$.distribution.invalidate.dateEnd", DATE(NOW()));
        WHEN 4 THEN BEGIN 
          SELECT company_date_create INTO firstDate FROM companies WHERE type_id = 14 AND bank_id = bankID ORDER BY company_date_create LIMIT 1;
          IF firstDate IS NULL
            THEN SET firstDate = DATE(NOW());
          END IF;
          SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.invalidate.dateStart", DATE(firstDate), "$.distribution.invalidate.dateEnd", DATE(NOW()));
        END;
        WHEN 5 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.invalidate.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 DAY)), "$.distribution.invalidate.dateEnd", DATE(SUBDATE(NOW(), INTERVAL 1 DAY)));
        WHEN 6 THEN BEGIN
        END;
        ELSE SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.invalidate.dateStart", DATE(NOW()), "$.distribution.invalidate.dateEnd", DATE(NOW()));
      END CASE;
      SET type = JSON_EXTRACT(NEW.state_json, "$.distribution.callBack.type");
      CASE type
        WHEN 0 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.callBack.dateStart", DATE(NOW()), "$.distribution.callBack.dateEnd", DATE(NOW()));
        WHEN 1 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.callBack.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 WEEK)), "$.distribution.callBack.dateEnd", DATE(NOW()));
        WHEN 2 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.callBack.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 MONTH)), "$.distribution.callBack.dateEnd", DATE(NOW()));
        WHEN 3 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.callBack.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 YEAR)), "$.distribution.callBack.dateEnd", DATE(NOW()));
        WHEN 4 THEN BEGIN 
          SELECT company_date_create INTO firstDate FROM companies WHERE type_id = 23 AND bank_id = bankID ORDER BY company_date_create LIMIT 1;
          IF firstDate IS NULL
            THEN SET firstDate = DATE(NOW());
          END IF;
          SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.callBack.dateStart", DATE(firstDate), "$.distribution.callBack.dateEnd", DATE(NOW()));
        END;
        WHEN 5 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.callBack.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 DAY)), "$.distribution.callBack.dateEnd", DATE(SUBDATE(NOW(), INTERVAL 1 DAY)));
        WHEN 6 THEN BEGIN
        END;
        ELSE SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.callBack.dateStart", DATE(NOW()), "$.distribution.callBack.dateEnd", DATE(NOW()));
      END CASE;
      SET type = JSON_EXTRACT(NEW.state_json, "$.distribution.api.type");
      CASE type
        WHEN 0 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.api.dateStart", DATE(NOW()), "$.distribution.api.dateEnd", DATE(NOW()));
        WHEN 1 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.api.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 WEEK)), "$.distribution.api.dateEnd", DATE(NOW()));
        WHEN 2 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.api.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 MONTH)), "$.distribution.api.dateEnd", DATE(NOW()));
        WHEN 3 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.api.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 YEAR)), "$.distribution.api.dateEnd", DATE(NOW()));
        WHEN 4 THEN BEGIN 
          SELECT company_date_create INTO firstDate FROM companies WHERE type_id IN (15, 16, 17) AND bank_id = bankID ORDER BY company_date_create LIMIT 1;
          IF firstDate IS NULL
            THEN SET firstDate = DATE(NOW());
          END IF;
          SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.api.dateStart", DATE(firstDate), "$.distribution.api.dateEnd", DATE(NOW()));
        END;
        WHEN 5 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.api.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 DAY)), "$.distribution.api.dateEnd", DATE(SUBDATE(NOW(), INTERVAL 1 DAY)));
        WHEN 6 THEN BEGIN
        END;
        ELSE SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.api.dateStart", DATE(NOW()), "$.distribution.api.dateEnd", DATE(NOW()));
      END CASE;
      SET type = JSON_EXTRACT(NEW.state_json, "$.distribution.notDial.type");
      CASE type
        WHEN 0 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.notDial.dateStart", DATE(NOW()), "$.distribution.notDial.dateEnd", DATE(NOW()));
        WHEN 1 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.notDial.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 WEEK)), "$.distribution.notDial.dateEnd", DATE(NOW()));
        WHEN 2 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.notDial.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 MONTH)), "$.distribution.notDial.dateEnd", DATE(NOW()));
        WHEN 3 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.notDial.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 YEAR)), "$.distribution.notDial.dateEnd", DATE(NOW()));
        WHEN 4 THEN BEGIN 
          SELECT company_date_create INTO firstDate FROM companies WHERE type_id = 36 AND bank_id = bankID ORDER BY company_date_create LIMIT 1;
          IF firstDate IS NULL
            THEN SET firstDate = DATE(NOW());
          END IF;
          SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.notDial.dateStart", DATE(firstDate), "$.distribution.notDial.dateEnd", DATE(NOW()));
        END;
        WHEN 5 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.notDial.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 DAY)), "$.distribution.notDial.dateEnd", DATE(SUBDATE(NOW(), INTERVAL 1 DAY)));
        WHEN 6 THEN BEGIN
        END;
        ELSE SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.notDial.dateStart", DATE(NOW()), "$.distribution.notDial.dateEnd", DATE(NOW()));
      END CASE;
      SET type = JSON_EXTRACT(NEW.state_json, "$.distribution.difficult.type");
      CASE type
        WHEN 0 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.difficult.dateStart", DATE(NOW()), "$.distribution.difficult.dateEnd", DATE(NOW()));
        WHEN 1 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.difficult.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 WEEK)), "$.distribution.difficult.dateEnd", DATE(NOW()));
        WHEN 2 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.difficult.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 MONTH)), "$.distribution.difficult.dateEnd", DATE(NOW()));
        WHEN 3 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.difficult.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 YEAR)), "$.distribution.difficult.dateEnd", DATE(NOW()));
        WHEN 4 THEN BEGIN 
          SELECT company_date_create INTO firstDate FROM companies WHERE type_id = 37 AND bank_id = bankID ORDER BY company_date_create LIMIT 1;
          IF firstDate IS NULL
            THEN SET firstDate = DATE(NOW());
          END IF;
          SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.difficult.dateStart", DATE(firstDate), "$.distribution.difficult.dateEnd", DATE(NOW()));
        END;
        WHEN 5 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.difficult.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 DAY)), "$.distribution.difficult.dateEnd", DATE(SUBDATE(NOW(), INTERVAL 1 DAY)));
        WHEN 6 THEN BEGIN
        END;
        ELSE SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.difficult.dateStart", DATE(NOW()), "$.distribution.difficult.dateEnd", DATE(NOW()));
      END CASE;
    END;
  END IF;
END
$$
DELIMITER ;
CREATE TABLE `statistic_view` (
`bank_id` int(11)
,`date` date
,`time` time(6)
,`type_id` int(11)
);

CREATE TABLE `templates` (
  `template_id` int(11) NOT NULL,
  `type_id` int(11) DEFAULT NULL,
  `template_columns_count` int(11) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
CREATE TABLE `templates_view` (
`template_id` int(11)
,`type_id` int(11)
,`template_columns_count` int(11)
,`type_name` varchar(128)
);

CREATE TABLE `template_columns` (
  `template_column_id` int(11) NOT NULL,
  `template_id` int(11) NOT NULL,
  `template_column_letters` varchar(3) COLLATE utf8_bin NOT NULL,
  `template_column_name` varchar(128) COLLATE utf8_bin NOT NULL,
  `column_id` int(11) DEFAULT NULL,
  `template_column_duplicate` tinyint(1) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
DELIMITER $$
CREATE TRIGGER `template_column_before_insert` BEFORE INSERT ON `template_columns` FOR EACH ROW BEGIN
  IF (SELECT COUNT(*) FROM template_columns WHERE column_id = NEW.column_id AND template_id = NEW.template_id) > 0
      THEN SET NEW.template_column_duplicate = 1;
    END IF;
END
$$
DELIMITER ;
CREATE TABLE `template_columns_view` (
`template_id` int(11)
,`template_column_id` int(11)
,`column_id` int(11)
,`column_name` varchar(128)
,`column_price` int(11)
,`column_blocked` tinyint(1)
,`template_column_letters` varchar(3)
,`template_column_name` varchar(128)
,`type_id` int(11)
,`type_name` varchar(128)
,`template_column_duplicate` tinyint(1)
);

CREATE TABLE `times` (
  `time_id` int(11) NOT NULL,
  `time_value` varchar(5) COLLATE utf8_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

CREATE TABLE `transactions` (
  `transaction_id` int(11) NOT NULL,
  `type_id` int(11) DEFAULT NULL,
  `transaction_value` int(11) NOT NULL,
  `transaction_date_create` varchar(19) COLLATE utf8_bin NOT NULL,
  `transaction_date_update` varchar(19) COLLATE utf8_bin DEFAULT NULL,
  `transaction_date_end` varchar(19) COLLATE utf8_bin DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `transaction_end` tinyint(4) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
DELIMITER $$
CREATE TRIGGER `transactions_before_insert` BEFORE INSERT ON `transactions` FOR EACH ROW BEGIN
  SET NEW.transaction_date_create = NOW();
    IF NEW.transaction_end
      THEN BEGIN 
          SET NEW.transaction_date_end = NOW();
            UPDATE purchases SET purchase_date_buy = NOW() WHERE transaction_id = NEW.transaction_id;
        END;
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `transactions_before_update` BEFORE UPDATE ON `transactions` FOR EACH ROW BEGIN
  SET NEW.transaction_date_update = NOW();
    IF NEW.transaction_end
      THEN BEGIN 
          SET NEW.transaction_date_end = NOW();
            UPDATE purchases SET purchase_date_buy = NOW() WHERE transaction_id = NEW.transaction_id;
        END;
    END IF;
END
$$
DELIMITER ;

CREATE TABLE `translates` (
  `translate_id` int(11) NOT NULL,
  `translate_from` varchar(128) COLLATE utf8_bin NOT NULL,
  `translate_to` varchar(128) COLLATE utf8_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

CREATE TABLE `types` (
  `type_id` int(11) NOT NULL,
  `type_name` varchar(128) COLLATE utf8_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

INSERT INTO `types` (`type_id`, `type_name`) VALUES
(30, 'api_accepted'),
(31, 'api_bank_rejection'),
(32, 'api_client_refusal'),
(25, 'api_doc_upload'),
(24, 'api_double'),
(17, 'api_error'),
(28, 'api_meeting_scheduled'),
(27, 'api_meeting_waiting'),
(29, 'api_postprocessing'),
(15, 'api_process'),
(26, 'api_processing'),
(16, 'api_success'),
(19, 'bank_supervisor'),
(18, 'bank_user'),
(23, 'call_back'),
(39, 'call_during'),
(41, 'call_end_client'),
(40, 'call_end_sip'),
(42, 'call_error'),
(45, 'call_record_file'),
(43, 'call_success'),
(38, 'call_to_client'),
(34, 'call_to_sip'),
(33, 'call_waiting'),
(44, 'check_inn'),
(7, 'deposit'),
(37, 'difficult'),
(21, 'file_created'),
(22, 'file_process'),
(20, 'file_reservation'),
(10, 'free'),
(4, 'get'),
(14, 'invalidate'),
(36, 'not_dial_all'),
(35, 'not_dial_user'),
(5, 'post'),
(6, 'purchase'),
(9, 'reservation'),
(1, 'root'),
(8, 'sale'),
(2, 'user'),
(13, 'validate'),
(3, 'ws'),
(11, 'ИП'),
(12, 'ООО');

CREATE TABLE `users` (
  `user_id` int(11) NOT NULL,
  `user_name` varchar(64) COLLATE utf8_bin NOT NULL,
  `user_email` varchar(512) COLLATE utf8_bin NOT NULL,
  `user_password` varchar(128) COLLATE utf8_bin NOT NULL,
  `user_date_create` varchar(19) COLLATE utf8_bin NOT NULL,
  `user_date_update` varchar(19) COLLATE utf8_bin DEFAULT NULL,
  `user_creator_id` int(11) DEFAULT NULL,
  `type_id` int(11) DEFAULT NULL,
  `user_auth` tinyint(1) NOT NULL DEFAULT '0',
  `user_online` tinyint(1) NOT NULL DEFAULT '0',
  `user_hash` varchar(32) COLLATE utf8_bin DEFAULT NULL,
  `user_connections_count` int(11) NOT NULL DEFAULT '0',
  `bank_id` int(11) DEFAULT NULL,
  `user_sip` varchar(20) COLLATE utf8_bin DEFAULT NULL,
  `user_ringing` tinyint(1) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
DELIMITER $$
CREATE TRIGGER `users_before_insert` BEFORE INSERT ON `users` FOR EACH ROW BEGIN
  SET NEW.user_date_create = NOW();
  IF NEW.user_auth
    THEN BEGIN
      hashLoop: LOOP
        SET NEW.user_hash = getHash(32);
          IF (SELECT COUNT(*) FROM users WHERE user_hash = NEW.user_hash) > 0
            THEN ITERATE hashLoop;
              ELSE LEAVE hashLoop;
          END IF;
      END LOOP;
    END;
  END IF;
  IF NEW.user_connections_count > 0
    THEN SET NEW.user_online = 1;
    ELSE SET NEW.user_online = 0;
  END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `users_before_update` BEFORE UPDATE ON `users` FOR EACH ROW BEGIN
  SET NEW.user_date_update = NOW();
  IF NEW.user_auth = 1 AND OLD.user_auth = 0
    THEN BEGIN
      hashLoop: LOOP
        SET NEW.user_hash = getHash(32);
          IF (SELECT COUNT(*) FROM users WHERE user_hash = NEW.user_hash) > 0
            THEN ITERATE hashLoop;
              ELSE LEAVE hashLoop;
          END IF;
      END LOOP;
    END;
  END IF;
  IF NEW.user_connections_count > 0
    THEN SET NEW.user_online = 1;
    ELSE SET NEW.user_online = 0;
  END IF;
  IF (NEW.user_auth = 0 AND OLD.user_auth = 1) OR (NEW.user_online = 0 AND OLD.user_online = 1)
    THEN BEGIN 
      IF NEW.type_id = 1
        THEN UPDATE companies SET user_id = NULL, type_id = 10 WHERE user_id = NEW.user_id AND type_id = 20;
      END IF;
    END;
  END IF;
END
$$
DELIMITER ;
CREATE TABLE `users_connections_view` (
`connection_id` int(11)
,`connection_hash` varchar(32)
,`connection_end` tinyint(1)
,`connection_api_id` varchar(128)
,`connection_type_id` int(11)
,`connection_type_name` varchar(128)
,`user_id` int(11)
,`type_id` int(11)
,`type_name` varchar(128)
,`user_auth` tinyint(1)
,`user_online` tinyint(1)
,`user_email` varchar(512)
,`bank_id` int(11)
,`user_sip` varchar(20)
);
DROP TABLE IF EXISTS `active_calls_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `active_calls_view`  AS  select `c`.`call_id` AS `call_id`,`c`.`type_id` AS `type_id`,`u`.`user_sip` AS `user_sip`,substr(`co`.`company_phone`,2) AS `company_phone`,`u`.`user_id` AS `user_id`,`co`.`company_id` AS `company_id` from ((`calls` `c` join `users` `u` on((`u`.`user_id` = `c`.`user_id`))) join `companies` `co` on((`co`.`company_id` = `c`.`company_id`))) where (`c`.`type_id` not in (40,41,42)) ;
DROP TABLE IF EXISTS `bank_cities_time_priority_companies_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `bank_cities_time_priority_companies_view`  AS  select `b`.`time_id` AS `time_id`,`t`.`time_value` AS `time_value`,`b`.`priority` AS `priority`,`r`.`region_name` AS `region_name`,`ci`.`city_name` AS `city_name`,`c`.`company_id` AS `company_id`,`c`.`user_id` AS `user_id`,`c`.`company_date_create` AS `company_date_create`,`c`.`type_id` AS `type_id`,`c`.`old_type_id` AS `old_type_id`,`c`.`company_date_update` AS `company_date_update`,`c`.`company_discount` AS `company_discount`,`c`.`company_discount_percent` AS `company_discount_percent`,`c`.`company_ogrn` AS `company_ogrn`,`c`.`company_ogrn_date` AS `company_ogrn_date`,`c`.`company_person_name` AS `company_person_name`,`c`.`company_person_surname` AS `company_person_surname`,`c`.`company_person_patronymic` AS `company_person_patronymic`,`c`.`company_person_birthday` AS `company_person_birthday`,`c`.`company_person_birthplace` AS `company_person_birthplace`,`c`.`company_inn` AS `company_inn`,`c`.`company_address` AS `company_address`,`c`.`company_doc_number` AS `company_doc_number`,`c`.`company_doc_date` AS `company_doc_date`,`c`.`company_organization_name` AS `company_organization_name`,`c`.`company_organization_code` AS `company_organization_code`,`c`.`company_phone` AS `company_phone`,`c`.`company_email` AS `company_email`,`c`.`company_okved_code` AS `company_okved_code`,`c`.`company_okved_name` AS `company_okved_name`,`c`.`purchase_id` AS `purchase_id`,`c`.`template_id` AS `template_id`,`c`.`company_kpp` AS `company_kpp`,`c`.`company_index` AS `company_index`,`c`.`company_house` AS `company_house`,`c`.`company_region_type` AS `company_region_type`,`c`.`company_region_name` AS `company_region_name`,`c`.`company_area_type` AS `company_area_type`,`c`.`company_area_name` AS `company_area_name`,`c`.`company_locality_type` AS `company_locality_type`,`c`.`company_locality_name` AS `company_locality_name`,`c`.`company_street_type` AS `company_street_type`,`c`.`company_street_name` AS `company_street_name`,`c`.`company_innfl` AS `company_innfl`,`c`.`company_person_position_type` AS `company_person_position_type`,`c`.`company_person_position_name` AS `company_person_position_name`,`c`.`company_doc_name` AS `company_doc_name`,`c`.`company_doc_gifter` AS `company_doc_gifter`,`c`.`company_doc_code` AS `company_doc_code`,`c`.`company_doc_house` AS `company_doc_house`,`c`.`company_doc_flat` AS `company_doc_flat`,`c`.`company_doc_region_type` AS `company_doc_region_type`,`c`.`company_doc_region_name` AS `company_doc_region_name`,`c`.`company_doc_area_type` AS `company_doc_area_type`,`c`.`company_doc_area_name` AS `company_doc_area_name`,`c`.`company_doc_locality_type` AS `company_doc_locality_type`,`c`.`company_doc_locality_name` AS `company_doc_locality_name`,`c`.`company_doc_street_type` AS `company_doc_street_type`,`c`.`company_doc_street_name` AS `company_doc_street_name`,`c`.`city_id` AS `city_id`,`c`.`region_id` AS `region_id`,`c`.`bank_id` AS `bank_id`,`c`.`company_date_registration` AS `company_date_registration`,`c`.`company_person_sex` AS `company_person_sex`,`c`.`company_ip_type` AS `company_ip_type`,`c`.`company_json` AS `company_json` from ((((`bank_cities_time_priority` `b` join `companies` `c` on(((`c`.`city_id` = `b`.`city_id`) and (`c`.`bank_id` = `b`.`bank_id`) and (json_unquote(json_extract(`c`.`company_json`,'$.company_id')) = `c`.`company_id`)))) join `times` `t` on((`t`.`time_id` = `b`.`time_id`))) join `cities` `ci` on((`ci`.`city_id` = `b`.`city_id`))) join `regions` `r` on((`r`.`region_id` = `c`.`region_id`))) order by `b`.`time_id`,`b`.`priority` ;
DROP TABLE IF EXISTS `bank_times_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `bank_times_view`  AS  select distinct `b`.`time_id` AS `time_id`,`t`.`time_value` AS `time_value`,`b`.`bank_id` AS `bank_id` from (`bank_cities_time_priority` `b` join `times` `t` on((`t`.`time_id` = `b`.`time_id`))) order by cast(`t`.`time_value` as time(6)) ;
DROP TABLE IF EXISTS `calls_file_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `calls_file_view`  AS  select `c`.`call_id` AS `call_id`,`f`.`file_id` AS `file_id`,`f`.`file_name` AS `file_name` from (`calls` `c` join `files` `f` on((`f`.`file_id` = `c`.`file_id`))) where (`c`.`file_id` is not null) ;
DROP TABLE IF EXISTS `columns_translates_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `columns_translates_view`  AS  select `c`.`column_id` AS `column_id`,if((`t`.`translate_to` is not null),`t`.`translate_to`,`c`.`column_name`) AS `translate_to`,`c`.`column_name` AS `column_name` from (`columns` `c` left join `translates` `t` on((`t`.`translate_from` = `c`.`column_name`))) ;
DROP TABLE IF EXISTS `empty_companies_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `empty_companies_view`  AS  select `companies`.`company_id` AS `company_id`,`companies`.`company_date_create` AS `company_date_create` from `companies` where (isnull(`companies`.`company_ogrn`) and isnull(`companies`.`company_ogrn_date`) and isnull(`companies`.`company_person_name`) and isnull(`companies`.`company_person_surname`) and isnull(`companies`.`company_person_patronymic`) and isnull(`companies`.`company_person_birthday`) and isnull(`companies`.`company_person_birthplace`) and isnull(`companies`.`company_inn`) and isnull(`companies`.`company_address`) and isnull(`companies`.`company_doc_number`) and isnull(`companies`.`company_doc_date`) and isnull(`companies`.`company_organization_name`) and isnull(`companies`.`company_organization_code`) and isnull(`companies`.`company_phone`) and isnull(`companies`.`company_email`) and isnull(`companies`.`company_okved_code`) and isnull(`companies`.`company_okved_name`) and isnull(`companies`.`company_kpp`) and isnull(`companies`.`company_index`) and isnull(`companies`.`company_house`) and isnull(`companies`.`company_region_type`) and isnull(`companies`.`company_region_name`) and isnull(`companies`.`company_area_type`) and isnull(`companies`.`company_area_name`) and isnull(`companies`.`company_locality_type`) and isnull(`companies`.`company_locality_name`) and isnull(`companies`.`company_street_type`) and isnull(`companies`.`company_street_name`) and isnull(`companies`.`company_innfl`) and isnull(`companies`.`company_person_position_type`) and isnull(`companies`.`company_person_position_name`) and isnull(`companies`.`company_doc_name`) and isnull(`companies`.`company_doc_gifter`) and isnull(`companies`.`company_doc_code`) and isnull(`companies`.`company_doc_house`) and isnull(`companies`.`company_doc_flat`) and isnull(`companies`.`company_doc_region_type`) and isnull(`companies`.`company_doc_region_name`) and isnull(`companies`.`company_doc_area_type`) and isnull(`companies`.`company_doc_area_name`) and isnull(`companies`.`company_doc_locality_type`) and isnull(`companies`.`company_doc_locality_name`) and isnull(`companies`.`company_doc_street_type`) and isnull(`companies`.`company_doc_street_name`) and isnull(`companies`.`company_date_registration`) and isnull(`companies`.`company_person_sex`) and isnull(`companies`.`company_ip_type`)) ;
DROP TABLE IF EXISTS `end_calls_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `end_calls_view`  AS  select `c`.`call_id` AS `call_id`,`c`.`type_id` AS `type_id`,`u`.`user_sip` AS `user_sip`,replace(`co`.`company_phone`,'+','') AS `company_phone`,`u`.`user_id` AS `user_id`,`co`.`company_id` AS `company_id`,`c`.`file_id` AS `file_id` from ((`calls` `c` join `users` `u` on((`u`.`user_id` = `c`.`user_id`))) join `companies` `co` on((`co`.`company_id` = `c`.`company_id`))) where (`c`.`type_id` in (40,41)) ;
DROP TABLE IF EXISTS `statistic_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `statistic_view`  AS  select `companies`.`bank_id` AS `bank_id`,cast(`companies`.`company_date_update` as date) AS `date`,cast(`companies`.`company_date_update` as time(6)) AS `time`,`companies`.`type_id` AS `type_id` from `companies` group by `companies`.`bank_id`,`date`,`time`,`companies`.`type_id` order by `companies`.`bank_id`,`date`,`time`,`companies`.`type_id` ;
DROP TABLE IF EXISTS `templates_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `templates_view`  AS  select `tm`.`template_id` AS `template_id`,`tm`.`type_id` AS `type_id`,`tm`.`template_columns_count` AS `template_columns_count`,`tp`.`type_name` AS `type_name` from (`templates` `tm` join `types` `tp` on((`tp`.`type_id` = `tm`.`type_id`))) ;
DROP TABLE IF EXISTS `template_columns_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `template_columns_view`  AS  select `t`.`template_id` AS `template_id`,`tc`.`template_column_id` AS `template_column_id`,`c`.`column_id` AS `column_id`,`c`.`column_name` AS `column_name`,`c`.`column_price` AS `column_price`,`c`.`column_blocked` AS `column_blocked`,`tc`.`template_column_letters` AS `template_column_letters`,`tc`.`template_column_name` AS `template_column_name`,`ts`.`type_id` AS `type_id`,`ts`.`type_name` AS `type_name`,`tc`.`template_column_duplicate` AS `template_column_duplicate` from (((`template_columns` `tc` join `templates` `t` on((`t`.`template_id` = `tc`.`template_id`))) join `columns` `c` on((`c`.`column_id` = `tc`.`column_id`))) join `types` `ts` on((`ts`.`type_id` = `t`.`type_id`))) ;
DROP TABLE IF EXISTS `users_connections_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `users_connections_view`  AS  select `c`.`connection_id` AS `connection_id`,`c`.`connection_hash` AS `connection_hash`,`c`.`connection_end` AS `connection_end`,`c`.`connection_api_id` AS `connection_api_id`,`c`.`type_id` AS `connection_type_id`,`tt`.`type_name` AS `connection_type_name`,`u`.`user_id` AS `user_id`,`u`.`type_id` AS `type_id`,`t`.`type_name` AS `type_name`,`u`.`user_auth` AS `user_auth`,`u`.`user_online` AS `user_online`,`u`.`user_email` AS `user_email`,`u`.`bank_id` AS `bank_id`,`u`.`user_sip` AS `user_sip` from (((`connections` `c` left join `users` `u` on((`u`.`user_id` = `c`.`user_id`))) left join `types` `t` on((`t`.`type_id` = `u`.`type_id`))) left join `types` `tt` on((`tt`.`type_id` = `c`.`type_id`))) ;


ALTER TABLE `banks`
  ADD PRIMARY KEY (`bank_id`);

ALTER TABLE `bank_cities`
  ADD PRIMARY KEY (`bank_city_id`),
  ADD KEY `bank_id` (`bank_id`),
  ADD KEY `city_id` (`city_id`);

ALTER TABLE `bank_cities_time_priority`
  ADD PRIMARY KEY (`bank_city_time_priority_id`),
  ADD KEY `bank_id` (`bank_id`),
  ADD KEY `time_id` (`time_id`),
  ADD KEY `city_id` (`city_id`);

ALTER TABLE `calls`
  ADD PRIMARY KEY (`call_id`),
  ADD KEY `type_id` (`type_id`),
  ADD KEY `company_id` (`company_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `file_id` (`file_id`);

ALTER TABLE `cities`
  ADD PRIMARY KEY (`city_id`);

ALTER TABLE `codes`
  ADD PRIMARY KEY (`code_id`),
  ADD UNIQUE KEY `code_value` (`code_value`),
  ADD KEY `region_id` (`region_id`);

ALTER TABLE `columns`
  ADD PRIMARY KEY (`column_id`),
  ADD UNIQUE KEY `column_name` (`column_name`);

ALTER TABLE `companies`
  ADD PRIMARY KEY (`company_id`),
  ADD UNIQUE KEY `company_ogrn` (`company_ogrn`),
  ADD UNIQUE KEY `company_inn` (`company_inn`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `type_id` (`type_id`),
  ADD KEY `purchase_id` (`purchase_id`),
  ADD KEY `template_id` (`template_id`),
  ADD KEY `city_id` (`city_id`),
  ADD KEY `region_id` (`region_id`),
  ADD KEY `bank_id` (`bank_id`),
  ADD KEY `file_id` (`file_id`),
  ADD KEY `old_type_id` (`old_type_id`),
  ADD KEY `call_id` (`call_id`);

ALTER TABLE `connections`
  ADD PRIMARY KEY (`connection_id`),
  ADD UNIQUE KEY `connection_hash` (`connection_hash`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `type_id` (`type_id`);

ALTER TABLE `files`
  ADD PRIMARY KEY (`file_id`),
  ADD UNIQUE KEY `file_name` (`file_name`),
  ADD KEY `type_id` (`type_id`),
  ADD KEY `purchase_id` (`purchase_id`),
  ADD KEY `user_id` (`user_id`);

ALTER TABLE `fns_codes`
  ADD PRIMARY KEY (`fns_code_id`),
  ADD KEY `city_id` (`city_id`),
  ADD KEY `region_id` (`region_id`);

ALTER TABLE `purchases`
  ADD PRIMARY KEY (`purchase_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `transaction_id` (`transaction_id`);

ALTER TABLE `regions`
  ADD PRIMARY KEY (`region_id`),
  ADD UNIQUE KEY `region_name` (`region_name`);

ALTER TABLE `states`
  ADD PRIMARY KEY (`state_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `connection_id` (`connection_id`);

ALTER TABLE `templates`
  ADD PRIMARY KEY (`template_id`),
  ADD KEY `type_id` (`type_id`);

ALTER TABLE `template_columns`
  ADD PRIMARY KEY (`template_column_id`),
  ADD KEY `template_id` (`template_id`),
  ADD KEY `column_id` (`column_id`);

ALTER TABLE `times`
  ADD PRIMARY KEY (`time_id`);

ALTER TABLE `transactions`
  ADD PRIMARY KEY (`transaction_id`),
  ADD KEY `type_id` (`type_id`),
  ADD KEY `user_id` (`user_id`);

ALTER TABLE `translates`
  ADD PRIMARY KEY (`translate_id`);

ALTER TABLE `types`
  ADD PRIMARY KEY (`type_id`),
  ADD UNIQUE KEY `type_name` (`type_name`);

ALTER TABLE `users`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `user_email` (`user_email`),
  ADD UNIQUE KEY `user_hash` (`user_hash`),
  ADD KEY `user_creator_id` (`user_creator_id`),
  ADD KEY `type_id` (`type_id`),
  ADD KEY `bank_id` (`bank_id`);


ALTER TABLE `banks`
  MODIFY `bank_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `bank_cities`
  MODIFY `bank_city_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `bank_cities_time_priority`
  MODIFY `bank_city_time_priority_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `calls`
  MODIFY `call_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `cities`
  MODIFY `city_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `codes`
  MODIFY `code_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `columns`
  MODIFY `column_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `companies`
  MODIFY `company_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `connections`
  MODIFY `connection_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `files`
  MODIFY `file_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `fns_codes`
  MODIFY `fns_code_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `purchases`
  MODIFY `purchase_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `regions`
  MODIFY `region_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `states`
  MODIFY `state_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `templates`
  MODIFY `template_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `template_columns`
  MODIFY `template_column_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `times`
  MODIFY `time_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `transactions`
  MODIFY `transaction_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `translates`
  MODIFY `translate_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `types`
  MODIFY `type_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `users`
  MODIFY `user_id` int(11) NOT NULL AUTO_INCREMENT;


ALTER TABLE `bank_cities`
  ADD CONSTRAINT `bank_cities_ibfk_1` FOREIGN KEY (`bank_id`) REFERENCES `banks` (`bank_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `bank_cities_ibfk_2` FOREIGN KEY (`city_id`) REFERENCES `cities` (`city_id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `bank_cities_time_priority`
  ADD CONSTRAINT `bank_cities_time_priority_ibfk_1` FOREIGN KEY (`bank_id`) REFERENCES `banks` (`bank_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `bank_cities_time_priority_ibfk_2` FOREIGN KEY (`city_id`) REFERENCES `cities` (`city_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `bank_cities_time_priority_ibfk_3` FOREIGN KEY (`time_id`) REFERENCES `times` (`time_id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `calls`
  ADD CONSTRAINT `calls_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `calls_ibfk_2` FOREIGN KEY (`company_id`) REFERENCES `companies` (`company_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `calls_ibfk_3` FOREIGN KEY (`type_id`) REFERENCES `types` (`type_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `calls_ibfk_4` FOREIGN KEY (`file_id`) REFERENCES `files` (`file_id`) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE `codes`
  ADD CONSTRAINT `codes_ibfk_1` FOREIGN KEY (`region_id`) REFERENCES `regions` (`region_id`) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE `companies`
  ADD CONSTRAINT `companies_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `companies_ibfk_10` FOREIGN KEY (`call_id`) REFERENCES `calls` (`call_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `companies_ibfk_2` FOREIGN KEY (`type_id`) REFERENCES `types` (`type_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `companies_ibfk_3` FOREIGN KEY (`purchase_id`) REFERENCES `purchases` (`purchase_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `companies_ibfk_4` FOREIGN KEY (`template_id`) REFERENCES `templates` (`template_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `companies_ibfk_5` FOREIGN KEY (`city_id`) REFERENCES `cities` (`city_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `companies_ibfk_6` FOREIGN KEY (`region_id`) REFERENCES `regions` (`region_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `companies_ibfk_7` FOREIGN KEY (`bank_id`) REFERENCES `banks` (`bank_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `companies_ibfk_8` FOREIGN KEY (`file_id`) REFERENCES `files` (`file_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `companies_ibfk_9` FOREIGN KEY (`old_type_id`) REFERENCES `types` (`type_id`) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE `connections`
  ADD CONSTRAINT `connections_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `connections_ibfk_2` FOREIGN KEY (`type_id`) REFERENCES `types` (`type_id`) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE `files`
  ADD CONSTRAINT `files_ibfk_1` FOREIGN KEY (`type_id`) REFERENCES `types` (`type_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `files_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `files_ibfk_3` FOREIGN KEY (`purchase_id`) REFERENCES `purchases` (`purchase_id`) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE `fns_codes`
  ADD CONSTRAINT `fns_codes_ibfk_1` FOREIGN KEY (`city_id`) REFERENCES `cities` (`city_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fns_codes_ibfk_2` FOREIGN KEY (`region_id`) REFERENCES `regions` (`region_id`) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE `purchases`
  ADD CONSTRAINT `purchases_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `purchases_ibfk_2` FOREIGN KEY (`transaction_id`) REFERENCES `transactions` (`transaction_id`) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE `states`
  ADD CONSTRAINT `states_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `states_ibfk_2` FOREIGN KEY (`connection_id`) REFERENCES `connections` (`connection_id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `templates`
  ADD CONSTRAINT `templates_ibfk_1` FOREIGN KEY (`type_id`) REFERENCES `types` (`type_id`) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE `template_columns`
  ADD CONSTRAINT `template_columns_ibfk_1` FOREIGN KEY (`template_id`) REFERENCES `templates` (`template_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `template_columns_ibfk_2` FOREIGN KEY (`column_id`) REFERENCES `columns` (`column_id`) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE `transactions`
  ADD CONSTRAINT `transactions_ibfk_1` FOREIGN KEY (`type_id`) REFERENCES `types` (`type_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `transactions_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE `users`
  ADD CONSTRAINT `users_ibfk_1` FOREIGN KEY (`user_creator_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `users_ibfk_2` FOREIGN KEY (`type_id`) REFERENCES `types` (`type_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `users_ibfk_3` FOREIGN KEY (`bank_id`) REFERENCES `banks` (`bank_id`) ON DELETE SET NULL ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
