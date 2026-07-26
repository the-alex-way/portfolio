/*==============================================================================
  Расчет ключевых бизнес-метрик сервиса доставки еды

  Цель проекта:
  Разработать SQL-запросы для расчёта ключевых бизнес-метрик сервиса
  доставки еды, которые используются в интерактивном дашборде Yandex DataLens.

  Рассчитанные показатели:
  1. DAU (Daily Active Users)
  2. Conversion Rate
  3. Средний чек
  4. LTV ресторанов
  5. LTV популярных блюд
  6. Retention Rate
  7. Retention Rate по когортам

  Результатом проекта является дашборд, позволяющий анализировать
  динамику пользовательской активности, удержания и финансовых показателей.
===============================================================================*/


/*=====================================================================
  1. Расчёт DAU
     Количество уникальных пользователей, активных в приложении за день
=====================================================================*/

/* Цель: рассчитать ежедневное количество активных зарегистрированных 
 * клиентов за май и июнь 2021 года в городе Саранске. 
 * Критерием активности клиента считается размещение заказа. 
 * Это позволит оценить эффективность вовлечения клиентов в ключевую 
 * бизнес-цель - совершение покупки.*/

SELECT log_date,
       COUNT(DISTINCT user_id) AS DAU
FROM rest_analytics.analytics_events AS events
JOIN rest_analytics.cities cities ON events.city_id = cities.city_id
WHERE log_date BETWEEN '2021-05-01' AND '2021-06-30'
  AND city_name = 'Саранск'
  AND event = 'order'
GROUP BY log_date
ORDER BY log_date; 

/*
Результаты расчёта DAU (за май-июнь 2021):

| log_date   | DAU | | log_date   | DAU |
|------------|-----| |------------|-----|
| 2021-05-01 | 56  | | 2021-06-01 | 58  |
| 2021-05-02 | 36  | | 2021-06-02 | 56  |
| 2021-05-03 | 72  | | 2021-06-03 | 76  |
| 2021-05-04 | 85  | | 2021-06-04 | 46  |
| 2021-05-05 | 60  | | 2021-06-05 | 44  |
| 2021-05-06 | 52  | | 2021-06-06 | 48  |
| 2021-05-07 | 52  | | 2021-06-07 | 66  |
| 2021-05-08 | 52  | | 2021-06-08 | 69  |
| 2021-05-09 | 33  | | 2021-06-09 | 81  |
| 2021-05-10 | 35  | | 2021-06-10 | 79  |
| 2021-05-11 | 45  | | 2021-06-11 | 84  |
| 2021-05-12 | 68  | | 2021-06-12 | 41  |
| 2021-05-13 | 39  | | 2021-06-13 | 44  |
| 2021-05-14 | 41  | | 2021-06-14 | 49  |
| 2021-05-15 | 21  | | 2021-06-15 | 64  |
| 2021-05-16 | 17  | | 2021-06-16 | 47  |
| 2021-05-17 | 37  | | 2021-06-17 | 56  |
| 2021-05-18 | 31  | | 2021-06-18 | 47  |
| 2021-05-19 | 41  | | 2021-06-19 | 41  |
| 2021-05-20 | 33  | | 2021-06-20 | 47  |
| 2021-05-21 | 37  | | 2021-06-21 | 52  |
| 2021-05-22 | 28  | | 2021-06-22 | 50  |
| 2021-05-23 | 43  | | 2021-06-23 | 42  |
| 2021-05-24 | 49  | | 2021-06-24 | 44  |
| 2021-05-25 | 38  | | 2021-06-25 | 39  |
| 2021-05-26 | 45  | | 2021-06-26 | 26  |
| 2021-05-27 | 55  | | 2021-06-27 | 26  |
| 2021-05-28 | 35  | | 2021-06-28 | 26  |
| 2021-05-29 | 41  | | 2021-06-29 | 33  |
| 2021-05-30 | 51  | | 2021-06-30 | 33  |
| 2021-05-31 | 70  | |            |     |
*/

/*========================================================================
  2. Расчёт Conversion Rate
     Доля пользователей, совершивших заказ, от всех активных пользователей
========================================================================*/

/* Цель: рассчитать конверсию зарегистрированных пользователей 
 * в активных клиентов за каждый день мая и июня 2021 года 
 * для клиентов из города Саранска.*/

SELECT log_date,
       ROUND((COUNT(DISTINCT user_id) FILTER (WHERE event = 'order'))
       /COUNT(DISTINCT user_id)::numeric, 2) AS CR
FROM rest_analytics.analytics_events AS events
JOIN rest_analytics.cities cities ON events.city_id = cities.city_id
WHERE log_date BETWEEN '2021-05-01' AND '2021-06-30'
  AND city_name = 'Саранск'
GROUP BY log_date
ORDER BY log_date; 

/*
Результаты расчёта CR (Conversion Rate) за май-июнь 2021:

| log_date   | CR   | | log_date   | CR   |
|------------|------| |------------|------|
| 2021-05-01 | 0.43 | | 2021-06-01 | 0.30 |
| 2021-05-02 | 0.28 | | 2021-06-02 | 0.30 |
| 2021-05-03 | 0.41 | | 2021-06-03 | 0.38 |
| 2021-05-04 | 0.41 | | 2021-06-04 | 0.21 |
| 2021-05-05 | 0.32 | | 2021-06-05 | 0.26 |
| 2021-05-06 | 0.25 | | 2021-06-06 | 0.34 |
| 2021-05-07 | 0.28 | | 2021-06-07 | 0.27 |
| 2021-05-08 | 0.33 | | 2021-06-08 | 0.29 |
| 2021-05-09 | 0.28 | | 2021-06-09 | 0.31 |
| 2021-05-10 | 0.30 | | 2021-06-10 | 0.27 |
| 2021-05-11 | 0.30 | | 2021-06-11 | 0.31 |
| 2021-05-12 | 0.37 | | 2021-06-12 | 0.30 |
| 2021-05-13 | 0.23 | | 2021-06-13 | 0.29 |
| 2021-05-14 | 0.27 | | 2021-06-14 | 0.31 |
| 2021-05-15 | 0.34 | | 2021-06-15 | 0.32 |
| 2021-05-16 | 0.22 | | 2021-06-16 | 0.31 |
| 2021-05-17 | 0.27 | | 2021-06-17 | 0.32 |
| 2021-05-18 | 0.25 | | 2021-06-18 | 0.18 |
| 2021-05-19 | 0.30 | | 2021-06-19 | 0.26 |
| 2021-05-20 | 0.29 | | 2021-06-20 | 0.26 |
| 2021-05-21 | 0.25 | | 2021-06-21 | 0.27 |
| 2021-05-22 | 0.24 | | 2021-06-22 | 0.33 |
| 2021-05-23 | 0.35 | | 2021-06-23 | 0.33 |
| 2021-05-24 | 0.23 | | 2021-06-24 | 0.30 |
| 2021-05-25 | 0.23 | | 2021-06-25 | 0.27 |
| 2021-05-26 | 0.26 | | 2021-06-26 | 0.31 |
| 2021-05-27 | 0.34 | | 2021-06-27 | 0.30 |
| 2021-05-28 | 0.19 | | 2021-06-28 | 0.22 |
| 2021-05-29 | 0.31 | | 2021-06-29 | 0.31 |
| 2021-05-30 | 0.32 | | 2021-06-30 | 0.37 |
| 2021-05-31 | 0.32 | |            |      |
*/

/*==============================================================
  3. Расчёт среднего чека
     Средний доход сервиса с одного заказа (комиссия)
==============================================================*/

/* Цель: рассчитать средний чек активных клиентов в Саранске в мае и в июне.
 * Вычисление будет произведено как среднее значение комиссии со всех 
 * заказов за месяц.*/

-- Рассчитываем величину комиссии с каждого заказа, отбираем заказы по дате и городу
WITH orders AS
  (SELECT *,
          revenue * commission AS commission_revenue
   FROM rest_analytics.analytics_events AS events
   JOIN rest_analytics.cities cities ON events.city_id = cities.city_id
   WHERE revenue IS NOT NULL
     AND log_date BETWEEN '2021-05-01' AND '2021-06-30'
     AND city_name = 'Саранск')
SELECT CAST(DATE_TRUNC('month', log_date) AS date) AS "Месяц",
       COUNT(DISTINCT order_id) AS "Количество заказов",
       ROUND(SUM(commission_revenue)::numeric, 2) AS "Сумма комиссии",
       ROUND((SUM(commission_revenue) / COUNT(DISTINCT order_id))::numeric, 2) "Средний чек"
FROM orders
GROUP BY "Месяц"
ORDER BY "Месяц";

/*
Результаты расчёта среднего чека за май-июнь 2021:

| Месяц      | Количество заказов | Сумма комиссии | Средний чек |
|------------|-------------------|----------------|-------------|
| 2021-05-01 | 2111              | 286852.27      | 135.88      |
| 2021-06-01 | 2225              | 328539.11      | 147.66      |
*/

/*================================================================
  4. Расчёт LTV ресторанов
     Суммарный доход (комиссия), который принёс ресторан за период
================================================================*/

/* Цель: определяем три ресторана из Саранска с наибольшим LTV с начала мая 
 * до конца июня. 
 * В контексте сервиса доставки клиентами являются не только 
 * покупатели, но и рестораны-партнёры. Для них LTV показывает, 
 * сколько суммарного дохода (комиссии) сервис получил от заказов 
 * этого ресторана.*/

-- Рассчитываем величину комиссии с каждого заказа, отбираем заказы по дате и городу
WITH orders AS
  (SELECT events.rest_id,
          events.city_id,
          revenue * commission AS commission_revenue
   FROM rest_analytics.analytics_events AS events
   JOIN rest_analytics.cities cities ON events.city_id = cities.city_id
   WHERE revenue IS NOT NULL
     AND log_date BETWEEN '2021-05-01' AND '2021-06-30'
     AND city_name = 'Саранск')
SELECT orders.rest_id,
       chain AS "Название сети",
       type AS "Тип кухни",
       ROUND(SUM(commission_revenue)::numeric, 2) AS LTV
FROM orders
JOIN rest_analytics.partners ON orders.rest_id = partners.rest_id AND orders.city_id = partners.city_id
GROUP BY 1, 2, 3
ORDER BY LTV DESC
LIMIT 3;

/*
Результаты расчёта LTV ресторанов (топ-3) за май-июнь 2021:

| rest_id                          | Название сети              | Тип кухни     | LTV       |
|----------------------------------|----------------------------|---------------|-----------|
| 2e2b2b9c458b42ce9da395ba9c247fdc | Гурманское Наслаждение     | Ресторан      | 170479.19 |
| b94505e7efff41d2b2bf6bbb78fe71f2 | Гастрономический Шторм     | Ресторан      | 164508.16 |
| 42d14fe9fd254ba9b18ab4acd64d4f33 | Шоколадный Рай             | Кондитерская  | 61199.76  |
*/

/*================================================================
  5. Расчёт LTV блюд
     Суммарный доход (комиссия), который принесло блюдо за период
================================================================*/

/* Цель: определяем LTV пяти самых популярных блюд ресторанов Саранска
 * (с максимальным LTV).
 * Для каждого блюда в этих ресторанах посчитал суммарную комиссию 
 * за май-июнь 2021 года. */

-- Рассчитываем величину комиссии с каждого заказа, фильтруем заказы по дате и городу
WITH orders AS
  (SELECT events.rest_id,
          events.city_id,
          events.object_id,
          revenue * commission AS commission_revenue
   FROM rest_analytics.analytics_events AS events
   JOIN rest_analytics.cities cities ON events.city_id = cities.city_id
   WHERE revenue IS NOT NULL
     AND log_date BETWEEN '2021-05-01' AND '2021-06-30'
     AND city_name = 'Саранск'), 
-- Рассчитываем два ресторана с наибольшим LTV
top_ltv_restaurants AS
  (SELECT orders.rest_id,
          chain,
          type,
          ROUND(SUM(commission_revenue)::numeric, 2) AS LTV
   FROM orders
   JOIN rest_analytics.partners partners ON orders.rest_id = partners.rest_id AND orders.city_id = partners.city_id 
   GROUP BY 1, 2, 3
   ORDER BY LTV DESC
   LIMIT 2)
SELECT chain AS "Название сети",
       dishes.name AS "Название блюда",
       spicy,
       fish,
       meat,
       ROUND(SUM(orders.commission_revenue)::numeric, 2) AS LTV
FROM orders
JOIN top_ltv_restaurants ON orders.rest_id = top_ltv_restaurants.rest_id
JOIN rest_analytics.dishes dishes ON orders.object_id = dishes.object_id
AND top_ltv_restaurants.rest_id = dishes.rest_id
GROUP BY 1, 2, 3, 4, 5
ORDER BY LTV DESC
LIMIT 5;

/*
Результаты расчёта LTV блюд (топ-5) за май-июнь 2021:

| Название сети          | Название блюда                                      | spicy | fish | meat | LTV      |
|------------------------|-----------------------------------------------------|-------|------|------|----------|
| Гастрономический Шторм | brokkoli zapechennaja v duhovke s jajcami i travami | 0     | 1    | 1    | 41140.43 |
| Гурманское Наслаждение | govjazhi shashliki v pesto iz kinzi                 | 0     | 1    | 1    | 36676.77 |
| Гурманское Наслаждение | medaloni iz lososja                                 | 0     | 1    | 1    | 14946.87 |
| Гурманское Наслаждение | myasnye ezhiki                                      | 0     | 0    | 1    | 14337.89 |
| Гастрономический Шторм | teljatina s sousom iz belogo vina petrushki         | 0     | 1    | 1    | 13980.96 |
*/

/*==============================================================
  6. Расчёт Retention Rate
     Доля пользователей, вернувшихся в приложение в определённый 
     день после регистрации
==============================================================*/

/* Цель: определить, как часто новые пользователи возвращаются 
 * в приложение в течение первой недели после регистрации.
 * Отобрал новых пользователей из Саранска, зарегистрировавшихся 
 * с 1 мая по 24 июня.
 * Для каждого нового пользователя определил, возвращался ли он 
 * в приложение в каждый из дней первой недели после регистрации.
 * Рассчитал Retention Rate для каждого дня (0–7) как отношение 
 * вернувшихся пользователей к общему числу новых пользователей.*/

-- Рассчитываем новых пользователей по дате первого посещения продукта
WITH new_users AS
  (SELECT DISTINCT first_date,
                   user_id
   FROM rest_analytics.analytics_events AS events
   JOIN rest_analytics.cities cities ON events.city_id = cities.city_id
   WHERE first_date BETWEEN '2021-05-01' AND '2021-06-24'
     AND city_name = 'Саранск'),
-- Рассчитываем активных пользователей по дате события
active_users AS
  (SELECT DISTINCT log_date,
                   user_id
   FROM rest_analytics.analytics_events AS events
   JOIN rest_analytics.cities cities ON events.city_id = cities.city_id
   WHERE log_date BETWEEN '2021-05-01' AND '2021-06-30'
     AND city_name = 'Саранск'),
daily_retention AS
  (SELECT n.user_id,
          first_date,
          log_date::date - first_date::date AS day_since_install
   FROM new_users AS n
   JOIN active_users AS a ON n.user_id = a.user_id
   AND log_date >= first_date)
SELECT day_since_install,
       COUNT(DISTINCT user_id) AS retained_users,
       ROUND((1.0 * COUNT(DISTINCT user_id) / MAX(COUNT(DISTINCT user_id)) OVER (ORDER BY day_since_install))::numeric, 2) AS retention_rate
FROM daily_retention
WHERE day_since_install < 8
GROUP BY day_since_install
ORDER BY day_since_install;

/*
Результаты расчёта Retention Rate (первая неделя) за май-июнь 2021:

| day_since_install | retained_users | retention_rate |
|-------------------|----------------|----------------|
| 0                 | 5572           | 1.00           |
| 1                 | 768            | 0.14           |
| 2                 | 419            | 0.08           |
| 3                 | 283            | 0.05           |
| 4                 | 251            | 0.05           |
| 5                 | 207            | 0.04           |
| 6                 | 205            | 0.04           |
| 7                 | 205            | 0.04           |
*/

/*================================================================
  7. Расчёт Retention Rate по месяцам
     Сравнение возвращаемости пользователей, зарегистрировавшихся 
     в разные месяцы
================================================================*/

/* Цель: сравнить возвращаемость пользователей двух когорт 
 * (май и июнь 2021 года) в первую неделю после регистрации. * 
 * Разбил новых пользователей из Саранска на две когорты 
 * по месяцу первого посещения (май и июнь 2021).
 * Для каждой когорты рассчитал Retention Rate в разрезе дней 
 * первой недели (после регистрации).
 * Сравнил Retention Rate двух когорт, чтобы оценить, 
 * изменилось ли поведение пользователей между месяцами.*/

-- Рассчитываем новых пользователей по дате первого посещения продукта
WITH new_users AS
  (SELECT DISTINCT first_date,
                   user_id
   FROM rest_analytics.analytics_events AS events
   JOIN rest_analytics.cities cities ON events.city_id = cities.city_id
   WHERE first_date BETWEEN '2021-05-01' AND '2021-06-24'
     AND city_name = 'Саранск'),
-- Рассчитываем активных пользователей по дате события
active_users AS
  (SELECT DISTINCT log_date,
                   user_id
   FROM rest_analytics.analytics_events AS events
   JOIN rest_analytics.cities cities ON events.city_id = cities.city_id
   WHERE log_date BETWEEN '2021-05-01' AND '2021-06-30'
     AND city_name = 'Саранск'),
-- Соединяем таблицы с новыми и активными пользователями
daily_retention AS
  (SELECT n.user_id,
          first_date,
          log_date::date - first_date::date AS day_since_install
   FROM new_users AS n
   JOIN active_users AS a ON n.user_id = a.user_id
   AND log_date >= first_date)
SELECT DISTINCT CAST(DATE_TRUNC('month', first_date) AS date) AS "Месяц",
                day_since_install,
                COUNT(DISTINCT user_id) AS retained_users,
                ROUND((1.0 * COUNT(DISTINCT user_id) / MAX(COUNT(DISTINCT user_id)) OVER (PARTITION BY CAST(DATE_TRUNC('month', first_date) AS date)
ORDER BY day_since_install))::numeric, 2) AS retention_rate
FROM daily_retention
WHERE day_since_install < 8
GROUP BY "Месяц", day_since_install
ORDER BY "Месяц", day_since_install;

/*
Результаты расчёта Retention Rate по когортам (май и июнь 2021):

| Месяц      | day_since_install | retained_users | retention_rate |
|------------|-------------------|----------------|----------------|
| 2021-05-01 | 0                 | 3069           | 1.00           |
| 2021-05-01 | 1                 | 443            | 0.14           |
| 2021-05-01 | 2                 | 223            | 0.07           |
| 2021-05-01 | 3                 | 144            | 0.05           |
| 2021-05-01 | 4                 | 142            | 0.05           |
| 2021-05-01 | 5                 | 122            | 0.04           |
| 2021-05-01 | 6                 | 120            | 0.04           |
| 2021-05-01 | 7                 | 140            | 0.05           |
|            |                   |                |                |
| 2021-06-01 | 0                 | 2576           | 1.00           |
| 2021-06-01 | 1                 | 328            | 0.13           |
| 2021-06-01 | 2                 | 196            | 0.08           |
| 2021-06-01 | 3                 | 140            | 0.05           |
| 2021-06-01 | 4                 | 109            | 0.04           |
| 2021-06-01 | 5                 | 86             | 0.03           |
| 2021-06-01 | 6                 | 85             | 0.03           |
| 2021-06-01 | 7                 | 65             | 0.03           |
*/
