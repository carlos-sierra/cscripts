-- gc_status_setup.sql - Create gc_status Table and merge_gc_status Procedure
DECLARE
  l_exists NUMBER;
  l_sql_statement VARCHAR2(32767) := q'[
CREATE TABLE c##iod.gc_status (
  -- /* key: version, db_domain, db_name, pdb_name, gc_status */
  version                         DATE          NOT NULL
, db_domain                       VARCHAR2(64)  NOT NULL
, db_name                         VARCHAR2(9)   NOT NULL
, pdb_name                        VARCHAR2(30)  NOT NULL
, gc_status                       VARCHAR2(16)  NOT NULL
  -- oci domains
, host_name                       VARCHAR2(64)  NOT NULL
, realm_type                      VARCHAR2(1)   NOT NULL
, realm_type_order_by             NUMBER        NOT NULL
, realm                           VARCHAR2(4)   NOT NULL
, realm_order_by                  NUMBER        NOT NULL
, region                          VARCHAR2(64)  NOT NULL
, region_acronym                  VARCHAR2(4)   NOT NULL
, region_order_by                 NUMBER        NOT NULL
, locale                          VARCHAR2(4)   NOT NULL
, locale_order_by                 NUMBER        NOT NULL
  -- data attributes
, tables                          NUMBER        NOT NULL
, num_rows                        NUMBER        NOT NULL
, blocks                          NUMBER        NOT NULL
)
PARTITION BY RANGE (version)
INTERVAL (NUMTOYMINTERVAL(1, 'MONTH'))
(
PARTITION before_2016_01_01 VALUES LESS THAN (TO_DATE('2016-01-01', 'YYYY-MM-DD'))
)
ROW STORE COMPRESS ADVANCED
TABLESPACE IOD
]';
  l_sql_statement2 VARCHAR2(32767) := q'[
CREATE UNIQUE INDEX c##iod.gc_status_pk 
ON c##iod.gc_status 
(version, db_domain, db_name, pdb_name, gc_status) 
LOCAL
COMPRESS ADVANCED LOW
TABLESPACE IOD
]';
  l_sql_statement3 VARCHAR2(32767) := q'[
ALTER TABLE c##iod.gc_status ADD PRIMARY KEY 
(version, db_domain, db_name, pdb_name, gc_status) 
USING INDEX c##iod.gc_status_pk
]';
BEGIN
  SELECT COUNT(*) INTO l_exists FROM dba_tables WHERE owner = UPPER(TRIM('c##iod')) AND table_name = UPPER('gc_status');
  IF l_exists = 0 THEN
    EXECUTE IMMEDIATE l_sql_statement;
  END IF;
  SELECT COUNT(*) INTO l_exists FROM dba_indexes WHERE owner = UPPER(TRIM('c##iod')) AND index_name = UPPER('gc_status_pk');
  IF l_exists = 0 THEN
    EXECUTE IMMEDIATE l_sql_statement2;
    EXECUTE IMMEDIATE l_sql_statement3;
  END IF;
END;
/    

CREATE OR REPLACE 
PROCEDURE c##iod.merge_gc_status (
  p_version              IN VARCHAR2
, p_db_domain            IN VARCHAR2
, p_db_name              IN VARCHAR2
, p_pdb_name             IN VARCHAR2
, p_host_name            IN VARCHAR2
, p_gc_status            IN VARCHAR2
, p_tables               IN VARCHAR2
, p_num_rows             IN VARCHAR2
, p_blocks               IN VARCHAR2
)
IS
  r c##iod.gc_status%ROWTYPE;
BEGIN
  IF p_num_rows IS NOT NULL AND p_blocks IS NOT NULL THEN
    r.version := TO_DATE(p_version, 'YYYY-MM-DD');
    r.db_domain := LOWER(p_db_domain);
    r.db_name := UPPER(p_db_name);
    r.pdb_name := p_pdb_name;
    r.host_name := p_host_name;
    r.realm_type := c##iod.IOD_META_AUX.get_realm_type(c##iod.IOD_META_AUX.get_region(p_host_name));
    r.realm_type_order_by := c##iod.IOD_META_AUX.get_realm_type_order_by(c##iod.IOD_META_AUX.get_region(p_host_name));
    r.realm := c##iod.IOD_META_AUX.get_realm(c##iod.IOD_META_AUX.get_region(p_host_name));
    r.realm_order_by := c##iod.IOD_META_AUX.get_realm_order_by(c##iod.IOD_META_AUX.get_region(p_host_name));
    r.region := c##iod.IOD_META_AUX.get_region(p_host_name);
    r.region_acronym := c##iod.IOD_META_AUX.get_region_acronym(c##iod.IOD_META_AUX.get_region(p_host_name));
    r.region_order_by := c##iod.IOD_META_AUX.get_region_order_by(c##iod.IOD_META_AUX.get_region(p_host_name));
    r.locale := c##iod.IOD_META_AUX.get_locale(LOWER(p_db_domain));
    r.locale_order_by := c##iod.IOD_META_AUX.get_locale_order_by(LOWER(p_db_domain));
    r.gc_status := p_gc_status;
    r.tables := p_tables;
    r.num_rows := p_num_rows;
    r.blocks := p_blocks;
    --
    DELETE c##iod.gc_status WHERE version = r.version AND db_domain = r.db_domain AND db_name = r.db_name AND pdb_name = r.pdb_name AND gc_status = r.gc_status;
    INSERT INTO c##iod.gc_status VALUES r;
    COMMIT;
  END IF;
END merge_gc_status;
/
SHOW ERRORS;

/************************************************************************************************/

-- gc_status_setup.sql - Create gc_status Table and merge_gc_status Procedure
DECLARE
  l_exists NUMBER;
  l_sql_statement VARCHAR2(32767) := q'[
CREATE TABLE c##iod.gc_gt_20k (
  -- /* key: version, db_domain, db_name, pdb_name, owner, table_name */
  version                         DATE          NOT NULL
, db_domain                       VARCHAR2(64)  NOT NULL
, db_name                         VARCHAR2(9)   NOT NULL
, pdb_name                        VARCHAR2(30)  NOT NULL
, owner                           VARCHAR2(128) NOT NULL
, table_name                      VARCHAR2(128) NOT NULL
  -- oci domains
, host_name                       VARCHAR2(64)  NOT NULL
, realm_type                      VARCHAR2(1)   NOT NULL
, realm_type_order_by             NUMBER        NOT NULL
, realm                           VARCHAR2(4)   NOT NULL
, realm_order_by                  NUMBER        NOT NULL
, region                          VARCHAR2(64)  NOT NULL
, region_acronym                  VARCHAR2(4)   NOT NULL
, region_order_by                 NUMBER        NOT NULL
, locale                          VARCHAR2(4)   NOT NULL
, locale_order_by                 NUMBER        NOT NULL
  -- data attributes
, gc_status                       VARCHAR2(16)  NOT NULL
, num_rows                        NUMBER        NOT NULL
, blocks                          NUMBER        NOT NULL
)
PARTITION BY RANGE (version)
INTERVAL (NUMTOYMINTERVAL(1, 'MONTH'))
(
PARTITION before_2016_01_01 VALUES LESS THAN (TO_DATE('2016-01-01', 'YYYY-MM-DD'))
)
ROW STORE COMPRESS ADVANCED
TABLESPACE IOD
]';
  l_sql_statement2 VARCHAR2(32767) := q'[
CREATE UNIQUE INDEX c##iod.gc_gt_20k_pk 
ON c##iod.gc_gt_20k 
(version, db_domain, db_name, pdb_name, owner, table_name) 
LOCAL
COMPRESS ADVANCED LOW
TABLESPACE IOD
]';
  l_sql_statement3 VARCHAR2(32767) := q'[
ALTER TABLE c##iod.gc_gt_20k ADD PRIMARY KEY 
(version, db_domain, db_name, pdb_name, owner, table_name) 
USING INDEX c##iod.gc_gt_20k_pk
]';
BEGIN
  SELECT COUNT(*) INTO l_exists FROM dba_tables WHERE owner = UPPER(TRIM('c##iod')) AND table_name = UPPER('gc_gt_20k');
  IF l_exists = 0 THEN
    EXECUTE IMMEDIATE l_sql_statement;
  END IF;
  SELECT COUNT(*) INTO l_exists FROM dba_indexes WHERE owner = UPPER(TRIM('c##iod')) AND index_name = UPPER('gc_gt_20k_pk');
  IF l_exists = 0 THEN
    EXECUTE IMMEDIATE l_sql_statement2;
    EXECUTE IMMEDIATE l_sql_statement3;
  END IF;
END;
/    

CREATE OR REPLACE 
PROCEDURE c##iod.merge_gt_20k (
  p_version              IN VARCHAR2
, p_db_domain            IN VARCHAR2
, p_db_name              IN VARCHAR2
, p_pdb_name             IN VARCHAR2
, p_host_name            IN VARCHAR2
, p_gc_status            IN VARCHAR2
, p_owner                IN VARCHAR2
, p_table_name           IN VARCHAR2
, p_num_rows             IN VARCHAR2
, p_blocks               IN VARCHAR2
)
IS
  r c##iod.gc_gt_20k%ROWTYPE;
BEGIN
  IF p_num_rows IS NOT NULL AND p_blocks IS NOT NULL THEN
    r.version := TO_DATE(p_version, 'YYYY-MM-DD');
    r.db_domain := LOWER(p_db_domain);
    r.db_name := UPPER(p_db_name);
    r.pdb_name := p_pdb_name;
    r.host_name := p_host_name;
    r.realm_type := c##iod.IOD_META_AUX.get_realm_type(c##iod.IOD_META_AUX.get_region(p_host_name));
    r.realm_type_order_by := c##iod.IOD_META_AUX.get_realm_type_order_by(c##iod.IOD_META_AUX.get_region(p_host_name));
    r.realm := c##iod.IOD_META_AUX.get_realm(c##iod.IOD_META_AUX.get_region(p_host_name));
    r.realm_order_by := c##iod.IOD_META_AUX.get_realm_order_by(c##iod.IOD_META_AUX.get_region(p_host_name));
    r.region := c##iod.IOD_META_AUX.get_region(p_host_name);
    r.region_acronym := c##iod.IOD_META_AUX.get_region_acronym(c##iod.IOD_META_AUX.get_region(p_host_name));
    r.region_order_by := c##iod.IOD_META_AUX.get_region_order_by(c##iod.IOD_META_AUX.get_region(p_host_name));
    r.locale := c##iod.IOD_META_AUX.get_locale(LOWER(p_db_domain));
    r.locale_order_by := c##iod.IOD_META_AUX.get_locale_order_by(LOWER(p_db_domain));
    r.gc_status := p_gc_status;
    r.owner := p_owner;
    r.table_name := p_table_name;
    r.num_rows := p_num_rows;
    r.blocks := p_blocks;
    --
    DELETE c##iod.gc_gt_20k WHERE version = r.version AND db_domain = r.db_domain AND db_name = r.db_name AND pdb_name = r.pdb_name AND owner = r.owner AND table_name = r.table_name;
    INSERT INTO c##iod.gc_gt_20k VALUES r;
    COMMIT;
  END IF;
END merge_gt_20k;
/
SHOW ERRORS;
