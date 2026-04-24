<?php
/**
 * RITMINITY - Backend Configuration
 * Configuration file for the web backend
 */

// Database configuration
define('DB_HOST', 'localhost');
define('DB_NAME', 'ritminity');
define('DB_USER', 'root');
define('DB_PASS', '');
define('DB_CHARSET', 'utf8mb4');

// Application settings
define('APP_NAME', 'RITMINITY');
define('APP_VERSION', '1.0.0');
define('APP_URL', 'http://localhost/ritminity');
define('APP_DEBUG', true);

// Security settings
define('SESSION_LIFETIME', 86400); // 24 hours
define('PASSWORD_MIN_LENGTH', 6);
define('API_RATE_LIMIT', 100); // requests per hour
define('API_KEY_LENGTH', 32);

// File upload settings
define('UPLOAD_MAX_SIZE', 52428800); // 50MB
define('UPLOAD_ALLOWED_TYPES', ['mp3', 'ogg', 'wav', 'flac']);
define('UPLOAD_PATH', 'uploads/');
define('COVER_PATH', 'uploads/covers/');
define('CHART_PATH', 'uploads/charts/');

// Pagination
define('ITEMS_PER_PAGE', 20);
define('MAX_PAGES', 100);

// Timezone
date_default_timezone_set('UTC');

// Error reporting
if (APP_DEBUG) {
    error_reporting(E_ALL);
    ini_set('display_errors', 1);
} else {
    error_reporting(0);
    ini_set('display_errors', 0);
}

// Autoloader
spl_autoload_register(function ($class) {
    $paths = [
        'src/',
        'src/controllers/',
        'src/models/',
        'src/utils/',
    ];
    
    foreach ($paths as $path) {
        $file = $path . $class . '.php';
        if (file_exists($file)) {
            require_once $file;
            return;
        }
    }
});

// CORS headers
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-API-Key');
header('Content-Type: application/json');

// Handle preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}