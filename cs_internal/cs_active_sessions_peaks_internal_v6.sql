PRO
PRO Active Sessions Peaks (when greater than &&times_cpu_cores.x NUM_CPU_CORES)
PRO ~~~~~~~~~~~~~~~~~~~~~
COL begin_peak FOR A19 HEA 'Aprox|Start Time';
COL end_peak FOR A19 HEA 'Aprox|End Time';
COL seconds FOR 999,990 HEA 'Aprox|Secs';
COL sessions_peak FOR 999,990 HEA 'Max|Sessions';
COL sql_statement FOR A64 HEA 'Top SQL Statement' TRUNC;
COL timed_event FOR A50 HEA 'Top Timed Event' TRUNC;
COL pdb_name FOR A35 HEA 'Top PDB Name(CON_ID)' TRUNC;
--
BREAK ON REPORT;
COMPUTE SUM OF seconds ON REPORT;
--
 SELECT TO_CHAR(timestamp, 'YYYY-MM-DD"T"HH24:MI:SS') AS begin_peak, 
        TO_CHAR(timestamp + (cost/3600/24), 'YYYY-MM-DD"T"HH24:MI:SS') AS end_peak, 
        cost AS seconds, 
        cardinality AS sessions_peak,
        -- statement_id AS sql_id,
        -- remarks AS sql_text,
        statement_id||' '||SUBSTR(remarks, 1, 50) AS sql_statement,
        -- operation AS session_state,
        -- options AS wait_class,
        -- object_node AS event,
        CASE operation WHEN 'ON CPU' THEN operation ELSE options||' - '||object_node END AS timed_event,
        -- object_owner AS pdb_name,
        -- plan_id AS con_id
        object_owner||'('||plan_id||')' AS pdb_name
   FROM plan_table 
  ORDER BY 1
/
--
PRO NOTE: Displayed values for 3 dimensions (SQL, Timed Event and PDB), correspond to sample time of Max Sessions
