/*=============================================================
=  0.  PREPARACIÓN                                           =
=============================================================*/
/*Diferencias principales entre el código SQL y el diagrama:
1. Estructura de herencia de usuarios
Diagrama: Muestra una herencia simple con USUARI como clase base y U_TREBALLADOR y U_EMPRESA como subclases.
Código SQL: Implementa correctamente la herencia usando:

Tabla base usuari con campo tipus (ENUM)
Tablas especializadas u_treballador y u_empresa con FK hacia usuari.id

✅ Coincide con el diagrama.
2. Tabla CONTRASENYA
Diagrama: Muestra CONTRASENYA relacionada con USUARI.
Código SQL: Implementa correctamente con:

Relación 1:N entre usuari y contrasenya
Campo vigent para contraseña activa
Historial de contraseñas

✅ Coincide con el diagrama.
3. Gestión de permisos
Diagrama: Muestra PERMIS y Permis x Usuari (tabla de unión).
Código SQL: Implementa con:

Tabla permis con permisos globales
Tabla permis_usuari con campos adicionales (lectura, escriptura, edicio)

⚠️ Diferencia: El código añade granularidad de permisos no especificada en el diagrama.
4. Tabla LOG DE SESSIO
Diagrama: Relacionada con USUARI.
Código SQL:
sqlFOREIGN KEY (id_usuari) REFERENCES u_empresa(id)
❌ ERROR: El código relaciona log_de_sessio solo con u_empresa, pero el diagrama la relaciona con USUARI (debería permitir tanto trabajadores como empresas).
5. Campos de fecha/tiempo
Diagrama: Muestra campos como Data_creacio, Data_entrega, etc.
Código SQL: Implementa con:

Algunos campos como TIMESTAMP (ej: data_creacio)
Otros como DATE (ej: data_entrega)

⚠️ Inconsistencia: El diagrama no especifica el tipo exacto de fecha, pero el código mezcla DATE y TIMESTAMP.
6. Campo Data_darrera_sessio
Código SQL: Incluye el comentario:
sqldata_darrera_sessio  TIMESTAMP NULL, -- Último login *************NO ADECUAT PERQUE NECESITAR D'ACTUALITZACIO
❌ Problema de diseño: El desarrollador reconoce que este campo requiere actualizaciones constantes, lo cual no es eficiente.
7. Tabla CONFIGURACIO
Diagrama: Muestra relación 1:1 con USUARI.
Código SQL: Implementa correctamente con:

id_usuari como PK y FK
Campos adicionales como idioma, acceptacio_terms

✅ Coincide parcialmente, pero el código añade campos no mostrados en el diagrama.
8. Relaciones N:M
Diagrama: Muestra varias relaciones muchos a muchos.
Código SQL: Implementa correctamente con tablas de unión:

responsable_obra (obra-trabajador)
tasca_treballador (tarea-trabajador)
permis_usuari (usuario-permiso)

✅ Coincide con el diagrama.
9. Campos no representados en el diagrama
El código SQL incluye varios campos que no aparecen en el diagrama:

mida en document_obra
format en document_obra
cost_temporal en solucio
impacte en solucio

Conclusiones:

El principal error está en la tabla log_de_sessio que debería referenciar usuari.id en lugar de u_empresa.id.
El código es más detallado que el diagrama, añadiendo campos y funcionalidades no especificadas.
La estructura general sigue correctamente el diseño del diagrama, especialmente en las relaciones principales.
Faltan optimizaciones como la gestión adecuada del campo data_darrera_sessio que el propio código marca como problemático.
*/
-- Elimina la BD si ya existe (debes estar conectado a otra BD, p. ej. postgres)
--DROP DATABASE IF EXISTS obraAgil;

-- Crea la BD con UTF-8 y ordenación catalana/valenciana
CREATE DATABASE obraAgil
  ENCODING 'UTF8';           -- Codificación multilingüe


-- Cambia la conexión para usar la nueva BD
--\c obraAgil

/*=============================================================
=  1.  TABLAS DE USUARIOS Y SEGURIDAD                        =
=============================================================*/
-- Enum para el tipo de usuario
CREATE TYPE usuari_tipus AS ENUM ('TREBALLADOR', 'EMPRESA');
    
CREATE TABLE usuari (
    id         SERIAL PRIMARY KEY,
    tipus      usuari_tipus NOT NULL,        -- 'PERSONA' o 'EMPRESA'
    telefon    BIGINT        NULL,
    data_creacio TIMESTAMP   NOT NULL
);

-- Només per persones
CREATE TABLE u_persona (
    id       INTEGER PRIMARY KEY,                  -- FK → usuari.id
    nickname VARCHAR(120) NOT NULL,
    nom      VARCHAR(120) NOT NULL,
    cognoms  VARCHAR(160) NOT NULL,
    rol      VARCHAR(60)  NOT NULL,
    estat    VARCHAR(40)   NOT NULL,
    CONSTRAINT fk_persona_usuari
        FOREIGN KEY (id) REFERENCES usuari(id)
        ON DELETE CASCADE ON UPDATE CASCADE
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


-- 1E. Tabla de contraseñas históricas
CREATE TABLE contrasenya (
    id            SERIAL PRIMARY KEY,                       -- PK autoincremental
    id_usuari     INTEGER     NOT NULL,                     -- FK → usuari.id
    clau          VARCHAR(255) NOT NULL,                    -- Hash de la contraseña
    data_creacio  TIMESTAMP    NOT NULL,                    -- Fecha de alta
    data_reemplas TIMESTAMP    NULL,                        -- Fecha de sustitución
    CONSTRAINT fk_pwd_user
        FOREIGN KEY (id_usuari) REFERENCES usuari(id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Índex per localitzar ràpidament la contrasenya vigent (no reemplaçada) a partir de la data de reemplaçament
CREATE INDEX idx_pwd_vigent ON contrasenya (id_usuari)
WHERE data_reemplas IS NULL;


-- 1F. Tabla de permisos globales
CREATE TABLE permis (
    id              SERIAL PRIMARY KEY,       -- Identificador del permiso
    clau_funcional  VARCHAR(100) UNIQUE NOT NULL, -- Clave de negocio
    descripcio      VARCHAR(255) NOT NULL     -- Descripción legible
);

-- 1G. Permisos asignados a cada usuario
CREATE TABLE permis_usuari (
    id           SERIAL PRIMARY KEY,      -- Clave surrogate
    id_usuari    INTEGER NOT NULL,        -- FK → usuari.id
    id_permis    INTEGER NOT NULL,        -- FK → permis.id
    lectura      BOOLEAN NOT NULL DEFAULT FALSE, -- Derecho de lectura
    escriptura   BOOLEAN NOT NULL DEFAULT FALSE, -- Derecho de escritura
    edicio       BOOLEAN NOT NULL DEFAULT FALSE, -- Derecho de edición
    data_creacio TIMESTAMP NOT NULL,      -- Fecha de alta
    data_modif   TIMESTAMP NULL,          -- Última modificación
    CONSTRAINT fk_pu_user
        FOREIGN KEY (id_usuari) REFERENCES u_persona(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_pu_permis
        FOREIGN KEY (id_permis) REFERENCES permis(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    -- Valida que los booleanos solo sean 0/1
    CONSTRAINT chk_pu_boolean
        CHECK (lectura IN (FALSE, TRUE)
           AND escriptura IN (FALSE, TRUE)
           AND edicio IN (FALSE, TRUE))
);
-- Índices para acelerar filtros por usuario y permiso
CREATE INDEX idx_pu_user   ON permis_usuari (id_usuari);
CREATE INDEX idx_pu_permis ON permis_usuari (id_permis);

-- 1H. Historial de sesiones de empresas
CREATE TABLE log_de_sessio (
    id         SERIAL PRIMARY KEY,      -- PK autoincremental
    id_usuari  INTEGER NOT NULL,        -- FK → u_empresa.id
    data_inici DATE     NOT NULL,       -- Día de inicio
    hora_inici TIME     NOT NULL,       -- Hora exacta
    CONSTRAINT fk_log_user
        FOREIGN KEY (id_usuari) REFERENCES usuari(id)
        ON DELETE SET NULL ON UPDATE CASCADE
);
-- Índice para búsquedas por usuario
CREATE INDEX idx_log_user ON log_de_sessio (id_usuari);

-- 1I. Preferencias/configuración (1-a-1)
CREATE TABLE configuracio (
    id_usuari        INTEGER PRIMARY KEY,         -- PK + FK → usuari.id
    idioma           VARCHAR(10)  DEFAULT 'ca',   -- Idioma por defecto
    acceptacio_terms BOOLEAN      NOT NULL DEFAULT FALSE, -- Acepta T&C
    imatge_perfil    VARCHAR(255) NULL,           -- URL de avatar
    CONSTRAINT fk_cfg_user
        FOREIGN KEY (id_usuari) REFERENCES usuari(id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- 1J. Tabla de verificaciones de cuenta d'empreses
CREATE TABLE verificacio (
    id                SERIAL PRIMARY KEY,        -- PK autoincremental
    id_usuari         INTEGER NOT NULL,          -- FK → usuari.id
    estat_ver         VARCHAR(40) NOT NULL,      -- Estado (pendiente, ok…)
    data_ver          DATE        NULL,          -- Fecha de verificación
    token_verificacio VARCHAR(120) NOT NULL,     -- Token único
    data_token        TIMESTAMP    NOT NULL,     -- Fecha de emisión
    CONSTRAINT fk_ver_user
        FOREIGN KEY (id_usuari) REFERENCES u_empresa(id)
        ON DELETE CASCADE ON UPDATE CASCADE
);
-- Índice para verificar por usuario
CREATE INDEX idx_ver_user ON verificacio (id_usuari);

/*=============================================================
=  2.  ENTIDADES DE OBRA                                      =
=============================================================*/
-- 2A. Obras o proyectos de construcción
CREATE TABLE obra (
    id            SERIAL PRIMARY KEY,           -- PK autoincremental
    nom           VARCHAR(160) NOT NULL,        -- Nombre comercial
    ubicacio      VARCHAR(255) NOT NULL,        -- Dirección o coordenadas
    data_inici    DATE         NOT NULL,        -- Inicio real
    data_prev_fi  DATE         NOT NULL,        -- Fin previsto
    data_fi       DATE         NULL,            -- Fin real (si existe)
    descripcio    TEXT         NULL,            -- Descripción larga
    pressupost    BIGINT       NOT NULL,        -- Presupuesto (€)
    estat         VARCHAR(40)  NOT NULL         -- Estado (en curso, etc.)
);

-- 2B. Responsables de obra (N-a-N débil)
CREATE TABLE responsable_obra (
    id_obra        INTEGER NOT NULL,          -- FK → obra.id
    id_treballador INTEGER NOT NULL,          -- FK → u_persona.id
    data_inici     DATE NOT NULL,             -- Desde
    data_fi        DATE NULL,                 -- Hasta
    PRIMARY KEY (id_obra, id_treballador, data_inici),
    CONSTRAINT fk_ro_obra
        FOREIGN KEY (id_obra) REFERENCES obra(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_ro_treballador
        FOREIGN KEY (id_treballador) REFERENCES u_persona(id)
        ON DELETE CASCADE ON UPDATE CASCADE
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
    id_creador   INTEGER NOT NULL,          -- Usuario que sube el doc
    nom          VARCHAR(160) NOT NULL,     -- Nombre de archivo
    format       VARCHAR(40)  NOT NULL,     -- PDF, DWG, etc.
    mida         NUMERIC(6,2)      NOT NULL,     -- Tamaño (MB)
    comentari    TEXT         NULL,         -- Comentario opcional
    data_pujada  TIMESTAMP    NOT NULL,     -- Fecha de subida
    tipus        VARCHAR(40)  NOT NULL,     -- Plano, informe…
    CONSTRAINT fk_doc_obra
        FOREIGN KEY (id_obra) REFERENCES obra(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_doc_autor
        FOREIGN KEY (id_creador) REFERENCES usuari(id)
        ON DELETE SET NULL ON UPDATE CASCADE
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
    id_tasca       INTEGER NOT NULL,      -- FK → tasca.id
    id_treballador INTEGER NOT NULL,      -- FK → u_persona.id
    comentari      TEXT NULL,            -- Comentario extra
    PRIMARY KEY (id_tasca, id_treballador),
    CONSTRAINT fk_tt_tasca
        FOREIGN KEY (id_tasca) REFERENCES tasca(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_tt_treballador
        FOREIGN KEY (id_treballador) REFERENCES u_persona(id)
        ON DELETE CASCADE ON UPDATE CASCADE
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
    eficacia      INTEGER  NOT NULL,        -- 1-5
    cost_temporal INTEGER  NOT NULL,        -- Horas empleadas
    impacte       INTEGER  NOT NULL,    -- 1-10 (bajo-alto)
    CONSTRAINT fk_sol_inc
        FOREIGN KEY (id_incidencia) REFERENCES incidencia(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_sol_tasca
        FOREIGN KEY (id_tasca) REFERENCES tasca(id)
        ON DELETE SET NULL ON UPDATE CASCADE
);

/*=============================================================
=  4.  RECURSOS Y SOLICITUDES                                 =
=============================================================*/
-- 4A. Recursos inventariados
CREATE TABLE recurs (
    id             SERIAL PRIMARY KEY,      -- PK autoincremental
    nom            VARCHAR(120) NOT NULL,   -- Nombre genérico
    unitats_mesura VARCHAR(40)  NOT NULL,   -- Unidades (kg, m3…)
    quantitat_stock NUMERIC NOT NULL,       -- Cantidad en almacén
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
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_sr_recurs
        FOREIGN KEY (id_recurs) REFERENCES recurs(id)
        ON DELETE RESTRICT ON UPDATE CASCADE
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
 
