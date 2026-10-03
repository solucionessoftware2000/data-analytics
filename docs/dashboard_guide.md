# Power BI dashboard: build guide

The dashboard has one page per business question: **Products**, **Inventory**, **Locations** and **Customers**. Every page follows the same layout: the business question as the title, the main insight as the subtitle and three or four visuals below.

This guide explains how to open the finished dashboard and how to rebuild it from scratch, step by step. Rebuilding it takes about three hours the first time. Every step ends with a **Check**: a value or a picture that must appear before moving on. If a check fails, stop there and see [Troubleshooting](#7-troubleshooting).

## Contents

1. [Open the finished dashboard](#1-open-the-finished-dashboard)
2. [Prepare the file](#2-prepare-the-file)
3. [Build the data model](#3-build-the-data-model)
4. [Basic operations used on every page](#4-basic-operations-used-on-every-page)
5. [Build the pages](#5-build-the-pages)
6. [Export the screenshots](#6-export-the-screenshots)
7. [Troubleshooting](#7-troubleshooting)

## 1. Open the finished dashboard

The repository includes the dashboard in two formats:

| File | What it is |
|---|---|
| `dashboard/sales_dashboard.pbix` | The usual Power BI file, with the data included. Open it with a double click. |
| `dashboard/sales_dashboard.pbip` | The same dashboard as a Power BI project: every page and visual is a JSON file and every table and measure a text file, so changes can be reviewed in Git. |

Both open in **Power BI Desktop** (free, from the Microsoft Store). To load your own copy of the data:

1. Run the six notebooks so that `data/processed/` contains the CSV files.
2. Open the dashboard and go to **Home → Transform data → Data source settings**.
3. For each file, select it, choose **Change source** and point it to the same file in your `data/processed/` folder.
4. Close the window and click **Home → Refresh**.

**Check:** on the Products page, the first card shows **13,179,778**.

## 2. Prepare the file

### 2.1 Requirements

- Power BI Desktop installed.
- The six notebooks run, so `data/processed/` contains the CSV files listed in 2.3.

The menu names below are those of the English version of Power BI Desktop. In other languages the options are in the same places.

### 2.2 Set the import locale

The CSV files use a point as the decimal separator. If Windows uses a comma, Power BI may read `137.04` as `13704` without any warning.

1. Open Power BI Desktop and start a blank report.
2. Go to **File → Options and settings → Options → Current file → Regional settings**.
3. Set **Locale for import** to **English (United States)** and click **OK**.

This must be done **before** importing any file.

### 2.3 Import the 12 CSV files

Use **Home → Get data → Text/CSV** once per file and click **Load** in each preview:

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

Load only these 12. The clean tables from Phase 1 (`orders_clean`, `items_clean` and the others) are not used by the dashboard, and loading them adds automatic relationships that confuse the visuals.

**Check:** open the **Table view** (second icon on the left bar), select `category_summary` and find the row **Health beauty**. `revenue` must be **1229557.5** and `avg_price` about **130.5**. A number without a decimal separator, such as 12295575, means the locale of step 2.2 was not applied: delete the tables, apply it and import again.

### 2.4 Apply the theme

The theme sets the colors and fonts of every visual, so it goes before building any visual. Colors set by hand afterwards override the theme.

1. Go to **View → Themes → Browse for themes**. In recent versions the option is **Design → Import theme**.
2. Select `dashboard/theme.json`.

The theme uses the same colors as the notebooks:

| Role | Color |
|---|---|
| Main data | `#2a78d6` (blue) |
| Second series | `#eb6834` (orange) |
| Context and incomplete data | `#898781` (gray) |
| Losses and warnings | `#e34948` (red) |
| Text | `#0b0b0b` and `#52514e` |

### 2.5 Check the page size

The positions in this guide assume pages of **1920 × 1080** pixels. Click an empty area of the page, open the **Format** pane (paint brush icon in **Visualizations**) and check **Canvas settings**. If the size is different, choose **Custom** and type 1920 and 1080.

### 2.6 Save the file

Save it as `dashboard/sales_dashboard.pbix` and press **Ctrl+S** after every page.

## 3. Build the data model

### 3.1 Relationships

Relationships let a filter on one table reach another: choosing a category on the Products page also filters its monthly sales and its products.

1. Go to **Modeling → Manage relationships**.
2. Delete every relationship that is not in the table below. Power BI creates some automatically when two columns share a name.
3. Create the missing ones with **New relationship**: choose the first table and column, then the second table and column, set **Cardinality** to **Many to one (\*:1)** and **Cross filter direction** to **Single**.

| From (many) | To (one) |
|---|---|
| `category_monthly[category]` | `category_summary[category]` |
| `product_abc[category]` | `category_summary[category]` |
| `forecast_categories[category]` | `category_summary[category]` |
| `city_summary[customer_state]` | `state_scores[customer_state]` |
| `customer_return_scores[customer_state]` | `state_scores[customer_state]` |

**Check:** the window lists exactly these 5 relationships, all *Many to one* and *Active*. If Power BI proposes *One to one* or *Many to many* for any of them, the data was not loaded correctly.

### 3.2 Measures

A measure is a calculation that Power BI recomputes with the filters of each visual. To create one:

1. In the **Data** pane, click the name of the table where the measure goes.
2. Click **Home → New measure**. A formula bar appears above the page.
3. Without clicking anywhere else, press **Ctrl+A**, paste the formula and press **Enter**.

If you click outside the formula bar before pressing Enter, the bar closes and the empty measure disappears. Start again from step 1.

A measure cannot have the same name as a column of its own table, and Power BI ignores upper and lower case. That is why the revenue measure is called `Total revenue`: the table already has a column called `revenue`.

**Base measures**

| Table | Formula | Format |
|---|---|---|
| `category_monthly` | `Total revenue = SUM ( category_monthly[revenue] )` | |
| `category_monthly` | `Total units = SUM ( category_monthly[units] )` | |
| `product_abc` | `Products = DISTINCTCOUNT ( product_abc[product_id] )` | |
| `product_abc` | `Class A share of products = DIVIDE ( CALCULATE ( [Products], product_abc[abc_class] = "A" ), [Products] )` | Percentage |
| `product_abc` | `Slow movers = CALCULATE ( [Products], product_abc[is_slow_mover] = TRUE () )` | |
| `churn_dataset` | `Customers in cohort = COUNTROWS ( churn_dataset )` | |
| `churn_dataset` | `Return rate = AVERAGE ( churn_dataset[returned] )` | Percentage |
| `churn_dataset` | `Churn rate = 1 - [Return rate]` | Percentage |
| `customer_return_scores` | `Recent customers = COUNTROWS ( customer_return_scores )` | |

To format a measure as a percentage, select it in the **Data** pane and click the **%** button in **Measure tools**.

**Card measures**

The card visual abbreviates numbers (32,079 becomes "32K"). These measures turn the values into text with the exact figure and English separators, and their names become the card labels:

| Table | Formula |
|---|---|
| `category_monthly` | `Revenue (R$) = FORMAT ( [Total revenue], "#,0", "en-US" )` |
| `product_abc` | `Products sold = FORMAT ( [Products], "#,0", "en-US" )` |
| `product_abc` | `Class A products (80% of revenue) = FORMAT ( [Class A share of products], "0.0%", "en-US" )` |
| `product_abc` | `Slow-moving products = FORMAT ( [Slow movers], "#,0", "en-US" )` |
| `churn_dataset` | `Customers analyzed = FORMAT ( [Customers in cohort], "#,0", "en-US" )` |
| `churn_dataset` | `Did not come back within 180 days = FORMAT ( [Churn rate], "0.00%", "en-US" )` |
| `churn_model_metrics` | `Model ROC AUC (random forest) = FORMAT ( CALCULATE ( MAX ( churn_model_metrics[roc_auc] ), churn_model_metrics[model] = "Random forest" ), "0.000", "en-US" )` |
| `churn_model_metrics` | `Returners found in the top 10% = FORMAT ( CALCULATE ( MAX ( churn_model_metrics[top_10pct_capture] ), churn_model_metrics[model] = "Random forest" ), "0.0%", "en-US" )` |

If a formula fails because of the commas, your installation uses semicolons as list separators: replace every `,` between arguments with `;`. If `Slow movers` returns an error, replace `TRUE ()` with `"True"`.

**Check:** drag each measure onto an empty card (section 4.1). The expected values are:

| Measure | Value |
|---|---|
| Revenue (R$) | 13,179,778 |
| Products sold | 32,079 |
| Class A products (80% of revenue) | 25.9% |
| Slow-moving products | 6,707 |
| Customers analyzed | 49,936 |
| Did not come back within 180 days | 98.25% |
| Model ROC AUC (random forest) | 0.571 |
| Returners found in the top 10% | 15.0% |

### 3.3 Calculated column

The delivery chart needs readable labels instead of 1 and 0. Select `churn_dataset`, click **Modeling → New column** and paste:

```DAX
delivery_status = IF ( churn_dataset[is_late] = 1, "Late", "On time" )
```

### 3.4 Calculated table for the forecast chart

The forecast chart shows actual sales (`monthly_sales`) and the forecast (`forecast_total`) on one timeline. They are separate tables with no relationship, so this formula stacks them into a new table: the first part takes the 19 complete months of actual sales, the second the three forecast months, and `BLANK ()` leaves empty the columns that do not apply to each part.

Click **Modeling → New table** and paste:

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

**Check:** in the Table view, `Units timeline` has 22 rows: July 2018 has `actual_units` = 6960, and August to October 2018 have `forecast_units` = 7259, `lower_units` = 6034.01 and `upper_units` = 8483.99.

## 4. Basic operations used on every page

These operations repeat on every page. The page instructions refer to them by number.

### 4.1 Add a visual and its fields

1. Click an **empty area** of the page, so that no visual is selected.
2. In the **Visualizations** pane, click the visual type. Hover over an icon to see its name.
3. With the new visual selected, **tick the fields** in the **Data** pane, or drag each field to its well in **Build visual** (the first icon of the Visualizations pane).

Ticking a field adds it **inside** the selected visual. Dragging a field to the **Filters** pane adds it as a filter that does not show in the visual. When several fields have to go to specific wells (X-axis, Y-axis, Size), drag them instead of ticking them.

### 4.2 Use a date as a date, not as a hierarchy

When a date column goes to an axis, Power BI turns it into a hierarchy (Year, Quarter, Month, Day) and the chart shows one point per year. In the well, open the arrow next to the field and choose the **field name** instead of **Date hierarchy**.

### 4.3 Rename a field inside a visual

Double click the field in its well, type the new name and press **Enter**. Only the visual changes; the column keeps its name.

### 4.4 Size and position

Select the visual, open **Format** (paint brush) → **General** → **Properties** and type **Height**, **Width**, **Horizontal** and **Vertical** in pixels. Each page has a table with these values.

### 4.5 Title

**Format → General → Title**: turn it on and type the text. The project theme hides the automatic subtitle, which repeats the field names in the language of Power BI. If a subtitle still appears, turn **Subtitle** off in the same section.

### 4.6 Color rules

Conditional formatting colors a value according to a rule, for example red when an error is above 40%.

1. Open the rule window. For a table column: arrow next to the field in **Build visual** → **Conditional formatting** → **Font color**. For the bars of a chart: **Format → Visual → Bars → Color → fx**.
2. Set **Format style** to **Rules** and check that **What field should we base this on?** is the numeric field, not a text field.
3. Each rule reads *If value [operator] [number] and [operator] [number] then [color]*. Choose **Number** in both type boxes, never **Percent**: Percent means a position between the minimum and the maximum, not the value. An empty box means the minimum or the maximum.
4. Pick the color with **More colors** and type the hex code.

### 4.7 Filters on one visual

Select the visual and use the **Filters** pane → **Filters on this visual**. Power BI adds a card for every field of the visual, showing *is (All)*: they filter nothing until you set them. Three filter types are used here:

- **Basic filtering:** tick the values to keep. Untick **Require single selection** to keep more than one.
- **Advanced filtering:** a condition such as *is greater than or equal to 30*, then **Apply filter**.
- **Top N:** keep the first N items by a value, then **Apply filter**.

### 4.8 Clear a selection

Clicking a bar, a point, a row or a map bubble filters the other visuals of the page, and the rest of the visual turns pale. Click the same element again to clear it. Clear every selection before saving or taking screenshots.

### 4.9 Title box of each page

Use **Insert → Text box**, type the question on the first line and the insight on the second, center both lines, set the first to **bold, 28 pt** and the second to **20 pt**. Once the first page is done, copy its text box (**Ctrl+C**) and paste it on every new page (**Ctrl+V**), then change the text.

## 5. Build the pages

Create each page with the **+** button at the bottom and rename it with a double click on its tab.

### 5.1 Page 1 · Products

**Title box** (4.9):

> Which products and categories sell the most and the least?
> 25.9% of the products bring in 80% of revenue.

**Cards.** Four **Card** visuals, each with one measure in the **Data** well:

| Card | Measure | Check |
|---|---|---|
| 1 | `Revenue (R$)` | 13,179,778 |
| 2 | `Products sold` | 32,079 |
| 3 | `Class A products (80% of revenue)` | 25.9% |
| 4 | `Slow-moving products` | 6,707 |

**Category slicer.** A **Slicer** with `category_summary[category]`, renamed *Category* (4.3). In **Format → Visual → Slicer settings → Options**, set **Style** to **Dropdown**.

*Check:* choosing **Toys** changes every visual of the page, and the monthly line shows a peak in December 2017. Choose **All** again afterwards.

**Revenue by category.** A **Stacked bar chart**:

1. `category_summary[category]` in **Y-axis**, renamed *Category*. `category_summary[revenue]` in **X-axis**, renamed *Revenue (R$)*.
2. Only the 15 first categories (4.7): on the *category* card, choose **Top N**, show **Top 15**, drag `category_summary[revenue]` to **By value** and click **Apply filter**.
3. Title: *Revenue by category (top 15)*.

*Check:* 15 blue bars, from Health beauty at the top down to Office furniture.

**Revenue per month.** A **Line chart**:

1. `category_monthly[month]` in **X-axis**, as a date and not as a hierarchy (4.2). The measure `Total revenue` in **Y-axis**.
2. Leave out August 2018, which is incomplete: drag `category_monthly[is_complete_month]` to **Filters on this visual** and tick only **True**.
3. Title: *Revenue per month (complete months)*.

*Check:* the line rises during 2017, peaks in November 2017 (Black Friday) and levels off in 2018. The filter card shows True with 1,406 rows (74 categories × 19 months).

**Category table.** A **Table**:

1. Tick, in this order, from `category_summary`: `category`, `revenue_pct`, `rank_by_revenue`, `rank_by_units` and `change_pp`. Rename them *Category*, *Revenue share (%)*, *Rank by revenue*, *Rank by units* and *Change in share (pp)*.
2. **Format → Visual → Totals**: turn **Values** off.
3. Color rule on *Change in share (pp)*, font color (4.6): *>= Min and < 0* in red `#e34948`; *>= 0 and <= Max* in blue `#2a78d6`.
4. Sort by *Revenue share (%)* from highest to lowest: click its header until the largest value is at the top.
5. Title: *Categories: revenue share, rank and change in share (2017 to 2018)*.

*Check:* the first row is Health beauty (9.33, rank 1, change 2.00 in blue); Cool stuff shows −3.57 in red. All five columns are visible; if the last one is cut off, make the table wider.

**Positions** (4.4):

| Visual | Height | Width | Horizontal | Vertical |
|---|---|---|---|---|
| Title box | 115 | 1860 | 30 | 10 |
| Card 1 | 170 | 340 | 30 | 140 |
| Card 2 | 170 | 340 | 390 | 140 |
| Card 3 | 170 | 340 | 750 | 140 |
| Card 4 | 170 | 340 | 1110 | 140 |
| Slicer | 90 | 400 | 1490 | 140 |
| Revenue by category | 720 | 520 | 30 | 330 |
| Revenue per month | 720 | 540 | 570 | 330 |
| Category table | 720 | 760 | 1130 | 330 |

### 5.2 Page 2 · Inventory

**Title box:**

> How much will sell in the next 3 months, and how much inventory is needed?
> A 3-month moving average forecasts 7,259 units per month, with a 7.8% error.

**Sales and forecast.** A **Line chart** built from the `Units timeline` table of section 3.4:

1. `month` in **X-axis** as a date (4.2). In **Y-axis**, `actual_units`, `forecast_units`, `lower_units` and `upper_units`, renamed *Actual units*, *Forecast*, *Lower bound* and *Upper bound*.
2. Colors: **Format → Visual → Lines**. In **Series**, choose each series and set its color in **Colors**: Actual units blue `#2a78d6`, Forecast orange `#eb6834`, Lower bound and Upper bound gray `#898781`. For the two bounds, also set **Line style** to **Dashed**.
3. With **Series** set to **All**, some options are grayed out: choose one series first. If a line does not appear, choose that series and check that **Show line** is on.
4. Title: *Units sold per month and forecast (Aug-Oct 2018)*.

*Check:* the blue line ends at 6,960 in July 2018. From August to October there is a flat orange line at 7,259 and two dashed gray lines at 6,034 and 8,484, the forecast range.

**Forecast error by model.** A **Stacked bar chart**:

1. `model_comparison[model]` in **Y-axis**; `model_comparison[rolling_mape_pct]` in **X-axis**, renamed *Forecast error, MAPE (%)*.
2. Best model at the top: **More options (…) → Sort axis → Forecast error, MAPE (%)**, then **Sort axis → Sort ascending**.
3. Color rule on the bars (4.6), based on `rolling_mape_pct`: *>= Min and < 8* in blue `#2a78d6`; *>= 8 and <= Max* in gray `#898781`. The 8 separates the winner (7.8) from the next model (8.74).
4. **Format → Visual → Data labels**: on.
5. Title: *Forecast error by model (rolling evaluation)*.

*Check:* 3-month moving average 7.8 in blue at the top, then Naive 8.7, Holt 14.9 and ARIMA 16.7 in gray.

**Suggested stock table.** A **Table**:

1. Tick, in this order, from `forecast_categories`: `category`, `forecast_per_month`, `safety_stock`, `suggested_monthly_stock` and `wape_pct`. Rename them *Category*, *Forecast per month*, *Safety stock*, *Suggested stock* and *Error, WAPE (%)*.
2. Keep one month. The three forecast months have the same values, so without this filter the table adds them up and shows triple figures. **Drag** (do not tick) `forecast_categories[month]` to **Filters on this visual**, choose **Basic filtering** and tick only August 1, 2018.
3. Totals off.
4. Color rule on *Error, WAPE (%)*, font color: a single rule, *>= 40 and <= Max* in red `#e34948`.
5. Sort by *Error, WAPE (%)* from highest to lowest, so the least reliable categories come first.
6. Title: *Suggested monthly stock by category (red: forecast error of 40% or more)*.

*Check:* 18 rows. Five errors in red: Computers 108.79, Computers accessories 49.71, Toys 49.44, Stationery 48.65 and Office furniture 42.21. Health beauty shows 798.67, 240.34 and 1040.

**Positions:**

| Visual | Height | Width | Horizontal | Vertical |
|---|---|---|---|---|
| Title box | 115 | 1860 | 30 | 10 |
| Sales and forecast | 440 | 1860 | 30 | 140 |
| Forecast error by model | 450 | 760 | 30 | 600 |
| Suggested stock table | 450 | 1080 | 810 | 600 |

### 5.3 Page 3 · Locations

**Title box:**

> Where do customers come from, and where should a new branch open?
> Bahia is the most robust candidate, and Salvador the best-supported city.

**Customer map.** An **Azure map**. If it shows a message saying that map visuals are disabled, turn them on in **File → Options and settings → Options → Global → Security** and restart Power BI.

1. Drag from `city_summary`: `lat` to **Latitude**, `lng` to **Longitude** and `customers` to **Size**. Coordinates are used instead of state codes because a code such as `BA` can be matched to places outside Brazil.
2. Bubble sizes: **Format → Visual → Bubble layer** (called **Marker layer** in recent versions) → **Size**: minimum 2, maximum 25.
3. Whole country in view: **Format → Visual → Map settings → View** → turn on **Auto zoom**.
4. Title: *Where the customers are (one bubble per city)*.

*Check:* the largest bubbles are São Paulo and Rio de Janeiro; Brazil fits in the frame.

**Branch score.** A **Stacked bar chart**:

1. `state_scores[customer_state]` in **Y-axis**, renamed *State*; `state_scores[score]` in **X-axis**, renamed *Branch score (0 to 1)*.
2. Top 10 filter on *customer_state*: **Top N**, **Top 10**, by value `score`, **Apply filter**.
3. Sort by score, descending (**More options → Sort axis**).
4. Color rule on the bars, based on `score`: *>= 0.68 and <= Max* in blue `#2a78d6`; *>= Min and < 0.68* in gray `#898781`.
5. Data labels on. Title: *Branch score of the top 10 states*.

*Check:* BA at the top in blue with 0.69, then MA 0.67, RJ 0.67, PA 0.65 and CE 0.64 in gray.

**Distance and delivery.** A **Scatter chart**. Drag from `state_scores`:

| Field | Well | Rename to |
|---|---|---|
| `customer_state` | Values | |
| `median_distance_km` | X-axis | Median distance to sellers (km) |
| `median_delivery_days` | Y-axis | Median delivery days |
| `customers` | Size | |

Turn on **Format → Visual → Category labels** to show the state codes. Title: *The farther from the sellers, the slower the delivery*.

*Check:* SP is the largest bubble, at the bottom left (164 km, 7 days); AM, AP and RR are at the top right (25 days or more).

**Main city table.** A **Table**:

1. Tick, in this order, from `city_summary`: `customer_city`, `customer_state`, `customers` and `share_of_state_customers_pct`. Rename them *City*, *State*, *Customers* and *Share of state customers (%)*.
2. On the *customer_state* filter card: **Basic filtering**, untick **Require single selection**, tick **BA, CE, MA, PA and RJ** (the five best-scored states).
3. On the *share_of_state_customers_pct* filter card: **Advanced filtering**, *is greater than or equal to* 30, **Apply filter**. This keeps the city that concentrates a large part of its state's customers.
4. Totals off. Sort by *Customers*, descending. Title: *Main city of the five best-scored states*.
5. Stop the map from filtering this table: select the **map**, click **Format → Edit interactions** in the ribbon, click the **None** icon (a circle with a line) over the table and click **Edit interactions** again to finish.

Do not filter this table by `state_scores[rank]`. A numeric field from another table is summed for every city row and, because the relationship only filters from states to cities, the sum covers all 27 states: the condition is never met and the table stays empty.

*Check:* five rows: rio de janeiro 6336, salvador 1154, fortaleza 605, belem 418 and sao luis 325, with shares between 36.55% and 53.29%. City names are lowercase and without accents, as in the Olist data.

**Positions:**

| Visual | Height | Width | Horizontal | Vertical |
|---|---|---|---|---|
| Title box | 115 | 1860 | 30 | 10 |
| Customer map | 910 | 640 | 30 | 140 |
| Branch score | 430 | 590 | 690 | 140 |
| Distance and delivery | 430 | 590 | 1300 | 140 |
| Main city table | 460 | 1200 | 690 | 590 |

### 5.4 Page 4 · Customers

**Title box:**

> Why do some customers not come back, and who is about to leave?
> 98.25% of customers do not come back within 180 days of their first purchase.

**Cards:**

| Card | Measure | Check |
|---|---|---|
| 1 | `Customers analyzed` | 49,936 |
| 2 | `Did not come back within 180 days` | 98.25% |
| 3 | `Model ROC AUC (random forest)` | 0.571 |
| 4 | `Returners found in the top 10%` | 15.0% |

**Return rate by region.** A **Stacked bar chart** with `churn_dataset[region]` in **Y-axis** (renamed *Region*) and the measure `Return rate` in **X-axis**. Sort by Return rate, descending. Data labels on. Title: *Share of customers who came back within 180 days, by region*.

*Check:* Southeast 1.91%, South 1.55%, Central-West 1.46%, North 1.40% and Northeast 1.22%.

**Return rate by first delivery.** The same chart with `churn_dataset[delivery_status]` (the column of section 3.3) instead of the region, renamed *Delivery status*. Title: *Same share by first delivery (difference not statistically clear)*. The title warns the reader because the confidence intervals in notebook 06 overlap.

*Check:* On time 1.77% and Late 1.38%.

**Risk groups by region.** A **100% stacked bar chart**:

1. `customer_return_scores[region]` in **Y-axis** (renamed *Region*), `customer_return_scores[risk_group]` in **Legend** (renamed *Chance of returning*) and the measure `Recent customers` in **X-axis**.
2. Colors: **Format → Visual → Bars → Colors**, one color per group, from blue (most likely to come back) to red (least likely):

| Group | Color |
|---|---|
| 1 - highest chance of returning | `#184f95` |
| 2 | `#86b6ef` |
| 3 | `#d3d1c9` |
| 4 | `#f2a29b` |
| 5 - lowest chance of returning | `#e34948` |

3. Title: *Recent customers by model risk group (share of each region)*.

The groups are quintiles, so a simple count would show five equal bars. Splitting each region by group shows where the customers least likely to come back are.

*Check:* in the Northeast about two thirds of the bar is red (group 5); in the Southeast the dark blue group 1 is the largest.

**Positions:**

| Visual | Height | Width | Horizontal | Vertical |
|---|---|---|---|---|
| Title box | 115 | 1860 | 30 | 10 |
| Card 1 | 170 | 450 | 30 | 140 |
| Card 2 | 170 | 450 | 500 | 140 |
| Card 3 | 170 | 450 | 970 | 140 |
| Card 4 | 170 | 450 | 1440 | 140 |
| Return rate by region | 420 | 760 | 30 | 330 |
| Return rate by first delivery | 280 | 760 | 30 | 770 |
| Risk groups by region | 720 | 1080 | 810 | 330 |

## 6. Export the screenshots

1. Clear every selection (4.8) and set the slicer of the Products page to **All**.
2. Go to **File → Export → Export to PDF**. Power BI creates one page per report page.
3. Save one image per page in `dashboard/screenshots/` as `01_products.png`, `02_inventory.png`, `03_locations.png` and `04_customers.png`, and reference them in the Dashboard section of the README.

## 7. Troubleshooting

| Problem | Cause | Solution |
|---|---|---|
| Numbers without decimals (12295575 instead of 1229557.5) | Import locale not set | Section 2.2, then import the files again |
| A measure shows "the name is already used" | A column of the same table has that name | Choose another name, such as `Total revenue` |
| The formula bar closed and the measure disappeared | A click outside the bar before pressing Enter | Select the table and click **New measure** again |
| A line chart shows one point per year | The date was added as a hierarchy | Section 4.2 |
| A field went into the visual instead of filtering it | The field was ticked | Remove it from the well and drag it to the Filters pane |
| A table shows triple values | Several months added up | Filter one month (Inventory table, step 2) |
| A table or chart is empty | A selection in another visual is filtering it | Section 4.8, or turn off the interaction (Locations, step 5) |
| The theme option is not under View | Recent versions moved it | **Design → Import theme** |
| A color rule paints the whole column | **Percent** chosen instead of **Number**, or the first box left empty | Section 4.6 |
| The last column of a table is cut off | The table is too narrow | Make it wider with the position table of the page |
| The map is gray or disabled | Map visuals turned off | **File → Options → Global → Security** |
