DROP TABLE info;

CREATE TABLE info
(
    product_name VARCHAR(100),
    product_id VARCHAR(11) PRIMARY KEY,
    description VARCHAR(700)
);

DROP TABLE finance;

CREATE TABLE finance
(
    product_id VARCHAR(11) PRIMARY KEY,
    listing_price FLOAT,
    sale_price FLOAT,
    discount FLOAT,
    revenue FLOAT
);

DROP TABLE reviews;

CREATE TABLE reviews
(
    product_id VARCHAR(11) PRIMARY KEY,
    rating FLOAT,
    reviews FLOAT
);

DROP TABLE traffic;

CREATE TABLE traffic
(
    product_id VARCHAR(11) PRIMARY KEY,
    last_visited TIMESTAMP
);

DROP TABLE brands;

CREATE TABLE brands
(
    product_id VARCHAR(11) PRIMARY KEY,
    brand VARCHAR(7)
);

\copy info FROM 'info_v2.csv' DELIMITER ',' CSV HEADER;
\copy finance FROM 'finance.csv' DELIMITER ',' CSV HEADER;
\copy reviews FROM 'reviews_v2.csv' DELIMITER ',' CSV HEADER;
\copy traffic FROM 'traffic_v3.csv' DELIMITER ',' CSV HEADER;
\copy brands FROM 'brands_v2.csv' DELIMITER ',' CSV HEADER;


-- Count all columns as total_rows
-- Count the number of non-missing entries for description, listing_price, and last_visited
-- Join info, finance, and traffic
SELECT COUNT(*) AS total_rows,
	COUNT(i.description) as count_description,
	COUNT(f.listing_price)as count_listing_price,
	COUNT( t.last_visited) as count_last_visited
FROM info AS i
INNER JOIN finance AS f
ON i.product_id = f.product_id
INNER JOIN traffic AS t
ON f.product_id = t.product_id;


-- Select the brand, listing_price as an integer, and a count of all products in finance 
-- Join brands to finance on product_id
-- Filter for products with a listing_price more than zero
-- Aggregate results by brand and listing_price, and sort the results by listing_price in descending order

SELECT b.brand, 
	f.listing_price :: integer,
	COUNT(f.*) 
FROM finance as f
INNER JOIN brands as b
ON b.product_id = f.product_id
WHERE listing_price > 0
GROUP BY b.brand, f.listing_price
ORDER BY listing_price desc;

-- Select the brand, a count of all products in the finance table, and total revenue
-- Create four labels for products based on their price range, aliasing as price_category
-- Join brands to finance on product_id and filter out products missing a value for brand
-- Group results by brand and price_category, sort by total_revenue
SELECT b.brand, 
	COUNT(*),
	SUM(revenue) AS total_revenue,
    CASE WHEN listing_price < 41 THEN 'Budget'
	WHEN listing_price >= 42 AND listing_price < 74 THEN 'Average'
	WHEN listing_price >= 74 AND listing_price  < 129 THEN 'Expensive'
	ELSE 'Elite' END AS price_category
    
FROM finance as f
left JOIN brands AS b
ON f.product_id = b.product_id
WHERE b.brand IS NOT NULL
GROUP BY b.brand, price_category
ORDER BY total_revenue desc;


-- Select brand and average_discount as a percentage
-- Join brands to finance on product_id
-- Aggregate by brand
-- Filter for products without missing values for brand


SELECT b.brand,
	AVG(f.discount) * 100 as average_discount
FROM finance as f
INNER JOIN brands as b
ON f.product_id = b.product_id
GROUP BY b.brand
HAVING b.brand is not NULL;


-- Calculate the correlation between reviews and revenue as review_revenue_corr
-- Join the reviews and finance tables on product_id

SELECT corr(r.reviews, f.revenue) AS review_revenue_corr
FROM finance as f
INNER JOIN reviews as r
ON r.product_id = f.product_id;


-- Calculate description_length
-- Convert rating to a numeric data type and calculate average_rating
-- Join info to reviews on product_id and group the results by description_length
-- Filter for products without missing values for description, and sort results by description_length

SELECT TRUNC(length(i.description), -2) as description_length,
	ROUND(AVG( r.rating::numeric), 2) as average_rating
FROM info as i
LEFT JOIN reviews as r
ON i.product_id = r.product_id
WHERE i.description IS NOT NULL
Group by description_length
Order by description_length;


-- Select brand, month from last_visited, and a count of all products in reviews aliased as num_reviews
-- Join traffic with reviews and brands on product_id
-- Group by brand and month, filtering out missing values for brand and month
-- Order the results by brand and month

Select b.brand,
	date_part('month', t.last_visited) as month,
	COUNT(*) as num_reviews
FROM traffic as t
LEFT JOIN reviews as r
    ON t.product_id = r.product_id
LEFT JOIN brands as b
    ON t.product_id = b.product_id
where b.brand IS NOT NULL
    AND date_part('month', t.last_visited) IS NOT NULL
GROUP BY b.brand, month
ORDER BY b.brand, month;


-- Create the footwear CTE, containing description and revenue
-- Filter footwear for products with a description containing %shoe%, %trainer, or %foot%
-- Also filter for products that are not missing values for description
-- Calculate the number of products and median revenue for footwear products

WITH footwear AS (
	SELECT i.description AS description,
		f.revenue AS revenue
	FROM info AS i
	INNER JOIN finance AS f
	ON i.product_id = f.product_id
	WHERE description ILIKE '%shoe%'
		OR description ILIKE '%trainer%'
		OR description ILIKE '%foot%'
AND description IS NOT NULL)

SELECT  COUNT(*) AS num_footwear_products,
	PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY revenue) AS median_footwear_revenue
FROM footwear;


-- Copy the footwear CTE from the previous task
-- Calculate the number of products in info and median revenue from finance
-- Inner join info with finance on product_id
-- Filter the selection for products with a description not in footwear

SELECT COUNT(*) as num_clothing_products,
	PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY f.revenue) as median_clothing_revenue
FROM info as i
INNER JOIN finance as f
ON i.product_id = f.product_id
WHERE i.description not in (
	SELECT i.description as description
	FROM info as i
	INNER JOIN finance as f
	ON i.product_id = f.product_id
	WHERE description ILIKE '%shoe%'
		OR description ILIKE '%trainer%'
		OR description ILIKE '%foot%'
AND description IS NOT NULL);
