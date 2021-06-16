-- 4.1 База данных содержит список аэропортов практически всех крупных городов России. В большинстве городов есть только один аэропорт. Исключение составляет:
SELECT city,
       count(airport_code)
FROM dst_project.airports
GROUP BY city
ORDER BY 2 DESC

-- 4.2 Таблица рейсов содержит всю информацию о прошлых, текущих и запланированных рейсах. Сколько всего статусов для рейсов определено в таблице?
SELECT count(distinct(status))
FROM dst_project.flights

-- Какое количество самолетов находятся в воздухе на момент среза в базе (статус рейса «самолёт уже вылетел и находится в воздухе»).
SELECT count(flight_id)
FROM dst_project.flights
WHERE status = 'Departed'

-- Места определяют схему салона каждой модели. Сколько мест имеет самолет модели  (Boeing 777-300)?
SELECT count(seat_no)
FROM dst_project.seats s
INNER JOIN dst_project.aircrafts a ON a.aircraft_code = s.aircraft_code
WHERE a.model = 'Boeing 777-300'

-- Сколько состоявшихся (фактических) рейсов было совершено между 1 апреля 2017 года и 1 сентября 2017 года?
SELECT count(flight_id)
FROM dst_project.flights
WHERE actual_arrival BETWEEN '2017-04-01' AND '2017-09-01'
  AND status = 'Arrived'

-- 4.3 Сколько всего рейсов было отменено по данным базы?
SELECT count(flight_id)
FROM dst_project.flights
WHERE status = 'Cancelled'

-- Сколько самолетов моделей типа Boeing, Sukhoi Superjet, Airbus находится в базе авиаперевозок?
SELECT 'Boeing',
       count(*)
FROM dst_project.aircrafts
WHERE model like 'Boeing%'
UNION
SELECT 'Sukhoi',
       count(*)
FROM dst_project.aircrafts
WHERE model like 'Sukhoi%'
UNION
SELECT 'Airbus',
       count(*)
FROM dst_project.aircrafts
WHERE model like 'Airbus%'

-- В какой части (частях) света находится больше аэропортов?
SELECT CASE
           WHEN a.timezone like 'Asia%' THEN 'Asia'
           WHEN a.timezone like 'Europe%' THEN 'Europe'
           ELSE 'others'
       END AS timezone,
       count(*)
FROM dst_project.airports a
GROUP BY 1

-- У какого рейса была самая большая задержка прибытия за все время сбора данных? Введите id рейса (flight_id).
SELECT f.flight_id,
       max(f.actual_arrival - f.scheduled_arrival)
FROM dst_project.flights f
WHERE f.status = 'Arrived'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1

--4.4 Когда был запланирован самый первый вылет, сохраненный в базе данных?
SELECT f.scheduled_departure
FROM dst_project.flights f
ORDER BY 1
LIMIT 1

-- Сколько минут составляет запланированное время полета в самом длительном рейсе?
SELECT date_part('hour', max(f.scheduled_arrival - f.scheduled_departure)) * 60 + date_part('minute', max(f.scheduled_arrival - f.scheduled_departure))
FROM dst_project.flights f

-- Между какими аэропортами пролегает самый длительный по времени запланированный рейс?
SELECT f.departure_airport,
       f.arrival_airport,
       f.scheduled_arrival - f.scheduled_departure
FROM dst_project.flights f
ORDER BY 3 DESC
LIMIT 1

-- Сколько составляет средняя дальность полета среди всех самолетов в минутах? Секунды округляются в меньшую сторону (отбрасываются до минут).
WITH ar_dep_t AS
  (SELECT avg(f.actual_arrival - f.actual_departure) AS ar_dep
   FROM dst_project.flights f
   WHERE f.actual_arrival IS NOT NULL
     AND f.actual_departure IS NOT NULL),
     avg_res AS
  (SELECT date_trunc('minute', avg(a.ar_dep)) AS mnt
   FROM ar_dep_t AS a)
SELECT avg_res.mnt AS mean,
       (date_part('hour', avg_res.mnt) * 60 + date_part('minute', avg_res.mnt)) AS minutes
FROM avg_res

-- 4.5 Мест какого класса у SU9 больше всего?
SELECT aircraft_code,
       fare_conditions,
       count(fare_conditions)
FROM dst_project.seats
WHERE aircraft_code = 'SU9'
GROUP BY 1,
         2

-- Какую самую минимальную стоимость составило бронирование за всю историю?
SELECT min(total_amount)
FROM dst_project.bookings

-- Какой номер места был у пассажира с id = 4313 788533?
SELECT t.passenger_id,
       p.seat_no
FROM dst_project.tickets t
INNER JOIN dst_project.boarding_passes p ON p.ticket_no = t.ticket_no
WHERE t.passenger_id = '4313 788533'

-- 5.1 Анапа — курортный город на юге России. Сколько рейсов прибыло в Анапу за 2017 год?
SELECT count(*)
FROM dst_project.flights
WHERE arrival_airport = 'AAQ'
  AND actual_arrival BETWEEN '2017-01-01' AND '2017-12-31'

-- Сколько рейсов из Анапы вылетело зимой 2017 года?
SELECT count(*)
FROM dst_project.flights
WHERE arrival_airport = 'AAQ'
  AND date_trunc('month', actual_departure) in ('2017-01-01',
                                                '2017-02-01',
                                                '2017-12-01')
  AND status = 'Arrived'

-- Посчитайте количество отмененных рейсов из Анапы за все время.
SELECT count(*)
FROM dst_project.flights
WHERE arrival_airport = 'AAQ'
  AND status = 'Cancelled'

-- Сколько рейсов из Анапы не летают в Москву?
SELECT count(*)
FROM dst_project.flights
WHERE departure_airport = 'AAQ'
  AND arrival_airport not in ('DME',
                              'SVO',
                              'VKO')

--  Какая модель самолета летящего на рейсах из Анапы имеет больше всего мест?
SELECT f.aircraft_code,
       a.model,
       count(DISTINCT s.seat_no)
FROM dst_project.seats s
INNER JOIN dst_project.flights f ON f.aircraft_code = s.aircraft_code
INNER JOIN dst_project.aircrafts a ON a.aircraft_code = f.aircraft_code
WHERE f.departure_airport = 'AAQ'
GROUP BY 1,
         2

-- Итоговый датасет
WITH fl AS
  (SELECT f.flight_id,
          f.departure_airport,
          f.arrival_airport,
          (date_part('hour', f.actual_arrival - f.actual_departure) * 60 + date_part('minute', f.actual_arrival - f.actual_departure)) AS duration,
          f.aircraft_code AS craft_code
   FROM dst_project.flights AS f
   WHERE f.departure_airport = 'AAQ'
     AND (date_trunc('month', f.scheduled_departure) in ('2017-01-01',
                                                         '2017-02-01',
                                                         '2016-12-01'))
     AND f.status in ('Arrived')),
     tf AS
  (SELECT t.flight_id,
          count(t.ticket_no) AS ticket_count,
          sum(t.amount) AS revenue
   FROM dst_project.ticket_flights AS t
   GROUP BY 1)
SELECT fl.flight_id,
       fl.departure_airport,
       fl.arrival_airport,
       ac.model,
       fl.duration,
       tf.ticket_count,
       tf.revenue AS revenue
FROM fl
JOIN dst_project.aircrafts AS ac ON fl.craft_code = ac.aircraft_code
LEFT JOIN tf ON tf.flight_id = fl.flight_id
ORDER BY 1,
         3