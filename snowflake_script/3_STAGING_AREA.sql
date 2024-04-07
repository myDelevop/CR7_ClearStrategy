USE DATABASE RONALDO;

CREATE OR REPLACE SCHEMA RONALDO.C_SA;

USE SCHEMA RONALDO.C_SA;




CREATE OR REPLACE PROCEDURE insert_ids (DATABASE string, SCHEMA string, TABLE_NAME string)
    returns string
    language javascript

    AS $$
        
        var IDS_NAME = TABLE_NAME.substring(2) + "_IDS";
        
        var sql_command_1 = "CREATE OR REPLACE SEQUENCE ids_sequence;";
        
        var sql_command_2 = "CREATE OR REPLACE TABLE IDS_TEMP LIKE ";
        var sql_command_2 = sql_command_2 + (DATABASE + "." + SCHEMA + "." + TABLE_NAME + ";");
        
        var sql_command_3 = "ALTER TABLE IDS_TEMP ADD COLUMN ids_tmp int DEFAULT ids_sequence.nextval;";
        
        var sql_command_4 = "INSERT INTO IDS_TEMP SELECT *, ids_sequence.nextval FROM ";
        var sql_command_4 = sql_command_4 + (DATABASE + "." + SCHEMA + "." + TABLE_NAME + ";");
        
        var sql_command_5 = "CREATE OR REPLACE TABLE ";
        var sql_command_5 = sql_command_5 + (DATABASE + "." + SCHEMA + "." + TABLE_NAME);        
        var sql_command_5 = sql_command_5 + " AS SELECT A.IDS_TMP AS ";
        var sql_command_5 = sql_command_5 + IDS_NAME;
        var sql_command_5 = sql_command_5 + ", A.* FROM IDS_TEMP A;";        

        var sql_command_6 = "DROP TABLE IDS_TEMP;";

        var sql_command_7 = "ALTER TABLE ";
        var sql_command_7 = sql_command_7 + (DATABASE + "." + SCHEMA + "." + TABLE_NAME);        
        var sql_command_7 = sql_command_7 + " DROP COLUMN IDS_TMP;";        

        try {
            snowflake.execute ({ sqlText: sql_command_1 });
            snowflake.execute ({ sqlText: sql_command_2 });
            snowflake.execute ({ sqlText: sql_command_3 });
            snowflake.execute ({ sqlText: sql_command_4 });
            snowflake.execute ({ sqlText: sql_command_5 });
            snowflake.execute ({ sqlText: sql_command_6 });
            snowflake.execute ({ sqlText: sql_command_7 });
            
            return "Succeeded.";
        } catch (err)  {
            return "Failed: " + err;
        }
    $$;
    

/* STEP 1: CREATION OF DIMENSIONS */

CREATE OR REPLACE TABLE S_AREA_OF_SHOT AS 
SELECT DISTINCT 
    CASE WHEN AREA_OF_SHOT LIKE '%(C)%' THEN 'C'
         WHEN AREA_OF_SHOT LIKE '%(R)%' THEN 'R'
         WHEN AREA_OF_SHOT LIKE '%(L)%' THEN 'L'
         WHEN AREA_OF_SHOT LIKE '%(RC)%' THEN 'RC'
         WHEN AREA_OF_SHOT LIKE '%(MG)%' THEN 'MG'
         WHEN AREA_OF_SHOT LIKE '%(LC)%' THEN 'LC'
     END AS AREA_OF_SHOT_CODE,
AREA_OF_SHOT AS AREA_OF_SHOT_DESCRIPTION
FROM RONALDO.B_CLEANING.T_CR7_CLEANING
WHERE AREA_OF_SHOT IS NOT NULL;

CALL INSERT_IDS('RONALDO', 'C_SA', 'S_AREA_OF_SHOT');
INSERT INTO S_AREA_OF_SHOT VALUES (-1, 'N/A', 'N/A');


CREATE OR REPLACE TABLE S_SHOT_BASICS AS 
SELECT DISTINCT 
    CASE WHEN SHOT_BASICS = 'Penalty Spot' THEN 'PS'
         WHEN SHOT_BASICS = 'Right Corner' THEN 'RC'
         WHEN SHOT_BASICS = 'Goal Area' THEN 'GA'
         WHEN SHOT_BASICS = 'Mid Range' THEN 'MR'
         WHEN SHOT_BASICS = 'Goal Line' THEN 'GL'
         WHEN SHOT_BASICS = 'Mid Ground Line' THEN 'MGL'
         WHEN SHOT_BASICS = 'Left Corner' THEN 'LC'
     END AS SHOT_BASICS_CODE,
SHOT_BASICS AS SHOT_BASICS_DESCRIPTION
FROM RONALDO.B_CLEANING.T_CR7_CLEANING
WHERE SHOT_BASICS IS NOT NULL;

CALL INSERT_IDS('RONALDO', 'C_SA', 'S_SHOT_BASICS');
INSERT INTO S_SHOT_BASICS VALUES (-1, 'N/A', 'N/A');



CREATE OR REPLACE TABLE S_TEAM AS
SELECT DISTINCT TEAM_HOME AS TEAM_ABBR,
    B.TEAM_NAME
FROM RONALDO.B_CLEANING.T_CR7_CLEANING A
LEFT JOIN RONALDO.A_IMPORT.M_TEAM_NAMES B
ON A.TEAM_HOME = B.ABBREVIATION
UNION
SELECT DISTINCT TEAM_AWAY AS TEAM_ABBR,
    B.TEAM_NAME
FROM RONALDO.B_CLEANING.T_CR7_CLEANING A
LEFT JOIN RONALDO.A_IMPORT.M_TEAM_NAMES B
ON A.TEAM_AWAY = B.ABBREVIATION;

CALL INSERT_IDS('RONALDO', 'C_SA', 'S_TEAM');
INSERT INTO S_TEAM VALUES (-1, 'N/A', 'N/A');




CREATE OR REPLACE TABLE S_TYPE_OF_SHOT AS
SELECT DISTINCT TYPE_OF_SHOT, TYPE_OF_SHOT_NUM, IS_COMBINED
FROM RONALDO.B_CLEANING.T_CR7_CLEANING;

CALL INSERT_IDS('RONALDO', 'C_SA', 'S_TYPE_OF_SHOT');
INSERT INTO S_TYPE_OF_SHOT VALUES (-1, 'N/A', -1, -1);



CREATE OR REPLACE TABLE S_GAME_SEASON AS
SELECT DISTINCT GAME_SEASON,
    CAST(SUBSTR(GAME_SEASON, 0, 4) AS NUMBER) AS FIRST_YEAR,
    FIRST_YEAR + 1 AS LAST_YEAR
FROM RONALDO.B_CLEANING.T_CR7_CLEANING;

CALL INSERT_IDS('RONALDO', 'C_SA', 'S_GAME_SEASON');
INSERT INTO S_GAME_SEASON VALUES (-1, 'N/A', -1, -1);



CREATE OR REPLACE TABLE S_MATCH AS
SELECT DISTINCT MATCH_ID,
    B.TEAM_IDS AS TEAM_HOME_IDS,
    B.TEAM_ABBR AS TEAM_HOME_ABBR,
    B.TEAM_NAME AS TEAM_HOME_NAME,
    C.TEAM_IDS AS TEAM_AWAY_IDS,
    C.TEAM_ABBR AS TEAM_AWAY_ABBR,
    C.TEAM_NAME AS TEAM_AWAY_NAME
FROM RONALDO.B_CLEANING.T_CR7_CLEANING A
LEFT JOIN S_TEAM B
ON A.TEAM_HOME = B.TEAM_ABBR
    LEFT JOIN S_TEAM C
    ON A.TEAM_AWAY = C.TEAM_ABBR;

CALL INSERT_IDS('RONALDO', 'C_SA', 'S_MATCH');
INSERT INTO S_MATCH VALUES (-1, -1, -1, 'N/A', 'N/A', -1, 'N/A', 'N/A');


-- RANGE OF SHOT, DATE OF GAME
CREATE OR REPLACE TABLE SF_RONALDO_SHOTS AS
SELECT DISTINCT 
    CASE WHEN B.MATCH_IDS IS NULL THEN -1 ELSE B.MATCH_IDS END AS MATCH_IDS,
    CASE WHEN C.GAME_SEASON_IDS IS NULL THEN -1 ELSE C.GAME_SEASON_IDS END AS GAME_SEASON_IDS,
    CASE WHEN D.AREA_OF_SHOT_IDS IS NULL THEN -1 ELSE D.AREA_OF_SHOT_IDS END AS AREA_OF_SHOT_IDS,
    CASE WHEN E.SHOT_BASICS_IDS IS NULL THEN -1 ELSE E.SHOT_BASICS_IDS END AS SHOT_BASICS_IDS,
    CASE WHEN F.TYPE_OF_SHOT_IDS IS NULL THEN -1 ELSE F.TYPE_OF_SHOT_IDS END AS TYPE_OF_SHOT_IDS,
    DATE_OF_GAME,
    POWER_OF_SHOT,
    LATITUDE,
    LONGITUDE,
    KNOCKOUT_MATCH,
    DISTANCE_OF_SHOT,
    IS_GOAL
FROM RONALDO.B_CLEANING.T_CR7_CLEANING A
LEFT JOIN S_MATCH B
ON A.MATCH_ID = B.MATCH_ID
    LEFT JOIN S_GAME_SEASON C
    ON A.GAME_SEASON = C.GAME_SEASON
        LEFT JOIN S_AREA_OF_SHOT D
        ON A.AREA_OF_SHOT = D.AREA_OF_SHOT_DESCRIPTION
            LEFT JOIN S_SHOT_BASICS E
            ON A.SHOT_BASICS = E.SHOT_BASICS_DESCRIPTION
                LEFT JOIN S_TYPE_OF_SHOT F
                ON A.TYPE_OF_SHOT = F.TYPE_OF_SHOT
                AND A.IS_COMBINED = F.IS_COMBINED;