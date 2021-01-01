----------------------------------------------------------------------------------------
--
-- File name:   cs_locks_internal.sql
--
-- Purpose:     Locks Summary and Details
--
-- Author:      Carlos Sierra
--
-- Version:     2020/03/19
--
-- Usage:       Execute connected to PDB or CDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_locks_internal.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
--SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
--ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
--ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS.FF6';
--ALTER SESSION SET STATISTICS_LEVEL = 'ALL';
--ALTER SESSION SET "_px_cdb_view_enabled" = FALSE;
--
COL cs9_current_time NEW_V cs9_current_time FOR A19 NOPRI;
SELECT TO_CHAR(SYSDATE) AS cs9_current_time FROM DUAL;
COL type FOR A4;
COL blocker FOR A16;
COL blockee FOR A16;
COL lmode FOR A15;
COL request FOR A15;
COL seconds_in_wait FOR 999,990 HEA 'SECONDS|IN WAIT';
COL object_name FOR A50 TRUNC;
COL line FOR A100 HEA 'Disconnect Command (just as reference, if needed)'TRUNC;
--
BREAK ON blocker SKIP PAGE ON line;
--
PRO
PRO TX/TM Locks Summary (gv$lock) as of &&cs9_current_time.
PRO ~~~~~~~~~~~~~~~~~~~
SELECT blocker_lock.sid||','||blocker_session.serial#||',@'||blocker_session.inst_id AS blocker,
       blocker_lock.type,
       blocker_lock.lmode||':'||CASE blocker_lock.lmode WHEN 0 THEN 'none' WHEN 1 THEN 'null (NULL)' WHEN 2 THEN 'row-S (SS)' WHEN 3 THEN 'row-X (SX)' WHEN 4 THEN 'share (S)' WHEN 5 THEN 'S/Row-X (SSX)' WHEN 6 THEN 'exclusive (X)' END AS lmode,
       blockee_lock.sid||','||blockee_session.serial#||',@'||blockee_session.inst_id AS blockee,
       blockee_lock.request||':'||CASE blockee_lock.request  WHEN 0 THEN 'none' WHEN 1 THEN 'null (NULL)' WHEN 2 THEN 'row-S (SS)' WHEN 3 THEN 'row-X (SX)' WHEN 4 THEN 'share (S)' WHEN 5 THEN 'S/Row-X (SSX)' WHEN 6 THEN 'exclusive (X)' END AS request,
       blockee_session.seconds_in_wait,
       cdb_objects.object_type||' '||cdb_objects.owner||'.'||cdb_objects.object_name AS object_name,
       CASE blocker_session.type WHEN 'USER' THEN 'ALTER SYSTEM DISCONNECT SESSION '''||blocker_lock.sid||','||blocker_session.serial#||',@'||blocker_lock.inst_id||''' IMMEDIATE;' END AS line
  FROM gv$lock blocker_lock,
       gv$lock blockee_lock,
       gv$session blocker_session,
       gv$session blockee_session,
       gv$locked_object locked_object,
       cdb_objects 
 WHERE blocker_lock.block = 1
   AND blockee_lock.id1 = blocker_lock.id1
   AND blockee_lock.id2 = blocker_lock.id2
   AND blockee_lock.request > 0
   AND blocker_session.sid = blocker_lock.sid
   AND blocker_session.inst_id = blocker_lock.inst_id
   AND blockee_session.sid = blockee_lock.sid
   AND blockee_session.inst_id = blockee_lock.inst_id
   AND blockee_session.blocking_session_status = 'VALID'
   AND blocker_session.sid IN (blockee_session.blocking_session, blockee_session.final_blocking_session)
   AND locked_object.session_id = blockee_session.sid
   AND locked_object.inst_id = blockee_lock.inst_id
   AND cdb_objects.object_id = locked_object.object_id
   AND cdb_objects.con_id = locked_object.con_id
 ORDER BY
       blocker_session.seconds_in_wait DESC,
       blockee_session.seconds_in_wait DESC
/
--
CLEAR BREAK;
--
SELECT TO_CHAR(SYSDATE) AS cs9_current_time FROM DUAL;
PRO All Locks Details (gv$session) as of &&cs9_current_time.
PRO ~~~~~~~~~~~~~~~~~
PRO
SET SERVEROUT ON;
VAR root_blockers NUMBER;
VAR blockees NUMBER;
DECLARE
  l_value_max_length INTEGER := 100;
  l_prefix VARCHAR2(4000)     := '|   |                                   | ';
  l_separator  VARCHAR2(4000) := '+---+-----------------------------------+------------------------------------------------------+-'||RPAD('-', l_value_max_length, '-')||'-+';
  l_separator2 VARCHAR2(4000) := '| L | sid,serial#,@inst_id              |                                        source.key(s) | '||RPAD(' value(s)', l_value_max_length, ' ')||' +';
  --
  PROCEDURE put_line (p_line IN VARCHAR2)
  IS
  BEGIN
    IF p_line = l_prefix THEN
      RETURN;
    ELSE
      DBMS_OUTPUT.put_line(p_line);
    END IF;
  END put_line;
  --
  FUNCTION key_value (p_key IN VARCHAR2, p_value IN VARCHAR2)
  RETURN VARCHAR2
  IS
  BEGIN
    IF p_value IS NULL THEN
      RETURN NULL;
    ELSE
      RETURN LPAD(SUBSTR(p_key, 1, 52), 52, ' ')||' : '||RPAD(SUBSTR(p_value, 1, l_value_max_length), l_value_max_length, ' ')||' |';
    END IF;
  END key_value;  
  -- 
  FUNCTION get_lmode_text (p_lmode IN NUMBER)
  RETURN VARCHAR2
  IS
  BEGIN
    IF p_lmode = 0 THEN RETURN 'none';
    ELSIF p_lmode = 1 THEN RETURN 'null (NULL)';
    ELSIF p_lmode = 2 THEN RETURN 'row-S (SS)';
    ELSIF p_lmode = 3 THEN RETURN 'row-X (SX)';
    ELSIF p_lmode = 4 THEN RETURN 'share (S)';
    ELSIF p_lmode = 5 THEN RETURN 'S/Row-X (SSX)';
    ELSIF p_lmode = 6 THEN RETURN 'exclusive (X)';
    ELSE RETURN 'unknown (ERROR)';
    END IF;
  END get_lmode_text;
  --
  PROCEDURE cs_session (p_inst_id IN NUMBER, p_sid IN NUMBER, p_level IN NUMBER)
  IS
    l_blocker_or_blockee VARCHAR2(100);
    l_session gv$session%ROWTYPE;
    l_process gv$process%ROWTYPE;
    l_transaction gv$transaction%ROWTYPE;
    l_lock gv$lock%ROWTYPE;
    l_sql gv$sql%ROWTYPE;
    l_containers v$containers%ROWTYPE;
    l_procedures dba_procedures%ROWTYPE;
    l_objects cdb_objects%ROWTYPE;
  BEGIN
    IF p_level > 9 THEN
      DBMS_OUTPUT.put_line('*** LVL > '||(p_level + 1));
      RETURN;
    ELSIF p_level = 0 THEN
      l_blocker_or_blockee := 'ROOT BLOCKER';
    ELSE
      l_blocker_or_blockee := 'BLOCKEE';
      :blockees := :blockees + 1;
    END IF;
    --
    SELECT * INTO l_session FROM gv$session WHERE inst_id = p_inst_id AND sid = p_sid;
    --
    put_line(l_separator);
    put_line('| '||(p_level + 1)||' |'||LPAD(' ', (2 * p_level) + 1, ' ')||RPAD(p_sid||','||l_session.serial#||',@'||p_inst_id, 15, ' ')||LPAD(' ', 2 * (9 - p_level) + 1, ' ')||'| '||key_value('gv$session.username (role)', l_session.username||' ('||l_blocker_or_blockee||')'));
    put_line(l_prefix||key_value('gv$session.type - status', l_session.type||' - '||l_session.status));
    --
    FOR i IN (SELECT * FROM gv$lock WHERE inst_id = p_inst_id AND sid = p_sid AND type <> 'AE' ORDER BY ctime DESC, block DESC, type DESC, lmode DESC, request DESC)
    LOOP
      put_line(l_prefix||key_value('gv$lock.ctime block type[lmode][request] id1,id2', i.ctime||' '||i.block||' '||i.type||'['||i.lmode||':'||get_lmode_text(i.lmode)||']['||i.request||':'||get_lmode_text(i.request)||'] '||i.id1||','||i.id2));
    END LOOP;
    --
    FOR i IN (SELECT * FROM gv$locked_object WHERE inst_id = p_inst_id AND session_id = p_sid ORDER BY object_id)
    LOOP
      BEGIN
        SELECT * INTO l_objects FROM cdb_objects WHERE con_id = l_session.con_id AND object_id = i.object_id;
      EXCEPTION 
        WHEN NO_DATA_FOUND THEN
          l_objects := NULL;
      END;
      put_line(l_prefix||key_value('gv$locked_object.id[lmode]', i.object_id||'['||i.locked_mode||':'||get_lmode_text(i.locked_mode)||'] '||l_objects.object_type||' '||l_objects.owner||'.'||l_objects.object_name));
    END LOOP;
    --
    put_line(l_prefix||key_value('gv$session.machine', l_session.machine));
    put_line(l_prefix||key_value('gv$session.program', l_session.program));
    --
    IF l_session.sql_id IS NOT NULL THEN
      BEGIN
        SELECT * INTO l_sql FROM gv$sql WHERE inst_id = p_inst_id AND sql_id = l_session.sql_id AND child_number = l_session.sql_child_number ORDER BY last_active_time DESC FETCH FIRST 1 ROW ONLY;
      EXCEPTION 
        WHEN NO_DATA_FOUND THEN
          l_sql := NULL;
      END;
      put_line(l_prefix||key_value('gv$session.sql_id,child_number sql_text', l_session.sql_id||','||l_session.sql_child_number||' '||l_sql.sql_text));
      put_line(l_prefix||key_value('gv$session.sql_exec_start,exec_id', l_session.sql_exec_start||','||l_session.sql_exec_id));
    END IF;
    --
    IF l_session.prev_sql_id IS NOT NULL THEN
      BEGIN
        SELECT * INTO l_sql FROM gv$sql WHERE inst_id = p_inst_id AND sql_id = l_session.prev_sql_id AND child_number = l_session.prev_child_number ORDER BY last_active_time DESC FETCH FIRST 1 ROW ONLY;
      EXCEPTION 
        WHEN NO_DATA_FOUND THEN
          l_sql := NULL;
      END;
      put_line(l_prefix||key_value('gv$session.prev_sql_id,prev_child_number sql_text', l_session.prev_sql_id||','||l_session.prev_child_number||' '||l_sql.sql_text));
      put_line(l_prefix||key_value('gv$session.prev_exec_start,prev_exec_id', l_session.prev_exec_start||','||l_session.prev_exec_id));
    END IF;
    --
    IF l_session.plsql_entry_object_id IS NOT NULL THEN
      BEGIN
        SELECT * INTO l_procedures FROM dba_procedures WHERE object_id = l_session.plsql_entry_object_id AND subprogram_id = l_session.plsql_entry_subprogram_id;
      EXCEPTION 
        WHEN NO_DATA_FOUND THEN
          l_procedures := NULL;
      END;
      put_line(l_prefix||key_value('gv$session.plsql_entry_subprogram_id,plsql_entry_subprogram_id', l_session.plsql_entry_object_id||','||l_session.plsql_entry_subprogram_id||' ('||l_procedures.object_type||' '||l_procedures.owner||'.'||l_procedures.object_name||' '||l_procedures.procedure_name||')'));
    END IF;
    --
    IF l_session.plsql_object_id IS NOT NULL THEN
      BEGIN
        SELECT * INTO l_procedures FROM dba_procedures WHERE object_id = l_session.plsql_object_id AND subprogram_id = l_session.plsql_subprogram_id;
      EXCEPTION 
        WHEN NO_DATA_FOUND THEN
          l_procedures := NULL;
      END;
      put_line(l_prefix||key_value('gv$session.plsql_object_id,plsql_subprogram_id', l_session.plsql_object_id||','||l_session.plsql_subprogram_id||' ('||l_procedures.object_type||' '||l_procedures.owner||'.'||l_procedures.object_name||' '||l_procedures.procedure_name||')'));
    END IF;
    --
    IF l_session.module||l_session.action IS NOT NULL THEN
      put_line(l_prefix||key_value('gv$session.module - action', l_session.module||' - '||l_session.action));
    END IF;
    put_line(l_prefix||key_value('gv$session.client_info', l_session.client_info));
    put_line(l_prefix||key_value('gv$session.client_identifier', l_session.client_identifier));
    --
    IF l_session.row_wait_obj# <> -1 THEN
      BEGIN
        SELECT * INTO l_objects FROM cdb_objects WHERE con_id = l_session.con_id AND object_id = l_session.row_wait_obj#;
      EXCEPTION 
        WHEN NO_DATA_FOUND THEN
          l_objects := NULL;
      END;
      put_line(l_prefix||key_value('gv$session.row_wait_obj#,file#,block#,row# object', l_session.row_wait_obj#||','||l_session.row_wait_file#||','||l_session.row_wait_block#||','||l_session.row_wait_row#||' '||l_objects.object_type||' '||l_objects.owner||'.'||l_objects.object_name));
    END IF;
    --
    IF l_session.blocking_session_status = 'VALID' THEN
      put_line(l_prefix||key_value('gv$session.blocking_session,@instance (status)', l_session.blocking_session||',@'||l_session.blocking_instance||' ('||l_session.blocking_session_status||') BLOCKER'));
    END IF;
    IF l_session.final_blocking_session_status = 'VALID' THEN
      put_line(l_prefix||key_value('gv$session.final_blocking_session,@instance (status)', l_session.final_blocking_session||',@'||l_session.final_blocking_instance||' ('||l_session.final_blocking_session_status||') ROOT BLOCKER'));
    END IF;
    --
    put_line(l_prefix||key_value('gv$session.state - wait_class - event', l_session.state||' - '||l_session.wait_class||' - '||l_session.event));
    --
    IF l_session.p1text <> '0' THEN
      put_line(l_prefix||key_value('gv$session.p1text:p1', l_session.p1text||':'||l_session.p1));
    END IF;
    IF l_session.p2text <> '0' THEN
      put_line(l_prefix||key_value('gv$session.p2text:p2', l_session.p2text||':'||l_session.p2));
    END IF;
    IF l_session.p3text <> '0' THEN
      put_line(l_prefix||key_value('gv$session.p3text:p3', l_session.p3text||':'||l_session.p3));
    END IF;
    --
    put_line(l_prefix||key_value('gv$session.logon_time (last_call_et)', l_session.logon_time||' ('||l_session.last_call_et||')'));
    put_line(l_prefix||key_value('gv$session.wait_time_micro,wait_time,seconds_in_wait', l_session.wait_time_micro||','||l_session.wait_time||','||l_session.seconds_in_wait));
    --
    BEGIN
      SELECT * INTO l_containers FROM v$containers WHERE con_id = l_session.con_id;
    EXCEPTION 
      WHEN NO_DATA_FOUND THEN
        l_containers := NULL;
    END;
    --
    put_line(l_prefix||key_value('v$containers.name(con_id)', l_containers.name||'('||l_session.con_id||')'));
    --
    IF l_session.paddr IS NOT NULL THEN
      BEGIN
        SELECT * INTO l_process FROM gv$process WHERE inst_id = p_inst_id AND addr = l_session.paddr;
      EXCEPTION 
        WHEN NO_DATA_FOUND THEN
          l_process := NULL;
      END;
      put_line(l_prefix||key_value('gv$process.spid', l_process.spid||' (paddr:'||l_session.paddr||')'));
    END IF;
    --
    IF l_session.taddr IS NOT NULL THEN
      BEGIN
        SELECT * INTO l_transaction FROM gv$transaction WHERE inst_id = p_inst_id AND addr = l_session.taddr AND ses_addr = l_session.saddr;
      EXCEPTION 
        WHEN NO_DATA_FOUND THEN
          l_transaction := NULL;
      END;
      put_line(l_prefix||key_value('gv$transaction.start_time', l_transaction.start_time||' (taddr:'||l_session.taddr||')'));
    END IF;
    --
    FOR i IN (SELECT inst_id, sid FROM gv$session WHERE blocking_session_status = 'VALID' AND blocking_instance = p_inst_id AND blocking_session = p_sid ORDER BY wait_time_micro DESC, inst_id, sid)
    LOOP
      cs_session(i.inst_id, i.sid, p_level + 1);
    END LOOP;
  EXCEPTION 
    WHEN NO_DATA_FOUND THEN
      NULL;
  END cs_session;
  --
BEGIN
  :root_blockers := 0;
  :blockees := 0;
  FOR i IN (SELECT MAX(wait_time_micro) AS max_wait_time_micro, final_blocking_instance, final_blocking_session FROM gv$session WHERE final_blocking_session_status = 'VALID' GROUP BY final_blocking_instance, final_blocking_session ORDER BY 1 DESC)
  LOOP
    :root_blockers := :root_blockers + 1;
    put_line(l_separator);
    put_line(l_separator2);
    cs_session(i.final_blocking_instance, i.final_blocking_session, 0);
  END LOOP;
  IF :root_blockers > 0 THEN
    put_line(l_separator);
  END IF;
END;
/
SET SERVEROUT OFF;
--
