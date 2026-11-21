# Ecommerce · Proyecto final de Base de Datos II

**Luis Antonio Audon Perez · Carné 000141859 · UPANA**

Proyecto de comercio electrónico con MySQL 8.0.40, una instancia principal y una réplica en Docker. El dashboard de Databricks presenta los pedidos y las ventas en quetzales.

## Primer arranque

Con Git instalado, Docker en ejecución y Docker Compose v2 disponible, ejecutá:

```bash
git clone https://github.com/stlaudonpe/Audon_BDD2.git
cd Audon_BDD2/Audon_BDD2
docker compose up -d
docker compose wait verificar
docker compose logs verificar
```

El mensaje `OK` en el registro de `verificar` confirma que terminó la comprobación de la carga y la réplica.

## Documentación y dashboard

- [Guía de arranque y conexiones en DBeaver](Audon_BDD2/README.md)
- [Ver el dashboard de pedidos y ventas en PDF](Audon_BDD2/Dashboard_Ecommerce.pdf)
- [Consultas y datos de Databricks](Audon_BDD2/databricks/)
- [Guía completa del proyecto (PDF): orden de los scripts SQL, usuarios, Databricks, respaldo y restauración](Audon_BDD2/README.pdf)
