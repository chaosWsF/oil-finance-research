# Power of Rare Disaster - Commodity Index

CI: Commodity Index, DI: Disaster Index (component)

## Methodology

- remove country with missing value
- remove country of fix rate
- DI, NVIX^2, mean, PCA, PLS, VIX (trending)
- parallel computing

## Data

- 3-month T-bills
- commodity Index (AQR), GSCITR, BCITR
- price of crude oil and oil futures

## Results

Use 1970:01-2016:03 (CI) and 1988:07-2015:12 (oil)

- log return + normalized DI
- recursive OOS
- in_sample_period = 20 \* 12 (CI) and 10 \* 12 (oil)
- bootstrap size = 2000

Elapsed time (seconds):

- CI PLS: 137.623822
- oil PLS: 101.674313
- CI simple: 855.807078
- oil simple: 589.940423


## TODO

- generate **more NVIX**
- **asset allocation**
    - EX  ref. zhang:oil_strike
