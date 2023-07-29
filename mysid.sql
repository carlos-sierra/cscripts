-- mysid.sql - Get SID and SPID of own Session
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
--
COL sid FOR 99999;
COL serial# FOR 9999999;
COL spid FOR A6;
--
SELECT s.sid, s.serial#, s.logon_time, p.spid
  FROM v$session s,
       v$process p
 WHERE s.sid = SYS_CONTEXT('USERENV', 'SID')
   AND p.addr = s.paddr
/
