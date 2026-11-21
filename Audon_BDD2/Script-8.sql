SELECT @@server_id AS servidor, @@read_only AS solo_lectura;

USE ecommerce_db;

CREATE TABLE IF NOT EXISTS product_price_history (
    history_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    product_id BIGINT UNSIGNED NOT NULL,
    old_price DECIMAL(12,2) NOT NULL,
    new_price DECIMAL(12,2) NOT NULL,
    changed_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    changed_by VARCHAR(288) NOT NULL
) ENGINE=InnoDB;

-- Requerimiento 1: auditar cambios efectivos en el precio.
CREATE TRIGGER IF NOT EXISTS trg_products_price_audit
AFTER UPDATE ON products
FOR EACH ROW
INSERT INTO product_price_history
    (product_id, old_price, new_price, changed_by)
SELECT OLD.product_id, OLD.unit_price, NEW.unit_price, USER()
WHERE OLD.unit_price <> NEW.unit_price;

START TRANSACTION;

UPDATE products
SET unit_price = unit_price + 1.00
WHERE sku = 'TEC-001';

UPDATE products
SET unit_price = unit_price
WHERE sku = 'TEC-001';

SELECT p.sku, h.old_price, h.new_price, h.changed_at, h.changed_by
FROM product_price_history AS h
JOIN products AS p ON p.product_id = h.product_id
WHERE p.sku = 'TEC-001'
ORDER BY h.history_id DESC;

-- ROLLBACK;


