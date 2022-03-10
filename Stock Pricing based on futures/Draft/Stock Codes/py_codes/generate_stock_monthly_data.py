import pandas as pd
import numpy as np
from os.path import dirname, join
from sklearn.linear_model import LinearRegression


class dailyData:

    def __init__(self, filename, start_date, end_date, output):

        self.fname = filename
        self.sdate = start_date
        self.edate = end_date
        self.oname = join(dirname(filename), output)
    
    @property
    def load(self):

        data = pd.read_csv(self.fname)
        data.date = pd.to_datetime(data.date, format='%Y/%m/%d')
        self.col = data.columns

        return data
    
    @property
    def init_monthly(self):

        date_index = pd.date_range(self.sdate, self.edate, freq='MS')

        monthly_data = pd.DataFrame(columns=self.col)
        monthly_data.date = date_index[:-1].strftime('%Y/%m')

        return monthly_data, date_index
    
    @property
    def generating(self):

        data = self.load
        monthly_data, date_index = self.init_monthly

        for i in range(len(date_index)-1):

            this_month_data = data[(data.date >= date_index[i]) & (data.date < date_index[i+1])]
            this_month_data = this_month_data.iloc[:, 1:].values

            if len(this_month_data) > 0:
                monthly_data.iloc[i, 1:] = self.set_values(this_month_data)
            else:
                monthly_data.iloc[i, 1:] = np.nan
            
        return monthly_data
    
    def set_values(self, dat):
        return dat[0] / dat[-1]

    def writing(self):

        monthly_data = self.generating
        monthly_data.to_csv(self.oname, index=False)
        print('Save in ' + self.oname)


class huanbao(dailyData):

    def set_values(self, dat):
        return dat[-1] / dat[0]


class shibor(dailyData):

    def set_values(self, dat):

        result = dat / 1200
        result = 1 + np.mean(result)
        
        return result


class stockLast(dailyData):

    def set_values(self, dat):
        return dat[0]


# # futures
# dataPath = '../data/'
# dataFile = 'data_EF_BF_CF_shf.csv'
# monthDataFile = 'month_EF_BF_CF_shf.csv'
# startDate = '1995/4/1'
# endDate = '2019/4/1'
# futureDaily = dailyData(dataPath + dataFile, startDate, endDate, monthDataFile)
# futureDaily.writing()

# # huanbao index
# dataPath = '../data/'
# dataFile = 'huanbao_concept.csv'
# monthDataFile = 'month_huanbao.csv'
# startDate = '1990/12/1'
# endDate = '2019/4/1'
# huanbaoDaily = huanbao(dataPath + dataFile, startDate, endDate, monthDataFile)
# huanbaoDaily.writing()

# # SHIBOR
# dataPath = '../data/'
# dataFile = 'shibor.csv'
# monthDataFile = 'month_shibor.csv'
# startDate = '2006/10/1'
# endDate = '2019/4/1'
# shiborDaily = shibor(dataPath + dataFile, startDate, endDate, monthDataFile)
# shiborDaily.writing()

# # stock (1 + return)
# dataPath = '../data/'
# dataFile = 'stock.csv'
# monthDataFile = 'month_stock.csv'
# startDate = '1990/12/1'
# endDate = '2019/4/1'
# stockDaily = dailyData(dataPath + dataFile, startDate, endDate, monthDataFile)
# stockDaily.writing()

# stock (last price)
dataPath = '../data/'
dataFile = 'stock.csv'
monthDataFile = 'month_stock_last.csv'
startDate = '1990/12/1'
endDate = '2019/4/1'
stockLastDaily = stockLast(dataPath + dataFile, startDate, endDate, monthDataFile)
stockLastDaily.writing()
