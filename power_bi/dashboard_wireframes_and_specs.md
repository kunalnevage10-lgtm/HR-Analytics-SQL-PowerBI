# Power BI Dashboard Design Specifications & Visual Wireframes

This document details the multi-page Power BI executive reporting suite designed for CHROs, VP of Talent, and Business Unit Leaders. It provides visual layout wireframes, card configurations, chart specifications, drill-through architectures, and the corporate color design system.

---

## 1. Design System & Theme Guidelines

| Element | Specification | Hex Code | Visual Application |
| :--- | :--- | :---: | :--- |
| **Primary Navy** | Deep Executive Navy | `#0F2C59` | Headers, primary navigation, primary series bars. |
| **Secondary Slate** | Professional Slate | `#337CCF` | Trends, secondary series, active selections. |
| **Alert Coral** | High Risk / Attrition | `#D80032` | Terminations, underpaid flags, high flight risk. |
| **Success Emerald** | Retention / Health | `#227B49` | Retention rate, budget compliance, high satisfaction. |
| **Neutral Grey** | Metric Card Fill | `#F8F9FA` | KPI background containers, subtle divider lines. |
| **Typography** | Segoe UI Semibold / Regular | — | Clean, highly legible enterprise typography. |

---

## 2. Page 1: Executive Workforce & Headcount Dynamics

### Purpose
High-level strategic pulse providing the CEO and CHRO with immediate visibility into total workforce size, annualized attrition trends, departmental variance against budget, and total payroll spend.

### Visual Layout Wireframe
```
+---------------------------------------------------------------------------------------------------+
|  [LOGO]  HR EXECUTIVE WORKFORCE PULSE                           [Period: FY2024] [Dept: All] [v]  |
+---------------------------------------------------------------------------------------------------+
|  CARD 1            CARD 2             CARD 3             CARD 4             CARD 5                |
|  Active Headcount  TTM Attrition Rate Total Payroll      Avg Compa-Ratio    Avg Tenure            |
|  872               13.2%              $88.4M             0.99               2.8 Yrs               |
|  (+4.2% YoY)       (-1.1% vs target)  ($101.4k Avg)      (88% in band)      (Healthy Retention)   |
+------------------------------------+--------------------------------------------------------------+
|  CHART 1: Headcount Growth Trend   |  CHART 2: Department Headcount vs Budget Variance           |
|  [Line & Clustered Column]         |  [Horizontal Bullet / Bar Chart]                             |
|  - Columns: Active Headcount       |  - Bars: Current Headcount                                   |
|  - Line: Rolling 12M Attrition %   |  - Target Line: Approved Budget                              |
|                                    |  - Color: Red if variance < -15%, Green if within 5%         |
+------------------------------------+--------------------------------------------------------------+
|  CHART 3: Workforce Mix by Tier    |  CHART 4: Remote Work Distribution by Division               |
|  [Donut Chart]                     |  [100% Stacked Bar Chart]                                    |
|  - Junior (L1-L2): 51.8%           |  - Segments: Fully Remote (100%), Hybrid (50%), On-site (0%) |
|  - Mid / Senior (L3-L4): 37.2%     |  - High remote concentration in Engineering & Product        |
|  - Leadership (M1-E1): 11.0%       |                                                              |
+------------------------------------+--------------------------------------------------------------+
```

### Visual Specifications
1. **Global Slicers (Top Ribbon)**:
   - Calendar Year / Quarter (`Dim_Date[FiscalYear]`, `Dim_Date[FiscalQuarter]`)
   - Department (`Dim_Department[department_name]`)
   - Office Location (`Dim_Location[city]`)
2. **KPI Scorecards (Row 1)**:
   - Card 1: `[Active Headcount]` with dynamic subtitle showing YoY % delta.
   - Card 2: `[Rolling 12M Attrition Rate %]` with status color threshold ($\le 14\%$ Green, $> 14\%$ Red).
   - Card 3: `[Total Annual Payroll]` formatted in Millions.
   - Card 4: `[Average Compa-Ratio]` gauge or card with reference marker at `1.00`.
   - Card 5: `[Average Employee Tenure]` in years.
3. **Chart 1 (Headcount Growth Trend)**:
   - X-Axis: `Dim_Date[MonthYear]`
   - Primary Y-Axis: `[Active Headcount]` (Bars)
   - Secondary Y-Axis: `[Rolling 12M Attrition Rate %]` (Line)
4. **Chart 2 (Department Headcount vs Budget)**:
   - Category: `Dim_Department[department_name]`
   - Measure: `[Active Headcount]` vs `[Budget Headcount]` target line.

---

## 3. Page 2: Attrition Drivers & Flight Risk Intelligence

### Purpose
Diagnostic and predictive root-cause analysis identifying *why* talent departs, evaluating compensation, overtime burnout, career stagnation, and flagging active high-risk individuals.

### Visual Layout Wireframe
```
+---------------------------------------------------------------------------------------------------+
|  ATTRITION DRIVERS & RETENTION INTELLIGENCE                    [Filter: Voluntary Only] [Dept: v] |
+---------------------------------------------------------------------------------------------------+
|  CARD 1               CARD 2               CARD 3               CARD 4                            |
|  Total Separations    Voluntary Turnover   Regretted Losses     Estimated Turnover Cost           |
|  378                  28.1%                119                  $28.2M                            |
|  (304 Voluntary)      (Tech Avg: ~14%/yr)  (Rating 4-5 Stars)   (Avg $74.6k / departure)         |
+------------------------------------+--------------------------------------------------------------+
|  CHART 1: Departure Reason Pareto  |  CHART 2: Attrition Rate by Overtime Bracket                 |
|  [Clustered Bar with % Line]       |  [Column Chart]                                              |
|  - Comp Under-market: 32%          |  - 0 hrs: 12.1% turnover                                     |
|  - Overtime Burnout: 26%           |  - 1-15 hrs: 21.4% turnover                                  |
|  - Career Stagnation: 22%          |  - 16-25 hrs: 37.4% turnover                                 |
|  - Relocation/Personal: 20%        |  - >25 hrs: 56.8% turnover (Burnout threshold!)              |
+------------------------------------+--------------------------------------------------------------+
|  CHART 3: Compa-Ratio Hazard Curve |  TABLE: Active High Flight Risk Watchlist (Drill-through)     |
|  [Scatter / Line Chart]            |  [Data Table with Conditional Formatting]                    |
|  - X: Compa-Ratio Bands            |  - Columns: Name, Dept, Role, Compa, OT Hrs, Risk Index      |
|  - Y: Voluntary Attrition Rate %   |  - Top alerts: Overtime >25 hrs & Compa <0.88               |
|  - Clear inverse correlation       |  - Action button: "Open Employee Talent Profile"             |
+------------------------------------+--------------------------------------------------------------+
```

### Visual Specifications
1. **Chart 1 (Departure Reasons Pareto)**:
   - Category: `Fact_Attrition_Events[TerminationReason]`
   - Bars: `[Total Exits]` sorted descending.
   - Line: Cumulative % of total departures.
2. **Chart 2 (Overtime Workload Impact)**:
   - X-Axis: Overtime Bracket (`0 hrs`, `1-15 hrs`, `16-25 hrs`, `>25 hrs`).
   - Y-Axis: `[Attrition Rate %]`.
   - Tooltip: `[Average Satisfaction Score]`, `[Average Work-Life Balance]`.
3. **Chart 3 (Compa-Ratio vs Turnover Hazard)**:
   - X-Axis: `[Compa-Ratio Bands]` ($<0.85$, $0.85-0.95$, $0.95-1.05$, $1.05-1.15$, $>1.15$).
   - Y-Axis: `[Voluntary Turnover Rate %]`.
4. **Table (Early Warning Flight Risk Grid)**:
   - Records sourced from `vw_flight_risk_early_warning` where `flight_risk_index >= 50`.
   - Highlight badges: Critical ($\ge 70$, Coral Red), High ($50-69$, Amber).

---

## 4. Page 3: Compensation, Pay Equity & Compa-Ratio Deep-Dive

### Purpose
Examines internal salary distributions, external market competitiveness (Compa-Ratio), salary compression anomalies, and gender compensation equity across grades.

### Visual Layout Wireframe
```
+---------------------------------------------------------------------------------------------------+
|  COMPENSATION ARCHITECTURE & PAY EQUITY                        [Level: All] [Department: All] [v] |
+---------------------------------------------------------------------------------------------------+
|  CARD 1               CARD 2               CARD 3               CARD 4                            |
|  Avg Annual Base      Median Annual Base   Overall Compa-Ratio  Underpaid Population              |
|  $101,438             $96,500              0.992                110 Employees (12.6%)             |
+------------------------------------+--------------------------------------------------------------+
|  CHART 1: Salary Band Penetration  |  CHART 2: Salary Compression Audit (Tenure vs Pay)           |
|  [Box & Whisker / Range Bars]      |  [Scatter Plot]                                              |
|  - Y-Axis: Job Title & Level       |  - X-Axis: Tenure in Years                                   |
|  - Min, Mid, Max Band Markers      |  - Y-Axis: Base Salary ($)                                   |
|  - Dots: Current Employee Salaries |  - Trendline: Flat slope indicates wage stagnation           |
+------------------------------------+--------------------------------------------------------------+
|  CHART 3: Adjusted Gender Pay Gap  |  CHART 4: Compa-Ratio Distribution by Department             |
|  [Horizontal Diverging Bar]        |  [Violin / Histogram]                                        |
|  - Level L1-L2: +0.4% diff (equal) |  - Center at 1.00                                            |
|  - Level L3-L4: -1.2% diff         |  - Skewed low in Customer Support (0.94)                     |
|  - Level M1-M2: -1.8% diff         |  - Balanced in Engineering (1.01)                            |
+------------------------------------+--------------------------------------------------------------+
```

### Visual Specifications
1. **Chart 1 (Salary Band Range Penetration)**:
   - Visual Type: Range Bar or Box Plot.
   - Data: `job_roles.salary_band_min`, `salary_band_mid`, `salary_band_max` plotted with `Fact_Headcount_Snapshot_Monthly[BaseSalary]`.
2. **Chart 2 (Salary Compression Scatter)**:
   - X-Axis: `Dim_Employee[tenure_years]`.
   - Y-Axis: `Fact_Headcount_Snapshot_Monthly[BaseSalary]`.
   - Slicer filter: Specific job role (e.g., Senior Software Engineer).
3. **Chart 3 (Gender Pay Gap by Seniority Level)**:
   - X-Axis: `[Compa-Ratio Differential]` or `[Raw Pay Gap %]`.
   - Category: Seniority Tier (`L1-L2`, `L3-L4`, `M1-M2`, `E1`).

---

## 5. Page 4: Talent Acquisition, Velocity & Span of Control

### Purpose
Monitors hiring velocity, time-to-promotion velocity, manager span of control, and first-year retention hazards.

### Visual Layout Wireframe
```
+---------------------------------------------------------------------------------------------------+
|  TALENT ACQUISITION, CAREER VELOCITY & SPAN OF CONTROL                   [Fiscal Year: 2024] [v]  |
+---------------------------------------------------------------------------------------------------+
|  CARD 1               CARD 2               CARD 3               CARD 4                            |
|  Net Hires (YTD)      Avg Time to Promo    First-Year Churn     Avg Span of Control               |
|  +68 Hires            2.4 Years            14.2%                7.8 Direct Reports                |
+------------------------------------+--------------------------------------------------------------+
|  CHART 1: Quarterly Hiring Ramp    |  CHART 2: Manager Span of Control Distribution               |
|  [Waterfall Chart]                 |  [Histogram / Column Chart]                                  |
|  - Starting HC -> Hires -> Exits   |  - Target Span: 5 to 10 Direct Reports                       |
|  - Ending Headcount Balance        |  - Outlier Managers (>12 Reports) flagged for support        |
+------------------------------------+--------------------------------------------------------------+
|  CHART 3: Cohort Retention Curves  |  CHART 4: Promotions & Merit Increase Trajectory             |
|  [Multi-line Retention Rate]       |  [Clustered Column]                                          |
|  - Cohorts 2018 through 2024       |  - Average % raise on Promotion (13.5%) vs Merit (3.8%)      |
|  - Retention drop steepest M6-M14  |  - Career velocity benchmarked by department                 |
+------------------------------------+--------------------------------------------------------------+
```

### Interactivity & Drill-Through Actions
- **Right-Click Drill-Through**: Right-clicking any Department bar on Page 1 or 2 drills through to a hidden **Department Detail Deep Dive** page pre-filtered to that business unit.
- **Cross-Filtering**: Clicking any departure reason on Page 2 dynamically cross-filters the Tenure and Overtime distributions.
- **Tooltip Cards**: Hovering over any manager bar in Chart 2 displays team size, team average satisfaction score, and team voluntary attrition rate.
