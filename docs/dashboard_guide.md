# Power BI dashboard: build guide

The dashboard has one page per business question. Every page follows the same layout: the business question as the title, the main insight as a subtitle, three or four visuals and the filters in a single row at the top.

## 1. Import the data

**Before importing, set the import locale.** The CSV files use a point as the decimal separator. If Windows is set to a language that uses a comma, Power BI may read `137.04` as `13704`. Go to **File → Options and settings → Options → Current file → Regional settings** and set **Locale for import** to **English (United States)**. This applies to every file loaded afterwards.

Run the six notebooks first, then use **Get data → Text/CSV** to load these files from `data/processed/`:

| File | Used on page |
|---|---|
| `category_summary.csv` | Products |
| `category_monthly.csv` | Products |
| `product_abc.csv` | Products |
| `monthly_sales.csv` | Inventory |
| `forecast_total.csv` | Inventory |
| `forecast_categories.csv` | Inventory |
| `model_comparison.csv` | Inventory |
| `state_scores.csv` | Locations |
| `city_summary.csv` | Locations |
| `churn_dataset.csv` | Customers |
| `customer_return_scores.csv` | Customers |
| `churn_model_metrics.csv` | Customers |

If a numeric column still looks wrong, change its type in Power Query with **Change type → Using locale → English (United States)**.

In Power Query, also set `month` columns to *Date* and `customer_zip_prefix`, `zip_prefix` and `seller_zip_prefix` to *Text*, so the leading zeros are kept.

Apply the project theme (section 5) before building any visual: colors set by hand later override the theme.

## 2. Relationships

In the model view, create these one-to-many relationships:

| From (many) | To (one) |
|---|---|
| `category_monthly[category]` | `category_summary[category]` |
| `product_abc[category]` | `category_summary[category]` |
| `forecast_categories[category]` | `category_summary[category]` |
| `city_summary[customer_state]` | `state_scores[customer_state]` |
| `customer_return_scores[customer_state]` | `state_scores[customer_state]` |

## 3. Measures

Create these measures (Home → New measure). Measure names are not case-sensitive and cannot repeat a column name of their own table, which is why the first two are called `Total revenue` and `Total units` instead of `Revenue` and `Units`.

```DAX
Total revenue = SUM ( category_monthly[revenue] )
Total units = SUM ( category_monthly[units] )
Products = DISTINCTCOUNT ( product_abc[product_id] )
Class A share of products = DIVIDE ( CALCULATE ( [Products], product_abc[abc_class] = "A" ), [Products] )
Slow movers = CALCULATE ( [Products], product_abc[is_slow_mover] = TRUE () )
Customers in cohort = COUNTROWS ( churn_dataset )
Return rate = AVERAGE ( churn_dataset[returned] )
Churn rate = 1 - [Return rate]
```

## 4. Pages

### Page 1 · Products

- **Title:** Which products and categories sell the most and the least?
- **Subtitle:** 25.9% of the products bring in 80% of revenue.
- **Cards:** Total revenue, Products, Class A share of products, Slow movers.
- **Bar chart:** revenue by category (`category_summary`), sorted, top 15.
- **Line chart:** revenue by month (`category_monthly`), with a category slicer.
- **Table:** `category_summary` with revenue share, rank by revenue, rank by units and change in share (`change_pp`), with conditional formatting on `change_pp`.

### Page 2 · Inventory

- **Title:** How much will sell in the next 3 months, and how much inventory is needed?
- **Subtitle:** A 3-month moving average forecasts 7,259 units per month, with a 7.8% error.
- **Line chart:** units per month from `monthly_sales` (complete months only) and the forecast from `forecast_total`, with `lower_units` and `upper_units` as the range. The two tables have no relationship, so first combine them in a calculated table (Modeling → New table) and build the chart from it, with `month` on the X-axis and the four unit columns on the Y-axis:

```DAX
Units timeline =
UNION (
    SELECTCOLUMNS (
        FILTER ( monthly_sales, monthly_sales[is_complete_month] = TRUE () ),
        "month", monthly_sales[month],
        "actual_units", monthly_sales[units],
        "forecast_units", BLANK (),
        "lower_units", BLANK (),
        "upper_units", BLANK ()
    ),
    SELECTCOLUMNS (
        forecast_total,
        "month", forecast_total[month],
        "actual_units", BLANK (),
        "forecast_units", forecast_total[forecast_units],
        "lower_units", forecast_total[lower_units],
        "upper_units", forecast_total[upper_units]
    )
)
```
- **Bar chart:** `rolling_mape_pct` by model from `model_comparison`.
- **Table:** `forecast_categories` for one month, with forecast, safety stock, suggested stock and `wape_pct`, highlighting `wape_pct` above 40% as unreliable.

### Page 3 · Locations

- **Title:** Where do customers come from, and where should a new branch open?
- **Subtitle:** Bahia is the most robust candidate, and Salvador the best-supported city.
- **Map:** bubble map of `state_scores` by `customer_state`, with bubble size = customers and `score` in the tooltip.
- **Bar chart:** `score` of the top 10 states.
- **Scatter chart:** `median_distance_km` against `median_delivery_days`, one point per state, size = customers.
- **Table:** the largest cities of the top states from `city_summary`.

### Page 4 · Customers

- **Title:** Why do some customers not come back, and who is about to leave?
- **Subtitle:** 98.25% of customers do not come back within 180 days of their first purchase.
- **Cards:** Customers in cohort, Churn rate, ROC AUC of the random forest (from `churn_model_metrics`).
- **Bar charts:** Return rate by `region` and by `is_late` (`churn_dataset`).
- **Donut or bar chart:** recent customers by `risk_group` (`customer_return_scores`), with a region slicer.

## 5. Style

Apply the project theme first: **Design → Import theme** (in older versions of Power BI Desktop, **View → Themes → Browse for themes**) and select `dashboard/theme.json`. It sets the colors and fonts of every visual. The theme uses the same colors as the notebooks, so the dashboard and the report look like one project:

| Role | Color |
|---|---|
| Main data | `#2a78d6` |
| Second series | `#eb6834` |
| Context and incomplete data | `#898781` |
| Gridlines | `#e1e0d9` |
| Text | `#0b0b0b` and `#52514e` |

Keep one axis per chart, label only the values that matter and leave gridlines light.

## 6. Screenshots

Export one image per page (**File → Export → Export to PDF**, or a screenshot) and save them in `dashboard/screenshots/` as `01_products.png`, `02_inventory.png`, `03_locations.png` and `04_customers.png`. Then add them to the Dashboard section of the README.
