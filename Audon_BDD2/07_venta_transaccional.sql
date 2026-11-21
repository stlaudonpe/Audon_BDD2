USE ecommerce_db;

DELIMITER $$

CREATE PROCEDURE IF NOT EXISTS sp_registrar_venta(
    IN p_numero VARCHAR(30),
    IN p_cliente BIGINT UNSIGNED,
    IN p_direccion BIGINT UNSIGNED,
    IN p_bodega INT UNSIGNED,
    IN p_productos JSON
)
BEGIN
    DECLARE v_pedido BIGINT UNSIGNED;
    DECLARE v_indice INT DEFAULT 0;
    DECLARE v_sku VARCHAR(40);
    DECLARE v_cantidad INT;
    DECLARE v_total DECIMAL(12,2);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    IF p_productos IS NULL OR NOT JSON_SCHEMA_VALID(
        '{"type":"array","minItems":1,"items":{"type":"object",
          "required":["sku","cantidad"],
          "properties":{"sku":{"type":"string","minLength":1,"maxLength":40},
          "cantidad":{"type":"integer","minimum":1,"maximum":2147483647}}}}',
        p_productos
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Revise los productos y sus cantidades.';
    END IF;

    INSERT INTO orders (
        order_number, customer_id, shipping_address_id,
        status, subtotal, total_amount
    )
    SELECT p_numero, customer_id, address_id, 'PAID', 0, 0
    FROM addresses
    WHERE address_id = p_direccion AND customer_id = p_cliente;

    IF ROW_COUNT() <> 1 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La direccion no corresponde al cliente.';
    END IF;

    SET v_pedido = LAST_INSERT_ID();

    WHILE v_indice < JSON_LENGTH(p_productos) DO
        SET v_sku = JSON_UNQUOTE(JSON_EXTRACT(
            p_productos, CONCAT('$[', v_indice, '].sku')
        ));
        SET v_cantidad = JSON_EXTRACT(
            p_productos, CONCAT('$[', v_indice, '].cantidad')
        );

        INSERT INTO order_items (
            order_id, product_id, warehouse_id, sku_snapshot,
            product_name_snapshot, quantity, unit_price, line_total
        )
        SELECT v_pedido, product_id, p_bodega, sku, name,
               v_cantidad, unit_price, v_cantidad * unit_price
        FROM products
        WHERE sku = v_sku AND status = 'ACTIVE';

        IF ROW_COUNT() <> 1 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Producto inexistente o inactivo.';
        END IF;

        SET v_indice = v_indice + 1;
    END WHILE;

    SELECT SUM(line_total) INTO v_total
    FROM order_items WHERE order_id = v_pedido;

    UPDATE orders
    SET subtotal = v_total, total_amount = v_total
    WHERE order_id = v_pedido;

    INSERT INTO payments (order_id, payment_method, status, amount, paid_at)
    VALUES (v_pedido, 'CARD', 'APPROVED', v_total, NOW());

    COMMIT;
END$$

DELIMITER ;

SET @numero = CONCAT('TEST-', UUID_SHORT());
SET @bodega = (SELECT warehouse_id FROM warehouses WHERE code = 'GT-CEN');

SELECT customer_id, address_id INTO @cliente, @direccion
FROM addresses ORDER BY address_id LIMIT 1;

SELECT
    MAX(CASE WHEN p.sku = 'TEC-001' THEN i.quantity_on_hand - i.quantity_reserved END),
    MAX(CASE WHEN p.sku = 'TEC-002' THEN i.quantity_on_hand - i.quantity_reserved END)
INTO @antes_1, @antes_2
FROM inventory AS i
JOIN products AS p ON p.product_id = i.product_id
WHERE i.warehouse_id = @bodega;

CALL sp_registrar_venta(
    @numero, @cliente, @direccion, @bodega,
    JSON_ARRAY(
        JSON_OBJECT('sku', 'TEC-001', 'cantidad', 2),
        JSON_OBJECT('sku', 'TEC-002', 'cantidad', @antes_2 + 1)
    )
);

SELECT
    @numero AS intento_de_venta,
    p.sku,
    CASE p.sku WHEN 'TEC-001' THEN @antes_1 ELSE @antes_2 END AS antes,
    i.quantity_on_hand - i.quantity_reserved AS despues,
    (SELECT COUNT(*) FROM orders WHERE order_number = @numero) AS pedidos_guardados
FROM inventory AS i
JOIN products AS p ON p.product_id = i.product_id
WHERE i.warehouse_id = @bodega AND p.sku IN ('TEC-001', 'TEC-002')
ORDER BY p.sku;

SET @venta_ok = CONCAT('OK-', UUID_SHORT());

CALL sp_registrar_venta(
    @venta_ok, @cliente, @direccion, @bodega,
    JSON_ARRAY(
        JSON_OBJECT('sku', 'TEC-001', 'cantidad', 2),
        JSON_OBJECT('sku', 'TEC-002', 'cantidad', 1)
    )
);

SELECT
    o.order_number AS pedido,
    d.sku_snapshot AS producto,
    d.quantity AS unidades,
    w.code AS bodega,
    i.quantity_on_hand - i.quantity_reserved AS disponible,
    o.total_amount AS total_pedido,
    pg.amount AS monto_pago,
    pg.status AS estado_pago
FROM orders AS o
JOIN order_items AS d ON d.order_id = o.order_id
JOIN warehouses AS w ON w.warehouse_id = d.warehouse_id
JOIN inventory AS i ON i.warehouse_id = d.warehouse_id
                   AND i.product_id = d.product_id
JOIN payments AS pg ON pg.order_id = o.order_id
WHERE o.order_number = @venta_ok
ORDER BY d.sku_snapshot;

SELECT d.sku_snapshot AS producto,
       d.quantity AS unidades,
       d.unit_price AS precio_unitario,
       d.line_total AS total_linea
FROM order_items AS d
JOIN orders AS o ON o.order_id = d.order_id
WHERE o.order_number = @venta_ok
ORDER BY d.sku_snapshot;
