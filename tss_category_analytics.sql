-- =============================================================================
-- THE SOULED STORE — CATEGORY ANALYTICS SQL QUERIES
-- Author: Jayesh Dipak Bedse
-- Coverage: Sales Performance, Inventory Health, Sell-Through, Category Margins,
--           Customer Behaviour, Channel Mix, Seasonality, Forecasting Support
-- =============================================================================
Create database The_Souled_Store;
Use The_souled_store;
-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 1: SALES PERFORMANCE & REVENUE
-- ───────────────────────────────────────────────────────────────────────────── 

-- Q1. Monthly Revenue Trend with MoM Growth %
--     Purpose: Track top-line momentum and identify growth/decline inflection points.
-- ─────────────────────────────────────────────────────────────────────────────
WITH monthly_rev AS (
    SELECT year, month, month_name,
        ROUND(SUM(revenue_inr) / 100000, 2)AS revenue_lakhs,
        COUNT(DISTINCT order_id)AS total_orders,
        ROUND(AVG(selling_price), 0)AS avg_order_value
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY year, month, month_name
)
SELECT year, month_name, revenue_lakhs, total_orders, avg_order_value,
    LAG(revenue_lakhs) OVER (ORDER BY year, month) AS prev_month_revenue,
    ROUND((revenue_lakhs - LAG(revenue_lakhs) OVER (ORDER BY year, month))/ NULLIF(LAG(revenue_lakhs) OVER (ORDER BY year, month), 0) * 100, 1
    )AS mom_growth_pct
FROM monthly_rev
ORDER BY year, month;


-- Q2. Category Revenue Contribution & Gross Margin (YTD)
--     Purpose: Identify which fandoms/categories drive revenue vs. profit.
-- ─────────────────────────────────────────────────────────────────────────────
SELECT o.category,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(o.quantity) AS units_sold,
    ROUND(SUM(o.revenue_inr) / 100000, 2) AS revenue_lakhs,
    ROUND(SUM(o.gross_profit_inr) / 100000, 2)AS gross_profit_lakhs,
    ROUND(SUM(o.gross_profit_inr) / NULLIF(SUM(o.revenue_inr), 0) * 100, 1) AS gross_margin_pct,
    ROUND(SUM(o.revenue_inr) / NULLIF(SUM(SUM(o.revenue_inr)) OVER (), 0) * 100, 1) AS revenue_share_pct,
    ROUND(AVG(o.discount_pct), 1) AS avg_discount_pct
FROM orders o
WHERE o.order_status = 'Delivered' AND o.year = 2024
GROUP BY o.category
ORDER BY revenue_lakhs DESC;


-- Q3. Top 20 Products by Revenue with Sell-Through
--     Purpose: Identify hero SKUs and flag low-traction products.
-- ─────────────────────────────────────────────────────────────────────────────
SELECT p.product_id, p.product_name, p.category, p.product_type, p.gender, p.mrp,
    SUM(o.quantity) AS units_sold,
    ROUND(SUM(o.revenue_inr) / 1000, 1) AS revenue_thousands,
    ROUND(AVG(o.gross_margin_pct), 1) AS avg_margin_pct,
    ROUND(AVG(o.discount_pct), 1) AS avg_discount_pct,
    MAX(i.sell_through_pct) AS sell_through_pct,
    MAX(i.stock_health_status) AS stock_status
FROM orders o JOIN products p  ON o.product_id = p.product_id
LEFT JOIN (
    SELECT product_id,
           MAX(sell_through_pct)    AS sell_through_pct,
           MAX(stock_health_status) AS stock_health_status
    FROM inventory
    GROUP BY product_id
) i ON p.product_id = i.product_id
WHERE o.order_status = 'Delivered'
GROUP BY p.product_id, p.product_name, p.category, p.product_type, p.gender, p.mrp
ORDER BY units_sold DESC
LIMIT 20;


-- Q4. Channel-wise Revenue, Orders, AOV and Discount Rate
--     Purpose: Understand channel health and profitability leakage via discounts.
-- ─────────────────────────────────────────────────────────────────────────────
SELECT channel, year,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(quantity) AS units_sold,
    ROUND(SUM(revenue_inr) / 100000, 2) AS revenue_lakhs,
    ROUND(AVG(selling_price), 0) AS avg_order_value,
    ROUND(AVG(discount_pct), 1) AS avg_discount_pct,
    ROUND(SUM(gross_profit_inr) / NULLIF(SUM(revenue_inr),0) * 100, 1) AS gross_margin_pct,
    ROUND(SUM(revenue_inr) / NULLIF(SUM(SUM(revenue_inr)) OVER (PARTITION BY year), 0) * 100, 1) AS channel_share_pct
FROM orders
WHERE order_status = 'Delivered'
GROUP BY channel, year
ORDER BY year, revenue_lakhs DESC;


-- Q5. Quarterly Revenue by Category (Pivot-ready format for BI tools)
--     Purpose: Spot seasonal spikes per category — Marvel in Q3 (festive), Basics year-round.
-- ─────────────────────────────────────────────────────────────────────────────
SELECT year, quarter, category,
    ROUND(SUM(revenue_inr) / 100000, 2) AS revenue_lakhs,
    SUM(quantity) AS units_sold,
    COUNT(DISTINCT order_id) AS orders,
    ROUND(AVG(discount_pct), 1) AS avg_discount_pct
FROM orders
WHERE order_status = 'Delivered'
GROUP BY year, quarter, category
ORDER BY year, quarter, revenue_lakhs DESC;


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 2: INVENTORY HEALTH & STOCK MANAGEMENT
-- ─────────────────────────────────────────────────────────────────────────────

-- Q6. Current Inventory Health Summary by Category
--     Purpose: Flag overstocked and understocked categories for allocation decisions.
-- ─────────────────────────────────────────────────────────────────────────────
SELECT category,
    COUNT(DISTINCT product_id) AS sku_count,
    SUM(closing_stock) AS total_closing_units,
    ROUND(AVG(sell_through_pct), 1) AS avg_sell_through_pct,
    ROUND(AVG(rate_of_sale_per_week), 2) AS avg_ros_per_week,
    ROUND(AVG(weeks_of_cover), 1) AS avg_weeks_of_cover,
    SUM(CASE WHEN stock_health_status = 'Stockout'    THEN 1 ELSE 0 END) AS stockout_skus,
    SUM(CASE WHEN stock_health_status = 'Low Stock'   THEN 1 ELSE 0 END) AS low_stock_skus,
    SUM(CASE WHEN stock_health_status = 'Overstocked' THEN 1 ELSE 0 END) AS overstock_skus,
    ROUND(SUM(stock_value_at_cost) / 100000, 2)	AS stock_value_at_cost_lakhs
FROM inventory
GROUP BY category
ORDER BY avg_sell_through_pct DESC;


-- Q7. Overstock Alert — SKUs with >16 Weeks of Cover and <30% Sell-Through
--     Purpose: Identify dead stock requiring markdown or clearance action.
-- ─────────────────────────────────────────────────────────────────────────────
SELECT i.product_id, p.product_name, p.category, p.product_type, i.size, i.closing_stock, i.sell_through_pct,
 i.rate_of_sale_per_week, i.weeks_of_cover, i.stock_value_at_mrp, i.stock_value_at_cost,
    ROUND(i.stock_value_at_cost * 0.35, 0) AS potential_markdown_loss,
    'Clearance Recommended' AS action_flag
FROM inventory i
JOIN products p ON i.product_id = p.product_id
WHERE i.weeks_of_cover > 16
  AND i.sell_through_pct < 30
  AND i.closing_stock > 20
ORDER BY i.stock_value_at_cost DESC
LIMIT 30;


-- Q8. Stockout & Low Stock — Reorder Priority List
--     Purpose: Trigger reorder recommendations before lost sales occur.
-- ─────────────────────────────────────────────────────────────────────────────
SELECT i.product_id, p.product_name, p.category, i.size, i.closing_stock, i.rate_of_sale_per_week, i.weeks_of_cover, i.stock_health_status,
    ROUND(i.rate_of_sale_per_week * 8, 0) AS suggested_reorder_qty,   -- 8 weeks coverage
    p.cost_price,
    ROUND(i.rate_of_sale_per_week * 8 * p.cost_price, 0) AS reorder_value_inr,
    CASE
        WHEN i.closing_stock = 0 THEN 'P1 - Urgent'
        WHEN i.weeks_of_cover < 4 THEN 'P2 - High'
        ELSE 'P3 - Medium'
    END AS reorder_priority
FROM inventory i
JOIN products p ON i.product_id = p.product_id
WHERE i.reorder_recommended = TRUE
ORDER BY
    CASE WHEN i.closing_stock = 0 THEN 0 WHEN i.weeks_of_cover < 4 THEN 1 ELSE 2 END,
    i.rate_of_sale_per_week DESC;


-- Q9. Size Curve Analysis — Sell-Through by Size per Category
--     Purpose: Optimise size ratio in future purchase orders.
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    p.category,
    i.size,
    SUM(i.units_sold) AS units_sold,
    SUM(i.closing_stock) AS units_remaining,
    ROUND(AVG(i.sell_through_pct), 1) AS avg_sell_through_pct,
    SUM(i.units_sold) * 1.0 / NULLIF(SUM(SUM(i.units_sold)) OVER (PARTITION BY p.category), 0) * 100 AS size_contribution_pct
FROM inventory i
JOIN products p ON i.product_id = p.product_id
GROUP BY p.category, i.size
ORDER BY p.category,
    CASE i.size WHEN 'XS' THEN 1 WHEN 'S' THEN 2 WHEN 'M' THEN 3
                WHEN 'L' THEN 4 WHEN 'XL' THEN 5 WHEN 'XXL' THEN 6 END;


-- Q10. Sell-Through Rate by Product Type and Gender
--      Purpose: Inform buying decisions — which type/gender sells fastest.
-- ─────────────────────────────────────────────────────────────────────────────
SELECT p.product_type, p.gender,
    COUNT(DISTINCT i.product_id) AS sku_count,
    ROUND(AVG(i.sell_through_pct), 1) AS avg_sell_through_pct,
    ROUND(AVG(i.rate_of_sale_per_week), 2) AS avg_ros,
    ROUND(AVG(i.weeks_of_cover), 1) AS avg_weeks_cover,
    SUM(i.units_sold) AS total_units_sold
FROM inventory i
JOIN products p ON i.product_id = p.product_id
GROUP BY p.product_type, p.gender
ORDER BY avg_sell_through_pct DESC;


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 3: CUSTOMER BEHAVIOUR & SEGMENTATION
-- ─────────────────────────────────────────────────────────────────────────────

-- Q11. RFM Segmentation — Recency, Frequency, Monetary
--      Purpose: Drive targeted CRM campaigns and retention strategy.
-- ─────────────────────────────────────────────────────────────────────────────
WITH rfm_raw AS (
    SELECT 
        o.customer_id,
        MAX(o.order_date)            AS last_order_date,
        COUNT(DISTINCT o.order_id)   AS frequency,
        ROUND(SUM(o.revenue_inr), 0) AS monetary
    FROM orders o
    WHERE o.order_status = 'Delivered'
    GROUP BY o.customer_id
),
rfm_scored AS (
    SELECT *,
        DATEDIFF(CURRENT_DATE, last_order_date)                              AS recency_days,
        NTILE(5) OVER (ORDER BY DATEDIFF(CURRENT_DATE, last_order_date) ASC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency DESC)                              AS f_score,
        NTILE(5) OVER (ORDER BY monetary DESC)                               AS m_score
    FROM rfm_raw
)
SELECT
    customer_id,
    recency_days,
    frequency,
    monetary,
    r_score, f_score, m_score,
    (r_score + f_score + m_score) AS rfm_total,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 THEN 'Champion'
        WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal'
        WHEN r_score >= 4 AND f_score <  3 THEN 'Potential Loyalist'
        WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
        WHEN r_score =  5 AND f_score =  1 THEN 'New Customer'
        WHEN r_score <= 1                  THEN 'Lost'
        ELSE                                    'Needs Attention'
    END AS rfm_segment
FROM rfm_scored
ORDER BY rfm_total DESC;


-- Q12. Repeat Purchase Rate and Cohort Retention
--      Purpose: Measure loyalty — % of customers who order more than once.
-- ─────────────────────────────────────────────────────────────────────────────
WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id)  AS order_count,
        MIN(order_date)           AS first_order_date
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
)
SELECT
    YEAR(first_order_date)                                           AS acquisition_year,
    QUARTER(first_order_date)                                        AS acquisition_quarter,
    COUNT(*)                                                         AS cohort_size,
    SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END)                AS repeat_customers,
    ROUND(SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END)
        / COUNT(*) * 100, 1)                                         AS repeat_rate_pct,
    ROUND(AVG(order_count), 2)                                       AS avg_orders_per_customer
FROM customer_orders
GROUP BY acquisition_year, acquisition_quarter
ORDER BY acquisition_year, acquisition_quarter;

-- Q13. Preferred Category by Customer Loyalty Segment
--      Purpose: Tailor merchandising and communications to each segment.
-- ─────────────────────────────────────────────────────────────────────────────
SELECT c.loyalty_segment, o.category,
    COUNT(DISTINCT o.customer_id) AS unique_buyers,
    SUM(o.quantity) AS units_purchased,
    ROUND(SUM(o.revenue_inr) / 100000, 2) AS revenue_lakhs,
    ROUND(AVG(o.selling_price), 0) AS avg_basket_value
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'Delivered'
GROUP BY c.loyalty_segment, o.category
ORDER BY c.loyalty_segment, revenue_lakhs DESC;


-- Q14. Acquisition Channel Effectiveness — CAC vs LTV
--      Purpose: Identify highest ROI acquisition channels.
-- ─────────────────────────────────────────────────────────────────────────────
SELECT c.acquisition_channel,
    COUNT(*) AS total_customers,
    ROUND(AVG(c.total_spend_inr), 0) AS avg_ltv_inr,
    ROUND(AVG(c.total_orders), 1) AS avg_orders,
    ROUND(AVG(c.avg_order_value), 0) AS avg_order_value,
    SUM(CASE WHEN c.loyalty_segment = 'Champion' THEN 1 ELSE 0 END)  AS champions,
    SUM(CASE WHEN c.loyalty_segment = 'Lost'     THEN 1 ELSE 0 END)  AS lost_customers,
    ROUND(SUM(CASE WHEN c.loyalty_segment = 'Champion' THEN 1 ELSE 0 END)
        / COUNT(*) * 100, 1) AS champion_rate_pct
FROM customers c
GROUP BY c.acquisition_channel
ORDER BY avg_ltv_inr DESC;


-- Q15. City-Tier Revenue Mix and AOV Benchmarks
--      Purpose: Inform regional allocation strategy and geographic expansion.
-- ─────────────────────────────────────────────────────────────────────────────
SELECT c.city_tier, c.city,
    COUNT(DISTINCT o.order_id) AS orders,
    ROUND(SUM(o.revenue_inr) / 100000, 2) AS revenue_lakhs,
    ROUND(AVG(o.selling_price), 0) AS avg_order_value,
    ROUND(AVG(o.discount_pct), 1) AS avg_discount_pct,
    COUNT(DISTINCT o.customer_id) AS unique_buyers
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'Delivered'
GROUP BY c.city_tier, c.city
ORDER BY c.city_tier, revenue_lakhs DESC;


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 4: PRICING, MARGINS & DISCOUNTING
-- ─────────────────────────────────────────────────────────────────────────────

-- Q16. Margin Erosion by Discount Band
--      Purpose: Quantify the gross profit impact of deep discounting.
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    CASE WHEN discount_pct = 0 THEN '0% (No Discount)'
        WHEN discount_pct BETWEEN 1  AND 10  THEN '1–10%'
        WHEN discount_pct BETWEEN 11 AND 20  THEN '11–20%'
        WHEN discount_pct BETWEEN 21 AND 30  THEN '21–30%'
        ELSE '30%+'
    END AS discount_band,
    COUNT(DISTINCT order_id) AS orders,
    SUM(quantity) AS units_sold,
    ROUND(SUM(revenue_inr) / 100000, 2) AS revenue_lakhs,
    ROUND(AVG(gross_margin_pct), 1) AS avg_gross_margin_pct,
    ROUND(SUM(gross_profit_inr) / 100000, 2) AS gross_profit_lakhs
FROM orders
WHERE order_status = 'Delivered'
GROUP BY discount_band
ORDER BY MIN(discount_pct);


-- Q17. Price Elasticity Proxy — Revenue vs Discount by Category
--      Purpose: Estimate demand sensitivity and optimal discount floors.
-- ─────────────────────────────────────────────────────────────────────────────
SELECT category,
    ROUND(AVG(discount_pct), 1) AS avg_discount_pct,
    ROUND(AVG(selling_price), 0) AS avg_selling_price,
    SUM(quantity) AS units_sold,
    ROUND(SUM(revenue_inr) / 100000, 2) AS revenue_lakhs,
    ROUND((COUNT(*) * SUM(discount_pct * quantity) - SUM(discount_pct) * SUM(quantity)) /
        SQRT((COUNT(*) * SUM(discount_pct * discount_pct) - SUM(discount_pct) * SUM(discount_pct))
            * (COUNT(*) * SUM(quantity * quantity) - SUM(quantity) * SUM(quantity))),3)                                                                    AS discount_qty_correlation
FROM orders
WHERE order_status = 'Delivered'
GROUP BY category
ORDER BY discount_qty_correlation DESC;

-- Q18. Licensed vs Non-Licensed Margin Comparison
--      Purpose: Evaluate whether royalty costs on licensed IP justify the margin tradeoff.
-- ─────────────────────────────────────────────────────────────────────────────
SELECT p.is_licensed,
    COUNT(DISTINCT o.order_id) AS orders,
    SUM(o.quantity) AS units_sold,
    ROUND(AVG(p.mrp), 0) AS avg_mrp,
    ROUND(AVG(p.gross_margin_pct), 1) AS avg_product_margin_pct,
    ROUND(AVG(o.discount_pct), 1) AS avg_discount_pct,
    ROUND(AVG(o.gross_margin_pct), 1) AS avg_realised_margin_pct,
    ROUND(SUM(o.revenue_inr) / 100000, 2) AS revenue_lakhs,
    ROUND(SUM(o.gross_profit_inr) / 100000, 2) AS gross_profit_lakhs
FROM orders o
JOIN products p ON o.product_id = p.product_id
WHERE o.order_status = 'Delivered'
GROUP BY p.is_licensed;


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 5: SEASONALITY, TRENDS & FORECASTING SUPPORT
-- ─────────────────────────────────────────────────────────────────────────────

-- Q19. Seasonality Index — Monthly Revenue vs Annual Average
--      Purpose: Identify high/low-demand months to inform production planning.
-- ─────────────────────────────────────────────────────────────────────────────
WITH monthly AS (
    SELECT month, month_name,
        ROUND(AVG(revenue_inr) / 100000, 2) AS avg_monthly_rev_lakhs
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY month, month_name
),
annual_avg AS (
    SELECT AVG(avg_monthly_rev_lakhs) AS annual_monthly_avg FROM monthly
)
SELECT m.month, m.month_name, m.avg_monthly_rev_lakhs, a.annual_monthly_avg,
    ROUND(m.avg_monthly_rev_lakhs / a.annual_monthly_avg, 3) AS seasonality_index,
    CASE
        WHEN m.avg_monthly_rev_lakhs / a.annual_monthly_avg > 1.2 THEN 'Peak'
        WHEN m.avg_monthly_rev_lakhs / a.annual_monthly_avg < 0.85 THEN 'Trough'
        ELSE 'Normal'
    END AS demand_label
FROM monthly m, annual_avg a
ORDER BY m.month;


-- Q20. YoY Category Growth — 2023 vs 2024
--      Purpose: Identify fastest-growing and declining fandoms for buying focus.
-- ─────────────────────────────────────────────────────────────────────────────
WITH cat_year AS (
    SELECT category, year,
        ROUND(SUM(revenue_inr) / 100000, 2) AS revenue_lakhs,
        SUM(quantity) AS units_sold
    FROM orders
    WHERE order_status = 'Delivered'
      AND year IN (2023, 2024)
    GROUP BY category, year
)
SELECT a.category, a.revenue_lakhs AS rev_2023, b.revenue_lakhs AS rev_2024,
    ROUND((b.revenue_lakhs - a.revenue_lakhs) / NULLIF(a.revenue_lakhs, 0) * 100, 1)AS yoy_growth_pct,
    a.units_sold AS units_2023,
    b.units_sold AS units_2024
FROM cat_year a
JOIN cat_year b ON a.category = b.category AND a.year = 2023 AND b.year = 2024
ORDER BY yoy_growth_pct DESC;


-- Q21. 3-Month Rolling Revenue (Moving Average) — for Trend Smoothing
--      Purpose: Remove noise from weekly/monthly spikes for cleaner forecasting input.
-- ─────────────────────────────────────────────────────────────────────────────
WITH monthly_total AS (
    SELECT year, month, month_name, ROUND(SUM(revenue_inr) / 100000, 2) AS revenue_lakhs
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY year, month, month_name
)
SELECT year, month_name, revenue_lakhs,
    ROUND(AVG(revenue_lakhs) OVER (
        ORDER BY year, month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS rolling_3m_avg_lakhs,
    ROUND(SUM(revenue_lakhs) OVER ( PARTITION BY year ORDER BY month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 2) AS ytd_revenue_lakhs
FROM monthly_total
ORDER BY year, month;


-- Q22. Festive Season Performance — Q3 (Oct–Dec) Deep Dive
--      Purpose: Benchmark festive vs non-festive performance for planning.
-- ─────────────────────────────────────────────────────────────────────────────
SELECT year, category, channel,
    COUNT(DISTINCT order_id) AS festive_orders,
    SUM(quantity) AS festive_units,
    ROUND(SUM(revenue_inr) / 100000, 2)AS festive_revenue_lakhs,
    ROUND(AVG(discount_pct), 1) AS avg_discount_pct,
    ROUND(AVG(gross_margin_pct), 1) AS avg_margin_pct
FROM orders
WHERE order_status = 'Delivered' AND month IN (10, 11, 12)
GROUP BY year, category, channel
ORDER BY year, festive_revenue_lakhs DESC;


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 6: MARKETING ROI & RETURNS ANALYSIS
-- ─────────────────────────────────────────────────────────────────────────────

-- Q23. Marketing ROAS by Channel and Quarter
--      Purpose: Evaluate paid media efficiency; rebalance spend towards high-ROAS channels.
-- ─────────────────────────────────────────────────────────────────────────────
SELECT year, quarter, marketing_channel,
    ROUND(SUM(spend_inr_lakhs), 2) AS total_spend_lakhs,
    ROUND(SUM(attributed_revenue_lakhs), 2) AS attributed_revenue_lakhs,
    ROUND(SUM(attributed_revenue_lakhs) / NULLIF(SUM(spend_inr_lakhs), 0), 2) AS blended_roas,
    ROUND(AVG(cac_inr), 0) AS avg_cac_inr,
    SUM(conversions) AS total_conversions
FROM marketing_spend
GROUP BY year, quarter, marketing_channel
ORDER BY year, quarter, blended_roas DESC;


-- Q24. Return Rate Analysis by Category and Channel
--      Purpose: Identify quality/fit issues causing returns — reduce operational cost.
-- ─────────────────────────────────────────────────────────────────────────────
SELECT category, channel,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(CASE WHEN is_returned THEN 1 ELSE 0 END) AS returned_orders,
    ROUND(SUM(CASE WHEN is_returned THEN 1 ELSE 0 END) / NULLIF(COUNT(DISTINCT order_id), 0) * 100, 1) AS return_rate_pct,
    ROUND(SUM(CASE WHEN is_returned THEN revenue_inr ELSE 0 END) / 100000, 2) AS returned_revenue_lakhs,
    ROUND(AVG(CASE WHEN is_returned THEN selling_price END), 0) AS avg_returned_order_value
FROM orders
GROUP BY category, channel
ORDER BY return_rate_pct DESC;


-- Q25. Executive KPI Summary Dashboard View
--      Purpose: Single-query snapshot for leadership reporting automation.
-- ─────────────────────────────────────────────────────────────────────────────
SELECT o.year,
    -- Revenue
    ROUND(SUM(o.revenue_inr) / 100000, 2) AS net_revenue_lakhs,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(AVG(o.selling_price), 0) AS aov_inr,
    -- Margin
    ROUND(AVG(o.gross_margin_pct), 1) AS avg_gross_margin_pct,
    ROUND(AVG(o.discount_pct), 1) AS avg_discount_pct,
    -- Volume
    SUM(o.quantity) AS units_sold,
    -- Returns
    ROUND(SUM(CASE WHEN o.is_returned THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) * 100, 1) AS return_rate_pct,
    -- Customers
    COUNT(DISTINCT o.customer_id) AS unique_buyers,
    ROUND(COUNT(DISTINCT o.order_id) * 1.0 / NULLIF(COUNT(DISTINCT o.customer_id), 0), 2) AS orders_per_customer,
    -- Marketing ROAS (joined)
    ROUND(SUM(m.attributed_revenue_lakhs) / NULLIF(SUM(m.spend_inr_lakhs), 0), 2)    AS blended_roas,
    -- Top Category
    (SELECT category FROM orders
     WHERE order_status='Delivered' AND year = o.year
     GROUP BY category ORDER BY SUM(revenue_inr) DESC LIMIT 1) AS top_category_by_rev
FROM orders o
LEFT JOIN (
    SELECT year, SUM(attributed_revenue_lakhs) AS attributed_revenue_lakhs, SUM(spend_inr_lakhs) AS spend_inr_lakhs
    FROM marketing_spend GROUP BY year
) m ON o.year = m.year
WHERE o.order_status = 'Delivered'
GROUP BY o.year
ORDER BY o.year;
