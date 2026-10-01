# Applying the analysis to the agricultural machinery business

This guide explains how to rerun the project with the sales data of the agricultural machinery business once its sales system can export it. The logic of every notebook stays the same; what changes is how the data is loaded and a few decisions that depend on the business.

## 1. Data needed

The export should have one row per item sold. These are the columns the analysis needs and the Olist column each one replaces:

| Business column | Required | Replaces in Olist | Used in |
|---|---|---|---|
| Sale date | Yes | `order_purchase_timestamp` | Every phase |
| Invoice or sale number | Yes | `order_id` | Grouping items into purchases |
| Customer ID or name | Yes | `customer_unique_id` | Phase 6 and customer counts |
| Customer town or rural area | Yes | `customer_city`, `customer_state` | Phase 5 |
| Item code and name | Yes | `product_id` | Phases 3 and 4 |
| Item category (tractors, implements, spare parts...) | Yes | `product_category_name` | Phases 3 and 4 |
| Quantity | Yes | one row per unit in Olist | Units sold |
| Sale price | Yes | `price` | Revenue |
| Item cost | Recommended | not available in Olist | ABC by margin (Phase 3) |
| Delivery or installation date | Optional | `order_delivered_customer_date` | Service indicators (Phases 5 and 6) |
| Payment method and installments | Optional | `payment_type`, `payment_installments` | Phase 6 features |

Two conditions matter more than any column:

- **One identifier per customer.** If the same farmer appears under different names or codes, the repeat purchase analysis will undercount returning customers, which is the same trap as `customer_id` in Olist.
- **Complete periods.** Export whole months and check the last weeks of the export, as Phase 1 does, before trusting the most recent data.

## 2. Loading the data (Phase 1)

Replace the loading and cleaning sections of `01_data_cleaning.ipynb` with the business export, and build the same two tables with the same column names:

- `items_clean`: one row per item line, with `quantity` and `price`. Unlike Olist, the business data has a quantity column, so units are the sum of `quantity` and revenue is `quantity × price`.
- `orders_clean`: one row per sale, with its date, customer, location, units, revenue and, if available, delivery information.

Keep the checks: `validate` in every join, the cleaning log and the final `assert` block. Then save the CSV files and the SQLite database as the notebook does now, so the SQL queries in `sql/` work without changes.

For the maps in Phase 5, Olist gives coordinates by zip code. For the business, prepare a small table with the latitude and longitude of each town or rural area where customers live; it only has to be built once.

## 3. Adjustments by phase

| Phase | What changes for the machinery business |
|---|---|
| 2 · Exploratory analysis | Nothing structural. Seasons are expected to follow planting and harvest, so compare the monthly pattern with the agricultural calendar of the region. |
| 3 · Products | Run the ABC classification by margin as well as by revenue if item costs are available. Analyze machines and spare parts separately: a single tractor can outweigh hundreds of spare parts in revenue. |
| 4 · Forecast and inventory | Forecast spare parts and small implements, which sell steadily. Tractors and large implements have intermittent demand and are better handled by order. Use the real supplier lead time: with a lead time of L months, multiply the safety stock by the square root of L. With at least two years of data, add Holt-Winters and SARIMA to the comparison. |
| 5 · Locations | The areas are towns or rural areas instead of Brazilian states. Demand is the number of customers or sales per area; the service gap is the distance and travel time from the current store and the response time for spare parts and repairs. Agree on the weights with the owners before looking at the ranking, and add the costs of opening a branch before deciding. |
| 6 · Customers | Machines are bought every few years, so measure churn on spare parts and service purchases, with a window of 6 to 12 months. Keep the same safeguards: a prediction moment, features known at that moment and a temporal validation. If repeat purchases are common, the RFM segmentation discarded for Olist becomes useful. |

## 4. Checklist before presenting results

- [ ] Every customer has a single identifier.
- [ ] The first and last months of the export are complete.
- [ ] The final checks of `01_data_cleaning.ipynb` pass.
- [ ] Forecasts were compared with simple baselines, and the chosen model beats them.
- [ ] The branch criteria and weights were written down before looking at the ranking.
- [ ] The churn window fits the purchase cycle of the items analyzed.
- [ ] Every recommendation states its limitations and is presented as an association, not a cause.
