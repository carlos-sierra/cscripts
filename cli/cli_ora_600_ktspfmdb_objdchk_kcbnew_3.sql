SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS.FF3';
COL originating_timestamp FOR A23;
COL container_name FOR A30;
COL detailed_location FOR A100;
SELECT originating_timestamp, container_name, detailed_location
FROM x$dbgalertext WHERE problem_key = 'ORA 600 [ktspfmdb:objdchk_kcbnew_3]' ORDER BY originating_timestamp;
--

COL cnt FOR 999990;
COL container_name FOR A30;
COL min_time FOR A23;
COL max_time FOR A23;
-- SELECT container_name, COUNT(*) AS cnt, MIN(originating_timestamp) AS min_time, MAX(originating_timestamp) AS max_time FROM x$dbgalertext WHERE problem_key = 'ORA 600 [ktspfmdb:objdchk_kcbnew_3]' GROUP BY container_name ORDER BY container_name;
SELECT * FROM x$dbgalertext WHERE problem_key = 'ORA 600 [ktspfmdb:objdchk_kcbnew_3]' ORDER BY originating_timestamp;
/*
+--------------------------------+
|                           addr : 00007F85917234B8
|                           indx : 1297741
|                        inst_id : 1
|                         con_id : 41
|          originating_timestamp : 2021-12-03T21:08:24.166
|           normalized_timestamp :
|                organization_id : oracle
|                   component_id : rdbms
|                        host_id : iod-db-kiev-01005.node.ad1.eu-frankfurt-1
|                   host_address : 10.192.39.2
|                   message_type : 2
|                  message_level : 1
|                     message_id : 872775673
|                  message_group : Generic Internal Error
|                      client_id :
|                      module_id :
|                     process_id : 20445
|                      thread_id :
|                        user_id :
|                    instance_id :
|              detailed_location : /u01/app/oracle/diag/rdbms/kiev02a1_b/kiev02a1/trace/kiev02a1_ora_20445.trc
|                    problem_key : ORA 600 [ktspfmdb:objdchk_kcbnew_3]
|               upstream_comp_id :
|             downstream_comp_id : CACHE_RCV
|           execution_context_id :
|     execution_context_sequence : 0
|              error_instance_id : 1354231
|        error_instance_sequence : 0
|                        version : 0
|                   message_text : Errors in file /u01/app/oracle/diag/rdbms/kiev02a1_b/kiev02a1/trace/kiev02a1_ora_20445.trc  (incident=1354231) (PDBNAME=DBAAS_MARS_COLLECTOR):
ORA-00600: internal error code, arguments: [ktspfmdb:objdchk_kcbnew_3], [], [], [], [], [], [], [], [], [], [], []

|              message_arguments : name='PDBNAME' value='DBAAS_MARS_COLLECTOR'
|        supplemental_attributes :
|           supplemental_details :
|                      partition : 50
|                      record_id : 1297742
|                        con_uid : 748945135
|                 container_name : DBAAS_MARS_COLLECTOR
|                   attention_id : 0
|                      id_suffix :
|                   operation_id :
|                     cause_text :
|                    action_text :
|              oracle_process_id : 0
|                    database_id :
|                         sql_id :
|                     session_id :
|                      impact_id :
|                   impact_scope :
|                     call_stack :
|                          flags : 0
+--------------------------------+
*/



