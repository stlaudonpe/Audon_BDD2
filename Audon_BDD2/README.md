# Base de Datos II · Primer arranque
Luis Antonio Audon Perez · Carné 000141859

Desde esta carpeta, con Docker Desktop en ejecución (contenedores Linux) y Docker Compose v2, ejecutar:
```
docker compose up -d
docker compose wait verificar
docker compose logs verificar
docker compose ps
```
El primer arranque descarga MySQL y carga los dos SQL originales en un volumen nuevo. Esperar el mensaje OK. En una carga inicial se esperan 82 clientes, 30 productos, 1288 pedidos y 2576 líneas. En arranques posteriores la verificación compara ambas instancias respetando los cambios que se hayan hecho. Para repetirla: `docker compose run --rm verificar`.

En DBeaver crear dos conexiones MySQL a 127.0.0.1, base ecommerce_db, usuario root, contraseña demo_local_2026 (solo laboratorio local). Principal 3317, réplica 3318. Si DBeaver solicita recuperar la clave pública, habilitar allowPublicKeyRetrieval en las propiedades del controlador para estas conexiones locales.

**Captura 01.** Mostrar los dos servicios activos y ejecutar en ambas conexiones:
```sql
SELECT @@hostname AS contenedor, @@server_id AS servidor, @@read_only AS solo_lectura;
```
Principal debe mostrar 101/0 y réplica 102/1.

**Captura 02.** Guardar la salida de verificar con los cuatro conteos y el mensaje OK antes de modificar datos.

Para detener conservando los datos: `docker compose down`. Para continuar: `docker compose up -d`. El DDL original comienza borrando ecommerce_db. No volver a ejecutarlo sobre una base con avances. Los puertos publicados están limitados al equipo local y son configurables con PUERTO_PRINCIPAL y PUERTO_REPLICA.

Si la verificación falla, revisar `docker compose logs principal replica verificar`. En la conexión de réplica ejecutar `SHOW REPLICA STATUS;` y revisar Last_IO_Error y Last_SQL_Error antes de tocar los volúmenes.

Este bloque cubre infraestructura y carga inicial. Databricks, roles de aplicación, lógica de ventas y pruebas funcionales corresponden a los siguientes bloques.
