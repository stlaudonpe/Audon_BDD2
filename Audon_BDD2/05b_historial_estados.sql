USE ecommerce_db;

CREATE TABLE IF NOT EXISTS order_status_history (
    history_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT UNSIGNED NOT NULL,
    old_status VARCHAR(20) NOT NULL,
    new_status VARCHAR(20) NOT NULL,
    changed_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    changed_by VARCHAR(288) NOT NULL
) ENGINE=InnoDB;

-- Requerimiento 3: registrar cada cambio efectivo de estado.
CREATE TRIGGER IF NOT EXISTS trg_orders_status_audit
AFTER UPDATE ON orders
FOR EACH ROW
INSERT INTO order_status_history
    (order_id, old_status, new_status, changed_by)
SELECT NEW.order_id, OLD.status, NEW.status, USER()
WHERE OLD.status <> NEW.status;

START TRANSACTION;

SET @pedido = (
    SELECT MIN(order_id) FROM orders WHERE status = 'PAID'
);

SET @ultimo_historial = (
    SELECT COALESCE(MAX(history_id), 0) FROM order_status_history
);

UPDATE orders SET status = 'PROCESSING' WHERE order_id = @pedido;
UPDATE orders SET status = 'PROCESSING' WHERE order_id = @pedido;

SELECT order_id, old_status, new_status, changed_at, changed_by
FROM order_status_history
WHERE order_id = @pedido AND history_id > @ultimo_historial;

-- ROLLBACK;

SELECT order_id, status
FROM orders
WHERE order_id = 13;