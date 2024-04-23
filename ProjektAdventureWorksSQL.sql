
--I undertook a SQL project to explore database management and analysis. Through designing schemas, creating queries, 
--and optimizing performance, I improved my skills in data manipulation and gained a deeper understanding of relational databases. 
--This project improved my SQL programming skills and made me aware that working with databases greatly interests me.
--Throughout the entire project, both in SQL and Power BI, I will be working with the popular AdventureWorksDW2022 database
--At the outset, I will employ simple queries to gain a comprehensive understanding of the database I am working with, 
--gradually progressing to more advanced queries.


--At the beginning I would like to know some details about the customers 
select FirstName, MiddleName, LastName, Gender, MaritalStatus, EnglishEducation, NumberCarsOwned
from DimCustomer

--then I would like to see only people with children At home 
select LastName, NumberChildrenAtHome
from DimCustomer
where NumberChildrenAtHome >0

-- I wanna see how many people has children at home (to do this I have to use aggregate function)
select count(LastName) 
from DimCustomer
where NumberChildrenAtHome >0

-- I want to see what the average income is grouped by Education 
select EnglishEducation, Avg(YearlyIncome)
from DimCustomer
group by EnglishEducation
 
 -- I want to see max number of Cars Owned 
 select max(NumberCarsOwned)
 from DimCustomer

-- I want to see connections between Education and number of owned Cars  
select EnglishEducation, NumberCarsOwned, 
Case 
when NumberCarsOwned = 0 then 'zero'
when NumberCarsOwned = 1 then 'one'
when NumberCarsOwned = 2 then 'two'
when NumberCarsOwned = 3 then 'three'
else 'four'
end as NumberCarsOwnedInWords,
Count(NumberCarsOwned) as NumberOfPeopleWithExactNumberOfCars  
from DimCustomer
group by EnglishEducation, NumberCarsOwned
order by 1,2

--I want to see what products  they bought and the product SubCategory 
select *
from FactInternetSales

select FirstName, LastName, P.ProductKey, EnglishProductName, P.ProductSubcategoryKey, EnglishProductSubcategoryName
from DimCustomer C
join FactInternetSales FIS on C.CustomerKey = FIS.CustomerKey
join DimProduct P on FIS.ProductKey = P.ProductKey
join DimProductSubcategory PS on P.ProductSubcategoryKey = PS.ProductSubcategoryKey

-- I want to compute average price for each Product Subcategory
select EnglishProductName, P.ProductSubcategoryKey, EnglishProductSubcategoryName, Avg(UnitPrice) as Average 
from FactInternetSales FIS 
join DimProduct P on FIS.ProductKey = P.ProductKey
join DimProductSubcategory PS on P.ProductSubcategoryKey = PS.ProductSubcategoryKey
group by P.ProductSubcategoryKey, EnglishProductName, EnglishProductSubcategoryName

--I want to see how many days was between Order Day and Ship Day for each Product
Select FIS.ProductKey, OrderDate, ShipDate, DATEDIFF(DAY, OrderDate, ShipDate) as NumberOfDaysFromOrderToShip
from FactInternetSales FIS
join DimProduct P on FIS.ProductKey = P.ProductKey

--I want to have only the most important things about the OrderDate thats why I will create Temp Table 
Drop table if EXISTS #Temp_OrderDate -- I have to add this line because, if I execute that table again it would be an error
Create Table #Temp_OrderDate (
ProductName nvarchar(100),
DateKey int,
DayNumberOfYear int,
FullDate Date,
DayNameOfWeek nvarchar(100),
CalenderQuater int
)
select *
from #Temp_OrderDate

Insert into #Temp_OrderDate 
select EnglishProductName, FPI.DateKey, DayNumberOfYear, FullDateAlternateKey, EnglishDayNameOfWeek, CalendarQuarter
from DimDate D
join FactProductInventory FPI on D.DateKey = FPI.DateKey
join DimProduct P on P.ProductKey = FPI.ProductKey

select *
from #Temp_OrderDate 
-- Temp Tables are stored somewhere in DataBase so we can refere to them later 

select *
from dimProduct

select *
from FactInternetSales

select *
from DimEmployee

-- I want to know in which department average Base Rate is bigger than 30 
select DepartmentName, avg(BaseRate) as AverageBaseRateInDirectDepartment
from DimEmployee
group by DepartmentName
having avg(BaseRate)>30

--I want to see how many women and men works in direct department
select FirstName, LastName, DepartmentName, Gender, Count(Gender) Over (Partition by DepartmentName) as TotalGender 
from DimEmployee 

select *
from FactResellerSales

--I want to see how many products were sold by direct Employee
select FRS.EmployeeKey, E.FirstName, E.LastName, count(ProductKey) as NumberOfProductSoldByDirectEmployee
from FactResellerSales FRS
join DimEmployee E on FRS.EmployeeKey = E.EmployeeKey
group by FRS.EmployeeKey, E.FirstName,  E.LastName
order by 4 desc

select *
from DimSalesTerritory

select *
from DimGeography

select *
from FactResellerSales

--I want to see how many Products were sold in each City
select P.ProductKey, FRS.SalesTerritoryKey, SalesTerritoryRegion, City, count(P.ProductKey) as QuantityOfSoldProductsInEachCity
from DimProduct P 
join FactResellerSales FRS on P.ProductKey = FRS.ProductKey
join DimSalesTerritory ST on FRS.SalesTerritoryKey = ST.SalesTerritoryKey
join DimGeography G on G.SalesTerritoryKey = ST.SalesTerritoryKey
group by FRS.SalesTerritoryKey, City, P.ProductKey, SalesTerritoryRegion

-- I want to see how much money company earn in each year (by creating a view)
select *
from DimDate

select *
from FactInternetSales

create view Sum_By_Year(CalenderYear, sumOfItemsSold)
as
select CalendarYear, sum(UnitPrice) 
From DimProduct P
join FactProductInventory FPI on P.ProductKey = FPI.ProductKey
join DimDate D on D.DateKey = FPI.DateKey
join FactInternetSales FIS on FIS.ProductKey = P.ProductKey
group by CalendarYear
Go

drop view Sum_By_Year

select *
from DimCurrency

--I want to see how many product have been sold in direct currency ( I will use CTE)
WITH CTE_Currency As (
Select C.CurrencyKey, C.CurrencyName, Count(FIS.ProductKey) as NumberOfPRoductsSoldInDirectCurrency
from DimCurrency C
join FactInternetSales FIS on C.CurrencyKey = FIS.CurrencyKey
group by C.CurrencyKey, CurrencyName )

BEGIN TRANSACTION; 
		insert into CTE_Currency (C.CurrencyName) values ('Polish Zloty');
		select *
		from CTE_Currency
commit transaction  


--I want to see changes automatically in DimProductCategory when I make changes in DimProductSubcategory, that's why I am creating Trigger 
select *
from DimProductSubcategory

select *
from DimProductCategory

Create Trigger ProductInsertTwo
	on DimProductSubcategory
	after insert as 
begin 
	insert into DimProductCategory (ProductCategoryKey, EnglishProductCategoryName, SpanishProductCategoryName, FrenchProductCategoryName)
	select ProductSubcategoryKey, EnglishProductSubcategoryName, SpanishProductSubcategoryName, FrenchProductSubcategoryName
	from inserted
end 

SET IDENTITY_INSERT DimProductCategory ON;
SET IDENTITY_INSERT DimProductSubcategory ON;
Insert into DimProductSubcategory (ProductSubcategoryAlternateKey, EnglishProductSubcategoryName, SpanishProductSubcategoryName, FrenchProductSubcategoryName)
values ( 100, 'Tent', 'Carpa', 'tente');

select *
from DimProductCategory

-- I want to see product with the highest Price and products with the lowest Price (subquery)
select P.ProductKey, EnglishProductName, UnitPrice
from FactInternetSales FIS
join DimProduct P on FIS.ProductKey = P.ProductKey
where UnitPrice = (select max(UnitPrice) from FactInternetSales) or UnitPrice = (select min(unitPrice) from FactInternetSales)

--I would like to see date of first Order and date of last Order (Union all)
select max(FullDateAlternateKey) OrderDay
from DimDate
Union all
select min(FullDateAlternateKey)
from DimDate

--Assume that this company has problems with money and have to fire some employees. The management decided 
--that every person after 65 years of age will be retired immediately. I will create a EVENT to delete that people right away from the table.
select *
from DimEmployee

Create Procedure Delete_Retirees
As
begin 
	Delete 
	from DimEmployee 
	where DATEDIFF(YEAR, BirthDate, convert(date, GetDate())) >=65
end 
-- tutaj trzeba uruchomich harmonogram 

-- I will show another way to use Procedure. Suppose, that my shop has two telephone types. After sale I want to change immediately tables
-- where I put the most important things about that items (especially, the number of items sold and those that are in stock).
Create table SalesTwo (
Orderdate date,
ProductKey int, 
ProductName nvarchar(100), 
SalePrice int
)

Create table Products (
ProductKey int,
ProductName nvarchar(100),
SalePrice int, 
QuantityInStock int, 
QuantitySold int
)

Insert into Products values 
(001, 'Samsung', 2500, 35, 0),
(002, 'Iphone', 3000, 65, 0)

--Creating a PROCEDURE (WITH PARAMETERS)
Create or alter Procedure SoldProducts(@v_ProductName nvarchar(100), @_quantity int)
as 
	declare @v_productKey int,
			@v_price int,
			@_checking int;
begin
	select @_checking = count(1)
	from Products
	where ProductName = @v_ProductName and QuantityInStock >= @_quantity
	
	select  @v_productKey = ProductKey, @v_price = SalePrice
	from Products
	where ProductName = @v_ProductName;
	
	if @_checking > 0
	begin
		insert into SalesTwo (OrderDate, ProductKey, ProductName, SalePrice)
		values (cast(getdate() as date), @v_productKey, @v_ProductName, (@v_price*@_quantity));

		update Products
		set QuantityInStock = (QuantityInStock - @_quantity)
		, QuantitySold = (QuantitySold + @_quantity)
		where ProductKey = @v_productKey

		Print('Product Sold !!!');
	end
	else 
		print('We do not have this quantity');
end 

--When I want to call the Procedure 
exec SoldProducts 'Samsung', 3;
