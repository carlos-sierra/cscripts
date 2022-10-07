----------------------------------------------------------------------------------------
--
-- File name:   cs_sprf_implement_wf.sql
--
-- Purpose:     Implements (imports) Execution Plans for some KIEV WF SQL in some PDBs, using SQL Profile(s)
--
-- Author:      Carlos Sierra
--
-- Version:     2021/09/10
--
-- Usage:       Connecting into CDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_sprf_implement_wf.sql
--
-- Notes:       Developed and tested on 12.1.0.2 and 19c.
--              KIEV WF specific
--
---------------------------------------------------------------------------------------
--
PRO
PRO This script will implement some SQL Profiles for some KIEV WF SQL.
PRO It will require you review its output on every PAUSE.
PRO It is idempotent, then you can execute it more than once.
PRO You can use companion script cs_sprf_verify_wf.sql to verify current state of consiered SQL.
PRO
@@cs_internal/&&cs_set_container_to_cdb_root.
--
PRO
PRO Search String: performScanQuery(leaseDecorators,ae_timestamp_index)%(1 = 1)%ASC
PRO Expected Plan: 610059206
PRO
PAUSE hit "return" to execute idempotent script kiev/cs_sprf_kiev_wf_leaseDecorators.sql
@@kiev/cs_sprf_kiev_wf_leaseDecorators.sql
--
PRO
PRO Search String: performScanQuery(workflowInstances,I_GC_INDEX)%(1 = 1)%ASC
PRO Expected Plan: 472260233 (or 549294716)
PRO
PAUSE hit "return" to execute idempotent script kiev/cs_sprf_kiev_wf_workflowInstances.sql
@@kiev/cs_sprf_kiev_wf_workflowInstances.sql
--
PRO
PRO Search String: performScanQuery(futureWork,resumptionTimestamp)%(1 = 1)%ASC
PRO Expected Plan: 2784194979
PRO
PAUSE hit "return" to execute idempotent script kiev/cs_sprf_kiev_wf_futureWork.sql
@@kiev/cs_sprf_kiev_wf_futureWork.sql
--
PRO
PRO Search String: populateBucketGCWorkspace%MAPPING_UPDATES_rgn%ASC
PRO Expected Plan: 1172229985 (or 1742292103)
PRO
PAUSE hit "return" to execute idempotent script kiev/cs_sprf_kiev_vcn_mappingUpdates.sql
@@kiev/cs_sprf_kiev_vcn_mappingUpdates.sql
--
PRO
PRO Search String: populateBucketGCWorkspace%EVENTS_V2_rgn%ASC
PRO Expected Plan: 3740437391
PRO
PAUSE hit "return" to execute idempotent script kiev/cs_sprf_kiev_vcn_events_v2_rgn.sql
@@kiev/cs_sprf_kiev_vcn_events_v2_rgn.sql
--
@@cs_internal/&&cs_set_container_to_curr_pdb.