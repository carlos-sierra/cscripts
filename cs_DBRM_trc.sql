----------------------------------------------------------------------------------------
--
-- File name:   cs_DBRM_trc.sql
--
-- Purpose:     Get database resource manager DBRM trace
--
-- Author:      Carlos Sierra
--
-- Version:     2022/09/08
--
-- Usage:       Execute connected to CDB or PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_DBRM_trc.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
--
COL trace_dir NEW_V trace_dir FOR A100 NOPRI;
COL dbrm_trc NEW_V dbrm_trc FOR A30 NOPRI;
SELECT d.value AS trace_dir, LOWER('&&cs_db_name._')||LOWER(p.pname)||'_'||p.spid||'.trc' AS dbrm_trc FROM v$diag_info d, v$process p WHERE d.name = 'Diag Trace' AND p.pname = 'DBRM';
--
HOS cat &&trace_dir./&&dbrm_trc.
PRO 
PRO &&trace_dir./&&dbrm_trc.
PRO
HOS cp &&trace_dir./&&dbrm_trc. /tmp/
HOS chmod 644 /tmp/&&dbrm_trc.
PRO
PRO Preserved dbrm trace on /tmp
PRO ~~~~~~~~~~~~~~~~~~~~~~~
HOS ls -oX /tmp/&&dbrm_trc.
PRO
PRO If you want to copy dbrm trace file, execute scp command below, from a TERM session running on your Mac/PC:
PRO
PRO scp &&cs_host_name.:/tmp/&&dbrm_trc. &&cs_local_dir.
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--
