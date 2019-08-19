SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;


DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `checkBanksStatuses` (IN `banksArray` JSON, IN `statusesArray` JSON)  NO SQL
BEGIN
    DECLARE statusExist TINYINT(1);
    DECLARE statusText VARCHAR(256);
    DECLARE bankID, statusesLength, banksLength, statusesIterator, banksIterator INT(11);
    SET banksLength = JSON_LENGTH(banksArray),
            statusesLength = JSON_LENGTH(statusesArray);
    IF statusesLength > 0 AND banksLength > 0
        THEN BEGIN
            SET statusesIterator = 0;
            statusesLoop: LOOP
                IF statusesIterator >= statusesLength
                    THEN LEAVE statusesLoop;
                END IF;
                SET banksIterator = 0;
                SET statusText = JSON_UNQUOTE(JSON_EXTRACT(statusesArray, CONCAT("$[", statusesIterator, "]")));
                banksLoop: LOOP
                    IF banksIterator >= banksLength
                        THEN LEAVE banksLoop;
                    END IF;
                    SET bankID = JSON_UNQUOTE(JSON_EXTRACT(banksArray, CONCAT("$[", banksIterator, "]")));
                    SET statusExist = 0;
                    SELECT 1 INTO statusExist FROM bank_statuses WHERE bank_id = bankID AND bank_status_text = statusText;
                    IF statusExist = 0
                        THEN INSERT INTO bank_statuses (bank_id, bank_status_text) VALUES (bankID, statusText);
                    END IF;
                    SET banksIterator = banksIterator + 1;
                    ITERATE banksLoop;
                END LOOP;
                SET statusesIterator = statusesIterator + 1;
                ITERATE statusesLoop;
            END LOOP;
        END;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `createStatisticFile` (IN `connectionHash` VARCHAR(32) CHARSET utf8, OUT `responce` JSON)  NO SQL
BEGIN
    DECLARE connectionID, fileID, userID INT(11);
    DECLARE connectionApiID VARCHAR(128);
    DECLARE dateStart, dateEnd VARCHAR(10);
    DECLARE state, types, company, companies, statistic, users, banks, statuses JSON;
    DECLARE done TINYINT(1);
    DECLARE companiesCursor CURSOR FOR SELECT company_json FROM custom_statistic_file_view;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    SET responce = JSON_ARRAY();
    SET companies = JSON_ARRAY(JSON_ARRAY(
        "Название компании",
        "Ф.И.О",
        "Телефон",
        "ИНН",
        "Дата создания",
        "Дата обновления",
        "Статус"
    ));
    SELECT connection_id, connection_api_id INTO connectionID, connectionApiID FROM connections WHERE connection_hash = connectionHash;
    SELECT state_json ->> "$.statistic" INTO statistic FROM states WHERE connection_id = connectionID;
    SET users = JSON_UNQUOTE(JSON_EXTRACT(statistic, "$.users"));
    SET types = JSON_UNQUOTE(JSON_EXTRACT(statistic, "$.types"));
    SET banks = JSON_UNQUOTE(JSON_EXTRACT(statistic, "$.banks[*].bank_id"));
    SET statuses = JSON_UNQUOTE(JSON_EXTRACT(statistic, "$.bankStatuses"));
    SET dateStart = JSON_UNQUOTE(JSON_EXTRACT(statistic, "$.dateStart"));
    SET dateEnd = JSON_UNQUOTE(JSON_EXTRACT(statistic, "$.dateEnd"));
    SET @mysqlText = CONCAT("CREATE VIEW custom_statistic_file_view AS
        SELECT JSON_ARRAY(
            c.company_organization_name,
            RTRIM(LTRIM(CONCAT(
                IF(c.company_person_name IS NOT NULL, c.company_person_name, ''),
                IF(c.company_person_surname IS NOT NULL, CONCAT(' ', c.company_person_surname, ' '), ''),
                IF(c.company_person_patronymic IS NOT NULL, c.company_person_patronymic, '')
            ))),
            c.company_phone,
            c.company_inn,
            c.company_date_create,
            c.company_date_update,
            IF(tr.translate_to IS NOT NULL, tr.translate_to, t.type_name)
        ) company_json
        FROM
            companies c
            JOIN types t ON t.type_id = c.type_id
            LEFT JOIN translates tr ON tr.translate_from = t.type_name
        WHERE
            c.type_id != 10 AND
            DATE(c.company_date_update) BETWEEN DATE('", dateStart, "') AND DATE('", dateEnd, "')",
            IF(users IS NOT NULL AND JSON_LENGTH(users) > 0, CONCAT(" AND JSON_CONTAINS('",users,"', JSON_ARRAY(c.user_id))"), ""),
            IF(types IS NOT NULL AND JSON_LENGTH(types) > 0, CONCAT(" AND JSON_CONTAINS('",types,"', JSON_ARRAY(c.type_id))"), ""),
            IF(banks IS NOT NULL AND JSON_LENGTH(banks) > 0, CONCAT(" AND jsonContainsLeastOne('",banks,"', c.company_json ->> '$.company_banks.*.bank_id')"), ""),
            IF(statuses IS NOT NULL AND JSON_LENGTH(statuses) > 0, CONCAT(" AND jsonContainsLeastOne('",statuses,"', c.company_json ->> '$.company_banks.*.bank_status_id')"), "")
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
            SET companies = JSON_MERGE(companies, JSON_ARRAY(company));
            ITERATE companiesLoop;
        END LOOP;
    CLOSE companiesCursor;
    DROP VIEW IF EXISTS custom_statistic_file_view;
    IF JSON_LENGTH(companies) > 1
        THEN BEGIN
            SELECT user_id INTO userID FROM connections WHERE connection_hash = connectionHash;
            INSERT INTO files (type_id, user_id, file_statistic) VALUES (22, userID, 1);
            SELECT file_id INTO fileID FROM files ORDER BY file_id DESC LIMIT 1;
            SET responce = JSON_MERGE(responce, JSON_OBJECT(
                "type", "xlsxCreate",
                "data", JSON_OBJECT(
                    "name", DATE(NOW()),
                    "data", companies,
                    "fileID", fileID
                )
            ));
        END;
        ELSE SET responce = JSON_MERGE(responce, JSON_OBJECT(
            "type", "sendToSocket",
            "data", JSON_OBJECT(
                "socketID", connectionApiID,
                "data", JSON_ARRAY(JSON_OBJECT(
                    "type", "mergeDeep",
                    "data", JSON_OBJECT(
                        "message", "Нет компаний для формирования файла по текущим фильтрам"
                    )
                ))
            )
        ));
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getBanksForOldCompanies` ()  NO SQL
BEGIN
    DECLARE companyID, cityID, bankID INT(11);
    DECLARE bankName VARCHAR(128);
    DECLARE bankNames JSON;
    DECLARE done TINYINT(1);
    DECLARE companyBanksCursor CURSOR FOR SELECT DISTINCT bank_id FROM bank_cities WHERE city_id = @cityID;
    DECLARE companiesCursor CURSOR FOR SELECT company_id, city_id FROM companies WHERE company_json ->> "$.company_banks" is null AND city_id IS NOT NULL;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    SET bankNames = JSON_ARRAY();
    OPEN companiesCursor;
        companiesLoop: LOOP
            FETCH companiesCursor INTO companyID, cityID;
            IF done
                THEN LEAVE companiesLoop;
            END IF;
            SET @cityID = cityID;
            SET bankNames = JSON_ARRAY();
            OPEN companyBanksCursor;
                companyBanksLoop:LOOP
                    FETCH companyBanksCursor INTO bankID;
                    IF done
                        THEN BEGIN
                            SET done = 0;
                            LEAVE companyBanksLoop;
                        END;
                    END IF;
                    SELECT bank_name INTO bankName FROM banks WHERE bank_id = bankID;
                    INSERT INTO company_banks (company_id, bank_id) VALUES (companyID, bankID);
                    SET bankNames = JSON_MERGE(bankNames, JSON_ARRAY(bankName));
                    ITERATE companyBanksLoop;
                END LOOP;
            CLOSE companyBanksCursor;
            UPDATE companies SET company_json = JSON_SET(company_json, "$.company_banks", bankNames) WHERE company_id = companyID;
            ITERATE companiesLoop;
        END LOOP;
    CLOSE companiesCursor;
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
        "CREATE VIEW custom_download_view AS SELECT company_json FROM companies WHERE company_file_user = ",
        userID,
        " AND company_file_type = 20"
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
                "$.old_type_id",
                "$.company_id",
                "$.template_id",
                "$.company_comment",
                "$.company_date_call_back",
                "$.call_type",
                "$.call_destination_type_id",
                "$.call_internal_type_id",
                "$.file_name",
                "$.template_type_id",
                "$.company_banks"
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
            SELECT count(*) INTO companiesCount FROM companies WHERE company_file_user = userID AND company_file_type = 20;
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
    DECLARE columns, companiesKeys, company JSON;
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
                                SET company = JSON_EXTRACT(companies, CONCAT("$.r", iterator + 2));
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
                            UPDATE companies SET company_json = json_set(company_json, "$.company_id", company_id) WHERE company_json ->> "$.company_id" != company_id;
                            DELETE LOW_PRIORITY c FROM companies c, empty_companies_view ecv WHERE c.company_id = ecv.company_id;
                            DELETE LOW_PRIORITY FROM companies WHERE CHAR_LENGTH(company_phone) < 5 or company_phone IS NULL;
                            SELECT count(*) INTO insertCompaniesCount FROM companies WHERE company_id > insertCompaniesCount;
                            SET message = CONCAT(
                                "Добавленно ",
                                insertCompaniesCount,
                                " компаний из ",
                                companiesLength,
                                ". Удалено ",
                                companiesLength - insertCompaniesCount
                            );
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
            "message", message,
            "telegram", 1
        )
    ));
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `reserveCompanies` (IN `connectionHash` VARCHAR(32) CHARSET utf8, OUT `responce` JSON)  NO SQL
BEGIN
    DECLARE typesLength, regionsLength, nullColumnsLength, notNullColumnsLength, ordersLength, columnID, regionID, limitOption, offsetOption, iterator, companyID, banksLength, banksWithoutNullLength, userID INT(11);
    DECLARE columnName, connectionApiID VARCHAR(128);
    DECLARE regionName VARCHAR(60);
    DECLARE types, regions, nullColumns, notNullColumns, company, companies, allColumns, allRegions, orders, orderObject, companiesID, banks, banksWithoutNull JSON;
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
            UPDATE companies SET type_id = IF(type_id = 20, 10, type_id), user_id = IF(type_id = 20, NULL, user_id), company_file_user = NULL, company_file_type = NULL WHERE company_file_user = userID AND company_file_type = 20;
            SELECT
                state_json ->> "$.download.types",
                state_json ->> "$.download.dateStart",
                state_json ->> "$.download.dateEnd",
                state_json ->> "$.download.regions",
                state_json ->> "$.download.nullColumns",
                state_json ->> "$.download.notNullColumns",
                state_json ->> "$.download.count",
                state_json ->> "$.download.banks"
            INTO
                types,
                dateStart,
                dateEnd,
                regions,
                nullColumns,
                notNullColumns,
                limitOption,
                banks
            FROM states WHERE user_id = userID ORDER BY state_id DESC LIMIT 1;
            SET banksWithoutNull = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(banks, "null", ""), " ", ""), ",,", ","), ",]", "]"), "[,", "["), "]", '"]'), "[", '["'), ",", '","'), '""', "");
            SET typesLength = JSON_LENGTH(types);
            SET regionsLength = JSON_LENGTH(regions);
            SET nullColumnsLength = JSON_LENGTH(nullColumns);
            SET notNullColumnsLength = JSON_LENGTH(notNullColumns);
            SET ordersLength = JSON_LENGTH(orders);
            SET banksLength = JSON_LENGTH(banks);
            SET banksWithoutNullLength = JSON_LENGTH(banksWithoutNull);
            SET @mysqlText = CONCAT(
                "UPDATE companies SET company_file_user = ", userID,", company_file_type = 20 WHERE DATE(company_date_create)",
                IF(dateStart = dateEnd, "=", " BETWEEN "),
                IF(dateStart = dateEnd, CONCAT("DATE('", dateStart, "')"), CONCAT("DATE('", dateStart, "') AND DATE('", dateEnd, "')")),
                IF(typesLength > 0, CONCAT(" AND JSON_CONTAINS('", types, "', JSON_ARRAY(type_id))"), ""),
                IF(regionsLength > 0, CONCAT(" AND JSON_CONTAINS('", regions, "', JSON_ARRAY(region_id))"), ""),
                IF(
                    banksLength > 0,
                    CONCAT(
                        " AND (",
                        IF(banksWithoutNullLength > 0, CONCAT("(JSON_LENGTH(company_json ->> '$.company_banks') > 0 AND jsonContainsLeastOne(company_json ->> '$.company_banks.*.bank_id', '", banksWithoutNull,"'))"), "0"),
                        IF(JSON_CONTAINS(banks, JSON_ARRAY(NULL)), " OR JSON_LENGTH(company_json ->> '$.company_banks') = 0)", ")")
                    ),
                    ""
                )
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateCompanyBanks` ()  NO SQL
BEGIN
  DECLARE cityID, bankID, companyBankID, companyID, typeID, bankStatusID, bankStatusTypeID INT(11);
  DECLARE requestID, applicationID, bankName, bankStatusText VARCHAR(128);
  DECLARE dateUpdate, bankStatusDateSend VARCHAR(19);
  DECLARE companyBanks JSON;
  DECLARE done TINYINT(1);
  DECLARE companiesCursor CURSOR FOR SELECT company_id, bank_id, company_api_request_id, company_application_id, type_id, city_id, company_date_update FROM companies;
  DECLARE banksCursor CURSOR FOR SELECT bc.bank_id, b.bank_name FROM bank_cities bc JOIN banks b ON b.bank_id = bc.bank_id WHERE IF(@cityID IS NOT NULL, bc.city_id = @cityID, bc.city_id IS NULL);
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
  OPEN companiesCursor;
    companiesLoop: LOOP
      SET done = 0;
      FETCH companiesCursor INTO companyID, companyBankID, requestID, applicationID, typeID, cityID, dateUpdate;
      IF done
        THEN LEAVE companiesLoop;
      END IF;
      SET @cityID = cityID;
      SET companyBanks = JSON_OBJECT();
      OPEN banksCursor;
        banksLoop: LOOP
          SET done = 0;
          FETCH banksCursor INTO bankID, bankName;
          IF done
            THEN LEAVE banksLoop;
          END IF;
          SET bankStatusText = NULL;
          SET bankStatusID = NULL;
          SET bankStatusDateSend = NULL;
          SET bankStatusTypeID = NULL;
          IF companyBankID = bankID
            THEN BEGIN
              CASE typeID
                WHEN 15 THEN SELECT bank_status_id, type_id INTO bankStatusID, bankStatusTypeID FROM bank_statuses WHERE bank_status_text = "Ожидание" AND bank_id = bankID;
                WHEN 16 THEN CASE bankID
                  WHEN 1 THEN SELECT bank_status_id, type_id INTO bankStatusID, bankStatusTypeID FROM bank_statuses WHERE bank_status_text = "CREATE_APPLICATION" AND bank_id = bankID;
                  WHEN 2 THEN SELECT bank_status_id, type_id INTO bankStatusID, bankStatusTypeID FROM bank_statuses WHERE bank_status_text = "CREATE_APPLICATION" AND bank_id = bankID;
                  WHEN 3 THEN SELECT bank_status_id, type_id INTO bankStatusID, bankStatusTypeID FROM bank_statuses WHERE bank_status_text = "ACCEPTED" AND bank_id = bankID;
                  WHEN 4 THEN SELECT bank_status_id, type_id INTO bankStatusID, bankStatusTypeID FROM bank_statuses WHERE bank_status_text = "1" AND bank_id = bankID;
                END CASE;
                WHEN 17 THEN SELECT bank_status_id, type_id INTO bankStatusID, bankStatusTypeID FROM bank_statuses WHERE bank_status_text = "Ошибка" AND bank_id = bankID;
                ELSE IF (typeID IN (25,26,27,28,29,30,31,32) AND bankID = 1) OR (typeID = 24 AND bankID IN (1,2))
                  THEN CASE typeID
                    WHEN 24 THEN SELECT bank_status_id, type_id INTO bankStatusID, bankStatusTypeID FROM bank_statuses WHERE bank_status_text = IF(bankID = 1, "APPLICATION_DOUBLE", "REJECT") AND bank_id = bankID;
                    WHEN 25 THEN SELECT bank_status_id, type_id INTO bankStatusID, bankStatusTypeID FROM bank_statuses WHERE bank_status_text = "DOC_UPLOAD" AND bank_id = bankID;
                    WHEN 26 THEN SELECT bank_status_id, type_id INTO bankStatusID, bankStatusTypeID FROM bank_statuses WHERE bank_status_text = "PROCESSING" AND bank_id = bankID;
                    WHEN 27 THEN SELECT bank_status_id, type_id INTO bankStatusID, bankStatusTypeID FROM bank_statuses WHERE bank_status_text = "MEETING_WAITING" AND bank_id = bankID;
                    WHEN 28 THEN SELECT bank_status_id, type_id INTO bankStatusID, bankStatusTypeID FROM bank_statuses WHERE bank_status_text = "MEETING_SCHEDULED" AND bank_id = bankID;
                    WHEN 29 THEN SELECT bank_status_id, type_id INTO bankStatusID, bankStatusTypeID FROM bank_statuses WHERE bank_status_text = "POSTPROCESSING" AND bank_id = bankID;
                    WHEN 30 THEN SELECT bank_status_id, type_id INTO bankStatusID, bankStatusTypeID FROM bank_statuses WHERE bank_status_text = "ACCEPTED" AND bank_id = bankID;
                    WHEN 31 THEN SELECT bank_status_id, type_id INTO bankStatusID, bankStatusTypeID FROM bank_statuses WHERE bank_status_text = "BANK_REJECTION" AND bank_id = bankID;
                    WHEN 32 THEN SELECT bank_status_id, type_id INTO bankStatusID, bankStatusTypeID FROM bank_statuses WHERE bank_status_text = "CLIENT_REFUSAL" AND bank_id = bankID;
                  END CASE;
                END IF;
              END CASE;
              IF typeID IN (15,16,17,24,25,26,27,28,29,30,31,32)
                THEN SET bankStatusDateSend = dateUpdate;
              END IF;
            END;
          END IF;
          IF bankStatusID IS NOT NULL
            THEN SELECT IF(tr.translate_to IS NOT NULL, tr.translate_to, bs.bank_status_text) INTO bankStatusText FROM bank_statuses bs LEFT JOIN translates tr ON tr.translate_from = bs.bank_status_text WHERE bs.bank_status_id = bankStatusID;
          END IF;
          INSERT INTO company_banks (company_id, bank_id, bank_status_id, company_bank_date_send, company_bank_application_id, company_bank_request_id) VALUES (companyID, bankID, bankStatusID, bankStatusDateSend, applicationID, requestID);
          SET companyBanks = JSON_SET(companyBanks, CONCAT("$.b", bankID), JSON_OBJECT(
            "bank_id", bankID,
            "bank_name", bankName,
            "bank_status_id", bankStatusID,
            "company_bank_status", bankStatusText,
            "type_id", bankStatusTypeID
          ));
          ITERATE banksLoop;
        END LOOP;
      CLOSE banksCursor;
      SET bankStatusText = NULL;
      SET bankStatusID = NULL;
      SET bankStatusTypeID = NULL;
      IF companyBankID IS NOT NULL AND !JSON_CONTAINS(JSON_UNQUOTE(JSON_EXTRACT(companyBanks, "$.*.bank_id")), JSON_ARRAY(companyBankID)) AND typeID IN (15,16,17,24,25,26,27,28,29,30,31,32)
        THEN BEGIN
          CASE typeID
            WHEN 15 THEN SELECT bank_status_id, type_id INTO bankStatusID, bankStatusTypeID FROM bank_statuses WHERE bank_status_text = "Ожидание" AND bank_id = companyBankID;
            WHEN 16 THEN CASE companyBankID
              WHEN 1 THEN SELECT bank_status_id, type_id INTO bankStatusID, bankStatusTypeID FROM bank_statuses WHERE bank_status_text = "CREATE_APPLICATION" AND bank_id = companyBankID;
              WHEN 2 THEN SELECT bank_status_id, type_id INTO bankStatusID, bankStatusTypeID FROM bank_statuses WHERE bank_status_text = "CREATE_APPLICATION" AND bank_id = companyBankID;
              WHEN 3 THEN SELECT bank_status_id, type_id INTO bankStatusID, bankStatusTypeID FROM bank_statuses WHERE bank_status_text = "ACCEPTED" AND bank_id = companyBankID;
              WHEN 4 THEN SELECT bank_status_id, type_id INTO bankStatusID, bankStatusTypeID FROM bank_statuses WHERE bank_status_text = "1" AND bank_id = companyBankID;
            END CASE;
            WHEN 17 THEN SELECT bank_status_id, type_id INTO bankStatusID, bankStatusTypeID FROM bank_statuses WHERE bank_status_text = "Ошибка" AND bank_id = companyBankID;
            ELSE IF (typeID IN (25,26,27,28,29,30,31,32) AND companyBankID = 1) OR (typeID = 24 AND companyBankID IN (1,2))
              THEN CASE typeID
                WHEN 24 THEN SELECT bank_status_id, type_id INTO bankStatusID, bankStatusTypeID FROM bank_statuses WHERE bank_status_text = IF(companyBankID = 1, "APPLICATION_DOUBLE", "REJECT") AND bank_id = companyBankID;
                WHEN 25 THEN SELECT bank_status_id, type_id INTO bankStatusID, bankStatusTypeID FROM bank_statuses WHERE bank_status_text = "DOC_UPLOAD" AND bank_id = companyBankID;
                WHEN 26 THEN SELECT bank_status_id, type_id INTO bankStatusID, bankStatusTypeID FROM bank_statuses WHERE bank_status_text = "PROCESSING" AND bank_id = companyBankID;
                WHEN 27 THEN SELECT bank_status_id, type_id INTO bankStatusID, bankStatusTypeID FROM bank_statuses WHERE bank_status_text = "MEETING_WAITING" AND bank_id = companyBankID;
                WHEN 28 THEN SELECT bank_status_id, type_id INTO bankStatusID, bankStatusTypeID FROM bank_statuses WHERE bank_status_text = "MEETING_SCHEDULED" AND bank_id = companyBankID;
                WHEN 29 THEN SELECT bank_status_id, type_id INTO bankStatusID, bankStatusTypeID FROM bank_statuses WHERE bank_status_text = "POSTPROCESSING" AND bank_id = companyBankID;
                WHEN 30 THEN SELECT bank_status_id, type_id INTO bankStatusID, bankStatusTypeID FROM bank_statuses WHERE bank_status_text = "ACCEPTED" AND bank_id = companyBankID;
                WHEN 31 THEN SELECT bank_status_id, type_id INTO bankStatusID, bankStatusTypeID FROM bank_statuses WHERE bank_status_text = "BANK_REJECTION" AND bank_id = companyBankID;
                WHEN 32 THEN SELECT bank_status_id, type_id INTO bankStatusID, bankStatusTypeID FROM bank_statuses WHERE bank_status_text = "CLIENT_REFUSAL" AND bank_id = companyBankID;
              END CASE;
            END IF;
          END CASE;
          IF bankStatusID IS NOT NULL
            THEN SELECT IF(tr.translate_to IS NOT NULL, tr.translate_to, bs.bank_status_text) INTO bankStatusText FROM bank_statuses bs LEFT JOIN translates tr ON tr.translate_from = bs.bank_status_text WHERE bs.bank_status_id = bankStatusID;
          END IF;
          SELECT bank_name INTO bankName FROM banks WHERE bank_id = companyBankID;
          SET companyBanks = JSON_SET(companyBanks, CONCAT("$.b", companyBankID), JSON_OBJECT(
            "bank_id", companyBankID,
            "bank_name", bankName,
            "bank_status_id", bankStatusID,
            "company_bank_status", bankStatusText,
            "type_id", bankStatusTypeID,
            "bank_suits", 0
          ));
        END;
      END IF;
      UPDATE companies SET company_json = JSON_SET(company_json, "$.company_banks", companyBanks) WHERE company_id = companyID;
      ITERATE companiesLoop;
    END LOOP;
  CLOSE companiesCursor;
  UPDATE companies SET type_id = 13 WHERE type_id in (15,16,17,24,25,26,27,28,29,30,31,32);
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `auth` (`connectionHash` VARCHAR(32) CHARSET utf8, `email` VARCHAR(512) CHARSET utf8, `pass` VARCHAR(128) CHARSET utf8) RETURNS JSON NO SQL
BEGIN
    DECLARE userHash VARCHAR(32);
    DECLARE connectionApiID VARCHAR(128);
    DECLARE userName VARCHAR(64);
    DECLARE userEmail VARCHAR(512);
    DECLARE userID, connectionID, activeCompaniesLength, typeID, bankID INT(11);
    DECLARE connectionEnd, ringing TINYINT(1);
    DECLARE responce, activeCompanies, downloadFilters, distributionFilters, statisticFilters, activeCompany JSON;
    SET responce = JSON_ARRAY();
    SET activeCompanies = JSON_ARRAY();
    SELECT user_id, type_id, user_name, user_email, bank_id INTO userID, typeID, userName, userEmail, bankID FROM users WHERE LOWER(user_email) = LOWER(email) AND user_password = pass;
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
                                    "userType", typeID,
                                    "userName", userName,
                                    "userEmail", userEmail
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
                    SET activeCompany = JSON_OBJECT();
                    SELECT company_json INTO activeCompany FROM working_user_company_view WHERE user_id = userID LIMIT 1;
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
                                        "activeCompany", activeCompany,
                                        "distribution", distributionFilters,
                                        "message", CONCAT("Загружено компаний: ", activeCompaniesLength),
                                        "ringing", ringing,
                                        "cities", getCities()
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
                    SELECT state_json ->> "$.statistic" INTO statisticFilters FROM states WHERE connection_id = connectionID;
                    SET statisticFilters = JSON_SET(statisticFilters, "$.users", getUsers(bankID));
                    SET responce = JSON_MERGE(responce, JSON_OBJECT(
                        "type", "sendToSocket",
                        "data", JSON_OBJECT(
                            "socketID", connectionApiID,
                            "data", JSON_ARRAY(JSON_OBJECT(
                                "type", "merge",
                                "data", JSON_OBJECT(
                                    "statistic", statisticFilters
                                )
                            ))
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
    DECLARE connectionID, userID, activeCompaniesLength, typeID, bankID INT(11);
    DECLARE connectionApiID VARCHAR(128);
    DECLARE userName VARCHAR(64);
    DECLARE userEmail VARCHAR(512);
    DECLARE userAuth, connectionEnd, ringing TINYINT(1);
    DECLARE responce, activeCompanies, activeCompany, downloadFilters, distributionFilters, statisticFilters JSON;
    SET responce = JSON_ARRAY();
    SELECT connection_id, connection_end, connection_api_id INTO connectionID, connectionEnd, connectionApiID FROM connections WHERE connection_hash = connectionHash;
    SELECT user_id, user_auth, type_id, user_name, user_email, bank_id INTO userID, userAuth, typeID, userName, userEmail, bankID FROM users WHERE user_hash = userHash;
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
                                "userType", typeID,
                                "userName", userName,
                                "userEmail", userEmail
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
                    SET activeCompany = JSON_OBJECT();
                    SELECT company_json INTO activeCompany FROM working_user_company_view WHERE user_id = userID LIMIT 1;
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
                                        "activeCompany", activeCompany,
                                        "distribution", distributionFilters,
                                        "message", CONCAT("Загружено компаний: ", activeCompaniesLength),
                                        "ringing", ringing,
                                        "cities", getCities()
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
                    SELECT state_json ->> "$.statistic" INTO statisticFilters FROM states WHERE connection_id = connectionID;
                    SET statisticFilters = JSON_SET(statisticFilters, "$.users", getUsers(bankID));
                    SET responce = JSON_MERGE(responce, JSON_OBJECT(
                        "type", "sendToSocket",
                        "data", JSON_OBJECT(
                            "socketID", connectionApiID,
                            "data", JSON_ARRAY(JSON_OBJECT(
                                "type", "merge",
                                "data", JSON_OBJECT(
                                    "statistic", statisticFilters
                                )
                            ))
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

CREATE DEFINER=`root`@`localhost` FUNCTION `callRequest` (`connectionHash` VARCHAR(32) CHARSET utf8, `companyID` INT(11), `predicted` BOOLEAN) RETURNS JSON NO SQL
BEGIN
  DECLARE userID, callID INT(11);
  DECLARE connectionValid TINYINT(1);
  DECLARE userSip VARCHAR(20);
  DECLARE connectionApiID VARCHAR(32);
  DECLARE companyPhone VARCHAR(120);
  DECLARE responce JSON;
  SET responce = JSON_ARRAY();
  SET connectionValid = checkConnection(connectionHash);
  IF connectionValid
    THEN BEGIN
      SELECT user_sip, user_id, connection_api_id INTO userSip, userID, connectionApiID FROM users_connections_view WHERE connection_hash = connectionHash;
      SELECT company_phone INTO companyPhone FROM companies WHERE company_id = companyID;
      INSERT INTO calls (user_id, company_id, call_internal_type_id, call_destination_type_id, call_predicted) VALUES (userID, companyID, 33, 33, IF(predicted IS NULL, 0, predicted));
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
            "predicted", predicted
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

CREATE DEFINER=`root`@`localhost` FUNCTION `confirmTelegram` (`chatID` VARCHAR(128) CHARSET utf8) RETURNS JSON NO SQL
BEGIN
    DECLARE responce JSON;
    DECLARE telegramID INT(11);
    SET responce = JSON_ARRAY();
    SELECT telegram_id INTO telegramID FROM telegrams WHERE telegram_chat_id = chatID;
    IF telegramID IS NOT NULL
        THEN SET responce = JSON_MERGE(responce, JSON_OBJECT(
            "type", "sendToTelegram",
            "data", JSON_OBJECT(
                "chats", JSON_ARRAY(chatID),
                "message", "Вы уже зарегестрированы в системе"
            )
        ));
        ELSE BEGIN
            INSERT INTO telegrams (telegram_chat_id) VALUES (chatID);
            SET responce = JSON_MERGE(responce, JSON_OBJECT(
                "type", "sendToTelegram",
                "data", JSON_OBJECT(
                    "chats", JSON_ARRAY(chatID),
                    "message", "Подписка на обновления установлена"
                )
            ));
        END;
    END IF;
    RETURN responce;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `createDownloadFile` (`connectionHash` VARCHAR(32) CHARSET utf8) RETURNS JSON NO SQL
BEGIN
    DECLARE connectionValid, done, translateDone TINYINT(1);
    DECLARE responce, companies, company, companyKeys, translateNames, companyArray JSON;
    DECLARE fileID, iterator, keysLength INT(11);
    DECLARE keyName, translateTo, connectionApiID VARCHAR(128);
    DECLARE userID INT(11) DEFAULT (SELECT user_id FROM connections WHERE connection_hash = connectionHash);
    DECLARE companiesCursor CURSOR FOR SELECT company_json FROM companies WHERE company_file_user = userID AND company_file_type = 20;
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
                        "$.type_id",
                        "$.call_destination_type_id",
                        "$.call_internal_type_id",
                        "$.company_banks",
                        "$.company_comment",
                        "$.file_name",
                        "$.template_type_id",
                        "$.company_date_call_back"
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
            UPDATE companies SET type_id = IF(type_id = 20, 22, type_id), file_id = fileID, company_file_type = 22 WHERE company_file_user = userID AND company_file_type = 20;
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

CREATE DEFINER=`root`@`localhost` FUNCTION `deleteCompany` (`connectionHash` VARCHAR(128) CHARSET utf8, `companyID` INT(11)) RETURNS JSON NO SQL
BEGIN
    DECLARE connectionApiID VARCHAR(128);
    DECLARE typeID, userID INT(11);
    DECLARE connectionValid TINYINT(1);
    DECLARE responce JSON;
    SET responce = JSON_ARRAY();
    SET connectionValid = checkConnection(connectionHash);
    SELECT connection_api_id, user_id INTO connectionApiID, userID FROM connections WHERE connection_hash = connectionHash;
    IF connectionValid
        THEN BEGIN
            SELECT type_id INTO typeID FROM companies WHERE company_id = companyID;
            DELETE FROM companies WHERE company_id = companyID;
            IF typeID = 36
                THEN SET responce = JSON_MERGE(responce, refreshUsersCompanies());
                ELSE BEGIN
                    SET responce = JSON_MERGE(responce, refreshUserCompanies(userID));
                    SET responce = JSON_MERGE(responce, sendToAllUserSockets(userID, JSON_ARRAY(JSON_OBJECT(
                        "type", "mergeDeep",
                        "data", JSON_OBJECT(
                            "message", "компания успешно удалена",
                            "messageType", "success"
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
  RETURN responce;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `editCompanyInformation` (`connectionHash` VARCHAR(32) CHARSET utf8, `companyID` INT(11), `phone` VARCHAR(12) CHARSET utf8, `cityID` INT(11)) RETURNS JSON NO SQL
BEGIN
    DECLARE userID, companyTypeID, oldCityID, bankID INT(11);
    DECLARE connectionValid, done TINYINT(1);
    DECLARE connectionApiID VARCHAR(32);
    DECLARE cityName VARCHAR(60);
    DECLARE bankName VARCHAR(128);
    DECLARE responce, companyBanks JSON;
    DECLARE banksCursor CURSOR FOR SELECT bank_id FROM bank_cities WHERE city_id = cityID;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    SET responce = JSON_ARRAY();
    SET connectionValid = checkConnection(connectionHash);
    IF connectionValid
        THEN BEGIN
            SELECT type_id, city_id INTO companyTypeID, oldCityID FROM companies WHERE company_id = companyID;
            SELECT user_id INTO userID FROM connections WHERE connection_hash = connectionHash;
            SELECT city_name INTO cityName FROM cities WHERE city_id = cityID;
            SET companyBanks = JSON_OBJECT();
            IF oldCityID != cityID
                THEN BEGIN
                    DELETE FROM company_banks WHERE company_id = companyID;
                    OPEN banksCursor;
                        banksLoop: LOOP
                            SET done = 0;
                            FETCH banksCursor INTO bankID;
                            IF done
                                THEN LEAVE banksLoop;
                            END IF;
                            INSERT INTO company_banks (company_id, bank_id) VALUES (companyID, bankID);
                            SELECT bank_name INTO bankName FROM banks WHERE bank_id = bankID;
                            SET companyBanks = JSON_SET(companyBanks, CONCAT("$.b", bankID), JSON_OBJECT("bank_id", bankID, "bank_name", bankName, "company_bank_status", NULL, "bank_status_id", NULL));
                            ITERATE banksLoop;
                        END LOOP;
                    CLOSE banksCursor;
                END;
            END IF;
            UPDATE companies SET company_phone = phone, city_id = cityID, company_json = JSON_SET(company_json, "$.company_phone", phone, "$.city_name", cityName, "$.city_id", cityID, "$.company_banks", companyBanks) WHERE company_id = companyID;
            SET responce = JSON_MERGE(responce, IF(companyTypeID = 36, refreshUsersCompanies(), refreshUserCompanies(userID)));
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
                @apiCount:=IF(type_id = 13, @apiCount+1, @apiCount) apiCount,
                @invalidateCount:=IF(type_id = 14, @invalidateCount+1, @invalidateCount) invalidateCount,
                @difficultCount:=IF(type_id = 37, @difficultCount+1, @difficultCount) difficultCount,
                @callbackCount:=IF(type_id = 23, @callbackCount+1, @callbackCount) callbackCount,
                @inworkCount:=IF(type_id IN (9, 35), @inworkCount+1, @inworkCount) inworkCount,
                @dialCount:=IF(type_id = 36, @dialCount+1, @dialCount) dialCount,
                @duplicatesCount:=IF(type_id = 24, @duplicatesCount+1, @duplicatesCount) duplicatesCount,
                type_id
            FROM
                companies
            WHERE
                (
                    (
                        (type_id = 13 AND DATE(company_date_create) BETWEEN DATE(@apiDateStart) AND DATE(@apiDateEnd)) OR
                        (type_id = 14 AND DATE(company_date_create) BETWEEN DATE(@invalidateDateStart) AND DATE(@invalidateDateEnd)) OR
                        (type_id = 37 AND DATE(company_date_create) BETWEEN DATE(@difficultDateStart) AND DATE(@difficultDateEnd)) OR
                        (type_id = 23 AND DATE(company_date_create) BETWEEN DATE(@callbackDateStart) AND DATE(@callbackDateEnd)) OR
                        (type_id = 24 AND DATE(company_date_create) BETWEEN DATE(@duplicatesDateStart) AND DATE(@duplicatesDateEnd)) OR
                        (type_id IN (9, 35))
                    ) AND user_id = userID
                ) OR
                (type_id = 36 AND DATE(company_date_create) BETWEEN DATE(@dialDateStart) AND DATE(@dialDateEnd))
            ORDER BY type_id ASC, company_date_registration DESC, company_date_create DESC
        ) c
        WHERE
            (apiCount BETWEEN @apiRowStart AND @apiRowLimit AND type_id = 13) OR
            (invalidateCount BETWEEN @invalidateRowStart AND @invalidateRowLimit AND type_id = 14) OR
            (difficultCount BETWEEN @difficultRowStart AND @difficultRowLimit AND type_id = 37) OR
            (callbackCount BETWEEN @callbackRowStart AND @callbackRowLimit AND type_id = 23) OR
            (inworkCount BETWEEN @inworkRowStart AND @inworkRowLimit AND type_id IN (9, 35)) OR
            (duplicatesCount BETWEEN @duplicatesRowStart AND @duplicatesRowLimit AND type_id = 24) OR
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
                    @duplicatesCount = 0,
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
                    @duplicatesRowStart = JSON_EXTRACT(distributionFilters, "$.duplicates.rowStart"),
                    @duplicatesRowLimit = JSON_EXTRACT(distributionFilters, "$.duplicates.rowLimit"),
                    @duplicatesDateStart = JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.duplicates.dateStart")),
                    @duplicatesDateEnd = JSON_UNQUOTE(JSON_EXTRACT(distributionFilters, "$.duplicates.dateEnd")),
                    @inworkRowStart = JSON_EXTRACT(distributionFilters, "$.work.rowStart"),
                    @inworkRowLimit = JSON_EXTRACT(distributionFilters, "$.work.rowLimit");
            SET @apiRowLimit = @apiRowLimit + @apiRowStart - 1,
                    @invalidateRowLimit = @invalidateRowLimit + @invalidateRowStart - 1,
                    @difficultRowLimit = @difficultRowLimit + @difficultRowStart - 1,
                    @callbackRowLimit = @callbackRowLimit + @callbackRowStart - 1,
                    @inworkRowLimit = @inworkRowLimit + @inworkRowStart - 1,
                    @dialRowLimit = @dialRowLimit + @dialRowStart - 1,
                    @duplicatesRowLimit = @duplicatesRowLimit + @duplicatesRowStart - 1;
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

CREATE DEFINER=`root`@`localhost` FUNCTION `getBankCityFilials` (`connectionHash` VARCHAR(32) CHARSET utf8, `bankID` INT, `cityID` INT) RETURNS JSON NO SQL
BEGIN
    DECLARE done, connectionValid TINYINT(1);
    DECLARE filialName VARCHAR(256);
    DECLARE connectionApiID VARCHAR(128);
    DECLARE bankFilialID INT(11);
    DECLARE responce, bankCityFilials JSON;
    DECLARE filialsCursor CURSOR FOR SELECT bank_filial_name, bank_filial_id FROM bank_filials WHERE bank_id = bankID AND city_id = cityID;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    SELECT connection_api_id INTO connectionApiID FROM connections WHERE connection_hash = connectionHash;
    SET connectionValid = checkConnection(connectionHash);
    SET responce = JSON_ARRAY();
    SET bankCityFilials = JSON_ARRAY();
    IF connectionValid
        THEN BEGIN
            OPEN filialsCursor;
                filialsLoop: LOOP
                    FETCH filialsCursor INTO filialName, bankFilialID;
                    IF done
                        THEN LEAVE filialsLoop;
                    END IF;
                    SET bankCityFilials = JSON_MERGE(bankCityFilials, JSON_OBJECT(
                        "bank_filial_name", filialName,
                        "bank_filial_id", bankFilialID
                    ));
                    ITERATE filialsLoop;
                END LOOP;
            CLOSE filialsCursor;
            SET responce = JSON_MERGE(responce, JSON_ARRAY(JSON_OBJECT(
                "type", "sendToSocket",
                "data", JSON_OBJECT(
                    "socketID", connectionApiID,
                    "data", JSON_ARRAY(JSON_OBJECT(
                        "type", "mergeDeep",
                        "data", JSON_OBJECT(
                            "banksFilials", JSON_OBJECT(
                                CONCAT("b", bankID), JSON_OBJECT(
                                    "bank_id", bankID,
                                    "bank_filials", bankCityFilials
                                )
                            )
                        )
                    ))
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

CREATE DEFINER=`root`@`localhost` FUNCTION `getBankCompanies` (`connectionHash` VARCHAR(32) CHARSET utf8, `rows` INT(11), `clearWorkList` BOOLEAN) RETURNS JSON NO SQL
BEGIN
    DECLARE companyID, companiesLength, connectionID, userID, timeID, companiesCount INT(11);
    DECLARE connectionValid TINYINT(1);
    DECLARE connectionApiID VARCHAR(128);
    DECLARE today, yesterday, hours, weekdaynow, friday VARCHAR(19);
    DECLARE responce, companiesArray JSON;
    SET connectionValid = checkConnection(connectionHash);
    SELECT connection_api_id, connection_id, user_id INTO connectionApiID, connectionID, userID FROM users_connections_view WHERE connection_hash = connectionHash;
    SET responce = JSON_ARRAY();
    IF connectionValid
        THEN BEGIN
            SET today = DATE(NOW());
            SET yesterday = SUBDATE(today, INTERVAL 1 DAY);
            SET hours = HOUR(NOW());
            SET friday = SUBDATE(today, INTERVAL 3 DAY);
            SET weekdaynow = WEEKDAY(today);
            IF clearWorkList
                THEN BEGIN
                    UPDATE companies SET user_id = NULL, type_id = 10 WHERE user_id = userID AND type_id IN (9, 35, 44);
                    SET responce = JSON_MERGE(responce, refreshUserCompanies(userID));
                    SET responce = JSON_MERGE(responce, JSON_MERGE(responce, sendToAllUserSockets(userID, JSON_ARRAY(
                        JSON_OBJECT(
                            "type", "merge",
                            "data", JSON_OBJECT(
                                "message", CONCAT("Рабочий список сброшен. На проверке ", rows, " компаний."),
                                "messageType", ""
                            )
                        )
                    ))));
                END;
            END IF;
            UPDATE
                companies c
                JOIN (
                    SELECT
                        company_id,
                        IF(type_id = 10 AND old_type_id = 36, 1, 2) type
                    FROM
                        regions_companies_view
                    WHERE
                        (
                            company_banks_length > 0 AND
                            (hours + region_msc_timezone) BETWEEN 10 AND 18
                        ) AND
                        (
                            (
                                IF(
                                    DATE(company_date_registration) IS NOT NULL,
                                    DATE(company_date_registration) IN (today, IF(weekdaynow = 0, friday, yesterday)),
                                    DATE(company_date_create) IN (today, IF(weekdaynow = 0, friday, yesterday))
                                ) AND
                                user_id IS NULL AND
                                type_id = 10 AND
                                (old_type_id IS NULL OR old_type_id != 36) AND
                                IF(
                                    DATE(company_date_registration) IS NOT NULL,
                                    IF(
                                        DATE(company_date_registration) = IF(weekdaynow = 0, friday, yesterday),
                                        IF(
                                            hours BETWEEN 9 AND 16,
                                            1,
                                            0
                                        ),
                                        1
                                    ),
                                    IF(
                                        DATE(company_date_create) = IF(weekdaynow = 0, friday, yesterday),
                                        IF(
                                            hours BETWEEN 9 AND 16,
                                            1,
                                            0
                                        ),
                                        1
                                    )
                                )
                            )
                            OR
                            (
                                type_id = 10 AND
                                old_type_id = 36 AND
                                date(company_date_update) = today
                            )
                        )
                    ORDER BY type ASC, date(company_date_registration) DESC, date(company_date_create) DESC, region_priority ASC, time(company_date_create) DESC LIMIT rows
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

CREATE DEFINER=`root`@`localhost` FUNCTION `getCities` () RETURNS JSON NO SQL
BEGIN
    DECLARE cityID, bankID INT(11);
    DECLARE done TINYINT(1);
    DECLARE cityName VARCHAR(60);
    DECLARE bankName VARCHAR(128);
    DECLARE responce, cityBanks, city JSON;
    DECLARE citiesCursor CURSOR FOR SELECT city_id, city_name FROM cities;
    DECLARE banksCursor CURSOR FOR SELECT DISTINCT bc.bank_id, b.bank_name FROM bank_cities bc JOIN banks b ON b.bank_id = bc.bank_id WHERE bc.city_id = @cityID;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    SET responce = JSON_ARRAY();
    OPEN citiesCursor;
        citiesLoop: LOOP
            SET done = 0;
            FETCH citiesCursor INTO cityID, cityName;
            IF done
                THEN LEAVE citiesLoop;
            END IF;
            SET @cityID = cityID;
            SET city = JSON_OBJECT(
                "city_id", cityID,
                "city_name", cityName
            );
            SET cityBanks = JSON_ARRAY();
            OPEN banksCursor;
                banksLoop: LOOP
                    SET done = 0;
                    FETCH banksCursor INTO bankID, bankName;
                    IF done
                        THEN LEAVE banksLoop;
                    END IF;
                    SET cityBanks = JSON_MERGE(cityBanks, JSON_OBJECT(
                        "bank_id", bankID,
                        "bank_name", bankName
                    ));
                    ITERATE banksLoop;
                END LOOP;
            CLOSE banksCursor;
            SET city = JSON_SET(city, "$.city_banks", cityBanks);
            SET responce = JSON_MERGE(responce, city);
            ITERATE citiesLoop;
        END LOOP;
    CLOSE citiesCursor;
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

CREATE DEFINER=`root`@`localhost` FUNCTION `getCompaniesToCheckStatus` (`connectionHash` VARCHAR(32) CHARSET utf8) RETURNS JSON NO SQL
BEGIN
  DECLARE done TINYINT(1);
  DECLARE responce, company JSON;
  DECLARE userID INT(11) DEFAULT (SELECT user_id FROM connections WHERE connection_hash = connectionHash);
  DECLARE companiesCursor CURSOR FOR SELECT JSON_OBJECT("companyID", company_id, "applicationID", company_application_id) FROM companies WHERE type_id in (16, 25, 26, 27, 28, 29) AND company_application_id IS NOT NULL AND IF(userID IS NOT NULL, user_id = userID, 1);
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

CREATE DEFINER=`root`@`localhost` FUNCTION `getDataStatistic` (`dateStart` VARCHAR(19) CHARSET utf8, `dateEnd` VARCHAR(19) CHARSET utf8, `banks` JSON, `free` TINYINT(1)) RETURNS JSON NO SQL
BEGIN
    DECLARE done TINYINT(1);
    DECLARE companiesCount INT(11);
    DECLARE templateName VARCHAR(128);
    DECLARE companiesDate VARCHAR(10);
    DECLARE companiesTime VARCHAR(5);
    DECLARE responce JSON;
    DECLARE companiesCursor CURSOR FOR SELECT
        COUNT(*),
        ty.type_name,
        DATE(c.company_date_create) company_date,
        CONCAT(HOUR(c.company_date_create), ":", MINUTE(c.company_date_create)) company_time
    FROM
        companies c
        JOIN templates t ON t.template_id = c.template_id
        JOIN types ty ON ty.type_id = t.type_id
    WHERE
        IF(banks IS NOT NULL AND JSON_LENGTH(banks) > 0, jsonContainsLeastOne(banks, c.company_json ->> "$.company_banks.*.bank_id"), JSON_LENGTH(c.company_json ->> "$.company_banks") = 0) AND
        IF(free, c.type_id = 10, 1) AND
        DATE(c.company_date_create) BETWEEN DATE(dateStart) AND DATE(dateEnd)
    GROUP BY
        company_date,
        company_time,
        ty.type_name
    ORDER BY
        company_date,
        HOUR(company_time),
        MINUTE(company_time),
        ty.type_name;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    SET responce = JSON_ARRAY();
    OPEN companiesCursor;
        companiesLoop: LOOP
            FETCH companiesCursor INTO companiesCount, templateName, companiesDate, companiesTime;
            IF done
                THEN LEAVE companiesLoop;
            END IF;
            SET responce = JSON_MERGE(responce, JSON_OBJECT(
                "template_name", templateName,
                "companies", companiesCount,
                "date", companiesDate,
                "time", companiesTime
            ));
            ITERATE companiesLoop;
        END LOOP;
    CLOSE companiesCursor;
    RETURN responce;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `getDayStatistic` () RETURNS JSON NO SQL
BEGIN
    DECLARE done TINYINT(1);
    DECLARE translateTo, searchResult, searchResult2, bankName VARCHAR(128);
    DECLARE userName VARCHAR(64);
    DECLARE userID, countLength, companyBanksLength, bankTypesLength, iterator, companyBankType, userObjectBanksTypeCount INT(11);
    DECLARE responce, userObject, typesArray, companyBanks, companyBank, userObjectBanks JSON;
    DECLARE companiesCursor CURSOR FOR SELECT translate_to, user_name, user_id, count FROM day_types_statistic_view;
    DECLARE statusesCursor CURSOR FOR SELECT user_id, bank_name, count FROM day_banks_statistic_view;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    SET responce = JSON_ARRAY();
    OPEN companiesCursor;
        companiesLoop: LOOP
            FETCH companiesCursor INTO translateTo, userName, userID, countLength;
            IF done
                THEN LEAVE companiesLoop;
            END IF;
            SET searchResult = REPLACE(JSON_UNQUOTE(JSON_SEARCH(responce, "one", CONCAT(userID), NULL, "$[*].user_id")), ".user_id", "");
            IF searchResult IS NULL
                THEN SET responce = JSON_MERGE(responce, JSON_OBJECT(
                    "user_id", CONCAT(userID),
                    "user_name", userName,
                    "types", JSON_ARRAY(JSON_OBJECT(
                        "type_name", translateTo,
                        "count", countLength
                    )),
                    "banks", JSON_ARRAY()
                ));
                ELSE BEGIN
                    SET userObject = JSON_UNQUOTE(JSON_EXTRACT(responce, searchResult));
                    SET typesArray = JSON_UNQUOTE(JSON_EXTRACT(userObject, "$.types"));
                    SET userObject = JSON_SET(userObject, "$.types", JSON_MERGE(typesArray, JSON_OBJECT(
                        "type_name", translateTo,
                        "count", countLength
                    )));
                    SET responce = JSON_SET(responce, searchResult, userObject);
                END;
            END IF;
            SET done = 0;
            ITERATE companiesLoop;
        END LOOP;
    CLOSE companiesCursor;
    SET done = 0;
    OPEN statusesCursor;
        statusesLoop: LOOP
            FETCH statusesCursor INTO userID, bankName, countLength;
            IF done
                THEN LEAVE statusesLoop;
            END IF;
            SET searchResult = REPLACE(JSON_UNQUOTE(JSON_SEARCH(responce, "one", CONCAT(userID), NULL, "$[*].user_id")), ".user_id", "");
            SET userObject = JSON_UNQUOTE(JSON_EXTRACT(responce, searchResult));
            SET userObjectBanks = JSON_UNQUOTE(JSON_EXTRACT(userObject, "$.banks"));
            SET userObjectBanks = JSON_MERGE(userObjectBanks, JSON_OBJECT(
                "bank_name", bankName,
                "count", countLength
            ));
            SET userObject = JSON_SET(userObject, "$.banks", userObjectBanks);
            SET responce = JSON_SET(responce, searchResult, userObject);
            ITERATE statusesLoop;
        END LOOP;
    CLOSE statusesCursor;
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

CREATE DEFINER=`root`@`localhost` FUNCTION `getUserStatistic` (`connectionHash` VARCHAR(32) CHARSET utf8, `statisticType` VARCHAR(128) CHARSET utf8) RETURNS JSON NO SQL
BEGIN
    DECLARE connectionID, bankID, userID, user, workingCompaniesLimit, workingCompaniesOffset INT(11);
    DECLARE connectionValid, free TINYINT(1);
    DECLARE connectionApiID VARCHAR(128);
    DECLARE dateStart, dateEnd, dataDateStart, dataDateEnd VARCHAR(19);
    DECLARE responce, state, statistic, types, banks, statuses, users, dataBanks JSON;
    SET responce = JSON_ARRAY();
    SET connectionValid = checkConnection(connectionHash);
    SELECT connection_api_id INTO connectionApiID FROM connections WHERE connection_hash = connectionHash;
    IF connectionValid
        THEN BEGIN
            SELECT connection_id, bank_id, user_id INTO connectionID, bankID, userID FROM users_connections_view WHERE connection_hash = connectionHash;
            SELECT state_json INTO state FROM states WHERE connection_id = connectionID;
            IF statisticType IN ("working", "data")
                THEN BEGIN
                    SET types = JSON_EXTRACT(state, "$.statistic.types");
                    SET banks = JSON_EXTRACT(state, "$.statistic.banks[*].bank_id");
                    SET statuses = JSON_EXTRACT(state, "$.statistic.bankStatuses");
                    SET users = JSON_EXTRACT(state, "$.statistic.selectedUsers");
                    SET dateStart = JSON_UNQUOTE(JSON_EXTRACT(state, "$.statistic.dateStart"));
                    SET dateEnd = JSON_UNQUOTE(JSON_EXTRACT(state, "$.statistic.dateEnd"));
                    SET dataDateStart = JSON_UNQUOTE(JSON_EXTRACT(state, "$.statistic.dataDateStart"));
                    SET dataDateEnd = JSON_UNQUOTE(JSON_EXTRACT(state, "$.statistic.dataDateEnd"));
                    SET dataBanks = JSON_EXTRACT(state, "$.statistic.dataBanks");
                    SET free = JSON_EXTRACT(state, "$.statistic.dataFree");
                    SET workingCompaniesLimit = JSON_EXTRACT(state, "$.statistic.workingCompaniesLimit");
                    SET workingCompaniesOffset = JSON_EXTRACT(state, "$.statistic.workingCompaniesOffset");
                    SET statistic = JSON_OBJECT(
                        "period", JSON_EXTRACT(state, "$.statistic.period"),
                        "dateStart", dateStart,
                        "dateEnd", dateEnd,
                        "user", user,
                        "dataFree", free,
                        "dataBanks", dataBanks,
                        "dataDateStart", dataDateStart,
                        "dataDateEnd", dataDateEnd,
                        "dataPeriod", JSON_EXTRACT(state, "$.statistic.dataPeriod"),
                        "users", getUsers(bankID),
                        "workingCompaniesLimit", workingCompaniesLimit,
                        "workingCompaniesOffset", workingCompaniesOffset
                    );
                    IF statisticType = "working"
                        THEN SET statistic = JSON_SET(statistic,
                            "$.working", getWorkingBankStatistic(dateStart, dateEnd, types, users, banks, statuses),
                            "$.workingCompanies", getWorkingStatisticCompanies(dateStart, dateEnd, types, users, banks, statuses, workingCompaniesLimit, workingCompaniesOffset)
                        );
                    END IF;
                    IF statisticType = "data"
                        THEN SET statistic = JSON_SET(statistic, "$.data", getDataStatistic(dataDateStart, dataDateEnd, dataBanks, free));
                    END IF;
                    SET responce = JSON_MERGE(responce, JSON_OBJECT(
                        "type", "sendToSocket",
                        "data", JSON_OBJECT(
                            "socketID", connectionApiID,
                            "data", JSON_ARRAY(JSON_OBJECT(
                                "type", "mergeDeep",
                                "data", JSON_OBJECT(
                                    "statistic", statistic
                                )
                            ))
                        )
                    ));
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

CREATE DEFINER=`root`@`localhost` FUNCTION `getWorkingBankStatistic` (`dateStart` VARCHAR(19) CHARSET utf8, `dateEnd` VARCHAR(19) CHARSET utf8, `companiesTypes` JSON, `users` JSON, `banks` JSON, `statuses` JSON) RETURNS JSON NO SQL
BEGIN
    DECLARE done TINYINT(1);
    DECLARE responce JSON;
    DECLARE companiesCount, iterator INT(11);
    DECLARE companiesHour VARCHAR(2);
    DECLARE companiesDate VARCHAR(10);
    DECLARE templateName VARCHAR(128);
    DECLARE companiesCursor CURSOR FOR SELECT
        COUNT(*),
        DATE(c.company_date_update) company_date,
        HOUR(c.company_date_update) company_hour,
        ty.type_name
    FROM
        companies c
        JOIN templates t ON t.template_id = c.template_id
        JOIN types ty ON ty.type_id = t.type_id
    WHERE
        c.type_id != 10 AND
        JSON_LENGTH(company_json ->> "$.company_banks") > 0 AND
        IF(companiesTypes IS NOT NULL AND JSON_LENGTH(companiesTypes) > 0, JSON_CONTAINS(companiesTypes, CONCAT(c.type_id)), 1) AND
        IF(users IS NOT NULL AND JSON_LENGTH(users) > 0, JSON_CONTAINS(users, JSON_ARRAY(c.user_id)), 1) AND
        IF(banks IS NOT NULL AND JSON_LENGTH(banks) > 0, jsonContainsLeastOne(JSON_EXTRACT(c.company_json, "$.company_banks.*.bank_id"), banks), 1) AND
        IF(statuses IS NOT NULL AND JSON_LENGTH(statuses) > 0, jsonContainsLeastOne(JSON_EXTRACT(c.company_json, "$.company_banks.*.bank_status_id"), statuses), 1) AND
        DATE(company_date_update) BETWEEN DATE(dateStart) AND DATE(dateEnd)
    GROUP BY
        company_date,
        company_hour,
        ty.type_name;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    SET responce = JSON_ARRAY();
    SET iterator = 0;
    OPEN companiesCursor;
        companiesLoop: LOOP
            FETCH companiesCursor INTO companiesCount, companiesDate, companiesHour, templateName;
            IF done
                THEN LEAVE companiesLoop;
            END IF;
            SET responce = JSON_MERGE(responce, JSON_OBJECT(
                "template_name", templateName,
                "companies", companiesCount,
                "date", companiesDate,
                "hour", companiesHour
            ));
            ITERATE companiesLoop;
        END LOOP;
    CLOSE companiesCursor;
    RETURN responce;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `getWorkingStatisticCompanies` (`dateStart` VARCHAR(19) CHARSET utf8, `dateEnd` VARCHAR(19) CHARSET utf8, `companiesTypes` JSON, `users` JSON, `banks` JSON, `statuses` JSON, `companiesLimit` INT(11), `companiesOffset` INT(11)) RETURNS JSON NO SQL
BEGIN
    DECLARE done TINYINT(1);
    DECLARE responce, company JSON;
    DECLARE companiesCursor CURSOR FOR SELECT
        company_json
    FROM
        working_statistic_companies_view
    WHERE
        type_id != 10 AND
        JSON_LENGTH(company_banks) > 0 AND
        IF(companiesTypes IS NOT NULL AND JSON_LENGTH(companiesTypes) > 0, JSON_CONTAINS(companiesTypes, CONCAT(type_id)), 1) AND
        IF(users IS NOT NULL AND JSON_LENGTH(users) > 0, JSON_CONTAINS(users, CONCAT(user_id)), 1) AND
        IF(banks IS NOT NULL AND JSON_ARRAY(banks) > 0, jsonContainsLeastOne(JSON_EXTRACT(company_banks, "$.*.bank_id"), banks), 1) AND
        IF(statuses IS NOT NULL AND JSON_LENGTH(statuses) > 0, jsonContainsLeastOne(JSON_EXTRACT(company_banks, "$.*.bank_status_id"), statuses), 1) AND
        DATE(company_date_update) BETWEEN DATE(dateStart) AND DATE(dateEnd)
    LIMIT
        companiesLimit
    OFFSET
        companiesOffset;
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

CREATE DEFINER=`root`@`localhost` FUNCTION `jsonContainsLeastOne` (`array1` JSON, `array2` JSON) RETURNS TINYINT(1) NO SQL
BEGIN
    DECLARE responce TINYINT(1);
    DECLARE iterator, array1Length, array2Length, minArrayLength, maxArrayLength INT(11);
    DECLARE minArray, maxArray JSON;
    IF JSON_CONTAINS(array1, array2) OR JSON_CONTAINS(array2, array1)
        THEN SET responce = 1;
        ELSE BEGIN
            SET array1Length = JSON_LENGTH(array1);
            SET array2Length = JSON_LENGTH(array2);
            IF array1Length = array2Length OR array1Length < array2Length
                THEN SET minArray = array1, maxArray = array2;
                ELSE SET minArray = array2, maxArray = array1;
            END IF;
            SET minArrayLength = JSON_LENGTH(minArray);
            SET maxArrayLength = JSON_LENGTH(maxArray);
            SET iterator = 0;
            maxArrayLoop: LOOP
                IF iterator >= maxArrayLength
                    THEN LEAVE maxArrayLoop;
                END IF;
                SET maxArray = JSON_SET(maxArray, CONCAT("$[", iterator, "]"), CONCAT(JSON_UNQUOTE(JSON_EXTRACT(maxArray, CONCAT("$[", iterator, "]")))));
                SET iterator = iterator + 1;
                ITERATE maxArrayLoop;
            END LOOP;
            SET iterator = 0;
            minArrayLoop: LOOP
                IF iterator >= minArrayLength OR responce
                    THEN LEAVE minArrayLoop;
                END IF;
                SET responce = JSON_CONTAINS(maxArray, JSON_ARRAY(CONCAT(JSON_UNQUOTE(JSON_EXTRACT(minArray, CONCAT("$[", iterator, "]"))))));
                SET iterator = iterator + 1;
                ITERATE minArrayLoop;
            END LOOP;
        END;
    END IF;
    RETURN responce;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `jsonMap` (`array` JSON, `keysArray` JSON) RETURNS JSON NO SQL
BEGIN
    DECLARE responce, arrayItem, customObject JSON;
    DECLARE arrayIterator, keysIterator, arrayLength, keysLength INT(11);
    DECLARE keyName TEXT;
    SET responce = JSON_ARRAY();
    SET arrayIterator = 0;
    SET arrayLength = JSON_LENGTH(array);
    SET keysLength = JSON_LENGTH(keysArray);
    arrayLoop: LOOP
        IF arrayIterator >= arrayLength
            THEN LEAVE arrayLoop;
        END IF;
        IF keysLength > 1
            THEN BEGIN
                SET arrayItem = JSON_UNQUOTE(JSON_EXTRACT(array, CONCAT("$[", arrayIterator, "]")));
                SET customObject = JSON_OBJECT();
                SET keysIterator = 0;
                keysLoop: LOOP
                    IF keysIterator >= keysLength
                        THEN LEAVE keysLoop;
                    END IF;
                    SET keyName = JSON_UNQUOTE(JSON_EXTRACT(keysArray, CONCAT("$[", keysIterator, "]")));
                    SET customObject = JSON_SET(customObject, CONCAT("$.", keyName), JSON_UNQUOTE(JSON_EXTRACT(arrayItem, CONCAT("$.", keyName))));
                    SET keysIterator = keysIterator + 1;
                    ITERATE keysLoop;
                END LOOP;
                SET responce = JSON_MERGE(responce, customObject);
            END;
            ELSE BEGIN
                SET keyName = JSON_UNQUOTE(JSON_EXTRACT(keysArray, "$[0]"));
                SET responce = JSON_MERGE(responce, JSON_ARRAY(JSON_UNQUOTE(JSON_EXTRACT(array, CONCAT("$[", arrayIterator, "].", keyName)))));
            END;
        END IF;
        SET arrayIterator = arrayIterator + 1;
        ITERATE arrayLoop;
    END LOOP;
    RETURN responce;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `jsonRemoveNulls` (`arr` JSON) RETURNS JSON NO SQL
BEGIN
    DECLARE arrLength, iterator INT(11);
    DECLARE responce JSON;
    SET arrLength = JSON_LENGTH(arr);
    SET responce = JSON_ARRAY();
    SET iterator = 0;
    arrLoop: LOOP
        IF iterator >= arrLength
            THEN LEAVE arrLoop;
        END IF;
        IF JSON_UNQUOTE(JSON_EXTRACT(arr, CONCAT("$[", iterator, "]"))) != "null"
            THEN SET responce = JSON_MERGE(responce, JSON_UNQUOTE(JSON_EXTRACT(arr, CONCAT("$[", iterator, "]"))));
        END IF;
        SET iterator = iterator + 1;
        ITERATE arrLoop;
    END LOOP;
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

CREATE DEFINER=`root`@`localhost` FUNCTION `nextCall` (`connectionHash` VARCHAR(32) CHARSET utf8) RETURNS JSON NO SQL
BEGIN
    DECLARE connectionApiID VARCHAR(120);
    DECLARE companyID, userID INT(11);
    DECLARE validConnection TINYINT(1);
    DECLARE userSip VARCHAR(20);
    DECLARE companyPhone VARCHAR(120);
    DECLARE responce JSON;
    SET responce = JSON_ARRAY();
    SET validConnection = checkConnection(connectionHash);
    SELECT user_id, connection_api_id INTO userID, connectionApiID FROM connections WHERE connection_hash = connectionHash;
    IF validConnection
        THEN BEGIN
            SELECT user_sip INTO userSip FROM users WHERE user_id = userID;
            SELECT company_json ->> "$.company_id" INTO companyID FROM working_user_company_view WHERE user_id = userID LIMIT 1;
            IF companyID IS NOT NULL
                THEN UPDATE companies SET company_ringing = 1 WHERE company_id = companyID;
            END IF;
            SELECT company_phone, company_id INTO companyPhone, companyID FROM companies WHERE user_id = userID AND type_id IN (9, 35) AND company_ringing = 0 ORDER BY type_id ASC, company_date_registration DESC, company_date_create DESC LIMIT 1;
            IF companyPhone IS NOT NULL
                THEN BEGIN
                    INSERT INTO calls (user_id, company_id, call_internal_type_id, call_destination_type_id, call_predicted) VALUES (userID, companyID, 33, 33, 1);
                    UPDATE users SET user_ringing = 1 WHERE user_id = userID;
                    SET responce = JSON_MERGE(responce, JSON_OBJECT(
                        "type", "sendToZadarma",
                        "data", JSON_OBJECT(
                            "options", JSON_OBJECT(
                                "from", userSip,
                                "to", companyPhone,
                                "predicted", 1
                            ),
                            "method", "request/callback",
                            "type", "GET"
                        )
                    ));
                    SET responce = JSON_MERGE(responce, refreshUserCompanies(userID));
                    SET responce = JSON_MERGE(responce, sendToAllUserSockets(userID, JSON_ARRAY(JSON_OBJECT(
                        "type", "mergeDeep",
                        "data", JSON_OBJECT(
                            "message", CONCAT("соединение с ", companyPhone, " имеет статус: ожидание ответа от АТС")
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

CREATE DEFINER=`root`@`localhost` FUNCTION `refreshBankSupervisors` (`bankID` INT(11)) RETURNS JSON NO SQL
BEGIN
    DECLARE userID INT(11);
    DECLARE connectionHash VARCHAR(32);
    DECLARE done TINYINT(1);
    DECLARE responce JSON;
    DECLARE usersCursor CURSOR FOR SELECT user_id, connection_hash FROM users_connections_view WHERE connection_end = 0 AND connection_type_id = 3 AND type_id IN (1, 19) AND bank_id = bankID;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    SET responce = JSON_ARRAY();
    OPEN usersCursor;
        usersLoop: LOOP
            FETCH usersCursor INTO userID, connectionHash;
            IF done
                THEN LEAVE usersLoop;
            END IF;
            SET responce = JSON_MERGE(responce, getBankStatistic(connectionHash));
            ITERATE usersLoop;
        END LOOP;
    CLOSE usersCursor;
    RETURN responce;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `refreshUserCompanies` (`userID` INT(11)) RETURNS JSON NO SQL
BEGIN
    DECLARE responce, activeCompany JSON;
    DECLARE connectionApiID VARCHAR(128);
    DECLARE connectionID INT(11);
    DECLARE done TINYINT(1);
    DECLARE connectionsCursor CURSOR FOR SELECT connection_id, connection_api_id FROM connections WHERE user_id = userID AND connection_end = 0;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    SET responce = JSON_ARRAY();
    SET activeCompany = JSON_OBJECT();
    SELECT company_json INTO activeCompany FROM working_user_company_view WHERE user_id = userID LIMIT 1;
    SET done = 0;
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
                                "companies", getActiveBankUserCompanies(connectionID),
                                "activeCompany", activeCompany
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

CREATE DEFINER=`root`@`localhost` FUNCTION `refreshUsersCompanies` () RETURNS JSON NO SQL
BEGIN
    DECLARE userID INT(11);
    DECLARE done TINYINT(1);
    DECLARE responce JSON;
    DECLARE usersCursor CURSOR FOR SELECT user_id FROM users_connections_view WHERE connection_end = 0 AND type_id IN (1, 18);
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

CREATE DEFINER=`root`@`localhost` FUNCTION `resetCall` (`connectionHash` VARCHAR(32) CHARSET utf8, `companyID` INT(11)) RETURNS JSON NO SQL
BEGIN
    DECLARE connectionValid TINYINT(1);
    DECLARE callID, userID, typeID INT(11);
    DECLARE responce JSON;
    SET responce = JSON_ARRAY();
    SET connectionValid = checkConnection(connectionHash);
    IF connectionValid
        THEN BEGIN
            SELECT call_id, user_id, type_id INTO callID, userID, typeID FROM companies WHERE company_id = companyID;
            IF callID IS NOT NULL
                THEN BEGIN
                    UPDATE calls SET call_destination_type_id = 42, call_internal_type_id = 42 WHERE call_id = callID;
                    IF typeID = 36
                        THEN SET responce = JSON_MERGE(responce, refreshUsersCompanies());
                        ELSE SET responce = JSON_MERGE(responce, refreshUserCompanies(userID));
                    END IF;
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

CREATE DEFINER=`root`@`localhost` FUNCTION `resetCalls` () RETURNS JSON NO SQL
BEGIN
  DECLARE responce, usersArray JSON;
  DECLARE callsCountBefore, callsCountAfter, userID, iterator, usersLength INT(11);
  DECLARE done TINYINT(1);
  DECLARE usersCursor CURSOR FOR SELECT DISTINCT user_id FROM active_calls_view;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
  SET responce = JSON_ARRAY();
  SET usersArray = JSON_ARRAY();
  OPEN usersCursor;
    usersLoop: LOOP
      FETCH usersCursor INTO userID;
      IF done
        THEN LEAVE usersLoop;
      END IF;
      SET usersArray = JSON_MERGE(usersArray, CONCAT(userID));
      ITERATE usersLoop;
    END LOOP;
  CLOSE usersCursor;
  SELECT count(*) INTO callsCountBefore FROM active_calls_view;
  UPDATE calls c SET call_internal_type_id = 42, call_destination_type_id = 42 WHERE call_internal_type_id NOT IN (38,40,41,42,46,47,48,49,50,51,52,53) AND call_destination_type_id NOT IN (38,40,41,42,46,47,48,49,50,51,52,53);
  SELECT count(*) INTO callsCountAfter FROM active_calls_view;
  SET usersLength = JSON_LENGTH(usersArray);
  IF usersLength > 0
    THEN BEGIN
      SET iterator = 0;
      usersLoop: LOOP
        IF iterator >= usersLength
          THEN LEAVE usersLoop;
        END IF;
        SET userID = JSON_UNQUOTE(JSON_EXTRACT(usersArray, CONCAT("$[", iterator, "]")));
        SET responce = JSON_MERGE(responce, refreshUserCompanies(userID));
        SET iterator = iterator + 1;
        ITERATE usersLoop;
      END LOOP;
    END;
  END IF;
  SET responce = JSON_MERGE(responce, JSON_OBJECT(
    "type", "print",
    "data", JSON_OBJECT(
      "message", CONCAT("Число активных звонков (до | после) сброса: ", callsCountBefore, " | ", callsCountAfter),
      "telegram", 1
    )
  ));
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

CREATE DEFINER=`root`@`localhost` FUNCTION `resetNotDialAllCompanies` () RETURNS JSON NO SQL
BEGIN
    DECLARE companiesCount INT(11) DEFAULT 0;
    DECLARE responce JSON;
    SET responce = JSON_ARRAY();
    SELECT COUNT(*) INTO companiesCount FROM companies WHERE type_id = 36;
    UPDATE companies SET type_id = 10, user_id = NULL WHERE type_id = 36;
    SET responce = JSON_MERGE(responce, refreshUsersCompanies());
    SET responce = JSON_MERGE(responce, JSON_OBJECT(
        "type", "print",
        "data", JSON_OBJECT(
            "message", CONCAT("Сброшено в свободный доступ ", companiesCount, " компаний из общего списка недозвона за все время."),
            "telegram", 1
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

CREATE DEFINER=`root`@`localhost` FUNCTION `sendToApi` (`connectionHash` VARCHAR(32) CHARSET utf8, `companyID` INT(11), `comment` TEXT CHARSET utf8, `banks` JSON) RETURNS JSON NO SQL
BEGIN
    DECLARE userID, iterator, banksLength, bankFilialID, bankStatusID INT(11);
    DECLARE connectionValid TINYINT(1);
    DECLARE connectionApiID VARCHAR(128);
    DECLARE filialApiCode, regionApiCode, cityApiCode VARCHAR(32);
    DECLARE filialName VARCHAR(256);
    DECLARE statusText VARCHAR(22);
    DECLARE responce, company, banksIDArray JSON;
    SET responce = JSON_ARRAY();
    SET statusText = "Ожидание";
    SET connectionValid = checkConnection(connectionHash);
    SET iterator = 0;
    SET banksLength = JSON_LENGTH(banks);
    SELECT connection_api_id, user_id INTO connectionApiID, userID FROM connections WHERE connection_hash = connectionHash;
    IF connectionValid
        THEN BEGIN
            UPDATE companies SET company_comment = comment, type_id = 13 WHERE company_id = companyID;
            SET banksIDArray = jsonMap(banks, JSON_ARRAY("bank_id"));
            CALL checkBanksStatuses(banksIDArray, JSON_ARRAY(statusText));
            UPDATE company_banks cb JOIN bank_statuses bs ON bs.bank_id = cb.bank_id AND bs.bank_status_text = statusText SET cb.bank_status_id = bs.bank_status_id, cb.company_bank_date_send = NOW() WHERE cb.company_id = companyID AND JSON_CONTAINS(banksIDArray, JSON_ARRAY(CONCAT(cb.bank_id)));
            banksLoop: LOOP
                IF iterator >= banksLength
                    THEN LEAVE banksLoop;
                END IF;
                SET bankFilialID = JSON_UNQUOTE(JSON_EXTRACT(banks, CONCAT("$[", iterator, "].bank_filial_id")));
                SELECT bank_filial_api_code, bank_filial_region_api_code, bank_filial_city_api_code, bank_filial_name INTO filialApiCode, regionApiCode, cityApiCode, filialName FROM bank_filials WHERE bank_filial_id = bankFilialID;
                SET banks = JSON_SET(banks, CONCAT("$[", iterator, "].bankFilialApiCode"), filialApiCode, CONCAT("$[", iterator, "].bankFilialRegionApiCode"), regionApiCode, CONCAT("$[", iterator, "].bankFilialCityApiCode"), cityApiCode, CONCAT("$[", iterator, "].bankFilialName"), filialName);
                SET iterator = iterator + 1;
                ITERATE banksLoop;
            END LOOP;
            SELECT
                JSON_OBJECT(
                    "companyID", c.company_id,
                    "companyPersonName", c.company_person_name,
                    "companyPersonSurname", c.company_person_surname,
                    "companyPersonPatronymic", c.company_person_patronymic,
                    "companyPhone", c.company_phone,
                    "companyOrganizationName", c.company_organization_name,
                    "companyInn", c.company_inn,
                    "companyOgrn", c.company_ogrn,
                    "companyComment", c.company_comment,
                    "banks", banks,
                    "templateTypeID", c.company_json ->> "$.template_type_id",
                    "regionCode", cd.code_value,
                    "companyEmail", c.company_email,
                    "cityName", ci.city_name
                )
            INTO company
            FROM
                companies c
                LEFT JOIN codes cd ON cd.region_id = c.region_id
                LEFT JOIN cities ci ON ci.city_id = c.city_id
            WHERE c.company_id = companyID LIMIT 1;
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

CREATE DEFINER=`root`@`localhost` FUNCTION `sendToTelegram` (`message` TEXT CHARSET utf8) RETURNS JSON NO SQL
BEGIN
    DECLARE chatID VARCHAR(128);
    DECLARE done TINYINT(1);
    DECLARE responce, telegramsArray JSON;
    DECLARE telegramCursor CURSOR FOR SELECT telegram_chat_id FROM telegrams WHERE telegram_chat_id IS NOT NULL;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    SET responce = JSON_ARRAY();
    SET telegramsArray = JSON_ARRAY();
    OPEN telegramCursor;
        telegramLoop: LOOP
            FETCH telegramCursor INTO chatID;
            IF done
                THEN LEAVE telegramLoop;
            END IF;
            SET telegramsArray = JSON_MERGE(telegramsArray, CONCAT(chatID));
            ITERATE telegramLoop;
        END LOOP;
    CLOSE telegramCursor;
    IF JSON_LENGTH(telegramsArray) > 0
        THEN SET responce = JSON_MERGE(responce, JSON_OBJECT(
            "type", "sendToTelegram",
            "data", JSON_OBJECT(
                "chats", telegramsArray,
                "message", message
            )
        ));
        ELSE SET responce = JSON_MERGE(responce, JSON_OBJECT(
            "type", "print",
            "data", JSON_OBJECT(
                "message", CONCAT("нет чатов для рассылки в телеграм (", message, ")")
            )
        ));
    END IF;
    RETURN responce;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `serverStart` () RETURNS JSON NO SQL
BEGIN
  DECLARE responce JSON;
  DECLARE connectionsBeforeCount, connectionsAfterCount INT(11);
  SET responce = JSON_ARRAY();
  SELECT count(*) INTO connectionsBeforeCount FROM connections WHERE connection_end = 0;
  UPDATE connections SET connection_end = 1;
  SELECT count(*) INTO connectionsAfterCount FROM connections WHERE connection_end = 0;
  SET responce = JSON_MERGE(responce, resetCalls());
  SET responce = JSON_MERGE(responce, JSON_OBJECT(
    "type", "print",
    "data", JSON_OBJECT(
      "message", CONCAT("число активных соединений (до | после) сброса: ", connectionsBeforeCount, " | ", connectionsAfterCount),
      "telegram", 1
    )
  ));
  RETURN responce;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `setApiResponce` (`companyID` INT(11), `bankID` INT(11), `applicationID` VARCHAR(128) CHARSET utf8, `requestID` VARCHAR(128) CHARSET utf8, `statusText` VARCHAR(128) CHARSET utf8) RETURNS JSON NO SQL
BEGIN
    DECLARE userID, bankStatusID INT(11);
    DECLARE responce JSON;
    SET responce = JSON_ARRAY();
    SELECT user_id INTO userID FROM companies WHERE company_id = companyID;
    CALL checkBanksStatuses(JSON_ARRAY(bankID), JSON_ARRAY(statusText));
    SELECT bank_status_id INTO bankStatusID FROM bank_statuses WHERE bank_id = bankID AND bank_status_text = statusText LIMIT 1;
    UPDATE company_banks SET bank_status_id = bankStatusID, company_bank_application_id = applicationID, company_bank_request_id = requestID WHERE company_id = companyID AND bank_id = bankID;
    SET responce = JSON_MERGE(responce, refreshUserCompanies(userID));
    RETURN responce;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `setBankFilials` (`bankID` INT(11), `filials` JSON, `deleteFilials` BOOLEAN) RETURNS JSON NO SQL
BEGIN
    DECLARE iterator, filialsLength, regionCode, regionID, cityID, bankFilialsCountBefore, bankFilialsCountAfter INT(11);
    DECLARE cityName, regionName VARCHAR(60);
    DECLARE bankFilialApiCode, bankFilialRegionApiCode, bankFilialCityApiCode VARCHAR(32);
    DECLARE bankFilialName VARCHAR(256);
    DECLARE bankName VARCHAR(128);
    DECLARE filial, responce JSON;
    SET responce = JSON_ARRAY();
    SET iterator = 0;
    SET filialsLength = JSON_LENGTH(filials);
    SELECT bank_name INTO bankName FROM banks WHERE bank_id = bankID;
    SELECT count(*) INTO bankFilialsCountBefore FROM bank_filials WHERE bank_id = bankID;
    IF deleteFilials
        THEN DELETE FROM bank_filials WHERE bank_id = bankID;
    END IF;
    filialsLoop: LOOP
        IF iterator >= filialsLength
            THEN LEAVE filialsLoop;
        END IF;
        SET filial = JSON_UNQUOTE(JSON_EXTRACT(filials, CONCAT("$[", iterator, "]")));
        IF filial IS NOT NULL
            THEN BEGIN
                SET cityName = JSON_UNQUOTE(JSON_EXTRACT(filial, "$.city_name"));
                SET regionCode = JSON_UNQUOTE(JSON_EXTRACT(filial, "$.region_code"));
                SET regionName = JSON_UNQUOTE(JSON_EXTRACT(filial, "$.region_name"));
                SET bankFilialApiCode = JSON_UNQUOTE(JSON_EXTRACT(filial, "$.bank_filial_api_code"));
                SET bankFilialName = JSON_UNQUOTE(JSON_EXTRACT(filial, "$.bank_filial_name"));
                SET bankFilialRegionApiCode = JSON_UNQUOTE(JSON_EXTRACT(filial, "$.bank_filial_region_api_code"));
                SET bankFilialCityApiCode = JSON_UNQUOTE(JSON_EXTRACT(filial, "$.bank_filial_city_api_code"));
                IF regionCode IS NOT NULL
                    THEN SELECT region_id INTO regionID FROM codes WHERE code_value = regionCode;
                    ELSE IF regionName IS NOT NULL
                        THEN SELECT region_id INTO regionID FROM regions WHERE LOWER(region_name) = LOWER(regionName);
                    END IF;
                END IF;
                IF cityName IS NOT NULL
                    THEN SELECT city_id INTO cityID FROM cities WHERE LOWER(city_name) = LOWER(cityName);
                END IF;
                IF bankFilialName IS NULL AND cityName IS NOT NULL
                    THEN SET bankFilialName = cityName;
                END IF;
                IF bankFilialName IS NOT NULL AND cityID IS NOT NULL AND bankFilialApiCode IS NOT NULL AND bankID IS NOT NULL
                    THEN INSERT INTO bank_filials (bank_id, city_id, region_id, bank_filial_name, bank_filial_api_code, bank_filial_region_api_code, bank_filial_city_api_code) VALUES (bankID, cityID, regionID, bankFilialName, bankFilialApiCode, bankFilialRegionApiCode, bankFilialCityApiCode);
                END IF;
            END;
        END IF;
        SET iterator = iterator + 1;
        ITERATE filialsLoop;
    END LOOP;
    SELECT count(*) INTO bankFilialsCountAfter FROM bank_filials WHERE bank_id = bankID;
    SET responce = JSON_MERGE(responce, JSON_OBJECT(
        "type", "print",
        "data", JSON_OBJECT(
            "message", CONCAT("Обновление филиалов банка ", bankName, ". Было филиалов ", bankFilialsCountBefore, ". Стало ", bankFilialsCountAfter, ".")
        )
    ));
    RETURN responce;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `setCallRecord` (`callApiIDWithRec` VARCHAR(128) CHARSET utf8, `callApiID` VARCHAR(128) CHARSET utf8) RETURNS JSON NO SQL
BEGIN
    DECLARE responce JSON;
    SET responce = JSON_ARRAY();
    UPDATE calls SET call_record = 1 WHERE call_api_id_with_rec = callApiIDWithRec OR call_api_id_1 = callApiID OR call_api_id_2 = callApiID;
    RETURN responce;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `setCallStatus` (`userSip` VARCHAR(20) CHARSET utf8, `callApiID` VARCHAR(128) CHARSET utf8, `callApiIDWithRec` VARCHAR(128) CHARSET utf8, `typeID` INT(11)) RETURNS JSON NO SQL
BEGIN
    DECLARE callID, userID, companyTypeID, companyOldTypeID, callCount, companyID, callInternalTypeID, callDestinationTypeID INT(11);
    DECLARE typeTranslate VARCHAR(128);
    DECLARE nextPhone, companyPhone VARCHAR(120);
    DECLARE ringing, notDial, callEnd, callProcess TINYINT(1);
    DECLARE responce JSON;
    SET responce = JSON_ARRAY();
    SELECT call_id, user_id INTO callID, userID FROM calls_view WHERE user_sip = userSip OR call_api_id_internal = callApiID OR call_api_id_destination = callApiID ORDER BY call_id DESC LIMIT 1;
    SELECT user_sip, user_ringing INTO userSip, ringing FROM users WHERE user_id = userID;
    UPDATE calls SET
        call_internal_type_id = IF(
            (
                call_api_id_internal IS NOT NULL AND
                call_api_id_internal = callApiID
            ) OR
            (
                call_api_id_internal IS NULL AND (
                    (
                        call_api_id_destination IS NULL AND
                        call_predicted = 0
                    ) OR (
                        call_api_id_destination IS NOT NULL AND
                        call_api_id_destination != callApiID
                    )
                )
            ),
            typeID,
            call_internal_type_id
        ),
        call_destination_type_id = IF(
            (
                call_api_id_destination IS NOT NULL AND
                call_api_id_destination = callApiID
            ) OR
            (
                call_api_id_destination IS NULL AND (
                    (
                        call_api_id_internal IS NULL AND
                        call_predicted = 1
                    ) OR (
                        call_api_id_internal IS NOT NULL AND
                        call_api_id_internal != callApiID
                    )
                )
            ),
            typeID,
            call_destination_type_id
        ),
        call_api_id_internal = IF(
            call_api_id_internal IS NULL AND
            ((
                call_api_id_destination IS NULL AND
                call_predicted = 0
            ) OR (
                call_api_id_destination IS NOT NULL AND
                call_api_id_destination != callApiID
            )),
            callApiID,
            call_api_id_internal
        ),
        call_api_id_destination = IF(
            call_api_id_destination IS NULL AND
            ((
                call_api_id_internal IS NULL AND
                call_predicted = 1
            ) OR (
                call_api_id_internal IS NOT NULL AND
                call_api_id_internal != callApiID
            )),
            callApiID,
            call_api_id_destination
        ),
        call_internal_api_id_with_rec = IF(
            call_api_id_internal = callApiID,
            callApiIDWithRec,
            call_internal_api_id_with_rec
        ),
        call_destination_api_id_with_rec = IF(
            call_api_id_destination = callApiID,
            callApiIDWithRec,
            call_destination_api_id_with_rec
        )
    WHERE call_id = callID;
    SELECT call_internal_type_id, call_destination_type_id, company_id INTO callInternalTypeID, callDestinationTypeID, companyID FROM calls WHERE call_id = callID;
    SET callEnd = IF(callDestinationTypeID IN (38,40,41,42,46,47,48,49,50,51,52,53,33) AND callInternalTypeID IN (38,40,41,42,46,47,48,49,50,51,52,53,33), 1, 0);
    SET callProcess = IF(callDestinationTypeID = 34, 1, 0);
    SET notDial = IF((callInternalTypeID IN (42,47,48,49,50) OR callDestinationTypeID IN (42,47,48,49,50)) AND callEnd = 1, 1, 0);
    UPDATE companies SET type_id = IF(notDial = 1, IF(type_id = 9, 35, 36), IF(type_id IN (35, 36) AND callEnd = 1, 9, type_id)), company_ringing = IF(ringing = 1 AND callEnd = 1, IF(type_id = 35, 0, 1), 0) WHERE company_id = companyID;
    SELECT type_id, old_type_id, company_id, company_phone INTO companyTypeID, companyOldTypeID, companyID, companyPhone FROM companies WHERE call_id = callID;
    SELECT tr.translate_to INTO typeTranslate FROM translates tr JOIN types t ON t.type_id = typeID AND t.type_name = tr.translate_from;
    IF companyTypeID = 36
        THEN SET responce = JSON_MERGE(responce, refreshUsersCompanies());
        ELSE SET responce = JSON_MERGE(responce, refreshUserCompanies(userID));
    END IF;
    SET responce = JSON_MERGE(responce, sendToAllUserSockets(userID, JSON_ARRAY(JSON_OBJECT(
        "type", "mergeDeep",
        "data", JSON_OBJECT(
            "message", CONCAT("соединение с ", companyPhone, " имеет статус: ", typeTranslate),
            "messageType", IF(typeID IN (39, 33, 34, 43), "success", "error")
        )
    ))));
    IF callProcess = 1 AND callEnd = 0
        THEN BEGIN
            UPDATE users SET user_ringing = 0 WHERE user_id = userID;
            SET ringing = 0;
        END;
    END IF;
    IF companyOldTypeID IN (9, 35, 10) AND callEnd = 1 AND companyTypeID IN (9, 35, 36) AND ringing = 1
        THEN BEGIN
            SELECT COUNT(*) INTO callCount FROM active_calls_view WHERE user_id = userID;
            IF callCount = 0
                THEN BEGIN
                    SELECT REPLACE(company_phone, "+", ""), company_id INTO nextPhone, companyID FROM companies WHERE user_id = userID AND type_id IN (9, 35) AND company_ringing = 0 ORDER BY type_id LIMIT 1;
                    IF nextPhone IS NOT NULL
                        THEN BEGIN
                            INSERT INTO calls (user_id, company_id, call_internal_type_id, call_destination_type_id, call_predicted) VALUES (userID, companyID, 33, 33, 1);
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
                            SET responce = JSON_MERGE(responce, sendToAllUserSockets(userID, JSON_ARRAY(JSON_OBJECT(
                                "type", "mergeDeep",
                                "data", JSON_OBJECT(
                                    "message", CONCAT("соединение с ", nextPhone, " имеет статус: ожидание ответа от АТС")
                                )
                            ))));
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
        SET responce = JSON_MERGE(responce, sendToAllUserSockets(userID, JSON_ARRAY(JSON_OBJECT(
          "type", "mergeDeep",
          "data", JSON_OBJECT(
            "message", "статусы компаний обновлены",
            "messageType", "success"
          )
        ))));
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
    DECLARE userID, connectionID, lastTypeID INT(11);
    DECLARE connectionValid TINYINT(1);
    DECLARE connectionApiID VARCHAR(128);
    DECLARE responce JSON;
    SET connectionValid = checkConnection(connectionHash);
    SELECT connection_api_id, user_id, connection_id INTO connectionApiID, userID, connectionID FROM users_connections_view WHERE connection_hash = connectionHash;
    SET responce = JSON_ARRAY();
    IF connectionValid
        THEN BEGIN
            SELECT type_id INTO lastTypeID FROM companies WHERE company_id = companyID;
            IF typeID = 23
                THEN UPDATE companies SET type_id = typeID, company_date_call_back = dateParam, user_id = userID WHERE company_id = companyID;
                ELSE UPDATE companies SET type_id = typeID, user_id = userID WHERE company_id = companyID;
            END IF;
            IF typeID = 36 OR lastTypeID = 36
                THEN SET responce = JSON_MERGE(responce, refreshUsersCompanies());
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
  DECLARE responce, filtersKeys, userFilters, activeCompany JSON;
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
      SET activeCompany = JSON_OBJECT();
      SELECT company_json INTO activeCompany FROM working_user_company_view WHERE user_id = userID LIMIT 1;
      SET responce = JSON_MERGE(responce, JSON_OBJECT(
        "type", "sendToSocket",
        "data", JSON_OBJECT(
          "socketID", connectionApiID,
          "data", JSON_ARRAY(
            JSON_OBJECT(
              "type", "merge",
              "data", JSON_OBJECT(
                "distribution", userFilters,
                "companies", getActiveBankUserCompanies(connectionID),
                "activeCompany", activeCompany
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
    DECLARE companiesLength, bankID, companiesIterator, banksIterator, banksLength, companyID, statusTypeID, statusID, companyBankID, negativeCompaniesLength INT(11);
    DECLARE connectionHash VARCHAR(32);
    DECLARE statusText VARCHAR(256);
    DECLARE responce, company, companyBanksArray, companyBank, negativeCompanies JSON;
    SET responce = JSON_ARRAY();
    SET companiesLength = JSON_LENGTH(companiesArray);
    SET negativeCompanies = JSON_ARRAY();
    SET negativeCompaniesLength = 0;
    SET companiesIterator = 0;
    companiesLoop: LOOP
        IF companiesIterator >= companiesLength
            THEN LEAVE companiesLoop;
        END IF;
        SET company = JSON_UNQUOTE(JSON_EXTRACT(companiesArray, CONCAT("$[", companiesIterator, "]")));
        SET companyID = JSON_UNQUOTE(JSON_EXTRACT(company, "$.company_id"));
        SET companyBanksArray = JSON_UNQUOTE(JSON_EXTRACT(company, "$.banks"));
        SET banksIterator = 0;
        SET banksLength = JSON_LENGTH(companyBanksArray);
        companyBanksLoop:LOOP
            IF banksIterator >= banksLength
                THEN LEAVE companyBanksLoop;
            END IF;
            SET companyBank = JSON_UNQUOTE(JSON_EXTRACT(companyBanksArray, CONCAT("$[", banksIterator, "]")));
            SET statusText = JSON_UNQUOTE(JSON_EXTRACT(companyBank, "$.status_text"));
            SET bankID = JSON_UNQUOTE(JSON_EXTRACT(companyBank, "$.bank_id"));
            CALL checkBanksStatuses(JSON_ARRAY(bankID), JSON_ARRAY(statusText));
            SELECT type_id, bank_status_id INTO statusTypeID, statusID FROM bank_statuses WHERE bank_id = bankID AND bank_status_text = statusText LIMIT 1;
            SET companyBankID = (SELECT company_bank_id FROM company_banks WHERE bank_id = bankID AND company_id = companyID LIMIT 1);
            IF companyBankID IS NOT NULL
                THEN UPDATE company_banks SET bank_status_id = statusID WHERE company_bank_id = companyBankID;
                ELSE UPDATE companies c LEFT JOIN translates tr ON tr.translate_from = statusText JOIN banks b ON b.bank_id = bankID SET c.company_json = JSON_SET(c.company_json, CONCAT("$.company_banks.b", bankID), JSON_OBJECT(
                    "bank_id", b.bank_id,
                    "bank_name", b.bank_name,
                    "company_bank_status", IF(tr.translate_to IS NOT NULL, tr.translate_to, statusText),
                    "bank_status_id", statusID,
                    "type_id", statusTypeID,
                    "bank_suits", 0
                )) WHERE company_id = companyID;
            END IF;
            IF statusTypeID = 17
                THEN BEGIN
                    UPDATE companies SET type_id = 24 WHERE company_id = companyID;
                    IF !JSON_CONTAINS(negativeCompanies, JSON_ARRAY(companyID))
                        THEN SET negativeCompanies = JSON_MERGE(negativeCompanies, JSON_ARRAY(companyID));
                    END IF;
                END;
            END IF;
            SET banksIterator = banksIterator + 1;
            ITERATE companyBanksLoop;
        END LOOP;
        SET companiesIterator = companiesIterator + 1;
        ITERATE companiesLoop;
    END LOOP;
    UPDATE companies SET type_id = 9 WHERE user_id = userID AND type_id = 44;
    SELECT bank_id, connection_hash INTO bankID, connectionHash FROM users_connections_view WHERE user_id = userID AND connection_end = 0 LIMIT 1;
    SET negativeCompaniesLength = JSON_LENGTH(negativeCompanies);
    SET responce = JSON_MERGE(responce, refreshUserCompanies(userID));
    SET responce = JSON_MERGE(responce, sendToAllUserSockets(userID, JSON_ARRAY(JSON_OBJECT(
        "type", "merge",
        "data", JSON_OBJECT(
            "message", IF(negativeCompaniesLength = 0, "Окончание наполнения рабочего списка", CONCAT("Добавлено в рабочий список ", (companiesLength - negativeCompaniesLength) ," компаний. На проверке ещё ", negativeCompaniesLength, " компаний")),
            "messageType", IF(negativeCompaniesLength = 0, "success", "")
        )
    ))));
    IF negativeCompaniesLength > 0
        THEN SET responce = JSON_MERGE(responce, getBankCompanies(connectionHash, negativeCompaniesLength, 0));
    END IF;
    RETURN responce;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `setRecordFile` (`userSip` VARCHAR(128) CHARSET utf8, `companyPhone` VARCHAR(128) CHARSET utf8, `fileName` VARCHAR(128) CHARSET utf8, `filePath` VARCHAR(128) CHARSET utf8, `internal` TINYINT(1)) RETURNS JSON NO SQL
BEGIN
  DECLARE callID, userID, fileID INT(11);
  DECLARE responce JSON;
  SET responce = JSON_ARRAY();
  SELECT call_id, user_id INTO callID, userID FROM end_calls_view WHERE company_phone = IF(companyPhone IS NOT NULL, companyPhone, company_phone) AND user_sip = userSip ORDER BY call_id DESC LIMIT 1;
  IF callID IS NOT NULL
    THEN BEGIN
      INSERT INTO files (file_name, type_id, user_id) VALUES (filePath, 45, userID);
      SELECT file_id INTO fileID FROM files ORDER BY file_id DESC LIMIT 1;
      UPDATE calls SET
        call_destination_file_id = IF(internal = 0, fileID, call_destination_file_id),
        call_internal_file_id = IF(internal = 1, fileID, call_internal_file_id),
        call_destination_type_id = IF(call_destination_type_id NOT IN (38,40,41,42,46,47,48,49,50,51,52,53), call_destination_type_id, 42),
        call_internal_type_id = IF(call_internal_type_id NOT IN (38,40,41,42,46,47,48,49,50,51,52,53), call_internal_type_id, 42)
      WHERE call_id = callID;
      SET responce = JSON_MERGE(responce, JSON_OBJECT(
        "type", "moveFile",
        "data", JSON_OBJECT(
          "fileName", fileName,
          "from", "attachments",
          "to", "files"
        )
      ));
      SET responce = JSON_MERGE(responce, refreshUserCompanies(userID));
    END;
  END IF;
  RETURN responce;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `setStatisticFilter` (`connectionHash` VARCHAR(32) CHARSET utf8, `filters` JSON) RETURNS JSON NO SQL
BEGIN
    DECLARE connectionValid TINYINT(1);
    DECLARE keyName VARCHAR(128);
    DECLARE connectionApiID VARCHAR(32);
    DECLARE keysLength, iterator, stateID, userID, connectionID, bankID INT(11);
    DECLARE userFilters, responce, filtersKeys JSON;
    SET connectionValid = checkConnection(connectionHash);
    SET responce = JSON_ARRAY();
    SELECT user_id, connection_id, connection_api_id, bank_id INTO userID, connectionID, connectionApiID, bankID FROM users_connections_view WHERE connection_hash = connectionHash;
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
                SET userFilters = JSON_SET(userFilters, CONCAT("$.", keyName), JSON_EXTRACT(filters, CONCAT("$.", keyName)));
                SET iterator = iterator + 1;
                ITERATE keysLoop;
            END LOOP;
            UPDATE states SET state_json = JSON_SET(state_json, "$.statistic", userFilters) WHERE state_id = stateID;
            SELECT state_json ->> "$.statistic" INTO userFilters FROM states WHERE state_id = stateID LIMIT 1;
            SET userFilters = JSON_SET(userFilters, "$.users", getUsers(bankID));
            SET responce = JSON_MERGE(responce, JSON_OBJECT(
                "type", "sendToSocket",
                "data", JSON_OBJECT(
                    "socketID", connectionApiID,
                    "data", JSON_ARRAY(JSON_OBJECT(
                        "type", "merge",
                        "data", JSON_OBJECT(
                            "statistic", userFilters
                        )
                    ))
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

CREATE DEFINER=`root`@`localhost` FUNCTION `setUserRinging` (`connectionHash` VARCHAR(32) CHARSET utf8, `ringing` BOOLEAN) RETURNS JSON NO SQL
BEGIN
    DECLARE userID INT(11);
    DECLARE connectionValid, oldRinging TINYINT(1);
    DECLARE responce JSON;
    SET responce = JSON_ARRAY();
    SET connectionValid = checkConnection(connectionHash);
    IF connectionValid
        THEN BEGIN
            SELECT user_id INTO userID FROM connections WHERE connection_hash = connectionHash;
            SELECT user_ringing INTO oldRinging FROM users WHERE user_id = userID;
            IF ringing != oldRinging
                THEN BEGIN
                    UPDATE users SET user_ringing = ringing WHERE user_id = userID;
                    UPDATE companies SET company_ringing = 0 WHERE user_id = userID AND type_id IN (9, 35) AND company_ringing = 1;
                    SET responce = JSON_MERGE(responce, sendToAllUserSockets(userID, JSON_ARRAY(
                        JSON_OBJECT(
                            "type", "merge",
                            "data", JSON_OBJECT(
                                "ringing", ringing
                            )
                        )
                    )));
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
  DECLARE fileStatistic TINYINT(1);
  DECLARE responce JSON;
  DECLARE userID INT(11);
  SET responce = JSON_ARRAY();
  UPDATE files SET file_name = fileName, type_id = 21 WHERE file_id = fileID;
  UPDATE companies SET type_id = IF(type_id = 22, 21, type_id), company_file_type = 22 WHERE company_file_type = fileID;
  SELECT user_id, file_statistic INTO userID, fileStatistic FROM files WHERE file_id = fileID;
  SET responce = JSON_MERGE(responce, sendToAllUserSockets(userID, JSON_ARRAY(
    JSON_OBJECT(
      "type", "mergeDeep",
      "data", JSON_OBJECT(
        IF(!fileStatistic, "download", "statistic"), JSON_OBJECT(
          "fileURL", fileName,
          "message", "Файл успешно создан",
          "companiesCount", 0
        )
      )
    )
  )));
  IF !fileStatistic
    THEN SET responce = JSON_MERGE(responce, JSON_OBJECT(
      "type", "merge",
      "data", JSON_OBJECT(
        "files", getUserFiles(userID)
      )
    ));
  END IF;
  RETURN responce;
END$$

DELIMITER ;
CREATE TABLE `active_calls_view` (
`call_id` int(11)
,`call_internal_type_id` int(11)
,`call_destination_type_id` int(11)
,`user_sip` varchar(20)
,`company_phone` varchar(359)
,`user_id` int(11)
,`company_id` int(11)
,`call_api_id_internal` varchar(128)
,`call_api_id_destination` varchar(128)
);

CREATE TABLE `banks` (
  `bank_id` int(11) NOT NULL,
  `bank_name` varchar(128) COLLATE utf8_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
CREATE TABLE `banks_statistic_view` (
`bank_id` int(11)
,`bank_json` json
);

CREATE TABLE `bank_cities` (
  `bank_city_id` int(11) NOT NULL,
  `bank_id` int(11) NOT NULL,
  `city_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
CREATE TABLE `bank_cities_company_view` (
`company_id` int(11)
,`bank_id` int(11)
);

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

CREATE TABLE `bank_filials` (
  `bank_filial_id` int(11) NOT NULL,
  `bank_id` int(11) NOT NULL,
  `city_id` int(11) NOT NULL,
  `region_id` int(11) DEFAULT NULL,
  `bank_filial_name` varchar(256) COLLATE utf8_bin DEFAULT NULL,
  `bank_filial_api_code` varchar(32) COLLATE utf8_bin NOT NULL,
  `bank_filial_region_api_code` varchar(32) COLLATE utf8_bin DEFAULT NULL,
  `bank_filial_city_api_code` varchar(32) COLLATE utf8_bin DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

CREATE TABLE `bank_statuses` (
  `bank_status_id` int(11) NOT NULL,
  `bank_id` int(11) NOT NULL,
  `bank_status_text` varchar(256) COLLATE utf8_bin NOT NULL,
  `bank_status_date_create` varchar(19) COLLATE utf8_bin NOT NULL,
  `type_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
DELIMITER $$
CREATE TRIGGER `bank_statuses_before_insert` BEFORE INSERT ON `bank_statuses` FOR EACH ROW BEGIN
    SET NEW.bank_status_date_create = NOW();
    IF NEW.type_id IS NULL
        THEN SET NEW.type_id = 15;
    END IF;
END
$$
DELIMITER ;
CREATE TABLE `bank_status_translate` (
`status_json` json
,`bank_id` int(11)
);
CREATE TABLE `bank_times_view` (
`time_id` int(11)
,`time_value` varchar(5)
,`bank_id` int(11)
);

CREATE TABLE `calls` (
  `call_id` int(11) NOT NULL,
  `call_internal_type_id` int(11) DEFAULT NULL,
  `company_id` int(11) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `call_date_create` varchar(19) COLLATE utf8_bin NOT NULL,
  `call_internal_file_id` int(11) DEFAULT NULL,
  `call_api_id_internal` varchar(128) COLLATE utf8_bin DEFAULT NULL,
  `call_api_id_destination` varchar(128) COLLATE utf8_bin DEFAULT NULL,
  `call_internal_record` tinyint(1) NOT NULL DEFAULT '0',
  `call_date_update` varchar(19) COLLATE utf8_bin DEFAULT NULL,
  `call_internal_api_id_with_rec` varchar(128) COLLATE utf8_bin DEFAULT NULL,
  `call_destination_record` tinyint(1) NOT NULL DEFAULT '0',
  `call_destination_api_id_with_rec` varchar(128) COLLATE utf8_bin DEFAULT NULL,
  `call_destination_file_id` int(11) DEFAULT NULL,
  `call_destination_type_id` int(11) DEFAULT NULL,
  `call_predicted` tinyint(1) NOT NULL DEFAULT '0'
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
        THEN UPDATE companies SET call_id = NEW.call_id WHERE company_id = NEW.company_id;
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
,`call_internal_file_id` int(11)
,`call_destination_file_id` int(11)
,`internal_file_name` varchar(128)
,`destination_file_name` varchar(128)
);
CREATE TABLE `calls_view` (
`call_id` int(11)
,`call_internal_type_id` int(11)
,`company_id` int(11)
,`user_id` int(11)
,`call_date_create` varchar(19)
,`call_internal_file_id` int(11)
,`call_internal_api_id_with_rec` varchar(128)
,`call_date_update` varchar(19)
,`call_api_id_internal` varchar(128)
,`call_api_id_destination` varchar(128)
,`call_internal_record` tinyint(1)
,`call_predicted` tinyint(1)
,`call_destination_api_id_with_rec` varchar(128)
,`call_destination_record` tinyint(1)
,`call_destination_file_id` int(11)
,`call_destination_type_id` int(11)
,`user_sip` varchar(20)
,`company_phone` varchar(120)
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
  `company_ringing` tinyint(1) NOT NULL DEFAULT '0',
  `company_file_user` int(11) DEFAULT NULL,
  `company_file_type` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
DELIMITER $$
CREATE TRIGGER `companies_after_insert` AFTER INSERT ON `companies` FOR EACH ROW BEGIN
    DECLARE iterator, banksLength, bankID INT(11);
    DECLARE bankKey VARCHAR(12);
    DECLARE banks, banksKeys JSON;
    SET banks = JSON_UNQUOTE(JSON_EXTRACT(NEW.company_json, "$.company_banks"));
    SET iterator = 0;
    SET banksKeys = JSON_KEYS(banks);
    SET banksLength = JSON_LENGTH(banksKeys);
    IF banksLength > 0
        THEN BEGIN
            banksLoop: LOOP
                IF iterator >= banksLength
                    THEN LEAVE banksLoop;
                END IF;
                SET bankKey = JSON_UNQUOTE(JSON_EXTRACT(banksKeys, CONCAT("$[", iterator, "]")));
                SET bankID = JSON_UNQUOTE(JSON_EXTRACT(banks, CONCAT("$.", bankKey, ".bank_id")));
                INSERT INTO company_banks (company_id, bank_id) VALUES (NEW.company_id, bankID);
                SET iterator = iterator + 1;
                ITERATE banksLoop;
            END LOOP;
        END;
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `companies_before_insert` BEFORE INSERT ON `companies` FOR EACH ROW BEGIN
  DECLARE innLength, templateType, bankID INT(11);
  DECLARE cityID INT(11) DEFAULT (SELECT city_id FROM fns_codes WHERE fns_code_value = SUBSTRING(NEW.company_inn, 1, 4));
  DECLARE companyBanks JSON;
  DECLARE bankName VARCHAR(128);
  DECLARE done TINYINT(1);
  DECLARE banksCursor CURSOR FOR SELECT DISTINCT bank_id FROM bank_cities WHERE city_id = cityID OR city_id IS NULL;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
  SET companyBanks = JSON_OBJECT();
  OPEN banksCursor;
    banksLoop: LOOP
      FETCH banksCursor INTO bankID;
      IF done
        THEN LEAVE banksLoop;
      END IF;
      SELECT bank_name INTO bankName FROM banks WHERE bank_id = bankID;
      SET companyBanks = JSON_SET(companyBanks, CONCAT("$.b", bankID), JSON_OBJECT("bank_id", bankID, "bank_name", bankName, "company_bank_status", NULL, "bank_status_id", NULL));
      ITERATE banksLoop;
    END LOOP;
  CLOSE banksCursor;
  SET NEW.company_date_create = NOW();
  SET innLength = CHAR_LENGTH(NEW.company_inn);
  IF innLength = 9 OR innLength = 11
    THEN SET NEW.company_inn = CONCAT("0", NEW.company_inn);
  END IF;
  SET NEW.city_id = cityID;
  SET NEW.region_id = (SELECT region_id FROM codes WHERE code_value = SUBSTRING(NEW.company_inn, 1, 2));
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
    'template_type_id', (SELECT type_id FROM templates WHERE template_id = NEW.template_id),
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
    "company_date_call_back", NEW.company_date_call_back,
    "company_banks", companyBanks
  );
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `companies_before_update` BEFORE UPDATE ON `companies` FOR EACH ROW BEGIN
    DECLARE callInternalTypeID, callDestinationTypeID INT(11);
    DECLARE callPredicted TINYINT(1);
    DECLARE fileName VARCHAR(128);
    IF NEW.call_id IS NOT NULL
        THEN BEGIN
            SELECT call_internal_type_id, call_destination_type_id, call_predicted INTO callInternalTypeID, callDestinationTypeID, callPredicted FROM calls WHERE call_id = NEW.call_id;
            SELECT IF(callPredicted = 1, destination_file_name, internal_file_name) INTO fileName FROM calls_file_view WHERE call_id = NEW.call_id;
        END;
    END IF;
    IF OLD.type_id IN (15, 16, 17, 24, 25, 26, 27, 28, 29, 30, 31, 32) AND NEW.type_id IN (15, 16, 17, 24, 25, 26, 27, 28, 29, 30, 31, 32)
        THEN SET NEW.company_date_update = OLD.company_date_update;
        ELSE BEGIN
            IF NEW.company_file_user IS NULL AND OLD.company_file_user IS NULL
                THEN SET NEW.company_date_update = NOW();
                ELSE SET NEW.company_date_update = OLD.company_date_update;
            END IF;
        END;
    END IF;
    IF NEW.type_id != OLD.type_id
        THEN SET NEW.old_type_id = OLD.type_id;
    END IF;
    SET NEW.company_json = JSON_SET(NEW.company_json,
        "$.type_id", NEW.type_id,
        "$.old_type_id", NEW.old_type_id,
        "$.company_date_update", NEW.company_date_update,
        "$.company_comment", NEW.company_comment,
        "$.company_date_call_back", NEW.company_date_call_back,
        "$.call_internal_type_id", callInternalTypeID,
        "$.call_destination_type_id", callDestinationTypeID,
        "$.file_name", fileName
    );
END
$$
DELIMITER ;

CREATE TABLE `company_banks` (
  `company_bank_id` int(11) NOT NULL,
  `company_id` int(11) NOT NULL,
  `bank_id` int(11) NOT NULL,
  `company_bank_date_send` varchar(19) COLLATE utf8_bin DEFAULT NULL,
  `company_bank_date_update` varchar(19) COLLATE utf8_bin DEFAULT NULL,
  `bank_status_id` int(11) DEFAULT NULL,
  `company_bank_request_id` varchar(128) COLLATE utf8_bin DEFAULT NULL,
  `company_bank_application_id` varchar(128) COLLATE utf8_bin DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
DELIMITER $$
CREATE TRIGGER `company_banks_before_update` BEFORE UPDATE ON `company_banks` FOR EACH ROW BEGIN
    SET NEW.company_bank_date_update = NOW();
    IF NEW.bank_status_id IS NOT NULL AND IF(OLD.bank_status_id IS NOT NULL, NEW.bank_status_id != OLD.bank_status_id, 1)
        THEN UPDATE companies c LEFT JOIN bank_statuses bs ON bs.bank_status_id = NEW.bank_status_id LEFT JOIN translates tr ON tr.translate_from = bs.bank_status_text SET c.company_json = JSON_SET(c.company_json, CONCAT("$.company_banks.b", NEW.bank_id, ".company_bank_status"), IF(tr.translate_to IS NOT NULL, tr.translate_to, bs.bank_status_text), CONCAT("$.company_banks.b", NEW.bank_id, ".type_id"), bs.type_id, CONCAT("$.company_banks.b", NEW.bank_id, ".bank_status_id"), bs.bank_status_id) WHERE c.company_id = NEW.company_id;
    END IF;
END
$$
DELIMITER ;
CREATE TABLE `company_banks_statuses_view` (
`company_id` int(11)
,`bank_id` int(11)
,`bank_status_text` varchar(256)
,`type_id` int(11)
);

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
    THEN BEGIN
        DELETE FROM states WHERE connection_id = NEW.connection_id;
        INSERT INTO states (connection_id, user_id) VALUES (NEW.connection_id, NEW.user_id);
    END;
  END IF;
END
$$
DELIMITER ;
CREATE TABLE `day_banks_statistic_view` (
`user_id` int(11)
,`bank_name` varchar(128)
,`count` bigint(21)
);
CREATE TABLE `day_types_statistic_view` (
`translate_to` varchar(128)
,`user_name` varchar(64)
,`user_id` int(11)
,`count` bigint(21)
);
CREATE TABLE `empty_companies_view` (
`company_id` int(11)
,`company_date_create` varchar(19)
);
CREATE TABLE `end_calls_view` (
`call_id` int(11)
,`call_internal_type_id` int(11)
,`call_destination_type_id` int(11)
,`user_sip` varchar(20)
,`company_phone` varchar(120)
,`user_id` int(11)
,`company_id` int(11)
,`call_destination_file_id` int(11)
,`call_internal_file_id` int(11)
);

CREATE TABLE `files` (
  `file_id` int(11) NOT NULL,
  `file_name` varchar(128) COLLATE utf8_bin DEFAULT NULL,
  `type_id` int(11) DEFAULT NULL,
  `file_date_create` varchar(19) COLLATE utf8_bin NOT NULL,
  `purchase_id` int(11) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `file_statistic` tinyint(1) NOT NULL DEFAULT '0'
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
CREATE TABLE `nikolay_view` (
`инн` varchar(12)
,`телефон` varchar(120)
,`дата создания` varchar(19)
,`дата последнего обновления` varchar(19)
,`статус` varchar(128)
);

CREATE TABLE `psb_codes` (
  `psb_code_id` int(11) NOT NULL,
  `psb_code_filial` int(11) NOT NULL,
  `psb_code_region` int(11) NOT NULL,
  `city_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

CREATE TABLE `psb_filial_codes` (
  `psb_filial_code_id` int(11) NOT NULL,
  `city_id` int(11) DEFAULT NULL,
  `psb_filial_code_value` int(11) NOT NULL
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
  `region_name` varchar(60) COLLATE utf8_bin NOT NULL,
  `region_msc_timezone` int(11) DEFAULT NULL,
  `region_priority` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
CREATE TABLE `regions_companies_view` (
`company_id` int(11)
,`company_date_create` varchar(19)
,`company_date_update` varchar(19)
,`company_date_registration` varchar(10)
,`type_id` int(11)
,`old_type_id` int(11)
,`user_id` int(11)
,`company_banks_length` bigint(21)
,`region_msc_timezone` int(11)
,`region_priority` int(11)
);

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
                        "period", 0,
                        "types", JSON_ARRAY(),
                        "users", JSON_ARRAY(),
                        "dataDateStart", DATE(NOW()),
                        "dataDateEnd", DATE(NOW()),
                        "dataPeriod", 5,
                        "dataBanks", JSON_EXTRACT(getBanks(), "$[*].id"),
                        "dataFree", 1,
                        "workingCompaniesLimit", 10,
                        "workingCompaniesOffset", 0
                    )
                );
            END IF;
            IF typeID = 1
                THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.download", JSON_OBJECT(
                    "dateStart", DATE(NOW()),
                    "dateEnd", DATE(NOW()),
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
                        ),
                        "duplicates", JSON_OBJECT(
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
    DECLARE typeToView, period, type, bankID INT(11);
    DECLARE firstDate VARCHAR(19);
    DECLARE dataFree, dataBank, done TINYINT(11);
    DECLARE types, bank, banks, status, statuses JSON;
    DECLARE banksCursor CURSOR FOR SELECT bank_json, bank_id FROM banks_statistic_view WHERE JSON_CONTAINS(@banks, JSON_ARRAY(CONCAT(bank_id)));
    DECLARE banksStatusesCursor CURSOR FOR SELECT status_json FROM bank_status_translate WHERE bank_id = @bankID;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    SET NEW.state_date_update = NOW();
    IF JSON_EXTRACT(NEW.state_json, "$.statistic") IS NOT NULL
        THEN BEGIN
            SET @banks = jsonMap(JSON_EXTRACT(NEW.state_json, "$.statistic.banks"), JSON_ARRAY("bank_id"));
            SET banks = JSON_ARRAY();
            OPEN banksCursor;
                banksLoop: LOOP
                    FETCH banksCursor INTO bank, bankID;
                    IF done
                        THEN LEAVE banksLoop;
                    END IF;
                    SET statuses = JSON_ARRAY();
                    SET @bankID = bankID;
                    OPEN banksStatusesCursor;
                        banksStatusesLoop:LOOP
                            FETCH banksStatusesCursor INTO status;
                            IF done
                                THEN LEAVE banksStatusesLoop;
                            END IF;
                            SET statuses = JSON_MERGE(statuses, status);
                            ITERATE banksStatusesLoop;
                        END LOOP;
                    CLOSE banksStatusesCursor;
                    SET bank = JSON_SET(bank, "$.bank_statuses", statuses);
                    SET banks = JSON_MERGE(banks, bank);
                    SET done = 0;
                    ITERATE banksLoop;
                END LOOP;
            CLOSE banksCursor;
            SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.banks", banks);
            SET period = JSON_EXTRACT(NEW.state_json, "$.statistic.period");
            SET types = JSON_UNQUOTE(JSON_EXTRACT(NEW.state_json, "$.statistic.types"));
            IF !JSON_CONTAINS(types, JSON_ARRAY(13))
                THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.banks", JSON_ARRAY(), "$.statistic.bankStatuses", JSON_ARRAY());
            END IF;
            CASE period
                WHEN 0 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 WEEK)), "$.statistic.dateEnd", DATE(NOW()));
                WHEN 1 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 MONTH)), "$.statistic.dateEnd", DATE(NOW()));
                WHEN 2 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 YEAR)), "$.statistic.dateEnd", DATE(NOW()));
                WHEN 3 THEN BEGIN
                    SELECT company_date_update INTO firstDate FROM companies WHERE IF(JSON_LENGTH(types) = 0, 1, JSON_CONTAINS(types, JSON_ARRAY(type_id))) ORDER BY company_date_update LIMIT 1;
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
                    SELECT company_date_create INTO firstDate FROM companies WHERE IF(dataFree, type_id = 10, 1) AND IF(dataBank, JSON_LENGTH(JSON_KEYS(company_json ->> "$.company_banks")) > 0, 1) ORDER BY company_date_create LIMIT 1;
                    SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.dataDateStart", DATE(firstDate), "$.statistic.dataDateEnd", DATE(NOW()));
                END;
                WHEN 4 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.dataDateStart", DATE(SUBDATE(NOW(), INTERVAL 1 DAY)), "$.statistic.dataDateEnd", DATE(SUBDATE(NOW(), INTERVAL 1 DAY)));
                WHEN 5 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.statistic.dataDateStart", DATE(NOW()), "$.statistic.dataDateEnd", DATE(NOW()));
                WHEN 6 THEN BEGIN END;
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
                    SELECT company_date_create INTO firstDate FROM companies WHERE type_id = 14 ORDER BY company_date_create LIMIT 1;
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
                    SELECT company_date_create INTO firstDate FROM companies WHERE type_id = 23 ORDER BY company_date_create LIMIT 1;
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
                    SELECT company_date_create INTO firstDate FROM companies WHERE type_id = 13 ORDER BY company_date_create LIMIT 1;
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
                    SELECT company_date_create INTO firstDate FROM companies WHERE type_id = 36 ORDER BY company_date_create LIMIT 1;
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
                    SELECT company_date_create INTO firstDate FROM companies WHERE type_id = 37 ORDER BY company_date_create LIMIT 1;
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
            SET type = JSON_EXTRACT(NEW.state_json, "$.distribution.duplicates.type");
            CASE type
                WHEN 0 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.duplicates.dateStart", DATE(NOW()), "$.distribution.duplicates.dateEnd", DATE(NOW()));
                WHEN 1 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.duplicates.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 WEEK)), "$.distribution.duplicates.dateEnd", DATE(NOW()));
                WHEN 2 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.duplicates.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 MONTH)), "$.distribution.duplicates.dateEnd", DATE(NOW()));
                WHEN 3 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.duplicates.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 YEAR)), "$.distribution.duplicates.dateEnd", DATE(NOW()));
                WHEN 4 THEN BEGIN
                    SELECT company_date_create INTO firstDate FROM companies WHERE type_id = 24 ORDER BY company_date_create LIMIT 1;
                    IF firstDate IS NULL
                        THEN SET firstDate = DATE(NOW());
                    END IF;
                    SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.duplicates.dateStart", DATE(firstDate), "$.distribution.duplicates.dateEnd", DATE(NOW()));
                END;
                WHEN 5 THEN SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.duplicates.dateStart", DATE(SUBDATE(NOW(), INTERVAL 1 DAY)), "$.distribution.duplicates.dateEnd", DATE(SUBDATE(NOW(), INTERVAL 1 DAY)));
                WHEN 6 THEN BEGIN
                END;
                ELSE SET NEW.state_json = JSON_SET(NEW.state_json, "$.distribution.duplicates.dateStart", DATE(NOW()), "$.distribution.duplicates.dateEnd", DATE(NOW()));
            END CASE;
        END;
    END IF;
END
$$
DELIMITER ;

CREATE TABLE `telegrams` (
  `telegram_id` int(11) NOT NULL,
  `telegram_chat_id` varchar(120) COLLATE utf8_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

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
(19, 'bank_supervisor'),
(18, 'bank_user'),
(46, 'call_answered'),
(23, 'call_back'),
(47, 'call_busy'),
(48, 'call_cancel'),
(34, 'call_dialing'),
(39, 'call_during'),
(42, 'call_error'),
(50, 'call_failed'),
(40, 'call_line_limit'),
(49, 'call_no_answer'),
(38, 'call_no_day_limit'),
(53, 'call_no_limit'),
(51, 'call_no_money'),
(45, 'call_record_file'),
(43, 'call_success'),
(52, 'call_unallocated_number'),
(33, 'call_waiting'),
(44, 'check_inn'),
(7, 'deposit'),
(37, 'difficult'),
(24, 'double'),
(21, 'file_created'),
(22, 'file_process'),
(20, 'file_reservation'),
(10, 'free'),
(4, 'get'),
(14, 'invalidate'),
(17, 'negative'),
(15, 'neutral'),
(41, 'no_money_no_limit'),
(36, 'not_dial_all'),
(35, 'not_dial_user'),
(16, 'positive'),
(5, 'post'),
(6, 'purchase'),
(9, 'reservation'),
(1, 'root'),
(8, 'sale'),
(2, 'user'),
(13, 'validate'),
(3, 'ws'),
(11, 'ИП'),
(12, 'ООО'),
(25, '–'),
(26, '––'),
(27, '–––'),
(28, '––––'),
(29, '–––––'),
(30, '––––––'),
(31, '–––––––'),
(32, '––––––––');

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
CREATE TABLE `working_statistic_companies_view` (
`company_json` json
,`company_banks` longtext
,`company_date_update` varchar(19)
,`type_id` int(11)
,`user_id` int(11)
);
CREATE TABLE `working_user_company_view` (
`user_id` int(11)
,`company_json` json
,`call_date_create` varchar(19)
);
DROP TABLE IF EXISTS `active_calls_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `active_calls_view`  AS  select `c`.`call_id` AS `call_id`,`c`.`call_internal_type_id` AS `call_internal_type_id`,`c`.`call_destination_type_id` AS `call_destination_type_id`,`u`.`user_sip` AS `user_sip`,substr(`co`.`company_phone`,2) AS `company_phone`,`u`.`user_id` AS `user_id`,`co`.`company_id` AS `company_id`,`c`.`call_api_id_internal` AS `call_api_id_internal`,`c`.`call_api_id_destination` AS `call_api_id_destination` from ((`calls` `c` join `users` `u` on((`u`.`user_id` = `c`.`user_id`))) join `companies` `co` on((`co`.`company_id` = `c`.`company_id`))) where ((`c`.`call_destination_type_id` not in (38,40,41,42,46,47,48,49,50,51,52,53)) and (`c`.`call_internal_type_id` not in (38,40,41,42,46,47,48,49,50,51,52,53))) ;
DROP TABLE IF EXISTS `banks_statistic_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `banks_statistic_view`  AS  select `banks`.`bank_id` AS `bank_id`,json_object('bank_id',`banks`.`bank_id`,'bank_name',`banks`.`bank_name`) AS `bank_json` from `banks` ;
DROP TABLE IF EXISTS `bank_cities_company_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `bank_cities_company_view`  AS  select `c`.`company_id` AS `company_id`,`bc`.`bank_id` AS `bank_id` from (`companies` `c` join `bank_cities` `bc` on((`bc`.`city_id` = `c`.`city_id`))) ;
DROP TABLE IF EXISTS `bank_cities_time_priority_companies_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `bank_cities_time_priority_companies_view`  AS  select `b`.`time_id` AS `time_id`,`t`.`time_value` AS `time_value`,`b`.`priority` AS `priority`,`r`.`region_name` AS `region_name`,`ci`.`city_name` AS `city_name`,`c`.`company_id` AS `company_id`,`c`.`user_id` AS `user_id`,`c`.`company_date_create` AS `company_date_create`,`c`.`type_id` AS `type_id`,`c`.`old_type_id` AS `old_type_id`,`c`.`company_date_update` AS `company_date_update`,`c`.`company_discount` AS `company_discount`,`c`.`company_discount_percent` AS `company_discount_percent`,`c`.`company_ogrn` AS `company_ogrn`,`c`.`company_ogrn_date` AS `company_ogrn_date`,`c`.`company_person_name` AS `company_person_name`,`c`.`company_person_surname` AS `company_person_surname`,`c`.`company_person_patronymic` AS `company_person_patronymic`,`c`.`company_person_birthday` AS `company_person_birthday`,`c`.`company_person_birthplace` AS `company_person_birthplace`,`c`.`company_inn` AS `company_inn`,`c`.`company_address` AS `company_address`,`c`.`company_doc_number` AS `company_doc_number`,`c`.`company_doc_date` AS `company_doc_date`,`c`.`company_organization_name` AS `company_organization_name`,`c`.`company_organization_code` AS `company_organization_code`,`c`.`company_phone` AS `company_phone`,`c`.`company_email` AS `company_email`,`c`.`company_okved_code` AS `company_okved_code`,`c`.`company_okved_name` AS `company_okved_name`,`c`.`purchase_id` AS `purchase_id`,`c`.`template_id` AS `template_id`,`c`.`company_kpp` AS `company_kpp`,`c`.`company_index` AS `company_index`,`c`.`company_house` AS `company_house`,`c`.`company_region_type` AS `company_region_type`,`c`.`company_region_name` AS `company_region_name`,`c`.`company_area_type` AS `company_area_type`,`c`.`company_area_name` AS `company_area_name`,`c`.`company_locality_type` AS `company_locality_type`,`c`.`company_locality_name` AS `company_locality_name`,`c`.`company_street_type` AS `company_street_type`,`c`.`company_street_name` AS `company_street_name`,`c`.`company_innfl` AS `company_innfl`,`c`.`company_person_position_type` AS `company_person_position_type`,`c`.`company_person_position_name` AS `company_person_position_name`,`c`.`company_doc_name` AS `company_doc_name`,`c`.`company_doc_gifter` AS `company_doc_gifter`,`c`.`company_doc_code` AS `company_doc_code`,`c`.`company_doc_house` AS `company_doc_house`,`c`.`company_doc_flat` AS `company_doc_flat`,`c`.`company_doc_region_type` AS `company_doc_region_type`,`c`.`company_doc_region_name` AS `company_doc_region_name`,`c`.`company_doc_area_type` AS `company_doc_area_type`,`c`.`company_doc_area_name` AS `company_doc_area_name`,`c`.`company_doc_locality_type` AS `company_doc_locality_type`,`c`.`company_doc_locality_name` AS `company_doc_locality_name`,`c`.`company_doc_street_type` AS `company_doc_street_type`,`c`.`company_doc_street_name` AS `company_doc_street_name`,`c`.`city_id` AS `city_id`,`c`.`region_id` AS `region_id`,`c`.`bank_id` AS `bank_id`,`c`.`company_date_registration` AS `company_date_registration`,`c`.`company_person_sex` AS `company_person_sex`,`c`.`company_ip_type` AS `company_ip_type`,`c`.`company_json` AS `company_json` from ((((`bank_cities_time_priority` `b` join `companies` `c` on(((`c`.`city_id` = `b`.`city_id`) and (`c`.`bank_id` = `b`.`bank_id`) and (json_unquote(json_extract(`c`.`company_json`,'$.company_id')) = `c`.`company_id`)))) join `times` `t` on((`t`.`time_id` = `b`.`time_id`))) join `cities` `ci` on((`ci`.`city_id` = `b`.`city_id`))) join `regions` `r` on((`r`.`region_id` = `c`.`region_id`))) order by `b`.`time_id`,`b`.`priority` ;
DROP TABLE IF EXISTS `bank_status_translate`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `bank_status_translate`  AS  select json_object('bank_status_id',`bs`.`bank_status_id`,'bank_status_text',if((`tr`.`translate_to` is not null),`tr`.`translate_to`,`bs`.`bank_status_text`)) AS `status_json`,`bs`.`bank_id` AS `bank_id` from (`bank_statuses` `bs` left join `translates` `tr` on((`tr`.`translate_from` = `bs`.`bank_status_text`))) ;
DROP TABLE IF EXISTS `bank_times_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `bank_times_view`  AS  select distinct `b`.`time_id` AS `time_id`,`t`.`time_value` AS `time_value`,`b`.`bank_id` AS `bank_id` from (`bank_cities_time_priority` `b` join `times` `t` on((`t`.`time_id` = `b`.`time_id`))) order by cast(`t`.`time_value` as time(6)) ;
DROP TABLE IF EXISTS `calls_file_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `calls_file_view`  AS  select `c`.`call_id` AS `call_id`,`c`.`call_internal_file_id` AS `call_internal_file_id`,`c`.`call_destination_file_id` AS `call_destination_file_id`,`inf`.`file_name` AS `internal_file_name`,`df`.`file_name` AS `destination_file_name` from ((`calls` `c` left join `files` `inf` on((`inf`.`file_id` = `c`.`call_internal_file_id`))) left join `files` `df` on((`df`.`file_id` = `c`.`call_destination_file_id`))) where ((`c`.`call_internal_file_id` is not null) or (`c`.`call_destination_file_id` is not null)) ;
DROP TABLE IF EXISTS `calls_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `calls_view`  AS  select `c`.`call_id` AS `call_id`,`c`.`call_internal_type_id` AS `call_internal_type_id`,`c`.`company_id` AS `company_id`,`c`.`user_id` AS `user_id`,`c`.`call_date_create` AS `call_date_create`,`c`.`call_internal_file_id` AS `call_internal_file_id`,`c`.`call_internal_api_id_with_rec` AS `call_internal_api_id_with_rec`,`c`.`call_date_update` AS `call_date_update`,`c`.`call_api_id_internal` AS `call_api_id_internal`,`c`.`call_api_id_destination` AS `call_api_id_destination`,`c`.`call_internal_record` AS `call_internal_record`,`c`.`call_predicted` AS `call_predicted`,`c`.`call_destination_api_id_with_rec` AS `call_destination_api_id_with_rec`,`c`.`call_destination_record` AS `call_destination_record`,`c`.`call_destination_file_id` AS `call_destination_file_id`,`c`.`call_destination_type_id` AS `call_destination_type_id`,`u`.`user_sip` AS `user_sip`,replace(`co`.`company_phone`,'+','') AS `company_phone` from ((`calls` `c` left join `users` `u` on((`u`.`user_id` = `c`.`user_id`))) left join `companies` `co` on((`co`.`company_id` = `c`.`company_id`))) ;
DROP TABLE IF EXISTS `columns_translates_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `columns_translates_view`  AS  select `c`.`column_id` AS `column_id`,if((`t`.`translate_to` is not null),`t`.`translate_to`,`c`.`column_name`) AS `translate_to`,`c`.`column_name` AS `column_name` from (`columns` `c` left join `translates` `t` on((`t`.`translate_from` = `c`.`column_name`))) ;
DROP TABLE IF EXISTS `company_banks_statuses_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `company_banks_statuses_view`  AS  select `cb`.`company_id` AS `company_id`,`cb`.`bank_id` AS `bank_id`,if((`tr`.`translate_to` is not null),`tr`.`translate_to`,`bs`.`bank_status_text`) AS `bank_status_text`,`bs`.`type_id` AS `type_id` from ((`company_banks` `cb` left join `bank_statuses` `bs` on((`cb`.`bank_status_id` = `bs`.`bank_status_id`))) left join `translates` `tr` on((`tr`.`translate_from` = `bs`.`bank_status_text`))) ;
DROP TABLE IF EXISTS `day_banks_statistic_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `day_banks_statistic_view`  AS  select `c`.`user_id` AS `user_id`,`b`.`bank_name` AS `bank_name`,count(0) AS `count` from ((`company_banks` `cb` join `companies` `c` on((`c`.`company_id` = `cb`.`company_id`))) join `banks` `b` on((`b`.`bank_id` = `cb`.`bank_id`))) where ((cast(`cb`.`company_bank_date_send` as date) = cast(now() as date)) and (`c`.`type_id` = 13) and ((`cb`.`company_bank_application_id` is not null) or (`cb`.`company_bank_request_id` is not null))) group by `c`.`user_id`,`b`.`bank_name` ;
DROP TABLE IF EXISTS `day_types_statistic_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `day_types_statistic_view`  AS  select if((`tr`.`translate_to` is not null),`tr`.`translate_to`,`tp`.`type_name`) AS `translate_to`,`u`.`user_name` AS `user_name`,`u`.`user_id` AS `user_id`,count(0) AS `count` from (((`companies` `c` left join `types` `tp` on((`tp`.`type_id` = `c`.`type_id`))) left join `translates` `tr` on((`tr`.`translate_from` = `tp`.`type_name`))) join `users` `u` on((`u`.`user_id` = `c`.`user_id`))) where (cast(`c`.`company_date_update` as date) = cast(now() as date)) group by `u`.`user_name`,`tr`.`translate_to`,`tp`.`type_id`,`u`.`user_id` ;
DROP TABLE IF EXISTS `empty_companies_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `empty_companies_view`  AS  select `companies`.`company_id` AS `company_id`,`companies`.`company_date_create` AS `company_date_create` from `companies` where (isnull(`companies`.`company_ogrn`) and isnull(`companies`.`company_ogrn_date`) and isnull(`companies`.`company_person_name`) and isnull(`companies`.`company_person_surname`) and isnull(`companies`.`company_person_patronymic`) and isnull(`companies`.`company_person_birthday`) and isnull(`companies`.`company_person_birthplace`) and isnull(`companies`.`company_inn`) and isnull(`companies`.`company_address`) and isnull(`companies`.`company_doc_number`) and isnull(`companies`.`company_doc_date`) and isnull(`companies`.`company_organization_name`) and isnull(`companies`.`company_organization_code`) and isnull(`companies`.`company_phone`) and isnull(`companies`.`company_email`) and isnull(`companies`.`company_okved_code`) and isnull(`companies`.`company_okved_name`) and isnull(`companies`.`company_kpp`) and isnull(`companies`.`company_index`) and isnull(`companies`.`company_house`) and isnull(`companies`.`company_region_type`) and isnull(`companies`.`company_region_name`) and isnull(`companies`.`company_area_type`) and isnull(`companies`.`company_area_name`) and isnull(`companies`.`company_locality_type`) and isnull(`companies`.`company_locality_name`) and isnull(`companies`.`company_street_type`) and isnull(`companies`.`company_street_name`) and isnull(`companies`.`company_innfl`) and isnull(`companies`.`company_person_position_type`) and isnull(`companies`.`company_person_position_name`) and isnull(`companies`.`company_doc_name`) and isnull(`companies`.`company_doc_gifter`) and isnull(`companies`.`company_doc_code`) and isnull(`companies`.`company_doc_house`) and isnull(`companies`.`company_doc_flat`) and isnull(`companies`.`company_doc_region_type`) and isnull(`companies`.`company_doc_region_name`) and isnull(`companies`.`company_doc_area_type`) and isnull(`companies`.`company_doc_area_name`) and isnull(`companies`.`company_doc_locality_type`) and isnull(`companies`.`company_doc_locality_name`) and isnull(`companies`.`company_doc_street_type`) and isnull(`companies`.`company_doc_street_name`) and isnull(`companies`.`company_date_registration`) and isnull(`companies`.`company_person_sex`) and isnull(`companies`.`company_ip_type`)) ;
DROP TABLE IF EXISTS `end_calls_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `end_calls_view`  AS  select `c`.`call_id` AS `call_id`,`c`.`call_internal_type_id` AS `call_internal_type_id`,`c`.`call_destination_type_id` AS `call_destination_type_id`,`u`.`user_sip` AS `user_sip`,replace(`co`.`company_phone`,'+','') AS `company_phone`,`u`.`user_id` AS `user_id`,`co`.`company_id` AS `company_id`,`c`.`call_destination_file_id` AS `call_destination_file_id`,`c`.`call_internal_file_id` AS `call_internal_file_id` from ((`calls` `c` join `users` `u` on((`u`.`user_id` = `c`.`user_id`))) join `companies` `co` on((`co`.`company_id` = `c`.`company_id`))) where ((`c`.`call_internal_type_id` in (38,40,41,42,46,47,48,49,50,51,52,53)) or (`c`.`call_destination_type_id` in (38,40,41,42,46,47,48,49,50,51,52,53))) ;
DROP TABLE IF EXISTS `nikolay_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `nikolay_view`  AS  select `c`.`company_inn` AS `инн`,`c`.`company_phone` AS `телефон`,`c`.`company_date_create` AS `дата создания`,`c`.`company_date_update` AS `дата последнего обновления`,if((`tr`.`translate_to` is not null),`tr`.`translate_to`,`t`.`type_name`) AS `статус` from ((`companies` `c` join `types` `t` on((`t`.`type_id` = `c`.`type_id`))) left join `translates` `tr` on((`tr`.`translate_from` = `t`.`type_name`))) where ((cast(`c`.`company_date_update` as date) between '2019-4-1' and '2019-4-12') and (`c`.`type_id` in (36,35,37)) and (`c`.`user_id` is not null)) ;
DROP TABLE IF EXISTS `regions_companies_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `regions_companies_view`  AS  select `c`.`company_id` AS `company_id`,`c`.`company_date_create` AS `company_date_create`,`c`.`company_date_update` AS `company_date_update`,`c`.`company_date_registration` AS `company_date_registration`,`c`.`type_id` AS `type_id`,`c`.`old_type_id` AS `old_type_id`,`c`.`user_id` AS `user_id`,json_length(json_keys(json_unquote(json_extract(`c`.`company_json`,'$.company_banks')))) AS `company_banks_length`,`r`.`region_msc_timezone` AS `region_msc_timezone`,`r`.`region_priority` AS `region_priority` from (`companies` `c` join `regions` `r` on((`r`.`region_id` = `c`.`region_id`))) ;
DROP TABLE IF EXISTS `templates_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `templates_view`  AS  select `tm`.`template_id` AS `template_id`,`tm`.`type_id` AS `type_id`,`tm`.`template_columns_count` AS `template_columns_count`,`tp`.`type_name` AS `type_name` from (`templates` `tm` join `types` `tp` on((`tp`.`type_id` = `tm`.`type_id`))) ;
DROP TABLE IF EXISTS `template_columns_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `template_columns_view`  AS  select `t`.`template_id` AS `template_id`,`tc`.`template_column_id` AS `template_column_id`,`c`.`column_id` AS `column_id`,`c`.`column_name` AS `column_name`,`c`.`column_price` AS `column_price`,`c`.`column_blocked` AS `column_blocked`,`tc`.`template_column_letters` AS `template_column_letters`,`tc`.`template_column_name` AS `template_column_name`,`ts`.`type_id` AS `type_id`,`ts`.`type_name` AS `type_name`,`tc`.`template_column_duplicate` AS `template_column_duplicate` from (((`template_columns` `tc` join `templates` `t` on((`t`.`template_id` = `tc`.`template_id`))) join `columns` `c` on((`c`.`column_id` = `tc`.`column_id`))) join `types` `ts` on((`ts`.`type_id` = `t`.`type_id`))) ;
DROP TABLE IF EXISTS `users_connections_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `users_connections_view`  AS  select `c`.`connection_id` AS `connection_id`,`c`.`connection_hash` AS `connection_hash`,`c`.`connection_end` AS `connection_end`,`c`.`connection_api_id` AS `connection_api_id`,`c`.`type_id` AS `connection_type_id`,`tt`.`type_name` AS `connection_type_name`,`u`.`user_id` AS `user_id`,`u`.`type_id` AS `type_id`,`t`.`type_name` AS `type_name`,`u`.`user_auth` AS `user_auth`,`u`.`user_online` AS `user_online`,`u`.`user_email` AS `user_email`,`u`.`bank_id` AS `bank_id`,`u`.`user_sip` AS `user_sip` from (((`connections` `c` left join `users` `u` on((`u`.`user_id` = `c`.`user_id`))) left join `types` `t` on((`t`.`type_id` = `u`.`type_id`))) left join `types` `tt` on((`tt`.`type_id` = `c`.`type_id`))) ;
DROP TABLE IF EXISTS `working_statistic_companies_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `working_statistic_companies_view`  AS  select json_object('company_organization_name',`c`.`company_organization_name`,'company_person_name',`c`.`company_person_name`,'company_person_surname',`c`.`company_person_surname`,'company_person_patronymic',`c`.`company_person_patronymic`,'company_phone',`c`.`company_phone`,'company_inn',`c`.`company_inn`,'company_date_create',`c`.`company_date_create`,'company_date_update',`c`.`company_date_update`,'translate_to',if((`tr`.`translate_to` is not null),`tr`.`translate_to`,`t`.`type_name`)) AS `company_json`,json_unquote(json_extract(`c`.`company_json`,'$.company_banks')) AS `company_banks`,`c`.`company_date_update` AS `company_date_update`,`c`.`type_id` AS `type_id`,`c`.`user_id` AS `user_id` from ((`companies` `c` join `types` `t` on((`t`.`type_id` = `c`.`type_id`))) left join `translates` `tr` on((`tr`.`translate_from` = `t`.`type_name`))) ;
DROP TABLE IF EXISTS `working_user_company_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `working_user_company_view`  AS  select `c`.`user_id` AS `user_id`,`c`.`company_json` AS `company_json`,`cl`.`call_date_create` AS `call_date_create` from (`calls` `cl` join `companies` `c` on((`c`.`call_id` = `cl`.`call_id`))) where (`c`.`company_ringing` = 0) order by `cl`.`call_date_create` desc ;


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

ALTER TABLE `bank_filials`
  ADD PRIMARY KEY (`bank_filial_id`),
  ADD KEY `bank_id` (`bank_id`),
  ADD KEY `city_id` (`city_id`),
  ADD KEY `region_id` (`region_id`);

ALTER TABLE `bank_statuses`
  ADD PRIMARY KEY (`bank_status_id`),
  ADD KEY `bank_id` (`bank_id`),
  ADD KEY `type_id` (`type_id`);

ALTER TABLE `calls`
  ADD PRIMARY KEY (`call_id`),
  ADD KEY `type_id` (`call_internal_type_id`),
  ADD KEY `company_id` (`company_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `file_id` (`call_internal_file_id`),
  ADD KEY `call_destination_file_id` (`call_destination_file_id`),
  ADD KEY `call_destination_type_id` (`call_destination_type_id`),
  ADD KEY `call_internal_file_id` (`call_internal_file_id`);

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
  ADD KEY `call_id` (`call_id`),
  ADD KEY `company_file_user` (`company_file_user`),
  ADD KEY `company_file_type` (`company_file_type`);

ALTER TABLE `company_banks`
  ADD PRIMARY KEY (`company_bank_id`),
  ADD KEY `company_id` (`company_id`),
  ADD KEY `bank_id` (`bank_id`),
  ADD KEY `bank_status_id` (`bank_status_id`);

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

ALTER TABLE `psb_codes`
  ADD PRIMARY KEY (`psb_code_id`),
  ADD KEY `city_id` (`city_id`);

ALTER TABLE `psb_filial_codes`
  ADD PRIMARY KEY (`psb_filial_code_id`),
  ADD KEY `city_id` (`city_id`);

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

ALTER TABLE `telegrams`
  ADD PRIMARY KEY (`telegram_id`);

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

ALTER TABLE `bank_filials`
  MODIFY `bank_filial_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `bank_statuses`
  MODIFY `bank_status_id` int(11) NOT NULL AUTO_INCREMENT;

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

ALTER TABLE `company_banks`
  MODIFY `company_bank_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `connections`
  MODIFY `connection_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `files`
  MODIFY `file_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `fns_codes`
  MODIFY `fns_code_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `psb_codes`
  MODIFY `psb_code_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `psb_filial_codes`
  MODIFY `psb_filial_code_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `purchases`
  MODIFY `purchase_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `regions`
  MODIFY `region_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `states`
  MODIFY `state_id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `telegrams`
  MODIFY `telegram_id` int(11) NOT NULL AUTO_INCREMENT;

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

ALTER TABLE `bank_statuses`
  ADD CONSTRAINT `bank_statuses_ibfk_1` FOREIGN KEY (`bank_id`) REFERENCES `banks` (`bank_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `bank_statuses_ibfk_2` FOREIGN KEY (`type_id`) REFERENCES `types` (`type_id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `calls`
  ADD CONSTRAINT `calls_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `calls_ibfk_2` FOREIGN KEY (`company_id`) REFERENCES `companies` (`company_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `calls_ibfk_3` FOREIGN KEY (`call_internal_type_id`) REFERENCES `types` (`type_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `calls_ibfk_4` FOREIGN KEY (`call_internal_file_id`) REFERENCES `files` (`file_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `calls_ibfk_5` FOREIGN KEY (`call_destination_file_id`) REFERENCES `files` (`file_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `calls_ibfk_6` FOREIGN KEY (`call_destination_type_id`) REFERENCES `types` (`type_id`) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE `codes`
  ADD CONSTRAINT `codes_ibfk_1` FOREIGN KEY (`region_id`) REFERENCES `regions` (`region_id`) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE `companies`
  ADD CONSTRAINT `companies_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `companies_ibfk_10` FOREIGN KEY (`call_id`) REFERENCES `calls` (`call_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `companies_ibfk_11` FOREIGN KEY (`company_file_user`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `companies_ibfk_12` FOREIGN KEY (`company_file_type`) REFERENCES `types` (`type_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `companies_ibfk_2` FOREIGN KEY (`type_id`) REFERENCES `types` (`type_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `companies_ibfk_3` FOREIGN KEY (`purchase_id`) REFERENCES `purchases` (`purchase_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `companies_ibfk_4` FOREIGN KEY (`template_id`) REFERENCES `templates` (`template_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `companies_ibfk_5` FOREIGN KEY (`city_id`) REFERENCES `cities` (`city_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `companies_ibfk_6` FOREIGN KEY (`region_id`) REFERENCES `regions` (`region_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `companies_ibfk_7` FOREIGN KEY (`bank_id`) REFERENCES `banks` (`bank_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `companies_ibfk_8` FOREIGN KEY (`file_id`) REFERENCES `files` (`file_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `companies_ibfk_9` FOREIGN KEY (`old_type_id`) REFERENCES `types` (`type_id`) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE `company_banks`
  ADD CONSTRAINT `company_banks_ibfk_1` FOREIGN KEY (`bank_id`) REFERENCES `banks` (`bank_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `company_banks_ibfk_2` FOREIGN KEY (`company_id`) REFERENCES `companies` (`company_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `company_banks_ibfk_3` FOREIGN KEY (`bank_status_id`) REFERENCES `bank_statuses` (`bank_status_id`) ON DELETE SET NULL ON UPDATE CASCADE;

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

ALTER TABLE `psb_codes`
  ADD CONSTRAINT `psb_codes_ibfk_1` FOREIGN KEY (`city_id`) REFERENCES `cities` (`city_id`) ON DELETE SET NULL ON UPDATE CASCADE;

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
