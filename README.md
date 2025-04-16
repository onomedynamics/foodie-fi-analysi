# foodie-fi-analysi
This SQL project analyzes Foodie-Fi, a subscription-based streaming service for food enthusiasts. The analysis focuses on customer behavior, subscription trends, churn rates, and upgrade/downgrade patterns to provide actionable business insights.

##  Key Questions Explored:
Customer Base: Total customers and monthly trial sign-ups.

Churn Analysis: Percentage of customers who canceled subscriptions.

Plan Conversions: Post-trial subscription trends.

Upgrades & Downgrades: Customer movement between plans.

Annual Plan Adoption: Average time taken to upgrade to annual plans.

## content
📊 Database Schema
Tables:

subscriptions: Tracks customer subscriptions (customer_id, plan_id, start_date).

plans: Contains subscription plan details (plan_id, plan_name, price).

🔧 SQL Techniques Used
✔ Window Functions (ROW_NUMBER(), RANK())
✔ Common Table Expressions (CTEs) for complex queries
✔ Aggregations (COUNT, SUM, AVG)
✔ Date Functions (DATEDIFF, MONTHNAME)
✔ Conditional Logic (CASE WHEN)

🚀 Key Insights
Churn Rate: 30.7% of customers canceled subscriptions.

Post-Trial Behavior: 55% upgraded to paid plans after trials.

Annual Plans: Customers take an average of 104.6 days to upgrade.

Downgrades: 0 customers switched from Pro to Basic in 2020.

📥 How to Run
Execute the SQL script in a MySQL-compatible database.

Modify date filters (e.g., WHERE YEAR(start_date) = 2020) for different timeframes.
