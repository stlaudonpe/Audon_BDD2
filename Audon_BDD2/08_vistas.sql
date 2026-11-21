USE ecommerce_db;

-- Requerimiento 4: resumen general de pedidos.
CREATE OR REPLACE VIEW vw_order_summary AS
SELECT
    o.order_id,
    o.order_number,
    o.ordered_at,
    o.customer_id,
    CONCAT_WS(' ', c.first_name, c.last_name) AS cliente,
    COALESCE(d.productos_distintos, 0) AS productos_distintos,
    COALESCE(d.unidades, 0) AS unidades,
    o.subtotal,
    o.total_amount AS total_pedido,
    o.status AS estado_pedido,
    (
        SELECT pg.status
        FROM payments AS pg
        WHERE pg.order_id = o.order_id
        ORDER BY pg.created_at DESC, pg.payment_id DESC
        LIMIT 1
    ) AS estado_ultimo_pago
FROM orders AS o
JOIN customers AS c ON c.customer_id = o.customer_id
LEFT JOIN (
    SELECT order_id,
           COUNT(DISTINCT product_id) AS productos_distintos,
           SUM(quantity) AS unidades
    FROM order_items
    GROUP BY order_id
) AS d ON d.order_id = o.order_id;

SELECT order_number AS pedido, cliente, productos_distintos, unidades,
       subtotal, total_pedido, estado_pedido, estado_ultimo_pago
FROM vw_order_summary
WHERE order_number = 'OK-7307933076011614210';

CREATE OR REPLACE VIEW vw_customer_summary AS
SELECT
    c.customer_id,
    CONCAT_WS(' ', c.first_name, c.last_name) AS cliente,
    COUNT(o.order_id) AS total_pedidos,
    COALESCE(SUM(o.total_amount), 0) AS monto_historico_pedidos,
    ROUND(AVG(o.total_amount), 2) AS ticket_promedio,
    MIN(o.ordered_at) AS primer_pedido,
    MAX(o.ordered_at) AS ultimo_pedido
FROM customers AS c
LEFT JOIN orders AS o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name;

SELECT *
FROM vw_customer_summary
WHERE customer_id IN (1, 81, 82)
ORDER BY customer_id;

CREATE OR REPLACE VIEW vw_inventory_status AS
SELECT
    p.sku,
    p.name AS producto,
    w.code AS bodega,
    i.quantity_on_hand AS existencia_fisica,
    i.quantity_reserved AS reservado,
    i.quantity_on_hand - i.quantity_reserved AS disponible,
    CASE
        WHEN i.quantity_on_hand <= i.quantity_reserved THEN 'AGOTADO'
        WHEN i.quantity_on_hand - i.quantity_reserved <= 10 THEN 'BAJO'
        ELSE 'NORMAL'
    END AS estado_inventario
FROM inventory AS i
JOIN products AS p ON p.product_id = i.product_id
JOIN warehouses AS w ON w.warehouse_id = i.warehouse_id;

SELECT sku, bodega, existencia_fisica, reservado, disponible, estado_inventario
FROM vw_inventory_status
WHERE sku = 'TEC-001'
ORDER BY bodega;