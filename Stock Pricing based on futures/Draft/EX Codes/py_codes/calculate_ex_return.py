import pandas as pd
import numpy as np

dataPath = '../EX/'
# dataFile = 'ex_data.csv'
# returnExFile = 'ex_return.csv'
dataFile = 'real_ex.csv'
returnExFile = 'real_ex_return.csv'

data = pd.read_csv(dataPath + dataFile)
returnExData = pd.DataFrame(columns=data.columns)
returnExData.Month = data.Month[1:]

exData = data.iloc[:, 1:].values
returnExData.iloc[:, 1:] = exData[1:] / exData[:-1]

returnExData.to_csv(dataPath + returnExFile, index=False)
