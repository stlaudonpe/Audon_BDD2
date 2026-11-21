CREATE USER IF NOT EXISTS 'replicador'@'%' IDENTIFIED BY 'demo_replica_2026';
GRANT REPLICATION SLAVE ON *.* TO 'replicador'@'%';
