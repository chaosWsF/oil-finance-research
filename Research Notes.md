## Moments of Oil Futures Return

    Predict cross-section stock excess return

1. best trend lag and in_sample_period
    - idiosyncratic risk 6, 6
    - idiosyncratic volatility 3, 8
    - idiosyncratic skewness 3, 8. *results of demeaning are bad even after dividing std*


## Rare Disaster

1. MATLAB code
    - parallel computing
    - remove country with missing value
    - remove country of fix rate
    - DI, NVIX^2, mean, PCA, PLS, VIX (trending)
    - **asset allocation**
        - EX  ref. zhang:oil_strike

2. Data
    - **NVIX are not enough**
    - 1-month-SHIBOR / 3-month-Tbills
    - EX (fxtop)
    - oil net export (EIA 2016, ref. JCE13 Table 1)
    - CPI (IMF), *missing New Zealand*
    - commodity Index (AQR), GSCITR, BCITR
    - crude oil and oil futures price

3. Exchange rate

    Use 2000:01-2016:03 to predict 2000:02 - 2016:04

    Not used country list:

        fix rate: AED BHD IQD JOD LBP MMK OMR PAB QAR SAR
        missing data: BGN RON RSD
        bad results: LAK KHR EGP TRY PHP ZAR IDR

    - normal return + normalized DI
    - recursive OOS
    - in_sample_period = 6 * 12
    - bootstrap size = 2000
    - net ex = 0 is exporter

    Elapsed time (PLS) is 292.812128 seconds.

    Elapsed time (Simple) is 1616.117463 seconds.

    - shibor monthly = average(daily), 2006:10-2016:04
    - fillmissing(SHIBOR, 'constant', mean(SHIBOR))
    - RRA = 2
    - cov window = 5 * 12
    - c = linspace(100, 10, T + 1) * 1e-4, ref. neely2009
    - vols = [8% 10% 12%]

4. commodity index

    Use 1970:01-2016:03 (CI) and 1988:07-2015:12 (oil)

    - log return + normalized DI
    - recursive OOS
    - in_sample_period = 20 \* 12 (CI) and 10 \* 12 (oil)
    - bootstrap size = 2000

    Elapsed time (seconds):

    - CI PLS - 137.623822
    - oil PLS - 101.674313
    - CI simple - 855.807078
    - oil simple - 589.940423
