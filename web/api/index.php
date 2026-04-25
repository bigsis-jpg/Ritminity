<?php
/**
 * RITMINITY - API Router
 * Main API entry point
 */

// Include configuration
require_once __DIR__ . '/../config.php';

// Get request information
$method = $_SERVER['REQUEST_METHOD'];
$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$headers = getallheaders();

// Remove base path from URI
$basePath = '/api';
$path = str_replace($basePath, '', $uri);

// Parse path segments
$segments = array_filter(explode('/', $path));
$segments = array_values($segments);

// Get API key if provided
$apiKey = $headers['X-API-Key'] ?? $headers['Authorization'] ?? null;

// Route the request
try {
    $response = routeRequest($method, $segments, $_POST, $apiKey);
    echo json_encode($response);
} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}

/**
 * Route API requests
 */
function routeRequest($method, $segments, $data, $apiKey) {
    // Health check
    if (empty($segments) || $segments[0] === 'health') {
        return ['status' => 'ok', 'version' => APP_VERSION];
    }
    
    // Authentication required for most endpoints
    $publicEndpoints = ['auth/login', 'auth/register', 'maps', 'maps/{id}', 'leaderboard'];
    $isPublic = in_array($segments[0] ?? '', $publicEndpoints);
    
    if (!$isPublic && !validateApiKey($apiKey)) {
        http_response_code(401);
        return ['success' => false, 'error' => 'Unauthorized'];
    }
    
    // Route based on first segment
    $controller = $segments[0] ?? '';
    
    switch ($controller) {
        // Authentication
        case 'auth':
            return handleAuth($method, $segments, $data);
            
        // Users
        case 'users':
            return handleUsers($method, $segments, $data);
            
        // Maps/Beatmaps
        case 'maps':
            return handleMaps($method, $segments, $data);
            
        // Scores
        case 'scores':
            return handleScores($method, $segments, $data);
            
        // Leaderboard
        case 'leaderboard':
            return handleLeaderboard($method, $segments, $data);
            
        // Replays
        case 'replays':
            return handleReplays($method, $segments, $data);
            
        // Stats
        case 'stats':
            return handleStats($method, $segments, $data);
            
        default:
            http_response_code(404);
            return ['success' => false, 'error' => 'Endpoint not found'];
    }
}

/**
 * Validate API key
 */
function validateApiKey($apiKey) {
    if (!$apiKey) {
        return false;
    }
    
    // For development, accept a simple key
    // In production, validate against database
    return $apiKey === 'ritminity_dev_key' || strlen($apiKey) >= 32;
}

/**
 * Handle authentication requests
 */
function handleAuth($method, $segments, $data) {
    $action = $segments[1] ?? '';
    
    if ($method === 'POST' && $action === 'login') {
        $username = $data['username'] ?? '';
        $password = $data['password'] ?? '';
        
        if (empty($username) || empty($password)) {
            return ['success' => false, 'error' => 'Missing credentials'];
        }
        
        // Validate credentials
        $user = db()->fetch(
            "SELECT id, username, email, password_hash, is_admin FROM users WHERE username = ? AND is_active = 1",
            [$username]
        );
        
        if (!$user || !password_verify($password, $user['password_hash'])) {
            return ['success' => false, 'error' => 'Invalid credentials'];
        }
        
        // Generate session token
        $token = bin2hex(random_bytes(32));
        $expires = date('Y-m-d H:i:s', time() + SESSION_LIFETIME);
        
        // Store session
        db()->insert('sessions', [
            'id' => $token,
            'user_id' => $user['id'],
            'ip_address' => $_SERVER['REMOTE_ADDR'] ?? '',
            'user_agent' => $_SERVER['HTTP_USER_AGENT'] ?? '',
            'expires_at' => $expires
        ]);
        
        // Update last login
        db()->query("UPDATE users SET last_login = NOW() WHERE id = ?", [$user['id']]);
        
        return [
            'success' => true,
            'token' => $token,
            'user' => [
                'id' => $user['id'],
                'username' => $user['username'],
                'email' => $user['email'],
                'is_admin' => (bool)$user['is_admin']
            ]
        ];
    }
    
    if ($method === 'POST' && $action === 'register') {
        $username = $data['username'] ?? '';
        $email = $data['email'] ?? '';
        $password = $data['password'] ?? '';
        
        // Validation
        if (strlen($username) < 3 || strlen($username) > 50) {
            return ['success' => false, 'error' => 'Username must be 3-50 characters'];
        }
        
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            return ['success' => false, 'error' => 'Invalid email format'];
        }
        
        if (strlen($password) < PASSWORD_MIN_LENGTH) {
            return ['success' => false, 'error' => 'Password must be at least ' . PASSWORD_MIN_LENGTH . ' characters'];
        }
        
        // Check if username or email exists
        $exists = db()->fetch(
            "SELECT id FROM users WHERE username = ? OR email = ?",
            [$username, $email]
        );
        
        if ($exists) {
            return ['success' => false, 'error' => 'Username or email already exists'];
        }
        
        // Create user
        $userId = db()->insert('users', [
            'username' => $username,
            'email' => $email,
            'password_hash' => password_hash($password, PASSWORD_DEFAULT),
            'country' => $data['country'] ?? 'US'
        ]);
        
        // Create user stats
        db()->insert('user_stats', [
            'user_id' => $userId
        ]);
        
        return [
            'success' => true,
            'message' => 'User created successfully',
            'user_id' => $userId
        ];
    }
    
    if ($method === 'POST' && $action === 'logout') {
        $token = $data['token'] ?? '';
        
        if ($token) {
            db()->delete('sessions', 'id = ?', [$token]);
        }
        
        return ['success' => true, 'message' => 'Logged out successfully'];
    }
    
    return ['success' => false, 'error' => 'Invalid action'];
}

/**
 * Handle user requests
 */
function handleUsers($method, $segments, $data) {
    $userId = $segments[1] ?? null;
    
    if ($method === 'GET' && $userId) {
        $user = db()->fetch(
            "SELECT id, username, email, avatar_url, country, created_at, last_login FROM users WHERE id = ?",
            [$userId]
        );
        
        if (!$user) {
            return ['success' => false, 'error' => 'User not found'];
        }
        
        // Get user stats
        $stats = db()->fetch(
            "SELECT * FROM user_stats WHERE user_id = ?",
            [$userId]
        );
        
        $user['stats'] = $stats;
        
        return ['success' => true, 'user' => $user];
    }
    
    if ($method === 'PUT' && $userId) {
        $updateData = [];
        
        if (isset($data['avatar_url'])) {
            $updateData['avatar_url'] = $data['avatar_url'];
        }
        
        if (isset($data['country'])) {
            $updateData['country'] = $data['country'];
        }
        
        if (!empty($updateData)) {
            db()->update('users', $updateData, 'id = :id', ['id' => $userId]);
        }
        
        return ['success' => true, 'message' => 'Profile updated'];
    }
    
    return ['success' => false, 'error' => 'Invalid request'];
}

/**
 * Handle map requests
 */
function handleMaps($method, $segments, $data) {
    $mapId = $segments[1] ?? null;
    
    if ($method === 'GET') {
        if ($mapId) {
            // Get single map
            $map = db()->fetch(
                "SELECT * FROM maps WHERE id = ?",
                [$mapId]
            );
            
            if (!$map) {
                return ['success' => false, 'error' => 'Map not found'];
            }
            
            return ['success' => true, 'map' => $map];
        } else {
            // Get multiple maps with pagination
            $page = (int)($data['page'] ?? 1);
            $limit = (int)($data['limit'] ?? ITEMS_PER_PAGE);
            $offset = ($page - 1) * $limit;
            
            $where = "1=1";
            $params = [];
            
            if (!empty($data['search'])) {
                $where .= " AND (title LIKE ? OR artist LIKE ?)";
                $search = '%' . $data['search'] . '%';
                $params[] = $search;
                $params[] = $search;
            }
            
            if (!empty($data['difficulty'])) {
                $where .= " AND difficulty = ?";
                $params[] = $data['difficulty'];
            }
            
            if (!empty($data['column_count'])) {
                $where .= " AND column_count = ?";
                $params[] = $data['column_count'];
            }
            
            if (!empty($data['ranked'])) {
                $where .= " AND is_ranked = 1";
            }
            
            $total = db()->rowCount("SELECT COUNT(*) FROM maps WHERE $where", $params);
            
            $maps = db()->fetchAll(
                "SELECT * FROM maps WHERE $where ORDER BY created_at DESC LIMIT $offset, $limit",
                $params
            );
            
            return [
                'success' => true,
                'maps' => $maps,
                'pagination' => [
                    'page' => $page,
                    'limit' => $limit,
                    'total' => $total,
                    'pages' => ceil($total / $limit)
                ]
            ];
        }
    }
    
    if ($method === 'POST') {
        // Upload new map (requires authentication)
        $required = ['title', 'audio_file', 'bpm', 'difficulty', 'column_count'];
        
        foreach ($required as $field) {
            if (empty($data[$field])) {
                return ['success' => false, 'error' => "Missing required field: $field"];
            }
        }
        
        $mapId = db()->insert('maps', [
            'title' => $data['title'],
            'artist' => $data['artist'] ?? '',
            'mapper' => $data['mapper'] ?? 'Unknown',
            'audio_file' => $data['audio_file'],
            'bpm' => $data['bpm'],
            'difficulty' => $data['difficulty'],
            'column_count' => $data['column_count'],
            'note_count' => $data['note_count'] ?? 0,
            'duration' => $data['duration'] ?? 0,
            'cs' => $data['cs'] ?? 5.0,
            'ar' => $data['ar'] ?? 5.0,
            'od' => $data['od'] ?? 5.0,
            'hp' => $data['hp'] ?? 5.0
        ]);
        
        return ['success' => true, 'map_id' => $mapId, 'message' => 'Map uploaded successfully'];
    }
    
    return ['success' => false, 'error' => 'Invalid request'];
}

/**
 * Handle score requests
 */
function handleScores($method, $segments, $data) {
    $scoreId = $segments[1] ?? null;
    
    if ($method === 'GET') {
        if ($scoreId) {
            $score = db()->fetch(
                "SELECT s.*, u.username, m.title as map_title FROM scores s 
                 JOIN users u ON s.user_id = u.id 
                 JOIN maps m ON s.map_id = m.id 
                 WHERE s.id = ?",
                [$scoreId]
            );
            
            return ['success' => true, 'score' => $score];
        } else {
            // Get scores for a map or user
            $page = (int)($data['page'] ?? 1);
            $limit = (int)($data['limit'] ?? ITEMS_PER_PAGE);
            $offset = ($page - 1) * $limit;
            
            $where = "1=1";
            $params = [];
            
            if (!empty($data['user_id'])) {
                $where .= " AND s.user_id = ?";
                $params[] = $data['user_id'];
            }
            
            if (!empty($data['map_id'])) {
                $where .= " AND s.map_id = ?";
                $params[] = $data['map_id'];
            }
            
            $scores = db()->fetchAll(
                "SELECT s.*, u.username, m.title as map_title FROM scores s 
                 JOIN users u ON s.user_id = u.id 
                 JOIN maps m ON s.map_id = m.id 
                 WHERE $where 
                 ORDER BY s.score DESC 
                 LIMIT $offset, $limit",
                $params
            );
            
            return ['success' => true, 'scores' => $scores];
        }
    }
    
    if ($method === 'POST') {
        // Submit score
        $required = ['user_id', 'map_id', 'score', 'accuracy', 'grade'];
        
        foreach ($required as $field) {
            if (!isset($data[$field])) {
                return ['success' => false, 'error' => "Missing required field: $field"];
            }
        }
        
        $scoreId = db()->insert('scores', [
            'user_id' => $data['user_id'],
            'map_id' => $data['map_id'],
            'score' => $data['score'],
            'max_combo' => $data['max_combo'] ?? 0,
            'accuracy' => $data['accuracy'],
            'grade' => $data['grade'],
            'perfect_count' => $data['perfect_count'] ?? 0,
            'great_count' => $data['great_count'] ?? 0,
            'good_count' => $data['good_count'] ?? 0,
            'bad_count' => $data['bad_count'] ?? 0,
            'miss_count' => $data['miss_count'] ?? 0,
            'mods' => $data['mods'] ?? ''
        ]);
        
        // Update user stats
        db()->query("CALL update_user_stats(?)", [$data['user_id']]);
        
        // Update map play count
        db()->query("UPDATE maps SET play_count = play_count + 1 WHERE id = ?", [$data['map_id']]);
        
        return ['success' => true, 'score_id' => $scoreId, 'message' => 'Score submitted'];
    }
    
    return ['success' => false, 'error' => 'Invalid request'];
}

/**
 * Handle leaderboard requests
 */
function handleLeaderboard($method, $segments, $data) {
    if ($method === 'GET') {
        $page = (int)($data['page'] ?? 1);
        $limit = (int)($data['limit'] ?? ITEMS_PER_PAGE);
        $offset = ($page - 1) * $limit;
        
        $type = $data['type'] ?? 'score';
        
        $orderBy = 'rank_points DESC';
        if ($type === 'accuracy') {
            $orderBy = 'max_accuracy DESC';
        } elseif ($type === 'combo') {
            $orderBy = 'max_combo DESC';
        } elseif ($type === 'plays') {
            $orderBy = 'total_plays DESC';
        }
        
        $leaderboard = db()->fetchAll(
            "SELECT us.*, u.username, u.avatar_url, u.country 
             FROM user_stats us 
             JOIN users u ON us.user_id = u.id 
             ORDER BY $orderBy 
             LIMIT $offset, $limit"
        );
        
        return ['success' => true, 'leaderboard' => $leaderboard];
    }
    
    return ['success' => false, 'error' => 'Invalid request'];
}

/**
 * Handle replay requests
 */
function handleReplays($method, $segments, $data) {
    $replayId = $segments[1] ?? null;
    
    if ($method === 'GET' && $replayId) {
        $replay = db()->fetch(
            "SELECT r.*, u.username, m.title as map_title FROM replays r 
             JOIN users u ON r.user_id = u.id 
             JOIN maps m ON r.map_id = m.id 
             WHERE r.id = ?",
            [$replayId]
        );
        
        return ['success' => true, 'replay' => $replay];
    }
    
    if ($method === 'POST') {
        // Save replay
        $required = ['score_id', 'user_id', 'map_id', 'replay_data'];
        
        foreach ($required as $field) {
            if (empty($data[$field])) {
                return ['success' => false, 'error' => "Missing required field: $field"];
            }
        }
        
        $replayId = db()->insert('replays', [
            'score_id' => $data['score_id'],
            'user_id' => $data['user_id'],
            'map_id' => $data['map_id'],
            'replay_data' => $data['replay_data'],
            'file_size' => strlen($data['replay_data'])
        ]);
        
        return ['success' => true, 'replay_id' => $replayId];
    }
    
    return ['success' => false, 'error' => 'Invalid request'];
}

/**
 * Handle stats requests
 */
function handleStats($method, $segments, $data) {
    if ($method === 'GET') {
        $type = $data['type'] ?? 'global';
        
        if ($type === 'global') {
            // Global statistics
            $stats = [
                'total_users' => db()->fetch("SELECT COUNT(*) as count FROM users")['count'],
                'total_maps' => db()->fetch("SELECT COUNT(*) as count FROM maps")['count'],
                'total_plays' => db()->fetch("SELECT SUM(total_plays) as count FROM user_stats")['count'],
                'total_scores' => db()->fetch("SELECT COUNT(*) as count FROM scores")['count']
            ];
            
            return ['success' => true, 'stats' => $stats];
        }
        
        if ($type === 'user' && !empty($data['user_id'])) {
            $stats = db()->fetch(
                "SELECT * FROM user_stats WHERE user_id = ?",
                [$data['user_id']]
            );
            
            return ['success' => true, 'stats' => $stats];
        }
        
        if ($type === 'map' && !empty($data['map_id'])) {
            $map = db()->fetch("SELECT * FROM maps WHERE id = ?", [$data['map_id']]);
            
            $scores = db()->fetchAll(
                "SELECT s.*, u.username FROM scores s 
                 JOIN users u ON s.user_id = u.id 
                 WHERE s.map_id = ? 
                 ORDER BY s.score DESC 
                 LIMIT 10",
                [$data['map_id']]
            );
            
            return ['success' => true, 'map' => $map, 'top_scores' => $scores];
        }
    }
    
    return ['success' => false, 'error' => 'Invalid request'];
}