WHENEVER SQLERROR EXIT FAILURE;

/* ------------------------------------------------------------------------------------ */

-- sql_plan_baseline_hist
-- create repository, partitioned and compressed
-- code preserves 2 months of data
DECLARE
  l_exists NUMBER;
  l_sql_statement VARCHAR2(32767) := q'[
CREATE TABLE &&1..sql_plan_baseline_hist (
  -- soft PK
  con_id                         NUMBER,
  sql_id                         VARCHAR2(13),
  snap_id                        NUMBER,
  snap_time                      DATE,
  -- columns
  plan_hash_value                NUMBER,
  plan_hash_2                    NUMBER,
  plan_hash_full                 NUMBER,
  plan_id                        NUMBER,
  src                            VARCHAR2(3),
  parsing_schema_name            VARCHAR2(30),
  signature                      NUMBER,
  sql_profile_name               VARCHAR2(30),
  sql_patch_name                 VARCHAR2(30),
  sql_handle                     VARCHAR2(20),
  spb_plan_name                  VARCHAR2(30),
  spb_description                VARCHAR2(500),
  spb_created                    DATE,
  spb_last_modified              DATE,
  spb_enabled                    VARCHAR2(3),
  spb_accepted                   VARCHAR2(3),
  spb_fixed                      VARCHAR2(3),
  spb_reproduced                 VARCHAR2(3),
  optimizer_cost                 NUMBER,
  executions                     NUMBER,
  elapsed_time                   NUMBER,
  cpu_time                       NUMBER,
  buffer_gets                    NUMBER,
  disk_reads                     NUMBER,
  rows_processed                 NUMBER,
  pdb_name                       VARCHAR2(128),
  -- zapper
  zapper_aggressiveness          NUMBER,
  zapper_action                  VARCHAR2(8), -- [LOADED|DISABLED|FIXED|NULL]
  zapper_message1                VARCHAR2(256),
  zapper_message2                VARCHAR2(256),
  zapper_message3                VARCHAR2(256),
  zapper_report                  CLOB
)
PARTITION BY RANGE (snap_time)
INTERVAL (NUMTOYMINTERVAL(1,'MONTH'))
(
PARTITION before_2018_10_01 VALUES LESS THAN (TO_DATE('2018-10-01', 'YYYY-MM-DD'))
)
ROW STORE COMPRESS ADVANCED
TABLESPACE USERS
]';
BEGIN
  SELECT COUNT(*) INTO l_exists FROM dba_tables WHERE owner = UPPER(TRIM('&&1.')) AND table_name = UPPER('sql_plan_baseline_hist');
  IF l_exists = 0 THEN
    EXECUTE IMMEDIATE l_sql_statement;
  END IF;
END;
/

/* ------------------------------------------------------------------------------------ */
