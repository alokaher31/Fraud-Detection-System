-- Drop tables if they exist to start fresh
DROP TABLE IF EXISTS alerts, transactions, locations, users CASCADE;

-- Create Users table
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100),
    registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Locations table
CREATE TABLE locations (
    location_id SERIAL PRIMARY KEY,
    city VARCHAR(100),
    ip_address VARCHAR(50),
    country VARCHAR(100)
);

-- Create Transactions table
CREATE TABLE transactions (
    txn_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(user_id),
    amount DECIMAL(12,2),
    txn_type VARCHAR(20),
    txn_time TIMESTAMP,
    location_id INT REFERENCES locations(location_id)
);

-- Create Alerts table
CREATE TABLE alerts (
    alert_id SERIAL PRIMARY KEY,
    txn_id INT,
    alert_type VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample users
INSERT INTO users (name, email) VALUES
('Alice', 'alice@example.com'),
('Bob', 'bob@example.com'),
('Charlie', 'charlie@example.com');

-- Insert sample locations
INSERT INTO locations (city, ip_address, country) VALUES
('New York', '192.168.1.1', 'USA'),
('London', '203.0.113.5', 'UK'),
('Tokyo', '203.0.113.10', 'Japan'),
('Mumbai', '10.0.0.1', 'India'),
('Berlin', '192.0.2.10', 'Germany');

-- Insert sample transactions (Charlie - normal user)
INSERT INTO transactions (user_id, amount, txn_type, txn_time, location_id) VALUES
(3, 100, 'deposit', '2025-07-06 08:00:00', 1),
(3, 150, 'withdrawal', '2025-07-06 08:10:00', 1),
(3, 80, 'withdrawal', '2025-07-06 08:20:00', 1);

-- Alice's transactions - some suspicious ones
INSERT INTO transactions (user_id, amount, txn_type, txn_time, location_id) VALUES
(1, 300, 'withdrawal', '2025-07-06 10:00:00', 1),
(1, 250, 'withdrawal', '2025-07-06 10:01:00', 1),
(1, 400, 'withdrawal', '2025-07-06 10:02:00', 1),
(1, 15000, 'withdrawal', '2025-07-06 10:03:00', 1),
(1, 500, 'withdrawal', '2025-07-06 11:00:00', 2),
(1, 200, 'withdrawal', '2025-07-06 11:10:00', 3),
(1, 100, 'withdrawal', '2025-07-06 11:20:00', 4);

-- Bob's rapid withdrawals
INSERT INTO transactions (user_id, amount, txn_type, txn_time, location_id) VALUES
(2, 90, 'withdrawal', '2025-07-06 12:00:00', 5),
(2, 80, 'withdrawal', '2025-07-06 12:00:30', 5),
(2, 70, 'withdrawal', '2025-07-06 12:01:00', 5),
(2, 95, 'withdrawal', '2025-07-06 12:01:30', 5);

-- Rule 1: Flag transactions over $10,000
INSERT INTO alerts (txn_id, alert_type)
SELECT txn_id, 'High-value transaction'
FROM transactions
WHERE amount > 10000;

-- Rule 2: Flag more than 2 transactions in the same minute per user
WITH txn_counts AS (
    SELECT txn_id, user_id, txn_time,
           COUNT(*) OVER (PARTITION BY user_id, DATE_TRUNC('minute', txn_time)) AS txn_count
    FROM transactions
)
INSERT INTO alerts (txn_id, alert_type)
SELECT txn_id, 'Multiple transactions in the same minute'
FROM txn_counts
WHERE txn_count > 2;

-- Rule 3: Flag users with transactions from 3 or more countries
WITH country_check AS (
    SELECT user_id, COUNT(DISTINCT country) AS distinct_countries
    FROM transactions t
    JOIN locations l ON t.location_id = l.location_id
    GROUP BY user_id
    HAVING COUNT(DISTINCT country) >= 3
)
INSERT INTO alerts (txn_id, alert_type)
SELECT t.txn_id, 'Multiple countries detected'
FROM transactions t
JOIN locations l ON t.location_id = l.location_id
JOIN country_check cc ON t.user_id = cc.user_id;

-- Rule 4: Flag more than 3 withdrawals within 10-minute windows per user
WITH withdrawal_bursts AS (
    SELECT txn_id, user_id, txn_time,
           COUNT(*) OVER (
               PARTITION BY user_id
               ORDER BY txn_time
               RANGE BETWEEN INTERVAL '10 minutes' PRECEDING AND CURRENT ROW
           ) AS withdrawal_count
    FROM transactions
    WHERE txn_type = 'withdrawal'
)
INSERT INTO alerts (txn_id, alert_type)
SELECT txn_id, 'Withdrawal burst detected (10 min window)'
FROM withdrawal_bursts
WHERE withdrawal_count > 3;

-- Final: Show all alerts with user and location info
SELECT a.alert_id, u.name, t.amount, t.txn_time, l.country, a.alert_type, a.created_at
FROM alerts a
JOIN transactions t ON a.txn_id = t.txn_id
JOIN users u ON t.user_id = u.user_id
JOIN locations l ON t.location_id = l.location_id
ORDER BY a.created_at;
