SET SERVEROUTPUT ON;
DROP TABLE Wrogowie_Kocurow_R;
DROP TABLE Konta_R;
DROP TABLE Elita_R;
DROP TABLE Plebs_R;
DROP TABLE Kocury_R;

DROP TYPE Wrogowie_Kocurow_TYPE;
DROP TYPE Konta_TYPE;
DROP TYPE Elita_TYPE;
DROP TYPE Plebs_TYPE;
DROP TYPE Kocury_TYPE;


--TYPY-------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE TYPE Kocury_TYPE AS OBJECT (
    imie VARCHAR2(15),
    plec VARCHAR2(1),
    pseudo VARCHAR2(15),
    funkcja VARCHAR2(10),
    szef REF Kocury_TYPE,
    w_stadku_od DATE,
    przydzial_myszy NUMBER(3),
    myszy_extra NUMBER(3),
    nr_bandy NUMBER(2),
    
    MAP MEMBER FUNCTION sortPoPseudo RETURN VARCHAR2,
    MEMBER FUNCTION sumaMyszy RETURN NUMBER
);

CREATE OR REPLACE TYPE Plebs_TYPE AS OBJECT (
    nr_kota NUMBER,
    kot REF Kocury_TYPE,
    
    MAP MEMBER FUNCTION sortPoNr RETURN NUMBER,
    MEMBER FUNCTION dajImieKota RETURN VARCHAR2
);

CREATE OR REPLACE TYPE Elita_TYPE AS OBJECT (
    nr_kota NUMBER,
    pan REF Kocury_TYPE,
    sluga REF Plebs_TYPE,
    
    MAP MEMBER FUNCTION sortPoNr RETURN NUMBER,
    MEMBER FUNCTION ileMyszyNaKoncie RETURN NUMBER,
    MEMBER FUNCTION czyMaSluge RETURN VARCHAR2
);

CREATE OR REPLACE TYPE Konta_TYPE AS OBJECT (
    nr_myszy NUMBER,
    wlasciciel REF Elita_TYPE,
    data_wprowadzenia DATE,
    data_usuniecia DATE,
    
    MAP MEMBER FUNCTION sortPoNr RETURN NUMBER,
    MEMBER FUNCTION czySwiezaIDostepna RETURN VARCHAR2
);

CREATE OR REPLACE TYPE Wrogowie_kocurow_TYPE AS OBJECT (
    nr_incydentu NUMBER,
    pseudo REF Kocury_TYPE,
    imie_wroga VARCHAR2(15),
    data_incydentu DATE,
    opis_incydentu VARCHAR2(50),
    
    MAP MEMBER FUNCTION sortPoNr RETURN NUMBER,
    MEMBER FUNCTION daneIncydentu RETURN VARCHAR2
);


--OBIEKTY WIERSZOWE------------------------------------------------------------------------------------------------------------
CREATE TABLE Kocury_R OF Kocury_TYPE(
    CONSTRAINT kor_ps_pk PRIMARY KEY (pseudo),
    CONSTRAINT kor_im_nn CHECK (imie IS NOT NULL),
    CONSTRAINT kor_pl_ch CHECK (plec IN ('M', 'D')),
    w_stadku_od DEFAULT (SYSDATE),
    szef SCOPE IS Kocury_R
);

CREATE TABLE Plebs_R OF Plebs_TYPE(
    kot SCOPE IS Kocury_R CONSTRAINT pl_ko_nn NOT NULL,
    CONSTRAINT pl_pk PRIMARY KEY(nr_kota)
);
    
CREATE TABLE Elita_R OF Elita_TYPE(
    CONSTRAINT el_pk PRIMARY KEY(nr_kota),
    pan SCOPE IS Kocury_R CONSTRAINT el_pa_nn NOT NULL,
    sluga SCOPE IS Plebs_R CONSTRAINT el_sl_nn NOT NULL
);

CREATE TABLE Konta_R OF Konta_TYPE(
    CONSTRAINT kon_pk PRIMARY KEY(nr_myszy),
    wlasciciel SCOPE IS Elita_R CONSTRAINT kon_wl_nn NOT NULL,
    data_wprowadzenia CONSTRAINT kon_dw_nn NOT NULL
);

CREATE TABLE Wrogowie_kocurow_R OF Wrogowie_kocurow_TYPE(
    CONSTRAINT wkr_pk PRIMARY KEY(nr_incydentu),
    pseudo SCOPE IS Kocury_R CONSTRAINT wkr_ps_nn NOT NULL,
    imie_wroga CONSTRAINT wkr_iw_nn NOT NULL,
    data_incydentu CONSTRAINT wkr_di_nn NOT NULL
);


--CIALA TYPOW------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE TYPE BODY Kocury_TYPE AS 
    MAP MEMBER FUNCTION sortPoPseudo RETURN VARCHAR2 IS
        BEGIN
            RETURN pseudo;
        END;
    MEMBER FUNCTION sumaMyszy RETURN NUMBER IS
        BEGIN
            RETURN nvl(przydzial_myszy,0) + nvl(myszy_extra,0);
        END;
END;

CREATE OR REPLACE TYPE BODY Plebs_TYPE AS
    MAP MEMBER FUNCTION sortPoNr RETURN NUMBER IS
        BEGIN
           RETURN nr_kota; 
        END;
    MEMBER FUNCTION dajImieKota RETURN VARCHAR2 IS
        imie VARCHAR2(15);
        BEGIN
            SELECT K.imie
            INTO imie
            FROM Kocury_R K
            WHERE K.pseudo = DEREF(kot).pseudo;
            RETURN imie;
        END;
END;

CREATE OR REPLACE TYPE BODY Elita_TYPE AS
    MAP MEMBER FUNCTION sortPoNr RETURN NUMBER IS
        BEGIN
           RETURN nr_kota; 
        END;
    MEMBER FUNCTION ileMyszyNaKoncie RETURN NUMBER IS
        liczba_myszy NUMBER;
        BEGIN
            SELECT COUNT(K.nr_myszy) INTO liczba_myszy
            FROM Konta_R K
            WHERE DEREF(K.wlasciciel) = SELF;
            RETURN liczba_myszy;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN RETURN 'Nie posiada myszy na koncie.';
        END;
    MEMBER FUNCTION czyMaSluge RETURN VARCHAR2 IS
        czyMa VARCHAR2(15) := 'Nie ma';
        BEGIN
            IF sluga IS NOT NULL THEN
                czyMa := 'Ma';
            END IF;
            RETURN czyMa;
        END;
END;

CREATE OR REPLACE TYPE BODY Konta_TYPE AS
    MAP MEMBER FUNCTION sortPoNr RETURN NUMBER IS
        BEGIN
           RETURN nr_myszy; 
        END;   
    MEMBER FUNCTION czySwiezaIDostepna RETURN VARCHAR2 IS
        czySwieza VARCHAR2(30) := 'Nie œwie¿a';
        czyDostepna VARCHAR2(30) := ' i nie dostêpna.';
        BEGIN
            IF SYSDATE - data_wprowadzenia < 7 THEN
                czySwieza := 'Œwie¿a';
            END IF;
            IF data_usuniecia IS NULL THEN
                czyDostepna:= ' i dostêpna.';
            END IF;
            RETURN czySwieza || czyDostepna;
        END;
END;

CREATE OR REPLACE TYPE BODY Wrogowie_Kocurow_TYPE AS
    MAP MEMBER FUNCTION sortPoNr RETURN NUMBER IS
        BEGIN
           RETURN nr_incydentu; 
        END; 
    MEMBER FUNCTION daneIncydentu RETURN VARCHAR2 IS
        BEGIN
            RETURN 'Incydent pomiêdzy' ||
            imie_wroga || ' a ' || 
            ' mia³ miejsce dnia ' || data_incydentu ||
            '. Opis incydentu: ' || opis_incydentu || '.';
        END;
END;


--WSTAWIANIE DANYCH------------------------------------------------------------------------------------------------------------
INSERT ALL
    INTO Kocury_R
    VALUES ('MRUCZEK','M','TYGRYS','SZEFUNIO',NULL,'2002-01-01',103,33,1)
    SELECT * FROM Dual;
    
INSERT ALL
    INTO Kocury_R
    VALUES ('BOLEK','M','LYSY','BANDZIOR',(SELECT REF(K) FROM Kocury_R K WHERE K.pseudo='TYGRYS'),'2006-08-15',72,21,2)
    INTO Kocury_R
    VALUES ('PUCEK','M','RAFA','LOWCZY',(SELECT REF(K) FROM Kocury_R K WHERE K.pseudo='TYGRYS'),'2006-10-15',65,NULL,4)
    INTO Kocury_R
    VALUES ('KOREK','M','ZOMBI','BANDZIOR',(SELECT REF(K) FROM Kocury_R K WHERE K.pseudo='TYGRYS'),'2004-03-16',75,13,3)
    SELECT * FROM Dual;
    
INSERT ALL
    INTO Kocury_R
    VALUES ('JACEK','M','PLACEK','LOWCZY',(SELECT REF(K) FROM Kocury_R K WHERE K.pseudo='LYSY'),'2008-12-01',67,NULL,2)
    INTO Kocury_R
    VALUES ('BARI','M','RURA','LAPACZ',(SELECT REF(K) FROM Kocury_R K WHERE K.pseudo='LYSY'),'2009-09-01',56,NULL,2)
    INTO Kocury_R
    VALUES ('MICKA','D','LOLA','MILUSIA',(SELECT REF(K) FROM Kocury_R K WHERE K.pseudo='TYGRYS'),'2009-10-14',25,47,1)
    INTO Kocury_R
    VALUES ('SONIA','D','PUSZYSTA','MILUSIA',(SELECT REF(K) FROM Kocury_R K WHERE K.pseudo='ZOMBI'),'2010-11-18',20,35,3)
    INTO Kocury_R
    VALUES ('LATKA','D','UCHO','KOT',(SELECT REF(K) FROM Kocury_R K WHERE K.pseudo='RAFA'),'2011-01-01',40,NULL,4)
    INTO Kocury_R
    VALUES ('DUDEK','M','MALY','KOT',(SELECT REF(K) FROM Kocury_R K WHERE K.pseudo='RAFA'),'2011-05-15',40,NULL,4)
    INTO Kocury_R
    VALUES ('CHYTRY','M','BOLEK','DZIELCZY',(SELECT REF(K) FROM Kocury_R K WHERE K.pseudo='TYGRYS'),'2002-05-05',50,NULL,1)
    INTO Kocury_R
    VALUES ('ZUZIA','D','SZYBKA','LOWCZY',(SELECT REF(K) FROM Kocury_R K WHERE K.pseudo='LYSY'),'2006-07-21',65,NULL,2)
    INTO Kocury_R
    VALUES ('RUDA','D','MALA','MILUSIA',(SELECT REF(K) FROM Kocury_R K WHERE K.pseudo='TYGRYS'),'2006-09-17',22,42,1)
    INTO Kocury_R
    VALUES ('PUNIA','D','KURKA','LOWCZY',(SELECT REF(K) FROM Kocury_R K WHERE K.pseudo='ZOMBI'),'2008-01-01',61,NULL,3)
    INTO Kocury_R
    VALUES ('BELA','D','LASKA','MILUSIA',(SELECT REF(K) FROM Kocury_R K WHERE K.pseudo='LYSY'),'2008-02-01',24,28,2)
    INTO Kocury_R
    VALUES ('KSAWERY','M','MAN','LAPACZ',(SELECT REF(K) FROM Kocury_R K WHERE K.pseudo='RAFA'),'2008-07-12',51,NULL,4)
    INTO Kocury_R
    VALUES ('MELA','D','DAMA','LAPACZ',(SELECT REF(K) FROM Kocury_R K WHERE K.pseudo='RAFA'),'2008-11-01',51,NULL,4)
    SELECT * FROM Dual; 

INSERT ALL
    INTO Kocury_R
    VALUES ('LUCEK','M','ZERO','KOT',(SELECT REF(K) FROM Kocury_R K WHERE K.pseudo='KURKA'),'2010-03-01',43,NULL,3)
    SELECT * FROM Dual;


INSERT ALL
    INTO Wrogowie_kocurow_R VALUES (1, (SELECT REF(K) FROM Kocury_R K WHERE K.pseudo='TYGRYS'),'KAZIO','2004-10-13','USILOWAL NABIC NA WIDLY')
    INTO Wrogowie_kocurow_R VALUES (2, (SELECT REF(K) FROM Kocury_R K WHERE K.pseudo='ZOMBI'),'SWAWOLNY DYZIO','2005-03-07','WYBIL OKO Z PROCY')
    INTO Wrogowie_kocurow_R VALUES (3, (SELECT REF(K) FROM Kocury_R K WHERE K.pseudo='BOLEK'),'KAZIO','2005-03-29','POSZCZUL BURKIEM')
    INTO Wrogowie_kocurow_R VALUES (4, (SELECT REF(K) FROM Kocury_R K WHERE K.pseudo='SZYBKA'),'GLUPIA ZOSKA','2006-09-12','UZYLA KOTA JAKO SCIERKI')
    INTO Wrogowie_kocurow_R VALUES (5, (SELECT REF(K) FROM Kocury_R K WHERE K.pseudo='MALA'),'CHYTRUSEK','2007-03-07','ZALECAL SIE')
    INTO Wrogowie_kocurow_R VALUES (6, (SELECT REF(K) FROM Kocury_R K WHERE K.pseudo='TYGRYS'),'DZIKI BILL','2007-06-12','USILOWAL POZBAWIC ZYCIA')
    INTO Wrogowie_kocurow_R VALUES (7, (SELECT REF(K) FROM Kocury_R K WHERE K.pseudo='BOLEK'),'DZIKI BILL','2007-11-10','ODGRYZL UCHO')
    INTO Wrogowie_kocurow_R VALUES (8, (SELECT REF(K) FROM Kocury_R K WHERE K.pseudo='LASKA'),'DZIKI BILL','2008-12-12','POGRYZL ZE LEDWO SIE WYLIZALA')
    INTO Wrogowie_kocurow_R VALUES (9, (SELECT REF(K) FROM Kocury_R K WHERE K.pseudo='LASKA'),'KAZIO','2009-01-07','ZLAPAL ZA OGON I ZROBIL WIATRAK')
    INTO Wrogowie_kocurow_R VALUES (10, (SELECT REF(K) FROM Kocury_R K WHERE K.pseudo='DAMA'),'KAZIO','2009-02-07','CHCIAL OBEDRZEC ZE SKORY')
    INTO Wrogowie_kocurow_R VALUES (11, (SELECT REF(K) FROM Kocury_R K WHERE K.pseudo='MAN'),'REKSIO','2009-04-14','WYJATKOWO NIEGRZECZNIE OBSZCZEKAL')
    INTO Wrogowie_kocurow_R VALUES (12, (SELECT REF(K) FROM Kocury_R K WHERE K.pseudo='LYSY'),'BETHOVEN','2009-05-11','NIE PODZIELIL SIE SWOJA KASZA')
    INTO Wrogowie_kocurow_R VALUES (13, (SELECT REF(K) FROM Kocury_R K WHERE K.pseudo='RURA'),'DZIKI BILL','2009-09-03','ODGRYZL OGON')
    INTO Wrogowie_kocurow_R VALUES (14, (SELECT REF(K) FROM Kocury_R K WHERE K.pseudo='PLACEK'),'BAZYLI','2010-07-12','DZIOBIAC UNIEMOZLIWIL PODEBRANIE KURCZAKA')
    INTO Wrogowie_kocurow_R VALUES (15, (SELECT REF(K) FROM Kocury_R K WHERE K.pseudo='PUSZYSTA'),'SMUKLA','2010-11-19','OBRZUCILA SZYSZKAMI')
    INTO Wrogowie_kocurow_R VALUES (16, (SELECT REF(K) FROM Kocury_R K WHERE K.pseudo='KURKA'),'BUREK','2010-12-14','POGONIL')
    INTO Wrogowie_kocurow_R VALUES (17, (SELECT REF(K) FROM Kocury_R K WHERE K.pseudo='MALY'),'CHYTRUSEK','2011-07-13','PODEBRAL PODEBRANE JAJKA')
    INTO Wrogowie_kocurow_R VALUES (18, (SELECT REF(K) FROM Kocury_R K WHERE K.pseudo='UCHO'),'SWAWOLNY DYZIO','2011-07-14','OBRZUCIL KAMIENIAMI')
    SELECT * FROM Dual;

INSERT ALL
    INTO Plebs_R VALUES (1, (SELECT REF(K) FROM Kocury_R K WHERE K.pseudo ='LASKA'))
    INTO Plebs_R VALUES (2, (SELECT REF(K) FROM Kocury_R K WHERE K.pseudo ='BOLEK'))
    INTO Plebs_R VALUES (3, (SELECT REF(K) FROM Kocury_R K WHERE K.pseudo ='MALY'))
    INTO Plebs_R VALUES (4, (SELECT REF(K) FROM Kocury_R K WHERE K.pseudo ='MAN'))
    INTO Plebs_R VALUES (5, (SELECT REF(K) FROM Kocury_R K WHERE K.pseudo ='DAMA'))
    INTO Plebs_R VALUES (6, (SELECT REF(K) FROM Kocury_R K WHERE K.pseudo ='UCHO'))
    INTO Plebs_R VALUES (7, (SELECT REF(K) FROM Kocury_R K WHERE K.pseudo ='ZERO'))
    SELECT * FROM Dual;
    
INSERT ALL
    INTO Elita_R VALUES (1,(SELECT REF(K) FROM Kocury_R K WHERE K.pseudo ='TYGRYS'), (SELECT REF(P) FROM Plebs_R P WHERE P.kot.pseudo='LASKA'))
    INTO Elita_R VALUES (2,(SELECT REF(K) FROM Kocury_R K WHERE K.pseudo ='LYSY'), (SELECT REF(P) FROM Plebs_R P WHERE P.kot.pseudo='DAMA'))
    INTO Elita_R VALUES (3,(SELECT REF(K) FROM Kocury_R K WHERE K.pseudo ='ZOMBI'), (SELECT REF(P) FROM Plebs_R P WHERE P.kot.pseudo='UCHO'))
    INTO Elita_R VALUES (4,(SELECT REF(K) FROM Kocury_R K WHERE K.pseudo ='PLACEK'), (SELECT REF(P) FROM Plebs_R P WHERE P.kot.pseudo='ZERO'))
    INTO Elita_R VALUES (5,(SELECT REF(K) FROM Kocury_R K WHERE K.pseudo ='LOLA'), (SELECT REF(P) FROM Plebs_R P WHERE P.kot.pseudo='MALY'))
    SELECT * FROM Dual;
    
INSERT ALL 
    INTO Konta_R VALUES (1, (SELECT REF(E) FROM Elita_R E WHERE E.pan.pseudo='TYGRYS'),'2019-01-01','2019-01-02')
    INTO Konta_R VALUES (2, (SELECT REF(E) FROM Elita_R E WHERE E.pan.pseudo='LYSY'),'2019-01-01','2019-01-02')
    INTO Konta_R VALUES (3, (SELECT REF(E) FROM Elita_R E WHERE E.pan.pseudo='TYGRYS'),'2019-01-01','2019-01-02')
    INTO Konta_R VALUES (4, (SELECT REF(E) FROM Elita_R E WHERE E.pan.pseudo='LOLA'),'2019-01-01','2019-01-02')
    SELECT * FROM Dual;


--PRZYKLADOWE ZAPYTANIA--------------------------------------------------------------------------------------------------------
SELECT E.pan.pseudo, E.ileMyszyNaKoncie(), E.czyMaSluge()
FROM Elita_R E;

SELECT K.czySwiezaIDostepna()
FROM Konta_R K;

SELECT P.dajImieKota()
FROM Plebs_R P;

SELECT LPAD('==>==>==>', 3 * (level-1)) || TO_CHAR(level-1) "Hierarchia", LPAD('   ', 3 * (level-1)) || imie " ", NVL(DEREF(szef).pseudo, 'sam sobie panem') " ", funkcja
FROM Kocury_R
WHERE myszy_extra IS NOT NULL
CONNECT BY PRIOR pseudo = DEREF(szef).pseudo
START WITH szef IS NULL;

SELECT DEREF(pseudo).imie, imie_wroga
FROM Wrogowie_kocurow_R;

SELECT MIN(DEREF(kot).funkcja), COUNT(*)
FROM Plebs_R
GROUP BY kot;

SELECT MIN(DEREF(P.kot).funkcja), COUNT(*)
FROM Plebs_R P
GROUP BY P.kot.funkcja;

SELECT pseudo, imie, przydzial_myszy
FROM Kocury_R
WHERE pseudo IN (SELECT DEREF(pan).pseudo
                 FROM Elita_R);

--18--
--Wyœwietliæ bez stosowania podzapytania imiona i daty przyst¹pienia do stada kotów,--
--które przyst¹pi³y do stada przed kotem o imieniu ’JACEK’. Wyniki uporz¹dkowaæ malej¹co wg daty przyst¹pienia do stadka.--
SELECT K2.imie, K2.w_stadku_od "Poluje od"
FROM Kocury_R K1 JOIN Kocury_R K2
                ON K1.imie='JACEK' AND K1.w_stadku_od > K2.w_stadku_od
ORDER BY K2.w_stadku_od DESC;


--19a--
SELECT K.imie || '|', K.funkcja || '|', NVL(K.szef.imie, ' ') || '|' "Szef 1",  NVL(K.szef.szef.imie, ' ') || '|' "Szef 2", NVL(K.szef.szef.szef.imie, ' ') || '|' "Szef 3"
FROM Kocury_R K
WHERE K.funkcja = 'MILUSIA' OR K.funkcja = 'KOT';


--23--
--Wyœwietliæ imiona kotów, które dostaj¹ „mysz¹” premiê wraz z ich ca³kowitym rocznym spo¿yciem myszy.--
--Dodatkowo jeœli ich roczna dawka myszy przekracza 864 wyœwietliæ tekst ’powyzej 864’, jeœli jest równa 864 tekst ’864’,--
--jeœli jest mniejsza od 864 tekst ’poni¿ej 864’. Wyniki uporz¹dkowaæ malej¹co wg rocznej dawki myszy.--
--Do rozwi¹zania wykorzystaæ operator zbiorowy UNION.--
SELECT K.imie, 12 * K.sumaMyszy() "Dawka roczna", 'powyzej 864' "Dawka"
FROM Kocury_R K
WHERE 12 * K.sumaMyszy() > 864 AND K.myszy_extra IS NOT NULL
UNION SELECT  K.imie, 12 * K.sumaMyszy() "Dawka roczna", '864' "Dawka"
FROM Kocury_R K
WHERE 12 * K.sumaMyszy() = 864 AND K.myszy_extra IS NOT NULL
UNION SELECT  K.imie, 12 * K.sumaMyszy() "Dawka roczna", 'ponizej 864' "Dawka"
FROM Kocury_R K
WHERE 12 * K.sumaMyszy() < 864 AND K.myszy_extra IS NOT NULL
ORDER BY 2 DESC;

--35--
--Napisaæ blok PL/SQL, który wyprowadza na ekran nastêpuj¹ce informacje o kocie o pseudonimie wprowadzonym z klawiatury --
--(w zale¿noœci od rzeczywistych danych):--
--	'calkowity roczny przydzial myszy >700'--
--	'imiê zawiera litere A'--
--	'styczeñ jest miesiacem przystapienia do stada'--
--	'nie odpowiada kryteriom'.--
--Powy¿sze informacje wymienione s¹ zgodnie z hierarchi¹ wa¿noœci. Ka¿d¹ wprowadzan¹ informacjê poprzedziæ imieniem kota.--

SET SERVEROUTPUT ON;
DECLARE
    pseudo Kocury_R.pseudo%TYPE;
    imie Kocury_R.imie%TYPE;
    data_przystapienia Kocury_R.w_stadku_od%TYPE;
    roczny_przydzial NUMBER(4);
    przynajmniej_jedno_wystapilo BOOLEAN:=false;
BEGIN
    SELECT K.pseudo, K.imie, K.w_stadku_od, K.sumaMyszy()*12 
    INTO pseudo, imie, data_przystapienia, roczny_przydzial
    FROM Kocury_R K
    WHERE K.pseudo = '&pseudo';
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

--37--
--Napisaæ blok, który powoduje wybranie w pêtli kursorowej FOR piêciu kotów o najwy¿szym ca³kowitym przydziale myszy.--
--Wynik wyœwietliæ na ekranie.--
DECLARE
    licznik NUMBER(3):= 0;
    CURSOR koty IS SELECT K.pseudo, K.sumaMyszy() as przydzial FROM Kocury_R K  ORDER BY przydzial DESC;
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