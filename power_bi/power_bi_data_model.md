# Power BI Data Model Architecture & Schema Design

This document details the semantic data model engineered for Power BI, adhering to dimensional modeling best practices (Kimball Star Schema). It addresses complex HR analytical challenges such as dual-date role-playing dimensions, slowly changing attributes, and point-in-time headcount tracking.

---

## 1. Dimensional Architecture (Star Schema)

The model is partitioned into distinct **Dimension Tables** (lookup attributes) and **Fact Tables** (quantitative event and snapshot measurements).

```mermaid
flowchart TD
    subgraph Dimensions
        D_EMP["Dim_Employee<br/>(Employee Grain)"]
        D_DEPT["Dim_Department<br/>(Org Hierarchy)"]
        D_JOB["Dim_JobRole<br/>(Bands & Levels)"]
        D_LOC["Dim_Location<br/>(Geographies)"]
        D_DATE["Dim_Date<br/>(Calendar Spine)"]
    end

    subgraph Facts
        F_SNAP["Fact_Headcount_Snapshot_Monthly<br/>(Monthly Status & Comp Grain)"]
        F_ATTR["Fact_Attrition_Events<br/>(Separation Event Grain)"]
        F_REV["Fact_Performance_Reviews<br/>(Annual Review Grain)"]
    end

    D_DEPT -->|1 : Many| F_SNAP
    D_JOB -->|1 : Many| F_SNAP
    D_LOC -->|1 : Many| F_SNAP
    D_EMP -->|1 : Many| F_SNAP
    D_DATE -->|1 : Many (Active: SnapshotDate)| F_SNAP

    D_DEPT -->|1 : Many| F_ATTR
    D_JOB -->|1 : Many| F_ATTR
    D_LOC -->|1 : Many| F_ATTR
    D_EMP -->|1 : Many| F_ATTR
    D_DATE -.->|1 : Many (Inactive: ExitDate)| F_ATTR
    D_DATE -.->|1 : Many (Inactive: HireDate)| F_ATTR

    D_EMP -->|1 : Many| F_REV
    D_DATE -->|1 : Many (Active: ReviewDate)| F_REV
```

---

## 2. Table Cardinalities & Relationship Catalog

| From Table (Dimension) | From Column | To Table (Fact) | To Column | Cardinality | Cross Filter | Active State | Purpose |
| :--- | :--- | :--- | :--- | :---: | :---: | :---: | :--- |
| `Dim_Date` | `Date` | `Fact_Headcount_Snapshot_Monthly` | `SnapshotDate` | 1 : * | Single | **Active** | Primary time slicer for monthly headcount, active payroll, and MoM trends. |
| `Dim_Date` | `Date` | `Fact_Attrition_Events` | `ExitDate` | 1 : * | Single | *Inactive* | Activated via `USERELATIONSHIP()` in DAX for exit-date-aligned attrition metrics. |
| `Dim_Date` | `Date` | `Fact_Attrition_Events` | `HireDate` | 1 : * | Single | *Inactive* | Activated via `USERELATIONSHIP()` for cohort survival analysis. |
| `Dim_Date` | `Date` | `Fact_Performance_Reviews` | `ReviewDate` | 1 : * | Single | **Active** | Aligns annual appraisal cycles to fiscal/calendar years. |
| `Dim_Employee` | `employee_id` | `Fact_Headcount_Snapshot_Monthly` | `EmployeeId` | 1 : * | Single | **Active** | Slices monthly snapshot by individual employee attributes. |
| `Dim_Employee` | `employee_id` | `Fact_Attrition_Events` | `EmployeeId` | 1 : * | Single | **Active** | Links departure events with demographics. |
| `Dim_Department` | `department_id` | `Fact_Headcount_Snapshot_Monthly` | `DepartmentId` | 1 : * | Single | **Active** | Departmental rollups and division hierarchies. |
| `Dim_Department` | `department_id` | `Fact_Attrition_Events` | `DepartmentId` | 1 : * | Single | **Active** | Departmental turnover reporting. |
| `Dim_JobRole` | `job_id` | `Fact_Headcount_Snapshot_Monthly` | `JobId` | 1 : * | Single | **Active** | Job tier, title, and salary band slicing. |
| `Dim_JobRole` | `job_id` | `Fact_Attrition_Events` | `JobId` | 1 : * | Single | **Active** | Separation patterns by career level. |
| `Dim_Location` | `location_id` | `Fact_Headcount_Snapshot_Monthly` | `LocationId` | 1 : * | Single | **Active** | Geographic and office type breakdown. |
| `Dim_Location` | `location_id` | `Fact_Attrition_Events` | `LocationId` | 1 : * | Single | **Active** | Geographic attrition rates. |

---

## 3. Modeling Role-Playing Dates & The `USERELATIONSHIP` Pattern

### The Problem
An employee record possesses two critical dates: `HireDate` and `ExitDate`. If both relationships between `Dim_Date` and the fact table are active, ambiguity is introduced and cyclical filter paths break the engine.

### The Solution
1. The relationship between `Dim_Date[Date]` and `Fact_Headcount_Snapshot_Monthly[SnapshotDate]` is kept **Active**.
2. The relationships to `Fact_Attrition_Events[ExitDate]` and `Fact_Attrition_Events[HireDate]` are configured as **Inactive**.
3. Specific DAX measures selectively activate the required path using `USERELATIONSHIP()`:

```dax
Total Exits (Exit Date Context) = 
CALCULATE(
    COUNTROWS(Fact_Attrition_Events),
    USERELATIONSHIP(Dim_Date[Date], Fact_Attrition_Events[ExitDate])
)
```

---

## 4. Periodic Snapshot vs. Transactional Fact Design

| Dimension / Fact | Grain | Record Count | Use Case in Power BI |
| :--- | :--- | :---: | :--- |
| `Dim_Date` | 1 row per day (2018–2025) | 2,922 | Calendar time intelligence, fiscal periods, day-of-week analysis. |
| `Dim_Employee` | 1 row per employee | 1,250 | Demographic filtering (Gender, Education, Age). |
| `Dim_Department` | 1 row per department | 7 | Division, Cost Center, and Budget targets. |
| `Dim_JobRole` | 1 row per role | 26 | Seniority tier (L1-E1), Min/Mid/Max salary bands. |
| `Dim_Location` | 1 row per office/hub | 6 | City, Region, Cost of Living Index. |
| `Fact_Headcount_Snapshot_Monthly` | 1 row per employee per month | 44,883 | Point-in-time active headcount, rolling averages, compa-ratio trends. |
| `Fact_Attrition_Events` | 1 row per departure | 378 | Separation root causes, regretted attrition, turnover costs. |
| `Fact_Performance_Reviews` | 1 row per annual appraisal | 3,663 | Rating distributions, goals met %, 9-box talent evaluation. |

---

## 5. Engine Performance Optimization Guidelines

1. **Auto Date/Time Disabled**: Global and file-level "Auto Date/Time" disabled in Power BI Options to prevent hidden internal tables bloating memory.
2. **Integer Keys**: All foreign key relationships utilize numeric integers (`DateKey`, `EmployeeId`, `DepartmentId`) instead of text strings for optimal VertiPaq dictionary encoding.
3. **Columnar Sorting**: `MonthYear` is explicitly sorted by `YearMonth` integer column; `Quarter` is sorted by `FiscalQuarter`.
4. **Calculated Columns Avoided in Fact Tables**: All metrics (Compa-Ratio, Turnover Cost, Tenures) are either pre-computed in SQL/ETL or dynamically calculated via DAX measures to conserve RAM.
