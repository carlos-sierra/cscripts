----------------------------------------------------------------------------------------
--
-- File name:   cs_kiev_transaction_keys_report.sql
--
-- Purpose:     KIEV Transaction Keys Report
--
-- Author:      Carlos Sierra
--
-- Version:     2021/04/07
--
-- Usage:       Execute connected to PDB
--
--              Enter KIEV owner and Transaction ID when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_kiev_transaction_keys_report.sql
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
DEF cs_script_name = 'cs_kiev_transaction_keys_report';
--
COL username NEW_V username FOR A30 HEA 'OWNER';
SELECT u.username
  FROM dba_users u
 WHERE u.oracle_maintained = 'N' 
   AND u.username NOT LIKE 'C##'||CHR(37) 
   AND (SELECT COUNT(*) FROM dba_tables t WHERE t.owner = u.username AND t.table_name = 'KIEVDATASTOREMETADATA') > 0
 ORDER BY u.username
/
PRO
COL kiev_owner NEW_V kiev_owner FOR A30 NOPRI;
PRO 1. Enter Owner
DEF kiev_owner = '&1.';
UNDEF 1;
SELECT UPPER(NVL('&&kiev_owner.', '&&username.')) kiev_owner FROM DUAL
/
--
PRO
PRO 2. Enter KIEV Transaction ID
DEF kiev_transaction_id = '&2.';
UNDEF 2;
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&kiev_owner." "&&kiev_transaction_id."
@@cs_internal/cs_spool_id.sql
--
PRO OWNER        : &&kiev_owner.
PRO TRANSACTION  : &&kiev_transaction_id.
--
COL begintime FOR A26 HEA 'Begin Time';
COL endtime FOR A26 HEA 'End Time';
COL latency_ms FOR 9,999,990.000 HEA 'Duration|Latency (ms)';
COL transactionid HEA 'Transaction ID';
COL committransactionid HEA 'Commit|Transaction ID';
COL applicationname HEA 'Application Name';
COL transactionname HEA 'Transaction Name';
COL status HEA 'Status';
COL gcpruned FOR A6 HEA 'GC|Pruned';
--
PRO 
PRO KIEV Transaction &&kiev_transaction_id.
PRO ~~~~~~~~~~~~~~~~
--
WITH
kt AS (
SELECT kt.transactionid,
       kt.applicationname,
       kt.transactionname,
       kt.status,
       kt.begintime,
       kt.endtime,
       1000 * ((86400 * EXTRACT(DAY FROM (kt.endtime - kt.begintime))) + (3600 * EXTRACT(HOUR FROM (kt.endtime - kt.begintime))) + (60 * EXTRACT(MINUTE FROM (kt.endtime - kt.begintime))) + EXTRACT(SECOND FROM (kt.endtime - kt.begintime))) AS latency_ms,
       kt.committransactionid,
       kt.gcpruned
  FROM &&kiev_owner..kievtransactions kt
 WHERE kt.transactionid = &&kiev_transaction_id.
)
SELECT TO_CHAR(kt.begintime, '&&cs_timestamp_full_format.') begintime,
       TO_CHAR(kt.endtime, '&&cs_timestamp_full_format.') endtime,
       kt.latency_ms,
       kt.transactionid,
       kt.committransactionid,
       kt.applicationname,
       kt.transactionname,
       kt.status,
       kt.gcpruned
  FROM kt
 ORDER BY
       kt.endtime
/
--
COL stepnumber FOR 999,990 HEA 'Step|Number';
COL bucketid FOR 999990 HEA 'Bucket|ID';
COL bucket_name HEA 'Bucket Name';
COL indexid FOR 999990 HEA 'Index|ID';
COL indexname HEA 'Index Name';
COL keyread FOR 999999999999 HEA 'Key|Read';
COL keywritten FOR 999999999999 HEA 'Key|Written';
COL uniqueifier FOR 999999999999 HEA 'Unique|Identifier';
COL uniqueifierpresent FOR A7 HEA 'UI|Present'
BREAK ON committransactionid SKIP PAGE DUPL;
PRO 
PRO KIEV Transaction Keys
PRO ~~~~~~~~~~~~~~~~~~~~~
SELECT ktk.transactionid,
       ktk.committransactionid,
       ktk.stepnumber,
       ktk.bucketid,
       kb.name bucket_name,
       ktk.indexid,
       ki.indexname,
       ktk.keyread,
       ktk.keywritten,
       ktk.uniqueifier,
       ktk.uniqueifierpresent
  FROM &&kiev_owner..kievtransactionkeys ktk,
       &&kiev_owner..kievbuckets kb,
       &&kiev_owner..kievindexes ki
 WHERE ktk.transactionid = &&kiev_transaction_id.
   AND kb.bucketid(+) = ktk.bucketid
   AND ki.bucketid(+) = ktk.bucketid
   AND ki.indexid(+) = ktk.indexid
 ORDER BY
       ktk.transactionid,
       ktk.committransactionid,
       ktk.stepnumber
/
CLEAR BREAK;
--
SET HEA OFF;
SPO &&cs_file_name._dynamic.sql
SELECT 'PRO'||CHR(10)||'PRO Bucket: &&kiev_owner..'||kb.name||CHR(10)||'PRO ~~~~~~~'||CHR(10)||
       'SELECT * FROM &&kiev_owner..'||kb.name||' WHERE kievtxnid = '||ktk.committransactionid||';'
  FROM &&kiev_owner..kievtransactionkeys ktk,
       &&kiev_owner..kievbuckets kb,
       &&kiev_owner..kievindexes ki
 WHERE ktk.transactionid = &&kiev_transaction_id.
   AND kb.bucketid(+) = ktk.bucketid
   AND ki.bucketid(+) = ktk.bucketid
   AND ki.indexid(+) = ktk.indexid
 GROUP BY
       kb.name,
       ktk.committransactionid
 ORDER BY
       kb.name,
       ktk.committransactionid
/
SPO OFF;
SET HEA ON;
SPO &&cs_file_name..txt APP
@&&cs_file_name._dynamic.sql
--
PRO
PRO SQL> @&&cs_script_name..sql "&&kiev_owner." "&&kiev_transaction_id."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--