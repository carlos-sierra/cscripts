SET SERVEROUT ON;
-- PDBs older than 90 days, have a KIEV tablespace with objects on it, it does not contain a KIEVTransactions table, or it does and such table is empty or has its most recent transaction older than 60 days
-- iodcli sql_exec -y -t PRIMARY -p "%" file:/Users/csierra/git/bitbucket.oci.oraclecorp.com/dbeng/oratk/sql/cscripts/cli/cli_kiev_pdbs_2b_dropped_v04.sql hcg:HC_KIEV > cli_kiev_pdbs_2b_dropped_v04.txt
-- cat cli_kiev_pdbs_2b_dropped_v04.txt | grep -v "\-$" | grep -v "PDBs older than 90 days" | cut -b 115- > cli_kiev_pdbs_2b_dropped_v04.csv
DECLARE
 l_kiev_ts INTEGER;
 l_kiev_gbs NUMBER;
 l_segments INTEGER;
 l_kiev_segments INTEGER;
 l_drop_candidates INTEGER := 0;
 l_kiev_schemas INTEGER;
 l_pdb_creation DATE;
 l_max_endtime DATE;
 l_max_max_endtime DATE;
 l_region VARCHAR2(30); 
 l_ez_connect_string VARCHAR2(512);
 l_locale VARCHAR2(3);
 l_db_name VARCHAR2(9);
 l_host_name VARCHAR2(64);
BEGIN
  SELECT op_timestamp INTO l_pdb_creation FROM cdb_pdb_history 
  WHERE pdb_name = SYS_CONTEXT('USERENV', 'CON_NAME') AND operation LIKE '%CREATE%'; -- had to use LIKE '%CREATE%' instead of = 'CREATE' due to IOD_META_AUX.do_dbc_pdbs ORA-00604: error occurred at recursive SQL level 1 ORA-00932: inconsistent datatypes: expected CHAR got C##IOD.SYS_PLSQL_25D5A17D_55_1
  IF l_pdb_creation > SYSDATE - 90 THEN RETURN; END IF; -- PDB is newer than 90 days
  --
  SELECT COUNT(*), ROUND(SUM(m.used_space * t.block_size) / POWER(10,9)) INTO l_kiev_ts, l_kiev_gbs 
  FROM dba_tablespace_usage_metrics m, dba_tablespaces t 
  WHERE m.tablespace_name LIKE '%KIEV%' AND t.tablespace_name = m.tablespace_name;
  IF NVL(l_kiev_ts, 0) = 0 THEN RETURN; END IF; -- not a KIEV PDB
  --
  SELECT COUNT(*), NVL(SUM(CASE WHEN segment_name LIKE 'KIEV%' THEN 1 ELSE 0 END), 0) INTO l_segments, l_kiev_segments
  FROM dba_segments WHERE tablespace_name LIKE '%KIEV%';
  IF l_segments > 0 AND l_kiev_segments = 0 THEN RETURN; END IF; -- not a KIEV PDB
  --  
  SELECT COUNT(*) INTO l_kiev_schemas FROM dba_tables WHERE table_name = 'KIEVTRANSACTIONS';
  --
  IF l_kiev_schemas > 0 THEN
    FOR i IN (SELECT owner FROM dba_tables WHERE table_name = 'KIEVTRANSACTIONS')
    LOOP
      EXECUTE IMMEDIATE 'SELECT CAST(MAX(endtime) AS DATE) FROM '||i.owner||'.kievtransactions' INTO l_max_endtime;
      IF l_max_endtime IS NULL OR SYSDATE - l_max_endtime > 60 THEN
        l_drop_candidates := l_drop_candidates + 1;
        IF l_max_endtime IS NOT NULL THEN
          l_max_max_endtime := GREATEST(COALESCE(l_max_max_endtime, l_max_endtime), l_max_endtime);
        END IF;
      END IF;
    END LOOP;
  END IF;
  --
  IF l_kiev_schemas = l_drop_candidates THEN -- no kt table, or most recent transaction is older than 60 days
    SELECT SUBSTR(UPPER(SUBSTR(host_name,INSTR(host_name,'.',-1)+1)),1,30) INTO l_region FROM v$instance;
    -- 
    WITH 
    service AS (
    SELECT CASE WHEN ds.pdb = 'CDB$ROOT' THEN 'oradb' WHEN ts.name = 'KIEV' THEN 'kiev' ELSE 'orapdb' END type,
           ds.name||'.'||SYS_CONTEXT('USERENV','DB_DOMAIN') name, 
           vs.con_id, ds.pdb
      FROM cdb_services ds,
           v$active_services vs,
           v$tablespace ts
     WHERE 1 = 1
       AND ds.pdb = SYS_CONTEXT ('USERENV', 'CON_NAME')
       AND ds.name LIKE 's\_%' ESCAPE '\'
       AND ds.name NOT LIKE '%\_ro' ESCAPE '\'
       AND vs.con_name = ds.pdb
       AND vs.name = ds.name
       AND ts.con_id(+) = vs.con_id
       AND ts.name(+) = 'KIEV'
    )
    SELECT --s.pdb,
           --'jdbc:oracle:thin:@//'||
           s.type||'-'||
           CASE  
             WHEN s.pdb = 'CDB$ROOT' THEN REPLACE(LOWER(SYS_CONTEXT('USERENV','DB_NAME')),'_','-') 
             ELSE REPLACE(LOWER(s.pdb),'_','-')
           END||'.svc.'||       
           CASE REGEXP_COUNT(REPLACE(REPLACE(LOWER(SYS_CONTEXT('USERENV','DB_DOMAIN')),'regional.',''),'.regional',''),'\.')
             WHEN 0 THEN SUBSTR(i.host_name,INSTR(i.host_name,'.',-1,1)+1)
             ELSE SUBSTR(i.host_name,INSTR(i.host_name,'.',-1,2)+1)
           END||'/'||
           s.name
      INTO l_ez_connect_string
      FROM service s, v$instance i;
    --
    SELECT CASE
    WHEN d.name IN ('KIEV01', 'IOD01', 'IOD05') OR d.name LIKE CHR(37)||'RG' THEN 'RGN'
    WHEN UPPER(SUBSTR(i.host_name,INSTR(i.host_name,'.',-1)+1)) = 'R2' AND d.name IN ('KIEV02', 'KIEV1R2') THEN 'RGN'
    ELSE UPPER(SUBSTR(i.host_name,INSTR(i.host_name,'.',-1,2)+1,INSTR(i.host_name,'.',-1)-INSTR(i.host_name,'.',-1,2)-1))
    END,
    d.name, i.host_name
    INTO l_locale, l_db_name, l_host_name
    FROM v$database d, v$instance i;
    --PDB Name,EZ Connect,Host Name,Region,Locale,DB Name,PDB creation date,PDB age in days,KIEV instances within PDB,GBs on disk,Segments on KIEV TS,KIEV Segments,Last transaction date,Last transaction age in days
    DBMS_OUTPUT.put_line(
      SYS_CONTEXT('USERENV', 'CON_NAME')||','|| -- PDB Name
      l_ez_connect_string||','|| -- EZ Connect
      l_host_name||','|| -- Host Name
      l_region||','|| -- Region
      l_locale||','|| -- Locale
      l_db_name||','|| -- DB Name
      TO_CHAR(l_pdb_creation, 'YYYY-MM-DD"T"HH24:MI:SS')||','|| -- PDB creation date
      TO_CHAR(TRUNC(SYSDATE - l_pdb_creation))||','|| -- PDB age in days
      l_kiev_schemas||','|| -- KIEV instances within PDB
      l_kiev_gbs||','|| -- GBs on disk
      l_segments||','|| -- Segments on KIEV TS
      l_kiev_segments||','|| -- KIEV Segments
      TO_CHAR(l_max_max_endtime, 'YYYY-MM-DD"T"HH24:MI:SS')||','|| -- Last transaction date
      TO_CHAR(TRUNC(SYSDATE - l_max_max_endtime)) -- Last transaction age in days
    );
  END IF;  
END; 
/
