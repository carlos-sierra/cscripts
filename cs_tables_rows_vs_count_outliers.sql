SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
-- cs_tables_rows_vs_count_outliers.sql - Compares CBO Stats Rows to COUNT(*) on Application Tables and Reports Outliers
SET SERVEROUT ON;
DECLARE
  l_cnt INTEGER;
  l_pct INTEGER;
BEGIN
  FOR i IN (SELECT t.owner, t.table_name, t.num_rows, t.last_analyzed FROM dba_tables t, dba_users u WHERE /*t.owner <> 'C##IOD' AND t.table_name NOT LIKE 'KIEV%' AND t.num_rows > 0 AND*/ t.last_analyzed < SYSDATE -1 AND u.username = t.owner AND u.oracle_maintained = 'N' ORDER BY t.owner, t.table_name)
  LOOP
    IF NVL(i.num_rows, 0) < 1e6 THEN
      EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM '||i.owner||'.'||i.table_name INTO l_cnt;
    ELSE
      EXECUTE IMMEDIATE 'SELECT 100 * COUNT(*) FROM '||i.owner||'.'||i.table_name||' SAMPLE(1)' INTO l_cnt;
    END IF;
    l_pct := ROUND(100 * (l_cnt - i.num_rows) / NULLIF(i.num_rows, 0));
    IF ABS(l_pct) > 10 THEN
      DBMS_OUTPUT.put_line(RPAD(i.owner||'.'||i.table_name, 61, '.')||'  GAP:'||LPAD(NVL(TO_CHAR(l_pct), ' '), 4)||'%  DAYS:'||LPAD(NVL(TO_CHAR(ROUND(SYSDATE - i.last_analyzed)), ' '), 4)||'  COUNT:'||LPAD(l_cnt, 10)||'  NUM_ROWS:'||LPAD(i.num_rows, 10)||'  ANALYZED:'||TO_CHAR(i.last_analyzed, 'YYYY-MM-DD"T"HH24:MI:SS'));
    END IF;
  END LOOP;
END;
/
