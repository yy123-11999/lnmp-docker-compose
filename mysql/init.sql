CREATE TABLE IF NOT EXISTS visitors (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ip VARCHAR(45) NOT NULL,
    php_instance VARCHAR(10),
    visit_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    user_agent VARCHAR(255)
);

INSERT INTO visitors (ip, php_instance, user_agent) 
VALUES ('127.0.0.1', 'init', 'test');
