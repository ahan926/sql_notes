/*
===============================================================================
                    SQL ANALYTICS MASTERCLASS: LESSONS 1-18
===============================================================================
Table of Contents:
  - Lessons 01-04: Basic Filtering, Aggregations & Joins
  - Lessons 05-08: Intermediate Grouping, String & Date Functions
  - Lessons 09-12: Advanced Joins, CASE Logic & Aggregations
  - Lessons 13-14: CTE Foundations & Subqueries
  - Lessons 15-18: Advanced Analytics (Window Functions, Pivoting, Correlated Subqueries)
===============================================================================
*/


-- ============================================================================
-- LESSON 01: BASIC SELECT, FILTERING & ORDERING
-- Concept: Selecting specific attributes, filtering with WHERE, and sorting.
-- ============================================================================
SELECT 
    employee_id, 
    emp_name, 
    department, 
    salary
FROM employees
WHERE salary > 75000 AND status = 'Active'
ORDER BY salary DESC;


-- ============================================================================
-- LESSON 02: AGGREGATION & GROUP BY
-- Concept: Summarizing row data using COUNT, SUM, AVG with GROUP BY.
-- ============================================================================
SELECT 
    department,
    COUNT(employee_id) AS total_employees,
    ROUND(AVG(salary), 2) AS avg_salary
FROM employees
GROUP BY department
ORDER BY avg_salary DESC;


-- ============================================================================
-- LESSON 03: HAVING CLAUSE (FILTERING AGGREGATES)
-- Concept: WHERE filters rows before aggregation; HAVING filters groups after.
-- ============================================================================
SELECT 
    department,
    COUNT(employee_id) AS total_employees,
    SUM(salary) AS total_payroll
FROM employees
GROUP BY department
HAVING COUNT(employee_id) >= 5
ORDER BY total_payroll DESC;


-- ============================================================================
-- LESSON 04: INNER JOIN (COMBINING TABLES)
-- Concept: Matching rows across tables using primary/foreign key relationships.
-- ============================================================================
SELECT 
    o.order_id,
    c.customer_name,
    c.email,
    o.order_date,
    o.order_amount
FROM orders o
INNER JOIN customers c
    ON o.customer_id = c.customer_id
ORDER BY o.order_date DESC;


-- ============================================================================
-- LESSON 05: LEFT JOIN & MISSING DATA IDENTIFICATION
-- Concept: Preserving all records from the left table regardless of matches.
-- ============================================================================
SELECT 
    c.customer_id,
    c.customer_name,
    o.order_id,
    o.order_amount
FROM customers c
LEFT JOIN orders o
    ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL
ORDER BY c.customer_id ASC;


-- ============================================================================
-- LESSON 06: STRING MANIPULATION & CONCATENATION
-- Concept: Cleaning and combining text strings.
-- ============================================================================
SELECT 
    customer_id,
    UPPER(CONCAT(first_name, ' ', last_name)) AS full_name_uppercase,
    LOWER(email) AS normalized_email
FROM customers
ORDER BY full_name_uppercase ASC;


-- ============================================================================
-- LESSON 07: DATE EXTRACTION & PARSING
-- Concept: Extracting temporal components (YEAR, MONTH) for time-series analysis.
-- ============================================================================
SELECT 
    EXTRACT(YEAR FROM order_date) AS sales_year,
    EXTRACT(MONTH FROM order_date) AS sales_month,
    COUNT(order_id) AS total_orders,
    SUM(order_amount) AS monthly_revenue
FROM orders
GROUP BY EXTRACT(YEAR FROM order_date), EXTRACT(MONTH FROM order_date)
ORDER BY sales_year DESC, sales_month DESC;


-- ============================================================================
-- LESSON 08: BASIC CASE WHEN LOGIC
-- Concept: Creating conditional attributes based on value thresholds.
-- ============================================================================
SELECT 
    order_id,
    order_amount,
    CASE 
        WHEN order_amount >= 500 THEN 'High Value'
        WHEN order_amount >= 150 THEN 'Mid Value'
        ELSE 'Low Value'
    END AS order_tier
FROM orders
ORDER BY order_amount DESC;


-- ============================================================================
-- LESSON 09: MULTI-TABLE JOINS
-- Concept: Chaining multiple joins to consolidate relational data across entities.
-- ============================================================================
SELECT 
    o.order_id,
    c.customer_name,
    p.product_name,
    oi.quantity,
    oi.unit_price
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
ORDER BY o.order_id ASC;


-- ============================================================================
-- LESSON 10: UNION ALL VS UNION
-- Concept: Combining result sets vertically (UNION drops duplicates, UNION ALL keeps them).
-- ============================================================================
SELECT customer_id, email, 'US_Region' AS source_table FROM us_customers
UNION ALL
SELECT customer_id, email, 'EU_Region' AS source_table FROM eu_customers
ORDER BY customer_id ASC;


-- ============================================================================
-- LESSON 11: BASIC SUBQUERIES IN WHERE
-- Concept: Filtering rows based on the result of another query.
-- ============================================================================
SELECT 
    product_id,
    product_name,
    unit_price
FROM products
WHERE unit_price > (SELECT AVG(unit_price) FROM products)
ORDER BY unit_price DESC;


-- ============================================================================
-- LESSON 12: AGGREGATE COMPUTATION WITH DISTINCT
-- Concept: Removing duplicate rows prior to performing count operations.
-- ============================================================================
SELECT 
    department_id,
    COUNT(DISTINCT employee_id) AS total_employees,
    COUNT(DISTINCT project_id) AS total_projects
FROM project_assignments
GROUP BY department_id;


-- ============================================================================
-- LESSON 13: SINGLE COMMON TABLE EXPRESSIONS (CTEs)
-- Concept: Simplifying complex queries with named temporal result sets using WITH.
-- ============================================================================
WITH HighSpendingCustomers AS (
    SELECT 
        customer_id,
        SUM(order_amount) AS total_spent
    FROM orders
    GROUP BY customer_id
    HAVING SUM(order_amount) > 1000
)
SELECT 
    c.customer_id,
    c.customer_name,
    h.total_spent
FROM HighSpendingCustomers h
JOIN customers c ON h.customer_id = c.customer_id
ORDER BY h.total_spent DESC;


-- ============================================================================
-- LESSON 14: DENSE_RANK VS ROW_NUMBER
-- Concept: Partitioning and ranking data when handling potential tied ranks.
-- ============================================================================
SELECT 
    department_id,
    employee_id,
    salary,
    ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY salary DESC) AS row_num,
    DENSE_RANK() OVER (PARTITION BY department_id ORDER BY salary DESC) AS dense_rnk
FROM employees
ORDER BY department_id ASC, salary DESC;


-- ============================================================================
-- LESSON 15: WINDOW FUNCTIONS & ANALYTICAL RANKING
-- Concept: RUNNING TOTALS, LAG(), NULLIF(), and top-N filtering with CTEs.
-- ============================================================================

-- 15.1: Running Total
SELECT 
    order_date,
    daily_revenue,
    SUM(daily_revenue) OVER (ORDER BY order_date ASC) AS running_total_revenue
FROM daily_sales;

-- 15.2: Month-over-Month Growth
SELECT 
    sales_month,
    monthly_revenue,
    LAG(monthly_revenue, 1) OVER (ORDER BY sales_month ASC) AS prev_month_revenue,
    COALESCE(
        ROUND(
            (monthly_revenue - LAG(monthly_revenue, 1) OVER (ORDER BY sales_month ASC)) * 100.0 / 
            NULLIF(LAG(monthly_revenue, 1) OVER (ORDER BY sales_month ASC), 0), 
            2
        ), 
        0
    ) AS mom_growth_pct
FROM monthly_sales;

-- 15.3: Top 2 Sales Reps Per Region
WITH RankedSales AS (
    SELECT 
        region,
        rep_id,
        rep_name,
        total_sales,
        ROW_NUMBER() OVER (PARTITION BY region ORDER BY total_sales DESC) AS sales_rank
    FROM sales_reps
)
SELECT region, rep_id, rep_name, total_sales
FROM RankedSales
WHERE sales_rank <= 2;


-- ============================================================================
-- LESSON 16: NULL HANDLING & DATA RESHAPING (UNPIVOTING)
-- Concept: Safe division with NULLIF/COALESCE and unpivoting wide survey data.
-- ============================================================================

-- 16.1: Safe Division & Conversion Rates
SELECT 
    campaign_id,
    campaign_name,
    clicks,
    conversions,
    COALESCE(ROUND((conversions * 100.0 / NULLIF(clicks, 0)), 2), 0) AS conversion_rate
FROM ad_campaigns;

-- 16.2: Unpivoting Columns into Rows
SELECT survey_id, customer_id, 'Product' AS feedback_category, product_rating AS rating
FROM customer_surveys WHERE product_rating IS NOT NULL
UNION ALL
SELECT survey_id, customer_id, 'Service' AS feedback_category, service_rating AS rating
FROM customer_surveys WHERE service_rating IS NOT NULL
UNION ALL
SELECT survey_id, customer_id, 'Delivery' AS feedback_category, delivery_rating AS rating
FROM customer_surveys WHERE delivery_rating IS NOT NULL
ORDER BY survey_id ASC, feedback_category ASC;


-- ============================================================================
-- LESSON 17: SELF-JOINS, MULTI-STAGE CTES & CONDITIONAL AGGREGATION
-- Concept: Hierarchical self-joins, conversion funnels, and CASE WHEN pivoting.
-- ============================================================================

-- 17.1: Employee-Manager Organizational Hierarchy (Self-Join)
SELECT 
    e.employee_id, 
    e.emp_name, 
    e.job_title, 
    COALESCE(m.emp_name, 'Top Level') AS manager_name,
    COALESCE(m.job_title, 'Top Level') AS manager_title
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.employee_id
ORDER BY e.employee_id ASC;

-- 17.2: Multi-Stage Sales Funnel Analysis (Chained CTEs)
WITH TotalSignups AS (
    SELECT COUNT(DISTINCT user_id) AS total_signups FROM users
),
ActiveUsers AS (
    SELECT COUNT(DISTINCT user_id) AS active_users FROM activity_logs
),
PayingUsers AS (
    SELECT COUNT(DISTINCT user_id) AS paying_users FROM subscriptions
)
SELECT 
    s.total_signups,
    a.active_users,
    p.paying_users,
    ROUND((p.paying_users * 100.0 / s.total_signups), 2) AS paying_conversion_rate
FROM TotalSignups s
CROSS JOIN ActiveUsers a
CROSS JOIN PayingUsers p;

-- 17.3: Conditional Pivot Aggregation (CASE WHEN)
SELECT 
    EXTRACT(YEAR FROM order_date) AS order_year,
    SUM(CASE WHEN region = 'US' THEN COALESCE(order_amount, 0) ELSE 0 END) AS us_revenue,
    SUM(CASE WHEN region = 'EU' THEN COALESCE(order_amount, 0) ELSE 0 END) AS eu_revenue,
    SUM(CASE WHEN region = 'ASIA' THEN COALESCE(order_amount, 0) ELSE 0 END) AS asia_revenue
FROM orders
GROUP BY EXTRACT(YEAR FROM order_date)
ORDER BY order_year ASC;


-- ============================================================================
-- LESSON 18: SCALAR SUBQUERIES, EXISTS VS. IN & CORRELATED SUBQUERIES
-- Concept: Inline benchmarks, membership tests, and dynamic row-by-row filtering.
-- ============================================================================

-- 18.1: Above-Average Customer Orders (Scalar Subquery)
SELECT 
    order_id, 
    customer_id, 
    order_date, 
    order_amount
FROM orders
WHERE order_amount > (SELECT AVG(order_amount) FROM orders)
ORDER BY order_amount DESC;

-- 18.2: Active Customers in 2026 (WHERE EXISTS)
SELECT 
    c.customer_id, 
    c.customer_name, 
    c.email
FROM customers c
WHERE EXISTS (
    SELECT 1 
    FROM orders o 
    WHERE o.customer_id = c.customer_id
      AND EXTRACT(YEAR FROM o.order_date) = 2026
      AND o.status = 'Completed'
)
ORDER BY c.customer_id ASC;

-- 18.3: Most Recent Order Per Customer (Correlated Subquery)
SELECT 
    co.customer_id, 
    co.order_id, 
    co.order_date, 
    co.total_amount
FROM customer_orders co
WHERE co.order_date = (
    SELECT MAX(sub.order_date)
    FROM customer_orders sub
    WHERE sub.customer_id = co.customer_id
)
ORDER BY co.customer_id ASC;

-- ============================================================
-- PRACTICE SET 19: EXECUTION ORDER, INDEXING & SARGABILITY
-- ============================================================

-- Problem 1: Logical Execution Order & Aggregations
SELECT 
    account_id, 
    SUM(amount) AS total_completed_amount
FROM transactions
WHERE status = 'Completed'
  AND EXTRACT(YEAR FROM transaction_date) = 2026
GROUP BY account_id
HAVING SUM(amount) > 10000
ORDER BY total_completed_amount DESC;

-- Problem 2: Optimal Composite Index DDL
CREATE INDEX idx_users_status_region_created
ON users (account_status, region, created_at DESC);

-- Problem 3: SARGable Refactoring
SELECT COUNT(log_id) AS event_count
FROM logs
WHERE log_timestamp >= '2026-08-01 00:00:00'
  AND log_timestamp <  '2026-08-02 00:00:00';