CREATE TABLE hourly_bart (
    ride_date date ,
    ride_hour integer,
    origin_station text,
    destination_station text,
    number_trips integer
);


COPY hourly_bart(ride_date, ride_hour, origin_station, destination_station, number_trips)
FROM '/Users/timothyzheng/Desktop/bart_data/date-hour-soo-dest-2019.csv'
WITH (FORMAT csv, DELIMITER ',');

COPY hourly_bart(ride_date, ride_hour, origin_station, destination_station, number_trips)
FROM '/Users/timothyzheng/Desktop/bart_data/date-hour-soo-dest-2025.csv'
WITH (FORMAT csv, DELIMITER ',');


CREATE OR REPLACE VIEW ride_data AS 
SELECT 
    EXTRACT(YEAR FROM ride_date) AS year, 
    origin_station, 
    destination_station, 
    CASE 
        WHEN ride_hour BETWEEN 7 AND 10 AND EXTRACT(ISODOW FROM ride_date) BETWEEN 1 AND 5 THEN 'Morning Rush'
        WHEN ride_hour BETWEEN 11 AND 14 AND EXTRACT(ISODOW FROM ride_date) BETWEEN 1 AND 5 THEN 'Lunch Rush'
        WHEN ride_hour BETWEEN 16 AND 19 AND EXTRACT(ISODOW FROM ride_date) BETWEEN 1 AND 5 THEN 'Evening Rush'
        WHEN EXTRACT(ISODOW FROM ride_date) IN (6,7) THEN 'Weekend'
        ELSE 'Off Peak'
    END AS time_period,
    SUM(number_trips) AS total_trips
FROM hourly_bart
GROUP BY 1, 2, 3, 4;

DROP TABLE IF EXISTS bart_stations;
CREATE TABLE bart_stations (
    station_code text PRIMARY KEY,
    station_name text,
    county text
);

INSERT INTO bart_stations (station_code, station_name, county) VALUES
('NBRK', 'North Berkeley', 'Alameda'),
('DBRK', 'Downtown Berkeley', 'Alameda'),
('ASHB', 'Ashby', 'Alameda'),
('MCAR', 'MacArthur', 'Alameda'),
('19TH', '19th St. Oakland', 'Alameda'),
('12TH', '12th St. Oakland City Center', 'Alameda'),
('LAKE', 'Lake Merritt', 'Alameda'),
('WOAK', 'West Oakland', 'Alameda'),
('FTVL', 'Fruitvale', 'Alameda'),
('COLS', 'Coliseum', 'Alameda'),
('EMBR', 'Embarcadero', 'San Francisco'),
('MONT', 'Montgomery St.', 'San Francisco'),
('POWL', 'Powell St.', 'San Francisco'),
('CIVC', 'Civic Center/UN Plaza', 'San Francisco'),
('16TH', '16th St. Mission', 'San Francisco'),
('24TH', '24th St. Mission', 'San Francisco'),
('GLEN', 'Glen Park', 'San Francisco'),
('BALB', 'Balboa Park', 'San Francisco');


WITH joined_table AS (
    SELECT 
        bart_stations.station_name,
        ride_data.time_period,
        ride_data.year,
        SUM(ride_data.total_trips) AS total_trips
    FROM ride_data
    INNER JOIN bart_stations 
        ON ride_data.destination_station = bart_stations.station_code
    GROUP BY 1, 2, 3),
combined_years AS (
    SELECT 
        station_name,
        time_period,
        year,
        total_trips AS trips_current,
        LAG(total_trips) OVER (PARTITION BY station_name, time_period ORDER BY year) AS trips_prior
    FROM joined_table
)
SELECT 
    station_name,
    time_period,
    trips_prior AS trips_2019,
    trips_current AS trips_2025,
    ROUND((trips_current::numeric / trips_prior) * 100, 2) AS recovery_rate
FROM combined_years
WHERE year = 2025
ORDER BY recovery_rate DESC;

x
