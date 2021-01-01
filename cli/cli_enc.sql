SELECT a.username, a.osuser, a.sid, a.serial#, TO_CHAR(a.logon_time, 'MON-DD-YYYY HH:MI:SS PM') LOGON_TIME, a.status,
   c.authentication_type AUTHENTICATION,
   decode (c.NETWORK_SERVICE_BANNER,
               'TCP/IP NT Protocol Adapter for Linux: Version 12.1.0.2.0 - Production', 'Not-In-Use',
               'Encryption service for Linux: Version 12.1.0.2.0 - Production', 'Not-In-Use',
               'Crypto-checksumming service for Linux: Version 12.1.0.2.0 - Production', 'Not-In-Use',
               c.NETWORK_SERVICE_BANNER) network_encryption
FROM v$session a,
        (SELECT DISTINCT b.sid, b.authentication_type, b.NETWORK_SERVICE_BANNER FROM v$session_connect_info b) c, v$process d
WHERE a.sid = c.sid AND a.username NOT IN ('SYSTEM','SYS') AND d.addr = a.paddr
and c.NETWORK_SERVICE_BANNER not in 
('TCP/IP NT Protocol Adapter for Linux: Version 12.1.0.2.0 - Production',
 'Encryption service for Linux: Version 12.1.0.2.0 - Production', 'Not-In-Use',
 'Crypto-checksumming service for Linux: Version 12.1.0.2.0 - Production')
ORDER BY LOGON_TIME, a.username;