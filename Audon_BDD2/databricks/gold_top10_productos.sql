CREATE VIEW workspace.default.gold_top10_productos AS
SELECT
    product_id,
    producto,
    categoria,
    unidades_vendidas,
    CAST(monto_vendido_q AS DECIMAL(22, 2)) AS ventas_q
FROM workspace.default.silver_productos
WHERE unidades_vendidas > 0
ORDER BY ventas_q DESC, product_id
LIMIT 10;

SELECT producto, categoria, unidades_vendidas, ventas_q
FROM workspace.default.gold_top10_productos
ORDER BY ventas_q DESC, product_id;