/*
Proyecto Final Base de Datos II
Sistema de Base de Datos para Tienda en Línea
Motor: MySQL 8.0+ / MySQL Workbench
Archivo 01: DDL + DML + datos masivos
*/

DROP DATABASE IF EXISTS TiendaOnlineBD;
CREATE DATABASE TiendaOnlineBD
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE TiendaOnlineBD;

/* =========================
   1. TABLAS BASE
   ========================= */

CREATE TABLE roles (
    rol_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE usuarios (
    usuario_id INT AUTO_INCREMENT PRIMARY KEY,
    rol_id INT NOT NULL,
    nombre VARCHAR(120) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    activo TINYINT(1) NOT NULL DEFAULT 1,
    fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_usuarios_roles
        FOREIGN KEY (rol_id) REFERENCES roles(rol_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE direcciones (
    direccion_id INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id INT NOT NULL,
    calle VARCHAR(150) NOT NULL,
    ciudad VARCHAR(80) NOT NULL,
    estado VARCHAR(80) NOT NULL,
    codigo_postal VARCHAR(10) NOT NULL,
    pais VARCHAR(80) NOT NULL DEFAULT 'México',
    principal TINYINT(1) NOT NULL DEFAULT 0,
    CONSTRAINT fk_direcciones_usuarios
        FOREIGN KEY (usuario_id) REFERENCES usuarios(usuario_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE categorias (
    categoria_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion VARCHAR(255),
    categoria_padre_id INT NULL,
    CONSTRAINT fk_categorias_padre
        FOREIGN KEY (categoria_padre_id) REFERENCES categorias(categoria_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE productos (
    producto_id INT AUTO_INCREMENT PRIMARY KEY,
    categoria_id INT NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    descripcion TEXT,
    activo TINYINT(1) NOT NULL DEFAULT 1,
    fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_productos_categorias
        FOREIGN KEY (categoria_id) REFERENCES categorias(categoria_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE producto_variantes (
    variante_id INT AUTO_INCREMENT PRIMARY KEY,
    producto_id INT NOT NULL,
    sku VARCHAR(80) NOT NULL UNIQUE,
    talla VARCHAR(30) NULL,
    color VARCHAR(50) NULL,
    especificacion VARCHAR(100) NULL,
    precio DECIMAL(10,2) NOT NULL,
    stock INT NOT NULL DEFAULT 0,
    activo TINYINT(1) NOT NULL DEFAULT 1,
    CONSTRAINT chk_variante_precio CHECK (precio >= 0),
    CONSTRAINT chk_variante_stock CHECK (stock >= 0),
    CONSTRAINT fk_variantes_productos
        FOREIGN KEY (producto_id) REFERENCES productos(producto_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE historial_precios (
    historial_id INT AUTO_INCREMENT PRIMARY KEY,
    variante_id INT NOT NULL,
    precio_anterior DECIMAL(10,2) NOT NULL,
    precio_nuevo DECIMAL(10,2) NOT NULL,
    fecha_cambio DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_historial_variantes
        FOREIGN KEY (variante_id) REFERENCES producto_variantes(variante_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE carritos (
    carrito_id INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id INT NOT NULL,
    estado ENUM('Abierto','Cerrado','Abandonado') NOT NULL DEFAULT 'Abierto',
    fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_carritos_usuarios
        FOREIGN KEY (usuario_id) REFERENCES usuarios(usuario_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE carrito_detalle (
    carrito_detalle_id INT AUTO_INCREMENT PRIMARY KEY,
    carrito_id INT NOT NULL,
    variante_id INT NOT NULL,
    cantidad INT NOT NULL,
    fecha_agregado DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_carrito_cantidad CHECK (cantidad > 0),
    CONSTRAINT uq_carrito_variante UNIQUE (carrito_id, variante_id),
    CONSTRAINT fk_carrito_detalle_carritos
        FOREIGN KEY (carrito_id) REFERENCES carritos(carrito_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_carrito_detalle_variantes
        FOREIGN KEY (variante_id) REFERENCES producto_variantes(variante_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE orden_estatus (
    estatus_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE metodos_pago (
    metodo_pago_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(80) NOT NULL UNIQUE,
    activo TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB;

CREATE TABLE ordenes (
    orden_id INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id INT NOT NULL,
    carrito_id INT NULL,
    direccion_envio_id INT NULL,
    estatus_id INT NOT NULL,
    total DECIMAL(12,2) NOT NULL DEFAULT 0,
    stock_descontado TINYINT(1) NOT NULL DEFAULT 0,
    fecha_orden DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_orden_total CHECK (total >= 0),
    CONSTRAINT fk_ordenes_usuarios
        FOREIGN KEY (usuario_id) REFERENCES usuarios(usuario_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_ordenes_carritos
        FOREIGN KEY (carrito_id) REFERENCES carritos(carrito_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    CONSTRAINT fk_ordenes_direcciones
        FOREIGN KEY (direccion_envio_id) REFERENCES direcciones(direccion_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    CONSTRAINT fk_ordenes_estatus
        FOREIGN KEY (estatus_id) REFERENCES orden_estatus(estatus_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE orden_detalle (
    orden_detalle_id INT AUTO_INCREMENT PRIMARY KEY,
    orden_id INT NOT NULL,
    variante_id INT NOT NULL,
    cantidad INT NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(12,2) GENERATED ALWAYS AS (cantidad * precio_unitario) STORED,
    CONSTRAINT chk_orden_detalle_cantidad CHECK (cantidad > 0),
    CONSTRAINT chk_orden_detalle_precio CHECK (precio_unitario >= 0),
    CONSTRAINT fk_orden_detalle_ordenes
        FOREIGN KEY (orden_id) REFERENCES ordenes(orden_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_orden_detalle_variantes
        FOREIGN KEY (variante_id) REFERENCES producto_variantes(variante_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE pagos (
    pago_id INT AUTO_INCREMENT PRIMARY KEY,
    orden_id INT NOT NULL,
    metodo_pago_id INT NOT NULL,
    monto DECIMAL(12,2) NOT NULL,
    estatus ENUM('Pendiente','Aprobado','Rechazado') NOT NULL DEFAULT 'Pendiente',
    fecha_pago DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    referencia VARCHAR(100) NULL,
    CONSTRAINT chk_pago_monto CHECK (monto >= 0),
    CONSTRAINT fk_pagos_ordenes
        FOREIGN KEY (orden_id) REFERENCES ordenes(orden_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_pagos_metodos
        FOREIGN KEY (metodo_pago_id) REFERENCES metodos_pago(metodo_pago_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE envio_estatus (
    envio_estatus_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE envios (
    envio_id INT AUTO_INCREMENT PRIMARY KEY,
    orden_id INT NOT NULL UNIQUE,
    envio_estatus_id INT NOT NULL,
    numero_guia VARCHAR(100) NULL,
    paqueteria VARCHAR(80) NULL,
    fecha_envio DATETIME NULL,
    fecha_entrega DATETIME NULL,
    CONSTRAINT fk_envios_ordenes
        FOREIGN KEY (orden_id) REFERENCES ordenes(orden_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_envios_estatus
        FOREIGN KEY (envio_estatus_id) REFERENCES envio_estatus(envio_estatus_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

/* =========================
   2. CARGA INICIAL Y MASIVA
   ========================= */

DELIMITER $$

CREATE PROCEDURE sp_cargar_datos_iniciales()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE v_producto_id INT;
    DECLARE v_usuario_id INT;
    DECLARE v_direccion_id INT;
    DECLARE v_variante_id INT;
    DECLARE v_precio DECIMAL(10,2);
    DECLARE v_cantidad INT;
    DECLARE v_total DECIMAL(12,2);
    DECLARE v_orden_id INT;
    DECLARE v_fecha DATETIME;
    DECLARE v_estatus_id INT;
    DECLARE v_envio_estatus_id INT;

    INSERT INTO roles (nombre, descripcion) VALUES
    ('Cliente', 'Usuario que realiza compras en la tienda en línea'),
    ('Administrador', 'Usuario con permisos de administración');

    INSERT INTO orden_estatus (nombre, descripcion) VALUES
    ('Procesando', 'La orden fue creada y está en revisión'),
    ('Pagado', 'El pago fue aprobado'),
    ('Enviado', 'La orden fue enviada por paquetería'),
    ('Entregado', 'La orden fue entregada al cliente'),
    ('Cancelado', 'La orden fue cancelada');

    INSERT INTO envio_estatus (nombre, descripcion) VALUES
    ('Pendiente', 'El envío aún no sale del almacén'),
    ('En tránsito', 'El paquete se encuentra en camino'),
    ('Entregado', 'El paquete fue entregado'),
    ('Devuelto', 'El paquete fue devuelto');

    INSERT INTO metodos_pago (nombre, activo) VALUES
    ('Tarjeta de crédito', 1),
    ('Tarjeta de débito', 1),
    ('Transferencia bancaria', 1),
    ('PayPal', 1);

    INSERT INTO usuarios (rol_id, nombre, email, password_hash) VALUES
    (2, 'Administrador General', 'admin@tienda.com', SHA2('admin123', 256)),
    (1, 'Cliente Demo', 'cliente.demo@tienda.com', SHA2('cliente123', 256));

    INSERT INTO direcciones (usuario_id, calle, ciudad, estado, codigo_postal, principal) VALUES
    (2, 'Av. Principal 100', 'Tlaxcala', 'Tlaxcala', '90000', 1);

    INSERT INTO categorias (nombre, descripcion) VALUES
    ('Ropa', 'Ropa para dama y caballero'),
    ('Electrónica', 'Dispositivos electrónicos'),
    ('Hogar', 'Artículos para el hogar'),
    ('Deportes', 'Productos deportivos'),
    ('Belleza', 'Productos de cuidado personal');

    SET i = 1;
    WHILE i <= 50 DO
        INSERT INTO productos (categoria_id, nombre, descripcion, activo)
        VALUES (((i - 1) MOD 5) + 1,
                CONCAT('Producto ', i),
                CONCAT('Descripción del producto ', i),
                1);

        SET v_producto_id = LAST_INSERT_ID();

        INSERT INTO producto_variantes
        (producto_id, sku, talla, color, especificacion, precio, stock, activo)
        VALUES
        (v_producto_id,
         CONCAT('SKU-', LPAD(i, 3, '0'), '-A'),
         'M',
         'Negro',
         'Variante estándar',
         100 + (i * 7),
         5000,
         1),
        (v_producto_id,
         CONCAT('SKU-', LPAD(i, 3, '0'), '-B'),
         'G',
         'Azul',
         'Variante alternativa',
         120 + (i * 7),
         5000,
         1);

        SET i = i + 1;
    END WHILE;

    SET i = 1;
    WHILE i <= 500 DO
        INSERT INTO usuarios (rol_id, nombre, email, password_hash)
        VALUES (1,
                CONCAT('Cliente ', i),
                CONCAT('cliente', i, '@correo.com'),
                SHA2(CONCAT('pass', i), 256));

        SET v_usuario_id = LAST_INSERT_ID();

        INSERT INTO direcciones (usuario_id, calle, ciudad, estado, codigo_postal, principal)
        VALUES (v_usuario_id,
                CONCAT('Calle ', i),
                'Tlaxcala',
                'Tlaxcala',
                LPAD(90000 + (i MOD 999), 5, '0'),
                1);

        SET i = i + 1;
    END WHILE;

    /* Carrito de prueba para ejecutar el checkout */
    INSERT INTO carritos (usuario_id, estado) VALUES (2, 'Abierto');

    INSERT INTO carrito_detalle (carrito_id, variante_id, cantidad) VALUES
    (1, 1, 2),
    (1, 2, 1);

    /* 10,000 órdenes simuladas para rendimiento y analítica */
    SET i = 1;
    WHILE i <= 10000 DO
        SET v_usuario_id = 3 + ((i - 1) MOD 500);
        SET v_direccion_id = 2 + ((i - 1) MOD 500);
        SET v_variante_id = 1 + ((i - 1) MOD 100);
        SET v_cantidad = 1 + (i MOD 3);
        SET v_fecha = DATE_SUB(NOW(), INTERVAL (i MOD 90) DAY);

        SELECT precio INTO v_precio
        FROM producto_variantes
        WHERE variante_id = v_variante_id;

        SET v_total = v_precio * v_cantidad;

        IF (i MOD 3) = 0 THEN
            SET v_estatus_id = 4; /* Entregado */
            SET v_envio_estatus_id = 3;
        ELSEIF (i MOD 3) = 1 THEN
            SET v_estatus_id = 3; /* Enviado */
            SET v_envio_estatus_id = 2;
        ELSE
            SET v_estatus_id = 2; /* Pagado */
            SET v_envio_estatus_id = 1;
        END IF;

        INSERT INTO ordenes
        (usuario_id, carrito_id, direccion_envio_id, estatus_id, total, stock_descontado, fecha_orden)
        VALUES
        (v_usuario_id, NULL, v_direccion_id, v_estatus_id, v_total, 1, v_fecha);

        SET v_orden_id = LAST_INSERT_ID();

        INSERT INTO orden_detalle
        (orden_id, variante_id, cantidad, precio_unitario)
        VALUES
        (v_orden_id, v_variante_id, v_cantidad, v_precio);

        INSERT INTO pagos
        (orden_id, metodo_pago_id, monto, estatus, fecha_pago, referencia)
        VALUES
        (v_orden_id, 1 + (i MOD 4), v_total, 'Aprobado', v_fecha, CONCAT('PAY-', LPAD(i, 8, '0')));

        INSERT INTO envios
        (orden_id, envio_estatus_id, numero_guia, paqueteria, fecha_envio, fecha_entrega)
        VALUES
        (v_orden_id,
         v_envio_estatus_id,
         CONCAT('TRK-', LPAD(i, 8, '0')),
         'Paquetería Demo',
         CASE WHEN v_estatus_id IN (3,4) THEN DATE_ADD(v_fecha, INTERVAL 1 DAY) ELSE NULL END,
         CASE WHEN v_estatus_id = 4 THEN DATE_ADD(v_fecha, INTERVAL 4 DAY) ELSE NULL END);

        SET i = i + 1;
    END WHILE;
END$$

CALL sp_cargar_datos_iniciales()$$
DROP PROCEDURE sp_cargar_datos_iniciales$$

DELIMITER ;

/* =========================
   3. VERIFICACIÓN RÁPIDA
   ========================= */

SELECT 'usuarios' AS tabla, COUNT(*) AS total FROM usuarios
UNION ALL SELECT 'productos', COUNT(*) FROM productos
UNION ALL SELECT 'producto_variantes', COUNT(*) FROM producto_variantes
UNION ALL SELECT 'ordenes', COUNT(*) FROM ordenes
UNION ALL SELECT 'orden_detalle', COUNT(*) FROM orden_detalle
UNION ALL SELECT 'pagos', COUNT(*) FROM pagos
UNION ALL SELECT 'envios', COUNT(*) FROM envios;
