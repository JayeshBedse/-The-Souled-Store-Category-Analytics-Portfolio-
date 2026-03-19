The Souled Store — Category Analytics Portfolio Project  
Author: Jayesh Bedse
Tools Demonstrated: Python (pandas · numpy · matplotlib · seaborn) · SQL
---
Project Overview
This project simulates the end-to-end Category analytics workflow at The Souled Store — India's leading pop-culture merchandise brand. 
The dataset, queries, and visualisations are structured around sell-through optimisation, inventory health monitoring, margin analysis, channel performance, and seasonality-driven forecasting support.
All data is synthetically generated to mirror TSS's real business model — D2C + Amazon + Flipkart + Myntra + Nykaa Fashion + Offline Studio Stores — across 10 fandom categories (Marvel, DC, Friends, Anime, Harry Potter, Music, Movies & TV, Sports, Basics, Original Art).
---
Dataset Details
1. `orders.csv` — 793 rows
Core transactional table. Each row = one product line within an order.
order_id - Unique order identifier
order_date - Date of order
year / month / quarter - Time dimensions for BI slicing
customer_id	- FK → customers
product_id - FK → products
category - Fandom / product category
channel	- Sales channel
size - XS / S / M / L / XL / XXL
quantity - Units ordered
mrp	- Maximum Retail Price
discount_pct - % discount applied
selling_price - Net price after discount
revenue_inr	- Total line revenue
gross_profit_inr - Revenue minus COGS
gross_margin_pct - Gross margin as %
order_status - Delivered / Cancelled / Returned
is_returned - 	Boolean flag
payment_method - UPI / Card / COD / Wallet
Key metrics derivable: Monthly revenue · AOV · Category mix · Return rate · Discount depth
---
2. `products.csv` — 150 SKUs
Master SKU catalogue with margin structure.
product_id	- TSS-XXXX format
product_name	- Design + Product Type
category	- Fandom category
product_type	- Oversized T-Shirt / Hoodie / Joggers etc.
gender	- Men / Women / Unisex / Kids
mrp	- Listed price
cost_price	- COGS per unit
gross_margin_pct	- (MRP - Cost) / MRP × 100
launch_date	- SKU introduction date
is_licensed	- Whether design is licensed IP
fabric / fit	- Product attributes
---
3. `customers.csv` — 300 rows
Customer master with behavioural attributes.
customer_id	- CUST-XXXX
city / state / city_tier	- Geographic segmentation
acquisition_channel	- How customer was acquired
total_orders / total_spend_inr	- Lifetime behaviour
loyalty_segment	- Champion / Loyal / Potential Loyalist / Recent / At Risk / Lost
preferred_category	- Primary fandom
preferred_size - 	Dominant size purchased
---
4. `inventory.csv` — 900 rows (150 SKUs × 6 sizes)
Snapshot inventory at 30-Nov-2024. Critical for stock health and reorder decisions.
opening_stock	- Units at period start
units_received	- Replenishment received
units_sold	- Units dispatched
closing_stock	- Current live inventory
sell_through_pct	- % of available stock sold
rate_of_sale_per_week	- Avg weekly velocity
weeks_of_cover	- Weeks until stockout at current ROS
stock_health_status	- Healthy / Low Stock / Stockout / Overstocked / Normal
reorder_recommended	- Boolean trigger
---
5. `marketing_spend.csv` — 252 rows
Monthly spend and attributed revenue across 7 marketing channels.
Channels: Meta Ads · Google Ads · Influencer Marketing · Email/WhatsApp · Affiliate · SEO/Content · Offline/Events
Key metrics: `spend_inr_lakhs` · `attributed_revenue_lakhs` · `roas` · `cac_inr` · `conversions`
---
6. `channel_revenue_monthly.csv` — 216 rows
Monthly GMV and order metrics per sales channel (2022–2024).
Key metrics: `gmv_lakhs` · `net_revenue_lakhs` · `total_orders` · `avg_order_value_inr` · `return_rate_pct` · `discount_rate_pct`
---
SQL Queries — 25 Business Queries
File: `sql/tss_category_analytics.sql`
Sales Performance & Revenue -	Q1–Q5	Sales insights, MoM/YoY tracking
Inventory Health	- Q6–Q10 Allocation, reorder, size curves
Customer Behaviour	- Q11–Q15	Segment analysis, city-tier mix
Pricing & Margins	- Q16–Q18	Margin optimisation, discount bands
Seasonality & Forecasting	- Q19–Q22	Trend smoothing, festive planning
Marketing & Returns	- Q23–Q25	ROAS tracking, return cost analysis
Highlights:
Q7 — Overstock alert with markdown loss estimation
Q8 — Priority-ranked reorder list (P1/P2/P3)
Q9 — Size curve by category for OTB planning
Q11 — Full RFM scoring with NTILE-based segmentation
Q21 — 3-month rolling average for forecasting input
Q25 — Executive KPI summary — single-query dashboard view

Python EDA — 14 Visualisations

#	Chart	Business Question Answered
01	Monthly Revenue Trend (2022–2024)	- Is growth consistent? When do sales peak?
02	Category Revenue vs Gross Margin %	- Which fandoms drive profit vs just revenue?
03	Channel Revenue Mix (Stacked %)	- How is channel dependency shifting YoY?
04	Sell-Through Heatmap (Cat × Type)	- Which category-type combos move fastest?
05	Inventory Health Donut	- What % of stock is at risk (stockout/overstock)?
06	Size Curve — Units vs Sell-Through	- Are we buying the right size ratios?
07	Top 15 SKUs by Revenue	- What are our hero products?
08	Discount vs Gross Margin Scatter	- Where is discounting hurting margins most?
09	Customer Loyalty Segment Breakdown	- What does our customer quality look like?
10	Seasonality Index by Month	- Which months are peak, normal, trough?
11	Marketing ROAS by Channel (2024)	- Which paid channels deserve more budget?
12	Return Rate Heatmap (Cat × Channel)	- Where do returns erode operational efficiency?
13	YoY Category Growth (2023 vs 2024)	- Which fandoms are accelerating vs declining?
14	Executive KPI Summary Dashboard	- One-page snapshot for leadership reporting
---
Key Business Insights from the Data
Festive Quarter (Oct–Dec) drives ~38% of annual revenue — inventory build-up strategy is critical 3 months prior.
Marvel and Anime show the highest sell-through rates but lowest margin (licensed royalties compress gross margin by ~8–12 pp vs Basics/Original Art).
Myntra has the highest discount rate (avg ~15%) but only ranks 4th in revenue — net margin impact needs assessment.
M and L account for ~58% of units sold — size ratio imbalance in buying leads to XS/XXL overstock.
Email/WhatsApp delivers the best ROAS (6.5×) at the lowest spend — under-invested relative to Meta Ads.
Hoodie sell-through spikes in Q3 (Oct–Dec) — forward buying by August is critical to avoid stockouts during peak demand.
Champion customers (top loyalty tier) generate 3.8× the LTV of Average customers — retention economics favour CRM investment over pure acquisition spend.
---
About This Project
This portfolio project was created to demonstrate the analytical capabilities relevant to the Associate Category Analyst role at The Souled Store. The data is synthetic but calibrated to reflect realistic business patterns — revenue scale, margin structures, seasonal dynamics, and inventory metrics are based on publicly available information about TSS.
Skills demonstrated: Data modelling · SQL window functions · Inventory KPIs (ROS, sell-through, WOC) · Customer segmentation (RFM) · Marketing attribution (ROAS/CAC) · Python EDA · BI dashboard design · Business storytelling through data.
