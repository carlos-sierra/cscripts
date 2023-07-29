----------------------------------------------------------------------------------------
--
-- File name:   cs_acs_disable.sql
--
-- Purpose:     Disable Adaptive Cursor Sharing (ACS)
--
-- Author:      Carlos Sierra
--
-- Version:     2022/02/07
--
-- Usage:       Connecting into PDB or CDB.
--
--              Confirm when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_acs_disable.sql
--
-- Notes:       Developed and tested on 19c.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
--
PRO
PRO ***
PRO *** You are about to DISABLE Adaptive Cursor Sharing (ACS) for &&cs_con_name.
PRO ***
PRO
PRO 1. Enter "Yes" (case sensitive) to continue, else <ctrl>-C
DEF cs_confirm = '&1.';
UNDEF 1;
--
SET SERVEROUT ON;
BEGIN
  IF '&&cs_confirm.' = 'Yes' THEN
    EXECUTE IMMEDIATE 'ALTER SYSTEM SET "_optimizer_adaptive_cursor_sharing" = FALSE';
    EXECUTE IMMEDIATE 'ALTER SYSTEM SET "_optimizer_extended_cursor_sharing_rel" = "NONE"';
    EXECUTE IMMEDIATE 'ALTER SYSTEM SET "_optimizer_extended_cursor_sharing" = "NONE"';
    DBMS_OUTPUT.put_line('Done');
  ELSE
    DBMS_OUTPUT.put_line('Null');
  END IF;
END;
/
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--