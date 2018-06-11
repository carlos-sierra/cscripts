SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
SET LIN 1000;

ACC days PROMPT 'Enter past N days of history to consider (default 1): '

ALTER SESSION SET nls_date_format = 'YYYY-MM-DD"T"HH24:MI:SS';
COL sid FOR 99999;
COL serial# FOR 9999999;
COL spid FOR 99999;
COL logon_time FOR A19;
COL ctime FOR 99999;
COL type FOR A4;
COL lmode FOR 99999;
COL con_id FOR 999999;
COL reason FOR A30;
COL killed FOR A6;
COL pty 999;
COL death_row FOR A2 HEA 'DR';
BREAK ON pty SKIP ON death_row SKIP ON con_id SKIP PAGE ON pdb_name SKIP ON machine SKIP 1;

COL current_time NEW_V current_time FOR A15;
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;
COL x_host_name NEW_V x_host_name;
SELECT host_name x_host_name FROM v$instance;
COL x_db_name NEW_V x_db_name;
SELECT name x_db_name FROM v$database;
COL x_container NEW_V x_container;
SELECT 'NONE' x_container FROM DUAL;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') x_container FROM DUAL;

SPO inactive_sessions_hist_&&x_db_name._&&x_host_name._&&current_time..txt;
PRO HOST: &&x_host_name.
PRO DATABASE: &&x_db_name.
PRO PDB: &&x_container.
PRO

SELECT pty,
       death_row,
       con_id,      
       pdb_name,    
       machine,     
       MAX(last_call_et) last_call_et,
       logon_time,  
       CEIL((MAX(snap_time) - logon_time) * 24 * 60 * 60) logon_et,
       MAX(snap_time) snap_time,
       ROUND((SYSDATE - MAX(snap_time)) * 24 * 60 * 60) snap_et,
       sid,         
       serial#,     
       spid,        
       status,      
       killed,      
       MAX(ctime) ctime,       
       type,        
       lmode,       
       service_name,
       osuser,      
       program,     
       module,      
       client_info, 
       prev_sql_id, 
       username,    
       object_id,   
       reason      
  FROM c##iod.inactive_sessions_audit_trail
 WHERE snap_time > SYSDATE - TO_CHAR(NVL('&&days.', '1'))
 GROUP BY
       pty,
       death_row,
       con_id,      
       pdb_name,    
       machine,     
       logon_time,  
       sid,         
       serial#,     
       spid,        
       status,      
       killed,      
       type,        
       lmode,       
       service_name,
       osuser,      
       program,     
       module,      
       client_info, 
       prev_sql_id, 
       username,    
       object_id,   
       reason
 ORDER BY
       pty,
       death_row DESC,
       con_id,      
       pdb_name,    
       machine,     
       last_call_et DESC,
       logon_time
/

SPO OFF;
CLEAR BREAK;
