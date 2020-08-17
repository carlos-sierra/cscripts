----------------------------------------------------------------------------------------
--
-- File name:   cs_table_stats_report.sql
--
-- Purpose:     CBO Statistics History for given Table
--
-- Author:      Carlos Sierra
--
-- Version:     2020/03/10
--
-- Usage:       Execute connected to PDB.
--
--              Enter Table when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_table_stats_report.sql
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
DEF cs_script_name = 'cs_table_stats_report';
--
ALTER SESSION SET container = CDB$ROOT;
--
COL owner NEW_V owner FOR A30 HEA 'TABLE_OWNER';
SELECT DISTINCT h.owner
  FROM c##iod.table_stats_hist h,
       cdb_users u
 WHERE h.pdb_name = UPPER(TRIM('&&cs_con_name.'))
   AND u.con_id = h.con_id
   AND u.username = h.owner
   AND u.oracle_maintained = 'N' 
   AND u.username NOT LIKE 'C##'||CHR(37) 
 ORDER BY 1
/
COL table_owner NEW_V table_owner FOR A30;
PRO
PRO 1. Table Owner:
DEF table_owner = '&1.';
UNDEF 1;
SELECT UPPER(NVL('&&table_owner.', '&&owner.')) table_owner FROM DUAL
/
--
SELECT DISTINCT h.table_name
  FROM c##iod.table_stats_hist h,
       cdb_users u
 WHERE h.pdb_name = UPPER(TRIM('&&cs_con_name.'))
   AND h.owner = UPPER(TRIM('&&table_owner.'))
   AND u.con_id = h.con_id
   AND u.username = h.owner
   AND u.oracle_maintained = 'N' 
   AND u.username NOT LIKE 'C##'||CHR(37) 
 ORDER BY 1
/
PRO
PRO 2. Table Name:
DEF table_name = '&2.';
UNDEF 2;
COL table_name NEW_V table_name NOPRI;
SELECT UPPER(TRIM('&&table_name.')) table_name FROM DUAL;
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&table_owner..&&table_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&table_owner." "&&table_name."
@@cs_internal/cs_spool_id.sql
--
PRO TABLE_OWNER  : &&table_owner.
PRO TABLE_NAME   : &&table_name.
--
COL num_rows FOR 999,999,999,990;
COL blocks FOR 9,999,999,990;
COL rows_per_block FOR 999,999,990.0;
COL avg_row_len FOR 999,999,990;
COL sample_size FOR 999,999,999,990;
--
WITH
my_query AS (
SELECT last_analyzed,
       num_rows,
       blocks,
       num_rows/GREATEST(blocks,1) rows_per_block,
       avg_row_len,
       sample_size
  FROM c##iod.table_stats_hist
 WHERE pdb_name = '&&cs_con_name.'
   AND owner = UPPER(TRIM('&&table_owner.'))
   AND table_name = UPPER(TRIM('&&table_name.'))
)
SELECT TO_CHAR(q.last_analyzed, '&&cs_datetime_full_format.') last_analyzed,
       q.num_rows,
       q.blocks,
       q.rows_per_block,
       q.avg_row_len,
       q.sample_size
  FROM my_query q
 ORDER BY
       q.last_analyzed
/
--
COL hours_since_gathering FOR 999,990.0 HEA 'HOURS|SINCE|GATHERING';
COL num_rows FOR 999,999,990;
COL inserts FOR 999,999,990 HEA 'INSERTS|SINCE|GATHERING';
COL updates FOR 999,999,990 HEA 'UPDATES|SINCE|GATHERING';
COL deletes FOR 999,999,990 HEA 'DELETES|SINCE|GATHERING';
COL inserts_per_sec FOR 999,990.000 HEA 'INSERTS|PER SEC';
COL updates_per_sec HEA 999,990.000 HEA 'UPDATES|PER SEC';
COL deletes_per_sec HEA 999,990.000 HEA 'DELETES|PER SEC';
--
ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
SELECT TO_CHAR(t.last_analyzed, '&&cs_datetime_full_format.') last_analyzed,
       t.num_rows,
       ROUND(m.inserts / ((m.timestamp - t.last_analyzed) * 24 * 60 * 60), 3) inserts_per_sec,
       ROUND(m.deletes / ((m.timestamp - t.last_analyzed) * 24 * 60 * 60), 3) deletes_per_sec,
       ROUND(m.updates / ((m.timestamp - t.last_analyzed) * 24 * 60 * 60), 3) updates_per_sec,
       TO_CHAR(m.timestamp, '&&cs_datetime_full_format.') timestamp,
       24 * (m.timestamp - t.last_analyzed) hours_since_gathering,
       m.inserts,
       m.deletes,
       m.updates
  FROM dba_tables t,
       dba_tab_modifications m
 WHERE t.owner = UPPER(TRIM('&&table_owner.'))
   AND t.table_name = UPPER(TRIM('&&table_name.'))
   AND m.table_owner = t.owner
   AND m.table_name = t.table_name
/
--
PRO
PRO SQL> @&&cs_script_name..sql "&&table_owner." "&&table_name."
--
@@cs_internal/cs_spool_tail.sql
--
ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--