import numpy as np
import pandas as pd

dataFile = '../EX/Consumer Price Index.csv'
nameFile = '../EX/CourntryList.xlsx'

data = pd.read_csv(dataFile)
data = data.iloc[:, :-1]
nameList = pd.read_excel(nameFile)
names = nameList.dropna()
names = names.Name.values

usedIndex = data.loc[:, 'Country Name'].isin(names)
data = data[usedIndex]
data = data[data.loc[:, 'Attribute'] == 'Value']
data = data[data.loc[:, 'Indicator Code'] == 'PCPI_IX']
data.iloc[:, 5:-1] = data.iloc[:, 5:-1].apply(pd.to_numeric)

for name in names:
    if name not in data.loc[:, 'Country Name'].values:
        print('Not find ' + name)

baseName = data['Country Name'] == 'United States'
baseCPI = data[baseName]
baseCPI = baseCPI.iloc[:, 5:-1].values
data = data[~baseName]

data.iloc[:, 5:-1] = baseCPI / data.iloc[:, 5:-1].values
data.to_csv('../EX/CPI.csv', index=False)
