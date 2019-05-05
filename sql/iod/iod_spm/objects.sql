WHENEVER SQLERROR EXIT FAILURE;

/* ------------------------------------------------------------------------------------ */

-- zapper_ignore_sql
DECLARE
  l_exists NUMBER;
  l_sql_statement VARCHAR2(32767) := q'[
CREATE TABLE &&1..zapper_ignore_sql (
  -- soft PK
  sql_id                         VARCHAR2(13),
  -- columns
  reference                      VARCHAR2(30)
)
TABLESPACE IOD
]';
BEGIN
  SELECT COUNT(*) INTO l_exists FROM dba_tables WHERE owner = UPPER(TRIM('&&1.')) AND table_name = UPPER('zapper_ignore_sql');
  IF l_exists = 0 THEN
    EXECUTE IMMEDIATE l_sql_statement;
  END IF;
END;
/    

MERGE INTO c##iod.zapper_ignore_sql o
  USING (SELECT '9pugnjaryw6mq' sql_id,'ODSI-1449' reference FROM DUAL 
          UNION ALL
         SELECT 'bnkpa2ha3ug68' sql_id,'IOD-15009 14931 14551 14030' reference FROM DUAL
        ) i
  ON (o.sql_id = i.sql_id)
WHEN MATCHED THEN
  UPDATE SET o.reference = i.reference
WHEN NOT MATCHED THEN
  INSERT (sql_id, reference)
  VALUES (i.sql_id, i.reference)
/

MERGE INTO c##iod.zapper_ignore_sql o
  USING (SELECT '13fd2cz22txzu' sql_id,'DBPERF-35' reference FROM DUAL 
          UNION ALL
         SELECT '91pk205cxrx29' sql_id,'DBPERF-35' reference FROM DUAL
        ) i
  ON (o.sql_id = i.sql_id)
WHEN MATCHED THEN
  UPDATE SET o.reference = i.reference
WHEN NOT MATCHED THEN
  INSERT (sql_id, reference)
  VALUES (i.sql_id, i.reference)
/

/* ------------------------------------------------------------------------------------ */

-- zapper_quarantine_pdb
DECLARE
  l_exists NUMBER;
  l_sql_statement VARCHAR2(32767) := q'[
CREATE TABLE &&1..zapper_quarantine_pdb (
  -- soft PK
  pdb_name                       VARCHAR2(128),
  -- columns
  quarantine_expire              DATE DEFAULT ON NULL SYSDATE + 1
)
TABLESPACE IOD
]';
BEGIN
  SELECT COUNT(*) INTO l_exists FROM dba_tables WHERE owner = UPPER(TRIM('&&1.')) AND table_name = UPPER('zapper_quarantine_pdb');
  IF l_exists = 0 THEN
    EXECUTE IMMEDIATE l_sql_statement;
  END IF;
END;
/    

/* ------------------------------------------------------------------------------------ */

-- zapper_global
DECLARE
  l_exists NUMBER;
  l_sql_statement VARCHAR2(32767) := q'[
CREATE TABLE &&1..zapper_global (
  -- soft PK
  tool_name                      VARCHAR2(16),
  -- columns
  enabled                        VARCHAR2(1),
  create_spm_limit               NUMBER,
  promote_spm_limit              NUMBER,
  disable_spm_limit              NUMBER,
  aggressiveness_lower_limit     NUMBER,
  aggressiveness_upper_limit     NUMBER,
  repo_rejected_candidates       VARCHAR2(1),
  repo_non_promoted_spb          VARCHAR2(1),
  repo_fixed_spb                 VARCHAR2(1),
  persist_null_actions           VARCHAR2(1),
  instance_days                  NUMBER,
  awr_days                       NUMBER,
  cur_days                       NUMBER,
  most_recent_awr_snap_hours     NUMBER,
  display_plan                   VARCHAR2(1),
  display_plan_format            VARCHAR2(128),
  secs_after_any_spm_api_call    NUMBER,
  secs_before_spm_call_sql_id    NUMBER,
  workaround_ora_13831           VARCHAR2(1),
  workaround_ora_06512           VARCHAR2(1),
  debugging                      VARCHAR2(1),
  kiev_pdbs_only                 VARCHAR2(1)
)
TABLESPACE IOD
]';
BEGIN
  SELECT COUNT(*) INTO l_exists FROM dba_tables WHERE owner = UPPER(TRIM('&&1.')) AND table_name = UPPER('zapper_global');
  IF l_exists = 0 THEN
    EXECUTE IMMEDIATE l_sql_statement;
  END IF;
END;
/    

COMMENT ON TABLE &&1..zapper_global IS 'Zapper Global Parameters';
COMMENT ON COLUMN &&1..zapper_global.tool_name IS 'Zapper!';
COMMENT ON COLUMN &&1..zapper_global.enabled IS '(Y|N) zapper to include SQL from this application';
COMMENT ON COLUMN &&1..zapper_global.create_spm_limit IS 'limits the number of SPMs to be created in one execution';
COMMENT ON COLUMN &&1..zapper_global.promote_spm_limit IS 'limits the number of SPMs to be promoted to "FIXED" in one execution';
COMMENT ON COLUMN &&1..zapper_global.disable_spm_limit IS 'limits the number of SPMs to be demoted to "DISABLE" in one execution';
COMMENT ON COLUMN &&1..zapper_global.aggressiveness_upper_limit IS '(2-5) levels the aggressiveness parameter can take (calibrated to value of 5)';
COMMENT ON COLUMN &&1..zapper_global.repo_rejected_candidates IS '(Y|N) include on report rejected candidates';
COMMENT ON COLUMN &&1..zapper_global.repo_non_promoted_spb  IS '(Y|N) include on report non-fixed SPB that is not getting promoted to "FIXED"';
COMMENT ON COLUMN &&1..zapper_global.repo_fixed_spb  IS '(Y|N) include on report "FIXED" SPB';
COMMENT ON COLUMN &&1..zapper_global.persist_null_actions  IS '(Y|N) store into sql_plan_baseline_hist reports where no SPB action was taken.';
COMMENT ON COLUMN &&1..zapper_global.instance_days IS 'database instance must be at least these many days old';
COMMENT ON COLUMN &&1..zapper_global.awr_days IS 'amount of days to consider from AWR metrics history assuming retention is at least this long';
COMMENT ON COLUMN &&1..zapper_global.cur_days IS 'cursor must be active within the past cur_days to be considered';
COMMENT ON COLUMN &&1..zapper_global.most_recent_awr_snap_hours IS 'most recent awr must be younger than these many hours in order to be considered';
COMMENT ON COLUMN &&1..zapper_global.display_plan IS '(Y|N) include execution plan on report';
COMMENT ON COLUMN &&1..zapper_global.display_plan_format IS 'DBMS_XPLAN format';
COMMENT ON COLUMN &&1..zapper_global.secs_after_any_spm_api_call IS 'sleep this many seconds after each dbms_spm api call (trying to avoid bug 27496360)';
COMMENT ON COLUMN &&1..zapper_global.secs_before_spm_call_sql_id IS 'sleep this many seconds before a dbms_spm api call on same sql_id (trying to avoid bug 27496360)';
COMMENT ON COLUMN &&1..zapper_global.workaround_ora_13831 IS '(Y|N) workaround ORA-13831';
COMMENT ON COLUMN &&1..zapper_global.workaround_ora_06512 IS '(Y|N) workaround ORA-06512';
COMMENT ON COLUMN &&1..zapper_global.debugging IS '(Y|N) enable debugging';
COMMENT ON COLUMN &&1..zapper_global.kiev_pdbs_only IS '(Y|N) when Y then execute only on KIEV PDBs';

MERGE INTO &&1..zapper_global t 
USING (
SELECT 'ZAPPER' tool_name,
       'Y'      enabled,
       10000    create_spm_limit,
       10000    promote_spm_limit,
       10000    disable_spm_limit,
       1        aggressiveness_lower_limit,
       5        aggressiveness_upper_limit,
       'N'      repo_rejected_candidates,   
       'N'      repo_non_promoted_spb,     
       'N'      repo_fixed_spb, 
       'N'      persist_null_actions,        
       1        instance_days,    
       14       awr_days,                   
       0.25     cur_days,                   
       3        most_recent_awr_snap_hours,
       'Y'      display_plan,               
       'ADVANCED ALLSTATS LAST' 
                display_plan_format,        
       0        secs_after_any_spm_api_call,
       0        secs_before_spm_call_sql_id,
       'Y'      workaround_ora_13831,       
       'Y'      workaround_ora_06512,       
       'N'      debugging,                  
       'Y'      kiev_pdbs_only             
  FROM DUAL
) q
ON (t.tool_name = q.tool_name)
WHEN NOT MATCHED THEN
INSERT (
  tool_name                      
, enabled                        
, create_spm_limit               
, promote_spm_limit              
, disable_spm_limit              
, aggressiveness_lower_limit
, aggressiveness_upper_limit     
, repo_rejected_candidates       
, repo_non_promoted_spb          
, repo_fixed_spb                 
, persist_null_actions
, instance_days
, awr_days                       
, cur_days                       
, most_recent_awr_snap_hours
, display_plan                   
, display_plan_format            
, secs_after_any_spm_api_call    
, secs_before_spm_call_sql_id    
, workaround_ora_13831           
, workaround_ora_06512           
, debugging                      
, kiev_pdbs_only                 
) VALUES (
  q.tool_name                      
, q.enabled                        
, q.create_spm_limit               
, q.promote_spm_limit              
, q.disable_spm_limit              
, q.aggressiveness_lower_limit
, q.aggressiveness_upper_limit     
, q.repo_rejected_candidates       
, q.repo_non_promoted_spb          
, q.repo_fixed_spb                 
, q.persist_null_actions
, q.instance_days
, q.awr_days                       
, q.cur_days                       
, q.most_recent_awr_snap_hours
, q.display_plan                   
, q.display_plan_format            
, q.secs_after_any_spm_api_call    
, q.secs_before_spm_call_sql_id    
, q.workaround_ora_13831           
, q.workaround_ora_06512           
, q.debugging                      
, q.kiev_pdbs_only                 
)
/

COMMIT;

/* ------------------------------------------------------------------------------------ */

-- zapper_application
DECLARE
  l_exists NUMBER;
  l_sql_statement VARCHAR2(32767) := q'[
CREATE TABLE &&1..zapper_application (
  -- soft PK
  application_id                 NUMBER,
  -- columns
  enabled                        VARCHAR2(1),
  application_category           VARCHAR2(2),
  description                    VARCHAR2(40),
  min_num_rows                   NUMBER,
  et_90th_pctl_over_avg          NUMBER,
  et_95th_pctl_over_avg          NUMBER,
  et_97th_pctl_over_avg          NUMBER,
  et_99th_pctl_over_avg          NUMBER,
  execs_to_demote                NUMBER, /* ~1x execs_to_qualify for level 5 (min for application) */
  spb_probation_days             NUMBER,
  secs_per_exec_bar              NUMBER, /* ~10x secs_per_exec_to_qualify for level 5 (max for application) */
  slow_down_factor_bar           NUMBER,
  spb_monitoring_days_cap        NUMBER,
  secs_per_exec_cap              NUMBER, /* ~100x secs_per_exec_to_qualify for level 5 (max for application) */
  slow_down_factor_cap           NUMBER,
  execs_per_hr_threshold         NUMBER
)
TABLESPACE IOD
]';
BEGIN
  SELECT COUNT(*) INTO l_exists FROM dba_tables WHERE owner = UPPER(TRIM('&&1.')) AND table_name = UPPER('zapper_application');
  IF l_exists = 0 THEN
    EXECUTE IMMEDIATE l_sql_statement;
  END IF;
END;
/    

COMMENT ON TABLE &&1..zapper_application IS 'Zapper Application Parameters';
COMMENT ON COLUMN &&1..zapper_application.application_id IS 'application id as per SQL type (e.g. Transaction Processing, Read Only, Background)';
COMMENT ON COLUMN &&1..zapper_application.enabled IS '(Y|N) zapper to include SQL from this application';
COMMENT ON COLUMN &&1..zapper_application.application_category IS 'application category for qualified SQL';
COMMENT ON COLUMN &&1..zapper_application.description IS 'application description for qualified SQL';
COMMENT ON COLUMN &&1..zapper_application.min_num_rows IS 'minimum number of rows on cbo stats for main table for the SQL to be a candidate';
COMMENT ON COLUMN &&1..zapper_application.et_90th_pctl_over_avg IS 'the 90th percentile of AWR "Avg CPU Time per Exec" should be less than this many times the "CPU Time per Exec" from Memory(Avg)/AWR(Avg)/AWR(Med) in order to qualify for a SPB';
COMMENT ON COLUMN &&1..zapper_application.et_95th_pctl_over_avg IS 'the 95th percentile of AWR "Avg CPU Time per Exec" should be less than this many times the "CPU Time per Exec" from Memory(Avg)/AWR(Avg)/AWR(Med) in order to qualify for a SPB';
COMMENT ON COLUMN &&1..zapper_application.et_97th_pctl_over_avg IS 'the 97th percentile of AWR "Avg CPU Time per Exec" should be less than this many times the "CPU Time per Exec" from Memory(Avg)/AWR(Avg)/AWR(Med) in order to qualify for a SPB';
COMMENT ON COLUMN &&1..zapper_application.et_99th_pctl_over_avg IS 'the 99th percentile of AWR "Avg CPU Time per Exec" should be less than this many times the "CPU Time per Exec" from Memory(Avg)/AWR(Avg)/AWR(Med) in order to qualify for a SPB';
COMMENT ON COLUMN &&1..zapper_application.execs_to_demote IS 'executions for a cursor with a SPB in order to be considered for demotion';
COMMENT ON COLUMN &&1..zapper_application.spb_probation_days IS 'probation window (a non-fixed SPB needs to be older than this many days in order to be promoted to "FIXED")';
COMMENT ON COLUMN &&1..zapper_application.secs_per_exec_bar IS 'during its probation window, plan must perform better than this, else it gets disabled!';
COMMENT ON COLUMN &&1..zapper_application.slow_down_factor_bar IS 'during its probation window, plan must perform better than this many times its own performance from when the SPB was created, else it gets disabled!';
COMMENT ON COLUMN &&1..zapper_application.spb_monitoring_days_cap IS 'a "FIXED" SPB is no longer considered for demotion after these many days';
COMMENT ON COLUMN &&1..zapper_application.secs_per_exec_cap IS 'plan must perform better than this, regardless if fixed or number of executions, else it gets disabled!';
COMMENT ON COLUMN &&1..zapper_application.slow_down_factor_cap IS 'plan must perform better than this many times its own performance from when the SPB was created, regardless if fixed or number of executions, else it gets disabled!';
COMMENT ON COLUMN &&1..zapper_application.execs_per_hr_threshold IS 'minimum number of executions per hour in order to promote or demote a SPB';

MERGE INTO &&1..zapper_application t 
USING (
SELECT 1        application_id,
       'Y'      enabled,
       'TP'     application_category, 
       'Transaction Processing'
                description,
       5000     min_num_rows,          
       10       et_90th_pctl_over_avg, 
       20       et_95th_pctl_over_avg, 
       30       et_97th_pctl_over_avg, 
       40       et_99th_pctl_over_avg, 
       5000     execs_to_demote,         /* ~1x execs_to_qualify for level 5 (min for application) */
       60       spb_probation_days,     
       0.050    secs_per_exec_bar,       /* ~10x secs_per_exec_to_qualify for level 5 (max for application) */
       50       slow_down_factor_bar,  
       180      spb_monitoring_days_cap,
       0.500    secs_per_exec_cap,       /* ~100x secs_per_exec_to_qualify for level 5 (max for application) */
       500      slow_down_factor_cap,  
       20       execs_per_hr_threshold
  FROM DUAL
 UNION ALL
SELECT 2        application_id,
       'Y'      enabled,
       'RO'     application_category, 
       'Read Only'
                description,
       10000    min_num_rows,          
       10       et_90th_pctl_over_avg, 
       20       et_95th_pctl_over_avg, 
       30       et_97th_pctl_over_avg, 
       40       et_99th_pctl_over_avg, 
       1000     execs_to_demote,         /* ~1x execs_to_qualify for level 5 (min for application) */
       60       spb_probation_days,     
       2.5      secs_per_exec_bar,       /* ~10x secs_per_exec_to_qualify for level 5 (max for application) */
       50       slow_down_factor_bar,    
       180      spb_monitoring_days_cap,
       25       secs_per_exec_cap,       /* ~100x secs_per_exec_to_qualify for level 5 (max for application) */
       500      slow_down_factor_cap,  
       10       execs_per_hr_threshold   
  FROM DUAL
 UNION ALL
SELECT 3        application_id,
       'Y'      enabled,
       'BG'     application_category, 
       'Background'
                description,
       100000   min_num_rows,          
       10       et_90th_pctl_over_avg, 
       20       et_95th_pctl_over_avg, 
       30       et_97th_pctl_over_avg, 
       40       et_99th_pctl_over_avg, 
       100      execs_to_demote,         /* ~1x execs_to_qualify for level 5 (min for application) */
       90       spb_probation_days,     
       120      secs_per_exec_bar,       /* ~10x secs_per_exec_to_qualify for level 5 (max for application) */
       50       slow_down_factor_bar,    
       180      spb_monitoring_days_cap,
       600      secs_per_exec_cap,       /* ~50x secs_per_exec_to_qualify for level 5 (max for application) */
       500      slow_down_factor_cap,  
       0        execs_per_hr_threshold 
  FROM DUAL
 UNION ALL
SELECT 9        application_id,
       'Y'      enabled,
       'UN'     application_category, 
       'Unknown'
                description,
       100000   min_num_rows,          
       10       et_90th_pctl_over_avg, 
       20       et_95th_pctl_over_avg, 
       30       et_97th_pctl_over_avg, 
       40       et_99th_pctl_over_avg, 
       1000     execs_to_demote,         /* ~1x execs_to_qualify for level 5 (min for application) */
       60       spb_probation_days,     
       2.5      secs_per_exec_bar,       /* ~10x secs_per_exec_to_qualify for level 5 (max for application) */
       50       slow_down_factor_bar,    
       180      spb_monitoring_days_cap,
       25       secs_per_exec_cap,       /* ~100x secs_per_exec_to_qualify for level 5 (max for application) */
       500      slow_down_factor_cap,  
       10       execs_per_hr_threshold   
  FROM DUAL
) q
ON (t.application_id = q.application_id)
WHEN NOT MATCHED THEN
INSERT (
  application_id
, enabled               
, application_category  
, description
, min_num_rows          
, et_90th_pctl_over_avg 
, et_95th_pctl_over_avg 
, et_97th_pctl_over_avg 
, et_99th_pctl_over_avg 
, execs_to_demote
, spb_probation_days     
, secs_per_exec_bar     
, slow_down_factor_bar  
, spb_monitoring_days_cap
, secs_per_exec_cap     
, slow_down_factor_cap  
, execs_per_hr_threshold
) VALUES (
  q.application_id
, q.enabled               
, q.application_category  
, q.description
, q.min_num_rows          
, q.et_90th_pctl_over_avg 
, q.et_95th_pctl_over_avg 
, q.et_97th_pctl_over_avg 
, q.et_99th_pctl_over_avg 
, q.execs_to_demote
, q.spb_probation_days     
, q.secs_per_exec_bar     
, q.slow_down_factor_bar  
, q.spb_monitoring_days_cap
, q.secs_per_exec_cap     
, q.slow_down_factor_cap  
, q.execs_per_hr_threshold
)
/

COMMIT;

/* ------------------------------------------------------------------------------------ */

-- zapper_appl_and_level
DECLARE
  l_exists NUMBER;
  l_sql_statement VARCHAR2(32767) := q'[
CREATE TABLE &&1..zapper_appl_and_level (
  -- soft PK
  application_id                 NUMBER,
  aggressiveness_level           NUMBER,
  -- columns
  execs_candidate                NUMBER, /* ~0.5x execs_to_qualify */
  execs_to_qualify               NUMBER,
  secs_per_exec_candidate        NUMBER, /* ~2x secs_per_exec_to_qualify */
  secs_per_exec_to_qualify       NUMBER,
  secs_per_exec_90th_pctl        NUMBER, /* ~2x secs_per_exec_to_qualify */
  secs_per_exec_95th_pctl        NUMBER, /* ~3x secs_per_exec_to_qualify */
  secs_per_exec_97th_pctl        NUMBER, /* ~4x secs_per_exec_to_qualify */
  secs_per_exec_99th_pctl        NUMBER, /* ~10x secs_per_exec_to_qualify */
  first_load_hours_candidate     NUMBER, /* ~0.5x first_load_hours_qualify */
  first_load_hours_qualify       NUMBER
)
TABLESPACE IOD
]';
BEGIN
  SELECT COUNT(*) INTO l_exists FROM dba_tables WHERE owner = UPPER(TRIM('&&1.')) AND table_name = UPPER('zapper_appl_and_level');
  IF l_exists = 0 THEN
    EXECUTE IMMEDIATE l_sql_statement;
  END IF;
END;
/    

COMMENT ON TABLE &&1..zapper_appl_and_level IS 'Zapper Parameters as per Application and Aggresiveness Levels';
COMMENT ON COLUMN &&1..zapper_appl_and_level.application_id IS 'application id as per SQL type (e.g. Transaction Processing, Read Only, Background)';
COMMENT ON COLUMN &&1..zapper_appl_and_level.aggressiveness_level IS '(1-5) range between 1 to 5 where 1 is conservative and 5 is most aggresive';
COMMENT ON COLUMN &&1..zapper_appl_and_level.execs_candidate IS 'a plan must be executed these many times in order to be a candidate';
COMMENT ON COLUMN &&1..zapper_appl_and_level.execs_to_qualify IS 'a plan must be executed these many times in order to qualify for a SPB';
COMMENT ON COLUMN &&1..zapper_appl_and_level.secs_per_exec_candidate IS 'a plan must perform better than this in order to be a candidate';
COMMENT ON COLUMN &&1..zapper_appl_and_level.secs_per_exec_to_qualify IS 'a plan must perform better than this in order to qualify for a SPB';
COMMENT ON COLUMN &&1..zapper_appl_and_level.secs_per_exec_90th_pctl IS 'the 90th percentile of "Avg CPU Time per Exec" should be better than this in order to qualify for a SPB';
COMMENT ON COLUMN &&1..zapper_appl_and_level.secs_per_exec_95th_pctl IS 'the 95th percentile of "Avg CPU Time per Exec" should be better than this in order to qualify for a SPB';
COMMENT ON COLUMN &&1..zapper_appl_and_level.secs_per_exec_97th_pctl IS 'the 97th percentile of "Avg CPU Time per Exec" should be better than this in order to qualify for a SPB';
COMMENT ON COLUMN &&1..zapper_appl_and_level.secs_per_exec_99th_pctl IS 'the 99th percentile of "Avg CPU Time per Exec" should be better than this in order to qualify for a SPB';
COMMENT ON COLUMN &&1..zapper_appl_and_level.first_load_hours_candidate IS 'a sql must be loaded into memory at least this many hours before it is considered as candidate';
COMMENT ON COLUMN &&1..zapper_appl_and_level.first_load_hours_qualify IS 'a sql must be loaded into memory at least this many hours before it qualifies for a SPB';

MERGE INTO &&1..zapper_appl_and_level t 
USING (
SELECT 1        application_id,
       1        aggressiveness_level,
       12500    execs_candidate,            /* ~0.5x execs_to_qualify */
       25000    execs_to_qualify,
       0.002    secs_per_exec_candidate,    /* ~2x secs_per_exec_to_qualify */
       0.001    secs_per_exec_to_qualify,
       0.002    secs_per_exec_90th_pctl,    /* ~2x secs_per_exec_to_qualify */
       0.003    secs_per_exec_95th_pctl,    /* ~3x secs_per_exec_to_qualify */
       0.004    secs_per_exec_97th_pctl,    /* ~4x secs_per_exec_to_qualify */
       0.005    secs_per_exec_99th_pctl,    /* ~10x secs_per_exec_to_qualify */
       0.5      first_load_hours_candidate, /* ~0.5x first_load_hours_qualify */
       1        first_load_hours_qualify
  FROM DUAL
 UNION ALL
SELECT 1        application_id,
       2        aggressiveness_level,
       10000    execs_candidate,            /* ~0.5x execs_to_qualify */
       20000    execs_to_qualify,
       0.004    secs_per_exec_candidate,    /* ~2x secs_per_exec_to_qualify */
       0.002    secs_per_exec_to_qualify,
       0.004    secs_per_exec_90th_pctl,    /* ~2x secs_per_exec_to_qualify */
       0.006    secs_per_exec_95th_pctl,    /* ~3x secs_per_exec_to_qualify */
       0.008    secs_per_exec_97th_pctl,    /* ~4x secs_per_exec_to_qualify */
       0.010    secs_per_exec_99th_pctl,    /* ~10x secs_per_exec_to_qualify */
       1        first_load_hours_candidate, /* ~0.5x first_load_hours_qualify */
       2        first_load_hours_qualify
  FROM DUAL
 UNION ALL
SELECT 1        application_id,
       3        aggressiveness_level,
       7500     execs_candidate,            /* ~0.5x execs_to_qualify */
       15000    execs_to_qualify,
       0.006    secs_per_exec_candidate,    /* ~2x secs_per_exec_to_qualify */
       0.003    secs_per_exec_to_qualify,
       0.006    secs_per_exec_90th_pctl,    /* ~2x secs_per_exec_to_qualify */
       0.009    secs_per_exec_95th_pctl,    /* ~3x secs_per_exec_to_qualify */
       0.012    secs_per_exec_97th_pctl,    /* ~4x secs_per_exec_to_qualify */
       0.015    secs_per_exec_99th_pctl,    /* ~10x secs_per_exec_to_qualify */
       1.5      first_load_hours_candidate, /* ~0.5x first_load_hours_qualify */
       3        first_load_hours_qualify
  FROM DUAL
 UNION ALL
SELECT 1        application_id,
       4        aggressiveness_level,
       5000     execs_candidate,            /* ~0.5x execs_to_qualify */
       10000    execs_to_qualify,
       0.008    secs_per_exec_candidate,    /* ~2x secs_per_exec_to_qualify */
       0.004    secs_per_exec_to_qualify,
       0.008    secs_per_exec_90th_pctl,    /* ~2x secs_per_exec_to_qualify */
       0.012    secs_per_exec_95th_pctl,    /* ~3x secs_per_exec_to_qualify */
       0.016    secs_per_exec_97th_pctl,    /* ~4x secs_per_exec_to_qualify */
       0.020    secs_per_exec_99th_pctl,    /* ~10x secs_per_exec_to_qualify */
       2        first_load_hours_candidate, /* ~0.5x first_load_hours_qualify */
       4        first_load_hours_qualify
  FROM DUAL
 UNION ALL
SELECT 1        application_id,
       5        aggressiveness_level,
       2500     execs_candidate,            /* ~0.5x execs_to_qualify */
       5000     execs_to_qualify,
       0.010    secs_per_exec_candidate,    /* ~2x secs_per_exec_to_qualify */
       0.005    secs_per_exec_to_qualify,
       0.010    secs_per_exec_90th_pctl,    /* ~2x secs_per_exec_to_qualify */
       0.015    secs_per_exec_95th_pctl,    /* ~3x secs_per_exec_to_qualify */
       0.020    secs_per_exec_97th_pctl,    /* ~4x secs_per_exec_to_qualify */
       0.025    secs_per_exec_99th_pctl,    /* ~10x secs_per_exec_to_qualify */
       2.5      first_load_hours_candidate, /* ~0.5x first_load_hours_qualify */
       5        first_load_hours_qualify
  FROM DUAL
 UNION ALL
SELECT 2        application_id,
       1        aggressiveness_level,
       2500     execs_candidate,            /* ~0.5x execs_to_qualify */
       5000     execs_to_qualify,
       0.100    secs_per_exec_candidate,    /* ~2x secs_per_exec_to_qualify */
       0.050    secs_per_exec_to_qualify,
       0.100    secs_per_exec_90th_pctl,    /* ~2x secs_per_exec_to_qualify */
       0.150    secs_per_exec_95th_pctl,    /* ~3x secs_per_exec_to_qualify */
       0.200    secs_per_exec_97th_pctl,    /* ~4x secs_per_exec_to_qualify */
       0.250    secs_per_exec_99th_pctl,    /* ~10x secs_per_exec_to_qualify */
       0.5      first_load_hours_candidate, /* ~0.5x first_load_hours_qualify */
       1        first_load_hours_qualify
  FROM DUAL
 UNION ALL
SELECT 2        application_id,
       2        aggressiveness_level,
       2000     execs_candidate,            /* ~0.5x execs_to_qualify */
       4000     execs_to_qualify,
       0.200    secs_per_exec_candidate,    /* ~2x secs_per_exec_to_qualify */
       0.100    secs_per_exec_to_qualify,
       0.200    secs_per_exec_90th_pctl,    /* ~2x secs_per_exec_to_qualify */
       0.300    secs_per_exec_95th_pctl,    /* ~3x secs_per_exec_to_qualify */
       0.400    secs_per_exec_97th_pctl,    /* ~4x secs_per_exec_to_qualify */
       0.500    secs_per_exec_99th_pctl,    /* ~10x secs_per_exec_to_qualify */
       1        first_load_hours_candidate, /* ~0.5x first_load_hours_qualify */
       2        first_load_hours_qualify
  FROM DUAL
 UNION ALL
SELECT 2        application_id,
       3        aggressiveness_level,
       1500     execs_candidate,            /* ~0.5x execs_to_qualify */
       3000     execs_to_qualify,
       0.300    secs_per_exec_candidate,    /* ~2x secs_per_exec_to_qualify */
       0.150    secs_per_exec_to_qualify,
       0.300    secs_per_exec_90th_pctl,    /* ~2x secs_per_exec_to_qualify */
       0.450    secs_per_exec_95th_pctl,    /* ~3x secs_per_exec_to_qualify */
       0.600    secs_per_exec_97th_pctl,    /* ~4x secs_per_exec_to_qualify */
       0.750    secs_per_exec_99th_pctl,    /* ~10x secs_per_exec_to_qualify */
       1.5      first_load_hours_candidate, /* ~0.5x first_load_hours_qualify */
       3        first_load_hours_qualify
  FROM DUAL
 UNION ALL
SELECT 2        application_id,
       4        aggressiveness_level,
       1000     execs_candidate,            /* ~0.5x execs_to_qualify */
       2000     execs_to_qualify,
       0.400    secs_per_exec_candidate,    /* ~2x secs_per_exec_to_qualify */
       0.200    secs_per_exec_to_qualify,
       0.400    secs_per_exec_90th_pctl,    /* ~2x secs_per_exec_to_qualify */
       0.600    secs_per_exec_95th_pctl,    /* ~3x secs_per_exec_to_qualify */
       0.800    secs_per_exec_97th_pctl,    /* ~4x secs_per_exec_to_qualify */
       1.000    secs_per_exec_99th_pctl,    /* ~10x secs_per_exec_to_qualify */
       2        first_load_hours_candidate, /* ~0.5x first_load_hours_qualify */
       4        first_load_hours_qualify
  FROM DUAL
 UNION ALL
SELECT 2        application_id,
       5        aggressiveness_level,
       500      execs_candidate,            /* ~0.5x execs_to_qualify */
       1000     execs_to_qualify,
       0.500    secs_per_exec_candidate,    /* ~2x secs_per_exec_to_qualify */
       0.250    secs_per_exec_to_qualify,
       0.500    secs_per_exec_90th_pctl,    /* ~2x secs_per_exec_to_qualify */
       0.750    secs_per_exec_95th_pctl,    /* ~3x secs_per_exec_to_qualify */
       1.000    secs_per_exec_97th_pctl,    /* ~4x secs_per_exec_to_qualify */
       1.250    secs_per_exec_99th_pctl,    /* ~10x secs_per_exec_to_qualify */
       2.5      first_load_hours_candidate, /* ~0.5x first_load_hours_qualify */
       5        first_load_hours_qualify
  FROM DUAL
 UNION ALL
SELECT 3        application_id,
       1        aggressiveness_level,
       250      execs_candidate,            /* ~0.5x execs_to_qualify */
       500      execs_to_qualify,
       8        secs_per_exec_candidate,    /* ~2x secs_per_exec_to_qualify */
       4        secs_per_exec_to_qualify,
       8        secs_per_exec_90th_pctl,    /* ~2x secs_per_exec_to_qualify */
       12       secs_per_exec_95th_pctl,    /* ~3x secs_per_exec_to_qualify */
       16       secs_per_exec_97th_pctl,    /* ~4x secs_per_exec_to_qualify */
       20       secs_per_exec_99th_pctl,    /* ~10x secs_per_exec_to_qualify */
       12       first_load_hours_candidate, /* ~0.5x first_load_hours_qualify */
       24       first_load_hours_qualify
  FROM DUAL
 UNION ALL
SELECT 3        application_id,
       2        aggressiveness_level,
       200      execs_candidate,            /* ~0.5x execs_to_qualify */
       400      execs_to_qualify,
       12       secs_per_exec_candidate,    /* ~2x secs_per_exec_to_qualify */
       6        secs_per_exec_to_qualify,
       12       secs_per_exec_90th_pctl,    /* ~2x secs_per_exec_to_qualify */
       18       secs_per_exec_95th_pctl,    /* ~3x secs_per_exec_to_qualify */
       24       secs_per_exec_97th_pctl,    /* ~4x secs_per_exec_to_qualify */
       30       secs_per_exec_99th_pctl,    /* ~10x secs_per_exec_to_qualify */
       24       first_load_hours_candidate, /* ~0.5x first_load_hours_qualify */
       48       first_load_hours_qualify
  FROM DUAL
 UNION ALL
SELECT 3        application_id,
       3        aggressiveness_level,
       150      execs_candidate,            /* ~0.5x execs_to_qualify */
       300      execs_to_qualify,
       16       secs_per_exec_candidate,    /* ~2x secs_per_exec_to_qualify */
       8        secs_per_exec_to_qualify,
       16       secs_per_exec_90th_pctl,    /* ~2x secs_per_exec_to_qualify */
       24       secs_per_exec_95th_pctl,    /* ~3x secs_per_exec_to_qualify */
       32       secs_per_exec_97th_pctl,    /* ~4x secs_per_exec_to_qualify */
       40       secs_per_exec_99th_pctl,    /* ~10x secs_per_exec_to_qualify */
       36       first_load_hours_candidate, /* ~0.5x first_load_hours_qualify */
       72       first_load_hours_qualify
  FROM DUAL
 UNION ALL
SELECT 3        application_id,
       4        aggressiveness_level,
       100      execs_candidate,            /* ~0.5x execs_to_qualify */
       200      execs_to_qualify,
       20       secs_per_exec_candidate,    /* ~2x secs_per_exec_to_qualify */
       10       secs_per_exec_to_qualify,
       20       secs_per_exec_90th_pctl,    /* ~2x secs_per_exec_to_qualify */
       30       secs_per_exec_95th_pctl,    /* ~3x secs_per_exec_to_qualify */
       40       secs_per_exec_97th_pctl,    /* ~4x secs_per_exec_to_qualify */
       50       secs_per_exec_99th_pctl,    /* ~10x secs_per_exec_to_qualify */
       48       first_load_hours_candidate, /* ~0.5x first_load_hours_qualify */
       96       first_load_hours_qualify
  FROM DUAL
 UNION ALL
SELECT 3        application_id,
       5        aggressiveness_level,
       50       execs_candidate,            /* ~0.5x execs_to_qualify */
       100      execs_to_qualify,
       24       secs_per_exec_candidate,    /* ~2x secs_per_exec_to_qualify */
       12       secs_per_exec_to_qualify,
       24       secs_per_exec_90th_pctl,    /* ~2x secs_per_exec_to_qualify */
       36       secs_per_exec_95th_pctl,    /* ~3x secs_per_exec_to_qualify */
       48       secs_per_exec_97th_pctl,    /* ~4x secs_per_exec_to_qualify */
       60       secs_per_exec_99th_pctl,    /* ~10x secs_per_exec_to_qualify */
       60       first_load_hours_candidate, /* ~0.5x first_load_hours_qualify */
       120      first_load_hours_qualify
  FROM DUAL
 UNION ALL
SELECT 9        application_id,
       1        aggressiveness_level,
       2500     execs_candidate,            /* ~0.5x execs_to_qualify */
       5000     execs_to_qualify,
       0.100    secs_per_exec_candidate,    /* ~2x secs_per_exec_to_qualify */
       0.050    secs_per_exec_to_qualify,
       0.100    secs_per_exec_90th_pctl,    /* ~2x secs_per_exec_to_qualify */
       0.150    secs_per_exec_95th_pctl,    /* ~3x secs_per_exec_to_qualify */
       0.200    secs_per_exec_97th_pctl,    /* ~4x secs_per_exec_to_qualify */
       0.250    secs_per_exec_99th_pctl,    /* ~10x secs_per_exec_to_qualify */
       2        first_load_hours_candidate, /* ~0.5x first_load_hours_qualify */
       4        first_load_hours_qualify
  FROM DUAL
 UNION ALL
SELECT 9        application_id,
       2        aggressiveness_level,
       2000     execs_candidate,            /* ~0.5x execs_to_qualify */
       4000     execs_to_qualify,
       0.200    secs_per_exec_candidate,    /* ~2x secs_per_exec_to_qualify */
       0.100    secs_per_exec_to_qualify,
       0.200    secs_per_exec_90th_pctl,    /* ~2x secs_per_exec_to_qualify */
       0.300    secs_per_exec_95th_pctl,    /* ~3x secs_per_exec_to_qualify */
       0.400    secs_per_exec_97th_pctl,    /* ~4x secs_per_exec_to_qualify */
       0.500    secs_per_exec_99th_pctl,    /* ~10x secs_per_exec_to_qualify */
       4        first_load_hours_candidate, /* ~0.5x first_load_hours_qualify */
       8        first_load_hours_qualify
  FROM DUAL
 UNION ALL
SELECT 9        application_id,
       3        aggressiveness_level,
       1500     execs_candidate,            /* ~0.5x execs_to_qualify */
       3000     execs_to_qualify,
       0.300    secs_per_exec_candidate,    /* ~2x secs_per_exec_to_qualify */
       0.150    secs_per_exec_to_qualify,
       0.300    secs_per_exec_90th_pctl,    /* ~2x secs_per_exec_to_qualify */
       0.450    secs_per_exec_95th_pctl,    /* ~3x secs_per_exec_to_qualify */
       0.600    secs_per_exec_97th_pctl,    /* ~4x secs_per_exec_to_qualify */
       0.750    secs_per_exec_99th_pctl,    /* ~10x secs_per_exec_to_qualify */
       6        first_load_hours_candidate, /* ~0.5x first_load_hours_qualify */
       12       first_load_hours_qualify
  FROM DUAL
 UNION ALL
SELECT 9        application_id,
       4        aggressiveness_level,
       1000     execs_candidate,            /* ~0.5x execs_to_qualify */
       2000     execs_to_qualify,
       0.400    secs_per_exec_candidate,    /* ~2x secs_per_exec_to_qualify */
       0.200    secs_per_exec_to_qualify,
       0.400    secs_per_exec_90th_pctl,    /* ~2x secs_per_exec_to_qualify */
       0.600    secs_per_exec_95th_pctl,    /* ~3x secs_per_exec_to_qualify */
       0.800    secs_per_exec_97th_pctl,    /* ~4x secs_per_exec_to_qualify */
       1.000    secs_per_exec_99th_pctl,    /* ~10x secs_per_exec_to_qualify */
       8        first_load_hours_candidate, /* ~0.5x first_load_hours_qualify */
       16       first_load_hours_qualify
  FROM DUAL
 UNION ALL
SELECT 9        application_id,
       5        aggressiveness_level,
       500      execs_candidate,            /* ~0.5x execs_to_qualify */
       1000     execs_to_qualify,
       0.500    secs_per_exec_candidate,    /* ~2x secs_per_exec_to_qualify */
       0.250    secs_per_exec_to_qualify,
       0.500    secs_per_exec_90th_pctl,    /* ~2x secs_per_exec_to_qualify */
       0.750    secs_per_exec_95th_pctl,    /* ~3x secs_per_exec_to_qualify */
       1.000    secs_per_exec_97th_pctl,    /* ~4x secs_per_exec_to_qualify */
       1.250    secs_per_exec_99th_pctl,    /* ~10x secs_per_exec_to_qualify */
       10       first_load_hours_candidate, /* ~0.5x first_load_hours_qualify */
       20       first_load_hours_qualify
  FROM DUAL
) q
ON (t.application_id = q.application_id AND t.aggressiveness_level = q.aggressiveness_level)
WHEN NOT MATCHED THEN
INSERT (
  application_id
, aggressiveness_level
, execs_candidate
, execs_to_qualify
, secs_per_exec_candidate
, secs_per_exec_to_qualify
, secs_per_exec_90th_pctl
, secs_per_exec_95th_pctl
, secs_per_exec_97th_pctl
, secs_per_exec_99th_pctl
, first_load_hours_candidate
, first_load_hours_qualify
) VALUES (
  q.application_id
, q.aggressiveness_level
, q.execs_candidate
, q.execs_to_qualify
, q.secs_per_exec_candidate
, q.secs_per_exec_to_qualify
, q.secs_per_exec_90th_pctl
, q.secs_per_exec_95th_pctl
, q.secs_per_exec_97th_pctl
, q.secs_per_exec_99th_pctl
, q.first_load_hours_candidate
, q.first_load_hours_qualify
)
/

COMMIT;

/* ------------------------------------------------------------------------------------ */

-- sql_plan_baseline_hist
-- create repository, partitioned and compressed
-- code preserves 2 months of data
DECLARE
  l_exists NUMBER;
  l_sql_statement VARCHAR2(32767) := q'[
CREATE TABLE &&1..sql_plan_baseline_hist (
  -- soft PK
  con_id                         NUMBER,
  sql_id                         VARCHAR2(13),
  snap_id                        NUMBER,
  snap_time                      DATE,
  -- columns
  plan_hash_value                NUMBER,
  plan_hash_2                    NUMBER,
  plan_hash_full                 NUMBER,
  plan_id                        NUMBER,
  src                            VARCHAR2(3),
  parsing_schema_name            VARCHAR2(30),
  signature                      NUMBER,
  sql_profile_name               VARCHAR2(30),
  sql_patch_name                 VARCHAR2(30),
  sql_handle                     VARCHAR2(20),
  spb_plan_name                  VARCHAR2(30),
  spb_description                VARCHAR2(500),
  spb_created                    DATE,
  spb_last_modified              DATE,
  spb_enabled                    VARCHAR2(3),
  spb_accepted                   VARCHAR2(3),
  spb_fixed                      VARCHAR2(3),
  spb_reproduced                 VARCHAR2(3),
  optimizer_cost                 NUMBER,
  executions                     NUMBER,
  elapsed_time                   NUMBER,
  cpu_time                       NUMBER,
  buffer_gets                    NUMBER,
  disk_reads                     NUMBER,
  rows_processed                 NUMBER,
  pdb_name                       VARCHAR2(128),
  -- zapper
  zapper_aggressiveness          NUMBER,
  zapper_action                  VARCHAR2(8), -- [LOADED|DISABLED|FIXED|NULL]
  zapper_message1                VARCHAR2(256),
  zapper_message2                VARCHAR2(256),
  zapper_message3                VARCHAR2(256),
  zapper_report                  CLOB
)
LOB(zapper_report) STORE AS SECUREFILE (COMPRESS DEDUPLICATE)
PARTITION BY RANGE (snap_time)
INTERVAL (NUMTOYMINTERVAL(1,'MONTH'))
(
PARTITION before_2018_10_01 VALUES LESS THAN (TO_DATE('2018-10-01', 'YYYY-MM-DD'))
)
ROW STORE COMPRESS ADVANCED
TABLESPACE IOD
]';
BEGIN
  SELECT COUNT(*) INTO l_exists FROM dba_tables WHERE owner = UPPER(TRIM('&&1.')) AND table_name = UPPER('sql_plan_baseline_hist');
  IF l_exists = 0 THEN
    EXECUTE IMMEDIATE l_sql_statement;
  END IF;
END;
/    

--ALTER TABLE &&1..sql_plan_baseline_hist MODIFY LOB(zapper_report) (COMPRESS DEDUPLICATE)
--/
    
/* ------------------------------------------------------------------------------------ */
