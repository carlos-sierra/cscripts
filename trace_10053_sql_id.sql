-- trace_10053_sql_id.sql - Turn ON and OFF SQL Trace EVENT 10053 LEVEL 1 on given SQL_ID
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
--
PRO
PRO 1. SQL_ID:
DEF sql_id = '&1.';
UNDEF 1;
--
PRO
PRO CBO Trace (a.k.a. 10053 Event Trace) is same as "SQL_Optimizer" scope. SQL_Compiler is a superset of SQL_Optimizer.
PRO
PRO 2. Scope: [{SQL_Optimizer}|SQL_Compiler]
DEF scope = '&2.';
UNDEF 2;
COL scope NEW_V scope NOPRI;
SELECT CASE WHEN '&&scope.' IN ('SQL_Optimizer', 'SQL_Compiler') THEN '&&scope.' ELSE 'SQL_Optimizer' END AS scope FROM DUAL;
--
PRO
PRO Trace would be enabled these many seconds for a Hard Parse to happen. Default value is recommended.
PRO
PRO 3. Seconds: [{600}|1-3600] 
DEF seconds = '&3.';
UNDEF 3;
COL seconds NEW_V seconds NOPRI;
SELECT CASE WHEN TO_NUMBER('&&seconds.') BETWEEN 1 AND 3600 THEN '&&seconds.' ELSE '600' END AS seconds FROM DUAL;
--
PRO
PRO Cursor needs to be Purged (flushed) one or more times during &&seconds. seconds, in order to trap at least one Hard Parse. Default value is recommended.
PRO
PRO 4. Cursor Purge Count: [{5}|1-10] 
DEF purge_count = '&4.';
UNDEF 4;
COL purge_count NEW_V purge_count NOPRI;
SELECT CASE WHEN TO_NUMBER('&&purge_count.') BETWEEN 1 AND 10 THEN '&&purge_count.' ELSE '5' END AS purge_count FROM DUAL;
--
COL host_name NEW_V host_name NOPRI;
COL trace_dir NEW_V trace_dir NOPRI;
COL timeout NEW_V timeout NOPRI;
SELECT host_name, value AS trace_dir, TO_CHAR(SYSDATE + (&&seconds. / 24 / 3600), 'YYYY-MM-DD"T"HH24:MI:SS') AS timeout FROM v$instance, v$diag_info WHERE name = 'Diag Trace';
--
ALTER SYSTEM SET EVENTS='trace[RDBMS.&&scope..*] off' ;
ALTER SYSTEM SET EVENTS='trace[RDBMS.&&scope..*][SQL:&&sql_id.]' ;
--
PRO
PRO Tracing &&sql_id.. Sleeping for &&seconds. seconds. Timeout at &&timeout.. Please wait...
PRO
PRO To monitor progress from another session:
PRO HOS find &&trace_dir./ -mmin -60 | grep trc | xargs grep -i "(sql_id=&&sql_id.)" | awk -F: '{print $1}' | sort | uniq
PRO
-- purge cursor &&purge_count. times. this is to potentially collect up to &&purge_count. traces, hoping to produce more than one distinct plan.
SET SERVEROUT ON;
@@cs_internal/cs_internal_purge_cursor "&&sql_id."
DECLARE
    l_name     VARCHAR2(64);
BEGIN
    FOR i IN 1 .. &&purge_count. 
    LOOP
        BEGIN
            SELECT address||','||hash_value INTO l_name FROM v$sqlarea WHERE sql_id = '&&sql_id.' AND ROWNUM = 1; -- there are cases where it comes back with > 1 row!!!
            SYS.DBMS_SHARED_POOL.PURGE(name => l_name, flag => 'C', heaps => 1); -- not always does the job
            -- report
            DBMS_OUTPUT.put_line(TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')||' &&sql_id. purged using an api on parent cursor');
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.put_line(TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')||' &&sql_id. not found in v$sqlarea');
        END;
        --
        DBMS_LOCK.sleep(&&seconds. / &&purge_count.);
  END LOOP;
END;
/
SET SERVEROUT OFF;
--
ALTER SYSTEM SET EVENTS='trace[RDBMS.&&scope..*][SQL:&&sql_id.] off' ;
--
HOS mkdir -p /tmp/SQL_ID_&&sql_id.
--*/
PRO please wait...
HOS find &&trace_dir./ -mmin -61 | grep trc | xargs grep -i "(sql_id=&&sql_id.)" | awk -F: '{print $1}' | sort | uniq | xargs -I{} mv "{}" /tmp/SQL_ID_&&sql_id.
--*/
HOS rename ora EVENT_10053_&&sql_id. /tmp/SQL_ID_&&sql_id./*ora*.trc
--*/
HOS chmod 644 /tmp/SQL_ID_&&sql_id./*EVENT_10053_&&sql_id.*.trc
--*/
HOS ls -lt /tmp/SQL_ID_&&sql_id./*EVENT_10053_&&sql_id.*.trc
--*/
PRO
PRO If you want to preserve traces, execute scp command below, from a TERM session running on your Mac/PC:
PRO scp &&host_name.:/tmp/SQL_ID_&&sql_id./*EVENT_10053_&&sql_id.*.trc .
--*/
PRO