SET SERVEROUTPUT ON;
DROP VIEW Wrogowie_kocurow_PO;
DROP VIEW Konta_PO;
DROP VIEW Elita_PO;
DROP VIEW Plebs_PO;
DROP VIEW Kocury_PO;

DROP TYPE Wrogowie_Kocurow_TYPE2;
DROP TYPE Konta_TYPE2;
DROP TYPE Elita_TYPE2;
DROP TYPE Plebs_TYPE2;
DROP TYPE Kocury_TYPE2;

DROP TABLE Plebs;
DROP TABLE Elita;
DROP TABLE Konta;


--TABELE-----------------------------------------------------------------------------------------------------------------------
CREATE TABLE Plebs (
    nr_kota NUMBER CONSTRAINT plr_pk PRIMARY KEY,
    kot VARCHAR2(15) CONSTRAINT plr_ko_ref REFERENCES Kocury(pseudo)
);
    
CREATE TABLE Elita (
    nr_kota NUMBER CONSTRAINT elr_pk PRIMARY KEY,
    pan VARCHAR2(15) CONSTRAINT elr_pa_ref REFERENCES Kocury(pseudo),
    sluga NUMBER CONSTRAINT elr_sl_ref REFERENCES Plebs(nr_kota)
);

CREATE TABLE Konta (
    nr_myszy NUMBER CONSTRAINT konr_pk PRIMARY KEY,
    wlasciciel NUMBER CONSTRAINT konr_wl_ref REFERENCES Elita(nr_kota),
    data_wprowadzenia DATE CONSTRAINT konr_dw_nn NOT NULL,
    data_usuniecia DATE
);


--TYPY-------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE TYPE Kocury_TYPE2 AS OBJECT (
    imie VARCHAR2(15),
    plec VARCHAR2(1),
    pseudo VARCHAR2(15),
    funkcja VARCHAR2(10),
    szef REF Kocury_TYPE2,
    w_stadku_od DATE,
    przydzial_myszy NUMBER(3),
    myszy_extra NUMBER(3),
    nr_bandy NUMBER(2),
    
    MAP MEMBER FUNCTION sortPoPseudo RETURN VARCHAR2,
    MEMBER FUNCTION sumaMyszy RETURN NUMBER
);

CREATE OR REPLACE TYPE Plebs_TYPE2 AS OBJECT (
    nr_kota NUMBER,
    kot REF Kocury_TYPE2,
    
    MAP MEMBER FUNCTION sortPoNr RETURN NUMBER,
    MEMBER FUNCTION dajImieKota RETURN VARCHAR2
);

CREATE OR REPLACE TYPE Elita_TYPE2 AS OBJECT (
    nr_kota NUMBER,
    pan REF Kocury_TYPE2,
    sluga REF Plebs_TYPE2,
    
    MAP MEMBER FUNCTION sortPoNr RETURN NUMBER,
    MEMBER FUNCTION ileMyszyNaKoncie RETURN NUMBER,
    MEMBER FUNCTION czyMaSluge RETURN VARCHAR2
);

CREATE OR REPLACE TYPE Konta_TYPE2 AS OBJECT (
    nr_myszy NUMBER,
    wlasciciel REF Elita_TYPE2,
    data_wprowadzenia DATE,
    data_usuniecia DATE,
    
    MAP MEMBER FUNCTION sortPoNr RETURN NUMBER,
    MEMBER FUNCTION czySwiezaIDostepna RETURN VARCHAR2
);

CREATE OR REPLACE TYPE Wrogowie_kocurow_TYPE2 AS OBJECT (
    nr_incydentu NUMBER,
    pseudo REF Kocury_TYPE2,
    imie_wroga VARCHAR2(15),
    data_incydentu DATE,
    opis_incydentu VARCHAR2(50),
    
    MAP MEMBER FUNCTION sortPoNr RETURN NUMBER,
    MEMBER FUNCTION daneIncydentu RETURN VARCHAR2
);


--PERSPEKTYWY------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE VIEW Kocury_PO OF KOCURY_TYPE2
WITH OBJECT IDENTIFIER (pseudo) AS
SELECT imie, plec, pseudo, funkcja, null, w_stadku_od, przydzial_myszy, myszy_extra, nr_bandy
FROM Kocury;

CREATE OR REPLACE VIEW Kocury_PO OF KOCURY_TYPE2
WITH OBJECT IDENTIFIER (pseudo) AS
SELECT imie, plec, pseudo, funkcja, MAKE_REF(Kocury_PO, szef), w_stadku_od, przydzial_myszy, myszy_extra, nr_bandy
FROM Kocury;

CREATE OR REPLACE VIEW Plebs_PO OF Plebs_TYPE2
WITH OBJECT IDENTIFIER (nr_kota) AS
SELECT nr_kota, MAKE_REF(Kocury_PO, kot) kot
FROM Plebs;

CREATE OR REPLACE VIEW Elita_PO OF Elita_TYPE2
WITH OBJECT IDENTIFIER (nr_kota) AS
SELECT nr_kota, MAKE_REF(Kocury_PO, pan) pan, MAKE_REF(Plebs_PO, sluga) sluga
FROM Elita;

CREATE OR REPLACE VIEW Konta_PO OF Konta_TYPE2
WITH OBJECT IDENTIFIER (nr_myszy) AS
SELECT nr_myszy, MAKE_REF(Elita_PO, wlasciciel) wlasciciel, data_wprowadzenia, data_usuniecia
FROM Konta;

CREATE OR REPLACE VIEW Wrogowie_kocurow_PO OF Wrogowie_kocurow_TYPE2
WITH OBJECT IDENTIFIER (nr_incydentu) AS
SELECT rownum, MAKE_REF(Kocury_PO, pseudo), imie_wroga, data_incydentu, opis_incydentu
FROM Wrogowie_Kocurow;


--CIALA TYPOW------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE TYPE BODY Kocury_TYPE2 AS 
    MAP MEMBER FUNCTION sortPoPseudo RETURN VARCHAR2 IS
        BEGIN
            RETURN pseudo;
        END;
    MEMBER FUNCTION sumaMyszy RETURN NUMBER IS
        BEGIN
            RETURN nvl(przydzial_myszy,0) + nvl(myszy_extra,0);
        END;
END;

CREATE OR REPLACE TYPE BODY Plebs_TYPE2 AS
    MAP MEMBER FUNCTION sortPoNr RETURN NUMBER IS
        BEGIN
           RETURN nr_kota; 
        END;
    MEMBER FUNCTION dajImieKota RETURN VARCHAR2 IS
        imie VARCHAR2(15);
        BEGIN
            SELECT K.imie
            INTO imie
            FROM Kocury_PO K
            WHERE K.pseudo = DEREF(kot).pseudo;
            RETURN imie;
        END;
END;

CREATE OR REPLACE TYPE BODY Elita_TYPE2 AS
    MAP MEMBER FUNCTION sortPoNr RETURN NUMBER IS
        BEGIN
           RETURN nr_kota; 
        END;
    MEMBER FUNCTION ileMyszyNaKoncie RETURN NUMBER IS
        liczba_myszy NUMBER;
        BEGIN
            SELECT NVL(COUNT(nr_myszy),0) INTO liczba_myszy
            FROM Konta_po 
            WHERE DEREF(wlasciciel) = SELF;
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

CREATE OR REPLACE TYPE BODY Konta_TYPE2 AS
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

CREATE OR REPLACE TYPE BODY Wrogowie_Kocurow_TYPE2 AS
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


--DANE-------------------------------------------------------------------------------------------------------------------------
INSERT ALL
    INTO Plebs VALUES (1, 'LASKA')
    INTO Plebs VALUES (2, 'BOLEK')
    INTO Plebs VALUES (3, 'MALY')
    INTO Plebs VALUES (4, 'MAN')
    INTO Plebs VALUES (5, 'DAMA')
    INTO Plebs VALUES (6, 'UCHO')
    INTO Plebs VALUES (7, 'ZERO')
    SELECT * FROM Dual;
    
INSERT ALL
    INTO Elita VALUES (1,'TYGRYS', (SELECT nr_kota FROM Plebs WHERE kot = 'LASKA'))
    INTO Elita VALUES (2,'LYSY', (SELECT nr_kota FROM Plebs WHERE kot = 'DAMA'))
    INTO Elita VALUES (3,'ZOMBI', (SELECT nr_kota FROM Plebs WHERE kot = 'UCHO'))
    INTO Elita VALUES (4,'PLACEK', (SELECT nr_kota FROM Plebs WHERE kot = 'ZERO'))
    INTO Elita VALUES (5,'LOLA', (SELECT nr_kota FROM Plebs WHERE kot = 'MALY'))
    SELECT * FROM Dual;
    
INSERT ALL 
    INTO Konta VALUES (1, (SELECT nr_kota FROM Elita WHERE pan = 'TYGRYS'),'2019-01-01','2019-01-02')
    INTO Konta VALUES (2, (SELECT nr_kota FROM Elita WHERE pan =  'LYSY'),'2019-01-01','2019-01-05')
    INTO Konta VALUES (3, (SELECT nr_kota FROM Elita WHERE pan =  'TYGRYS'),'2019-01-15',null)
    INTO Konta VALUES (4, (SELECT nr_kota FROM Elita WHERE pan =  'LOLA'),'2019-01-01','2019-01-03')
    SELECT * FROM Dual;
    
    
--ZADANIA----------------------------------------------------------------------------------------------------------------------

SELECT E.pan.pseudo, E.ileMyszyNaKoncie(), E.czyMaSluge()
FROM Elita_PO E;

SELECT K.czySwiezaIDostepna()
FROM Konta_PO K;

SELECT P.dajImieKota()
FROM Plebs_PO P;

SELECT LPAD('==>==>==>', 3 * (level-1)) || TO_CHAR(level-1) "Hierarchia", LPAD('   ', 3 * (level-1)) || imie " ", NVL(DEREF(szef).pseudo, 'sam sobie panem') " ", funkcja
FROM Kocury_PO
WHERE myszy_extra IS NOT NULL
CONNECT BY PRIOR pseudo = DEREF(szef).pseudo
START WITH szef IS NULL;

SELECT DEREF(pseudo).imie, imie_wroga
FROM Wrogowie_kocurow_PO;

SELECT MIN(DEREF(kot).funkcja), COUNT(*)
FROM Plebs_PO
GROUP BY kot;

SELECT MIN(DEREF(P.kot).funkcja), COUNT(*)
FROM Plebs_PO P
GROUP BY P.kot.funkcja;

SELECT pseudo, imie, przydzial_myszy
FROM Kocury_PO
WHERE pseudo IN (SELECT DEREF(pan).pseudo
                 FROM Elita_PO);

--18--
--Wyœwietliæ bez stosowania podzapytania imiona i daty przyst¹pienia do stada kotów,--
--które przyst¹pi³y do stada przed kotem o imieniu ’JACEK’. Wyniki uporz¹dkowaæ malej¹co wg daty przyst¹pienia do stadka.--
SELECT K2.imie, K2.w_stadku_od "Poluje od"
FROM Kocury_PO K1 JOIN Kocury_PO K2
                ON K1.imie='JACEK' AND K1.w_stadku_od > K2.w_stadku_od
ORDER BY K2.w_stadku_od DESC;


--19a--
SELECT K.imie || '|', K.funkcja || '|', NVL(K.szef.imie, ' ') || '|' "Szef 1",  NVL(K.szef.szef.imie, ' ') || '|' "Szef 2", NVL(K.szef.szef.szef.imie, ' ') || '|' "Szef 3"
FROM Kocury_PO K
WHERE K.funkcja = 'MILUSIA' OR K.funkcja = 'KOT';


--23--
--Wyœwietliæ imiona kotów, które dostaj¹ „mysz¹” premiê wraz z ich ca³kowitym rocznym spo¿yciem myszy.--
--Dodatkowo jeœli ich roczna dawka myszy przekracza 864 wyœwietliæ tekst ’powyzej 864’, jeœli jest równa 864 tekst ’864’,--
--jeœli jest mniejsza od 864 tekst ’poni¿ej 864’. Wyniki uporz¹dkowaæ malej¹co wg rocznej dawki myszy.--
--Do rozwi¹zania wykorzystaæ operator zbiorowy UNION.--
SELECT K.imie, 12 * K.sumaMyszy() "Dawka roczna", 'powyzej 864' "Dawka"
FROM Kocury_PO K
WHERE 12 * K.sumaMyszy() > 864 AND K.myszy_extra IS NOT NULL
UNION SELECT  K.imie, 12 * K.sumaMyszy() "Dawka roczna", '864' "Dawka"
FROM Kocury_PO K
WHERE 12 * K.sumaMyszy() = 864 AND K.myszy_extra IS NOT NULL
UNION SELECT  K.imie, 12 * K.sumaMyszy() "Dawka roczna", 'ponizej 864' "Dawka"
FROM Kocury_PO K
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
    pseudo Kocury_PO.pseudo%TYPE;
    imie Kocury_PO.imie%TYPE;
    data_przystapienia Kocury_PO.w_stadku_od%TYPE;
    roczny_przydzial NUMBER(4);
    przynajmniej_jedno_wystapilo BOOLEAN:=false;
BEGIN
    SELECT K.pseudo, K.imie, K.w_stadku_od, K.sumaMyszy()*12 
    INTO pseudo, imie, data_przystapienia, roczny_przydzial
    FROM Kocury_PO K
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
    CURSOR koty IS SELECT K.pseudo, K.sumaMyszy() as przydzial FROM Kocury_PO K  ORDER BY przydzial DESC;
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