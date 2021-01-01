
----------------------------------------------------------------------------------------
--
-- File name:   zd.sql | cs_spbl_zap_disable.sql
--
-- Purpose:     Disable ZAPPER on CDB
--
-- Author:      Carlos Sierra
--
-- Version:     2020/12/25
--
-- Usage:       Connecting into CDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_spbl_zap_disable.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
ALTER SESSION SET container = CDB$ROOT;
--
-- disable legacy zapper
UPDATE &&cs_tools_schema..zapper_config SET enabled = 'N' WHERE enabled = 'Y'
/
-- disable zapper-19
UPDATE &&cs_tools_schema..zapper_global SET enabled = 'N' WHERE enabled = 'Y'
/
COMMIT
/
PRO
PRO ZAPPER and ZAPPER-19 are now DISABLED persistently. They will NOT be re-enabled automatically.
PRO