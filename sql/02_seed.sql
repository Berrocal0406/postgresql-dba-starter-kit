-- 02_seed.sql
-- Datos base mínimos para pruebas

BEGIN;

INSERT INTO app.clientes (nombre, email, telefono)
VALUES
  ('Juan Pérez', 'juan.perez@email.com', '555-111-1111'),
  ('Ana López', 'ana.lopez@email.com', '555-222-2222'),
  ('Carlos Ruiz', 'carlos.ruiz@email.com', '555-333-3333');

INSERT INTO app.ordenes (cliente_id, estado, total)
VALUES
  (1, 'PENDIENTE', 1500.00),
  (1, 'PAGADA', 2300.50),
  (2, 'PAGADA', 999.99);

INSERT INTO app.pagos (orden_id, monto, metodo)
VALUES
  (2, 2300.50, 'TARJETA'),
  (3, 999.99, 'EFECTIVO');

COMMIT;
