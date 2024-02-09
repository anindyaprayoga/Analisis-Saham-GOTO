-- Menampilkan seluruh data
SELECT *
FROM AnalisisSahamGOTO.dbo.GOTO$

-- Menampilkan 10 data terbaru pada dataset
SELECT TOP 10 *
FROM AnalisisSahamGOTO..GOTO$

-- Mencari baris dengan nilai yang hilang
-- Query ini mencari baris di mana salah satu kolom memiliki nilai NULL, yang menunjukkan adanya data yang hilang.
SELECT *
FROM AnalisisSahamGOTO..GOTO$
WHERE [timestamp] IS NULL OR [open] IS NULL OR [low] IS NULL OR [high] IS NULL OR [close] IS NULL 
OR [volume] IS NULL

-- Mencari harga pentupan atau data 'close' setiap hari
SELECT [timestamp], [close]
FROM AnalisisSahamGOTO..GOTO$
ORDER BY timestamp

-- Mencari Volatilitas setiap hari
-- Query ini menghitung volatilitas setiap hari sebagai selisih antara harga tertinggi dan terendah.
SELECT timestamp, high - low as daily_range
FROM AnalisisSahamGOTO..GOTO$
ORDER BY timestamp

-- Menampilkan data volume perdagangan setiap hari
-- Query ini mengambil tanggal dan volume perdagangan setiap hari, dan mengurutkannya berdasarkan tanggal.
SELECT timestamp, volume
FROM AnalisisSahamGOTO..GOTO$
ORDER BY timestamp

-- Mencari outlier dari data harga penutupan atau 'close'
-- Query ini mencari outlier dalam data harga penutupan. 
-- Outlier didefinisikan sebagai nilai yang lebih besar dari rata-rata ditambah tiga kali standar deviasi, atau lebih kecil dari rata-rata dikurangi tiga kali standar deviasi.
SELECT [timestamp], [close]
FROM AnalisisSahamGOTO..GOTO$
WHERE [close] > (SELECT AVG([close]) + 3 * STDEV([close]) FROM AnalisisSahamGOTO..GOTO$)
OR [close] < (SELECT AVG([close]) - 3 * STDEV([close]) FROM AnalisisSahamGOTO..GOTO$)

-- Mencari korelasi antara data 'volume' dan data perubahan harga atau volatilitas per hari
-- Query ini mengambil tanggal, volume perdagangan, dan volatilitas setiap hari, dan mengurutkannya berdasarkan volume perdagangan.
SELECT timestamp, volume, high -low as daily_range
FROM AnalisisSahamGOTO..GOTO$
ORDER BY volume DESC

-- Analisis Moving Average
-- Query ini menghitung moving average 7 hari dan 30 hari untuk harga penutupan. Moving average dihitung sebagai rata-rata harga penutupan dalam waktu tertentu.
SELECT timestamp, [close],
AVG([close]) OVER (ORDER BY timestamp ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) as moving_average_7d,
AVG([close]) OVER (ORDER BY timestamp ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) as moving_average_30d
FROM AnalisisSahamGOTO..GOTO$
ORDER BY timestamp

-- Mencari persentase perubahan harga penutupan setiap hari
-- Query ini menghitung return harian sebagai perubahan persentase harga penutupan dari hari ke hari.
SELECT timestamp, [close],
([close] - LAG([close], 1) OVER (ORDER BY timestamp)) / LAG([close], 1) OVER (ORDER BY timestamp) as daily_return
FROM AnalisisSahamGOTO..GOTO$
ORDER BY timestamp

-- Analisis volatilitas historis
-- Query ini menghitung volatilitas historis sebagai standar deviasi dari return harian.
WITH daily_return_subquery AS (
	SELECT timestamp,[close],
		([close] - LAG([close], 1) OVER (ORDER BY timestamp)) / LAG([close], 1) OVER (ORDER BY timestamp) AS daily_return
	FROM AnalisisSahamGOTO..GOTO$
),
volatility_subquery AS (
	SELECT *, AVG(daily_return) OVER () AS avg_daily_return
	FROM daily_return_subquery
)
SELECT SQRT(AVG(POWER(daily_return - avg_daily_return, 2))) AS historical_volatility
FROM volatility_subquery

-- Analisis moving volatility
-- Query ini menghitung moving volatility 7 hari dan 30 hari sebagai standar deviasi dari return harian dalam waktu tertentu.
SELECT timestamp, [close], daily_return,
SQRT(AVG(POWER(daily_return, 2)) OVER (ORDER BY timestamp ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)) as moving_volatility_7d,
SQRT(AVG(POWER(daily_return, 2)) OVER (ORDER BY timestamp ROWS BETWEEN 29 PRECEDING AND CURRENT ROW)) as moving_volatility_30d
FROM (
    SELECT timestamp, [close],
    ([close] - LAG([close], 1) OVER (ORDER BY timestamp)) / LAG([close], 1) OVER (ORDER BY timestamp) as daily_return
    FROM AnalisisSahamGOTO..GOTO$
) subquery
ORDER BY timestamp;