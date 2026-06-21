/*
Proyecto Final Base de Datos II
Sistema de Base de Datos para Tienda en Línea
Motor: MySQL 8.0+ / MySQL Workbench
Archivo 03: Rendimiento + EXPLAIN + Índices
*/

USE TiendaOnlineBD;

/* =====================================================
   A. CONSULTA COMPLEJA 1: PRODUCTOS TOP POR CATEGORÍA
   Ejecuta primero este EXPLAIN ANTES de crear índices.
   Guarda captura para el reporte.
   ===================================================== */

EXPLAIN FORMAT=JSON
SELECT *
FROM vw_productos_top_categoria_ultimo_mes;

/* Si tu MySQL es 8.0.18 o superior, también puedes usar:
EXPLAIN ANALYZE
SELECT * FROM vw_productos_top_categoria_ultimo_mes;
*/

/* =====================================================
   B. CONSULTA COMPLEJA 2: CLIENTES VIP
   Ejecuta primero este EXPLAIN ANTES de crear índices.
   Guarda captura para el reporte.
   ===================================================== */

EXPLAIN FORMAT=JSON
WITH gasto_cliente AS (
    SELECT
        u.usuario_id,
        u.nombre,
        u.email,
        SUM(o.total) AS gasto_acumulado,
        MAX(o.fecha_orden) AS ultima_compra
    FROM usuarios u
    INNER JOIN ordenes o
        ON o.usuario_id = u.usuario_id
    INNER JOIN orden_estatus oe
        ON oe.estatus_id = o.estatus_id
    WHERE oe.nombre IN ('Pagado', 'Enviado', 'Entregado')
    GROUP BY
        u.usuario_id,
        u.nombre,
        u.email
), promedio_general AS (
    SELECT AVG(gasto_acumulado) AS promedio_gasto
    FROM gasto_cliente
)
SELECT
    gc.usuario_id,
    gc.nombre,
    gc.email,
    gc.gasto_acumulado,
    gc.ultima_compra,
    DATEDIFF(NOW(), gc.ultima_compra) AS dias_sin_comprar,
    pg.promedio_gasto
FROM gasto_cliente gc
CROSS JOIN promedio_general pg
WHERE gc.gasto_acumulado > pg.promedio_gasto
  AND DATEDIFF(NOW(), gc.ultima_compra) > 30
ORDER BY gc.gasto_acumulado DESC;

/* =====================================================
   C. ÍNDICES PROPUESTOS
   Después de tomar capturas del EXPLAIN inicial,
   ejecuta estos índices y vuelve a correr los EXPLAIN.
   ===================================================== */

CREATE INDEX IX_ordenes_fecha_estatus_usuario
ON ordenes (fecha_orden, estatus_id, usuario_id);

CREATE INDEX IX_ordenes_usuario_estatus_fecha
ON ordenes (usuario_id, estatus_id, fecha_orden);

CREATE INDEX IX_orden_detalle_orden_variante
ON orden_detalle (orden_id, variante_id);

CREATE INDEX IX_orden_detalle_variante
ON orden_detalle (variante_id);

CREATE INDEX IX_producto_variantes_producto
ON producto_variantes (producto_id);

CREATE INDEX IX_productos_categoria
ON productos (categoria_id);

CREATE INDEX IX_carritos_usuario_estado
ON carritos (usuario_id, estado);

CREATE INDEX IX_carrito_detalle_carrito
ON carrito_detalle (carrito_id, variante_id);

CREATE INDEX IX_pagos_orden_metodo
ON pagos (orden_id, metodo_pago_id);

/* =====================================================
   D. EXPLAIN DESPUÉS DE LOS ÍNDICES
   Guarda capturas para comparar antes vs después.
   ===================================================== */

EXPLAIN FORMAT=JSON
SELECT *
FROM vw_productos_top_categoria_ultimo_mes;

EXPLAIN FORMAT=JSON
WITH gasto_cliente AS (
    SELECT
        u.usuario_id,
        u.nombre,
        u.email,
        SUM(o.total) AS gasto_acumulado,
        MAX(o.fecha_orden) AS ultima_compra
    FROM usuarios u
    INNER JOIN ordenes o
        ON o.usuario_id = u.usuario_id
    INNER JOIN orden_estatus oe
        ON oe.estatus_id = o.estatus_id
    WHERE oe.nombre IN ('Pagado', 'Enviado', 'Entregado')
    GROUP BY
        u.usuario_id,
        u.nombre,
        u.email
), promedio_general AS (
    SELECT AVG(gasto_acumulado) AS promedio_gasto
    FROM gasto_cliente
)
SELECT
    gc.usuario_id,
    gc.nombre,
    gc.email,
    gc.gasto_acumulado,
    gc.ultima_compra,
    DATEDIFF(NOW(), gc.ultima_compra) AS dias_sin_comprar,
    pg.promedio_gasto
FROM gasto_cliente gc
CROSS JOIN promedio_general pg
WHERE gc.gasto_acumulado > pg.promedio_gasto
  AND DATEDIFF(NOW(), gc.ultima_compra) > 30
ORDER BY gc.gasto_acumulado DESC;

/* =====================================================
   E. CONSULTAS DE VALIDACIÓN
   ===================================================== */

SHOW INDEX FROM ordenes;
SHOW INDEX FROM orden_detalle;
SHOW INDEX FROM producto_variantes;
SHOW INDEX FROM productos;
