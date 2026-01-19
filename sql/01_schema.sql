-- 01_schema.sql
-- Crea "app" con tablas normalizadas, índices y rol con permisos limitados

BEGIN;

-- 1) Esquema separado para no usar "public"
CREATE SCHEMA IF NOT EXISTS app;

-- 2) Tablas

CREATE TABLE IF NOT EXISTS app.clientes (
  cliente_id  BIGSERIAL PRIMARY KEY,
  nombre      TEXT NOT NULL,
  email       TEXT NOT NULL UNIQUE,
  telefono    TEXT,
  creado_en   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS app.ordenes (
  orden_id     BIGSERIAL PRIMARY KEY,
  cliente_id   BIGINT NOT NULL REFERENCES app.clientes(cliente_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  fecha_orden  TIMESTAMPTZ NOT NULL DEFAULT now(),
  estado       TEXT NOT NULL DEFAULT 'PENDIENTE', -- PENDIENTE / PAGADA / CANCELADA
  total        NUMERIC(12,2) NOT NULL CHECK (total >= 0)
);

CREATE TABLE IF NOT EXISTS app.pagos (
  pago_id    BIGSERIAL PRIMARY KEY,
  orden_id   BIGINT NOT NULL REFERENCES app.ordenes(orden_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  fecha_pago TIMESTAMPTZ NOT NULL DEFAULT now(),
  monto      NUMERIC(12,2) NOT NULL CHECK (monto > 0),
  metodo     TEXT NOT NULL DEFAULT 'TARJETA' -- TARJETA / EFECTIVO / TRANSFERENCIA
);

-- 3) Índices útiles (para consultas típicas)
-- Buscar órdenes por cliente rápidamente
CREATE INDEX IF NOT EXISTS idx_ordenes_cliente_id ON app.ordenes(cliente_id);

-- Buscar órdenes recientes/por estado (reportes y seguimiento)
CREATE INDEX IF NOT EXISTS idx_ordenes_estado_fecha ON app.ordenes(estado, fecha_orden DESC);

-- 4) Rol con permisos limitados
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_user') THEN
    CREATE ROLE app_user LOGIN PASSWORD 'app_user_password';
  END IF;
END$$;

-- Permisos mínimos:
-- - Conectar a la base
GRANT CONNECT ON DATABASE dba_starter TO app_user;

-- - Usar el esquema app
GRANT USAGE ON SCHEMA app TO app_user;

-- - Leer y modificar datos (sin borrar, sin cambiar estructura)
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA app TO app_user;

-- Para que futuras tablas también hereden permisos (buena práctica)
ALTER DEFAULT PRIVILEGES IN SCHEMA app
GRANT SELECT, INSERT, UPDATE ON TABLES TO app_user;

-- Importante para BIGSERIAL (sequences)
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA app TO app_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA app
GRANT USAGE, SELECT ON SEQUENCES TO app_user;

COMMIT;
