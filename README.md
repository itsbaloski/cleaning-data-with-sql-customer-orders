# 🛒 Customer Orders Data Cleaning  

📑 **Table of Contents**  
- [📌 Project Overview](#project-overview)  
- [🛠️ Tools](#tools)  
- [🧹 Data Cleaning / Preparation](#data-cleaning--preparation)  
- [📊 Exploratory Data Analysis (EDA)](#exploratory-data-analysis-eda)  
- [🔎 Data Analysis](#data-analysis)  
- [📈 Results](#results)  
- [💡 Business Recommendations / Next Steps](#business-recommendations--next-steps)  
- [⚠️ Limitations](#limitations)  


---

## 📌 Project Overview  
This project focused on cleaning and preparing a **customer orders dataset** for analysis. The raw data included messy customer names, inconsistent product naming, unclear order statuses, duplicate records, and mixed date formats. Using SQL, the dataset was cleaned, standardized, and prepared for downstream analytics and visualization.  

The goal was to create a **single, reliable dataset** that can be used for reporting customer behavior, sales trends, and operational efficiency. The process ensured accurate product categorization, correct quantities, valid order dates, and deduplication of repeated entries.  

---

## 🛠️ Tools  
- **SQL Server** – Data cleaning and transformation  
- **CSV/Excel** – Raw data source  

---

## 🧹 Data Cleaning / Preparation  
- Standardized `order_status` values (e.g., Deliver, Returned, Refunded, Pending, Shipped).  
- Normalized `product_name` to unify entries (e.g., “samsung galazy s22” → “Samsung Galaxy S22”).  
- Cleaned `quantity` field (converted “two” → 2, casted valid integers).  
- Standardized `customer_name` into proper title case.  
- Converted multiple `order_date` formats into a consistent SQL date field.  
- Removed duplicate orders based on customer email and product.  

---

## 📊 Exploratory Data Analysis (EDA)  
- Distribution of **order statuses** after cleaning.  
- Top-selling products (e.g., iPhone 14, Samsung Galaxy S22, MacBook Pro).  
- Customer segmentation by email domains (potential for marketing insights).  
- Trends in **order dates** (daily, monthly, seasonal).  

---

## 🔎 Data Analysis  
Example SQL snippet used for final cleaning:  

```sql
WITH cleaned_data AS (
    SELECT
        order_id,
        -- Cleaned customer names
        STUFF((
            SELECT ' ' + UPPER(LEFT(s.value, 1)) + LOWER(SUBSTRING(s.value, 2, LEN(s.value)))
            FROM STRING_SPLIT(LTRIM(RTRIM(customer_name)), ' ') AS s
            FOR XML PATH(''), TYPE
        ).value('.', 'nvarchar(max)'), 1, 1, '') AS customer_name,

        email,

        -- Standardized order status
        CASE
            WHEN LOWER(order_status) LIKE '%deliver%' THEN 'Deliver'
            WHEN LOWER(order_status) LIKE '%return%'  THEN 'Returned'
            WHEN LOWER(order_status) LIKE '%refund%'  THEN 'Refunded'
            WHEN LOWER(order_status) LIKE '%pend%'    THEN 'Pending'
            WHEN LOWER(order_status) LIKE '%ship%'    THEN 'Shipped'
            ELSE 'Other'
        END AS Cleaned_order_status,

        -- Standardized product names
        CASE
            WHEN LOWER(product_name) LIKE '%apple watch%'        THEN 'Apple Watch'
            WHEN LOWER(product_name) LIKE '%samsung galaxy s22%' THEN 'Samsung Galaxy S22'
            WHEN LOWER(product_name) LIKE '%google pixel%'       THEN 'Google Pixel'
            WHEN LOWER(product_name) LIKE '%macbook pro%'        THEN 'Macbook Pro'
            WHEN LOWER(product_name) LIKE '%iphone 14%'          THEN 'iPhone 14'
            ELSE 'Other'
        END AS Cleaned_product_name,

        -- Cleaned quantity
        CASE
            WHEN LOWER(LTRIM(RTRIM(quantity))) = 'two' THEN 2
            ELSE TRY_CONVERT(int, quantity)
        END AS Clean_quantity,

        -- Standardized order dates
        COALESCE(
            TRY_CONVERT(date, order_date),
            TRY_PARSE(CONVERT(varchar(50), order_date) AS date USING 'en-GB'),
            TRY_PARSE(CONVERT(varchar(50), order_date) AS date USING 'en-US')
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
```
## 📈 Results  

- All `order_status` values standardized into 5 clear categories.  
- Product names cleaned and grouped into consistent categories.  
- Customer names formatted into proper case.  
- Invalid and duplicate records removed.  
- Mixed date formats successfully unified into SQL `date`.  
- Final dataset is clean, structured, and ready for **reporting dashboards**.  

---

## 💡 Business Recommendations / Next Steps  

- Use the cleaned dataset in Power BI or Tableau for sales insights.  
- Perform customer segmentation by purchase history and email domain.  
- Track monthly/seasonal sales trends to optimize stock and marketing.  
- Expand cleaning rules to include addresses, phone numbers, and payment details.  
- Automate the SQL pipeline for recurring data loads.  

---

## ⚠️ Limitations  

- Dataset only covers order details, no revenue or cost data for profitability analysis.  
- Product categories are limited to predefined keywords.  
- Date cleaning involved assumptions where invalid formats existed.  
- Results are limited to available columns; no external enrichment (e.g., demographics).  
