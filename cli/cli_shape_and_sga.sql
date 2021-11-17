COL host_name FOR A64;
COL db_u_name FOR A12;
COL db_role FOR A20;
COL host_type FOR A20;
COL sga_max_size FOR A12;
COL err FOR A3;
--
-- iodcli sql_exec -y file:/Users/csierra/git/bitbucket.oci.oraclecorp.com/dbeng/oratk/sql/cscripts/cli/cli_shape_and_sga.sql hcg:HC_DATABASE > cli_shape_and_sga.txt
-- cat cli_shape_and_sga.txt | grep "\*\*\*" | grep -v OMR | grep -v "\.pop" > cli_shape_and_sga_err.txt
-- cat cli_shape_and_sga_err.txt | grep -i casper > cli_shape_and_sga_casper_err.txt
--
WITH
system AS (
    SELECT host_shape, ROW_NUMBER() OVER (ORDER BY timestamp DESC) AS rn FROM C##IOD.dbc_system 
)
SELECT --i.host_name, d.db_unique_name AS db_u_name, 
       d.database_role AS db_role, s.host_shape AS host_type, p.display_value AS sga_max_size,
       CASE WHEN s.host_shape LIKE 'x7%' AND p.value < 500 * POWER(2, 30) THEN '***' END AS err
  FROM system s,
       v$system_parameter p,
       v$database d,
       v$instance i
 WHERE s.rn = 1
   AND p.name = 'sga_max_size'
/
