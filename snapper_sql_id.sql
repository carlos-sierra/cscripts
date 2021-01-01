PRO Executing: SQL> @@snapper.sql ash=service_name,ash1=module,ash2=machine,ash3=sid+service_name+module+machine+sql_id+sql_child_number+wait_class+event 1 1 "select inst_id,sid from gv$session where sql_id='&&sql_id.' OR prev_sql_id='&&sql_id.'"
@@snapper.sql ash=service_name,ash1=module,ash2=machine,ash3=sid+service_name+module+machine+sql_id+sql_child_number+wait_class+event 1 1 "select inst_id,sid from gv$session where sql_id='&&sql_id.' OR prev_sql_id='&&sql_id.'"
PRO Executing: SQL> @@snapper.sql all 10 1 "select inst_id,sid from gv$session where sql_id='&&sql_id.' OR prev_sql_id='&&sql_id.'"
@@snapper.sql all 10 1 "select inst_id,sid from gv$session where sql_id='&&sql_id.' OR prev_sql_id='&&sql_id.'"
UNDEF sql_id;
UNDEF 1 2 3 4;
