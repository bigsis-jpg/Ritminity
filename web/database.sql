-- RITMINITY Database Schema
-- MySQL Database for RITMINITY Rhythm Game

-- Create database
CREATE DATABASE IF NOT EXISTS ritminity CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE ritminity;

-- ============================================
-- USERS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS users (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    avatar_url VARCHAR(500) DEFAULT NULL,
    country VARCHAR(2) DEFAULT 'US',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL,
    is_active BOOLEAN DEFAULT TRUE,
    is_admin BOOLEAN DEFAULT FALSE,
    INDEX idx_username (username),
    INDEX idx_email (email),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- SCORES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS scores (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    map_id INT UNSIGNED NOT NULL,
    score BIGINT UNSIGNED NOT NULL DEFAULT 0,
    max_combo INT UNSIGNED NOT NULL DEFAULT 0,
    accuracy DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    grade VARCHAR(2) NOT NULL DEFAULT 'F',
    perfect_count INT UNSIGNED NOT NULL DEFAULT 0,
    great_count INT UNSIGNED NOT NULL DEFAULT 0,
    good_count INT UNSIGNED NOT NULL DEFAULT 0,
    bad_count INT UNSIGNED NOT NULL DEFAULT 0,
    miss_count INT UNSIGNED NOT NULL DEFAULT 0,
    mods VARCHAR(50) DEFAULT '',
    play_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    replay_data TEXT,
    is_submitted BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (map_id) REFERENCES maps(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_map_id (map_id),
    INDEX idx_score (score DESC),
    INDEX idx_accuracy (accuracy DESC),
    INDEX idx_play_time (play_time DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- MAPS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS maps (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    artist VARCHAR(255) DEFAULT '',
    mapper VARCHAR(50) DEFAULT 'Unknown',
    audio_file VARCHAR(500) NOT NULL,
    audio_hash VARCHAR(64) DEFAULT '',
    cover_url VARCHAR(500) DEFAULT NULL,
    bpm DECIMAL(6,2) DEFAULT 120.00,
    duration INT UNSIGNED DEFAULT 0,
    difficulty VARCHAR(20) DEFAULT 'Normal',
    column_count TINYINT UNSIGNED DEFAULT 4,
    note_count INT UNSIGNED DEFAULT 0,
    cs DECIMAL(3,1) DEFAULT 5.0,
    ar DECIMAL(3,1) DEFAULT 5.0,
    od DECIMAL(3,1) DEFAULT 5.0,
    hp DECIMAL(3,1) DEFAULT 5.0,
    is_ranked BOOLEAN DEFAULT FALSE,
    is_approved BOOLEAN DEFAULT FALSE,
    submitter_id INT UNSIGNED,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    download_count INT UNSIGNED DEFAULT 0,
    play_count INT UNSIGNED DEFAULT 0,
    fav_count INT UNSIGNED DEFAULT 0,
    FOREIGN KEY (submitter_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_title (title),
    INDEX idx_artist (artist),
    INDEX idx_bpm (bpm),
    INDEX idx_difficulty (difficulty),
    INDEX idx_column_count (column_count),
    INDEX idx_is_ranked (is_ranked),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- REPLAYS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS replays (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    score_id INT UNSIGNED NOT NULL,
    user_id INT UNSIGNED NOT NULL,
    map_id INT UNSIGNED NOT NULL,
    replay_data LONGTEXT NOT NULL,
    file_size INT UNSIGNED DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (score_id) REFERENCES scores(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (map_id) REFERENCES maps(id) ON DELETE CASCADE,
    INDEX idx_score_id (score_id),
    INDEX idx_user_id (user_id),
    INDEX idx_map_id (map_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- USER STATS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS user_stats (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL UNIQUE,
    total_plays INT UNSIGNED DEFAULT 0,
    total_time INT UNSIGNED DEFAULT 0,
    total_score BIGINT UNSIGNED DEFAULT 0,
    max_combo INT UNSIGNED DEFAULT 0,
    max_accuracy DECIMAL(5,2) DEFAULT 0.00,
    perfect_count BIGINT UNSIGNED DEFAULT 0,
    ss_count INT UNSIGNED DEFAULT 0,
    s_count INT UNSIGNED DEFAULT 0,
    a_count INT UNSIGNED DEFAULT 0,
    rank_points DECIMAL(10,2) DEFAULT 0.00,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_rank_points (rank_points DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- SESSIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS sessions (
    id VARCHAR(64) PRIMARY KEY,
    user_id INT UNSIGNED,
    ip_address VARCHAR(45),
    user_agent VARCHAR(500),
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_expires_at (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- COMMENTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS comments (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    map_id INT UNSIGNED NOT NULL,
    user_id INT UNSIGNED NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_deleted BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (map_id) REFERENCES maps(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_map_id (map_id),
    INDEX idx_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- FAVORITES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS favorites (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    map_id INT UNSIGNED NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (map_id) REFERENCES maps(id) ON DELETE CASCADE,
    UNIQUE KEY unique_favorite (user_id, map_id),
    INDEX idx_user_id (user_id),
    INDEX idx_map_id (map_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- REPORTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS reports (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    reporter_id INT UNSIGNED NOT NULL,
    reported_user_id INT UNSIGNED,
    map_id INT UNSIGNED,
    reason VARCHAR(100) NOT NULL,
    description TEXT,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP NULL,
    FOREIGN KEY (reporter_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (reported_user_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (map_id) REFERENCES maps(id) ON DELETE SET NULL,
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- BEATMAPS TABLE (Alternative name)
-- ============================================
CREATE TABLE IF NOT EXISTS beatmaps (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    map_id INT UNSIGNED NOT NULL,
    version VARCHAR(20) DEFAULT '1.0',
    data LONGTEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (map_id) REFERENCES maps(id) ON DELETE CASCADE,
    INDEX idx_map_id (map_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- PROCEDURES
-- ============================================

-- Procedure to update user stats after a play
DELIMITER //
CREATE PROCEDURE IF NOT EXISTS update_user_stats(IN p_user_id INT UNSIGNED)
BEGIN
    INSERT INTO user_stats (user_id, total_plays, total_time, total_score, max_combo, max_accuracy, perfect_count, ss_count, s_count, a_count, rank_points)
    SELECT 
        p_user_id,
        COUNT(*) as total_plays,
        COALESCE(SUM(duration), 0) as total_time,
        COALESCE(SUM(score), 0) as total_score,
        COALESCE(MAX(max_combo), 0) as max_combo,
        COALESCE(MAX(accuracy), 0) as max_accuracy,
        COALESCE(SUM(perfect_count), 0) as perfect_count,
        SUM(CASE WHEN grade = 'SS' THEN 1 ELSE 0 END) as ss_count,
        SUM(CASE WHEN grade = 'S' THEN 1 ELSE 0 END) as s_count,
        SUM(CASE WHEN grade = 'A' THEN 1 ELSE 0 END) as a_count,
        COALESCE(SUM(score), 0) / 1000 as rank_points
    FROM scores
    WHERE user_id = p_user_id
    ON DUPLICATE KEY UPDATE
        total_plays = VALUES(total_plays),
        total_time = VALUES(total_time),
        total_score = VALUES(total_score),
        max_combo = VALUES(max_combo),
        max_accuracy = VALUES(max_accuracy),
        perfect_count = VALUES(perfect_count),
        ss_count = VALUES(ss_count),
        s_count = VALUES(s_count),
        a_count = VALUES(a_count),
        rank_points = VALUES(rank_points);
END //
DELIMITER ;

-- ============================================
-- SAMPLE DATA
-- ============================================

-- Insert sample users
INSERT INTO users (username, email, password_hash, country, is_admin) VALUES
('Admin', 'admin@ritminity.com', '$2y$10$abcdefghijklmnopqrstuv', 'US', TRUE),
('TestPlayer', 'test@ritminity.com', '$2y$10$abcdefghijklmnopqrstuv', 'JP', FALSE);

-- Insert sample maps
INSERT INTO maps (title, artist, mapper, audio_file, bpm, difficulty, column_count, note_count, is_ranked) VALUES
('Sample Beat 1', 'Artist 1', 'Mapper1', 'sample1.mp3', 120.00, 'Easy', 4, 100, TRUE),
('Sample Beat 2', 'Artist 2', 'Mapper2', 'sample2.mp3', 140.00, 'Normal', 4, 200, TRUE),
('Sample Beat 3', 'Artist 3', 'Mapper3', 'sample3.mp3', 160.00, 'Hard', 4, 300, TRUE),
('Sample Beat 4', 'Artist 4', 'Mapper4', 'sample4.mp3', 180.00, 'Insane', 4, 400, TRUE);

-- Insert sample scores
INSERT INTO scores (user_id, map_id, score, max_combo, accuracy, grade, perfect_count, great_count, good_count, bad_count, miss_count) VALUES
(2, 1, 1000000, 100, 98.50, 'S', 90, 5, 3, 1, 1),
(2, 2, 1500000, 200, 95.00, 'S', 180, 10, 5, 3, 2),
(2, 3, 2000000, 300, 92.00, 'A', 250, 20, 15, 10, 5);

-- Insert sample user stats
INSERT INTO user_stats (user_id, total_plays, total_time, total_score, max_combo, max_accuracy, ss_count, s_count, a_count, rank_points) VALUES
(2, 3, 600, 4500000, 300, 98.50, 0, 2, 1, 4500.00);