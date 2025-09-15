use PortfolioProject;

select * 
from customer_orders;

-- standardize the order_status column

select order_status,
case
	when lower(order_status) like '%deliver%' then 'Deliver'
	when lower(order_status) like '%return%' then 'Returned'
	when lower(order_status) like '%refund%' then 'Refunded'
	when lower(order_status) like '%pend%' then 'Pending'
	when lower(order_status) like '%ship%' then 'Shipped'
else 'Other'
end as Cleaned_order_status
from customer_orders;

-- standardize the product_name column
select *,
case
	when lower(product_name) like '%apple watch%' then 'Apple Watch'
	when lower(product_name) like '%samsung galazy s22%' then 'Samsung Galaxy S22'
	when lower(product_name) like '%google pixel%' then 'Google Pixel'
	when lower(product_name) like '%macbook pro%' then 'Macbook Pro'
	when lower(product_name) like '%iphone 14%' then 'iPhone 14'
else 'Other'
end as Cleaned_product_name
from customer_orders;

 -- Clean quantity field
 select *,
case
	when lower(quantity) = 'two' then 2
else CAST(quantity as int)
end as Clean_quantity
from customer_orders;

 -- Customer_name field (chatgpt helped here) 
SELECT customer_name,
       (
         SELECT STRING_AGG(UPPER(LEFT(value, 1)) + LOWER(SUBSTRING(value, 2, LEN(value))), ' ')
         FROM STRING_SPLIT(customer_name, ' ')
       ) AS clean_customer_name
FROM customer_orders
WHERE customer_name IS NOT NULL;

-- Remove Duplicate orders
SELECT *
from (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY lower(email), lower(product_name)
               ORDER BY order_id
           ) AS rn
    from customer_orders
) as t
WHERE rn = 1;


-- Final Clean Data
WITH cleaned_data AS (
    SELECT
        order_id,

        -- Title-case full name
        STUFF((
            SELECT ' ' + UPPER(LEFT(s.value, 1)) + LOWER(SUBSTRING(s.value, 2, LEN(s.value)))
            FROM STRING_SPLIT(LTRIM(RTRIM(customer_name)), ' ') AS s
            FOR XML PATH(''), TYPE
        ).value('.', 'nvarchar(max)'), 1, 1, '') AS customer_name,

        email,

        -- Standardize order_status
        CASE
            WHEN LOWER(order_status) LIKE '%deliver%' THEN 'Deliver'
            WHEN LOWER(order_status) LIKE '%return%'  THEN 'Returned'
            WHEN LOWER(order_status) LIKE '%refund%'  THEN 'Refunded'
            WHEN LOWER(order_status) LIKE '%pend%'    THEN 'Pending'
            WHEN LOWER(order_status) LIKE '%ship%'    THEN 'Shipped'
            ELSE 'Other'
        END AS Cleaned_order_status,

        -- Standardize product_name
        CASE
            WHEN LOWER(product_name) LIKE '%apple watch%'        THEN 'Apple Watch'
            WHEN LOWER(product_name) LIKE '%samsung galaxy s22%' THEN 'Samsung Galaxy S22'
            WHEN LOWER(product_name) LIKE '%google pixel%'       THEN 'Google Pixel'
            WHEN LOWER(product_name) LIKE '%macbook pro%'        THEN 'Macbook Pro'
            WHEN LOWER(product_name) LIKE '%iphone 14%'          THEN 'iPhone 14'
            ELSE 'Other'
        END AS Cleaned_product_name,

        -- Clean quantity
        CASE
            WHEN LOWER(LTRIM(RTRIM(quantity))) = 'two' THEN 2
            ELSE TRY_CONVERT(int, quantity)
        END AS Clean_quantity,

        -- Standardize date (handles datetime/datetime2 first, then strings)
        COALESCE(
            TRY_CONVERT(date, order_date),                                         -- date/datetime/datetime2
            TRY_CONVERT(date, CONVERT(varchar(50), order_date), 23),               -- yyyy-mm-dd
            TRY_CONVERT(date, CONVERT(varchar(50), order_date), 120),              -- yyyy-mm-dd hh:mi:ss
            TRY_CONVERT(date, CONVERT(varchar(50), order_date), 110),              -- mm-dd-yy
            TRY_PARSE(CONVERT(varchar(50), order_date) AS date USING 'en-GB'),     -- dd/mm/yyyy
            TRY_PARSE(CONVERT(varchar(50), order_date) AS date USING 'en-US')      -- mm/dd/yyyy
        ) AS standardized_order_date

    FROM customer_orders
    WHERE customer_name IS NOT NULL
),
deduplicated_data AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY LOWER(email), LOWER(Cleaned_product_name)
               ORDER BY order_id
           ) AS rn
    FROM cleaned_data
)
SELECT *
FROM deduplicated_data
WHERE rn = 1;

