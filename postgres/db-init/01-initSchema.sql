
-- Crea la BD con UTF-8 y ordenación catalana/valenciana
CREATE DATABASE obraAgil
  ENCODING 'UTF8';           -- Codificación multilingüe


-- Cambia la conexión para usar la nueva BD
--\c obraAgil

/*=============================================================
=  1.  TABLAS DE USUARIOS Y SEGURIDAD                        =
=============================================================*/
-- Enum para el tipo de usuario
/*
CREATE TYPE usuari_tipus AS ENUM ('TREBALLADOR', 'EMPRESA');
    
CREATE TABLE usuari (
    id         SERIAL PRIMARY KEY,
    tipus      usuari_tipus NOT NULL,        -- 'PERSONA' o 'EMPRESA'
    telefon    BIGINT        NULL,
    data_creacio TIMESTAMP   NOT NULL
);
-- Només per empreses
CREATE TABLE u_empresa (
    id            INTEGER PRIMARY KEY,             -- FK → usuari.id
    nom           VARCHAR(120) NOT NULL,           -- Nom comercial
    correu        VARCHAR(160) NOT NULL,
    CONSTRAINT fk_empresa_usuari
        FOREIGN KEY (id) REFERENCES usuari(id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Només per persones
CREATE TABLE u_persona (
    id       INTEGER PRIMARY KEY,                  -- FK → usuari.id
    nickname VARCHAR(120) NOT NULL,
    empresa  INTEGER,
    nom      VARCHAR(120) NOT NULL,
    cognoms  VARCHAR(160) NOT NULL,
    rol      VARCHAR(60)  NOT NULL,
    estat    VARCHAR(40)   NOT NULL,
    CONSTRAINT fk_persona_usuari
        FOREIGN KEY (empresa) REFERENCES u_empresa(id),
        FOREIGN KEY (id) REFERENCES usuari(id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

*/
CREATE TABLE usuari (
    id SERIAL PRIMARY KEY,
    username VARCHAR(150),
    password VARCHAR(128) NOT NULL,
    email VARCHAR(254),
    first_name VARCHAR(150),
    last_name VARCHAR(150),

    tipus VARCHAR(20) CHECK (tipus IN ('treballador', 'empresa')),
    login_field VARCHAR(150) UNIQUE NOT NULL,

    is_active BOOLEAN DEFAULT TRUE,
    is_staff BOOLEAN DEFAULT FALSE,
    is_superuser BOOLEAN DEFAULT FALSE,

    date_joined TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL
);


CREATE TABLE ubicacio (
    id_ubicacio  SERIAL PRIMARY KEY,
    adreça VARCHAR(150),
    ciutat VARCHAR(50),
    codi_postal VARCHAR(10),
    provincia VARCHAR(50),
    país VARCHAR(50) DEFAULT 'Espanya', 
    latitud DECIMAL(10,7),
    longitud DECIMAL(11,7)
);

CREATE TABLE treballador (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(50) NOT NULL,
    cognoms VARCHAR(100) NOT NULL,
    nickname VARCHAR(100),
    dni_nie_passaport VARCHAR(20) UNIQUE NOT NULL,
    data_naixement DATE,
    telefon VARCHAR(20),
    email VARCHAR(100),
    foto VARCHAR(255),
    comentaris TEXT,
    user_id INTEGER NOT NULL UNIQUE,

    CONSTRAINT fk_treballador_user
        FOREIGN KEY (user_id) REFERENCES usuari(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);


CREATE TYPE estat_empresa AS ENUM ('activa', 'inactiva', 'suspesa');

CREATE TABLE empresa (
    id_empresa SERIAL PRIMARY KEY,
    nom_empresa VARCHAR(100) NOT NULL,
    cif VARCHAR(20) UNIQUE NOT NULL,
    ubicacio_id INTEGER,
    telefon VARCHAR(20),
    email VARCHAR(100),
    web VARCHAR(100),
    sector VARCHAR(50),
    data_alta DATE DEFAULT CURRENT_DATE,
    estat estat_empresa DEFAULT 'activa',
    persona_contacte VARCHAR(100),
    comentaris TEXT,
    user_id INTEGER NOT NULL UNIQUE,

    CONSTRAINT fk_empresa_ubicacio
        FOREIGN KEY (ubicacio_id) REFERENCES ubicacio(id_ubicacio)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    CONSTRAINT fk_empresa_user
        FOREIGN KEY (user_id) REFERENCES usuari(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);


-- 1. Enum per tipus de contracte
CREATE TYPE estat_treballador_enum AS ENUM ('actiu', 'baixa', 'acomiadat');

-- 3. Taula contracte_treballador
CREATE TABLE contracte_treballador (
    id SERIAL PRIMARY KEY, -- clau surrogate

    id_treballador INTEGER NOT NULL,
    id_empresa INTEGER NOT NULL,

    data_contracte DATE NULL,
    data_fi DATE NULL,

    salari NUMERIC(10,2) NULL,

    carrec VARCHAR(50) NULL,
    categoria_professional VARCHAR(50) NULL,
    nss VARCHAR(20) NULL,
    formacions TEXT NULL,

    estat estat_treballador_enum NOT NULL DEFAULT 'actiu',

    CONSTRAINT fk_ct_treballador FOREIGN KEY (id_treballador)
        REFERENCES treballador(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_ct_empresa FOREIGN KEY (id_empresa)
        REFERENCES empresa(id_empresa)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT uq_treballador_data UNIQUE (id_treballador, data_contracte)
);
-- 1E. Tabla de contraseñas históricas
CREATE TABLE contrasenya (
    id            SERIAL PRIMARY KEY,                       -- PK autoincremental
    id_treballador INTEGER  NULL,                     -- FK → TREBALLADOR
    id_empresa    INTEGER  NULL,                                          -- FK → usuari.id
    clau          VARCHAR(255) NOT NULL,                    -- Hash de la contraseña
    data_creacio  TIMESTAMP    NOT NULL,                    -- Fecha de alta
    data_reemplas TIMESTAMP    NULL,  
                          -- Fecha de sustitución
    CONSTRAINT fk_pwd_empresa
        FOREIGN KEY (id_empresa) REFERENCES empresa(id_empresa)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_pwd_treb
        FOREIGN KEY (id_treballador) REFERENCES treballador(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
        -- Assegura wu un dels camps de usuaris es buit i l'altre no
    -- d'aquesta manera en assegurem que la contrasenyaes de un i tan sols un usuari
    CONSTRAINT chk_un_fk
        CHECK (
            (id_treballador IS NOT NULL AND id_empresa IS NULL)
            OR
            (id_treballador IS NULL AND id_empresa IS NOT NULL)
        )
);

-- Índex per localitzar ràpidament la contrasenya vigent (no reemplaçada) a partir de la data de reemplaçament
CREATE INDEX idx_pwd_e_vigent ON contrasenya (id_empresa)
WHERE data_reemplas IS NULL;

CREATE INDEX idx_pwd_t_vigent ON contrasenya (id_treballador)
WHERE data_reemplas IS NULL;

-- 1F. Tabla de permisos globales
CREATE TABLE permis (
    id              SERIAL PRIMARY KEY,       -- Identificador del permiso
    clau_funcional  VARCHAR(100) UNIQUE NOT NULL, -- Clave de negocio
    descripcio      VARCHAR(255) NOT NULL     -- Descripción legible
);

-- 1G. Permisos asignados a cada usuario
CREATE TABLE permis_treballador (
    id           SERIAL PRIMARY KEY,      -- Clave surrogate
    id_treballador    INTEGER NOT NULL,        -- FK → usuari.id
    id_permis    INTEGER NOT NULL,        -- FK → permis.id
    lectura      BOOLEAN NOT NULL DEFAULT FALSE, -- Derecho de lectura
    escriptura   BOOLEAN NOT NULL DEFAULT FALSE, -- Derecho de escritura
    edicio       BOOLEAN NOT NULL DEFAULT FALSE, -- Derecho de edición
    data_creacio TIMESTAMP NOT NULL,      -- Fecha de alta
    data_modif   TIMESTAMP NULL,          -- Última modificación
    CONSTRAINT fk_pu_user
        FOREIGN KEY (id_treballador) REFERENCES treballador(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_pu_permis
        FOREIGN KEY (id_permis) REFERENCES permis(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,  --Els permisos no han de ser bons de borrar si ghi ha logica de l'app que depen d'aixo.
    -- Valida que los booleanos solo sean 0/1
    CONSTRAINT chk_pu_boolean
        CHECK (lectura IN (FALSE, TRUE)
           AND escriptura IN (FALSE, TRUE)
           AND edicio IN (FALSE, TRUE))
);
-- Índices para acelerar filtros por usuario y permiso
CREATE INDEX idx_pu_user   ON permis_treballador (id_treballador);
CREATE INDEX idx_pu_permis ON permis_treballador (id_permis);

-- 1H. Historial de sesiones de empresas

CREATE TABLE log_de_sessio (
    id             SERIAL PRIMARY KEY,
    id_treballador INTEGER NULL,
    id_empresa     INTEGER NULL,
    data_inici     DATE NOT NULL,
    hora_inici     TIME NOT NULL,

    CONSTRAINT fk_log_treballador
        FOREIGN KEY (id_treballador) REFERENCES treballador(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_log_empresa
        FOREIGN KEY (id_empresa) REFERENCES empresa(id_empresa)
        ON DELETE SET NULL ON UPDATE CASCADE,

    -- EXACTAMENT un dels dos: o és sessió de treballador o és sessió d’empresa
    CONSTRAINT chk_log_subjecte
        CHECK ( (id_treballador IS NOT NULL) <> (id_empresa IS NOT NULL) )
);

-- Índexos útils per consultes habituals
CREATE INDEX idx_log_treballador ON log_de_sessio (id_treballador);
CREATE INDEX idx_log_empresa     ON log_de_sessio (id_empresa);

-- 1I. Preferencias/configuración (1-a-1)
CREATE TABLE configuracio (
    id       SERIAL PRIMARY KEY,         
    id_empresa  INTEGER NULL,
    id_treballador INTEGER NULL,
    idioma           VARCHAR(10)  DEFAULT 'ca',   -- Idioma por defecto
    acceptacio_terms BOOLEAN      NOT NULL DEFAULT FALSE, -- Acepta T&C
    imatge_perfil    VARCHAR(255) NULL,           -- URL de avatar
    CONSTRAINT fk_cfg_user
        FOREIGN KEY (id_treballador) REFERENCES treballador(id)
        ON DELETE CASCADE ON UPDATE CASCADE,  
    
    CONSTRAINT fk_cfg_empresa
        FOREIGN KEY (id_empresa) REFERENCES empresa(id_empresa)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT chk_cfg_subjecte
        CHECK ( (id_treballador IS NOT NULL) <> (id_empresa IS NOT NULL) )
);

CREATE UNIQUE INDEX ux_cfg_treballador_one
  ON configuracio (id_treballador)
  WHERE id_treballador IS NOT NULL;

CREATE UNIQUE INDEX ux_cfg_empresa_one
  ON configuracio (id_empresa)
  WHERE id_empresa IS NOT NULL;


-- 1J. Tabla de verificaciones de cuenta d'empreses
CREATE TABLE verificacio (
    id                SERIAL PRIMARY KEY,        -- PK autoincremental
    id_empresa        INTEGER NOT NULL,          -- FK → usuari.id
    estat_ver         VARCHAR(40) NOT NULL,      -- Estado (pendiente, ok…)
    data_ver          DATE        NULL,          -- Fecha de verificación
    token_verificacio VARCHAR(120) NOT NULL,     -- Token único
    data_token        TIMESTAMP    NOT NULL,     -- Fecha de emisión
    CONSTRAINT fk_ver_user
        FOREIGN KEY (id_empresa) REFERENCES empresa(id_empresa)
        ON DELETE CASCADE ON UPDATE CASCADE
);
-- Índice para verificar por usuario
CREATE INDEX idx_ver_user ON verificacio(id_empresa);

/*=============================================================
=  2.  ENTIDADES DE OBRA                                      =
=============================================================*/
-- 2A. Obras o proyectos de construcción
CREATE TABLE obra (
    id            SERIAL PRIMARY KEY,           -- PK autoincremental
    nom           VARCHAR(100) NOT NULL,        -- Nombre comercial
    ubicacio_id   INTEGER NOT NULL,        -- Dirección o coordenadas
    data_inici    DATE         NOT NULL,        -- Inicio real
    data_prev_fi  DATE         NOT NULL,        -- Fin previsto
    data_fi       DATE         NULL,            -- Fin real (si existe)
    descripcio    TEXT         NULL,            -- Descripción larga
    pressupost    BIGINT       NOT NULL,        -- Presupuesto (€)
    estat         VARCHAR(50)  NOT NULL,         -- Estado (en curso, etc.)
    CONSTRAINT fk_uni_obra
        FOREIGN KEY (ubicacio_id) REFERENCES ubicacio(id_ubicacio)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE obra_empresa(
    id serial primary key,
    id_empresa INTEGER NOT NULL,
    id_obra INTEGER NOT NULL,
    data_i  TIMESTAMP NOT NULL,
    data_f TIMESTAMP NULL,
    
    CONSTRAINT fk_obra
        FOREIGN KEY (id_obra) REFERENCES obra(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    
    CONSTRAINT fk_empresa 
        FOREIGN KEY (id_empresa) REFERENCES empresa(id_empresa)
        ON DELETE CASCADE ON UPDATE CASCADE
);
-- 2B. Responsables de obra (N-a-N débil)
CREATE TABLE responsable_obra (
    id             SERIAL PRIMARY  KEY,
    id_obra        INTEGER NOT NULL,          -- FK → obra.id
    id_treballador INTEGER NOT NULL,          -- FK → u_persona.id
    data_inici     DATE NOT NULL,             -- Desde
    data_fi        DATE NULL,                 -- Hasta
    --la clau anterior era una clau en combinacio de data, idobre i idtreballador. 
    --Es mes net tenir un id com a primary jey i tenir foreign keys referenciant les taules
    CONSTRAINT fk_ro_obra
        FOREIGN KEY (id_obra) REFERENCES obra(id)
        ON DELETE NO ACTION ON UPDATE CASCADE,

    CONSTRAINT fk_ro_treballador
        FOREIGN KEY (id_treballador) REFERENCES treballador(id)
        ON DELETE NO ACTION ON UPDATE CASCADE
);  

-- 2C. Documentos asociados a la obra

-- **********COM AFEGIR ARXIUS A AQUESTA TAULA**********

-- La taula guarda només les dades (nom, tipus, descripció, ruta, etc.), però no 
-- el fitxer real dins la base de dades. Si vols que un document real (PDF, Word,
-- imatge…) estigui vinculat i accessible des d’una app, el que normalment es fa 
--és guardar el document en un sistema d’arxius (filesystem) o en un sistema 
-- d’emmagatzematge (com Amazon S3, Google Cloud Storage, o una carpeta del servidor)
--, i la taula SQL guarda només la “ruta” o “URL” al fitxer.
--
CREATE TABLE document_obra (
    id           SERIAL PRIMARY KEY,        -- PK autoincremental
    id_obra      INTEGER NOT NULL,          -- FK → obra.id
    id_creador   INTEGER NOT NULL,          -- Usuario o no usuario que sube el doc
    path_doc     TEXT NOT NULL,                 -- Ruta + nom fins al fitxer dins el servidor Back End.
    format       VARCHAR(40)  NOT NULL,     -- PDF, DWG, etc.
    mida         NUMERIC(6,2)      NOT NULL,     -- Tamaño (MB)
    comentari    TEXT         NULL,         -- Comentario opcional
    data_pujada  TIMESTAMP    NOT NULL,     -- Fecha de subida
    tipus        VARCHAR(40)  NOT NULL,     -- Plano, informe…
    CONSTRAINT fk_doc_obra
        FOREIGN KEY (id_obra) REFERENCES obra(id)
        ON DELETE NO ACTION ON UPDATE CASCADE
);
-- Índice para listar docs por obra
CREATE INDEX idx_doc_obra ON document_obra (id_obra);

/*=============================================================
=  3.  TAREAS, INCIDENTES Y SOLUCIONES                        =
=============================================================*/
-- 3A. Tareas de la obra (estructura jerárquica opcional)
CREATE TABLE tasca (
    id                SERIAL PRIMARY KEY,         -- PK autoincremental
    id_obra           INTEGER NOT NULL,           -- FK → obra.id
    id_tasca_pare     INTEGER NULL,               -- FK autorreferente
    descripcio        TEXT    NOT NULL,           -- Texto libre
    data_inici        DATE    NOT NULL,           -- Inicio previsto
    data_fi           DATE    NULL,               -- Fin real
    prioritat         INTEGER NOT NULL,           -- 1-5
    visibilitat_tasca BOOLEAN NOT NULL DEFAULT TRUE, -- Visible al cliente
    CONSTRAINT fk_tasca_obra
        FOREIGN KEY (id_obra) REFERENCES obra(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_tasca_pare
        FOREIGN KEY (id_tasca_pare) REFERENCES tasca(id)
        ON DELETE SET NULL ON UPDATE CASCADE
);

-- 3B. Relación tarea-trabajador (N-a-N)
CREATE TABLE tasca_treballador (
    id              SERIAL PRIMARY KEY,  
    id_tasca       INTEGER NOT NULL,      -- FK → tasca.id
    id_treballador INTEGER NOT NULL,      -- FK → u_persona.id
    comentari      TEXT NULL,            -- Comentario extra

    CONSTRAINT uq_tasca_treballador
        UNIQUE (id_tasca, id_treballador),
        
    CONSTRAINT fk_tt_tasca
        FOREIGN KEY (id_tasca) REFERENCES tasca(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_tt_treballador
        FOREIGN KEY (id_treballador) REFERENCES treballador(id)
        ON DELETE NO ACTION ON UPDATE CASCADE
);

-- 3C. Incidencias
-- nO S'HA AFEGIT L'INICIDENCIA EN CASCADA, PERÒ ES PODRIA FER
CREATE TABLE incidencia (
    id           SERIAL PRIMARY KEY,        -- PK autoincremental
    id_obra      INTEGER NOT NULL,          -- FK → obra.id
    id_tasca     INTEGER NULL,              -- FK opcional → tasca.id
    descripcio   TEXT    NOT NULL,          -- Descripción
    data_inici   DATE    NOT NULL,          -- Inicio
    data_fi      DATE    NULL,              -- Fin
    criticitat   INTEGER NOT NULL,          -- 1-5
    prioritat    INTEGER NOT NULL,          -- 1-5
    categoria    INTEGER NOT NULL,          -- Enumeración libre
    estat        VARCHAR(40) NOT NULL,      -- Abierta, cerrada…
    CONSTRAINT fk_inc_obra
        FOREIGN KEY (id_obra) REFERENCES obra(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_inc_tasca
        FOREIGN KEY (id_tasca) REFERENCES tasca(id)
        ON DELETE SET NULL ON UPDATE CASCADE
);
-- Índices para búsquedas rápidas
CREATE INDEX idx_inc_obra  ON incidencia (id_obra);
CREATE INDEX idx_inc_tasca ON incidencia (id_tasca);

-- 3D. Soluciones asociadas a incidencias
CREATE TABLE solucio (
    id            SERIAL PRIMARY KEY,       -- PK autoincremental
    id_incidencia INTEGER NOT NULL,         -- FK → incidencia.id
    id_tasca      INTEGER NULL,             -- FK opcional → tasca.id: rEPRESENTA LES TASQUES QUE HAN DE FER-SE EFECTUAR LA SOLUCIÓ
    descripcio    TEXT     NOT NULL,        -- Descripción
    cost_monetari BIGINT   NOT NULL,        -- € de la solución
    eficacia      INTEGER  NOT NULL CHECK (eficacia BETWEEN 0 AND 5),        -- 1-5
    cost_temporal INTEGER  NOT NULL,        -- Horas empleadas
    impacte       INTEGER  NOT NULL,    -- 1-10 (bajo-alto)
    CONSTRAINT fk_sol_inc
        FOREIGN KEY (id_incidencia) REFERENCES incidencia(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_sol_tasca
        FOREIGN KEY (id_tasca) REFERENCES tasca(id)
        ON DELETE NO ACTION ON UPDATE CASCADE
);

/*=============================================================
=  4.  RECURSOS Y SOLICITUDES                                 =
=============================================================*/
-- 4A. Recursos inventariados
CREATE TABLE recurs (
    id             SERIAL PRIMARY KEY,      -- PK autoincremental
    nom            VARCHAR(120) NOT NULL,   -- Nombre genérico
    unitats_mesura VARCHAR(40)  NOT NULL,   -- Unidades (kg, m3…)
    quantitat_stock NUMERIC(8,2) NOT NULL,       -- Cantidad en almacén
    tipus_recurs   VARCHAR(60) NOT NULL     -- Material, equipo…
);

-- 4B. Solicitudes de recurso por obra
CREATE TABLE sol_recurs (
    id               SERIAL PRIMARY KEY,   -- PK autoincremental
    id_obra          INTEGER NOT NULL,     -- FK → obra.id
    id_recurs        INTEGER NOT NULL,     -- FK → recurs.id
    quantitat        INTEGER NOT NULL,     -- Cantidad solicitada
    data_necessitat  DATE    NOT NULL,     -- Fecha requerida
    comentari        TEXT    NULL,         -- Justificación
    data_entrega     DATE    NULL,         -- Entregado el…
    data_creacio     TIMESTAMP NOT NULL,   -- Creado el…
    proveidor        VARCHAR(120) NULL,    -- Proveedor asignado
    CONSTRAINT fk_sr_obra
        FOREIGN KEY (id_obra) REFERENCES obra(id)
        ON DELETE NO ACTION ON UPDATE CASCADE,
    CONSTRAINT fk_sr_recurs
        FOREIGN KEY (id_recurs) REFERENCES recurs(id)
        ON DELETE NO ACTION ON UPDATE CASCADE  --Restric perque vul que quedi constancia de les solicituds de cada material.
);
-- Índices para filtros habituales
CREATE INDEX idx_sr_obra   ON sol_recurs (id_obra);
CREATE INDEX idx_sr_recurs ON sol_recurs (id_recurs);

/*=============================================================
=  5.  VISTAS / ÍNDICES COMPLEMENTARIOS (opcionales)          =
=============================================================*/
-- 5A. Vista de incidencias abiertas por obra
CREATE OR REPLACE VIEW vw_incidencies_obertes AS
SELECT i.*, o.nom AS obra
FROM incidencia i
JOIN obra o ON o.id = i.id_obra
WHERE i.estat <> 'TANCADA';
 
