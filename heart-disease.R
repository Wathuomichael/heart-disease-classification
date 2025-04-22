library(Amelia)
library(ggplot2)
library(caTools)
library(car)

heart.data <- read.csv('./Documents/stats/models/logistic-regression/Heart-disease-classification/framingham.xls')

heart.data$male <- sapply(heart.data$male, factor)
heart.data$education <- sapply(heart.data$education, factor)
heart.data$currentSmoker <- sapply(heart.data$currentSmoker, factor)
heart.data$BPMeds <- sapply(heart.data$BPMeds, factor)
heart.data$prevalentStroke <- sapply(heart.data$prevalentStroke, factor)
heart.data$prevalentHyp <- sapply(heart.data$prevalentHyp, factor)
heart.data$diabetes <- sapply(heart.data$diabetes, factor)
heart.data$TenYearCHD <- sapply(heart.data$TenYearCHD, factor)

missmap(heart.data, col = c('yellow', 'black'))

heart.data <- na.omit(heart.data)

#age against risk boxplot
ggplot(heart.data, aes(x = factor((TenYearCHD), labels = c('No', 'Yes')), age)) +
  geom_boxplot() + theme_bw() + 
  xlab('Heart Disease Risk') + ylab('Age') +
  ggtitle('Age against Heart Disease Risk') + 
  theme(plot.title = element_text(hjust = 0.5))

#age against risk violin plot
ggplot(heart.data, aes(x = factor((TenYearCHD), labels = c('No', 'Yes')), y = age)) + 
  geom_violin(aes(fill = TenYearCHD)) + theme_bw() +
  ggtitle('Age against Heart Disease Risk') + 
  xlab('Heart Disease Risk') + ylab('Age') +
  scale_fill_discrete(labels = c('No Disease', 'Heart Disease')) +
  theme(plot.title = element_text(hjust = 0.5))

#sysbp against risk boxplot
ggplot(heart.data, aes(factor((TenYearCHD), labels = c('No', 'Yes')), sysBP)) + 
  geom_boxplot() + theme_bw() + 
  xlab('Heart Disease Risk') + ylab('Systolic Blood Pressure') +
  ggtitle('Systolic Blood Pressure against Heart Disease Risk') +
  theme(plot.title = element_text(hjust = 0.5))

#diabp against risk boxplot
ggplot(heart.data, aes(factor((TenYearCHD), labels = c('No', 'Yes')), diaBP)) + 
  geom_boxplot() + theme_bw() + 
  xlab('Heart Disease Risk') + ylab('Diastolic Blood Pressure') +
  ggtitle('Diastolic Blood Pressure against Heart Disease Risk') +
  theme(plot.title = element_text(hjust = 0.5))

set.seed(0)

data.split <- sample.split(heart.data, SplitRatio = 0.7)

train <- subset(heart.data, data.split == T)
test <- subset(heart.data, data.split == F)

model <- glm(TenYearCHD ~ ., family = binomial(link = 'logit'), train)
summary(model)

var.vif <- vif(model)

model.preds <- predict(model, test, type = 'response')
model.preds.class <- ifelse(model.preds > 0.5, 1, 0)
conf.matrix <- table(test$TenYearCHD, model.preds.class, dnn = c('Actual', 'Predictions'))

TN <- conf.matrix[1,1]
TP <- conf.matrix[2,2]
FP <- conf.matrix[1,2]
FN <- conf.matrix[2,1]

recall <- TP / (TP + FN)
precision <- TP / (TP + FP)
