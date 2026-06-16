-- One row per hospital: average Excess Readmission Ratio across all conditions.
-- Averaging across conditions is appropriate here because we want a single
-- summary signal per hospital. Individual condition breakdown lives in readmissions_by_condition.
SELECT
    printf('%06d', TRY_CAST("Facility ID" AS INTEGER)) AS ccn,
    "Facility Name"                                     AS facility_name,
    "State"                                             AS state,
    AVG(TRY_CAST("Excess Readmission Ratio" AS DOUBLE)) AS avg_excess_readmission_ratio,
    COUNT(*)                                            AS condition_count
FROM read_csv_auto('sources/hospital_data/readmissions.csv', header=true)
WHERE TRY_CAST("Facility ID" AS INTEGER) IS NOT NULL
  AND TRY_CAST("Excess Readmission Ratio" AS DOUBLE) IS NOT NULL
GROUP BY 1, 2, 3
