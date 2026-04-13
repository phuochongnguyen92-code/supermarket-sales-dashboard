-- Supermarket Sales Analysis
-- This SQL script analyzes sales performance, order volume,
-- customer behavior, and monthly trends using MySQL.

-- Question 1:
-- A. Count total number of orders
SELECT COUNT(Invoice_ID) AS Total_Order
FROM supermarket_sales;


-- B. Calculate total sales by Branch (round to 2 decimal places)
SELECT Branch, ROUND(SUM(cogs), 2) AS Sum_Sales
FROM supermarket_sales
GROUP BY Branch;


-- Question 2:
-- A. Calculate total sales and total orders by Product Line
SELECT Product_line, ROUND(SUM(cogs), 2) AS Sum_Sales, COUNT(Invoice_ID) AS Total_Order
FROM supermarket_sales
GROUP BY Product_line;


-- B. Calculate total sales and total orders by Customer Type and Product Line
SELECT Product_line, Customer_type, ROUND(SUM(cogs), 2) AS Sum_Sales, COUNT(Invoice_ID) AS Total_Order
FROM supermarket_sales
GROUP BY Product_line, Customer_type
ORDER BY Product_line;

-- Question 3:
-- A. Find hours where total orders are higher than the average
--    within the month that has the highest total sales

-- e: sales and orders by month and hour
WITH e AS (
    SELECT 
        MONTH(STR_TO_DATE(`Date`, '%c/%e/%Y')) AS mth,
        HOUR(`Time`) AS hr,
        ROUND(SUM(cogs), 2) AS Sum_Sales,
        COUNT(Invoice_ID) AS Total_Order
    FROM supermarket_sales
    GROUP BY 
        MONTH(STR_TO_DATE(`Date`, '%c/%e/%Y')),
        HOUR(`Time`)
),

-- f: total sales by month
f AS (
    SELECT 
        MONTH(STR_TO_DATE(`Date`, '%c/%e/%Y')) AS mth,
        ROUND(SUM(cogs), 2) AS Sum_Sales
    FROM supermarket_sales
    GROUP BY MONTH(STR_TO_DATE(`Date`, '%c/%e/%Y'))
),

-- k: month with highest sales
k AS (
    SELECT mth 
    FROM f
    WHERE Sum_Sales = (SELECT MAX(Sum_Sales) FROM f)
),

-- j: hourly orders in the highest sales month
j AS (
    SELECT 
        e.hr, 
        e.Total_Order
    FROM e 
    JOIN k 
        ON e.mth = k.mth
),

-- avg_order: average orders per hour
avg_order AS (
    SELECT AVG(Total_Order) AS avg_val 
    FROM j
)

-- filter hours where orders > average
SELECT 
    j.hr, 
    j.Total_Order
FROM j
CROSS JOIN avg_order
WHERE j.Total_Order > avg_order.avg_val
ORDER BY j.hr;


-- B. Find product line where customer type has fewer orders
--    but higher sales than the other type

WITH h AS (
    SELECT Product_line, Customer_type,
           ROUND(SUM(cogs), 2) AS Sum_Sales,
           COUNT(Invoice_ID) AS Total_Order
    FROM supermarket_sales
    GROUP BY Product_line, Customer_type
),
-- total orders per product line
l AS (
    SELECT Product_line, SUM(Total_Order) AS Total_Order_per_line
    FROM h
    GROUP BY Product_line
),
-- product line with lowest total orders
m AS (
    SELECT * FROM l
    WHERE Total_Order_per_line = (SELECT MIN(Total_Order_per_line) FROM l)
),
-- filter customer types in that product line
n AS (
    SELECT h.*, m.Total_Order_per_line
    FROM h JOIN m ON h.Product_line = m.Product_line
)
-- find customer type with lowest orders but highest sales
SELECT * FROM n
WHERE Total_Order = (SELECT MIN(Total_Order) FROM n)
  AND Sum_Sales = (SELECT MAX(Sum_Sales) FROM n);
 
-- Question 4:
-- Calculate monthly sales, total orders, and cumulative values of previous months

WITH e AS (
    SELECT 
        MONTH(STR_TO_DATE(`Date`, '%c/%e/%Y')) AS mth,
        ROUND(SUM(cogs), 2) AS Sum_Sales,
        COUNT(Invoice_ID) AS Total_Order
    FROM supermarket_sales
    GROUP BY MONTH(STR_TO_DATE(`Date`, '%c/%e/%Y'))
)

SELECT 
    mth,
    Sum_Sales,
    Total_Order,

    -- cumulative sales of previous months
    ROUND(
        SUM(Sum_Sales) OVER (
            ORDER BY mth 
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ), 2
    ) AS Total_Sales_Before,

    -- cumulative orders of previous months
    SUM(Total_Order) OVER (
        ORDER BY mth 
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
    ) AS Total_Order_Before

FROM e
ORDER BY mth;




