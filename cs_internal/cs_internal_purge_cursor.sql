DEF p_sql_id = '&1.';
UNDEF 1;
-- purge cursor
DECLARE
  l_signature NUMBER;
  l_sql_text CLOB;
  l_name VARCHAR2(64);
BEGIN
  -- get signature and sql_text
  SELECT exact_matching_signature AS signature, sql_fulltext AS sql_text INTO l_signature, l_sql_text FROM v$sql WHERE sql_id = '&&p_sql_id.' AND ROWNUM = 1;
  -- backup existing pacth
  FOR i IN (SELECT name FROM dba_sql_patches WHERE signature = l_signature AND category = 'DEFAULT')
  LOOP
    $IF DBMS_DB_VERSION.ver_le_12_1
    $THEN
      DBMS_SQLDIAG.alter_sql_patch(name => i.name, attribute_name => 'CATEGORY', value => 'PURGE'); -- 12c
    $ELSE
      DBMS_SQLDIAG.alter_sql_patch(name => i.name, attribute_name => 'CATEGORY', attribute_value => 'PURGE'); -- 19c
    $END
  END LOOP;
  -- create dummy patch
  $IF DBMS_DB_VERSION.ver_le_12_1
  $THEN
    DBMS_SQLDIAG_INTERNAL.i_create_patch(sql_text => l_sql_text, hint_text => 'NULL', name => 'PURGE_&&p_sql_id.'); -- 12c
  $ELSE
    l_name := DBMS_SQLDIAG.create_sql_patch(sql_text => l_sql_text, hint_text => 'NULL', name => 'PURGE_&&p_sql_id.'); -- 19c
  $END
  -- drop dummy patch
  DBMS_SQLDIAG.drop_sql_patch(name => 'PURGE_&&p_sql_id.'); 
  -- restore backup patch
  FOR i IN (SELECT name FROM dba_sql_patches WHERE signature = l_signature AND category = 'PURGE')
  LOOP
    $IF DBMS_DB_VERSION.ver_le_12_1
    $THEN
      DBMS_SQLDIAG.alter_sql_patch(name => i.name, attribute_name => 'CATEGORY', value => 'DEFAULT'); -- 12c
    $ELSE
      DBMS_SQLDIAG.alter_sql_patch(name => i.name, attribute_name => 'CATEGORY', attribute_value => 'DEFAULT'); -- 19c
    $END
  END LOOP;
  -- report
  DBMS_OUTPUT.put_line('&&p_sql_id. purged using a transient sql patch');
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.put_line('&&p_sql_id. not found in v$sql');
END;
/
-- purge cursor
DECLARE
  l_name     VARCHAR2(64);
BEGIN
  SELECT address||','||hash_value INTO l_name FROM v$sqlarea WHERE sql_id = '&&p_sql_id.' AND ROWNUM = 1; -- there are cases where it comes back with > 1 row!!!
  SYS.DBMS_SHARED_POOL.PURGE(name => l_name, flag => 'C', heaps => 1); -- not always does the job
  -- report
  DBMS_OUTPUT.put_line('&&p_sql_id. purged using an api on parent cursor');
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.put_line('&&p_sql_id. not found in v$sqlarea');
END;
/
--
UNDEF p_sql_id;