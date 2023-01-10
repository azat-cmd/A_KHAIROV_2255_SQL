-- 2.Написать процедуру, которая возвращает свободные места по заданному маршруту

INSERT INTO route(departure, arrive, date_departure, date_arrival)
VALUES('Москва','Питер','2023-01-10','2023-01-10'),
('Воронеж','Нижний Новгород','2023-02-05','2023-02-06'),
('Таганрог','Уфа','2023-01-15','2023-01-17'),
('Казань','Москва','2023-03-12','2023-03-13'),
('Москва','Питер','2023-01-12','2023-01-13'),
('Воронеж','Нижний Новгород','2023-01-05','2023-01-06');

CREATE OR REPLACE FUNCTION free_seats(departure varchar, arrive varchar) RETURNS SETOF route
AS $$
BEGIN
	RETURN QUERY
		SELECT *
		FROM route r
		WHERE r.departure = free_seats.departure and r.arrive =  free_seats.arrive;
END $$ LANGUAGE plpgsql;

SELECT * FROM free_seats('Воронеж','Нижний Новгород');
-- 3.Написать функцию, которая возвращает true/false, при помощи неё
--можно подписаться на изменение цены на заданный маршрут

CREATE OR REPLACE FUNCTION subscribe(departure varchar, arrive varchar, date_departure TIMESTAMPTZ, date_arrival TIMESTAMPTZ, mail varchar) RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE 
	rez boolean;
	id_route int;
BEGIN
	IF((SELECT count(*) FROM route r WHERE r.departure = subscribe.departure) = 0) THEN
		rez := false;
	ELSE 
		rez := true;
		SELECT id INTO id_route 
		FROM route r 
		WHERE r.departure = subscribe.departure and
		r.arrive = subscribe.arrive and 
		r.date_departure = subscribe.date_departure and 
		r.date_arrival = subscribe.date_arrival;
		IF((SELECT count(*) FROM subscription_cost sc where sc.route_id = id_route and sc.email = subscribe.mail) = 0) THEN
			INSERT INTO subscription_cost(route_id, email) VALUES(id_route, subscribe.mail);
		ELSE 
			rez := false;
		END IF;
	END IF;
	RETURN rez;
END $$;

SELECT * FROM subscribe('Воронеж','Нижний Новгород','2023-02-05','2023-02-06', 'a.@mail.ru')


-- 4.Добавить новую таблицу, в которую будут сохраняться данные по
--сделанным запросом от пользователей (поиск свободных мест) на
--конкретный маршрут.

CREATE TABLE history
(	id SERIAL PRIMARY KEY,
	route_id INT REFERENCES route(id),
 	user_id INT REFERENCES users(id),
 	seat INT NOT NULL,
 	request_date TIMESTAMPTZ
 	);
-- 5.По п. 4 реализовать триггер, который при записе в таблицу
--агрегирует данные в ещё одну таблицу (которой будут пользоваться
--аналитики), нужно помитно сохранять сколько было сделано запросов
CREATE TABLE history2
(	id SERIAL PRIMARY KEY,
	route_id INT REFERENCES route(id),
 	user_id INT REFERENCES users(id),
 	seat INT NOT NULL,
 	count INT DEFAULT 1,
 	year INT,
 	month INT,
 	day INT,
 	hour INT,
 	minut INT
 	);

CREATE OR REPLACE FUNCTION add_to_history2() RETURNS TRIGGER 
AS $$
BEGIN
	IF((SELECT COUNT(*)
	   FROM history2  h
	   WHERE h.route_id = NEW.route_id and
	  	 h.seat = NEW.seat and
	  	 h.year =  EXTRACT(year from NEW.request_date) and
	  	 h.month = EXTRACT(month from NEW.request_date) and
	  	 h.day =  EXTRACT(day from NEW.request_date) and
	  	 h.hour = EXTRACT(hour from NEW.request_date) and
	 	 h.minut = EXTRACT(minute from NEW.request_date)) = 0) THEN
		INSERT INTO history2(route_id, seat, year, month, day, hour, minut)
		VALUES(NEW.route_id,NEW.seat,
			   EXTRACT(year from NEW.request_date),
			   EXTRACT(month from NEW.request_date),
			   EXTRACT(day from NEW.request_date),
			   EXTRACT(hour from NEW.request_date),
			   EXTRACT(minute from NEW.request_date));
	ELSE 
		UPDATE history2 h
		SET count = count + 1
		WHERE h.route_id = NEW.route_id and
		   h.seat = NEW.seat and
		   h.year =  EXTRACT(year from NEW.request_date) and
	  	   h.month = EXTRACT(month from NEW.request_date) and
	  	   h.day =  EXTRACT(day from NEW.request_date) and
	  	   h.hour =  EXTRACT(hour from NEW.request_date) and
	 	   h.minut =  EXTRACT(minute from NEW.request_date);
	END IF;
	RETURN NULL;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER 	menu_audit
	AFTER 	
	INSERT 
	ON history
	for each row
	EXECUTE FUNCTION add_to_history2()


