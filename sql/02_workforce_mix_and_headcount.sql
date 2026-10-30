-- ==============================================================================
-- 02_workforce_mix_and_headcount.sql
-- HR Analytics Portfolio: Workforce Mix, Demographics & Span of Control
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. Departmental Headcount vs. Board Budget Variance
-- Evaluates current staffing levels against budgeted headcounts.
-- ------------------------------------------------------------------------------
SELECT
    d.department_id,
    d.department_name,
    d.division,
    d.headcount_budget,
    COUNT(CASE WHEN e.employment_status = 'Active' THEN 1 END) AS active_headcount,
    COUNT(CASE WHEN e.employment_status = 'Active' THEN 1 END) - d.headcount_budget AS budget_variance,
    ROUND(
        (COUNT(CASE WHEN e.employment_status = 'Active' THEN 1 END) * 100.0) / d.headcount_budget, 1
    ) AS budget_fill_pct,
    COUNT(CASE WHEN e.employment_status = 'Terminated' THEN 1 END) AS historical_departures,
    COUNT(e.employee_id) AS total_cumulative_hires
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id
GROUP BY d.department_id, d.department_name, d.division, d.headcount_budget
ORDER BY active_headcount DESC;

-- ------------------------------------------------------------------------------
-- 2. Span of Control: Manager-to-Direct-Report Ratios
-- Uses self-joins to evaluate management overhead and team sizes.
-- ------------------------------------------------------------------------------
WITH manager_report_counts AS (
    SELECT
        m.employee_id AS manager_id,
        m.first_name || ' ' || m.last_name AS manager_name,
        d.department_name,
        j.job_title AS manager_title,
        j.job_level AS manager_level,
        COUNT(e.employee_id) AS direct_reports_count,
        ROUND(AVG(e.satisfaction_score), 2) AS team_avg_satisfaction,
        ROUND(AVG(e.monthly_overtime_hours), 1) AS team_avg_overtime,
        ROUND(
            (SUM(CASE WHEN e.employment_status = 'Terminated' THEN 1 ELSE 0 END) * 100.0) / COUNT(e.employee_id), 1
        ) AS team_attrition_rate_pct
    FROM employees m
    JOIN employees e ON m.employee_id = e.manager_id
    JOIN departments d ON m.department_id = d.department_id
    JOIN job_roles j ON m.job_id = j.job_id
    GROUP BY m.employee_id, m.first_name, m.last_name, d.department_name, j.job_title, j.job_level
)
SELECT
    manager_id,
    manager_name,
    department_name,
    manager_title,
    manager_level,
    direct_reports_count,
    team_avg_satisfaction,
    team_avg_overtime,
    team_attrition_rate_pct,
    CASE 
        WHEN direct_reports_count > 12 THEN 'High Span (>12 Reports)'
        WHEN direct_reports_count BETWEEN 5 AND 12 THEN 'Optimal Span (5-12 Reports)'
        ELSE 'Narrow Span (<5 Reports)'
    END AS span_classification
FROM manager_report_counts
ORDER BY direct_reports_count DESC;

-- ------------------------------------------------------------------------------
-- 3. Workplace Flexibility & Remote Work Distribution
-- Analyzes active employee distribution across Remote, Hybrid, and On-site modalities.
-- ------------------------------------------------------------------------------
SELECT
    d.department_name,
    COUNT(e.employee_id) AS active_headcount,
    SUM(CASE WHEN e.remote_ratio_pct = 100 THEN 1 ELSE 0 END) AS fully_remote_count,
    SUM(CASE WHEN e.remote_ratio_pct = 50 THEN 1 ELSE 0 END) AS hybrid_count,
    SUM(CASE WHEN e.remote_ratio_pct = 0 THEN 1 ELSE 0 END) AS on_site_count,
    ROUND((SUM(CASE WHEN e.remote_ratio_pct = 100 THEN 1 ELSE 0 END) * 100.0) / COUNT(e.employee_id), 1) AS remote_pct,
    ROUND((SUM(CASE WHEN e.remote_ratio_pct = 50 THEN 1 ELSE 0 END) * 100.0) / COUNT(e.employee_id), 1) AS hybrid_pct,
    ROUND((SUM(CASE WHEN e.remote_ratio_pct = 0 THEN 1 ELSE 0 END) * 100.0) / COUNT(e.employee_id), 1) AS onsite_pct
FROM employees e
JOIN departments d ON e.department_id = d.department_id
WHERE e.employment_status = 'Active'
GROUP BY d.department_id, d.department_name
ORDER BY active_headcount DESC;

-- ------------------------------------------------------------------------------
-- 4. Gender Representation & Diversity Across Career Tiers
-- Demonstrates CTEs and conditional aggregation across organizational seniority levels.
-- ------------------------------------------------------------------------------
WITH level_gender_matrix AS (
    SELECT
        j.job_level,
        CASE
            WHEN j.job_level IN ('L1', 'L2') THEN '1. Junior / Associate (L1-L2)'
            WHEN j.job_level IN ('L3', 'L4') THEN '2. Senior / Staff (L3-L4)'
            WHEN j.job_level IN ('M1', 'M2') THEN '3. Management / Leadership (M1-M2)'
            WHEN j.job_level = 'E1' THEN '4. Executive (E1)'
            ELSE 'Other'
        END AS seniority_tier,
        e.gender,
        COUNT(e.employee_id) AS head_count
    FROM employees e
    JOIN job_roles j ON e.job_id = j.job_id
    WHERE e.employment_status = 'Active'
    GROUP BY j.job_level, seniority_tier, e.gender
)
SELECT
    seniority_tier,
    SUM(CASE WHEN gender = 'Female' THEN head_count ELSE 0 END) AS female_count,
    SUM(CASE WHEN gender = 'Male' THEN head_count ELSE 0 END) AS male_count,
    SUM(CASE WHEN gender = 'Non-Binary' THEN head_count ELSE 0 END) AS non_binary_count,
    SUM(head_count) AS total_headcount,
    ROUND((SUM(CASE WHEN gender = 'Female' THEN head_count ELSE 0 END) * 100.0) / SUM(head_count), 1) AS female_representation_pct,
    ROUND((SUM(CASE WHEN gender = 'Male' THEN head_count ELSE 0 END) * 100.0) / SUM(head_count), 1) AS male_representation_pct
FROM level_gender_matrix
GROUP BY seniority_tier
ORDER BY seniority_tier;
