<?php
$php_id = getenv('PHP_ID') ?: 'unknown';

$host = 'mysql';
$user = 'appuser';
$pass = '123456778';
$db = 'testdb';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$db", $user, $pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    $stmt = $pdo->query("SELECT NOW() as db_time, @@hostname as db_host");
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    
    echo json_encode([
        'status' => 'success',
        'php_instance' => $php_id,
        'db_time' => $row['db_time'],
        'db_host' => $row['db_host'],
        'client_ip' => $_SERVER['REMOTE_ADDR'] ?? 'unknown',
        'request_time' => date('Y-m-d H:i:s')
    ], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage()
    ]);
}
