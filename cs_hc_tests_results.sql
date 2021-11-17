----------------------------------------------------------------------------------------
--
-- File name:   cs_hc_tests_results.sql
--
-- Purpose:     Health Check (HC) Tests Results
--
-- Author:      Carlos Sierra
--
-- Version:     2021/10/20
--
-- Usage:       Execute connected to CDB or PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_hc_tests_results.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
--@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_hc_tests_results';
--
PRO 1. Include INFO and PASS?: [{N}|Y]
DEF cs_info_pass = '&1.';
UNDEF 1;
COL cs_info_pass NEW_V cs_info_pass NOPRI;
SELECT CASE WHEN UPPER(TRIM('&&cs_info_pass.')) IN ('N', 'Y') THEN UPPER(TRIM('&&cs_info_pass.')) ELSE 'N' END AS cs_info_pass FROM DUAL
/
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_info_pass."
@@cs_internal/cs_spool_id.sql
--
PRO INFO and PASS: &&cs_info_pass.
--
ALTER SESSION SET CONTAINER = CDB$ROOT;
--
COL test FOR A70 WRA WOR;
COL pdbs FOR A80 WRA WOR;
COL value FOR A16;
COL narrative FOR A60 WRA WOR;
--
BREAK ON status SKIP PAGE DUPL ON test SKIP 1 DUPL;
--
PRO
PRO HC Test Results (&cs_tools_schema..hc_result)
PRO ~~~~~~~~~~~~~~~
WITH
results AS (
SELECT r.*, ROW_NUMBER() OVER (PARTITION BY r.pdb_name, r.test_name ORDER BY r.test_begin DESC NULLS LAST) AS rn
  FROM &&cs_tools_schema..hc_result r
 WHERE '&&cs_con_name.' IN ('CDB$ROOT', r.pdb_name)
   AND r.test_begin > SYSDATE - 7 -- only care for last 7 days
)
SELECT r.status,
       r.test_name||': '||r.test_description AS test,
       LISTAGG(r.pdb_name, ', ') WITHIN GROUP (ORDER BY r.pdb_name) AS pdbs,
       MIN(r.value)||CASE WHEN MIN(r.value) <> MAX(r.value) THEN ' - '|| MAX(r.value) END AS value,
       r.test_value_uom AS uom,
       r.test_narrative AS narrative
  FROM results r
 WHERE r.rn = 1
   AND CASE WHEN '&&cs_info_pass.' = 'Y' THEN 1 WHEN r.status IN ('WIP', 'FAIL', 'WARNING', 'ERROR') THEN 1 ELSE 0 END = 1
 GROUP BY
       r.status,
       r.timestamp_for_order_by,
       r.test_name,
       r.test_value_uom,
       r.test_description,
       r.test_narrative 
 ORDER BY
       CASE r.status WHEN 'ERROR' THEN 1 WHEN 'FAIL' THEN 2 WHEN 'WIP' THEN 3 WHEN 'WARNING' THEN 4 WHEN 'INFO' THEN 5 WHEN 'PASS' THEN 6 ELSE 7 END,
       r.timestamp_for_order_by,
       r.test_name,
       r.test_value_uom,
       r.test_description,
       r.test_narrative
/
--
CLEAR BREAK;
--
ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_info_pass."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--