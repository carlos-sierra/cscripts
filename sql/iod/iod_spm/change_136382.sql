-- Enhance Zapper to create SQL Plan Baselines for GC queries even with short history (CHANGE-136382)

MERGE INTO &&1..zapper_application t 
USING (
SELECT 3        application_id,
       'Y'      enabled,
       'BG'     application_category, 
       'Background'
                description,
       --100000   min_num_rows,          
       50000    min_num_rows, /* CHANGE-136382 */        
       10       et_90th_pctl_over_avg, 
       20       et_95th_pctl_over_avg, 
       30       et_97th_pctl_over_avg, 
       40       et_99th_pctl_over_avg, 
       --100      execs_to_demote,         /* ~1x execs_to_qualify for level 5 (min for application) */
       10       execs_to_demote,         /* ~1x execs_to_qualify for level 5 (min for application) */ /* CHANGE-136382 */
       90       spb_probation_days,     
       120      secs_per_exec_bar,       /* ~10x secs_per_exec_to_qualify for level 5 (max for application) */
       50       slow_down_factor_bar,    
       180      spb_monitoring_days_cap,
       600      secs_per_exec_cap,       /* ~50x secs_per_exec_to_qualify for level 5 (max for application) */
       500      slow_down_factor_cap,  
       0        execs_per_hr_threshold 
  FROM DUAL
) q
ON (t.application_id = q.application_id)
WHEN MATCHED THEN
  UPDATE SET t.min_num_rows    = q.min_num_rows,
             t.execs_to_demote = q.execs_to_demote
/

MERGE INTO &&1..zapper_appl_and_level t 
USING (
SELECT 3        application_id,
       1        aggressiveness_level,
       --250      execs_candidate,            /* ~0.5x execs_to_qualify */
       --500      execs_to_qualify,
       5        execs_candidate,            /* ~0.5x execs_to_qualify */ /* CHANGE-136382 */
       10       execs_to_qualify,           /* CHANGE-136382 */
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
       --200      execs_candidate,            /* ~0.5x execs_to_qualify */
       --400      execs_to_qualify,
       10       execs_candidate,            /* ~0.5x execs_to_qualify */ /* CHANGE-136382 */
       20       execs_to_qualify,           /* CHANGE-136382 */
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
       --150      execs_candidate,            /* ~0.5x execs_to_qualify */
       --300      execs_to_qualify,
       15       execs_candidate,            /* ~0.5x execs_to_qualify */ /* CHANGE-136382 */
       30       execs_to_qualify,           /* CHANGE-136382 */
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
       --100      execs_candidate,            /* ~0.5x execs_to_qualify */
       --200      execs_to_qualify,
       20       execs_candidate,            /* ~0.5x execs_to_qualify */ /* CHANGE-136382 */
       40       execs_to_qualify,           /* CHANGE-136382 */
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
       --50       execs_candidate,            /* ~0.5x execs_to_qualify */
       --100      execs_to_qualify,
       25       execs_candidate,            /* ~0.5x execs_to_qualify */ /* CHANGE-136382 */
       50       execs_to_qualify,           /* CHANGE-136382 */
       24       secs_per_exec_candidate,    /* ~2x secs_per_exec_to_qualify */
       12       secs_per_exec_to_qualify,
       24       secs_per_exec_90th_pctl,    /* ~2x secs_per_exec_to_qualify */
       36       secs_per_exec_95th_pctl,    /* ~3x secs_per_exec_to_qualify */
       48       secs_per_exec_97th_pctl,    /* ~4x secs_per_exec_to_qualify */
       60       secs_per_exec_99th_pctl,    /* ~10x secs_per_exec_to_qualify */
       60       first_load_hours_candidate, /* ~0.5x first_load_hours_qualify */
       120      first_load_hours_qualify
  FROM DUAL
) q
ON (t.application_id = q.application_id AND t.aggressiveness_level = q.aggressiveness_level)
WHEN MATCHED THEN
  UPDATE SET t.execs_candidate  = q.execs_candidate,
             t.execs_to_qualify = q.execs_to_qualify
/

COMMIT;

