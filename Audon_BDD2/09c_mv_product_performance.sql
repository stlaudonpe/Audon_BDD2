-- R8. Rendimiento por producto. MySQL 8.0.40.
-- Ejecutar en la principal después de instalar vw_order_summary (R4).
USE ecommerce_db;

CREATE TABLE IF NOT EXISTS mv_product_performance (
    product_id BIGINT UNSIGNED PRIMARY KEY,
    producto VARCHAR(180) NOT NULL,
    categoria VARCHAR(100) NOT NULL,
    unidades_vendidas BIGINT UNSIGNED NOT NULL,
    pedidos_distintos BIGINT UNSIGNED NOT NULL,
    monto_vendido_q DECIMAL(22,2) NOT NULL,
    precio_promedio_venta_q DECIMAL(14,2),
    fecha_ultima_venta DATE
) ENGINE = InnoDB;

DELIMITER $$
CREATE PROCEDURE IF NOT EXISTS sp_refrescar_rendimiento_productos()
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    DELETE FROM mv_product_performance;

    INSERT INTO mv_product_performance (
        product_id, producto, categoria, unidades_vendidas,
        pedidos_distintos, monto_vendido_q, precio_promedio_venta_q, fecha_ultima_venta
    )
    SELECT p.product_id, p.name,
           COALESCE((
               SELECT c.name
               FROM product_categories pc
               JOIN categories c ON c.category_id = pc.category_id
               WHERE pc.product_id = p.product_id
               ORDER BY pc.is_primary DESC, pc.category_id
               LIMIT 1
           ), 'Sin categoría'),
           COALESCE(v.unidades, 0), COALESCE(v.pedidos, 0),
           COALESCE(v.monto, 0), ROUND(v.monto / NULLIF(v.unidades, 0), 2),
           v.ultima_venta
    FROM products p
    LEFT JOIN (
        SELECT i.product_id, SUM(i.quantity) AS unidades,
               COUNT(DISTINCT i.order_id) AS pedidos, SUM(i.line_total) AS monto,
               DATE(MAX(o.ordered_at)) AS ultima_venta
        FROM order_items i
        JOIN vw_order_summary o ON o.order_id = i.order_id
        WHERE o.estado_ultimo_pago = 'APPROVED' AND o.estado_pedido <> 'CANCELLED'
        GROUP BY i.product_id
    ) v ON v.product_id = p.product_id;

    COMMIT;
END$$
DELIMITER ;

CALL sp_refrescar_rendimiento_productos();

-- Control de cobertura y conciliación con las líneas de venta.
SELECT r.productos_en_resumen, p.productos_en_catalogo,
       r.unidades AS unidades_resumen, d.unidades AS unidades_origen,
       r.monto AS monto_resumen_q, d.monto AS monto_origen_q,
       CASE WHEN r.productos_en_resumen = p.productos_en_catalogo
                 AND r.unidades = d.unidades AND r.monto = d.monto
            THEN 'COINCIDE' ELSE 'REVISAR' END AS control
FROM (SELECT COUNT(*) AS productos_en_resumen,
             COALESCE(SUM(unidades_vendidas), 0) AS unidades,
             COALESCE(SUM(monto_vendido_q), 0) AS monto
      FROM mv_product_performance) r
CROSS JOIN (SELECT COUNT(*) AS productos_en_catalogo FROM products) p
CROSS JOIN (SELECT COALESCE(SUM(i.quantity), 0) AS unidades,
                   COALESCE(SUM(i.line_total), 0) AS monto
            FROM order_items i JOIN vw_order_summary o ON o.order_id = i.order_id
            WHERE o.estado_ultimo_pago = 'APPROVED' AND o.estado_pedido <> 'CANCELLED') d;

-- Evidencia R8. Top 10 por monto vendido.
SELECT product_id, producto, categoria, unidades_vendidas, pedidos_distintos,
       monto_vendido_q, precio_promedio_venta_q, fecha_ultima_venta
FROM mv_product_performance
WHERE unidades_vendidas > 0
ORDER BY monto_vendido_q DESC, product_id
LIMIT 10;
