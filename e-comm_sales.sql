
-- 1) Total sales, total profit, profit margin, distinct orders, and average order value

SELECT 
	ROUND(SUM(sales)::numeric,2) AS total_sales,
	ROUND(SUM(profit)::numeric,2) AS total_profit,
	ROUND(((SUM(profit)/SUM(sales))*100)::numeric,2) AS profit_margin,
	COUNT(DISTINCT order_id) AS orders,
	ROUND((SUM(sales)/COUNT(DISTINCT order_id))::numeric,2) AS avg_order_value
FROM
	sales;

-- 2) Monthly sales and profit for each year.

SELECT
	SUM(profit) AS monthly_profit,
	order_year,
	order_month_no
FROM
	sales
GROUP BY
	order_year, 
	order_month_no
ORDER BY 
	order_year, 
	order_month_no;

-- 3) Month-over-month sales growth.

WITH monthly_sales AS(
	SELECT 
		order_year as sales_year,
		order_month_no as sales_month,
		SUM(sales) as total_sales
	FROM
		sales
	GROUP BY
		order_year,
		order_month_no
	ORDER BY
		order_year ASC,
		order_month_no ASC
)
SELECT
	sales_year,
	sales_month,
	ROUND(total_sales::numeric, 2) AS current_month_sales,
	ROUND(LAG(total_sales,1) OVER (ORDER BY sales_year ASC, sales_month ASC)::numeric,2) AS previous_month_sales,
	 ROUND((
        (total_sales - LAG(total_sales, 1) OVER (ORDER BY sales_year ASC, sales_month ASC)) 
        / LAG(total_sales, 1) OVER (ORDER BY sales_year ASC, sales_month ASC) * 100
  		  )::numeric, 2) AS mom_growth_percent
FROM
	monthly_sales;
	
-- 4) Highest- and lowest-performing months.

WITH monthly_sales AS(
	SELECT 
		order_year as sales_year,
		order_month_no AS sales_month,
		ROUND(SUM(sales)::numeric,2) as total_sales 
	FROM 
		sales
	GROUP BY 
		order_year,
		order_month_no
	ORDER BY
		order_year,
		order_month_no
),
ranked_month AS(
	SELECT
		sales_year,
		sales_month,
		total_sales,
		row_number() OVER(PARTITION BY sales_year ORDER BY total_sales DESC) AS sales_rank
	FROM 
		monthly_sales
),
monthly_profit AS(
	SELECT 
		order_year as profit_year,
		order_month_no AS profit_month,
		ROUND(SUM(profit)::numeric,2) as total_profit 
	FROM 
		sales
	GROUP BY 
		order_year,
		order_month_no
	ORDER BY
		order_year,
		order_month_no
),
ranked_month_p AS(
	SELECT
		profit_year,
		profit_month,
		total_profit,
		row_number() OVER(PARTITION BY profit_year ORDER BY total_profit DESC) AS profit_rank
	FROM 
		monthly_profit
)
SELECT
	s.sales_year AS year,
	s.sales_month AS high_sales_month,
	s.total_sales AS high_sales,
	p.profit_month AS high_profit_month,
	p.total_profit AS high_profit
FROM
	ranked_month s
JOIN 
	ranked_month_p p ON s.sales_year = p.profit_year
WHERE
	s.sales_rank = 1
	AND p.profit_rank = 1;
	


WITH monthly_sales AS(
	SELECT 
		order_year as sales_year,
		order_month_no AS sales_month,
		ROUND(SUM(sales)::numeric,2) as total_sales 
	FROM 
		sales
	GROUP BY 
		order_year,
		order_month_no
	ORDER BY
		order_year,
		order_month_no
),
ranked_month AS(
	SELECT
		sales_year,
		sales_month,
		total_sales,
		row_number() OVER(PARTITION BY sales_year ORDER BY total_sales ASC) AS sales_rank
	FROM 
		monthly_sales
),
monthly_profit AS(
	SELECT 
		order_year as profit_year,
		order_month_no AS profit_month,
		ROUND(SUM(profit)::numeric,2) as total_profit 
	FROM 
		sales
	GROUP BY 
		order_year,
		order_month_no
	ORDER BY
		order_year,
		order_month_no
),
ranked_month_p AS(
	SELECT
		profit_year,
		profit_month,
		total_profit,
		row_number() OVER(PARTITION BY profit_year ORDER BY total_profit ASC) AS profit_rank
	FROM 
		monthly_profit
)
SELECT
	s.sales_year AS year,
	s.sales_month AS low_sales_month,
	s.total_sales AS low_sales,
	p.profit_month AS low_profit_month,
	p.total_profit AS low_profit
FROM
	ranked_month s
JOIN 
	ranked_month_p p ON s.sales_year = p.profit_year
WHERE
	s.sales_rank = 1
	AND p.profit_rank = 1;
	
-- 5) Sales, profit, and profit margin by category and sub-category.

SELECT
	category,
	ROUND(SUM(sales)::numeric,2) AS sales,
	ROUND(SUM(profit)::numeric,2) AS profit,
	Round(((SUM(profit)/sum(sales)*100))::numeric,2) AS profit_margin
FROM
	sales
GROUP BY category;

SELECT
	"sub-category",
	ROUND(SUM(sales)::numeric,2) AS sales,
	ROUND(SUM(profit)::numeric,2) AS profit,
	Round(((SUM(profit)/sum(sales)*100))::numeric,2) AS profit_margin
FROM
	sales
GROUP BY 
	"sub-category";
	
-- 6) Top 10 products by profit.

SELECT 
	product_id,
	product_name,
	ROUND(SUM(profit)::numeric,2) AS profit
FROM 
	sales
GROUP BY 
	product_id,
	product_name
ORDER BY 
	SUM(profit) DESC
LIMIT 10;
	
-- 7) Bottom 10 products by profit.

SELECT 
	product_id,
	product_name,
	ROUND(SUM(profit)::numeric,2) AS profit
FROM 
	sales
GROUP BY 
	product_id,
	product_name
ORDER BY 
	SUM(profit) ASC
LIMIT 10;

-- 8) High-sales products that generate negative profit.

SELECT 
	product_id,
	product_name,
	ROUND(SUM(profit)::numeric,2) AS profit,
	ROUND(SUM(sales)::numeric,2) AS sales
FROM 
	sales
GROUP BY 
	product_id,
	product_name
ORDER BY 
	SUM(profit) ASC,
	SUM(sales) DESC
LIMIT 10;

-- 8) Year-wise product category performance.

WITH yearly_performance AS(
	SELECT 
		category,
		order_year as sales_year,
		ROUND(SUM(sales)::numeric,2) as total_sales, 
		ROUND(SUM(profit)::numeric,2) as total_profit
	FROM 
		sales
	GROUP BY 
		category,
		order_year
	ORDER BY
		category,
		order_year
),
performance_with_previous_year AS (
    SELECT
        sales_year,
        category,
        total_sales,
        total_profit,

        LAG(total_sales) OVER (
            PARTITION BY category
            ORDER BY sales_year
        ) AS previous_year_sales,

        LAG(total_profit) OVER (
            PARTITION BY category
            ORDER BY sales_year
        ) AS previous_year_profit
    FROM yearly_performance
)
SELECT
    sales_year,
    category,
    ROUND(total_sales::numeric, 2) AS total_sales,
    ROUND(previous_year_sales::numeric, 2) AS previous_year_sales,

    ROUND(
        ((total_sales - previous_year_sales)
        / NULLIF(previous_year_sales, 0) * 100)::numeric,
        2
    ) AS sales_yoy_growth_pct,

    ROUND(total_profit::numeric, 2) AS total_profit,
    ROUND(previous_year_profit::numeric, 2) AS previous_year_profit,

    ROUND(
        ((total_profit - previous_year_profit)
        / NULLIF(ABS(previous_year_profit), 0) * 100)::numeric,
        2
    ) AS profit_yoy_change_pct

FROM performance_with_previous_year
ORDER BY category, sales_year;

-- 9) Sales, profit, and profit margin by region.

SELECT 
	ROUND(SUM(sales)::numeric,2) AS sales,
	ROUND(SUM(profit)::numeric,2) AS profit,
	ROUND(((SUM(profit)/SUM(sales))*100)::numeric,2) AS profit_margin,
	region
FROM
	sales
GROUP BY 
	region;

-- 10) Sales, profit, and profit margin by customer segment.

SELECT 
	ROUND(SUM(sales)::numeric,2) AS sales,
	ROUND(SUM(profit)::numeric,2) AS profit,
	ROUND(((SUM(profit)/SUM(sales))*100)::numeric,2) AS profit_margin,
	segment
FROM
	sales
GROUP BY 
	segment;

-- 11) State-wise performance to identify strong and weak markets.

SELECT
	state,
	ROUND(SUM(sales)::numeric,2) AS sales,
	ROUND(SUM(profit)::numeric,2) AS profit,
	ROUND(((SUM(profit)/SUM(sales))*100)::numeric,2) AS profit_margin
FROM
	sales
GROUP BY
	state;

-- 12) Sales and profit at each discount level.

SELECT
	ROUND(SUM(sales)::numeric,2) AS sales,
	ROUND(SUM(profit)::numeric,2) AS profit,
	discount AS discount_level
FROM
	sales
GROUP BY
	discount;

-- 13) Profit margin by discount level.
SELECT
	ROUND(((SUM(profit)/SUM(sales))*100)::numeric,2) AS profit_margin,
	discount AS discount_level
FROM
	sales
GROUP BY
	discount;


-- 14) Sub-categories with negative profit at higher discounts.

SELECT
	discount AS discount_level,
	"sub-category",
	ROUND(SUM(profit)::numeric,2) AS profit
FROM
	sales
GROUP BY
	discount,
	"sub-category"
HAVING
	ROUND(SUM(profit)::numeric,2) <= 0
ORDER BY
	discount;




