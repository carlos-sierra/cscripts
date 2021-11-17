REM cli_cdb_kiev_identity_columns.sql 2021-04-11
REM CDB list of IDENTITY columns on KIEV tables
REM Enables PX on Standby and disables PX on RW Primary (fast on 19c Standby, slow otherwise)
--
SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
SET FEED ON TI ON TIMI ON;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
--
COL px_cdb_view_enabled NEW_V px_cdb_view_enabled NOPRI;
SELECT CASE WHEN open_mode = 'READ WRITE' AND database_role = 'PRIMARY' THEN 'FALSE' ELSE 'TRUE' END AS px_cdb_view_enabled FROM v$database;
--
COL pdb_name FOR A30 TRUNC;
COL owner FOR A30 TRUNC;
COL table_name FOR A30 TRUNC;
COL object_id FOR 999999999;
COL column_name FOR A30 TRUNC;
COL sequence_name FOR A30 TRUNC;
COL table_name_seq FOR A30 TRUNC;
--
BRE ON pdb_name SKIP PAGE DUPL;
--
PRO
PRO KIEV IDENTITY COLUMNS
PRO ~~~~~~~~~~~~~~~~~~~~~
--
WITH
cdb_stuff AS (
SELECT /*+ MATERIALIZE NO_MERGE OPT_PARAM('_px_cdb_view_enabled' '&&px_cdb_view_enabled.') */
       i.con_id, i.owner, i.table_name, o.object_id, o.created, i.column_name, i.sequence_name, s.last_number, SUBSTR(i.table_name, 1, 26)||'_SEQ' AS table_name_seq, s2.last_number AS s2_last_number
  FROM cdb_users u, cdb_tables t, cdb_tab_identity_cols i, cdb_objects o, cdb_sequences s, cdb_sequences s2
 WHERE u.oracle_maintained = 'N'
   AND t.con_id = u.con_id AND t.owner = u.username AND t.table_name = 'KIEVDATASTOREMETADATA'
   AND i.con_id = t.con_id AND i.owner = t.owner
   AND o.con_id = i.con_id AND o.owner = i.owner AND o.object_name = i.table_name AND o.object_type = 'TABLE'
   AND s.con_id = i.con_id AND s.sequence_owner = i.owner AND s.sequence_name = i.sequence_name
   AND s2.con_id(+) = i.con_id AND s2.sequence_owner(+) = i.owner AND s2.sequence_name(+) = SUBSTR(i.table_name, 1, 26)||'_SEQ'
)
SELECT c.name AS pdb_name, v.owner, v.table_name, v.object_id, v.created, v.column_name, v.sequence_name, v.last_number, v.table_name_seq, v.s2_last_number
  FROM cdb_stuff v, v$containers c
 WHERE c.con_id = v.con_id
 ORDER BY
       c.name, v.owner, v.table_name
/