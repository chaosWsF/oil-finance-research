# This file should be run before calibrate_date_daily.py.
# This file can merge different oils and set NAN at each nontrading day.

import pandas as pd

dataPath = '../data/'
dataFile = 'oil_price.xlsx'
dailyDataFile = 'daily_data_un.csv'

data = pd.read_excel(dataPath + dataFile, sheet_name=[0, 1, 2, 3, 4, 5])

startDate = '1950/1/2'
endDate = '2019/5/10'
dateIndex = pd.date_range(startDate, endDate, freq='D')

col = ['date', 'arabian', 'dubai', 'brent', 'oil_future', 'WTI_cushing', 'WTI_Midland']
dailyData = pd.DataFrame(columns=col)
dailyData.date = dateIndex.strftime('%Y/%m/%d')

for k in range(1, len(col)):
    print(col[k])
    dat = data[k-1]
    dat.date = dat.date.apply(lambda x: '/'.join([str(str(x)[:4]), str(str(x)[4:6]), str(str(x)[6:])]))
    dat.date = pd.to_datetime(dat.date, format='%Y/%m/%d')
    for i in range(len(dateIndex)):
        thisDayData = dat[dat.date == dateIndex[i]]
        thisDayData = thisDayData.oilprice.values
        if len(thisDayData) > 0:
            dailyData.iloc[i, k] = thisDayData[0]
        
        if i % 100 == 0:
            print(dateIndex[i])

dailyData = dailyData[dailyData.iloc[:, 1:].notna().any(axis=1)].reset_index(drop=True)
dailyData.to_csv(dataPath + dailyDataFile, index=False)