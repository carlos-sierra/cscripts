SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
COL created FOR A26 HEA 'Created';
COL last_modified FOR A19 HEA 'Last Modified';
COL signature FOR 99999999999999999999 HEA 'Signature';
COL category FOR A10 HEA 'Category' TRUNC;
COL obj_type FOR 99999999 HEA 'Obj Type';
COL plan_name FOR A30 HEA 'Plan Name';
COL ori FOR 999 HEA 'Ori';
COL sql_handle FOR A30 HEA 'SQL Handle';
COL sql_text FOR A80 HEA 'SQL Text' TRUNC;
COL description FOR A125 HEA 'Description';
COL category FOR A30;
COL enabled FOR A10 HEA 'Enabled';
COL accepted FOR A10 HEA 'Accepted';
COL fixed FOR A10 HEA 'Fixed' PRI;
COL reproduced FOR A10 HEA 'Reproduced';
COL autopurge FOR A10 HEA 'Autopurge';
COL adaptive FOR A10 HEA 'Adaptive';
COL plan_id FOR 999999999990 HEA 'Plan ID';
-- only works from PDB. do not use CONTAINERS(table_name) since it causes ORA-00600: internal error code, arguments: [kkdolci1], [], [], [], [], [], [],
SELECT o.signature,
       o.category,
       o.obj_type,
       o.plan_id,
       o.name AS plan_name,
       TO_CHAR(a.created, 'YYYY-MM-DD"T"HH24:MI:SS') AS created,
       TO_CHAR(a.last_modified, 'YYYY-MM-DD"T"HH24:MI:SS') AS last_modified, 
       DECODE(BITAND(o.flags, 1),   0, 'NO', 'YES') AS enabled,
       DECODE(BITAND(o.flags, 2),   0, 'NO', 'YES') AS accepted,
       DECODE(BITAND(o.flags, 4),   0, 'NO', 'YES') AS fixed,
       DECODE(BITAND(o.flags, 64),  0, 'YES', 'NO') AS reproduced,
       DECODE(BITAND(o.flags, 128), 0, 'NO', 'YES') AS autopurge,
       DECODE(BITAND(o.flags, 256), 0, 'NO', 'YES') AS adaptive, 
       a.origin AS ori, 
       t.sql_handle,
       t.sql_text,
       a.description
  FROM sys.sqlobj$ o,
       sys.sqlobj$auxdata a,
       sys.sql$text t
 WHERE o.category = 'DEFAULT'
   AND o.obj_type = 2 /* 1:profile, 2:baseline, 3:patch */
   AND a.signature = o.signature
   AND a.category = o.category
   AND a.obj_type = o.obj_type
   AND a.plan_id = o.plan_id
   AND t.signature = o.signature
   AND NOT EXISTS (
         SELECT NULL
           FROM sys.sqlobj$plan p
          WHERE p.signature = o.signature
            AND p.category = o.category
            AND p.obj_type = o.obj_type 
            AND p.plan_id = o.plan_id
            AND ROWNUM = 1
   )
   AND NOT EXISTS (
         SELECT NULL
           FROM sys.sqlobj$data d
          WHERE d.signature = o.signature
            AND d.category = o.category
            AND d.obj_type = o.obj_type 
            AND d.plan_id = o.plan_id
            AND d.comp_data IS NOT NULL
            AND ROWNUM = 1
   )
 ORDER BY
       o.signature, o.category, o.obj_type, o.plan_id
/