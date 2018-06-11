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
WHENEVER SQLERROR CONTINUE;

SET HEA ON LIN 1000 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;

COL kiev_tx FOR A8;
COL percent FOR 990.0;

WITH 
all_ash AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sql_id,
       COUNT(*) samples
  FROM v$active_session_history
 WHERE (session_state = 'ON CPU' OR wait_class = 'Scheduler')
   AND sql_id IS NOT NULL
 GROUP BY
       sql_id
),
kiev_sql AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       DISTINCT sql_id,
       c##iod.iod_spm.application_category(sql_text) kiev_tx
  FROM v$sql
 WHERE sql_text LIKE '/*'||CHR(37)
   AND c##iod.iod_spm.application_category(sql_text) IN ('BeginTx','CommitTx','Scan','GC')
   AND command_type NOT IN (SELECT action FROM audit_actions WHERE name IN ('PL/SQL EXECUTE', 'EXECUTE PROCEDURE'))
)
SELECT s.kiev_tx,
       ROUND(100 * SUM(a.samples) / SUM(SUM(a.samples)) OVER (),1) percent
  FROM kiev_sql s,
       all_ash a
 WHERE a.sql_id = s.sql_id
 GROUP BY
       s.kiev_tx
/