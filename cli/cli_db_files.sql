SET PAGES 0 HEA OFF;
WITH
d AS (SELECT TO_NUMBER(value) AS cnt FROM v$system_parameter WHERE name = 'db_files'),
v AS (SELECT COUNT(*) AS cnt FROM v$datafile)
SELECT 'db_files:'||d.cnt||' v$datafile:'||v.cnt||' remaining:'||(d.cnt - v.cnt)
  FROM d, v
/
