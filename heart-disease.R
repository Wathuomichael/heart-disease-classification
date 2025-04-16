library(Amelia)
library(ggplot2)
library(caTools)
library(car)

heart.data <- read.csv('./Documents/stats/models/Logistic Regression/Heart-disease-classification/framingham.xls')

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

ggplot(heart.data, aes(as.factor(TenYearCHD), age)) + geom_boxplot() + theme_bw()
ggplot(heart.data, aes(x = factor((TenYearCHD), labels = c('No Disease', 'Heart Disease')), y = age)) + 
  geom_violin(aes(fill = TenYearCHD)) + theme_bw() +
  ggtitle('Age against Heart Disease Risk') + 
  xlab('Heart disease risk') + ylab('Age') +
  scale_fill_discrete(labels = c('No Disease', 'Heart Disease')) +
  theme(plot.title = element_text(hjust = 0.5))

table(heart.data$TenYearCHD, heart.data$currentSmoker, dnn = c('TenYearCHD', 'currentsmoker'))
table(heart.data$TenYearCHD, heart.data$BPMeds, dnn = c('TenYearCHD', 'bpmeds'))

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
