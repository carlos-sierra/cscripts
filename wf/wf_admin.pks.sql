CREATE OR REPLACE PACKAGE app_user.wf_admin AS
/* $Header: wf_admin.pks.sql 2021-03-11T23:06:04 carlos.sierra $ */
--
/* ------------------------------------------------------------------------------------ */ 
--
-- lock_request
--
-- requests a dbms_lock on a lockname
-- ex: 
-- VAR b1 NUMBER;
-- EXEC :b1 := app_user.wf_admin.lock_request(p_lockname => 'some instance name or any other application key', p_timeout => 1);
-- PRINT b1;
--
FUNCTION lock_request (
    p_lockname      IN VARCHAR2,
    p_timeout       IN INTEGER      DEFAULT 1 -- [{1}|1-32767] seconds
)
RETURN INTEGER; -- [0-5] 0:Success, 1:Timeout, 2:Deadlock, 3:Parameter error, 4:Already own lock specified by id or lockhandle, 5:Illegal lock handle
--
/* ------------------------------------------------------------------------------------ */  
--
-- lock_request
--
-- requests a dbms_lock on up to 3 locknames
-- if request succeeds for all N locknames, it returns value 0 or 4, corresponding to last not null lockname
-- if request fails for one of the N locknames, it returns value 1, 2, 3 or 5 corresponding to first not nulled failed lockname
-- 2nd and 3rd locknames could be null, in such case only 1st lockname would be requested
-- ex: 
-- VAR b1 NUMBER;
-- EXEC :b1 := app_user.wf_admin.lock_request(p_lockname_1 => 'key1', p_lockname_2 => 'key2', p_timeout => 1);
-- PRINT b1;
-- 
FUNCTION lock_request (
    p_lockname_1    IN VARCHAR2,
    p_lockname_2    IN VARCHAR2     DEFAULT NULL,
    p_lockname_3    IN VARCHAR2     DEFAULT NULL,
    p_timeout       IN INTEGER      DEFAULT 1 -- [{1}|1-32767] seconds
)
RETURN INTEGER; -- [0-5] 0:Success, 1:Timeout, 2:Deadlock, 3:Parameter error, 4:Already own lock specified by id or lockhandle, 5:Illegal lock handle
--
/* ------------------------------------------------------------------------------------ */  
--
END wf_admin;
/
SHOW ERRORS;
