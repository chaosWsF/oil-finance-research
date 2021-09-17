# Trend Factor of Oil Futures

## Data

- industrial index for each nation
    - Price Index, Level 3, USD
      - *USD is better than local currency*

## Methodology

- monthly return = log(P_{last} / P_{first})

## Results

- best trend lag: G7=1, Developing=6, B&R=1

## TODO
- add **risk free**
  - F-F_Research_Data_Factors.CSV
- use bootstrapping to get **p-value**
- find **commonality** among countries
  - net exporting/importing
    - ref to Table 1 of *JCE13*
  - G7/developing
  - energy structure
    - 一带一路国家能源结构.xlsx
- test robustness
  - try oil commodity
  - try gas
    - gas_oil_idx_month.xlsx
