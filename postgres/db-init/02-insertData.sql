INSERT INTO usuari (id, tipus, nom, cognoms, rol, telefon, estat, data_creacio) VALUES
  (1, 'TREBALLADOR', 'Joan', 'Garcia Mora', 'Mestre Obra', 600123001, 'ACTIU', '2024-06-01 09:30:00'),
  (2, 'TREBALLADOR', 'Marta', 'Riera Pont', 'Oficial 1a', 600123002, 'ACTIU', '2024-06-03 10:00:00'),
  (3, 'TREBALLADOR', 'Pere', 'Fiol Serra', 'Peó', 600123003, 'INACTIU', '2024-06-05 11:15:00'),
  (4, 'EMPRESA', 'Construccions Alzina', 'S.L.', 'Empresa', 871123456, 'ACTIU', '2024-05-21 13:00:00'),
  (5, 'EMPRESA', 'Serveis Integrals', 'Mallorca', 'Empresa', 971987654, 'ACTIU', '2024-05-25 12:00:00');

INSERT INTO u_empresa (id, correu, identificador) VALUES
  (4, 'info@alzina.com', 'B12345678'),
  (5, 'contacte@servintmallorca.com', 'B87654321');

INSERT INTO contrasenya (id_usuari, clau, data_creacio, data_reemplas) VALUES
  (4, 'Alzina', '2024-06-01 09:31:00', NULL),
  (5, 'servintMallorca', '2024-06-03 10:02:00', NULL);

INSERT INTO permis (clau_funcional, descripcio) VALUES
  ('ADMIN', 'Accés complet al sistema'),
  ('GESTIO_OBRA', 'Gestió obres i recursos'),
  ('VISUALITZACIO', 'Només visualització');

INSERT INTO permis_usuari (id_usuari, id_permis, lectura, escriptura, edicio, data_creacio) VALUES
  (1, 1, TRUE, TRUE, TRUE, '2024-06-01 09:35:00'),
  (2, 2, TRUE, TRUE, FALSE, '2024-06-03 10:10:00'),
  (4, 3, TRUE, FALSE, FALSE, '2024-05-21 13:15:00');


INSERT INTO configuracio (id_usuari, idioma, acceptacio_terms, imatge_perfil) VALUES
  (1, 'ca', TRUE, NULL),
  (2, 'es', TRUE, 'https://avatar.com/marta.png'),
  (4, 'ca', TRUE, 'https://avatar.com/alzina.jpg');


INSERT INTO verificacio (id_usuari, estat_ver, data_ver, token_verificacio, data_token) VALUES
  (4, 'OK', '2024-06-02', 'token_alzina_123', '2024-06-01 10:00:00'),
  (5, 'PENDENT', NULL, 'token_servint_456', '2024-06-03 11:00:00'),
  (4, 'OK', '2024-07-01', 'token_alzina_789', '2024-07-01 08:00:00');


INSERT INTO obra (nom, ubicacio, data_inici, data_prev_fi, data_fi, descripcio, pressupost, estat) VALUES
  ('Reforma Casa Serra', 'C/ Major, 123, Palma', '2024-07-01', '2024-10-01', NULL, 'Reforma integral habitatge', 50000, 'EN CURS'),
  ('Construcció Xalet', 'C/ Pins, 45, Inca', '2024-05-20', '2024-11-30', NULL, 'Nova construcció de xalet unifamiliar', 150000, 'EN CURS'),
  ('Pavimentació Pl. Espanya', 'Plaça Espanya, Manacor', '2024-04-01', '2024-07-31', '2024-07-15', 'Reforma paviment plaça', 90000, 'FINALITZADA');

INSERT INTO recurs (nom, unitats_mesura, quantitat_stock, tipus_recurs) VALUES
  ('Formigó', 'm3', 40, 'Material'),
  ('Grua torre', 'unitats', 2, 'Maquinària'),
  ('Totxos ceràmics', 'unitats', 10000, 'Material');

INSERT INTO sol_recurs (id_obra, id_recurs, quantitat, data_necessitat, comentari, data_entrega, data_creacio, proveidor) VALUES
  (1, 1, 15, '2024-07-02', 'Necessari per fonaments', NULL, '2024-06-25 08:00:00', 'Formigons Balears'),
  (2, 2, 1, '2024-06-10', 'Per començar estructura', '2024-06-12', '2024-06-01 10:00:00', 'Maquinària Mallorquina'),
  (3, 3, 5000, '2024-04-15', 'Primera fase obra', '2024-04-16', '2024-04-10 09:00:00', 'Totxos SA');


INSERT INTO document_obra (id_obra, id_creador, nom, format, mida, comentari, data_pujada, tipus) VALUES
  (1, 1, 'plano_fonament.pdf', 'PDF', 2.3, 'Plànol fonaments', '2024-06-15 10:00:00', 'Pla'),
  (2, 2, 'certificat_energia.pdf', 'PDF', 0.7, 'Certificat energètic', '2024-06-25 09:00:00', 'Informe'),
  (3, 1, 'pressupost_final.xlsx', 'XLSX', 0.2, 'Pressupost final', '2024-07-01 11:00:00', 'Pressupost');

INSERT INTO tasca (id_obra, id_tasca_pare, descripcio, data_inici, data_fi, prioritat, visibilitat_tasca) VALUES
  (1, NULL, 'Preparació fonament', '2024-07-02', NULL, 1, TRUE),
  (1, 1, 'Col·locació armadures', '2024-07-03', NULL, 2, TRUE),
  (2, NULL, 'Encofrat sostre', '2024-06-12', NULL, 2, TRUE);

INSERT INTO tasca_treballador (id_tasca, id_treballador, comentari) VALUES
  (1, 1, 'Supervisó general'),
  (2, 2, NULL),
  (3, 3, 'Tasca assignada pel responsable');

INSERT INTO incidencia (id_obra, id_tasca, descripcio, data_inici, data_fi, criticitat, prioritat, categoria, estat) VALUES
  (1, 1, 'Retard subministrament formigó', '2024-07-04', NULL, 3, 2, 1, 'OBERTA'),
  (2, NULL, 'Problema humitat parets', '2024-06-20', NULL, 4, 1, 2, 'OBERTA'),
  (3, 3, 'Endarreriment subministrament totxos', '2024-04-17', '2024-04-20', 2, 1, 3, 'TANCADA');

INSERT INTO solucio (id_incidencia, id_tasca, descripcio, cost_monetari, eficacia, cost_temporal, impacte) VALUES
  (1, 1, 'Canvi de proveïdor formigó', 500, 4, 5, 6),
  (2, NULL, 'Reparació i segellat parets', 1200, 5, 8, 7),
  (3, 3, 'Demora acceptada; ampliació termini', 0, 3, 2, 4);

-- Responsable d'obra (id_treballador = usuari.id d'un treballador)
INSERT INTO responsable_obra (id_obra, id_treballador, data_inici, data_fi) VALUES
  (1, 1, '2024-07-01', NULL),   -- Joan
  (2, 2, '2024-05-20', NULL),   -- Marta
  (3, 1, '2024-04-01', '2024-07-15');  -- Joan

