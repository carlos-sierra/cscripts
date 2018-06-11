SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;

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
WHENEVER SQLERROR EXIT FAILURE;
BEGIN
  IF SYS_CONTEXT('USERENV', 'CON_NAME') = 'CDB$ROOT' THEN
    raise_application_error(-20000, 'Must execute from a PDB');
  END IF;
END;
/
WHENEVER SQLERROR CONTINUE;

COL owner FOR A30;
SELECT DISTINCT o.owner
  FROM sys.wri$_optstat_tab_history h,
       dba_objects o
 WHERE h.analyzetime IS NOT NULL
   AND h.flags > 0
   AND o.object_id = h.obj#
   AND o.object_type = 'TABLE'
 ORDER BY 
       1
/

PRO
PRO 1. Enter Table Owner
DEF owner = '&1.';

COL table_name FOR A30;
SELECT DISTINCT object_name table_name
  FROM sys.wri$_optstat_tab_history h,
       dba_objects o
 WHERE h.analyzetime IS NOT NULL
   AND h.flags > 0
   AND o.object_id = h.obj#
   AND o.owner = UPPER(TRIM('&&owner.'))
   AND o.object_type = 'TABLE'
 ORDER BY 
       1
/

PRO
PRO 2. Enter Table Name
DEF table_name = '&2.';

SPO table_stats_hist_&&owner..&&table_name..txt;
PRO
PRO table_stats_hist_&&owner..&&table_name..txt;
PRO
PRO SQL> @table_stats_hist_report_pdb.sql "&&owner." "&&table_name."
PRO
PRO OWNER: &&owner.
PRO TABLE: &&table_name.
PRO

SELECT TO_CHAR(h.analyzetime, 'YYYY-MM-DD"T"HH24:MI:SS') last_analyzed,
       h.rowcnt,
       h.blkcnt,
       --h.samplesize,
       h.avgrln
  FROM sys.wri$_optstat_tab_history h,
       dba_objects o
 WHERE h.analyzetime IS NOT NULL
   AND h.flags > 0
   AND o.object_id = h.obj#
   AND o.owner = UPPER(TRIM('&&owner.'))
   AND o.object_name = UPPER(TRIM('&&table_name.'))
   AND o.object_type = 'TABLE'
 ORDER BY 
       h.analyzetime
/

SELECT TO_CHAR(last_analyzed, 'YYYY-MM-DD"T"HH24:MI:SS') last_analyzed,
       num_rows,
       blocks,
       --sample_size,
       avg_row_len
  FROM dba_tables
 WHERE owner = UPPER(TRIM('&&owner.'))
   AND table_name = UPPER(TRIM('&&table_name.'))
/

-- safe to do. as name implies, it flushes this table modifications from sga so we can report on them
EXEC DBMS_STATS.FLUSH_DATABASE_MONITORING_INFO;

COL hours_since_gathering HEA 'HOURS|SINCE|GATHERING';
COL num_rows FOR 999,999,999,990;
COL inserts_per_day FOR 999,999,990 HEA 'INSERTS|PER DAY';
COL updates_per_day FOR 999,999,990 HEA 'UPDATES|PER DAY';
COL deletes_per_day FOR 999,999,990 HEA 'DELETES|PER DAY';
COL growth_per_day FOR 999,999,990 HEA 'GROWTH|PER_DAY';
COL percent FOR 9,990.0 HEA 'PERCENT|PER_DAY';

SELECT DISTINCT
       t.num_rows,
       ROUND((m.inserts - m.deletes) / (m.timestamp - t.last_analyzed)) growth_per_day,
       ROUND(100 * (m.inserts - m.deletes) / (m.timestamp - t.last_analyzed) / t.num_rows, 1) percent,
       ROUND(m.inserts / (m.timestamp - t.last_analyzed)) inserts_per_day,
       ROUND(m.updates / (m.timestamp - t.last_analyzed)) updates_per_day,
       ROUND(m.deletes / (m.timestamp - t.last_analyzed)) deletes_per_day,
       TO_CHAR(t.last_analyzed, 'YYYY-MM-DD"T"HH24:MI:SS') last_analyzed,
       TO_CHAR(m.timestamp, 'YYYY-MM-DD"T"HH24:MI:SS') timestamp,
       ROUND((m.timestamp - t.last_analyzed) * 24, 1) hours_since_gathering
  FROM dba_tables t,
       dba_tab_modifications m
 WHERE t.owner = UPPER(TRIM('&&owner.'))
   AND t.table_name = UPPER(TRIM('&&table_name.'))
   AND m.table_owner = t.owner
   AND m.table_name = t.table_name
/

PRO
PRO table_stats_hist_&&owner..&&table_name..txt;
PRO
SPO OFF;
UNDEF 1 2 table_owner table_name
