--Однотабличные запросы
--1 Вывести всеми возможными способами имена и фамилии студентов, средний балл которых от 4 до 4.5
SELECT name, surname
FROM student
WHERE score > 4 AND score < 4.5
--2 Познакомиться с функцией CAST. Вывести при помощи неё студентов заданного курса (использовать Like)
SELECT *
FROM student
WHERE n_group::varchar like '4%'
--3 Вывести всех студентов, отсортировать по убыванию номера группы и имени от а до я
SELECT *
FROM student, hobby
ORDER BY n_group,name
--4 Вывести студентов, средний балл которых больше 4 и отсортировать по баллу от большего к меньшему
SELECT *
FROM student
WHERE score > 4
ORDER BY score DESC 
--5 Вывести на экран название и риск футбола и хоккея
SELECT name, risk
FROM hobby
WHERE name ='футбол' or name = 'хоккей'
--6 Вывести id хобби и id студента которые начали заниматься хобби между двумя заданными датами (выбрать самим) и студенты должны до сих пор заниматься хобби
SELECT hobby_id, student_id
FROM student_hobby
WHERE date_start BETWEEN '2018-11-12' AND '2020-5-1' AND date_finish IS NULL
--7 Вывести студентов, средний балл которых больше 4.5 и отсортировать по баллу от большего к меньшему
SELECT name
FROM student
WHERE score > 4.5
ORDER BY score DESC
--8 Из запроса №7 вывести несколькими способами на экран только 5 студентов с максимальным баллом
SELECT name
FROM student
WHERE score > 4.5
ORDER BY score DESC
LIMIT 5

SELECT name
FROM student
WHERE score > 4.5
ORDER BY score DESC FETCH FIRST 5 ROWS ONLY
--9 Выведите хобби и с использованием условного оператора сделайте риск словами:
SELECT name, 
	(CASE 
		WHEN risk>=8  THEN 'очень высокий'
		WHEN risk>=6 THEN 'высокий'
	    WHEN risk>=4 THEN 'средний'
	    WHEN risk>=2 THEN 'низкий'
		ELSE 'очень низкий'
	END) as risk
FROM hobby
--10 Вывести 3 хобби с максимальным риском
SELECT hobby_name
FROM hobby
ORDER BY risk DESC 
LIMIT 3

--Групповые функции
--1 Выведите на экран номера групп и количество студентов, обучающихся в них
SELECT MAX(n_group), COUNT(n_group)
FROM student
GROUP BY n_group
ORDER BY n_group
--2 Выведите на экран для каждой группы максимальный средний балл
SELECT MAX(n_group), MAX(score)
FROM student
GROUP BY n_group
ORDER BY n_group
--3 Подсчитать количество студентов с каждой фамилией
SELECT surname, COUNT(surname)
FROM student
GROUP BY surname
ORDER BY surname
--4 Подсчитать студентов, которые родились в каждом году
SELECT YEAR(date_born), COUNT(YEAR(date_born))
FROM student
WHERE date_born IS NOT NULL
GROUP BY YEAR(date_born)
ORDER BY YEAR(date_born)
--5 Для студентов каждого курса подсчитать средний балл см. Substr
SELECT substr(n_group::varchar, 1, 1), AVG(score)
FROM student
GROUP BY substr(n_group::varchar, 1, 1)
--6 Для студентов заданного курса вывести один номер группы с максимальным средним баллом
SELECT substr(n_group::varchar, 1, 1), MAX(score)
FROM student
WHERE n_group::varchar LIKE '4%'
GROUP BY substr(n_group::varchar, 1, 1)
--7 Для каждой группы подсчитать средний балл, вывести на экран только те номера групп и их средний балл, в которых он менее или равен 3.5. Отсортировать по от меньшего среднего балла к большему.
SELECT n_group, AVG(score)
FROM student
WHERE score <= 3.5
GROUP BY n_group
--8 Для каждой группы в одном запросе вывести количество студентов, максимальный балл в группе, средний балл в группе, минимальный балл в группе
SELECT n_group, count(n_group), MAX(score), AVG(score), MIN(score)
FROM student
GROUP BY n_group
--9 Вывести студента/ов, который/ые имеют наибольший балл в заданной группе
SELECT name, score
FROM student
WHERE n_group::varchar LIKE '1135'
and score = (SELECT MAX(score) FROM student WHERE n_group::varchar LIKE '1135')
ORDER BY score DESC;
--10 Аналогично 9 заданию, но вывести в одном запросе для каждой группы студента с максимальным баллом.
SELECT n_group, name, score
FROM student, (SELECT n_group as ng, MAX(score) as sc FROM student GROUP BY n_group) as bd
WHERE score = bd.sc and n_group = bd.ng


--Многотабличные запросы
--1 Вывести все имена и фамилии студентов, и название хобби, которым занимается этот студент.
SELECT st.name,surname, h.name
FROM student st
INNER JOIN student_hobby sh ON st.id = sh.student_id
INNER JOIN hobby h ON h.id = sh.hobby_id
--2 Вывести информацию о студенте, занимающимся хобби самое продолжительное время.
SELECT *
FROM student st
INNER JOIN student_hobby sh ON st.id = sh.student_id
INNER JOIN hobby h ON h.id = sh.hobby_id
WHERE st.id = (SELECT id
FROM(
SELECT id,CASE 
		WHEN bd.finished_at IS NULL THEN now()-started_at
		ELSE finished_at-started_at 
	END
FROM (SELECT st.id, finished_at, started_at FROM student st INNER JOIN student_hobby sh ON st.id = sh.student_id INNER JOIN hobby h ON h.id = sh.hobby_id) bd) bd
WHERE bd.case = (SELECT max(bd.case)
FROM(
SELECT id,CASE 
		WHEN bd.finished_at IS NULL THEN now()-started_at
		ELSE finished_at-started_at 
	END
FROM (SELECT st.id, finished_at, started_at FROM student st INNER JOIN student_hobby sh ON st.id = sh.student_id INNER JOIN hobby h ON h.id = sh.hobby_id) bd) bd))
--3 Вывести имя, фамилию, номер зачетки и дату рождения для студентов, средний балл которых выше среднего, а сумма риска всех хобби, которыми он занимается в данный момент, больше 0.9.
SELECT st.name,st.surname,st.id,st.date_born
FROM student st , 
(SELECT AVG(score)
FROM student) bd1,
(SELECT student_id as id
FROM(
SELECT student_id, SUM(risk) 
FROM student_hobby sh
INNER JOIN hobby h ON h.id = sh.hobby_id
WHERE finished_at IS null 
GROUP BY student_id) bd
WHERE sum > 0.9)bd2
where  st.id = bd2.id and st.score>bd1.avg
--4 Вывести фамилию, имя, зачетку, дату рождения, название хобби и длительность в месяцах, для всех завершенных хобби Диапазон дат.
SELECT st.name,st.surname,st.id,st.date_born,h.name as hobby_name, 12 * extract(year from age(finished_at, started_at)) as months
FROM student st
INNER JOIN student_hobby sh ON st.id = sh.student_id
INNER JOIN hobby h ON h.id = sh.hobby_id
WHERE finished_at IS NOT null 
--5 Вывести фамилию, имя, зачетку, дату рождения студентов, которым исполнилось N полных лет на текущую дату, и которые имеют более 1 действующего хобби.
SELECT st.name,st.surname,st.id,st.date_born
FROM student st
INNER JOIN student_hobby sh ON st.id = sh.student_id
WHERE finished_at IS NOT null
GROUP BY st.id
--6 Найти средний балл в каждой группе, учитывая только баллы студентов, которые имеют хотя бы одно действующее хобби.
SELECT n_group,AVG(score)
FROM student st
INNER JOIN student_hobby sh ON st.id = sh.student_id
WHERE finished_at IS NOT null
GROUP BY n_group, st.id
--7 Найти название, риск, длительность в месяцах самого продолжительного хобби из действующих, указав номер зачетки студента.
SELECT  h.name,h.risk,12 * extract(year from age(now(), started_at)) as months
FROM student st
INNER JOIN student_hobby sh ON st.id = sh.student_id
INNER JOIN hobby h ON h.id = sh.hobby_id
WHERE finished_at IS null and st.id = 5 --указываем номер зачетки
ORDER BY months DESC
LIMIT 1
--8 Найти все хобби, которыми увлекаются студенты, имеющие максимальный балл.
SELECT  h.name
FROM student st
INNER JOIN student_hobby sh ON st.id = sh.student_id
INNER JOIN hobby h ON h.id = sh.hobby_id
WHERE st.score = (SELECT MAX(score) FROM student)
--9 Найти все действующие хобби, которыми увлекаются троечники 2-го курса.
SELECT h.name
FROM student st
INNER JOIN student_hobby sh ON st.id = sh.student_id
INNER JOIN hobby h ON h.id = sh.hobby_id
WHERE st.score >= 3 and st.score <4 and finished_at IS null
--10 Найти номера курсов, на которых более 50% студентов имеют более одного действующего хобби.
SELECT DISTINCT bd1.n_course
FROM 
(SELECT count(n_group),substr(n_group::varchar, 1, 1)::float as n_course
FROM (SELECT st.id,st.n_group
FROM student st
INNER JOIN student_hobby sh ON st.id = sh.student_id
WHERE finished_at IS null
GROUP BY st.id) bd 
GROUP BY n_group) bd1,
(SELECT substr(n_group::varchar, 1, 1)::float as n_course,count(*)
FROM student st
GROUP BY substr(n_group::varchar, 1, 1)) bd2
WHERE bd1.count > bd2.count/2
--11 Вывести номера групп, в которых не менее 60% студентов имеют балл не ниже 4.
SELECT bd1.n_group
FROM (
SELECT n_group,count(n_group)::float
FROM student st
GROUP BY n_group) bd1,
(SELECT n_group,count(n_group)::float
FROM student st
WHERE st.score >= 4 
GROUP BY n_group) bd2
WHERE bd1.n_group = bd2.n_group and bd2.count >= bd1.count*6/10
--12 Для каждого курса подсчитать количество различных действующих хобби на курсе.
SELECT substr(n_group::varchar, 1, 1)as n_course,count(n_group)
FROM student st
INNER JOIN student_hobby sh ON st.id = sh.student_id
WHERE finished_at IS null
GROUP BY n_group
--13 Вывести номер зачётки, фамилию и имя, дату рождения и номер курса для всех отличников, не имеющих хобби. Отсортировать данные по возрастанию в пределах курса по убыванию даты рождения.
SELECT st.id,st.surname,st.name,st.date_born,substr(n_group::varchar, 1, 1) as n_course,st.score
FROM student st
WHERE st.id NOT IN(
SELECT DISTINCT st.id
FROM student st
INNER JOIN student_hobby sh ON st.id = sh.student_id) and st.score = 5
ORDER BY substr(n_group::varchar, 1, 1),st.date_born DESC
--14 Создать представление, в котором отображается вся информация о студентах, которые продолжают заниматься хобби в данный момент и занимаются им как минимум 5 лет.
CREATE OR REPLACE VIEW view1 AS
SELECT st.*,sh.started_at,h.name as h_name,h.risk
FROM student st
INNER JOIN student_hobby sh ON st.id = sh.student_id
INNER JOIN hobby h ON h.id = sh.hobby_id
WHERE finished_at IS null and extract(year from age(now(), started_at)) >= 5
--15 Для каждого хобби вывести количество людей, которые им занимаются.
SELECT h.name,count(h.name)
FROM student st
INNER JOIN student_hobby sh ON st.id = sh.student_id
INNER JOIN hobby h ON h.id = sh.hobby_id
WHERE finished_at IS null
GROUP BY h.name
--16 Вывести ИД самого популярного хобби.
SELECT h.id,count(h.id)
FROM student st
INNER JOIN student_hobby sh ON st.id = sh.student_id
INNER JOIN hobby h ON h.id = sh.hobby_id
WHERE finished_at IS null
GROUP BY h.id
HAVING count(h.id) =
(SELECT max(bd.count)
FROM (SELECT h.id,count(h.id)
FROM student st
INNER JOIN student_hobby sh ON st.id = sh.student_id
INNER JOIN hobby h ON h.id = sh.hobby_id
WHERE finished_at IS null
GROUP BY h.id) bd)
--17 Вывести всю информацию о студентах, занимающихся самым популярным хобби.
SELECT *
FROM student st
INNER JOIN student_hobby sh ON st.id = sh.student_id
INNER JOIN hobby h ON h.id = sh.hobby_id
WHERE sh.finished_at IS null and h.name IN (SELECT h.name
FROM student st
INNER JOIN student_hobby sh ON st.id = sh.student_id
INNER JOIN hobby h ON h.id = sh.hobby_id
WHERE finished_at IS null
GROUP BY h.name
HAVING count(h.name) =
(select max(bd.count)
from (SELECT h.name,count(h.name)
FROM student st
INNER JOIN student_hobby sh ON st.id = sh.student_id
INNER JOIN hobby h ON h.id = sh.hobby_id
WHERE finished_at IS null
GROUP BY h.name) bd))
--18 Вывести ИД 3х хобби с максимальным риском.
SELECT h.id
FROM hobby h
ORDER BY risk DESC
LIMIT 3
--19 Вывести 10 студентов, которые занимаются одним (или несколькими) хобби самое продолжительно время.
SELECT bd.id,bd.name
FROM(
SELECT st.id,st.name,MIN(started_at)
FROM student st
INNER JOIN student_hobby sh ON st.id = sh.student_id
WHERE finished_at IS null
GROUP BY st.id) bd
ORDER BY min
LIMIT 10
--20 Вывести номера групп (без повторений), в которых учатся студенты из предыдущего запроса.
SELECT DISTINCT n_group
FROM student st, (SELECT bd.id,bd.name
FROM(
SELECT st.id,st.name,MIN(started_at)
FROM student st
INNER JOIN student_hobby sh ON st.id = sh.student_id
WHERE finished_at IS null
GROUP BY st.id) bd
ORDER BY min
LIMIT 10) bd
WHERE st.id = bd.id
--21 Создать представление, которое выводит номер зачетки, имя и фамилию студентов, отсортированных по убыванию среднего балла.
CREATE OR REPLACE VIEW view2 AS
SELECT st.id, st.name, st.surname
FROM student st
ORDER BY score DESC
--22 Представление: найти каждое популярное хобби на каждом курсе.
    -- не понятен смысл словосочетания "каждое популярное хобби", предположим, что оно означает "самое популярное хобби"
CREATE OR REPLACE VIEW view3 AS
SELECT bd1.n_course, bd1.name
FROM (SELECT h.name,substr(n_group::varchar, 1, 1) as n_course,count(substr(n_group::varchar, 1, 1))
FROM student st
INNER JOIN student_hobby sh ON st.id = sh.student_id
INNER JOIN hobby h ON h.id = sh.hobby_id
WHERE finished_at IS null
GROUP BY h.name,substr(n_group::varchar, 1, 1)) bd1,
(SELECT  n_course, MAX(count)
FROM (SELECT h.name,substr(n_group::varchar, 1, 1) as n_course,count(substr(n_group::varchar, 1, 1))
FROM student st
INNER JOIN student_hobby sh ON st.id = sh.student_id
INNER JOIN hobby h ON h.id = sh.hobby_id
WHERE finished_at IS null
GROUP BY h.name,substr(n_group::varchar, 1, 1)
) bd
GROUP BY n_course) bd2
WHERE bd1.n_course = bd2.n_course and bd1.count = bd2.max
ORDER BY n_course
--24 Представление: для каждого курса подсчитать количество студентов на курсе и количество отличников.
CREATE OR REPLACE VIEW view4 AS
SELECT substr(n_group::varchar, 1, 1) as n_course, count(substr(n_group::varchar, 1, 1))
FROM student st
GROUP BY substr(n_group::varchar, 1, 1)
--25 Представление: самое популярное хобби среди всех студентов.
SELECT name
FROM
(SELECT h.name, count(h.name)
FROM student st
INNER JOIN student_hobby sh ON st.id = sh.student_id
INNER JOIN hobby h ON h.id = sh.hobby_id
WHERE finished_at IS null
GROUP BY h.name)bd1,
(SELECT MAX(count)
FROM
(SELECT h.name, count(h.name)
FROM student st
INNER JOIN student_hobby sh ON st.id = sh.student_id
INNER JOIN hobby h ON h.id = sh.hobby_id
WHERE finished_at IS null
GROUP BY h.name) bd) bd2
WHERE bd1.count = bd2.max
--26 Создать обновляемое представление.
CREATE OR REPLACE VIEW V2 AS
SELECT id, surname, name, n_group FROM student
WITH CHECK OPTION;
--36 Выведите на экран сколько дней в апреле 2018 года.
SELECT '2018-05-01'::TIMESTAMPTZ-'2018-04-01'::TIMESTAMPTZ as days
