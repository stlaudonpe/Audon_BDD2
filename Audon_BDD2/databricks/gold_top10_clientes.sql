CREATE OR REPLACE VIEW workspace.default.gold_top10_clientes AS
SELECT
    customer_id,
    FORMAT_STRING('Cliente%03d Apellido%03d', customer_id, customer_id) AS cliente,
    COUNT(*) AS pedidos_confirmados,
    SUM(total_pedido) AS monto_comprado_q
FROM workspace.default.silver_pedidos
WHERE estado_ultimo_pago = 'APPROVED'
  AND estado_pedido <> 'CANCELLED'
GROUP BY customer_id
ORDER BY monto_comprado_q DESC, customer_id
LIMIT 10;

SELECT cliente, pedidos_confirmados, monto_comprado_q
FROM workspace.default.gold_top10_clientes
ORDER BY monto_comprado_q DESC, customer_id;