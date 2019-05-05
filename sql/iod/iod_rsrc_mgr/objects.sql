WHENEVER SQLERROR EXIT FAILURE;

-- create repository with plan configuration parameters
DECLARE
  l_exists NUMBER;
  l_sql_statement VARCHAR2(32767) := q'[
CREATE TABLE &&1..rsrc_mgr_plan_config (
  plan                           VARCHAR2(128),
  shares_autotask                NUMBER,
  shares_default                 NUMBER,
  shares_pdb_cap                 NUMBER,
  utilization_limit_autotask     NUMBER,
  utilization_limit_default      NUMBER,
  utilization_limit_pdb_cap      NUMBER,
  parallel_server_limit_autotask NUMBER,
  parallel_server_limit_default  NUMBER,
  parallel_server_imit_pdb_cap   NUMBER
)
TABLESPACE IOD
]';
  l_sql_statement2 VARCHAR2(32767) := q'[
INSERT INTO &&1..rsrc_mgr_plan_config (plan) VALUES ('IOD_CDB_PLAN')
]';
BEGIN
  SELECT COUNT(*) INTO l_exists FROM dba_tables WHERE owner = UPPER(TRIM('&&1.')) AND table_name = UPPER('rsrc_mgr_plan_config');
  IF l_exists = 0 THEN
    EXECUTE IMMEDIATE l_sql_statement;
    EXECUTE IMMEDIATE l_sql_statement2;   
    COMMIT; 
  END IF;
END;
/

SET LONG 40000;
SET LONGC 400 ;
SET PAGES 100;
SET LINE 200;
SET HEA OFF;
SELECT DBMS_METADATA.GET_DDL('TABLE', UPPER('rsrc_mgr_plan_config'), UPPER('&&1.')) rsrc_mgr_plan_config FROM DUAL
/
SET HEA ON;
SELECT * FROM &&1..rsrc_mgr_plan_config
/

/* ------------------------------------------------------------------------------------ */

-- create repository with pdb configuration parameters
DECLARE
  l_exists NUMBER;
  l_sql_statement VARCHAR2(32767) := q'[
CREATE TABLE &&1..rsrc_mgr_pdb_config (
  plan                           VARCHAR2(128),
  pdb_name                       VARCHAR2(128),
  shares                         NUMBER,
  utilization_limit              NUMBER,
  parallel_server_limit          NUMBER
)
TABLESPACE IOD
]';
  l_sql_statement2 VARCHAR2(32767) := q'[
ALTER TABLE &&1..rsrc_mgr_pdb_config ADD (
  end_date                       DATE
)
]';
  l_sql_statement3 VARCHAR2(32767) := q'[
UPDATE &&1..rsrc_mgr_pdb_config SET end_date = SYSDATE + 7 WHERE end_date IS NULL
]';
BEGIN
  SELECT COUNT(*) INTO l_exists FROM dba_tables WHERE owner = UPPER(TRIM('&&1.')) AND table_name = UPPER('rsrc_mgr_pdb_config');
  IF l_exists = 0 THEN
    EXECUTE IMMEDIATE l_sql_statement;
  END IF;
  SELECT COUNT(*) INTO l_exists FROM dba_tab_columns WHERE owner = UPPER(TRIM('&&1.')) AND table_name = UPPER('rsrc_mgr_pdb_config') AND column_name = UPPER('end_date');
  IF l_exists = 0 THEN
    EXECUTE IMMEDIATE l_sql_statement2;
    EXECUTE IMMEDIATE l_sql_statement3;    
  END IF;
END;
/

SET LONG 40000;
SET LONGC 400 ;
SET PAGES 100;
SET LINE 200;
SET HEA OFF;
SELECT DBMS_METADATA.GET_DDL('TABLE', UPPER('rsrc_mgr_pdb_config'), UPPER('&&1.')) rsrc_mgr_pdb_config FROM DUAL
/
SET HEA ON;
COL plan FOR A30;
COL pdb_name FOR A30;
SELECT * FROM &&1..rsrc_mgr_pdb_config
/

/* ------------------------------------------------------------------------------------ */

-- rsrc_mgr_pdb_hist
-- create repository, partitioned and compressed
-- code preserves 2 months of data
DECLARE
  l_exists NUMBER;
  l_sql_statement VARCHAR2(32767) := q'[
CREATE TABLE &&1..rsrc_mgr_pdb_hist (
  plan                           VARCHAR2(128),
  pdb_name                       VARCHAR2(128),
  shares                         NUMBER,
  utilization_limit              NUMBER,
  parallel_server_limit          NUMBER,
  aas_p99                        NUMBER,
  aas_p95                        NUMBER,
  snap_time                      DATE,
  con_id                         NUMBER
)
PARTITION BY RANGE (snap_time)
INTERVAL (NUMTOYMINTERVAL(1,'MONTH'))
(
PARTITION before_2018_04_01 VALUES LESS THAN (TO_DATE('2018-04-01', 'YYYY-MM-DD'))
)
ROW STORE COMPRESS ADVANCED
TABLESPACE IOD
]';
BEGIN
  SELECT COUNT(*) INTO l_exists FROM dba_tables WHERE owner = UPPER(TRIM('&&1.')) AND table_name = UPPER('rsrc_mgr_pdb_hist');
  IF l_exists = 0 THEN
    EXECUTE IMMEDIATE l_sql_statement;
  END IF;
END;
/

SET LONG 40000;
SET LONGC 400 ;
SET PAGES 100;
SET LINE 200;
SET HEA OFF;
SELECT DBMS_METADATA.GET_DDL('TABLE', UPPER('rsrc_mgr_pdb_hist'), UPPER('&&1.')) rsrc_mgr_pdb_hist FROM DUAL
/
SET HEA ON;

/* ------------------------------------------------------------------------------------ */
