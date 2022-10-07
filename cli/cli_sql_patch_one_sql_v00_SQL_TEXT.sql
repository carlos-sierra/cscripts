REM cli_sql_patch_one_sql_v00_SQL_TEXT - Create SQL Patch for given SQL Text
SET LIN 600 SERVEROUT ON;
/*

iodcli sql_exec -y -t PRIMARY -p "%" -r r1 file:/Users/csierra/git/bitbucket.oci.oraclecorp.com/dbeng/oratk/sql/cscripts/cli/cli_sql_patch_one_sql_v01_performScanQuery_workflowInstances_I_GC_INDEX.sql iod-db-kiev-02012.node.ad2.r1 > cli_sql_patch_one_sql_v01_performScanQuery_workflowInstances_I_GC_INDEX_4_one_cdb.txt

iodcli sql_exec -y -t PRIMARY -p "%" -r r1 file:/Users/csierra/git/bitbucket.oci.oraclecorp.com/dbeng/oratk/sql/cscripts/cli/cli_sql_patch_one_sql_v01_performScanQuery_workflowInstances_I_GC_INDEX.sql hcg:HC_KIEV > cli_sql_patch_one_sql_v01_performScanQuery_workflowInstances_I_GC_INDEX_4_r1.txt

iodcli sql_exec -y -t PRIMARY -p "%" file:/Users/csierra/git/bitbucket.oci.oraclecorp.com/dbeng/oratk/sql/cscripts/cli/cli_sql_patch_one_sql_v01_performScanQuery_workflowInstances_I_GC_INDEX.sql hcg:HC_KIEV > cli_sql_patch_one_sql_v01_performScanQuery_workflowInstances_I_GC_INDEX_4_fleet.txt

iodcli sql_exec -y -t PRIMARY -p "%W%F%" file:/Users/csierra/git/bitbucket.oci.oraclecorp.com/dbeng/oratk/sql/cscripts/cli/cli_sql_patch_one_sql_v01_performScanQuery_workflowInstances_I_GC_INDEX.sql hcg:HC_KIEV > cli_sql_patch_one_sql_v01_performScanQuery_workflowInstances_I_GC_INDEX_4_fleet_WF.txt


*/
DECLARE
  l_cs_reference VARCHAR2(30) := 'DBPERF-6724';
  l_cbo_hints VARCHAR2(500) := q'[FIRST_ROWS(1)]';
  l_update CHAR(1) := 'Y'; -- N|Y
--
  l_count NUMBER;
  l_open_mode VARCHAR2(10);
  l_plans INTEGER := -1;
  l_name VARCHAR2(64);
  l_desired_patch_exists BOOLEAN;
--
BEGIN
  IF SYS_CONTEXT('USERENV', 'CON_ID') < 3 THEN
    DBMS_OUTPUT.put_line('SKIP. con_id < 3');
    RETURN;
  END IF;
  -- validate open mode
  SELECT open_mode INTO l_open_mode FROM v$containers WHERE con_id = SYS_CONTEXT('USERENV', 'CON_ID');
  IF l_open_mode <> 'READ WRITE' THEN
    DBMS_OUTPUT.put_line('SKIP. not READ WRITE');
    RETURN; 
  END IF;
  -- find sql
  FOR i IN (
    WITH
    sql_to_patch AS (
      SELECT  sql_id,
              exact_matching_signature AS signature,
              plan_hash_value,
              sql_text,
              sql_fulltext,
              DBMS_LOB.getlength(sql_fulltext) - DBMS_LOB.instr(sql_fulltext, 'WHERE') + 1 AS sql_text_predicate_length,
              ROW_NUMBER() OVER (PARTITION BY sql_id ORDER BY last_active_time DESC) AS rn
      FROM    v$sql
      WHERE   1 = 1
      --AND     sql_id = ''
      --AND     exact_matching_signature = 999
      AND     plan_hash_value IN (3909535023, 1722955104, 566781138, 290068306, 613836746, 426763630, 3898936138, 3093691349, 1023183060, 2672251801)
      AND     sql_text LIKE '%performScanQuery(workflowInstances,I_GC_INDEX)%(1 = 1)%'
      AND     DBMS_LOB.getlength(sql_fulltext) - DBMS_LOB.instr(sql_fulltext, 'WHERE') + 1 IN (271)
    )
    SELECT sql_id, signature, plan_hash_value, sql_text, sql_fulltext, sql_text_predicate_length FROM sql_to_patch WHERE rn = 1
  )
  LOOP
    DBMS_OUTPUT.put_line(i.sql_id||' '||i.signature||' '||i.plan_hash_value||' '||i.sql_text_predicate_length||' '||SUBSTR(i.sql_text, 1, 100));
    -- drop baseline(s)
    FOR j IN (
      SELECT sql_handle, plan_name, sql_text, description, 
      SUBSTR(description, INSTR(description, 'SQL_ID=') + 7, 13) AS sql_id, 
      REPLACE(TRIM(SUBSTR(description, INSTR(description, 'PHV=') + 4, 10)), ' ') AS phv
        FROM dba_sql_plan_baselines 
      WHERE signature = i.signature
      ORDER BY
            sql_handle, plan_name
    )
    LOOP
      DBMS_OUTPUT.put_line('drop baseline: '||j.sql_handle||' '||j.plan_name||' '||j.sql_id||' '||j.phv||' '||j.description);
      IF l_update = 'Y' THEN
        l_plans := DBMS_SPM.drop_sql_plan_baseline(sql_handle => j.sql_handle, plan_name => j.plan_name); -- drop all plans on baseline (one by one)
      END IF;
    END LOOP;
    -- drop profile
    FOR j IN (SELECT name, description FROM dba_sql_profiles WHERE signature = i.signature)
    LOOP
      DBMS_OUTPUT.put_line('drop sql profile: '||j.name||' '||j.description);
      IF l_update = 'Y' THEN
        DBMS_SQLTUNE.drop_sql_profile(name => j.name); -- drop any pre-existing sql profile
      END IF;
    END LOOP;
    -- drop unexpected patch and create new patch if it does not exist
    l_desired_patch_exists := FALSE;
    FOR j IN (SELECT name, description FROM dba_sql_patches WHERE signature = i.signature)
    LOOP
      IF j.description = l_cbo_hints||' '||l_cs_reference THEN
        l_desired_patch_exists := TRUE;
        DBMS_OUTPUT.put_line('SKIP. sql patch already exists');
      ELSE
        DBMS_OUTPUT.put_line('drop sql patch: '||j.name||' '||j.description);
        IF l_update = 'Y' THEN
          DBMS_SQLDIAG.drop_sql_patch(name => j.name); -- drop any pre-existing sql patch
        END IF;
      END IF;
    END LOOP;
    --
    IF NOT l_desired_patch_exists THEN
      DBMS_OUTPUT.put_line('create sql patch: '||l_cbo_hints);
      $IF DBMS_DB_VERSION.ver_le_12_1
      $THEN
        IF l_update = 'Y' THEN
          DBMS_SQLDIAG_INTERNAL.i_create_patch(sql_text => i.sql_fulltext, hint_text => l_cbo_hints, name => 'spch_'||i.sql_id, description => l_cbo_hints||' '||l_cs_reference); -- 12c
        END IF;
      $ELSE
        IF l_update = 'Y' THEN
          l_name := DBMS_SQLDIAG.create_sql_patch(sql_text => i.sql_fulltext, hint_text => l_cbo_hints, name => 'spch_'||i.sql_id, description => l_cbo_hints||' '||l_cs_reference); -- 19c
        END IF;
      $END
    END IF;  
  END LOOP;
END;
/