MERGE INTO C##iod.exceptions_black_list o
 USING (SELECT 'TABLE_REDEFINITION' AS iod_api,'ASIODLIVE' AS pdb_name, 'DBPERF-7887 KPT-29' AS reference FROM DUAL
        ) i
  ON (o.iod_api = i.iod_api AND o.pdb_name = i.pdb_name)
WHEN MATCHED THEN
  UPDATE SET o.reference = i.reference
WHEN NOT MATCHED THEN
  INSERT (iod_api, pdb_name, reference)
  VALUES (i.iod_api, i.pdb_name, i.reference)
/
COMMIT
/