-- ==============================================================================
-- HR ANALYTICS REPOSITORY: RELATIONAL SCHEMA DEFINITION (DDL)
-- Dialect: ANSI SQL / SQLite / PostgreSQL / MySQL / SQL Server compatible
-- ==============================================================================

-- 1. Departments Table
CREATE TABLE IF NOT EXISTS departments (
    department_id       INTEGER PRIMARY KEY,
    department_name     VARCHAR(100) NOT NULL,
    division            VARCHAR(100) NOT NULL,
    cost_center         VARCHAR(20)  NOT NULL UNIQUE,
    headcount_budget    INTEGER      NOT NULL CHECK (headcount_budget > 0)
);

-- 2. Locations / Offices Table
CREATE TABLE IF NOT EXISTS locations (
    location_id             INTEGER PRIMARY KEY,
    city                    VARCHAR(100) NOT NULL,
    state_province          VARCHAR(100) NOT NULL,
    country                 VARCHAR(50)  NOT NULL,
    region                  VARCHAR(50)  NOT NULL,
    cost_of_living_index    DECIMAL(4,2) NOT NULL CHECK (cost_of_living_index > 0),
    office_type             VARCHAR(50)  NOT NULL
);

-- 3. Job Roles & Salary Bands Table
CREATE TABLE IF NOT EXISTS job_roles (
    job_id              INTEGER PRIMARY KEY,
    job_title           VARCHAR(100) NOT NULL,
    department_id       INTEGER      NOT NULL,
    job_level           VARCHAR(20)  NOT NULL, -- L1 to L5, M1-M2, E1
    salary_band_min     DECIMAL(12,2) NOT NULL CHECK (salary_band_min > 0),
    salary_band_mid     DECIMAL(12,2) NOT NULL CHECK (salary_band_mid >= salary_band_min),
    salary_band_max     DECIMAL(12,2) NOT NULL CHECK (salary_band_max >= salary_band_mid),
    CONSTRAINT fk_job_department FOREIGN KEY (department_id) REFERENCES departments(department_id)
);

-- 4. Employees Master Table
CREATE TABLE IF NOT EXISTS employees (
    employee_id             INTEGER PRIMARY KEY,
    first_name              VARCHAR(50)  NOT NULL,
    last_name               VARCHAR(50)  NOT NULL,
    email                   VARCHAR(100) NOT NULL UNIQUE,
    gender                  VARCHAR(20)  NOT NULL CHECK (gender IN ('Female', 'Male', 'Non-Binary')),
    birth_date              DATE         NOT NULL,
    education_level         VARCHAR(50)  NOT NULL,
    hire_date               DATE         NOT NULL,
    exit_date               DATE,
    employment_status       VARCHAR(20)  NOT NULL CHECK (employment_status IN ('Active', 'Terminated')),
    termination_type        VARCHAR(30)  CHECK (termination_type IN ('Voluntary', 'Involuntary', 'Retirement', NULL)),
    termination_reason      VARCHAR(100),
    department_id           INTEGER      NOT NULL,
    job_id                  INTEGER      NOT NULL,
    manager_id              INTEGER,
    location_id             INTEGER      NOT NULL,
    base_salary             DECIMAL(12,2) NOT NULL CHECK (base_salary > 0),
    compa_ratio             DECIMAL(5,3) NOT NULL CHECK (compa_ratio > 0),
    performance_rating      INTEGER      NOT NULL CHECK (performance_rating BETWEEN 1 AND 5),
    satisfaction_score      INTEGER      NOT NULL CHECK (satisfaction_score BETWEEN 1 AND 5),
    work_life_balance_score INTEGER      NOT NULL CHECK (work_life_balance_score BETWEEN 1 AND 5),
    monthly_overtime_hours  INTEGER      NOT NULL DEFAULT 0 CHECK (monthly_overtime_hours >= 0),
    remote_ratio_pct        INTEGER      NOT NULL CHECK (remote_ratio_pct IN (0, 50, 100)),
    promotions_count        INTEGER      NOT NULL DEFAULT 0 CHECK (promotions_count >= 0),
    last_promotion_date     DATE,
    tenure_years            DECIMAL(5,2) NOT NULL CHECK (tenure_years >= 0),
    
    -- Constraints & Foreign Keys
    CONSTRAINT fk_emp_dept     FOREIGN KEY (department_id) REFERENCES departments(department_id),
    CONSTRAINT fk_emp_job      FOREIGN KEY (job_id)        REFERENCES job_roles(job_id),
    CONSTRAINT fk_emp_location FOREIGN KEY (location_id)   REFERENCES locations(location_id),
    CONSTRAINT fk_emp_manager  FOREIGN KEY (manager_id)    REFERENCES employees(employee_id),
    CONSTRAINT chk_exit_order  CHECK (exit_date IS NULL OR exit_date >= hire_date)
);

-- 5. Annual Performance Reviews Table
CREATE TABLE IF NOT EXISTS performance_reviews (
    review_id           INTEGER PRIMARY KEY,
    employee_id         INTEGER NOT NULL,
    review_year         INTEGER NOT NULL CHECK (review_year BETWEEN 2018 AND 2030),
    review_date         DATE    NOT NULL,
    rating              INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
    goals_met_pct       INTEGER NOT NULL CHECK (goals_met_pct >= 0),
    potential_rating    VARCHAR(20) NOT NULL CHECK (potential_rating IN ('Low', 'Medium', 'High')),
    CONSTRAINT fk_rev_emp FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

-- 6. Historical Compensation & Promotion Log Table
CREATE TABLE IF NOT EXISTS salary_history (
    history_id          INTEGER PRIMARY KEY,
    employee_id         INTEGER NOT NULL,
    effective_date      DATE    NOT NULL,
    previous_salary     DECIMAL(12,2) NOT NULL CHECK (previous_salary >= 0),
    new_salary          DECIMAL(12,2) NOT NULL CHECK (new_salary > 0),
    salary_change_pct   DECIMAL(6,2) NOT NULL,
    change_reason       VARCHAR(50)  NOT NULL CHECK (change_reason IN ('New Hire', 'Annual Merit', 'Promotion', 'Market Adjustment')),
    CONSTRAINT fk_hist_emp FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

-- ==============================================================================
-- INDEX OPTIMIZATIONS FOR ANALYTICS QUERY PERFORMANCE
-- ==============================================================================
CREATE INDEX IF NOT EXISTS idx_employees_department ON employees(department_id);
CREATE INDEX IF NOT EXISTS idx_employees_job ON employees(job_id);
CREATE INDEX IF NOT EXISTS idx_employees_location ON employees(location_id);
CREATE INDEX IF NOT EXISTS idx_employees_manager ON employees(manager_id);
CREATE INDEX IF NOT EXISTS idx_employees_status ON employees(employment_status);
CREATE INDEX IF NOT EXISTS idx_employees_hire_date ON employees(hire_date);
CREATE INDEX IF NOT EXISTS idx_employees_exit_date ON employees(exit_date);
CREATE INDEX IF NOT EXISTS idx_salary_history_employee ON salary_history(employee_id, effective_date);
CREATE INDEX IF NOT EXISTS idx_reviews_employee_year ON performance_reviews(employee_id, review_year);
