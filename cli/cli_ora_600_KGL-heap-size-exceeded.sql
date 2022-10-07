SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS.FF3';
COL originating_timestamp FOR A23;
COL container_name FOR A30;
COL detailed_location FOR A100;
SELECT originating_timestamp, container_name, detailed_location
FROM x$dbgalertext WHERE problem_key = 'ORA 600 [KGL-heap-size-exceeded]' ORDER BY originating_timestamp;
--

/*
-- COL cnt FOR 999990;
-- COL container_name FOR A30;
-- COL min_time FOR A23;
-- COL max_time FOR A23;
-- SELECT container_name, COUNT(*) AS cnt, MIN(originating_timestamp) AS min_time, MAX(originating_timestamp) AS max_time FROM x$dbgalertext WHERE problem_key = 'ORA 600 [KGL-heap-size-exceeded]' GROUP BY container_name ORDER BY container_name;
SELECT * FROM x$dbgalertext WHERE problem_key = 'ORA 600 [KGL-heap-size-exceeded]' ORDER BY originating_timestamp;
@pr
*/

/*
+--------------------------------+
  1* SELECT * FROM x$dbgalertext WHERE problem_key = 'ORA 600 [KGL-heap-size-exceeded]' ORDER BY originating_timestamp
+--------------------------------+
|                           addr : 00007F7CF2A3D500
|                           indx : 3024075
|                        inst_id : 1
|                         con_id : 208
|          originating_timestamp : 29-JAN-22 04.40.54.942 PM +00:00
|           normalized_timestamp :
|                organization_id : oracle
|                   component_id : rdbms
|                        host_id : iod-db-01312.node.ad1.ap-singapore-1
|                   host_address : 10.192.47.66
|                   message_type : 2
|                  message_level : 1
|                     message_id : 1125574800
|                  message_group : Generic Internal Error
|                      client_id :
|                      module_id :
|                     process_id : 297784
|                      thread_id :
|                        user_id :
|                    instance_id :
|              detailed_location : /u01/app/oracle/diag/rdbms/iod01rg_a/iod01rg/trace/iod01rg_ora_297784.trc
|                    problem_key : ORA 600 [KGL-heap-size-exceeded]
|               upstream_comp_id :
|             downstream_comp_id : LIBCACHE
|           execution_context_id :
|     execution_context_sequence : 0
|              error_instance_id : 311699
|        error_instance_sequence : 0
|                        version : 0
|                   message_text : Errors in file /u01/app/oracle/diag/rdbms/iod01rg_a/iod01rg/trace/iod01rg_ora_297784.trc  (incident=311699) (PDBNAME=FACP_PROD_WF):
ORA-00600: internal error code, arguments: [KGL-heap-size-exceeded], [0x406F8CB88], [0], [524289712], [], [], [], [], [], [], [], []

|              message_arguments : name='PDBNAME' value='FACP_PROD_WF'
|        supplemental_attributes :
|           supplemental_details :
|                      partition : 254
|                      record_id : 3024076
|                        con_uid : 3831534140
|                 container_name : FACP_PROD_WF
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
|                           addr : 00007F7CF2A3D500
|                           indx : 3024081
|                        inst_id : 1
|                         con_id : 208
|          originating_timestamp : 29-JAN-22 04.43.34.676 PM +00:00
|           normalized_timestamp :
|                organization_id : oracle
|                   component_id : rdbms
|                        host_id : iod-db-01312.node.ad1.ap-singapore-1
|                   host_address : 10.192.47.66
|                   message_type : 2
|                  message_level : 1
|                     message_id : 1125574800
|                  message_group : Generic Internal Error
|                      client_id :
|                      module_id :
|                     process_id : 297784
|                      thread_id :
|                        user_id :
|                    instance_id :
|              detailed_location : /u01/app/oracle/diag/rdbms/iod01rg_a/iod01rg/trace/iod01rg_ora_297784.trc
|                    problem_key : ORA 600 [KGL-heap-size-exceeded]
|               upstream_comp_id :
|             downstream_comp_id : LIBCACHE
|           execution_context_id :
|     execution_context_sequence : 0
|              error_instance_id : 311700
|        error_instance_sequence : 0
|                        version : 0
|                   message_text : Errors in file /u01/app/oracle/diag/rdbms/iod01rg_a/iod01rg/trace/iod01rg_ora_297784.trc  (incident=311700) (PDBNAME=FACP_PROD_WF):
ORA-00600: internal error code, arguments: [KGL-heap-size-exceeded], [0x406F8CB88], [0], [524293848], [], [], [], [], [], [], [], []
ORA-00600: internal error code, arguments: [KGL-heap-size-exceeded], [0x406F8CB88], [0], [524289712], [], [], [], [], [], [], [], []

|              message_arguments : name='PDBNAME' value='FACP_PROD_WF'
|        supplemental_attributes :
|           supplemental_details :
|                      partition : 254
|                      record_id : 3024082
|                        con_uid : 3831534140
|                 container_name : FACP_PROD_WF
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
|                           addr : 00007F7CF2A3D500
|                           indx : 3024121
|                        inst_id : 1
|                         con_id : 208
|          originating_timestamp : 29-JAN-22 04.46.00.406 PM +00:00
|           normalized_timestamp :
|                organization_id : oracle
|                   component_id : rdbms
|                        host_id : iod-db-01312.node.ad1.ap-singapore-1
|                   host_address : 10.192.47.66
|                   message_type : 2
|                  message_level : 1
|                     message_id : 1125574800
|                  message_group : Generic Internal Error
|                      client_id :
|                      module_id :
|                     process_id : 297784
|                      thread_id :
|                        user_id :
|                    instance_id :
|              detailed_location : /u01/app/oracle/diag/rdbms/iod01rg_a/iod01rg/trace/iod01rg_ora_297784.trc
|                    problem_key : ORA 600 [KGL-heap-size-exceeded]
|               upstream_comp_id :
|             downstream_comp_id : LIBCACHE
|           execution_context_id :
|     execution_context_sequence : 0
|              error_instance_id : 311701
|        error_instance_sequence : 0
|                        version : 0
|                   message_text : Errors in file /u01/app/oracle/diag/rdbms/iod01rg_a/iod01rg/trace/iod01rg_ora_297784.trc  (incident=311701) (PDBNAME=FACP_PROD_WF):
ORA-00600: internal error code, arguments: [KGL-heap-size-exceeded], [0x406F8CB88], [0], [524297984], [], [], [], [], [], [], [], []
ORA-00600: internal error code, arguments: [KGL-heap-size-exceeded], [0x406F8CB88], [0], [524293848], [], [], [], [], [], [], [], []
ORA-00600: internal error code, arguments: [KGL-heap-size-exceeded], [0x406F8CB88], [0], [524289712], [], [], [], [], [], [], [], []

|              message_arguments : name='PDBNAME' value='FACP_PROD_WF'
|        supplemental_attributes :
|           supplemental_details :
|                      partition : 254
|                      record_id : 3024122
|                        con_uid : 3831534140
|                 container_name : FACP_PROD_WF
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
  1* SELECT * FROM x$dbgalertext WHERE problem_key = 'ORA 600 [KGL-heap-size-exceeded]' ORDER BY originating_timestamp
+--------------------------------+
*/
