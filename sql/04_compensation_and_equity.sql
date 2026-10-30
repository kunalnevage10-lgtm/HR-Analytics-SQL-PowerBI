-- ==============================================================================
-- 04_compensation_and_equity.sql
-- HR Analytics Portfolio: Salary Distribution, Compa-Ratio & Pay Equity
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. Salary Percentiles & Quartiles using NTILE() and DENSE_RANK()
-- Demonstrates window ranking functions across department and career tiers.
-- ------------------------------------------------------------------------------
WITH ranked_salaries AS (
    SELECT
        e.employee_id,
        e.first_name || ' ' || e.last_name AS employee_name,
        d.department_name,
        j.job_title,
        j.job_level,
        e.base_salary,
        e.compa_ratio,
        NTILE(4) OVER (PARTITION BY j.job_level ORDER BY e.base_salary ASC) AS level_salary_quartile,
        DENSE_RANK() OVER (PARTITION BY d.department_name ORDER BY e.base_salary DESC) AS dept_salary_rank,
        ROUND(
            AVG(e.base_salary) OVER (PARTITION BY j.job_id), 0
        ) AS role_avg_salary
    FROM employees e
    JOIN departments d ON e.department_id = d.department_id
    JOIN job_roles j ON e.job_id = j.job_id
    WHERE e.employment_status = 'Active'
)
SELECT
    employee_id,
    employee_name,
    department_name,
    job_title,
    job_level,
    base_salary,
    role_avg_salary,
    (base_salary - role_avg_salary) AS variance_from_role_avg,
    level_salary_quartile,
    dept_salary_rank
FROM ranked_salaries
WHERE dept_salary_rank <= 3
ORDER BY department_name, dept_salary_rank;

-- ------------------------------------------------------------------------------
-- 2. Compa-Ratio Penetration by Department & Seniority
-- Compares actual pay distribution against standard market bands (Midpoint = 1.00).
-- ------------------------------------------------------------------------------
SELECT
    d.department_name,
    COUNT(e.employee_id) AS active_headcount,
    ROUND(MIN(e.compa_ratio), 2) AS min_compa_ratio,
    ROUND(AVG(e.compa_ratio), 2) AS avg_compa_ratio,
    ROUND(MAX(e.compa_ratio), 2) AS max_compa_ratio,
    SUM(CASE WHEN e.compa_ratio < 0.85 THEN 1 ELSE 0 END) AS underpaid_flight_risk_count,
    SUM(CASE WHEN e.compa_ratio BETWEEN 0.85 AND 1.15 THEN 1 ELSE 0 END) AS target_market_band_count,
    SUM(CASE WHEN e.compa_ratio > 1.15 THEN 1 ELSE 0 END) AS premium_pay_count,
    ROUND(
        (SUM(CASE WHEN e.compa_ratio < 0.85 THEN 1 ELSE 0 END) * 100.0) / COUNT(e.employee_id), 1
    ) AS underpaid_pct
FROM employees e
JOIN departments d ON e.department_id = d.department_id
WHERE e.employment_status = 'Active'
GROUP BY d.department_id, d.department_name
ORDER BY underpaid_pct DESC;

-- ------------------------------------------------------------------------------
-- 3. Salary Compression Analysis: Tenure vs. Compensation Disparity
-- Detects inverted pay structures where tenured staff (tenure > 3 yrs) earn less
-- than newer hires (tenure <= 1.5 yrs) within the exact same job role.
-- ------------------------------------------------------------------------------
WITH role_tenure_salaries AS (
    SELECT
        j.job_id,
        j.job_title,
        d.department_name,
        AVG(CASE WHEN e.tenure_years <= 1.5 THEN e.base_salary END) AS avg_recent_hire_salary,
        COUNT(CASE WHEN e.tenure_years <= 1.5 THEN 1 END) AS recent_hire_count,
        AVG(CASE WHEN e.tenure_years >= 3.0 THEN e.base_salary END) AS avg_tenured_salary,
        COUNT(CASE WHEN e.tenure_years >= 3.0 THEN 1 END) AS tenured_count
    FROM employees e
    JOIN job_roles j ON e.job_id = j.job_id
    JOIN departments d ON e.department_id = d.department_id
    WHERE e.employment_status = 'Active'
    GROUP BY j.job_id, j.job_title, d.department_name
)
SELECT
    job_title,
    department_name,
    recent_hire_count,
    ROUND(avg_recent_hire_salary, 0) AS avg_recent_hire_salary,
    tenured_count,
    ROUND(avg_tenured_salary, 0) AS avg_tenured_salary,
    ROUND(avg_recent_hire_salary - avg_tenured_salary, 0) AS salary_compression_gap,
    CASE 
        WHEN avg_recent_hire_salary > avg_tenured_salary THEN 'ALERT: Inversion Detected (New > Tenured)'
        WHEN (avg_tenured_salary - avg_recent_hire_salary) < 5000 THEN 'WARNING: Severe Compression'
        ELSE 'Healthy Premium for Tenure'
    END AS compression_status
FROM role_tenure_salaries
WHERE recent_hire_count > 0 AND tenured_count > 0
ORDER BY salary_compression_gap DESC;

-- ------------------------------------------------------------------------------
-- 4. Gender Pay Equity Analysis (Unadjusted vs. Level-Adjusted)
-- Compares average pay across genders, controlling for job level and tenure.
-- ------------------------------------------------------------------------------
SELECT
    j.job_level,
    COUNT(CASE WHEN e.gender = 'Female' THEN 1 END) AS female_count,
    ROUND(AVG(CASE WHEN e.gender = 'Female' THEN e.base_salary END), 0) AS avg_female_salary,
    ROUND(AVG(CASE WHEN e.gender = 'Female' THEN e.compa_ratio END), 3) AS avg_female_compa,
    COUNT(CASE WHEN e.gender = 'Male' THEN 1 END) AS male_count,
    ROUND(AVG(CASE WHEN e.gender = 'Male' THEN e.base_salary END), 0) AS avg_male_salary,
    ROUND(AVG(CASE WHEN e.gender = 'Male' THEN e.compa_ratio END), 3) AS avg_male_compa,
    ROUND(
        ((AVG(CASE WHEN e.gender = 'Male' THEN e.base_salary END) - 
          AVG(CASE WHEN e.gender = 'Female' THEN e.base_salary END)) * 100.0) 
        / NULLIF(AVG(CASE WHEN e.gender = 'Male' THEN e.base_salary END), 0), 2
    ) AS raw_pay_gap_pct,
    ROUND(
        (AVG(CASE WHEN e.gender = 'Female' THEN e.compa_ratio END) - 
         AVG(CASE WHEN e.gender = 'Male' THEN e.compa_ratio END)), 3
    ) AS compa_ratio_differential
FROM employees e
JOIN job_roles j ON e.job_id = j.job_id
WHERE e.employment_status = 'Active' AND e.gender IN ('Female', 'Male')
GROUP BY j.job_level
ORDER BY j.job_level;
