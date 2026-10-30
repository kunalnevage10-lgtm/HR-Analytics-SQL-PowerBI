# DAX Measures Library: Production-Grade HR Analytics

This repository catalog houses 25+ production-grade DAX measures designed for the HR Analytics Power BI model. Measures are categorized by display folders with explicit business definitions, formatting strings, and performance-optimized DAX patterns.

---

## Folder 1: Headcount & Movement Metrics

### 1. `[Active Headcount]`
Returns the distinct count of active employees at the selected date snapshot.
```dax
Active Headcount = 
CALCULATE(
    DISTINCTCOUNT(Fact_Headcount_Snapshot_Monthly[EmployeeId]),
    Fact_Headcount_Snapshot_Monthly[IsActiveMonthEnd] = 1,
    LASTDATE(Dim_Date[Date])
)
```
*Format: `#,##0`*

### 2. `[Starting Headcount]`
Headcount at the beginning of the selected calendar or fiscal period.
```dax
Starting Headcount = 
VAR PeriodStart = MIN(Dim_Date[Date])
RETURN
CALCULATE(
    DISTINCTCOUNT(Fact_Headcount_Snapshot_Monthly[EmployeeId]),
    Fact_Headcount_Snapshot_Monthly[IsActiveMonthEnd] = 1,
    Dim_Date[Date] = PeriodStart
)
```
*Format: `#,##0`*

### 3. `[Ending Headcount]`
Headcount at the end of the selected period.
```dax
Ending Headcount = 
VAR PeriodEnd = MAX(Dim_Date[Date])
RETURN
CALCULATE(
    DISTINCTCOUNT(Fact_Headcount_Snapshot_Monthly[EmployeeId]),
    Fact_Headcount_Snapshot_Monthly[IsActiveMonthEnd] = 1,
    Dim_Date[Date] = PeriodEnd
)
```
*Format: `#,##0`*

### 4. `[Average Headcount]`
Standard denominator for attrition calculations ($\frac{\text{Start} + \text{End}}{2}$).
```dax
Average Headcount = 
DIVIDE(
    [Starting Headcount] + [Ending Headcount],
    2,
    [Active Headcount]
)
```
*Format: `#,##0.0`*

### 5. `[Total Hires]`
New additions joining the company within the selected period.
```dax
Total Hires = 
CALCULATE(
    COUNTROWS(Fact_Headcount_Snapshot_Monthly),
    Fact_Headcount_Snapshot_Monthly[IsHiredMonth] = 1
)
```
*Format: `#,##0`*

### 6. `[Total Exits]`
Total employee separations within the selected period using role-playing `USERELATIONSHIP`.
```dax
Total Exits = 
CALCULATE(
    COUNTROWS(Fact_Attrition_Events),
    USERELATIONSHIP(Dim_Date[Date], Fact_Attrition_Events[ExitDate])
)
```
*Format: `#,##0`*

### 7. `[Voluntary Exits]`
Separations initiated by the employee.
```dax
Voluntary Exits = 
CALCULATE(
    COUNTROWS(Fact_Attrition_Events),
    Fact_Attrition_Events[TerminationType] = "Voluntary",
    USERELATIONSHIP(Dim_Date[Date], Fact_Attrition_Events[ExitDate])
)
```
*Format: `#,##0`*

### 8. `[Involuntary Exits]`
Company-initiated terminations (performance or restructuring).
```dax
Involuntary Exits = 
CALCULATE(
    COUNTROWS(Fact_Attrition_Events),
    Fact_Attrition_Events[TerminationType] = "Involuntary",
    USERELATIONSHIP(Dim_Date[Date], Fact_Attrition_Events[ExitDate])
)
```
*Format: `#,##0`*

---

## Folder 2: Attrition & Retention Rates

### 9. `[Attrition Rate %]`
Standard HR formula: $\frac{\text{Total Exits}}{\text{Average Headcount}} \times 100$.
```dax
Attrition Rate % = 
DIVIDE(
    [Total Exits],
    [Average Headcount],
    BLANK()
)
```
*Format: `0.0%`*

### 10. `[Voluntary Turnover Rate %]`
Voluntary departures expressed as a proportion of average headcount.
```dax
Voluntary Turnover Rate % = 
DIVIDE(
    [Voluntary Exits],
    [Average Headcount],
    BLANK()
)
```
*Format: `0.0%`*

### 11. `[Retention Rate %]`
Percentage of workforce retained over the period ($1 - \text{Turnover Rate}$).
```dax
Retention Rate % = 
1 - [Attrition Rate %]
```
*Format: `0.0%`*

### 12. `[Regretted Loss Rate %]`
Proportion of voluntary departures who were rated top performers (Rating $\ge 4$).
```dax
Regretted Loss Rate % = 
VAR RegrettedExits = 
    CALCULATE(
        COUNTROWS(Fact_Attrition_Events),
        Fact_Attrition_Events[IsRegrettedLoss] = 1,
        USERELATIONSHIP(Dim_Date[Date], Fact_Attrition_Events[ExitDate])
    )
RETURN
DIVIDE(
    RegrettedExits,
    [Voluntary Exits],
    BLANK()
)
```
*Format: `0.0%`*

### 13. `[First-Year Churn Rate %]`
Percentage of new hires who separate within the first 12 months of service.
```dax
First-Year Churn Rate % = 
VAR EarlyExits = 
    CALCULATE(
        COUNTROWS(Fact_Attrition_Events),
        Fact_Attrition_Events[TenureYearsAtExit] <= 1.0,
        USERELATIONSHIP(Dim_Date[Date], Fact_Attrition_Events[ExitDate])
    )
RETURN
DIVIDE(
    EarlyExits,
    [Total Exits],
    BLANK()
)
```
*Format: `0.0%`*

---

## Folder 3: Compensation & Benchmarking

### 14. `[Total Annual Payroll]`
Sum of annualized base compensation for currently active personnel.
```dax
Total Annual Payroll = 
CALCULATE(
    SUM(Fact_Headcount_Snapshot_Monthly[BaseSalary]),
    Fact_Headcount_Snapshot_Monthly[IsActiveMonthEnd] = 1,
    LASTDATE(Dim_Date[Date])
)
```
*Format: `$#,##0`*

### 15. `[Average Base Salary]`
Average base salary across the filtered active employee cohort.
```dax
Average Base Salary = 
CALCULATE(
    AVERAGE(Fact_Headcount_Snapshot_Monthly[BaseSalary]),
    Fact_Headcount_Snapshot_Monthly[IsActiveMonthEnd] = 1,
    LASTDATE(Dim_Date[Date])
)
```
*Format: `$#,##0`*

### 16. `[Median Base Salary]`
Median base salary, resilient against executive compensation skew.
```dax
Median Base Salary = 
CALCULATE(
    MEDIAN(Fact_Headcount_Snapshot_Monthly[BaseSalary]),
    Fact_Headcount_Snapshot_Monthly[IsActiveMonthEnd] = 1,
    LASTDATE(Dim_Date[Date])
)
```
*Format: `$#,##0`*

### 17. `[Average Compa-Ratio]`
Mean comparative ratio ($1.00 = \text{Market Midpoint}$).
```dax
Average Compa-Ratio = 
CALCULATE(
    AVERAGE(Fact_Headcount_Snapshot_Monthly[CompaRatio]),
    Fact_Headcount_Snapshot_Monthly[IsActiveMonthEnd] = 1,
    LASTDATE(Dim_Date[Date])
)
```
*Format: `0.00`*

### 18. `[Underpaid Flight Risk Count]`
Active employees whose pay is below 85% of market band midpoint.
```dax
Underpaid Flight Risk Count = 
CALCULATE(
    DISTINCTCOUNT(Fact_Headcount_Snapshot_Monthly[EmployeeId]),
    Fact_Headcount_Snapshot_Monthly[IsActiveMonthEnd] = 1,
    Fact_Headcount_Snapshot_Monthly[CompaRatio] < 0.85,
    LASTDATE(Dim_Date[Date])
)
```
*Format: `#,##0`*

### 19. `[Estimated Turnover Cost $]`
Total estimated cost of replacement based on salary multipliers ($0.5\times$ to $1.25\times$).
```dax
Estimated Turnover Cost $ = 
CALCULATE(
    SUM(Fact_Attrition_Events[EstimatedTurnoverCost]),
    USERELATIONSHIP(Dim_Date[Date], Fact_Attrition_Events[ExitDate])
)
```
*Format: `$#,##0`*

---

## Folder 4: Time Intelligence & Trend Velocity

### 20. `[Headcount MoM %]`
Month-over-Month percentage change in active workforce headcount.
```dax
Headcount MoM % = 
VAR CurrentHC = [Active Headcount]
VAR PrevMonthHC = 
    CALCULATE(
        [Active Headcount],
        DATEADD(Dim_Date[Date], -1, MONTH)
    )
RETURN
DIVIDE(
    CurrentHC - PrevMonthHC,
    PrevMonthHC,
    BLANK()
)
```
*Format: `+0.0%;-0.0%;0.0%`*

### 21. `[Hires YoY %]`
Year-over-Year percentage change in recruitment volume.
```dax
Hires YoY % = 
VAR CurrentHires = [Total Hires]
VAR PriorYearHires = 
    CALCULATE(
        [Total Hires],
        SAMEPERIODLASTYEAR(Dim_Date[Date])
    )
RETURN
DIVIDE(
    CurrentHires - PriorYearHires,
    PriorYearHires,
    BLANK()
)
```
*Format: `+0.0%;-0.0%;0.0%`*

### 22. `[Rolling 12M Attrition Rate %]`
Trailing 12-Month annualized turnover rate smoothing out single-month anomalies.
```dax
Rolling 12M Attrition Rate % = 
VAR RollingExits = 
    CALCULATE(
        [Total Exits],
        DATESINPERIOD(Dim_Date[Date], MAX(Dim_Date[Date]), -12, MONTH)
    )
VAR Avg12MHeadcount = 
    CALCULATE(
        AVERAGE(Fact_Headcount_Snapshot_Monthly[IsActiveMonthEnd]),
        DATESINPERIOD(Dim_Date[Date], MAX(Dim_Date[Date]), -12, MONTH)
    ) * DISTINCTCOUNT(Dim_Employee[employee_id])
RETURN
DIVIDE(
    RollingExits,
    Avg12MHeadcount,
    BLANK()
)
```
*Format: `0.0%`*

---

## Folder 5: Workload, Sentiment & Flight Risk

### 23. `[Average Overtime Hours]`
Mean monthly overtime hours worked across active employees.
```dax
Average Overtime Hours = 
CALCULATE(
    AVERAGE(Fact_Headcount_Snapshot_Monthly[OvertimeHours]),
    Fact_Headcount_Snapshot_Monthly[IsActiveMonthEnd] = 1,
    LASTDATE(Dim_Date[Date])
)
```
*Format: `0.0`*

### 24. `[High Overtime Population %]`
Percentage of active employees working $>20$ hours of monthly overtime.
```dax
High Overtime Population % = 
VAR HighOTCount = 
    CALCULATE(
        DISTINCTCOUNT(Fact_Headcount_Snapshot_Monthly[EmployeeId]),
        Fact_Headcount_Snapshot_Monthly[IsActiveMonthEnd] = 1,
        Fact_Headcount_Snapshot_Monthly[OvertimeHours] > 20,
        LASTDATE(Dim_Date[Date])
    )
RETURN
DIVIDE(
    HighOTCount,
    [Active Headcount],
    BLANK()
)
```
*Format: `0.0%`*

### 25. `[Average Satisfaction Score]`
Mean sentiment score from employee engagement pulses (1 to 5).
```dax
Average Satisfaction Score = 
CALCULATE(
    AVERAGE(Fact_Headcount_Snapshot_Monthly[SatisfactionScore]),
    Fact_Headcount_Snapshot_Monthly[IsActiveMonthEnd] = 1,
    LASTDATE(Dim_Date[Date])
)
```
*Format: `0.00`*

### 26. `[Flight Risk Employee Count]`
Active headcount identified with compound risk score $\ge 50$ (Underpaid + High Overtime + Low Satisfaction).
```dax
Flight Risk Employee Count = 
CALCULATE(
    DISTINCTCOUNT(Fact_Headcount_Snapshot_Monthly[EmployeeId]),
    Fact_Headcount_Snapshot_Monthly[IsActiveMonthEnd] = 1,
    Fact_Headcount_Snapshot_Monthly[CompaRatio] < 0.88,
    Fact_Headcount_Snapshot_Monthly[OvertimeHours] > 15,
    Fact_Headcount_Snapshot_Monthly[SatisfactionScore] <= 2,
    LASTDATE(Dim_Date[Date])
)
```
*Format: `#,##0`*
