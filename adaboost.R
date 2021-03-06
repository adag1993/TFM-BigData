library(rpart)
library(caret)
library(RColorBrewer)
library(randomForest)
library(ROCR)
library(caTools)
library(gbm)
library(neuralnet)
library(ada)
library(rpart)

rm(list = ls())

set.seed(42)
final <- read.csv("C:/Users/Abel de Andr�s G�mez/OneDrive/TFM/TraumaticData.csv",na.strings=c("","NA"))

summary(final)
#Max-Min Normalization
normalize <- function(x) {
  return ((x - min(x)) / (max(x) - min(x)))
}

final <- as.data.frame(lapply(final, normalize))
summary(final)


final$outcome<-as.factor(ifelse(final$outcome == "1", "F", "V"))
#final$outcome<-class.ind(final$outcome)
ind<-sample.split(Y=final$outcome,SplitRatio =0.7)
train <- final[ind,]
test <- final[!ind,]

nnetGrid <-  expand.grid(
  iter = seq(from = 1, to = 200, by = 10),
  maxdepth = seq(from = 1, to = 10, by = 1),
  nu = seq(from = 0.1, to = 0.4, by = 0.1)
  )

trainControl <- trainControl(method="cv", number=10)
metric <- "Accuracy"
rfRandom <- train(outcome~., data=train, method="ada", 
                  trControl=trainControl,metric=metric,tuneGrid = nnetGrid)
print(rfRandom)
plot(rfRandom)




model.ada<-ada(outcome~.,data=train,iter=141,nu=0.3,control=rpart.control(maxdepth=1))

print(model.ada)
plot(model.ada)

adaboost.predict=predict(model.ada,test)
confusionMatrixAdaBoost<-confusionMatrix(data=model.ada$confusion,reference=test$outcome,positive="F")
confusionMatrixAdaBoost
fourfoldplot(confusionMatrixAdaBoost$table)

