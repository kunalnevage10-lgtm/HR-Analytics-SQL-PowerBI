-- ==============================================================================
-- 01_data_profiling_and_qc.sql
-- HR Analytics Portfolio: Data Quality, Integrity Audits & Profiling
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. NULL Value & Missing Data Audit Across Key Fields
-- Ensures no critical operational or analytical fields have unexpected nulls.
-- ------------------------------------------------------------------------------
SELECT
    'employees' AS table_name,
    COUNT(*) AS total_records,
    SUM(CASE WHEN employee_id IS NULL THEN 1 ELSE 0 END) AS null_emp_ids,
    SUM(CASE WHEN email IS NULL THEN 1 ELSE 0 END) AS null_emails,
    SUM(CASE WHEN hire_date IS NULL THEN 1 ELSE 0 END) AS null_hire_dates,
    SUM(CASE WHEN base_salary IS NULL OR base_salary <= 0 THEN 1 ELSE 0 END) AS invalid_salaries,
    SUM(CASE WHEN department_id IS NULL THEN 1 ELSE 0 END) AS null_departments,
    SUM(CASE WHEN job_id IS NULL THEN 1 ELSE 0 END) AS null_jobs,
    SUM(CASE WHEN location_id IS NULL THEN 1 ELSE 0 END) AS null_locations,
    SUM(CASE WHEN employment_status = 'Terminated' AND exit_date IS NULL THEN 1 ELSE 0 END) AS missing_exit_dates
FROM employees;

-- ------------------------------------------------------------------------------
-- 2. Date Chronology & Logical Integrity Check
-- Verifies that no exit dates occur prior to hire dates or in the future.
-- ------------------------------------------------------------------------------
SELECT
    employee_id,
    first_name,
    last_name,
    hire_date,
    exit_date,
    tenure_years,
    CASE 
        WHEN exit_date < hire_date THEN 'ERROR: Exit before Hire'
        WHEN hire_date > '2024-12-31' THEN 'ERROR: Future Hire'
        WHEN tenure_years < 0 THEN 'ERROR: Negative Tenure'
        ELSE 'VALID'
    END AS integrity_status
FROM employees
WHERE exit_date < hire_date 
   OR hire_date > '2024-12-31' 
   OR tenure_years < 0;

-- ------------------------------------------------------------------------------
-- 3. Referential Integrity Check (Orphaned Foreign Keys)
-- Validates that all department_id, job_id, location_id, and manager_id exist.
-- ------------------------------------------------------------------------------
SELECT 
    'Orphaned Department' AS issue_type, COUNT(*) AS anomaly_count
FROM employees e
LEFT JOIN departments d ON e.department_id = d.department_id
WHERE d.department_id IS NULL
UNION ALL
SELECT 
    'Orphaned Job Role' AS issue_type, COUNT(*) AS anomaly_count
FROM employees e
LEFT JOIN job_roles j ON e.job_id = j.job_id
WHERE j.job_id IS NULL
UNION ALL
SELECT 
    'Orphaned Location' AS issue_type, COUNT(*) AS anomaly_count
FROM employees e
LEFT JOIN locations l ON e.location_id = l.location_id
WHERE l.location_id IS NULL
UNION ALL
SELECT 
    'Orphaned Manager' AS issue_type, COUNT(*) AS anomaly_count
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.employee_id
WHERE e.manager_id IS NOT NULL AND m.employee_id IS NULL;

-- ------------------------------------------------------------------------------
-- 4. Compensation Boundary & Compa-Ratio Outlier Profiling
-- Identifies employees paid outside official salary bands or with extreme compa-ratios.
-- ------------------------------------------------------------------------------
SELECT
    e.employee_id,
    e.first_name || ' ' || e.last_name AS employee_name,
    d.department_name,
    j.job_title,
    j.job_level,
    e.base_salary,
    j.salary_band_min,
    j.salary_band_max,
    e.compa_ratio,
    CASE
        WHEN e.base_salary < j.salary_band_min THEN 'Below Band Minimum'
        WHEN e.base_salary > j.salary_band_max THEN 'Above Band Maximum'
        WHEN e.compa_ratio < 0.80 THEN 'Extreme Low Compa (<0.80)'
        WHEN e.compa_ratio > 1.20 THEN 'Extreme High Compa (>1.20)'
        ELSE 'Within Acceptable Range'
    END AS compensation_health_flag
FROM employees e
JOIN job_roles j ON e.job_id = j.job_id
JOIN departments d ON e.department_id = d.department_id
WHERE e.base_salary < j.salary_band_min 
   OR e.base_salary > j.salary_band_max
   OR e.compa_ratio < 0.80 
   OR e.compa_ratio > 1.20
ORDER BY e.compa_ratio ASC
LIMIT 10;
