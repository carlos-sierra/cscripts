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
WHENEVER SQLERROR CONTINUE;
--
-- exit graciously if executed from CDB$ROOT
--WHENEVER SQLERROR EXIT SUCCESS;
BEGIN
  IF SYS_CONTEXT('USERENV', 'CON_NAME') = 'CDB$ROOT' THEN
    raise_application_error(-20000, 'Be aware! You are executing this script connected into CDB$ROOT.');
  END IF;
END;
/
WHENEVER SQLERROR CONTINUE;
--
SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
CL COL BRE
--
COL pdb_name NEW_V pdb_name FOR A30;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') pdb_name FROM DUAL;
--
ALTER SESSION SET container = CDB$ROOT;
--
COL owner FOR A30;
SELECT DISTINCT owner
  FROM c##iod.table_stats_hist
 WHERE pdb_name = UPPER(TRIM('&&pdb_name.'))
 ORDER BY 1
/

PRO
PRO 1. Enter Table Owner
DEF table_owner = '&1.';

COL table_name FOR A30;
SELECT DISTINCT table_name
  FROM c##iod.table_stats_hist
 WHERE pdb_name = UPPER(TRIM('&&pdb_name.'))
   AND owner = UPPER(TRIM('&&table_owner.'))
 ORDER BY 1
/

PRO
PRO 2. Enter Table Name
DEF table_name = '&2.';

COL current_time NEW_V current_time FOR A15;
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24.MI.SS') current_time FROM DUAL;
COL x_host_name NEW_V x_host_name;
SELECT host_name x_host_name FROM v$instance;
COL x_db_name NEW_V x_db_name;
SELECT name x_db_name FROM v$database;

SPO table_stats_hist_&&pdb_name..&&table_owner..&&table_name..txt;

PRO CDB: &&x_db_name.
PRO HOST: &&x_host_name.
PRO PDB: &&pdb_name.
PRO OWNER: &&table_owner.
PRO TABLE: &&table_name.
PRO

COL rows_per_block FOR 999,999,990.0

WITH
my_query AS (
SELECT last_analyzed,
       num_rows,
       blocks,
       ROUND(num_rows/blocks, 1) rows_per_block,
       avg_row_len,
       sample_size
  FROM c##iod.table_stats_hist
 WHERE pdb_name = UPPER(TRIM('&&pdb_name.'))
   AND owner = UPPER(TRIM('&&table_owner.'))
   AND table_name = UPPER(TRIM('&&table_name.'))
)
SELECT TO_CHAR(q.last_analyzed, 'YYYY-MM-DD"T"HH24:MI:SS') last_analyzed,
       q.num_rows,
       q.blocks,
       q.rows_per_block,
       q.avg_row_len,
       q.sample_size
  FROM my_query q
 ORDER BY
       q.last_analyzed
/

-- safe to do. as name implies, it flushes this table modifications from sga so we can report on them
EXEC DBMS_STATS.FLUSH_DATABASE_MONITORING_INFO;

COL hours_since_gathering HEA 'HOURS|SINCE|GATHERING';
COL num_rows FOR 999,999,990;
COL inserts FOR 999,999,990 HEA 'INSERTS|SINCE|GATHERING';
COL updates FOR 999,999,990 HEA 'UPDATES|SINCE|GATHERING';
COL deletes FOR 999,999,990 HEA 'DELETES|SINCE|GATHERING';
COL inserts_per_sec FOR 999,990.000 HEA 'INSERTS|PER SEC';
COL updates_per_sec HEA 999,990.000 HEA 'UPDATES|PER SEC';
COL deletes_per_sec HEA 999,990.000 HEA 'DELETES|PER SEC';

ALTER SESSION SET CONTAINER = &&pdb_name.;


SELECT TO_CHAR(t.last_analyzed, 'YYYY-MM-DD"T"HH24:MI:SS') last_analyzed,
       t.num_rows,
       ROUND(m.inserts / ((m.timestamp - t.last_analyzed) * 24 * 60 * 60), 3) inserts_per_sec,
       ROUND(m.updates / ((m.timestamp - t.last_analyzed) * 24 * 60 * 60), 3) updates_per_sec,
       ROUND(m.deletes / ((m.timestamp - t.last_analyzed) * 24 * 60 * 60), 3) deletes_per_sec,
       TO_CHAR(m.timestamp, 'YYYY-MM-DD"T"HH24:MI:SS') timestamp,
       ROUND((m.timestamp - t.last_analyzed) * 24, 1) hours_since_gathering,
       m.inserts,
       m.updates,
       m.deletes
  FROM dba_tables t,
       dba_tab_modifications m
 WHERE t.owner = UPPER(TRIM('&&table_owner.'))
   AND t.table_name = UPPER(TRIM('&&table_name.'))
   AND m.table_owner = t.owner
   AND m.table_name = t.table_name
/
SPO OFF;

UNDEF 1 2;
ALTER SESSION SET container = &&pdb_name.;
