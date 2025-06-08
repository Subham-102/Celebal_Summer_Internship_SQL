1. List of all customers
select FirstName, MiddleName, LastName from SalesLT.Customer;

2. list of all customers where company name ending in N
select FirstName, MiddleName, LastName, CompanyName from SalesLT.Customer
where CompanyName like '%N';

3. list of all customers who live in Berlin or London
select * from SalesLT.Address
where City = 'Berlin' or City='London';

4. list of all customers who live in UK or USA
select * from SalesLT.Address
where CountryRegion = 'United Kingdom' or CountryRegion=' United States %';

5. list of all products sorted by product name
select * from SalesLT.Product order by Name asc;

6. list of all products where product name starts with an A
select * from SalesLT.Product 
where Name like 'A%';

7. List of customers who ever placed an order
select SalesLT.Customer.FirstName, SalesLT.Customer.MiddleName, SalesLT.Customer.LastName
from SalesLT.Customer
join SalesLT.SalesOrderHeader
on SalesLT.Customer.CustomerID = SalesLT.SalesOrderHeader.CustomerID;

8. list of Customers who live in London and have bought chai
select SalesLT.Customer.FirstName, SalesLT.Customer.MiddleName, SalesLT.Customer.LastName
from SalesLT.Customer
join SalesLT.SalesOrderHeader
on SalesLT.Customer.CustomerID = SalesLT.SalesOrderHeader.CustomerID
join SalesLT.SalesOrderDetail
on SalesLT.SalesOrderDetail.SalesOrderID = SalesLT.SalesOrderHeader.SalesOrderID
join SalesLT.Product 
on SalesLT.Product.ProductID = SalesLT.SalesOrderDetail.ProductID
where SalesLT.Address.City = 'London' and SalesLT.Product.Name = 'Chai';

9. List of customers who never place an order
SELECT * FROM SalesLT.Customer
WHERE CustomerID NOT IN (SELECT CustomerID FROM SalesLT.SalesOrderHeader);

10. List of customers who ordered Tofu
select SalesLT.Customer.FirstName, SalesLT.Customer.MiddleName, SalesLT.Customer.LastName
from SalesLT.Customer
join SalesLT.SalesOrderHeader
on SalesLT.Customer.CustomerID = SalesLT.SalesOrderHeader.CustomerID
join SalesLT.SalesOrderDetail
on SalesLT.SalesOrderDetail.SalesOrderID = SalesLT.SalesOrderHeader.SalesOrderID
join SalesLT.Product 
on SalesLT.Product.ProductID = SalesLT.SalesOrderDetail.ProductID
where SalesLT.Product.Name = 'Tofu';

11. Details of first order of the system
select top 1 * from SalesLT.SalesOrderHeader order by OrderDate asc ;

12. Find the details of most expensive order date
select top 1 * from SalesLT.SalesOrderHeader order by SubTotal asc ;

13. For each order get the OrderID and Average quantity of items in that order
select SalesOrderID,AVG(OrderQty) as AvgQuantity from saleslt.SalesOrderDetail
group by SalesOrderID;

14. For each order get the orderID, minimum quantity and maximum quantity for that order
select SalesOrderID,MIN(OrderQty) as MinQty , MAX(OrderQty) as MaxQt from saleslt.SalesOrderDetail
group by SalesOrderID;

15. Get a list of all managers and total number of employees who report to them.
SELECT EmployeeNationalIDAlternateKey, COUNT(*) AS NumberOfReports
FROM dbo.DimEmployee
WHERE Title like '%Manager' and EmployeeNationalIDAlternateKey IS NOT NULL 
GROUP BY EmployeeNationalIDAlternateKey;

16. Get the OrderID and the total quantity for each order that has a total quantity of greater than 300
SELECT SalesOrderID, SUM(OrderQty) AS TotalOrderQty
FROM SalesLT.SalesOrderDetail
GROUP BY SalesOrderID
having SUM(OrderQty) > 300;

17. list of all orders placed on or after 1996/12/31
select SalesOrderID from SalesLT.SalesOrderHeader
where OrderDate >='1996-12-31'

18. list of all orders shipped to Canada
select * 
from SalesLT.Address
join SalesLT.SalesOrderHeader
on SalesLT.Address.AddressID = SalesLT.SalesOrderHeader.ShipToAddressID
where CountryRegion = 'Canada' ;

19. list of all orders with order total > 200
select SalesOrderID,SUM(OrderQty*UnitPrice) as TotalAmount
from SalesLT.SalesOrderDetail
group by SalesOrderID
having SUM(OrderQty*UnitPrice) > 200;

20. List of countries and sales made in each country
select * 
from SalesLT.Address
join SalesLT.SalesOrderHeader
on SalesLT.Address.AddressID = SalesLT.SalesOrderHeader.ShipToAddressID;

21. List of Customer ContactName and number of orders they placed
select SalesLT.Customer.FirstName, SalesLT.Customer.MiddleName,SalesLT.Customer.LastName , count(SalesLT.SalesOrderHeader.SalesOrderID) as NumberofOrders
from SalesLT.Customer
join SalesLT.SalesOrderHeader
on SalesLT.Customer.CustomerID = SalesLT.SalesOrderHeader.CustomerID
group by SalesLT.Customer.FirstName, SalesLT.Customer.MiddleName,SalesLT.Customer.LastName

22.  List of customer contactnames who have placed more than 3 orders
select SalesLT.Customer.FirstName, SalesLT.Customer.MiddleName,SalesLT.Customer.LastName , count(SalesLT.SalesOrderHeader.SalesOrderID) as NumberofOrders
from SalesLT.Customer
join SalesLT.SalesOrderHeader
on SalesLT.Customer.CustomerID = SalesLT.SalesOrderHeader.CustomerID
group by SalesLT.Customer.FirstName, SalesLT.Customer.MiddleName,SalesLT.Customer.LastName
having count(SalesLT.SalesOrderHeader.SalesOrderID) > 3

23. List of discontinued products which were ordered between 1/1/1997 and 1/1/1998
select SalesLT.Product.Name, SalesLT.Product.DiscontinuedDate , SalesLT.SalesOrderDetail.SalesOrderID, SalesLT.SalesOrderHeader.OrderDate from SalesLT.Product
join SalesLT.SalesOrderDetail
on SalesLT.Product.ProductID = SalesLT.SalesOrderDetail.ProductID
join SalesLT.SalesOrderHeader
on SalesLT.SalesOrderDetail.SalesOrderID = SalesLT.SalesOrderHeader.SalesOrderID
where DiscontinuedDate != NULL and OrderDate between '1997-01-01 %' and '1998-01-01%'

24. List of employee firsname, lastName, superviser FirstName, LastName
SELECT F.FirstName AS Employee_First_Name, F.LastName AS Employee_Last_Name,
       T.FirstName AS Supervisor_First_Name, T.LastName AS Supervisor_Last_Name
FROM Employees F
LEFT JOIN Employees T ON F.ManagerID = T.EmployeeID;

25. List of Employees id and total sale condcuted by employee
SELECT SalesLT.SalesOrderHeader.EmployeeID, SUM(OrderQty * UnitPrice) AS TotalSales
FROM saleslt.SalesOrderDetail
GROUP BY SalesLT.SalesOrderHeader.EmployeeID;

26. list of employees whose FirstName contains character a
SELECT * FROM dbo.DimEmployee
WHERE FirstName LIKE '%a%';

27. List of managers who have more than four people reporting to them.
SELECT EmployeeNationalIDAlternateKey, COUNT(*) AS NumberOfReports
FROM dbo.DimEmployee
WHERE Title like '%Manager' and EmployeeNationalIDAlternateKey IS NOT NULL 
GROUP BY EmployeeNationalIDAlternateKey
having COUNT(*) AS NumberOfReports > 4;

28. List of Orders and ProductNames
select SalesLT.Product.Name,SalesLT.SalesOrderDetail.* 
from SalesLT.Product
join SalesLT.SalesOrderDetail
on SalesLT.Product.ProductID = SalesLT.SalesOrderDetail.ProductID

29. List of orders place by the best customer (3 is the no of most orders placed by a single customer)
select SalesLT.Customer.FirstName, SalesLT.Customer.MiddleName,SalesLT.Customer.LastName , count(SalesLT.SalesOrderHeader.SalesOrderID) as NumberofOrders
from SalesLT.Customer
join SalesLT.SalesOrderHeader
on SalesLT.Customer.CustomerID = SalesLT.SalesOrderHeader.CustomerID
group by SalesLT.Customer.FirstName, SalesLT.Customer.MiddleName,SalesLT.Customer.LastName
having count(SalesLT.SalesOrderHeader.SalesOrderID) > 3

30. List of orders placed by customers who do not have a Fax number
select saleslt.Customer.FirstName, saleslt.Customer.MiddleName , SalesLT.Customer.lastname
from SalesLT.Customer
where SalesLT.Customer.Fax is NULL

31. List of Postal codes where the product Tofu was shipped
SELECT SalesLT.Address.PostalCode
FROM SalesLT.Address
JOIN SalesLT.SalesOrderHeader
ON SalesLT.Address.AddressID = SalesLT.SalesOrderHeader.ShipToAddressID
JOIN SalesLT.SalesOrderDetail
ON SalesLT.SalesOrderHeader.SalesOrderID = SalesLT.SalesOrderDetail.SalesOrderID
JOIN SalesLT.Product
ON SalesLT.SalesOrderDetail.ProductID = SalesLT.Product.ProductID
where SalesLT.Product.Name = 'Tofu'

32. List of product Names that were shipped to France
select * 
from SalesLT.Address
join SalesLT.SalesOrderHeader
on SalesLT.Address.AddressID = SalesLT.SalesOrderHeader.ShipToAddressID
where CountryRegion = 'France' ;

33. List of ProductNames and Categories for the supplier 'Specialty Biscuits, Ltd.'
SELECT SalesLT.Products.ProductName, SalesLT.Categories.CategoryName
FROM SalesLT.Products
JOIN SalesLT.Suppliers ON SalesLT.Products.SupplierID = SalesLT.Suppliers.SupplierID
JOIN SalesLT.Categories ON SalesLT.Products.CategoryID = SalesLT.Categories.CategoryID
WHERE SalesLT.Suppliers.CompanyName = 'Specialty Biscuits, Ltd.';

34. List of products that were never ordered
SELECT *
FROM SalesLT.Product
left jOIN SalesLT.SalesOrderDetail
ON SalesLT.Product.ProductID = SalesLT.SalesOrderDetail.ProductID
WHERE SalesLT.SalesOrderDetail.ProductID IS NULL;

35. List of products where units in stock is less than 10 and units on order are 0.
select * from SalesLT.Product
where SalesLT.Product.UnitsInStock < 10 and SalesLT.ProductUnitsOnOrder = 0;

36. List of top 10 countries by sales
select TOP 10 SalesLT.Address.CountryRegion from SalesLT.Address
join SalesLT.SalesOrderHeader
on SalesLT.Address.AddressID = SalesLT.SalesOrderHeader.ShipToAddressID
group by SalesLT.Address.CountryRegion
order by SUM(SalesLT.SalesOrderHeader.SubTotal) desc;

37. Number of orders each employee has taken for customers with CustomerIDs between A and AO
SELECT SalesLTOrders.EmployeeID, COUNT(*) AS NumberOfOrders
FROM SalesLT.Orders
JOIN SalesLTCustomers ON SalesLTOrders.CustomerID = SalesLTCustomers.CustomerID
WHERE SalesLTCustomers.CustomerID BETWEEN 'A' AND 'AO'
GROUP BY Orders.EmployeeID;

38. Orderdate of most expensive order
select TOP 1 SalesLT.SalesOrderHeader.OrderDate from SalesLT.SalesOrderHeader
order by SalesLT.SalesOrderHeader.SubTotal desc

39. Product name and total revenue from that product
select SalesLT.Product.Name, SUM(SalesLT.SalesOrderDetail.OrderQty*SalesLT.SalesOrderDetail.UnitPrice) as TotalRevenue 
from SalesLT.Product
left join SalesLT.SalesOrderDetail
on SalesLT.Product.ProductID = SalesLT.SalesOrderDetail.ProductID
group by SalesLT.Product.Name

40. Supplierid and number of products offered
select SalesLT.Product.SupplierID, COUNT(*) AS NumberOfProducts
FROM SalesLT.Product
GROUP BY SalesLT.Product.SupplierID;

41. Top ten customers based on their business
select top 10 SalesLT.Customer.FirstName, SalesLT.Customer.MiddleName, SalesLT.Customer.LastName
from SalesLT.Customer
left join SalesLT.SalesOrderHeader
on SalesLT.Customer.CustomerID = SalesLT.SalesOrderHeader.CustomerID
order by SalesLT.SalesOrderHeader.SubTotal

42. What is the total revenue of the company
select SUM(SalesLT.SalesOrderHeader.SubTotal) as TotalRevenue
from SalesLT.SalesOrderHeader
