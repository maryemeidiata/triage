-- One row per hospital: most recent cost report filing, with cost per discharge computed.
-- We cast Provider CCN to text and zero-pad to 6 digits to match the readmissions Facility ID format.
WITH raw AS (
    SELECT
        printf('%06d', TRY_CAST("Provider CCN" AS INTEGER))   AS ccn,
        "Hospital Name"                                        AS hospital_name,
        "State Code"                                           AS state,
        TRY_CAST("Number of Beds" AS INTEGER)                  AS num_beds,
        TRY_CAST("Total Costs" AS DOUBLE)                      AS total_costs,
        TRY_CAST(
            "Total Discharges (V + XVIII + XIX + Unknown)" AS INTEGER
        )                                                      AS total_discharges,
        "Fiscal Year End Date"                                 AS fy_end,
        ROW_NUMBER() OVER (
            PARTITION BY "Provider CCN"
            ORDER BY "Fiscal Year End Date" DESC
        )                                                      AS rn
    FROM read_csv_auto('sources/hospital_data/cost_report.csv', header=true)
    WHERE TRY_CAST("Provider CCN" AS INTEGER) IS NOT NULL
)
SELECT
    ccn,
    hospital_name,
    state,
    num_beds,
    total_costs,
    total_discharges,
    -- Cost per discharge: the unit-cost metric we use for peer comparison
    CASE
        WHEN total_discharges > 0
        THEN total_costs / total_discharges
        ELSE NULL
    END AS cost_per_discharge,
    -- Size bucket: small < 100 beds, medium 100-299, large >= 300
    CASE
        WHEN num_beds < 100  THEN 'Small'
        WHEN num_beds < 300  THEN 'Medium'
        ELSE 'Large'
    END AS size_bucket
FROM raw
WHERE rn = 1
  AND num_beds IS NOT NULL
  AND num_beds > 0
  AND total_costs IS NOT NULL
  AND total_costs > 0
  AND total_discharges IS NOT NULL
  AND total_discharges > 0
