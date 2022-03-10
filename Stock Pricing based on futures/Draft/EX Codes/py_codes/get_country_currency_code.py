beltRoadCountryFile = 'E:\\Research\\Scholar\\Oil Research\\Reference\\belt and road names.txt'
currencyCodeFile = 'E:\\Research\\Scholar\\Stock Pricing based on futures\\EX\\WorldCurrList.csv'
beltRoadCodeFile = 'E:\\Research\\Scholar\\Stock Pricing based on futures\\EX\\source\\daily\\belt_road_code.csv'

with open(beltRoadCountryFile) as fr:
    beltRoadCountries = [line[:-1] for line in fr]

countryName = []
currencyCode = []
with open(currencyCodeFile) as fr:
    for i, line in enumerate(fr):
        if (line[:-1] != ',,') and (i > 0):
            line = line[:-1].split(',')
            countryName.append(line[0].split('?')[0])
            currencyCode.append(line[2])

beltRoadCode = []
for beltRoadCountry in beltRoadCountries:
    if beltRoadCountry in countryName:
        beltRoadCode.append(currencyCode[countryName.index(beltRoadCountry)] + ',,')
    elif beltRoadCountry == 'Cape Verde':
        beltRoadCode.append('CVE,,')
    elif beltRoadCountry == 'Viet Nam':
        beltRoadCode.append('VND,,')
    elif beltRoadCountry == 'Czech Republic':
        beltRoadCode.append('CZK,,')
    elif beltRoadCountry == 'Republic of Korea':
        beltRoadCode.append('KRW,,')
    elif beltRoadCountry == 'Macedonia':
        beltRoadCode.append('MKD,,')
    elif beltRoadCountry == 'Congo':
        beltRoadCode.append('XAF,,')
    else:
        print(beltRoadCountry)

beltRoadCode = list(set(beltRoadCode))
beltRoadCode.remove('USD,,')
beltRoadCode.remove('none,,')

beltRoadCode_add = []

with open(beltRoadCodeFile, 'w') as fw:
    fw.writelines(beltRoadCode)
