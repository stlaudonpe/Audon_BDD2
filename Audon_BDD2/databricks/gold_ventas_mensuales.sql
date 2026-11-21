CREATE OR REPLACE VIEW workspace.default.gold_ventas_mensuales AS
SELECT
    CAST(DATE_TRUNC('MONTH', ordered_at) AS DATE) AS mes,
    COUNT(*) AS pedidos_confirmados,
    SUM(total_pedido) AS ventas_q
FROM workspace.default.silver_pedidos
WHERE estado_ultimo_pago = 'APPROVED'
  AND estado_pedido <> 'CANCELLED'
GROUP BY CAST(DATE_TRUNC('MONTH', ordered_at) AS DATE);

SELECT
    mes,
    pedidos_confirmados,
    ventas_q,
    SUM(pedidos_confirmados) OVER () AS pedidos_confirmados_control,
    SUM(ventas_q) OVER () AS ventas_confirmadas_control_q
FROM workspace.default.gold_ventas_mensuales
ORDER BY mes;