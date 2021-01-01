PRO Executing: SQL> @@snapper.sql ash=service_name,ash1=module,ash2=machine,ash3=sid+service_name+module+machine+sql_id+sql_child_number+wait_class+event 5 1 "select inst_id,sid from gv$session where lower(service_name) like lower('%&&service_name.%')"
@@snapper.sql ash=service_name,ash1=module,ash2=machine,ash3=sid+service_name+module+machine+sql_id+sql_child_number+wait_class+event 5 1 "select inst_id,sid from gv$session where lower(service_name) like lower('%&&service_name.%')"
--PRO Executing: SQL> @@snapper.sql all 10 1 "select inst_id,sid from gv$session where lower(service_name) like lower('%&&service_name.%')"
--@@snapper.sql all 10 1 "select inst_id,sid from gv$session where lower(service_name) like lower('%&&service_name.%')"
UNDEF service_name;
UNDEF 1 2 3 4;
