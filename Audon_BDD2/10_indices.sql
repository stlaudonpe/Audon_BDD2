SHOW INDEX FROM orders;

EXPLAIN
SELECT order_id, ordered_at, total_amount
FROM orders
WHERE customer_id = 1
ORDER BY ordered_at DESC, order_id DESC
LIMIT 5;

EXPLAIN
SELECT order_id, ordered_at, total_amount
FROM orders IGNORE INDEX (idx_orders_customer_date)
WHERE customer_id = 1
ORDER BY ordered_at DESC, order_id DESC
LIMIT 5;

USE ecommerce_db;

-- R10. Historial de pedidos de un cliente dentro de un rango de fechas.
-- EXPLAIN ANALYZE
SELECT
    o.order_id,
    o.ordered_at AS fecha,
    o.customer_id AS cliente,
    SUM(oi.quantity) AS unidades,
    o.total_amount AS total_pedido,
    o.status AS estado
FROM orders AS o
JOIN order_items AS oi ON oi.order_id = o.order_id
WHERE o.customer_id = 1
  AND o.ordered_at >= '2026-05-01'
  AND o.ordered_at <  '2026-06-01'
GROUP BY o.order_id, o.ordered_at, o.customer_id, o.total_amount, o.status
ORDER BY o.ordered_at DESC, o.order_id DESC;

-- R10. Plan de ejecución sin usar el índice de cliente y fecha. 
-- EXPLAIN ANALYZE
-- Ctrl + Shift + E
SELECT
    o.order_id,
    o.ordered_at AS fecha,
    o.customer_id AS cliente,
    SUM(oi.quantity) AS unidades,
    o.total_amount AS total_pedido,
    o.status AS estado
FROM orders AS o IGNORE INDEX (idx_orders_customer_date)
JOIN order_items AS oi ON oi.order_id = o.order_id
WHERE o.customer_id = 1
  AND o.ordered_at >= '2026-05-01'
  AND o.ordered_at < '2026-06-01'
GROUP BY o.order_id, o.ordered_at, o.customer_id, o.total_amount, o.status
ORDER BY o.ordered_at DESC, o.order_id DESC;