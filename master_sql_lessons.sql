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

-- ============================================================
-- SQL Master Practice Challenge #3
-- ============================================================

-- ------------------------------------------------------------
-- Problem 1: Aggregation & Multi-Condition Filtering
-- Scenario: A bank wants to identify high-value accounts that had frequent
-- large transfers during Q2 2026.
-- Table: wire_transfers (transfer_id, account_id, amount, transfer_date, status)
-- Task: Find all accounts that completed (status = 'Completed') at least 3
-- transfers between '2026-04-01' and '2026-06-30' whose total completed transfer
-- volume exceeds $50,000.
-- ------------------------------------------------------------

SELECT 
    account_id, 
    COUNT(transfer_id) AS transfer_count, 
    SUM(amount) AS total_volume
FROM wire_transfers
WHERE status = 'Completed'
  AND transfer_date >= '2026-04-01'
  AND transfer_date <= '2026-06-30'
GROUP BY account_id
HAVING COUNT(transfer_id) >= 3 
   AND SUM(amount) > 50000
ORDER BY total_volume DESC;


-- ------------------------------------------------------------
-- Problem 2: Outer Joins & Null Handling
-- Scenario: An e-learning platform wants a report on course enrollment revenue,
-- including courses with zero enrollments.
-- Tables: 
--   courses (course_id, course_name, price)
--   enrollments (enrollment_id, course_id, user_id, discount_applied)
-- Task: Calculate the total net revenue per course (price - discount_applied).
-- Display $0.00 for courses with no enrollments.
-- ------------------------------------------------------------

SELECT 
    c.course_id, 
    c.course_name, 
    c.price, 
    COALESCE(SUM(c.price - COALESCE(e.discount_applied, 0.00)), 0.00) AS total_revenue
FROM courses c
LEFT JOIN enrollments e
    ON c.course_id = e.course_id
GROUP BY c.course_id, c.course_name, c.price
ORDER BY total_revenue DESC, c.course_id ASC;


-- ------------------------------------------------------------
-- Problem 3: Window Functions & Cumulative Running Totals
-- Scenario: Finance wants to calculate a cumulative running total of daily
-- sales revenue for January 2026.
-- Table: daily_sales (sale_date, daily_revenue)
-- Task: Use SUM() OVER (...) to generate a running revenue total for each day.
-- ------------------------------------------------------------

SELECT 
    sale_date, 
    daily_revenue, 
    SUM(daily_revenue) OVER (ORDER BY sale_date ASC) AS running_total_revenue
FROM daily_sales
ORDER BY sale_date ASC;


-- ------------------------------------------------------------
-- Problem 4: Composite Index Design
-- Scenario: Create the optimal composite index for a table with 15M+ rows:
--
-- SELECT order_id, customer_id, order_total, created_at 
-- FROM orders 
-- WHERE store_id = 101 AND status = 'Shipped' AND created_at >= '2026-01-01' 
-- ORDER BY created_at DESC;
-- ------------------------------------------------------------

CREATE INDEX idx_orders_store_status_created
ON orders (store_id, status, created_at DESC);


-- ------------------------------------------------------------
-- Problem 5: Correlated Subqueries & Relative Thresholds
-- Scenario: HR wants to find employees earning > 15% above the average salary
-- for their specific job title.
-- Table: staff (emp_id, emp_name, job_title, salary)
-- Task: Use a correlated subquery linking inner/outer rows on job_title.
-- ------------------------------------------------------------

SELECT 
    s.emp_id, 
    s.emp_name, 
    s.job_title, 
    s.salary
FROM staff s
WHERE s.salary > (
    SELECT AVG(sub.salary) 
    FROM staff sub
    WHERE sub.job_title = s.job_title
) * 1.15
ORDER BY s.job_title ASC, s.salary DESC;


-- ------------------------------------------------------------
-- Problem 6: SARGable Date & String Optimization
-- Scenario: Refactor the non-SARGable query:
--
-- SELECT customer_id, email, last_login FROM customers 
-- WHERE UPPER(account_status) = 'ACTIVE' AND DATE(last_login) = '2026-05-15';
-- ------------------------------------------------------------

SELECT 
    customer_id, 
    email, 
    last_login
FROM customers
WHERE account_status = 'ACTIVE'
  AND last_login >= '2026-05-15 00:00:00'
  AND last_login <  '2026-05-16 00:00:00';

 -- ============================================================
-- SQL Master Practice Challenge #4 (Complete Reference)
-- ============================================================

-- ------------------------------------------------------------
-- Problem 1: Window Functions (Top 1 Per Group)
--
-- Scenario & Requirements:
-- Table: watch_history (user_id, movie_id, watch_time_minutes, watched_at)
-- Goal: Find the single most-watched movie per user based on total watch time.
-- Requirements:
--   1. Calculate total watch time per user and movie.
--   2. Rank movies per user using ROW_NUMBER() in descending order of watch time.
--   3. Break ties using the most recent watch timestamp (MAX(watched_at)).
--   4. Filter to keep only rank 1 per user.
--
-- Key Takeaways & Guidelines:
--   • ROW_NUMBER() guarantees exactly 1 row per partition (unlike RANK/DENSE_RANK).
--   • In the OVER() clause, evaluate aggregations directly: ORDER BY SUM(watch_time_minutes) DESC.
--   • Include explicit tie-breakers (e.g., MAX(watched_at) DESC) for deterministic output.
-- ------------------------------------------------------------

WITH RankedMovies AS (
    SELECT 
        user_id, 
        movie_id, 
        SUM(watch_time_minutes) AS total_watch_time,
        ROW_NUMBER() OVER (
            PARTITION BY user_id 
            ORDER BY SUM(watch_time_minutes) DESC, MAX(watched_at) DESC
        ) AS rn
    FROM watch_history
    GROUP BY user_id, movie_id
)
SELECT 
    user_id, 
    movie_id, 
    total_watch_time
FROM RankedMovies
WHERE rn = 1
ORDER BY user_id ASC;


-- ------------------------------------------------------------
-- Problem 2: Conditional Aggregation (Pivot Rows to Columns)
--
-- Scenario & Requirements:
-- Table: orders (customer_id, order_status, order_amount)
-- Goal: Executive revenue breakdown by order status per customer.
-- Requirements:
--   1. Aggregate revenue into 3 separate columns: completed_revenue, cancelled_revenue, returned_revenue.
--   2. Use CASE WHEN inside SUM() to pivot status categories into columns.
--   3. Wrap SUMs in COALESCE(..., 0.00) to avoid NULL values.
--   4. Filter to only show customers with at least 1 completed order (HAVING clause).
--
-- Key Takeaways & Guidelines:
--   • Conditional aggregation (SUM(CASE WHEN ...)) pivots rows into columns in a single pass over data.
--   • COALESCE(SUM(...), 0.00) converts NULL sums (where no matching rows exist) to 0.00.
--   • Filter aggregate results using HAVING (e.g., HAVING COUNT(CASE WHEN order_status = 'Completed' THEN 1 END) >= 1), not WHERE.
-- ------------------------------------------------------------

SELECT 
    customer_id, 
    COALESCE(SUM(CASE WHEN order_status = 'Completed' THEN order_amount ELSE 0 END), 0.00) AS completed_revenue,
    COALESCE(SUM(CASE WHEN order_status = 'Cancelled' THEN order_amount ELSE 0 END), 0.00) AS cancelled_revenue,
    COALESCE(SUM(CASE WHEN order_status = 'Returned'  THEN order_amount ELSE 0 END), 0.00) AS returned_revenue
FROM orders
GROUP BY customer_id
HAVING COUNT(CASE WHEN order_status = 'Completed' THEN 1 END) >= 1
ORDER BY completed_revenue DESC;


-- ------------------------------------------------------------
-- Problem 3: Multi-CTE Conversion Rate Pipeline
--
-- Scenario & Requirements:
-- Tables: signups (user_id, channel, signup_date), subscriptions (user_id, plan_type)
-- Goal: Conversion rate of 2026 signups to paid plans by acquisition channel.
-- Requirements:
--   1. CTE 1 (channel_signups): Count total signups per channel in 2026.
--   2. CTE 2 (channel_conversions): Count distinct users who converted to a paid plan (plan_type != 'Free') in 2026.
--   3. Main Query: Join CTEs on channel and calculate conversion_rate_pct = (conversions / total_signups) * 100.
--   4. Use COALESCE to handle channels with 0 conversions and ROUND to 2 decimal places.
--
-- Key Takeaways & Guidelines:
--   • Isolate signups vs. conversions into separate CTEs before joining to prevent fan-out / inflated counts.
--   • Use half-open date bounds (signup_date >= '2026-01-01' AND signup_date < '2027-01-01') to preserve SARGability.
--   • Use LEFT JOIN from base signups to conversions so 0-conversion channels remain included.
--   • Multiply by 100.0 (float) to enforce decimal division across different RDBMS platforms.
-- ------------------------------------------------------------

WITH channel_signups AS (
    SELECT 
        channel, 
        COUNT(user_id) AS total_signups
    FROM signups
    WHERE signup_date >= '2026-01-01' 
      AND signup_date <  '2027-01-01'
    GROUP BY channel
),
channel_conversions AS (
    SELECT 
        s.channel, 
        COUNT(DISTINCT sub.user_id) AS converted_users
    FROM signups s
    JOIN subscriptions sub 
        ON s.user_id = sub.user_id
    WHERE s.signup_date >= '2026-01-01' 
      AND s.signup_date <  '2027-01-01'
      AND sub.plan_type != 'Free'
    GROUP BY s.channel
)
SELECT 
    cs.channel, 
    cs.total_signups, 
    COALESCE(cc.converted_users, 0) AS converted_users, 
    ROUND((COALESCE(cc.converted_users, 0) * 100.0 / cs.total_signups), 2) AS conversion_rate_pct
FROM channel_signups cs
LEFT JOIN channel_conversions cc 
    ON cs.channel = cc.channel
ORDER BY conversion_rate_pct DESC;


-- ------------------------------------------------------------
-- Problem 4: Self-Joins & Hierarchical Data
--
-- Scenario & Requirements:
-- Table: employees (emp_id, emp_name, job_title, manager_id, salary)
-- Goal: Map employees to their direct managers using a self-join.
-- Requirements:
--   1. Self-join employees as e (employee) and m (manager) on e.manager_id = m.emp_id.
--   2. Use LEFT JOIN so top-level employees (without a manager) are not excluded.
--   3. Display emp_id, emp_name, job_title, manager_name (or 'No Manager'), and manager_salary.
--
-- Key Takeaways & Guidelines:
--   • Explicit table aliasing (`e` for employee, `m` for manager) is essential for self-joins.
--   • Join predicate must reflect relationship direction: `ON e.manager_id = m.emp_id`.
--   • Use `LEFT JOIN` + `COALESCE(m.emp_name, 'No Manager')` to safely preserve root records (CEOs/executives).
-- ------------------------------------------------------------

SELECT 
    e.emp_id, 
    e.emp_name, 
    e.job_title, 
    COALESCE(m.emp_name, 'No Manager') AS manager_name, 
    m.salary AS manager_salary
FROM employees e
LEFT JOIN employees m
    ON e.manager_id = m.emp_id
ORDER BY e.emp_id ASC;


-- ------------------------------------------------------------
-- Problem 5: Covering Index Design
--
-- Scenario & Requirements:
-- Target Query:
--   SELECT account_id, payment_method, SUM(amount)
--   FROM payments
--   WHERE payment_status = 'PROCESSED' AND payment_date >= '2026-01-01'
--   GROUP BY account_id, payment_method;
-- Goal: Create a composite index that covers all query columns to enable an Index-Only Scan.
-- Requirements:
--   1. Order index columns from Left to Right: Equality Filter -> Range Filter -> Group By Columns -> Aggregate Payload.
--
-- Key Takeaways & Guidelines:
--   • A covering index contains all columns requested by a query, avoiding costly heap/table lookup operations.
--   • Optimal Column Ordering Rules (Left-to-Right):
--       1. Equality Filters (`payment_status = ...`)
--       2. Range Filters (`payment_date >= ...`)
--       3. GROUP BY Columns (`account_id, payment_method`)
--       4. Included Aggregated Data (`amount`)
--   • Modern engines (PostgreSQL, SQL Server) also support `INCLUDE (amount)` to separate keys from payload data.
-- ------------------------------------------------------------

CREATE INDEX idx_payments_covering
ON payments (payment_status, payment_date, account_id, payment_method, amount);


-- ------------------------------------------------------------
-- Problem 6: SARGable Math Optimization
--
-- Scenario & Requirements:
-- Non-SARGable Query:
--   SELECT order_id, customer_id, order_subtotal
--   FROM orders
--   WHERE order_subtotal * 1.10 >= 550.00
--     AND status = 'COMPLETED';
-- Goal: Refactor the WHERE clause so that arithmetic operations are moved off the indexed column (order_subtotal), making the query SARGable.
--
-- Key Takeaways & Guidelines:
--   • SARGable = Search Argument Able. Keeping functions/arithmetic off column names allows B-Tree index range scans.
--   • Algebraic isolation: To undo `order_subtotal * 1.10 >= 550.00`, divide $550.00$ by $1.10$ ($550 / 1.10 = 500.00$).
--   • Avoid multiplying by decimals like $0.90$ ($550 \times 0.90 = 495$), which is mathematically unequal to dividing by $1.10$.
-- ------------------------------------------------------------

SELECT 
    order_id, 
    customer_id, 
    order_subtotal
FROM orders
WHERE order_subtotal >= 500.00
  AND status = 'COMPLETED';