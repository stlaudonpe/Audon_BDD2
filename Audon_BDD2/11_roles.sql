SELECT
    FROM_USER AS rol,
    TO_USER AS usuario,
    TO_HOST AS host_usuario
FROM mysql.role_edges
ORDER BY rol, usuario, host_usuario;

CREATE ROLE IF NOT EXISTS 'rol_reportes';

GRANT SELECT ON ecommerce_db.vw_order_summary TO 'rol_reportes';
GRANT SELECT ON ecommerce_db.vw_customer_summary TO 'rol_reportes';
GRANT SELECT ON ecommerce_db.vw_inventory_status TO 'rol_reportes';

SHOW GRANTS FOR 'rol_reportes';

CREATE USER IF NOT EXISTS 'lector_reportes'@'%'
IDENTIFIED BY RANDOM PASSWORD;

GRANT 'rol_reportes' TO 'lector_reportes'@'%';
SET DEFAULT ROLE 'rol_reportes' TO 'lector_reportes'@'%';

-- R11. Administrador de la base de datos del proyecto.
CREATE ROLE IF NOT EXISTS 'rol_admin_ecommerce';

GRANT ALL PRIVILEGES ON ecommerce_db.*
TO 'rol_admin_ecommerce';

CREATE USER IF NOT EXISTS 'db_admin'@'%'
IDENTIFIED BY 'DemoLocal_Admin2026!';

GRANT 'rol_admin_ecommerce' TO 'db_admin'@'%';

SET DEFAULT ROLE 'rol_admin_ecommerce' TO 'db_admin'@'%';

-- Comprobar los permisos que recibe el usuario mediante su rol.
SHOW GRANTS FOR 'db_admin'@'%' USING 'rol_admin_ecommerce';

-- R11. Usuario de aplicación para registrar ventas.
CREATE ROLE IF NOT EXISTS 'rol_app_ventas';

GRANT EXECUTE ON PROCEDURE ecommerce_db.sp_registrar_venta
TO 'rol_app_ventas';

-- Credencial de demostración para el entorno local.
CREATE USER IF NOT EXISTS 'ecommerce_app'@'%'
IDENTIFIED BY 'DemoLocal_App2026!';

GRANT 'rol_app_ventas' TO 'ecommerce_app'@'%';

SET DEFAULT ROLE 'rol_app_ventas' TO 'ecommerce_app'@'%';

SHOW GRANTS FOR 'ecommerce_app'@'%' USING 'rol_app_ventas';

-- R11. Analista con lectura sobre vistas y resúmenes materializados.
CREATE USER IF NOT EXISTS 'bi_analyst'@'%'
IDENTIFIED BY 'DemoLocal_BI2026!';

GRANT 'rol_reportes' TO 'bi_analyst'@'%';
SET DEFAULT ROLE 'rol_reportes' TO 'bi_analyst'@'%';

GRANT SELECT ON ecommerce_db.resumen_clientes_materializado
TO 'bi_analyst'@'%';

GRANT SELECT ON ecommerce_db.mv_daily_sales
TO 'bi_analyst'@'%';

GRANT SELECT ON ecommerce_db.mv_product_performance
TO 'bi_analyst'@'%';

SHOW GRANTS FOR 'bi_analyst'@'%' USING 'rol_reportes';