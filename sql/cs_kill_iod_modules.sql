PRO
PRO kill IOD jobs in execution (expecting none). wait up to 60 seconds...
SET SERVEROUT ON;
EXEC C##IOD.IOD_ADMIN.kill_iod_jobs;