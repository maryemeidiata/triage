-- Self-contained outlier scoring query.
-- All CTEs are inlined since each Evidence SQL file runs in its own DuckDB session.

WITH cost_raw AS (
    SELECT
        printf('%06d', TRY_CAST("Provider CCN" AS INTEGER)) AS ccn,
        "Hospital Name"                                      AS hospital_name,
        "State Code"                                         AS state,
        TRY_CAST("Number of Beds" AS INTEGER)                AS num_beds,
        TRY_CAST("Total Costs" AS DOUBLE)                    AS total_costs,
        TRY_CAST(
            "Total Discharges (V + XVIII + XIX + Unknown)" AS INTEGER
        )                                                    AS total_discharges,
        ROW_NUMBER() OVER (
            PARTITION BY "Provider CCN"
            ORDER BY "Fiscal Year End Date" DESC
        )                                                    AS rn
    FROM read_csv_auto('sources/hospital_data/cost_report.csv', header=true)
    WHERE TRY_CAST("Provider CCN" AS INTEGER) IS NOT NULL
),

cost_base AS (
    SELECT
        ccn,
        hospital_name,
        state,
        num_beds,
        total_costs / total_discharges AS cost_per_discharge,
        CASE
            WHEN num_beds < 100 THEN 'Small'
            WHEN num_beds < 300 THEN 'Medium'
            ELSE 'Large'
        END AS size_bucket
    FROM cost_raw
    WHERE rn = 1
      AND num_beds > 0
      AND total_costs > 0
      AND total_discharges > 0
),

readmissions_agg AS (
    SELECT
        printf('%06d', TRY_CAST("Facility ID" AS INTEGER)) AS ccn,
        AVG(TRY_CAST("Excess Readmission Ratio" AS DOUBLE)) AS avg_excess_readmission_ratio,
        COUNT(*)                                            AS condition_count
    FROM read_csv_auto('sources/hospital_data/readmissions.csv', header=true)
    WHERE TRY_CAST("Facility ID" AS INTEGER) IS NOT NULL
      AND TRY_CAST("Excess Readmission Ratio" AS DOUBLE) IS NOT NULL
    GROUP BY 1
),

joined AS (
    SELECT
        c.ccn,
        c.hospital_name,
        c.state,
        c.num_beds,
        c.size_bucket,
        c.cost_per_discharge,
        r.avg_excess_readmission_ratio,
        r.condition_count
    FROM cost_base c
    INNER JOIN readmissions_agg r ON c.ccn = r.ccn
),

peer_stats AS (
    SELECT
        state,
        size_bucket,
        AVG(cost_per_discharge)           AS peer_avg_cost_per_discharge,
        AVG(avg_excess_readmission_ratio) AS peer_avg_excess_readmission,
        COUNT(*)                          AS peer_group_size
    FROM joined
    GROUP BY state, size_bucket
),

scored AS (
    SELECT
        j.*,
        p.peer_avg_cost_per_discharge,
        p.peer_avg_excess_readmission,
        p.peer_group_size,
        ROUND(
            (j.cost_per_discharge - p.peer_avg_cost_per_discharge)
            / NULLIF(p.peer_avg_cost_per_discharge, 0) * 100,
        1) AS cost_pct_above_peer,
        ROUND(
            (j.avg_excess_readmission_ratio - p.peer_avg_excess_readmission)
            / NULLIF(p.peer_avg_excess_readmission, 0) * 100,
        1) AS readmission_pct_above_peer,
        ROUND(
            (
                (j.cost_per_discharge - p.peer_avg_cost_per_discharge)
                    / NULLIF(p.peer_avg_cost_per_discharge, 0)
                +
                (j.avg_excess_readmission_ratio - p.peer_avg_excess_readmission)
                    / NULLIF(p.peer_avg_excess_readmission, 0)
            ) / 2 * 100,
        2) AS composite_score
    FROM joined j
    JOIN peer_stats p ON j.state = p.state AND j.size_bucket = p.size_bucket
),

ranked AS (
    SELECT
        *,
        PERCENT_RANK() OVER (
            PARTITION BY state, size_bucket
            ORDER BY composite_score ASC
        ) AS composite_percentile_rank
    FROM scored
)

SELECT
    ccn,
    hospital_name,
    state,
    size_bucket,
    num_beds,
    ROUND(cost_per_discharge, 0)          AS cost_per_discharge,
    ROUND(peer_avg_cost_per_discharge, 0) AS peer_avg_cost_per_discharge,
    cost_pct_above_peer,
    ROUND(avg_excess_readmission_ratio, 4) AS avg_excess_readmission_ratio,
    ROUND(peer_avg_excess_readmission, 4)  AS peer_avg_excess_readmission,
    readmission_pct_above_peer,
    composite_score,
    peer_group_size,
    condition_count,
    ROUND(composite_percentile_rank * 100, 1) AS composite_percentile,
    CASE
        WHEN composite_percentile_rank >= 0.75 THEN 'High Priority'
        WHEN composite_percentile_rank >= 0.50 THEN 'Monitor'
        ELSE 'OK'
    END AS priority_flag
FROM ranked
ORDER BY composite_score DESC
