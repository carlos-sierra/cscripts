----------------------------------------------------------------------------------------
--
-- File name:   OEM IOD_REPEATING_SGASTAT
--
-- Purpose:     Collect subset of v$sgastat (dba_hist_sqlstat is bogus)
--
-- Frequency:   Every 15 minutes
--
-- Author:      Carlos Sierra
--
-- Version:     2019/02/04
--
-- Usage:       Execute connected into CDB 
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @IOD_REPEATING_SGASTAT.sql
--
-- Notes:       Collected data is used by cs_sgstat* and cs_shared_pool* scripts to
--              report and chart SGA and Shared Pool sizes over time.
--
---------------------------------------------------------------------------------------
--
-- exit graciously if executed on standby
WHENEVER SQLERROR EXIT SUCCESS;
DECLARE
  l_open_mode VARCHAR2(20);
BEGIN
  SELECT open_mode INTO l_open_mode FROM v$database;
  IF l_open_mode <> 'READ WRITE' THEN
    raise_application_error(-20000, 'Not PRIMARY');
  END IF;
END;
/
-- exit not graciously if any error
WHENEVER SQLERROR EXIT FAILURE;
--
DECLARE
  l_exists NUMBER;
  l_sql_statement VARCHAR2(32767) := q'[
CREATE TABLE c##iod.iod_sgastat (
pool VARCHAR(16), name VARCHAR2(32), bytes NUMBER, snap_time DATE
)
PARTITION BY RANGE (snap_time)
INTERVAL (NUMTOYMINTERVAL(1,'MONTH'))
(
PARTITION before_2018_12_01 VALUES LESS THAN (TO_DATE('2018-12-01', 'YYYY-MM-DD')),
PARTITION before_2019_01_01 VALUES LESS THAN (TO_DATE('2019-01-01', 'YYYY-MM-DD'))
)
ROW STORE COMPRESS ADVANCED
TABLESPACE IOD
]';
BEGIN
  SELECT COUNT(*) INTO l_exists FROM dba_tables WHERE owner = 'C##IOD' AND table_name = 'IOD_SGASTAT';
  IF l_exists = 0 THEN
    EXECUTE IMMEDIATE l_sql_statement;
  END IF;
END;
/    
--
INSERT INTO c##iod.iod_sgastat (pool, name, bytes, snap_time)
SELECT pool, name, SUM(bytes), SYSDATE
  FROM v$sgastat
 WHERE pool IS NULL 
    OR name = 'free memory'
    OR name IN ('SQLA', 'KGLH0', 'KGLHD', 'db_block_hash_buckets', 'KQR X SO', 'KGLDA', 'SQLP', 'KQR L PO', 'kglsim object batch', 'KGLS', 'Result Cache', 'PDBHP')
 GROUP BY
       pool, name
 UNION ALL
SELECT pool, NULL name, SUM(bytes), SYSDATE
  FROM v$sgastat
 WHERE pool IS NOT NULL
 GROUP BY
       pool
 ORDER BY
       1 NULLS FIRST, 2 NULLS FIRST
/
COMMIT;
--
DECLARE
  l_high_value DATE;
BEGIN
  FOR i IN (
    SELECT partition_name, high_value, blocks
      FROM dba_tab_partitions
     WHERE table_owner = 'C##IOD'
       AND table_name = 'IOD_SGASTAT'
     ORDER BY
           partition_name
  )
  LOOP
    EXECUTE IMMEDIATE 'SELECT '||i.high_value||' FROM DUAL' INTO l_high_value;
    IF l_high_value <= ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -2) THEN
      EXECUTE IMMEDIATE q'[ALTER TABLE c##iod.iod_sgastat SET INTERVAL (NUMTOYMINTERVAL(1,'MONTH'))]';
      EXECUTE IMMEDIATE 'ALTER TABLE c##iod.iod_sgastat DROP PARTITION '||i.partition_name;
    END IF;
  END LOOP;
END;
/
--
---------------------------------------------------------------------------------------