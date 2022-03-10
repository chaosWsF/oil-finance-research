import pandas as pd
import numpy as np
from sklearn.linear_model import LinearRegression


def normalize_results(df):
    process_df = df.iloc[:, 1:]
    df.iloc[:, 1:] = (process_df - process_df.mean()) / process_df.std()
    return df

dataPath = '../data/'
dataFile = 'stock.csv'
# outputFile = 'res_iv_is.xlsx'
outputFile = 'res_iv_is_standard.xlsx'

data = pd.read_csv(dataPath + dataFile)
data.date = pd.to_datetime(data.date, format='%Y/%m/%d')

startDate = '2002/1/1'
endDate = '2019/4/1'
dateIndex = pd.date_range(startDate, endDate, freq='MS')

col = [list(data.columns)[0]] + list(data.columns)[3:23]
resData = pd.DataFrame(columns=col)
resData.date = dateIndex[:-1].strftime('%Y/%m')
ivData = resData.copy()
isData = resData.copy()

for i in range(len(dateIndex) - 1):
    thisMonthData = data[(data.date >= dateIndex[i]) & (data.date < dateIndex[i + 1])]
    thisMonthStock = thisMonthData.iloc[:, 3:23].values # 20 industries
    thisMonthIndex = thisMonthData.iloc[:, 2].values   # sh300

    linreg = LinearRegression()
    X = thisMonthIndex.reshape([-1,1])
    y = thisMonthStock
    linreg.fit(X, y)
    residuals = y - (np.dot(X, linreg.coef_.T) + linreg.intercept_.reshape([1,-1]))
    # residualsModified = residuals - np.mean(residuals, axis=0)
    residualsNormalized = (residuals - np.mean(residuals, axis=0)) / np.std(residuals, axis=0)

    resData.iloc[i, 1:] = np.sum(residuals, axis=0)
    ivData.iloc[i, 1:] = np.sum(residuals ** 2, axis=0)
    isData.iloc[i, 1:] = np.sum(residualsNormalized ** 3, axis=0)

# resData = normalize_results(resData)
# ivData = normalize_results(ivData)
# isData = normalize_results(isData)

with pd.ExcelWriter(dataPath + outputFile) as fw:
    resData.to_excel(fw, sheet_name='RES', index=False)
    ivData.to_excel(fw, sheet_name='IV', index=False)
    isData.to_excel(fw, sheet_name='IS', index=False)