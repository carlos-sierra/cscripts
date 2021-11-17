SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
--
COL customer FOR A50 TRUNC;
COL pdb_name FOR A30 TRUNC;
COL cpu_cores_perc FOR 990.000000000;
COL disk_space_perc FOR 990.000000000;
COL pdb_count_perc FOR 990.000000000;
COL sessions_perc FOR 990.000000000;
COL total_cpu_cores FOR 999,990.000000000;
COL total_size_gbs FOR 999,999,990.000000000;
COL pdb_count FOR 999,990;
COL sessions FOR 999,990;
BREAK ON REPORT;
COMPUTE SUM OF disk_space_perc pdb_count_perc cpu_cores_perc sessions_perc total_cpu_cores total_size_gbs pdb_count sessions ON REPORT;
--
SPO /tmp/iod_fleet_cpu_cores_by_customer.txt
PRO
PRO IOD Fleet - Top Customer as per CPU Cores percent
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
WITH
FUNCTION con_name_to_customer_map (p_con_name IN VARCHAR2)
RETURN VARCHAR2
IS
BEGIN
  IF p_con_name LIKE '%WFAAS%' THEN RETURN 'WFaaS'; END IF;
  IF p_con_name LIKE '%WF' THEN RETURN 'WFaaS'; END IF;
  IF p_con_name LIKE '%WORKFLOW%' THEN RETURN 'WFaaS'; END IF;
  IF p_con_name LIKE 'ACC%MESSAGING%' THEN RETURN 'Messaging'; END IF;
  IF p_con_name LIKE 'ANNOUNCEMENT%' THEN RETURN 'Announcements'; END IF;
  IF p_con_name LIKE 'BLING%' THEN RETURN 'Accounts'; END IF;
  IF p_con_name LIKE 'BLOCKSTORAGE%' THEN RETURN 'Block Storage'; END IF;
  IF p_con_name LIKE 'CEREBROFLEETTRACKER%' THEN RETURN 'BM Card Management'; END IF;
  IF p_con_name LIKE 'COMPARTMENTS%' THEN RETURN 'Compartments'; END IF;
  IF p_con_name LIKE 'COMPUTE%' THEN RETURN 'Compute BMI'; END IF;
  IF p_con_name LIKE 'DBAAS%' THEN RETURN 'DBaaS'; END IF;
  IF p_con_name LIKE 'DNS%' THEN RETURN 'DNS'; END IF;
  IF p_con_name LIKE 'EL%TORO%' THEN RETURN 'ElToro'; END IF;
  IF p_con_name LIKE 'EVENT%' THEN RETURN 'Cloud Events'; END IF;
  IF p_con_name LIKE 'EXECSERVICEORCHESTRATOR%' THEN RETURN 'Exec Service'; END IF;
  IF p_con_name LIKE 'FAAS%' THEN RETURN 'FaaS'; END IF;
  IF p_con_name LIKE 'FAST%' THEN RETURN 'FaaS'; END IF;
  IF p_con_name LIKE 'FLAMINGO%' THEN RETURN 'Flamingo'; END IF;
  IF p_con_name LIKE 'FLEET%' THEN RETURN 'Fleet'; END IF;
  IF p_con_name LIKE 'HOPS%' THEN RETURN 'Hops'; END IF;
  IF p_con_name LIKE 'IDENTITY%' THEN RETURN 'Identity'; END IF;
  IF p_con_name LIKE 'KAAS%' THEN RETURN 'KaaS'; END IF;
  IF p_con_name LIKE 'KIEV%' THEN RETURN 'KaaS'; END IF;
  IF p_con_name LIKE 'KMS%' THEN RETURN 'KMS'; END IF;
  IF p_con_name LIKE 'LIMITS%' THEN RETURN 'Limits'; END IF;
  IF p_con_name LIKE 'LUMBERJACK%' THEN RETURN 'Lumberjack'; END IF;
  IF p_con_name LIKE 'MESSAGING%' THEN RETURN 'Messaging'; END IF;
  IF p_con_name LIKE 'NETWORK%' THEN RETURN 'Network Control Plane (part of Network Automation)'; END IF;
  IF p_con_name LIKE 'NPI%' THEN RETURN 'NPI'; END IF;
  IF p_con_name LIKE 'ODO%' THEN RETURN 'Oracle Data Pipeline (ODP)'; END IF;
  IF p_con_name LIKE 'ONS%' THEN RETURN 'Oracle Notification Service (ONS)'; END IF;
  IF p_con_name LIKE 'ORALB%' THEN RETURN 'LBaaS'; END IF;
  IF p_con_name LIKE 'ORCHESTRATION%' THEN RETURN 'Orchestration'; END IF;
  IF p_con_name LIKE 'OSS%' THEN RETURN 'Oracle Sreaming Service (OSS)'; END IF;
  IF p_con_name LIKE 'PLATFORM%' THEN RETURN 'Scan Platform'; END IF;
  IF p_con_name LIKE 'RQS%' THEN RETURN 'RQS'; END IF;
  IF p_con_name LIKE 'SCCP%' THEN RETURN 'SCCP'; END IF;
  IF p_con_name LIKE 'SECRETS%' THEN RETURN 'Secret Service v2'; END IF;
  IF p_con_name LIKE 'SEC%' THEN RETURN 'Security'; END IF;
  IF p_con_name LIKE 'SERVICE%GATEWAY%' THEN RETURN 'Service Gateway'; END IF;
  IF p_con_name LIKE 'SHERLOCK%' THEN RETURN 'Secret Service v2'; END IF;
  IF p_con_name LIKE 'T2%' THEN RETURN 'Telemetry'; END IF;
  IF p_con_name LIKE 'TANDEN%' THEN RETURN 'Tanden'; END IF;
  IF p_con_name LIKE 'TELEMETRY%' THEN RETURN 'Telemetry'; END IF;
  IF p_con_name LIKE 'TEST%DNS%' THEN RETURN 'DNS'; END IF;
  IF p_con_name LIKE 'VCN%' THEN RETURN 'VCN'; END IF;
  IF p_con_name LIKE 'VPN%' THEN RETURN 'VPN'; END IF;
  IF p_con_name LIKE 'WFS%' THEN RETURN 'WFaaS'; END IF;
  IF p_con_name LIKE 'X%REGION%REPLICATION%' THEN RETURN 'Replication (part of Platform)'; END IF;
  --
  IF p_con_name LIKE 'PULSE%' THEN RETURN 'Pulse'; END IF;
  IF p_con_name LIKE 'PRODSTORE%' THEN RETURN 'Prod Store'; END IF;
  IF p_con_name LIKE 'STOREKEEPER%' THEN RETURN 'Store Keeper'; END IF;
  IF p_con_name LIKE 'COREIAASWORKREQUESTS%' THEN RETURN 'Core IaaS Work Requests'; END IF;
  IF p_con_name LIKE 'PIKAFRONTENDDB%' THEN RETURN 'PIKA Front End'; END IF;
  IF p_con_name LIKE 'PIKA%CONTROLPLANE%' THEN RETURN 'PIKA Control Plane'; END IF;
  IF p_con_name LIKE 'SPLAT%' THEN RETURN 'SPLAT'; END IF;
  IF p_con_name LIKE 'VIRTUALNETWORK%' THEN RETURN 'VCN'; END IF;
  IF p_con_name LIKE '%CASPER%' THEN RETURN 'Object Storage (CASPER)'; END IF;
  IF p_con_name LIKE 'SOTU%' THEN RETURN 'State of the Union'; END IF;
  IF p_con_name LIKE 'PUBLIC_LOG_METERING%' THEN RETURN 'Public Log Metering'; END IF;
  IF p_con_name LIKE '%COMPUTE%' THEN RETURN 'Compute BMI'; END IF;
  IF p_con_name LIKE 'EXECSERVICE%' THEN RETURN 'Exec Service'; END IF;
  IF p_con_name LIKE 'IBEX_COORDINATOR%' THEN RETURN 'IBEX Coordinator'; END IF;
  IF p_con_name LIKE '%KIEV%' THEN RETURN 'KaaS'; END IF;
  RETURN 'Unclassified';
END con_name_to_customer_map;
fleet AS (
SELECT    pdb_name
        , realm
        , region_acronym
        , locale
        , db_name
        , avg_running_sessions
        , total_size_bytes
        , sessions
        , ez_connect_string
        , host_name
        , realm_type_order_by
        , region_order_by
        , locale_order_by
        , ROW_NUMBER() OVER (PARTITION BY ez_connect_string ORDER BY version DESC NULLS LAST) AS rn
FROM    C##IOD.pdb_attributes
)
SELECT    con_name_to_customer_map(pdb_name) AS customer
        --, pdb_name
        , 100 * SUM(avg_running_sessions) / SUM(SUM(avg_running_sessions)) OVER () AS cpu_cores_perc
        , 100 * SUM(total_size_bytes) / SUM(SUM(total_size_bytes)) OVER () AS disk_space_perc
        , 100 * COUNT(*) / SUM(COUNT(*)) OVER () AS pdb_count_perc
        , 100 * SUM(sessions) / SUM(SUM(sessions)) OVER () AS sessions_perc
        , '|' AS "|"
        , SUM(avg_running_sessions) AS total_cpu_cores
        , SUM(total_size_bytes) / POWER(10, 9) AS total_size_gbs
        , COUNT(*) AS pdb_count
        , SUM(sessions) AS sessions
FROM    fleet
WHERE rn = 1
  AND avg_running_sessions > 0
GROUP BY
          con_name_to_customer_map(pdb_name)
        --, pdb_name
ORDER BY
        2 DESC
/
CLEAR BREAK COMPUTE;
SPO OFF;
