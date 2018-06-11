----------------------------------------------------------------------------------------
--
-- File name:   purge_hvc.sql (OEM IOD_REPEATING_PURGE_HIGH_VERSIONCOUNT_SQL)
--
-- Purpose:     Purges Cursors with 100 or more Obsolete Child Cursors
--              Many of these are due to bug 22994542
--
-- Author:      Ashish Shanbhag and Carlos Sierra 
--
-- Version:     2018/05/07
--
-- Usage:       Execute connected into CDB (or OEM)
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @purge_hvc.sql
--
-- Notes:       Includes SYS Cursors.
--              Sleeps 1s between consecutive Purge Cursor opers (reduce LC contention)
--              Executes for 1h then stops
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
    raise_application_error(-20000, 'Must execute on PRIMARY');
  END IF;
END;
/
WHENEVER SQLERROR EXIT FAILURE;
--
SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
SET SERVEROUT ON;
DECLARE
  l_count NUMBER := 0;
  l_cursors NUMBER := 0;
  l_prior_sql_id VARCHAR2(13) := 'xxxxxxxxxxxxx';
  l_sqls NUMBER := 0;
  l_timeout DATE := SYSDATE + (1/24); -- 1h
BEGIN
  DBMS_OUTPUT.PUT_LINE(TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')||' begin');
  DBMS_OUTPUT.PUT_LINE('timeout:'||TO_CHAR(l_timeout, 'YYYY-MM-DD"T"HH24:MI:SS'));
  FOR i IN (SELECT sql_id, address, hash_value,
                   COUNT(*) cursors, COUNT(DISTINCT con_id) pdbs, COUNT(DISTINCT plan_hash_value) plans,
                   SUBSTR(sql_text, 1, 100) sql_text_100
              FROM v$sql
             WHERE is_obsolete = 'Y'
             GROUP BY sql_id, address, hash_value, SUBSTR(sql_text, 1, 100)
            HAVING COUNT(*) > 99
             ORDER BY sql_id, address, hash_value)
  LOOP
    IF SYSDATE + (1/1440) >= l_timeout THEN EXIT; END IF; -- exits 1m before timeout of 1h (for ease of 1h OEM scheduling)
    DBMS_OUTPUT.PUT_LINE(TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')||' sql_id:'||i.sql_id||' address:'||i.address||' hash_value:'||i.hash_value||' cursors:'||i.cursors||' pdbs:'||i.pdbs||' plans:'||i.plans||' '||i.sql_text_100);
    BEGIN
      DBMS_SHARED_POOL.PURGE(i.address||','||i.hash_value, 'c');
      l_count := l_count + 1;
      l_cursors := l_cursors + i.cursors;
      IF i.sql_id <> l_prior_sql_id THEN l_sqls := l_sqls + 1; END IF;
      l_prior_sql_id := i.sql_id;
      DBMS_LOCK.SLEEP(1); -- pause for 1s (to reduce Library Cache contention)
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('*** '||SQLERRM);
    END;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('count:'||l_count||' cursors:'||l_cursors||' sql_ids:'||l_sqls);
  DBMS_OUTPUT.PUT_LINE(TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')||' end');
END;
/

