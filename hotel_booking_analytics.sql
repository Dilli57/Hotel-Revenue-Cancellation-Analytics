CREATE DATABASE hotel_analytics;

USE hotel_analytics;

CREATE TABLE hotel_bookings (

    hotel VARCHAR(50),
    is_canceled INT,
    lead_time INT,

    arrival_date_year INT,
    arrival_date_month VARCHAR(20),
    arrival_date_week_number INT,
    arrival_date_day_of_month INT,

    stays_in_weekend_nights INT,
    stays_in_week_nights INT,

    adults INT,
    children FLOAT,
    babies INT,

    meal VARCHAR(50),
    country VARCHAR(20),

    market_segment VARCHAR(50),
    distribution_channel VARCHAR(50),

    is_repeated_guest INT,

    previous_cancellations INT,
    previous_bookings_not_canceled INT,

    reserved_room_type VARCHAR(10),
    assigned_room_type VARCHAR(10),

    booking_changes INT,

    deposit_type VARCHAR(50),

    days_in_waiting_list INT,

    customer_type VARCHAR(50),

    adr FLOAT,

    required_car_parking_spaces INT,

    total_of_special_requests INT,

    reservation_status VARCHAR(50),

    reservation_status_date DATE,

    total_guests FLOAT,

    total_nights INT,

    total_revenue FLOAT,

    reservation_month INT

);



SET GLOBAL local_infile = 1;

SHOW GLOBAL VARIABLES LIKE 'local_infile';

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/final_hotel_analytics_dataset.csv'
INTO TABLE hotel_bookings
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

select * from hotel_bookings 
limit 10;

select count(*) from hotel_bookings;

-- 1. Which hotels and customer segments generate the highest revenue? 

SELECT 
hotel,

ROUND(SUM(total_revenue), 2) AS total_revenue,

ROUND(AVG(total_revenue), 2) AS avg_booking_revenue

FROM hotel_bookings

GROUP BY hotel

ORDER BY total_revenue DESC;

-- 2. Which factors contribute most to booking cancellations?

SELECT deposit_type,
COUNT(*) AS total_bookings,
SUM(is_canceled) AS cancellations,
ROUND(SUM(is_canceled) * 100 / COUNT(*),2) AS cancellation_rate
FROM hotel_bookings
GROUP BY deposit_type
ORDER BY cancellation_rate DESC;

--  3.Do customers who book earlier cancel more?

SELECT is_canceled,
ROUND(AVG(lead_time), 2) AS avg_lead_time
FROM hotel_bookings
GROUP BY is_canceled;

-- 4. Which months are peak booking seasons?

SELECT arrival_date_month,
COUNT(*) AS bookings,
ROUND(SUM(total_revenue), 2) AS revenue
FROM hotel_bookings
GROUP BY arrival_date_month
ORDER BY bookings DESC;

-- 5. Which customer types are most valuable?

SELECT 
customer_type,

COUNT(*) AS bookings,

ROUND(AVG(total_revenue), 2) AS avg_revenue,

ROUND(AVG(total_nights), 2) AS avg_stay

FROM hotel_bookings

GROUP BY customer_type;

-- 6. Which countries generate maximum hotel revenue?

SELECT 
country,

ROUND(SUM(total_revenue), 2) AS revenue,

COUNT(*) AS bookings

FROM hotel_bookings

GROUP BY country

ORDER BY revenue DESC

LIMIT 10;

-- 7. Do repeat guests generate higher revenue?

SELECT 
is_repeated_guest,

COUNT(*) AS total_bookings,

ROUND(AVG(total_revenue), 2) AS avg_revenue

FROM hotel_bookings

GROUP BY is_repeated_guest;

-- 8. Which booking channels are most profitable?

SELECT 
market_segment,

ROUND(SUM(total_revenue), 2) AS revenue,

COUNT(*) AS bookings

FROM hotel_bookings

GROUP BY market_segment

ORDER BY revenue DESC;

-- 9. Which room types are assigned most frequently?

SELECT 
assigned_room_type,

COUNT(*) AS total_bookings,

ROUND(SUM(total_revenue), 2) AS revenue

FROM hotel_bookings

GROUP BY assigned_room_type

ORDER BY revenue DESC;

-- 10. Do customers with more special requests spend more?

SELECT 
total_of_special_requests,

ROUND(AVG(total_revenue), 2) AS avg_revenue,

COUNT(*) AS bookings

FROM hotel_bookings

GROUP BY total_of_special_requests

ORDER BY total_of_special_requests;

-- 11. Revenue Ranking by Country Using Window Functions

SELECT 
country,

ROUND(SUM(total_revenue), 2) AS revenue,

RANK() OVER(
    ORDER BY SUM(total_revenue) DESC
) AS revenue_rank

FROM hotel_bookings

GROUP BY country;

-- 12. Running Revenue Trend
-- Business Problem
-- Track cumulative hotel growth over time.

SELECT
    reservation_status_date,
    daily_revenue,

    SUM(daily_revenue) OVER (
        ORDER BY reservation_status_date
    ) AS running_revenue

FROM (

    SELECT
        reservation_status_date,

        ROUND(SUM(total_revenue), 2) AS daily_revenue

    FROM hotel_bookings

    GROUP BY reservation_status_date

) AS revenue_data;

-- 13. Top High-Value Bookings Using CTE + RANK()

WITH revenue_rank AS (
    SELECT 
    hotel,
    customer_type,
    total_revenue,
    RANK() OVER(
        ORDER BY total_revenue DESC
    ) AS revenue_rank

    FROM hotel_bookings
)
SELECT *
FROM revenue_rank
WHERE revenue_rank <= 10;

-- 14. Revenue Contribution %

SELECT hotel,
ROUND(SUM(total_revenue), 2) AS revenue,
ROUND(SUM(total_revenue) * 100 /SUM(SUM(total_revenue)) OVER(),2) AS revenue_percentage
FROM hotel_bookings
GROUP BY hotel;

-- 15. Monthly Revenue Growth %

WITH monthly_revenue AS (

    SELECT

        arrival_date_year,
        arrival_date_month,

        ROUND(SUM(total_revenue),2) AS revenue

    FROM hotel_bookings

    GROUP BY
        arrival_date_year,
        arrival_date_month
)

SELECT *,

ROUND(

    (
        revenue -

        LAG(revenue) OVER(
            ORDER BY arrival_date_year
        )

    )

    /

    LAG(revenue) OVER(
        ORDER BY arrival_date_year
    ) * 100,

2) AS monthly_growth_percent

FROM monthly_revenue;

-- 16. Dense Rank Revenue by Country

SELECT

    country,

    ROUND(SUM(total_revenue),2) AS revenue,

    DENSE_RANK() OVER(
        ORDER BY SUM(total_revenue) DESC
    ) AS dense_rank_revenue

FROM hotel_bookings

GROUP BY country;

-- 17. Top Revenue Customers per Hotel

SELECT *

FROM (

    SELECT

        hotel,
        customer_type,
        total_revenue,

        RANK() OVER(

            PARTITION BY hotel

            ORDER BY total_revenue DESC

        ) AS hotel_rank

    FROM hotel_bookings

) ranked_data

WHERE hotel_rank <= 5;

-- 19. Stored Procedure: Top Revenue Generating Countries

-- Business Problem:
-- Hotel management wants a reusable automated report
-- to identify the top revenue-generating countries
-- and understand which regions contribute most to bookings
-- and overall hotel revenue.
DROP PROCEDURE IF EXISTS top_countries;

DELIMITER //

CREATE PROCEDURE top_countries()

BEGIN

    SELECT

        country,

        ROUND(SUM(total_revenue),2) AS revenue,

        COUNT(*) AS bookings

    FROM hotel_bookings

    GROUP BY country

    ORDER BY revenue DESC

    LIMIT 10;

END //

DELIMITER ;

-- Execute Procedure

CALL top_countries();

-- 20. Customer Revenue Segmentation Using CASE Statement

-- Business Problem:
-- Hotel management wants to categorize customers
-- based on their revenue contribution to identify
-- high-value customers, improve personalized marketing,
-- and optimize customer retention strategies.

SELECT

CASE

    WHEN total_revenue > 500 THEN 'High Value'

    WHEN total_revenue BETWEEN 200 AND 500 THEN 'Medium Value'

    ELSE 'Low Value'

END AS customer_segment,

COUNT(*) AS customers

FROM hotel_bookings

GROUP BY customer_segment;

