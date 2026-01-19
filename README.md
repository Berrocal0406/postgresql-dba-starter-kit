# PostgreSQL DBA Starter Kit (Docker) — Mini Proyecto

Mini proyecto práctico para demostrar bases de **DBA**:
- Entorno reproducible con Docker Compose (PostgreSQL + pgAdmin)
- Esquema normalizado (clientes, ordenes, pagos) con PK/FK + índices
- Rol con permisos limitados (`app_user`)
- Carga de datos por SQL (seed) y por CSV (`COPY`)
- Backups y restore con `pg_dump` / `pg_restore`
- Monitoreo básico con queries (`pg_stat_activity`, `pg_locks`, tamaños)

> Repo pensado para principiantes y para mostrar evidencia real en CV.

---

## Requisitos
- Windows 11
- Docker Desktop instalado y corriendo | WSL
- Git Bash (o PowerShell) para ejecutar comandos

---

## Estructura del repo

```
/
  README.md
  docker-compose.yml
  /sql
    01_schema.sql
    02_seed.sql
    03_monitoring.sql
  /scripts
    backup.sh
    restore.sh
  /data
    sample_clientes.csv
    sample_ordenes.csv
  /backups        # se crea al ejecutar backup (no se sube a git)
  .gitignore
```

---

## Levantar el entorno (PostgreSQL + pgAdmin)

En la raíz del proyecto:

```bash
docker compose up -d
docker ps
```

Servicios:
- PostgreSQL: `localhost:5432`
- pgAdmin: `http://localhost:5050`

Credenciales (demo):
- Postgres:
  - DB: `dba_starter`
  - User: `postgres`
  - Password: `postgres`
- pgAdmin:
  - Email: `admin@local.com`
  - Password: `admin`

### Conectar pgAdmin al servidor (opcional recomendado)
En pgAdmin:
- Register → Server
  - Name: `DBA Starter (Docker)`
  - Host: `db` (nombre del servicio en docker compose)
  - Port: `5432`
  - Maintenance DB: `dba_starter`
  - User: `postgres`
  - Password: `postgres`

---

## Correr scripts SQL (schema + seed + monitoreo)

### 1) Crear tablas, índices y rol
```bash
docker exec -i pg_dba_starter_db psql -U postgres -d dba_starter < sql/01_schema.sql
```

Validar tablas:
```bash
docker exec -it pg_dba_starter_db psql -U postgres -d dba_starter -c "\dt app.*"
```

### 2) Insertar datos de ejemplo (seed)
```bash
docker exec -i pg_dba_starter_db psql -U postgres -d dba_starter < sql/02_seed.sql
```

Validar:
```bash
docker exec -it pg_dba_starter_db psql -U postgres -d dba_starter -c "SELECT * FROM app.clientes;"
```

### 3) Monitoreo básico
```bash
docker exec -i pg_dba_starter_db psql -U postgres -d dba_starter < sql/03_monitoring.sql
```

---

## Cargar CSV (COPY)

Archivos de ejemplo:
- `data/sample_clientes.csv`
- `data/sample_ordenes.csv`

**Importante (tip):** `COPY FROM` lee archivos **desde el servidor** (el contenedor), no desde tu máquina.  
Por eso primero copiamos el CSV al contenedor:

```bash
docker cp data/sample_clientes.csv pg_dba_starter_db:/var/lib/postgresql/data/sample_clientes.csv
docker cp data/sample_ordenes.csv pg_dba_starter_db:/var/lib/postgresql/data/sample_ordenes.csv
```

Luego ejecutamos `COPY`:

```bash
docker exec -it pg_dba_starter_db psql -U postgres -d dba_starter -c "\
COPY app.clientes(nombre,email,telefono)
FROM '/var/lib/postgresql/data/sample_clientes.csv'
DELIMITER ',' CSV HEADER;"
```

```bash
docker exec -it pg_dba_starter_db psql -U postgres -d dba_starter -c "\
COPY app.ordenes(cliente_id,estado,total)
FROM '/var/lib/postgresql/data/sample_ordenes.csv'
DELIMITER ',' CSV HEADER;"
```

Validar:
```bash
docker exec -it pg_dba_starter_db psql -U postgres -d dba_starter -c "SELECT count(*) FROM app.clientes;"
```

**Alternativa:** `\copy` (client-side)  
Si trabajas con `psql` en tu máquina (no en contenedor), `\copy` permite leer archivos locales. En este repo usamos Docker, por eso preferimos `docker cp + COPY`.

---

## Backup y Restore

### Backup (pg_dump)
Crea un backup en `backups/` (no se sube a git):

```bash
./scripts/backup.sh
```

Salida esperada:
- `backups/dba_starter_YYYYMMDD_HHMMSS.dump`

### Restore (pg_restore)
Restaura desde un archivo `.dump`:

```bash
./scripts/restore.sh backups/dba_starter_YYYYMMDD_HHMMSS.dump
```

El restore usa:
- `pg_restore --clean --if-exists` (limpia objetos antes de recrearlos)

---

## Troubleshooting (rápido)

### Puerto 5432 ocupado
Cambia en `docker-compose.yml`:
```yaml
ports:
  - "5433:5432"
```
y reinicia:
```bash
docker compose down
docker compose up -d
```

### pgAdmin no abre en 5050
Cambia a `5051:80` en `docker-compose.yml`.

### Error: COPY no encuentra archivo
Ejemplo:
`could not open file ... No such file or directory`

Solución:
- Copiar el CSV al contenedor con `docker cp`
- Luego ejecutar `COPY` apuntando a la ruta interna del contenedor.

---

## Qué aprendí (DBA basics)
- Levantar un entorno reproducible de PostgreSQL con Docker Compose
- Diseñar un esquema normalizado
- Aplicar el principio de menor privilegio creando un rol de aplicación con permisos limitados
- Cargar datos con `COPY` desde CSV y validar integridad referencial
- Generar backups con `pg_dump` y restaurar con `pg_restore` (prueba real de recuperación)
- Consultas básicas de monitoreo: sesiones activas, locks y tamaños de BD/tablas
