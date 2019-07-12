1
SELECT imie_wroga "WROG", opis_incydentu "PRZEWINA" 
FROM wrogowie_kocurow
WHERE data_incydentu BETWEEN '2009-01-01' AND '2009-12-31';


2
SELECT imie, funkcja, w_stadku_od "Z NAMI OD"
FROM kocury
WHERE plec = 'D' AND w_stadku_od BETWEEN '2005-09-01' AND '2007-07-31'; 


3
SELECT imie_wroga "WROG", gatunek, stopien_wrogosci
FROM wrogowie
WHERE lapowka IS NULL
ORDER BY stopien_wrogosci;


4
SELECT imie || ' zwany ' || pseudo || ' (fun. ' || funkcja ||
') lowi myszki w bandzie ' || nr_bandy || ' od ' || w_stadku_od "WSZYSTKO O KOCURACH"
FROM kocury
WHERE plec = 'M'
ORDER BY w_stadku_od DESC, pseudo;


5
SELECT pseudo, regexp_REPLACE(regexp_REPLACE(pseudo, 'A', '#',1 ,1 ), 'L', '%',1 ,1 ) "Po wymianie A na # oraz L na %"
FROM kocury
WHERE pseudo LIKE '%A%' AND pseudo LIKE '%L%';


6
SELECT imie, w_stadku_od "W stadku", ROUND(przydzial_myszy / 1.1) "Zjadal", Add_Months(w_stadku_od, 6) "Podwyzka", przydzial_myszy "Zjada"
FROM kocury
WHERE EXTRACT(month from w_stadku_od) BETWEEN 3 AND 9 AND Add_Months(w_stadku_od, 9*12) <= '2018-06-20'
ORDER BY przydzial_myszy DESC;


7
SELECT imie, przydzial_myszy * 3 "Myszy kwartalnie", NVL(myszy_extra, 0) * 3 "Kwartalne dodatki"
FROM kocury
WHERE przydzial_myszy >= 55 AND przydzial_myszy > NVL(myszy_extra, 0) * 2
ORDER BY 2 DESC;


8
SELECT pseudo, (CASE WHEN (NVL(myszy_extra, 0) * 12 + przydzial_myszy * 12) = 660 THEN 'Limit' 
            WHEN (NVL(myszy_extra, 0) * 12 + przydzial_myszy * 12) < 660 THEN 'Ponizej 660' 
            ELSE TO_CHAR(NVL(myszy_extra, 0) * 12 + przydzial_myszy * 12) END) "Zjada rocznie"
FROM kocury
ORDER BY imie;


9
SELECT pseudo, w_stadku_od "W Stadku", CASE WHEN To_Char(w_stadku_od,'dd') <= 15 AND NEXT_DAY(LAST_DAY('2018-09-25') - INTERVAL '7' DAY, 3) >= '2018-09-25'
                                            THEN NEXT_DAY(LAST_DAY('2018-09-25') - INTERVAL '7' DAY, 3)
                                            ELSE NEXT_DAY(LAST_DAY(ADD_MONTHS('2018-09-25',1)) - INTERVAL '7' DAY, 3) END "Wyplata"
FROM kocury
ORDER BY w_stadku_od;


10a
SELECT pseudo || ' - ' || CASE WHEN COUNT(DISTINCT pseudo) = COUNT(pseudo) THEN 'unikalny' ELSE 'nieunikalny' END "Unikalnosc atr. PSEUDO"
FROM kocury
GROUP BY pseudo;


10b
SELECT szef || ' - ' || CASE WHEN COUNT(DISTINCT szef) = COUNT(szef) THEN 'unikalny' ELSE 'nieunikalny' END "Unikalnosc atr. SZEF"
FROM kocury
WHERE szef IS NOT NULL
GROUP BY szef;


11
SELECT pseudo, COUNT(*) "Liczba wrogow"
FROM wrogowie_kocurow
GROUP BY pseudo
HAVING COUNT(*) = 2;


12
SELECT 'Liczba kotow=' " ", COUNT(*) " ", 'lowi jako' " ", funkcja " ", 'i zjada max.' " ", MAX(przydzial_myszy + NVL(myszy_extra, 0)) " ", 'myszy miesiecznie' " "
FROM kocury
WHERE plec = 'D' AND funkcja != 'szefunio'
GROUP BY funkcja
HAVING AVG(przydzial_myszy + NVL(myszy_extra, 0)) > 50;


13
SELECT nr_bandy, plec, MIN(przydzial_myszy)
FROM kocury
GROUP BY nr_bandy, plec;


14
SELECT level "Poziom", pseudo "Pseudonim", funkcja, nr_bandy
FROM kocury
WHERE plec = 'M'
CONNECT BY PRIOR pseudo = szef
START WITH funkcja IN ('BANDZIOR');


15
SELECT LPAD('==>==>==>', 3 * (level-1)) || TO_CHAR(level-1) "Hierarchia", LPAD('   ', 3 * (level-1)) || imie " ", NVL(szef, 'sam sobie panem') " ", funkcja
FROM Kocury
WHERE myszy_extra IS NOT NULL
CONNECT BY PRIOR pseudo = szef
START WITH szef IS NULL;


16
SELECT LPAD(' ', 2 * (LEVEL-1)) || pseudo "Droga sluzbowa"
FROM Kocury
CONNECT BY PRIOR szef = pseudo
START WITH plec = 'M' AND Add_Months(w_stadku_od, 9*12) <= '2018-06-20' AND NVL(myszy_extra, 0) = 0;


17
SELECT K.pseudo "POLUJE W POLU", K.przydzial_myszy, B.nazwa
FROM Kocury K JOIN Bandy B ON K.nr_bandy = B.nr_bandy
WHERE K.przydzial_myszy > 50 AND (teren = 'POLE' OR teren = 'CALOSC');


18
SELECT K1.imie, K1.w_stadku_od
FROM Kocury K1, Kocury K2
WHERE K2.imie = 'JACEK' AND K1.w_stadku_od < K2.w_stadku_od
ORDER BY K1.w_stadku_od DESC;


19a
SELECT K.imie || '|', K.funkcja || '|', NVL(K1.imie, ' ') || '|' "Szef 1",  NVL(K2.imie, ' ') || '|' "Szef 2", NVL(K3.imie, ' ') || '|' "Szef 3"
FROM Kocury K LEFT JOIN Kocury K1 ON K.szef = K1.pseudo LEFT JOIN Kocury K2 ON K1.szef = K2.pseudo LEFT JOIN Kocury K3 ON K2.szef = K3.pseudo
WHERE K.funkcja = 'MILUSIA' OR K.funkcja = 'KOT';


19b
SELECT *
FROM(SELECT connect_by_root imie, connect_by_root funkcja, level as n, imie
     FROM Kocury 
     CONNECT BY pseudo = PRIOR szef
     START WITH funkcja = 'MILUSIA' OR funkcja = 'KOT')
PIVOT(
    MAX(imie)
    FOR n
    IN(2 AS szef1, 3 AS szef2, 4 AS szef3));


19c
SELECT connect_by_root imie,
       connect_by_root funkcja,
       substr(sys_connect_by_path(imie, '|'), length(connect_by_root imie) + 2),
       regexp_substr(sys_connect_by_path(imie, '>'), '[^>]+', 1, 2) szef1,
       regexp_substr(sys_connect_by_path(imie, '>'), '[^>]+', 1, 3) szef2,
       regexp_substr(sys_connect_by_path(imie, '>'), '[^>]+', 1, 4) szef3
FROM Kocury
WHERE connect_by_isleaf = 1
CONNECT BY pseudo = PRIOR szef
START WITH funkcja = 'MILUSIA' OR funkcja = 'KOT';


20
SELECT K.imie "Imie kotki", B.nazwa, WK.imie_wroga, W.stopien_wrogosci, WK.data_incydentu
FROM Wrogowie_Kocurow WK LEFT JOIN Kocury K ON WK.pseudo = K.pseudo LEFT JOIN Bandy B ON K.nr_bandy = B.nr_bandy LEFT JOIN Wrogowie W ON W.imie_wroga = WK.imie_wroga
WHERE WK.data_incydentu > '2007-01-01' AND K.plec = 'D'
ORDER BY K.imie;


21
SELECT B.nazwa, COUNT(DISTINCT K.imie)
FROM Wrogowie_kocurow WK LEFT JOIN Kocury K ON WK.pseudo = K.pseudo LEFT JOIN Bandy B ON K.nr_bandy = B.nr_bandy
GROUP BY B.nazwa;


22
SELECT MIN(K.funkcja), K.pseudo, COUNT(DISTINCT WK.imie_wroga)
FROM Wrogowie_kocurow WK LEFT JOIN Kocury K ON WK.pseudo = K.pseudo
GROUP BY WK.pseudo, K.pseudo
HAVING COUNT(DISTINCT WK.imie_wroga) > 1;


23
SELECT imie, 12 * przydzial_myszy + 12 * NVL(myszy_extra, 0) "Dawka roczna", 'powyzej 864' "Dawka"
FROM Kocury
WHERE 12 * przydzial_myszy + 12 * NVL(myszy_extra, 0) > 864 AND myszy_extra IS NOT NULL
UNION SELECT imie, 12 * przydzial_myszy + 12 * NVL(myszy_extra, 0) "Dawka roczna", '864' "Dawka"
FROM Kocury
WHERE 12 * przydzial_myszy + 12 * NVL(myszy_extra, 0) = 864 AND myszy_extra IS NOT NULL
UNION SELECT imie, 12 * przydzial_myszy + 12 * NVL(myszy_extra, 0) "Dawka roczna", 'ponizej 864' "Dawka"
FROM Kocury
WHERE 12 * przydzial_myszy + 12 * NVL(myszy_extra, 0) < 864 AND myszy_extra IS NOT NULL
ORDER BY 2 DESC;


24
SELECT B.nr_bandy, MIN(B.nazwa), MIN(B.Teren)
FROM Bandy B LEFT JOIN Kocury K ON B.nr_bandy = K.nr_bandy
GROUP BY B.nr_bandy, K.nr_bandy
HAVING COUNT(K.pseudo) = 0;


SELECT B.nr_bandy, B.nazwa, B.teren
FROM Bandy B
MINUS
SELECT B.nr_bandy, B.nazwa, B.teren
FROM Bandy B LEFT JOIN  Kocury ON Kocury.nr_bandy = B.nr_bandy
WHERE Kocury.nr_bandy IS NOT NULL;
    
    
25
SELECT pseudo, funkcja, przydzial_myszy
FROM Kocury 
WHERE przydzial_myszy >= 3 * (SELECT K.przydzial_myszy
                             FROM Kocury K LEFT JOIN Bandy B ON K.nr_bandy = B.nr_bandy
                             WHERE K.funkcja = 'MILUSIA' AND B.teren IN ('SAD', 'CALOSC')  AND K.przydzial_myszy >= ALL(SELECT K.przydzial_myszy
                                                                                                                        FROM Kocury K LEFT JOIN Bandy B ON K.nr_bandy = B.nr_bandy
                                                                                                                        WHERE K.funkcja = 'MILUSIA' AND B.teren IN ('SAD', 'CALOSC')));
                                                                                                    
                                                                                                    
26
SELECT funkcja, ROUND(AVG(przydzial_myszy + NVL(myszy_extra, 0)))
FROM Kocury
WHERE funkcja != 'SZEFUNIO'
GROUP BY funkcja
HAVING AVG(przydzial_myszy + NVL(myszy_extra, 0)) >= ALL(SELECT AVG(przydzial_myszy + NVL(myszy_extra, 0))
                                                         FROM Kocury
                                                         WHERE funkcja != 'SZEFUNIO'
                                                         GROUP BY funkcja)
        OR AVG(przydzial_myszy + NVL(myszy_extra, 0)) <= ALL(SELECT AVG(przydzial_myszy + NVL(myszy_extra, 0))
                                                             FROM Kocury
                                                             WHERE funkcja != 'SZEFUNIO'
                                                             GROUP BY funkcja);
                                                             
                                                             
27a
SELECT pseudo, przydzial_myszy + NVL(myszy_extra,0) "ZJADA"
FROM Kocury K
WHERE &n > (SELECT COUNT(DISTINCT  K2.przydzial_myszy + NVL(K2.myszy_extra,0))
             FROM Kocury K2
             WHERE K.przydzial_myszy + NVL(K.myszy_extra,0) < K2.przydzial_myszy + NVL(K2.myszy_extra,0))
ORDER BY 2 DESC;


27b
SELECT pseudo, przydzial_myszy + NVL(myszy_extra,0) "ZJADA"
FROM Kocury
WHERE przydzial_myszy + NVL(myszy_extra,0) >= ( SELECT szukana 
                                                FROM (SELECT rownum numer, szukana 
                                                      FROM (SELECT DISTINCT NVL(przydzial_myszy,0) + NVL(myszy_extra,0) szukana
                                                            FROM Kocury
                                                            ORDER BY szukana DESC
                                                           )
                                                     ) 
                                                WHERE numer=&n
                                              )
ORDER BY "ZJADA" DESC;


27c
SELECT Kocury.pseudo "PSEUDO", NVL(Kocury.przydzial_myszy,0) + NVL(Kocury.myszy_extra,0) "ZJADA"
FROM Kocury, Kocury Kocury2
WHERE NVL(Kocury.przydzial_myszy,0) + NVL(Kocury.myszy_extra,0) <= NVL(Kocury2.przydzial_myszy,0) + NVL(Kocury2.myszy_extra,0)
GROUP BY Kocury.pseudo, NVL(Kocury.przydzial_myszy,0) + NVL(Kocury.myszy_extra,0)
HAVING COUNT(DISTINCT NVL(Kocury2.przydzial_myszy,0) + NVL(Kocury2.myszy_extra,0)) <= &n
ORDER BY "ZJADA" DESC;


27d
SELECT imie, "ZJADA"
FROM (SELECT imie, "ZJADA",
               DENSE_RANK()         
               OVER(ORDER BY ("ZJADA") DESC) pozycja
               FROM (SELECT imie, przydzial_myszy + NVL(myszy_extra,0) "ZJADA"
                     FROM Kocury))
WHERE pozycja<=&n;


28
SELECT TO_CHAR(EXTRACT(YEAR FROM w_stadku_od)) "ROK", COUNT(pseudo) "LICZBA WSTAPIEN"
FROM Kocury
GROUP BY EXTRACT(YEAR FROM w_stadku_od)
HAVING COUNT(pseudo) = (SELECT * 
                        FROM ( SELECT COUNT(pseudo) 
                               FROM Kocury
                               GROUP BY EXTRACT(YEAR FROM w_stadku_od)
                               HAVING COUNT(pseudo) >= (SELECT AVG(COUNT(pseudo)) FROM Kocury GROUP BY EXTRACT(YEAR FROM w_stadku_od))
                               ORDER BY COUNT(pseudo) ASC) 
                        WHERE rownum=1)
UNION ALL 
SELECT 'Srednia' "ROK", ROUND(AVG(COUNT(pseudo)),2)  "LICZBA WSTAPIEN"
FROM Kocury
GROUP BY EXTRACT(YEAR FROM w_stadku_od)
UNION ALL 
SELECT TO_CHAR(EXTRACT(YEAR FROM w_stadku_od)) "ROK", COUNT(pseudo) "LICZBA WSTAPIEN"
FROM Kocury
GROUP BY EXTRACT(YEAR FROM w_stadku_od)
HAVING COUNT(pseudo) = ( SELECT * 
                         FROM (SELECT COUNT(pseudo) 
                               FROM Kocury
                               GROUP BY EXTRACT(YEAR FROM w_stadku_od)
                               HAVING COUNT(pseudo) <= (SELECT AVG(COUNT(pseudo)) FROM Kocury GROUP BY EXTRACT(YEAR FROM w_stadku_od))
                               ORDER BY COUNT(pseudo) DESC)
                         WHERE rownum=1);


29a----------------------------------------------------------------------------------------------------------------------------
SELECT K.imie, MIN(K.przydzial_myszy + NVL(K.myszy_extra, 0)), MIN(K.nr_bandy), AVG(K2.przydzial_myszy + NVL(K2.myszy_extra, 0))
FROM Kocury K JOIN Kocury K2 ON K.nr_bandy = K2.nr_bandy
WHERE K.plec = 'M'
GROUP BY K.imie
HAVING MIN(K.przydzial_myszy + NVL(K.myszy_extra, 0)) <= AVG(K2.przydzial_myszy + NVL(K2.myszy_extra, 0));


29b----------------------------------------------------------------------------------------------------------------------------
SELECT K.imie, K.funkcja, K.przydzial_myszy + NVL(K.myszy_extra, 0), S.srednia
FROM Kocury K LEFT JOIN (SELECT nr_bandy, (AVG(przydzial_myszy + NVL(myszy_extra, 0))) srednia
                         FROM Kocury
                         GROUP BY nr_bandy) S ON K.nr_bandy = S.nr_bandy
WHERE K.plec = 'M' AND K.przydzial_myszy + NVL(K.myszy_extra, 0) <= S.srednia;


29c----------------------------------------------------------------------------------------------------------------------------
SELECT imie, funkcja, przydzial_myszy + NVL(myszy_extra, 0), (SELECT (AVG(przydzial_myszy + NVL(myszy_extra, 0)))
                                                              FROM Kocury k
                                                              WHERE k.nr_bandy = k2.nr_bandy
                                                              GROUP BY k.nr_bandy) "srednia"
FROM Kocury k2
WHERE plec = 'M' AND przydzial_myszy + NVL(myszy_extra, 0) <= (SELECT (AVG(przydzial_myszy + NVL(myszy_extra, 0))) srednia
                                                               FROM Kocury k
                                                               WHERE k.nr_bandy = k2.nr_bandy
                                                               GROUP BY k.nr_bandy);


30-----------------------------------------------------------------------------------------------------------------------------
SELECT K.imie, K.w_stadku_od || '<---', 'NAJMLODSZY STAZEM W BANDZIE ' || B.nazwa
FROM Kocury K LEFT JOIN Bandy B ON K.nr_bandy = B.nr_bandy
WHERE K.w_stadku_od = (SELECT MAX(w_stadku_od)
                       FROM Kocury K2
                       WHERE K2.nr_bandy = K.nr_bandy
                       GROUP BY K2.nr_bandy)
UNION ALL SELECT K.imie, K.w_stadku_od || '<---', 'NAJSTRASZY STAZEM W BANDZIE ' || B.nazwa
FROM Kocury K LEFT JOIN Bandy B ON K.nr_bandy = B.nr_bandy
WHERE K.w_stadku_od = (SELECT MIN(w_stadku_od)
                       FROM Kocury K2
                       WHERE K2.nr_bandy = K.nr_bandy
                       GROUP BY K2.nr_bandy)
UNION ALL SELECT K.imie, K.w_stadku_od || ' ', ' '
FROM Kocury K LEFT JOIN Bandy B ON K.nr_bandy = B.nr_bandy
WHERE K.w_stadku_od != (SELECT MAX(w_stadku_od)
                       FROM Kocury K2
                       WHERE K2.nr_bandy = K.nr_bandy
                       GROUP BY K2.nr_bandy)
  AND K.w_stadku_od != (SELECT MIN(w_stadku_od)
                       FROM Kocury K2
                       WHERE K2.nr_bandy = K.nr_bandy
                       GROUP BY K2.nr_bandy);


31-----------------------------------------------------------------------------------------------------------------------------
DROP VIEW perspektywa1;

CREATE VIEW perspektywa1
AS SELECT B.nazwa "NAZWA_BANDY", AVG(przydzial_myszy) "SRE_SPOZ", MAX(przydzial_myszy) "MAX_SPOZ", MIN(przydzial_myszy)"MIN_SPOZ", COUNT(pseudo) "KOTY", COUNT(myszy_extra) "KOTY_Z_DOD"
FROM Bandy B LEFT JOIN Kocury K ON B.nr_bandy = K.nr_bandy
GROUP BY B.nazwa;

SELECT * FROM perspektywa1;

SELECT K.pseudo, K.imie, K.funkcja, K.przydzial_myszy,  'OD ' || MIN_SPOZ || ' DO ' || MAX_SPOZ, K.w_stadku_od
FROM Kocury K LEFT JOIN Bandy B ON K.nr_bandy = B.nr_bandy LEFT JOIN perspektywa1 P ON B.nazwa = P.nazwa_bandy
WHERE pseudo = '&x';

32-----------------------------------------------------------------------------------------------------------------------------
SELECT pseudo, plec, przydzial_myszy "PRZYDZIAL_PRZED POD", NVL(myszy_extra, 0) "EXTRA_PRZED_POD"
FROM Kocury 
WHERE pseudo IN((SELECT pseudo 
                FROM (SELECT pseudo
                      FROM Kocury K LEFT JOIN Bandy B ON K.nr_bandy = B.nr_bandy
                      WHERE B.nazwa = 'CZARNI RYCERZE'
                      ORDER BY w_stadku_od)
                WHERE rownum <= 3)
                UNION ALL (SELECT pseudo 
                       FROM (SELECT pseudo
                             FROM Kocury K LEFT JOIN Bandy B ON K.nr_bandy = B.nr_bandy
                             WHERE B.nazwa = 'LACIACI MYSLIWI'
                             ORDER BY w_stadku_od)
                       WHERE rownum <= 3));

SET AUTOCOMMIT OFF;

UPDATE Kocury
SET przydzial_myszy = CASE plec
                      WHEN 'M' THEN przydzial_myszy + 10
                      WHEN 'D' THEN przydzial_myszy + ROUND(0.1 * (SELECT MIN(NVL(K.przydzial_myszy, 0)) 
                                                             FROM Kocury K ))
                      END, myszy_extra = NVL(myszy_extra, 0) + ROUND(0.15 * (SELECT AVG(NVL(K.myszy_extra, 0)) 
                                                               FROM Kocury K 
                                                               WHERE Kocury.nr_bandy = K.nr_bandy))
WHERE pseudo IN ((SELECT pseudo 
                FROM (SELECT pseudo
                      FROM Kocury K LEFT JOIN Bandy B ON K.nr_bandy = B.nr_bandy
                      WHERE B.nazwa = 'CZARNI RYCERZE'
                      ORDER BY w_stadku_od)
                WHERE rownum <= 3)
                UNION ALL(SELECT pseudo 
                       FROM (SELECT pseudo
                             FROM Kocury K LEFT JOIN Bandy B ON K.nr_bandy = B.nr_bandy
                             WHERE B.nazwa = 'LACIACI MYSLIWI'
                             ORDER BY w_stadku_od)
                       WHERE rownum <= 3));

SELECT pseudo, plec, przydzial_myszy "PRZYDZIAL_PO POD", NVL(myszy_extra, 0) "EXTRA_PO_POD", nr_bandy
FROM Kocury K
WHERE K.nr_bandy IN (2 ,4) AND 3 > (SELECT COUNT(DISTINCT K2.w_stadku_od)
                                FROM Kocury K2
                                WHERE K2.nr_bandy = K.nr_bandy AND K.w_stadku_od > K2.w_stadku_od);
                     
ROLLBACK;
SET AUTOCOMMIT ON;


33a----------------------------------------------------------------------------------------------------------------------------
SELECT * FROM (
SELECT
  DECODE(plec, 'M', ' ', 'D', nazwa) "NAZWA BANDY",
  DECODE(plec, 'M', 'Kocur', 'D', 'Kotka') "PLEC",
  TO_CHAR(count(*)) "ILE",
  SUM(DECODE(funkcja, 'SZEFUNIO', NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0), 0)) "SZEFUNIO",
  SUM(DECODE(funkcja, 'BANDZIOR', NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0), 0)) "BANDZIOR",
  SUM(DECODE(funkcja, 'LOWCZY', NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0), 0)) "LOWCZY",
  SUM(DECODE(funkcja, 'LAPACZ', NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0), 0)) "LAPACZ",
  SUM(DECODE(funkcja, 'KOT', NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0), 0)) "KOT",
  SUM(DECODE(funkcja, 'MILUSIA', NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0), 0)) "MILUSIA",
  SUM(DECODE(funkcja, 'DZIELCZY', NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0), 0)) "DZIELCZY",
  SUM(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)) "SUMA"
FROM
  Kocury
LEFT JOIN Bandy ON Kocury.nr_bandy = Bandy.nr_bandy
GROUP BY
  nazwa, plec
ORDER BY nazwa ASC )
UNION ALL SELECT
  'ZJADA RAZEM', ' ', ' ',
  SUM(DECODE(funkcja, 'SZEFUNIO', NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0), 0)) "SZEFUNIO",
  SUM(DECODE(funkcja, 'BANDZIOR', NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0), 0)) "BANDZIOR",
  SUM(DECODE(funkcja, 'LOWCZY', NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0), 0)) "LOWCZY",
  SUM(DECODE(funkcja, 'LAPACZ', NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0), 0)) "LAPACZ",
  SUM(DECODE(funkcja, 'KOT', NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0), 0)) "KOT",
  SUM(DECODE(funkcja, 'MILUSIA', NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0), 0)) "MILUSIA",
  SUM(DECODE(funkcja, 'DZIELCZY', NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0), 0)) "DZIELCZY",
  SUM(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)) "SUMA"
FROM Kocury;


33b----------------------------------------------------------------------------------------------------------------------------
SELECT naz, pl, il, "SZEFUNIO", "BANDZIOR", "LAPACZ", "LOWCZY", "KOT", "DZIELCZY", "MILUSIA", razem FROM(
SELECT a1.nazwa, DECODE(a1.plec, 'M', a1.nazwa, 'D', ' ') naz, pl, TO_CHAR(ile) il, "SZEFUNIO", "BANDZIOR", "LAPACZ", "LOWCZY", "KOT", "DZIELCZY", "MILUSIA", razem
FROM (( SELECT nazwa, plec, DECODE(plec, 'M', 'Kocur', 'D', 'Kotka') pl, funkcja, NVL(przydzial_myszy,0)+NVL(myszy_extra,0) myszy_calk
       FROM Kocury LEFT JOIN Bandy ON Kocury.nr_bandy = Bandy.nr_bandy)
PIVOT(
SUM(myszy_calk)
FOR funkcja
IN('SZEFUNIO' "SZEFUNIO", 'BANDZIOR' "BANDZIOR", 'LOWCZY' "LOWCZY", 'LAPACZ' "LAPACZ",  'KOT' "KOT", 'MILUSIA' "MILUSIA", 'DZIELCZY' "DZIELCZY"))) a1
LEFT JOIN (SELECT nazwa, plec, count(*) ile, SUM(przydzial_myszy + NVL(myszy_extra, 0)) razem
            FROM Kocury LEFT JOIN Bandy ON Kocury.nr_bandy = Bandy.nr_bandy 
            GROUP BY nazwa, plec) a2 ON a1.nazwa = a2.nazwa AND a1.plec = a2.plec
UNION ALL SELECT
  'z', 'ZJADA RAZEM', ' ', ' ',
  SUM(DECODE(funkcja, 'SZEFUNIO', NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0), 0)) "SZEFUNIO",
  SUM(DECODE(funkcja, 'BANDZIOR', NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0), 0)) "BANDZIOR",
  SUM(DECODE(funkcja, 'LAPACZ', NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0), 0)) "LAPACZ",
  SUM(DECODE(funkcja, 'LOWCZY', NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0), 0)) "LOWCZY",
  SUM(DECODE(funkcja, 'KOT', NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0), 0)) "KOT",
  SUM(DECODE(funkcja, 'DZIELCZY', NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0), 0)) "DZIELCZY",
  SUM(DECODE(funkcja, 'MILUSIA', NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0), 0)) "MILUSIA",
  SUM(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)) "SUMA"
FROM
  Kocury)
ORDER BY nazwa, pl;


34-----------------------------------------------------------------------------------------------------------------------------
DECLARE
ile_jest NUMBER;
fun Funkcje.funkcja%TYPE;
BEGIN
    SELECT count(*), MIN(funkcja)
    INTO ile_jest, fun
    FROM Kocury
    WHERE funkcja = '&funkcja';
    IF ile_jest > 0 THEN 
        DBMS_OUTPUT.PUT_LINE('Znaleziono kota pelniacego funkcje ' || fun);
    ELSE
        DBMS_OUTPUT.PUT_LINE('Nie znaleziono kota pelniacego taka funkcje');
    END IF;
END;

SET SERVEROUTPUT ON;


35-----------------------------------------------------------------------------------------------------------------------------
DECLARE
    pseudo Kocury.pseudo%TYPE;
    imie Kocury.imie%TYPE;
    data_przystapienia Kocury.w_stadku_od%TYPE;
    roczny_przydzial NUMBER(4);
    przynajmniej_jedno_wystapilo BOOLEAN:=false;
BEGIN
    SELECT pseudo, imie, w_stadku_od, 12* NVL(przydzial_myszy, 0) + 12*NVL(myszy_extra, 0) 
    INTO pseudo, imie, data_przystapienia, roczny_przydzial
    FROM Kocury
    WHERE pseudo = '&pseudo';
    IF roczny_przydzial > 700 THEN 
        DBMS_OUTPUT.PUT_LINE(pseudo || ' calkowity roczny przydzial myszy>700');
        przynajmniej_jedno_wystapilo:= TRUE;
    END IF;
    IF imie LIKE '%A%' THEN
        DBMS_OUTPUT.PUT_LINE(pseudo || ' imie zawiera litere A');
        przynajmniej_jedno_wystapilo:= TRUE;
    END IF;
    IF EXTRACT(MONTH from data_przystapienia) = 1 THEN
        DBMS_OUTPUT.PUT_LINE(pseudo || ' styczen jest miesiacem przystapienia do stada');
        przynajmniej_jedno_wystapilo:= TRUE;
    END IF;
    IF  NOT przynajmniej_jedno_wystapilo THEN
        DBMS_OUTPUT.PUT_LINE(pseudo || ' nie odpowiada kryteriom');
    END IF;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Nie ma takiego kota');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;

SET AUTOCOMMIT OFF;


36-----------------------------------------------------------------------------------------------------------------------------
DECLARE
    sum_w_stadzie NUMBER(4):= 0;
    CURSOR koty IS SELECT * FROM Kocury ORDER BY przydzial_myszy FOR UPDATE OF przydzial_myszy;
    podwyzka NUMBER(3);
    max_mys NUMBER(3);
BEGIN
    FOR kot IN koty
    LOOP
        sum_w_stadzie:= sum_w_stadzie + NVL(kot.przydzial_myszy, 0);
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('Suma przed podwyzka: ' || sum_w_stadzie);
    
    LOOP
        IF sum_w_stadzie > 1050 THEN EXIT;
        END IF;
        FOR kot IN koty
        LOOP
            SELECT max_myszy INTO max_mys FROM Funkcje WHERE funkcja = kot.funkcja;
            IF NVL(kot.przydzial_myszy, 0) * 1.1 > max_mys THEN
                podwyzka:= max_mys;
            ELSE
                podwyzka:= NVL(kot.przydzial_myszy, 0) * 1.1;
            END IF;
            
            sum_w_stadzie:= sum_w_stadzie + (podwyzka - NVL(kot.przydzial_myszy, 0));
            
            UPDATE Kocury
            SET przydzial_myszy = podwyzka
            WHERE pseudo = kot.pseudo;
            
            IF sum_w_stadzie > 1050 THEN EXIT;
            END IF;
        END LOOP;  
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('Suma po podwyzce: ' || sum_w_stadzie);
END;

SELECT imie, NVL(przydzial_myszy,0) "Myszki po podwyzce" FROM Kocury;

ROLLBACK;


37-----------------------------------------------------------------------------------------------------------------------------
DECLARE
    licznik NUMBER(3):= 0;
    CURSOR koty IS SELECT pseudo, przydzial_myszy + NVL(myszy_extra, 0) as przydzial FROM Kocury  ORDER BY przydzial DESC;
    poprzedni_kot koty%ROWTYPE;
BEGIN
    FOR kot IN Koty
    LOOP
        IF licznik > 4 AND kot.przydzial != poprzedni_kot.przydzial THEN
            EXIT;
        ELSE
            DBMS_OUTPUT.PUT_LINE(kot.pseudo || ' ' || kot.przydzial);
        END IF;
        IF licznik > 0 THEN
            poprzedni_kot:= kot;
        END IF;
        licznik:= licznik + 1;
    END LOOP;
END;
            
            
38-----------------------------------------------------------------------------------------------------------------------------
DECLARE
    aktualny_poziom NUMBER(3);
    zadany_poziom NUMBER(3):= &n;
    max_poziom NUMBER(3);
    CURSOR koty IS SELECT pseudo, imie, szef FROM Kocury WHERE funkcja = 'MILUSIA' OR funkcja = 'KOT';
    aktualny_kot koty%ROWTYPE;
BEGIN
    SELECT MAX(level)-1 INTO max_poziom FROM Kocury CONNECT BY pseudo = PRIOR szef START WITH funkcja = 'MILUSIA' OR funkcja = 'KOT'; 
    IF zadany_poziom < max_poziom THEN
        max_poziom:= zadany_poziom;
    END IF;
    
    DBMS_OUTPUT.PUT('  |  ' || RPAD( 'Imie', 10));
    FOR i IN 1..max_poziom 
    LOOP
        DBMS_OUTPUT.PUT('|  ' || RPAD('Szef ' || i, 10));
    END LOOP;
    
    FOR kot IN koty
    LOOP
        aktualny_poziom:= 0;
        aktualny_kot:= kot;
        DBMS_OUTPUT.NEW_LINE();
        LOOP
            DBMS_OUTPUT.PUT('|  ' || RPAD(aktualny_kot.imie, 10));
            IF aktualny_kot.szef IS NULL OR aktualny_poziom = max_poziom THEN
                EXIT;
            ELSE
                aktualny_poziom:= aktualny_poziom + 1;
                SELECT pseudo, imie, szef INTO aktualny_kot FROM Kocury WHERE pseudo = aktualny_kot.szef;
            END IF;
        END LOOP;
    END LOOP;
    DBMS_OUTPUT.NEW_LINE();
END;

SET SERVEROUTPUT ON;
39-----------------------------------------------------------------------------------------------------------------------------
DECLARE
    nr_ban Bandy.nr_bandy%TYPE:= &numer;
    nazwa_ban Bandy.nazwa%TYPE:= '&nazwa';
    teren_ban Bandy.teren%TYPE:= '&teren';
    liczba_wystapien NUMBER(3):= 0;
    blad_do_wyswietlenia STRING(256);
    wystapil_blad BOOLEAN:= FALSE;
    wystapilo_powtorzenie BOOLEAN:= FALSE;
    ERR_WYSTAPIL_BLAD EXCEPTION;
    ERR_WYSTAPILO_POWTORZENIE EXCEPTION;
BEGIN
    IF nr_ban <= 0 THEN 
        wystapil_blad:= TRUE;
        blad_do_wyswietlenia:= nr_ban || ': ujemny numer';
    END IF;
    
    SELECT COUNT(*) INTO liczba_wystapien FROM Bandy WHERE nr_bandy = nr_ban;
    
    IF liczba_wystapien > 0 THEN
        wystapilo_powtorzenie:= TRUE;
        IF NOT wystapil_blad THEN 
            wystapil_blad:= TRUE;
            blad_do_wyswietlenia:= blad_do_wyswietlenia || nr_ban;
        ELSE
            blad_do_wyswietlenia:= blad_do_wyswietlenia || ', ' || nr_ban;
        END IF;
    END IF;
    
    SELECT COUNT(*) INTO liczba_wystapien FROM Bandy WHERE nazwa = nazwa_ban;
    
    IF liczba_wystapien > 0 THEN 
        IF NOT wystapilo_powtorzenie THEN
            wystapilo_powtorzenie:= TRUE;
        END IF;
        IF NOT wystapil_blad THEN 
            wystapil_blad:= TRUE;
            blad_do_wyswietlenia:= blad_do_wyswietlenia || nazwa_ban;
        ELSE
            blad_do_wyswietlenia:= blad_do_wyswietlenia || ', ' || nazwa_ban;
        END IF;
    END IF;
        
    SELECT COUNT(*) INTO liczba_wystapien FROM Bandy WHERE teren = teren_ban;
    
    IF liczba_wystapien > 0 THEN 
        IF NOT wystapilo_powtorzenie THEN
            wystapilo_powtorzenie:= TRUE;
        END IF;
        IF NOT wystapil_blad THEN 
            wystapil_blad:= TRUE;
            blad_do_wyswietlenia:= blad_do_wyswietlenia || teren_ban;
        ELSE
            blad_do_wyswietlenia:= blad_do_wyswietlenia || ', ' || teren_ban;
        END IF; 
    END IF;
    
        
    IF wystapilo_powtorzenie THEN
        RAISE ERR_WYSTAPILO_POWTORZENIE;
    END IF;
    
    IF wystapil_blad THEN
        RAISE ERR_WYSTAPIL_BLAD;
    END IF;
    
    INSERT INTO bandy (nr_bandy, nazwa, teren)
    VALUES (nr_ban, nazwa_ban, teren_ban);
    
    EXCEPTION
    WHEN ERR_WYSTAPIL_BLAD
        THEN DBMS_OUTPUT.PUT(blad_do_wyswietlenia);
        DBMS_OUTPUT.NEW_LINE();
    WHEN ERR_WYSTAPILO_POWTORZENIE
        THEN DBMS_OUTPUT.PUT(blad_do_wyswietlenia || ': juz istnieje');
        DBMS_OUTPUT.NEW_LINE();
END;

ROLLBACK;


40 ----------------------------------------------------------------------------------------------------------------------------
DROP PROCEDURE dodaj_bande;
CREATE OR REPLACE PROCEDURE dodaj_bande(nr_ban Bandy.nr_bandy%TYPE, nazwa_ban Bandy.nazwa%TYPE, teren_ban Bandy.teren%TYPE)
IS
    liczba_wystapien NUMBER(3):= 0;
    blad_do_wyswietlenia STRING(256);
    wystapil_blad BOOLEAN:= FALSE;
    wystapilo_powtorzenie BOOLEAN:= FALSE;
    ERR_WYSTAPIL_BLAD EXCEPTION;
    ERR_WYSTAPILO_POWTORZENIE EXCEPTION;
BEGIN
    IF nr_ban <= 0 THEN 
        wystapil_blad:= TRUE;
        blad_do_wyswietlenia:= nr_ban || ': ujemny numer';
    END IF;
    
    SELECT COUNT(*) INTO liczba_wystapien FROM Bandy WHERE nr_bandy = nr_ban;
    
    IF liczba_wystapien > 0 THEN
        wystapilo_powtorzenie:= TRUE;
        IF NOT wystapil_blad THEN 
            wystapil_blad:= TRUE;
            blad_do_wyswietlenia:= blad_do_wyswietlenia || nr_ban;
        ELSE
            blad_do_wyswietlenia:= blad_do_wyswietlenia || ', ' || nr_ban;
        END IF;
    END IF;
    
    SELECT COUNT(*) INTO liczba_wystapien FROM Bandy WHERE nazwa = nazwa_ban;
    
    IF liczba_wystapien > 0 THEN 
        IF NOT wystapilo_powtorzenie THEN
            wystapilo_powtorzenie:= TRUE;
        END IF;
        IF NOT wystapil_blad THEN 
            wystapil_blad:= TRUE;
            blad_do_wyswietlenia:= blad_do_wyswietlenia || nazwa_ban;
        ELSE
            blad_do_wyswietlenia:= blad_do_wyswietlenia || ', ' || nazwa_ban;
        END IF;
    END IF;
        
    SELECT COUNT(*) INTO liczba_wystapien FROM Bandy WHERE teren = teren_ban;
    
    IF liczba_wystapien > 0 THEN 
        IF NOT wystapilo_powtorzenie THEN
            wystapilo_powtorzenie:= TRUE;
        END IF;
        IF NOT wystapil_blad THEN 
            wystapil_blad:= TRUE;
            blad_do_wyswietlenia:= blad_do_wyswietlenia || teren_ban;
        ELSE
            blad_do_wyswietlenia:= blad_do_wyswietlenia || ', ' || teren_ban;
        END IF; 
    END IF;
    
        
    IF wystapilo_powtorzenie THEN
        RAISE ERR_WYSTAPILO_POWTORZENIE;
    END IF;
    
    IF wystapil_blad THEN
        RAISE ERR_WYSTAPIL_BLAD;
    END IF;
    
    INSERT INTO bandy (nr_bandy, nazwa, teren)
    VALUES (nr_ban, nazwa_ban, teren_ban);
    
    EXCEPTION
    WHEN ERR_WYSTAPIL_BLAD
        THEN DBMS_OUTPUT.PUT(blad_do_wyswietlenia);
        DBMS_OUTPUT.NEW_LINE();
    WHEN ERR_WYSTAPILO_POWTORZENIE
        THEN DBMS_OUTPUT.PUT(blad_do_wyswietlenia || ': juz istnieje');
        DBMS_OUTPUT.NEW_LINE();
END;

BEGIN
    DODAJ_BANDE(0, 'NOWA_BANDA', 'PODWORKO');
END;


41-----------------------------------------------------------------------------------------------------------------------------
DROP TRIGGER autoindeksowanie;
CREATE OR REPLACE TRIGGER autoindeksowanie
BEFORE INSERT ON Bandy
FOR EACH ROW
BEGIN
  SELECT MAX(nr_bandy) + 1 INTO :new.nr_bandy FROM Bandy;
END;

SET AUTOCOMMIT OFF;

BEGIN
  DODAJ_BANDE(10, 'NOWA BANDA', 'PODWORKO');
END;

SELECT * FROM Bandy;

ROLLBACK;


42a-----------------------------------------------------------------------------------------------------------------------------
SET AUTOCOMMIT OFF;
DROP TRIGGER Zad42_CompoundTrigger;
DROP PACKAGE zmiennepomocnicze;

CREATE OR REPLACE PACKAGE zmiennepomocnicze AS
  ``przydzial_tygrysa NUMBER:= 0;
 ` `zmiana_przydzialu_na_plus NUMBER:= 0;
    zmiana_przydzialu_na_minus NUMBER:= 0;
END zmiennepomocnicze;

CREATE OR REPLACE TRIGGER Zad42_BeforeUpdate
BEFORE UPDATE OF przydzial_myszy, myszy_extra ON kocury
BEGIN
    SELECT przydzial_myszy INTO zmiennepomocnicze.przydzial_tygrysa FROM Kocury WHERE pseudo = 'TYGRYS';
    zmiennepomocnicze.zmiana_przydzialu_na_plus:= 0;
    zmiennepomocnicze.zmiana_przydzialu_na_minus:= 0;
END;

CREATE OR REPLACE TRIGGER Zad42_BeforeUpdateEachRow
BEFORE UPDATE OF przydzial_myszy,myszy_extra ON Kocury 
FOR EACH ROW WHEN (OLD.funkcja = 'MILUSIA')
DECLARE
    max_mys NUMBER;
BEGIN
    SELECT max_myszy INTO max_mys
    FROM Funkcje WHERE funkcja = :NEW.funkcja;
    
    IF :NEW.przydzial_myszy < :OLD.przydzial_myszy THEN
        :NEW.przydzial_myszy:= :OLD.przydzial_myszy;
        DBMS_OUTPUT.PUT_LINE('Anulowano operacje zmiany przydzialu' || :NEW.pseudo
        || ' z ' || :OLD.przydzial_myszy || ' na ' || :NEW.przydzial_myszy);
    ELSIF (:NEW.przydzial_myszy - :OLD.przydzial_myszy) < zmiennepomocnicze.przydzial_tygrysa * 0.1 THEN
            zmiennepomocnicze.zmiana_przydzialu:= zmiennepomocnicze.zmiana_przydzialu_na_minus + 1;
            :NEW.przydzial_myszy:= :OLD.przydzial_myszy + zmiennepomocnicze.przydzial_tygrysa * 0.1;
            :NEW.myszy_extra:= :OLD.myszy_extra + 5;
            DBMS_OUTPUT.PUT_LINE('Kara dla Tygrysa za zmiane dla kota ' || :new.pseudo
            || ' z ' || :old.przydzial_myszy || ' na ' || :new.przydzial_myszy);
        ELSE
            zmiennepomocnicze.zmiana_przydzialu:= zmiennepomocnicze.zmiana_przydzialu_na_plus + 1;
            DBMS_OUTPUT.PUT_LINE('Nagroda dla Tygrysa za zmiane dla kota ' || :new.pseudo
            || ' z ' || :old.przydzial_myszy || ' na ' || :new.przydzial_myszy);
    END IF;
    
    IF :NEW.przydzial_myszy > max_mys THEN
        :NEW.przydzial_myszy := max_mys;
    END IF;
END;

CREATE OR REPLACE TRIGGER Zad42_AfterUpdate
AFTER UPDATE OF przydzial_myszy,myszy_extra ON Kocury
DECLARE
BEGIN
    IF zmiennepomocnicze.zmiana_przydzialu_na_minus > 0 THEN
        UPDATE Kocury 
        SET przydzial_myszy = przydzial_myszy - (0.1 * zmiennepomocnicze.zmiana_przydzialu_na_minus * przydzial_myszy)
        WHERE pseudo = 'TYGRYS';
        zmiennepomocnicze.zmiana_przydzialu_na_minus:= 0;
    END IF;
    IF zmiennepomocnicze.zmiana_przydzialu_na_plus > 0 THEN
        UPDATE Kocury 
        SET myszy_extra = myszy_extra + zmiennepomocnicze.zmiana_przydzialu_na_plus * 5
        WHERE pseudo = 'TYGRYS';
        zmiennepomocnicze.zmiana_przydzialu_na_plus:= 0;
    END IF;
END;

SELECT pseudo, przydzial_myszy, myszy_extra FROM Kocury;
UPDATE Kocury SET przydzial_myszy = przydzial_myszy + 11;
SELECT pseudo, przydzial_myszy, myszy_extra FROM Kocury;
ROLLBACK;


42b----------------------------------------------------------------------------------------------------------------------------
SET AUTOCOMMIT OFF;
DROP TRIGGER Zad42_BeforeUpdate;
DROP TRIGGER Zad42_BeforeUpdateEachRow;
DROP TRIGGER Zad42_AfterUpdate;
DROP PACKAGE 

CREATE OR REPLACE TRIGGER Zad42_CompoundTrigger
FOR UPDATE OF przydzial_myszy, myszy_extra ON Kocury
COMPOUND TRIGGER
    przydzial_tygrysa NUMBER:= 0;
    zmiana_przydzialu_na_plus NUMBER:= 0;
    zmiana_przydzialu_na_minus NUMBER:= 0;
    max_mys NUMBER;
  
    BEFORE STATEMENT IS BEGIN
        SELECT przydzial_myszy INTO przydzial_tygrysa FROM Kocury WHERE pseudo = 'TYGRYS';
    END BEFORE STATEMENT;
  
    BEFORE EACH ROW IS BEGIN
        SELECT max_myszy INTO max_mys
        FROM Funkcje WHERE funkcja = :NEW.funkcja;
    
        IF :new.funkcja = 'MILUSIA' THEN
            IF :NEW.przydzial_myszy < :OLD.przydzial_myszy THEN
                :NEW.przydzial_myszy:= :OLD.przydzial_myszy;
                DBMS_OUTPUT.PUT_LINE('Anulowano operacje zmiany przydzialu' || :NEW.pseudo
                || ' z ' || :OLD.przydzial_myszy || ' na ' || :NEW.przydzial_myszy);
            ELSIF (:NEW.przydzial_myszy - :OLD.przydzial_myszy) < przydzial_tygrysa * 0.1 THEN
                zmiana_przydzialu_na_minus:= zmiana_przydzialu_na_minus + 1;
                :NEW.przydzial_myszy:= :OLD.przydzial_myszy + przydzial_tygrysa * 0.1;
                :NEW.myszy_extra:= :OLD.myszy_extra + 5;
                DBMS_OUTPUT.PUT_LINE('Kara dla Tygrysa za zmiane dla kota ' || :new.pseudo
                || ' z ' || :old.przydzial_myszy || ' na ' || :new.przydzial_myszy);
            ELSE
                zmiana_przydzialu_na_plus:= zmiana_przydzialu_na_plus + 1;
                DBMS_OUTPUT.PUT_LINE('Nagroda dla Tygrysa za zmiane dla kota ' || :new.pseudo
                || ' z ' || :old.przydzial_myszy || ' na ' || :new.przydzial_myszy);
            END IF;
            IF :NEW.przydzial_myszy > max_mys THEN
                :NEW.przydzial_myszy := max_mys;
            END IF;
        END IF;
    END BEFORE EACH ROW;
  
    AFTER STATEMENT IS BEGIN
        IF zmiana_przydzialu_na_minus > 0 THEN
            UPDATE Kocury 
            SET przydzial_myszy = przydzial_myszy - (0.1  * zmiana_przydzialu_na_minus * przydzial_myszy)
            WHERE pseudo = 'TYGRYS';
            zmiana_przydzialu_na_minus:= 0;
        END IF;
        IF zmiana_przydzialu_na_plus > 0 THEN
            UPDATE Kocury 
            SET myszy_extra = myszy_extra + zmiana_przydzialu_na_plus * 5
            WHERE pseudo = 'TYGRYS';
            zmiana_przydzialu_na_plus:= 0;
        END IF;
    END AFTER STATEMENT;
END Zad42_CompoundTrigger;

SELECT pseudo, przydzial_myszy, myszy_extra FROM Kocury;
UPDATE Kocury SET przydzial_myszy = przydzial_myszy + 11;
SELECT pseudo, przydzial_myszy, myszy_extra FROM Kocury;
ROLLBACK;


43-----------------------------------------------------------------------------------------------------------------------------
DECLARE
    CURSOR funkcjekotow IS
        SELECT DISTINCT funkcja
        FROM Kocury;
    CURSOR bandykotow IS
        SELECT DISTINCT Bandy.nazwa, Bandy.nr_bandy
        FROM Kocury LEFT JOIN Bandy ON Kocury.nr_bandy = Bandy.nr_bandy;
    aktualnaplec Kocury.plec%TYPE;
    liczbakotow NUMBER;
    sumamyszy NUMBER;
BEGIN
    DBMS_OUTPUT.PUT(RPAD('NAZWA BANDY', 20) || RPAD('PLEC', 7) || RPAD('ILE', 5));
    FOR funkcja IN funkcjekotow LOOP
        DBMS_OUTPUT.PUT(RPAD(funkcja.funkcja, 10));
    END LOOP;
    DBMS_OUTPUT.PUT_LINE(RPAD('SUMA', 10));
    DBMS_OUTPUT.PUT(LPAD(' ', 20, '-') || LPAD(' ', 7, '-') || LPAD(' ', 5, '-'));
    FOR funkcja IN funkcjekotow LOOP
        DBMS_OUTPUT.PUT('--------- ');
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('--------- ');
    
    FOR banda IN bandykotow LOOP
        FOR i IN 1..2 LOOP
            IF i = 1 THEN
                DBMS_OUTPUT.PUT(RPAD(banda.nazwa, 20));
                DBMS_OUTPUT.PUT(RPAD('kotka', 7));
                aktualnaplec:= 'D';
            ELSE
                DBMS_OUTPUT.PUT(RPAD(' ', 20));
                DBMS_OUTPUT.PUT(RPAD('kocor', 7));
                aktualnaplec:= 'M';
            END IF;
            
            SELECT COUNT(*) INTO liczbakotow
            FROM Kocury
            WHERE Kocury.nr_bandy = banda.nr_bandy AND Kocury.plec = aktualnaplec;
          
            DBMS_OUTPUT.PUT(LPAD(liczbakotow || ' ',5));
            FOR funkcja IN funkcjekotow LOOP
                SELECT NVL(SUM(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)), 0)
                INTO sumamyszy
                FROM Kocury
                WHERE Kocury.plec = aktualnaplec AND Kocury.funkcja = funkcja.funkcja AND Kocury.nr_bandy = banda.nr_bandy;
                DBMS_OUTPUT.PUT(RPAD(sumamyszy, 10));
            END LOOP;
            
            SELECT NVL(SUM(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)), 0)
            INTO sumamyszy
            FROM Kocury
            WHERE Kocury.plec = aktualnaplec AND Kocury.nr_bandy = banda.nr_bandy;
            DBMS_OUTPUT.PUT(RPAD(sumamyszy, 10));
            DBMS_OUTPUT.PUT_LINE('');
        END LOOP;    
    END LOOP;
        DBMS_OUTPUT.PUT(LPAD(' ', 20, '-') || LPAD(' ', 7, '-') || LPAD(' ', 5, '-'));
    FOR funkcja IN funkcjekotow LOOP
        DBMS_OUTPUT.PUT('--------- ');
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('--------- ');
    DBMS_OUTPUT.PUT(RPAD('ZJADA RAZEM', 20) || RPAD(' ', 7) || RPAD(' ', 5));
    FOR funkcja IN funkcjekotow LOOP
        SELECT NVL(SUM(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)), 0)
        INTO sumamyszy
        FROM Kocury
        WHERE Kocury.funkcja = funkcja.funkcja;
        DBMS_OUTPUT.PUT(RPAD(sumamyszy, 10));
    END LOOP;
    SELECT NVL(SUM(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)), 0)
    INTO sumamyszy
    FROM Kocury;
    DBMS_OUTPUT.PUT_LINE(RPAD(sumamyszy, 10));
END;


44-----------------------------------------------------------------------------------------------------------------------------
DROP PACKAGE ZAD44;
DROP FUNCTION wyliczanie_podatku;
CREATE OR REPLACE PACKAGE Zad44 AS
    FUNCTION wyliczanie_podatku(aktualne_pseudo Kocury.pseudo%TYPE) RETURN NUMBER;
    PROCEDURE dodaj_bande(nr_ban Bandy.nr_bandy%TYPE, nazwa_ban Bandy.nazwa%TYPE, teren_ban Bandy.teren%TYPE);
END Zad44;

CREATE OR REPLACE PACKAGE BODY Zad44 AS
PROCEDURE dodaj_bande(nr_ban Bandy.nr_bandy%TYPE, nazwa_ban Bandy.nazwa%TYPE, teren_ban Bandy.teren%TYPE)
IS
    liczba_wystapien NUMBER(3):= 0;
    blad_do_wyswietlenia STRING(256);
    wystapil_blad BOOLEAN:= FALSE;
    wystapilo_powtorzenie BOOLEAN:= FALSE;
    ERR_WYSTAPIL_BLAD EXCEPTION;
    ERR_WYSTAPILO_POWTORZENIE EXCEPTION;
BEGIN
    IF nr_ban <= 0 THEN 
        wystapil_blad:= TRUE;
        blad_do_wyswietlenia:= nr_ban || ': ujemny numer';
    END IF;
    
    SELECT COUNT(*) INTO liczba_wystapien FROM Bandy WHERE nr_bandy = nr_ban;
    
    IF liczba_wystapien > 0 THEN
        wystapilo_powtorzenie:= TRUE;
        IF NOT wystapil_blad THEN 
            wystapil_blad:= TRUE;
            blad_do_wyswietlenia:= blad_do_wyswietlenia || nr_ban;
        ELSE
            blad_do_wyswietlenia:= blad_do_wyswietlenia || ', ' || nr_ban;
        END IF;
    END IF;
    
    SELECT COUNT(*) INTO liczba_wystapien FROM Bandy WHERE nazwa = nazwa_ban;
    
    IF liczba_wystapien > 0 THEN 
        IF NOT wystapilo_powtorzenie THEN
            wystapilo_powtorzenie:= TRUE;
        END IF;
        IF NOT wystapil_blad THEN 
            wystapil_blad:= TRUE;
            blad_do_wyswietlenia:= blad_do_wyswietlenia || nazwa_ban;
        ELSE
            blad_do_wyswietlenia:= blad_do_wyswietlenia || ', ' || nazwa_ban;
        END IF;
    END IF;
        
    SELECT COUNT(*) INTO liczba_wystapien FROM Bandy WHERE teren = teren_ban;
    
    IF liczba_wystapien > 0 THEN 
        IF NOT wystapilo_powtorzenie THEN
            wystapilo_powtorzenie:= TRUE;
        END IF;
        IF NOT wystapil_blad THEN 
            wystapil_blad:= TRUE;
            blad_do_wyswietlenia:= blad_do_wyswietlenia || teren_ban;
        ELSE
            blad_do_wyswietlenia:= blad_do_wyswietlenia || ', ' || teren_ban;
        END IF; 
    END IF;
    
        
    IF wystapilo_powtorzenie THEN
        RAISE ERR_WYSTAPILO_POWTORZENIE;
    END IF;
    
    IF wystapil_blad THEN
        RAISE ERR_WYSTAPIL_BLAD;
    END IF;
    
    INSERT INTO bandy (nr_bandy, nazwa, teren)
    VALUES (nr_ban, nazwa_ban, teren_ban);
    
    EXCEPTION
    WHEN ERR_WYSTAPIL_BLAD
        THEN DBMS_OUTPUT.PUT(blad_do_wyswietlenia);
        DBMS_OUTPUT.NEW_LINE();
    WHEN ERR_WYSTAPILO_POWTORZENIE
        THEN DBMS_OUTPUT.PUT(blad_do_wyswietlenia || ': juz istnieje');
        DBMS_OUTPUT.NEW_LINE();
END;

FUNCTION wyliczanie_podatku(aktualne_pseudo Kocury.pseudo%TYPE) 
RETURN NUMBER
IS
    podatek NUMBER;
    liczba_podwladnych NUMBER;
    liczba_wrogow NUMBER;
    liczba_myszy_extra NUMBER;
BEGIN
    
    SELECT CEIL( 0.05 * (NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)) )
    INTO podatek
    FROM Kocury
    WHERE pseudo = aktualne_pseudo;
    
    SELECT COUNT(pseudo) 
    INTO liczba_podwladnych
    FROM Kocury
    WHERE szef = aktualne_pseudo;
    
    SELECT COUNT(pseudo)
    INTO liczba_wrogow
    FROM Wrogowie_kocurow
    WHERE pseudo = aktualne_pseudo;
    
    SELECT NVL(myszy_extra, 0)
    INTO liczba_myszy_extra
    FROM Kocury
    WHERE pseudo = aktualne_pseudo;
    
    IF liczba_podwladnych = 0 THEN
        podatek:= podatek + 2;
    END IF;
    IF liczba_wrogow = 0 THEN
        podatek:= podatek + 1;
    END IF;
    IF liczba_myszy_extra = 0 THEN
        podatek:= podatek + 2;
    END IF;
    
    RETURN podatek;
END;
END Zad44;

SELECT pseudo, zad44.wyliczanie_podatku(pseudo)
FROM Kocury;


45-----------------------------------------------------------------------------------------------------------------------------
DROP TABLE Dodatki_extra;
CREATE TABLE Dodatki_extra (
    pseudo VARCHAR2(15) CONSTRAINT de_fk_k REFERENCES Kocury(pseudo) CONSTRAINT de_pk PRIMARY KEY,
    dodatek_extra NUMBER(3) NOT NULL
);

CREATE OR REPLACE TRIGGER Zad45
AFTER UPDATE OF przydzial_myszy ON Kocury
FOR EACH ROW WHEN(NEW.funkcja = 'MILUSIA')
DECLARE
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    IF  :NEW.przydzial_myszy > :OLD.przydzial_myszy
    AND LOGIN_USER != 'TYGRYS' THEN
        EXECUTE IMMEDIATE
        'DECLARE
            CURSOR curMilusie IS
                SELECT pseudo FROM Kocury WHERE funkcja = ''MILUSIA'';
            czy_jest NUMBER;
        BEGIN
            FOR kot IN curMilusie LOOP
                SELECT COUNT(pseudo)
                INTO czy_jest
                FROM Dodatki_extra
                WHERE pseudo = kot.pseudo;
                IF czy_jest = 0 THEN
                    INSERT INTO dodatki_extra(pseudo, dodatek_extra)
                    VALUES (kot.pseudo, -10);
                ELSE
                    UPDATE Dodatki_extra
                    SET dodatek_extra = dodatek_extra - 10
                    WHERE pseudo = kot.pseudo;
                END IF;
            END LOOP;
        END;';
        COMMIT;
    END IF;
END;

SELECT pseudo, przydzial_myszy, myszy_extra FROM Kocury;
UPDATE Kocury SET przydzial_myszy = przydzial_myszy + 5;
SELECT pseudo, przydzial_myszy, myszy_extra FROM Kocury;
SELECT * FROM Dodatki_extra;
ROLLBACK;
DROP TRIGGER Zad45;


46-----------------------------------------------------------------------------------------------------------------------------
CREATE TABLE Zdarzenia
(polecenie VARCHAR2(10), uzytkownik VARCHAR2(15), data DATE, edytowany_kot VARCHAR2(15));

DROP TRIGGER Zad46;
CREATE OR REPLACE TRIGGER Zad46
BEFORE UPDATE OF przydzial_myszy ON Kocury
FOR EACH ROW
DECLARE
    max_mys NUMBER;
    min_mys NUMBER;
    pol Zdarzenia.polecenie%TYPE;
    uzy Zdarzenia.uzytkownik%TYPE; 
    dat Zdarzenia.data%TYPE;
    kot Zdarzenia.edytowany_kot%TYPE;
    ERR_PRZYDZIAL_Z_POZA_ZAKRESU EXCEPTION;
BEGIN
    SELECT max_myszy INTO max_mys
    FROM Funkcje
    WHERE funkcja = :NEW.funkcja;
    
    SELECT min_myszy INTO min_mys
    FROM Funkcje
    WHERE funkcja = :NEW.funkcja;
    
    IF :NEW.przydzial_myszy > max_mys OR :NEW.przydzial_myszy < min_mys THEN
        :NEW.przydzial_myszy:= :OLD.przydzial_myszy;
        pol:= SYSEVENT; 
        uzy:= LOGIN_USER; 
        dat:= SYSDATE;
        kot:= :NEW.pseudo;
        INSERT INTO Zdarzenia VALUES (pol, uzy, dat, kot);
        RAISE ERR_PRZYDZIAL_Z_POZA_ZAKRESU;
    END IF;
    
EXCEPTION
    WHEN ERR_PRZYDZIAL_Z_POZA_ZAKRESU THEN
        DBMS_OUTPUT.PUT_LINE('Podany przydzia³ myszy jest poza zakresem dla danej funkcji.');
END;

SELECT pseudo, przydzial_myszy, myszy_extra FROM Kocury WHERE pseudo = 'ZERO';
UPDATE Kocury SET przydzial_myszy = przydzial_myszy + 50 WHERE pseudo = 'ZERO';
SELECT pseudo, przydzial_myszy, myszy_extra FROM Kocury WHERE pseudo = 'ZERO';
ROLLBACK;
