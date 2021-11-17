----------------------------------------------------------------------------------------
--
-- File name:   cs_spch_create.sql
--
-- Purpose:     Create a SQL Patch for given SQL_ID
--
-- Author:      Carlos Sierra
--
-- Version:     2021/08/19
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
--              FIRST_ROWS(1) OPT_PARAM('_fix_control' '13321547:OFF') -- 13321547: ANALYTICAL QUERY WINDOW SORT
--              FIRST_ROWS(1) OPT_PARAM('_fix_control' '6674254:OFF') -- DBPERF-6362 DNSVCNAPI cqhcc9c504qk5 getValues(INTERNAL_ZONES,ZoneIdIndex) after removing redundant predicate 6674254: FIRST_ROWS(X) HINT CAUSING BAD PLAN
--              FIRST_ROWS(1) OPT_PARAM('_optimizer_unnest_all_subqueries' 'FALSE')  -- DBPERF-6362 DNSVCNAPI cqhcc9c504qk5 getValues(INTERNAL_ZONES,ZoneIdIndex) after removing redundant predicate
--              FIRST_ROWS(1) OPT_PARAM('_unnest_subquery' 'FALSE')  -- DBPERF-6362 DNSVCNAPI cqhcc9c504qk5 getValues(INTERNAL_ZONES,ZoneIdIndex) after removing redundant predicate
--              FIRST_ROWS(1) OPT_PARAM('_first_k_rows_dynamic_proration' 'FALSE') -- DBPERF-6362 DNSVCNAPI cqhcc9c504qk5 getValues(INTERNAL_ZONES,ZoneIdIndex) after removing redundant predicate
--              CARDINALITY(T 1) 
--              OPT_ESTIMATE(TABLE T ROWS=1) e.g.: OPT_ESTIMATE(@SEL$1 TABLE REPLICATION_LOG_V2 ROWS=1000000)
--              BIND_AWARE 
--              PUSH_PRED(@SEL$XXXXXXXX)
--              NO_EXPAND
--              OPT_PARAM('_b_tree_bitmap_plans' 'FALSE') OPT_PARAM('_no_or_expansion' 'TRUE')
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
UNDEF 1;
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&cs_sql_id.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_signature.sql
--
@@cs_internal/cs_&&dba_or_cdb._plans_performance.sql
@@cs_internal/cs_spch_internal_list.sql
--
COL default_hints_text NEW_V default_hints_text NOPRI;
SELECT q'[FIRST_ROWS(1) OPT_PARAM('_fix_control' '5922070:OFF')]'||CASE WHEN '&&cs_kiev_table_name.' IS NOT NULL THEN ' LEADING(@SEL$1 &&cs_kiev_table_name.)' END AS default_hints_text FROM DUAL;
PRO
PRO To enhance diagnostics:          MONITOR GATHER_PLAN_STATISTICS
PRO
PRO For most KIEV scans use default: &&default_hints_text.
PRO
PRO 2. CBO_HINT(S):
DEF hints_text = "&2.";
UNDEF 2;
COL hints_text NEW_V hints_text NOPRI;
SELECT NVL(q'[&&hints_text.]', q'[&&default_hints_text.]') AS hints_text FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id." "&&hints_text." 
@@cs_internal/cs_spool_id.sql
--
PRO SQL_ID       : &&cs_sql_id.
PRO SQLHV        : &&cs_sqlid.
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

