SET SERVEROUT ON;
DECLARE
 l_count INTEGER := 0;
 l_schemas INTEGER;
 l_pdb_creation DATE;
 l_max_endtime DATE;
BEGIN
  SELECT op_timestamp INTO l_pdb_creation FROM cdb_pdb_history WHERE pdb_name = SYS_CONTEXT('USERENV', 'CON_NAME') AND operation LIKE '%CREATE%'; -- had to use LIKE '%CREATE%' instead of = 'CREATE' due to IOD_META_AUX.do_dbc_pdbs ORA-00604: error occurred at recursive SQL level 1 ORA-00932: inconsistent datatypes: expected CHAR got C##IOD.SYS_PLSQL_25D5A17D_55_1
  SELECT COUNT(*) INTO l_schemas FROM dba_tables WHERE table_name = 'KIEVTRANSACTIONS';
  FOR i IN (SELECT owner FROM dba_tables WHERE table_name = 'KIEVTRANSACTIONS')
  LOOP
    EXECUTE IMMEDIATE 'SELECT CAST(MAX(endtime) AS DATE) FROM '||i.owner||'.kievtransactions WHERE endtime IS NOT NULL' INTO l_max_endtime;
    IF l_max_endtime IS NULL OR TRUNC(SYSDATE-l_max_endtime) > 30 THEN
      l_count := l_count + 1;
      DBMS_OUTPUT.put_line(
        --RPAD(SUBSTR(SYS_CONTEXT('USERENV', 'CON_NAME'), 1, 30), 31)||
        RPAD(TO_CHAR(l_pdb_creation, 'YYYY-MM-DD"T"HH24:MI:SS'), 20)||
        RPAD(l_count||'/'||l_schemas, 6)||
        RPAD(i.owner, 31)||
        RPAD(TO_CHAR(l_max_endtime, 'YYYY-MM-DD"T"HH24:MI:SS'), 20)||
        LPAD(TO_CHAR(TRUNC(SYSDATE-l_max_endtime)), 5)
      );
    END IF;
  END LOOP;
END;
/ 
