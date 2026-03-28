CREATE DATABASE b2c_churn_analysis;
USE b2c_churn_analysis;

-- Customers with low usage and churned (high-risk pattern)
SELECT 
c.customer_id,
c.subscription_plan,
c.status,
AVG(u.feature_usage_score) AS avg_usage,
AVG(u.watch_time_hours) AS avg_watch_time
FROM customers c
JOIN usage_data u
ON c.customer_id = u.customer_id
GROUP BY c.customer_id, c.subscription_plan, c.status
HAVING avg_usage < 500
ORDER BY avg_usage ASC;

-- Churn rate by subscription plan
SELECT 
subscription_plan,
COUNT(*) AS total_customers,
SUM(CASE WHEN status = 'Churned' THEN 1 ELSE 0 END) AS churned_customers,
ROUND(
SUM(CASE WHEN status = 'Churned' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),2
) AS churn_rate
FROM customers
GROUP BY subscription_plan
ORDER BY churn_rate DESC;

-- Compare engagement between Active vs Churned users
SELECT 
c.status,
AVG(u.feature_usage_score) AS avg_feature_usage,
AVG(u.watch_time_hours) AS avg_watch_time
FROM customers c
JOIN usage_data u
ON c.customer_id = u.customer_id
GROUP BY c.status;

-- NPS score vs churn
SELECT 
f.nps_score,
c.status,
COUNT(*) AS total_customers
FROM customers c
LEFT JOIN feedback f
ON c.customer_id = f.customer_id
GROUP BY f.nps_score, c.status
ORDER BY f.nps_score;

-- Basic LTV calculation
SELECT 
ROUND(
    SUM(IFNULL(p.amount,0)) / COUNT(DISTINCT c.customer_id),
2) AS avg_ltv
FROM customers c
LEFT JOIN payments p
ON c.customer_id = p.customer_id;

-- LTV using successful payments
SELECT 
ROUND(
    SUM(
        CASE 
            WHEN p.payment_status = 'Success' THEN p.amount 
            ELSE 0 
        END
    ) / COUNT(DISTINCT c.customer_id),
2) AS avg_ltv
FROM customers c
LEFT JOIN payments p
ON c.customer_id = p.customer_id;

-- LTV by subscription plan
SELECT 
c.subscription_plan,
ROUND(
    SUM(
        CASE 
            WHEN p.payment_status = 'Success' THEN p.amount 
            ELSE 0 
        END
    ) / COUNT(DISTINCT c.customer_id),
2) AS avg_ltv
FROM customers c
LEFT JOIN payments p
ON c.customer_id = p.customer_id
GROUP BY c.subscription_plan
ORDER BY avg_ltv DESC;

-- Total customers
SELECT COUNT(*) AS total_customers
FROM customers;

-- Active vs churned customers
SELECT status, COUNT(customer_id) AS total
FROM customers
GROUP BY status;

-- Churned customers by subscription plan
SELECT 
subscription_plan,
COUNT(customer_id) AS churned_customers
FROM customers
WHERE status = 'Churned'
GROUP BY subscription_plan
ORDER BY churned_customers DESC;

-- Sum of feature usage score by status
SELECT 
c.status,
SUM(u.feature_usage_score) AS total_feature_usage_score
FROM customers c
JOIN usage_data u
ON c.customer_id = u.customer_id
GROUP BY c.status;

-- Average of retention percentage by month number
SELECT 
month_number,
ROUND(AVG(retention_percentage),2) AS avg_retention_percentage
FROM (
    SELECT 
    TIMESTAMPDIFF(
        MONTH,
        c.signup_date,
        STR_TO_DATE(CONCAT(u.month,'-01'),'%Y-%m-%d')
    ) AS month_number,

    COUNT(DISTINCT c.customer_id) * 100.0 / cs.total_customers AS retention_percentage

    FROM customers c
    JOIN usage_data u
        ON c.customer_id = u.customer_id

    JOIN (
        SELECT 
        DATE_FORMAT(signup_date,'%Y-%m') AS cohort_month,
        COUNT(*) AS total_customers
        FROM customers
        GROUP BY DATE_FORMAT(signup_date,'%Y-%m')
    ) cs
    ON DATE_FORMAT(c.signup_date,'%Y-%m') = cs.cohort_month

    GROUP BY 
    DATE_FORMAT(c.signup_date,'%Y-%m'),
    TIMESTAMPDIFF(
        MONTH,
        c.signup_date,
        STR_TO_DATE(CONCAT(u.month,'-01'),'%Y-%m-%d')
    ),
    cs.total_customers

) retention_data

GROUP BY month_number
ORDER BY month_number;

-- Average of feature usage score by status
SELECT 
c.status,
AVG(u.feature_usage_score) AS avg_feature_usage_score
FROM customers c
JOIN usage_data u
ON c.customer_id = u.customer_id
GROUP BY c.status;

-- Average of watch time hours by status
SELECT 
c.status,
AVG(u.watch_time_hours) AS avg_watch_time_hours
FROM customers c
JOIN usage_data u
ON c.customer_id = u.customer_id
GROUP BY c.status;

-- Count of customer id by device type and status
SELECT 
device_type,
status,
COUNT(customer_id) AS total_customers
FROM customers
GROUP BY device_type, status
ORDER BY device_type;

-- Average of feature usage score by subscription plan
SELECT 
c.subscription_plan,
AVG(u.feature_usage_score) AS avg_feature_usage_score
FROM customers c
JOIN usage_data u
ON c.customer_id = u.customer_id
GROUP BY c.subscription_plan
ORDER BY avg_feature_usage_score DESC;

-- Sum of feature usage score and sum of watch hours by status
SELECT 
c.status,
SUM(u.feature_usage_score) AS total_feature_usage_score,
SUM(u.watch_time_hours) AS total_watch_time_hours
FROM customers c
JOIN usage_data u
ON c.customer_id = u.customer_id
GROUP BY c.status;

-- Churn by age group
SELECT 
age_group,
COUNT(*) AS total_users,
SUM(CASE WHEN status = 'Churned' THEN 1 ELSE 0 END) AS churned_users,
ROUND(
(SUM(CASE WHEN status = 'Churned' THEN 1 ELSE 0 END) * 100) / COUNT(*), 
2
) AS churn_rate
FROM customers
GROUP BY age_group
ORDER BY churn_rate DESC;

-- Monthly signups
SELECT 
DATE_FORMAT(signup_date,'%Y-%m') AS signup_month,
COUNT(*) AS new_customers
FROM customers
GROUP BY signup_month
ORDER BY signup_month;

-- Churn by device type
SELECT 
device_type,
COUNT(*) AS total_users,
SUM(CASE WHEN status='Churned' THEN 1 ELSE 0 END) AS churned_users
FROM customers
GROUP BY device_type;

-- Usage behaviour analysis
SELECT 
c.status,
AVG(u.logins) AS avg_logins
FROM customers c
JOIN usage_data u
ON c.customer_id = u.customer_id
GROUP BY c.status;

-- Watch time comparison
SELECT 
c.status,
AVG(u.watch_time_hours) AS avg_watch_time
FROM customers c
JOIN usage_data u
ON c.customer_id = u.customer_id
GROUP BY c.status;

-- Revenue analysis
SELECT SUM(amount) AS total_revenue
FROM payments
WHERE payment_status = 'Paid';

/*Calculate churn rate percentage*/
SELECT 
ROUND(SUM(CASE WHEN status = 'Churned' THEN 1 ELSE 0 END) *100.0
/ COUNT(*),2) AS churn_rate_percentage
FROM customers;	


SELECT 	
    subscription_plan,
    ROUND(SUM(CASE WHEN status = 'Churned' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),2) AS churn_rate
FROM customers
GROUP BY subscription_plan
ORDER BY churn_rate DESC;
-- MRR
SELECT 
    SUM(monthly_fee) AS MRR
FROM customers
WHERE status = 'Active';

-- ARR
SELECT 
    SUM(monthly_fee) * 12 AS ARR
FROM customers
WHERE status = 'Active';

-- Revenue lost due to churn
SELECT 
    SUM(monthly_fee) AS revenue_lost
FROM customers
WHERE status = 'Churned';

-- Payment failure impact on churn
SELECT 
    c.status,
    COUNT(p.payment_id) AS failed_payments
FROM customers c
JOIN payments p ON c.customer_id = p.customer_id
WHERE p.payment_status = 'Failed'
GROUP BY c.status;

-- Low engagement vs churn
SELECT 
    c.status,
    AVG(u.feature_usage_score) AS avg_usage_score
FROM customers c
JOIN usage_data u ON c.customer_id = u.customer_id
GROUP BY c.status;

-- Average usage score by status
SELECT 
    c.status,
    ROUND(AVG(u.feature_usage_score),2) AS avg_usage_score,
    ROUND(AVG(u.logins),2) AS avg_logins
FROM customers c
JOIN usage_data u ON c.customer_id = u.customer_id
GROUP BY c.status;

-- NPS impact on churn
SELECT 
    c.status,
    ROUND(AVG(f.nps_score),2) AS avg_nps
FROM customers c
JOIN feedback f ON c.customer_id = f.customer_id
GROUP BY c.status;

-- High risk identification
SELECT 
    c.customer_id,
    c.subscription_plan,
    c.billing_cycle,
    AVG(u.feature_usage_score) AS avg_usage,
    SUM(CASE WHEN p.payment_status = 'Failed' THEN 1 ELSE 0 END) AS failed_payments,
    f.nps_score,
    
    
    CASE 
        WHEN AVG(u.feature_usage_score) < 50 
             OR SUM(CASE WHEN p.payment_status = 'Failed' THEN 1 ELSE 0 END) > 0
             OR f.nps_score < 6
        THEN 'High Risk'
        ELSE 'Low Risk'
    END AS churn_risk_flag

FROM customers c
JOIN usage_data u ON c.customer_id = u.customer_id
JOIN payments p ON c.customer_id = p.customer_id
JOIN feedback f ON c.customer_id = f.customer_id

GROUP BY 
    c.customer_id,
    c.subscription_plan,
    c.billing_cycle,
    f.nps_score;
    
    -- Country wise revenue
    SELECT 
    country,
    SUM(monthly_fee) AS total_revenue
FROM customers
WHERE status = 'Active'
GROUP BY country
ORDER BY total_revenue DESC;

-- Create signup cohort
SELECT 
    customer_id,
    DATE_FORMAT(signup_date, '%Y-%m') AS cohort_month
FROM customers;

-- Calculate active months difference
SELECT 
    c.customer_id,
    DATE_FORMAT(c.signup_date, '%Y-%m') AS cohort_month,
    u.month AS activity_month,
    TIMESTAMPDIFF(
        MONTH,
        c.signup_date,
        STR_TO_DATE(CONCAT(u.month, '-01'), '%Y-%m-%d')
    ) AS month_number
FROM customers c
JOIN usage_data u 
    ON c.customer_id = u.customer_id;

-- Count active users per cohort per month
SELECT 
    DATE_FORMAT(c.signup_date, '%Y-%m') AS cohort_month,
    TIMESTAMPDIFF(
        MONTH,
        c.signup_date,
        STR_TO_DATE(CONCAT(u.month, '-01'), '%Y-%m-%d')
    ) AS month_number,
    COUNT(DISTINCT c.customer_id) AS active_users
FROM customers c
JOIN usage_data u 
    ON c.customer_id = u.customer_id
GROUP BY cohort_month, month_number
ORDER BY cohort_month, month_number;

-- Calculate retention %
SELECT 
    DATE_FORMAT(c.signup_date, '%Y-%m') AS cohort_month,

    TIMESTAMPDIFF(
        MONTH,
        c.signup_date,
        STR_TO_DATE(CONCAT(u.month, '-01'), '%Y-%m-%d')
    ) AS month_number,

    COUNT(DISTINCT c.customer_id) AS active_users,

    cs.total_customers,

    ROUND(
        COUNT(DISTINCT c.customer_id) / cs.total_customers * 100,
        2
    ) AS retention_percentage

FROM customers c

JOIN usage_data u 
    ON c.customer_id = u.customer_id

JOIN (
    SELECT 
        DATE_FORMAT(signup_date, '%Y-%m') AS cohort_month,
        COUNT(*) AS total_customers
    FROM customers
    GROUP BY DATE_FORMAT(signup_date, '%Y-%m')
) cs
    ON DATE_FORMAT(c.signup_date, '%Y-%m') = cs.cohort_month

GROUP BY 
    DATE_FORMAT(c.signup_date, '%Y-%m'),
    month_number,
    cs.total_customers

ORDER BY 
    cohort_month,
    month_number;
    
-- Calculate ARPU
SELECT 
    ROUND(AVG(monthly_fee), 2) AS arpu
FROM customers;

SELECT 
    ROUND(
        SUM(CASE WHEN status = 'Churned' THEN 1 ELSE 0 END) 
        / COUNT(*),
    4) AS churn_rate
FROM customers;

SELECT 
    ROUND(
        (SELECT AVG(monthly_fee) FROM customers) /
        (SELECT 
            SUM(CASE WHEN status = 'Churned' THEN 1 ELSE 0 END) 
            / COUNT(*) 
         FROM customers),
    2) AS estimated_ltv;
    
    -- Actual revenue based
    SELECT 
    c.customer_id,
    ROUND(SUM(p.amount), 2) AS total_revenue_generated
FROM customers c
JOIN payments p 
    ON c.customer_id = p.customer_id
WHERE p.payment_status = 'Success'
GROUP BY c.customer_id;

-- Average LTV
SELECT 
    ROUND(AVG(total_revenue), 2) AS avg_ltv
FROM (
    SELECT 
        c.customer_id,
        SUM(p.amount) AS total_revenue
    FROM customers c
    JOIN payments p 
        ON c.customer_id = p.customer_id
    WHERE p.payment_status = 'Success'
    GROUP BY c.customer_id
) t;

-- LTV by plan
SELECT 
    t.subscription_plan,
    ROUND(AVG(t.customer_ltv), 2) AS avg_ltv
FROM (
    SELECT 
        c.customer_id,
        c.subscription_plan,
        SUM(p.amount) AS customer_ltv
    FROM customers c
    JOIN payments p 
        ON c.customer_id = p.customer_id
    WHERE p.payment_status = 'Success'
    GROUP BY c.customer_id, c.subscription_plan
) AS t
GROUP BY t.subscription_plan
ORDER BY avg_ltv DESC;