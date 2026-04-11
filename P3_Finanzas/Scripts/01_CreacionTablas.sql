CREATE TABLE FinanzasDB.dbo.Movimientos (
    IdMovimiento INT PRIMARY KEY IDENTITY,
    Tipo NVARCHAR(20), -- Depósito, Retiro, Pago
    Monto DECIMAL(10,2),
    Fecha DATETIME,
    Referencia NVARCHAR(15)
);

---DROP TABLE Movimientos;

CREATE TABLE FinanzasDB.dbo.Usuarios (
    IdUsuario INT PRIMARY KEY IDENTITY,
    Nombre NVARCHAR(100),
    Email NVARCHAR(100),
    Ciudad NVARCHAR(100),
    Edad DECIMAL(10,2),
    FechaRegistro DATETIME
);

CREATE TABLE FinanzasDB.dbo.Cuentas (
    IdCuenta INT PRIMARY KEY IDENTITY,
    IdUsuario INT FOREIGN KEY REFERENCES FinanzasDB.dbo.Usuarios(IdUsuario),
    TipoCuenta NVARCHAR(50),
    Saldo DECIMAL(10,2),
    Banco NVARCHAR(20),
    FechaApertura DATETIME
);

CREATE TABLE FinanzasDB.dbo.Transacciones (
    IdTransaccion INT PRIMARY KEY IDENTITY,
    IdCuenta INT FOREIGN KEY REFERENCES FinanzasDB.dbo.Cuentas(IdCuenta),
    Monto DECIMAL(10,2),
    Tipo NVARCHAR(20),
    Categoria NVARCHAR(20),
    Fecha DATETIME
);

CREATE TABLE FinanzasDB.dbo.Categorias (
    IdCategoria INT PRIMARY KEY IDENTITY,
    Nombre NVARCHAR(100),
    Tipo NVARCHAR(20),
    Descripcion NVARCHAR(50),
    Estado NVARCHAR(10),
    FechaCreacion DATETIME
);

CREATE TABLE FinanzasDB.dbo.Presupuestos (
    IdPresupuesto INT PRIMARY KEY IDENTITY,
    IdUsuario INT FOREIGN KEY REFERENCES Usuarios(IdUsuario),
    IdCategoria INT FOREIGN KEY REFERENCES FinanzasDB.dbo.Categorias(IdCategoria),
    MontoAsignado DECIMAL(10,2),
    Periodo NVARCHAR(20),
    Estado NVARCHAR(10)
);



---Paso 1. Obtener los nombres exactos de las restricciones en la BD FinanzasDB
----SELECT name, parent_object_id 
----FROM sys.foreign_keys;

--Paso 2. Eliminar restricciones de claves foráneas
----ALTER TABLE Transacciones DROP CONSTRAINT FK__Transacci__IdCue__52593CB8;
----ALTER TABLE Cuentas DROP CONSTRAINT FK__Cuentas__IdUsuar__4F7CD00D;
----ALTER TABLE Presupuestos DROP CONSTRAINT FK__Presupues__IdUsu__5812160E;
----ALTER TABLE Presupuestos DROP CONSTRAINT FK__Presupues__IdCat__59063A47;

--Paso 3. Eliminar las tablas sin importar dependencias
----DROP TABLE IF EXISTS Transacciones;
----DROP TABLE IF EXISTS Presupuestos;
----DROP TABLE IF EXISTS Cuentas;
----DROP TABLE IF EXISTS Categorias;
----DROP TABLE IF EXISTS Usuarios;