# phdee-KL homework 1

# Sample code to get you started -- Dylan Brewer, 2021
# This script reads in data, generates a table of means and standard deviations, plots a histogram, estimates a linear regression model, and bootstraps confidence intervals for the coefficients.  It outputs a table of means and standard deviations, a histogram, a table of regression output, and a plot of the regression output with error bars.

# Import packages - you may need to type "conda install numpy" the first time you use a package, for example.

import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import statsmodels.api as sm

# Set working directories and seed

outputpath = r'/Users/kellylifchez/GaTech Dropbox/Kelly Lifchez/phdee-KL/homework1/output'
# Normally I will also have a datapath where I store the original data if I am working on a small enough csv file.

np.random.seed(6578103)

# Generate some random data --------------------------------------------------
nobs = 100 # set number of observations

truexvars = np.random.multivariate_normal((10,20,15),[[10,5,6],[5,15,25],[6,25,100]],nobs) # Random data

truebetas = np.array([[-3,11,1]]).T # parameters

yvar = np.matmul(truexvars,truebetas)

# Define what independent variables we observe -------------------------------
xvars = truexvars[:,0:2] # The last column of xvars is not observed
data = pd.DataFrame(np.concatenate([yvar,xvars], axis = 1),columns = ['Outcome','X1','X2']) # Convert to a pandas data frame for demonstration

# Generate a table of means and standard deviations for the observed variables (there are faster ways to do this that are less general)
## Generate means
means = data.mean()

## Generate standard deviations
stdev = data.std()

## Get number of observations
nobs2 = int(data.count().min())

## Set the row and column names
rownames = pd.concat([pd.Series(['Outcome','Variable 1','Variable 2', 'Observations']),pd.Series([' ',' ',' '])],axis = 1).stack() # Note this stacks an empty list to make room for stdevs
colnames = [('Mean','(s.d.)')] # Two rows of column names

## Format means and std devs to display to two decimal places
means = means.map('{:.2f}'.format)
stdev = stdev.map('({:.2f})'.format)

## Align std deviations under means and add observations
col0 = pd.concat([means,stdev,pd.Series(f"{int(nobs2)}")],axis = 1).stack()

## Add column and row labels.  Convert to dataframe (helps when you export it)
col0 = pd.DataFrame(col0)
col0.index = rownames
col0.columns = pd.MultiIndex.from_tuples(colnames)

## Output to LaTeX folder
os.chdir(outputpath) # Output directly to LaTeX folder

col0.to_latex('samplemeantable.tex') # Note you would have to stitch together multiple series into a dataframe to have multiple columns

# Plot a histogram of the outcome variable -----------------------------------
sns.displot(yvar,kind='kde',legend = False)
plt.xlabel('Outcome variable')
plt.legend(labels = ['Distribution of outcome variable'],loc = 'best',bbox_to_anchor = (0.75,-0.1))
plt.savefig('samplehist.pdf',format='pdf') # I suggest saving to .pdf for highest quality
plt.show()

# Fit a linear regression model to the data ----------------------------------
## Using statsmodels
ols = sm.OLS(data['Outcome'],sm.add_constant(data.drop('Outcome',axis = 1))).fit()
betaols = ols.params.to_numpy() # save estimated parameters
params, = np.shape(betaols) # save number of estimated parameters
nobs3 = np.round(int(ols.nobs))

# Bootstrap by hand and get confidence intervals -----------------------------
## Set values and initialize arrays to output to
breps = 100 # number of bootstrap replications
olsbetablist = np.zeros((breps,params))

## Get an index of the data we will sample by sampling with replacement
bidx = np.random.choice(nobs3,(nobs3,breps)) # Generates random numbers on the interval [0,nobs3] and produces a nobs3 x breps sized array

## Sample with replacement to get the size of the sample on each iteration
for r in range(breps):
    ### Sample the data
    datab = data.iloc[bidx[:,r]]
    
    ### Perform the estimation
    olsb = sm.OLS(datab['Outcome'],sm.add_constant(datab.drop('Outcome',axis = 1))).fit()
    
    ### Output the result
    olsbetablist[r,:] = olsb.params.to_numpy()
    
## Extract 2.5th and 97.5th percentile
lb = np.percentile(olsbetablist,2.5,axis = 0, method = 'lower')
ub = np.percentile(olsbetablist,97.5,axis = 0, method = 'higher')

# Regression output table with CIs -- again, this is a bit more general than usually necessary.  In this case, we cannot output CIs directly because we have bootstrapped them by hand.  If you were doing something without custom bootstrapping, you could use the Python package "stargazer" to output a table of regression results.
## Format estimates and confidence intervals
betaols = np.round(betaols,2)

lbP = pd.Series(np.round(lb,2)) # Round to two decimal places and get a Pandas Series version
ubP = pd.Series(np.round(ub,2))
ci = '(' + lbP.map(str) + ', ' + ubP.map(str) + ')'

## Get output in order
order = [1,2,0]
output = pd.DataFrame(np.column_stack([betaols,ci])).reindex(order)

## Row and column names
rownames = pd.concat([pd.Series(['Variable 1','Variable 2','Constant','Observations']),pd.Series([' ',' ',' '])],axis = 1).stack() # Note this stacks an empty list to make room for CIs
colnames = ['Estimates']

## Append CIs, # Observations, row and column names
output = pd.DataFrame(pd.concat([output.stack(),pd.Series(nobs3)]))
output.index = rownames
output.columns = colnames

## Output directly to LaTeX
output.to_latex('sampleoutput.tex')

# Plot regression output with error bars -------------------------------------
lowbar = np.array(betaols - lb)
highbar = np.array(ub - betaols)
plt.errorbar(y = betaols, x = np.arange(params), yerr = [lowbar,highbar], fmt = 'o', capsize = 5)
plt.ylabel('Coefficient estimate')
plt.xticks(np.arange(params),['Constant', 'Variable 1', 'Variable 2'])
plt.xlim((-0.5,2.5)) # Scales the figure more nicely
plt.axhline(linewidth=2, color='r')
plt.savefig('samplebars.pdf',format='pdf')
plt.show()