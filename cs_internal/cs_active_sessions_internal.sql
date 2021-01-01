SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
SET PAGES 300 LONGC 120;
--
COL sid_nopri NOPRI;
COL rt_lc FOR A12 HEA 'rt:RunTime|lc:LastCall';
COL sql_id_phv FOR A16 HEA 's:SQL_ID|p:Plan Hash';
COL attributes FOR A65 HEA 'c:Container, u:UserName, h:Host, m:Module, a:Action, p:Program|i:ClientInfo, s:State, w:WaitEvent, s:Sid,Session, l:LogonSecs';
COL sql_fulltext FOR A80 HEA 'SQL Text';
COL execution_plan FOR A80 HEA 'Execution Plan';
--
BREAK ON sid_nopri SKIP PAGE;
PRO
PRO Active Sessions
PRO ~~~~~~~~~~~~~~~
--
WITH
FUNCTION execution_plan (p_sql_id IN VARCHAR2, p_child_number IN NUMBER)
RETURN VARCHAR2
IS
  l_execution_plan VARCHAR2(32767) := NULL;
BEGIN
  FOR i IN (SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(p_sql_id, p_child_number, 'BASIC')) WHERE TRIM(plan_table_output) IS NOT NULL)
  LOOP
    IF i.plan_table_output LIKE 'Plan hash value: %' THEN l_execution_plan := NULL; END IF;
    IF l_execution_plan IS NOT NULL THEN l_execution_plan := l_execution_plan||CHR(10); END IF;
    IF LENGTH(l_execution_plan||SUBSTR(i.plan_table_output, 1, 79)) <= 4000 THEN
      l_execution_plan := l_execution_plan||SUBSTR(i.plan_table_output, 1, 79);
    ELSE
       EXIT; -- avoid ORA-06502: PL/SQL: numeric or value error: character string buffer too small
    END IF;
  END LOOP;
  RETURN l_execution_plan;
END execution_plan;
active_user_sessions 
AS (
SELECT /*+ MATERIALIZE NO_MERGE */
         e.con_id
       , e.sql_exec_start
       , e.last_call_et
       , e.sql_id 
       , e.username
       , e.osuser
       , e.machine
       , e.module
       , e.action
       , e.program
       , e.client_info
       , e.state
       , e.wait_class
       , e.event
       , e.seconds_in_wait
       , e.wait_time_micro
       , e.sid
       , e.serial#
       , e.type
       , e.logon_time
       , e.sql_child_number
       , e.audsid
       , p.spid
       , p.pname
  FROM   v$session e,
         v$process p
 WHERE e.status = 'ACTIVE'
  --  AND e.type = 'USER'
   AND e.sid <> SYS_CONTEXT('USERENV', 'SID') -- exclude myself
   AND p.addr = e.paddr
)
SELECT   e.sid AS sid_nopri
       , 'rt:'||TRIM(TO_CHAR((SYSDATE - e.sql_exec_start) * 24 * 3600, '999,999,990'))||CASE WHEN e.sql_exec_start IS NOT NULL THEN 's' ELSE '<null>' END||
          CHR(10)||'lc:'||TRIM(TO_CHAR(e.last_call_et, '999,999,990'))||'s' AS rt_lc
       , CASE WHEN e.sql_id IS NOT NULL THEN 's:'||e.sql_id END||
         CASE WHEN s.plan_hash_value IS NOT NULL THEN CHR(10)||'p:'||s.plan_hash_value END||
         CASE WHEN s.sql_plan_baseline IS NOT NULL THEN CHR(10)||'  spbl' END||
         CASE WHEN s.sql_patch IS NOT NULL THEN CHR(10)||'  spch' END||
         CASE WHEN s.sql_profile IS NOT NULL THEN CHR(10)||'  sprf' END
         AS sql_id_phv
       , 'c:'||SUBSTR(c.name, 1, 64)||
         CHR(10)||'u:'||SUBSTR(NVL(e.username,'<null>'), 1, 64)||' os:'||SUBSTR(NVL(e.osuser,'<null>'), 1, 64)||
         CHR(10)||'h:'||SUBSTR(NVL(e.machine,'<null>'), 1, 64)||
         CASE WHEN e.module IS NOT NULL THEN CHR(10)||'m:'||SUBSTR(e.module, 1, 64) END||
         CASE WHEN e.action IS NOT NULL THEN CHR(10)||'a:'||SUBSTR(e.action, 1, 64) END||
         CASE WHEN e.program IS NOT NULL THEN CHR(10)||'p:'||SUBSTR(e.program, 1, 64) END||
         CASE WHEN e.client_info IS NOT NULL THEN CHR(10)||'i:'||SUBSTR(e.client_info, 1, 64) END||
         CHR(10)||'s:'||e.state||
         CASE WHEN e.wait_time_micro > 0 THEN ' ('||TRIM(TO_CHAR(e.wait_time_micro,'999,999,999,990'))||'us)' END||
         CASE WHEN e.seconds_in_wait > 0 THEN ' ('||TRIM(TO_CHAR(e.seconds_in_wait,'999,990'))||'s)' END||
         CASE WHEN e.wait_class IS NOT NULL THEN CHR(10)||'w:'||e.wait_class||CASE WHEN e.event IS NOT NULL THEN ' - '||e.event END END||
         CHR(10)||'os:'||e.spid||'('||NVL(e.pname,'ORA')||')'||
         CHR(10)||'s:'||e.sid||','||e.serial#||'('||e.type||')'||
         CHR(10)||'l:'||TRIM(TO_CHAR((SYSDATE - e.logon_time) * 24 * 3600, '999,999,990'))||'s'
         AS attributes
       , COALESCE(s.sql_fulltext, s2.sql_fulltext) AS sql_fulltext
       , (SELECT execution_plan(e.sql_id, e.sql_child_number) FROM DUAL WHERE s.plan_hash_value > 0) AS execution_plan
  FROM   active_user_sessions e
         OUTER APPLY (
            SELECT   s.plan_hash_value
                   , s.sql_plan_baseline
                   , s.sql_patch
                   , s.sql_profile
                   , s.sql_fulltext
              FROM v$sql s
             WHERE s.con_id = e.con_id
               AND s.sql_id = e.sql_id
               AND s.child_number = e.sql_child_number
               AND s.object_status = 'VALID' 
               AND s.is_obsolete = 'N' 
               AND s.is_shareable = 'Y'
             ORDER BY s.last_active_time DESC
             FETCH FIRST ROW ONLY ) s
         OUTER APPLY (
            SELECT s.sql_fulltext
              FROM v$sql s
             WHERE s.sql_id = e.sql_id
             FETCH FIRST ROW ONLY ) s2
       , v$containers c
 WHERE c.con_id = e.con_id
 ORDER BY
       e.sql_exec_start NULLS LAST,
       e.last_call_et DESC
/