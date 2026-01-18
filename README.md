Fraud Detection System - Transaction Monitoring
Overview
This project implements a simple transaction monitoring system designed to identify potentially fraudulent activities in financial transactions. It uses a PostgreSQL database with tables for users, transaction locations, transactions, and alerts.

The system applies several rules to detect suspicious behavior and generates alerts accordingly. This is a foundational example for fraud detection or compliance monitoring in financial systems.

Database Schema
users: Stores user details (name, email, registration timestamp).
locations: Stores location info (city, IP address, country).
transactions: Records user transactions, including amount, type, timestamp, and location.
alerts: Flags suspicious transactions based on defined detection rules.
Suspicious Activity Detection Rules
High-value transactions: Transactions over $10,000 are flagged.
Rapid multiple transactions: More than 2 transactions by the same user within the same minute are flagged.
Transactions from multiple countries: Users with transactions from 3 or more different countries are flagged.
Withdrawal bursts: More than 3 withdrawal transactions by the same user within any rolling 10-minute window are flagged.
Sample Data
3 users: Alice, Bob, and Charlie.
5 locations in different cities and countries.
Transactions include both normal and suspicious patterns, such as rapid withdrawals, high-value withdrawals, and multi-country activity.
Usage
Run the SQL script to create tables and insert sample data.
Alerts will be automatically generated based on the detection rules.
Query the alerts table joined with users and locations to view flagged transactions.
Example Query to View Alerts
SELECT a.alert_id, u.name, t.amount, t.txn_time, l.country, a.alert_type, a.created_at
FROM alerts a
JOIN transactions t ON a.txn_id = t.txn_id
JOIN users u ON t.user_id = u.user_id
JOIN locations l ON t.location_id = l.location_id
ORDER BY a.created_at;
