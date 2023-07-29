DECLARE
  l_name VARCHAR2(64);
  l_sql_text CLOB := :cs_sql_text; -- for some bizarre reason we cannot simply pass :cs_sql_text into DBMS_SQLDIAG.create_sql_patch!
BEGIN
  -- see also PLSQL_CCFLAGS
  $IF DBMS_DB_VERSION.ver_le_12_1
  $THEN
    --DBMS_SQLDIAG_INTERNAL.i_create_patch(sql_id => '&&cs_sql_id.', hint_text => q'[&&hints_text.]', name => 'cs_&&cs_sql_id.', description => q'[cs_spch_create.sql /*+ &&hints_text. */ &&cs_reference_sanitized. &&who_am_i.]'); -- 12c (this api requires the sql to be in memory)
    DBMS_SQLDIAG_INTERNAL.i_create_patch(sql_text => l_sql_text, hint_text => q'[&&hints_text.]', name => 'cs_&&cs_sql_id._'||TO_CHAR(SYSDATE, 'MMDD_HH24MISS'), description => q'[cs_spch_create.sql /*+ &&hints_text. */ &&cs_reference_sanitized. &&who_am_i.]'); -- 12c
  $ELSE
    --l_name := DBMS_SQLDIAG.create_sql_patch(sql_id => '&&cs_sql_id.', hint_text => q'[&&hints_text.]', name => 'cs_&&cs_sql_id.', description => q'[cs_spch_create.sql /*+ &&hints_text. */ &&cs_reference_sanitized. &&who_am_i.]'); -- 19c (this api requires the sql to be in memory)
    l_name := DBMS_SQLDIAG.create_sql_patch(sql_text => l_sql_text, hint_text => q'[&&hints_text.]', name => 'cs_&&cs_sql_id._'||TO_CHAR(SYSDATE, 'MMDD_HH24MISS'), description => q'[cs_spch_create.sql /*+ &&hints_text. */ &&cs_reference_sanitized. &&who_am_i.]'); -- 19c
  $END
  NULL;
END;
/