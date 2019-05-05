SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 SERVEROUT OFF;
--
COL host NEW_V host NOPRI;
SELECT SYS_CONTEXT('USERENV','HOST') host FROM DUAL;
COL machine_prefix FOR A50;
COL servers FOR 999,990;
COL sessions FOR 999,990;
COL last_call_secs FOR 999,999,990 HEA 'LAST_CALL|SECONDS';
--
BREAK ON REPORT;
COMPUTE SUM LABEL 'TOTAL' OF servers sessions ON REPORT;
--
PRO HOST: &&host.
PRO ~~~~~
SELECT SUBSTR(machine, 1, INSTR(SUBSTR(machine, 1, INSTR(machine, '0')), '-', -1))||'*' machine_prefix, type, status, 
       COUNT(DISTINCT machine) servers, COUNT(*) sessions, MIN(last_call_et) last_call_secs
  FROM v$session
 GROUP BY
       SUBSTR(machine, 1, INSTR(SUBSTR(machine, 1, INSTR(machine, '0')), '-', -1))||'*', type, status
 ORDER BY
       SUBSTR(machine, 1, INSTR(SUBSTR(machine, 1, INSTR(machine, '0')), '-', -1))||'*', type, status
/
--
CLEAR BREAK COMPUTE;
--