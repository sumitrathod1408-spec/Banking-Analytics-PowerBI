-- =====================================================================
-- PROJECT   : Bank Transactions & Account Holders
-- FILE      : 01_database_and_tables.sql
-- PURPOSE   : Create the project database and the two core tables
-- PREPARED BY: Aishwarya Mate
-- =====================================================================

-- STEP 1: Create a fresh database for this project
DROP DATABASE IF EXISTS bank_transactions_db;
CREATE DATABASE bank_transactions_db;
USE bank_transactions_db;

-- ---------------------------------------------------------------------
-- STEP 2: Table 1 - account_holders
-- Stores one row per bank customer / account
-- ---------------------------------------------------------------------
CREATE TABLE account_holders (
    account_id          VARCHAR(15)     PRIMARY KEY,
    customer_name       VARCHAR(100)    NOT NULL,
    gender               VARCHAR(10),
    date_of_birth        DATE,
    mobile_number         VARCHAR(15),
    email                 VARCHAR(100),
    city                  VARCHAR(50),
    state                 VARCHAR(50),
    account_type          VARCHAR(20),     -- Savings / Current / Salary
    customer_segment      VARCHAR(20),     -- Retail / Premium / Corporate
    branch_name           VARCHAR(50),
    ifsc_code             VARCHAR(15),
    account_open_date     DATE,
    initial_deposit       DECIMAL(12,2),
    kyc_status            VARCHAR(15)      -- Verified / Pending
);

-- ---------------------------------------------------------------------
-- STEP 3: Table 2 - bank_transactions
-- Stores one row per transaction, linked to account_holders
-- ---------------------------------------------------------------------
CREATE TABLE bank_transactions (
    transaction_id             VARCHAR(15)   PRIMARY KEY,
    account_id                 VARCHAR(15)   NOT NULL,
    transaction_date           DATETIME,
    transaction_type           VARCHAR(10),   -- Credit / Debit
    transaction_channel        VARCHAR(20),   -- UPI / ATM / POS / NEFT / IMPS / Net Banking / Branch Deposit / Cheque Deposit / Salary Credit
    amount                     DECIMAL(12,2),
    merchant_category          VARCHAR(30),   -- populated only for UPI / POS debit spends
    transaction_status         VARCHAR(15),   -- Success / Failed / Pending
    balance_after_transaction  DECIMAL(12,2),
    branch_name                VARCHAR(50),
    description                VARCHAR(150),
    CONSTRAINT fk_account
        FOREIGN KEY (account_id) REFERENCES account_holders(account_id)
);

-- ---------------------------------------------------------------------
-- STEP 4: Helpful indexes for faster analysis queries
-- (primary keys are indexed automatically; these support the joins,
--  filters and date-range queries used in the analysis scripts)
-- ---------------------------------------------------------------------
CREATE INDEX idx_txn_account_id   ON bank_transactions(account_id);
CREATE INDEX idx_txn_date         ON bank_transactions(transaction_date);
CREATE INDEX idx_txn_status       ON bank_transactions(transaction_status);
CREATE INDEX idx_acc_segment      ON account_holders(customer_segment);
CREATE INDEX idx_acc_branch       ON account_holders(branch_name);

-- Quick check after creation
SHOW TABLES;
DESCRIBE account_holders;
DESCRIBE bank_transactions;
