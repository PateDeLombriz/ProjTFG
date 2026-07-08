INSERT INTO usuari
(id, username, password, email, first_name, last_name, tipus, login_field, is_active, is_staff, is_superuser, date_joined, last_login)
VALUES
  -- Empreses (1..6)
  (1, 'info@alzina.com', 'pbkdf2_sha256$dummy$empresa1', 'info@alzina.com', NULL, NULL, 'empresa', 'info@alzina.com', TRUE, FALSE, FALSE, CURRENT_TIMESTAMP, NULL),
  (2, 'contacte@servintmallorca.com', 'pbkdf2_sha256$dummy$empresa2', 'contacte@servintmallorca.com', NULL, NULL, 'empresa', 'contacte@servintmallorca.com', TRUE, FALSE, FALSE, CURRENT_TIMESTAMP, NULL),
  (3, 'info@mallorcaobres.com', 'pbkdf2_sha256$dummy$empresa3', 'info@mallorcaobres.com', NULL, NULL, 'empresa', 'info@mallorcaobres.com', TRUE, FALSE, FALSE, CURRENT_TIMESTAMP, NULL),
  (4, 'contacte@menorcaprojectes.com', 'pbkdf2_sha256$dummy$empresa4', 'contacte@menorcaprojectes.com', NULL, NULL, 'empresa', 'contacte@menorcaprojectes.com', TRUE, FALSE, FALSE, CURRENT_TIMESTAMP, NULL),
  (5, 'admin@eivissainfra.com', 'pbkdf2_sha256$dummy$empresa5', 'admin@eivissainfra.com', NULL, NULL, 'empresa', 'admin@eivissainfra.com', TRUE, FALSE, FALSE, CURRENT_TIMESTAMP, NULL),
  (6, 'hola@formenterarehab.com', 'pbkdf2_sha256$dummy$empresa6', 'hola@formenterarehab.com', NULL, NULL, 'empresa', 'hola@formenterarehab.com', TRUE, FALSE, FALSE, CURRENT_TIMESTAMP, NULL),

  -- Treballadors (7..39)
  (7,  'JohanPaletas',   'pbkdf2_sha256$dummy$treb1',  NULL,                 'Joan',     'Garcia Mora',        'treballador', 'JohanPaletas',   TRUE, FALSE, FALSE, CURRENT_TIMESTAMP, NULL),
  (8,  'MartaSport',     'pbkdf2_sha256$dummy$treb2',  'marta@exemple.com',  'Marta',    'Riera Pont',         'treballador', 'MartaSport',     TRUE, FALSE, FALSE, CURRENT_TIMESTAMP, NULL),
  (9,  'PerePipes',      'pbkdf2_sha256$dummy$treb3',  NULL,                 'Pere',     'Fiol Serra',         'treballador', 'PerePipes',      TRUE, FALSE, FALSE, CURRENT_TIMESTAMP, NULL),
  (10, 'Tonicofrat',     'pbkdf2_sha256$dummy$treb4',  NULL,                 'Antoni',   'Mas Coll',           'treballador', 'Tonicofrat',     TRUE, FALSE, FALSE, CURRENT_TIMESTAMP, NULL),
  (11, 'MigFerralla',    'pbkdf2_sha256$dummy$treb5',  NULL,                 'Miguel',   'Santos Ruiz',        'treballador', 'MigFerralla',    TRUE, FALSE, FALSE, CURRENT_TIMESTAMP, NULL),
  (12, 'RafelGruista',   'pbkdf2_sha256$dummy$treb6',  NULL,                 'Rafel',    'Servera Nadal',      'treballador', 'RafelGruista',   TRUE, FALSE, FALSE, CURRENT_TIMESTAMP, NULL),
  (13, 'AinaPintora',    'pbkdf2_sha256$dummy$treb7',  NULL,                 'Aina',     'Fullana Puig',       'treballador', 'AinaPintora',    TRUE, FALSE, FALSE, CURRENT_TIMESTAMP, NULL),
  (14, 'BernatPeo',      'pbkdf2_sha256$dummy$treb8',  NULL,                 'Bernat',   'Crespí Llabrés',     'treballador', 'BernatPeo',      TRUE, FALSE, FALSE, CURRENT_TIMESTAMP, NULL),
  (15, 'XiscoPladur',    'pbkdf2_sha256$dummy$treb9',  NULL,                 'Xisco',    'Amengual Bauzà',     'treballador', 'XiscoPladur',    TRUE, FALSE, FALSE, CURRENT_TIMESTAMP, NULL),
  (16, 'LauraFusta',     'pbkdf2_sha256$dummy$treb10', NULL,                 'Laura',    'Pons Gelabert',      'treballador', 'LauraFusta',     TRUE, FALSE, FALSE, CURRENT_TIMESTAMP, NULL),
  (17, 'GabiMarge',      'pbkdf2_sha256$dummy$treb11', NULL,                 'Gabriel',  'Ramis Forteza',      'treballador', 'GabiMarge',      TRUE, FALSE, FALSE, CURRENT_TIMESTAMP, NULL),
  (18, 'SergiManobre',   'pbkdf2_sha256$dummy$treb12', NULL,                 'Sergi',    'Tugores Rosselló',   'treballador', 'SergiManobre',   TRUE, FALSE, FALSE, CURRENT_TIMESTAMP, NULL),
  (19, 'NuriSolda',      'pbkdf2_sha256$dummy$treb13', NULL,                 'Núria',    'Costa Mir',          'treballador', 'NuriSolda',      TRUE, FALSE, FALSE, CURRENT_TIMESTAMP, NULL),
  (20, 'MateuPicapedrer','pbkdf2_sha256$dummy$treb14', NULL,                 'Mateu',    'Vidal Ferrer',       'treballador', 'MateuPicapedrer',TRUE, FALSE, FALSE, CURRENT_TIMESTAMP, NULL),
  (21, 'DamiaExcava',    'pbkdf2_sha256$dummy$treb15', NULL,                 'Damià',    'Munar Torres',       'treballador', 'DamiaExcava',    TRUE, FALSE, FALSE, CURRENT_TIMESTAMP, NULL),
  (22, 'CrisReformes',   'pbkdf2_sha256$dummy$treb16', NULL,                 'Cristina', 'Llompart Sastre',    'treballador', 'CrisReformes',   TRUE, FALSE, FALSE, CURRENT_TIMESTAMP, NULL),
  (23, 'JaumeTiler',     'pbkdf2_sha256$dummy$treb17', NULL,                 'Jaume',    'Bestard Roca',       'treballador', 'JaumeTiler',     TRUE, FALSE, FALSE, CURRENT_TIMESTAMP, NULL),
  (24, 'IvanYesaire',    'pbkdf2_sha256$dummy$treb18', NULL,                 'Iván',     'Moreno Díaz',        'treballador', 'IvanYesaire',    TRUE, FALSE, FALSE, CURRENT_TIMESTAMP, NULL),
  (25, 'Miquelet',       'pbkdf2_sha256$dummy$treb19', NULL,                 'Miquel',   'Perelló Juan',       'treballador', 'Miquelet',       TRUE, FALSE, FALSE, CURRENT_TIMESTAMP, NULL),
  (26, 'PaulaCable',     'pbkdf2_sha256$dummy$treb20', NULL,                 'Paula',    'Escandell Tur',      'treballador', 'PaulaCable',     TRUE, FALSE, FALSE, CURRENT_TIMESTAMP, NULL),
  (27, 'ToniAigua',      'pbkdf2_sha256$dummy$treb21', NULL,                 'Toni',     'Prats Colom',        'treballador', 'ToniAigua',      TRUE, FALSE, FALSE, CURRENT_TIMESTAMP, NULL),
  (28, 'LlorencFormigo', 'pbkdf2_sha256$dummy$treb22', NULL,                 'Llorenç',  'Adrover Mut',        'treballador', 'LlorencFormigo', TRUE, FALSE, FALSE, CURRENT_TIMESTAMP, NULL),
  (29, 'NeusAillaments', 'pbkdf2_sha256$dummy$treb23', NULL,                 'Neus',     'Cardona Ferragut',   'treballador', 'NeusAillaments', TRUE, FALSE, FALSE, CURRENT_TIMESTAMP, NULL),
  (30, 'SalvaBastida',   'pbkdf2_sha256$dummy$treb24', NULL,                 'Salvador', 'Barceló Sureda',     'treballador', 'SalvaBastida',   TRUE, FALSE, FALSE, CURRENT_TIMESTAMP, NULL),
  (31, 'JordiDemolicio', 'pbkdf2_sha256$dummy$treb25', NULL,                 'Jordi',    'Ferrer Salas',       'treballador', 'JordiDemolicio', TRUE, FALSE, FALSE, CURRENT_TIMESTAMP, NULL),
  (32, 'MariaCompacta',  'pbkdf2_sha256$dummy$treb26', NULL,                 'Maria',    'Oliver Truyols',     'treballador', 'MariaCompacta',  TRUE, FALSE, FALSE, CURRENT_TIMESTAMP, NULL),
  (33, 'BielCobertes',   'pbkdf2_sha256$dummy$treb27', NULL,                 'Biel',     'Rosselló Martorell', 'treballador', 'BielCobertes',   TRUE, FALSE, FALSE, CURRENT_TIMESTAMP, NULL),
  (34, 'AndreuAsfalt',   'pbkdf2_sha256$dummy$treb28', NULL,                 'Andreu',   'Calafat Cifre',      'treballador', 'AndreuAsfalt',   TRUE, FALSE, FALSE, CURRENT_TIMESTAMP, NULL),
  (35, 'CatiPaviments',  'pbkdf2_sha256$dummy$treb29', NULL,                 'Caterina', 'Serra Alcover',      'treballador', 'CatiPaviments',  TRUE, FALSE, FALSE, CURRENT_TIMESTAMP, NULL),
  (36, 'VicençMur',      'pbkdf2_sha256$dummy$treb30', NULL,                 'Vicenç',   'Miralles Vaquer',    'treballador', 'VicençMur',      TRUE, FALSE, FALSE, CURRENT_TIMESTAMP, NULL),
  (37, 'DavidTall',      'pbkdf2_sha256$dummy$treb31', NULL,                 'David',    'Hernández López',    'treballador', 'DavidTall',      TRUE, FALSE, FALSE, CURRENT_TIMESTAMP, NULL),
  (38, 'CarlaMetal',     'pbkdf2_sha256$dummy$treb32', NULL,                 'Carla',    'Fuster Bennàssar',   'treballador', 'CarlaMetal',     TRUE, FALSE, FALSE, CURRENT_TIMESTAMP, NULL),
  (39, 'MarcJardiObra',  'pbkdf2_sha256$dummy$treb33', NULL,                 'Marc',     'Reus Sampol',        'treballador', 'MarcJardiObra',  TRUE, FALSE, FALSE, CURRENT_TIMESTAMP, NULL);

SELECT setval('usuari_id_seq', (SELECT MAX(id) FROM usuari));

INSERT INTO ubicacio
(id_ubicacio, adreça, ciutat, codi_postal, provincia, país, latitud, longitud) VALUES
  (1, 'C/ Major, 123',   'Palma',       '07001', 'Illes Balears', 'Espanya',NULL,NULL),
  (2, 'C/ Pins, 45',     'Inca',        '07300', 'Illes Balears', 'Espanya',NULL,NULL),
  (3, 'Plaça Espanya',   'Manacor',     '07500', 'Illes Balears', 'Espanya',NULL,NULL),
  (4, 'Av. Alemanya, 10','Palma',       '07003', 'Illes Balears', 'Espanya',NULL,NULL),
  (5, 'C/ Ramon Llull, 7','Alcúdia',    '07400', 'Illes Balears', 'Espanya',NULL,NULL),
  (6, 'Passeig Marítim, 21','Sóller',   '07100', 'Illes Balears', 'Espanya',NULL,NULL),
  (7, 'C/ de la Pau, 15','Felanitx',    '07200', 'Illes Balears', 'Espanya',NULL,NULL),
  (8, 'Av. Joan Carles I, 5','Marratxí','07141', 'Illes Balears', 'Espanya',NULL,NULL),
  (9, 'C/ Sant Miquel, 88','Llucmajor', '07620', 'Illes Balears', 'Espanya',NULL,NULL),
  (10,'Plaça Major, 3',  'Pollença',    '07460', 'Illes Balears', 'Espanya',NULL,NULL),
  (11,'C/ Rector, 12',   'Campos',      '07630', 'Illes Balears', 'Espanya',NULL,NULL),
  (12,'Av. Constitució, 50','Capdepera','07580', 'Illes Balears', 'Espanya',NULL,NULL),
  (13,'C/ Mar, 9',       'Porto Cristo','07680', 'Illes Balears', 'Espanya',NULL,NULL ),
  (14, 'C/ Escola Nova, 22',         'Manacor',      '07500', 'Illes Balears', 'Espanya', NULL, NULL),
  (15, 'C/ del Comerç, 41',          'Inca',         '07300', 'Illes Balears', 'Espanya', NULL, NULL),
  (16, 'Av. Jaume III, 18',          'Llucmajor',    '07620', 'Illes Balears', 'Espanya', NULL, NULL),
  (17, 'C/ de s''Arravaleta, 7',     'Maó',          '07701', 'Illes Balears', 'Espanya', NULL, NULL),
  (18, 'C/ de Sant Josep, 14',       'Ciutadella',   '07760', 'Illes Balears', 'Espanya', NULL, NULL),
  (19, 'Polígon Marratxí, nau 5',    'Marratxí',     '07141', 'Illes Balears', 'Espanya', NULL, NULL),
  (20, 'Camí Vell d’Artà, 3',        'Artà',         '07570', 'Illes Balears', 'Espanya', NULL, NULL),
  (21, 'Av. Alexandre Rosselló, 44', 'Palma',        '07002', 'Illes Balears', 'Espanya', NULL, NULL),
  (22, 'C/ de sa Vinya, 11',         'Calvià',       '07184', 'Illes Balears', 'Espanya', NULL, NULL),
  (23, 'C/ de sa Lluna, 26',         'Sóller',       '07100', 'Illes Balears', 'Espanya', NULL, NULL),
  (24, 'Av. d''Isidor Macabich, 30', 'Eivissa',      '07800', 'Illes Balears', 'Espanya', NULL, NULL),
  (25, 'Passeig de ses Fonts, 8',    'Sant Antoni',  '07820', 'Illes Balears', 'Espanya', NULL, NULL),
  (26, 'C/ de Santa Maria, 19',      'Formentera',   '07860', 'Illes Balears', 'Espanya', NULL, NULL),
  (27, 'C/ del Moll, 12',            'Alcúdia',      '07400', 'Illes Balears', 'Espanya', NULL, NULL);

-- Sincronitza la seqüència, ja que hem fixat els IDs manualment
SELECT setval('ubicacio_id_ubicacio_seq', (SELECT MAX(id_ubicacio) FROM ubicacio));


/* ─────────────────────────
   EMPRESA (abans u_empresa)
   ───────────────────────── */
INSERT INTO empresa
(id_empresa, nom_empresa, cif, ubicacio_id, telefon, email, web, sector, data_alta, estat, persona_contacte, comentaris, user_id) VALUES
  (1, 'Construccions Alzina', 'B00000004', 7, '871123456', 'info@alzina.com', NULL, NULL, '2024-05-21', 'activa', NULL, NULL, 1),
  (2, 'Serveis Integrals', 'B00000005', 8, '971987654', 'contacte@servintmallorca.com', NULL, NULL, '2024-05-25', 'activa', NULL, NULL, 2),
  (3, 'Mallorca Obres i Serveis', 'B00000006', 9, '971111222', 'info@mallorcaobres.com', 'https://www.mallorcaobres.com', 'Construccio', '2024-06-02', 'activa', 'Joan Ferrer', 'Especialitzada en reformes residencials', 3),
  (4, 'Menorca Projectes Tècnics', 'B00000007', 10, '971222333', 'contacte@menorcaprojectes.com', 'https://www.menorcaprojectes.com', 'Enginyeria', '2024-06-10', 'activa', 'Maria Pons', 'Projectes tècnics i direcció d’obra', 4),
  (5, 'Eivissa Infraestructures', 'B00000008', 11, '971333444', 'admin@eivissainfra.com', 'https://www.eivissainfra.com', 'Obra publica', '2024-06-18', 'activa', 'Carles Serra', 'Especialitzada en urbanització i espais públics', 5),
  (6, 'Formentera Rehabilitacions', 'B00000009', 12, '971444555', 'hola@formenterarehab.com', 'https://www.formenterarehab.com', 'Rehabilitacio', '2024-06-22', 'activa', 'Neus Cardona', 'Petites i mitjanes rehabilitacions', 6);

SELECT setval('empresa_id_empresa_seq', (SELECT MAX(id_empresa) FROM empresa));

/* ───────────────────────────
   TREBALLADOR (abans u_persona)
   ─────────────────────────── */
INSERT INTO treballador
(id, nom, cognoms, nickname, dni_nie_passaport, data_naixement, telefon, email, foto, comentaris, user_id) VALUES
  (1,  'Joan',     'Garcia Mora',       'JohanPaletas',    'DNI0001A', NULL,         '600123001', NULL,                'back_end/media/fotos/fotoJohanPaletas', 'rol=Mestre Obra; estat=ACTIU', 7),
  (2,  'Marta',    'Riera Pont',        'MartaSport',      'DNI0002B', NULL,         '600123002', 'marta@exemple.com', NULL,                                 'rol=Oficial 1a; estat=ACTIU', 8),
  (3,  'Pere',     'Fiol Serra',        'PerePipes',       'DNI0003C', NULL,         '600123003', NULL,                NULL,                                 'rol=Peó; estat=INACTIU', 9),
  (4,  'Antoni',   'Mas Coll',          'Tonicofrat',      'DNI0004D', '1985-03-12', '600123004', NULL,                NULL,                                 'rol=Encofrador; estat=ACTIU', 10),
  (5,  'Miguel',   'Santos Ruiz',       'MigFerralla',     'DNI0005E', '1979-11-08', '600123005', NULL,                NULL,                                 'rol=Ferrallista; estat=ACTIU', 11),
  (6,  'Rafel',    'Servera Nadal',     'RafelGruista',    'DNI0006F', '1988-06-21', '600123006', NULL,                NULL,                                 'rol=Gruista; estat=ACTIU', 12),
  (7,  'Aina',     'Fullana Puig',      'AinaPintora',     'DNI0007G', '1992-01-17', '600123007', NULL,                NULL,                                 'rol=Pintora; estat=ACTIU', 13),
  (8,  'Bernat',   'Crespí Llabrés',    'BernatPeo',       'DNI0008H', '1996-09-03', '600123008', NULL,                NULL,                                 'rol=Peó; estat=ACTIU', 14),
  (9,  'Xisco',    'Amengual Bauzà',    'XiscoPladur',     'DNI0009I', '1987-04-25', '600123009', NULL,                NULL,                                 'rol=Instal·lador Pladur; estat=ACTIU', 15),
  (10, 'Laura',    'Pons Gelabert',     'LauraFusta',      'DNI0010J', '1991-07-14', '600123010', NULL,                NULL,                                 'rol=Fustera; estat=ACTIU', 16),
  (11, 'Gabriel',  'Ramis Forteza',     'GabiMarge',       'DNI0011K', '1983-12-01', '600123011', NULL,                NULL,                                 'rol=Marger; estat=ACTIU', 17),
  (12, 'Sergi',    'Tugores Rosselló',  'SergiManobre',    'DNI0012L', '1994-05-28', '600123012', NULL,                NULL,                                 'rol=Manobre; estat=ACTIU', 18),
  (13, 'Núria',    'Costa Mir',         'NuriSolda',       'DNI0013M', '1990-08-19', '600123013', NULL,                NULL,                                 'rol=Soldadora; estat=ACTIU', 19),
  (14, 'Mateu',    'Vidal Ferrer',      'MateuPicapedrer', 'DNI0014N', '1981-02-10', '600123014', NULL,                NULL,                                 'rol=Picapedrer; estat=ACTIU', 20),
  (15, 'Damià',    'Munar Torres',      'DamiaExcava',     'DNI0015O', '1986-10-30', '600123015', NULL,                NULL,                                 'rol=Maquinista Excavadora; estat=ACTIU', 21),
  (16, 'Cristina', 'Llompart Sastre',   'CrisReformes',    'DNI0016P', '1993-06-07', '600123016', NULL,                NULL,                                 'rol=Oficial 1a; estat=ACTIU', 22),
  (17, 'Jaume',    'Bestard Roca',      'JaumeTiler',      'DNI0017Q', '1989-09-11', '600123017', NULL,                NULL,                                 'rol=Enrajolador; estat=ACTIU', 23),
  (18, 'Iván',     'Moreno Díaz',       'IvanYesaire',     'DNI0018R', '1984-01-26', '600123018', NULL,                NULL,                                 'rol=Guixaire; estat=ACTIU', 24),
  (19, 'Miquel',   'Perelló Juan',      'Miquelet',        'DNI0019S', '1978-07-05', '600123019', NULL,                NULL,                                 'rol=Mestre Obra; estat=ACTIU', 25),
  (20, 'Paula',    'Escandell Tur',     'PaulaCable',      'DNI0020T', '1995-03-22', '600123020', NULL,                NULL,                                 'rol=Electricista d''obra; estat=ACTIU', 26),
  (21, 'Toni',     'Prats Colom',       'ToniAigua',       'DNI0021U', '1982-11-16', '600123021', NULL,                NULL,                                 'rol=Lampista; estat=ACTIU', 27),
  (22, 'Llorenç',  'Adrover Mut',       'LlorencFormigo',  'DNI0022V', '1980-04-09', '600123022', NULL,                NULL,                                 'rol=Formigoner; estat=ACTIU', 28),
  (23, 'Neus',     'Cardona Ferragut',  'NeusAillaments',  'DNI0023W', '1991-12-13', '600123023', NULL,                NULL,                                 'rol=Instal·ladora Aïllaments; estat=ACTIU', 29),
  (24, 'Salvador', 'Barceló Sureda',    'SalvaBastida',    'DNI0024X', '1987-08-27', '600123024', NULL,                NULL,                                 'rol=Muntador Bastides; estat=ACTIU', 30),
  (25, 'Jordi',    'Ferrer Salas',      'JordiDemolicio',  'DNI0025Y', '1988-05-31', '600123025', NULL,                NULL,                                 'rol=Operari Demolició; estat=ACTIU', 31),
  (26, 'Maria',    'Oliver Truyols',    'MariaCompacta',   'DNI0026Z', '1994-10-18', '600123026', NULL,                NULL,                                 'rol=Maquinista Compactadora; estat=ACTIU', 32),
  (27, 'Biel',     'Rosselló Martorell','BielCobertes',    'DNI0027A', '1983-01-04', '600123027', NULL,                NULL,                                 'rol=Especialista Cobertes; estat=ACTIU', 33),
  (28, 'Andreu',   'Calafat Cifre',     'AndreuAsfalt',    'DNI0028B', '1986-06-29', '600123028', NULL,                NULL,                                 'rol=Asfaltador; estat=ACTIU', 34),
  (29, 'Caterina', 'Serra Alcover',     'CatiPaviments',   'DNI0029C', '1990-09-20', '600123029', NULL,                NULL,                                 'rol=Col·locadora Paviments; estat=ACTIU', 35),
  (30, 'Vicenç',   'Miralles Vaquer',   'VicençMur',       'DNI0030D', '1977-02-15', '600123030', NULL,                NULL,                                 'rol=Paleta; estat=ACTIU', 36),
  (31, 'David',    'Hernández López',   'DavidTall',       'DNI0031E', '1992-07-09', '600123031', NULL,                NULL,                                 'rol=Tallador Materials; estat=ACTIU', 37),
  (32, 'Carla',    'Fuster Bennàssar',  'CarlaMetal',      'DNI0032F', '1993-11-24', '600123032', NULL,                NULL,                                 'rol=Muntadora Estructures Metàl·liques; estat=ACTIU', 38),
  (33, 'Marc',     'Reus Sampol',       'MarcJardiObra',   'DNI0033G', '1996-04-02', '600123033', NULL,                NULL,                                 'rol=Peó; estat=ACTIU', 39);

SELECT setval('treballador_id_seq', (SELECT MAX(id) FROM treballador));
/* ───────────
   OBRA (igual)
   ─────────── */
INSERT INTO obra (nom, ubicacio_id, data_inici, data_prev_fi, data_fi, descripcio, pressupost, estat) VALUES
  ('Reforma Casa Serra',      4, '2024-07-01', '2024-10-01', NULL, 'Reforma integral habitatge',            50000,  'planificacio'),
  ('Construcció Xalet',      5,    '2024-05-20', '2024-11-30', NULL, 'Nova construcció de xalet unifamiliar', 150000, 'en curs'),
  ('Pavimentació Pl. Espanya',6,'2024-04-01', '2024-07-31', '2024-07-15', 'Reforma paviment plaça',         90000,  'finalitzada'),
  ('Reforma Hotel Port de Pollença',       13, '2024-06-15', '2024-12-20', NULL,         'Reforma interior i millora d’instal·lacions d’un hotel',              280000, 'planificacio'),
  ('Adequació Escola de Manacor',          14, '2024-07-01', '2024-09-15', NULL,         'Millora d’aules, banys i accessibilitat',                             120000, 'en curs'),
  ('Rehabilitació Façana a Inca',          15, '2024-05-10', '2024-08-30', '2024-08-20', 'Rehabilitació completa de façana i coberta',                           76000, 'aturada'),
  ('Millora Xarxa Pluvial a Maó',          17, '2024-06-05', '2024-10-10', NULL,         'Renovació de canalitzacions i embornals',                             98000, 'en curs'),
  ('Reforma Apartaments a Ciutadella',     18, '2024-04-20', '2024-09-01', '2024-08-28', 'Actualització integral de 8 apartaments turístics',                 132000, 'finalitzada'),
  ('Ampliació Nau Industrial a Marratxí',  19, '2024-08-12', '2025-01-20', NULL,         'Ampliació d’espai logístic i zona de càrrega',                        210000, 'en curs'),
  ('Condicionament Camí Rural a Artà',     20, '2024-03-18', '2024-06-30', '2024-06-25', 'Millora de ferm i drenatge de camí rural',                             64000, 'finalitzada'),
  ('Reforma Local Comercial a Palma',      21, '2024-07-22', '2024-10-22', NULL,         'Adequació interior per a obertura de comerç',                          58000, 'en curs'),
  ('Urbanització zona verda a Calvià',     22, '2024-05-27', '2024-11-15', NULL,         'Creació d’espais enjardinats i recorreguts accessibles',             175000, 'en curs'),
  ('Rehabilitació habitatge a Sóller',     23, '2024-06-03', '2024-09-25', NULL,         'Reforma estructural i acabats interiors d’habitatge antic',           87000, 'aturada'),
  ('Nou aparcament municipal a Eivissa',   24, '2024-09-15', '2025-04-15', NULL,         'Execució d’aparcament exterior amb paviment i il·luminació',         320000, 'en curs'),
  ('Millora passeig marítim de Sant Antoni',25,'2024-10-01', '2025-03-01', NULL,         'Renovació de paviments, bancs i enllumenat',                          265000, 'en curs'),
  ('Reforma centre sanitari a Formentera', 26, '2024-05-14', '2024-10-01', '2024-09-18', 'Millora de consultes, accessos i climatització',                     143000, 'finalitzada'),
  ('Adequació biblioteca municipal a Alcúdia',27,'2024-08-01','2024-12-10', NULL,        'Redistribució interior, mobiliari fix i eficiència energètica',      110000, 'en curs');


INSERT INTO obra_empresa (id, id_empresa, id_obra, data_i, data_f) VALUES
  (1,  1,  1, '2024-07-01 08:00:00', NULL),
  (2,  3,  1, '2024-07-05 09:00:00', NULL),
  (3,  2,  2, '2024-05-20 08:00:00', NULL),
  (4,  4,  2, '2024-05-25 10:00:00', NULL),
  (5,  1,  3, '2024-04-01 08:00:00', '2024-07-15 18:00:00'),
  (6,  5,  3, '2024-04-03 08:30:00', '2024-07-15 18:00:00'),
  (7,  1,  4, '2024-06-15 08:00:00', NULL),
  (8,  3,  4, '2024-06-20 09:00:00', NULL),
  (9,  2,  5, '2024-07-01 08:00:00', NULL),
  (10, 4,  5, '2024-07-03 08:30:00', NULL),
  (11, 3,  6, '2024-05-10 08:00:00', '2024-08-20 17:00:00'),
  (12, 1,  6, '2024-05-12 08:00:00', '2024-08-20 17:00:00'),
  (13, 1,  7, '2024-09-01 08:00:00', NULL),
  (14, 4,  7, '2024-09-10 09:30:00', NULL),
  (15, 5,  7, '2024-09-15 10:00:00', NULL),
  (16, 4,  8, '2024-06-05 08:00:00', NULL),
  (17, 5,  8, '2024-06-06 08:00:00', NULL),
  (18, 4,  9, '2024-04-20 08:00:00', '2024-08-28 17:00:00'),
  (19, 2,  9, '2024-04-22 09:00:00', '2024-08-28 17:00:00'),
  (20, 3, 10, '2024-08-12 08:00:00', NULL),
  (21, 1, 10, '2024-08-15 08:30:00', NULL),
  (22, 2, 11, '2024-03-18 08:00:00', '2024-06-25 16:00:00'),
  (23, 5, 11, '2024-03-20 08:00:00', '2024-06-25 16:00:00'),
  (24, 1, 12, '2024-07-22 08:00:00', NULL),
  (25, 6, 12, '2024-07-24 09:00:00', NULL),
  (26, 5, 13, '2024-05-27 08:00:00', NULL),
  (27, 2, 13, '2024-05-30 08:00:00', NULL),
  (28, 6, 14, '2024-06-03 08:00:00', NULL),
  (29, 3, 14, '2024-06-05 08:00:00', NULL),
  (30, 5, 15, '2024-09-15 08:00:00', NULL),
  (31, 1, 15, '2024-09-20 08:30:00', NULL),
  (32, 5, 16, '2024-10-01 08:00:00', NULL),
  (33, 2, 16, '2024-10-03 09:00:00', NULL),
  (34, 6, 17, '2024-05-14 08:00:00', '2024-09-18 17:00:00'),
  (35, 4, 17, '2024-05-16 08:00:00', '2024-09-18 17:00:00'),
  (36, 3, 18, '2024-08-01 08:00:00', NULL),
  (37, 1, 18, '2024-08-03 08:00:00', NULL);

SELECT setval('obra_empresa_id_seq', (SELECT MAX(id) FROM obra_empresa));

/* ────────────────
   TASCA (igual)
   ──────────────── */
INSERT INTO tasca
(id, id_obra, id_tasca_pare, descripcio, data_inici, data_fi, prioritat, visibilitat_tasca, estat) VALUES
(1,  1, NULL, 'Preparació fonament',                   '2024-07-02', NULL,         1, TRUE, 'en_curs'),
(2,  1, 1,    'Col·locació armadures',                 '2024-07-03', NULL,         2, TRUE, 'en_curs'),

(3,  2, NULL, 'Excavació de terreny',                  '2024-05-21', NULL,         1, TRUE, 'en_curs'),
(4,  2, 3,    'Nivellació de base',                    '2024-05-22', NULL,         2, TRUE, 'en_curs'),

(5,  3, NULL, 'Tall de paviment existent',             '2024-04-02', '2024-04-03', 2, TRUE, 'finalitzada'),
(6,  3, 5,    'Retirada de peces malmeses',            '2024-04-03', '2024-04-05', 2, TRUE, 'finalitzada'),
(7,  3, 5,    'Preparació de base de grava',           '2024-04-06', '2024-04-08', 1, TRUE, 'finalitzada'),

(8,  4, NULL, 'Demolició envans interiors',            '2024-06-16', NULL,         2, TRUE, 'en_curs'),
(9,  4, 8,    'Desmuntatge d’aparells sanitaris',      '2024-06-16', NULL,         2, TRUE, 'cancelada'),
(10, 4, 8,    'Substitució de paviment interior',      '2024-06-20', NULL,         2, TRUE, 'en_curs'),
(11, 4, 8,    'Anivellat de solera interior',          '2024-06-20', NULL,         1, TRUE, 'en_curs'),

(12, 5, NULL, 'Replanteig d’aules noves',              '2024-07-02', NULL,         1, TRUE, 'en_curs'),
(13, 5, 12,   'Marcatge de divisòries interiors',      '2024-07-02', NULL,         2, TRUE, 'en_curs'),
(14, 5, 12,   'Instal·lació de fals sostre',           '2024-07-10', NULL,         2, TRUE, 'pendent_revisio'),
(15, 5, 12,   'Col·locació de perfileria metàl·lica',  '2024-07-10', NULL,         2, TRUE, 'en_curs'),

(16, 6, NULL, 'Picat de revestiment exterior',         '2024-05-11', '2024-05-14', 2, TRUE, 'finalitzada'),
(17, 6, 16,   'Neteja de superfície de façana',        '2024-05-15', '2024-05-16', 2, TRUE, 'finalitzada'),
(18, 6, 16,   'Aplicació de morter monocapa',          '2024-05-18', '2024-05-24', 1, TRUE, 'finalitzada'),

(19, 7, NULL, 'Moviment de terres inicial',            '2024-09-02', NULL,         1, TRUE, 'en_curs'),
(20, 7, 19,   'Compactació del terreny',               '2024-09-04', NULL,         1, TRUE, 'en_curs'),
(21, 7, 19,   'Execució de sabates aïllades',          '2024-09-06', NULL,         1, TRUE, 'en_curs'),
(22, 7, 19,   'Col·locació de ferralla en fonament',   '2024-09-07', '2024-09-09', 1, TRUE, 'pendent_revisio'),

(23, 8, NULL, 'Obertura de rasa principal',            '2024-06-06', NULL,         1, TRUE, 'cancelada'),
(24, 8, 23,   'Col·locació de tubs de drenatge',       '2024-06-08', NULL,         1, TRUE, 'en_curs'),
(25, 8, 23,   'Reposició de paviment afectat',         '2024-06-20', NULL,         2, TRUE, 'pendent_revisio'),

(26, 9, NULL, 'Desmuntatge de cuines antigues',        '2024-04-21', '2024-04-23', 2, TRUE, 'finalitzada'),
(27, 9, 26,   'Retirada d’electrodomèstics vells',     '2024-04-21', '2024-04-22', 3, TRUE, 'finalitzada'),
(28, 9, 26,   'Pintura interior d’apartaments',        '2024-06-10', '2024-06-20', 2, TRUE, 'finalitzada'),

(29, 10, NULL,'Excavació per ampliació de nau',        '2024-08-13', NULL,         1, TRUE, 'en_curs'),
(30, 10, 29,  'Formació de rampa de càrrega',          '2024-08-16', NULL,         2, TRUE, 'en_curs'),
(31, 10, 29,  'Muntatge d’estructura metàl·lica',      '2024-08-22', NULL,         1, TRUE, 'cancelada'),
(32, 10, 29,  'Soldadura de jàsseres principals',      '2024-08-24', '2024-08-28', 1, TRUE, 'pendent_revisio'),

(33, 11, NULL,'Desbrossament de marge de camí',        '2024-03-19', '2024-03-21', 2, TRUE, 'finalitzada'),
(34, 11, 33,  'Retirada de pedres grans',              '2024-03-20', '2024-03-22', 2, TRUE, 'finalitzada'),
(35, 11, 33,  'Estesa de capa granular',               '2024-04-01', '2024-04-05', 1, TRUE, 'finalitzada'),

(36, 12, NULL,'Enderroc de fals sostre antic',         '2024-07-23', NULL,         2, TRUE, 'en_curs'),
(37, 12, 36,  'Recollida de residus interiors',        '2024-07-24', NULL,         2, TRUE, 'en_curs'),
(38, 12, 36,  'Col·locació d’enrajolat nou',           '2024-08-05', NULL,         2, TRUE, 'en_curs'),
(39, 12, 36,  'Tall de peces per cantonades',          '2024-08-06', '2024-08-07', 3, TRUE, 'pendent_revisio'),

(40, 13, NULL,'Replanteig de camins interiors',        '2024-05-28', NULL,         2, TRUE, 'en_curs'),
(41, 13, 40,  'Excavació de rases per reg',            '2024-05-30', NULL,         2, TRUE, 'en_curs'),
(42, 13, 40,  'Col·locació de mobiliari urbà',         '2024-08-12', NULL,         3, TRUE, 'pendent_revisio'),

(43, 14, NULL,'Reforç de bigues de fusta',             '2024-06-04', NULL,         1, TRUE, 'en_curs'),
(44, 14, 43,  'Tractament protector de fusta',         '2024-06-06', NULL,         2, TRUE, 'en_curs'),
(45, 14, 43,  'Reposició de coberta inclinada',        '2024-07-01', NULL,         1, TRUE, 'pendent_revisio'),

(46, 15, NULL,'Formació de vorades per aparcament',    '2024-09-16', NULL,         2, TRUE, 'en_curs'),
(47, 15, 46,  'Col·locació de rigoles de drenatge',    '2024-09-18', NULL,         1, TRUE, 'en_curs'),
(48, 15, 46,  'Pavimentació de zona d’estacionament',  '2024-10-02', NULL,         1, TRUE, 'pendent_revisio'),

(49, 16, NULL,'Demolició de particions interiors',     '2024-10-02', NULL,         2, TRUE, 'en_curs'),
(50, 16, 49,  'Retirada selectiva de ferralla',        '2024-10-03', NULL,         2, TRUE, 'en_curs'),
(51, 16, 49,  'Renovació d’enllumenat exterior',       '2024-11-10', NULL,         2, TRUE, 'pendent_revisio'),

(52, 17, NULL,'Desmuntatge de portes antigues',        '2024-05-15', '2024-05-16', 2, TRUE, 'finalitzada'),
(53, 17, 52,  'Instal·lació de portes noves',          '2024-06-01', '2024-06-03', 2, TRUE, 'finalitzada'),

(54, 18, NULL,'Muntatge de prestatgeries fixes',       '2024-08-02', NULL,         3, TRUE, 'en_curs'),
(55, 18, 54,  'Ancoratge de mobiliari a paret',        '2024-08-03', NULL,         2, TRUE, 'en_curs');

SELECT setval(
  'tasca_id_seq',
  (SELECT MAX(id) FROM tasca)
);
/* ───────────────────────────────
   TASCA_TREBALLADOR (igual concept)
   ─────────────────────────────── */
INSERT INTO tasca_treballador (id_tasca, id_treballador, comentari) VALUES
  (1, 1, 'Supervisó general'),
  (2, 2, NULL),
  (3, 3, 'Tasca assignada pel responsable'),
  (4, 25, 'Demolició principal'),
  (5, 8, 'Retirada i càrrega de runa'),
  (6, 20, 'Execució instal·lació elèctrica'),
  (7, 20, 'Canalitzacions elèctriques'),
  (8, 20, 'Cablejat interior'),

  (9, 15, 'Excavació amb maquinària'),
  (10, 26, 'Compactació i nivellació'),
  (11, 24, 'Muntatge de bastida'),
  (12, 19, 'Revisió de seguretat i ancoratges'),

  (13, 28, 'Tall de paviment'),
  (14, 33, 'Retirada de peces i neteja'),
  (15, 22, 'Preparació de base granular'),

  (16, 25, 'Demolició interior'),
  (17, 21, 'Desmuntatge sanitari'),
  (18, 29, 'Substitució de paviment'),
  (19, 16, 'Anivellat i control d’execució'),

  (20, 19, 'Replanteig general'),
  (21, 16, 'Marcatge de divisòries'),
  (22, 9, 'Instal·lació fals sostre'),
  (23, 32, 'Perfileria metàl·lica de suport'),

  (24, 14, 'Picat de revestiment'),
  (25, 8, 'Neteja de superfície'),
  (26, 30, 'Aplicació de morter'),

  (27, 15, 'Moviment inicial de terres'),
  (28, 26, 'Compactació del terreny'),
  (29, 4, 'Execució de fonamentació'),
  (30, 5, 'Col·locació de ferralla'),

  (31, 15, 'Obertura de rasa'),
  (32, 21, 'Col·locació de drenatge'),
  (33, 28, 'Reposició de paviment'),

  (34, 25, 'Desmuntatge de mobiliari i cuines'),
  (35, 8, 'Retirada d’electrodomèstics'),
  (36, 7, 'Pintura interior'),

  (37, 15, 'Excavació per ampliació'),
  (38, 26, 'Formació de rampa'),
  (39, 32, 'Muntatge d’estructura metàl·lica'),
  (40, 13, 'Soldadura d’estructura'),

  (41, 33, 'Desbrossament manual'),
  (42, 8, 'Retirada de pedres'),
  (43, 22, 'Estesa de capa granular'),

  (44, 25, 'Enderroc interior'),
  (45, 33, 'Recollida selectiva de residus'),
  (46, 17, 'Col·locació d’enrajolat'),
  (47, 31, 'Tall de peces especials'),

  (48, 1, 'Replanteig de recorreguts'),
  (49, 15, 'Excavació per reg'),
  (50, 24, 'Col·locació de mobiliari urbà'),

  (51, 10, 'Reforç estructural amb fusta'),
  (52, 27, 'Tractament protector'),
  (53, 27, 'Reposició de coberta'),

  (54, 29, 'Execució de vorades'),
  (55, 21, 'Drenatge i rigoles');
/* ───────────────────────────────
   CONFIGURACIO (abans id_usuari)
   ─────────────────────────────── */
INSERT INTO configuracio
(id, id_empresa, id_treballador, idioma, acceptacio_terms, imatge_perfil) VALUES
  (1,  NULL, 1,  'ca', TRUE, NULL),
  (2,  NULL, 2,  'es', TRUE, 'https://avatar.com/marta.png'),
  (3,  1,    NULL, 'ca', TRUE, 'https://avatar.com/alzina.jpg'),
  (4,  NULL, 3,  'ca', TRUE, NULL),
  (5,  NULL, 4,  'ca', TRUE, NULL),
  (6,  NULL, 5,  'es', TRUE, NULL),
  (7,  NULL, 6,  'es', TRUE, NULL),
  (8,  NULL, 7,  'ca', TRUE, 'https://avatar.com/aina.png'),
  (9,  NULL, 8,  'ca', TRUE, NULL),
  (10, NULL, 9,  'es', TRUE, NULL),
  (11, NULL, 10, 'ca', TRUE, NULL),
  (12, NULL, 11, 'ca', TRUE, NULL),
  (13, NULL, 12, 'es', TRUE, NULL),
  (14, NULL, 13, 'ca', TRUE, NULL),
  (15, NULL, 14, 'ca', TRUE, NULL),
  (16, NULL, 15, 'es', TRUE, 'https://avatar.com/damia.png'),
  (17, NULL, 16, 'ca', TRUE, NULL),
  (18, NULL, 17, 'ca', TRUE, NULL),
  (19, NULL, 18, 'es', TRUE, NULL),
  (20, NULL, 19, 'ca', TRUE, 'https://avatar.com/miquel.png'),
  (21, NULL, 20, 'es', TRUE, NULL),
  (22, NULL, 21, 'ca', TRUE, NULL),
  (23, NULL, 22, 'ca', TRUE, NULL),
  (24, NULL, 23, 'es', TRUE, NULL),
  (25, NULL, 24, 'es', TRUE, NULL),
  (26, NULL, 25, 'ca', TRUE, NULL),
  (27, NULL, 26, 'ca', TRUE, NULL),
  (28, NULL, 27, 'es', TRUE, NULL),
  (29, NULL, 28, 'es', TRUE, NULL),
  (30, NULL, 29, 'ca', TRUE, NULL),
  (31, NULL, 30, 'ca', TRUE, NULL),
  (32, NULL, 31, 'es', TRUE, NULL),
  (33, NULL, 32, 'ca', TRUE, NULL),
  (34, NULL, 33, 'ca', TRUE, NULL),
  (35, 2, NULL, 'es', TRUE, 'https://avatar.com/serveisintegrals.jpg'),
  (36, 3, NULL, 'ca', TRUE, 'https://avatar.com/mallorcaobres.jpg'),
  (37, 4, NULL, 'ca', TRUE, 'https://avatar.com/menorcaprojectes.jpg'),
  (38, 5, NULL, 'es', TRUE, 'https://avatar.com/eivissainfra.jpg'),
  (39, 6, NULL, 'ca', TRUE, 'https://avatar.com/formenterarehab.jpg');

/* ─────────────────────────────
   CONTRASENYA (abans id_usuari)
   ───────────────────────────── */
INSERT INTO contrasenya
(id, id_treballador, id_empresa, clau, data_creacio, data_reemplas) VALUES
  (1,  NULL, 1,  'Alzina',              '2024-06-01 09:31:00', NULL),
  (2,  NULL, 2,  'servintMallorca',     '2024-06-03 10:02:00', NULL),
  (3,  2,    NULL, 'viscaElBarça',      '2024-05-22 10:02:00', NULL),
  (4,  1,    NULL, '12345678',          '2024-08-19 10:02:00', NULL),
  (5,  3,    NULL, '12345678',          '2024-09-02 10:02:00', NULL),
  (6,  NULL, 3,  'MallorcaObres2024',   '2024-06-05 09:00:00', NULL),
  (7,  NULL, 4,  'MenorcaTec2024',      '2024-06-06 09:10:00', NULL),
  (8,  NULL, 5,  'EivissaInfra2024',    '2024-06-07 09:20:00', NULL),
  (9,  NULL, 6,  'FormenteraRehab24',   '2024-06-08 09:30:00', NULL),
  (10, 4,   NULL, 'encofrat44',         '2024-06-05 08:30:00', NULL),
  (11, 5,   NULL, 'ferralla55',         '2024-06-05 08:45:00', NULL),
  (12, 6,   NULL, 'gruaTorre6',         '2024-06-07 09:00:00', NULL),
  (13, 7,   NULL, 'pintura77',          '2024-06-10 08:15:00', NULL),
  (14, 8,   NULL, 'peo2024',            '2024-06-10 08:20:00', NULL),
  (15, 9,   NULL, 'pladur99',           '2024-06-11 09:10:00', NULL),
  (16, 10,  NULL, 'fusta1010',          '2024-06-12 08:50:00', NULL),
  (17, 11,  NULL, 'pedra1111',          '2024-06-12 09:05:00', NULL),
  (18, 12,  NULL, 'manobre12',          '2024-06-13 08:40:00', NULL),
  (19, 13,  NULL, 'solda1313',          '2024-06-13 09:20:00', NULL),
  (20, 14,  NULL, 'picapedra14',        '2024-06-14 08:35:00', NULL),
  (21, 15,  NULL, 'excava1515',         '2024-06-15 09:00:00', NULL),
  (22, 16,  NULL, 'oficial16',          '2024-06-17 08:30:00', NULL),
  (23, 17,  NULL, 'rajola1717',         '2024-06-17 08:45:00', NULL),
  (24, 18,  NULL, 'guix1818',           '2024-06-18 09:10:00', NULL),
  (25, 19,  NULL, 'mestre1919',         '2024-06-18 09:30:00', NULL),
  (26, 20,  NULL, 'cable2020',          '2024-06-19 08:25:00', NULL),
  (27, 21,  NULL, 'lampista21',         '2024-06-19 08:40:00', NULL),
  (28, 22,  NULL, 'formigo2222',        '2024-06-20 09:00:00', NULL),
  (29, 23,  NULL, 'aillament23',        '2024-06-20 09:15:00', NULL),
  (30, 24,  NULL, 'bastida2424',        '2024-06-21 08:50:00', NULL),
  (31, 25,  NULL, 'demo2525',           '2024-06-21 09:05:00', NULL),
  (32, 26,  NULL, 'compacta26',         '2024-06-24 08:30:00', NULL),
  (33, 27,  NULL, 'coberta2727',        '2024-06-24 08:45:00', NULL),
  (34, 28,  NULL, 'asfalt2828',         '2024-06-25 09:00:00', NULL),
  (35, 29,  NULL, 'paviment29',         '2024-06-25 09:10:00', NULL),
  (36, 30,  NULL, 'paleta3030',         '2024-06-26 08:40:00', NULL),
  (37, 31,  NULL, 'tall3131',           '2024-06-26 08:55:00', NULL),
  (38, 32,  NULL, 'metal3232',          '2024-06-27 09:05:00', NULL),
  (39, 33,  NULL, 'peo3333',            '2024-06-27 09:20:00', NULL);

  SELECT setval('contrasenya_id_seq', (SELECT MAX(id) FROM contrasenya));
/* ───────────────────────────
   DOCUMENT_OBRA (coherent ara)
   ─────────────────────────── */
INSERT INTO document_obra
    (id_obra, id_creador, path_doc, format, mida, comentari, tipus)
VALUES
    (1, 1, 'documents_obra/obra_1/plano_fonament.pdf',
        'PDF',  2.30, 'Plànol fonaments',     'Pla'),

    (2, 2, 'documents_obra/obra_2/certificat_energia.pdf',
        'PDF',  0.70, 'Certificat energètic', 'Informe'),

    (3, 1, 'documents_obra/obra_3/pressupost_final.xlsx',
        'XLSX', 0.20, 'Pressupost final',     'Pressupost');
/* ────────────────
   INCIDENCIA (igual)
   ──────────────── */
INSERT INTO incidencia (id_obra, id_tasca, descripcio, data_inici, data_fi, criticitat, prioritat, categoria, estat) VALUES
  (1, 1,   'Retard subministrament formigó', '2024-07-04', NULL,          3, 2, 1, 'OBERTA'),
  (2, 2,   'Problema humitat parets',        '2024-06-20', NULL,          4, 1, 2, 'OBERTA'),
  (3, 3,   'Endarreriment subministrament totxos', '2024-04-17', '2024-04-20', 2, 1, 3, 'TANCADA'),
  (1, 6,   'Tall temporal de subministrament elèctric a zona d’obra',      '2024-07-10', NULL,         3, 2, 2, 'OBERTA'),
  (1, 4,   'Excés de runa acumulada a l’accés principal',                   '2024-07-06', '2024-07-07', 2, 3, 4, 'TANCADA'),
  (2, 11,  'Desajust en un mòdul de bastida detectat a inspecció',          '2024-05-26', '2024-05-27', 5, 1, 4, 'TANCADA'),
  (2, 9,   'Aparició de roca dura durant l’excavació',                      '2024-05-23', NULL,         4, 1, 1, 'OBERTA'),
  (3, 15,  'Base de grava insuficient a un tram de paviment',               '2024-04-09', '2024-04-11', 3, 2, 3, 'TANCADA'),
  (4, 16,  'Presència de canonada antiga no prevista en demolició',         '2024-06-17', '2024-06-19', 4, 1, 2, 'TANCADA'),
  (4, 18,  'Diferències de nivell al paviment interior',                    '2024-06-24', NULL,         3, 2, 3, 'OBERTA'),
  (5, 22,  'Retard en l’arribada de plaques per al fals sostre',            '2024-07-12', NULL,         2, 2, 1, 'OBERTA'),
  (5, 20,  'Error de replanteig a una de les divisòries',                   '2024-07-03', '2024-07-04', 3, 1, 3, 'TANCADA'),
  (6, 26,  'Assecat irregular del morter en façana nord',                   '2024-05-22', '2024-05-25', 3, 2, 3, 'TANCADA'),
  (7, 29,  'Manca parcial de ferralla prevista per a fonamentació',         '2024-09-08', NULL,         4, 1, 1, 'OBERTA'),
  (7, 27,  'Compactació inicial per sota dels valors requerits',            '2024-09-05', NULL,         4, 1, 3, 'OBERTA'),
  (8, 32,  'Filtració d’aigua a rasa oberta després de pluja intensa',      '2024-06-09', '2024-06-12', 4, 1, 2, 'TANCADA'),
  (9, 36,  'Diferència de to entre lots de pintura interior',               '2024-06-14', '2024-06-16', 2, 3, 3, 'TANCADA'),
  (10, 39, 'Retard en el muntatge per avaria d’equip d’elevació',           '2024-08-23', NULL,         3, 2, 5, 'OBERTA'),
  (11, 43, 'Material granular amb humitat excessiva',                       '2024-04-02', '2024-04-04', 3, 2, 1, 'TANCADA'),
  (12, 46, 'Algunes peces d’enrajolat han arribat trencades',               '2024-08-07', NULL,         2, 2, 1, 'OBERTA'),
  (13, 49, 'Rasa de reg afecta una conducció existent no planificada',      '2024-06-02', '2024-06-05', 5, 1, 2, 'TANCADA'),
  (14, 53, 'Entrada d’aigua per coberta abans de finalitzar el segellat',   '2024-07-10', NULL,         5, 1, 2, 'OBERTA');

INSERT INTO log_de_sessio
(id, id_treballador, id_empresa, data_inici, hora_inici) VALUES
  (1, NULL, 1, '2024-07-01', '08:30:00'),  -- Construccions Alzina
  (2, NULL, 2, '2024-07-02', '09:00:00'),  -- Serveis Integrals
  (3, NULL, 1, '2024-07-03', '11:15:00');  -- Nova sessió d’Alzina

-- Ajust de seqüència perquè no hi hagi conflictes amb futurs inserts
SELECT setval('log_de_sessio_id_seq', (SELECT MAX(id) FROM log_de_sessio));


/* ─────────────
   PERMIS (igual)
   ───────────── */
INSERT INTO permis (clau_funcional, descripcio) VALUES
  ('ADMIN',          'Accés complet al sistema'),
  ('GESTIO_OBRA',    'Gestió obres i recursos'),
  ('VISUALITZACIO',  'Només visualització'),
  ('GESTIO_TASQUES',       'Crear, assignar i actualitzar tasques'),
  ('GESTIO_INCIDENCIES',   'Crear i gestionar incidències d’obra'),
  ('GESTIO_RECURSOS',      'Gestionar materials, eines i maquinària'),
  ('GESTIO_TREBALLADORS',  'Gestionar fitxes i dades de treballadors'),
  ('GESTIO_EMPRESA',       'Gestionar dades generals de l’empresa'),
  ('ASSIGNACIO_PERSONAL',  'Assignar treballadors a obres i tasques'),
  ('RESPONSABLE_OBRA',     'Funcions de responsable o encarregat d’obra'),
  ('CONTROL_ESTOC',        'Consultar i actualitzar estoc de recursos'),
  ('REGISTRE_HORES',       'Registrar hores o dedicació a tasques'),
  ('VALIDACIO_TASQUES',    'Validar o donar per completades tasques'),
  ('TANCAMENT_INCIDENCIES','Resoldre i tancar incidències'),
  ('CONSULTA_COSTOS',      'Consultar pressuposts, costos i desviacions'),
  ('GESTIO_DOCUMENTS',     'Pujar, consultar i gestionar documents'),
  ('SIGNATURA_PARTS',      'Validar o signar parts d’obra o actuacions'),
  ('CONFIGURACIO',         'Modificar configuracions de compte o empresa'),
  ('GESTIO_PERMISOS',      'Assignar permisos i rols funcionals'),
  ('ACCES_MAQUINARIA',     'Registrar ús i estat de maquinària'),
  ('PLANIFICACIO',         'Planificar calendari i seqüència d’obra'),
  ('LECTURA_INCIDENCIES',  'Consultar incidències sense editar-les'),
  ('LECTURA_TASQUES',      'Consultar tasques sense modificar-les');

/* ──────────────────────────────
   PERMIS_TREBALLADOR (abans _usuari)
   ────────────────────────────── */
INSERT INTO permis_treballador
(id, id_treballador, id_permis, lectura, escriptura, edicio, data_creacio, data_modif) VALUES
  (1, 1, 1, TRUE, TRUE, TRUE,  '2024-06-01 09:35:00', NULL),
  (2, 2, 2, TRUE, TRUE, FALSE, '2024-06-03 10:10:00', NULL),
  (3, 3, 3, TRUE, FALSE, FALSE,'2024-05-21 13:15:00', NULL),
  (4, 4, 2, TRUE, TRUE, FALSE,  '2024-06-05 08:30:00', NULL),
  (5, 5, 2, TRUE, TRUE, FALSE,  '2024-06-05 08:45:00', NULL),
  (6, 6, 2, TRUE, TRUE, FALSE,  '2024-06-07 09:00:00', NULL),
  (7, 7, 2, TRUE, TRUE, FALSE,  '2024-06-10 08:15:00', NULL),
  (8, 8, 3, TRUE, FALSE, FALSE, '2024-06-10 08:20:00', NULL),
  (9, 9, 2, TRUE, TRUE, FALSE,  '2024-06-11 09:10:00', NULL),
  (10, 10, 2, TRUE, TRUE, FALSE, '2024-06-12 08:50:00', NULL),
  (11, 11, 2, TRUE, TRUE, FALSE, '2024-06-12 09:05:00', NULL),
  (12, 12, 3, TRUE, FALSE, FALSE, '2024-06-13 08:40:00', NULL),
  (13, 13, 2, TRUE, TRUE, FALSE, '2024-06-13 09:20:00', NULL),
  (14, 14, 2, TRUE, TRUE, FALSE, '2024-06-14 08:35:00', NULL),
  (15, 15, 2, TRUE, TRUE, FALSE, '2024-06-15 09:00:00', NULL),
  (16, 16, 2, TRUE, TRUE, TRUE,  '2024-06-17 08:30:00', NULL),
  (17, 17, 2, TRUE, TRUE, FALSE, '2024-06-17 08:45:00', NULL),
  (18, 18, 2, TRUE, TRUE, FALSE, '2024-06-18 09:10:00', NULL),
  (19, 19, 1, TRUE, TRUE, TRUE,  '2024-06-18 09:30:00', NULL),
  (20, 20, 2, TRUE, TRUE, FALSE, '2024-06-19 08:25:00', NULL),
  (21, 21, 2, TRUE, TRUE, FALSE, '2024-06-19 08:40:00', NULL),
  (22, 22, 2, TRUE, TRUE, FALSE, '2024-06-20 09:00:00', NULL),
  (23, 23, 2, TRUE, TRUE, FALSE, '2024-06-20 09:15:00', NULL),
  (24, 24, 2, TRUE, TRUE, FALSE, '2024-06-21 08:50:00', NULL),
  (25, 25, 3, TRUE, FALSE, FALSE, '2024-06-21 09:05:00', NULL),
  (26, 26, 2, TRUE, TRUE, FALSE, '2024-06-24 08:30:00', NULL),
  (27, 27, 2, TRUE, TRUE, FALSE, '2024-06-24 08:45:00', NULL),
  (28, 28, 2, TRUE, TRUE, FALSE, '2024-06-25 09:00:00', NULL),
  (29, 29, 2, TRUE, TRUE, FALSE, '2024-06-25 09:10:00', NULL),
  (30, 30, 2, TRUE, TRUE, FALSE, '2024-06-26 08:40:00', NULL),
  (31, 31, 3, TRUE, FALSE, FALSE, '2024-06-26 08:55:00', NULL),
  (32, 32, 2, TRUE, TRUE, FALSE, '2024-06-27 09:05:00', NULL),
  (33, 33, 3, TRUE, FALSE, FALSE, '2024-06-27 09:20:00', NULL);
/* ──────────────
   RECURS (igual)
   ────────────── */
INSERT INTO recurs (nom, unitats_mesura, quantitat_stock, tipus_recurs) VALUES
  ('Formigó',          'm3',      40,    'Material'),
  ('Grua torre',       'unitats', 2,     'Maquinària'),
  ('Totxos ceràmics',  'unitats', 10000, 'Material'),
  ('Ciment Portland',              'kg',       12000, 'Material'),
  ('Arena fina',                   'm3',       85,    'Material'),
  ('Grava',                        'm3',       70,    'Material'),
  ('Acer corrugat',                'kg',       9500,  'Material'),
  ('Mallazo electrosoldat',        'unitats',  140,   'Material'),
  ('Morter preparat',              'sacs',     600,   'Material'),
  ('Guix',                         'sacs',     320,   'Material'),
  ('Pladur',                       'plaques',  450,   'Material'),
  ('Aïllament tèrmic',             'm2',       900,   'Material'),
  ('Aïllament acústic',            'm2',       650,   'Material'),
  ('Rajoles gres',                 'm2',       700,   'Material'),
  ('Paviment porcelànic',          'm2',       520,   'Material'),
  ('Pintura plàstica blanca',      'litres',   420,   'Material'),
  ('Pintura exterior',             'litres',   260,   'Material'),
  ('Imprimació',                   'litres',   140,   'Material'),
  ('Silicona segelladora',         'cartutxos',180,   'Material'),
  ('Escuma de poliuretà',          'unitats',  95,    'Material'),
  ('Bigues de fusta',              'unitats',  75,    'Material'),
  ('Taulons d’encofrat',           'unitats',  210,   'Material'),
  ('Tub PVC sanejament',           'metres',   1500,  'Material'),
  ('Tub corrugat elèctric',        'metres',   2200,  'Material'),
  ('Cable elèctric 3x2.5',         'metres',   1800,  'Material'),
  ('Caixes d’empalme',             'unitats',  160,   'Material'),
  ('Interruptors',                 'unitats',  120,   'Material'),
  ('Endolls',                      'unitats',  145,   'Material'),
  ('Sanitaris',                    'unitats',  18,    'Material'),
  ('Aixetes',                      'unitats',  36,    'Material'),
  ('Portes interiors',             'unitats',  42,    'Material'),
  ('Finestres alumini',            'unitats',  28,    'Material'),
  ('Vidre laminat',                'm2',       110,   'Material'),
  ('Bastida modular',              'm2',       380,   'Maquinària'),
  ('Formigonera',                  'unitats',  4,     'Maquinària'),
  ('Excavadora',                   'unitats',  3,     'Maquinària'),
  ('Miniexcavadora',               'unitats',  2,     'Maquinària'),
  ('Camió bolquet',                'unitats',  3,     'Maquinària'),
  ('Compactadora',                 'unitats',  2,     'Maquinària'),
  ('Martell pneumàtic',            'unitats',  6,     'Maquinària'),
  ('Talladora radial gran',        'unitats',  7,     'Maquinària'),
  ('Generador elèctric',           'unitats',  3,     'Maquinària'),
  ('Soldadora elèctrica',          'unitats',  4,     'Maquinària'),
  ('Carretó elevador',             'unitats',  2,     'Maquinària'),
  ('Plataforma elevadora',         'unitats',  2,     'Maquinària'),
  ('Trepant percutor',             'unitats',  12,    'Eina'),
  ('Atornilladora elèctrica',      'unitats',  15,    'Eina'),
  ('Nivell làser',                 'unitats',  5,     'Eina'),
  ('Paleta de mà',                 'unitats',  40,    'Eina'),
  ('Pales',                        'unitats',  25,    'Eina'),
  ('Picoles',                      'unitats',  18,    'Eina'),
  ('Carretons d’obra',             'unitats',  14,    'Eina'),
  ('Escales extensibles',          'unitats',  9,     'Eina');

/* ────────────────────────────────
   RESPONSABLE_OBRA (coherent ara)
   ──────────────────────────────── */
INSERT INTO responsable_obra (id_obra, id_treballador, data_inici, data_fi) VALUES
  (1, 1,  '2024-07-01', NULL),
  (2, 2,  '2024-05-20', NULL),
  (3, 1,  '2024-04-01', '2024-07-15'),
  (4, 19, '2024-06-15', NULL),
  (5, 16, '2024-07-01', NULL),
  (6, 1,  '2024-05-10', '2024-08-20'),
  (7, 19, '2024-09-01', NULL),
  (8, 2,  '2024-06-05', NULL),
  (9, 16, '2024-04-20', '2024-08-28'),
  (10, 19, '2024-08-12', NULL),
  (11, 2,  '2024-03-18', '2024-06-25'),
  (12, 1,  '2024-07-22', NULL),
  (13, 16, '2024-05-27', NULL),
  (14, 19, '2024-06-03', NULL),
  (15, 1,  '2024-09-15', NULL),
  (16, 2,  '2024-10-01', NULL),
  (17, 16, '2024-05-14', '2024-09-18'),
  (18, 19, '2024-08-01', NULL);

/* ────────────────
   SOL_RECURS (igual)
   ──────────────── */
INSERT INTO sol_recurs
(id_obra, id_empresa, id_recurs, quantitat, data_necessitat, comentari, data_entrega, data_creacio, proveidor, id_treballador, estat) VALUES
  (1, 1, 1,  15,   '2024-07-02', 'Necessari per fonaments', NULL,         '2024-06-25 08:00:00', 'Formigons Balears',        1, 'pendent'),
  (2, 2, 2,   1,   '2024-06-10', 'Per començar estructura', '2024-06-12', '2024-06-01 10:00:00', 'Maquinària Mallorquina',  2, 'aprovada'),
  (3, 1, 3, 5000,  '2024-04-15', 'Primera fase obra',       '2024-04-16', '2024-04-10 09:00:00', 'Totxos SA',                3, 'aprovada'),
  (1, 1, 4, 1200,  '2024-07-06', 'Acer per reforç estructural interior', '2024-07-05', '2024-07-01 08:15:00', 'Aceros Mallorca', 1, 'aprovada'),
  (1, 1, 6,   80,  '2024-07-07', 'Morter per envans i reparacions', NULL, '2024-07-02 09:00:00', 'Materials Serra',          NULL, 'pendent'),

  (4, 1, 8,   60,  '2024-06-22', 'Plaques per divisòries noves', '2024-06-21', '2024-06-18 10:20:00', 'Pladur Illes',       4, 'aprovada'),
  (4, 1, 24,  20,  '2024-06-25', 'Interruptors per banys reformats', NULL, '2024-06-19 11:10:00', 'Electricitat Balear',     NULL, 'pendent'),

  (5, 2, 8,  140,  '2024-07-11', 'Plaques per sostres i divisions interiors', '2024-07-10', '2024-07-04 08:30:00', 'Pladur Illes', 2, 'aprovada'),
  (5, 2, 23,  35,  '2024-07-08', 'Caixes d’empalme per aules noves', '2024-07-07', '2024-07-03 09:15:00', 'Subministres Tècnics', 2, 'aprovada'),

  (6, 3, 14, 110,  '2024-05-20', 'Pintura exterior per façana principal', '2024-05-19', '2024-05-15 08:45:00', 'Pintures Mediterrània', 5, 'aprovada'),
  (6, 3, 31, 120,  '2024-05-12', 'Bastida per rehabilitació de façana', '2024-05-11', '2024-05-08 12:00:00', 'Lloguers Bastida', 5, 'aprovada'),

  (7, 1, 1,   90,  '2024-09-08', 'Formigó per sabates i fonamentació', NULL, '2024-09-02 08:00:00', 'Formigons Balears', 1, 'pendent'),
  (7, 1, 4, 2200,  '2024-09-07', 'Ferralla per estructura de fonament', '2024-09-06', '2024-09-03 09:40:00', 'Aceros Mallorca', 1, 'aprovada'),

  (8, 4, 20, 300,  '2024-06-08', 'Tub PVC per drenatge principal', '2024-06-07', '2024-06-05 08:20:00', 'Canalitzacions Maó', 6, 'aprovada'),
  (8, 4, 33,   1,  '2024-06-06', 'Excavadora per rasa principal', '2024-06-06', '2024-06-02 10:00:00', 'Maquinària Mallorquina', 6, 'aprovada'),

  (9, 4, 13, 180,  '2024-06-10', 'Pintura blanca per apartaments', '2024-06-09', '2024-06-01 09:00:00', 'Pintures Mediterrània', 6, 'aprovada'),
  (9, 4, 28,  12,  '2024-05-02', 'Portes interiors per habitatges reformats', NULL, '2024-04-27 08:50:00', 'Fusteria Levante', NULL, 'rebutjada'),

  (10, 3, 40, 1,   '2024-08-23', 'Soldadora per estructura metàl·lica', '2024-08-22', '2024-08-18 11:30:00', 'Industrial Solda', 5, 'aprovada'),
  (10, 3, 35, 1,   '2024-08-20', 'Camió bolquet per retirada de terres', '2024-08-20', '2024-08-14 07:45:00', 'Transports Illes', 5, 'aprovada'),

  (11, 2, 3,  35,  '2024-04-01', 'Grava per millora del ferm del camí', '2024-03-30', '2024-03-25 10:10:00', 'Àrids Tramuntana', 2, 'aprovada'),
  (11, 2, 49, 6,   '2024-03-19', 'Carretons per suport a brigada', '2024-03-18', '2024-03-16 08:00:00', 'Eines i Obra SL', 2, 'aprovada'),

  (12, 1, 11, 140, '2024-08-05', 'Rajoles per local comercial', NULL, '2024-07-28 09:35:00', 'Ceràmiques Palma', NULL, 'pendent'),
  (12, 1, 16, 25,  '2024-07-30', 'Silicona de remat i juntes', '2024-07-29', '2024-07-24 08:25:00', 'Materials Serra', 1, 'aprovada'),

  (13, 5, 50, 10,  '2024-08-10', 'Escales per muntatge de mobiliari urbà', '2024-08-09', '2024-08-02 09:20:00', 'Eines i Obra SL', 7, 'aprovada'),
  (13, 5, 9,  300, '2024-06-01', 'Aïllament per elements de jardineria tècnica', NULL, '2024-05-29 10:00:00', 'Aïllaments Balears', NULL, 'pendent'),

  (14, 6, 18, 20,  '2024-06-05', 'Bigues de fusta per reforç interior', '2024-06-04', '2024-06-01 08:40:00', 'Fustes Sóller', 8, 'aprovada'),
  (14, 6, 29, 8,   '2024-07-03', 'Finestres d’alumini per rehabilitació', NULL, '2024-06-25 11:15:00', 'Aluminis Costa', NULL, 'pendent'),

  (15, 5, 12, 260, '2024-10-02', 'Paviment porcelànic per aparcament', NULL, '2024-09-24 09:05:00', 'Paviments Balears', NULL, 'pendent');
   
   
   /*SOLUCIO (igual)
  ─────────────────*/
  INSERT INTO solucio (id_incidencia, id_tasca, descripcio, cost_monetari, eficacia, cost_temporal, impacte) VALUES
    (1, 1,   'Canvi de proveïdor formigó',         500, 4, 5, 6),
    (2, NULL,'Reparació i segellat parets',       1200, 5, 8, 7),
    (3, 3,   'Demora acceptada; ampliació termini',   0, 3, 2, 4),
    (3, 3,    'Demora acceptada; ampliació termini',                     0,    3,  2, 4),
    (5, 4,    'Retirada de runa i habilitació de contenidor extra',      180, 1, 49, 1),
    (6, 11,   'Reajust i reforç dels ancoratges de bastida',             350, 1, 31, 19),
    (8, 15,   'Aportació extra de grava i recompactició del tram',       420, 2, 5, 2),
    (9, 16,   'Desviament de canonada i actualització del replanteig',   650, 5, 20, 19),
    (11, 20,  'Correcció de replanteig i remarcació de divisòries',      140, 4, 45, 16),
    (12, 26,  'Reaplicació de morter i protecció de la façana afectada', 390, 3, 6, 1),
    (15, 32,  'Buidatge de rasa, bombeig i reposició de drenatge',       560, 4, 20, 2),
    (16, 36,  'Repintat complet amb un únic lot de pintura',             275, 5, 13, 16),
    (18, 43,  'Substitució del material granular i estesa controlada',   460, 3, 3, 2),
    (20, 49,  'Desviament de conducció existent i protecció del traçat', 980, 4, 33, 16);
    SELECT setval(
    'registre_horari_id_seq',
    (SELECT MAX(id) FROM registre_horari)
  );

/* ─────────────────────────
   VERIFICACIO (abans id_usuari)
   ───────────────────────── */
INSERT INTO verificacio
(id_empresa, estat_ver, data_ver, token_verificacio, data_token) VALUES
  (1, 'OK',      '2024-06-02', 'token_alzina_123',        '2024-06-01 10:00:00'),
  (2, 'PENDENT', NULL,         'token_servint_456',       '2024-06-03 11:00:00'),
  (3, 'OK',      '2024-06-06', 'token_mallorcaobres_789', '2024-06-05 09:30:00'),
  (4, 'OK',      '2024-06-07', 'token_menorca_321',       '2024-06-06 12:15:00'),
  (5, 'PENDENT', NULL,         'token_eivissa_654',       '2024-06-07 16:40:00'),
  (6, 'OK',      '2024-06-09', 'token_formentera_987',    '2024-06-08 08:50:00');   
  SELECT setval(
  'verificacio_id_seq',
  (SELECT MAX(id_empresa) FROM verificacio)
);


INSERT INTO registre_horari
(id, id_treballador, id_obra, data_entrada, data_sortida) VALUES
  (1, 1, 1, '2026-04-28 07:55:00+02', '2026-04-28 16:10:00+02'),
  (2, 2, 1, '2026-04-28 08:03:00+02', '2026-04-28 15:58:00+02'),
  (3, 1, 2, '2026-04-29 07:50:00+02', '2026-04-29 16:05:00+02'),
  (4, 3, 2, '2026-04-30 08:00:00+02', NULL);


/* Sincronitza la seqüència si has inserit IDs manualment */
SELECT setval(
  'registre_horari_id_seq',
  (SELECT MAX(id) FROM registre_horari)
);


/* (Opcional però recomanat si has fixat IDs manualment)
SELECT setval('empresa_id_empresa_seq',      (SELECT MAX(id_empresa) FROM empresa));
SELECT setval('treballador_id_seq',          (SELECT MAX(id) FROM treballador));
SELECT setval('configuracio_id_seq',         (SELECT MAX(id) FROM configuracio));
SELECT setval('contrasenya_id_seq',          (SELECT MAX(id) FROM contrasenya));
SELECT setval('permis_treballador_id_seq',   (SELECT MAX(id) FROM permis_treballador));
SELECT setval('verificacio_id_seq',          (SELECT MAX(id) FROM verificacio));
*/

INSERT INTO contracte_treballador
(id, id_treballador, id_empresa, data_contracte, data_fi, salari, carrec, categoria_professional, nss, formacions, estat) VALUES
  (1, 1, 1, '2024-06-01', NULL,         24000.00, 'Mestre Obra', 'Obrer', 'SS0001', 'PRL 60h', 'actiu'),
  (2, 2, 2, '2024-06-03', NULL,         22000.00, 'Oficial 1a', 'Obrer', 'SS0002', 'Carretó elevador', 'actiu'),
  (3, 3, 1, '2024-05-22', '2024-09-02', 18000.00, 'Peó', 'Obrer', 'SS0003', 'Formació bàsica', 'baixa'),
  (4, 4, 1, '2024-06-05', NULL,         21500.00, 'Encofrador', 'Obrer', 'SS0004', 'PRL 20h encofrats', 'actiu'),
  (5, 5, 1, '2024-06-05', NULL,         22500.00, 'Ferrallista', 'Obrer', 'SS0005', 'PRL ferralla', 'actiu'),
  (6, 6, 5, '2024-06-07', NULL,         26000.00, 'Gruista', 'Obrer', 'SS0006', 'Carnet grua', 'actiu'),
  (7, 7, 3, '2024-06-10', NULL,         20500.00, 'Pintora', 'Obrer', 'SS0007', 'Treballs en altura', 'actiu'),
  (8, 8, 3, '2024-06-10', NULL,         18000.00, 'Peó', 'Obrer', 'SS0008', 'Formació bàsica', 'actiu'),
  (9, 9, 3, '2024-06-11', NULL,         21000.00, 'Instal·lador Pladur', 'Obrer', 'SS0009', 'PRL interiors', 'actiu'),
  (10, 10, 6, '2024-06-12', NULL,       21200.00, 'Fustera', 'Obrer', 'SS0010', 'Maquinària de tall', 'actiu'),
  (11, 11, 1, '2024-06-12', NULL,       23000.00, 'Marger', 'Obrer', 'SS0011', 'Treballs de pedra', 'actiu'),
  (12, 12, 2, '2024-06-13', NULL,       18500.00, 'Manobre', 'Obrer', 'SS0012', 'Formació bàsica', 'actiu'),
  (13, 13, 4, '2024-06-13', NULL,       22000.00, 'Soldadora', 'Obrer', 'SS0013', 'Soldadura MIG/TIG', 'actiu'),
  (14, 14, 1, '2024-06-14', NULL,       22800.00, 'Picapedrer', 'Obrer', 'SS0014', 'Tall de pedra', 'actiu'),
  (15, 15, 5, '2024-06-15', NULL,       25000.00, 'Maquinista Excavadora', 'Obrer', 'SS0015', 'Carnet maquinària pesada', 'actiu'),
  (16, 16, 2, '2024-06-17', NULL,       22000.00, 'Oficial 1a', 'Obrer', 'SS0016', 'PRL 20h construcció', 'actiu'),
  (17, 17, 2, '2024-06-17', NULL,       21000.00, 'Enrajolador', 'Obrer', 'SS0017', 'Col·locació ceràmica', 'actiu'),
  (18, 18, 3, '2024-06-18', NULL,       20800.00, 'Guixaire', 'Obrer', 'SS0018', 'Acabats interiors', 'actiu'),
  (19, 19, 1, '2024-06-18', NULL,       24500.00, 'Mestre Obra', 'Obrer', 'SS0019', 'PRL 60h', 'actiu'),
  (20, 20, 4, '2024-06-19', NULL,       22300.00, 'Electricista d''obra', 'Obrer', 'SS0020', 'Baixa tensió', 'actiu'),
  (21, 21, 2, '2024-06-19', NULL,       22300.00, 'Lampista', 'Obrer', 'SS0021', 'Instal·lacions d''aigua', 'actiu'),
  (22, 22, 5, '2024-06-20', NULL,       20500.00, 'Formigoner', 'Obrer', 'SS0022', 'PRL estructures', 'actiu'),
  (23, 23, 6, '2024-06-20', NULL,       20600.00, 'Instal·ladora Aïllaments', 'Obrer', 'SS0023', 'Aïllaments tèrmics', 'actiu'),
  (24, 24, 5, '2024-06-21', NULL,       21200.00, 'Muntador Bastides', 'Obrer', 'SS0024', 'Muntatge de bastides', 'actiu'),
  (25, 25, 5, '2024-06-21', NULL,       19500.00, 'Operari Demolició', 'Obrer', 'SS0025', 'Demolició segura', 'actiu'),
  (26, 26, 5, '2024-06-24', NULL,       23800.00, 'Maquinista Compactadora', 'Obrer', 'SS0026', 'Carnet compactadora', 'actiu'),
  (27, 27, 6, '2024-06-24', NULL,       22000.00, 'Especialista Cobertes', 'Obrer', 'SS0027', 'Treballs en coberta', 'actiu'),
  (28, 28, 5, '2024-06-25', NULL,       21500.00, 'Asfaltador', 'Obrer', 'SS0028', 'Paviments bituminosos', 'actiu'),
  (29, 29, 2, '2024-06-25', NULL,       20800.00, 'Col·locadora Paviments', 'Obrer', 'SS0029', 'Paviments i revestiments', 'actiu'),
  (30, 30, 1, '2024-06-26', NULL,       21000.00, 'Paleta', 'Obrer', 'SS0030', 'PRL 20h construcció', 'actiu'),
  (31, 31, 3, '2024-06-26', NULL,       19800.00, 'Tallador Materials', 'Obrer', 'SS0031', 'Tall i manipulació de materials', 'actiu'),
  (32, 32, 4, '2024-06-27', NULL,       22400.00, 'Muntadora Estructures Metàl·liques', 'Obrer', 'SS0032', 'Muntatge metàl·lic', 'actiu'),
  (33, 33, 3, '2024-06-27', NULL,       18000.00, 'Peó', 'Obrer', 'SS0033', 'Formació bàsica', 'actiu');
-- Sincronitza la seqüència
SELECT setval('contracte_treballador_id_seq', (SELECT MAX(id) FROM contracte_treballador));

INSERT INTO notificacio (id_treballador, id_empresa, tipus, titol, missatge, entitat_id, entitat_tipus) VALUES
(1, NULL, 'nova_tasca', 'Nova tasca assignada', 'T’han assignat una nova tasca.', 101, 'tasca'),
(2, NULL, 'nova_tasca', 'Nova tasca assignada', 'T’han assignat una nova tasca a l’obra.', 102, 'tasca'),
(3, NULL, 'tasca_actualitzada', 'Tasca actualitzada', 'S’ha actualitzat una tasca assignada.', 103, 'tasca'),
(1, NULL, 'tasca_cancelada', 'Tasca cancel·lada', 'Una tasca assignada ha estat cancel·lada.', 104, 'tasca'),
(2, NULL, 'tasca_finalitzada', 'Tasca finalitzada', 'Una tasca s’ha marcat com a finalitzada.', 105, 'tasca'),
(3, NULL, 'tasca_validada', 'Tasca validada', 'L’empresa ha validat una tasca finalitzada.', 106, 'tasca'),
(1, NULL, 'tasca_rebutjada', 'Tasca retornada', 'Una tasca ha estat retornada per revisió.', 107, 'tasca'),
(2, NULL, 'sol_recurs_creada', 'Sol·licitud creada', 'S’ha creat una nova sol·licitud de recurs.', 201, 'sol_recurs'),
(3, NULL, 'sol_recurs_assignada', 'Recurs assignat', 'S’ha assignat un recurs a la teva sol·licitud.', 202, 'sol_recurs'),
(1, NULL, 'sol_recurs_aprovada', 'Sol·licitud aprovada', 'La teva sol·licitud de recurs ha estat aprovada.', 203, 'sol_recurs'),
(2, NULL, 'sol_recurs_rebutjada', 'Sol·licitud rebutjada', 'La teva sol·licitud de recurs ha estat rebutjada.', 204, 'sol_recurs'),
(3, NULL, 'recurs_entrega_propera', 'Entrega propera', 'Tens una entrega de recurs propera.', 205, 'recurs'),
(1, NULL, 'nova_incidencia', 'Nova incidència', 'S’ha registrat una nova incidència relacionada.', 301, 'incidencia'),
(2, NULL, 'incidencia_actualitzada', 'Incidència actualitzada', 'S’ha actualitzat una incidència existent.', 302, 'incidencia'),
(3, NULL, 'incidencia_tancada', 'Incidència tancada', 'Una incidència ha estat tancada.', 303, 'incidencia'),
(NULL, 1, 'nova_obra_assignada', 'Nova obra assignada', 'S’ha assignat una nova obra a l’empresa.', 401, 'obra'),
(NULL, 2, 'responsable_obra_assignat', 'Responsable assignat', 'S’ha assignat un responsable d’obra.', 402, 'obra'),
(NULL, 3, 'document_pujat', 'Document pujat', 'S’ha pujat un nou document a una obra.', 501, 'document'),
(NULL, 1, 'sortida_pendent', 'Sortida pendent', 'Hi ha una sortida pendent de gestionar.', 601, 'sortida'),
(NULL, 2, 'contracte_finalitza_properament', 'Contracte proper a finalitzar', 'Un contracte finalitza properament.', 701, 'contracte'),
(1, NULL, 'nova_tasca', 'Nova tasca assignada', 'Tens una nova tasca pendent de revisar.', 108, 'tasca'),
(2, NULL, 'tasca_actualitzada', 'Tasca modificada', 'La informació d’una tasca ha canviat.', 109, 'tasca'),
(3, NULL, 'tasca_validada', 'Tasca aprovada', 'La tasca enviada ha estat aprovada.', 110, 'tasca'),
(1, NULL, 'sol_recurs_aprovada', 'Recurs aprovat', 'S’ha aprovat el recurs sol·licitat.', 206, 'sol_recurs'),
(2, NULL, 'sol_recurs_rebutjada', 'Recurs rebutjat', 'No s’ha aprovat el recurs sol·licitat.', 207, 'sol_recurs'),
(NULL, 3, 'nova_incidencia', 'Nova incidència registrada', 'Una nova incidència requereix revisió.', 304, 'incidencia'),
(NULL, 1, 'incidencia_actualitzada', 'Incidència modificada', 'S’han actualitzat dades d’una incidència.', 305, 'incidencia'),
(NULL, 2, 'document_pujat', 'Nou document disponible', 'S’ha afegit un document nou al sistema.', 502, 'document'),
(NULL, 3, 'nova_obra_assignada', 'Nova obra disponible', 'Una nova obra ha estat vinculada a l’empresa.', 403, 'obra'),
(3, NULL, 'contracte_finalitza_properament', 'Contracte proper a finalitzar', 'El teu contracte finalitza properament.', 702, 'contracte');