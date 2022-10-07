SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
SET HEA OFF PAGES 0;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
COL line FOR A2000;
/*
iodcli sql_exec -y -t PRIMARY -p KIEV_METADATA file:/Users/csierra/git/bitbucket.oci.oraclecorp.com/dbeng/oratk/sql/cscripts/cli/cli_get_kiev_metadata.sql hcg:HC_KIEV > kiev_metadata1.txt
iodcli sql_exec -y -t PRIMARY -p KIEV_METADATA file:/Users/csierra/git/bitbucket.oci.oraclecorp.com/dbeng/oratk/sql/cscripts/cli/cli_get_kiev_metadata.sql hcg:HC_KIEV > kiev_metadata2.txt
cat kiev_metadata1.txt kiev_metadata2.txt | cut -b 115- | grep "^EXEC c##iod.merge_kiev_metadata(" | grep ");$" | grep -v "  " | sort | uniq > kiev_metadata.sql
cp kiev_metadata.sql /Users/csierra/git/bitbucket.oci.oraclecorp.com/dbeng/oratk/sql/cscripts/
ssho iod-db-kiev-01307.node.ad1.r1
--@kiev_metadata_setup.sql
@kiev_metadata.sql
@iod_fleet_kiev_metadata.sql
scp iod-db-kiev-01307.node.ad1.r1:/tmp/iod_fleet_kiev_metadata.txt .
*/    
--
COL kiev_owner NEW_V kiev_owner NOPRI;
SELECT owner AS kiev_owner FROM dba_tables WHERE table_name = 'V2_DATASTORES';
--
WITH
ds AS (
SELECT k.jdbcurl, k.schemaname, k.storename, k.state, k.dns, k.compartmentid, k.tenancyid, k.created, k.lastmodified, json_value(k.datastoremetadata, '$.phonebookEntry') AS phonebookentry
  FROM &&kiev_owner..V2_DATASTORES k
),
m AS (
SELECT REPLACE(ds.jdbcurl, 'jdbc:oracle:thin:@//') AS jdbcurl, ds.schemaname, ds.storename, ds.state, ds.dns, ds.compartmentid, ds.tenancyid, TO_CHAR(ds.created, 'YYYY-MM-DD"T"HH24:MI:SS') AS created, TO_CHAR(ds.lastmodified, 'YYYY-MM-DD"T"HH24:MI:SS') AS lastmodified, CASE WHEN INSTR(ds.phonebookentry, '/') > 0 THEN SUBSTR(ds.phonebookentry, INSTR(ds.phonebookentry, '/', -1) +1) ELSE ds.phonebookentry END AS phonebookentry,
       i.host_name, p1.value AS db_domain, d.name AS db_name, TO_CHAR(SYSDATE, 'YYYY-MM-DD') AS version
  FROM ds, v$instance i, v$database d, v$parameter p1
 WHERE p1.name = 'db_domain'
)
SELECT  'EXEC c##iod.merge_kiev_metadata('||
        ''''||version||''','||
        ''''||db_domain||''','||
        ''''||db_name||''','||
        ''''||host_name||''','||
        ''''||jdbcurl||''','||
        ''''||schemaname||''','||
        ''''||storename||''','||
        ''''||state||''','||
        ''''||dns||''','||
        ''''||compartmentid||''','||
        ''''||tenancyid||''','||
        ''''||created||''','||
        ''''||lastmodified||''','||
        ''''||phonebookentry||''');' AS line
FROM    m
ORDER BY
        jdbcurl
/
