SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;

COL p95 HEA '95th PCTL';
COL p97 HEA '97th PCTL';
COL p99 HEA '99th PCTL';
COL p99 HEA '99th PCTL';
COL p999 HEA '99.9th PCTL';
COL max HEA 'MAX';

BREAK ON REPORT;
COMPUTE SUM LABEL 'TOTAL' OF p95 p97 p99 p999 max ON REPORT;

WITH 
by_sample AS (
SELECT machine,
       sample_id,
       COUNT(*) cnt
  FROM dba_hist_active_sess_history
 GROUP BY
       machine,
       sample_id
)
SELECT machine,
       PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY cnt) p95,
       PERCENTILE_DISC(0.97) WITHIN GROUP (ORDER BY cnt) p97,
       PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY cnt) p99,
       PERCENTILE_DISC(0.999) WITHIN GROUP (ORDER BY cnt) p999,
       MAX(cnt) max
  FROM by_sample
 GROUP BY
       machine
 ORDER BY
       machine
/

CLEAR BREAK COMPUTE;

