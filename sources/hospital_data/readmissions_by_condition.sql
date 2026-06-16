-- One row per hospital per condition: cleaned readmission data for drill-down view.
-- Excess Readmission Ratio > 1.0 means worse than expected (risk-adjusted by CMS).
SELECT
    printf('%06d', TRY_CAST("Facility ID" AS INTEGER)) AS ccn,
    "Facility Name"                                     AS facility_name,
    "State"                                             AS state,
    "Measure Name"                                      AS condition,
    TRY_CAST("Excess Readmission Ratio" AS DOUBLE)      AS excess_readmission_ratio,
    TRY_CAST("Predicted Readmission Rate" AS DOUBLE)    AS predicted_readmission_rate,
    TRY_CAST("Expected Readmission Rate" AS DOUBLE)     AS expected_readmission_rate
FROM read_csv_auto('sources/hospital_data/readmissions.csv', header=true)
WHERE TRY_CAST("Facility ID" AS INTEGER) IS NOT NULL
  AND TRY_CAST("Excess Readmission Ratio" AS DOUBLE) IS NOT NULL
