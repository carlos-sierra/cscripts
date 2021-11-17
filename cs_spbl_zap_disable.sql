
----------------------------------------------------------------------------------------
--
-- File name:   zd.sql | cs_spbl_zap_disable.sql
--
-- Purpose:     Disable ZAPPER on CDB
--
-- Author:      Carlos Sierra
--
-- Version:     2021/03/11
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
-- disable zapper-19
UPDATE C##IOD.zapper_config SET enabled = 'N' WHERE enabled = 'Y'
/
COMMIT
/
PRO
PRO ZAPPER-19 is now DISABLED persistently. It will NOT be re-enabled automatically.
PRO