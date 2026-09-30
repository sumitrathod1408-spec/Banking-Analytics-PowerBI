-- =====================================================================
-- PROJECT   : Bank Transactions & Account Holders
-- FILE      : 04_business_insights_queries.sql
-- PURPOSE   : Answer real banking business questions using SQL
--             (joins, aggregation, filtering, grouping, subqueries)
-- PREPARED BY: Aishwarya Mate
-- =====================================================================

USE bank_transactions_db;

-- =====================================================================
-- SECTION A: CUSTOMER BASE OVERVIEW
-- =====================================================================

-- Q1. How many accounts do we have by account type?
SELECT account_type, COUNT(*) AS total_accounts
FROM account_holders
GROUP BY account_type
ORDER BY total_accounts DESC;

-- Q2. How is our customer base split by segment (Retail/Premium/Corporate)?
SELECT customer_segment, COUNT(*) AS total_accounts,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM account_holders), 2) AS pct_of_customers
FROM account_holders
GROUP BY customer_segment
ORDER BY total_accounts DESC;

-- Q3. What is the average initial deposit by customer segment?
SELECT customer_segment,
       ROUND(AVG(initial_deposit), 2) AS avg_initial_deposit,
       ROUND(SUM(initial_deposit), 2) AS total_initial_deposit
FROM account_holders
GROUP BY customer_segment
ORDER BY avg_initial_deposit DESC;

-- Q4. How many accounts were opened each year? (growth trend)
SELECT YEAR(account_open_date) AS year_opened, COUNT(*) AS accounts_opened
FROM account_holders
GROUP BY YEAR(account_open_date)
ORDER BY year_opened;


SELECT MONTHNAME(account_open_date), count(*) FROM account_holders WHERE 
YEAR(account_open_date) = 2020 GROUP BY MONTHNAME(account_open_date);
#We do not have whole 2020 year data so canot be concluded as year with least account

SELECT MONTHNAME(account_open_date) AS year_opened, COUNT(*) AS accounts_opened
FROM account_holders
GROUP BY MONTHNAME(account_open_date)
ORDER BY year_opened;

-- Q5. How many customers still have KYC pending?
SELECT kyc_status, COUNT(*) AS total_accounts
FROM account_holders
GROUP BY kyc_status HAVING kyc_status = 'Pending';

#Additional customer details analysis
# understanding thecustomer segment based on their age category
ALTER TABLE account_holders ADD COLUMN Age INT;
SET SQL_SAFE_UPDATES = 0;
UPDATE account_holders SET Age = 2026 - YEAR(date_of_birth);

#Age <=25
ALTER TABLE account_holders ADD COLUMN Age_Category varchar(100);
UPDATE account_holders 
SET Age_Category =
CASE 
   WHEN Age <=25 THEN 'Young'
   WHEN Age <= 55 THEN 'Adult'
   ELSE 'Senior Citizen'
   END ;
   SELECT * FROM account_holders;
   
#COUNT FROE EACH CATEGORY
SELECT Age_Category, COUNT(*) FROM account_holders GROUP BY Age_Category;

#AVG FOR EACH CATEGORY
SELECT Age_Category, ROUND(AVG(initial_deposit),2) AVG_DIPOSIT FROM account_holders GROUP BY Age_Category 
ORDER BY AVG_DIPOSIT DESC ;


-- =====================================================================
-- SECTION B: TRANSACTION VOLUME & VALUE
-- =====================================================================

-- Q6. What is the total credit vs debit amount processed (successful only)?
SELECT transaction_type,
       COUNT(*) AS total_transactions,
       ROUND(SUM(amount), 2) AS total_amount,
       ROUND(AVG(amount),2 ) AS Average_Amt
FROM bank_transactions
WHERE transaction_status = 'Success'
GROUP BY transaction_type;

-- Q7. What does the monthly transaction trend look like?
SELECT DATE_FORMAT(CURDATE(),'%Y-%M');

SELECT DATE_FORMAT(transaction_date, '%Y-%M') AS transaction_month,
       COUNT(*) AS total_transactions,
       ROUND(SUM(amount), 2) AS total_amount
FROM bank_transactions
WHERE transaction_status = 'Success'
GROUP BY DATE_FORMAT(transaction_date, '%Y-%M')
ORDER BY transaction_month;

-- Q8. Which transaction channel is used the most?
SELECT transaction_channel,
       COUNT(*) AS total_transactions,
       ROUND(SUM(amount), 2) AS total_amount
FROM bank_transactions
WHERE transaction_status = 'Success'
GROUP BY transaction_channel
ORDER BY total_transactions DESC;

-- Q9. Where is customer spending concentrated? (merchant category, debit only)
SELECT merchant_category,
       COUNT(*) AS total_transactions,
       ROUND(SUM(amount), 2) AS total_spend
FROM bank_transactions
WHERE transaction_type = 'Debit'
  AND transaction_status = 'Success'
  AND merchant_category IS NOT NULL
  AND merchant_category <> ''
GROUP BY merchant_category
ORDER BY total_spend DESC;

-- Q10. Which branches process the highest transaction value?
SELECT branch_name,
       COUNT(*) AS total_transactions,
       ROUND(SUM(amount), 2) AS total_amount
FROM bank_transactions
WHERE transaction_status = 'Success'
GROUP BY branch_name
ORDER BY total_amount DESC;


-- =====================================================================
-- SECTION C: CUSTOMER-LEVEL INSIGHTS (JOINS)
-- =====================================================================

-- Q11. Who are our top 10 customers by total successful transaction value?
SELECT a.account_id, a.customer_name, a.customer_segment, a.branch_name,
       COUNT(t.transaction_id) AS total_transactions,
       ROUND(SUM(t.amount), 2) AS total_transaction_value
FROM account_holders a
JOIN bank_transactions t ON a.account_id = t.account_id
WHERE t.transaction_status = 'Success'
GROUP BY a.account_id, a.customer_name, a.customer_segment, a.branch_name
ORDER BY total_transaction_value DESC
LIMIT 10;

-- Q12. What is the average closing balance by customer segment?
SELECT a.customer_segment,
       ROUND(AVG(t.balance_after_transaction), 2) AS avg_balance
FROM account_holders a
JOIN bank_transactions t ON a.account_id = t.account_id
WHERE t.transaction_status = 'Success'
GROUP BY a.customer_segment
ORDER BY avg_balance DESC;

-- Q13. Which accounts have never transacted at all? (dormant / inactive accounts)
SELECT a.account_id, a.customer_name, a.account_type, a.branch_name, a.account_open_date,
t.transaction_id
FROM account_holders a
LEFT JOIN bank_transactions t ON a.account_id = t.account_id
WHERE t.transaction_id IS NULL;

-- Q14. Are there customers with KYC still pending who are actively
-- transacting? (a real compliance risk flag for the operations team)
SELECT a.account_id, a.customer_name, a.kyc_status,
       COUNT(t.transaction_id) AS total_transactions
FROM account_holders a
JOIN bank_transactions t ON a.account_id = t.account_id
WHERE a.kyc_status = 'Pending'
  AND t.transaction_status = 'Success'
GROUP BY a.account_id, a.customer_name, a.kyc_status
ORDER BY total_transactions DESC;

#Out of 111 customers with pending KYC , 109 aare completing transaction without fail
#this is a major risk compliance.


-- =====================================================================
-- SECTION D: RISK & OPERATIONAL QUALITY
-- =====================================================================

-- Q15. Which channels have the highest failure rate? (HAVING clause)

SELECT transaction_channel,
case WHEN transaction_status = 'Failed' THEN 1 ELSE 0 end from bank_transactions;

SELECT transaction_channel,
       COUNT(*) AS total_transactions,
       SUM(CASE WHEN transaction_status = 'Failed' THEN 1 ELSE 0 END) AS failed_transactions,
       ROUND(SUM(CASE WHEN transaction_status = 'Failed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS failure_rate_pct
FROM bank_transactions
GROUP BY transaction_channel
HAVING failed_transactions > 0
ORDER BY failure_rate_pct DESC;

-- Q16. Flag high-value transactions for manual review (above ₹1,00,000)
SELECT transaction_id, account_id, transaction_date, transaction_type,
       transaction_channel, amount, transaction_status
FROM bank_transactions
WHERE amount > 100000
ORDER BY amount DESC;

-- Q17. Segment every successful transaction into a simple value band
-- (CASE WHEN used to bucket amounts into readable categories)

select * from bank_transactions;

select amount,
CASE 
	WHEN amount < 1000 THEN 'Low'
    WHEN amount BETWEEN 1001 AND 10000 THEN 'Medium'
    ELSE 'Large'
    END AS Amount_Category 
From bank_transactions;

SELECT *,
    CASE
        WHEN amount < 1000 THEN 'Small (< 1,000)'
        WHEN amount BETWEEN 1000 AND 10000 THEN 'Medium (1,000 - 10,000)'
        WHEN amount BETWEEN 10001 AND 50000 THEN 'Large (10,001 - 50,000)'
        ELSE 'Very Large (> 50,000)'
    END AS transaction_value_band 
FROM bank_transactions;

SELECT
    CASE
        WHEN amount < 1000 THEN 'Small (< 1,000)'
        WHEN amount BETWEEN 1000 AND 10000 THEN 'Medium (1,000 - 10,000)'
        WHEN amount BETWEEN 10001 AND 50000 THEN 'Large (10,001 - 50,000)'
        ELSE 'Very Large (> 50,000)'
    END AS transaction_value_band,
    COUNT(*) AS total_transactions,
    ROUND(SUM(amount), 2) AS total_amount
FROM bank_transactions
WHERE transaction_status = 'Success'
GROUP BY transaction_value_band
ORDER BY total_amount DESC;


-- =====================================================================
-- SECTION E: REUSABLE VIEW FOR REPORTING / BI TOOLS
-- =====================================================================

-- Q18. Create a view that joins both tables into one clean, reusable
-- dataset - handy for quick reporting or connecting to Excel/Power BI
CREATE OR REPLACE VIEW customer_transaction_summary AS
SELECT
    a.account_id,
    a.customer_name,
    a.city,
    a.state,
    a.account_type,
    a.customer_segment,
    a.branch_name,
    a.kyc_status,
    t.transaction_id,
    t.transaction_date,
    t.transaction_type,
    t.transaction_channel,
    t.merchant_category,
    t.amount,
    t.transaction_status,
    t.balance_after_transaction
FROM account_holders a
JOIN bank_transactions t ON a.account_id = t.account_id;

-- Example usage of the view: total successful spend per city
SELECT city,
       ROUND(SUM(amount), 2) AS total_amount
FROM customer_transaction_summary
WHERE transaction_status = 'Success'
GROUP BY city
ORDER BY total_amount DESC;
