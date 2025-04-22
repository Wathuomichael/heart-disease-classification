# Summary
Analysis showed that some of the most important predictors for ten year risk of coronary heart disease include gender, where men have a higher risk than women. Age was also significant factor as risk was more prevalent among older people. Number of cigarettes used per day showed increase in risk with more cigarettes by as much as 1.7% per extra cigarette per day. Others included: Hypertension, total cholesterol level, systolic blood pressure and glucose level.

Model predictions using a threshold of 0.5 contained a lot of false negatives with only a 7% of actual positives correctly predicted and when the model predicted positive it had an accuracy of 72%.

# Introduction
This is a report on the analysis of the factors that are associated with risk of future heart disease as well as predicting risk of heart disease using logistic regression. The dataset contains information on patients from Framingham, Massachusetts.

## Findings
### Age
![Age against risk boxplot](images/age-v-risk-boxplot.png)

The plot above shows the relationship between age and risk of coronary heart disease. Individuals who are older have a higher risk of coronary heart disease compared to their younger counterparts.

The plot below shows the distribution of age based on heart disease risk. We notice the large majority of younger people are in the no risk category and majority of older people are in the risk category.

![Age against risk violin plot](images/age-v-risk.png)



