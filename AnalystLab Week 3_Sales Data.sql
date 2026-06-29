
CREATE TABLE sales (
    ORDERNUMBER        INT,
    QUANTITYORDERED    INT,
    PRICEEACH          DECIMAL(10,2),
    ORDERLINENUMBER    INT,
    SALES              DECIMAL(10,2),
    ORDERDATE          VARCHAR(50),
    STATUS             VARCHAR(30),
    QTR_ID             INT,
    MONTH_ID           INT,
    YEAR_ID            INT,
    PRODUCTLINE        VARCHAR(50),
    MSRP               INT,
    PRODUCTCODE        VARCHAR(20),
    CUSTOMERNAME       VARCHAR(100),
    PHONE              VARCHAR(30),
    ADDRESSLINE1       VARCHAR(100),
    ADDRESSLINE2       VARCHAR(100),
    CITY               VARCHAR(50),
    STATE              VARCHAR(50),
    POSTALCODE         VARCHAR(20),
    COUNTRY            VARCHAR(50),
    TERRITORY          VARCHAR(30),
    CONTACTLASTNAME    VARCHAR(50),
    CONTACTFIRSTNAME   VARCHAR(50),
    DEALSIZE           VARCHAR(20)
);

SELECT COUNT(*) 
FROM dbo.sales_data_sample;

SELECT *
FROM dbo.sales_data_sample


SELECT * 
FROM dbo.sales_data_sample;

SELECT ORDERNUMBER, CUSTOMERNAME, PRODUCTLINE, 
       QUANTITYORDERED, SALES, COUNTRY, DEALSIZE
FROM dbo.sales_data_sample;

--  Orders from USA only (WHERE)
SELECT ORDERNUMBER, CUSTOMERNAME, SALES, COUNTRY
FROM dbo.sales_data_sample
WHERE COUNTRY = 'USA';

-- Orders where total sales amount is above $5000
SELECT ORDERNUMBER, CUSTOMERNAME, SALES, PRODUCTLINE
FROM dbo.sales_data_sample
WHERE SALES > 5000;

--  Large deals only, sorted by sales highest to lowest
SELECT ORDERNUMBER, CUSTOMERNAME, SALES, DEALSIZE
FROM dbo.sales_data_sample
WHERE DEALSIZE = 'Large'
ORDER BY SALES DESC;

-- Orders from 2004 only
SELECT ORDERNUMBER, CUSTOMERNAME, SALES, YEAR_ID
FROM dbo.sales_data_sample
WHERE YEAR_ID = 2004
ORDER BY SALES DESC;

-- Total revenue by country
SELECT COUNTRY, SUM(SALES) AS TotalRevenue
FROM dbo.sales_data_sample
GROUP BY COUNTRY
ORDER BY TotalRevenue DESC;


SELECT PRODUCTLINE, SUM(SALES) AS TotalRevenue
FROM dbo.sales_data_sample
GROUP BY PRODUCTLINE
ORDER BY TotalRevenue DESC;


SELECT YEAR_ID, COUNT(ORDERNUMBER) AS NumberOfOrders
FROM dbo.sales_data_sample
GROUP BY YEAR_ID
ORDER BY YEAR_ID ASC;

-- Average sales amount per deal size
SELECT DEALSIZE, AVG(SALES) AS AverageSales
FROM dbo.sales_data_sample
GROUP BY DEALSIZE
ORDER BY AverageSales DESC;

--  Total revenue per customer
SELECT CUSTOMERNAME, SUM(SALES) AS TotalSpent
FROM dbo.sales_data_sample
GROUP BY CUSTOMERNAME
ORDER BY TotalSpent DESC;

-- Countries with total revenue above $100,000
SELECT COUNTRY, SUM(SALES) AS TotalRevenue
FROM dbo.sales_data_sample
GROUP BY COUNTRY
HAVING SUM(SALES) > 100000
ORDER BY TotalRevenue DESC;

--  Product lines with more than 500 orders
SELECT PRODUCTLINE, COUNT(ORDERNUMBER) AS NumberOfOrders
FROM dbo.sales_data_sample
GROUP BY PRODUCTLINE
HAVING COUNT(ORDERNUMBER) > 500
ORDER BY NumberOfOrders DESC;

-- Customers who spent more than $50,000 in total
SELECT CUSTOMERNAME, SUM(SALES) AS TotalSpent
FROM dbo.sales_data_sample
GROUP BY CUSTOMERNAME
HAVING SUM(SALES) > 50000
ORDER BY TotalSpent DESC;


--  Self Join — Compare each order to other orders 
-- from the same customer to see if they ordered multiple product lines
SELECT 
    a.CUSTOMERNAME,
    a.PRODUCTLINE  AS ProductLine1,
    b.PRODUCTLINE  AS ProductLine2,
    a.SALES        AS Sales1,
    b.SALES        AS Sales2
FROM dbo.sales_data_sample a
INNER JOIN dbo.sales_data_sample b 
    ON  a.CUSTOMERNAME = b.CUSTOMERNAME
    AND a.PRODUCTLINE  <> b.PRODUCTLINE  
ORDER BY a.CUSTOMERNAME ASC;


--  JOIN sales to a derived table — 
-- Show each order alongside that customer's total spending
SELECT 
    s.ORDERNUMBER,
    s.CUSTOMERNAME,
    s.PRODUCTLINE,
    s.SALES,
    ct.TotalSpent
FROM dbo.sales_data_sample s
INNER JOIN (
    SELECT CUSTOMERNAME, SUM(SALES) AS TotalSpent
    FROM dbo.sales_data_sample
    GROUP BY CUSTOMERNAME
) ct ON s.CUSTOMERNAME = ct.CUSTOMERNAME
ORDER BY ct.TotalSpent DESC;


-- JOIN to find best product line per country
SELECT 
    s.COUNTRY,
    s.PRODUCTLINE,
    SUM(s.SALES) AS TotalRevenue
FROM dbo.sales_data_sample s
INNER JOIN (
    SELECT COUNTRY, MAX(SALES) AS MaxSale
    FROM dbo.sales_data_sample
    GROUP BY COUNTRY
) ms ON s.COUNTRY = ms.COUNTRY
GROUP BY s.COUNTRY, s.PRODUCTLINE
ORDER BY s.COUNTRY, TotalRevenue DESC;



--  Customers who spent more than the average customer
SELECT CUSTOMERNAME, SUM(SALES) AS TotalSpent
FROM dbo.sales_data_sample
GROUP BY CUSTOMERNAME
HAVING SUM(SALES) > (
    -- Subquery: average spending per customer
    SELECT AVG(TotalPerCustomer)
    FROM (
        SELECT CUSTOMERNAME, SUM(SALES) AS TotalPerCustomer
        FROM dbo.sales_data_sample
        GROUP BY CUSTOMERNAME
    ) AS AvgCalc
)
ORDER BY TotalSpent DESC;


-- Orders that are above the average order value
SELECT ORDERNUMBER, CUSTOMERNAME, SALES, PRODUCTLINE
FROM dbo.sales_data_sample
WHERE SALES > (
    SELECT AVG(SALES) FROM dbo.sales_data_sample
)
ORDER BY SALES DESC;


-- Best performing product line overall
SELECT TOP 1 PRODUCTLINE, SUM(SALES) AS TotalRevenue
FROM dbo.sales_data_sample
GROUP BY PRODUCTLINE
ORDER BY TotalRevenue DESC;


-- Countries that have at least one Large deal
SELECT DISTINCT COUNTRY
FROM dbo.sales_data_sample
WHERE COUNTRY IN (
    -- Subquery: all countries that have a Large deal
    SELECT DISTINCT COUNTRY
    FROM dbo.sales_data_sample
    WHERE DEALSIZE = 'Large'
)
ORDER BY COUNTRY;




--  RANK — Rank customers by total sales
SELECT 
    CUSTOMERNAME,
    SUM(SALES) AS TotalSales,
    RANK() OVER (
        ORDER BY SUM(SALES) DESC  
    ) AS CustomerRank
FROM dbo.sales_data_sample
GROUP BY CUSTOMERNAME
ORDER BY CustomerRank;


-- RANK within each country — 
-- Who is the top customer in each country?
SELECT 
    COUNTRY,
    CUSTOMERNAME,
    SUM(SALES) AS TotalSales,
    RANK() OVER (
        PARTITION BY COUNTRY      
        ORDER BY SUM(SALES) DESC
    ) AS RankInCountry
FROM dbo.sales_data_sample
GROUP BY COUNTRY, CUSTOMERNAME
ORDER BY COUNTRY, RankInCountry;


-- ROW_NUMBER — Rank products within each product line by sales
SELECT 
    PRODUCTLINE,
    PRODUCTCODE,
    SUM(SALES) AS TotalSales,
    ROW_NUMBER() OVER (
        PARTITION BY PRODUCTLINE     
        ORDER BY SUM(SALES) DESC
    ) AS RankInProductLine
FROM dbo.sales_data_sample
GROUP BY PRODUCTLINE, PRODUCTCODE
ORDER BY PRODUCTLINE, RankInProductLine;


--  Running total of revenue by year then month
SELECT 
    YEAR_ID,
    MONTH_ID,
    SUM(SALES) AS MonthlySales,
    SUM(SUM(SALES)) OVER (
        PARTITION BY YEAR_ID   
        ORDER BY MONTH_ID
    ) AS RunningTotalByYear
FROM dbo.sales_data_sample
GROUP BY YEAR_ID, MONTH_ID
ORDER BY YEAR_ID, MONTH_ID;


-- Compare each order's sales to the average 
-- within its product line
SELECT 
    ORDERNUMBER,
    CUSTOMERNAME,
    PRODUCTLINE,
    SALES,
    AVG(SALES) OVER (
        PARTITION BY PRODUCTLINE     
    ) AS AvgForProductLine,
    SALES - AVG(SALES) OVER (
        PARTITION BY PRODUCTLINE
    ) AS DifferenceFromAvg
FROM dbo.sales_data_sample
ORDER BY PRODUCTLINE, DifferenceFromAvg DESC;


-- Top Ten Customers by Revenue
SELECT TOP 10
    CUSTOMERNAME,
    COUNTRY,
    COUNT(DISTINCT ORDERNUMBER)   AS TotalOrders,
    ROUND(SUM(SALES), 2)          AS TotalRevenue,
    ROUND(AVG(SALES), 2)          AS AvgOrderValue,
    RANK() OVER (
        ORDER BY SUM(SALES) DESC
    )                             AS CustomerRank
FROM dbo.sales_data_sample
GROUP BY CUSTOMERNAME, COUNTRY
ORDER BY TotalRevenue DESC;

-- How sales trend over month by month
SELECT 
    YEAR_ID                             AS SalesYear,
    MONTH_ID                            AS SalesMonth,
    ROUND(SUM(SALES), 2)                AS MonthlyRevenue,
    COUNT(DISTINCT ORDERNUMBER)         AS TotalOrders,
    -- Month over month change in revenue
    ROUND(SUM(SALES) - LAG(SUM(SALES)) OVER (
        PARTITION BY YEAR_ID
        ORDER BY MONTH_ID
    ), 2)                               AS RevenueChangeFromLastMonth,
    -- Running total within the year
    ROUND(SUM(SUM(SALES)) OVER (
        PARTITION BY YEAR_ID
        ORDER BY MONTH_ID
    ), 2)                               AS YearToDateRevenue
FROM dbo.sales_data_sample
GROUP BY YEAR_ID, MONTH_ID
ORDER BY SalesYear, SalesMonth;
