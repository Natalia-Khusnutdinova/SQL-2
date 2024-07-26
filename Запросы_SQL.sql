--=============== МОДУЛЬ 6. POSTGRESQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Напишите SQL-запрос, который выводит всю информацию о фильмах 
--со специальным атрибутом "Behind the Scenes".
select film_id, title, special_features  
from film
where special_features && array ['Behind the Scenes']



--ЗАДАНИЕ №2
--Напишите еще 2 варианта поиска фильмов с атрибутом "Behind the Scenes",
--используя другие функции или операторы языка SQL для поиска значения в массиве.
select film_id, title, special_features  
from film
where special_features @> array ['Behind the Scenes']


select film_id, title, special_features  
from film
where 'Behind the Scenes' = any (special_features)
 

select film_id, title, special_features  
from film
where array_position(special_features, 'Behind the Scenes') is not null



--ЗАДАНИЕ №3
--Для каждого покупателя посчитайте сколько он брал в аренду фильмов 
--со специальным атрибутом "Behind the Scenes.

--Обязательное условие для выполнения задания: используйте запрос из задания 1, 
--помещенный в CTE. CTE необходимо использовать для решения задания.
with cte1 as (select f.film_id, f.title, f.special_features  
             from film f
             where f.special_features && array ['Behind the Scenes'])
select r.customer_id, count (r.rental_id) as "film_count"
from rental r 
join inventory i on r.inventory_id = i.inventory_id 
join cte1 c1 on c1.film_id = i.film_id
group by r.customer_id
order by r.customer_id





--ЗАДАНИЕ №4
--Для каждого покупателя посчитайте сколько он брал в аренду фильмов
-- со специальным атрибутом "Behind the Scenes".

--Обязательное условие для выполнения задания: используйте запрос из задания 1,
--помещенный в подзапрос, который необходимо использовать для решения задания.
select r.customer_id, count (r.rental_id) as "film_count" 
from rental r 
join inventory i on r.inventory_id = i.inventory_id
join (select f.film_id, f.title, f.special_features  
      from film f
      where f.special_features && array ['Behind the Scenes']) as p 
on p.film_id = i.film_id 
group by r.customer_id
order by r.customer_id




--ЗАДАНИЕ №5
--Создайте материализованное представление с запросом из предыдущего задания
--и напишите запрос для обновления материализованного представления
create materialized view example_1 as
       select r.customer_id, count (r.rental_id) as "film_count" 
       from rental r 
       join inventory i on r.inventory_id = i.inventory_id
       join (select f.film_id, f.title, f.special_features  
             from film f
             where f.special_features && array ['Behind the Scenes']) as p 
       on p.film_id = i.film_id 
       group by r.customer_id
       order by r.customer_id
with data       
       
select * from example_1

refresh materialized view example_1



--ЗАДАНИЕ №6
--С помощью explain analyze проведите анализ стоимости выполнения запросов из предыдущих заданий и ответьте на вопросы:
--1. с каким оператором или функцией языка SQL, используемыми при выполнении домашнего задания: 
--поиск значения в массиве затрачивает меньше ресурсов системы;
--2. какой вариант вычислений затрачивает меньше ресурсов системы: 
--с использованием CTE или с использованием подзапроса.
explain analyze
select film_id, title, special_features  
from film
where special_features && array ['Behind the Scenes']


explain analyze
select film_id, title, special_features  
from film
where special_features @> array ['Behind the Scenes']


explain analyze
select film_id, title, special_features  
from film
where 'Behind the Scenes' = any (special_features)


explain analyze
select film_id, title, special_features  
from film
where array_position(special_features, 'Behind the Scenes') is not null





explain analyze
with cte1 as (select f.film_id, f.title, f.special_features  
             from film f
             where f.special_features && array ['Behind the Scenes'])
select r.customer_id, count (r.rental_id) as "film_count"
from rental r 
join inventory i on r.inventory_id = i.inventory_id 
join cte1 c1 on c1.film_id = i.film_id
group by r.customer_id
order by r.customer_id


explain analyze
select r.customer_id, count (r.rental_id) as "film_count" 
from rental r 
join inventory i on r.inventory_id = i.inventory_id
join (select f.film_id, f.title, f.special_features  
      from film f
      where f.special_features && array ['Behind the Scenes']) as p 
on p.film_id = i.film_id 
group by r.customer_id
order by r.customer_id


--Ответы на вопросы:
--1. Поиск значения в массиве при использовании четырёх схожих функций/операторов:&& , @> , any и array_position
--   затрачивает примерно одинаковое количество ресурсов системы.
--   Оператор ANY на несколько процентов больше затрачивает ресурсов системы.

--2. Вариант одного и того же запроса с использованием cte или с использованием подзапроса
--   затрачивают одинаковое количество ресурсов системы.
--   время выполнения обоих запросов всегда показывает разное, от 16/19 до 28/30 (мс). 
--   сделав несколькр раз по обоим запросам explain analyze, ришла к выводу, что запрос с подзапросом всё-таки чаще срабатывает быстрее. 





--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Выполняйте это задание в форме ответа на сайте Нетологии


explain analyze
select distinct cu.first_name  || ' ' || cu.last_name as name, 
	count(ren.iid) over (partition by cu.customer_id)
from customer cu
full outer join 
	(select *, r.inventory_id as iid, inv.sf_string as sfs, r.customer_id as cid
	from rental r 
	full outer join 
		(select *, unnest(f.special_features) as sf_string
		from inventory i
		full outer join film f on f.film_id = i.film_id) as inv 
		on r.inventory_id = inv.inventory_id) as ren 
	on ren.cid = cu.customer_id 
where ren.sfs like '%Behind the Scenes%'
order by count desc

--"Узкие" места данного запроса:
-- функция unnest - узел ProjectSet на выходе получаем 9768 строк вместо 4623, узел съедает 346, 3 усл.ед.
-- также долгий по времени оператор like

explain analyze
select r.customer_id, count (r.rental_id) as "film_count" 
from rental r 
join inventory i on r.inventory_id = i.inventory_id
join (select f.film_id, f.title, f.special_features  
      from film f
      where f.special_features && array ['Behind the Scenes']) as p 
on p.film_id = i.film_id 
group by r.customer_id
order by r.customer_id

-- Планируемое время: 1,295 (мс)
-- Фактичекое время: 21,614 (мс)
-- Далее стоимость и время указаны нарастающим итогом.
-- 1. Сканирование таблицы film с использованием фильтра && с поиском значения 'Behind the Scenes' в массиве (стоим. 67.50, время 1.470 мс)
-- 2. Хэш (стоим. 67.50, время 1.713 мс)
-- 3. Сканирование таблицы inventory (стоим. 70.81, время 1.437 мс)
-- 4. Хэш (стоим. 70.81, время 3.182 мс)
-- 5. Сканирование таблицы rental (стоим. 310.44, время 1.764 мс)
-- 6. Хэш-соединение по условию r.inventory_id = i.inventory_id (стоим. 480.67, время 12.362 мс)
-- 7. Хэш-соединение по условию f.film_id = i.film_id (стоим. 597.19, время 18.221мс)
-- 8. Хэш-агрегирование (группировка) по ключу r.customer_id (стоим. 646.34, время 21.434)
-- 9. Сортировка по ключу r.customer_id Sort  (стоим. 675.47, время 21.614)




--ЗАДАНИЕ №2
--Используя оконную функцию выведите для каждого сотрудника
--сведения о самой первой продаже этого сотрудника.
select p1.staff_id, p1.film_id, title, amount, payment_date, last_name as "customer_last_name", first_name as "customer_first_name"  
from (
	select p.staff_id, f.film_id, f.title, p.amount, p.payment_date, c.last_name, c.first_name, row_number() over (partition by p.staff_id order by p.payment_date)
	from payment p
	join rental r on r.rental_id = p.rental_id 
    join customer c on r.customer_id = c.customer_id
    join inventory i on i.inventory_id = r.inventory_id 
    join film f on f.film_id = i.film_id) as p1
where row_number = 1




--ЗАДАНИЕ №3
--Для каждого магазина определите и выведите одним SQL-запросом следующие аналитические показатели:
-- 1. день, в который арендовали больше всего фильмов (день в формате год-месяц-день)
-- 2. количество фильмов взятых в аренду в этот день
-- 3. день, в который продали фильмов на наименьшую сумму (день в формате год-месяц-день)
-- 4. сумму продажи в этот день
select r.store_id as "ID магазина", r.rental_date as "День, в который арендовали больше всего фильмов", r.max as "Количество фильмов, взятых в аренду в этот день", p.payment_date as "День, в который продали фильмов на наименьшую сумму", p.min as "Сумма продажи в этот день" 
from (
     select i.store_id, r.rental_date::date, count (r.rental_id), max (count (r.rental_id)) over (partition by i.store_id)   
     from rental r 
     join inventory i on i.inventory_id = r.inventory_id 
     group by i.store_id, r.rental_date::date) as r
join (
     select s.store_id, p.payment_date::date, sum(amount), min (sum(amount)) over (partition by s.store_id) 
     from payment p 
     join staff s on p.staff_id = s.staff_id  
     group by s.store_id, p.payment_date::date) as p
on r.store_id = p.store_id
where sum = min and count = max











