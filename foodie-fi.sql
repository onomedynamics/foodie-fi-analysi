USE foodie_fi;
-- How many customers has Foodie-Fi ever had?
SELECT count(customer_id) AS total_customers
FROM subscriptions;

-- ANS 2650 customers

-- 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
SELECT p.plan_name,COUNT(MONTHNAME(s.start_date)) AS month_year
FROM plans p JOIN
subscriptions s ON p.plan_id=s.plan_id
WHERE p.plan_id=0 AND p.price=0
GROUP BY p.plan_name
ORDER BY field(month_year , 'jan','feb','mar');
-- we have 1000 months for trial subscriptions


-- 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name.
SELECT p.plan_name,
count(*) AS subscriptions_after_2020
FROM plans p JOIN
subscriptions s ON 
p.plan_id=s.plan_id
WHERE s.start_date > '2020-12-31'
GROUP BY plan_name
ORDER BY subscriptions_after_2020 DESC;

-- 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

WITH latest_subscription AS (
  SELECT 
    customer_id,
    plan_id,
    RANK() OVER (PARTITION BY customer_id ORDER BY start_date DESC) AS rn
  FROM subscriptions
)

SELECT 
  COUNT(DISTINCT customer_id) AS total_customers,
  COUNT(CASE WHEN plan_id = 4 AND rn = 1 THEN customer_id END) AS churned_customers,
  ROUND(
    100.0 * COUNT(CASE WHEN plan_id = 4 AND rn = 1 THEN customer_id END) 
    / COUNT(DISTINCT customer_id),
    1
  ) AS churn_percentage
FROM latest_subscription
WHERE rn = 1;

-- 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
WITH trial_customers AS (
  SELECT customer_id, MIN(start_date) AS trial_start_date
  FROM subscriptions
  WHERE plan_id = 0
  GROUP BY customer_id
),
churned_customers AS (
  SELECT customer_id, MIN(start_date) AS churn_date
  FROM subscriptions
  WHERE plan_id = 4
  GROUP BY customer_id
)
SELECT COUNT(DISTINCT tc.customer_id) AS churned_customers,
       ROUND((COUNT(DISTINCT tc.customer_id) * 100.0 / (SELECT COUNT(DISTINCT customer_id) FROM trial_customers)), 0) AS churn_percentage
FROM trial_customers tc
JOIN churned_customers cc ON tc.customer_id = cc.customer_id
WHERE cc.churn_date > tc.trial_start_date;

-- 6. What is the number and percentage of customer plans after their initial free trial?
WITH trial_customers AS (
  SELECT customer_id, MIN(start_date) AS trial_start_date
  FROM subscriptions
  WHERE plan_id = 0
  GROUP BY customer_id
),
post_trial_plans AS (
  SELECT s.customer_id, s.plan_id, MIN(s.start_date) AS plan_start_date
  FROM subscriptions s
  JOIN trial_customers tc ON s.customer_id = tc.customer_id
  WHERE s.start_date > tc.trial_start_date
  GROUP BY s.customer_id, s.plan_id
)
SELECT p.plan_id, COUNT(DISTINCT p.customer_id) AS customer_count,
       ROUND((COUNT(DISTINCT p.customer_id) * 100.0 / (SELECT COUNT(DISTINCT customer_id) FROM trial_customers)), 0) AS percentage
FROM post_trial_plans p
GROUP BY p.plan_id
ORDER BY customer_count DESC;

-- What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
WITH latest_subs AS (
  SELECT customer_id, plan_id
  FROM (
    SELECT 
      customer_id,
      plan_id,
      start_date,
      ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY start_date DESC) AS rn
    FROM subscriptions
    WHERE start_date <= '2020-12-31'
  ) AS sub_ranked
  WHERE rn = 1
)

SELECT 
  p.plan_name,
  COUNT(*) AS customer_count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS percentage
FROM latest_subs ls
JOIN plans p ON ls.plan_id = p.plan_id
GROUP BY p.plan_name
ORDER BY customer_count DESC;

-- 8 How many customers have upgraded to an annual plan in 2020?
SELECT
 COUNT(DISTINCT customer_id) as 'annual customers'
 FROM subscriptions s JOIN plans p
 ON p.plan_id=s.plan_id
 WHERE p.plan_id=3 AND YEAR(start_date)>=2020
 
 ORDER BY p.plan_id;
 
 WITH plan_types AS (
  SELECT 
    plan_id,
    plan_name,
    CASE 
      WHEN LOWER(plan_name) LIKE '%annual%' THEN 'annual'
      ELSE 'non_annual'
    END AS plan_type
  FROM plans
),

subs_with_type AS (
  SELECT 
    s.customer_id,
    s.plan_id,
    p.plan_type,
    s.start_date
  FROM subscriptions s
  JOIN plan_types p ON s.plan_id = p.plan_id
  WHERE YEAR(s.start_date) = 2020
),

upgrades AS (
  SELECT 
    customer_id
  FROM subs_with_type
  GROUP BY customer_id
  HAVING 
    SUM(plan_type = 'annual') > 0 AND
    SUM(plan_type = 'non_annual') > 0
)

SELECT COUNT(*) AS customers_upgraded_to_annual_2020
FROM upgrades;

-- 9 How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
WITH annual_plans AS (
  SELECT plan_id
  FROM plans
  WHERE LOWER(plan_name) LIKE '%annual%'
),

first_join AS (
  SELECT customer_id, MIN(start_date) AS join_date
  FROM subscriptions
  GROUP BY customer_id
),

first_annual AS (
  SELECT customer_id, MIN(s.start_date) AS annual_date
  FROM subscriptions s
  JOIN annual_plans a ON s.plan_id = a.plan_id
  GROUP BY customer_id
),

join_to_annual AS (
  SELECT 
    f.customer_id,
    DATEDIFF(a.annual_date, f.join_date) AS days_to_annual
  FROM first_join f
  JOIN first_annual a ON f.customer_id = a.customer_id
)

SELECT 
  ROUND(AVG(days_to_annual), 1) AS avg_days_to_annual
FROM join_to_annual;

-- 10 Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
WITH annual_plans AS (
  SELECT plan_id
  FROM plans
  WHERE LOWER(plan_name) LIKE '%annual%'
),

first_join AS (
  SELECT customer_id, MIN(start_date) AS join_date
  FROM subscriptions
  GROUP BY customer_id
),

first_annual AS (
  SELECT customer_id, MIN(s.start_date) AS annual_date
  FROM subscriptions s
  JOIN annual_plans a ON s.plan_id = a.plan_id
  GROUP BY customer_id
),

join_to_annual AS (
  SELECT 
    f.customer_id,
    DATEDIFF(a.annual_date, f.join_date) AS days_to_annual
  FROM first_join f
  JOIN first_annual a ON f.customer_id = a.customer_id
)

SELECT 
  CASE 
    WHEN days_to_annual BETWEEN 0 AND 30 THEN '0-30 days'
    WHEN days_to_annual BETWEEN 31 AND 60 THEN '31-60 days'
    WHEN days_to_annual BETWEEN 61 AND 90 THEN '61-90 days'
    WHEN days_to_annual BETWEEN 91 AND 120 THEN '91-120 days'
    WHEN days_to_annual BETWEEN 121 AND 150 THEN '121-150 days'
    ELSE '150+ days'
  END AS time_bucket,
  COUNT(*) AS customer_count,
  ROUND(AVG(days_to_annual), 1) AS avg_days_in_bucket
FROM join_to_annual
GROUP BY time_bucket
ORDER BY MIN(days_to_annual);

-- 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
WITH plan_ids AS (
  SELECT 
    plan_id,
    plan_name
  FROM plans
  WHERE plan_name IN ('Pro Monthly', 'Basic Monthly')
),

subs_2020 AS (
  SELECT 
    s.customer_id,
    s.plan_id,
    s.start_date,
    p.plan_name
  FROM subscriptions s
  JOIN plan_ids p ON s.plan_id = p.plan_id
  WHERE YEAR(s.start_date) = 2020
),

ranked_subs AS (
  SELECT 
    customer_id,
    plan_name,
    start_date,
    ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY start_date) AS rn
  FROM subs_2020
),

downgrades AS (
  SELECT 
    s1.customer_id
  FROM ranked_subs s1
  JOIN ranked_subs s2 
    ON s1.customer_id = s2.customer_id
   AND s1.rn < s2.rn
  WHERE s1.plan_name = 'Pro Monthly'
    AND s2.plan_name = 'Basic Monthly'
)

SELECT COUNT(DISTINCT customer_id) AS customers_downgraded
FROM downgrades;

-- End of the project


