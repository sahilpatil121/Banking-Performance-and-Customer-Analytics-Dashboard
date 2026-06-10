
---------------------------------------------------------------------------------------------------------------------
--SQL QUESTIONS

-- 1 What is the monthly transaction volume and value trends.

SELECT DATE_TRUNC('month',transaction_date )::DATE AS months,
	COUNT(transaction_id) AS transaction_volume,
	SUM(amount) AS transaction_value
FROM v_transactions
where transaction_date IS NOT NULL
GROUP BY months
ORDER BY months;


--2 Calculate top customers by total transaction amount, transaction frequency, and average transaction value.

SELECT c.customer_id,
CONCAT(c.first_name,' ',c.last_name) AS full_name,
	SUM(t.amount) AS total_transaction,
	COUNT(t.transaction_id) AS transaction_frequwncy,
	ROUND(AVG(t.amount),2) AS avg_transaction_value
FROM customers c
JOIN  accounts a ON c.customer_id=a.customer_id
JOIN transactions t ON a.account_id=t.account_origin_id
GROUP BY c.customer_id,full_name
ORDER BY total_transaction desc;


-- 3 Which accounts have the highest net cash inflow?

WITH money_recieved AS(SELECT account_destination_id AS account_id,
		SUM(amount) AS total_recieved
		FROM transactions
		GROUP BY account_id),		
money_send AS (SELECT account_origin_id AS account_id,
	SUM(amount) AS total_send
	FROM transactions
	GROUP BY account_id)	
SELECT c.customer_id,concat(c.first_name,' ',last_name) AS full_name,
a.account_id,mr.total_recieved,ms.total_send,
	mr.total_recieved-ms.total_send AS net_cash_flow
	FROM accounts a
	JOIN customers c ON
	a.customer_id=c.customer_id
	LEFT JOIN money_recieved mr ON
	a.account_id=mr.account_id
	LEFT JOIN money_send ms ON
	a.account_id=ms.account_id
	ORDER BY net_cash_flow DESC
	limit 10;


-- 4 Identify customers with no transactions in the last 90 days.

WITH last_transactions AS(SELECT a.customer_id,
		MAX(transaction_date)::date AS last_transaction
		From v_accounts a
		JOIN v_transactions t On a.account_id=t.account_origin_id
		WHERE transaction_date IS NOT NULL
		GROUP BY a.customer_id)
SELECT c.customer_id,concat(c.first_name,' ',last_name) AS full_name,
		CURRENT_DATE-last_transaction AS days_since_last_transaction
		FROM v_customers c
		JOIN last_transactions lt ON c.customer_id=lt.customer_id
		ORDER BY days_since_last_transaction DESC


-- 5 Which customer segment generates the highest revenue

SELECT ct.customer_type_name, 
	SUM(t.amount) AS total_revenue
	FROM customer_types ct
	JOIN customers c ON ct.customer_type_id=c.customer_type_id
	JOIN accounts a ON c.customer_id=a.customer_id
	JOIN transactions t ON a.account_id=t.account_origin_id
	GROUP BY ct.customer_type_name
	ORDER BY total_revenue DESC;


-- 6 Calculate average transaction amount by account type


SELECT at.account_type_name,SUM(t.amount) AS total_rev,
		ROUND(AVG(t.amount),2) AS avg_transaction_amount
		FROM account_types AS at
		JOIN accounts a ON at.account_type_id=a.account_type_id
		JOIN transactions t ON a.account_id=t.account_origin_id
		GROUP BY at.account_type_name
		ORDER BY total_rev DESC;


-- 7 Rank customers by total balance within each branch

SELECT
    branch_name,
    customer_id,
    customer_name,
    total_balance,
    RANK() OVER (PARTITION BY branch_id ORDER BY total_balance DESC) AS balance_rank
FROM (SELECT
    b.branch_id,
    b.branch_name,
    c.customer_id,
	CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    SUM(a.balance) AS total_balance
FROM customers c
JOIN accounts a
ON c.customer_id = a.customer_id
JOIN transactions t
ON a.account_id = t.account_origin_id
JOIN branches b
ON t.branch_id = b.branch_id
	GROUP BY
    b.branch_id,
    b.branch_name,
    c.customer_id,
    customer_name)
ORDER BY
branch_name,
balance_rank;


--8   banking performance summary including:Total Customers,Total Accounts,Active Accounts,Total Loan ,Total Transaction Value,Average Transaction Value

WITH customer_summary AS (
    SELECT COUNT(*) AS total_customers
    FROM customers),
account_summary AS (
    SELECT
    COUNT(*) AS total_accounts,
     COUNT(CASE WHEN account_status_id=1  THEN 1 END ) AS active_accounts
FROM accounts),
loan_summary AS (
    SELECT
    ROUND(SUM(principal_amount), 2) AS total_loan
    FROM loans),
transaction_summary AS (
    SELECT ROUND(SUM(amount), 2) AS total_transaction_value,
        ROUND(AVG(amount), 2) AS avg_transaction_value
    FROM transactions)
SELECT
    cs.total_customers,
    acc.total_accounts,
    acc.active_accounts,
    ls.total_loan,
    ts.total_transaction_value,
    ts.avg_transaction_value
FROM customer_summary cs
CROSS JOIN account_summary acc
CROSS JOIN loan_summary ls
CROSS JOIN transaction_summary ts;


-- 9 Identify customers with more than one active loan and measure their total exposure.

SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    COUNT(l.loan_id) AS active_loan_count,
    ROUND(SUM(l.principal_amount), 2) AS total_exposure
FROM customers c
JOIN accounts a
ON c.customer_id = a.customer_id
JOIN loans l
ON a.account_id = l.account_id
JOIN loan_statuses ls
ON l.loan_status_id = ls.loan_status_id
WHERE ls.status_name = 'Active'
GROUP BY
c.customer_id,
customer_name
HAVING COUNT(l.loan_id) > 1
ORDER BY total_exposure DESC;
-----------------------------------------------------------------------------------------------------------------------






