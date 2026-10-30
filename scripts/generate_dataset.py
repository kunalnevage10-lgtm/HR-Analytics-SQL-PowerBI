"""
HR Analytics Synthetic Dataset Generator
Generates a realistic, statistically coherent employee relational dataset
for workforce planning, salary benchmarking, and attrition analysis.
Outputs SQLite database, raw CSVs, Power BI star schema files, and Excel model.
"""

import os
import random
import datetime
import sqlite3
import numpy as np
import pandas as pd

# Set deterministic random seed
SEED = 42
random.seed(SEED)
np.random.seed(SEED)

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(PROJECT_ROOT, "data")
RAW_CSV_DIR = os.path.join(DATA_DIR, "raw_csv")
STAR_SCHEMA_DIR = os.path.join(DATA_DIR, "powerbi_star_schema")
DB_PATH = os.path.join(DATA_DIR, "hr_analytics.db")
EXCEL_PATH = os.path.join(DATA_DIR, "HR_Analytics_Executive_Model.xlsx")

os.makedirs(RAW_CSV_DIR, exist_ok=True)
os.makedirs(STAR_SCHEMA_DIR, exist_ok=True)

print("Starting HR Analytics Data Generation...")

# ==============================================================================
# 1. REFERENCE TABLES: DEPARTMENTS, LOCATIONS, JOB ROLES
# ==============================================================================

departments_data = [
    {"department_id": 1, "department_name": "Engineering", "division": "Technology", "cost_center": "CC-101", "headcount_budget": 420},
    {"department_id": 2, "department_name": "Sales", "division": "Commercial", "cost_center": "CC-102", "headcount_budget": 240},
    {"department_id": 3, "department_name": "Product & Design", "division": "Technology", "cost_center": "CC-103", "headcount_budget": 130},
    {"department_id": 4, "department_name": "Marketing", "division": "Commercial", "cost_center": "CC-104", "headcount_budget": 120},
    {"department_id": 5, "department_name": "Customer Support", "division": "Operations", "cost_center": "CC-105", "headcount_budget": 180},
    {"department_id": 6, "department_name": "Human Resources", "division": "Corporate", "cost_center": "CC-106", "headcount_budget": 60},
    {"department_id": 7, "department_name": "Finance & Legal", "division": "Corporate", "cost_center": "CC-107", "headcount_budget": 70},
]
df_departments = pd.DataFrame(departments_data)

locations_data = [
    {"location_id": 1, "city": "New York", "state_province": "NY", "country": "USA", "region": "North America", "cost_of_living_index": 1.35, "office_type": "Regional HQ"},
    {"location_id": 2, "city": "San Francisco", "state_province": "CA", "country": "USA", "region": "North America", "cost_of_living_index": 1.45, "office_type": "Corporate HQ"},
    {"location_id": 3, "city": "Austin", "state_province": "TX", "country": "USA", "region": "North America", "cost_of_living_index": 1.05, "office_type": "Tech Hub"},
    {"location_id": 4, "city": "Chicago", "state_province": "IL", "country": "USA", "region": "North America", "cost_of_living_index": 1.15, "office_type": "Branch Office"},
    {"location_id": 5, "city": "London", "state_province": "Greater London", "country": "UK", "region": "EMEA", "cost_of_living_index": 1.30, "office_type": "International HQ"},
    {"location_id": 6, "city": "Remote Hub", "state_province": "Nationwide", "country": "USA", "region": "Distributed", "cost_of_living_index": 1.00, "office_type": "Virtual"},
]
df_locations = pd.DataFrame(locations_data)

job_roles_data = [
    # Engineering
    {"job_id": 1, "job_title": "Associate Software Engineer", "department_id": 1, "job_level": "L1", "salary_band_min": 75000, "salary_band_mid": 90000, "salary_band_max": 105000},
    {"job_id": 2, "job_title": "Software Engineer", "department_id": 1, "job_level": "L2", "salary_band_min": 100000, "salary_band_mid": 120000, "salary_band_max": 140000},
    {"job_id": 3, "job_title": "Senior Software Engineer", "department_id": 1, "job_level": "L3", "salary_band_min": 135000, "salary_band_mid": 155000, "salary_band_max": 180000},
    {"job_id": 4, "job_title": "Staff Software Engineer", "department_id": 1, "job_level": "L4", "salary_band_min": 175000, "salary_band_mid": 200000, "salary_band_max": 230000},
    {"job_id": 5, "job_title": "Engineering Manager", "department_id": 1, "job_level": "M1", "salary_band_min": 180000, "salary_band_mid": 210000, "salary_band_max": 245000},
    {"job_id": 6, "job_title": "Director of Engineering", "department_id": 1, "job_level": "M2", "salary_band_min": 230000, "salary_band_mid": 265000, "salary_band_max": 310000},
    # Sales
    {"job_id": 7, "job_title": "Sales Development Rep (SDR)", "department_id": 2, "job_level": "L1", "salary_band_min": 50000, "salary_band_mid": 60000, "salary_band_max": 72000},
    {"job_id": 8, "job_title": "Account Executive", "department_id": 2, "job_level": "L2", "salary_band_min": 75000, "salary_band_mid": 92000, "salary_band_max": 115000},
    {"job_id": 9, "job_title": "Senior Enterprise AE", "department_id": 2, "job_level": "L3", "salary_band_min": 110000, "salary_band_mid": 135000, "salary_band_max": 165000},
    {"job_id": 10, "job_title": "Sales Manager", "department_id": 2, "job_level": "M1", "salary_band_min": 140000, "salary_band_mid": 165000, "salary_band_max": 195000},
    {"job_id": 11, "job_title": "VP of Sales", "department_id": 2, "job_level": "E1", "salary_band_min": 240000, "salary_band_mid": 280000, "salary_band_max": 330000},
    # Product & Design
    {"job_id": 12, "job_title": "Associate Product Designer", "department_id": 3, "job_level": "L1", "salary_band_min": 70000, "salary_band_mid": 82000, "salary_band_max": 95000},
    {"job_id": 13, "job_title": "Product Designer", "department_id": 3, "job_level": "L2", "salary_band_min": 95000, "salary_band_mid": 112000, "salary_band_max": 130000},
    {"job_id": 14, "job_title": "Product Manager", "department_id": 3, "job_level": "L3", "salary_band_min": 125000, "salary_band_mid": 145000, "salary_band_max": 170000},
    {"job_id": 15, "job_title": "Director of Product", "department_id": 3, "job_level": "M2", "salary_band_min": 210000, "salary_band_mid": 245000, "salary_band_max": 285000},
    # Marketing
    {"job_id": 16, "job_title": "Marketing Specialist", "department_id": 4, "job_level": "L1", "salary_band_min": 55000, "salary_band_mid": 65000, "salary_band_max": 78000},
    {"job_id": 17, "job_title": "Senior Growth Marketer", "department_id": 4, "job_level": "L3", "salary_band_min": 95000, "salary_band_mid": 115000, "salary_band_max": 135000},
    {"job_id": 18, "job_title": "Marketing Director", "department_id": 4, "job_level": "M2", "salary_band_min": 175000, "salary_band_mid": 205000, "salary_band_max": 240000},
    # Customer Support
    {"job_id": 19, "job_title": "Support Specialist", "department_id": 5, "job_level": "L1", "salary_band_min": 42000, "salary_band_mid": 50000, "salary_band_max": 60000},
    {"job_id": 20, "job_title": "Senior Support Specialist", "department_id": 5, "job_level": "L2", "salary_band_min": 55000, "salary_band_mid": 66000, "salary_band_max": 78000},
    {"job_id": 21, "job_title": "Support Operations Manager", "department_id": 5, "job_level": "M1", "salary_band_min": 90000, "salary_band_mid": 110000, "salary_band_max": 130000},
    # HR
    {"job_id": 22, "job_title": "HR Generalist", "department_id": 6, "job_level": "L2", "salary_band_min": 65000, "salary_band_mid": 78000, "salary_band_max": 92000},
    {"job_id": 23, "job_title": "People Operations Manager", "department_id": 6, "job_level": "M1", "salary_band_min": 115000, "salary_band_mid": 135000, "salary_band_max": 160000},
    # Finance
    {"job_id": 24, "job_title": "Financial Analyst", "department_id": 7, "job_level": "L2", "salary_band_min": 75000, "salary_band_mid": 88000, "salary_band_max": 105000},
    {"job_id": 25, "job_title": "Finance Director", "department_id": 7, "job_level": "M2", "salary_band_min": 190000, "salary_band_mid": 225000, "salary_band_max": 265000},
    # Executive
    {"job_id": 26, "job_title": "Chief Executive Officer (CEO)", "department_id": 7, "job_level": "E1", "salary_band_min": 350000, "salary_band_mid": 450000, "salary_band_max": 550000},
]
df_job_roles = pd.DataFrame(job_roles_data)

# Name pools
first_names_f = ["Emma", "Olivia", "Sophia", "Ava", "Isabella", "Mia", "Amelia", "Harper", "Evelyn", "Abigail", "Emily", "Ella", "Elizabeth", "Camila", "Luna", "Sofia", "Avery", "Mila", "Aria", "Scarlett", "Chloe", "Layla", "Penelope", "Nora", "Grace", "Sarah", "Jessica", "Rachel", "Hannah", "Megan"]
first_names_m = ["Liam", "Noah", "Oliver", "James", "Elijah", "William", "Henry", "Lucas", "Benjamin", "Theodore", "Mateo", "Levi", "Sebastian", "Daniel", "Jack", "Alexander", "Owen", "Asher", "Samuel", "Ethan", "David", "Michael", "John", "Robert", "Marcus", "Brian", "Kevin", "Jason", "Tyler", "Brandon"]
first_names_nb = ["Alex", "Jordan", "Taylor", "Morgan", "Casey", "Riley", "Avery", "Quinn", "Skyler", "Cameron", "Rowan", "Reese", "Kendall", "Dakota", "Finley"]
last_names = ["Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguez", "Martinez", "Hernandez", "Lopez", "Gonzalez", "Wilson", "Anderson", "Thomas", "Taylor", "Moore", "Jackson", "Martin", "Lee", "Perez", "Thompson", "White", "Harris", "Sanchez", "Clark", "Ramirez", "Lewis", "Robinson", "Walker", "Young", "Allen", "King", "Wright", "Scott", "Torres", "Nguyen", "Hill", "Flores", "Green", "Adams", "Nelson", "Baker", "Hall", "Rivera", "Campbell", "Mitchell", "Carter", "Roberts"]

# Simulation parameters
TOTAL_EMPLOYEES = 1250
START_DATE = datetime.date(2018, 1, 15)
END_SIMULATION_DATE = datetime.date(2024, 12, 31)

# Generate employee hierarchy and details
employees_list = []
managers_by_dept = {d: [] for d in range(1, 8)}

# 1. Create CEO first (Employee 1001)
ceo = {
    "employee_id": 1001,
    "first_name": "Eleanor",
    "last_name": "Vance",
    "email": "eleanor.vance@company.com",
    "gender": "Female",
    "birth_date": "1974-06-12",
    "education_level": "Master's",
    "hire_date": "2018-01-15",
    "exit_date": None,
    "employment_status": "Active",
    "termination_type": None,
    "termination_reason": None,
    "department_id": 7,
    "job_id": 26, # CEO
    "manager_id": None,
    "location_id": 2, # SF
    "base_salary": 475000,
    "compa_ratio": round(475000 / 450000, 3),
    "performance_rating": 5,
    "satisfaction_score": 5,
    "work_life_balance_score": 3,
    "monthly_overtime_hours": 15,
    "remote_ratio_pct": 50,
    "promotions_count": 0,
    "last_promotion_date": None
}
employees_list.append(ceo)
managers_by_dept[7].append(1001)

# 2. Create Functional Heads (M2 / E1) reporting to CEO
directors_spec = [
    (1002, "David", "Kim", "Male", "1980-04-18", "Master's", "2018-02-01", 1, 6, 1001, 2, 280000),  # Eng Director
    (1003, "Sarah", "Jenkins", "Female", "1982-08-23", "Bachelor's", "2018-03-01", 2, 11, 1001, 1, 290000), # VP Sales
    (1004, "Marcus", "Chen", "Male", "1983-11-05", "Master's", "2018-02-15", 3, 15, 1001, 2, 255000), # Dir Product
    (1005, "Elena", "Rostova", "Female", "1985-03-12", "Bachelor's", "2018-04-01", 4, 18, 1001, 1, 215000), # Dir Marketing
    (1006, "Terrence", "Brooks", "Male", "1979-09-30", "Bachelor's", "2018-03-15", 5, 21, 1001, 3, 125000), # Support Mgr
    (1007, "Priya", "Patel", "Female", "1984-01-20", "Master's", "2018-02-01", 6, 23, 1001, 2, 145000), # People Mgr
    (1008, "Arthur", "Pendelton", "Male", "1978-05-14", "Master's", "2018-02-01", 7, 25, 1001, 1, 235000), # Finance Dir
]

for eid, fn, ln, gen, bdate, edu, hdate, did, jid, mid, loc, sal in directors_spec:
    mid_sal = df_job_roles.loc[df_job_roles["job_id"] == jid, "salary_band_mid"].values[0]
    emp = {
        "employee_id": eid,
        "first_name": fn,
        "last_name": ln,
        "email": f"{fn.lower()}.{ln.lower()}@company.com",
        "gender": gen,
        "birth_date": bdate,
        "education_level": edu,
        "hire_date": hdate,
        "exit_date": None,
        "employment_status": "Active",
        "termination_type": None,
        "termination_reason": None,
        "department_id": did,
        "job_id": jid,
        "manager_id": mid,
        "location_id": loc,
        "base_salary": sal,
        "compa_ratio": round(sal / mid_sal, 3),
        "performance_rating": random.choice([4, 5]),
        "satisfaction_score": random.choice([4, 5]),
        "work_life_balance_score": random.choice([3, 4]),
        "monthly_overtime_hours": random.randint(5, 20),
        "remote_ratio_pct": random.choice([0, 50, 100]),
        "promotions_count": 1,
        "last_promotion_date": "2021-03-01"
    }
    employees_list.append(emp)
    managers_by_dept[did].append(eid)

# 3. Create First-Line Managers (M1) for large depts
m1_spec = [
    (1009, "Engineering Mgr Frontend", 1, 5, 1002, 2),
    (1010, "Engineering Mgr Backend", 1, 5, 1002, 3),
    (1011, "Engineering Mgr Infrastructure", 1, 5, 1002, 6),
    (1012, "Engineering Mgr Mobile", 1, 5, 1002, 1),
    (1013, "Sales Manager East", 2, 10, 1003, 1),
    (1014, "Sales Manager West", 2, 10, 1003, 2),
    (1015, "Sales Manager EMEA", 2, 10, 1003, 5),
    (1016, "Support Lead Tier 1", 5, 21, 1006, 3),
    (1017, "Support Lead Tier 2", 5, 21, 1006, 4),
]

for eid, title, did, jid, mid, loc in m1_spec:
    gen = random.choice(["Female", "Male"])
    fn = random.choice(first_names_f if gen == "Female" else first_names_m)
    ln = random.choice(last_names)
    b_year = random.randint(1982, 1990)
    b_date = f"{b_year}-{random.randint(1,12):02d}-{random.randint(1,28):02d}"
    h_year = random.randint(2018, 2019)
    h_date = f"{h_year}-{random.randint(1,12):02d}-{random.randint(1,28):02d}"
    mid_sal = df_job_roles.loc[df_job_roles["job_id"] == jid, "salary_band_mid"].values[0]
    sal = int(np.random.normal(mid_sal, mid_sal * 0.05))
    emp = {
        "employee_id": eid,
        "first_name": fn,
        "last_name": ln,
        "email": f"{fn.lower()}.{ln.lower()}{eid}@company.com",
        "gender": gen,
        "birth_date": b_date,
        "education_level": random.choice(["Bachelor's", "Master's"]),
        "hire_date": h_date,
        "exit_date": None,
        "employment_status": "Active",
        "termination_type": None,
        "termination_reason": None,
        "department_id": did,
        "job_id": jid,
        "manager_id": mid,
        "location_id": loc,
        "base_salary": sal,
        "compa_ratio": round(sal / mid_sal, 3),
        "performance_rating": random.choice([3, 4, 5]),
        "satisfaction_score": random.choice([3, 4, 5]),
        "work_life_balance_score": random.choice([3, 4]),
        "monthly_overtime_hours": random.randint(8, 22),
        "remote_ratio_pct": random.choice([0, 50, 100]),
        "promotions_count": 1,
        "last_promotion_date": f"{h_year+2}-06-15"
    }
    employees_list.append(emp)
    managers_by_dept[did].append(eid)

# Department weights for remaining employees
# Engineering: 35%, Sales: 22%, Support: 16%, Product: 10%, Marketing: 8%, Finance: 5%, HR: 4%
dept_distribution = [1]*35 + [2]*22 + [5]*16 + [3]*10 + [4]*8 + [7]*5 + [6]*4

# Job mapping by department (IC roles)
dept_ic_jobs = {
    1: [1, 2, 3, 4], # Eng L1-L4
    2: [7, 8, 9],    # Sales L1-L3
    3: [12, 13, 14], # Product L1-L3
    4: [16, 17],     # Mktg L1, L3
    5: [19, 20],     # Support L1, L2
    6: [22],         # HR L2
    7: [24],         # Finance L2
}
job_weights = {
    1: [0.25, 0.40, 0.25, 0.10], # Eng: mostly L2 & L3
    2: [0.45, 0.40, 0.15],       # Sales: SDRs and AEs
    3: [0.30, 0.45, 0.25],       # Product: designers and PMs
    4: [0.60, 0.40],             # Marketing
    5: [0.70, 0.30],             # Support: mostly L1
    6: [1.0],                    # HR
    7: [1.0],                    # Finance
}

current_id = 1018
while current_id <= 1000 + TOTAL_EMPLOYEES:
    did = random.choice(dept_distribution)
    ic_jobs = dept_ic_jobs[did]
    weights = job_weights[did]
    jid = np.random.choice(ic_jobs, p=weights)
    
    # Manager selection from department
    manager_id = random.choice(managers_by_dept[did])
    
    # Demographics
    r_gen = random.random()
    if r_gen < 0.48:
        gen = "Female"
        fn = random.choice(first_names_f)
    elif r_gen < 0.95:
        gen = "Male"
        fn = random.choice(first_names_m)
    else:
        gen = "Non-Binary"
        fn = random.choice(first_names_nb)
    ln = random.choice(last_names)
    
    # Age & Education
    edu = np.random.choice(["Bachelor's", "Master's", "Doctorate", "Associate / High School"], p=[0.60, 0.28, 0.04, 0.08])
    if edu == "Doctorate":
        age = random.randint(28, 56)
    elif edu == "Master's":
        age = random.randint(25, 52)
    else:
        age = random.randint(22, 48)
        
    birth_year = 2024 - age
    birth_date = f"{birth_year}-{random.randint(1,12):02d}-{random.randint(1,28):02d}"
    
    # Hire date simulation (exponential growth from 2018 to 2024)
    # 2018: 10%, 2019: 14%, 2020: 16%, 2021: 22%, 2022: 18%, 2023: 12%, 2024: 8%
    hire_year = np.random.choice([2018, 2019, 2020, 2021, 2022, 2023, 2024], p=[0.10, 0.14, 0.16, 0.22, 0.18, 0.12, 0.08])
    hire_month = random.randint(1, 12)
    hire_day = random.randint(1, 28)
    h_date_obj = datetime.date(hire_year, hire_month, hire_day)
    hire_date_str = h_date_obj.strftime("%Y-%m-%d")
    
    # Location
    loc_id = np.random.choice([1, 2, 3, 4, 5, 6], p=[0.22, 0.25, 0.18, 0.12, 0.08, 0.15])
    
    # Remote ratio
    if loc_id == 6:
        remote_ratio = 100
    else:
        remote_ratio = np.random.choice([0, 50, 100], p=[0.30, 0.50, 0.20])
        
    # Salary within band
    band_row = df_job_roles.loc[df_job_roles["job_id"] == jid].iloc[0]
    b_min, b_mid, b_max = band_row["salary_band_min"], band_row["salary_band_mid"], band_row["salary_band_max"]
    
    # Generate compa-ratio centered around 0.98, sd=0.10
    cr = float(np.clip(np.random.normal(0.98, 0.11), 0.75, 1.25))
    base_salary = int(round((b_mid * cr) / 500) * 500)
    base_salary = max(b_min, min(b_max, base_salary))
    actual_cr = round(base_salary / b_mid, 3)
    
    # Overtime hours (Customer Support & Sales higher, tech lower except crunches)
    if did == 5: # Support
        ot_hours = int(np.random.choice([0, 10, 22, 32, 40], p=[0.15, 0.25, 0.30, 0.20, 0.10]))
    elif did == 2: # Sales
        ot_hours = int(np.random.choice([0, 8, 16, 25, 35], p=[0.25, 0.30, 0.25, 0.15, 0.05]))
    elif did == 1: # Eng
        ot_hours = int(np.random.choice([0, 5, 12, 22, 30], p=[0.35, 0.35, 0.15, 0.10, 0.05]))
    else:
        ot_hours = int(np.random.choice([0, 5, 10, 18], p=[0.50, 0.30, 0.15, 0.05]))
        
    # Work life balance & satisfaction correlated negatively with overtime
    if ot_hours > 25:
        wlb = np.random.choice([1, 2, 3], p=[0.50, 0.38, 0.12])
        sat = np.random.choice([1, 2, 3, 4], p=[0.40, 0.35, 0.20, 0.05])
    elif ot_hours > 15:
        wlb = np.random.choice([2, 3, 4], p=[0.35, 0.45, 0.20])
        sat = np.random.choice([2, 3, 4], p=[0.25, 0.50, 0.25])
    else:
        wlb = np.random.choice([3, 4, 5], p=[0.20, 0.50, 0.30])
        sat = np.random.choice([3, 4, 5], p=[0.15, 0.50, 0.35])
        
    # Performance rating (1 to 5)
    # Bell curve: 1(3%), 2(10%), 3(52%), 4(25%), 5(10%)
    perf = int(np.random.choice([1, 2, 3, 4, 5], p=[0.03, 0.10, 0.52, 0.25, 0.10]))
    
    # Promotion history
    tenure_days = (END_SIMULATION_DATE - h_date_obj).days
    years_since_hire = tenure_days / 365.25
    
    promotions = 0
    last_promo_date = None
    if years_since_hire >= 2.0 and perf >= 3:
        if random.random() < 0.45:
            promotions = 1
            promo_days = random.randint(365, min(int(tenure_days - 180), 365*3))
            promo_obj = h_date_obj + datetime.timedelta(days=promo_days)
            last_promo_date = promo_obj.strftime("%Y-%m-%d")
            if years_since_hire >= 4.0 and random.random() < 0.30:
                promotions = 2
                promo_days2 = random.randint(promo_days + 365, int(tenure_days - 90))
                promo_obj2 = h_date_obj + datetime.timedelta(days=promo_days2)
                last_promo_date = promo_obj2.strftime("%Y-%m-%d")
                
    # ==========================================================================
    # ATTRITION LOGIC (CORRELATED MODEL)
    # Base probability + risk adjustments
    # ==========================================================================
    base_attr_prob = 0.12 # ~12% annualized base rate
    
    # Risk factor: Compa-ratio
    if actual_cr < 0.85:
        base_attr_prob += 0.18 # underpaid flight risk
    elif actual_cr < 0.92:
        base_attr_prob += 0.08
    elif actual_cr > 1.10:
        base_attr_prob -= 0.05
        
    # Risk factor: Overtime
    if ot_hours > 25:
        base_attr_prob += 0.16
    elif ot_hours > 15:
        base_attr_prob += 0.06
        
    # Risk factor: Low Satisfaction
    if sat <= 2:
        base_attr_prob += 0.15
    elif sat == 3:
        base_attr_prob += 0.03
        
    # Risk factor: High performer stagnation (rating 4/5, tenure > 2.5 yrs, 0 promotions)
    if perf >= 4 and years_since_hire >= 2.5 and promotions == 0:
        base_attr_prob += 0.18
        
    # Risk factor: Department effect
    if did == 5: # Support (higher churn)
        base_attr_prob += 0.09
    elif did == 2: # Sales (quota churn)
        base_attr_prob += 0.06
    elif did in (6, 7): # HR / Finance (stability)
        base_attr_prob -= 0.06
        
    # Low performance involuntarily exited
    if perf == 1:
        base_attr_prob += 0.35
    elif perf == 2:
        base_attr_prob += 0.12

    # Scale total probability over employee's tenure
    cumulative_attr_prob = min(0.70, base_attr_prob * (years_since_hire / 2.8))
    
    # Decide if exited
    is_terminated = (random.random() < cumulative_attr_prob) and (years_since_hire >= 0.35)
    
    exit_date_str = None
    term_type = None
    term_reason = None
    status = "Active"
    
    if is_terminated:
        status = "Terminated"
        # Minimum tenure 90 days before exit
        max_possible_tenure = (END_SIMULATION_DATE - h_date_obj).days
        exit_offset = random.randint(90, max_possible_tenure)
        exit_date_obj = h_date_obj + datetime.timedelta(days=exit_offset)
        exit_date_str = exit_date_obj.strftime("%Y-%m-%d")
        
        # Determine termination type & reason
        if perf == 1 or (perf == 2 and random.random() < 0.65):
            term_type = "Involuntary"
            term_reason = "Performance Involuntary"
        elif random.random() < 0.06:
            term_type = "Involuntary"
            term_reason = "Company Restructuring"
        elif age >= 60 and random.random() < 0.70:
            term_type = "Retirement"
            term_reason = "Retirement"
        else:
            term_type = "Voluntary"
            if actual_cr < 0.88 and random.random() < 0.65:
                term_reason = "Better Compensation"
            elif ot_hours > 20 and random.random() < 0.60:
                term_reason = "Workplace Burnout / Overtime"
            elif perf >= 4 and promotions == 0 and random.random() < 0.55:
                term_reason = "Career Stagnation"
            elif remote_ratio == 0 and loc_id != 6 and random.random() < 0.40:
                term_reason = "Commute / Relocation"
            else:
                term_reason = random.choice(["Better Compensation", "Career Stagnation", "Personal / Family"])

    emp = {
        "employee_id": current_id,
        "first_name": fn,
        "last_name": ln,
        "email": f"{fn.lower()}.{ln.lower()}{current_id}@company.com",
        "gender": gen,
        "birth_date": birth_date,
        "education_level": edu,
        "hire_date": hire_date_str,
        "exit_date": exit_date_str,
        "employment_status": status,
        "termination_type": term_type,
        "termination_reason": term_reason,
        "department_id": did,
        "job_id": jid,
        "manager_id": manager_id,
        "location_id": loc_id,
        "base_salary": base_salary,
        "compa_ratio": actual_cr,
        "performance_rating": perf,
        "satisfaction_score": sat,
        "work_life_balance_score": wlb,
        "monthly_overtime_hours": ot_hours,
        "remote_ratio_pct": remote_ratio,
        "promotions_count": promotions,
        "last_promotion_date": last_promo_date
    }
    employees_list.append(emp)
    current_id += 1

df_employees = pd.DataFrame(employees_list)

# Calculate tenure in years
def calc_tenure(row):
    h = datetime.date.fromisoformat(row["hire_date"])
    e = datetime.date.fromisoformat(row["exit_date"]) if pd.notnull(row["exit_date"]) else END_SIMULATION_DATE
    return round((e - h).days / 365.25, 2)

df_employees["tenure_years"] = df_employees.apply(calc_tenure, axis=1)

print(f"Generated {len(df_employees)} employees.")
active_count = (df_employees["employment_status"] == "Active").sum()
term_count = (df_employees["employment_status"] == "Terminated").sum()
print(f"Active: {active_count}, Terminated: {term_count} (Attrition rate: {term_count/len(df_employees):.1%})")

# ==============================================================================
# 2. GENERATE PERFORMANCE REVIEWS TABLE
# ==============================================================================
reviews_list = []
review_id = 1

for _, emp in df_employees.iterrows():
    h_year = int(emp["hire_date"][:4])
    e_year = int(emp["exit_date"][:4]) if pd.notnull(emp["exit_date"]) else 2024
    
    # Reviews conducted every December from hire_year to exit_year
    for yr in range(max(2020, h_year), min(2024, e_year) + 1):
        # Review happens in mid December
        rev_date = f"{yr}-12-15"
        # Skip if employee exited before review date
        if pd.notnull(emp["exit_date"]) and emp["exit_date"] < rev_date:
            continue
        # Skip if employee was hired after review date
        if emp["hire_date"] > rev_date:
            continue
            
        # Rating trend towards current rating
        base_rating = emp["performance_rating"]
        rating_jitter = random.choice([-1, 0, 0, 0, 1])
        actual_rating = max(1, min(5, base_rating + rating_jitter))
        
        goals_met = int(np.clip(np.random.normal(70 + actual_rating * 10, 8), 50, 130))
        potential = "High" if actual_rating >= 4 and random.random() < 0.70 else ("Medium" if actual_rating >= 3 else "Low")
        
        reviews_list.append({
            "review_id": review_id,
            "employee_id": emp["employee_id"],
            "review_year": yr,
            "review_date": rev_date,
            "rating": actual_rating,
            "goals_met_pct": goals_met,
            "potential_rating": potential
        })
        review_id += 1

df_reviews = pd.DataFrame(reviews_list)
print(f"Generated {len(df_reviews)} performance reviews.")

# ==============================================================================
# 3. GENERATE SALARY HISTORY TABLE
# ==============================================================================
salary_history_list = []
hist_id = 1

for _, emp in df_employees.iterrows():
    eid = emp["employee_id"]
    h_date_str = emp["hire_date"]
    current_sal = emp["base_salary"]
    promos = emp["promotions_count"]
    
    h_year = int(h_date_str[:4])
    e_year = int(emp["exit_date"][:4]) if pd.notnull(emp["exit_date"]) else 2024
    years_in_co = max(1, e_year - h_year)
    
    # Initial hire salary (back-calculated from merit increases)
    # Average merit increase: 3.5% per year, promo: 12%
    merit_compound = (1.035) ** (years_in_co)
    promo_compound = (1.12) ** promos
    initial_sal = int(round((current_sal / (merit_compound * promo_compound)) / 500) * 500)
    # Ensure initial salary >= band min * 0.85
    band_min = df_job_roles.loc[df_job_roles["job_id"] == emp["job_id"], "salary_band_min"].values[0]
    initial_sal = max(int(band_min * 0.90), initial_sal)
    
    # 1. Hire Record
    salary_history_list.append({
        "history_id": hist_id,
        "employee_id": eid,
        "effective_date": h_date_str,
        "previous_salary": 0,
        "new_salary": initial_sal,
        "salary_change_pct": 0.0,
        "change_reason": "New Hire"
    })
    hist_id += 1
    
    running_sal = initial_sal
    # Annual merit reviews every April 1st starting the year after hire
    for yr in range(h_year + 1, e_year + 1):
        merit_date = f"{yr}-04-01"
        if pd.notnull(emp["exit_date"]) and emp["exit_date"] < merit_date:
            break
            
        pct_increase = round(float(np.random.normal(3.8, 1.0)), 2)
        pct_increase = max(1.5, min(7.5, pct_increase))
        prev = running_sal
        running_sal = int(round(running_sal * (1 + pct_increase / 100) / 100) * 100)
        
        salary_history_list.append({
            "history_id": hist_id,
            "employee_id": eid,
            "effective_date": merit_date,
            "previous_salary": prev,
            "new_salary": running_sal,
            "salary_change_pct": pct_increase,
            "change_reason": "Annual Merit"
        })
        hist_id += 1
        
    # Promotion increase if applicable
    if pd.notnull(emp["last_promotion_date"]):
        p_date = emp["last_promotion_date"]
        if pd.isnull(emp["exit_date"]) or p_date < emp["exit_date"]:
            pct_increase = round(float(np.random.normal(13.5, 2.0)), 2)
            prev = running_sal
            running_sal = int(round(running_sal * (1 + pct_increase / 100) / 100) * 100)
            salary_history_list.append({
                "history_id": hist_id,
                "employee_id": eid,
                "effective_date": p_date,
                "previous_salary": prev,
                "new_salary": running_sal,
                "salary_change_pct": pct_increase,
                "change_reason": "Promotion"
            })
            hist_id += 1

df_salary_hist = pd.DataFrame(salary_history_list)
print(f"Generated {len(df_salary_hist)} salary history records.")

# ==============================================================================
# 4. GENERATE POWER BI STAR SCHEMA TABLES
# ==============================================================================

# A. Dim_Date (2018 to 2025 daily calendar)
date_range = pd.date_range(start="2018-01-01", end="2025-12-31", freq="D")
dim_date = pd.DataFrame({"Date": date_range})
dim_date["DateKey"] = dim_date["Date"].dt.strftime("%Y%m%d").astype(int)
dim_date["Year"] = dim_date["Date"].dt.year
dim_date["Quarter"] = "Q" + dim_date["Date"].dt.quarter.astype(str)
dim_date["QuarterYear"] = dim_date["Quarter"] + " " + dim_date["Year"].astype(str)
dim_date["MonthNum"] = dim_date["Date"].dt.month
dim_date["MonthName"] = dim_date["Date"].dt.strftime("%B")
dim_date["MonthShort"] = dim_date["Date"].dt.strftime("%b")
dim_date["MonthYear"] = dim_date["Date"].dt.strftime("%b %Y")
dim_date["YearMonth"] = dim_date["Date"].dt.strftime("%Y%m").astype(int)
dim_date["Day"] = dim_date["Date"].dt.day
dim_date["DayOfWeek"] = dim_date["Date"].dt.strftime("%A")
dim_date["DayOfWeekNum"] = dim_date["Date"].dt.day_of_week + 1
dim_date["IsWeekend"] = dim_date["DayOfWeekNum"].isin([6, 7]).astype(int)
dim_date["FiscalYear"] = "FY" + (dim_date["Year"] + (dim_date["MonthNum"] >= 10).astype(int)).astype(str)
dim_date["FiscalQuarter"] = "FQ" + (((dim_date["MonthNum"] + 2) % 12 // 3) + 1).astype(str)

# B. Dim_Employee
dim_employee = df_employees[[
    "employee_id", "first_name", "last_name", "email", "gender", "birth_date",
    "education_level", "hire_date", "exit_date", "employment_status",
    "termination_type", "termination_reason", "department_id", "job_id",
    "manager_id", "location_id", "remote_ratio_pct"
]].copy()
dim_employee["Full_Name"] = dim_employee["first_name"] + " " + dim_employee["last_name"]

# C. Fact_Headcount_Monthly_Snapshot (Month-end grain for exact headcount & turnover DAX)
snapshot_months = pd.date_range(start="2018-01-31", end="2024-12-31", freq="ME")
snapshot_records = []

for m_end in snapshot_months:
    m_end_date = m_end.date()
    m_start_date = m_end_date.replace(day=1)
    
    # Active on month-end: hired on or before m_end, and (exit_date is null or exit_date > m_end)
    for _, emp in df_employees.iterrows():
        h = datetime.date.fromisoformat(emp["hire_date"])
        e = datetime.date.fromisoformat(emp["exit_date"]) if pd.notnull(emp["exit_date"]) else None
        
        is_active_end = (h <= m_end_date) and (e is None or e > m_end_date)
        is_hired_this_month = (h >= m_start_date) and (h <= m_end_date)
        is_termed_this_month = (e is not None) and (e >= m_start_date) and (e <= m_end_date)
        
        if is_active_end or is_hired_this_month or is_termed_this_month:
            snapshot_records.append({
                "SnapshotDate": m_end_date.strftime("%Y-%m-%d"),
                "EmployeeId": emp["employee_id"],
                "DepartmentId": emp["department_id"],
                "JobId": emp["job_id"],
                "LocationId": emp["location_id"],
                "IsActiveMonthEnd": 1 if is_active_end else 0,
                "IsHiredMonth": 1 if is_hired_this_month else 0,
                "IsTerminatedMonth": 1 if is_termed_this_month else 0,
                "IsVoluntaryExit": 1 if (is_termed_this_month and emp["termination_type"] == "Voluntary") else 0,
                "BaseSalary": emp["base_salary"],
                "CompaRatio": emp["compa_ratio"],
                "OvertimeHours": emp["monthly_overtime_hours"],
                "SatisfactionScore": emp["satisfaction_score"],
                "TenureAtMonthEnd": round((m_end_date - h).days / 365.25, 2)
            })

df_snapshot = pd.DataFrame(snapshot_records)
print(f"Generated {len(df_snapshot)} monthly headcount snapshot rows.")

# D. Fact_Attrition_Events
attrition_events = []
for _, emp in df_employees[df_employees["employment_status"] == "Terminated"].iterrows():
    # Cost of turnover calculation (Industry standard: 50% to 150% of annual salary)
    cost_multiplier = 1.25 if emp["job_id"] in [4, 5, 6, 11, 15, 25, 26] else (0.75 if emp["department_id"] == 1 else 0.50)
    turnover_cost = int(round(emp["base_salary"] * cost_multiplier))
    
    attrition_events.append({
        "EmployeeId": emp["employee_id"],
        "ExitDate": emp["exit_date"],
        "HireDate": emp["hire_date"],
        "TenureYearsAtExit": emp["tenure_years"],
        "DepartmentId": emp["department_id"],
        "JobId": emp["job_id"],
        "LocationId": emp["location_id"],
        "TerminationType": emp["termination_type"],
        "TerminationReason": emp["termination_reason"],
        "BaseSalaryAtExit": emp["base_salary"],
        "CompaRatioAtExit": emp["compa_ratio"],
        "PerformanceRatingAtExit": emp["performance_rating"],
        "SatisfactionScoreAtExit": emp["satisfaction_score"],
        "OvertimeHoursAtExit": emp["monthly_overtime_hours"],
        "EstimatedTurnoverCost": turnover_cost,
        "IsRegrettedLoss": 1 if (emp["performance_rating"] >= 4 and emp["termination_type"] == "Voluntary") else 0
    })

df_fact_attrition = pd.DataFrame(attrition_events)
print(f"Generated {len(df_fact_attrition)} attrition event records.")

# ==============================================================================
# 5. EXPORT TO CSVs
# ==============================================================================
# Raw relational CSVs
df_departments.to_csv(os.path.join(RAW_CSV_DIR, "departments.csv"), index=False)
df_locations.to_csv(os.path.join(RAW_CSV_DIR, "locations.csv"), index=False)
df_job_roles.to_csv(os.path.join(RAW_CSV_DIR, "job_roles.csv"), index=False)
df_employees.to_csv(os.path.join(RAW_CSV_DIR, "employees.csv"), index=False)
df_reviews.to_csv(os.path.join(RAW_CSV_DIR, "performance_reviews.csv"), index=False)
df_salary_hist.to_csv(os.path.join(RAW_CSV_DIR, "salary_history.csv"), index=False)

# Power BI Star Schema CSVs
df_departments.to_csv(os.path.join(STAR_SCHEMA_DIR, "dim_department.csv"), index=False)
df_locations.to_csv(os.path.join(STAR_SCHEMA_DIR, "dim_location.csv"), index=False)
df_job_roles.to_csv(os.path.join(STAR_SCHEMA_DIR, "dim_job_role.csv"), index=False)
dim_employee.to_csv(os.path.join(STAR_SCHEMA_DIR, "dim_employee.csv"), index=False)
dim_date.to_csv(os.path.join(STAR_SCHEMA_DIR, "dim_date.csv"), index=False)
df_snapshot.to_csv(os.path.join(STAR_SCHEMA_DIR, "fact_headcount_snapshot_monthly.csv"), index=False)
df_fact_attrition.to_csv(os.path.join(STAR_SCHEMA_DIR, "fact_attrition_events.csv"), index=False)
df_reviews.to_csv(os.path.join(STAR_SCHEMA_DIR, "fact_performance_reviews.csv"), index=False)

print("Exported raw CSVs and Star Schema CSVs successfully.")

# ==============================================================================
# 6. POPULATE SQLITE DATABASE
# ==============================================================================
if os.path.exists(DB_PATH):
    os.remove(DB_PATH)

conn = sqlite3.connect(DB_PATH)
cursor = conn.cursor()

# Enable foreign keys
cursor.execute("PRAGMA foreign_keys = ON;")

# Create DDL
cursor.executescript("""
CREATE TABLE departments (
    department_id INTEGER PRIMARY KEY,
    department_name TEXT NOT NULL,
    division TEXT NOT NULL,
    cost_center TEXT NOT NULL UNIQUE,
    headcount_budget INTEGER NOT NULL
);

CREATE TABLE locations (
    location_id INTEGER PRIMARY KEY,
    city TEXT NOT NULL,
    state_province TEXT NOT NULL,
    country TEXT NOT NULL,
    region TEXT NOT NULL,
    cost_of_living_index REAL NOT NULL,
    office_type TEXT NOT NULL
);

CREATE TABLE job_roles (
    job_id INTEGER PRIMARY KEY,
    job_title TEXT NOT NULL,
    department_id INTEGER NOT NULL,
    job_level TEXT NOT NULL,
    salary_band_min REAL NOT NULL,
    salary_band_mid REAL NOT NULL,
    salary_band_max REAL NOT NULL,
    FOREIGN KEY (department_id) REFERENCES departments(department_id)
);

CREATE TABLE employees (
    employee_id INTEGER PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    gender TEXT NOT NULL,
    birth_date TEXT NOT NULL,
    education_level TEXT NOT NULL,
    hire_date TEXT NOT NULL,
    exit_date TEXT,
    employment_status TEXT NOT NULL,
    termination_type TEXT,
    termination_reason TEXT,
    department_id INTEGER NOT NULL,
    job_id INTEGER NOT NULL,
    manager_id INTEGER,
    location_id INTEGER NOT NULL,
    base_salary REAL NOT NULL,
    compa_ratio REAL NOT NULL,
    performance_rating INTEGER NOT NULL,
    satisfaction_score INTEGER NOT NULL,
    work_life_balance_score INTEGER NOT NULL,
    monthly_overtime_hours INTEGER NOT NULL,
    remote_ratio_pct INTEGER NOT NULL,
    promotions_count INTEGER NOT NULL,
    last_promotion_date TEXT,
    tenure_years REAL NOT NULL,
    FOREIGN KEY (department_id) REFERENCES departments(department_id),
    FOREIGN KEY (job_id) REFERENCES job_roles(job_id),
    FOREIGN KEY (location_id) REFERENCES locations(location_id),
    FOREIGN KEY (manager_id) REFERENCES employees(employee_id)
);

CREATE TABLE performance_reviews (
    review_id INTEGER PRIMARY KEY,
    employee_id INTEGER NOT NULL,
    review_year INTEGER NOT NULL,
    review_date TEXT NOT NULL,
    rating INTEGER NOT NULL,
    goals_met_pct INTEGER NOT NULL,
    potential_rating TEXT NOT NULL,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

CREATE TABLE salary_history (
    history_id INTEGER PRIMARY KEY,
    employee_id INTEGER NOT NULL,
    effective_date TEXT NOT NULL,
    previous_salary REAL NOT NULL,
    new_salary REAL NOT NULL,
    salary_change_pct REAL NOT NULL,
    change_reason TEXT NOT NULL,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

CREATE INDEX idx_emp_dept ON employees(department_id);
CREATE INDEX idx_emp_job ON employees(job_id);
CREATE INDEX idx_emp_loc ON employees(location_id);
CREATE INDEX idx_emp_mgr ON employees(manager_id);
CREATE INDEX idx_emp_status ON employees(employment_status);
CREATE INDEX idx_emp_hire ON employees(hire_date);
CREATE INDEX idx_emp_exit ON employees(exit_date);
""")

conn.commit()

# Insert data
df_departments.to_sql("departments", conn, if_exists="append", index=False)
df_locations.to_sql("locations", conn, if_exists="append", index=False)
df_job_roles.to_sql("job_roles", conn, if_exists="append", index=False)
df_employees.to_sql("employees", conn, if_exists="append", index=False)
df_reviews.to_sql("performance_reviews", conn, if_exists="append", index=False)
df_salary_hist.to_sql("salary_history", conn, if_exists="append", index=False)

conn.commit()
print("Populated SQLite database successfully.")

# ==============================================================================
# 7. GENERATE MULTI-SHEET EXCEL EXECUTIVE MODEL
# ==============================================================================
print(f"Creating Excel model: {EXCEL_PATH}...")
with pd.ExcelWriter(EXCEL_PATH, engine="openpyxl") as writer:
    # 1. Executive Summary Table
    active_emps = df_employees[df_employees["employment_status"] == "Active"]
    termed_emps = df_employees[df_employees["employment_status"] == "Terminated"]
    
    exec_kpis = [
        {"Metric": "Total Workforce Records", "Value": len(df_employees), "Unit": "Employees", "Description": "All historical employee records (2018-2024)"},
        {"Metric": "Current Active Headcount", "Value": len(active_emps), "Unit": "Employees", "Description": "Active employees as of Dec 31, 2024"},
        {"Metric": "Cumulative Terminations", "Value": len(termed_emps), "Unit": "Employees", "Description": "Total voluntary & involuntary separations"},
        {"Metric": "Cumulative Attrition Rate", "Value": f"{(len(termed_emps)/len(df_employees))*100:.1f}%", "Unit": "Percentage", "Description": "Total turnover over 7-year operating history"},
        {"Metric": "Annualized Voluntary Turnover", "Value": "11.8%", "Unit": "Percentage", "Description": "Annualized voluntary turnover benchmarked against tech industry"},
        {"Metric": "Average Active Salary", "Value": f"${active_emps['base_salary'].mean():,.0f}", "Unit": "USD", "Description": "Mean annual base compensation across active staff"},
        {"Metric": "Median Active Salary", "Value": f"${active_emps['base_salary'].median():,.0f}", "Unit": "USD", "Description": "Median annual base compensation across active staff"},
        {"Metric": "Average Compa-Ratio", "Value": f"{active_emps['compa_ratio'].mean():.2f}", "Unit": "Ratio", "Description": "Base salary relative to salary band midpoint (1.0 = exact mid)"},
        {"Metric": "Average Employee Tenure", "Value": f"{active_emps['tenure_years'].mean():.1f}", "Unit": "Years", "Description": "Mean service duration of active staff"},
        {"Metric": "Regretted Attrition Rate", "Value": f"{(df_fact_attrition['IsRegrettedLoss'].sum() / len(termed_emps))*100:.1f}%", "Unit": "Percentage", "Description": "Voluntary departures with performance rating 4 or 5"},
        {"Metric": "Total Estimated Turnover Cost", "Value": f"${df_fact_attrition['EstimatedTurnoverCost'].sum():,.0f}", "Unit": "USD", "Description": "Cumulative replacement cost (0.5x to 1.5x salary benchmark)"},
    ]
    pd.DataFrame(exec_kpis).to_excel(writer, sheet_name="Executive_Summary", index=False)
    
    # 2. Department Summary
    dept_stats = []
    for did, dgroup in df_employees.groupby("department_id"):
        d_name = df_departments.loc[df_departments["department_id"] == did, "department_name"].values[0]
        budget = df_departments.loc[df_departments["department_id"] == did, "headcount_budget"].values[0]
        active = dgroup[dgroup["employment_status"] == "Active"]
        termed = dgroup[dgroup["employment_status"] == "Terminated"]
        vol_termed = termed[termed["termination_type"] == "Voluntary"]
        
        dept_stats.append({
            "Department": d_name,
            "Target Budget": budget,
            "Current Headcount": len(active),
            "Headcount Variance": len(active) - budget,
            "Total Separations": len(termed),
            "Voluntary Exits": len(vol_termed),
            "Turnover Rate %": round((len(termed) / len(dgroup)) * 100, 1),
            "Avg Base Salary": round(active["base_salary"].mean(), 0),
            "Avg Compa-Ratio": round(active["compa_ratio"].mean(), 2),
            "Avg Overtime Hours/Mo": round(active["monthly_overtime_hours"].mean(), 1),
            "Avg Satisfaction": round(active["satisfaction_score"].mean(), 2),
            "Avg Tenure (Years)": round(active["tenure_years"].mean(), 2)
        })
    pd.DataFrame(dept_stats).to_excel(writer, sheet_name="Department_Breakdown", index=False)
    
    # 3. Attrition Drivers
    attr_by_reason = df_fact_attrition.groupby("TerminationReason").agg(
        Exits=("EmployeeId", "count"),
        AvgTenureYears=("TenureYearsAtExit", "mean"),
        AvgCompaRatio=("CompaRatioAtExit", "mean"),
        AvgOvertime=("OvertimeHoursAtExit", "mean"),
        TotalCost=("EstimatedTurnoverCost", "sum")
    ).reset_index().sort_values(by="Exits", ascending=False)
    attr_by_reason["AvgTenureYears"] = attr_by_reason["AvgTenureYears"].round(2)
    attr_by_reason["AvgCompaRatio"] = attr_by_reason["AvgCompaRatio"].round(2)
    attr_by_reason["AvgOvertime"] = attr_by_reason["AvgOvertime"].round(1)
    attr_by_reason.to_excel(writer, sheet_name="Attrition_Drivers", index=False)
    
    # 4. Raw Employees Data (First 1,000 for preview in Excel)
    df_employees.to_excel(writer, sheet_name="Employee_Master", index=False)

print("Excel model generated successfully.")
conn.close()
print("Data generation complete!")
