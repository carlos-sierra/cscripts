REM cli_cdb_not_validated_not_null.sql 2021-04-15
REM CDB list of MISSING or NOT VALIDATED NOT NULL constraints on columns which are part of a PK/UK constraint
REM Enables PX on Standby and disables PX on RW Primary (fast on 19c Standby, slow otherwise)
REM Be aware of ORA-00600 [kcbgtcr_17] 28208552 25444575 on Standby. WO: alter session set events '10200 trace name context forever, level 1'; alter session set events '10708 trace name context forever, level 1'; 
REM Reduce search scope with tables_over_these_many_rows and cbo_stats_newer_than_days. Set to 0 and 3650 respectively to select all
--
DEF tables_over_these_many_rows = '10000';
DEF cbo_stats_newer_than_days = '7';
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
COL index_name FOR A30 TRUNC;
COL constraint_name FOR A30 TRUNC;
COL constraint_type FOR A4 HEA 'TYPE';
COL position FOR 990 HEA 'POS';
COL column_name FOR A30 TRUNC;
COL is_not_null FOR A13;
COL col_constraint_name FOR A30 TRUNC;
--
BRE ON pdb_name SKIP PAGE DUPL ON constraint_name SKIP 1 DUPL;
--
PRO
PRO NOT VALIDATED NOT NULL CONSTRAINTS
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
WITH
cdb_stuff AS (
SELECT /*+ MATERIALIZE NO_MERGE OPT_PARAM('_px_cdb_view_enabled' '&&px_cdb_view_enabled.') */
       u.con_id, u.username AS owner, t.table_name, t.num_rows, t.last_analyzed, uc.index_name, uc.constraint_name, uc.constraint_type, col.position, col.column_name, cc.validated, cc.constraint_name AS col_constraint_name
  FROM cdb_users u, cdb_tables t, cdb_constraints uc, cdb_cons_columns col, cdb_constraints cc
 WHERE u.oracle_maintained = 'N' AND u.con_id > 2
   AND t.con_id = u.con_id AND t.owner = u.username AND t.partitioned = 'NO'
   AND uc.con_id = t.con_id AND uc.owner = t.owner AND uc.table_name = t.table_name AND uc.constraint_type IN ('P', 'U') AND uc.status = 'ENABLED' --AND uc.validated = 'NOT VALIDATED' 
   AND col.con_id = uc.con_id AND col.owner = uc.owner AND col.table_name = uc.table_name AND col.constraint_name = uc.constraint_name
   AND cc.con_id(+) = col.con_id AND cc.owner(+) = col.owner AND cc.table_name(+) = uc.table_name AND cc.constraint_type(+) = 'C' AND cc.search_condition_vc(+) = '"'||col.column_name||'" IS NOT NULL'
   AND ROWNUM >= 1 -- forces NO_MERGE
)
SELECT c.name AS pdb_name, v.owner, v.table_name, v.num_rows, v.last_analyzed, v.index_name, v.constraint_name, v.constraint_type, v.position, v.column_name, NVL(v.validated, 'MISSING') AS is_not_null, col_constraint_name
  FROM cdb_stuff v, v$containers c
 WHERE c.con_id = v.con_id
   AND v.validated = 'NOT VALIDATED' -- use this predicate to include only the not validated not null constraints
   --AND NVL(v.validated, 'MISSING') IN ('NOT VALIDATED', 'MISSING') -- use this predicate instead in order to include missing not null constraints (in addition to not validated)
   AND v.num_rows > &&tables_over_these_many_rows. AND v.last_analyzed > SYSDATE - &&cbo_stats_newer_than_days.
 ORDER BY
       c.name, v.owner, v.table_name, v.constraint_name, v.position
/
