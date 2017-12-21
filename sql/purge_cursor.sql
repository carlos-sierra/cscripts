-- purge_cursor.sql
DECLARE
  l_name     VARCHAR2(64);
  l_sql_text CLOB;
BEGIN
  -- get address, hash_value and sql text
  SELECT address||','||hash_value, sql_fulltext 
    INTO l_name, l_sql_text 
    FROM v$sqlarea 
   WHERE sql_id = '&&sql_id.'
     AND ROWNUM = 1; -- there are cases where it comes back with > 1 row!!!
  -- not always does the job
  SYS.DBMS_SHARED_POOL.PURGE (
    name  => l_name,
    flag  => 'C',
    heaps => 1
  );
  -- create fake sql patch
  SYS.DBMS_SQLDIAG_INTERNAL.I_CREATE_PATCH (
    sql_text    => l_sql_text,
    hint_text   => 'NULL',
    name        => 'purge_&&sql_id.',
    description => 'PURGE CURSOR',
    category    => 'DEFAULT',
    validate    => TRUE
  );
  -- drop fake sql patch
  SYS.DBMS_SQLDIAG.DROP_SQL_PATCH (
    name   => 'purge_&&sql_id.', 
    ignore => TRUE
  );
END;
/
