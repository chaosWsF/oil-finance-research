import numpy as np
import pandas as pd


def get_monthly(df):
    df_groups = df.groupby(pd.Grouper(key='Date', freq='M'))
    return df_groups.last()


data_path = './data/'

aqr_commodity_indices = pd.read_excel(
    data_path + 'Commodities for the Long Run Updated Monthly Data.xlsx', sheet_name='Data', 
    usecols=list(range(10)), skiprows=10, 
    names=['Date', 'CI_1', 'CI_2', 'CI_3', 'CI_4', 'CI_5', 'CI_6', 'CI_7', 'CI_8', 'CI_9']
)
tmp = pd.to_datetime(aqr_commodity_indices.iloc[0:275, 0], format='%Y-%m-%d %H:%M:%S')
tmp1 = pd.to_datetime(aqr_commodity_indices.iloc[275:, 0], format='%m/%d/%Y')
aqr_commodity_indices.Date = tmp.append(tmp1)
aqr_ci = get_monthly(aqr_commodity_indices)

commodity_indices = pd.read_excel(data_path + 'GSCI_SP_TR.xlsx', names=['Date', 'CI_10'])
commodity_indices.Date = pd.to_datetime(commodity_indices.Date, format='%Y%m%d')
ci = get_monthly(commodity_indices)

oil_prices = pd.read_excel(data_path + 'oil_commodity_futures.xlsx', sheet_name=None)
column_names = ['CI_11', 'CI_12', 'CI_13', 'CI_14', 'CI_15', 'CI_16', 'CI_17']
for i, s_i in enumerate(oil_prices):
    oil_price = oil_prices[s_i]
    oil_price = oil_price.rename(columns={'date': 'Date', 'close': column_names[i]})
    oil_price.Date = pd.to_datetime(oil_price.Date, format='%Y%m%d')
    cur = get_monthly(oil_price)
    ci = ci.join(cur, how='outer')

r_ci = np.log(ci).diff(1)
r_ci = aqr_ci.join(r_ci, how='outer')
r_ci = r_ci.reset_index()
r_ci.Date = list(map(int, list(r_ci.Date.dt.strftime('%Y%m%d'))))

with pd.ExcelWriter(data_path + 'CI.xlsx', engine='openpyxl', mode='a') as writer:
    r_ci.to_excel(writer, sheet_name='data', index=False)
