CREATE VIEW workspace.default.silver_productos AS
SELECT
    product_id,
    CASE WHEN producto LIKE '%Ã%'
         THEN decode(encode(producto, 'ISO-8859-1'), 'UTF-8')
         ELSE producto
    END AS producto,
    CASE WHEN categoria LIKE '%Ã%'
         THEN decode(encode(categoria, 'ISO-8859-1'), 'UTF-8')
         ELSE categoria
    END AS categoria,
    unidades_vendidas,
    pedidos_distintos,
    monto_vendido_q,
    precio_promedio_venta_q,
    fecha_ultima_venta
FROM workspace.default.productos;

SELECT product_id, producto, categoria
FROM workspace.default.silver_productos
WHERE product_id IN (2, 20)
ORDER BY product_id;