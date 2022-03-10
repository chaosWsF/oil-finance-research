import pandas as pd
import numpy as np


class googleFinance:

    def __init__(self, filename, start_date, end_date):

        self.fname = filename
        self.sdate = start_date
        self.edate = end_date
    
    @property
    def load(self):

        data = pd.read_csv(self.fname, low_memory=False)
        self.col = list(map(lambda x: x.split('_')[0], list(data.columns[::2])))

        col = ['date'] + self.col
        date_index = pd.date_range(self.sdate, self.edate)

        daily_data = pd.DataFrame(columns=col)
        daily_data.date = date_index[:-1]

        # TODO: Generate Daily Data

        return daily_data


dataPath = '../EX/source/daily/'
dataFile = 'google_finance.csv'
outputFile = 'google_finance_1.csv'
startDate = '1970/1/1'
endDate = '2019/9/1'

exData = googleFinance(dataPath + dataFile, startDate, endDate)
exData.load
