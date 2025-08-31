create schema Project;
-- set proejct as default folder
use project;
-- To gain a comprehensive understanding of the factors influencing hospitalization costs 
-- 	a. Merge the two tables by first identifying the columns in the data tables that will help you in merging 
-- 	b. In both tables, add a Primary Key constraint for these columns
-- 3) Basic hygiene: remove rows where customer_id is NULL after import
DELETE FROM names WHERE customer_id IS NULL;
DELETE FROM medical_examinations WHERE customer_id IS NULL;
DELETE FROM hospitalization_details WHERE customer_id IS NULL;

   
    
  --    We'll also left join names for readability.
CREATE OR REPLACE VIEW project.patient_master AS
SELECT 
    e.customer_id,
    n.full_name,
    e.bmi,
    e.hba1c,
    e.heart_issues,
    e.any_transplants,
    e.cancer_history,
    e.number_of_major_surgeries,
    e.smoker,
    h.year,
    h.month,
    h.day,
    h.children,
    h.charges,
    h.hospital_tier,
    h.city_tier,
    h.state_id
FROM project.medical_examinations e
JOIN project.hospitalization_details h
    ON e.customer_id = h.customer_id
LEFT JOIN project.names n
    ON n.customer_id = e.customer_id;

-- 2) Diabetic (assumption: HBA1C >= 6.5) AND heart problems (heart_issues='Yes')
--    Average age is not available in provided data, so returned as NULL.
SELECT
  'Assumption: Diabetes = HBA1C >= 6.5' AS note,
  COUNT(*) AS people_count,
  NULL AS avg_age,                            -- No age field present in CSVs
  AVG(children) AS avg_dependent_children,
  AVG(bmi)      AS avg_bmi,
  AVG(charges)  AS avg_hospitalization_costs
FROM patient_master
WHERE hba1c >= 6.5 AND heart_issues = 'Yes';

-- 3) Average hospitalization cost for each hospital tier AND each city level
SELECT
  hospital_tier,
  city_tier,
  AVG(charges) AS avg_charges,
  COUNT(*)     AS records
FROM patient_master
GROUP BY hospital_tier, city_tier
ORDER BY hospital_tier, city_tier;


-- 4) Number of people who have had major surgery AND have a history of cancer
--    Interpreting "had major surgery" as number_of_major_surgeries <> 'No major surgery'
SELECT 
    COUNT(DISTINCT customer_id) AS people_with_major_surgery_and_cancer
FROM
    patient_master
WHERE
    (number_of_major_surgeries IS NOT NULL
        AND number_of_major_surgeries <> 'No major surgery')
        AND cancer_history = 'Yes';


-- 5) Number of tier-1 hospitals in each state (proxy: count tier-1 hospitalization records per state)
--    The dataset has no hospital identifier, so we count tier-1 admissions per state_id.
SELECT
  state_id,
  COUNT(*) AS tier1_records
FROM patient_master
WHERE hospital_tier = 'tier - 1'
GROUP BY state_id
ORDER BY state_id;

