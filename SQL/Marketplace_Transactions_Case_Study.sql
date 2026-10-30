
CREATE DATABASE case_study_1;

USE case_study_1;

SHOW TABLES;


SELECT *
FROM marketplace_transactions
LIMIT 10;

-- check columns name

DESCRIBE marketplace_transactions;

/*
Question 1: Reconstruct the Commercial Performance Bridge

Reconstruct the monthly commercial performance bridge by calculating monthly GMV, delivered GMV, cancelled GMV, returned GMV, discounts, refunds, seller commission, payment fees, fulfilment costs, and contribution proxy.

Compare month-over-month growth in order count, GMV, delivered GMV, and contribution proxy. Identify the months where GMV growth is positive but contribution proxy growth is negative.
*/

-- Monthly GMV and Order Count calculate


USE case_study_1;

SELECT
    DATE_FORMAT(
        STR_TO_DATE(order_timestamp, '%Y-%m-%d'),
        '%Y-%m'
    ) AS order_month,

    COUNT(DISTINCT order_id) AS order_count,

    ROUND(
        SUM(quantity * unit_selling_price - discount_amount),
        2
    ) AS total_gmv

FROM marketplace_transactions

GROUP BY order_month

ORDER BY order_month;

-- Calculate Monthly Delivered GMV


SELECT
    DATE_FORMAT(
        STR_TO_DATE(order_timestamp, '%Y-%m-%d'),
        '%Y-%m'
    ) AS order_month,

    ROUND(
        SUM(
            CASE
                WHEN order_status = 'Delivered'
                THEN quantity * unit_selling_price - discount_amount
                ELSE 0
            END
        ), 2
    ) AS delivered_gmv

FROM marketplace_transactions

GROUP BY order_month

ORDER BY order_month;

-- Calculate Monthly Cancelled GMV


SELECT
    DATE_FORMAT(
        STR_TO_DATE(order_timestamp, '%Y-%m-%d'),
        '%Y-%m'
    ) AS order_month,

    ROUND(
        SUM(
            CASE
                WHEN order_status = 'Cancelled'
                THEN quantity * unit_selling_price - discount_amount
                ELSE 0
            END
        ), 2
    ) AS cancelled_gmv

FROM marketplace_transactions

GROUP BY order_month

ORDER BY order_month;

-- Calculate Monthly Returned GMV


SELECT
    DATE_FORMAT(
        STR_TO_DATE(order_timestamp, '%Y-%m-%d'),
        '%Y-%m'
    ) AS order_month,

    ROUND(
        SUM(
            CASE
                WHEN order_status = 'Returned'
                THEN quantity * unit_selling_price - discount_amount
                ELSE 0
            END
        ), 2
    ) AS returned_gmv

FROM marketplace_transactions

GROUP BY order_month

ORDER BY order_month;

-- Calculate Monthly Discounts


SELECT
    DATE_FORMAT(
        STR_TO_DATE(order_timestamp, '%Y-%m-%d'),
        '%Y-%m'
    ) AS order_month,

    ROUND(SUM(discount_amount), 2) AS total_discounts

FROM marketplace_transactions

GROUP BY order_month

ORDER BY order_month;

-- Calculate Monthly Refunds


SELECT
    DATE_FORMAT(
        STR_TO_DATE(order_timestamp, '%Y-%m-%d'),
        '%Y-%m'
    ) AS order_month,

    ROUND(SUM(refund_amount), 2) AS total_refunds

FROM marketplace_transactions

GROUP BY order_month

ORDER BY order_month;

-- Calculate Monthly Seller Commission


SELECT
    DATE_FORMAT(
        STR_TO_DATE(order_timestamp, '%Y-%m-%d'),
        '%Y-%m'
    ) AS order_month,

    ROUND(
        SUM(
            CASE
                WHEN order_status = 'Delivered'
                THEN (quantity * unit_selling_price - discount_amount)
                     * seller_commission_rate
                ELSE 0
            END
        ), 2
    ) AS seller_commission

FROM marketplace_transactions

GROUP BY order_month

ORDER BY order_month;

-- Calculate Monthly Payment Fees


SELECT
    DATE_FORMAT(
        STR_TO_DATE(order_timestamp, '%Y-%m-%d'),
        '%Y-%m'
    ) AS order_month,

    ROUND(
        SUM(
            CASE
                WHEN order_status = 'Delivered'
                THEN payment_fee
                ELSE 0
            END
        ), 2
    ) AS payment_fees

FROM marketplace_transactions

GROUP BY order_month

ORDER BY order_month;

-- Calculate Monthly Fulfilment Costs


SELECT
    DATE_FORMAT(
        STR_TO_DATE(order_timestamp, '%Y-%m-%d'),
        '%Y-%m'
    ) AS order_month,

    ROUND(
        SUM(
            CASE
                WHEN order_status = 'Delivered'
                THEN fulfilment_cost
                ELSE 0
            END
        ), 2
    ) AS fulfilment_costs

FROM marketplace_transactions

GROUP BY order_month

ORDER BY order_month;

-- Calculate Monthly Contribution Proxy


SELECT
    DATE_FORMAT(
        STR_TO_DATE(order_timestamp, '%Y-%m-%d'),
        '%Y-%m'
    ) AS order_month,

    ROUND(
        SUM(
            CASE
                WHEN order_status = 'Delivered'
                THEN (quantity * unit_selling_price - discount_amount)
                     - refund_amount
                     - payment_fee
                     - fulfilment_cost
                ELSE 0
            END
        ), 2
    ) AS contribution_proxy

FROM marketplace_transactions

GROUP BY order_month

ORDER BY order_month;

-- Calculate Month-over-Month Growth


WITH monthly AS (
    SELECT
        DATE_FORMAT(
            STR_TO_DATE(order_timestamp, '%Y-%m-%d'),
            '%Y-%m'
        ) AS order_month,

        COUNT(DISTINCT order_id) AS order_count,

        SUM(quantity * unit_selling_price - discount_amount)
            AS total_gmv,

        SUM(CASE WHEN order_status = 'Delivered'
            THEN quantity * unit_selling_price - discount_amount
            ELSE 0 END) AS delivered_gmv,

        SUM(CASE WHEN order_status = 'Cancelled'
            THEN quantity * unit_selling_price - discount_amount
            ELSE 0 END) AS cancelled_gmv,

        SUM(CASE WHEN order_status = 'Returned'
            THEN quantity * unit_selling_price - discount_amount
            ELSE 0 END) AS returned_gmv,

        SUM(discount_amount) AS total_discounts,
        SUM(refund_amount) AS total_refunds,

        SUM(CASE WHEN order_status = 'Delivered'
            THEN (quantity * unit_selling_price - discount_amount)
                 * seller_commission_rate
            ELSE 0 END) AS seller_commission,

        SUM(CASE WHEN order_status = 'Delivered'
            THEN payment_fee ELSE 0 END) AS payment_fees,

        SUM(CASE WHEN order_status = 'Delivered'
            THEN fulfilment_cost ELSE 0 END) AS fulfilment_costs,

        SUM(CASE WHEN order_status = 'Delivered'
            THEN (quantity * unit_selling_price - discount_amount)
                 - refund_amount - payment_fee - fulfilment_cost
            ELSE 0 END) AS contribution_proxy

    FROM marketplace_transactions
    GROUP BY order_month
),
growth AS (
    SELECT
        *,
        ROUND(
            (order_count - LAG(order_count) OVER (ORDER BY order_month))
            * 100.0 /
            NULLIF(LAG(order_count) OVER (ORDER BY order_month), 0),
            2
        ) AS order_count_growth_pct,

        ROUND(
            (total_gmv - LAG(total_gmv) OVER (ORDER BY order_month))
            * 100.0 /
            NULLIF(LAG(total_gmv) OVER (ORDER BY order_month), 0),
            2
        ) AS gmv_growth_pct,

        ROUND(
            (delivered_gmv - LAG(delivered_gmv) OVER (ORDER BY order_month))
            * 100.0 /
            NULLIF(LAG(delivered_gmv) OVER (ORDER BY order_month), 0),
            2
        ) AS delivered_gmv_growth_pct,

        ROUND(
            (contribution_proxy -
             LAG(contribution_proxy) OVER (ORDER BY order_month))
            * 100.0 /
            NULLIF(LAG(contribution_proxy) OVER (ORDER BY order_month), 0),
            2
        ) AS contribution_growth_pct

    FROM monthly
)
SELECT
    order_month,
    order_count,
    ROUND(total_gmv, 2) AS total_gmv,
    ROUND(delivered_gmv, 2) AS delivered_gmv,
    ROUND(cancelled_gmv, 2) AS cancelled_gmv,
    ROUND(returned_gmv, 2) AS returned_gmv,
    ROUND(total_discounts, 2) AS total_discounts,
    ROUND(total_refunds, 2) AS total_refunds,
    ROUND(seller_commission, 2) AS seller_commission,
    ROUND(payment_fees, 2) AS payment_fees,
    ROUND(fulfilment_costs, 2) AS fulfilment_costs,
    ROUND(contribution_proxy, 2) AS contribution_proxy,
    order_count_growth_pct,
    gmv_growth_pct,
    delivered_gmv_growth_pct,
    contribution_growth_pct
FROM growth
ORDER BY order_month;

/* 
Calculate the share of delivered GMV and contribution proxy generated by the top 1%, 5%, and 10% of
customers. Calculate repeat-purchase participation and identify customers whose delivered GMV is above the
90th percentile but whose contribution proxy is negative. Determine whether the largest customers are also
the most profitable
*/
-- Question 2 involves identifying customer concentration risks and high-value customers with negative contribution.

-- Step 1: Calculate Delivered GMV and Contribution Proxy by Customer


USE case_study_1;

SELECT
    customer_id,

    ROUND(
        SUM(
            quantity * unit_selling_price - discount_amount
        ), 2
    ) AS delivered_gmv,

    ROUND(
        SUM(
            (quantity * unit_selling_price - discount_amount)
            - refund_amount
            - payment_fee
            - fulfilment_cost
        ), 2
    ) AS contribution_proxy,

    COUNT(DISTINCT order_id) AS delivered_order_count

FROM marketplace_transactions

WHERE order_status = 'Delivered'

GROUP BY customer_id

ORDER BY delivered_gmv DESC;

-- Step 2: Customer Concentration


USE case_study_1;

WITH customer_totals AS (
    SELECT
        customer_id,
        SUM(quantity * unit_selling_price - discount_amount) AS delivered_gmv,
        SUM(
            (quantity * unit_selling_price - discount_amount)
            - refund_amount
            - payment_fee
            - fulfilment_cost
        ) AS contribution_proxy
    FROM marketplace_transactions
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
),
ranked_customers AS (
    SELECT
        customer_id,
        delivered_gmv,
        contribution_proxy,
        NTILE(100) OVER (
            ORDER BY delivered_gmv DESC
        ) AS pct_bucket
    FROM customer_totals
),
concentration AS (
    SELECT
        'Top 1%' AS concentration_band,
        1 AS sort_order,
        SUM(delivered_gmv) AS delivered_gmv,
        SUM(contribution_proxy) AS contribution_proxy
    FROM ranked_customers
    WHERE pct_bucket <= 1

    UNION ALL

    SELECT
        'Top 5%',
        2,
        SUM(delivered_gmv),
        SUM(contribution_proxy)
    FROM ranked_customers
    WHERE pct_bucket <= 5

    UNION ALL

    SELECT
        'Top 10%',
        3,
        SUM(delivered_gmv),
        SUM(contribution_proxy)
    FROM ranked_customers
    WHERE pct_bucket <= 10
)
SELECT
    concentration_band,
    ROUND(delivered_gmv, 2) AS delivered_gmv,
    ROUND(contribution_proxy, 2) AS contribution_proxy,
    ROUND(
        delivered_gmv * 100 /
        (SELECT SUM(delivered_gmv) FROM ranked_customers),
        2
    ) AS share_of_total_gmv_pct,
    ROUND(
        contribution_proxy * 100 /
        (SELECT SUM(contribution_proxy) FROM ranked_customers),
        2
    ) AS share_of_total_contribution_pct
FROM concentration
ORDER BY sort_order;

-- Step 3: High-value but unprofitable customers


USE case_study_1;

WITH customer_totals AS (
    SELECT
        customer_id,
        SUM(quantity * unit_selling_price - discount_amount) AS delivered_gmv,
        SUM(
            (quantity * unit_selling_price - discount_amount)
            - refund_amount
            - payment_fee
            - fulfilment_cost
        ) AS contribution_proxy,
        COUNT(DISTINCT order_id) AS delivered_order_count
    FROM marketplace_transactions
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
),
ranked_customers AS (
    SELECT
        customer_id,
        delivered_gmv,
        contribution_proxy,
        delivered_order_count,
        PERCENT_RANK() OVER (
            ORDER BY delivered_gmv
        ) AS gmv_percentile
    FROM customer_totals
)
SELECT
    customer_id,
    ROUND(delivered_gmv, 2) AS delivered_gmv,
    ROUND(contribution_proxy, 2) AS contribution_proxy,
    delivered_order_count,
    ROUND(gmv_percentile, 2) AS gmv_percentile,
    CASE
        WHEN contribution_proxy < 0 THEN 'Yes'
        ELSE 'No'
    END AS negative_contribution
FROM ranked_customers
WHERE contribution_proxy < 0
ORDER BY delivered_gmv DESC;

-- Step 4: Check negative contribution customers


WITH customer_totals AS (
    SELECT
        customer_id,
        SUM(
            (quantity * unit_selling_price - discount_amount)
            - refund_amount
            - payment_fee
            - fulfilment_cost
        ) AS contribution_proxy
    FROM marketplace_transactions
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
)
SELECT
    COUNT(*) AS total_customers,
    SUM(CASE
        WHEN contribution_proxy < 0 THEN 1
        ELSE 0
    END) AS negative_contribution_customers
FROM customer_totals;

/*
Calculate discount rates by product category and acquisition channel. Identify categories where higher
discount rates coincide with lower contribution per delivered order. Compare customer segments by average
order value, repeat-purchase frequency, discount dependency, refund burden, and contribution proxy. Identify
high-value transactions with weak post-discount economics
*/

-- Question 3: Discount Dependency and Commercial Quality

-- Step 1: Discount Rate by Product Category


USE case_study_1;

SELECT
    product_category,
    ROUND(
        100 * SUM(discount_amount) /
        NULLIF(SUM(quantity * unit_list_price), 0),
        2
    ) AS discount_rate_pct
FROM marketplace_transactions
GROUP BY product_category
ORDER BY discount_rate_pct DESC;

-- Step 2: Discount Rate by Acquisition Channel


SELECT
    acquisition_channel,
    ROUND(
        100 * SUM(discount_amount) /
        NULLIF(SUM(quantity * unit_list_price), 0),
        2
    ) AS discount_rate_pct
FROM marketplace_transactions
GROUP BY acquisition_channel
ORDER BY discount_rate_pct DESC;

-- Step 3: Category-wise Commercial Quality


WITH category_metrics AS (
    SELECT
        product_category,
        100 * SUM(discount_amount) /
            NULLIF(SUM(quantity * unit_list_price), 0)
            AS discount_rate_pct,

        SUM(
            CASE WHEN order_status = 'Delivered'
            THEN (quantity * unit_selling_price - discount_amount)
                 - refund_amount - payment_fee - fulfilment_cost
            ELSE 0 END
        ) / NULLIF(
            COUNT(DISTINCT CASE
                WHEN order_status = 'Delivered' THEN order_id
            END), 0
        ) AS contribution_per_delivered_order,

        100 * SUM(
            CASE WHEN order_status = 'Delivered'
            THEN refund_amount ELSE 0 END
        ) / NULLIF(
            SUM(CASE
                WHEN order_status = 'Delivered'
                THEN quantity * unit_selling_price - discount_amount
                ELSE 0
            END), 0
        ) AS refund_rate_pct
    FROM marketplace_transactions
    GROUP BY product_category
)
SELECT
    product_category,
    ROUND(discount_rate_pct, 2) AS discount_rate_pct,
    ROUND(contribution_per_delivered_order, 2)
        AS contribution_per_delivered_order,
    ROUND(refund_rate_pct, 2) AS refund_rate_pct,
    CASE
        WHEN discount_rate_pct >= 16
             AND refund_rate_pct >= 5 THEN 'High'
        WHEN discount_rate_pct >= 15
             OR refund_rate_pct >= 4 THEN 'Medium'
        ELSE 'Low'
    END AS commercial_risk
FROM category_metrics
ORDER BY contribution_per_delivered_order ASC;

-- Step 4: High-value transactions with weak post-discount economics


SELECT
    transaction_id,
    order_id,
    customer_id,
    product_category,
    quantity,
    ROUND(quantity * unit_list_price, 2) AS list_price_value,
    ROUND(discount_amount, 2) AS discount_amount,
    ROUND(
        quantity * unit_selling_price - discount_amount,
        2
    ) AS delivered_gmv,
    ROUND(
        (quantity * unit_selling_price - discount_amount)
        - refund_amount
        - payment_fee
        - fulfilment_cost,
        2
    ) AS contribution_proxy
FROM marketplace_transactions
WHERE order_status = 'Delivered'
ORDER BY contribution_proxy ASC
LIMIT 10;

-- Step 5 — High discount aur low contribution wale transactions

SELECT
    transaction_id,
    order_id,
    customer_id,
    product_category,
    ROUND(
        100 * discount_amount /
        NULLIF(quantity * unit_list_price, 0), 2
    ) AS discount_rate_pct,
    ROUND(
        quantity * unit_selling_price - discount_amount, 2
    ) AS delivered_gmv,
    ROUND(
        (quantity * unit_selling_price - discount_amount)
        - refund_amount - payment_fee - fulfilment_cost, 2
    ) AS contribution_proxy
FROM marketplace_transactions
WHERE order_status = 'Delivered'
ORDER BY discount_rate_pct DESC, contribution_proxy ASC
LIMIT 10;

-- Step 6 — Customer Segment Analysis

SELECT
    customer_segment,
    COUNT(DISTINCT customer_id) AS total_customers,
    COUNT(DISTINCT CASE
        WHEN order_status = 'Delivered' THEN order_id
    END) AS delivered_orders,

    ROUND(
        SUM(CASE WHEN order_status = 'Delivered'
            THEN quantity * unit_selling_price - discount_amount
            ELSE 0 END)
        / NULLIF(COUNT(DISTINCT CASE
            WHEN order_status = 'Delivered' THEN order_id
        END), 0), 2
    ) AS avg_order_value,

    ROUND(
        100 * SUM(CASE WHEN order_status = 'Delivered'
            THEN discount_amount ELSE 0 END)
        / NULLIF(SUM(CASE WHEN order_status = 'Delivered'
            THEN quantity * unit_list_price ELSE 0 END), 0), 2
    ) AS discount_rate_pct,

    ROUND(
        100 * SUM(CASE WHEN order_status = 'Delivered'
            THEN refund_amount ELSE 0 END)
        / NULLIF(SUM(CASE WHEN order_status = 'Delivered'
            THEN quantity * unit_selling_price - discount_amount
            ELSE 0 END), 0), 2
    ) AS refund_rate_pct,

    ROUND(
        SUM(CASE WHEN order_status = 'Delivered'
            THEN (quantity * unit_selling_price - discount_amount)
                 - refund_amount - payment_fee - fulfilment_cost
            ELSE 0 END)
        / NULLIF(COUNT(DISTINCT CASE
            WHEN order_status = 'Delivered' THEN order_id
        END), 0), 2
    ) AS contribution_per_order

FROM marketplace_transactions
GROUP BY customer_segment
ORDER BY contribution_per_order DESC;

-- Step 7 — Repeat Purchase Frequency

WITH customer_orders AS (
    SELECT
        customer_id,
        customer_segment,
        COUNT(DISTINCT order_id) AS delivered_order_count
    FROM marketplace_transactions
    WHERE order_status = 'Delivered'
    GROUP BY customer_id, customer_segment
)
SELECT
    customer_segment,
    COUNT(*) AS purchasing_customers,
    SUM(CASE
        WHEN delivered_order_count >= 2 THEN 1
        ELSE 0
    END) AS repeat_customers,
    ROUND(
        100.0 * SUM(CASE
            WHEN delivered_order_count >= 2 THEN 1
            ELSE 0
        END) / COUNT(*), 2
    ) AS repeat_purchase_rate_pct,
    ROUND(AVG(delivered_order_count), 2) AS avg_delivered_orders_per_customer
FROM customer_orders
GROUP BY customer_segment
ORDER BY repeat_purchase_rate_pct DESC;

-- Step 8 — Category Contribution Ranking

SELECT
    product_category,

    ROUND(SUM(
        CASE WHEN order_status = 'Delivered'
        THEN quantity * unit_selling_price - discount_amount
        ELSE 0 END
    ), 2) AS delivered_gmv,

    ROUND(SUM(
        CASE WHEN order_status = 'Delivered'
        THEN (quantity * unit_selling_price - discount_amount)
             - refund_amount - payment_fee - fulfilment_cost
        ELSE 0 END
    ), 2) AS current_contribution_proxy,

    ROUND(
        10 * SUM(
            CASE WHEN order_status = 'Delivered'
            THEN quantity * unit_selling_price - discount_amount
            ELSE 0 END
        ) / 100, 2
    ) AS gmv_reduction_scenario_10pct

FROM marketplace_transactions
GROUP BY product_category
ORDER BY gmv_reduction_scenario_10pct DESC;

-- Step 9 — Contribution Proxy Potentially Exposed

WITH category_metrics AS (
    SELECT
        product_category,
        SUM(
            CASE WHEN order_status = 'Delivered'
            THEN quantity * unit_selling_price - discount_amount
            ELSE 0 END
        ) AS delivered_gmv,

        SUM(
            CASE WHEN order_status = 'Delivered'
            THEN (quantity * unit_selling_price - discount_amount)
                 - refund_amount - payment_fee - fulfilment_cost
            ELSE 0 END
        ) AS contribution_proxy

    FROM marketplace_transactions
    GROUP BY product_category
)
SELECT
    product_category,
    ROUND(delivered_gmv, 2) AS delivered_gmv,
    ROUND(contribution_proxy, 2) AS current_contribution_proxy,
    ROUND(delivered_gmv * 0.10, 2) AS gmv_reduction_10pct,
    ROUND(contribution_proxy * 0.10, 2)
        AS contribution_proxy_potentially_exposed
FROM category_metrics
ORDER BY contribution_proxy_potentially_exposed DESC;

/*
Build acquisition-month cohorts. Compare first-purchase contribution, 90-day cumulative contribution, and
repeat-purchase rate by acquisition channel. Identify cohorts where first-purchase economics are positive but
90-day economics deteriorate, and flag incomplete 90-day windows
*/

-- Q4 — Acquisition Cohort Quality

-- Step 1: Acquisition Cohort Analysis

USE case_study_1;

SELECT
    DATE_FORMAT(
        STR_TO_DATE(customer_acquisition_date, '%Y-%m-%d'),
        '%Y-%m'
    ) AS acquisition_month,

    COUNT(DISTINCT customer_id) AS total_customers,

    COUNT(DISTINCT CASE
        WHEN order_status = 'Delivered' THEN order_id
    END) AS delivered_orders,

    ROUND(SUM(
        CASE WHEN order_status = 'Delivered'
        THEN quantity * unit_selling_price - discount_amount
        ELSE 0 END
    ), 2) AS delivered_gmv,

    ROUND(SUM(
        CASE WHEN order_status = 'Delivered'
        THEN (quantity * unit_selling_price - discount_amount)
             - refund_amount - payment_fee - fulfilment_cost
        ELSE 0 END
    ), 2) AS contribution_proxy

FROM marketplace_transactions
GROUP BY acquisition_month
ORDER BY acquisition_month;

-- Step 2 — Acquisition Cohort Contribution per Delivered Order

SELECT
    DATE_FORMAT(
        STR_TO_DATE(customer_acquisition_date, '%Y-%m-%d'),
        '%Y-%m'
    ) AS acquisition_month,

    COUNT(DISTINCT customer_id) AS total_customers,

    COUNT(DISTINCT CASE
        WHEN order_status = 'Delivered' THEN order_id
    END) AS delivered_orders,

    ROUND(
        SUM(
            CASE WHEN order_status = 'Delivered'
            THEN (quantity * unit_selling_price - discount_amount)
                 - refund_amount - payment_fee - fulfilment_cost
            ELSE 0 END
        )
        / NULLIF(
            COUNT(DISTINCT CASE
                WHEN order_status = 'Delivered' THEN order_id
            END), 0
        ),
        2
    ) AS contribution_per_delivered_order

FROM marketplace_transactions
GROUP BY acquisition_month
ORDER BY contribution_per_delivered_order DESC;

-- Step 3. Which customer acquisition cohorts have the highest repeat customer rate, and how does repeat purchasing behavior vary across acquisition months?

SELECT
    acquisition_month,
    COUNT(*) AS total_customers,
    SUM(CASE
        WHEN delivered_orders >= 2 THEN 1
        ELSE 0
    END) AS repeat_customers,
    ROUND(
        SUM(CASE
            WHEN delivered_orders >= 2 THEN 1
            ELSE 0
        END) * 100.0 / COUNT(*),
        2
    ) AS repeat_customer_rate_pct
FROM (
    SELECT
        customer_id,
        DATE_FORMAT(
            STR_TO_DATE(
                MIN(customer_acquisition_date),
                '%Y-%m-%d'
            ),
            '%Y-%m'
        ) AS acquisition_month,
        COUNT(DISTINCT CASE
            WHEN order_status = 'Delivered' THEN order_id
        END) AS delivered_orders
    FROM marketplace_transactions
    GROUP BY customer_id
) AS customer_cohorts
GROUP BY acquisition_month
ORDER BY acquisition_month;

-- Step 4 Question: Which acquisition cohorts generate the highest total contribution and contribution per delivered order, and how can the business use these insights to improve customer acquisition strategy?

SELECT
    DATE_FORMAT(
        STR_TO_DATE(customer_acquisition_date, '%Y-%m-%d'),
        '%Y-%m'
    ) AS acquisition_month,

    COUNT(DISTINCT customer_id) AS total_customers,

    COUNT(DISTINCT CASE
        WHEN order_status = 'Delivered'
        THEN order_id
    END) AS delivered_orders,

    ROUND(
        SUM(CASE
            WHEN order_status = 'Delivered'
            THEN (quantity * unit_selling_price - discount_amount)
                 - refund_amount
                 - payment_fee
                 - fulfilment_cost
            ELSE 0
        END),
        2
    ) AS total_contribution,

    ROUND(
        SUM(CASE
            WHEN order_status = 'Delivered'
            THEN (quantity * unit_selling_price - discount_amount)
                 - refund_amount
                 - payment_fee
                 - fulfilment_cost
            ELSE 0
        END)
        / NULLIF(
            COUNT(DISTINCT CASE
                WHEN order_status = 'Delivered'
                THEN order_id
            END),
            0
        ),
        2
    ) AS contribution_per_order

FROM marketplace_transactions

GROUP BY acquisition_month

ORDER BY total_contribution DESC;

-- Step 5 Question: What recommendations can the business make to improve customer acquisition quality, repeat purchases, and contribution from each acquisition cohort?

SELECT
    acquisition_month,
    COUNT(*) AS total_customers,

    SUM(CASE
        WHEN delivered_orders >= 2 THEN 1
        ELSE 0
    END) AS repeat_customers,

    ROUND(
        100.0 * SUM(CASE
            WHEN delivered_orders >= 2 THEN 1
            ELSE 0
        END) / COUNT(*),
        2
    ) AS repeat_customer_rate_pct,

    SUM(delivered_orders) AS delivered_orders,

    ROUND(SUM(total_contribution), 2) AS total_contribution,

    ROUND(
        SUM(total_contribution) /
        NULLIF(SUM(delivered_orders), 0),
        2
    ) AS contribution_per_order

FROM (
    SELECT
        customer_id,

        DATE_FORMAT(
            STR_TO_DATE(
                MIN(customer_acquisition_date),
                '%Y-%m-%d'
            ),
            '%Y-%m'
        ) AS acquisition_month,

        COUNT(DISTINCT CASE
            WHEN order_status = 'Delivered'
            THEN order_id
        END) AS delivered_orders,

        SUM(CASE
            WHEN order_status = 'Delivered'
            THEN (quantity * unit_selling_price - discount_amount)
                 - refund_amount
                 - payment_fee
                 - fulfilment_cost
            ELSE 0
        END) AS total_contribution

    FROM marketplace_transactions
    GROUP BY customer_id
) AS customer_cohorts

GROUP BY acquisition_month
ORDER BY total_contribution DESC;

/*
Quantify current monthly contribution by category. Calculate the break-even delivered-GMV decline that
eliminates the benefit of a 10% reduction in discount expense. Identify categories with the smallest tolerance
for volume decline
*/

-- Step 1: Current contribution and discount expense by category

SELECT
    DATE_FORMAT(order_timestamp, '%Y-%m') AS month,
    product_category,

    ROUND(
        SUM(CASE
            WHEN order_status = 'Delivered'
            THEN discount_amount
            ELSE 0
        END) * 0.10,
        2
    ) AS discount_saving,

    ROUND(
        SUM(CASE
            WHEN order_status = 'Delivered'
            THEN (quantity * unit_selling_price - discount_amount)
                 - refund_amount - payment_fee - fulfilment_cost
            ELSE 0
        END),
        2
    ) AS contribution_at_risk,

    ROUND(
        (
            SUM(CASE
                WHEN order_status = 'Delivered'
                THEN discount_amount
                ELSE 0
            END) * 0.10
        )
        /
        NULLIF(
            SUM(CASE
                WHEN order_status = 'Delivered'
                THEN (quantity * unit_selling_price - discount_amount)
                     - refund_amount - payment_fee - fulfilment_cost
                ELSE 0
            END),
            0
        ) * 100,
        2
    ) AS break_even_gmv_decline_pct

FROM marketplace_transactions

GROUP BY
    DATE_FORMAT(order_timestamp, '%Y-%m'),
    product_category

ORDER BY
    month,
    break_even_gmv_decline_pct ASC;

-- Step 2: 10% Discount Reduction Scenario

SELECT
    product_category,

    ROUND(SUM(CASE
        WHEN order_status = 'Delivered'
        THEN discount_amount
        ELSE 0
    END) * 0.10, 2) AS discount_saving,

    ROUND(SUM(CASE
        WHEN order_status = 'Delivered'
        THEN (quantity * unit_selling_price - discount_amount)
             - refund_amount
             - payment_fee
             - fulfilment_cost
        ELSE 0
    END), 2) AS contribution_at_risk,

    ROUND(
        100.0 * (
            SUM(CASE
                WHEN order_status = 'Delivered'
                THEN discount_amount
                ELSE 0
            END) * 0.10
        ) / NULLIF(
            SUM(CASE
                WHEN order_status = 'Delivered'
                THEN (quantity * unit_selling_price - discount_amount)
                     - refund_amount
                     - payment_fee
                     - fulfilment_cost
                ELSE 0
            END),
            0
        ),
        2
    ) AS break_even_gmv_decline_pct

FROM marketplace_transactions
GROUP BY product_category
ORDER BY break_even_gmv_decline_pct ASC;

-- Step 3: Monthly contribution by category

SELECT
    DATE_FORMAT(order_timestamp, '%Y-%m') AS month,
    product_category,

    COUNT(DISTINCT CASE
        WHEN order_status = 'Delivered'
        THEN order_id
    END) AS delivered_orders,

    ROUND(SUM(CASE
        WHEN order_status = 'Delivered'
        THEN quantity * unit_selling_price - discount_amount
        ELSE 0
    END), 2) AS delivered_gmv,

    ROUND(SUM(CASE
        WHEN order_status = 'Delivered'
        THEN discount_amount
        ELSE 0
    END), 2) AS discount_expense,

    ROUND(SUM(CASE
        WHEN order_status = 'Delivered'
        THEN (quantity * unit_selling_price - discount_amount)
             - refund_amount - payment_fee - fulfilment_cost
        ELSE 0
    END), 2) AS current_contribution

FROM marketplace_transactions
GROUP BY
    DATE_FORMAT(order_timestamp, '%Y-%m'),
    product_category
ORDER BY
    month,
    product_category;
