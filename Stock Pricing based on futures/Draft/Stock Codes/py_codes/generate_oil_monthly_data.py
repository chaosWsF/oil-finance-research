import pandas as pd
import numpy as np


class oil:

    def __init__(self, dat, oilname, start_date, end_date, varnames):

        self.dat = dat[oilname]
        self.oilname = oilname
        self.sdate = start_date
        self.edate = end_date
        self.col = ['date'] + varnames

    def load(self):

        data = self.dat
        data.date = data.date.apply(lambda x: '/'.join([str(str(x)[:4]), str(str(x)[4:6]), str(str(x)[6:])]))
        data.date = pd.to_datetime(data.date, format='%Y/%m/%d')
        
        oil_price = data.oilprice.values
        
        data['returnrate'] = np.nan
        data.iloc[:-1, -1] = np.log(oil_price[1:]) - np.log(oil_price[:-1])

        return data
    
    def generate_date_index(self):
        
        date_index = pd.date_range(self.sdate, self.edate, freq='MS')
        
        return date_index
    
    def init_monthly_data(self):

        monthly_data = pd.DataFrame(columns=self.col)

        return monthly_data
    
    def set_values(self, prices, returns):
        col = self.col[1:]
        results = []
        for c in col:
            if c == 'last':
                result = prices[-1]
            elif c == 'ma':
                result = np.mean(prices)
            elif c == 'sim_ret':
                result = prices[-1] / prices[0] - 1
            elif c == 'ret':
                result = np.mean(returns)
            elif c == 'vol':
                result = np.mean(returns**2)
            elif c == 'skew':
                result = np.mean(returns**3)
            elif c == 'vol_demean':
                result = np.mean((returns-returns.mean())**2)
            elif c == 'skew_demean':
                result = np.mean((returns-returns.mean())**3)
            elif c == 'norm1_ret':
                result = np.mean(returns) / np.std(returns)
            elif c == 'norm1_vol':
                result = np.mean(returns**2) / np.var(returns)
            elif c == 'norm1_skew':
                result = np.mean((returns/np.std(returns))**3)
            else:
                result = np.nan
            
            results.append(result)
        
        return results

    def add_columns(self):

        date_index = self.generate_date_index()
        data = self.load()
        monthly_data = self.init_monthly_data()
        monthly_data.date = date_index[:-1].strftime('%Y/%m')

        for i in range(len(date_index) - 1):
            this_month_data = data[(data.date >= date_index[i]) & (data.date < date_index[i+1])]
            this_month_price = this_month_data.oilprice.values
            this_month_return = this_month_data.returnrate.values
            if len(this_month_price) > 0:
                nonan_array = lambda arr: arr[~np.isnan(arr)]
                this_month_price = nonan_array(this_month_price)
                this_month_return = nonan_array(this_month_return)
                monthly_data.iloc[i, 1:] = self.set_values(this_month_price, this_month_return)
            else:
                monthly_data.iloc[i, 1:] = np.nan

        return monthly_data

dataPath = '../data/'
# fileName = 'oil_price.xlsx'
# outputFile = 'monthly_oil.xlsx'

fileName = 'oil_futures.xlsx'
outputFile = 'monthly_oil_futures.xlsx'

# startDate = '1950/1/1'
# endDate = '2019/4/1'

startDate = '1983/4/1'
endDate = '2019/9/1'

variables = [
    'last', 'ma', 'sim_ret', 
    'ret', 'vol', 'skew', 'vol_demean', 'skew_demean', 
    'norm1_ret', 'norm1_vol', 'norm1_skew'
]

dailyData = pd.read_excel(dataPath + fileName, sheet_name=None, na_values='NAN')
oilNameList = list(dailyData.keys())

with pd.ExcelWriter(dataPath + outputFile) as fw:
    for oilName in oilNameList:
        dailyOil = oil(dailyData, oilName, startDate, endDate, variables)
        monthlyData = dailyOil.add_columns()
        monthlyData.to_excel(fw, oilName, index=False)
        print(oilName)
