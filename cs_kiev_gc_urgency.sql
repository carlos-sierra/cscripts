----------------------------------------------------------------------------------------
--
-- File name:   cs_kiev_gc_urgency.sql
--
-- Purpose:     Determine list of tables for which GC is urgent
--
-- Author:      Carlos Sierra
--
-- Version:     2019/02/13
--
-- Usage:       Execute connected to CDB or PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_kiev_gc_urgency.sql
--
-- Notes:       In case of socket timeout consider "critical" to set ticket severity
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_kiev_gc_urgency';
--
--ALTER SESSION SET container = CDB$ROOT;
--
SELECT '&&cs_file_prefix._&&cs_file_date_time._&&cs_reference_sanitized._&&cs_script_name' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql 
@@cs_internal/cs_spool_id.sql
--
COL pdb_name FOR A30;
COL owner FOR A30;
COL table_name FOR A30;
COL num_rows FOR 999,999,999,990;
COL gc_perc FOR 999,990.0 HEA 'GARBAGE|PERCENT';
COL critical FOR A8;
-- 
BREAK ON pdb_name DUPLICATES SKIP PAGE;
--
WITH 
histogram AS (
SELECT t.owner,
       t.table_name,
       t.num_rows,
       SUBSTR(UTL_RAW.CAST_TO_VARCHAR2(SUBSTR(LPAD(TO_CHAR(h.endpoint_value,'fmxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'),30,'0'),1,12)), 1, 1) kievlive,
       h.endpoint_number,
       endpoint_number - LAG(endpoint_number, 1, 0) OVER (PARTITION BY h.owner, h.table_name ORDER BY h.endpoint_value) value_count,
       MAX(h.endpoint_number) OVER (PARTITION BY h.owner, h.table_name) max_endpoint_number
  FROM dba_tables t,
       dba_tab_histograms h
 WHERE h.owner = t.owner
   AND h.table_name = t.table_name
   AND h.column_name = 'KIEVLIVE'
)
SELECT owner,
       table_name,
       num_rows,
       100 * value_count / max_endpoint_number gc_perc,
       CASE WHEN value_count / max_endpoint_number > 0.2 AND num_rows > 1e4 THEN 'CRITICAL' ELSE '--' END critical
  FROM histogram
 WHERE kievlive = 'N'
 ORDER BY
       owner,
       table_name
/
--
CLEAR BREAK COMPUTE;
--
PRO
PRO SQL> @&&cs_script_name..sql 
--
@@cs_internal/cs_spool_tail.sql
--
--ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--