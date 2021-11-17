-- trace_SPM_sql_id.sql - Turn ON and OFF SQL Plan Management Trace on given SQL_ID
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
--
PRO
PRO 1. SQL_ID:
DEF sql_id = '&1.';
UNDEF 1;
--
PRO
PRO CBO Trace (a.k.a. 10053 Event Trace) is same as "Optimizer" scope. Compiler is a superset of Optimizer.
PRO
PRO 2. Scope: [{Optimizer}|Compiler]
DEF scope = '&2.';
UNDEF 2;
COL scope NEW_V scope NOPRI;
SELECT CASE WHEN '&&scope.' IN ('Optimizer', 'Compiler') THEN '&&scope.' ELSE 'Optimizer' END AS scope FROM DUAL;
--
COL host_name NEW_V host_name NOPRI;
COL trace_dir NEW_V trace_dir NOPRI;
SELECT host_name, value AS trace_dir FROM v$instance, v$diag_info WHERE name = 'Diag Trace';
--
SET SERVEROUT ON;
DECLARE
  l_child_number DBMS_UTILITY.number_array;
BEGIN
  SELECT DISTINCT child_number BULK COLLECT INTO l_child_number FROM v$sql WHERE sql_id = '&&sql_id.' AND object_status = 'VALID' AND is_obsolete = 'N' ORDER BY 1;
  IF l_child_number.LAST >= l_child_number.FIRST THEN
    FOR i IN l_child_number.FIRST .. l_child_number.LAST
    LOOP
      DBMS_OUTPUT.put_line(TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')||' DBMS_SQLDIAG.dump_trace of child_number:'||l_child_number(i));
      DBMS_SQLDIAG.dump_trace(p_sql_id => '&&sql_id.', p_child_number => l_child_number(i), p_component => '&&scope.', p_file_id => 'DUMP_TRACE_10053_&&sql_id._'||l_child_number(i));
    END LOOP;
  END IF;
END;
/
SET SERVEROUT OFF;
--
HOS mkdir -p /tmp/SQL_ID_&&sql_id.
--*/
HOS mv &&trace_dir./*DUMP_TRACE_10053_&&sql_id.*.trc /tmp/SQL_ID_&&sql_id.
--*/
HOS rename "ora_" "" /tmp/SQL_ID_&&sql_id./*ora*.trc
--*/
HOS chmod 644 /tmp/SQL_ID_&&sql_id./*DUMP_TRACE_10053_&&sql_id.*.trc
--*/
HOS ls -lt /tmp/SQL_ID_&&sql_id./*DUMP_TRACE_10053_&&sql_id.*.trc
--*/
PRO
PRO If you want to preserve traces, execute scp command below, from a TERM session running on your Mac/PC:
PRO scp &&host_name.:/tmp/SQL_ID_&&sql_id./*DUMP_TRACE_10053_&&sql_id.*.trc .
--*/
PRO