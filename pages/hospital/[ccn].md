---
title: Hospital Drill-Down
---

```sql hospital_info
SELECT * FROM hospital_data.watchlist
WHERE ccn = '${params.ccn}'
LIMIT 1
```

```sql conditions
SELECT
  condition,
  excess_readmission_ratio,
  predicted_readmission_rate,
  expected_readmission_rate
FROM hospital_data.readmissions_by_condition
WHERE ccn = '${params.ccn}'
ORDER BY excess_readmission_ratio DESC
```

# {hospital_info[0].hospital_name}

**{hospital_info[0].state}** &nbsp;·&nbsp; **{hospital_info[0].size_bucket}** ({hospital_info[0].num_beds} beds) &nbsp;·&nbsp; Priority: **{hospital_info[0].priority_flag}**

> **Finding:** This hospital is **{hospital_info[0].cost_pct_above_peer}% above peer cost average** and **{hospital_info[0].readmission_pct_above_peer}% above peer readmission rate**, placing it in the {hospital_info[0].composite_percentile}th percentile of its peer group ({hospital_info[0].peer_group_size} {hospital_info[0].size_bucket} hospitals in {hospital_info[0].state}).

---

## Summary Metrics

<BigValue data={hospital_info} value=cost_per_discharge title="Cost per Discharge" fmt="$#,##0" />
<BigValue data={hospital_info} value=peer_avg_cost_per_discharge title="Peer Avg Cost/Discharge" fmt="$#,##0" />
<BigValue data={hospital_info} value=cost_pct_above_peer title="Cost vs Peers (%)" fmt="0.0" />

<BigValue data={hospital_info} value=avg_excess_readmission_ratio title="Avg Excess Readmission Ratio" fmt="0.0000" />
<BigValue data={hospital_info} value=peer_avg_excess_readmission title="Peer Avg Excess Readmission" fmt="0.0000" />
<BigValue data={hospital_info} value=readmission_pct_above_peer title="Readmission vs Peers (%)" fmt="0.0" />

---

## Readmission Rate by Condition

The **Excess Readmission Ratio** is CMS's risk-adjusted metric: 1.0 = as expected, >1.0 = worse than expected given the patient mix. Conditions above 1.0 are driving policy penalties for this hospital.

<DataTable data={conditions} sort="excess_readmission_ratio desc">
  <Column id=condition title="Condition" wrap=true />
  <Column id=excess_readmission_ratio title="Excess Readmission Ratio" fmt="0.0000" />
  <Column id=predicted_readmission_rate title="Predicted Rate %" fmt="0.00" />
  <Column id=expected_readmission_rate title="Expected Rate %" fmt="0.00" />
</DataTable>

<BarChart
  data={conditions}
  x=condition
  y=excess_readmission_ratio
  title="Excess Readmission Ratio by Condition (1.0 = national expected baseline)"
  xAxisTitle="Condition"
  yAxisTitle="Excess Readmission Ratio"
  swapXY=true
/>

---

[← Back to Watchlist](/)
