----------------------------------------------------------------------------------------
--
-- File name:   spb_fix_report.sql
--
-- Purpose:     Woraround CPU spikes caused by bogus HVC on ACS, bypassing ACS
--              while setting one and only one SQL Plan Baseline (SPB) with FIXED flag 
--              set to YES for SQL at risk (of causing a CPU spike)
--
--              Note: When a SQL has one (and only one) SPB set to FIXED, then the code
--                    path for Adaptive Cursor Sharing (ACS) is not executed, avoiding
--                    then the creation of new child cursors due to ACS selectivity
--                    profiles. This technique does not fix undelying issues (bogus ACS +
--                    frequent CBO stats gathering + excesive sessions from connection
--                    pool). Then these two scripts are just a workaround until the actual
--                    culprits are addressed.
--
-- Author:      Carlos Sierra
--
-- Version:     v01 2017/11/21
--
-- Usage:       There are two sibling scripts: spb_fix_report.sql and spb_fix_script.sql,
--              both have two parts:
--
--              1. Select cursors with one or more SQL Plan Baselines (SPBs), where
--                 none is FIXED, and where the parent SQL has had many invalidations and
--                 report a High Version Count (HVC) due to anomalies on Adaptive Cursor
--                 Sharing (ACS). Choose the SPB with better average performance.
--
--              2. Select SPBs already FIXED, if a SQL SIGNATURE has more than one.
--                 Determine if those FIXED PDBs are in use, and what is their performance.
--                 Choose to demote (set FIXED flag to NO) those SPBs that have no cursor,
--                 or they are not the best performing; but only if the SQL reports many
--                 invalidations and a HVC.
--
--              Script spb_fix_report.sql lists candidates that need to get an existing
--              SPB promoted to FIXED, or have more than one FIXED SPB and all but one
--              must be demoted to not FIXED.
--
--              Script spb_fix_script.sql does the same, but instead of creating a report
--              it generates a dynamic script that can be reviewed, then executed, to
--              perform the activities described above.
--
-- Example:     $sqlplus / as sysdba
--              @spb_fix_report.sql
--
-- Notes:       Developed and tested on 12.0.1.0.2
--             
---------------------------------------------------------------------------------------
--
SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
COL sql_handle FOR A20;
COL plan_name FOR A30;
COL signature FOR 99999999999999999999;
CLEAR BREAK;
SPO spb_fix_report.txt;

BREAK ON con_id SKIP PAGE ON pdb_name;
PRO
PRO -- SPBs that need to be fixed (due to ACS/HVC anomalies)
PRO -- ~~~~~~~~~~~~~~~~~~~~~~~~~~
WITH
cur_with_spb AS (
SELECT s.con_id,
       s.sql_id,
       s.plan_hash_value,
       s.sql_plan_baseline,
       MAX(t.version_count) version_count,
       MAX(t.invalidations) invalidations,
       b.signature,
       b.sql_handle,
       b.enabled,
       b.accepted,
       b.reproduced,
       b.fixed,
       SUM(s.elapsed_time) elapsed_time,
       SUM(s.executions) executions,
       SUM(s.elapsed_time)/SUM(s.executions) et_per_exec,
       ROW_NUMBER () OVER (PARTITION BY s.con_id, s.sql_id ORDER BY SUM(s.elapsed_time)/SUM(s.executions) ASC NULLS LAST) row_number
  FROM v$sql s,
       v$sqlstats t,
       cdb_sql_plan_baselines b
 WHERE s.sql_plan_baseline IS NOT NULL
   AND s.sql_text NOT LIKE '/* SQL Analyze'||CHR(37)
   AND s.elapsed_time > 0
   AND s.executions > 0
   AND t.sql_id = s.sql_id
   AND t.con_id = s.con_id
   AND t.version_count > 100 -- HVC
   AND t.invalidations > 1000 -- frequent hard-parses
   AND b.signature = s.exact_matching_signature
   AND b.plan_name = s.sql_plan_baseline
   AND b.con_id = s.con_id
   --AND b.description IS NULL -- only those not created by zapper
 GROUP BY
       s.con_id,
       s.sql_id,
       s.plan_hash_value,
       s.sql_plan_baseline,
       b.signature,
       b.sql_handle,
       b.enabled,
       b.accepted,
       b.reproduced,
       b.fixed
),
sql_with_spb AS (
SELECT s.con_id,
       s.sql_id,
       COUNT(*) plans_with_spb,
       SUM(CASE s.fixed WHEN 'YES' THEN 1 ELSE 0 END) fixed_plans
  FROM cur_with_spb s
 GROUP BY
       s.con_id,
       s.sql_id
),
candidates AS (
SELECT s.con_id,
       p.name pdb_name,
       s.sql_id,
       c.plan_hash_value,
       c.version_count,
       c.invalidations,
       c.signature,
       c.sql_handle,
       c.sql_plan_baseline plan_name,
       c.elapsed_time,
       c.executions,
       ROUND(c.et_per_exec) et_per_exec
  FROM sql_with_spb s,
       cur_with_spb c,
       v$pdbs p
 WHERE s.fixed_plans = 0
   AND c.con_id = s.con_id
   AND c.sql_id = s.sql_id
   AND c.row_number = 1
   AND p.con_id = s.con_id
 ORDER BY
       s.con_id,
       s.sql_id
)
SELECT * 
  FROM candidates
/

BREAK ON con_id SKIP PAGE ON pdb_name ON signature SKIP 1 ON sql_handle;
PRO
PRO -- SQL with multiple fixed SPBs (demote SPBs with row_number <> 1, version_count > 100 and invalidations > 1000)
PRO -- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
WITH 
fixed_spbs AS (
SELECT b.signature,
       b.sql_handle,
       b.plan_name,
       b.con_id
  FROM cdb_sql_plan_baselines b
 WHERE b.enabled = 'YES'
   AND b.accepted = 'YES'
   AND b.reproduced = 'YES'
   AND b.fixed = 'YES'
   --AND b.description IS NULL -- only those not created by zapper
),
more_than_one_fixed AS (
SELECT b.signature,
       b.sql_handle,
       b.con_id,
       COUNT(*) fixed
  FROM fixed_spbs b
 GROUP BY
       b.signature,
       b.sql_handle,
       b.con_id
HAVING COUNT(*) > 1
),
sql_using_fixed AS (
SELECT s.sql_id,
       s.plan_hash_value,
       MAX(t.version_count) version_count,
       MAX(t.invalidations) invalidations,
       b.signature,
       b.sql_handle,
       b.plan_name,
       b.con_id,
       SUM(s.elapsed_time) elapsed_time,
       SUM(s.executions) executions,
       SUM(s.elapsed_time)/SUM(s.executions) et_per_exec,
       ROW_NUMBER () OVER (PARTITION BY b.con_id, s.sql_id ORDER BY SUM(s.elapsed_time)/SUM(s.executions) ASC NULLS LAST) row_number
  FROM more_than_one_fixed f,
       fixed_spbs b,
       v$sql s,
       v$sqlstats t
 WHERE b.signature = f.signature
   AND b.sql_handle = f.sql_handle
   AND b.con_id = f.con_id
   AND s.exact_matching_signature = b.signature
   AND s.sql_plan_baseline = b.plan_name
   AND s.con_id = b.con_id
   AND s.sql_text NOT LIKE '/* SQL Analyze'||CHR(37)
   AND s.elapsed_time > 0
   AND s.executions > 0
   AND t.sql_id = s.sql_id
   AND t.con_id = s.con_id
 GROUP BY
       s.sql_id,
       s.plan_hash_value,
       b.signature,
       b.sql_handle,
       b.plan_name,
       b.con_id
),
candidates AS (
SELECT f.con_id,
       p.name pdb_name,
       f.signature,
       f.sql_handle,
       f.plan_name,
       s.row_number,
       s.sql_id,
       s.plan_hash_value,
       s.version_count,
       s.invalidations,
       s.elapsed_time,
       s.executions,
       ROUND(s.et_per_exec) et_per_exec
  FROM more_than_one_fixed o,
       fixed_spbs f,
       sql_using_fixed s,
       v$pdbs p
 WHERE f.signature = o.signature
   AND f.sql_handle = o.sql_handle
   AND f.con_id = o.con_id
   AND s.signature(+) = f.signature
   AND s.sql_handle(+) = f.sql_handle
   AND s.con_id(+) = f.con_id
   AND s.plan_name(+) = f.plan_name
   AND p.con_id = o.con_id
 ORDER BY
       f.con_id,
       f.signature,
       f.sql_handle,
       s.row_number NULLS LAST,
       s.sql_id NULLS LAST
)
SELECT * 
  FROM candidates
/

SPO OFF;
