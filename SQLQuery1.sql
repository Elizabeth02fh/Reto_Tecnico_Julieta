create database PEDIDOS;
drop database PEDIDOS;
use PEDIDOS;
create table CAFE_PAGOS_TX (
	Usuario int,
	Transaccion int PRIMARY KEY,
	Dia Date, 
	Pedido Varchar(150),
	Total Varchar(15));

CREATE TABLE ENVIOS (
	Transaccion int, 
	Dia Date, 
	Barrio Varchar(25),
	Direccion Varchar(25), 
	Estado Varchar(15))

CREATE TABLE USUARIOS (
	Mes Varchar(10),
	Usuario int primary key, 
	Segmentacion varchar(15),
	Cantidad_cafes int, 
	cafe_gratis bit, 
	cafe_gratis_usado bit)

--para foreign key
ALTER TABLE CAFE_PAGOS_TX
ADD CONSTRAINT fk_Usuario FOREIGN KEY (Usuario)
REFERENCES USUARIOS (Usuario);

ALTER TABLE ENVIOS
ADD CONSTRAINT fk_Transaccion FOREIGN KEY (Transaccion)
REFERENCES CAFE_PAGOS_TX (Transaccion);

INSERT INTO USUARIOS (Mes,Usuario,Segmentacion,Cantidad_cafes,cafe_gratis,
cafe_gratis_usado)
VALUES ('2022-01', 100, 'Bronce', 4, 'False', 'False'), 
		('2022-01', 101, 'Gold', 20, 'True', 'True');

INSERT INTO CAFE_PAGOS_TX (Usuario, Transaccion, Dia, Pedido, Total)
VALUES (100, 100093, '2022-01-02', '[{‘cafe’:’latte’,’medida’:’venti’},{‘c
afe’:’cortado’,’medida’:’jarro’},{‘cafe’:’latte’,’medida’:’venti’}', '$500');
select * from CAFE_PAGOS_TX;

INSERT INTO ENVIOS (Transaccion, Dia, Barrio, Direccion, Estado)
VALUES (100093, '2022-01-02', 'Avenida siempre viva','Calle falsa 123', 'Entregado')

SELECT * FROM CAFE_PAGOS_TX;
SELECT * FROM ENVIOS;
SELECT * FROM USUARIOS;
/*1. Los diez clientes que más compraron en el mes*/
SELECT TOP 10
    Usuario,
    Mes,
    SUM(Cantidad_cafes) AS Total_Compras
FROM
    USUARIOS
GROUP BY
    Usuario, Mes
ORDER BY
    Total_Compras DESC;
/*2. Qué día de la semana es el más y menos concurrido del mes*/
SELECT TOP 1
    DATEPART(WEEKDAY, Dia) AS Dia_Semana,
    COUNT(*) AS Cantidad_Pedidos
FROM
    CAFE_PAGOS_TX
GROUP BY
    DATEPART(WEEKDAY, Dia)
ORDER BY
    Cantidad_Pedidos DESC;

SELECT TOP 1
    DATEPART(WEEKDAY, Dia) AS Dia_Semana,
    COUNT(*) AS Cantidad_Pedidos
FROM
    CAFE_PAGOS_TX
GROUP BY
    DATEPART(WEEKDAY, Dia)
ORDER BY
    Cantidad_Pedidos ASC;

/*3. Los cinco cafés más vendidos en el mes.*/
SELECT TOP 5
    Pedido AS Nombre_Cafe,
    SUM(Cantidad_cafes) AS Cantidad_Vendida
FROM
    CAFE_PAGOS_TX CPTX
JOIN
    USUARIOS U ON CPTX.Usuario = U.Usuario
WHERE
    U.Mes = '2022-01'  -- Reemplaza 'NombreDelMes' con el mes específico que estás buscando
GROUP BY
    Pedido
ORDER BY
    Cantidad_Vendida DESC;
/*4. Medir la cantidad de pedidos de delivery y pedidos en el café que hubo en el mes*/
-- Cantidad de pedidos de delivery en el mes
SELECT
    COUNT(*) AS Cantidad_Pedidos_Delivery
FROM
    ENVIOS
WHERE
    MONTH(Dia) = 11; -- Reemplaza 11 con el número de mes que estás buscando

-- Cantidad de pedidos en el café en el mes
SELECT
    COUNT(*) AS Cantidad_Pedidos_EnCafe
FROM
    CAFE_PAGOS_TX
WHERE
    MONTH(Dia) = 11; -- Reemplaza 11 con el número de mes que estás buscando

/*5. Las tres combinaciones (café y medida) más pedidas.*/
SELECT TOP 3
    Pedido AS Nombre_Cafe,
    COUNT(*) AS Cantidad_Pedidos
FROM
    CAFE_PAGOS_TX
GROUP BY
    Pedido
ORDER BY
    Cantidad_Pedidos DESC;

select * from CAFE_PAGOS_TX;

/*Al cerrar el día de trabajo se requiere actualizar la cantidad de cafés que consumieron los
usuarios y en caso de que tenga más de 5 cafés en el mes marcar que le corresponde un
café gratis .*/
-- Actualizar la cantidad de cafés consumidos por usuarios
UPDATE USUARIOS
SET Cantidad_cafes = (
    SELECT
        COUNT(*)
    FROM
        CAFE_PAGOS_TX CPTX
    WHERE
        CPTX.Usuario = USUARIOS.Usuario
        AND MONTH(CPTX.Dia) = MONTH(GETDATE())
);

-- Marcar que les corresponde un café gratis
UPDATE USUARIOS
SET cafe_gratis = 1
WHERE
    Cantidad_cafes > 5
    AND MONTH(GETDATE()) = Mes; -- Asumiendo que la columna Mes en USUARIOS almacena el mes actual

/*También la empresa quiere al cerrar el mes actualizar la segmentación de los usuarios, a
partir de las siguientes reglas:
● Platinum: Sí tuvo más de 30 pedidos (delivery o presencial) en el mes
● Gold: Sí tuvo más de 15 pedidos (delivery o presencial) en el mes
● Bronce: El resto de usuarios*/

-- Actualizar la segmentación de los usuarios al cerrar el mes
UPDATE USUARIOS
SET Segmentacion = 
    CASE
        WHEN (SELECT COUNT(*) FROM CAFE_PAGOS_TX WHERE Usuario = USUARIOS.Usuario AND MONTH(Dia) = MONTH(GETDATE())) > 30 THEN 'Platinum'
        WHEN (SELECT COUNT(*) FROM CAFE_PAGOS_TX WHERE Usuario = USUARIOS.Usuario AND MONTH(Dia) = MONTH(GETDATE())) > 15 THEN 'Gold'
        ELSE 'Bronce'
    END;

select * from USUARIOS;
select * from CAFE_PAGOS_TX;

/*CHALLENGE TÉCNICO
Se requiere modelar la atención de clientes en este café. Hoy contamos con 3 cajas para
atender a nuestros clientes. Se los atiende por orden de llegada. Para ello se cuenta con un
CSV con la siguiente información:
id_persona, orden de llegada (número entero)*/

CREATE TABLE AtencionClientes (
    id_persona INT PRIMARY KEY,
    orden_llegada INT,
    caja_asignada INT,
    atendido BIT DEFAULT 0
);

-- Ejemplo para generar números aleatorios entre 1 y 3 para una columna llamada "miColumna" en una tabla llamada "miTabla"
UPDATE AtencionClientes
SET caja_asignada = ABS(CHECKSUM(NEWID())) % 3 + 1; 

UPDATE AtencionClientes
SET atendido = ABS(CHECKSUM(NEWID())) % 2; 

/* Se requiere como output la información de qué persona fue atendida por qué caja. Enviar la
solución propuesta. Preferentemente en Python, en caso de no ser así aclarar en el código
lo que crea pertinente */

-- Consulta para obtener información sobre qué persona fue atendida por qué caja
SELECT
    id_persona,
    caja_asignada
FROM
    AtencionClientes
WHERE
    atendido = 1;

SELECT * FROM PEDIDOS.dbo.AtencionClientes;

