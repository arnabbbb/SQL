use gdb023;

-- Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.
SELECT distinct(market)
FROM dim_customer
WHERE customer = "Atliq Exclusive"
AND region = "APAC";

-- What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields: unique_products_2020, unique_products_2021, percentage_chg
SELECT 
SUM(IF(fiscal_year = 2020, 1,0)) AS "2020_count",
SUM(IF(fiscal_year = 2021, 1,0)) AS "2021_count",
ROUND(SUM(IF(fiscal_year = 2021, 1,0))*100/SUM(IF(fiscal_year = 2020, 1,0)),2) AS "percentage change"
FROM product_year;

-- Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. The final output contains 2 fields, segment, product_count
select segment, count(*) as product_count
from dim_product
group by segment
order by count(*) desc;

select count(*)
from dim_product;

with cte as(
select segment, product, COUNT(*)
from dim_product
GROUP BY segment, product)
select segment, count(*)
from cte
group by segment;

-- Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields, segment, product_count_2020, product_count_2021, difference
select segment,
SUM(IF(py.fiscal_year=2020,1,0)) AS 2020_count,
SUM(IF(py.fiscal_year=2021,1,0)) AS 2021_count,
(SUM(IF(py.fiscal_year=2021,1,0)) - SUM(IF(py.fiscal_year=2020,1,0))) AS difference
from product_year py
join dim_product p
using (product_code)
GROUP BY segment
ORDER BY SUM(IF(py.fiscal_year=2021,1,0)) - SUM(IF(py.fiscal_year=2020,1,0)) DESC;

-- Get the products that have the highest and lowest manufacturing costs. The final output should contain these fields, product_code, product, manufacturing_cost
WITH cte1 as(
SELECT p.product_code, p.product, manufacturing_cost
FROM fact_manufacturing_cost AS mc
JOIN dim_product AS p
USING (product_code)
ORDER BY manufacturing_cost DESC
LIMIT 1),
cte2 AS (SELECT p.product_code, p.product, manufacturing_cost
FROM fact_manufacturing_cost AS mc
JOIN dim_product AS p
USING (product_code)
ORDER BY manufacturing_cost ASC 
LIMIT 1)
SELECT * 
FROM cte1
UNION 
SELECT * 
FROM cte2;

-- Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market. The final output contains these fields customer_code, customer, average_discount_percentage
with cte as(
select c.*, d.fiscal_year, d.pre_invoice_discount_pct
from  dim_customer c
JOIN fact_pre_invoice_deductions d
USING (customer_code)
where c.market= "India"
and d.fiscal_year = 2021)
select customer_code, customer, ROUND(avg(pre_invoice_discount_pct*100),2) as average_discount_percentage
from cte
group by customer_code, customer
order by avg(pre_invoice_discount_pct) desc limit 5;

-- Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. This analysis helps to get an idea of low and high-performing months and take strategic decisions. The final report contains these columns: Month, Year, Gross sales Amount
with cte as(
select s.*, g.gross_price, c.customer, g.gross_price * s.sold_quantity as gross_sales_amount
from fact_sales_monthly s
join fact_gross_price g
on s.product_code = g.product_code
and s.fiscal_year = g.fiscal_year
join dim_customer c
on s.customer_code = c.customer_code
where c.customer = "Atliq Exclusive")
select month(date) as month, year(date) as year, round(sum(gross_sales_amount),2) as gross_sales_amount
 from cte
 group by month(date), year(date);
 
 -- In which quarter of 2020, got the maximum total_sold_quantity? The final output contains these fields sorted by the total_sold_quantity, Quarter, total_sold_quantity
 select quarter(date), sum(sold_quantity) as total_sold_quantity
 from fact_sales_monthly
  where year(date)=2020
 group by quarter(date)
 order by sum(sold_quantity) desc;
 
 -- Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? The final output contains these fields: channel, gross_sales_mln, percentage

WITH cte as(
select c.channel , ROUND(SUM(g.gross_price * s.sold_quantity)/1000000,2) as gross_sales_amount_mln
from fact_sales_monthly s
join fact_gross_price g
on s.product_code = g.product_code
and s.fiscal_year = g.fiscal_year
join dim_customer c
on s.customer_code = c.customer_code
where s.fiscal_year = 2021
GROUP BY c.channel)
SELECT channel, gross_sales_amount_mln, ROUND(gross_sales_amount_mln/(SELECT SUM(gross_sales_amount_mln) FROM cte)*100,2) AS percentage
FROM cte;

-- Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? The final output contains these fields, division, product_code, product, total_sold_quantity, rank_order
with cte as(
select p.division, p.product, SUM(sold_quantity) as total_sold_quantity
from fact_sales_monthly s
join dim_product p
using (product_code)
where fiscal_year = 2021
GROUP BY p.division, p.product),
cte2 as(
select *,
dense_rank() over(partition by division order by total_sold_quantity desc) AS rank_order
from cte)
select * from cte2
where rank_order<=3;


