
/*==============================================================
  Анализ рынка недвижимости Санкт-Петербурга
  и Ленинградской области

  Цель исследования:
  определить наиболее привлекательные сегменты недвижимости,
  выявить сезонные закономерности рынка и подготовить
  аналитические выводы для формирования бизнес-стратегии
==============================================================*/


/*==============================================================
  1. Анализ времени активности объявлений
==============================================================*/

-- Определим аномальные значения (выбросы) по значению перцентилей 
/* Только в тех колонках, в которых они присутствуют - total_area, rooms, balcony, ceiling_height.
   При проверке на аномальные значения (в частности MIN, MAX) колонок kitchen_area, floor, 
   floors_total (используются в финальном запросе) может показаться, 
   что выбросы в них есть. Однако, указанные "аномалии" нивелируются на общем фоне и слабо влияют 
   на средние показатели. Например, максимальная площадь кухни 112 кв.м. (при этом, анализируя 
   топ-10, мы видим, что разброс площади идет от 75 до 112 кв.м., что не является критичным), 
   аналогичная ситуация с максимальной жилой площадью (диапазон площади топ-10 от 274 до 409,7 кв.м.). 
   В связи с этим, значения в указанных колонках не фильтровались по процентилю. */

WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit, -- общая площадь
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit, -- количество комнат 
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit, -- количество балконов
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h, -- высота потолков (высокие)
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l -- высота потолков (низкие)
    FROM real_estate.flats     
),
-- Найдём id объявлений, которые не содержат выбросы, также оставим пропущенные данные:
filtered_id AS (
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
             AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) 
             OR ceiling_height IS NULL)
),
-- Подготавливаем очищенный набор данных
prepared_data AS (
    SELECT
        a.id, -- идентификатор объявления
        f.total_area, -- общая площадь квартиры
        f.kitchen_area, -- площадь кухни
        f.rooms, -- число комнат
        f.balcony, -- количество балконов
        f.ceiling_height, -- высота потолка
        f.floor, -- этаж квартиры
        f.floors_total, -- этажность дома
        a.last_price / f.total_area AS price_per_sqm, -- стоимость 1 кв. м. 
-- Присваиваем категорию в зависимости от местоположения недвижимости 
        CASE
            WHEN c.city = 'Санкт-Петербург' THEN 'Санкт-Петербург'
            ELSE 'ЛенОбл'
        END AS region, 
-- Присваиваем категорию в зависимости от количества дней активности объявления 
        CASE
            WHEN a.days_exposition IS NULL THEN 'non category'
            WHEN a.days_exposition BETWEEN 1 AND 30 THEN 'около одного месяца'
            WHEN a.days_exposition BETWEEN 31 AND 90 THEN 'от одного до трёх месяцев'
            WHEN a.days_exposition BETWEEN 91 AND 180 THEN 'от трёх месяцев до полугода'
            WHEN a.days_exposition > 180 THEN 'более полугода'
        END AS activity_category 
    FROM filtered_id AS fi
    JOIN real_estate.flats AS f ON fi.id = f.id
    JOIN real_estate.advertisement AS a ON a.id = f.id
    JOIN real_estate.city AS c ON f.city_id = c.city_id
    JOIN real_estate.type AS t ON f.type_id = t.type_id
-- Фильтруем данные по периоду нахождения объявления о продаже недвижимости (с 2015 по 2018 годы включительно) и по типу населённого пункта (город)
    WHERE 
        a.first_day_exposition BETWEEN '2015-01-01' AND '2018-12-31'
        AND t.type = 'город'
)
-- Финальный запрос
SELECT
    region, -- местоположение недвижимости 
    activity_category, -- время активности объявления (дни)
    COUNT(*) AS total_ads, -- количество объявлений 
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY region), 2) AS share_in_region, -- доля объявлений в разрезе каждого региона
    ROUND(AVG(price_per_sqm)::numeric, 2) AS avg_price_per_sqm, -- средняя стоимость 1 кв.м. 
    ROUND(AVG(total_area)::numeric, 2) AS avg_total_area, -- средняя площадь квартиры (кв.м.) 
    ROUND(AVG(kitchen_area)::numeric, 2) AS avg_kitchen_area, -- средняя площадь кухни
    ROUND(AVG(rooms)::numeric, 2) AS avg_rooms, -- среднее число комнат в каждом сегменте
    ROUND(AVG(balcony)::numeric, 2) AS avg_balcony, -- среднее количество балконов
    ROUND(AVG(ceiling_height)::numeric, 2) AS avg_ceiling_height, -- средняя высота потолка (в метрах)
    ROUND(AVG(floor)::numeric, 2) AS avg_floor, -- средняя этажность квартир
    ROUND(AVG(floors_total)::numeric, 2) AS avg_floors_total -- средняя этажность дома
FROM prepared_data
-- Группируем данные по категории region и активности объявления
GROUP BY region, activity_category
-- Сортируем данные по категории region и активности объявления
ORDER BY region, activity_category;


/*==============================================================
  2. Анализ сезонности рынка недвижимости
==============================================================*/


-- Определим аномальные значения (выбросы) по значению перцентилей:
/* Для фильтрации используем last_price (стоимость квартиры) total_area (площадь квартиры),
   поскольку аномальные показатели могут исказить значения необходимых нам метрик 
   (средняя стоимость квадратного метра и средняя площадь квартир) */

WITH limits AS (
    SELECT
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY f.total_area) AS total_area_p1,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY f.total_area) AS total_area_p99,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY a.last_price) AS price_p1,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY a.last_price) AS price_p99
    FROM real_estate.flats AS f
    JOIN real_estate.advertisement AS a ON f.id = a.id
),
-- Найдём id объявлений, которые не содержат выбросы, также оставим пропущенные данные:
filtered_id AS (
    SELECT f.id
    FROM real_estate.flats AS f
    JOIN real_estate.advertisement AS a ON f.id = a.id
    CROSS JOIN limits AS l
    WHERE
        f.total_area BETWEEN l.total_area_p1 AND l.total_area_p99
        AND a.last_price BETWEEN l.price_p1 AND l.price_p99
),
-- Используйте id объявлений (СТЕ filtered_id), которые не содержат выбросы при анализе данных
-- СТЕ для подготовки данных (месяцы, цена за кв.м.)
base_data AS (
    SELECT
        a.id, -- идентификатор объявления
        EXTRACT(MONTH FROM a.first_day_exposition) AS publication_month, -- месяц публикации
        EXTRACT(MONTH FROM (a.first_day_exposition + a.days_exposition::int)) AS removal_month, -- месяц снятия с продажи
        a.last_price / f.total_area AS price_per_sqm, -- стоимость за кв.м.
        f.total_area
    FROM real_estate.advertisement AS a
    JOIN real_estate.flats AS f ON a.id = f.id
    JOIN real_estate.type AS t ON f.type_id = t.type_id
    JOIN filtered_id AS fi ON fi.id = a.id
-- Фильтруем по населенному пункту "город" и временному интервалу (2015-2018 гг.)
    WHERE
        t.type = 'город'
        AND EXTRACT(YEAR FROM a.first_day_exposition) BETWEEN 2015 AND 2018
),
-- Собираем статистику по месяцам публикации
publication_stats AS (
    SELECT
        publication_month,
        COUNT(id) AS publication_count, -- количество объявлений опубликованных в месяце
        ROUND(AVG(price_per_sqm)::numeric, 2) AS avg_price_per_sqm_pub, -- средняя стоимость за 1 кв.м.
        ROUND(AVG(total_area)::numeric, 2) AS avg_area_pub -- средняя площадь
    FROM base_data
-- Группируем по месяцу публикации
    GROUP BY publication_month
),
-- Собираем статистику по месяцам снятия
removal_stats AS (
    SELECT
        removal_month,
        COUNT(id) AS removal_count, -- количество объявлений снятых с публикации
        ROUND(AVG(price_per_sqm)::numeric, 2) AS avg_price_per_sqm_rem,
        ROUND(AVG(total_area)::numeric, 2) AS avg_area_rem
    FROM base_data
    GROUP BY removal_month
)
-- Финальный запрос
SELECT
    p.publication_month, -- месяц публикации объявления
    p.publication_count, -- количество объявлений опубликованных в этом месяце
    r.removal_count, -- количество объявлений снятых с публикации в этом месяце
    p.avg_price_per_sqm_pub, -- средняя стоимость за 1 кв.м. в опубликованных объявлениях
    r.avg_price_per_sqm_rem, -- средняя стоимость за 1 кв.м. в снятых объявлениях
    p.avg_area_pub, -- средняя площадь квартир в опубликованных объявлениях
    r.avg_area_rem -- средняя стоимость квартир в снятых объявлениях
FROM publication_stats AS p
LEFT JOIN removal_stats AS r
    ON p.publication_month = r.removal_month
-- Сортируем по месяцу публикации
ORDER BY p.publication_month;
