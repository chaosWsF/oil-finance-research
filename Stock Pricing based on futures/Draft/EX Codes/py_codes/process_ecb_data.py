import pandas as pd
import numpy as np


class exEuro:
    
    def __init__(self, filename, start_date, end_date):

        self.fname = filename
        self.sdate = start_date
        self.edate = end_date
    
    @property
    def load(self):

        data = pd.read_csv(self.fname)
        data.iloc[:, 0] = pd.to_datetime(data.iloc[:, 0])
        col = list(data.columns)
        col.pop(1)    # rm USD
        self.col = col

        return data

    def generate_daily_data(self):

        data = self.load
        usd_data = data['USD'].values
        ex_based_euro = data.iloc[:, 2:].values

        daily_data = pd.DataFrame(columns=self.col)
        daily_data.iloc[:, 0] = data.iloc[:, 0]
        # daily_data.iloc[:, 1:] = (ex_based_euro.T / usd_data.T).T
        daily_data.iloc[:, 1:] = ex_based_euro / usd_data[:, None]

        daily_data.sort_values(['Date'], inplace=True)

        return daily_data

    def generate_data(self):

        data = self.generate_daily_data()

        date_index = pd.date_range(self.sdate, self.edate, freq='MS')

        monthly_data = pd.DataFrame(columns=self.col)
        monthly_data.iloc[:, 0] = date_index[:-1].strftime('%Y/%m')

        for i in range(len(date_index) - 1):

            this_month_ex = data[(data.iloc[:, 0] >= date_index[i]) & (data.iloc[:, 0] < date_index[i + 1])]
            this_month_ex = this_month_ex.iloc[:, 1:].values

            this_month_return = np.nanmean(this_month_ex, axis=0)

            monthly_data.iloc[i, 1:] = this_month_return

        return monthly_data, data


dataPath = '../EX/source/daily/'
dataFile = 'eurofxref-hist.csv'
dailyDataFile = 'ecb_data_USD_daily.csv'
monthlyDataFile = 'ecb_data_USD_monthly.csv'

startDate = '1999/1/4'
endDate = '2019/9/1'

exData = exEuro(dataPath + dataFile, startDate, endDate)
monthlyData, dailyData = exData.generate_data()
dailyData.to_csv(dataPath + dailyDataFile, index=False)
monthlyData.to_csv(dataPath + monthlyDataFile, index=False)
