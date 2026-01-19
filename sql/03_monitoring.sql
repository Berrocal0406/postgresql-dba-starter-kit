-- 03_monitoring.sql
-- Consultas básicas de monitoreo para DBA junior

-- 1) Sesiones activas
-- Muestra quién está conectado, desde dónde, y qué está ejecutando.
SELECT
  pid,
  usename,
  application_name,
  client_addr,
  state,
  now() - query_start AS duracion,
  left(query, 120) AS query_preview
FROM pg_stat_activity
WHERE datname = current_database()
ORDER BY query_start DESC;

-- 2) Locks simples
-- Si hay bloqueos, muestra quién bloquea y a quién.
SELECT
  blocked.pid     AS blocked_pid,
  blocked_user.usename AS blocked_user,
  blocking.pid    AS blocking_pid,
  blocking_user.usename AS blocking_user,
  blocked_activity.query  AS blocked_query,
  blocking_activity.query AS blocking_query
FROM pg_locks blocked
JOIN pg_stat_activity blocked_activity ON blocked_activity.pid = blocked.pid
JOIN pg_user blocked_user ON blocked_user.usesysid = blocked_activity.usesysid
JOIN pg_locks blocking ON blocking.locktype = blocked.locktype
  AND blocking.database IS NOT DISTINCT FROM blocked.database
  AND blocking.relation IS NOT DISTINCT FROM blocked.relation
  AND blocking.page IS NOT DISTINCT FROM blocked.page
  AND blocking.tuple IS NOT DISTINCT FROM blocked.tuple
  AND blocking.virtualxid IS NOT DISTINCT FROM blocked.virtualxid
  AND blocking.transactionid IS NOT DISTINCT FROM blocked.transactionid
  AND blocking.classid IS NOT DISTINCT FROM blocked.classid
  AND blocking.objid IS NOT DISTINCT FROM blocked.objid
  AND blocking.objsubid IS NOT DISTINCT FROM blocked.objsubid
  AND blocking.pid <> blocked.pid
JOIN pg_stat_activity blocking_activity ON blocking_activity.pid = blocking.pid
JOIN pg_user blocking_user ON blocking_user.usesysid = blocking_activity.usesysid
WHERE NOT blocked.granted
ORDER BY blocked.pid;

-- 3) Tamaño de base de datos (en formato legible)
SELECT
  current_database() AS db,
  pg_size_pretty(pg_database_size(current_database())) AS db_size;

-- 4) Tamaño de tablas del esquema app (incluye índices)
SELECT
  schemaname,
  relname AS table_name,
  pg_size_pretty(pg_total_relation_size(schemaname || '.' || relname)) AS total_size,
  pg_size_pretty(pg_relation_size(schemaname || '.' || relname)) AS table_size
FROM pg_stat_user_tables
WHERE schemaname = 'app'
ORDER BY pg_total_relation_size(schemaname || '.' || relname) DESC;
