-- ==============================================================================
-- 06_advanced_window_functions_and_ctes.sql
-- HR Analytics Portfolio: Advanced SQL (Multi-Stage CTEs, Window Aggregates, LAG/LEAD)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. Trailing 12-Month (TTM) Rolling Turnover Rate via Multi-Stage CTE
-- Calculates monthly terminations, active headcount, and rolling 12-month turnover.
-- ------------------------------------------------------------------------------
WITH monthly_spine AS (
    -- Distinct calendar months from 2019 to 2024
    SELECT DISTINCT 
        strftime('%Y-%m', hire_date) AS month_key,
        date(hire_date, 'start of month', '+1 month', '-1 day') AS month_end_date
    FROM employees
    WHERE hire_date >= '2019-01-01'
),
monthly_metrics AS (
    SELECT
        s.month_key,
        s.month_end_date,
        COUNT(CASE 
            WHEN e.hire_date <= s.month_end_date 
             AND (e.exit_date IS NULL OR e.exit_date > s.month_end_date) 
            THEN 1 
        END) AS active_headcount,
        COUNT(CASE 
            WHEN e.exit_date BETWEEN date(s.month_end_date, 'start of month') AND s.month_end_date 
            THEN 1 
        END) AS monthly_exits
    FROM monthly_spine s
    CROSS JOIN employees e
    GROUP BY s.month_key, s.month_end_date
),
rolling_calculations AS (
    SELECT
        month_key,
        active_headcount,
        monthly_exits,
        SUM(monthly_exits) OVER (
            ORDER BY month_key ROWS BETWEEN 11 PRECEDING AND CURRENT ROW
        ) AS exits_trailing_12m,
        AVG(active_headcount) OVER (
            ORDER BY month_key ROWS BETWEEN 11 PRECEDING AND CURRENT ROW
        ) AS avg_headcount_trailing_12m
    FROM monthly_metrics
)
SELECT
    month_key,
    active_headcount,
    monthly_exits,
    exits_trailing_12m,
    ROUND(avg_headcount_trailing_12m, 0) AS avg_headcount_trailing_12m,
    ROUND((exits_trailing_12m * 100.0) / NULLIF(avg_headcount_trailing_12m, 0), 2) AS ttm_turnover_rate_pct
FROM rolling_calculations
ORDER BY month_key DESC
LIMIT 24;

-- ------------------------------------------------------------------------------
-- 2. Career Progression & Salary Velocity with LAG()
-- Analyzes salary increase trajectory from previous compensation adjustments.
-- ------------------------------------------------------------------------------
WITH salary_trajectory AS (
    SELECT
        sh.history_id,
        sh.employee_id,
        e.first_name || ' ' || e.last_name AS employee_name,
        d.department_name,
        sh.effective_date,
        sh.change_reason,
        sh.new_salary,
        LAG(sh.new_salary, 1) OVER (
            PARTITION BY sh.employee_id ORDER BY sh.effective_date ASC
        ) AS previous_logged_salary,
        LAG(sh.effective_date, 1) OVER (
            PARTITION BY sh.employee_id ORDER BY sh.effective_date ASC
        ) AS previous_event_date,
        sh.salary_change_pct
    FROM salary_history sh
    JOIN employees e ON sh.employee_id = e.employee_id
    JOIN departments d ON e.department_id = d.department_id
)
SELECT
    history_id,
    employee_id,
    employee_name,
    department_name,
    effective_date,
    change_reason,
    previous_logged_salary,
    new_salary,
    ROUND(new_salary - COALESCE(previous_logged_salary, 0), 0) AS nominal_dollar_increase,
    salary_change_pct,
    ROUND(
        (julianday(effective_date) - julianday(previous_event_date)) / 365.25, 2
    ) AS years_between_salary_events
FROM salary_trajectory
WHERE change_reason IN ('Annual Merit', 'Promotion', 'Market Adjustment')
ORDER BY employee_id, effective_date ASC
LIMIT 15;

-- ------------------------------------------------------------------------------
-- 3. Top Talent Identification via Dense Ranking & High Potential Grid
-- Uses DENSE_RANK() to identify top 2 rated performers per department.
-- ------------------------------------------------------------------------------
WITH high_performer_ranking AS (
    SELECT
        e.employee_id,
        e.first_name || ' ' || e.last_name AS employee_name,
        d.department_name,
        j.job_title,
        j.job_level,
        e.performance_rating,
        e.satisfaction_score,
        e.base_salary,
        e.compa_ratio,
        e.promotions_count,
        e.tenure_years,
        DENSE_RANK() OVER (
            PARTITION BY d.department_id 
            ORDER BY e.performance_rating DESC, e.satisfaction_score DESC, e.tenure_years DESC
        ) AS dept_talent_rank
    FROM employees e
    JOIN departments d ON e.department_id = d.department_id
    JOIN job_roles j ON e.job_id = j.job_id
    WHERE e.employment_status = 'Active'
)
SELECT
    dept_talent_rank,
    department_name,
    employee_name,
    job_title,
    job_level,
    performance_rating,
    satisfaction_score,
    base_salary,
    compa_ratio,
    promotions_count,
    tenure_years
FROM high_performer_ranking
WHERE dept_talent_rank <= 2
ORDER BY department_name, dept_talent_rank;

-- ------------------------------------------------------------------------------
-- 4. Multi-Dimensional Flight Risk Early Warning CTE
-- Computes a weighted risk composite score (0 to 100) for currently active employees.
-- ------------------------------------------------------------------------------
WITH flight_risk_scoring AS (
    SELECT
        e.employee_id,
        e.first_name || ' ' || e.last_name AS employee_name,
        d.department_name,
        j.job_title,
        j.job_level,
        e.compa_ratio,
        e.monthly_overtime_hours,
        e.satisfaction_score,
        e.tenure_years,
        e.promotions_count,
        -- Risk Factor 1: Underpaid relative to market (Max 35 pts)
        CASE 
            WHEN e.compa_ratio < 0.85 THEN 35
            WHEN e.compa_ratio < 0.92 THEN 20
            WHEN e.compa_ratio < 0.98 THEN 10
            ELSE 0
        END AS compa_risk_score,
        -- Risk Factor 2: Extreme Overtime / Burnout (Max 30 pts)
        CASE 
            WHEN e.monthly_overtime_hours > 25 THEN 30
            WHEN e.monthly_overtime_hours > 15 THEN 18
            WHEN e.monthly_overtime_hours > 8 THEN 8
            ELSE 0
        END AS overtime_risk_score,
        -- Risk Factor 3: Low Engagement Survey Sentiment (Max 25 pts)
        CASE 
            WHEN e.satisfaction_score <= 2 THEN 25
            WHEN e.satisfaction_score = 3 THEN 12
            ELSE 0
        END AS sentiment_risk_score,
        -- Risk Factor 4: Career Stagnation (>2.5 yrs tenure with 0 promotions) (Max 10 pts)
        CASE 
            WHEN e.tenure_years >= 2.5 AND e.promotions_count = 0 THEN 10
            ELSE 0
        END AS stagnation_risk_score
    FROM employees e
    JOIN departments d ON e.department_id = d.department_id
    JOIN job_roles j ON e.job_id = j.job_id
    WHERE e.employment_status = 'Active'
),
composite_risk AS (
    SELECT
        employee_id,
        employee_name,
        department_name,
        job_title,
        job_level,
        compa_ratio,
        monthly_overtime_hours,
        satisfaction_score,
        tenure_years,
        (compa_risk_score + overtime_risk_score + sentiment_risk_score + stagnation_risk_score) AS flight_risk_index
    FROM flight_risk_scoring
)
SELECT
    employee_id,
    employee_name,
    department_name,
    job_title,
    job_level,
    compa_ratio,
    monthly_overtime_hours,
    satisfaction_score,
    tenure_years,
    flight_risk_index,
    CASE
        WHEN flight_risk_index >= 70 THEN 'CRITICAL RISK (Intervene Immediately)'
        WHEN flight_risk_index >= 50 THEN 'HIGH RISK (Review Compensation/Workload)'
        WHEN flight_risk_index >= 30 THEN 'MODERATE RISK (Monitor)'
        ELSE 'LOW RISK'
    END AS risk_tier
FROM composite_risk
WHERE flight_risk_index >= 50
ORDER BY flight_risk_index DESC
LIMIT 20;
