-- EEVIS database schema
-- Used by ../eevis-docker to provision a fresh database, and can also be used
-- for a manual local MySQL setup as an alternative to setup_eevis_database.sh.

CREATE DATABASE IF NOT EXISTS eevis CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE eevis;

CREATE TABLE IF NOT EXISTS users (
    id              INT NOT NULL AUTO_INCREMENT,
    username        VARCHAR(64) NOT NULL,
    email           VARCHAR(255) NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    is_logged_in    TINYINT(1) NOT NULL DEFAULT 0,
    is_admin        TINYINT(1) NOT NULL DEFAULT 0,
    PRIMARY KEY (id),
    UNIQUE KEY uniq_username (username),
    UNIQUE KEY uniq_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
