SELECT
    p.sku AS producto,
    w.code AS bodega,
    i.quantity_on_hand AS existencia_fisica,
    i.quantity_reserved AS reservado,
    i.quantity_on_hand - i.quantity_reserved AS disponible
FROM ecommerce_db.inventory AS i
JOIN ecommerce_db.products AS p ON p.product_id = i.product_id
JOIN ecommerce_db.warehouses AS w ON w.warehouse_id = i.warehouse_id
WHERE p.sku = 'TEC-001'
ORDER BY w.warehouse_id;

USE ecommerce_db;

-- Requerimiento 2. Identificar la bodega que despacha cada línea nueva.
-- Los detalles históricos conservan NULL porque el origen no indica bodega.
ALTER TABLE order_items
    ADD COLUMN warehouse_id INT UNSIGNED NULL,
    ADD CONSTRAINT fk_order_items_warehouse
        FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id);

DELIMITER $$

CREATE TRIGGER trg_order_items_inventory
BEFORE INSERT ON order_items
FOR EACH ROW
BEGIN
    IF NEW.warehouse_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Indique la bodega de salida.';
    END IF;

    UPDATE inventory
    SET quantity_on_hand = quantity_on_hand - NEW.quantity
    WHERE warehouse_id = NEW.warehouse_id
      AND product_id = NEW.product_id
      AND NEW.quantity > 0
      AND quantity_on_hand - quantity_reserved >= NEW.quantity;

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cantidad invalida o inventario insuficiente en la bodega.';
    END IF;
END$$

DELIMITER ;

START TRANSACTION;

SET @bodega = (SELECT warehouse_id FROM warehouses WHERE code = 'GT-CEN');
SET @precio = (SELECT unit_price FROM products WHERE sku = 'TEC-001');

INSERT INTO orders (
    order_number, customer_id, shipping_address_id,
    status, subtotal, total_amount
)
SELECT CONCAT('DEMO-', UUID_SHORT()), customer_id, address_id,
       'PAID', 2 * @precio, 2 * @precio
FROM addresses
ORDER BY address_id
LIMIT 1;

SET @pedido = LAST_INSERT_ID();

INSERT INTO order_items (
    order_id, product_id, warehouse_id, sku_snapshot,
    product_name_snapshot, quantity, unit_price, line_total
)
SELECT @pedido, product_id, @bodega, sku, name, 2, @precio, 2 * @precio
FROM products
WHERE sku = 'TEC-001';

INSERT INTO payments (order_id, payment_method, status, amount, paid_at)
VALUES (@pedido, 'CARD', 'APPROVED', 2 * @precio, NOW());

SELECT o.order_number AS pedido,
       d.sku_snapshot AS producto,
       w.code AS bodega,
       d.quantity AS unidades_vendidas,
       pg.status AS estado_pago,
       i.quantity_on_hand AS existencia_fisica,
       i.quantity_reserved AS reservado,
       i.quantity_on_hand - i.quantity_reserved AS disponible
FROM orders AS o
JOIN order_items AS d ON d.order_id = o.order_id
JOIN payments AS pg ON pg.order_id = o.order_id
JOIN warehouses AS w ON w.warehouse_id = d.warehouse_id
JOIN inventory AS i ON i.warehouse_id = d.warehouse_id
                   AND i.product_id = d.product_id
WHERE o.order_id = @pedido;

-- ROLLBACK;

SELECT
    @pedido AS id_pedido_de_prueba,
    (SELECT COUNT(*) FROM orders WHERE order_id = @pedido) AS pedidos,
    (SELECT COUNT(*) FROM order_items WHERE order_id = @pedido) AS detalles,
    (SELECT COUNT(*) FROM payments WHERE order_id = @pedido) AS pagos,
    i.quantity_on_hand AS existencia_fisica,
    i.quantity_reserved AS reservado,
    i.quantity_on_hand - i.quantity_reserved AS disponible
FROM inventory AS i
JOIN products AS p ON p.product_id = i.product_id
JOIN warehouses AS w ON w.warehouse_id = i.warehouse_id
WHERE p.sku = 'TEC-001' AND w.code = 'GT-CEN';