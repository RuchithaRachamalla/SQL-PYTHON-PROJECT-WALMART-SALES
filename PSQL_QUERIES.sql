/* creating database */

CREATE DATABASE walmart_db

/* using python connected to the postgresql */
/* created a table */

SELECT * FROM walmart_table

SELECT COUNT(*) FROM walmart_table

/* types of payment methods and their count */

SELECT
    payment_method,
    COUNT(*) AS no_payments,
    SUM(quantity) AS no_qty_sold
FROM walmart_table
GROUP BY 1

/* number of different branches */

SELECT COUNT(DISTINCT branch)
FROM walmart_table

SELECT MAX(quantity) FROM walmart_table
SELECT MIN(quantity) FROM walmart_table

-- Business Problems
--1Q: Find different payment method and number of transactions, number of qty sold

SELECT
    payment_method,
    COUNT(*) AS no_payments,
    SUM(quantity) AS no_qty_sold
FROM walmart_table
GROUP BY 1

--2Q: Identify the highest-rated category in each branch, displaying the branch, category
-- AVG RATING

SELECT *
FROM
(   SELECT
        branch,
        category,
        AVG(rating) AS avg_rating,
        RANK() OVER(PARTITION BY branch ORDER BY AVG(rating) DESC) AS rank
    FROM walmart_table
    GROUP BY 1, 2
)
WHERE rank = 1

--3Q: Identify the busiest day for each branch based on the number of transactions

SELECT *
FROM
    (SELECT
        branch,
        TO_CHAR(TO_DATE(date, 'DD/MM/YY'), 'Day') AS day_name,
        COUNT(*) AS no_transactions,
        RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) AS rank
    FROM walmart_table
    GROUP BY 1, 2
    )
WHERE rank = 1

--4Q: Calculate the total quantity of items sold per payment method. List payment_method and total_quantity.

SELECT
    payment_method,
    -- COUNT(*) as no_payments,
    SUM(quantity) AS no_qty_sold
FROM walmart_table
GROUP BY payment_method

-- 5Q: Determine the average, minimum, and maximum rating of category for each city. 
-- List the city, average_rating, min_rating, and max_rating.

SELECT
    city,
    category,
    MIN(rating) AS min_rating,
    MAX(rating) AS max_rating,
    AVG(rating) AS avg_rating
FROM walmart_table
GROUP BY 1, 2

--6Q: calculate the total profit for each category by considering total_profit as
-- (unit_price * quantity * profit_margin). 
-- List category and total_profit, ordered from highest to lowest profit.

SELECT
    category,
    SUM(total) AS total_revenue,  -- Assuming 'total' represents (unit_price * quantity)
    SUM(total * profit_margin) AS profit
FROM walmart_table
GROUP BY 1

--7Q: Determine the most common payment method for each Branch. 
-- Display Branch and the preferred_payment_method.

WITH cte
AS
(SELECT
    branch,
    payment_method,
    COUNT(*) AS total_trans,
    RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) AS rank
FROM walmart_table
GROUP BY 1, 2
)
SELECT *
FROM cte
WHERE rank = 1

--8Q: Categorize sales into 3 group MORNING, AFTERNOON, EVENING 
-- Find out each of the shift and number of invoices

SELECT
    branch,
CASE
        WHEN EXTRACT(HOUR FROM(time::time)) < 12 THEN 'Morning'
        WHEN EXTRACT(HOUR FROM(time::time)) BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END day_time,
    COUNT(*)
FROM walmart_table
GROUP BY 1, 2
ORDER BY 1, 3 DESC

--9Q: Identify 5 branch with highest decrease ratio in 
-- revenue compare to last year(current year 2023 and last year 2022)
-- rdr == last_rev-cr_rev/ls_rev*100

WITH revenue_2022 AS (
    SELECT
        branch,
        SUM(total) AS revenue_2022
    FROM walmart_table
    WHERE EXTRACT(YEAR FROM TO_DATE(date, 'DD/MM/YY')) = 2022
    GROUP BY 1
),
revenue_2023 AS (
    SELECT
        branch,
        SUM(total) AS revenue_2023
    FROM walmart_table
    WHERE EXTRACT(YEAR FROM TO_DATE(date, 'DD/MM/YY')) = 2023
    GROUP BY 1
)
SELECT
    COALESCE(ls.branch, cs.branch) AS branch,  -- Get branch even if one year is NULL
    COALESCE(ls.revenue_2022, 0) AS last_year_revenue,  -- Handle NULLs with 0
    COALESCE(cs.revenue_2023, 0) AS cr_year_revenue,  -- Handle NULLs with 0
    CASE
        WHEN ls.revenue_2022 IS NULL THEN -100  -- New branch (100% increase)
        WHEN cs.revenue_2023 IS NULL THEN 100   -- Closed branch (100% decrease)
        WHEN ls.revenue_2022 = 0 THEN NULL      -- Avoid division by zero
        ELSE ROUND(
            (ls.revenue_2022 - cs.revenue_2023)::numeric /
            ls.revenue_2022::numeric * 100,
            2
        )
    END AS rev_dec_ratio
FROM revenue_2022 AS ls
FULL OUTER JOIN revenue_2023 AS cs  -- Use FULL OUTER JOIN
ON ls.branch = cs.branch
WHERE COALESCE(ls.revenue_2022, 0) > COALESCE(cs.revenue_2023, 0) --Corrected WHERE clause
ORDER BY rev_dec_ratio DESC NULLS LAST
LIMIT 5;