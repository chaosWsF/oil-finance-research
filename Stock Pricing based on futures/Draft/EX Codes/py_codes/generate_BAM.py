import json
import datetime
import pandas as pd
import numpy as np


class exBAM:

    def __init__(self, filename, start_date, end_date):

        self.fname = filename
        self.sdate = start_date
        self.edate = end_date
    
    @property
    def load(self):

        with open(self.fname, 'r') as f:
            data = json.load(f)
        
        return data
    
    def generate_daily_data(self):

        data = self.load
        daily_values = []
        for datum in data:
            ex = float(datum['CurrencyExchangeItems'][-4]['Middle'])
            date = datetime.datetime.strptime(datum['Date'].split('T')[0], '%Y-%m-%d')
            daily_values.append([date, ex])

        daily_data = pd.DataFrame(daily_values, columns=['date', 'BAM'])

        return daily_data
    
    def generate_data(self):

        data = self.generate_daily_data()
        
        date_index = pd.date_range(self.sdate, self.edate, freq='MS')

        monthly_data = pd.DataFrame(columns=['date', 'BAM'])
        monthly_data.date = date_index[:-1].strftime('%Y/%m')

        for i in range(len(date_index) - 1):
            this_month_data = data[(data.date >= date_index[i]) & (data.date < date_index[i + 1])]
            this_month_ex = this_month_data.BAM.values
            average_ex = np.mean(this_month_ex)
            
            monthly_data.iloc[i, 1] = average_ex
        
        return monthly_data, data


dataPath = '../EX/source/daily/'
dataFile = 'BAM.json'
dailyDataFile = 'BAM_daily.csv'
monthlyDataFile = 'BAM_monthly.csv'

startDate = '1999/1/1'
endDate = '2019/9/1'

bamData = exBAM(dataPath + dataFile, startDate, endDate)
monthlyData, dailyData = bamData.generate_data()
dailyData.to_csv(dataPath + dailyDataFile, index=False)
monthlyData.to_csv(dataPath + monthlyDataFile, index=False)
