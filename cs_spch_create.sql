----------------------------------------------------------------------------------------
--
-- File name:   cs_spch_create.sql
--
-- Purpose:     Create a SQL Patch for given SQL_ID
--
-- Author:      Carlos Sierra
--
-- Version:     2020/12/20
--
-- Usage:       Connecting into PDB.
--
--              Enter SQL_ID and PLAN_HASH_VALUE when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_spch_create.sql
--
-- Notes:       Accesses AWR data thus you must have an Oracle Diagnostics Pack License.
--
--              Developed and tested on 12.1.0.2.
--
--              Other less common CBO Hints:
--              ~~~~~~~~~~~~~~~~~~~~~~~~~~~
--              FIRST_ROWS(1) OPT_PARAM('_fix_control' '5922070:OFF') --  DBPERF-5188 DBPERF-5443 DBPERF-5475 DBPERF-5513 DBPERF-5839 DBPERF-5881 DBPERF-6264 DBPERF-6302 DBPERF-6337 DBPERF-84 DBPERF-262 DBPERFOCI-54 IOD-31530 IOD-34530 WFAAS-5928 ... 5922070: NO COLUMN EQUIVALENCE BASED ON EQUIJOIN IS DONE IN STMT WITH GROUP BY 
--              FIRST_ROWS(1) OPT_PARAM('_fix_control' '21971099:OFF') -- DBPERF-5204 NAT_GATEWAY 9tbzxxg29px0p performScanQuery(RETRY_TOKENS,HashRangeIndex) 21971099: WRONG CARDINALITY FROM SQL ANALYTIC WINDOWS FUNCTIONS
--              O OPT_PARAM('_fix_control' '13321547:OFF') -- 13321547: ANALYTICAL QUERY WINDOW SORT
--              FIRST_ROWS(1) OPT_PARAM('_fix_control' '6674254:OFF') -- DBPERF-6362 DNSVCNAPI cqhcc9c504qk5 getValues(INTERNAL_ZONES,ZoneIdIndex) after removing redundant predicate 6674254: FIRST_ROWS(X) HINT CAUSING BAD PLAN
--              FIRST_ROWS(1) OPT_PARAM('_optimizer_unnest_all_subqueries' 'FALSE')  -- DBPERF-6362 DNSVCNAPI cqhcc9c504qk5 getValues(INTERNAL_ZONES,ZoneIdIndex) after removing redundant predicate
--              FIRST_ROWS(1) OPT_PARAM('_unnest_subquery' 'FALSE')  -- DBPERF-6362 DNSVCNAPI cqhcc9c504qk5 getValues(INTERNAL_ZONES,ZoneIdIndex) after removing redundant predicate
--              FIRST_ROWS(1) OPT_PARAM('_first_k_rows_dynamic_proration' 'FALSE') -- DBPERF-6362 DNSVCNAPI cqhcc9c504qk5 getValues(INTERNAL_ZONES,ZoneIdIndex) after removing redundant predicate
--              CARDINALITY(T 1) 
--              BIND_AWARE 
--              PUSH_PRED(@SEL$XXXXXXXX)
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_spch_create';
--
PRO 1. SQL_ID: 
DEF cs_sql_id = "&1.";
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&cs_sql_id.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_signature.sql
--
@@cs_internal/cs_&&dba_or_cdb._plans_performance.sql
@@cs_internal/cs_spch_internal_list.sql
--
PRO
PRO To enhance performance diagnostics use:                 MONITOR GATHER_PLAN_STATISTICS
PRO
PRO For KIEV Begin scan which includes "AND (1 = 1)" use:   FIRST_ROWS(1) OPT_PARAM('_fix_control' '5922070:OFF')
PRO
PRO For most KIEV scans and gets use:                       FIRST_ROWS(1)
PRO
PRO 2. CBO_HINT(S) (required):
DEF hints_text = "&2.";
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id." "&&hints_text." 
@@cs_internal/cs_spool_id.sql
--
PRO SQL_ID       : &&cs_sql_id.
PRO SIGNATURE    : &&cs_signature.
PRO SQL_HANDLE   : &&cs_sql_handle.
PRO CBO HINTS    : "&&hints_text."
--
SET HEA OFF;
PRINT :cs_sql_text
SET HEA ON;
-- drop existing patch if any
@@cs_internal/cs_spch_internal_drop.sql
--
PRO
PRO Create name: "spch_&&cs_sql_id."
@@cs_internal/cs_spch_internal_create.sql
--
@@cs_internal/cs_spch_internal_list.sql
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id." "&&hints_text." 
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--

