WITH
perc_per_snap AS (
SELECT SUBSTR(UPPER(SUBSTR(host_name,INSTR(host_name,'.',-1)+1)), 1, 50) AS region,
       dbname,
       timestamp,
       u02_size,
       100 * u02_used / u02_size AS perc,
       ROW_NUMBER() OVER (ORDER BY timestamp ASC) AS rn_first,
       ROW_NUMBER() OVER (ORDER BY timestamp DESC) AS rn_last
  FROM c##iod.dbc_system
 WHERE timestamp IS NOT NULL
),
space_inc AS (
SELECT f.region,
       f.dbname,
       f.u02_size,
       (l.timestamp - f.timestamp) AS days,
       f.perc AS f_perc,
       l.perc AS l_perc,
       (365 / 12) * (l.perc - f.perc) / (l.timestamp - f.timestamp) perc_inc_per_month
  FROM perc_per_snap f,
       perc_per_snap l
 WHERE f.rn_first = 1
   AND l.rn_last = 1
)
SELECT region,
       dbname,
       u02_size * 1024 / POWER(10,12) AS u02_tb,
       perc_inc_per_month,
       l_perc AS util_current,
       l_perc + CASE WHEN perc_inc_per_month > 0 THEN 1 * perc_inc_per_month ELSE 0 END AS util_1month, 
       l_perc + CASE WHEN perc_inc_per_month > 0 THEN 2 * perc_inc_per_month ELSE 0 END AS util_2month, 
       l_perc + CASE WHEN perc_inc_per_month > 0 THEN 3 * perc_inc_per_month ELSE 0 END AS util_3month, 
       l_perc + CASE WHEN perc_inc_per_month > 0 THEN 4 * perc_inc_per_month ELSE 0 END AS util_4month, 
       l_perc + CASE WHEN perc_inc_per_month > 0 THEN 5 * perc_inc_per_month ELSE 0 END AS util_5month, 
       l_perc + CASE WHEN perc_inc_per_month > 0 THEN 6 * perc_inc_per_month ELSE 0 END AS util_6month 
  FROM space_inc;
