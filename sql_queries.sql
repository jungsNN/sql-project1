/* QUERY 1: (are dates evenly distributed?) */

WITH main AS (
  SELECT CAST(
      DATE_PART('year', rental_date) || '-' ||
      DATE_PART('mon', rental_date) || '-' ||
      DATE_PART('day', rental_date) AS DATE) AS rented_on,
      rental_id,
      i.store_id
  FROM rental r
  JOIN inventory i
  ON i.inventory_id = r.inventory_id),
/* FIRST, THERE'S ONLY ONE MONTH IN 2006 */

SELECT DISTINCT
      DATE_PART('month', rented_on) AS months,
      DATE_PART('year', rented_on) AS year
FROM main
ORDER BY year, months

/* next, looking at number of days in each month
in the overall ‘rental’ dataset */
  SELECT months,
  	COUNT(DISTINCT days) num_days
  FROM (
  SELECT DISTINCT
          DATE_PART('month', rented_on) AS months,
          DATE_PART('day', rented_on) AS days
  FROM main
  ) sub
  GROUP BY 1
/* note: presented the above result images in the first query slide. 
  The queries below were for my reference */

/* finally, checking each store’s dates to make sure they look similar*/
  SELECT months,
    COUNT(DISTINCT days) num_days
  FROM (
  SELECT DISTINCT
          DATE_PART('month', rented_on) AS months,
          DATE_PART('day', rented_on) AS days
  FROM main
  WHERE store_id = 1
  ) sub
  GROUP BY 1

  SELECT months,
    COUNT(DISTINCT days) num_days
  FROM (
  SELECT DISTINCT
          DATE_PART('month', rented_on) AS months,
          DATE_PART('day', rented_on) AS days
  FROM main
  WHERE store_id = 2
  ) sub
  GROUP BY 1


/* QUERY 2: Throughout May 2005 -August 2005,
how are the two stores differ in counts of rentals?
*/
WITH st1 AS (
  SELECT DISTINCT
  	  month,
      year,
      store_id,
      COUNT(rental_id) OVER (PARTITION BY month) AS num_rented
  FROM (
    SELECT
          DATE_PART('year', rented_on) AS year,
          DATE_PART('month', rented_on) AS month,
          rental_id,
          store_id
    FROM main
    WHERE store_id = 1 AND DATE_PART('month', rented_on) != 2) t1
      ),
  /* store 2 */
st2 AS (
   SELECT DISTINCT
  	  month,
      year,
      store_id,
      COUNT(rental_id) OVER (PARTITION BY month) AS num_rented
   FROM (
    SELECT
          DATE_PART('year', rented_on) AS year,
          DATE_PART('month', rented_on) AS month,
          rental_id,
          store_id
    FROM main
    WHERE store_id = 2 AND DATE_PART('month', rented_on) != 2) t2

  /*Now, join the two table to compare (here I can add visuals )*/
  SELECT *
  FROM (
    SELECT *
    FROM st1

    UNION ALL

    SELECT *
    FROM st2
    ) u1
  ORDER BY num_rented DESC


/* QUERY 3:  7 day rolling mean for rental counts in each store? */

WITH rental_dates AS (
  SELECT CAST(
      DATE_PART('year', rental_date) || '-' ||
      DATE_PART('mon', rental_date) || '-' ||
      DATE_PART('day', rental_date) AS DATE) AS rented_on,
      rental_id,
      i.store_id
  FROM rental r
  JOIN inventory i
  ON i.inventory_id = r.inventory_id
  ),
daily_rented AS (
  SELECT store_id,
      	rented_on,
     	COUNT(rental_id) daily_count
  FROM rental_dates
  GROUP BY store_id, rented_on
  ORDER BY rented_on)

SELECT store_id,
DATE_TRUNC('week', rented_on) AS weekly,
    	ROUND(AVG(daily_count), 2) weekly_avg_rentals
FROM daily_rented
GROUP BY 1, 2
ORDER BY 2


/* QUERY 4: how do two stores different in the type of film genres
rented? (what are the top 10 genres rented in each store?)

WITH st1_genre AS (
    SELECT c.name genre,
  	r.inventory_id
  FROM rental r
  JOIN inventory i
  ON i.inventory_id = r.inventory_id
  JOIN film_category fc
  ON fc.film_id = i.film_id
  JOIN category c
  ON c.category_id = fc.category_id
  WHERE i.store_id = 1),
  st2_genre AS (
    SELECT c.name genre,
  	r.inventory_id
  FROM rental r
  JOIN inventory i
  ON i.inventory_id = r.inventory_id
  JOIN film_category fc
  ON fc.film_id = i.film_id
  JOIN category c
  ON c.category_id = fc.category_id
  WHERE i.store_id = 2)

/*STORE 1 GENRES RENTED COUNTS IN DESCENDING ORDER (ran this first)*/
 SELECT st1.genre store1_genre,
  	COUNT(st1.inventory_id) rented_count_st1
 FROM st1_genre st1
 GROUP BY 1
 ORDER BY 2 DESC

/* STORE 2 GENRES RENTED COUNTS IN DESCENDING ORDER */
 SELECT st2.genre store2_genre,
  	COUNT(st2.inventory_id) rented_count_st2
 FROM st2_genre st2
 GROUP BY 1
 ORDER BY 2 DESC
