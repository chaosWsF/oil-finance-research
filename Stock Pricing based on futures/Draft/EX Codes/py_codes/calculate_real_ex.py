import pandas as pd
import numpy as np

cpiFile = '../EX/CPI_1.csv'
exFile = '../EX/ex_data.csv'
nameFile = '../EX/CourntryList.xlsx'

cpiData = pd.read_csv(cpiFile)
exData = pd.read_csv(exFile)
nameData = pd.read_excel(nameFile)
nameData = nameData.dropna()

nameArr = nameData.Name.values
currArr = nameData.Used.values

countryNames = exData.columns
realExData = pd.DataFrame(columns=countryNames)
realExData.Month = exData.Month

for i in range(1, len(countryNames)):
    try:
        currIndex = nameArr[np.where(currArr == countryNames[i])][0]
        realEx = cpiData.loc[:, currIndex].values * exData.iloc[:, i].values
        realExData.iloc[:, i] = realEx
    except KeyError:
        realExData.iloc[:, i] = np.nan
        print('Miss', currIndex, countryNames[i])
    
realExData.to_csv('../EX/real_ex.csv', index=False)
