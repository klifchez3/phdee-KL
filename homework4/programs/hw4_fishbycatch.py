##### Homework 4: Fish Bycatch          #####
##### Kelly Lifchez Februaryt 9 2025    #####

import os
import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
import statsmodels.api as sm
import statsmodels.formula.api as smf
import statsmodels.iolib.summary2 as sm_summary

inputpath = r'/Users/kellylifchez/GaTech Dropbox/Kelly Lifchez/phdee-KL/homework4/data'
outputpath = r'/Users/kellylifchez/GaTech Dropbox/Kelly Lifchez/phdee-KL/homework4/output'

# Set seed
np.random.seed(6578103)

# Load the data
df = pd.read_csv(os.path.join(inputpath, 'fishbycatch.csv'))

print(df)

# Reshape to long format
df_long = pd.wide_to_long(df, stubnames=['shrimp', 'salmon', 'bycatch'], i='firm', j='month')

# Reset the index to make 'firm' and 'month' columns again
df_long = df_long.reset_index()

print(df_long)
print(df_long.head())


df_long["year"] = df_long["month"].apply(lambda x: 2017 if x <= 12 else 2018)

grouped_fishbycatch = df_long.groupby(['year', 'month', 'treated'])['bycatch'].mean().reset_index()

print(grouped_fishbycatch.head())
print(df_long.head())

# %%
### Question 1: Trend Plot 

plt.figure()
for treated in [0, 1]:
    subset = grouped_fishbycatch[grouped_fishbycatch['treated'] == treated]
    label = "Treated" if treated == 1 else "Control"
    plt.plot(subset['month'], subset['bycatch'], marker='o', linestyle='-', label=f"{label} group")

plt.axvline(x=12.5, color='r', linestyle='--')
plt.xlabel("Month")
plt.ylabel("Pounds of Bycatch")
plt.legend(bbox_to_anchor=(0.85, 0.94), loc='upper center')
plt.grid(axis='y')

ax = plt.gca()
ax.spines['top'].set_visible(False)
ax.spines['right'].set_visible(False)

month_labels = ['Jan 2017', 'Feb 2017', 'Mar 2017', 'Apr 2017', 'May 2017', 'Jun 2017', 'Jul 2017', 'Aug 2017', 'Sep 2017', 'Oct 2017', 'Nov 2017', 'Dec 2017',
                'Jan 2018', 'Feb 2018', 'Mar 2018', 'Apr 2018', 'May 2018', 'Jun 2018', 'Jul 2018', 'Aug 2018', 'Sep 2018', 'Oct 2018', 'Nov 2018', 'Dec 2018']
plt.xticks(ticks=range(1, 25), labels=month_labels, rotation=90)

plt.text(12.5, plt.ylim()[1], 'Program Start', horizontalalignment='center', verticalalignment='bottom', color='black')

plt.savefig(os.path.join(outputpath, 'trend_plot.pdf'))

plt.show()


### Question 2: Difference-in-Differences Estimation 

# %%
## Calculate DID estimates

#Treated group
pre_treated = grouped_fishbycatch[(grouped_fishbycatch["year"] == 2017) & (grouped_fishbycatch['month'] == 12) & (grouped_fishbycatch['treated'] == 1)]['bycatch'].values[0]
post_treated = grouped_fishbycatch[(grouped_fishbycatch["year"] == 2018) & (grouped_fishbycatch['month'] == 13) & (grouped_fishbycatch['treated'] == 1)]['bycatch'].values[0]

#Control group
pre_control = grouped_fishbycatch[(grouped_fishbycatch["year"] == 2017) & (grouped_fishbycatch['month'] == 12) & (grouped_fishbycatch['treated'] == 0)]['bycatch'].values[0]
post_control = grouped_fishbycatch[(grouped_fishbycatch["year"] == 2018) & (grouped_fishbycatch['month'] == 13) & (grouped_fishbycatch['treated'] == 0)]['bycatch'].values[0]

DID = (post_treated - pre_treated) - (post_control - pre_control)

did_estimate = f"{DID:.2f}" #formats estimate to 2 decimal places and stores as string
did_df = pd.DataFrame([did_estimate], columns=["DID Estimate"]) #one column named DID Estimate and one row with formatted value
did_tab = did_df.to_latex(index=False, escape=False, multicolumn=False) #convert to latex
output_path = os.path.join(outputpath, "did_estimate.tex") 
with open(output_path, "w") as f:
    f.write(did_tab)

# %%
# DID regression

df_long['post'] = (df_long['year'] == 2018).astype(int)
df_long['pre'] = (df_long['year'] == 2017).astype(int)

df_long['treatment'] = df_long['treated'] * df_long['post']

# a) Two-period DID
fishbycatch_two_period = df_long[(df_long['year'] == 2017) & (df_long['month'] == 12) | (df_long['year'] == 2018) & (df_long['month'] == 13)]
a = smf.ols("bycatch ~ pre + treated + treatment", data=fishbycatch_two_period).fit(cov_type='cluster', cov_kwds={'groups': fishbycatch_two_period['firm']})

# b) Full-period DID
b = smf.ols("bycatch ~ C(month) + treated + treatment", data=df_long).fit(cov_type='cluster', cov_kwds={'groups': df_long['firm']})

# c) Full sample with controls
c = smf.ols("bycatch ~ C(month) + treated + treatment + firmsize + shrimp + salmon", data=df_long).fit(cov_type='cluster', cov_kwds={'groups': df_long['firm']})

# d) Regression table
reg_table = sm_summary.summary_col([a, b, c], stars=True, float_format='%0.3f', model_names=["(a)", "(b)", "(c)"], 
                                       info_dict={'Observations': lambda x: f"{int(x.nobs)}"})
reg_str = reg_table.as_latex().split("\n")
month_idx = []
for i, li in enumerate(reg_str):
    if li.startswith('C(month)'):
        month_idx.append(i)
        month_idx.append(i + 1)
reg_str_filtered = [li for i, li in enumerate(reg_str) if i not in month_idx]
print("\n".join(reg_str_filtered))

output_path = os.path.join(outputpath, "regression_table.tex")
with open(output_path, "w") as f:
    f.write("\n".join(reg_str_filtered))