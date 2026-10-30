-- ==============================================================================
-- 05_attrition_and_retention.sql
-- HR Analytics Portfolio: Attrition Drivers, Survival Curve & Retention Hazards
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. Overall & Annualized Attrition Rates by Department
-- Evaluates voluntary vs. involuntary turnover alongside active headcount.
-- ------------------------------------------------------------------------------
WITH dept_turnover_stats AS (
    SELECT
        d.department_name,
        COUNT(e.employee_id) AS total_ever_hired,
        SUM(CASE WHEN e.employment_status = 'Active' THEN 1 ELSE 0 END) AS current_active,
        SUM(CASE WHEN e.employment_status = 'Terminated' THEN 1 ELSE 0 END) AS total_separations,
        SUM(CASE WHEN e.termination_type = 'Voluntary' THEN 1 ELSE 0 END) AS voluntary_separations,
        SUM(CASE WHEN e.termination_type = 'Involuntary' THEN 1 ELSE 0 END) AS involuntary_separations,
        ROUND(AVG(e.tenure_years), 2) AS avg_workforce_tenure
    FROM departments d
    LEFT JOIN employees e ON d.department_id = e.department_id
    GROUP BY d.department_id, d.department_name
)
SELECT
    department_name,
    current_active,
    total_separations,
    voluntary_separations,
    involuntary_separations,
    ROUND((total_separations * 100.0) / total_ever_hired, 1) AS cumulative_turnover_rate_pct,
    ROUND((voluntary_separations * 100.0) / total_ever_hired, 1) AS voluntary_turnover_rate_pct,
    avg_workforce_tenure
FROM dept_turnover_stats
ORDER BY cumulative_turnover_rate_pct DESC;

-- ------------------------------------------------------------------------------
-- 2. Attrition Hazard by Tenure Brackets
-- Highlights the vulnerable phases in the employee lifecycle.
-- ------------------------------------------------------------------------------
WITH tenure_brackets AS (
    SELECT
        employee_id,
        employment_status,
        termination_type,
        CASE
            WHEN tenure_years < 1.0 THEN '1. < 1 Year (Onboarding Risk)'
            WHEN tenure_years BETWEEN 1.0 AND 2.0 THEN '2. 1 - 2 Years (Early Career)'
            WHEN tenure_years BETWEEN 2.01 AND 3.5 THEN '3. 2 - 3.5 Years (Mid-Tenure Stagnation)'
            WHEN tenure_years BETWEEN 3.51 AND 5.0 THEN '4. 3.5 - 5 Years (Established)'
            ELSE '5. > 5 Years (Veteran)'
        END AS tenure_bracket
    FROM employees
)
SELECT
    tenure_bracket,
    COUNT(employee_id) AS total_employees,
    SUM(CASE WHEN employment_status = 'Active' THEN 1 ELSE 0 END) AS active_retained,
    SUM(CASE WHEN employment_status = 'Terminated' THEN 1 ELSE 0 END) AS total_exits,
    SUM(CASE WHEN termination_type = 'Voluntary' THEN 1 ELSE 0 END) AS voluntary_exits,
    ROUND(
        (SUM(CASE WHEN employment_status = 'Terminated' THEN 1 ELSE 0 END) * 100.0) / COUNT(employee_id), 1
    ) AS bracket_turnover_rate_pct
FROM tenure_brackets
GROUP BY tenure_bracket
ORDER BY tenure_bracket;

-- ------------------------------------------------------------------------------
-- 3. Chronic Overtime Burnout Correlation with Attrition
-- Assesses turnover rates across overtime workload tiers.
-- ------------------------------------------------------------------------------
SELECT
    CASE 
        WHEN monthly_overtime_hours = 0 THEN '1. No Overtime (0 hrs)'
        WHEN monthly_overtime_hours BETWEEN 1 AND 15 THEN '2. Moderate (1-15 hrs)'
        WHEN monthly_overtime_hours BETWEEN 16 AND 25 THEN '3. High (16-25 hrs)'
        ELSE '4. Extreme Overtime (>25 hrs)'
    END AS overtime_bracket,
    COUNT(employee_id) AS total_headcount,
    SUM(CASE WHEN employment_status = 'Terminated' THEN 1 ELSE 0 END) AS total_exits,
    ROUND(
        (SUM(CASE WHEN employment_status = 'Terminated' THEN 1 ELSE 0 END) * 100.0) / COUNT(employee_id), 1
    ) AS turnover_rate_pct,
    ROUND(AVG(satisfaction_score), 2) AS avg_satisfaction_score,
    ROUND(AVG(work_life_balance_score), 2) AS avg_wlb_score
FROM employees
GROUP BY overtime_bracket
ORDER BY overtime_bracket;

-- ------------------------------------------------------------------------------
-- 4. Compa-Ratio (Pay Competitiveness) Impact on Voluntary Resignations
-- Proves that below-market pay is a primary driver of voluntary turnover.
-- ------------------------------------------------------------------------------
SELECT
    CASE
        WHEN compa_ratio < 0.85 THEN '1. Severely Underpaid (< 0.85)'
        WHEN compa_ratio BETWEEN 0.85 AND 0.95 THEN '2. Below Midpoint (0.85 - 0.95)'
        WHEN compa_ratio BETWEEN 0.951 AND 1.05 THEN '3. At Market Midpoint (0.95 - 1.05)'
        WHEN compa_ratio BETWEEN 1.051 AND 1.15 THEN '4. Above Midpoint (1.05 - 1.15)'
        ELSE '5. Premium Band (> 1.15)'
    END AS compa_ratio_band,
    COUNT(employee_id) AS total_employees,
    SUM(CASE WHEN termination_type = 'Voluntary' THEN 1 ELSE 0 END) AS voluntary_exits,
    ROUND(
        (SUM(CASE WHEN termination_type = 'Voluntary' THEN 1 ELSE 0 END) * 100.0) / COUNT(employee_id), 1
    ) AS voluntary_attrition_rate_pct,
    ROUND(AVG(satisfaction_score), 2) AS avg_satisfaction
FROM employees
GROUP BY compa_ratio_band
ORDER BY compa_ratio_band;

-- ------------------------------------------------------------------------------
-- 5. "Regretted Attrition": High Performers Leaving the Firm
-- Tracks departures of employees with performance ratings 4 or 5 and their reasons.
-- ------------------------------------------------------------------------------
SELECT
    d.department_name,
    COUNT(CASE WHEN e.performance_rating >= 4 THEN e.employee_id END) AS high_performer_total,
    SUM(CASE WHEN e.performance_rating >= 4 AND e.termination_type = 'Voluntary' THEN 1 ELSE 0 END) AS regretted_losses_count,
    ROUND(
        (SUM(CASE WHEN e.performance_rating >= 4 AND e.termination_type = 'Voluntary' THEN 1 ELSE 0 END) * 100.0)
        / NULLIF(COUNT(CASE WHEN e.performance_rating >= 4 THEN e.employee_id END), 0), 1
    ) AS regretted_loss_rate_pct,
    ROUND(
        AVG(CASE WHEN e.performance_rating >= 4 AND e.termination_type = 'Voluntary' THEN e.compa_ratio END), 2
    ) AS avg_compa_ratio_lost_performers,
    ROUND(
        AVG(CASE WHEN e.performance_rating >= 4 AND e.termination_type = 'Voluntary' THEN e.tenure_years END), 2
    ) AS avg_tenure_lost_performers
FROM employees e
JOIN departments d ON e.department_id = d.department_id
GROUP BY d.department_id, d.department_name
ORDER BY regretted_loss_rate_pct DESC;
