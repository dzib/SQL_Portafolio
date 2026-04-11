--Movimientos (tipo, monto, fecha, referencia)
INSERT INTO dbo.Movimientos (Tipo, Monto, Fecha, Referencia)
VALUES 
('Depósito',3000,GETDATE(),'Ref_001 | Banco'),
('Retiro',1500,DATEADD(DAY,-1,GETDATE()),'Ref_002 | ATM'),
('Pago',2000,DATEADD(DAY,-2,GETDATE()),'Ref_003 | Comercio'),
('Depósito',5000,DATEADD(DAY,-3,GETDATE()),'Ref_004 | Empresa'),
('Retiro',1000,DATEADD(DAY,-4,GETDATE()),'Ref_005 | Sucursal');