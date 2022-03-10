import pandas as pd
import numpy as np

dataPath = '../EX/'
dataFile = 'bonds.txt'
monthDataFile = 'month_bonds.csv'

data = pd.read_csv(dataPath + dataFile, sep='\t')
data.Date = pd.to_datetime(data.Date, format='%m/%d/%y')

startDate = '2002/1/1'
endDate = '2019/4/1'
dateIndex = pd.date_range(startDate, endDate, freq='MS')

monthData = pd.DataFrame(columns=data.columns)
monthData.Date = dateIndex[:-1].strftime('%Y/%m')

for i in range(len(dateIndex) - 1):
    thisMonthData = data[(data.Date >= dateIndex[i]) & (data.Date < dateIndex[i + 1])]
    
    thisMonthVal = thisMonthData.iloc[:,1:].values / 12
    returnData = np.mean(thisMonthVal, axis=0)
    monthData.iloc[i, 1:] = (returnData / 100) + 1

monthData.to_csv(dataPath + monthDataFile, index=False)