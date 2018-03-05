SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;

SPO table_stats_hist_&&table_owner._&&table_name..txt;
SELECT TO_CHAR(h.analyzetime, 'YYYY-MM-DD"T"HH24:MI:SS') last_analyzed,
       h.blkcnt,
       h.rowcnt,
       h.samplesize,
       h.avgrln
  FROM sys.wri$_optstat_tab_history h,
       dba_objects o
 WHERE o.object_id = h.obj#
   AND o.owner = UPPER(TRIM('&&table_owner.'))
   AND o.object_name = UPPER(TRIM('&&table_name.'))
   AND o.object_type = 'TABLE'
 ORDER BY 
       h.analyzetime DESC
/

SELECT TO_CHAR(last_analyzed, 'YYYY-MM-DD"T"HH24:MI:SS') last_analyzed,
       blocks,
       num_rows,
       sample_size,
       avg_row_len
  FROM dba_tables
 WHERE owner = UPPER(TRIM('&&table_owner.'))
   AND table_name = UPPER(TRIM('&&table_name.'))
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

SELECT TO_CHAR(t.last_analyzed, 'YYYY-MM-DD"T"HH24:MI:SS') last_analyzed,
       t.num_rows,
       TO_CHAR(m.timestamp, 'YYYY-MM-DD"T"HH24:MI:SS') timestamp,
       ROUND((m.timestamp - t.last_analyzed) * 24, 1) hours_since_gathering,
       m.inserts,
       m.updates,
       m.deletes,
       ROUND(m.inserts / ((m.timestamp - t.last_analyzed) * 24 * 60 * 60), 3) inserts_per_sec,
       ROUND(m.updates / ((m.timestamp - t.last_analyzed) * 24 * 60 * 60), 3) updates_per_sec,
       ROUND(m.deletes / ((m.timestamp - t.last_analyzed) * 24 * 60 * 60), 3) deletes_per_sec
  FROM dba_tables t,
       dba_tab_modifications m
 WHERE t.owner = UPPER(TRIM('&&table_owner.'))
   AND t.table_name = UPPER(TRIM('&&table_name.'))
   AND m.table_owner = t.owner
   AND m.table_name = t.table_name
/

SPO OFF;
UNDEF table_owner table_name
