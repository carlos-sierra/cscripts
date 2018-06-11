SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
SET SERVEROUT ON;
/* IOD-7127 IOD-7151 IOD-7180 IOD-7501 ODSI-764

HOST: iod-db-kiev-02006.node.ad2.us-ashburn-1
DATABASE: KIEV02A2

*** COMPUTE ***

            SIGNATURE SQL_HANDLE           PLAN_NAME                         PLAN_ID PLAN_HASH_2  PLAN_HASH PLAN_HASH_FULL ENA ACC FIX REP ADA CREATED             DESCRIPTION
--------------------- -------------------- ------------------------------ ---------- ----------- ---------- -------------- --- --- --- --- --- ------------------- ----------------------------------------------------------------------------------------------------
  1308437012027679556 SQL_12288087b0e22344 SQL_PLAN_14a40hysf48u47e652cfc 2120559868  4019352493 2006526665     4019352493 NO  YES NO  YES NO  2018-01-23T16:06:11 IOD FPZ LVL=03 SQL_ID=grz8rabm79s5j PHV=1699631950 ORA-13831 DISABLED=2018-02-08T19:20:21
  1308437012027679556 SQL_12288087b0e22344 SQL_PLAN_14a40hysf48u4ef9273ad 4019352493  2120559868 1699631950     2120559868 NO  YES NO  YES NO  2018-02-13T16:06:40 IOD FPZ LVL=5 SQL_ID=grz8rabm79s5j PHV=2006526665 CREATED=2018-02-13T16:06:40 ERR-00030: ORA-13831 PID<>PH2 PHV:2006526665 PH:1699631950 PID:4019352493 PH2:2120559868 PHF:2120559868 DISABLED=2018-02-13T16:06:40

*** FLAMINGO_OPS ***

            SIGNATURE SQL_HANDLE           PLAN_NAME                         PLAN_ID PLAN_HASH_2  PLAN_HASH PLAN_HASH_FULL ENA ACC FIX REP ADA CREATED             DESCRIPTION
--------------------- -------------------- ------------------------------ ---------- ----------- ---------- -------------- --- --- --- --- --- ------------------- ----------------------------------------------------------------------------------------------------
 17348404270618741456 SQL_f0c1e9c4b2198ad0 SQL_PLAN_g1hg9skt1m2qh0b077997  185039255  2044567203 3355814645     2044567203 NO  YES YES YES NO  2018-01-23T16:02:03 IOD FPZ LVL=01 SQL_ID=8mrsx6k7cq2ur PHV=4272828202 PHV=4272828202 FIXED=2018-02-06T16:09:06 ORA-13831 DISABLED=2018-02-08T19:20:26
 17348404270618741456 SQL_f0c1e9c4b2198ad0 SQL_PLAN_g1hg9skt1m2qh79dd9ea3 2044567203   185039255 4272828202      185039255 NO  YES NO  YES NO  2018-02-13T16:04:10 IOD FPZ LVL=4 SQL_ID=8mrsx6k7cq2ur PHV=3355814645 CREATED=2018-02-13T16:04:10 ERR-00030: ORA-13831 PID<>PH2 PHV:3355814645 PH:4272828202 PID:2044567203 PH2:185039255 PHF:185039255 DISABLED=2018-02-13T16:04:10

*** WFS_TENANT_A ***

            SIGNATURE SQL_HANDLE           PLAN_NAME                         PLAN_ID PLAN_HASH_2  PLAN_HASH PLAN_HASH_FULL ENA ACC FIX REP ADA CREATED             DESCRIPTION
--------------------- -------------------- ------------------------------ ---------- ----------- ---------- -------------- --- --- --- --- --- ------------------- ----------------------------------------------------------------------------------------------------
 10967614423435453994 SQL_9834cb358e52262a SQL_PLAN_9hd6b6q7549ja36836140  914579776   950852389 3969426919      950852389 NO  YES NO  YES NO  2018-02-13T16:10:02 IOD FPZ LVL=5 SQL_ID=b5tzhaakzjymc PHV=4082536510 CREATED=2018-02-13T16:10:02 ERR-00030: ORA-13831 PID<>PH2 PHV:4082536510 PH:3969426919 PID:914579776 PH2:950852389 PHF:950852389 DISABLED=2018-02-13T16:10:02
 10967614423435453994 SQL_9834cb358e52262a SQL_PLAN_9hd6b6q7549ja841c42e7 2216444647   950852389 3969426919      950852389 NO  YES NO  YES NO  2018-02-13T16:10:05 IOD FPZ LVL=5 SQL_ID=b5tzhaakzjymc PHV=2745389102 CREATED=2018-02-13T16:10:05 ERR-00030: ORA-13831 PID<>PH2 PHV:2745389102 PH:3969426919 PID:2216444647 PH2:950852389 PHF:950852389 DISABLED=2018-02-13T16:10:05

*** WFS_TENANT_B ***

            SIGNATURE SQL_HANDLE           PLAN_NAME                         PLAN_ID PLAN_HASH_2  PLAN_HASH PLAN_HASH_FULL ENA ACC FIX REP ADA CREATED             DESCRIPTION
--------------------- -------------------- ------------------------------ ---------- ----------- ---------- -------------- --- --- --- --- --- ------------------- ----------------------------------------------------------------------------------------------------
 17179354286778768956 SQL_ee6953b426085e3c SQL_PLAN_fwuamqhm0hrjw6f71091d 1869678877   650765665 2101846552      650765665 NO  YES NO  YES NO  2018-02-13T16:10:43 IOD FPZ LVL=5 SQL_ID=fwakmqr9jt1nk PHV=4201362304 CREATED=2018-02-13T16:10:43 ERR-00030: ORA-13831 PID<>PH2 PHV:4201362304 PH:2101846552 PID:1869678877 PH2:650765665 PHF:650765665 DISABLED=2018-02-13T16:10:43
 17179354286778768956 SQL_ee6953b426085e3c SQL_PLAN_fwuamqhm0hrjwcc9fad69 3433016681   650765665 2101846552      650765665 NO  YES NO  YES NO  2018-02-13T16:10:46 IOD FPZ LVL=5 SQL_ID=fwakmqr9jt1nk PHV=4109437391 CREATED=2018-02-13T16:10:46 ERR-00030: ORA-13831 PID<>PH2 PHV:4109437391 PH:2101846552 PID:3433016681 PH2:650765665 PHF:650765665 DISABLED=2018-02-13T16:10:46
                                                                                                                                                                   
                                                                                                                                                                   
HOST: iod-db-kiev-03007.node.ad3.us-ashburn-1
DATABASE: KIEV02A3

*** COMPUTE ***

            SIGNATURE SQL_HANDLE           PLAN_NAME                         PLAN_ID PLAN_HASH_2  PLAN_HASH PLAN_HASH_FULL ENA ACC FIX REP ADA CREATED             DESCRIPTION
--------------------- -------------------- ------------------------------ ---------- ----------- ---------- -------------- --- --- --- --- --- ------------------- ----------------------------------------------------------------------------------------------------
 13898135509278096992 SQL_c0e0189c36c37e60 SQL_PLAN_c1s0smhvc6zm033eb1a4e  871045710  3187859032  934061161     3187859032 NO  YES NO  YES NO  2018-01-21T16:02:06 IOD FPZ LVL=05 SQL_ID=0t6zrcsggvtb8 PHV=4000308831
 13898135509278096992 SQL_c0e0189c36c37e60 SQL_PLAN_c1s0smhvc6zm0f19bc7f3 4053518323  3187859032  934061161     3187859032 NO  YES YES YES NO  2018-01-21T16:02:06 IOD FPZ LVL=05 SQL_ID=0t6zrcsggvtb8 PHV=3895175703 PHV=4053518323 FIXED=2018-02-04T16:04:38


*** FLAMINGO_OPS ***

            SIGNATURE SQL_HANDLE           PLAN_NAME                         PLAN_ID PLAN_HASH_2  PLAN_HASH PLAN_HASH_FULL ENA ACC FIX REP ADA CREATED             DESCRIPTION
--------------------- -------------------- ------------------------------ ---------- ----------- ---------- -------------- --- --- --- --- --- ------------------- ----------------------------------------------------------------------------------------------------
 17348404270618741456 SQL_f0c1e9c4b2198ad0 SQL_PLAN_g1hg9skt1m2qhd688a030 3599278128   185039255 4272828202      185039255 NO  YES YES YES NO  2018-01-24T16:12:34 IOD FPZ LVL=05 SQL_ID=8mrsx6k7cq2ur PHV=3128002370 PHV=3128002370 FIXED=2018-02-08T17:12:18 ORA-13831 DISABLED=2018-02-08T19:21:26

*** WFS_TENANT_A ***

            SIGNATURE SQL_HANDLE           PLAN_NAME                         PLAN_ID PLAN_HASH_2  PLAN_HASH PLAN_HASH_FULL ENA ACC FIX REP ADA CREATED             DESCRIPTION
--------------------- -------------------- ------------------------------ ---------- ----------- ---------- -------------- --- --- --- --- --- ------------------- ----------------------------------------------------------------------------------------------------
   538786350859411508 SQL_077a2754dccde034 SQL_PLAN_0fyj7amfcvs1n09827c54  159546452  3530212915  476282071     3530212915 NO  YES NO  YES NO  2018-02-13T16:03:00 IOD FPZ LVL=3 SQL_ID=9qjb6vhn0tns0 PHV=511366539 CREATED=2018-02-13T16:03:00 ERR-00030: ORA-13831 PID<>PH2 PHV:511366539 PH:476282071 PID:159546452 PH2:3530212915 PHF:3530212915 DISABLED=2018-02-13T16:03:00

*** WFS_TENANT_B ***

            SIGNATURE SQL_HANDLE           PLAN_NAME                         PLAN_ID PLAN_HASH_2  PLAN_HASH PLAN_HASH_FULL ENA ACC FIX REP ADA CREATED             DESCRIPTION
--------------------- -------------------- ------------------------------ ---------- ----------- ---------- -------------- --- --- --- --- --- ------------------- ----------------------------------------------------------------------------------------------------
 10967614423435453994 SQL_9834cb358e52262a SQL_PLAN_9hd6b6q7549ja36836140  914579776  2216444647 2745389102     2216444647 NO  YES NO  YES NO  2018-02-12T21:38:27 IOD FPZ LVL=4 SQL_ID=b5tzhaakzjymc PHV=4082536510 CREATED=2018-02-12T21:38:27 ERR-00030: ORA-13831 PID<>PH2 PHV:4082536510 PH:2745389102 PID:914579776 PH2:2216444647 PHF:2216444647 DISABLED=2018-02-12T21:38:27


HOST: iod-db-kiev-02008.node.ad2.r1
DATABASE: KIEV03A2

*/

COL signature FOR 99999999999999999999;
COL sql_handle FOR A20;
COL plan_name FOR A30;
COL description FOR A100;
SELECT p.signature,
       t.sql_handle,
       o.name plan_name,
       p.plan_id,
       TO_NUMBER(extractvalue(xmltype(p.other_xml),'/*/info[@type = "plan_hash_2"]')) plan_hash_2, -- plan_hash_value ignoring transient object names (must be same than plan_id)
       TO_NUMBER(extractvalue(xmltype(p.other_xml),'/*/info[@type = "plan_hash"]')) plan_hash, -- normal plan_hash_value
       TO_NUMBER(extractvalue(xmltype(p.other_xml),'/*/info[@type = "plan_hash_full"]')) plan_hash_full, -- adaptive plan (must be different than plan_hash_2 on loaded plans)
       DECODE(BITAND(o.flags, 1),   0, 'NO', 'YES') enabled,
       DECODE(BITAND(o.flags, 2),   0, 'NO', 'YES') accepted,
       DECODE(BITAND(o.flags, 4),   0, 'NO', 'YES') fixed,
       DECODE(BITAND(o.flags, 64),  0, 'YES', 'NO') reproduced,
       DECODE(BITAND(o.flags, 256), 0, 'NO', 'YES') adaptive,
       TO_CHAR(a.created, 'YYYY-MM-DD"T"HH24:MI:SS') created,
       a.description
  FROM sqlobj$plan p,
       sqlobj$ o,
       sqlobj$auxdata a,
       sql$text t
 WHERE p.obj_type = 2 /* 1:profile, 2:baseline, 3:patch */
   AND p.id = 1
--   AND p.signature IN (13898135509278096992 /*0t6zrcsggvtb8*/ /* performScanQuery(Hypervisors,HashRangeIndex) */,
--                       16377526110906104223 /*93wsbfysd3tu2*/ /* Populate workspace for transaction GC */, 
--                       17601030278524684402 /*4jyfj07t7sfgd*/ /* performScanQuery(leases,HashRangeIndex) */, 
--                       13101497412861498959 /*a967u2ycz6mrt*/ /* performScanQuery(leases,HashRangeIndex) */, 
--                        7187024993226245181 /*bqsbcjgx6gjzh*/ /* performScanQuery(STRUCTURED,HashRangeIndex) */, 
--                        7430609386916687830 /*g9k3tg0hthcb9*/ /* delete from "COMPUTE"."MLOG$_TEST"*/,
--                       -- R3 KIEV02A2
--                       17179354286778768956 /*fwakmqr9jt1nk*/ /* performSnapshotScanQuery(leases,HashRangeIndex(HRK)) */,
--                       17348404270618741456 /*8mrsx6k7cq2ur*/ /* performScanQuery(HOST_STATES_V3,HashRangeIndex) */,
--                        1308437012027679556 /*grz8rabm79s5j*/ /* performScanQuery(instances,HashRangeIndex) */,
--                       10967614423435453994 /*b5tzhaakzjymc*/ /* performSnapshotScanQuery(leases,HashRangeIndex(HRK)) */,
--                       -- R3 KIEV02A3
--                         538786350859411508 /*9qjb6vhn0tns0*/ /* performSnapshotScanQuery(leases,HashRangeIndex(HRK)) */.
--                       -- R1 KIEV02
--                        6880099737422759572 /*3xn2hya2wnyrb*/ /* performScanQuery(instances,instanceCmptNameIdx) */
--                       )
   AND p.other_xml IS NOT NULL
   AND p.plan_id <> TO_NUMBER(extractvalue(xmltype(p.other_xml),'/*/info[@type = "plan_hash_2"]'))
   --AND TO_NUMBER(extractvalue(xmltype(p.other_xml),'/*/info[@type = "plan_hash_full"]')) = TO_NUMBER(extractvalue(xmltype(p.other_xml),'/*/info[@type = "plan_hash_2"]'))
   AND o.obj_type = 2 /* 1:profile, 2:baseline, 3:patch */
   AND o.signature = p.signature
   AND o.plan_id = p.plan_id
   --AND BITAND(o.flags, 1) = 1 /* enabled */
   AND a.obj_type = 2 /* 1:profile, 2:baseline, 3:patch */
   AND a.signature = p.signature
   AND a.plan_id = p.plan_id
   AND t.signature = p.signature
 ORDER BY
       p.signature,
       t.sql_handle,
       o.name
/
