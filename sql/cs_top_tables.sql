----------------------------------------------------------------------------------------
--
-- File name:   cs_top_tables.sql
--
-- Purpose:     Top Tables as per number of rows
--
-- Author:      Carlos Sierra
--
-- Version:     2018/11/02
--
-- Usage:       Execute connected to CDB or PDB.
--
--              Enter if Oracle Maintained tables are included
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_top_tables.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_top_tables';
--
PRO 1. ORACLE_MAINT: [{N}|Y]
DEF cs_oracle_maint = '&1.';
COL cs_oracle_maint NEW_V cs_oracle_maint;
SELECT NVL('&&cs_oracle_maint.', 'N') cs_oracle_maint FROM DUAL;
--
SELECT '&&cs_file_prefix._&&cs_file_date_time._&&cs_reference_sanitized._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_oracle_maint."
@@cs_internal/cs_spool_id.sql
--
PRO ORACLE MAINT : "&&cs_oracle_maint." [{N}|Y]
--
COL num_rows FOR 999,999,999,990;
COL gbs FOR 9,990.000 HEA 'GBs';
COL owner FOR A30;
COL table_name FOR A30;
COL pdb_name FOR A35;
--
BREAK ON REPORT;
COMPUTE SUM LABEL 'TOTAL' OF num_rows gbs ON REPORT;
--
PRO
PRO TOP TABLES (as per number of rows)
PRO ~~~~~~~~~~
SELECT t.num_rows,
       t.blocks*s.block_size/POWER(2,30) gbs,
       t.owner,
       t.table_name,
       c.name||'('||t.con_id||')' pdb_name
  FROM cdb_tables t,
       cdb_tablespaces s,
       cdb_users u,
       v$containers c
 WHERE s.con_id = t.con_id
   AND s.tablespace_name = t.tablespace_name
   AND u.con_id = t.con_id
   AND u.username = t.owner
   AND ('&&cs_oracle_maint.' = 'Y' OR u.oracle_maintained = 'N')
   AND c.con_id = t.con_id
   AND c.open_mode = 'READ WRITE'
 ORDER BY
       t.num_rows DESC NULLS LAST
 FETCH FIRST 20 ROWS ONLY
/
--
CLEAR BREAK COMPUTE;
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_oracle_maint."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--