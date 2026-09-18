Use Project

--  01 - Database & Data Preparation



-- =============================================
--  Get All Data
-- Purpose: Retrieve all records from the
--          Central Region table
-- =============================================

With Get_All_Data as(
Select * FROM Central_Regions
)

Select * from Get_All_Data

-------------------------------------------------

-- =============================================
-- 1. Customers Table
-- Stores unique customer information.
-- Customer ID is the Primary Key.
-- =============================================

CREATE TABLE Customers_Dataset_Info (
    [Customer ID] VARCHAR(255) PRIMARY KEY,
    [Customer Name] VARCHAR(255),
    Segment VARCHAR(255)
);
INSERT INTO Customers_Dataset_Info ([Customer ID], [Customer Name], Segment)
SELECT DISTINCT
    [Customer ID],
    [Customer Name],
    Segment
FROM Central_Regions;


CREATE TABLE Customer_Locations_Info (
    Location_ID INT IDENTITY(1,1) PRIMARY KEY,
    [Customer ID] VARCHAR(255),
    Country VARCHAR(255),
    City VARCHAR(255),
    State VARCHAR(255),
    [Postal Code] VARCHAR(50),
    Region VARCHAR(255),

    FOREIGN KEY ([Customer ID])
        REFERENCES Customers_Dataset_Info([Customer ID])
);  
INSERT INTO Customer_Locations_Info  ([Customer ID], Country, City, State, [Postal Code], Region)
SELECT DISTINCT
    [Customer ID],
    Country,
    City,
    State,
    [Postal Code],
    Region
FROM Central_Regions;


-----------------------------------------------------------

-- =============================================
-- 2. Products Information Table
-- Stores unique information about each product.
-- Product ID is the Primary Key.
-- =============================================

CREATE TABLE Products_Dataset_Info (
    [Product ID] VARCHAR(255),
    Category VARCHAR(255),
    [Sub-Category] VARCHAR(255),
    [Product Name] VARCHAR(255),
    PRIMARY KEY ([Product ID], [Product Name])
);
INSERT INTO Products_Dataset_Info
    ([Product ID], Category, [Sub-Category], [Product Name])
SELECT DISTINCT
    [Product ID],
    Category,
    [Sub-Category],
    [Product Name]
FROM Central_Regions;



--------------------------------------------------------------

-- =============================================
-- 3. Orders Table
-- Stores unique information about each order.
-- Order ID is the Primary Key.
-- Customer ID is a Foreign Key referencing Customers.
-- =============================================


Create TABLE Orders_Data_Info(
[Order ID]  VARCHAR(255) PRIMARY KEY,
[Customer ID] VARCHAR(255),
[Order Date] Date,
[Ship Mode] VARCHAR(255),
[Ship Date] Datetime
FOREIGN KEY ([Customer ID]) REFERENCES Customers_Data([Customer ID])
)
insert into Orders_Data_Info([Order ID]  ,[Customer ID],[Order Date] , [Ship Mode] ,[Ship Date])
SELECT DISTINCT [Order ID] , [Customer ID] , [Order Date] , [Ship Mode] , [Ship Date]
FROM Central_Regions



---------------------------------------------------------------------

-- =============================================
-- 4. Order Details Table
-- Stores individual transaction lines for each order.
-- Row ID uniquely identifies each transaction line.
-- Order ID and Product ID are Foreign Keys.
-- =============================================

CREATE TABLE Order_Details_Data_Info (
    [Row ID] INT PRIMARY KEY,
    [Order ID] VARCHAR(255),
    [Product ID] VARCHAR(255),
    [Product Name] VARCHAR(255),
    Sales DECIMAL(10,3),
    Quantity INT,
    Discount DECIMAL(5,2),
    Profit DECIMAL(10,4),
    FOREIGN KEY ([Order ID])
        REFERENCES Orders_Dataset_Info([Order ID]),

    FOREIGN KEY ([Product ID], [Product Name])
        REFERENCES Products_Dataset_Info([Product ID], [Product Name])
);
INSERT INTO Order_Details_Data_Info
    ([Row ID], [Order ID], [Product ID], [Product Name],
     Sales, Quantity, Discount, Profit)
SELECT
    [Row ID],
    [Order ID],
    [Product ID],
    [Product Name],
    Sales,
    Quantity,
    Discount,
    Profit
FROM Central_Regions;
----------------------------------------------------------------------------
--02 - Quick Business Analysis

-- =====================================================
-- Quick Business Analysis
-- Provides quick insights into key sales, profit,
-- customer, product, and category performance using
-- simple and efficient SQL queries.
-- =====================================================

-------------------------------------------------------------

-- =====================================================
-- Texas High-Profit Customer Analysis
-- Identifies customers in Texas with total profits
-- exceeding 5,000 and ranks them by profitability.
-- =====================================================


WITH Texas_Customers_Above_5000_Profits AS
(
    SELECT 
        C.[Customer ID],
        C.[Customer Name],
        C.Segment,
        SUM(OD.Profit) AS Total_Profit
    FROM Customers_Dataset_Info AS C
    
    INNER JOIN Customer_Locations_Info AS CL
        ON CL.[Customer ID] = C.[Customer ID]
    
    INNER JOIN Orders_Data_Info AS O
        ON O.[Customer ID] = C.[Customer ID]
    
    INNER JOIN Order_Details_Data_Info AS OD
        ON OD.[Order ID] = O.[Order ID]
    
    WHERE CL.State = 'Texas'
    
    GROUP BY 
        C.[Customer ID],
        C.[Customer Name],
        C.Segment
    
    HAVING SUM(OD.Profit) > 5000
)

SELECT *
FROM Texas_Customers_Above_5000_Profits
ORDER BY Total_Profit DESC;


---------------------------------------------
-- =====================================================
-- High-Profit Technology & Office Supplies Products
-- Identifies products from the Technology and Office
-- Supplies categories with total profit exceeding 3,500.
-- =====================================================

WITH High_Profits_Tech_Office_Products AS
(
    SELECT
        P.[Product ID],
        P.[Product Name],
        P.Category,
        SUM(OD.Profit) AS Total_Profit
    FROM Products_Dataset_Info AS P

    INNER JOIN Order_Details_Data_Info AS OD
        ON OD.[Product ID] = P.[Product ID] AND OD.[Product Name] = P.[Product Name]

    WHERE P.Category IN ('Office Supplies', 'Technology')
    GROUP BY
        P.[Product ID],
        P.[Product Name],
        P.Category

    HAVING SUM(OD.Profit) > 3500
)

SELECT
    [Product ID],
    [Product Name],
    Category,
    Total_Profit
FROM High_Profits_Tech_Office_Products
ORDER BY Total_Profit DESC;



---------------------------------------------

-- =====================================================
-- Order Volume Analysis
-- Calculates the total number of unique orders placed
-- within the specified date range.
-- =====================================================

WITH Orders_Within_Date_Range AS
(
    SELECT 
        COUNT(DISTINCT O.[Order ID]) AS Total_Orders_Within_Range
    FROM Orders_Data_Info AS O
    WHERE O.[Order Date] BETWEEN '2013-02-20' AND '2013-09-21'
)
SELECT '2013-02-20' AS Start_Date , '2013-09-21' AS End_Date,
    Total_Orders_Within_Range
FROM Orders_Within_Date_Range;

------------------------------------------------
-- =====================================================
-- Category Order Volume Analysis
-- Calculates the total number of unique orders
-- associated with a selected product category.
-- =====================================================

CREATE PROCEDURE Get_Categories_Order_Count
    @Category VARCHAR(255)
AS
BEGIN
    SELECT
        P.Category,
        COUNT(DISTINCT O.[Order ID]) AS Total_Orders,
        CASE
            WHEN  COUNT(DISTINCT O.[Order ID]) >= 450 THEN 'High-Order Volume'
            WHEN COUNT(DISTINCT O.[Order ID]) >= 250 THEN  'Avreage-Order Volume'
            ELSE 'Low-Order Volume'
        END AS Category_Status
    FROM Products_Dataset_Info AS P

    INNER JOIN Order_Details_Dataset_Info AS OD
        ON OD.[Product ID] = P.[Product ID]

    INNER JOIN Orders_Data_Info AS O
        ON O.[Order ID] = OD.[Order ID]

    WHERE P.Category = @Category

    GROUP BY P.Category;
END;

EXEC Get_Categories_Order_Count
    @Category = 'Furniture';
    
--------------------------------------------
-- =====================================================
-- Ship Mode Usage Analysis
-- Calculates the total number of unique customers
-- and orders associated with a selected shipping mode.
-- =====================================================

CREATE PROCEDURE Get_Ship_Mode_Usage
    @ShipMode VARCHAR(255)
AS
BEGIN
    SELECT
        O.[Ship Mode],
        COUNT(DISTINCT C.[Customer ID]) AS Total_Customers,
        COUNT(DISTINCT O.[Order ID]) AS Total_Orders
    FROM Orders_Data_Info AS O

    INNER JOIN Customers_Dataset_Info AS C
        ON C.[Customer ID] = O.[Customer ID]

    WHERE O.[Ship Mode] = @ShipMode

    GROUP BY O.[Ship Mode];
END;


EXEC Get_Ship_Mode_Usage
    @ShipMode = 'Standard Class';
--------------------------------------------
-- =====================================================
-- Segment Customer and Order Analysis
-- Calculates the total number of unique customers
-- and orders within a selected customer segment.
-- =====================================================

CREATE PROCEDURE Get_Segments_Statistics
    @Segment VARCHAR(255)
AS
BEGIN
    SELECT
        C.Segment,
        COUNT(DISTINCT O.[Order ID]) AS Total_Orders,
        COUNT(DISTINCT C.[Customer ID]) AS Total_Customers,
        CASE
            WHEN COUNT(DISTINCT C.[Customer ID]) >= 200 THEN 'Large Base'
            WHEN COUNT(DISTINCT C.[Customer ID]) >= 150 THEN 'Average Base'
            Else 'Low Base'
        END AS Customers_Base
    FROM Customers_Dataset_Info AS C

    INNER JOIN Orders_Data_Info AS O
        ON O.[Customer ID] = C.[Customer ID]

    WHERE C.Segment = @Segment

    GROUP BY C.Segment;
END;

EXEC Get_Segments_Statistics
    @Segment = 'Corporate';


---------------------------------------------------------------
-- =====================================================
-- Customers with Negative Profit
-- Identifies customers whose total profit is negative,
-- indicating that their orders generated an overall loss.
-- =====================================================

CREATE VIEW Customers_With_Negative_Profits AS
SELECT C.[Customer ID] , C.[Customer Name] , C.Segment , SUM(OD.Sales) AS Total_Sales , SUM(OD.PROFIT) AS Total_Profit
FROM Customers_Dataset_Info AS C
JOIN Orders_Data_Info AS O
ON O.[Customer ID] = C.[Customer ID]
JOIN Order_Details_Data_Info AS OD
ON OD.[Order ID] = O.[Order ID]
GROUP BY C.[Customer ID] , C.[Customer Name] , C.Segment
HAVING SUM(OD.PROFIT) < 0


SELECT * FROM Customers_With_Negative_Profits
ORDER BY Total_Profit DESC

---------------------------------------------------------------
-- =====================================================
-- Products with Negative Profit
-- Identifies Products whose total profit is negative,
-- indicating that their orders generated an overall loss.
-- =====================================================


CREATE VIEW Products_With_Negative_Profits AS
SELECT P.[Product ID] , P.[Product Name] , P.Category , P.[Sub-Category] , SUM(OD.Sales) AS Total_Sales , SUM(OD.PROFIT) AS Total_Profit
,AVG(OD.Discount) as Average_Discount
FROM Products_Dataset_Info AS p
JOIN Order_Details_Data_Info AS OD
ON OD.[Product ID] = P.[Product ID]
GROUP BY P.[Product ID] , P.[Product Name] , P.Category , P.[Sub-Category] 
HAVING SUM(OD.PROFIT) < 0


SELECT * FROM Products_With_Negative_Profits
ORDER BY Total_Profit DESC

------------------------------------------------------------
-- =====================================================
-- High-Sales Low-Profit Product Analysis
-- Identifies products with high sales but relatively
-- low profit, highlighting potentially low-margin products.
-- =====================================================

Create VIEW High_Sales__Low_Profits_Products AS
SELECT P.[Product ID] , P.[Product Name] , P.Category , P.[Sub-Category] , SUM(OD.PROFIT) AS Total_Profit ,SUM(OD.Sales) AS Total_Sales
FROM Products_Dataset_Info AS P
JOIN Order_Details_Data_Info AS OD
ON OD.[Product ID] = P.[Product ID] AND OD.[Product Name] = P.[Product Name]
GROUP BY P.[Product ID] , P.[Product Name] , P.Category , P.[Sub-Category]
HAVING SUM(OD.Sales) > 5500 AND SUM(OD.PROFIT) < 0

SELECT * FROM High_Sales__Low_Profits_Products

--------------------------------------------------------------------------------

--02 - CTE Analysis------

-- =====================================================
-- High-Profit Customer Analysis
-- Identifies customers with total profits exceeding
-- 3,000 to highlight highly profitable customers.
-- =====================================================
WITH TOTAL_PROFIT_CUSTOMERS AS (
SELECT [Customer ID], SUM(Profit) AS Total_Profit
FROM Orders_Data_Info  AS O
JOIN Order_Details_Data_Info AS OD
ON OD.[Order ID] = O.[Order ID]
GROUP BY [Customer ID]
),
TOTAL_HIGH_PROFIT_CUSTOMERS AS (
SELECT *
FROM TOTAL_PROFIT_CUSTOMERS
WHERE Total_Profit > 3000
)
SELECT * FROM TOTAL_HIGH_PROFIT_CUSTOMERS

------------------------------------------------------------------------------
-- =====================================================
-- Highly Discounted Products Analysis
-- Identifies products with an average discount of 80%
-- or higher and evaluates their sales and profitability.
-- =====================================================
WITH Highly_Discounted_Products AS (
    SELECT
        P.[Product ID],
        P.[Product Name],
        P.Category,
        AVG(OD.Discount) AS Average_Discount,
        SUM(OD.Profit) AS Total_Profit,
        SUM(OD.Sales) AS Total_Sales
    FROM Products_Dataset_Info AS P
    JOIN Order_Details_Data_Info AS OD
        ON OD.[Product ID] = P.[Product ID]
        AND OD.[Product Name] = P.[Product Name]
    GROUP BY
        P.[Product ID],
        P.[Product Name],
        P.Category
    HAVING AVG(OD.Discount) >=0.60
    )
SELECT *
FROM Highly_Discounted_Products
ORDER BY Average_Discount DESC;
----------------------------------------------------------------------
-- =====================================================
-- Monthly Sales and Profit Analysis
-- Analyzes monthly sales and profit to identify
-- changes in business performance over time.
-- =====================================================
WITH Monthly_Performance AS ( 
   SELECT YEAR(O.[Order Date]) AS Order_Year , MONTH(O.[Order Date]) AS Order_Month,
   SUM(OD.PROFIT) AS Total_Profit , SUM(OD.Sales) AS Total_Sales
   FROM Orders_Data_Info AS O
   JOIN Order_Details_Data_Info AS OD
   ON OD.[Order ID] = O.[Order ID]
   GROUP BY  YEAR(O.[Order Date]) ,   MONTH(O.[Order Date])
)
SELECT *
FROM Monthly_Performance
ORDER BY Order_Year DESC , Order_Month DESC


-- =====================================================
-- Yearly Sales and Profit Performance Analysis
-- Analyzes yearly sales and profit to compare
-- business performance across different years.
-- Ranks years by total profit, followed by total sales.
-- =====================================================

WITH Yearly_Performance AS ( 
    SELECT 
        YEAR(O.[Order Date]) AS Order_Year,
        SUM(OD.Profit) AS Total_Profit,
        SUM(OD.Sales) AS Total_Sales,
        CASE
            WHEN SUM(OD.Profit) >= 13500 THEN 'High-Performing'
            WHEN SUM(OD.Profit) >= 8500 THEN 'Moderately Profitable'
            ELSE 'Low-Performing'
        END AS Performance_Status
    FROM Orders_Data_Info AS O
    JOIN Order_Details_Data_Info AS OD
        ON OD.[Order ID] = O.[Order ID]
    GROUP BY YEAR(O.[Order Date])
)
SELECT *
FROM Yearly_Performance
ORDER BY Total_Profit DESC

-----------------------------------------------------------

-- =====================================================
-- Top 5 Most Profitable City Location
-- Calculates the total profit generated by each City contribution
-- and returns the top 5 Cities with the highest profit.
-- =====================================================

WITH TOP5_High_Profit_City AS (
    SELECT TOP 5
        C.City,
        C.Country,
        SUM(OD.Profit) AS TOTAL_PROFIT
    FROM Customer_Locations_Info AS C
    JOIN Orders_Data_Info AS O
        ON O.[Customer ID] = C.[Customer ID]
    JOIN Order_Details_Data_Info AS OD
        ON OD.[Order ID] = O.[Order ID]
    GROUP BY
        C.City,
        C.Country
    ORDER BY SUM(OD.Profit) DESC
)
SELECT *
FROM TOP5_High_Profit_City;
-------------------------------------------------------
-- =====================================================
-- High-Sales Low-Profit Customer Analysis
-- Identifies customers with more than 3,500 in total
-- sales but negative total profit, highlighting
-- potentially unprofitable high-value customers.
-- =====================================================

WITH Customers_Profit_Summary AS (
SELECT [Customer Name] , SUM(OD.Sales) As Total_Sales  , SUM(OD.Profit) As Total_Profit , AVG(OD.PROFIT) AS Average_Profit
FROM Customers_Dataset_Info AS C
JOIN Orders_Data_Info AS O
ON O.[Customer ID] = C.[Customer ID]
JOIN Order_Details_Data_Info as OD
ON OD.[Order ID] = O.[Order ID]
group by C.[Customer Name]
having SUM(OD.Sales) > 3500 AND  SUM(OD.Profit) < 0
)

SELECT * FROM Customers_Profit_Summary

---------------------------------------------------------------

-- =====================================================
-- Customers Above Average Profit
-- Calculates the total profit generated by each customer
-- and identifies customers whose profit exceeds the average.
-- =====================================================

WITH Customers_Above_Average_Profit AS
(
SELECT C.[Customer Name], C.[Customer ID] , SUM(OD.PROFIT) AS Total_Profit
FROM Customers_Dataset_Info AS C
JOIN Orders_Data_Info AS O
on O.[Customer ID] = C.[Customer ID]
JOIN Order_Details_Data_Info AS OD
ON OD.[Order ID] = O.[Order ID]
GROUP BY C.[Customer Name] , C.[Customer ID]
)
, Customers_Avreage_Data as(
SELECT [Customer Name]  ,  [Customer ID] , Total_Profit , AVG(Total_Profit) OVER() AS Total_Avreage_Profit
FROM Customers_Above_Average_Profit
)

SELECT [Customer Name] ,Total_Profit , Total_Avreage_Profit,
CASE
    WHEN Total_Profit > Total_Avreage_Profit THEN 'ABOVE_AVERAGE'
    WHEN Total_Profit = Total_Avreage_Profit THEN 'AVERAGE'
    ELSE 'BELOW_AVERAGE'
END AS Status_Of_Customers_Profit
FROM Customers_Avreage_Data

-------------------------------------------------------------

-- =====================================================
-- Products Above Average Profit
-- Calculates the total profit generated by each Products
-- and identifies Products whose profit exceeds the average.
-- =====================================================

WITH Products_Above_Average_Profit AS(
SELECT P.[Product ID] , P.[Product Name] , Sum(OD.Sales) as Total_Sales, SUM(OD.Profit) as Total_Profit
FROM Products_Dataset_Info as P
Join Order_Details_Data_Info as OD
ON P.[Product ID] = OD.[Product ID]
GROUP BY P.[Product ID] , P.[Product Name]
)
 , Products_Avreage_Data AS (
Select [Product ID] , [Product Name] , Total_Sales , Total_Profit , AVG(Total_Profit) OVER() AS Total_Avreage_Profit
FROM Products_Above_Average_Profit
)

SELECT [Product ID] , [Product Name] , Total_Sales , Total_Profit ,Total_Avreage_Profit , 
CASE
    WHEN Total_Profit > Total_Avreage_Profit THEN 'ABOVE_AVERAGE'
    WHEN Total_Profit = Total_Avreage_Profit THEN 'AVERAGE'
    ELSE 'BELOW_AVERAGE'
END AS Status_Of_Products_Profit
FROM Products_Avreage_Data


------------------------------------------------------

WITH Categories_Above_Average_Profit AS(
SELECT P.Category , Sum(OD.Sales) as Total_Sales, SUM(OD.Profit) as Total_Profit
FROM Products_Dataset_Info as P
Join Order_Details_Data_Info as OD
ON P.[Product ID] = OD.[Product ID]
GROUP BY P.Category
)
 , Categories_Avreage_Data AS (
Select Category , Total_Sales , Total_Profit , AVG(Total_Profit) OVER() AS Total_Avreage_Profit
FROM Categories_Above_Average_Profit
)

SELECT Category , Total_Sales , Total_Profit ,Total_Avreage_Profit , 
CASE
    WHEN Total_Profit > Total_Avreage_Profit THEN 'ABOVE_AVERAGE'
    WHEN Total_Profit = Total_Avreage_Profit THEN 'AVERAGE'
    ELSE 'BELOW_AVERAGE'
END AS Status_Of_Categories_Profit
FROM Categories_Avreage_Data
ORDER BY Total_Profit DESC

-------------------------------------------------------------
-- =====================================================
-- Customer Performance Overview
-- Analyzes customer sales activity by calculating
-- total orders, quantity purchased, and total profit.
-- =====================================================

CREATE VIEW Customers_Performance__Overviews_info AS
SELECT
    C.[Customer ID],
    C.[Customer Name],
    SUM(OD.Quantity) AS Quantity_Purchased,
    COUNT(DISTINCT O.[Order ID]) AS Total_Orders,
    SUM(OD.Profit) AS Total_Profit,
    SUM(OD.Sales) AS Total_Sales,
    AVG(OD.Profit) AS Total_Average_Profit
FROM Customers_Dataset_Info AS C
JOIN Orders_Data_Info AS O
    ON O.[Customer ID] = C.[Customer ID]
JOIN Order_Details_Data_Info AS OD
    ON OD.[Order ID] = O.[Order ID]
GROUP BY
    C.[Customer ID],
    C.[Customer Name];

WITH Customer_Performance AS (
    SELECT
        [Customer ID],
        [Customer Name],
        Total_Sales,
        Total_Average_Profit,
        Total_Profit,
        CASE
            WHEN Total_Profit >= 3000 THEN 'Very High'
            WHEN Total_Profit >= 1000 THEN 'High'
            ELSE 'Low'
        END AS Profit_Category
    FROM Customers_Performance__Overviews_info
)

SELECT *
FROM Customer_Performance
ORDER BY Total_Profit DESC;

-- =====================================================
-- Top 5 Most Frequently Ordering Customer
-- Identifies the five Customers appearing in the
-- highest number of unique orders and compares
-- their sales and profitability.
-- =====================================================

SELECT TOP 5
 [Customer ID],
 [Customer Name],
 Total_Orders,
 Total_Sales,
 Total_Average_Profit,
 Quantity_Purchased
FROM Customers_Performance__Overviews_info
ORDER BY Total_Orders DESC




-----------------------------------------------------
--04 - Stored Procedures----

-- Checks the stock status of a specific product based on its Product ID.
-- Returns the product name, category, current stock quantity, and stock status.

Create Procedure Checking_Product_Quantity_Details
@ProductID VARCHAR(255)
AS
BEGIN
SELECT P.[Product Name] , P.Category , OD.Quantity ,
CASE
    WHEN Quantity = 0 THEN 'NO QUANTITY'
    WHEN Quantity < 10 THEN 'LOW QUANTITY'
    ELSE 'HIGH-QUANTITY '
END AS StockStatus
FROM Products_Dataset_Info AS P
INNER JOIN Order_Details_Data_Info AS OD
ON P.[Product ID] = OD.[Product ID]
WHERE @ProductID = P.[Product ID]
END; 

EXEC Checking_Stock_Quantity_Details @ProductID = 'FUR-BO-10000112'
---------------------------------------------------------------
-- =====================================================
-- State Sales Performance Analysis
-- Analyzes customer, order, quantity, and profit
-- performance across cities within a selected State.
-- =====================================================


Create Procedure Cities_Status_By_State
@State varchar(255)
AS
Begin
SELECT CL.City , CL.Country  ,  COUNT(DISTINCT C.[Customer ID]) AS Total_Customers,  SUM(OD.PROFIT) AS Total_Proft , SUM(OD.Quantity) AS Total_Quantity_Purchased, 
Count(Distinct O.[Order ID]) Total_Orders , 
AVG(OD.PROFIT) AS Avreage_Profit, SUM(OD.Sales) AS Total_Sales

from Customer_Locations_Info as CL
join Customers_Dataset_Info as C
ON C.[Customer ID] = CL.[Customer ID]

JOIN Orders_Data_Info AS O
ON O.[Customer ID] = C.[Customer ID]
JOIN Order_Details_Data_Info AS OD
ON OD.[Order ID] = O.[Order ID]
WHERE CL.State = @State
GROUP BY  CL.City , CL.Country 
END

EXEC Cities_Status_By_State @State = 'Texas'

-----------------------------------------------------
-- =====================================================
-- Product Overview by Category and Sub-Category
-- Analyzes product sales, quantity purchased, and profit
-- based on the selected category and sub-category.
-- =====================================================

Create Procedure Get_Products_Overview_By_Categories 
@Category varchar(250) , @SubCategory varchar(250)
as
begin
Select P.[Product ID] , P.[Product Name] , SUM(OD.Sales) as Total_Sales , SUM(OD.Quantity) As Total_Quantity_Purchased , SUM(OD.Profit) as Total_Profit, AVG(OD.Profit) as Avreage_Profit
from Products_Data_Info as P
join Order_Details_Data_Info as OD
on P.[Product ID] = OD.[Product ID] AND P.[Product Name] = OD.[Product Name]
WHERE P.Category = @Category AND P.[Sub-Category] = @SubCategory
GROUP BY P.[Product ID] , P.[Product Name]
END 

EXEC Get_Products_Overview_By_Categories
    @Category = 'Furniture',
    @SubCategory = 'Chairs';
--------------------------------------------------
-- =====================================================
-- Segment Performance Analysis
-- Analyzes the sales, quantity, and profit performance
-- of a selected customer segment and classifies its
-- performance based on total profit.
-- =====================================================

CREATE PROCEDURE Segment_Cases_Status
    @Segment VARCHAR(255)
AS
BEGIN
SELECT
  C.Segment,
 SUM(OD.Sales) AS Total_Sales,
 SUM(OD.Quantity) AS Total_Quantity_Purchased,
 SUM(OD.Profit) AS Total_Profit,
  AVG(OD.Profit) AS Average_Profit,
 CASE
        WHEN SUM(OD.Profit) >= 15000 THEN 'High-Performing'
        WHEN SUM(OD.Profit) >= 10000 THEN 'Moderately Profitable'
         ELSE 'Low-Performing'
 END AS Segment_Status

FROM Customers_Dataset_Info AS C

INNER JOIN Orders_Data_Info AS O
ON O.[Customer ID] = C.[Customer ID]

INNER JOIN Order_Details_Data_Info AS OD
ON OD.[Order ID] = O.[Order ID]
WHERE C.Segment = @Segment

GROUP BY C.Segment;

END;

EXEC Segment_Cases_Status
    @Segment = 'Consumer'
------------------------------------------


-- 05: VIEWS ANALYSIS--
-- =====================================================
-- Customer Sales Performance Classification
-- Analyzes total sales generated by each customer
-- and classifies customers into High, Average, and Low sales categories.
-- =====================================================


Create VIEW Sales_Cases_Overview_Info AS
SELECT C.[Customer Name] , SUM(OD.Sales) as Total_Sales , 
Case
    WHEN SUM(OD.Sales) >=3000 THEN 'High-Sales'
    WHEN SUM(OD.Sales) >=2000 THEN 'Avreage-Sales'
    Else 'Low_Sales'
END AS State_Of_Sales
FROM Customers_Dataset_info AS C
JOIN Orders_Data_Info AS O
on O.[Customer ID] = C.[Customer ID]
JOIN Order_Details_Data_Info AS OD
ON OD.[Order ID] = O.[Order ID]
GROUP BY C.[Customer Name] 


SELECT * FROM  Sales_Cases_Overview_Info
------------------------------------------

CREATE VIEW Ship_Modes_Performances AS

SELECT
 O.[Ship Mode],
 COUNT(DISTINCT O.[Order ID]) AS Total_Orders,
 SUM(OD.Profit) AS Total_Profit,
 SUM(OD.Sales) AS Total_Sales,
 AVG(OD.Profit) AS Average_Profit,

CASE
      WHEN SUM(OD.Profit) >= 5000 THEN 'High-Performing'
      WHEN SUM(OD.Profit) >= 2500  THEN 'Moderately Profitable'
       ELSE 'Low-Performing'
 END AS Profit_Performance

FROM Orders_Data_Info AS O
INNER JOIN Order_Details_Data_Info AS OD
    ON OD.[Order ID] = O.[Order ID]
GROUP BY
    O.[Ship Mode];

  SELECT *
FROM Ship_Mode_Performance
ORDER BY Total_Profit DESC;

---------------------------------------
-- =====================================================
-- Product Performance View
-- Provides a reusable summary of product sales,
-- profit, quantity, and order performance.
-- =====================================================

CREATE VIEW Product_Performance_View AS
SELECT 
    P.[Product ID],
    P.[Product Name],
    P.Category,
    P.[Sub-Category],
    COUNT(DISTINCT OD.[Order ID]) AS Total_Orders,
    SUM(OD.Quantity) AS Total_Quantity,
    SUM(OD.Sales) AS Total_Sales,
    SUM(OD.Profit) AS Total_Profit,
    AVG(OD.Profit) AS Average_Profit
FROM Products_Dataset_Info AS P
INNER JOIN Order_Details_Data_Info AS OD
    ON OD.[Product ID] = P.[Product ID]
    AND OD.[Product Name] = P.[Product Name]
GROUP BY
    P.[Product ID],
    P.[Product Name],
    P.Category,
    P.[Sub-Category];

select * from Product_Performance_View
ORDER BY Total_Profit DESC

-- =====================================================
-- Top 5 Most Frequently Ordered Products
-- Identifies the five products appearing in the
-- highest number of unique orders and compares
-- their sales and profitability.
-- =====================================================

SELECT TOP 5
    [Product ID],
    [Product Name],
    Category,
    Total_Orders,
    Total_Quantity,
    Total_Sales,
    Total_Profit
FROM Product_Performance_View
ORDER BY Total_Orders DESC, Total_Quantity DESC;


----------------------------------------

-- =====================================================
-- Customer Profit Comparison Analysis
-- Analyzes each customer's sales and profit performance
-- and compares customer profit with the overall total profit.
-- Calculates the profit difference to measure the distance
-- between each customer's profit and the overall profit.
-- =====================================================

CREATE VIEW Customer_Profit_Comparison AS

SELECT 
    C.[Customer ID],
    C.[Customer Name],
    C.Segment,
    SUM(OD.Sales) AS Total_Sales,
    SUM(OD.Profit) AS Customer_Profit,
    SUM(SUM(OD.Profit)) OVER() AS Overall_Total_Profit,
    ABS(
        SUM(OD.Profit) - SUM(SUM(OD.Profit)) OVER()
    ) AS Profit_Difference
FROM Customers_Dataset_Info AS C
JOIN Orders_Data_Info AS O
    ON O.[Customer ID] = C.[Customer ID]
JOIN Order_Details_Data_Info AS OD
    ON OD.[Order ID] = O.[Order ID]
GROUP BY 
    C.[Customer ID],
    C.[Customer Name],
    C.Segment;

SELECT *
FROM Customer_Profit_Comparison
ORDER BY Customer_Profit DESC;



-------------------------------------------
-- =====================================================
-- Top 10 Customer Contribution Analysis
-- Identifies the top 10 customers based on their
-- contribution to total profit.
-- =====================================================

Create VIEW TOP10_CUSTOMERS_PROFIT_CONTRIBUTION AS

SELECT TOP 10  C.[Customer ID] , C.[Customer Name] ,
SUM(OD.Sales) AS Total_Sales  , 
SUM(OD.Profit) AS Customer_Profit, 
SUM(OD.Profit) * 100.0 / SUM(SUM(OD.Profit)) OVER() AS Contribution_Percentage ,
Case    
      WHEN  SUM(OD.Profit) * 100.0 / SUM(SUM(OD.Profit)) OVER() >= 20 THEN 'High_Contribution'
      WHEN  SUM(OD.Profit) * 100.0  / SUM(SUM(OD.Profit)) OVER() >= 10 THEN 'Average_Contribution'
      ELSE 'Low_Contribution'

End AS Contribution_Percentage_Status
from Customers_Dataset_Info as C

JOIN Orders_Data_Info AS O
ON O.[Customer ID] = C.[Customer ID]

JOIN Order_Details_Data_Info AS OD
ON OD.[Order ID] = O.[Order ID]

GROUP BY  C.[Customer ID] ,
C.[Customer Name]

ORDER BY Contribution_Percentage DESC

SELECT * FROM TOP10_CUSTOMERS_PROFIT_CONTRIBUTION


--------------------------------------------------------
-- =====================================================
-- Top 10 Products Contribution Analysis
-- Identifies the top 10 Products based on their
-- contribution to Total Profit.
-- =====================================================
CREATE VIEW TOP10_PRODUCTS_PROFIT_CONTRIBUTION AS
SELECT TOP 10
    P.[Product ID],
    P.[Product Name],
    SUM(OD.Sales) AS Total_Sales,
    SUM(OD.Profit) AS Total_Profit,
    SUM(OD.Profit) * 100.0
        / SUM(SUM(OD.Profit)) OVER() AS Contribution_Percentage ,
 Case
      WHEN  SUM(OD.Profit) * 100.0 / SUM(SUM(OD.Profit)) OVER() >= 20 THEN 'High_Contribution'
      WHEN  SUM(OD.Profit) * 100.0  / SUM(SUM(OD.Profit)) OVER() >= 10 THEN 'Average_Contribution'
      ELSE 'Low_Contribution'
End AS Contribution_Percentage_Status

FROM Products_Dataset_Info AS P

JOIN Order_Details_Data_Info AS OD
    ON OD.[Product ID] = P.[Product ID]

GROUP BY
    P.[Product ID],
    P.[Product Name]

ORDER BY Contribution_Percentage DESC;



SELECT *
FROM TOP10_PRODUCTS_PROFIT_CONTRIBUTION;
----------------------------------------------------
-- =====================================================
-- Top 10 Categories Contribution Analysis
-- Identifies the top 10 Categories  based on their
-- contribution to Total Profit.
-- =====================================================

Create VIEW TOP10_CATEGORYIES_PROFIT_CONTRIBUTION AS
SELECT TOP 10 P.Category , 
SUM(OD.Sales) AS Total_Sales,
 SUM(OD.Profit) AS Total_Profit,
 SUM(OD.Profit) * 100.0 / SUM(SUM(OD.Profit)) OVER() AS Contribution_Percentage,
CASE 
    WHEN SUM(OD.Profit) * 100.0 / SUM(SUM(OD.Profit)) OVER() >= 20 THEN 'High_Contribution'
    WHEN SUM(OD.Profit) * 100.0 / SUM(SUM(OD.Profit)) OVER() >=10 THEN 'Average_Contribution'
    ELSE 'Low_Contribution'
END AS Contribution_Percentage_Status

FROM Products_Dataset_Info AS P

JOIN Order_Details_Data_Info AS OD
ON OD.[Product ID] = P.[Product ID]

GROUP BY P.Category 

ORDER BY Contribution_Percentage DESC

SELECT *
FROM TOP10_CATEGORYIES_PROFIT_CONTRIBUTION;
----------------------------------------------------
-- =====================================================
-- Top  Ship Modes Contribution Analysis
-- Identifies the top Categories  based on their
-- contribution to Total Profit.
-- =====================================================

Create VIEW TOP_PROFITS_CONTRIBUTIONS_Ship_Modes AS
SELECT O.[Ship Mode] , SUM(OD.Sales) AS Total_Sales , SUM(OD.Profit) AS Total_Profit , 
SUM(OD.PROFIT) * 100.0 / SUM(SUM(OD.PROFIT)) OVER() AS Contribution_Percentage,
CASE
    WHEN SUM(OD.PROFIT) * 100.0 / SUM(SUM(OD.PROFIT)) OVER() >= 20 THEN 'High_Contribution'
    WHEN SUM(OD.PROFIT) * 100.0 / SUM(SUM(OD.PROFIT)) OVER() >= 10 THEN 'Average_Contribution'
    ELSE 'Low_Contribution'
END AS Contribution_Status
FROM Orders_Data_Info AS O
JOIN Order_Details_Data_Info AS OD
ON OD.[Order ID] = O.[Order ID]
GROUP BY O.[Ship Mode]


SELECT * FROM TOP_PROFITS_CONTRIBUTIONS_Ship_Modes
ORDER BY Contribution_Percentage DESC

--===============================================================--