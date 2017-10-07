-- display plan for most recent executed query (SERVEROUT must be OFF all the time)
COL prev_sql_id NEW_V prev_sql_id;
COL prev_child_number NEW_V prev_child_number;
SELECT sid, serial#, audsid, prev_sql_id, prev_child_number FROM v$session WHERE audsid = USERENV('SESSIONID') AND sid IN (SELECT sid FROM v$mystat);

SELECT * FROM TABLE(DBMS_XPLAN.display_cursor('&&prev_sql_id.',&&prev_child_number,'RUNSTATS_LAST'));
