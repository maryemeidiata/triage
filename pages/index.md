---
title: Hospital Triage — Outlier Watchlist
---

# Hospital Outlier Watchlist

Hospitals flagged as outliers on **both cost and readmission rate** relative to peer hospitals of the same size and state. Data: CMS FY2026 HRRP + 2023 Provider Cost Report.

```sql all_states
SELECT DISTINCT state FROM hospital_data.watchlist ORDER BY state
```

```sql watchlist
SELECT * FROM hospital_data.watchlist ORDER BY composite_score DESC
```

<Dropdown
  name=selected_state
  data={all_states}
  value=state
  title="Filter by State"
>
  <DropdownOption value="%" valueLabel="All States" />
</Dropdown>

```sql filtered_watchlist
SELECT * FROM ${watchlist}
WHERE state LIKE '${inputs.selected_state.value}'
ORDER BY composite_score DESC
```

```sql summary_stats
SELECT
  COUNT(*) AS total_hospitals,
  SUM(CASE WHEN priority_flag = 'High Priority' THEN 1 ELSE 0 END) AS high_priority,
  SUM(CASE WHEN priority_flag = 'Monitor' THEN 1 ELSE 0 END) AS monitor
FROM ${filtered_watchlist}
```

<BigValue data={summary_stats} value=total_hospitals title="Hospitals Scored" />
<BigValue data={summary_stats} value=high_priority title="High Priority" />
<BigValue data={summary_stats} value=monitor title="Monitor" />

---

## Ranked Watchlist

Hospitals scored on how far above their peer group average they are on **cost per discharge** and **excess readmission ratio**. Composite score = average of the two % deviations. Top 25% within peer group = High Priority; next 25% = Monitor.

```sql flagged
SELECT
  hospital_name,
  state,
  size_bucket,
  num_beds,
  cost_per_discharge,
  cost_pct_above_peer,
  avg_excess_readmission_ratio,
  readmission_pct_above_peer,
  composite_score,
  peer_group_size,
  priority_flag,
  '/hospital/' || ccn AS link
FROM ${filtered_watchlist}
WHERE priority_flag IN ('High Priority', 'Monitor')
ORDER BY composite_score DESC
LIMIT 200
```

<DataTable
  data={flagged}
  rows=20
  search=true
  sort="composite_score desc"
  link=link
>
  <Column id=hospital_name title="Hospital" wrap=true />
  <Column id=state title="State" />
  <Column id=size_bucket title="Size" />
  <Column id=num_beds title="Beds" fmt="num0" />
  <Column id=cost_pct_above_peer title="Cost vs Peers %" fmt="0.0" />
  <Column id=readmission_pct_above_peer title="Readmission vs Peers %" fmt="0.0" />
  <Column id=composite_score title="Composite Score" fmt="0.00" />
  <Column id=peer_group_size title="Peer Group" fmt="num0" />
  <Column id=priority_flag title="Flag" />
</DataTable>

---

## Cost vs Readmission Outlier Map

```sql scatter_data
SELECT
  hospital_name,
  cost_pct_above_peer,
  readmission_pct_above_peer,
  priority_flag
FROM ${filtered_watchlist}
```

<ScatterPlot
  data={scatter_data}
  x=cost_pct_above_peer
  y=readmission_pct_above_peer
  series=priority_flag
  xAxisTitle="Cost % Above Peer Average"
  yAxisTitle="Readmission % Above Peer Average"
  title="Each dot is one hospital — top-right quadrant = worst on both dimensions"
  tooltipTitle=hospital_name
/>
