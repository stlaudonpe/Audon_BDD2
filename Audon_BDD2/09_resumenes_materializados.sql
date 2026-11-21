USE ecommerce_db;

CREATE TABLE IF NOT EXISTS resumen_clientes_materializado (
    PRIMARY KEY (customer_id)
) ENGINE = InnoDB
AS
SELECT *
FROM vw_customer_summary;	

SELECT
    (SELECT COUNT(*) FROM vw_customer_summary) AS clientes_en_vista,
    COUNT(*) AS clientes_en_tabla,
    SUM(total_pedidos) AS pedidos_en_tabla,
    (SELECT COUNT(*) FROM orders) AS pedidos_en_origen,
    COUNT(CASE WHEN total_pedidos = 0 THEN 1 END) AS clientes_sin_pedidos
FROM resumen_clientes_materializado;

DELIMITER $$

CREATE PROCEDURE IF NOT EXISTS sp_refrescar_resumen_clientes()
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    DELETE FROM resumen_clientes_materializado;

    INSERT INTO resumen_clientes_materializado (
        customer_id, cliente, total_pedidos, monto_historico_pedidos,
        ticket_promedio, primer_pedido, ultimo_pedido
    )
    SELECT customer_id, cliente, total_pedidos, monto_historico_pedidos,
           ticket_promedio, primer_pedido, ultimo_pedido
    FROM vw_customer_summary;

    COMMIT;
END$$

DELIMITER ;

CALL sp_refrescar_resumen_clientes();

SELECT
    COUNT(*) AS clientes_en_vista,
    COUNT(r.customer_id) AS clientes_en_resumen_con_coincidencia,
    SUM(CASE
        WHEN r.customer_id IS NULL
          OR r.total_pedidos <> v.total_pedidos
          OR r.monto_historico_pedidos <> v.monto_historico_pedidos
        THEN 1 ELSE 0
    END) AS clientes_con_diferencias
FROM vw_customer_summary AS v
LEFT JOIN resumen_clientes_materializado AS r
    ON r.customer_id = v.customer_id;

