----------------------------------------------------------------------------------------
--
-- File name:   cs_sprf_verify_wf.sql
--
-- Purpose:     Verifies Current Execution Plan for some KIEV WF SQL in all PDBs
--
-- Author:      Carlos Sierra
--
-- Version:     2021/09/10
--
-- Usage:       Connecting into CDB or PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_sprf_verify_wf.sql
--
-- Notes:       Developed and tested on 12.1.0.2 and 19c.
--              KIEV WF specific
--
---------------------------------------------------------------------------------------
--
PRO
PRO Search String: performScanQuery(leaseDecorators,ae_timestamp_index)%(1 = 1)%ASC
PRO Expected Plan: 610059206
PRO
PAUSE hit "return" to verify current Execution Plan
@@kiev/kiev_fs.sql "performScanQuery(leaseDecorators,ae_timestamp_index)%(1 = 1)%ASC"
--
PRO
PRO Search String: performScanQuery(workflowInstances,I_GC_INDEX)%(1 = 1)%ASC
PRO Expected Plan: 472260233 (or 549294716)
PRO
PAUSE hit "return" to verify current Execution Plan
@@kiev/kiev_fs.sql "performScanQuery(workflowInstances,I_GC_INDEX)%(1 = 1)%ASC"
--
PRO
PRO Search String: performScanQuery(futureWork,resumptionTimestamp)%(1 = 1)%ASC
PRO Expected Plan: 2784194979
PRO
PAUSE hit "return" to verify current Execution Plan
@@kiev/kiev_fs.sql "performScanQuery(futureWork,resumptionTimestamp)%(1 = 1)%ASC"
--
PRO
PRO Search String: populateBucketGCWorkspace%MAPPING_UPDATES_rgn%ASC
PRO Expected Plan: 1172229985 (or 1742292103)
PRO
PAUSE hit "return" to verify current Execution Plan
@@kiev/kiev_fs.sql "populateBucketGCWorkspace%MAPPING_UPDATES_rgn%ASC"
--
PRO
PRO Search String: populateBucketGCWorkspace%EVENTS_V2_rgn%ASC
PRO Expected Plan: 3740437391
PRO
PAUSE hit "return" to verify current Execution Plan
@@kiev/kiev_fs.sql "populateBucketGCWorkspace%EVENTS_V2_rgn%ASC"
--