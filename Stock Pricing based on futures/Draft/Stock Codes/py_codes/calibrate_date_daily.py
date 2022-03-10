# This file should be run after merge_oil_daily.py.
# This file can compare date index between oil and stock. Then pick up 
# the same part and remove the different part.

import pandas as pd


baseDateFile = '../data/stock.csv'
dateFile = '../data/daily_data_un.csv'
baseDates = pd.read_csv(baseDateFile)
dateDF = pd.read_csv(dateFile)

baseDates.date = pd.to_datetime(baseDates.date, format='%Y/%m/%d')
baseDates = baseDates.date.dt.strftime('%Y-%m-%d')
baseDates = baseDates.values[::-1]
dateDF.date = pd.to_datetime(dateDF.date, format='%Y/%m/%d')

df = pd.DataFrame(columns=dateDF.columns)
df.date = baseDates
dateDF.set_index('date', inplace=True)

for i in range(len(baseDates)):
    if i % 100 == 0:
        print(baseDates[i])
    
    try:
        df.iloc[i, 1:] = dateDF.loc[baseDates[i]].values
    except KeyError:
        df.iloc[i, 1:] = None

df.to_csv('../data/daily_data.csv', index=False)