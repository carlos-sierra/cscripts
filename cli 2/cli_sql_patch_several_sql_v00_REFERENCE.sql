REM cli_sql_patch_several_sql_v00_REFERENCE.sql - Create SQL Patch for multiple SQL_IDs
SET LIN 600 SERVEROUT ON;
/*

iodcli sql_exec -y -t PRIMARY -r SEA -p "KAAS_2018_12C_TESTING%" file:/Users/csierra/git/bitbucket.oci.oraclecorp.com/dbeng/cscripts/cli/cli_sql_patch_several_sql_v00_19c_test.sql iod-db-sandbox-02304.node.ad2.r1 > cli_sql_patch_several_sql_v00_19c_test_003.txt
iodcli sql_exec -y -t PRIMARY -r SEA -p "KAAS_2022_TDE_19C%" file:/Users/csierra/git/bitbucket.oci.oraclecorp.com/dbeng/cscripts/cli/cli_sql_patch_several_sql_v00_19c_test.sql iod-db-01014.node.ad1.r1 > cli_sql_patch_several_sql_v00_19c_test_001.txt

*/
DECLARE
  l_cs_reference VARCHAR2(30) := 'KIEV19c';
  l_cbo_hints VARCHAR2(500) := q'[FIRST_ROWS(1) OPT_PARAM('_fix_control' '5922070:OFF')]';
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
      AND     sql_id IN ( 'gt0mcab3kkgwt'
                        , 'bwbauvpwvmn2w'
                        , '4cf95h33jcv3f'
                        , 'ds8jcaaks4k88'
                        , '6dx2nanq78rc7'
                        , '4kau9r44wq4fu'
                        , 'dtbzd3pvb4vb8'
                        , '2tht0y9j78v29'
                        , 'gwmq3z3cxatvd'
                        , 'gumas374n1w1w'
                        , 'fnb3d0xtknf40'
                        , '69pt318xc8rbs'
                        , '3j65992nftptv'
                        , 'ay22t52usvkd9'
                        --, '90st1601q7rv0'
                        , '7fxq8yn1knx2m'
                        , '1r0ypqhgcvruk'
                        , '0gkgxm321gjws'
                        , '2dq9sgu963gfd'
                        , '4pdxgu3wm3cj5'
                        , '2jy78c3c258bb'
                        , '8pkr3190hza8d'
                        , '2cquy5urjwhrb'
                        )
      --AND     exact_matching_signature = 999
      --AND     plan_hash_value IN (2185442542, 642130494, 1445899302, 1351947040, 1991866930)
      --AND     sql_text LIKE '%performScanQuery(instanceEvents,HashRangeIndex)%'
      --AND     DBMS_LOB.getlength(sql_fulltext) - DBMS_LOB.instr(sql_fulltext, 'WHERE') + 1 IN (242, 251)
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