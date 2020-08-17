----------------------------------------------------------------------------------------
--
-- File name:   cs_kiev_indexes.sql
--
-- Purpose:     KIEV Indexes Inventory
--
-- Author:      Carlos Sierra
--
-- Version:     2020/03/10
--
-- Usage:       Execute connected to CDB or PDB.
--
--              Specify search scope when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_kiev_indexes.sql
--
-- Notes:       OEM JOB oem/IOD_IMMEDIATE_KIEV_INDEXES.sql should be executed in advance
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_kiev_indexes';
--
ALTER SESSION SET container = CDB$ROOT;
--
PRO 1. Include Missing Indexes: [{Y}|N]
DEF cs2_missing = '&1.';
UNDEF 1;
COL cs2_missing NEW_V cs2_missing NOPRI;
SELECT NVL(UPPER(TRIM('&&cs2_missing.')), 'Y') cs2_missing FROM DUAL;
--
PRO 2. Include Extra Indexes: [{Y}|N]
DEF cs2_extra = '&2.';
UNDEF 2;
COL cs2_extra NEW_V cs2_extra NOPRI;
SELECT NVL(UPPER(TRIM('&&cs2_extra.')), 'Y') cs2_extra FROM DUAL;
--
PRO 3. Include Compliant Indexes: [{Y}|N]
DEF cs2_compliant = '&3.';
UNDEF 3;
COL cs2_compliant NEW_V cs2_compliant NOPRI;
SELECT NVL(UPPER(TRIM('&&cs2_compliant.')), 'Y') cs2_compliant FROM DUAL;
--
COL cs_filename_suffix NEW_V cs_filename_suffix NOPRI;
SELECT CASE '&&cs2_missing.&&cs2_extra.&&cs2_compliant.' WHEN 'YYY' THEN '_ALL' ELSE (CASE '&&cs2_missing.' WHEN 'Y' THEN '_MISSING' END||CASE '&&cs2_extra.' WHEN 'Y' THEN '_EXTRA' END||CASE '&&cs2_compliant.' WHEN 'Y' THEN '_COMPLIANT' END) END cs_filename_suffix FROM DUAL;
--
SELECT '&&cs_file_prefix._&&cs_script_name.&&cs_filename_suffix.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs2_missing." "&&cs2_extra." "&&cs2_compliant." 
@@cs_internal/cs_spool_id.sql
--
PRO MISSING      : "&&cs2_missing." [{Y}|N]
PRO EXTRA        : "&&cs2_extra." [{Y}|N]
PRO COMPLIANT    : "&&cs2_compliant." [{Y}|N]
--
COL pdb_name FOR A30;
COL owner FOR A30;
COL table_name FOR A30;
COL u_table_name FOR A30 NOPRI;
COL index_name FOR A30;
COL uniqueness FOR A10;
COL discrepancy FOR A11;
COL column_position FOR 999 HEA 'POS';
COL column_name FOR A30;
COL type_len FOR A30;
COL nullable FOR A8;
COL missing_indexes NEW_V missing_indexes FOR 99999 NOPRI;
COL extra_indexes NEW_V extra_indexes FOR 99999 NOPRI;
COL compliant_indexes NEW_V compliant_indexes FOR 99999 NOPRI;
BREAK ON pdb_name DUPLICATES SKIP PAGE ON u_table_name DUPLICATES SKIP 1;       
--
WITH
kiev_tables AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       DISTINCT
       pdb_name,
       owner,
       table_name,
       con_id
  FROM c##iod.kiev_ind_columns
 WHERE '&&cs_con_name.' IN ('CDB$ROOT', pdb_name)
),
db_ind_columns AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       o.owner,
       i.table_name,
       i.index_name,
       i.uniqueness,
       ic.column_position,
       ic.column_name,
       tc.data_type,
       tc.data_length,
       tc.data_precision,
       tc.data_scale,
       tc.nullable,
       o.con_id
  FROM (SELECT /*+ MATERIALIZE NO_MERGE */ 
               DISTINCT con_id, owner 
          FROM cdb_tables
         WHERE table_name = 'KIEVBUCKETS') o,
       cdb_indexes i,
       cdb_ind_columns ic,
       cdb_tab_columns tc
 WHERE i.con_id = o.con_id 
   AND i.table_owner = o.owner
   AND i.table_name NOT LIKE 'KIEV'||CHR(37)
   AND ic.index_owner = i.owner
   AND ic.index_name = i.index_name
   AND ic.con_id = i.con_id
   AND tc.owner = ic.table_owner
   AND tc.table_name = ic.table_name
   AND tc.column_name = ic.column_name
   AND tc.con_id = ic.con_id
),
missing AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       k.pdb_name,
       k.owner,
       k.table_name,
       k.index_name,
       k.uniqueness,
       k.column_position,
       k.column_name,
       k.data_type,
       k.data_length,
       k.data_precision,
       k.data_scale,
       k.nullable,
       k.con_id
  FROM c##iod.kiev_ind_columns k
 WHERE '&&cs_con_name.' IN ('CDB$ROOT', k.pdb_name)
   AND NOT EXISTS
       ( SELECT /*+ MATERIALIZE NO_MERGE */ NULL
           FROM db_ind_columns a
          WHERE a.con_id = k.con_id
            AND a.owner = k.owner
            AND a.table_name = UPPER(k.table_name)
            AND a.index_name = UPPER(k.index_name)
            AND a.column_position = k.column_position
            AND a.column_name = UPPER(k.column_name)
       )
),
compliant AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       k.pdb_name,
       k.owner,
       k.table_name,
       k.index_name,
       k.uniqueness,
       k.column_position,
       k.column_name,
       a.data_type,
       a.data_length,
       a.data_precision,
       a.data_scale,
       a.nullable,
       k.con_id
  FROM c##iod.kiev_ind_columns k,
       db_ind_columns a
 WHERE '&&cs_con_name.' IN ('CDB$ROOT', k.pdb_name)
   AND a.con_id = k.con_id
   AND a.owner = k.owner
   AND a.table_name = UPPER(k.table_name)
   AND a.index_name = UPPER(k.index_name)
   AND a.column_position = k.column_position
   AND a.column_name = UPPER(k.column_name)
),
extra AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       c.name pdb_name,
       i.owner,
       i.table_name,
       i.index_name,
       i.uniqueness,
       i.column_position,
       i.column_name,
       i.data_type,
       i.data_length,
       i.data_precision,
       i.data_scale,
       i.nullable,
       i.con_id
  FROM db_ind_columns i,
       v$containers c
 WHERE c.con_id = i.con_id
   AND c.open_mode = 'READ WRITE'
   AND '&&cs_con_name.' IN ('CDB$ROOT', c.name)
   AND NOT EXISTS
       ( SELECT /*+ MATERIALIZE NO_MERGE */ NULL
           FROM c##iod.kiev_ind_columns a
          WHERE a.con_id = i.con_id
            AND a.owner = i.owner
            AND UPPER(a.table_name) = i.table_name
            AND UPPER(a.index_name) = i.index_name
            AND a.column_position = i.column_position
            AND UPPER(a.column_name) = i.column_name
       )
),
totals AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       (SELECT COUNT(DISTINCT pdb_name||'.'||owner||'.'||table_name||'.'||index_name) FROM missing) missing_indexes,
       (SELECT COUNT(DISTINCT pdb_name||'.'||owner||'.'||table_name||'.'||index_name) FROM extra) extra_indexes,
       (SELECT COUNT(DISTINCT pdb_name||'.'||owner||'.'||table_name||'.'||index_name) FROM compliant) compliant_indexes
  FROM dual
),
inventory AS (
SELECT pdb_name,
       owner,
       table_name,
       index_name,
       uniqueness,
       column_position,
       column_name,
       data_type,
       data_length,
       data_precision,
       data_scale,
       nullable,
       'MISSING' discrepancy
  FROM missing
 WHERE '&&cs2_missing.' = 'Y'
 UNION ALL
SELECT pdb_name,
       owner,
       table_name,
       index_name,
       uniqueness,
       column_position,
       column_name,
       data_type,
       data_length,
       data_precision,
       data_scale,
       nullable,
       '-' discrepancy
  FROM compliant
 WHERE '&&cs2_compliant.' = 'Y'
 UNION ALL
SELECT pdb_name,
       owner,
       table_name,
       index_name,
       uniqueness,
       column_position,
       column_name,
       data_type,
       data_length,
       data_precision,
       data_scale,
       nullable,
       'EXTRA' discrepancy
  FROM extra
 WHERE '&&cs2_extra.' = 'Y'
)  
SELECT t.missing_indexes,
       t.extra_indexes,
       t.compliant_indexes,
       UPPER(i.table_name) u_table_name,
       i.pdb_name,
       i.owner,
       i.table_name,
       i.index_name,
       i.uniqueness,
       i.column_position,
       i.column_name,
       i.data_type||CASE WHEN i.data_length IS NOT NULL THEN '('||i.data_length||')' END type_len,
       i.nullable,
       i.discrepancy
  FROM inventory i,
       totals t
 ORDER BY
       i.pdb_name,
       i.owner,
       UPPER(i.table_name),
       UPPER(i.index_name),
       i.column_position,
       UPPER(i.column_name)
/
--
CLEAR BREAK COMPUTE;
--
PRO
PRO Compliant : &&compliant_indexes. indexes
PRO Extra     : &&extra_indexes. indexes
PRO Missing   : &&missing_indexes. indexes
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs2_missing." "&&cs2_extra." "&&cs2_compliant." 
--
@@cs_internal/cs_spool_tail.sql
--
ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--