-- =====================================================================
-- PROJECT   : Bank Transactions & Account Holders
-- FILE      : 03_exploratory_data_analysis.sql
-- PURPOSE   : Basic exploration to understand the data before
--             answering business questions
-- PREPARED BY: Aishwarya Mate
-- =====================================================================

USE bank_transactions_db;

-- 1. Row counts in each table
SELECT COUNT(*) AS total_accounts FROM account_holders;
SELECT COUNT(*) AS total_transactions FROM bank_transactions;

-- 2. Preview a sample of each table
SELECT * FROM account_holders LIMIT 10;
SELECT * FROM bank_transactions LIMIT 10;

-- 3. Date range covered by the transactions
SELECT
    MIN(transaction_date) AS earliest_transaction,
    MAX(transaction_date) AS latest_transaction
FROM bank_transactions;

-- 4. Distinct values used to understand categorical columns
SELECT DISTINCT account_type FROM account_holders;
SELECT DISTINCT customer_segment FROM account_holders;
SELECT DISTINCT kyc_status FROM account_holders;
SELECT DISTINCT transaction_type FROM bank_transactions;
SELECT DISTINCT transaction_channel FROM bank_transactions;
SELECT DISTINCT transaction_status FROM bank_transactions;

-- 5. Check for missing / NULL values in key columns

SELECT * FROM account_holders;
SELECT * FROM account_holders WHERE customer_name IS NULL;
-----------------------------------------------------------
#EX:-

#CASE WHEN - CONDITIONAL
-- IT IS SAME AS if else condition 
-- it is crate a temp column in table

# AMT < 10000 : LOW
# AMT 10000 TO 50K : MEDIUM
# AMT > 50K : HIGH

SELECT transaction_id , account_id, amount,
CASE 
   WHEN amount < 10000 THEN 'LOW'
   WHEN amount BETWEEN 10000 AND 50000 THEN 'MEDIUM'
   ELSE 'HIGH'
   END AS Amt_Category
FROM bank_transactions;
------------------------------------------------------

SELECT customer_name,
CASE WHEN customer_name IS NULL THEN 1 ELSE 0 END FROM account_holders;   

SELECT
    SUM(CASE WHEN customer_name IS NULL THEN 1 ELSE 0 END) AS missing_name,   # WE DON'T HAVE ANY FUNCTION FOR MISSING VALUES SO DO IT MANUALLY
    SUM(CASE WHEN mobile_number IS NULL THEN 1 ELSE 0 END) AS missing_mobile,
    SUM(CASE WHEN branch_name IS NULL THEN 1 ELSE 0 END) AS missing_branch
FROM account_holders;

SELECT
    SUM(CASE WHEN amount IS NULL THEN 1 ELSE 0 END) AS missing_amount,
    SUM(CASE WHEN transaction_status IS NULL THEN 1 ELSE 0 END) AS missing_status
FROM bank_transactions;

SELECT * FROM bank_transactions;
SELECT * FROM bank_transactions WHERE merchant_category IS NULL;
SELECT * FROM bank_transactions WHERE merchant_category = '';

-- Note: merchant_category is expected to be blank/NULL for transactions
-- that are not UPI or POS spends (e.g. ATM withdrawals, NEFT transfers).
-- This is normal, not a data quality issue.

-- 6. Count of accounts per branch (helps confirm data spread realistically)
SELECT branch_name, COUNT(*) AS number_of_accounts
FROM account_holders
GROUP BY branch_name
ORDER BY number_of_accounts DESC;

SELECT ROUND(AVG(amount),3) FROM bank_transactions;

-- 7. Basic statistics on transaction amount
SELECT
    MIN(amount)                  AS min_amount,
    MAX(amount)                  AS max_amount,
    ROUND(AVG(amount), 2)        AS avg_amount   -- ROUND IS USED TO ROUNDUP THE VALUES EX: AVG- 245.45677 SO IT BECAME 245.45 
FROM bank_transactions
WHERE transaction_status = 'Success';

SELECT * FROM account_holders;

-- 8. Duplicate check on primary key columns (should always return 0 rows)
SELECT account_id, COUNT(*)
FROM account_holders
GROUP BY account_id
HAVING COUNT(*) > 1;

SELECT transaction_id, COUNT(*)
FROM bank_transactions
GROUP BY transaction_id
HAVING COUNT(*) > 1;
