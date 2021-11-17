CREATE OR REPLACE PACKAGE BODY app_user.wf_admin AS
/* $Header: wf_admin.pks.sql 2021-03-11T23:06:04 carlos.sierra $ */

/* ------------------------------------------------------------------------------------ */ 

FUNCTION get_numeric_hash (
    p_expr       IN VARCHAR2,
    p_max_bucket IN INTEGER DEFAULT 1073741823 -- [{1073741823}|1-2147483647] note: 1073741823 = POWER(2, 30) - 1, 2147483647 = POWER(2, 31) - 1 and 4294967295 = POWER(2, 32) - 1 
)
RETURN INTEGER
DETERMINISTIC
IS
  l_hash INTEGER;
BEGIN
    SELECT ORA_HASH(p_expr, p_max_bucket) INTO l_hash FROM DUAL; -- ORA_HASH has to be called from within a SQL statement!
    RETURN l_hash;
END get_numeric_hash;

/* ------------------------------------------------------------------------------------ */ 

FUNCTION lock_request (
    p_lockname      IN VARCHAR2,
    p_timeout       IN INTEGER      DEFAULT 1 -- [{1}|1-32767] seconds
)
RETURN INTEGER -- [0-5] 0:Success, 1:Timeout, 2:Deadlock, 3:Parameter error, 4:Already own lock specified by id or lockhandle, 5:Illegal lock handle
IS
BEGIN
    RETURN DBMS_LOCK.request(id => get_numeric_hash(p_expr => p_lockname), timeout => p_timeout, release_on_commit => TRUE);
END lock_request;

/* ------------------------------------------------------------------------------------ */  

FUNCTION lock_request (
    p_lockname_1    IN VARCHAR2,
    p_lockname_2    IN VARCHAR2     DEFAULT NULL,
    p_lockname_3    IN VARCHAR2     DEFAULT NULL,
    p_timeout       IN INTEGER      DEFAULT 1 -- [{1}|1-32767] seconds
)
RETURN INTEGER -- [0-5] 0:Success, 1:Timeout, 2:Deadlock, 3:Parameter error, 4:Already own lock specified by id or lockhandle, 5:Illegal lock handle
IS
    l_return INTEGER;
BEGIN
    l_return := lock_request(p_lockname => p_lockname_1, p_timeout => p_timeout);
    IF l_return NOT IN (0, 4) OR (p_lockname_2 IS NULL AND p_lockname_3 IS NULL) THEN
        RETURN l_return;
    END IF;
    --
    IF p_lockname_2 IS NOT NULL THEN
        l_return := lock_request(p_lockname => p_lockname_2, p_timeout => p_timeout);
        IF l_return NOT IN (0, 4) OR p_lockname_3 IS NULL THEN
            RETURN l_return;
        END IF;
    END IF;
    --
    IF p_lockname_3 IS NOT NULL THEN
        RETURN lock_request(p_lockname => p_lockname_3, p_timeout => p_timeout);
    END IF;
    --
    RETURN 3; -- Parameter error (unexpected)
END lock_request;

/* ------------------------------------------------------------------------------------ */  

END wf_admin;
/
SHOW ERRORS;
