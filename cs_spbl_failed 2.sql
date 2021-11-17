----------------------------------------------------------------------------------------
--
-- File name:   cs_spbl_failed.sql
--
-- Purpose:     List of SQL Plans with: "Failed to use SQL plan baseline for this statement"
--
-- Author:      Carlos Sierra
--
-- Version:     2021/03/11
--
-- Usage:       Connecting into PDB
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_spbl_failed.sql
--
-- Notes:       *** Requires Oracle Diagnostics Pack License ***
--
--              Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_spbl_failed';
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql 
@@cs_internal/cs_spool_id.sql
--
COL child_number FOR 99990 HEA 'CHILD';
COL plan_hash_value FOR 9999999999 HEA 'PHV';
COL executions FOR 999,999,990;
COL cpu_time FOR 999,999,999,990;
COL sql_handle FOR A20;
COL plan_name FOR A30;
COL sql_text FOR A80 TRUNC;
--
BREAK ON sql_text SKIP 1 DUPL;
--
PRO
PRO Failed to use SQL plan baseline on &&cs_con_name.
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SELECT  s.sql_text,
        p.sql_id, 
        p.child_number,
        p.plan_hash_value,
        s.executions,
        s.cpu_time,
        s.exact_matching_signature AS signature,
        b.sql_handle,
        b.plan_name
FROM    v$sql_plan p,
        XMLTABLE('other_xml/info' PASSING XMLTYPE(p.other_xml) COLUMNS type VARCHAR2(30) PATH '@type', note VARCHAR2(4) PATH '@note', value VARCHAR2(30) PATH '.') x,
        v$sql s,
        dba_sql_plan_baselines b
WHERE   p.plan_hash_value > 0
--AND     p.id = 1
AND     p.other_xml IS NOT NULL 
AND     x.type = 'baseline_repro_fail' 
AND     x.value = 'yes'
AND     s.parsing_user_id > 0
AND     s.parsing_schema_id > 0
AND     s.address = p.address
AND     s.hash_value = p.hash_value
AND     s.sql_id = p.sql_id
AND     s.plan_hash_value = p.plan_hash_value
AND     s.child_address = p.child_address
AND     s.child_number = p.child_number
AND     s.exact_matching_signature > 0 -- INSERT from values has 0 on signature
AND     s.executions > 0
AND     s.cpu_time > 0
AND     s.buffer_gets > 0
AND     s.buffer_gets > s.executions
AND     s.object_status = 'VALID'
AND     s.is_obsolete = 'N'
AND     s.is_shareable = 'Y'
AND     s.is_bind_aware = 'N' -- to ignore cursors using adaptive cursor sharing ACS as per CHANGE-190522
AND     s.is_resolved_adaptive_plan IS NULL -- to ignore adaptive plans which cause trouble when combined with SPM
AND     s.is_reoptimizable = 'N' -- to ignore cursors which require adjustments as per cardinality feedback  
AND     s.last_active_time > SYSDATE - (1/24)
AND     b.signature = s.exact_matching_signature
AND     b.enabled = 'YES'
AND     b.accepted = 'YES'
-- AND     b.created < SYSDATE - 1
ORDER BY
        s.sql_text,
        p.sql_id, 
        p.child_number,
        b.plan_name
/
--
COL line FOR A40 HEA 'COMMAND';
PRO
PRO Drop commands
PRO ~~~~~~~~~~~~~
SELECT  DISTINCT
        '@cs_spbl_drop.sql "'||p.sql_id||'" ""' AS line
FROM    v$sql_plan p,
        XMLTABLE('other_xml/info' PASSING XMLTYPE(p.other_xml) COLUMNS type VARCHAR2(30) PATH '@type', note VARCHAR2(4) PATH '@note', value VARCHAR2(30) PATH '.') x,
        v$sql s,
        dba_sql_plan_baselines b
WHERE   p.plan_hash_value > 0
--AND     p.id = 1
AND     p.other_xml IS NOT NULL 
AND     x.type = 'baseline_repro_fail' 
AND     x.value = 'yes'
AND     s.parsing_user_id > 0
AND     s.parsing_schema_id > 0
AND     s.address = p.address
AND     s.hash_value = p.hash_value
AND     s.sql_id = p.sql_id
AND     s.plan_hash_value = p.plan_hash_value
AND     s.child_address = p.child_address
AND     s.child_number = p.child_number
AND     s.exact_matching_signature > 0 -- INSERT from values has 0 on signature
AND     s.executions > 0
AND     s.cpu_time > 0
AND     s.buffer_gets > 0
AND     s.buffer_gets > s.executions
AND     s.object_status = 'VALID'
AND     s.is_obsolete = 'N'
AND     s.is_shareable = 'Y'
AND     s.is_bind_aware = 'N' -- to ignore cursors using adaptive cursor sharing ACS as per CHANGE-190522
AND     s.is_resolved_adaptive_plan IS NULL -- to ignore adaptive plans which cause trouble when combined with SPM
AND     s.is_reoptimizable = 'N' -- to ignore cursors which require adjustments as per cardinality feedback  
AND     s.last_active_time > SYSDATE - (1/24)
AND     b.signature = s.exact_matching_signature
AND     b.enabled = 'YES'
AND     b.accepted = 'YES'
-- AND     b.created < SYSDATE - 1
ORDER BY
        1
/
--
PRO
PRO SQL> @&&cs_script_name..sql 
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--
