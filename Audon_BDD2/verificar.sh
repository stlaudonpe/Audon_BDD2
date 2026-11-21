set -eu -o pipefail
consulta() { mysql --connect-timeout=5 -uroot -h "$1" -NBe "$2"; }
if [ -z "$(consulta replica 'SHOW REPLICA STATUS')" ]; then
  consulta replica "CHANGE REPLICATION SOURCE TO SOURCE_HOST='principal', SOURCE_USER='replicador', SOURCE_PASSWORD='demo_replica_2026', SOURCE_AUTO_POSITION=1, GET_SOURCE_PUBLIC_KEY=1; START REPLICA;"
fi
posicion=$(consulta principal 'SELECT @@GLOBAL.gtid_executed')
if [ "$(consulta replica "SELECT WAIT_FOR_EXECUTED_GTID_SET('$posicion',90)")" != 0 ]; then
  consulta replica 'SHOW REPLICA STATUS\G'
  exit 1
fi
for host in principal replica; do
  echo "$host | servidor, solo lectura"
  consulta "$host" 'SELECT @@server_id, @@read_only'
done
sql='SELECT (SELECT COUNT(*) FROM customers), (SELECT COUNT(*) FROM products), (SELECT COUNT(*) FROM orders), (SELECT COUNT(*) FROM order_items) FROM DUAL'
principal=$(consulta principal "USE ecommerce_db; $sql")
replica=$(consulta replica "USE ecommerce_db; $sql")
echo "Clientes | Productos | Pedidos | Detalles"
echo "$principal"
test "$principal" = "$replica"
echo "OK: GTID alcanzado y conteos iguales en principal y réplica."
