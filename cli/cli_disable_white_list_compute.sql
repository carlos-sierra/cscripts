ALTER SESSION SET CONTAINER = CDB$ROOT;

-- TABLE_REDEFINITION | ONLINE_INDEX_REBUILD | GATHER_TABLE_STATS

DELETE C##IOD.exceptions_black_list WHERE reference = 'Reduce hard-parse frequency';

COMMIT;

COL CONTAINER NEW_V CONTAINER;
SELECT name AS CONTAINER FROM v$containers WHERE name IN ('COMPUTE', 'COMPUTEAPI');

ALTER SESSION SET CONTAINER = &&CONTAINER.;

COL OWNER NEW_V OWNER;
SELECT OWNER FROM dba_tables WHERE table_name = 'INSTANCES';

EXEC DBMS_STATS.unlock_table_stats('&&OWNER.', 'INSTANCES');
EXEC DBMS_STATS.unlock_table_stats('&&OWNER.', 'INSTANCEATTRIBUTES');
EXEC DBMS_STATS.unlock_table_stats('&&OWNER.', 'VMIATTACHMENT');
EXEC DBMS_STATS.unlock_table_stats('&&OWNER.', 'KIEVSNAPSHOTMETADATA');
EXEC DBMS_STATS.unlock_table_stats('&&OWNER.', 'HYPERVISORS');
EXEC DBMS_STATS.unlock_table_stats('&&OWNER.', 'HOSTS');
EXEC DBMS_STATS.unlock_table_stats('&&OWNER.', 'BUMPCARD');
EXEC DBMS_STATS.unlock_table_stats('&&OWNER.', 'VOLUMEATTACHMENTS');

QUIT;

-- IAD3/HYD/AMS/YUL
-- iod-db-03012.node.ad3.us-ashburn-1 iod-db-01314.node.ad1.ap-hyderabad-1 iod-db-01309.node.ad1.eu-amsterdam-1 iod-db-01308.node.ad1.ca-montreal-1
--   COMPUTE                        OC1   IAD AD1    IOD03A1                 21.003        577.912      282 kiev-compute.svc.ad1.us-ashburn-1/s_compute.ad1.usashburn1                                                     iod-db-01004.node.ad1.us-ashburn-1
--   COMPUTE                        OC1   IAD AD2    IOD02A2                 11.807        495.515      259 kiev-compute.svc.ad2.us-ashburn-1/s_compute.ad2.usashburn1                                                     iod-db-02004.node.ad2.us-ashburn-1
-- * COMPUTE                        OC1   IAD AD3    IOD03A3                 17.325        491.149      352 kiev-compute.svc.ad3.us-ashburn-1/s_compute.ad3.usashburn1                                                     iod-db-03012.node.ad3.us-ashburn-1
--   COMPUTEAPI                     OC1   HYD RGN    KIEV02RG                 0.062          2.713       46 kiev-computeapi.svc.ap-hyderabad-1/s_computeapi.aphyderabad1                                                   iod-db-kiev-01302.node.ad1.ap-hyderabad-1
-- * COMPUTEAPI                     OC1   HYD AD1    IOD01A1                  3.897        126.606      235 kiev-computeapi.svc.ad1.ap-hyderabad-1/s_computeapi.ad1.aphyderabad1                                           iod-db-01314.node.ad1.ap-hyderabad-1
--   COMPUTEAPI                     OC1   AMS RGN    KIEV02RG                 0.109          3.464       51 kiev-computeapi.svc.eu-amsterdam-1/s_computeapi.euamsterdam1                                                   iod-db-kiev-01302.node.ad1.eu-amsterdam-1
-- * COMPUTEAPI                     OC1   AMS AD1    IOD01A1                  5.708        187.261      250 kiev-computeapi.svc.ad1.eu-amsterdam-1/s_computeapi.ad1.euamsterdam1                                           iod-db-01309.node.ad1.eu-amsterdam-1
--   COMPUTEAPI                     OC1   YUL RGN    KIEV02RG                 0.057          3.109       42 kiev-computeapi.svc.ca-montreal-1/s_computeapi.camontreal1                                                     iod-db-kiev-01301.node.ad1.ca-montreal-1
-- * COMPUTEAPI                     OC1   YUL AD1    KIEV01A1                 3.667        112.190       96 kiev-computeapi.svc.ad1.ca-montreal-1/s_computeapi.ad1.camontreal1                                             iod-db-01308.node.ad1.ca-montreal-1

-- Connection strings:
-- •	IAD3: "jdbc:oracle:thin:@//kiev-compute.svc.ad3.us-ashburn-1/s_compute.ad3.usashburn1" -> IAD IOD03A3 -> iod-db-03012.node.ad3.us-ashburn-1
-- •	AMS: "jdbc:oracle:thin:@//kiev-computeapi.svc.ad1.eu-amsterdam-1/s_computeapi.ad1.euamsterdam1" -> AMS IOD01A1 -> iod-db-01309.node.ad1.eu-amsterdam-1
-- •	HYD: "jdbc:oracle:thin:@//kiev-computeapi.svc.ad1.ap-hyderabad-1/s_computeapi.ad1.aphyderabad1" -> HYD IOD01A1 -> iod-db-01314.node.ad1.ap-hyderabad-1
-- •	YUL: "jdbc:oracle:thin:@//kiev-computeapi.svc.ad1.ca-montreal-1/s_computeapi.ad1.camontreal1" -> YUL KIEV01A1 -> iod-db-01308.node.ad1.ca-montreal-1

-- LOCALE       : OC1 EU-AMSTERDAM-1 AMS AD1
-- DATABASE     : IOD01A1 (19.0.0.0.0) CONTAINERS:3 STARTUP:2021-03-24T18:24:16
-- CONTAINER    : COMPUTEAPI (3) READ WRITE CREATED:2021-02-18T18:19:02
-- CONNECT_STRNG: kiev-computeapi.svc.ad1.eu-amsterdam-1/s_computeapi.ad1.euamsterdam1
-- HOST         : iod-db-01309.node.ad1.eu-amsterdam-1 SHAPE:x7.enclave2-104 DISK:raid10

-- LOCALE       : OC1 AP-HYDERABAD-1 HYD AD1
-- DATABASE     : IOD01A1 (19.0.0.0.0) CONTAINERS:3 STARTUP:2021-03-23T17:06:50
-- CONTAINER    : COMPUTEAPI (3) READ WRITE CREATED:2021-02-23T18:52:24
-- CONNECT_STRNG: kiev-computeapi.svc.ad1.ap-hyderabad-1/s_computeapi.ad1.aphyderabad1
-- HOST         : iod-db-01314.node.ad1.ap-hyderabad-1 SHAPE:x7.enclave2-104 DISK:raid10

-- LOCALE       : OC1 CA-MONTREAL-1 YUL AD1
-- DATABASE     : IOD01A1 (19.0.0.0.0) CONTAINERS:3 STARTUP:2021-03-29T12:05:12
-- CONTAINER    : COMPUTEAPI (3) READ WRITE CREATED:2021-03-29T15:17:56
-- CONNECT_STRNG: kiev-computeapi.svc.ad1.ca-montreal-1/s_computeapi.ad1.camontreal1
-- HOST         : iod-db-01308.node.ad1.ca-montreal-1 SHAPE:x7.enclave2-104 DISK:raid10

-- LOCALE       : OC1 EU-AMSTERDAM-1 AMS AD1
-- DATABASE     : KIEV01A1 (12.1.0.2.0) CONTAINERS:86 STARTUP:2021-03-24T18:49:31
-- CONTAINER    : COMPUTEWORKFLOWSERVER (55) READ WRITE CREATED:2019-09-25T21:34:50
-- CONNECT_STRNG: kiev-computeworkflowserver.svc.ad1.eu-amsterdam-1/s_computeworkflowserver.ad1.euamsterdam1
-- HOST         : iod-db-01301.node.ad1.eu-amsterdam-1 SHAPE:x7.enclave2-104 DISK:raid10

-- LOCALE       : OC1 AP-HYDERABAD-1 HYD AD1
-- DATABASE     : KIEV01A1 (12.1.0.2.0) CONTAINERS:78 STARTUP:2021-03-23T17:24:26
-- CONTAINER    : COMPUTE_VMI_WF (58) READ WRITE CREATED:2020-03-09T22:18:13
-- CONNECT_STRNG: kiev-compute-vmi-wf.svc.ad1.ap-hyderabad-1/s_compute_vmi_wf.ad1.aphyderabad1
-- HOST         : iod-db-01302.node.ad1.ap-hyderabad-1 SHAPE:x7.enclave2-104 DISK:raid10

-- LOCALE       : OC1 CA-MONTREAL-1 YUL AD1
-- DATABASE     : KIEV01A1 (12.1.0.2.0) CONTAINERS:76 STARTUP:2021-03-25T16:11:52
-- CONTAINER    : COMPUTEWORKFLOWSERVER (38) READ WRITE CREATED:2019-12-07T22:52:52
-- CONNECT_STRNG: kiev-computeworkflowserver.svc.ad1.ca-montreal-1/s_computeworkflowserver.ad1.camontreal1
-- HOST         : iod-db-01302.node.ad1.ca-montreal-1 SHAPE:x7.enclave2-104 DISK:raid10

-- @cli/cli_disable_white_list_compute.sql