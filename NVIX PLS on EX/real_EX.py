# %%
import numpy as np
import pandas as pd
from collections import OrderedDict

# %%
EX_Path = './data/Belt_Road_EX_monthly.xlsx'
EX = pd.read_excel(EX_Path, sheet_name=None)
BR_Country = EX['Description']
EX = EX['Data']
dates = EX['Date'].to_numpy()
dates = dates.reshape((-1, 1))

# %%
EUR_Country = BR_Country[BR_Country['Currency Code'] == 'EUR']['Country Name'].to_list()
EX_col = EX.columns.to_list()
EX_val = EX.iloc[:, 1:].to_numpy().T.tolist()

real_EX_col = [EX_col[0]]
real_EX_val = []
for i in range(1, len(EX_col)):
    col = EX_col[i]
    val = EX_val[i - 1]
    if col == 'EUR':
        for name in EUR_Country:
            real_EX_col.append(col + ' ' + name)
            real_EX_val.append(val)
    else:
        real_EX_col.append(col)
        real_EX_val.append(val)

real_EX_val = np.asarray(real_EX_val)

# %%
CPI_Path = './data/Consumer Price Index.csv'
CPI = pd.read_csv(CPI_Path)

# %%
CPI = CPI.groupby(['Indicator Code', 'Attribute'])
CPI = CPI.get_group(('PCPI_IX', 'Value'))
CPI = CPI.reset_index(drop=True)

# %%
baseCPI = CPI.loc[CPI['Country Name'] == 'United States', '1980M1':'2019M3'].to_numpy()
baseCPI = baseCPI.astype('float64')

BR_Country = OrderedDict.fromkeys(BR_Country['Country Name'].to_list())
for i, x in enumerate(CPI['Country Name'].to_list()):
    if x in BR_Country:
        BR_Country[x] = i

# %%
CPI = CPI.reindex(BR_Country.values())
CPI = CPI.reset_index(drop=True)
CPI = CPI.loc[:, '1980M1':'2019M3'].to_numpy()
CPI = CPI.astype('float64')

# %%
real_EX_val = real_EX_val * baseCPI / CPI
real_EX = pd.DataFrame(np.hstack((dates, real_EX_val.T)), columns=real_EX_col)
real_EX['Date'] = real_EX['Date'].astype('int64')


# %%
real_EX.to_csv('./data/real_EX.csv', index=False)

# %%
