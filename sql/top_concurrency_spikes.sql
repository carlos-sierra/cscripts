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

SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;

COL cdb FOR A50;
PRO
SELECT LOWER(name)||'_'||LOWER(REPLACE(SUBSTR(host_name, 1 + INSTR(host_name, '.', 1, 2), 30), '.', '_')) cdb, host_name FROM v$database, v$instance
/
PRO

COL sample_date FOR A12;
COL sample_time FOR A12;
COL sessions HEA 'SESSIONS|WAITING ON|CONCURRENCY';
COL top_n FOR 99999;

BREAK ON sample_date SKIP PAGE;

PRO
WITH 
concurrency_samples AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.sample_time,
       COUNT(*) sessions,
       ROW_NUMBER () OVER (ORDER BY COUNT(*) DESC, h.sample_time) top_n
  FROM dba_hist_active_sess_history h
 WHERE h.wait_class = 'Concurrency'
 GROUP BY
       h.sample_time
HAVING COUNT(*) > 72
)
SELECT TO_CHAR(s.sample_time, 'YYYY-MM-DD') sample_date,
       TO_CHAR(s.sample_time, 'HH24:MI:SS') sample_time,
       s.sessions,
       s.top_n
  FROM concurrency_samples s
 WHERE s.top_n <= 20
 ORDER BY
       1, 2
/
PRO

CLEAR BREAK;