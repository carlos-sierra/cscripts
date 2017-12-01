SET PAGES 100 LIN 300
SPO tabls_stats_hist_&&table_owner._&&table_name..txt;
SELECT TO_CHAR(h.analyzetime, 'YYYY-MM-DD"T"HH24:MI:SS') last_analyzed,
       h.rowcnt,
       h.samplesize,
       h.blkcnt,
       h.avgrln
  FROM sys.wri$_optstat_tab_history h,
       dba_objects o
 WHERE o.owner = UPPER(TRIM('&&table_owner.'))
   AND o.object_name = UPPER(TRIM('&&table_name.'))
   AND o.object_type = 'TABLE'
   AND o.object_id = h.obj#
 ORDER BY h.analyzetime
/
SPO OFF;