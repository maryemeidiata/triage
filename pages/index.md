---
title: Hospital Performance Watchlist
---

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
  SUM(CASE WHEN priority_flag = 'Monitor' THEN 1 ELSE 0 END) AS monitor,
  SUM(CASE WHEN priority_flag = 'OK' THEN 1 ELSE 0 END) AS ok
FROM ${filtered_watchlist}
```

# Hospital performance watchlist

Hospitals flagged as outliers on **both cost per discharge and readmission rate** relative to peer hospitals of the same size and state. Data: CMS FY2026 HRRP + 2023 Provider Cost Report.

<BigValue data={summary_stats} value=total_hospitals title="Hospitals scored" />
<BigValue data={summary_stats} value=high_priority title="High priority" />
<BigValue data={summary_stats} value=monitor title="Monitor" />
<BigValue data={summary_stats} value=ok title="Within normal range" />

---

## Cost vs readmission map

Each dot is one hospital. Hospitals in the **top-right quadrant** are above their peer average on both cost and readmissions — those are the highest-priority targets. The dashed lines represent the peer group average (zero = exactly average).

```sql scatter_data
SELECT
  hospital_name,
  CASE WHEN cost_pct_above_peer > 400 THEN 400 ELSE cost_pct_above_peer END AS cost_pct_above_peer,
  readmission_pct_above_peer,
  priority_flag
FROM ${filtered_watchlist}
WHERE readmission_pct_above_peer BETWEEN -60 AND 60
```

<ScatterPlot
  data={scatter_data}
  x=cost_pct_above_peer
  y=readmission_pct_above_peer
  series=priority_flag
  colorPalette={['#E24B4A', '#EF9F27', '#4ade80']}
  xAxisTitle="Cost % above peer average (capped at 400% for readability)"
  yAxisTitle="Readmission rate % above peer average"
  tooltipTitle=hospital_name
/>

---

## Top hospitals by cost above peer average

```sql top_cost
SELECT
  hospital_name,
  cost_pct_above_peer,
  priority_flag
FROM ${filtered_watchlist}
WHERE priority_flag IN ('High Priority', 'Monitor')
ORDER BY cost_pct_above_peer DESC
LIMIT 15
```

<BarChart
  data={top_cost}
  x=hospital_name
  y=cost_pct_above_peer
  swapXY=true
  series=priority_flag
  colorPalette={['#E24B4A', '#EF9F27']}
  yAxisTitle="% above peer average cost per discharge"
/>

---

## Flagged hospitals — ranked by severity

Click any row to see the full condition-level breakdown for that hospital.

```sql flagged
SELECT
  hospital_name,
  state,
  size_bucket,
  num_beds,
  cost_pct_above_peer,
  readmission_pct_above_peer,
  finding,
  composite_score,
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
  <Column id=cost_pct_above_peer title="Cost vs peers %" fmt="0.0" />
  <Column id=readmission_pct_above_peer title="Readmission vs peers %" fmt="0.0" />
  <Column id=finding title="Finding" wrap=true />
  <Column id=priority_flag title="Flag" />
</DataTable>
