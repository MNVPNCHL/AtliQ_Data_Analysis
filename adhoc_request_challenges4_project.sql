-- Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.
SELECT *
FROM dim_customer
where customer like '%Atliq Exclusive%' and region = "APAC";

-- What is the percentage of unique product increase in 2021 vs. 2020
with fy_20 as 
			(SELECT  count(distinct product_code) as unique_products_2020
			 FROM fact_sales_monthly
			 where fiscal_year = 2020),
 fy_21 as 
			(select count(distinct product_code) unique_products_2021
			 FROM fact_sales_monthly
			 where fiscal_year = 2021)
select *, 
	ROUND((unique_products_2021-unique_products_2020) * 100/unique_products_2020, 2) as percentage_chg
from fy_20,fy_21;

-- Provide a report with all the unique product counts for each segment and sort them in descending order of product counts.
SELECT 
	segment, 
    count( product) as product_count 
FROM gdb023.dim_product
group by segment
order by product_count desc;

-- Follow-up: Which segment had the most increase in unique products in 2021 vs 2020

with fy_20 as (
			SELECT segment, count(distinct(s.product_code)) as seg20
			FROM fact_sales_monthly s 
			join dim_product p
			using (product_code)
			where fiscal_year = 2020
			group by segment),

fy_21 as (
			SELECT segment, count(distinct(s.product_code)) as seg21
			FROM fact_sales_monthly s 
			join dim_product p
			using (product_code)
			where fiscal_year = 2021
			group by segment)

select 
	fy_20.segment, 
	fy_20.seg20, 
    fy_21.seg21,
	fy_21.seg21 -fy_20.seg20 as difference
from fy_20
join fy_21
	on fy_20.segment= fy_21.segment
order by difference desc;

-- Get the products that have the highest and lowest manufacturing costs

SELECT 
	fc.product_code, 
    product, 
    manufacturing_cost
FROM fact_manufacturing_cost as fc
JOIN dim_product as dp
	ON fc.product_code = dp.product_code
WHERE fc.manufacturing_cost = (SELECT max(manufacturing_cost) FROM fact_manufacturing_cost) OR
		fc.manufacturing_cost = (SELECT min(manufacturing_cost) FROM fact_manufacturing_cost)
ORDER BY manufacturing_cost DESC;

-- Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and
-- in the Indian market.

select 
	pr.customer_code, 
    c.customer,
	round(avg(pr.pre_invoice_discount_pct * 100), 2) as avg_dis
from fact_pre_invoice_deductions pr
join dim_customer c  
	on c.customer_code = pr.customer_code
    where pr.fiscal_year = 2021 and c.market = "India"
group by pr.customer_code, c.customer
order by avg_dis desc
limit 5;


-- Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month.
--  This analysis helps to get an idea of low and high-performing months and take strategic decisions

SELECT 
	month(s.date) as month ,
    s.fiscal_year as year, 
    round(sum(gross_price*sold_quantity)/ 1000000, 2) as gross_sales_mln
FROM fact_sales_monthly s
join fact_gross_price  g 
	on g.product_code = s.product_code
    and g.fiscal_year = s.fiscal_year
join dim_customer c 
	on c.customer_code = s.customer_code
where customer = "Atliq Exclusive"
group by month(s.date), s.fiscal_year
order by gross_sales_mln;

-- In which quarter of 2020, got the maximum total_sold_quantity

with quarter as (
	select sold_quantity,
case
	when month(date) in (09,10,11) then "Q1"
    when month(date) in (12,01,02) then "Q2"
    when month(date) in (03,04,05) then "Q3"
    when month(date) in (06,07,08) then "Q4"
end as quarter
from fact_sales_monthly
where fiscal_year = 2020)

select 
	quarter, sum(sold_quantity) as total_sold_quantity
    
from quarter
group by quarter
order by total_sold_quantity desc;


-- Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?

with cte1 as (
SELECT 
	c.channel,
    round(sum(gross_price*sold_quantity)/ 1000000, 3) as gross_sales_mln
FROM fact_sales_monthly s
join fact_gross_price  g 
	on g.product_code = s.product_code
    and g.fiscal_year = s.fiscal_year
join dim_customer c 
	on c.customer_code = s.customer_code
where s.fiscal_year = 2021
group by c.channel)

select *, 	
	round(c.gross_sales_mln/ sum(c.gross_sales_mln) over() * 100, 2)as percentage
from cte1 c
order by gross_sales_mln desc ;

-- Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021

with cte1 as (
			SELECT 
				p.division,
				s.product_code,
				p.product,
				sum(s.sold_quantity) as total_sold_quantity
			FROM fact_sales_monthly s 
			join dim_product p 
				on p.product_code = s.product_code
			where s.fiscal_year = 2021
			group by s.product_code, p.division,p.product),
drk as (
			select *,
				dense_rank () over (partition by division order by total_sold_quantity desc) as drk
			from cte1)
select * from drk
where drk <4 ;