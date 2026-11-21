CREATE OR REPLACE VIEW workspace.default.silver_pedidos AS
SELECT
    CAST(order_id AS BIGINT)              AS order_id,
    TRIM(order_number)                    AS order_number,
    CAST(ordered_at AS TIMESTAMP)         AS ordered_at,
    CAST(customer_id AS BIGINT)           AS customer_id,
    CAST(productos_distintos AS INT)      AS productos_distintos,
    CAST(unidades AS INT)                 AS unidades,
    CAST(total_pedido AS DECIMAL(18, 2))  AS total_pedido,
    UPPER(TRIM(estado_pedido))            AS estado_pedido,
    UPPER(TRIM(estado_ultimo_pago))       AS estado_ultimo_pago
FROM workspace.default.bronze_pedidos;

SELECT
    COUNT(*) AS filas_silver,
    COUNT(DISTINCT order_id) AS pedidos_distintos,
    COUNT(*) - COUNT(ordered_at) AS sin_fecha,
    COUNT(*) - COUNT(total_pedido) AS sin_importe
FROM workspace.default.silver_pedidos;