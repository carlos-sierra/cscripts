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
       h.analyzetime
/
SPO OFF;
UNDEF table_owner table_name