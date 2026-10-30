"""
SQL Verification and Analysis Runner
Executes all SQL modules against hr_analytics.db and validates query performance,
views creation, and analytical outputs.
"""

import os
import sqlite3
import pandas as pd

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DB_PATH = os.path.join(PROJECT_ROOT, "data", "hr_analytics.db")
SQL_DIR = os.path.join(PROJECT_ROOT, "sql")

def run_script(conn, filename):
    print(f"\n{'='*70}\nExecuting: {filename}\n{'='*70}")
    filepath = os.path.join(SQL_DIR, filename)
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()
        
    # Split queries by semicolon, filtering out comments and whitespace
    statements = [stmt.strip() for stmt in content.split(";") if stmt.strip()]
    for idx, stmt in enumerate(statements, 1):
        # Ignore comments-only blocks
        clean_lines = [line for line in stmt.split("\n") if not line.strip().startswith("--")]
        clean_stmt = "\n".join(clean_lines).strip()
        if not clean_stmt:
            continue
            
        try:
            if clean_stmt.upper().startswith("SELECT") or clean_stmt.upper().startswith("WITH"):
                df = pd.read_sql_query(clean_stmt, conn)
                print(f"[Query {idx}] Returned {len(df)} rows. Sample (first 3 rows):")
                print(df.head(3).to_string(index=False))
                print("-" * 50)
            else:
                conn.execute(clean_stmt)
                conn.commit()
                print(f"[DDL/View {idx}] Executed successfully.")
        except Exception as e:
            print(f"[ERROR in {filename} - Statement {idx}]: {e}")
            print(f"Statement:\n{clean_stmt}\n")
            raise

def main():
    if not os.path.exists(DB_PATH):
        raise FileNotFoundError(f"Database not found at {DB_PATH}. Run scripts/generate_dataset.py first.")
        
    conn = sqlite3.connect(DB_PATH)
    
    # Run views first so queries referencing them work if any
    run_script(conn, "07_executive_reporting_views.sql")
    
    # Run analytical modules in sequence
    modules = [
        "01_data_profiling_and_qc.sql",
        "02_workforce_mix_and_headcount.sql",
        "03_hiring_patterns_and_velocity.sql",
        "04_compensation_and_equity.sql",
        "05_attrition_and_retention.sql",
        "06_advanced_window_functions_and_ctes.sql"
    ]
    
    for mod in modules:
        run_script(conn, mod)
        
    conn.close()
    print("\nAll SQL scripts executed and validated with zero errors!")

if __name__ == "__main__":
    main()
