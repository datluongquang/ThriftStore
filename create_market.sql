--Dat Luong
USE master
GO

IF DB_ID('luongdq') IS NOT NULL
	DROP DATABASE luongdq
GO

CREATE DATABASE luongdq
GO 

USE luongdq
GO

CREATE TABLE Users(
	UserId			INT				PRIMARY KEY		IDENTITY,
	username		varchar(50)		NOT NULL,
	password		varchar(50)		NOT NULL,
	BankAccountId	bigint			NOT NULL,
	SellerOrBuyer	varchar(10)		NOT NULL
)
GO

CREATE TABLE Products(
	ProductId		INT				PRIMARY KEY		IDENTITY,
	Name			VARCHAR(50)		NOT NULL,
	Description		VARCHAR(MAX)	NOT NULL,
	Category		VARCHAR(50)		NOT NULL,
	Price			float			NOT NULL,
	UserId			INT				FOREIGN KEY		REFERENCES Users(UserId),
	Status			varchar(50)		NOT NULL
)
GO

CREATE TABLE Orders(
	OrderId			INT				PRIMARY KEY		IDENTITY,
	OrderDate		DATE			NOT NULL,
	UserId			INT				FOREIGN KEY		REFERENCES Users(UserId)
)
GO


CREATE TABLE Cart(
	CartId			INT				PRIMARY KEY		IDENTITY,
	UserId			INT				FOREIGN KEY		REFERENCES Users(UserId)
)
GO

CREATE TABLE OrderProduct(
	OrderProductId	INT				PRIMARY KEY		IDENTITY,
	OrderId			INT				FOREIGN KEY 	REFERENCES Orders(OrderId),
	ProductId		INT				FOREIGN KEY 	REFERENCES Products(ProductId)
)
GO

CREATE TABLE ProductCart(
	ProductCartId	INT				PRIMARY KEY		IDENTITY,
	ProductId			INT				FOREIGN KEY 	REFERENCES Products(ProductId),
	CartId			INT				FOREIGN KEY 	REFERENCES Cart(CartId)
)
GO

CREATE PROCEDURE LogIn(		@username varchar(50),
							@password varchar(50))
AS	
	SELECT	*
	FROM Users
	WHERE	username = @Username COLLATE SQL_Latin1_General_CP1_CS_AS
			AND password = @Password COLLATE SQL_Latin1_General_CP1_CS_AS
GO

CREATE PROCEDURE newUser(	@username		varchar(50),
							@password		varchar(50),
							@BankAccountId	bigint,
							@SellerOrBuyer	varchar(10))
AS
	BEGIN
	IF NOT EXISTS (	SELECT * 
					FROM Users
					WHERE username = @username
				 )	
		BEGIN
			INSERT INTO Users (username,password,BankAccountId,SellerOrBuyer) VALUES(@username,@password,@BankAccountId,@SellerOrBuyer)
			SELECT [return] = 'Success'
		END
	ELSE
		BEGIN
			SELECT [return] = 'username already exist'
		END
	END
GO

CREATE PROCEDURE postItem(	@UserId			INT,
							@Name			VARCHAR(50),
							@Description	VARCHAR(MAX),
							@Category		VARCHAR(50),
							@Price			FLOAT)
AS
	INSERT INTO Products ( UserId , Name, Description, Category ,Price, Status)
	VALUES (@UserId, @Name, @Description,@Category, @Price, 'Available')
GO

CREATE PROCEDURE removeItem(@ProductId		INT)
AS
	DELETE FROM Products
	WHERE ProductId = @ProductId
GO

CREATE Procedure addToCart(	@ProductId		INT,
							@UserId			INT	)
AS
	BEGIN
		UPDATE Products 
		SET Status='Sold' WHERE ProductId=@ProductId
		IF NOT EXISTS (	SELECT * 
						FROM Cart
						WHERE UserId = @UserId)
			BEGIN
				INSERT INTO Cart (UserId) VALUES (@UserId)
			END
		DECLARE @CartId Int
		SET @CartId = (SELECT CartId FROM Cart WHERE UserId=@UserId)
		INSERT INTO ProductCart(CartId,ProductId) VALUES(@CartId,@ProductId)
	END
GO

CREATE PROCEDURE checkOut(	@UserId			INT,
							@OrderDate		date)
AS
	BEGIN
		DECLARE @CartId Int, @OrderId INT
		SET @CartId = (SELECT CartId FROM Cart WHERE UserId=@UserId)
		BEGIN
			UPDATE Products
			SET Status='Sold'
			WHERE ProductId IN (SELECT ProductId
								FROM ProductCart
								WHERE CartId=@CartId
								)
		END
		BEGIN
			INSERT INTO Orders(UserId,OrderDate) VALUES (@UserId,@OrderDate)
		END
		BEGIN
			SET @OrderId=(SELECT TOP (1) OrderId FROM Orders ORDER BY OrderId DESC)
			INSERT INTO OrderProduct(OrderId,ProductID) 
			SELECT	[OrderId]=@OrderId,
					ProductId
			FROM	ProductCart
			WHERE	CartId=@CartId
		END
		BEGIN
			DELETE FROM ProductCart WHERE CartId=@CartId
		END
	END
GO

CREATE PROCEDURE findItemByCategory(	@Category	Varchar(50))
AS
	SELECT	* 
	FROM	Products 
	WHERE	Category=@Category
		AND	Status= 'Available'	
GO

CREATE PROCEDURE ShowOrder(	@UserId	INT)
AS
	SELECT	OrderDate, op.ProductId, Description,Category,Price,o.UserId
	FROM	Orders o JOIN
			OrderProduct op ON o.OrderId=op.OrderId
			JOIN Products p
			ON op.ProductId= p.ProductId
	WHERE	o.UserId=@UserId
	ORDER BY o.OrderId
GO

CREATE PROCEDURE showItem(	@UserId INT)
AS
	SELECT	*
	FROM	Products
	WHERE	UserId= @UserId
GO

CREATE PROCEDURE showCart(	@UserId INT)
AS
	SELECT	*
	FROM	ProductCart pc
			JOIN Cart c
			ON pc.CartId=c.CartId
			JOIN Products p
			ON p.ProductId=pc.ProductId
	WHERE	c.UserId= @UserId
GO

CREATE PROCEDURE showAllItem
AS
	SELECT * FROM Products
	WHERE Status = 'Available'
GO

EXEC newUser 'luongdq','abcdef',123456,'Seller'
EXEC newUser 'nguenq3','12345',234567,'Buyer'
EXEC postItem 1,'CSGo','New','Shooting', 12000
EXEC postItem 1,'FIFA 2017','New','Game', 13000
EXEC postItem 1,'PES 2019','New','Game', 12000
EXEC postItem 1,'PUBG','New','Shooting', 12000
EXEC postItem 1,'Ninja Storm 4','New','Fighting', 12000
EXEC postItem 1,'NBA 2018','New','Game', 12000
EXEC postItem 1,'NBA 2019','New','Sport', 12000
EXEC postItem 1,'GTA V','New','Other', 12000
EXEC postItem 1,'GTA 2','New','Other', 12000
EXEC postItem 1,'Injustice 2','New','Fighting', 12000
EXEC postItem 1,'God of War 4','New','Fighting', 12000
EXEC postItem 1,'FIFA 2016','New','Sport', 12000
EXEC postItem 1,'Fortnite','New','Shooting', 12000
