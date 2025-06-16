library(Amelia)
library(ggplot2)
library(caTools)
library(car)
library(Metrics)
library(PRROC)

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
numeric.cols <- sapply(heart.data, is.numeric)

#normality test
for (col in names(heart.data)[numeric.cols]) {
  cat("Testing", col, "...\n")
  print(shapiro.test(heart.data[[col]]))
}

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

heart.data[numeric.cols] <- scale(heart.data[numeric.cols])

one.hot.encoding <- model.matrix(~. -TenYearCHD -1, data = heart.data)
heart.data.encoded <- data.frame(one.hot.encoding, heart.data$TenYearCHD)

set.seed(0)

data.split <- sample.split(heart.data, SplitRatio = 0.7)

train <- subset(heart.data, data.split == T)
test <- subset(heart.data, data.split == F)

train.encoded <- subset(heart.data.encoded, data.split == T)
test.encoded <- subset(heart.data.encoded, data.split == F)

thresholds <- seq(0, 1, by = 0.01)
actual <- as.numeric(as.character(test$TenYearCHD))

#logistic model
log.model <- glm(TenYearCHD ~ ., family = binomial(link = 'logit'), train)
summary(log.model)

var.vif <- vif(log.model)

log.model.preds <- predict(log.model, test, type = 'response')
log.model.preds.class <- ifelse(log.model.preds > 0.2, 1, 0)
log.conf.matrix <- table(test$TenYearCHD, log.model.preds.class, dnn = c('Actual', 'Predicted'))

log.recall <- recall(actual, log.model.preds.class)
log.precision <- precision(actual, log.model.preds.class)

log.accuracy <- accuracy(actual, log.model.preds.class)

log.pr <- pr.curve(log.model.preds[actual == 1], log.model.preds.class[actual == 0], curve = T)
plot(log.pr, main = 'Log Model')

#calculating optimal logmodel f1 score
log.f1s <- numeric(length(thresholds))
log.recalls <- numeric(length(thresholds))
log.precisions <- numeric(length(thresholds))
log.accuracies <- numeric(length(thresholds))
for(i in seq_along(thresholds)) {
  t <- thresholds[i]
  preds <- ifelse(log.model.preds > t, 1, 0)
  log.recalls[i] <- recall(actual, as.numeric(as.character(preds)))
  log.precisions[i] <- precision(actual, as.numeric(as.character(preds)))
  log.f1s[i] <- fbeta_score(actual, preds)
  log.accuracies[i] <- accuracy(actual, preds)
}

log.metrics <- data.frame(log.recalls, log.precisions, log.f1s, log.accuracies)

#LDA model
library(MASS)

lda.model <- lda(train$TenYearCHD ~ ., data = train)
lda.model

lda.pred <- predict(lda.model, test)
custom.lda.pred <- ifelse(lda.pred$posterior[,1] > 0.1, 1, 0)
lda.conf.matrix <- table(test$TenYearCHD, custom.lda.pred, dnn = c('Actual', 'Predicted'))


lda.recall <- recall(test$TenYearCHD, custom.lda.pred)
lda.precision <- precision(as.numeric(as.character(test$TenYearCHD)), custom.lda.pred)

lda.accuracy <- accuracy(test$TenYearCHD, lda.pred$class)

lda.pr <- pr.curve(lda.pred$posterior[actual == 1], lda.pred$posterior[actual == 0], curve = T)
plot(lda.pr, main = 'LDA Model')

#calculating optimal ldamodel f1 score
lda.f1s <- numeric(length(thresholds))
lda.recalls <- numeric(length(thresholds))
lda.precisions <- numeric(length(thresholds))
lda.accuracies <- numeric(length(thresholds))
for(i in seq_along(thresholds)) {
  t <- thresholds[i]
  preds <- ifelse(lda.pred$posterior[,1] > t, 1, 0)
  lda.recalls[i] <- recall(actual, as.numeric(as.character(preds)))
  lda.precisions[i] <- precision(actual, as.numeric(as.character(preds)))
  lda.f1s[i] <- fbeta_score(actual, preds)
  lda.accuracies[i] <- accuracy(actual, preds)
}

lda.metrics <- data.frame(lda.recalls, lda.precisions, lda.f1s, lda.accuracies)

#QDA model
qda.model <- qda(train$TenYearCHD ~ ., data = train)
qda.model

qda.pred <- predict(qda.model, test)
qda.conf.matrix <- table(test$TenYearCHD, qda.pred$class, dnn = c('Actual', 'Predicted'))

qda.recall <- recall(as.numeric(as.character(test$TenYearCHD)), as.numeric(as.character(qda.pred$class)))
qda.precision <- precision(as.numeric(as.character(test$TenYearCHD)), as.numeric(as.character(qda.pred$class)))

qda.accuracy <- accuracy(as.numeric(as.character(test$TenYearCHD)), as.numeric(as.character(qda.pred$class)))

qda.pr <- pr.curve(qda.pred$posterior[actual == 1], qda.pred$posterior[actual == 0], curve = T)
plot(qda.pr, main = 'QDA Model')

#calculating optimal qdamodel f1 score
qda.f1s <- numeric(length(thresholds))
qda.recalls <- numeric(length(thresholds))
qda.precisions <- numeric(length(thresholds))
qda.accuracies <- numeric(length(thresholds))
for(i in seq_along(thresholds)) {
  t <- thresholds[i]
  preds <- ifelse(qda.pred$posterior[,1] > t, 1, 0)
  qda.recalls[i] <- recall(actual, as.numeric(as.character(preds)))
  qda.precisions[i] <- precision(actual, as.numeric(as.character(preds)))
  qda.f1s[i] <- fbeta_score(actual, preds)
  qda.accuracies[i] <- accuracy(actual, preds)
}

qda.metrics <- data.frame(qda.recalls, qda.precisions, qda.f1s, qda.accuracies)

#KNN model
library(class)

predicted.CHD <- NULL
error.rate <- NULL

for(i in 1:20) {
  set.seed(101)
  predicted.CHD <- knn(train.encoded[1:18], test.encoded[1:18], train.encoded$heart.data.TenYearCHD, k=i)
  error.rate[i] <- mean(test.encoded$heart.data.TenYearCHD != predicted.CHD)
}

k <- 1:20

error.data <- data.frame(error.rate, k)

ggplot(error.data, aes(k, error.rate)) + geom_point() + geom_line(linetype = 2, color = 'red')

knn.model <- knn(train.encoded[1:18], test.encoded[1:18], train.encoded$heart.data.TenYearCHD, k=13, prob = T)

probs <- attr(knn.model, 'prob')

knn.conf.matrix <- table(test.encoded$heart.data.TenYearCHD, knn.model, dnn = c('Actual', 'Predicted'))

knn.TN <- knn.conf.matrix[1,1]
knn.TP <- knn.conf.matrix[2,2]
knn.FP <- knn.conf.matrix[1,2]
knn.FN <- knn.conf.matrix[2,1]

knn.recall <- recall(as.numeric(as.character(test.encoded$heart.data.TenYearCHD)), as.numeric(as.character(knn.model)))
knn.precision <- precision(as.numeric(as.character(test.encoded$heart.data.TenYearCHD)), as.numeric(as.character(knn.model)))

knn.accuracy <- mean(knn.model == test.encoded$heart.data.TenYearCHD)

probs.positive <- ifelse(knn.model == 1, probs, 1 - probs)

knn.pr <- pr.curve(probs.positive[actual == 1], probs.positive[actual == 0], curve = T)
plot(knn.pr, main = 'KNN Model')

knn.f1s <- numeric(length(thresholds))
knn.recalls <- numeric(length(thresholds))
knn.precisions <- numeric(length(thresholds))
knn.accuracies <- numeric(length(thresholds))
for(i in seq_along(thresholds)) {
  t <- thresholds[i]
  preds <- ifelse(probs.positive > t, 1, 0)
  knn.recalls[i] <- recall(actual, as.numeric(as.character(preds)))
  knn.precisions[i] <- precision(actual, as.numeric(as.character(preds)))
  knn.f1s[i] <- fbeta_score(actual, preds)
  knn.accuracies[i] <- accuracy(actual, preds)
}

knn.metrics <- data.frame(knn.recalls, knn.precisions, knn.f1s, knn.accuracies)

#comparison
precision.vec <- c(log.precision, lda.precision, qda.precision, knn.precision) * 100
recall.vec <- c(log.recall, lda.recall, qda.recall, knn.recall) * 100
accuracy.vec <- c(log.accuracy, lda.accuracy, qda.accuracy, knn.accuracy) * 100
model <- c('Logistic Regression', 'LDA', 'QDA', 'KNN')
eval.metrics.df <- data.frame(model, precision.vec, recall.vec, accuracy.vec)

#precision recall plot
ggplot(eval.metrics.df, aes(recall.vec, precision.vec)) + 
  geom_point(aes(colour = model), show.legend = F) + theme_bw() +
  geom_text(aes(label = model), hjust = -0.2) +
  xlab('Recall(%)') + ylab('Precision(%)') +
  ggtitle('Model Precision vs Recall') +
  theme(plot.title = element_text(hjust = 0.5))
  
#accuracy plot
ggplot(eval.metrics.df, aes(model, accuracy.vec)) +
  geom_col(aes(fill = model), show.legend = F, width = 0.5) + theme_bw() +
  coord_cartesian(ylim = c(83, 84.5))

par(mfrow = c(2,2))
plot(log.pr, main = 'Log Model')
plot(lda.pr, main = 'LDA Model')
plot(qda.pr, main = 'QDA Model')
plot(knn.pr, main = 'KNN Model')
