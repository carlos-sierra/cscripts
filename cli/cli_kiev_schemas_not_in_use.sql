SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
SET SERVEROUT ON;
DECLARE
  l_schema_count INTEGER;
  l_schema_version VARCHAR2(16);
  l_max_endtime DATE;
  l_count INTEGER := 0;
  l_candidate_2b_dropped INTEGER := 0;
  l_message VARCHAR2(128);
BEGIN
  SELECT COUNT(*) INTO l_schema_count FROM dba_tables WHERE table_name = 'KIEVDATASTOREMETADATA';
  IF l_schema_count > 1 THEN
    FOR i IN (SELECT owner FROM dba_tables WHERE table_name = 'KIEVDATASTOREMETADATA' ORDER BY owner)
    LOOP
      l_count := l_count + 1;
      EXECUTE IMMEDIATE 'SELECT schemaversion FROM '||i.owner||'.KievDataStoreMetadata' INTO l_schema_version;
      EXECUTE IMMEDIATE 'SELECT MAX(endtime) FROM '||i.owner||'.KievTransactions' INTO l_max_endtime;
      l_message := NULL;
      IF l_max_endtime < SYSDATE - 30 OR l_max_endtime IS NULL THEN
        l_candidate_2b_dropped := l_candidate_2b_dropped + 1;
        l_message := ' *** schema '||i.owner||' candidate to dropped since it has not been used in '||ROUND(SYSDATE - l_max_endtime)||' days ***';
      END IF;
      DBMS_OUTPUT.put_line('Schemas:'||l_schema_count||' Schema('||l_count||'/'||l_schema_count||'):'||i.owner||' Version:'||l_schema_version||' EndTime:'||TO_CHAR(l_max_endtime, 'YYYY-MM-DD"T"HH24:MI:SS')||l_message);
    END LOOP;
    IF l_candidate_2b_dropped = l_schema_count THEN
      DBMS_OUTPUT.put_line('*** pdb '||SYS_CONTEXT('USERENV', 'CON_NAME')||' candidate to be dropped ***');
    END IF;
  END IF;
END;
/ 
