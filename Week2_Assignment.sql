--Create a procedure InsertOrderDetails that takes OrderID, ProductID, UnitPrice,
--Quantiy, Discount as input parameters and inserts that order information in the
--Order Details table. After each order inserted, check the @@rowcount value to
--make sure that order was inserted properly. If for any reason the order was not
--inserted, print the message: Failed to place the order. Please try again. Also your
--procedure should have these functionalities
--Make the UnitPrice and Discount parameters optional
--If no UnitPrice is given, then use the UnitPrice value from the product table.
--If no Discount is given, then use a discount of 0.
--Adjust the quantity in stock (UnitsInStock) for the product by subtracting the quantity
--sold from inventory.
--However, if there is not enough of a product in stock, then abort the stored procedure
--without making any changes to the database.
--Print a message if the quantity in stock of a product drops below its Reorder Level as a result of the update.

--Soluition
create procedure InsertOrderDetails
@OrderID int,
@ProductID int=NULL,
@UnitPrice money = NULL,
@Quantity int,
@Discount money=NULL
as
begin
if @UnitPrice is NULL
select @UnitPrice = ListPrice from SalesLT.Product where ProductID = @ProductID
if @Discount is NULL
set @Discount = 0
begin transaction
begin try
insert into SalesLT.SalesOrderDetail (OrderID, ProductID, UnitPrice, OrderQty, Discount)
values (@OrderID, @ProductID, @UnitPrice,@Quantity,@Discount)
declare @UnitsinStk int = (select UnitsInStock from SalesLT.Product where ProductID=@ProductID)
if @UnitsinStk < @Quantity
raiserror('Stock not available',16,1)
update SalesLT.Product
set UnitsInStock=@UnitsinStk-@Quantity where ProductID=@ProductID
if @@ROWCOUNT=0
raiserror ('Order was not inserted',16,1)
commit transaction
end try
begin catch
rollback transaction
raiserror('The order was not placed',16,1)
end catch
end

-- Create a procedure UpdateOrderDetails that takes OrderID, ProductID, Unit Price, Quantity, and discount, and updates these values for that ProductID in that Order. All the parameters
-- except the OrderID and ProductID should be optional so that if the user wants to only update Quantity s/he should be able to do so without providing the rest of the values. You need 
-- also make sure that if any of the values are being passed in as NULL, then you want to retain the original value instead of overwriting it with NULL. To accomplish this, look for the
-- ISNULL() function in google or sql server books online. Adjust the UnitsInStock value in products table accordingly.

  create procedure UpdateOrderDetails
@OrderID int,
@ProductID int,
@UnitPrice money = NULL,
@Quantity int = NULL,
@Discount money = NULL
as
begin
update SalesLT.SalesOrderDetail
set UnitPrice= isnull(@UnitPrice,UnitPrice),
OrderQty=isnull(@Quantity,OrderQty),
UnitPriceDiscount=isnull(@Discount,UnitPriceDiscount)
where SalesOrderID = @OrderID and ProductID = @ProductID
update SalesLT.Product
set UnitsInStock = UnitsInStock-(select OrderQty from SalesLT.SalesOrderDetail where SalesOrderID=@OrderID and ProductID=@ProductID)
where ProductID=@ProductID
if @@ROWCOUNT=0
raiserror('Not Found',16,1)
end

-- Create a procedure GetOrderDetails that takes OrderID as input parameter and returns all the records for that OrderID. If no records are found in Order Details table, then it should
-- print the line: "The OrderID XXXX does not exits", where XXX should be the OrderlD entered by user and the procedure should RETURN the value 1.

create procedure GetOrderDetails
@OrderID int
as
begin
if not exists (select 1 from SalesLT.SalesOrderDetail where SalesOrderID=@OrderID)
print 'The OrderID'+ convert(varchar(10),@OrderID)+'does not exist'
else
select * from SalesLT.SalesOrderDetail where SalesOrderID=@OrderID
return 1
end

-- Create a procedure DeleteOrderDetails that takes OrderID and ProductID and deletes that from Order Details table. Your procedure should validate parameters. It should retum an error
-- code (-1) and print a message if the parameters are invalid. Parameters are valid if the given order ID appears in the table and if the given product ID appears in that order.

create procedure DeleteOrderDetails
@OrderID int,
@ProductID int
as
begin
if not exists (select 1 from SalesLT.SalesOrderDetail where SalesOrderID=@OrderID and ProductID=@ProductID)\
raiserror('Parameters are invalid',16,1)
else
delete from SalesLT.SalesOrderDetail where SalesOrderID=@OrderID and ProductID=@ProductID
return 0;
end

-- Functions
-----------------

-- Review SQL Server date formats on this website and then create following functions

-- http://www.sql-server-helper.com/tips/date-formats.aspx

-- Create a function that takes an input parameter type datetime and returns the date in the format MM/DD/YYYY. For example if I pass in 2006-11-21 23:34:05.920', the output of the
--  functions should be 11/21/2006

create function Formatdate (@datetime datetime)
returns varchar(10)
as
begin
return convert(varchar(10),convert(date,@datetime),101)
end

-- Create a function that takes an input parameter type datetime and returns the date in the fonnat YYYYMMDD

create function Formatdate (@datetime datetime)
returns varchar(10)
as
begin
return convert(varchar(10),convert(date,@datetime),112)
end

-- Views
------------------

-- Create a view vwCustomerOrders which returns CompanyName OrderID.OrderDate, ProductID ProductName Quantity UnitPrice.Quantity od. UnitPrice

create view vwCustomerOrders
as
select SalesLT.Customer.CompanyName,SalesLT.SalesOrderDetail.SalesOrderID,SalesLT.SalesOrderHeader.OrderDate,SalesLT.Product.Name,SalesLT.SalesOrderDetail.OrderQty,SalesLT.SalesOrderDetail.UnitPrice
from SalesLT.SalesOrderDetail
join SalesLT.Product on SalesLT.Product.ProductID = SalesLT.SalesOrderDetail.ProductID
join SalesLT.SalesOrderHeader on SalesLT.SalesOrderHeader.SalesOrderID = SalesLT.SalesOrderDetail.SalesOrderID
join SalesLT.Customer on SalesLT.Customer.CustomerID = SalesLT.SalesOrderHeader.CustomerID

-- Use a CREATE VIEW statement to create a view called MyProducts. Your view should contain the ProductID, ProductName, QuantityPerUnit and Unit Price columns from the Products table. It
-- should also contain the CompanyName column from the Suppliers table and the CategoryName column from the Categories table. Your view should only contain products that are 
-- not discontinued. 

create view MyProducts 
as
select SalesLT.Product.ProductID,SalesLT.Product.Name,SalesLT.Product.QuantityPerUnit,SalesLT.Product.ListPrice,SalesLT.Suppliers.CompanyName,SalesLT.ProductCategory.Name
from SalesLT.Product
join SalesLT.Suppliers on SalesLT.Product.SupplierID = SalesLT.Supplier.SupplierID
join SalesLT.ProductCategory on SalesLT.Product.ProductCategoryID = SalesLT.ProductCategory.ProductCategoryID 
where SalesLT.Product.DiscontinuedDate is NULL;

-- Triggers
-------------------

-- If someone cancels an order in northwind database, then you want to delete that order from the Orders table. But you will not be able to delete that Order before deleting the records 
-- from Order Details table for that particular order due to referential integrity constraints. Create an Instead of Delete trigger on Orders table so that if some one tries to delete an
-- Order that trigger gets fired and that trigger should first delete everything in order details table and then delete that order from the Orders table

create trigger trg ON SalesLT.SalesOrderDetail instead of delete as
begin
    delete from SalesLT.SalesOrderHeader where SalesLT.SalesOrderHeader.SalesOrderID in (select SalesLT.SalesOrderHeader.SalesOrderID  from deleted)
    delete from SalesLT.SalesOrderDetail where SalesLT.SalesOrderDetail.SalesOrderID in (select SalesLT.SalesOrderDetail.SalesOrderID from deleted)
end

-- When an order is placed for X units of product Y, we must first check the Products table to ensure that there is sufficient stock to fill the order. This trigger will operate on the
-- Order Details table. If sufficient stock exists, then fill the order and decrement X units from the UnitsInStock column in Products. If insufficient stock exists, then refuse the order
-- (le. do not insert it) and notify the user that the order could not be filled because of insufficient stock.

create trigger trg before insert on SalesLT.SalesOrderDetails 
as
begin
    if EXISTS (select 1 from SalesLT.Product where ProductID = INSERTED.ProductId and UnitsInStock < INSERTED.Quantity)
        rollback transaction;
end;
