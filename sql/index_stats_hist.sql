SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
SPO index_stats_hist_&&table_owner._&&table_name..txt;
BREAK ON index_name SKIP PAGE;
COL index_name FORMAT A30;
SELECT i.index_name,
       TO_CHAR(h.analyzetime, 'YYYY-MM-DD"T"HH24:MI:SS') last_analyzed,
       h.blevel,
       h.leafcnt,
       h.rowcnt,
       h.samplesize,
       h.distkey
  FROM sys.wri$_optstat_ind_history h,
       dba_objects o,
       dba_indexes i
 WHERE o.object_id = h.obj#
   AND o.object_type = 'INDEX'
   AND i.owner = o.owner
   AND i.index_name = o.object_name
   AND i.table_owner = UPPER(TRIM('&&table_owner.'))
   AND i.table_name = UPPER(TRIM('&&table_name.'))
 ORDER BY
       i.index_name,
       h.analyzetime
/
SPO OFF;
