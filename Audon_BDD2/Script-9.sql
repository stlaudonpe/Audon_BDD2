SELECT @@server_id AS servidor, @@read_only AS solo_lectura;

SELECT
    @@server_id AS servidor,
    @@read_only AS solo_lectura,
    order_number AS pedido,
    productos_distintos,
    unidades,
    total_pedido,
    estado_ultimo_pago
FROM ecommerce_db.vw_order_summary
WHERE order_number = 'OK-7307933076011614210';

SHOW REPLICA STATUS;