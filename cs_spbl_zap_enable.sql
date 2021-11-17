
----------------------------------------------------------------------------------------
--
-- File name:   ze.sql | cs_spbl_zap_enable.sql
--
-- Purpose:     Enable ZAPPER on CDB
--
-- Author:      Carlos Sierra
--
-- Version:     2021/03/11
--
-- Usage:       Connecting into CDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_spbl_zap_enable.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
ALTER SESSION SET container = CDB$ROOT;
-- enable zapper-19
UPDATE C##IOD.zapper_config SET enabled = 'Y' WHERE enabled = 'N'
/
COMMIT
/
PRO
PRO ZAPPER-19 is now ENABLED
PRO