SET SERVEROUT ON;
DECLARE
  l_schema_count INTEGER;
  l_schema_version VARCHAR2(16);
BEGIN
  SELECT COUNT(*) INTO l_schema_count FROM dba_tables WHERE table_name = 'KIEVDATASTOREMETADATA';
  IF l_schema_count > 1 THEN
    FOR i IN (SELECT owner FROM dba_tables WHERE table_name = 'KIEVDATASTOREMETADATA' ORDER BY owner)
    LOOP
      EXECUTE IMMEDIATE 'SELECT schemaversion FROM '||i.owner||'.KievDataStoreMetadata' INTO l_schema_version;
      DBMS_OUTPUT.put_line(RPAD(i.owner, 31)||l_schema_version);
    END LOOP;
  END IF;
END;
/
