REM Merges a snapshot of v$active_session_history into C##IOD.iod_active_session_history
select count(*) from c##iod.iod_active_session_history;
EXEC C##IOD.IOD_SESS.snap_ash(p_force => 'Y');
select count(*) from c##iod.iod_active_session_history;