CREATE DATABASE IF NOT EXISTS bank;
USE bank; 
CREATE TABLE IF NOT EXISTS utilisateurs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    prenom VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    mot_de_passe_hash VARCHAR(255) NOT NULL,
    role ENUM('employé', 'admin') NOT NULL,
    departement VARCHAR(100),
    telephone VARCHAR(20),
    actif BOOLEAN DEFAULT TRUE,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    derniere_connexion TIMESTAMP NULL
) ENGINE=InnoDB;

-- Table des statuts des ticketsutilisateurs
CREATE TABLE IF NOT EXISTS statut_ticket (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(50) UNIQUE NOT NULL
) ENGINE=InnoDB;

-- Table des tickets
CREATE TABLE IF NOT EXISTS tickets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ticket_uuid CHAR(36) NOT NULL,
    titre VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    statut_id INT,
    priorite ENUM('faible', 'moyenne', 'haute', 'critique') NOT NULL,
    demandeur_id INT NOT NULL,
    technicien_id INT NULL,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_mise_a_jour TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (statut_id) REFERENCES statut_ticket(id),
    FOREIGN KEY (demandeur_id) REFERENCES utilisateurs(id),
    FOREIGN KEY (technicien_id) REFERENCES utilisateurs(id)
) ENGINE=InnoDB;

-- Table des commentaires
CREATE TABLE IF NOT EXISTS commentaires (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ticket_id INT NOT NULL,
    auteur_id INT NOT NULL,
    contenu TEXT NOT NULL,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ticket_id) REFERENCES tickets(id) ON DELETE CASCADE,
    FOREIGN KEY (auteur_id) REFERENCES utilisateurs(id)
) ENGINE=InnoDB;

-- Table des notifications
CREATE TABLE IF NOT EXISTS notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    destinataire_id INT NOT NULL,
    ticket_id INT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) NOT NULL,
    lu BOOLEAN DEFAULT FALSE,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (destinataire_id) REFERENCES utilisateurs(id),
    FOREIGN KEY (ticket_id) REFERENCES tickets(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Table de l'historique des tickets
CREATE TABLE IF NOT EXISTS historique_tickets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ticket_id INT NOT NULL,
    utilisateur_id INT NOT NULL,
    action VARCHAR(100) NOT NULL,
    ancienne_valeur TEXT,
    nouvelle_valeur TEXT,
    date_action TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ticket_id) REFERENCES tickets(id) ON DELETE CASCADE,
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id)
) ENGINE=InnoDB;

-- Index pour les performances
CREATE INDEX idx_tickets_statut ON tickets(statut_id);
CREATE INDEX idx_tickets_priorite ON tickets(priorite);
CREATE INDEX idx_tickets_demandeur ON tickets(demandeur_id);
CREATE INDEX idx_tickets_technicien ON tickets(technicien_id);
CREATE INDEX idx_tickets_date_creation ON tickets(date_creation);
CREATE INDEX idx_notifications_destinataire ON notifications(destinataire_id);

-- Données initiales : statuts des tickets
INSERT IGNORE INTO statut_ticket (nom) VALUES
    ('Créé'),
    ('En cours de traitement'),
    ('Traité');

-- Données initiales : utilisateurs de démonstration
INSERT IGNORE INTO utilisateurs (nom, prenom, email, mot_de_passe_hash, role) VALUES
    
    ('Jlidi', 'Mariem', 'maryem@bhbank.tn', '1234', 'employe');
INSERT IGNORE INTO Utilisateurs (nom, email, mot_de_passe_hash, role)
VALUES ('Admin', 'admin@gmail.com', '0000', 'Admin');
INSERT IGNORE INTO Utilisateurs (nom, email, mot_de_passe_hash, role)
VALUES ('Admin', 'admin@gmail.com', '0000', 'Admin');
INSERT IGNORE INTO Utilisateurs (nom, email, mot_de_passe_hash, role)
VALUES ('rym', 'rym@gmail.com', '147', 'employe');
-- Pour UUID automatique dans MySQL
DELIMITER $$
CREATE TRIGGER before_insert_tickets
BEFORE INSERT ON tickets
FOR EACH ROW
BEGIN
    IF NEW.ticket_uuid IS NULL THEN
        SET NEW.ticket_uuid = UUID();
    END IF;
END$$
DELIMITER ;

-- Vérification des données
SELECT * FROM statut_ticket;
SELECT * FROM tickets;
SELECT * FROM historique_tickets;
SELECT * FROM commentaires;
SELECT * FROM notifications;