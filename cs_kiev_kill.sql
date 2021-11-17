----------------------------------------------------------------------------------------
--
-- File name:   cs_kiev_kill.sql
--
-- Purpose:     Script to mark Kiev sessions to be killed by IOD Session Killer job process
--
-- Author:      Rodrigo Righetti
--
-- Version:     2019/08/06
--
-- Usage:       Execute connected to PDB or CDB.
--
--              Enter SID, SERIAL or SQL_ID when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_kiev_kill.sql.sql
--
-- Notes:       
--
--              Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
WHENEVER SQLERROR EXIT FAILURE;
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 SERVEROUT ON;
--
DEF cs_script_name = 'cs_kiev_kill';
--
COL key1 FOR A13 HEA 'SQL_ID';
COL seconds FOR 999,999,990;
COL secs_avg FOR 999,990;
COL secs_max FOR 999,999,990;
COL sql_text FOR A100 HEA 'SQL_TEXT' TRUNC;
COL reports FOR 999,990;
COL pdbs FOR 9,990;
COL pdb_name FOR A30 TRUNC;
--
--
PRO KIEV SUPPORT TEAM KILL SESSION PROCESS
PRO 
PRO 1. Enter Kill type SID or SQL_ID: [{SID}|SQL_ID]
DEF kill_type = '&1.';
PRO
-- 
SET termout OFF 
COL cs_kill_type NEW_V cs_kill_type;
SELECT CASE WHEN NVL(UPPER(TRIM('&&kill_type.')), 'SID') IN ('SID', 'SQL_ID') THEN 'ok' ELSE 'nook' END cs_kill_type FROM DUAL;
COL cs_op_name NEW_V cs_op_name;
SELECT CASE WHEN NVL(UPPER(TRIM('&&kill_type.')), 'SID') = 'SID' THEN 'KILL_SID' ELSE 'KILL_SQLID' END cs_op_name FROM DUAL;
SET termout ON 
--
BEGIN
  IF '&&cs_kill_type.' = 'nook' THEN
    raise_application_error(-20100,'Kill type invalid: '||'&&kill_type.');
  END IF;
END;
/
--
BEGIN
    IF '&&cs_op_name.' = 'KILL_SID' THEN
        DBMS_OUTPUT.PUT_LINE('Enter SID:');
    ELSE 
        DBMS_OUTPUT.PUT_LINE('Enter SQL_ID:');
    END IF;
END;
/
DEF cs_to_kill = '&2.';
PRO
--
DECLARE
    l_output CLOB;
    l_check  NUMBER;
    l_mysid  NUMBER;
    l_username VARCHAR2(30);
BEGIN
    IF '&&cs_op_name.' = 'KILL_SID' THEN

        BEGIN

            SELECT DISTINCT sid
            INTO l_mysid
            FROM v$mystat;

            SELECT count(1)
            INTO   l_check
            FROM   v$session
            WHERE  sid = '&&cs_to_kill.'
            AND    sid != l_mysid
            AND    USERNAME = 'KIEVGCUSER'; 

           IF l_check = 0 THEN
                raise_application_error(-20101,'You do not have permission to kill this session: '||'&&cs_to_kill.');
           END IF;

        END;

        SELECT 'SID     : '||SID||CHR(10)|| 
               'SERIAL# : '||SERIAL#||CHR(10)||
               'USERNAME: '||USERNAME||CHR(10)||
               'MACHINE : '||MACHINE||CHR(10)||
               'SQL_ID  : '||SQL_ID||CHR(10)||
               'EVENT   : '||EVENT
        INTO l_output
        FROM v$session
        WHERE sid = '&&cs_to_kill.';

        DBMS_OUTPUT.PUT_LINE('Session to be killed: ');
        DBMS_OUTPUT.PUT_LINE('--------------------- ');
        DBMS_OUTPUT.PUT_LINE(l_output);
        DBMS_OUTPUT.PUT_LINE('--------------------- ');
        DBMS_OUTPUT.PUT_LINE('--------------------- ');
        DBMS_OUTPUT.PUT_LINE('Do you want to proceed? [{Y}|N]: ');

    ELSE 
         BEGIN

            SELECT DISTINCT username
            INTO l_username
            FROM v$session
            WHERE sql_id = '&&cs_to_kill.';

            SELECT count(1)
            INTO   l_check
            FROM   v$session
            WHERE  sql_id = '&&cs_to_kill.'
            AND    USERNAME = 'KIEVGCUSER';  

           IF l_check = 0 THEN
                raise_application_error(-20102,'You do not have permission to kill sessions running this SQL_ID: '||'&&cs_to_kill.');
           END IF;

        END;

        SELECT 'Number of Sessions to be killed:'|| count(1)
        INTO l_output
        FROM v$session
        WHERE sql_id = '&&cs_to_kill.';

        DBMS_OUTPUT.PUT_LINE('Session to be killed: ');
        DBMS_OUTPUT.PUT_LINE('--------------------- ');
        DBMS_OUTPUT.PUT_LINE(l_output);
        DBMS_OUTPUT.PUT_LINE('--------------------- ');
        DBMS_OUTPUT.PUT_LINE('--------------------- ');
        DBMS_OUTPUT.PUT_LINE('Do you want to proceed? [{Y}|N]: ');


    END IF;
END;
/
DEF cs_continue = '&3.';
PRO
--
-- 
SET termout OFF 
COL cs_continue_v NEW_V cs_continue_v;
SELECT CASE WHEN NVL(UPPER(TRIM('&&cs_continue.')), 'Y') IN ('Y', 'N') THEN 'ok' ELSE 'nook' END cs_continue_v FROM DUAL;
SET termout ON 
--
BEGIN
  IF '&&cs_continue_v.' = 'nook' THEN
    raise_application_error(-20100,'Invalid Option: '||'&&cs_continue.');
  ELSIF UPPER('&&cs_continue.') = 'N' THEN
    raise_application_error(-20110,'Process terminated per user request: '||'&&cs_continue.');
  END IF;
END;
/
--
PRO
PRO Sessions will be marked for disconnection, it may take a few minutes.
PRO
PRO You can monitor by openning another session and using this query:
PRO ---------------------------------------------------------------------
--
PRO col opname for a20
PRO col target_desc for a20
PRO col target for a20
PRO col message for A60
PRO col username for a20
PRO alter session set nls_date_format='mm/dd/yyyy hh24:mi:ss' 
PRO  SELECT SID, SERIAL#, OPNAME, SOFAR, TOTALWORK,  TARGET_DESC,ELAPSED_SECONDS, MESSAGE, START_TIME
PRO     FROM V$SESSION_LONGOPS 
PRO  WHERE OPNAME LIKE 'KILL%' 
PRO  AND   TARGET_DESC = '&&cs_to_kill.'
PRO
--
DECLARE
        l_rindex    BINARY_INTEGER;
        l_slno      BINARY_INTEGER;
        l_totalwork number;
        l_sofar     number;
        l_obj       BINARY_INTEGER;
        l_killed    number;
        l_op_name   varchar2(10) := '&&cs_op_name.';
        l_mysid     number;
        l_timeout   number := 60;
        l_start     date;
        l_end       number := 0;  
 
BEGIN        

        l_rindex := dbms_application_info.set_session_longops_nohint;
        l_sofar := 0;
        l_totalwork := 1;
        
        l_start := sysdate;

        IF  l_op_name = 'KILL_SID' THEN

            SELECT count(1) 
            INTO l_killed
            FROM v$session
            WHERE sid='&&cs_to_kill.';

            WHILE l_killed >= 1 LOOP
    
            SELECT count(1) 
            INTO l_killed
            FROM v$session
            WHERE sid='&&cs_to_kill.';
    
              IF l_killed = 0 THEN
                l_sofar := l_sofar + 1;
              END IF;

              IF l_timeout <= l_end THEN
                  l_killed := 0;
                  l_sofar := l_sofar + 1;
                  DBMS_OUTPUT.PUT_LINE('--------------------- ');
                  DBMS_OUTPUT.PUT_LINE('Process stopped by timeout, check v$session if session(s) were killed');
                  DBMS_OUTPUT.PUT_LINE('--------------------- ');
              END IF;
    
              dbms_application_info.set_session_longops(l_rindex, l_slno,
                   l_op_name , l_obj, 0, l_sofar, l_totalwork, '&&cs_to_kill.', '');

              dbms_lock.sleep(3);
            
              l_end := (sysdate-l_start)*86400;

            END LOOP;

        ELSE

            SELECT count(1) 
            INTO l_killed
            FROM v$session
            WHERE sql_id='&&cs_to_kill.';
    
            WHILE l_killed >= 1 LOOP
    
            SELECT count(1) 
            INTO l_killed
            FROM v$session
            WHERE sql_id='&&cs_to_kill.';
    
              IF l_killed = 0 THEN
                l_sofar := l_sofar + 1;
              END IF;

                 IF l_timeout <= l_end THEN
                  l_killed := 0;
                  l_sofar := l_sofar + 1;
                  DBMS_OUTPUT.PUT_LINE('--------------------- ');
                  DBMS_OUTPUT.PUT_LINE('Process stopped by timeout, check v$session if session(s) were killed');
                  DBMS_OUTPUT.PUT_LINE('--------------------- ');
              END IF;
    
              dbms_application_info.set_session_longops(l_rindex, l_slno,
                   l_op_name , l_obj, 0, l_sofar, l_totalwork, '&&cs_to_kill.', '');
              
              dbms_lock.sleep(3);
                
              l_end := (sysdate-l_start)*86400;
            END LOOP;

        END IF;
END;
/
--
exec dbms_lock.sleep(2);
--
PRO PROCESS STATUS
PRO ---------------------------------------------------------------------
--
col opname for a20
col target_desc for a20
col target for a20
col message for A60
col username for a20
alter session set nls_date_format='mm/dd/yyyy hh24:mi:ss';
 SELECT SID, SERIAL#, OPNAME, SOFAR, TOTALWORK, TARGET_DESC, ELAPSED_SECONDS, MESSAGE, START_TIME
    FROM V$SESSION_LONGOPS 
 WHERE OPNAME LIKE 'KILL%' 
 AND   TARGET_DESC = '&&cs_to_kill.';
