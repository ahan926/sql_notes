# SQL Analytics & Database Practice Sets

A structured collection of advanced SQL queries, data transformations, and analytical practice problems covering window functions, CTEs, self-joins, subqueries, and performance optimization.

---

## 🛠 Tech Stack & Tools
* **Dialect:** Standard ANSI SQL (PostgreSQL / BigQuery compatible)
* **Topics Covered:** Aggregations, Joins, Window Functions, CTEs, Subqueries, Conditional Logic, Reshaping/Unpivoting
* **Version Control:** Git & GitHub

---

## 📁 Repository Structure

```text
sql-practice-sets/
│
├── README.md                          # Repository overview and topic breakdown
├── 01_window_functions.sql            # LAG, LEAD, ROW_NUMBER, DENSE_RANK, Running Totals
├── 02_null_handling_unpivot.sql       # COALESCE, NULLIF, UNION ALL unpivoting
├── 03_multi_cte_self_joins.sql        # Chained CTEs, Self-joins for org charts, CASE WHEN pivoting
└── 04_subqueries_exists.sql           # Scalar subqueries, EXISTS vs IN, Correlated subqueries