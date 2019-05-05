DEF cs_lock_seconds = '1';
DEF cs_days = '7';
DEF cs_datetime_full_format = 'YYYY-MM-DD"T"HH24:MI:SS';
--
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 SERVEROUT OFF;
--
COL snap_time FOR A19 HEA 'CAPTURE_TIME';
COL type FOR A8;
COL sid_serial FOR A13 HEA '  SID,SERIAL#'; 
COL ctime FOR 999,999 HEA 'LOCK_SECS';
COL last_call_et FOR 999,999 HEA 'INAC_SECS';
COL lmode FOR A11 HEA 'LOCK MODE';
COL killed FOR A6;
COL death_row FOR A9 HEA '2B_KILLED';
COL logon_time FOR A19;
COL spid FOR 99999;
COL object_id FOR 999999999;
COL username FOR A30;
COL pdb_name FOR A30;
COL sql_exec_start FOR A19;
COL prev_exec_start FOR A19;
--
SELECT TO_CHAR(snap_time, '&&cs_datetime_full_format.') snap_time,
       CASE lmode
       WHEN 0 THEN '0:none'
       WHEN 1 THEN '1:null'
       WHEN 2 THEN '2:row-S'
       WHEN 3 THEN '3:row-X'
       WHEN 4 THEN '4:share'
       WHEN 5 THEN '5:S/row-X'
       WHEN 6 THEN '6:exclusive'
       END lmode,
       machine,
       LPAD(sid,5)||','||serial# sid_serial,
       ctime,
       last_call_et,
       object_id,
       sql_id,
       TO_CHAR(sql_exec_start, '&&cs_datetime_full_format.') sql_exec_start,
       prev_sql_id,
       TO_CHAR(prev_exec_start, '&&cs_datetime_full_format.') prev_exec_start,
       username,
       TO_CHAR(logon_time, '&&cs_datetime_full_format.') logon_time,
       spid,
       osuser,
       pdb_name,
       status
  FROM c##iod.inactive_sessions_audit_trail
 WHERE snap_time > SYSDATE - TO_NUMBER('&&cs_days.')
   AND pty IN (1, 2)
   AND killed = 'Y'
   AND ctime >= TO_NUMBER('&&cs_lock_seconds.')
   AND LOWER(machine) LIKE '%-mac%'
 ORDER BY
       snap_time
/
