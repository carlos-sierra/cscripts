PRO Executing: SQL> @@snapper.sql ash=sid+service_name+module+machine+sql_id+sql_child_number+wait_class+event 1 1 "select s.inst_id,s.sid from gv$session s, gv$process p where p.spid = '&&spid.' AND p.addr = s.paddr"
@@snapper.sql ash=sid+service_name+module+machine+sql_id+sql_child_number+wait_class+event 1 1 "select s.inst_id,s.sid from gv$session s, gv$process p where p.spid = '&&spid.' AND p.addr = s.paddr"
PRO Executing: SQL> @@snapper.sql all 10 1 "select s.inst_id,s.sid from gv$session s, gv$process p where p.spid = '&&spid.' AND p.addr = s.paddr"
@@snapper.sql all 10 1 "select s.inst_id,s.sid from gv$session s, gv$process p where p.spid = '&&spid.' AND p.addr = s.paddr"
UNDEF spid;
UNDEF 1 2 3 4;
