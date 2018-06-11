-- generates init.ora (pfile) from spfile and memory 

COL spfile NEW_V spfile NOPRI;
SELECT value spfile FROM v$system_parameter WHERE name = 'spfile';

COL partial_filename NEW_V partial_filename NOPRI;
SELECT LOWER(name)||'_'||LOWER(REPLACE(SUBSTR(host_name, 1 + INSTR(host_name, '.', 1, 2), 30), '.', '_'))||'_'||TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') partial_filename FROM v$database, v$instance;

COL pfile_from_spfile NEW_V pfile_from_spfile NOPRI;
SELECT 'pfile_from_spfile_for_&&partial_filename.' pfile_from_spfile FROM DUAL;

COL pfile_from_memory NEW_V pfile_from_memory NOPRI;
SELECT 'pfile_from_memory_for_&&partial_filename.' pfile_from_memory FROM DUAL;


CREATE PFILE = '/tmp/&&pfile_from_spfile..txt' FROM SPFILE = '&&spfile.';
CREATE PFILE = '/tmp/&&pfile_from_memory..txt' FROM MEMORY;
 
HOS cp /tmp/&&pfile_from_spfile..txt .
HOS cp /tmp/&&pfile_from_memory..txt .

PRO
PRO &&pfile_from_spfile..txt was created
PRO &&pfile_from_memory..txt was created
PRO