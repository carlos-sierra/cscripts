SET SERVEROUT ON;
BEGIN -- using pl/sql to avoid a blank line
  FOR i IN (SELECT RPAD(r.role, 13, ' ')||': '||d.db_unique_name||' HOST:'||h.host_name||CASE h.host_name WHEN '&&cs_host_name.' THEN ' <-' END AS dg_members
            FROM
            (SELECT x.value db_unique_name, ROW_NUMBER() OVER (ORDER BY x.indx) AS rn FROM x$drc x WHERE x.attribute = 'DATABASE') d,
            (SELECT x.value role, ROW_NUMBER() OVER (ORDER BY x.indx) AS rn FROM x$drc x WHERE x.attribute = 'role') r,
            (SELECT x.value host_name, ROW_NUMBER() OVER (ORDER BY x.indx) AS rn FROM x$drc x WHERE x.attribute = 'host') h
            WHERE r.rn = d.rn AND h.rn = d.rn
            ORDER BY r.role DESC, d.db_unique_name
  )
  LOOP
    DBMS_OUTPUT.put_line(i.dg_members);
  END LOOP;
END;
/
SET SERVEROUT OFF;
-- SET HEA OFF;
-- COL dg_members FOR A100;
-- SELECT RPAD(r.role, 13, ' ')||': '||d.db_unique_name||' HOST:'||h.host_name||CASE h.host_name WHEN '&&cs_host_name.' THEN ' <-' END AS dg_members
-- FROM
-- (SELECT x.value db_unique_name, ROW_NUMBER() OVER (ORDER BY x.indx) AS rn FROM x$drc x WHERE x.attribute = 'DATABASE') d,
-- (SELECT x.value role, ROW_NUMBER() OVER (ORDER BY x.indx) AS rn FROM x$drc x WHERE x.attribute = 'role') r,
-- (SELECT x.value host_name, ROW_NUMBER() OVER (ORDER BY x.indx) AS rn FROM x$drc x WHERE x.attribute = 'host') h
-- WHERE r.rn = d.rn AND h.rn = d.rn
-- ORDER BY r.role DESC, d.db_unique_name
-- /
-- SET HEA ON;