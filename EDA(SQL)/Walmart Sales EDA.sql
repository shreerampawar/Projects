USE walle;

CREATE TABLE sales (
    invoice_id VARCHAR(30) NOT NULL PRIMARY KEY,
    branch VARCHAR(5) NOT NULL,
    city VARCHAR(30) NOT NULL,
    customer_type VARCHAR(30) NOT NULL,
    gender VARCHAR(30) NOT NULL,
    product_line VARCHAR(100) NOT NULL,
    unit_price DECIMAL(10 , 2 ) NOT NULL,
    quantity INT NOT NULL,
    tax_pct FLOAT(6 , 4 ) NOT NULL,
    total DECIMAL(12 , 4 ) NOT NULL,
    date DATETIME NOT NULL,
    time TIME NOT NULL,
    payment VARCHAR(15) NOT NULL,
    cogs DECIMAL(10 , 2 ) NOT NULL,
    gross_margin_pct FLOAT(11 , 9 ),
    gross_income DECIMAL(12 , 4 ),
    rating FLOAT(2 , 1 )
);

-- ## // Feature Engineering // ## --

SELECT 
    time,
    (CASE
        WHEN `time` BETWEEN '00:00:00' AND '12:00:00' THEN 'Morning'
        WHEN `time` BETWEEN '12:01:00' AND '16:00:00' THEN 'Afternoon'
        ELSE 'Evening'
    END) AS time_of_date
FROM
    sales;

ALTER TABLE sales
ADD COLUMN time_of_day VARCHAR(20);

UPDATE sales 
SET 
    time_of_day = (CASE
        WHEN `time` BETWEEN '00:00:00' AND '12:00:00' THEN 'Morning'
        WHEN `time` BETWEEN '12:00:01' AND '16:00:00' THEN 'Afternoon'
        ELSE 'Evening'
    END);

SELECT 
    date, DAYNAME(date) AS day_name
FROM
    sales;

ALTER TABLE sales
ADD COLUMN day_name VARCHAR(10);

UPDATE sales 
SET 
    day_name = DAYNAME(date);

SELECT 
    date, MONTHNAME(date)
FROM
    sales;

ALTER TABLE sales
ADD COLUMN month_name VARCHAR(20);

UPDATE sales 
SET 
    month_name = MONTHNAME(date);

---------------------------------------------------------

-- ## // EDA // ## --

-- Generic Ques -------------------------------///////////////////////

# How many unique cities does the data have?
SELECT DISTINCT
    city
FROM
    sales;

# How many unique branches does the data have?

SELECT DISTINCT
    branch
FROM
    sales;

# In which city is each branch?

SELECT DISTINCT
    city, branch
FROM
    sales;

-- Product Ques -----------------------------------/////////////

# How many unique product lines does the data have?

SELECT DISTINCT
    product_line
FROM
    sales;
SELECT 
    COUNT(DISTINCT product_line)
FROM
    sales;

# What payment mode is preferred?

SELECT 
    payment, COUNT(payment) AS cnt
FROM
    sales
GROUP BY payment
ORDER BY cnt DESC;

# What is the most selling product line?

SELECT 
    product_line, COUNT(product_line) AS pd_cnt
FROM
    sales
GROUP BY product_line
ORDER BY pd_cnt DESC;

# What is the total revenue by month?

SELECT 
    month_name AS month, SUM(total) AS total_revenue
FROM
    sales
GROUP BY month_name
ORDER BY total_revenue DESC;

# What month had the largest COGS?

SELECT 
    month_name AS month, SUM(cogs) AS cogs
FROM
    sales
GROUP BY month_name
ORDER BY cogs DESC;

# What product line had the largest revenue?

SELECT 
    product_line, SUM(total) AS total_revenue
FROM
    sales
GROUP BY product_line
ORDER BY total_revenue DESC;

# What is the city with the largest revenue?

SELECT 
    branch, city, SUM(total) AS total_revenue
FROM
    sales
GROUP BY branch , city
ORDER BY total_revenue DESC;

# What product line had the largest tax_pct?

SELECT 
    product_line, AVG(tax_pct) AS avg_tax
FROM
    sales
GROUP BY product_line
ORDER BY avg_tax DESC;

# Which branch sold more products than average product sold?

SELECT 
    branch, SUM(quantity) AS qty
FROM
    sales
GROUP BY branch
HAVING SUM(quantity) > (SELECT 
        AVG(quantity)
    FROM
        sales);

# What is the most common product line by gender

SELECT 
    gender, product_line, COUNT(gender) AS cnt
FROM
    sales
GROUP BY gender , product_line
ORDER BY cnt DESC;

# What is the average rating of each product line?

SELECT 
    product_line, ROUND(AVG(rating), 2) AS avg_rating
FROM
    sales
GROUP BY product_line
ORDER BY avg_rating DESC;

# Which product line has quantity more than 5 highest number of times?

SELECT 
    product_line, COUNT(quantity) AS count
FROM
    sales
WHERE
    quantity > 5
GROUP BY product_line;

-- Customers Ques --------------------------------/////////////////////

## How many unique customer types does the data have?
SELECT DISTINCT
    customer_type
FROM
    sales;

## How many unique payment methods does the data have?
SELECT DISTINCT
    payment
FROM
    sales;
    
## What is the most common customer type?
SELECT 
    customer_type, COUNT(*) AS total_count
FROM
    sales
GROUP BY customer_type
ORDER BY total_count DESC;

# Which customer type buys the most?
SELECT customer_type, product_line, COUNT(*) AS count
FROM sales
GROUP BY customer_type, product_line
ORDER BY SUM(count) OVER (PARTITION BY customer_type) DESC,
         customer_type,
         count DESC;

## What is the gender of most of the customers?
SELECT DISTINCT
    gender, COUNT(*) AS count
FROM
    sales
GROUP BY gender;

## What is the gender distribution per branch?
SELECT 
    branch, gender, COUNT(branch) AS cnt_per_branch
FROM
    sales
GROUP BY branch , gender
ORDER BY branch , cnt_per_branch DESC , gender DESC;

## Which time of the day do customers give most ratings?
SELECT 
    time_of_day, AVG(rating) AS avg_rating
FROM
    sales
GROUP BY time_of_day
ORDER BY avg_rating DESC;

## Which time of the day do customers give most ratings per branch?
SELECT 
    branch, time_of_day, AVG(rating) AS avg_rating
FROM
    sales
GROUP BY branch , time_of_day
ORDER BY branch , avg_rating DESC;

## Which day fo the week has the best avg ratings?
SELECT 
    day_name, AVG(rating) AS avg_rating
FROM
    sales
GROUP BY day_name
ORDER BY avg_rating DESC;

## Which day of the week has the best average ratings per branch?
SELECT 
    branch, day_name, AVG(rating) AS avg_rating
FROM
    sales
GROUP BY branch , day_name
ORDER BY branch , avg_rating DESC;

-- Sales Ques -----------------------------//////////////////

## Number of sales made in each time of the day per weekday
SELECT DISTINCT
    (day_name), COUNT(*) AS total_sales
FROM
    sales
GROUP BY day_name
ORDER BY total_sales DESC;

## Which of the customer types brings the most revenue?
SELECT 
    time_of_day, COUNT(*) AS total_sales
FROM
    sales
GROUP BY time_of_day
ORDER BY total_sales DESC;

# Number of sales made in each time of the day per weekday by the day with max sales

SELECT day_name, time_of_day, COUNT(*) AS total_sales
FROM sales
GROUP BY day_name, time_of_day
ORDER BY SUM(total_sales) OVER (PARTITION BY day_name) DESC,
         day_name,
         total_sales DESC;
         
## Which of the customer types brings the most revenue?
SELECT 
    customer_type, SUM(total) AS total_revenue
FROM
    sales
GROUP BY customer_type
ORDER BY total_revenue DESC;

## Which city has the largest tax percent?
SELECT 
    city, AVG(tax_pct) AS tax_pct
FROM
    sales
GROUP BY city
ORDER BY tax_pct DESC;

## Which customer type pays the most in tax?
SELECT 
    customer_type, SUM(tax_pct) AS tax_pct
FROM
    sales
GROUP BY customer_type
ORDER BY tax_pct DESC;