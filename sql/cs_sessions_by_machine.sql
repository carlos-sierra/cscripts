SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 SERVEROUT OFF;
--
COL host NEW_V host NOPRI;
SELECT SYS_CONTEXT('USERENV','HOST') host FROM DUAL;
COL sessions FOR 999,990;
COL min_last_call_secs FOR 999,999,999,990 HEA 'MIN LAST_CALL|SECONDS';
COL avg_last_call_secs FOR 999,999,999,990 HEA 'AVG LAST_CALL|SECONDS';
--
BREAK ON REPORT;
COMPUTE SUM LABEL 'TOTAL' OF sessions active inactive killed ON REPORT;
--
PRO HOST: &&host.
PRO ~~~~~
WITH
v_session AS (
select /*+ MATERIALIZE NO_MERGE */
s.inst_id,
s.addr AS SADDR,
s.indx AS SID,
s.ksuseser AS SERIAL#,
s.ksuudses AS AUDSID,
s.ksusepro AS PADDR,
s.ksuudlui AS USER#,
s.ksuudlna AS USERNAME,
s.ksuudoct AS COMMAND,
s.ksusesow AS OWNERID, 
decode(s.ksusetrn,hextoraw('00'),null,s.ksusetrn) AS TADDR,
decode(s.ksqpswat,hextoraw('00'),null,s.ksqpswat) AS LOCKWAIT,
decode(bitand(s.ksuseidl,11),1,'ACTIVE',0,decode(bitand(s.ksuseflg,4096),0,'INACTIVE','CACHED'),2,'SNIPED',3,'SNIPED', 'KILLED') AS STATUS,
decode(s.ksspatyp,1,'DEDICATED',2,'SHARED',3,'PSEUDO',4,'POOLED','NONE') AS SERVER,  
s.ksuudsid AS SCHEMA#,
s.ksuudsna AS SCHEMANAME,
s.ksuseunm AS OSUSER,
s.ksusepid AS PROCESS, 
s.ksusemnm AS MACHINE,
s.ksusemnp AS PORT,
s.ksusetid AS TERMINAL,
s.ksusepnm AS PROGRAM, 
decode(bitand(s.ksuseflg,19),17,'BACKGROUND',1,'USER',2,'RECURSIVE','?') AS TYPE, 
s.ksusesql AS SQL_ADDRESS, 
s.ksusesqh AS SQL_HASH_VALUE, 
s.ksusesqi AS SQL_ID, 
decode(s.ksusesch, 65535, to_number(null), s.ksusesch) AS SQL_CHILD_NUMBER,  
s.ksusesesta AS SQL_EXEC_START,  
decode(s.ksuseseid, 0, to_number(null), s.ksuseseid) AS SQL_EXEC_ID,  
s.ksusepsq AS PREV_SQL_ADDR, 
s.ksusepha AS PREV_HASH_VALUE, 
s.ksusepsi AS PREV_SQL_ID,  
decode(s.ksusepch, 65535, to_number(null), s.ksusepch) AS PREV_CHILD_NUMBER,  
s.ksusepesta AS PREV_EXEC_START,  
decode(s.ksusepeid, 0, to_number(null), s.ksusepeid) AS PREV_EXEC_ID, 
decode(s.ksusepeo,0,to_number(null),s.ksusepeo) AS PLSQL_ENTRY_OBJECT_ID, 
decode(s.ksusepeo,0,to_number(null),s.ksusepes) AS PLSQL_ENTRY_SUBPROGRAM_ID,  
decode(s.ksusepco,0,to_number(null),         decode(bitand(s.ksusstmbv, power(2,11)), power(2,11), s.ksusepco,                to_number(null))) AS MODULE,
decode(s.ksusepcs,0,to_number(null),         decode(bitand(s.ksusstmbv, power(2,11)), power(2,11), s.ksusepcs,                to_number(null))) AS MODULE_HASH,  
s.ksuseapp AS ACTION, 
s.ksuseaph AS ACTION_HASH, 
s.ksuseact, 
s.ksuseach, 
s.ksusecli AS CLIENT_INFO, 
s.ksusefix AS FIXED_TABLE_SEQUENCE, 
s.ksuseobj AS ROW_WAIT_OBJ#, 
s.ksusefil AS ROW_WAIT_FILE#, 
s.ksuseblk AS ROW_WAIT_BLOCK#, 
s.ksuseslt AS ROW_WAIT_ROW#,  
s.ksuseorafn AS TOP_LEVEL_CALL#, 
s.ksuseltm AS LOGON_TIME, 
s.ksusectm AS LAST_CALL_ET,
decode(bitand(s.ksusepxopt, 12),0,'NO','YES') AS PDML_ENABLED,
decode(s.ksuseft, 2,'SESSION', 4,'SELECT',8,'TRANSACTIONAL','NONE') AS FAILOVER_TYPE,
decode(s.ksusefm,1,'BASIC',2,'PRECONNECT',4,'PREPARSE','NONE') AS FAILOVER_METHOD,
decode(s.ksusefs, 1, 'YES', 'NO') AS FAILED_OVER,
s.ksusegrp AS RESOURCE_CONSUMER_GROUP,
decode(bitand(s.ksusepxopt,4),4,'ENABLED',decode(bitand(s.ksusepxopt,8),8,'FORCED','DISABLED')) AS PDML_STATUS,
decode(bitand(s.ksusepxopt,2),2,'FORCED',decode(bitand(s.ksusepxopt,1),1,'DISABLED','ENABLED')) AS PDDL_STATUS,
decode(bitand(s.ksusepxopt,32),32,'FORCED',decode(bitand(s.ksusepxopt,16),16,'DISABLED','ENABLED')) AS PQ_STATUS,  
s.ksusecqd AS CURRENT_QUEUE_DURATION, 
s.ksuseclid AS CLIENT_IDENTIFIER,  
decode(s.ksuseblocker,4294967295,'UNKNOWN',  4294967294, 'UNKNOWN',4294967293,'UNKNOWN',4294967292,'NO HOLDER',  4294967291,'NOT IN WAIT','VALID') AS BLOCKING_SESSION_STATUS,
decode(s.ksuseblocker, 4294967295,to_number(null),4294967294,to_number(null), 4294967293,to_number(null), 4294967292,to_number(null),4294967291,  to_number(null),bitand(s.ksuseblocker, 2147418112)/65536) AS BLOCKING_INSTANCE,
decode(s.ksuseblocker, 4294967295,to_number(null),4294967294,to_number(null), 4294967293,to_number(null), 4294967292,to_number(null),4294967291
,  to_number(null),bitand(s.ksuseblocker, 65535)) AS BLOCKING_SESSION,  
decode(s.ksusefblocker,4294967295,'UNKNOWN',  4294967294, 'UNKNOWN',4294967293,'UNKNOWN',4294967292,'NO HOLDER',  4294967291,'NOT IN WAIT','VALID') AS FINAL_BLOCKING_SESSION_STATUS,
decode(s.ksusefblocker,4294967295,to_number(null),4294967294,to_number(null), 4294967293,to_number(null), 4294967292,to_number(null),4294967291,  to_number(null),bitand(s.ksusefblocker, 2147418112)/65536) AS FINAL_BLOCKING_INSTANCE,
decode(s.ksusefblocker,4294967295,to_number(null),4294967294,to_number(null), 4294967293,to_number(null), 4294967292,to_number(null),4294967291,  to_number(null),bitand(s.ksusefblocker, 65535)) AS FINAL_BLOCKING_SESSION,  
w.kslwtseq AS SEQ# ,
w.kslwtevt AS EVENT#,
e.kslednam AS EVENT,
e.ksledp1 AS P1TEXT,
w.kslwtp1 AS P1,
w.kslwtp1r AS P1RAW, 
e.ksledp2 AS P2TEXT,
w.kslwtp2 AS P2,
w.kslwtp2r AS P2RAW,
e.ksledp3 AS P3TEXT,
w.kslwtp3 AS P3,
w.kslwtp3r AS P3RAW, 
e.ksledclassid AS WAIT_CLASS_ID,
e.ksledclass# AS WAIT_CLASS#,
e.ksledclass AS WAIT_CLASS, 
decode(w.kslwtinwait,        0,decode(bitand(w.kslwtflags,256),                 0,-2,                 decode(round(w.kslwtstime/10000),                        0,-1,                        round(w.kslwtstime/10000))),        0) AS WAIT_TIME, 
decode(w.kslwtinwait,0,round((w.kslwtstime+w.kslwtltime)/1000000),  round(w.kslwtstime/1000000)) AS SECONDS_IN_WAIT, 
decode(w.kslwtinwait,1,'WAITING',  decode(bitand(w.kslwtflags,256),0,'WAITED UNKNOWN TIME',   decode(round(w.kslwtstime/10000),0,'WAITED SHORT TIME',    'WAITED KNOWN TIME'))) AS STATE,
w.kslwtstime AS WAIT_TIME_MICRO, 
decode(w.kslwtinwait,0,to_number(null),  decode(bitand(w.kslwtflags,64),64,0,w.kslwttrem)) AS TIME_REMAINING_MICRO, 
w.kslwtltime AS TIME_SINCE_LAST_WAIT_MICRO,
s.ksusesvc AS SERVICE_NAME, 
decode(bitand(s.ksuseflg2,32),32,'ENABLED','DISABLED') AS SQL_TRACE,
decode(bitand(s.ksuseflg2,64),64,'TRUE','FALSE') AS SQL_TRACE_WAITS,
s.con_id
--    DBPERFOCI-205
--    FROM sys.X$KSUSE s
--    , sys.X$KSLWT w
--    , X$KSLED e
--    WHERE 1=1
--    AND S.INDX=W.KSLWTSID(+) -- added (+)
--    --AND BITAND(S.KSUSEFLG,1)<>0 -- commented out since it filtered out RECURSIVE
--    AND BITAND(S.KSUSEFLG,19) IN (17,1,2) -- added to filter on BACKGROUND(17), USER(1) and RECURSIVE(2)
--    --AND BITAND(S.KSSPAFLG,1)<>0 -- commented out since it filtered out RECURSIVE
--    AND S.INST_ID=USERENV('INSTANCE')
--    AND W.KSLWTEVT=E.INDX(+) -- added (+)
FROM sys.X$KSUSE s
, sys.X$KSLWT w
, X$KSLED e
WHERE 1=1
AND BITAND(S.KSUSEFLG,19) IN (17,1,2) -- added to filter on BACKGROUND(17), USER(1) and RECURSIVE(2)
AND BITAND(S.KSSPAFLG,1)<>0
AND S.INST_ID=USERENV('INSTANCE')
AND S.INDX=W.KSLWTSID(+) -- added (+)
AND W.KSLWTEVT=E.INDX(+) -- added (+)
) 
SELECT machine, COUNT(*) sessions, 
       SUM(CASE status WHEN 'ACTIVE' THEN 1 ELSE 0 END) active,
       SUM(CASE status WHEN 'INACTIVE' THEN 1 ELSE 0 END) inactive,
       SUM(CASE status WHEN 'KILLED' THEN 1 ELSE 0 END) killed,
       MIN(last_call_et) AS min_last_call_secs --,
       --ROUND(AVG(last_call_et)) avg_last_call_secs
  FROM v_session
 GROUP BY 
       machine
 ORDER BY
       machine
/
--
CLEAR BREAK COMPUTE;
--