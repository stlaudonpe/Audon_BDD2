CREATE OR REPLACE VIEW workspace.default.gold_pedidos_mensuales AS
SELECT
    CAST(DATE_TRUNC('MONTH', ordered_at) AS DATE) AS mes,
    COUNT(*) AS pedidos,
    SUM(
        CASE WHEN estado_pedido = 'CANCELLED' THEN 1 ELSE 0 END
    ) AS pedidos_cancelados,
    SUM(
        CASE WHEN estado_pedido <> 'CANCELLED' THEN total_pedido ELSE 0 END
    ) AS importe_pedidos_q,
    COUNT_IF(
        estado_ultimo_pago = 'APPROVED'
        AND estado_pedido <> 'CANCELLED'
    ) AS pedidos_confirmados
FROM workspace.default.silver_pedidos
GROUP BY CAST(DATE_TRUNC('MONTH', ordered_at) AS DATE);

-- Consulta de control para la captura 14d
SELECT
    mes,
    pedidos,
    pedidos_cancelados,
    importe_pedidos_q,
    SUM(pedidos) OVER () AS pedidos_total_control
FROM workspace.default.gold_pedidos_mensuales
ORDER BY mes;