/*==============================================================
  Анализ внутриигровых покупок пользователей MMORPG
  Проект: «Секреты Темнолесья»

  Цель исследования:
  определить влияние характеристик игроков и игровых персонажей
  на совершение внутриигровых покупок, оценить платежное поведение
  пользователей и подготовить рекомендации для повышения
  эффективности внутриигровой монетизации
==============================================================*/


/*==============================================================
  Исследовательский анализ данных
==============================================================*/

-- 1. Исследование доли платящих игроков

-- 1.1. Доля платящих пользователей по всем данным:

SELECT 
      COUNT(id) AS count_users, -- общее количество игроков, зарегистрированных в игре
      SUM(CASE WHEN payer = 1 THEN 1 ELSE 0 END) AS paying_players, -- количество платящих игроков
      SUM(CASE WHEN payer = 1 THEN 1 ELSE 0 END) * 1.0
      / COUNT(id) AS share_of_players -- доля платящих игроков от общего количества пользователей, зарегистрированных в игре
FROM fantasy.users;

-- 1.2. Доля платящих пользователей в разрезе расы персонажа:

SELECT 
      r.race, -- раса персонажа;
      SUM(CASE WHEN u.payer = 1 THEN 1 ELSE 0 END) AS paying_players_race, -- количество платящих игроков этой расы
      COUNT(u.id) AS count_users_race, -- общее количество зарегистрированных игроков этой расы
      SUM(CASE WHEN u.payer = 1 THEN 1 ELSE 0 END) * 1.0
      / COUNT(u.id) AS share_of_players_race -- доля платящих игроков среди всех зарегистрированных игроков этой расы
FROM fantasy.users AS u 
JOIN fantasy.race AS r 
ON r.race_id = u.race_id 
GROUP BY r.race
ORDER BY share_of_players_race DESC;

-- 2. Исследование внутриигровых покупок

-- 2.1. Статистические показатели по полю amount:

SELECT 
      COUNT(transaction_id) AS number_of_purchases, -- общее количество покупок
      SUM(amount) AS total_cost, -- суммарная стоимость всех покупок
      MIN(amount) AS min_cost, -- минимальная стоимость покупки
      MAX(amount) AS max_cost, -- максимальная стоимость покупки
      AVG(amount) AS avg_cost, -- среднее значение стоимости покупки
      PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY amount) AS median_cost, -- медиана стоимости покупки 
      STDDEV(amount) AS standard_deviation_cost -- стандартное отклонение стоимости покупки
FROM fantasy.events;

-- 2.2. Аномальные нулевые покупки:

SELECT
    COUNT(*) AS count_purchases, -- общее количество покупок
    SUM(CASE WHEN amount = 0 THEN 1 ELSE 0 END) AS zero_amount_purchases, -- покупки с нулевой стоимостью
    SUM(CASE WHEN amount = 0 THEN 1 ELSE 0 END) * 1.0 
    / COUNT(*) AS zero_amount_share -- доля покупок с нулевой стоимостью от общего количества покупок
FROM fantasy.events;

-- 2.3. Популярные эпические предметы:

-- действительные покупки (исключаем покупки с нулевой стоимостью)
WITH valid_purchases AS (
    SELECT *
    FROM fantasy.events
    WHERE amount > 0
),
-- общие показатели по количеству продаж и числу игроков, которые что-либо купили по всей таблице
general_indicators AS (
    SELECT 
         COUNT(*) AS number_of_sales, -- общее количестов продаж всех предметов
         COUNT(DISTINCT id) AS buying_players -- число игроков, которые что-либо купили 
    FROM valid_purchases
)
SELECT 
     i.game_items AS item_name, -- название эпического предмета
     COUNT(*) AS absolute_number, -- абсолютное число продаж предмета
     COUNT(*) * 1.0 / gi.number_of_sales AS relative_number, -- относительное число продаж предмета
     COUNT(DISTINCT vp.id) * 1.0 / gi.buying_players AS share_of_buying_players-- доля игроков, которые купили предмет
FROM valid_purchases AS vp
JOIN fantasy.items AS i 
     ON i.item_code = vp.item_code
CROSS JOIN general_indicators AS gi
-- группируем по названию эпического предмета, количеству продаж и числу покупающих игроков
GROUP BY i.game_items, gi.number_of_sales, gi.buying_players
-- сортируем по популярности эпического предмета среди игроков
ORDER BY share_of_buying_players DESC 

/*==============================================================
  Решение ad hoc-задачи
==============================================================*/

-- Зависимость активности игроков от расы персонажа:

-- общее количество зарегистрированных игроков по расам 
WITH race_users AS (  
    SELECT
        r.race,
        COUNT(u.id) AS total_users -- количество зарегистрированных игроков для каждой расы
    FROM fantasy.users AS u
    JOIN fantasy.race AS r 
        ON r.race_id = u.race_id
    GROUP BY r.race
),
-- игроки, которые совершали покупку
paying_players AS (  
    SELECT
        r.race,
        COUNT(DISTINCT u.id) AS number_of_buyers, -- количество игроков по расе, которые покупали
        COUNT(DISTINCT CASE WHEN u.payer = 1 THEN u.id END) AS pay_play -- количество платящих игроков
    FROM fantasy.users AS u
    JOIN fantasy.race AS r 
        ON r.race_id = u.race_id
    JOIN fantasy.events AS e 
        ON e.id = u.id
    WHERE e.amount > 0
    GROUP BY r.race
),
-- активность игроков, которые совершали покупку, с учётом расы персонажа
player_activity AS (  
    SELECT
        r.race, -- название расы
        u.id AS user_id,
        COUNT(*) AS number_of_purchases, -- количество покупок игрока
        AVG(e.amount) AS avg_purchase_price, -- средняя стоимость покупки игрока
        SUM(e.amount) AS total_purchase_amount -- общая сумма покупки игрока
    FROM fantasy.users AS u
    JOIN fantasy.race AS r 
        ON r.race_id = u.race_id
    JOIN fantasy.events AS e 
        ON e.id = u.id
    WHERE e.amount > 0
    GROUP BY r.race, u.id
)
SELECT
    ru.race, 
    ru.total_users, -- общее количество зарегистрированных игроков в расе
    COALESCE(pp.number_of_buyers, 0) AS number_of_buyers, -- игроки, совершившие покупку
    COALESCE(pp.number_of_buyers, 0) * 1.0 / ru.total_users AS share_of_buyers, -- доля покупающих игроков
    COALESCE(pp.pay_play, 0) * 1.0 / NULLIF(pp.number_of_buyers, 0) 
    AS share_of_paying_players, -- доля платящих игроков среди покупателей
    AVG(pa.number_of_purchases) AS avg_number_of_purchases, -- среднее количество покупок
    AVG(pa.avg_purchase_price) AS avg_purchase_price, -- средняя стоимость одной покупки
    AVG(pa.total_purchase_amount) AS avg_total_cost -- средняя суммарная стоимость всех покупок
FROM race_users AS ru
LEFT JOIN paying_players AS pp 
    ON ru.race = pp.race
LEFT JOIN player_activity AS pa 
    ON ru.race = pa.race
GROUP BY
    ru.race,
    ru.total_users,
    pp.number_of_buyers,
    pp.pay_play
ORDER BY share_of_buyers DESC;






