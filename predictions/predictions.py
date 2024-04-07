import pandas
from sklearn import linear_model



training_set = pandas.read_csv("training_set.csv")
unlabeled_set = pandas.read_csv("unlabeled_set.csv")



X = training_set[['TYPE_OF_SHOT', 'DISTANCE_OF_SHOT', 'POWER_OF_SHOT']]
y = training_set['IS_GOAL']




regr = linear_model.LinearRegression()
regr.fit(X, y)



predicted = regr.predict(unlabeled_set)

print(predicted)



unlabeled_set['TARGET'] = predicted

print(unlabeled_set)

unlabeled_set.to_csv('predictions.csv', index=False)
