SELECT 
    COUNT(Airline) AS n_flights_per_month
FROM {{ ref('flights') }}
GROUP BY Month