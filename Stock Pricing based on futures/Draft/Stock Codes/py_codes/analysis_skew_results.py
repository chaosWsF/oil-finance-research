import pandas as pd
import numpy as np
from os.path import basename
import glob


class resultTable:

    def __init__(self, filename):
        
        self.fname = filename
        params = basename(filename).split('.')[0]
        self.L = int(params.split('_')[0][1:])
        self.nlag = int(params.split('_')[1][4:])

    def read_result(self):

        result = pd.read_excel(
            self.fname, sheet_name='In-Sample', 
            header=None, usecols=[2,3,4], skiprows=[0], 
            names=['beta', 'pval', 'r2']
        )

        return result

    def score(self, standard=.01):

        result = self.read_result()
        p_values = result.pval.values
        points = np.sum(p_values < standard) / len(p_values) * 100
        
        return 'L={0} nlag={1}  {2:.2f}%'.format(self.L, self.nlag, points), points

pVal = .01

# filePathList = glob.glob('../programs/results/add/ret_reg/L*_nlag*.xlsx')
# reportsName = './reports/reports_retreg_pval{}.txt'.format(int(pVal*100))

# filePathList = glob.glob('../programs/results/add/vol_reg/L*_nlag*.xlsx')
# reportsName = './reports/reports_volreg_pval{}.txt'.format(int(pVal*100))

# filePathList = glob.glob('../programs/results/add/skew_reg/L*_nlag*.xlsx')
# reportsName = './reports/reports_skewreg_pval{}.txt'.format(int(pVal*100))

# filePathList = glob.glob('../programs/results/add/n1ret_reg/L*_nlag*.xlsx')
# reportsName = './reports/reports_n1retreg_pval{}.txt'.format(int(pVal*100))

# filePathList = glob.glob('../programs/results/add/n1vol_reg/L*_nlag*.xlsx')
# reportsName = './reports/reports_n1volreg_pval{}.txt'.format(int(pVal*100))

filePathList = glob.glob('../programs/results/add/n1skew_reg/L*_nlag*.xlsx')
reportsName = './reports/reports_n1skewreg_pval{}.txt'.format(int(pVal*100))

with open(reportsName, 'w') as fw:
    for filePath in filePathList:
        result = resultTable(filePath)
        report, _ = result.score(pVal)
        fw.write(report + '\n')