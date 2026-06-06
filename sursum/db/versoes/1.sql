PRAGMA foreign_keys = off;
BEGIN TRANSACTION;

-- Table: meta_cp_relacs
DROP TABLE IF EXISTS meta_cp_relacs;

CREATE TABLE meta_cp_relacs (
    id               INTEGER      PRIMARY KEY AUTOINCREMENT,
    meta_tb_relac_id              REFERENCES meta_tb_relacs (id) ON DELETE CASCADE
                                                                 ON UPDATE CASCADE,
    cod_cp_01        VARCHAR (50),
    cod_cp_02        VARCHAR (50),
    dt_hr_registro   DATETIME
);


-- Table: meta_tb_relacs
DROP TABLE IF EXISTS meta_tb_relacs;

CREATE TABLE meta_tb_relacs (
    id                   INTEGER       PRIMARY KEY AUTOINCREMENT,
    num_tipo_relac_tb_01 INTEGER (2),
    num_tipo_relac_tb_02 INTEGER (2),
    cod_tb_01            VARCHAR (50),
    cod_tb_02            VARCHAR (50),
    log_of               BOOLEAN,
    cps_of               VARCHAR (300),
    dt_hr_registro       DATETIME      NOT NULL,
    log_manual           BOOLEAN
);


COMMIT TRANSACTION;
PRAGMA foreign_keys = on;
