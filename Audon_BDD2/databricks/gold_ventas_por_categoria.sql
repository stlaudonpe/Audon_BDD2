CREATE OR REPLACE VIEW workspace.default.gold_ventas_por_categoria AS
SELECT
    categoria,
    SUM(CAST(monto_vendido_q AS DECIMAL(22, 2))) AS ventas_q
FROM workspace.default.silver_productos
GROUP BY categoria;

SELECT categoria, ventas_q
FROM workspace.default.gold_ventas_por_categoria
ORDER BY ventas_q DESC;