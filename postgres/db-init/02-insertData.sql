/*-------------------------------------------------------------
  0. UBICACIONS
-------------------------------------------------------------*/
INSERT INTO ubicacio (adreça, ciutat, codi_postal, provincia, país) VALUES
  ('C/ Major, 123',   'Palma',   '07001', 'Illes Balears', 'Espanya'), -- id_ubicacio = 1
  ('C/ Pins, 45',     'Inca',    '07300', 'Illes Balears', 'Espanya'), -- id_ubicacio = 2
  ('Plaça Espanya',   'Manacor', '07500', 'Illes Balears', 'Espanya'); -- id_ubicacio = 3
SELECT setval('ubicacio_id_ubicacio_seq', (SELECT MAX(id_ubicacio) FROM ubicacio));

/*-------------------------------------------------------------
  1. EMPRESES
-------------------------------------------------------------*/
INSERT INTO empresa
  (nom_empresa, cif, ubicacio_id, telefon, email, web, sector,
   estat, persona_contacte, comentaris)
VALUES
  ('Construccions Alzina', 'B12345678', 1, '871123456',
   'info@alzina.com',   'https://alzina.com', 'Construcció',
   'activa', 'Joan Alzina', NULL),                        -- id_empresa = 1

  ('Serveis Integrals',    'B98765432', 2, '971987654',
   'contacte@servintmallorca.com', NULL,  'Serveis',
   'activa', NULL, NULL);                                 -- id_empresa = 2
SELECT setval('empresa_id_empresa_seq', (SELECT MAX(id_empresa) FROM empresa));

/*-------------------------------------------------------------
  2. TREBALLADORS
-------------------------------------------------------------*/
INSERT INTO treballador
  (nom, cognoms, nickname, dni_nie_passaport, data_naixement,
   ubicacio_id, telefon, email, comentaris)
VALUES
  ('Joan',  'Garcia Mora','JohanPera', '12345678A', '1985-01-15', 1, '600123001', NULL, NULL), -- id = 1
  ('Marta', 'Riera Pont', 'MartaSport',  '87654321B', '1990-03-22', 2, '600123002', NULL, NULL), -- id = 2
  ('Pere',  'Fiol Serra', 'PereCarretera' ,'11223344C', '1982-07-08', 3, '600123003', NULL, NULL); -- id = 3
SELECT setval('treballador_id_seq', (SELECT MAX(id) FROM treballador));

/*-------------------------------------------------------------
  3. OBRES
-------------------------------------------------------------*/
INSERT INTO obra
  (nom, ubicacio, data_inici, data_prev_fi, data_fi,
   descripcio, pressupost, estat)
VALUES
  ('Reforma Casa Serra',  'C/ Major, 123, Palma', '2024-07-01', '2024-10-01', NULL,
   'Reforma integral habitatge',  50000, 'EN CURS'),

  ('Construcció Xalet',   'C/ Pins, 45, Inca',   '2024-05-20', '2024-11-30', NULL,
   'Nova construcció de xalet unifamiliar', 150000, 'EN CURS'),

  ('Pavimentació Pl. Espanya', 'Plaça Espanya, Manacor', '2024-04-01',
   '2024-07-31', '2024-07-15',
   'Reforma paviment plaça', 90000, 'FINALITZADA');

/*-------------------------------------------------------------
  4. TASCES i TASCA_TREBALLADOR
-------------------------------------------------------------*/
INSERT INTO tasca
  (id_obra, id_tasca_pare, descripcio, data_inici,
   data_fi, prioritat, visibilitat_tasca)
VALUES
  (1, NULL, 'Preparació fonament',  '2024-07-02', NULL, 1, TRUE), -- id_tasca = 1
  (1, 1,    'Col·locació armadures','2024-07-03', NULL, 2, TRUE), -- id_tasca = 2
  (2, NULL, 'Encofrat sostre',      '2024-06-12', NULL, 2, TRUE); -- id_tasca = 3

INSERT INTO tasca_treballador
  (id, id_tasca, id_treballador, comentari) VALUES
  (1,1, 1, 'Supervisió general'),
  (2,3, 2, NULL),
  (3,2, 3, 'Tasca assignada pel responsable');

/*-------------------------------------------------------------
  5. CONFIGURACIÓ
-------------------------------------------------------------*/
INSERT INTO configuracio (id_treballador, idioma, acceptacio_terms, imatge_perfil)
VALUES
  (1, 'ca', TRUE, NULL),
  (2, 'es', TRUE, 'https://avatar.com/marta.png');

INSERT INTO configuracio (id_empresa, idioma, acceptacio_terms, imatge_perfil)
VALUES
  (1, 'ca', TRUE, 'https://avatar.com/alzina.jpg');

/*-------------------------------------------------------------
  6. CONTRASENYES
-------------------------------------------------------------*/
-- Empreses
INSERT INTO contrasenya (empresa_id, clau, data_creacio) VALUES
  (1, 'Alzina',          '2024-06-01 09:31:00'),
  (2, 'servintMallorca', '2024-06-03 10:02:00');

-- Treballadors
INSERT INTO contrasenya (treballador_id, clau, data_creacio) VALUES
  (2, 'viscaElBarça', '2024-05-22 10:02:00'),
  (1, '12345678',    '2024-08-19 10:02:00'),
  (3, '12345678',    '2024-09-02 10:02:00');

/*-------------------------------------------------------------
  7. DOCUMENTS D’OBRA  (sense FK creador)
-------------------------------------------------------------*/
INSERT INTO document_obra
  (id_obra, nom_creador, nom, format, mida, comentari,
   data_pujada, tipus)
VALUES
  (1, 'Joan Garcia',  'plano_fonament.pdf',      'PDF', 2.3,
   'Plànol fonaments',     '2024-06-15 10:00:00', 'Pla'),

  (2, 'Marta Riera', 'certificat_energia.pdf',  'PDF', 0.7,
   'Certificat energètic', '2024-06-25 09:00:00', 'Informe'),

  (3, 'Joan Garcia', 'pressupost_final.xlsx',   'XLSX', 0.2,
   'Pressupost final',     '2024-07-01 11:00:00', 'Pressupost');

/*-------------------------------------------------------------
  8. INCIDÈNCIES
-------------------------------------------------------------*/
INSERT INTO incidencia
  (id_obra, id_tasca, descripcio, data_inici, data_fi,
   criticitat, prioritat, categoria, estat)
VALUES
  (1, 1, 'Retard subministrament formigó', '2024-07-04', NULL, 3, 2, 1, 'OBERTA'),
  (2, NULL,'Problema humitat parets',       '2024-06-20', NULL, 4, 1, 2, 'OBERTA'),
  (3, 3, 'Endarreriment subministrament totxos','2024-04-17','2024-04-20', 2, 1, 3,'TANCADA');

/*-------------------------------------------------------------
  9. LOG DE SESSIÓ (ara només per treballadors)
-------------------------------------------------------------*/
INSERT INTO log_de_sessio
  (id_treballador, data_inici, hora_inici) VALUES
  (1, '2024-07-01', '08:30:00'),
  (2, '2024-07-02', '09:00:00'),
  (1, '2024-07-03', '11:15:00');

/*-------------------------------------------------------------
 10. PERMISOS i PERMIS_TREBALLADOR
-------------------------------------------------------------*/
INSERT INTO permis (clau_funcional, descripcio) VALUES
  ('ADMIN',          'Accés complet al sistema'),
  ('GESTIO_OBRA',    'Gestió obres i recursos'),
  ('VISUALITZACIO',  'Només visualització');

INSERT INTO permis_treballador
  (id_treballador, id_permis, lectura, escriptura, edicio, data_creacio)
VALUES
  (1, 1, TRUE, TRUE, TRUE,   '2024-06-01 09:35:00'),
  (2, 2, TRUE, TRUE, FALSE,  '2024-06-03 10:10:00'),
  (3, 3, TRUE, FALSE, FALSE, '2024-05-21 13:15:00');

/*-------------------------------------------------------------
 11. RECURSOS, RESPONSABLES, SOL·LICITUDS, SOLUCIONS
-------------------------------------------------------------*/
INSERT INTO recurs (nom, unitats_mesura, quantitat_stock, tipus_recurs) VALUES
  ('Formigó',          'm3',       40,     'Material'),
  ('Grua torre',       'unitats',  2,      'Maquinària'),
  ('Totxos ceràmics',  'unitats',  10000,  'Material');

INSERT INTO responsable_obra
  (id_obra, id_treballador, data_inici, data_fi) VALUES
  (1, 1, '2024-07-01', NULL),
  (2, 2, '2024-05-20', NULL),
  (3, 1, '2024-04-01', '2024-07-15');

INSERT INTO sol_recurs
  (id_obra, id_recurs, quantitat, data_necessitat,
   comentari, data_entrega, data_creacio, proveidor)
VALUES
  (1, 1, 15,   '2024-07-02', 'Necessari per fonaments',
   NULL, '2024-06-25 08:00:00', 'Formigons Balears'),

  (2, 2, 1,    '2024-06-10', 'Per començar estructura',
   '2024-06-12', '2024-06-01 10:00:00', 'Maquinària Mallorquina'),

  (3, 3, 5000, '2024-04-15', 'Primera fase obra',
   '2024-04-16', '2024-04-10 09:00:00', 'Totxos SA');

INSERT INTO solucio
  (id_incidencia, id_tasca, descripcio,
   cost_monetari, eficacia, cost_temporal, impacte)
VALUES
  (1, 1, 'Canvi de proveïdor formigó',     500, 4, 5, 6),
  (2, NULL,'Reparació i segellat parets',  1200,5, 8, 7),
  (3, 3,  'Demora acceptada; ampliació termini', 0, 3, 2, 4);

/*-------------------------------------------------------------
 12. VERIFICACIONS (empreses)
-------------------------------------------------------------*/
INSERT INTO verificacio
  (id, id_empresa, estat_ver, data_ver,
   token_verificacio, data_token)
VALUES
  (1, 1, 'OK',      '2024-06-02', 'token_alzina_123',  '2024-06-01 10:00:00'),
  (2, 1,'PENDENT', NULL,         'token_servint_456', '2024-06-03 11:00:00'),
  (3, 2,'OK',      '2024-07-01', 'token_alzina_789',  '2024-07-01 08:00:00');
