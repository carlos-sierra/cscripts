SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 SERVEROUT OFF;
--
COL host NEW_V host NOPRI;
SELECT SYS_CONTEXT('USERENV','HOST') host FROM DUAL;
COL sessions FOR 999,990;
COL last_call_secs FOR 999,990 HEA 'LAST_CALL|SECONDS';
--
BREAK ON REPORT;
COMPUTE SUM LABEL 'TOTAL' OF sessions ON REPORT;
--
PRO HOST: &&host.
PRO ~~~~~
SELECT machine, service_name, status, COUNT(*) sessions, MIN(last_call_et) last_call_secs
  FROM v$session
 GROUP BY 
       machine, service_name, status
 ORDER BY
       machine, service_name, status
/
--
CLEAR BREAK COMPUTE;
--