----------------------------------------------------------------------------------------
--
-- File name:   pr.sql | cs_pr.sql 
--
-- Purpose:     Print Table (vertical display of result columns for last query)
--
-- Author:      Carlos Sierra
--
-- Version:     2020/12/06
--
-- Usage:       Execute connected to PDB or CDB. 
--
--              Parameter options:
--
--              1. null (assumes then last sql executed)
--
--              2. directory_path/script_name.sql (with one query)
--
--              3. one query
--
-- Examples:    1. SQL> @cs_pr.sql ""
--
--              2. SQL> @cs_pr.sql "/tmp/carlos.sql"
--
--              3. SQL> @cs_pr.sql "SELECT * FROM v$database;"
--
-- Notes:       When passing a query which contains single quotes then double them
--              e.g. SQL> @cs_pr.sql "SELECT sid||'',''||serial# AS sid_serial FROM v$session"
--
--              Last sql executed must end with "/" or with ";".  When the latter, then 
--              the ";" must immediately follow the last piece of the SQL text, and not be
--              on the next line by itself. First sample below is correct while second is not:
--                
--                SQL> SELECT * FROM DUAL;
--
--                SQL> SELECT * FROM DUAL
--                SQL> ;
-- 
--              Modified version of Tanel Poder pr.sql script, which is a mofified version
--              of Tom Kyte printtbl code.
--             
---------------------------------------------------------------------------------------
--
-- https://github.com/tanelpoder/tpt-oracle/blob/master/pr.sql
-- Notes:   This script is based on Tom Kyte's original printtbl code ( http://asktom.oracle.com )
--          For coding simplicity (read: lazyness) I'm using custom quotation marks ( q'\ ) so 
--          this script works only from Oracle 10gR2 onwards
-- prompt Pivoting output using Tom Kyte's printtab....
--
SET TERM OFF;
-- stores last sql executed
SAVE "/tmp/cs_pr_last_executed.sql" REPLACE;
STORE SET "/tmp/cs_pr_set_config.sql" REPLACE;
--
SET TERM ON HEA OFF TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON SERVEROUT ON SIZE UNL TRIM ON LIN 4050 BLO .;
--
PRO
PRO 1. Enter [{null}|directory_path/script_name.sql|query]:
DEF cs_input_parameter = '&1.';
UNDEF 1;
--SET TERM OFF;
--
COL cs_option NEW_V cs_option NOPRI;
COL cs_parameter NEW_V cs_parameter NOPRI;
SELECT CASE 
         WHEN q'[&&cs_input_parameter.]' IS NULL THEN '1' -- null
         WHEN LOWER(SUBSTR(q'[&&cs_input_parameter.]', -4, 4)) = '.sql' THEN '2' -- directory_path/script_name.sql
         ELSE '3' -- query
       END AS cs_option,
       CASE 
         WHEN q'[&&cs_input_parameter.]' IS NULL THEN '/tmp/cs_pr_last_executed.sql' -- null
         WHEN LOWER(SUBSTR(q'[&&cs_input_parameter.]', -4, 4)) = '.sql' THEN q'[&&cs_input_parameter.]' -- directory_path/script_name.sql
         ELSE q'[&&cs_input_parameter.]' -- query
       END AS cs_parameter
  FROM DUAL
/
-- stores inline query
SPOOL "/tmp/cs_pr_inline_query.sql";
PRO &&cs_parameter.
SPOOL OFF;
--
COL script_name NEW_V script_name NOPRI;
SELECT CASE '&&cs_option.'
       WHEN '1' THEN '/tmp/cs_pr_last_executed.sql' -- null
       WHEN '2' THEN q'[&&cs_parameter.]' -- directory_path/script_name.sql
       WHEN '3' THEN '/tmp/cs_pr_inline_query.sql' -- query
       END AS script_name
  FROM DUAL
/
--
GET "&&script_name." LIST;
SAVE "/tmp/cs_pr_last_executed.sql" REPLACE;
--
SET TERM ON;
PRO
PRO
PRO +--------------------------------+
GET "&&script_name." LIST;
.
SET TERM OFF;
--
0 c clob := q'\
0 declare
--
666666      \';;
666666      l_theCursor     integer default dbms_sql.open_cursor;;
666666      l_columnValue   varchar2(4000);;
666666      l_status        integer;;
666666      l_descTbl       dbms_sql.desc_tab;;
666666      l_colCnt        number;;
666666      l_amount        number;;
666666  begin
666666      IF DBMS_LOB.instr(c, ';') = 0 THEN 
666666        l_amount := DBMS_LOB.getlength(c);;
666666      ELSE 
666666        l_amount := DBMS_LOB.instr(c, ';') - 1;;
666666      END IF;;
666666      c := DBMS_LOB.substr(c, l_amount);;
666666      dbms_sql.parse(  l_theCursor, c, dbms_sql.native );;
666666      dbms_sql.describe_columns( l_theCursor, l_colCnt, l_descTbl );;
666666      for i in 1 .. l_colCnt loop
666666        if l_descTbl(i).col_type not in (112, 113) then -- excludes blob and clob (see https://docs.oracle.com/cd/E11882_01/server.112/e41085/sqlqr06002.htm#SQLQR959)
666666          dbms_sql.define_column( l_theCursor, i,
666666                                  l_columnValue, 4000 );;
666666        end if;;
666666      end loop;;
666666      l_status := dbms_sql.execute(l_theCursor);;
666666      while ( dbms_sql.fetch_rows(l_theCursor) > 0 ) loop
666666          dbms_output.put_line( '+--------------------------------+' );;
666666          for i in 1 .. l_colCnt loop
666666            if l_descTbl(i).col_type not in (112, 113) then -- excludes blob and clob (see https://docs.oracle.com/cd/E11882_01/server.112/e41085/sqlqr06002.htm#SQLQR959)
666666                  dbms_sql.column_value( l_theCursor, i,
666666                                         l_columnValue );;
666666                  dbms_output.put_line
666666                      ( '|'||lpad( lower(l_descTbl(i).col_name),
666666                        31 ) || ' : ' || l_columnValue );;
666666            end if;;
666666          end loop;;
666666      end loop;;
666666      dbms_output.put_line( '+--------------------------------+' );;
666666  exception
666666      when others then
666666          dbms_output.put_line(dbms_utility.format_error_backtrace);;
666666          raise;;
666666 end;;
SET TERM ON;
/
--
GET "&&script_name." LIST;
.
PRO +--------------------------------+
PRO
PRO
@"/tmp/cs_pr_set_config.sql";
HOST rm "/tmp/cs_pr_set_config.sql" "/tmp/cs_pr_last_executed.sql" "/tmp/cs_pr_inline_query.sql";
SET TERM ON;
--
-- from cs_ash_sample_detail.sql and cs_blocked_sessions_report.sql
UNDEF sid session sample_date_and_time