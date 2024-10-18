-- Monday Coffee -- Data Analysis 

SELECT * from city;
SELECT * from products;
SELECT * from customers;
SELECT * from sales;

-- Reports & Data Analysis
-- Q1. Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

SELECT city_name, 
ROUND((population * 0.25)/1000000,2) as Coffee_consumers_in_millions, 
city_rank from city
Order By 2 DESC;

-- Q2.Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

SELECT 
	SUM(total) as total_revenue from sales
where 
	EXTRACT(YEAR FROM sale_date) = 2023 and 
	EXTRACT(quarter FROM sale_date) = 4

	
SELECT 
	ci.city_name,
	SUM(s.total) as total_revenue
from sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
where 
	EXTRACT(YEAR FROM s.sale_date) = 2023 and 
	EXTRACT(quarter FROM s.sale_date) = 4
group by 1 	
order by 2 DESC

-- Q3 Sales Count for Each Product
--How many units of each coffee product have been sold?

select p.product_name, COUNT(s.product_id) from sales as s
right join products as p
on s.product_id = p.product_id
group by 1
order by 2 DESC;

-- Q4 Average Sales Amount per City
-- What is the average sales amount per customer in each city?

SELECT 
	ci.city_name,
	SUM(s.total) as total_revenue,
	COUNT(DISTINCT c.customer_name) as total_cux,
	ROUND(SUM(s.total)::numeric / COUNT(DISTINCT c.customer_name)::numeric,2) as percity_average_sale
from sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
group by 1 	
order by 2 DESC;

---Q5 City Population and Coffee Consumers(25%)
---Provide list of cities along with Their popualtion and estimated coffee customers
---return city_name, total_current_cx, estimated coffee consumers (25%)

with 
city_table as
(
SELECT  
	city_name,
	ROUND((population * 0.25)/1000000, 2) as coffee_customers_in_millions
from city
),

Customer_table as 
(
Select 
	ci.city_name,
	COUNT(Distinct c.customer_id) as unique_cx
from sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
Group by 1
)

SELECT 
	ct.city_name,
	ct.coffee_customers_in_millions,
	cust.unique_cx
from city_table as ct
JOIN Customer_table as cust
on ct.city_name = cust.city_name

---Q6 Top Selling Products by City
---What are the top 3 selling products in each city based on sales volume?

SELECT * from
(
select p.product_name, ci.city_name, count(p.product_name) as total_order,
	DENSE_RANK() OVER(PARTITION BY ci.city_name order by count(p.product_name) DESC) AS City_rank
from products as p
join sales as s on p.product_id = s.product_id
join customers as cus on s.customer_id = cus.customer_id
join city as ci on ci.city_id = cus.city_id
group by p.product_name, ci.city_name
) as t1
WHERE City_rank <=3


--Q7Customer Segmentation by City
--How many unique customers are there in each city who have purchased coffee products?

Select 
	ci.city_name,
	count(DISTINCT c.customer_id) as unique_cx
from city as ci
LEFT JOIN customers as c
on ci.city_id = c.city_id
JOIN sales as s
on s.customer_id = c.customer_id
JOIN products as p
on p.product_id = s.product_id
WHERE p.product_id BETWEEN 1 AND 14
GROUP BY 1
ORDER BY 2 DESC

--Q8 Average Sale vs Rent
--Find each city and their average sale per customer and avg rent per customer

with city_table as
(
SELECT 
	ci.city_name,
	COUNT(DISTINCT c.customer_name) as total_cux,
	ROUND(SUM(s.total)::numeric / COUNT(DISTINCT c.customer_name)::numeric,2) as percity_average_sale
from sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
group by 1 	
order by 2 DESC
),

city_rent as 
(
Select 
city_name, estimated_rent
from city
)

select 
	cr.city_name,
	cr.estimated_rent,
	ct.total_cux,
	ct.percity_average_sale,
	round((cr.estimated_rent/ct.total_cux)::numeric,2) as avg_rent_per_customers
from city_rent as cr
JOIN city_table as ct
ON cr.city_name =ct.city_name
order by 4 DESC

--Q9. Monthly Sales Growth
--Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).
with
monthly_sales as
(
select 
	ci.city_name,
	EXTRACT(month FROM sale_date) as month,
	EXTRACT(year from sale_date) as year,
	SUM(s.total) as total_sale
from sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
on ci.city_id = c.city_id
group by 1,2,3
order by 1,3,2

),

Growth_ratio as
(
select
	city_name,
	month,
	year,
	total_sale as cr_month_sale,
	LAG(total_sale, 1) OVER(PARTITION BY city_name order by year, month) as last_month_sale
from monthly_sales	
)

select 
	city_name,
	month,
	year,
	cr_month_sale,
	last_month_sale,
	round(((cr_month_sale - last_month_sale)::numeric/last_month_sale)::numeric *100,2) as grownth_ratio
from 	Growth_ratio
where 
	last_month_sale IS NOT NULL


--Q10 Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer

with city_table as
(
SELECT 
	ci.city_name,
	COUNT(DISTINCT c.customer_name) as total_cux,
	SUM(total) as total_revenue,
	ROUND(SUM(s.total)::numeric / COUNT(DISTINCT c.customer_name)::numeric,2) as percity_average_sale
from sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
group by 1 	
order by 2 DESC
),

city_rent as 
(
Select 
	city_name, 
	estimated_rent,
	round((population *0.25)/1000000,2) as est_coffee_consumer
from city
)

select 
	cr.city_name,
	ct.total_revenue,
	cr.estimated_rent,
	ct.total_cux,
	cr.est_coffee_consumer,
	ct.percity_average_sale,
	round((cr.estimated_rent/ct.total_cux)::numeric,2) as avg_rent_per_customers
from city_rent as cr
JOIN city_table as ct
ON cr.city_name =ct.city_name
order by 2 DESC

/*
--Reccomendation
City1: Pune
	1. Average rent per customer is very less
	2. Highest total revenue
	3. Average sale per customer is also High
	
City2: Delhi 
	1. Highest estimated coffee consumer which is 7.7M
	2. Highest total customer which is 68
	3. Average rent per customer 330 (Still under 500)
	
City3: Jaipur
	1. Hihest number of customers
	2. Average rent per customer is very less
	3. Avearge sale per customer is decent


