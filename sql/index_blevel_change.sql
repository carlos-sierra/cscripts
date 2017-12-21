SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
CL col;
CL bre;
COL current_time NEW_V current_time FOR A15;
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;
COL x_host_name NEW_V x_host_name;
SELECT host_name x_host_name FROM v$instance;
COL x_db_name NEW_V x_db_name;
SELECT name x_db_name FROM v$database;
COL x_container NEW_V x_container;
SELECT 'NONE' x_container FROM DUAL;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') x_container FROM DUAL;
COL last_analyzed FOR A19;
COL table_index_name FOR A60 HEA 'TABLE_OWNER.TABLE_NAME|INDEX_OWNER.INDEX_NAME';
COL lag_blevel HEA 'BLEVEL|FROM';
COL blevel HEA 'BLEVEL|TO';
COL lag_leafcnt HEA 'LEAFCNT|FROM';
COL leafcnt HEA 'LEAFCNT|TO';
COL lag_rowcnt HEA 'ROWCNT|FROM';
COL rowcnt HEA 'ROWCNT|TO';
COL lag_distkey HEA 'DISTKEY|FROM';
COL distkey HEA 'DISTKEY|TO';
SPO index_blevel_change_&&current_time..txt;
PRO HOST: &&x_host_name.
PRO DATABASE: &&x_db_name.
PRO CONTAINER: &&x_container.
/****************************************************************************************/
WITH 
optstat_ind_history AS (
SELECT h.obj#,
       h.rowcnt,
       h.blevel,
       h.leafcnt,
       h.distkey,
       h.analyzetime,
       LAG(h.rowcnt) OVER (PARTITION BY h.obj# ORDER BY h.analyzetime NULLS LAST) lag_rowcnt,
       LAG(h.blevel) OVER (PARTITION BY h.obj# ORDER BY h.analyzetime NULLS LAST) lag_blevel,
       LAG(h.leafcnt) OVER (PARTITION BY h.obj# ORDER BY h.analyzetime NULLS LAST) lag_leafcnt,
       LAG(h.distkey) OVER (PARTITION BY h.obj# ORDER BY h.analyzetime NULLS LAST) lag_distkey
  FROM sys.wri$_optstat_ind_history h
),
blevel_flips AS (
SELECT o.owner,
       o.object_name,
       i.table_owner,
       i.table_name,
       h.analyzetime,
       h.blevel,
       h.lag_blevel,
       h.leafcnt,
       h.lag_leafcnt,
       h.rowcnt,
       h.lag_rowcnt,
       h.distkey,
       h.lag_distkey
  FROM optstat_ind_history h,
       dba_objects o,
       dba_users u,
       dba_indexes i
 WHERE h.blevel <> h.lag_blevel
   AND o.object_id = h.obj#
   AND o.object_type = 'INDEX' -- redundant
   AND u.username = o.owner
   AND u.oracle_maintained = 'N'
   AND i.owner = o.owner
   AND i.index_name = o.object_name
)
SELECT TO_CHAR(analyzetime, 'YYYY-MM-DD"T"HH24:MI:SS') last_analyzed,
       lag_blevel,
       blevel,
       table_owner||'.'||table_name||CHR(10)||
       owner||'.'||object_name table_index_name,
       lag_leafcnt,
       leafcnt,
       lag_rowcnt,
       rowcnt,
       lag_distkey,
       distkey
  FROM blevel_flips
 ORDER BY
       analyzetime
/
/****************************************************************************************/
SPO OFF;
