--1 Какие самолеты имеют более 50 посадочных мест?

select aircraft_code, count(*) from seats
group by aircraft_code 
having count(*) > 50

--2 В каких аэропортах есть рейсы, в рамках которых можно добраться бизнес - классом дешевле, чем эконом - классом?
-- CTE

with table1 as (
	select distinct flight_id, amount from ticket_flights tf 
	where fare_conditions = 'Business'),
table2 as (
	select distinct flight_id, amount from ticket_flights tf 
	where fare_conditions = 'Economy')
select * from table1 a 
join table2 b using (flight_id)
where a.amount < b.amount
--таких нет

--3 Есть ли самолеты, не имеющие бизнес - класса?
-- array_agg
select aircraft_code, list_cond from (
	select aircraft_code, array_agg(fare_conditions) list_cond from (
		select distinct a.aircraft_code, b.fare_conditions from flights a
		join (select distinct flight_id, fare_conditions from ticket_flights) b 
		using (flight_id)) c
	group by aircraft_code) d
where not 'Business' = any(list_cond)

--4 Найдите количество занятых мест для каждого рейса, процентное отношение количества занятых мест к общему количеству мест в самолете, 
--добавьте накопительный итог вывезенных пассажиров по каждому аэропорту на каждый день.
-- Оконная функция
-- Подзапрос

select flight_id, "количество занятых мест", "процентное отношение", departure_airport, actual_departure::date,
sum("количество занятых мест") over (partition by departure_airport order by actual_departure) from (
	select a.flight_id, a.count_pass "количество занятых мест", 
	round(a.count_pass/c.count_all::numeric*100, 2) "процентное отношение", b.departure_airport, b.actual_departure 
	from (
		select flight_id, count(*) count_pass from boarding_passes bp  
		group by flight_id) a
	join flights b using (flight_id)
	join (
		select aircraft_code, count(*) count_all from seats c
		group by aircraft_code) c using (aircraft_code)
	order by flight_id) f
	

--5 Найдите процентное соотношение перелетов по маршрутам от общего количества перелетов. 
--Выведите в результат названия аэропортов и процентное отношение.
-- Оконная функция
-- Оператор ROUND

select distinct departure_airport, arrival_airport,
round(count (*) over (partition by departure_airport, arrival_airport)/count (*) over ()::numeric*100, 2) "процентное соотношение"
from flights
order by departure_airport


--6 Выведите количество пассажиров по каждому коду сотового оператора, если учесть, что код оператора - это три символа после +7
select "код", count(*) from (
	select passenger_name, substring (contact_data ->> 'phone' from 3 for 3) "код" from tickets) a
group by "код"

--7 Между какими городами не существует перелетов?
-- Декартово произведение
-- Оператор EXCEPT

select d.airport_name, e.airport_name  from (select a.airport_code code1, b.airport_code code2
from airports a, airports b
except 
select departure_airport, arrival_airport
from flights) c
join airports d on d.airport_code = c.code1
join airports e on e.airport_code = c.code2
where d.airport_name != e.airport_name

--8 Классифицируйте финансовые обороты (сумма стоимости билетов) по маршрутам:
--До 50 млн - low
--От 50 млн включительно до 150 млн - middle
--От 150 млн включительно - high
--Выведите в результат количество маршрутов в каждом классе.
-- Оператор CASE

with new_table as (
	select * from
	(select flight_id, sum(amount) sum_am from ticket_flights tf 
	group by flight_id) a
join flights using (flight_id)),
new_table2 as (select departure_airport, arrival_airport, sum(sum_am) sum_am2 from new_table
group by (departure_airport, arrival_airport)),
new_table3 as (select *, case 
	when sum_am2 < 50000000 then 'low'
	when sum_am2 >= 50000000 and sum_am2 < 150000000 then 'middle'
	else 'high'
end classif
from new_table2)
select classif, count(*) from new_table3
group by classif


--9 Выведите пары городов между которыми расстояние более 5000 км
-- Оператор RADIANS или использование sind/cosd

select city_a, city_b, x from (
	select city_a, city_b, acos(num)*6371 x from (
		select a.city city_a, b.city city_b, sind(a.latitude)*sind(b.latitude) + cosd(a.latitude)*cosd(b.latitude)*cosd(a.longitude - b.longitude)::numeric num
		from airports a, airports b
		where a.city != b.city) t
	where acos(num)*6371 > 5000 ) t1
where city_a < city_b
order by x






