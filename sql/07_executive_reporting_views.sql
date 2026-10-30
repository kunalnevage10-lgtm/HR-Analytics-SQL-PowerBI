-- ==============================================================================
-- 07_executive_reporting_views.sql
-- HR Analytics Portfolio: Production-Grade Analytical Views for BI Ingestion
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- View 1: vw_executive_workforce_kpis
-- Aggregated departmental scorecards for executive workforce planning.
-- ------------------------------------------------------------------------------
DROP VIEW IF EXISTS vw_executive_workforce_kpis;
CREATE VIEW vw_executive_workforce_kpis AS
SELECT
    d.department_id,
    d.department_name,
    d.division,
    d.cost_center,
    d.headcount_budget,
    COUNT(CASE WHEN e.employment_status = 'Active' THEN 1 END) AS active_headcount,
    COUNT(CASE WHEN e.employment_status = 'Active' THEN 1 END) - d.headcount_budget AS headcount_variance,
    ROUND((COUNT(CASE WHEN e.employment_status = 'Active' THEN 1 END) * 100.0) / d.headcount_budget, 1) AS budget_utilization_pct,
    COUNT(CASE WHEN e.employment_status = 'Terminated' THEN 1 END) AS total_separations,
    COUNT(CASE WHEN e.termination_type = 'Voluntary' THEN 1 END) AS voluntary_separations,
    ROUND((COUNT(CASE WHEN e.employment_status = 'Terminated' THEN 1 END) * 100.0) / COUNT(e.employee_id), 1) AS cumulative_turnover_pct,
    ROUND(AVG(CASE WHEN e.employment_status = 'Active' THEN e.base_salary END), 0) AS avg_active_salary,
    ROUND(AVG(CASE WHEN e.employment_status = 'Active' THEN e.compa_ratio END), 2) AS avg_active_compa_ratio,
    ROUND(AVG(CASE WHEN e.employment_status = 'Active' THEN e.tenure_years END), 2) AS avg_active_tenure_years,
    ROUND(AVG(CASE WHEN e.employment_status = 'Active' THEN e.satisfaction_score END), 2) AS avg_active_satisfaction
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id
GROUP BY d.department_id, d.department_name, d.division, d.cost_center, d.headcount_budget;

-- ------------------------------------------------------------------------------
-- View 2: vw_attrition_analytics
-- Granular separation records with cost-of-turnover financial estimates.
-- ------------------------------------------------------------------------------
DROP VIEW IF EXISTS vw_attrition_analytics;
CREATE VIEW vw_attrition_analytics AS
SELECT
    e.employee_id,
    e.first_name || ' ' || e.last_name AS employee_name,
    d.department_name,
    j.job_title,
    j.job_level,
    l.city AS office_location,
    e.hire_date,
    e.exit_date,
    e.tenure_years AS tenure_at_exit,
    e.termination_type,
    e.termination_reason,
    e.base_salary AS salary_at_exit,
    e.compa_ratio AS compa_ratio_at_exit,
    e.performance_rating,
    e.satisfaction_score,
    e.monthly_overtime_hours,
    CASE 
        WHEN e.performance_rating >= 4 AND e.termination_type = 'Voluntary' THEN 1 
        ELSE 0 
    END AS is_regretted_loss,
    CASE
        WHEN j.job_level IN ('L4', 'L5', 'M1', 'M2', 'E1') THEN ROUND(e.base_salary * 1.25, 0)
        WHEN d.department_id = 1 THEN ROUND(e.base_salary * 0.75, 0)
        ELSE ROUND(e.base_salary * 0.50, 0)
    END AS estimated_replacement_cost
FROM employees e
JOIN departments d ON e.department_id = d.department_id
JOIN job_roles j ON e.job_id = j.job_id
JOIN locations l ON e.location_id = l.location_id
WHERE e.employment_status = 'Terminated';

-- ------------------------------------------------------------------------------
-- View 3: vw_compensation_benchmarking
-- Job level salary band penetration, compa-ratios, and pay equity tracking.
-- ------------------------------------------------------------------------------
DROP VIEW IF EXISTS vw_compensation_benchmarking;
CREATE VIEW vw_compensation_benchmarking AS
SELECT
    j.job_id,
    j.job_title,
    j.job_level,
    d.department_name,
    j.salary_band_min,
    j.salary_band_mid,
    j.salary_band_max,
    COUNT(e.employee_id) AS active_incumbents,
    ROUND(MIN(e.base_salary), 0) AS min_actual_salary,
    ROUND(AVG(e.base_salary), 0) AS avg_actual_salary,
    ROUND(MAX(e.base_salary), 0) AS max_actual_salary,
    ROUND(AVG(e.compa_ratio), 3) AS avg_compa_ratio,
    SUM(CASE WHEN e.compa_ratio < 0.85 THEN 1 ELSE 0 END) AS count_below_band_target,
    SUM(CASE WHEN e.compa_ratio > 1.15 THEN 1 ELSE 0 END) AS count_above_band_target
FROM job_roles j
JOIN departments d ON j.department_id = d.department_id
LEFT JOIN employees e ON j.job_id = e.job_id AND e.employment_status = 'Active'
GROUP BY j.job_id, j.job_title, j.job_level, d.department_name, j.salary_band_min, j.salary_band_mid, j.salary_band_max;

-- ------------------------------------------------------------------------------
-- View 4: vw_flight_risk_early_warning
-- Predictive composite risk scoring for active employees to enable retention intervention.
-- ------------------------------------------------------------------------------
DROP VIEW IF EXISTS vw_flight_risk_early_warning;
CREATE VIEW vw_flight_risk_early_warning AS
SELECT
    e.employee_id,
    e.first_name || ' ' || e.last_name AS employee_name,
    e.email,
    d.department_name,
    j.job_title,
    j.job_level,
    m.first_name || ' ' || m.last_name AS manager_name,
    e.base_salary,
    e.compa_ratio,
    e.performance_rating,
    e.satisfaction_score,
    e.work_life_balance_score,
    e.monthly_overtime_hours,
    e.tenure_years,
    e.promotions_count,
    -- Composite Risk Formula: Compa (35) + Overtime (30) + Low Satisfaction (25) + Stagnation (10)
    (
        CASE WHEN e.compa_ratio < 0.85 THEN 35 WHEN e.compa_ratio < 0.92 THEN 20 WHEN e.compa_ratio < 0.98 THEN 10 ELSE 0 END +
        CASE WHEN e.monthly_overtime_hours > 25 THEN 30 WHEN e.monthly_overtime_hours > 15 THEN 18 WHEN e.monthly_overtime_hours > 8 THEN 8 ELSE 0 END +
        CASE WHEN e.satisfaction_score <= 2 THEN 25 WHEN e.satisfaction_score = 3 THEN 12 ELSE 0 END +
        CASE WHEN e.tenure_years >= 2.5 AND e.promotions_count = 0 THEN 10 ELSE 0 END
    ) AS flight_risk_index,
    CASE
        WHEN (
            CASE WHEN e.compa_ratio < 0.85 THEN 35 WHEN e.compa_ratio < 0.92 THEN 20 WHEN e.compa_ratio < 0.98 THEN 10 ELSE 0 END +
            CASE WHEN e.monthly_overtime_hours > 25 THEN 30 WHEN e.monthly_overtime_hours > 15 THEN 18 WHEN e.monthly_overtime_hours > 8 THEN 8 ELSE 0 END +
            CASE WHEN e.satisfaction_score <= 2 THEN 25 WHEN e.satisfaction_score = 3 THEN 12 ELSE 0 END +
            CASE WHEN e.tenure_years >= 2.5 AND e.promotions_count = 0 THEN 10 ELSE 0 END
        ) >= 70 THEN 'CRITICAL RISK'
        WHEN (
            CASE WHEN e.compa_ratio < 0.85 THEN 35 WHEN e.compa_ratio < 0.92 THEN 20 WHEN e.compa_ratio < 0.98 THEN 10 ELSE 0 END +
            CASE WHEN e.monthly_overtime_hours > 25 THEN 30 WHEN e.monthly_overtime_hours > 15 THEN 18 WHEN e.monthly_overtime_hours > 8 THEN 8 ELSE 0 END +
            CASE WHEN e.satisfaction_score <= 2 THEN 25 WHEN e.satisfaction_score = 3 THEN 12 ELSE 0 END +
            CASE WHEN e.tenure_years >= 2.5 AND e.promotions_count = 0 THEN 10 ELSE 0 END
        ) >= 50 THEN 'HIGH RISK'
        WHEN (
            CASE WHEN e.compa_ratio < 0.85 THEN 35 WHEN e.compa_ratio < 0.92 THEN 20 WHEN e.compa_ratio < 0.98 THEN 10 ELSE 0 END +
            CASE WHEN e.monthly_overtime_hours > 25 THEN 30 WHEN e.monthly_overtime_hours > 15 THEN 18 WHEN e.monthly_overtime_hours > 8 THEN 8 ELSE 0 END +
            CASE WHEN e.satisfaction_score <= 2 THEN 25 WHEN e.satisfaction_score = 3 THEN 12 ELSE 0 END +
            CASE WHEN e.tenure_years >= 2.5 AND e.promotions_count = 0 THEN 10 ELSE 0 END
        ) >= 30 THEN 'MODERATE RISK'
        ELSE 'LOW RISK'
    END AS risk_tier
FROM employees e
JOIN departments d ON e.department_id = d.department_id
JOIN job_roles j ON e.job_id = j.job_id
LEFT JOIN employees m ON e.manager_id = m.employee_id
WHERE e.employment_status = 'Active';
