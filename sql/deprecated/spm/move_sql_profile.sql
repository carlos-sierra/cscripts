----------------------------------------------------------------------------------------
--
-- File name:   move_sql_profile.sql
--
-- Purpose:     Moves a SQL Profile from one statement to another.
-
-- Author:      Kerry Osborne
--
-- Usage:       This scripts prompts for four values.
--
--              profile_name: the name of the profile to be attached to a new statement
--
--              sql_id: the sql_id of the statement to attach the profile to
--
--              category: the category to assign to the new profile
--
--              force_macthing: a toggle to turn on or off the force_matching feature
--
-- Description: This script is based on a script originally written by Randolf Giest.
--              It's purpose is to allow a statements text to be manipulated in whatever
--              manner necessary (typically with hints) to get the desired plan. Then
--              once a SQL Profile has been created on the new statement, it's SQL Profile
--              can be moved (or attached) to the orignal statement with unmodified text.
--
-- Mods:        This script should now work wirh all flavors of 10g and 11g and 12c.
--
-- Notes:       Ran into a situation where two statements had differnt SQL ID's, but the signature
--              was the same. Results in an error that a SQL Profile already exists.
--              So the profile that was created on the first statement was already being applied
--              to the statement we were attempting to attach it to. This happens when two
--              statements only differ in white spaces or something that signature normalizes.
--
--              See kerryosborne.oracle-guy.com for additional information.
----------------------------------------------------------------------------------------- 

accept profile_name -
       prompt 'Enter value for profile_name: ' -
       default 'X0X0X0X0'
accept sql_id -
       prompt 'Enter value for sql_id: ' -
       default 'X0X0X0X0'
accept category -
       prompt 'Enter value for category (DEFAULT): ' -
       default 'DEFAULT'
accept force_matching -
       prompt 'Enter value for force_matching (false): ' -
       default 'false'


----------------------------------------------------------------------------------------
--
-- File name:   profile_hints.sql
--
---------------------------------------------------------------------------------------
--
set sqlblanklines on

declare
ar_profile_hints sys.sqlprof_attr;
cl_sql_text clob;
version varchar2(3);
l_category varchar2(30);
l_force_matching varchar2(3);
b_force_matching boolean;
begin
 select regexp_replace(version,'\..*') into version from v$instance;

if version = '10' then

-- dbms_output.put_line('version: '||version);
   execute immediate -- to avoid 942 error 
   'select attr_val as outline_hints '||
   'from dba_sql_profiles p, sqlprof$attr h '||
   'where p.signature = h.signature '||
   'and name like (''&&profile_name'') '||
   'order by attr#'
   bulk collect 
   into ar_profile_hints;

elsif version = '11' then

-- dbms_output.put_line('version: '||version);
   execute immediate -- to avoid 942 error 
   'select hint as outline_hints '||
   'from (select p.name, p.signature, p.category, row_number() '||
   '      over (partition by sd.signature, sd.category order by sd.signature) row_num, '||
   '      extractValue(value(t), ''/hint'') hint '||
   'from sqlobj$data sd, dba_sql_profiles p, '||
   '     table(xmlsequence(extract(xmltype(sd.comp_data), '||
   '                               ''/outline_data/hint''))) t '||
   'where sd.obj_type = 1 '||
   'and p.signature = sd.signature '||
   'and p.name like (''&&profile_name'')) '||
   'order by row_num'
   bulk collect 
   into ar_profile_hints;

end if;


/*
declare
ar_profile_hints sys.sqlprof_attr;
cl_sql_text clob;
begin
select attr_val as outline_hints
bulk collect
into
ar_profile_hints
from dba_sql_profiles p, sqlprof$attr h
where p.signature = h.signature
and name like ('&&profile_name')
order by attr#;
*/

select
sql_fulltext
into
cl_sql_text
from
v$sqlarea
where
sql_id = '&&sql_id';

dbms_sqltune.import_sql_profile(
sql_text => cl_sql_text
, profile => ar_profile_hints
, category => '&&category'
, name => 'PROFILE_'||'&&sql_id'||'_moved'
-- use force_match => true
-- to use CURSOR_SHARING=SIMILAR
-- behaviour, i.e. match even with
-- differing literals
, force_match => &&force_matching
);
end;
/

undef profile_name
undef sql_id
undef category
undef force_matching

