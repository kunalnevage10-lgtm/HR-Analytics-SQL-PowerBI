-- ==============================================================================
-- 03_hiring_patterns_and_velocity.sql
-- HR Analytics Portfolio: Talent Acquisition, Hiring Velocity & Cohort Survival
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. Yearly & Quarterly Hiring Velocity with Running Total
-- Demonstrates Window Functions: SUM() OVER (ORDER BY ...) for cumulative ramp-up.
-- ------------------------------------------------------------------------------
WITH quarterly_hires AS (
    SELECT
        strftime('%Y', hire_date) AS hire_year,
        'Q' || ((CAST(strftime('%m', hire_date) AS INTEGER) + 2) / 3) AS hire_quarter,
        COUNT(employee_id) AS hires_count
    FROM employees
    GROUP BY strftime('%Y', hire_date), hire_quarter
)
SELECT
    hire_year,
    hire_quarter,
    hires_count,
    SUM(hires_count) OVER (PARTITION BY hire_year ORDER BY hire_quarter) AS ytd_hires,
    SUM(hires_count) OVER (ORDER BY hire_year, hire_quarter) AS cumulative_hires_total,
    ROUND(
        AVG(hires_count) OVER (ORDER BY hire_year, hire_quarter ROWS BETWEEN 3 PRECEDING AND CURRENT ROW), 1
    ) AS rolling_4qtr_avg_hires
FROM quarterly_hires
ORDER BY hire_year, hire_quarter;

-- ------------------------------------------------------------------------------
-- 2. Net Headcount Velocity: Hires vs. Exits by Year
-- Analyzes organic growth rate, replacement hiring, and net workforce additions.
-- ------------------------------------------------------------------------------
WITH yearly_hires AS (
    SELECT
        strftime('%Y', hire_date) AS calendar_year,
        COUNT(employee_id) AS hires
    FROM employees
    GROUP BY strftime('%Y', hire_date)
),
yearly_exits AS (
    SELECT
        strftime('%Y', exit_date) AS calendar_year,
        COUNT(employee_id) AS exits,
        SUM(CASE WHEN termination_type = 'Voluntary' THEN 1 ELSE 0 END) AS voluntary_exits,
        SUM(CASE WHEN termination_type = 'Involuntary' THEN 1 ELSE 0 END) AS involuntary_exits
    FROM employees
    WHERE exit_date IS NOT NULL
    GROUP BY strftime('%Y', exit_date)
)
SELECT
    h.calendar_year,
    h.hires,
    COALESCE(x.exits, 0) AS total_exits,
    COALESCE(x.voluntary_exits, 0) AS voluntary_exits,
    COALESCE(x.involuntary_exits, 0) AS involuntary_exits,
    (h.hires - COALESCE(x.exits, 0)) AS net_headcount_addition,
    ROUND(
        (COALESCE(x.exits, 0) * 100.0) / NULLIF(h.hires, 0), 1
    ) AS turnover_to_hire_ratio_pct
FROM yearly_hires h
LEFT JOIN yearly_exits x ON h.calendar_year = x.calendar_year
ORDER BY h.calendar_year;

-- ------------------------------------------------------------------------------
-- 3. Hiring Cohort Retention Tracking
-- Groups employees by joining cohort year and evaluates active retention rate.
-- ------------------------------------------------------------------------------
SELECT
    strftime('%Y', hire_date) AS cohort_year,
    COUNT(employee_id) AS cohort_size,
    SUM(CASE WHEN employment_status = 'Active' THEN 1 ELSE 0 END) AS currently_active,
    SUM(CASE WHEN employment_status = 'Terminated' THEN 1 ELSE 0 END) AS total_churned,
    ROUND(
        (SUM(CASE WHEN employment_status = 'Active' THEN 1 ELSE 0 END) * 100.0) / COUNT(employee_id), 1
    ) AS active_retention_rate_pct,
    ROUND(AVG(tenure_years), 2) AS avg_tenure_years,
    ROUND(AVG(base_salary), 0) AS avg_current_salary,
    ROUND(AVG(compa_ratio), 2) AS avg_compa_ratio
FROM employees
GROUP BY strftime('%Y', hire_date)
ORDER BY cohort_year;

-- ------------------------------------------------------------------------------
-- 4. First-Year Churn Analysis (Early Flight Hazard)
-- Identifies departments with problematic onboarding or misaligned expectations.
-- ------------------------------------------------------------------------------
SELECT
    d.department_name,
    COUNT(e.employee_id) AS total_cohort_hires,
    SUM(CASE WHEN e.employment_status = 'Terminated' AND e.tenure_years <= 1.0 THEN 1 ELSE 0 END) AS churn_within_1yr,
    ROUND(
        (SUM(CASE WHEN e.employment_status = 'Terminated' AND e.tenure_years <= 1.0 THEN 1 ELSE 0 END) * 100.0) 
        / COUNT(e.employee_id), 1
    ) AS first_year_churn_rate_pct,
    ROUND(
        AVG(CASE WHEN e.employment_status = 'Terminated' AND e.tenure_years <= 1.0 THEN e.satisfaction_score END), 2
    ) AS avg_satisfaction_churned_1yr
FROM employees e
JOIN departments d ON e.department_id = d.department_id
GROUP BY d.department_id, d.department_name
ORDER BY first_year_churn_rate_pct DESC;
