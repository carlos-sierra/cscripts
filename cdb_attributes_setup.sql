-- Create cdb_attributes Table and merge_cdb_attributes Procedure for IOD Fleet Inventory
CREATE TABLE c##iod.cdb_attributes (
  -- soft PK
  version                         VARCHAR2(10),
  host_name                       VARCHAR2(64),
  -- columns
  db_domain                       VARCHAR2(64),
  disk_config                     VARCHAR2(16),
  host_shape                      VARCHAR2(64),
  host_class                      VARCHAR2(64),
  num_cpu_cores                   NUMBER,
  num_cpu_threads                 NUMBER,
  maxed_out                       NUMBER,
  cdb_weight                      NUMBER,
  load_avg                        NUMBER,
  load_p90                        NUMBER,
  load_p95                        NUMBER,
  load_p99                        NUMBER,
  aas_on_cpu_avg                  NUMBER,
  aas_on_cpu_p90                  NUMBER,
  aas_on_cpu_p95                  NUMBER,
  aas_on_cpu_p99                  NUMBER,
  u02_size_1m                     NUMBER,
  u02_used_1m                     NUMBER,
  u02_available_1m                NUMBER,
  u02_size                        NUMBER,
  u02_used                        NUMBER,
  u02_available                   NUMBER,
  fs_u02_util_perc                NUMBER,
  fs_u02_at_80p                   VARCHAR2(10),
  fs_u02_at_90p                   VARCHAR2(10),
  fs_u02_at_95p                   VARCHAR2(10),
  db_name                         VARCHAR2(9),
  dg_members                      NUMBER,
  pdbs                            NUMBER,
  kiev_flag                       VARCHAR2(1),
  kiev_pdbs                       NUMBER,
  wf_flag                         VARCHAR2(1),
  wf_pdbs                         NUMBER,
  casper_flag                     VARCHAR2(1),
  casper_pdbs                     NUMBER,
  -- extension
  realm_type                      VARCHAR2(12), -- Commercial | Government
  realm_type_order_by             NUMBER,
  realm                           VARCHAR2(12), -- R1, OC1, OC2, OC3, OC4
  realm_order_by                  NUMBER,
  region                          VARCHAR2(64),
  region_acronym                  VARCHAR2(10),
  region_order_by                 NUMBER,
  locale                          VARCHAR2(4),
  locale_order_by                 NUMBER
)
TABLESPACE iod
/

ALTER TABLE c##iod.cdb_attributes ADD (
  disk_config                     VARCHAR2(16),
  host_shape                      VARCHAR2(64),
  host_class                      VARCHAR2(64)
)
/

/*
ALTER TABLE c##iod.cdb_attributes DROP column cpu_threads;
ALTER TABLE c##iod.cdb_attributes ADD (
  num_cpu_threads                     NUMBER
)
/
*/

CREATE OR REPLACE 
PROCEDURE c##iod.merge_cdb_attributes (
  p_version                 IN VARCHAR2,
  p_host_name               IN VARCHAR2,
  p_db_domain               IN VARCHAR2,
  p_disk_config             IN VARCHAR2,
  p_host_shape              IN VARCHAR2,
  p_host_class              IN VARCHAR2,
  p_num_cpu_cores           IN NUMBER,
  p_num_cpu_threads         IN NUMBER,
  p_maxed_out               IN NUMBER,
  p_cdb_weight              IN NUMBER,
  p_load_avg                IN NUMBER,
  p_load_p90                IN NUMBER,
  p_load_p95                IN NUMBER,
  p_load_p99                IN NUMBER,
  p_aas_on_cpu_avg          IN NUMBER,
  p_aas_on_cpu_p90          IN NUMBER,
  p_aas_on_cpu_p95          IN NUMBER,
  p_aas_on_cpu_p99          IN NUMBER,
  p_u02_size_1m             IN NUMBER,
  p_u02_used_1m             IN NUMBER,
  p_u02_available_1m        IN NUMBER,
  p_u02_size                IN NUMBER,
  p_u02_used                IN NUMBER,
  p_u02_available           IN NUMBER,
  p_fs_u02_util_perc        IN NUMBER,
  p_fs_u02_at_80p           IN VARCHAR2,
  p_fs_u02_at_90p           IN VARCHAR2,
  p_fs_u02_at_95p           IN VARCHAR2,
  p_db_name                 IN VARCHAR2,
  p_dg_members              IN NUMBER,
  p_pdbs                    IN NUMBER,
  p_kiev_pdbs               IN NUMBER,
  p_wf_pdbs                 IN NUMBER,
  p_casper_pdbs             IN NUMBER
)
IS
  r c##iod.cdb_attributes%ROWTYPE;
BEGIN
  r.version := p_version;
  r.host_name := LOWER(TRIM(p_host_name));
  r.db_domain := LOWER(TRIM(p_db_domain));
  r.disk_config := LOWER(TRIM(p_disk_config));
  r.host_shape := LOWER(TRIM(p_host_shape));
  r.host_class := UPPER(TRIM(p_host_class));
  r.num_cpu_cores := p_num_cpu_cores;
  r.num_cpu_threads := p_num_cpu_threads;
  r.maxed_out := p_maxed_out;
  r.cdb_weight := p_cdb_weight;
  r.load_avg := p_load_avg;
  r.load_p90 := p_load_p90;
  r.load_p95 := p_load_p95;
  r.load_p99 := p_load_p99;
  r.aas_on_cpu_avg := p_aas_on_cpu_avg;
  r.aas_on_cpu_p90 := p_aas_on_cpu_p90;
  r.aas_on_cpu_p95 := p_aas_on_cpu_p95;
  r.aas_on_cpu_p99 := p_aas_on_cpu_p99;
  r.u02_size_1m := p_u02_size_1m;
  r.u02_used_1m := p_u02_used_1m;
  r.u02_available_1m := p_u02_available_1m;
  r.u02_size := p_u02_size;
  r.u02_used := p_u02_used;
  r.u02_available := p_u02_available;
  r.fs_u02_util_perc := p_fs_u02_util_perc;
  r.fs_u02_at_80p := p_fs_u02_at_80p;
  r.fs_u02_at_90p := p_fs_u02_at_90p;
  r.fs_u02_at_95p := p_fs_u02_at_95p;
  r.db_name := UPPER(TRIM(p_db_name));
  r.dg_members := p_dg_members;
  r.pdbs := p_pdbs;
  r.kiev_pdbs := p_kiev_pdbs;
  r.wf_pdbs := p_wf_pdbs;
  r.casper_pdbs := p_casper_pdbs;
  --
  r.region := C##IOD.IOD_META_AUX.get_region(r.host_name);
  r.locale := C##IOD.IOD_META_AUX.get_locale(r.db_domain);
  r.locale_order_by := C##IOD.IOD_META_AUX.get_locale_order_by(r.db_domain);
  r.realm_type := C##IOD.IOD_META_AUX.get_realm_type(r.region);
  IF r.realm_type = 'C' THEN r.realm_type := 'Commercial'; ELSE r.realm_type := 'Government'; END IF;
  r.realm_type_order_by := C##IOD.IOD_META_AUX.get_realm_type_order_by(r.region);
  r.realm := C##IOD.IOD_META_AUX.get_realm(r.region);
  r.realm_order_by := C##IOD.IOD_META_AUX.get_realm_order_by(r.region);
  r.region_acronym := C##IOD.IOD_META_AUX.get_region_acronym(r.region);
  r.region_order_by := C##IOD.IOD_META_AUX.get_region_order_by(r.region);
  --
  IF p_kiev_pdbs > 0 THEN r.kiev_flag := 'Y'; ELSE r.kiev_flag := 'N'; END IF;
  IF p_wf_pdbs > 0 THEN r.wf_flag := 'Y'; ELSE r.wf_flag := 'N'; END IF;
  IF p_casper_pdbs > 0 THEN r.casper_flag := 'Y'; ELSE r.casper_flag := 'N'; END IF;
  --
  DELETE c##iod.cdb_attributes WHERE version = r.version AND host_name = r.host_name;
  INSERT INTO c##iod.cdb_attributes VALUES r;
  COMMIT;
END merge_cdb_attributes;
/
SHOW ERRORS;
