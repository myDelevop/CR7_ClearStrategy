USE DATABASE RONALDO;

CREATE OR REPLACE SCHEMA RONALDO.A_IMPORT;

USE SCHEMA RONALDO.A_IMPORT;


CREATE OR REPLACE TABLE tt_cr7_import (
    id numeric primary key,
    match_event_id numeric,
    location_x numeric,
    location_y numeric,
    remaining_min smallint,
    power_of_shot tinyint,
    knockout_match tinyint,
    game_season varchar(10),
    remaining_sec smallint,
    distance_of_shot tinyint,
    is_goal tinyint,
    area_of_shot varchar(60),
    shot_basics varchar(60),
    range_of_shot varchar(60),
    team_name varchar(60),
    date_of_game date,
    home_away varchar(60),
    shot_id_number numeric,
    lat_lng varchar(240),
    type_of_shot varchar(60),
    type_of_combined_shot varchar(60),
    match_id numeric,
    team_id numeric,
    remaining_min_1 smallint,
    power_of_shot_1 tinyint,
    knockout_match_1 tinyint,
    remaining_sec_1 smallint,
    distance_of_shot_1 tinyint
);


CREATE OR REPLACE TABLE m_team_names (
    abbreviation varchar(4) primary key,
    team_name varchar(50)
);

CREATE OR REPLACE TABLE m_final_predictions (
    type_of_shot number,
    distance_of_shot number,
    power_of_shot number,
    is_goal tinyint
);

CREATE OR REPLACE FILE FORMAT csv_file_format
TYPE = csv
FIELD_DELIMITER = ','
SKIP_HEADER = 1
NULL_IF = ('NULL', 'null')
EMPTY_FIELD_AS_NULL = true
FIELD_OPTIONALLY_ENCLOSED_BY = '"';

CREATE OR REPLACE STAGE cr7_stage
file_format = csv_file_format;

list @cr7_stage;

// do this using snowsql -a RV36350.europe-west2.gcp -u rcaliandro
//put file://C:\Users\rocco\Documents\colloqui\ClearStrategy\CR7_project\yds_data.csv @cr7_stage;
//put file://C:\Users\rocco\Documents\colloqui\ClearStrategy\CR7_project\teamNames.csv @cr7_stage;
//put file://C:\Users\rocco\Documents\colloqui\ClearStrategy\CR7_project\predictions\final_predictions.csv @cr7_stage;

list @cr7_stage;

// should be already empty
truncate table TT_CR7_IMPORT;
truncate table M_TEAM_NAMES;
truncate table M_FINAL_PREDICTIONS;

copy into TT_CR7_IMPORT from @cr7_stage/yds_data.csv;
copy into M_TEAM_NAMES from @cr7_stage/teamNames.csv;
copy into M_FINAL_PREDICTIONS from @cr7_stage/final_predictions.csv;
