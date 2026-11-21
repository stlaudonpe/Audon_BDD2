
USE ecommerce_db;

CREATE TABLE IF NOT EXISTS mv_daily_sales (
    fecha DATE PRIMARY KEY,
    pedidos BIGINT NOT NULL,
    clientes_distintos BIGINT NOT NULL,
    unidades_vendidas BIGINT NOT NULL,
    total_vendido DECIMAL(22,2) NOT NULL,
    ticket_promedio DECIMAL(22,2) NOT NULL,
    venta_mayor DECIMAL(22,2) NOT NULL,
    venta_menor DECIMAL(22,2) NOT NULL
) ENGINE = InnoDB;

DELIMITER $$
CREATE PROCEDURE IF NOT EXISTS sp_refrescar_ventas_diarias()
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    DELETE FROM mv_daily_sales;
    INSERT INTO mv_daily_sales (
        fecha, pedidos, clientes_distintos, unidades_vendidas,
        total_vendido, ticket_promedio, venta_mayor, venta_menor
    )
    SELECT DATE(ordered_at), COUNT(*), COUNT(DISTINCT customer_id),
           SUM(unidades), SUM(total_pedido), ROUND(AVG(total_pedido), 2),
           MAX(total_pedido), MIN(total_pedido)
    FROM vw_order_summary
    WHERE estado_ultimo_pago = 'APPROVED'
      AND estado_pedido <> 'CANCELLED'
    GROUP BY DATE(ordered_at);
    COMMIT;
END$$
DELIMITER ;

CALL sp_refrescar_ventas_diarias();

-- Evidencia. Comparar la fecha de la venta de prueba contra el origen.
SELECT d.*, c.pedidos AS pedidos_origen, c.total AS total_origen,
       CASE WHEN d.pedidos = c.pedidos AND d.total_vendido = c.total
            THEN 'COINCIDE' ELSE 'REVISAR' END AS control_pedidos_e_importe
FROM mv_daily_sales AS d
JOIN (
    SELECT DATE(ordered_at) AS fecha, COUNT(*) AS pedidos, SUM(total_pedido) AS total
    FROM vw_order_summary
    WHERE estado_ultimo_pago = 'APPROVED' AND estado_pedido <> 'CANCELLED'
    GROUP BY DATE(ordered_at)
) AS c ON c.fecha = d.fecha
WHERE d.fecha = (SELECT DATE(ordered_at) FROM orders
                 WHERE order_number = 'OK-7307933076011614210');
