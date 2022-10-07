DECLARE
  is_correct CHAR(1);
BEGIN
  $IF DBMS_DB_VERSION.ver_le_12_1
  $THEN
    NULL;
  $ELSE
    SELECT CASE WHEN COUNT(*) = 1 THEN 'Y' ELSE 'N' END INTO is_correct FROM v$system_parameter WHERE name = 'cursor_invalidation' AND value = 'IMMEDIATE';
    IF is_correct = 'N' THEN
      EXECUTE IMMEDIATE 'alter system set cursor_invalidation=IMMEDIATE scope=both';
    END IF;
  $END
  NULL;
END;
/