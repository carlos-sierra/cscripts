----------------------------------------------------------------------------------------
--
-- File name:   cs_drop_redef_table.sql
--
-- Purpose:     Generate commands to drop stale objects from failed Table Redefinition(s)
--
-- Author:      Carlos Sierra
--
-- Version:     2021/10/20
--
-- Usage:       Execute connected to CDB or PDB
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_drop_redef_table.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
--              Comands listed by this script must be executed manually inside corresponding PDB(s)
--
---------------------------------------------------------------------------------------
--
SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
ALTER SESSION SET "_px_cdb_view_enabled" = FALSE;
--
COL drop_commands FOR A200;
--
WITH 
users AS (
SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') MATERIALIZE NO_MERGE */ con_id, username FROM cdb_users WHERE oracle_maintained = 'N' AND common = 'NO'
)
SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') MATERIALIZE NO_MERGE */
       '/* '||c.name||' #1 '||purge_start||' '||last_purge_date||' */ DROP MATERIALIZED VIEW LOG ON "'||lg.log_owner||'"."'||lg.master||'";' drop_commands
  FROM cdb_mview_logs lg, v$containers c
 WHERE lg.log_table LIKE 'MLOG$\_'||CHR(37) ESCAPE '\'
   AND c.con_id = lg.con_id
   AND c.open_mode = 'READ WRITE'
   AND c.restricted = 'NO'
   AND (lg.con_id, lg.log_owner) IN (SELECT u.con_id, u.username FROM users u)
 UNION ALL
SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') MATERIALIZE NO_MERGE */
       '/* '||c.name||' #2 '||LAST_REFRESH_DATE||' '||LAST_REFRESH_END_TIME||' '||STALE_SINCE||' */ DROP MATERIALIZED VIEW "'||mv.owner||'"."'||mv.mview_name||'";' drop_commands
  FROM cdb_mviews mv, v$containers c
 WHERE mv.mview_name LIKE 'REDEF$\_T'||CHR(37) ESCAPE '\'
   AND c.con_id = mv.con_id
   AND c.open_mode = 'READ WRITE'
   AND c.restricted = 'NO'
   AND (mv.con_id, mv.owner) IN (SELECT u.con_id, u.username FROM users u)
 UNION ALL
SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') MATERIALIZE NO_MERGE */
       '/* '||c.name||' #3 '||last_analyzed||' */ DROP TABLE "'||tb.owner||'"."'||tb.table_name||'";' drop_commands
  FROM cdb_tables tb, v$containers c
 WHERE tb.table_name LIKE 'REDEF$\_T'||CHR(37) ESCAPE '\'
   AND c.con_id = tb.con_id
   AND c.open_mode = 'READ WRITE'
   AND c.restricted = 'NO'
   AND (tb.con_id, tb.owner) IN (SELECT u.con_id, u.username FROM users u)
 ORDER BY
       1
/
PRO
PRO Comands listed by this script must be executed manually inside corresponding PDB(s)
PRO