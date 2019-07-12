DROP TABLE Myszy;
BEGIN
    EXECUTE IMMEDIATE 'CREATE TABLE Myszy (
        nr_myszy NUMBER CONSTRAINT my_pk PRIMARY KEY,
        lowca VARCHAR(15) CONSTRAINT my_lw_fk REFERENCES Kocury(pseudo),
        zjadacz VARCHAR(15) CONSTRAINT my_zj_fk REFERENCES Kocury(pseudo),
        waga_myszy NUMBER NOT NULL CONSTRAINT my_wm_ck CHECK(waga_myszy BETWEEN 10 AND 40),
        data_zlowienia DATE NOT NULL,
        data_wydania DATE)';
    COMMIT;
END;

DECLARE
    TYPE KocuryIWyplata IS RECORD (pseudo Kocury.pseudo%TYPE, sumaMyszy NUMBER(3));
    TYPE TablicaKocurow IS TABLE OF KocuryIWyplata INDEX BY BINARY_INTEGER;
    kocuryWStadku TablicaKocurow;
    TYPE TablicaMyszy IS TABLE OF Myszy%ROWTYPE INDEX BY BINARY_INTEGER;
    tabMyszy TablicaMyszy;
    data_aktualna DATE := TO_DATE('2004-01-01', 'YYYY-MM-DD');
    data_dzisiejsza DATE := SYSDATE;
    ostatnia_sroda_miesiaca DATE;
    data_zlowienia DATE;
    srednia_liczba_myszy_mies NUMBER;
    index1 NUMBER:= 1;
    index2 NUMBER:= 1;
    sumaMyszy NUMBER;
BEGIN
    ostatnia_sroda_miesiaca := NEXT_DAY(LAST_DAY(data_aktualna) - INTERVAL '7' DAY, 'œroda');
    WHILE data_aktualna <= data_dzisiejsza LOOP        
        SELECT pseudo, NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)
        BULK COLLECT INTO kocuryWStadku
        FROM Kocury
        WHERE w_stadku_od <= ostatnia_sroda_miesiaca;
        
        SELECT CEIL(AVG(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)))
        INTO srednia_liczba_myszy_mies
        FROM Kocury
        WHERE w_stadku_od <= ostatnia_sroda_miesiaca;
        
        FOR i IN 1..kocuryWStadku.COUNT LOOP
            FOR j IN 1..srednia_liczba_myszy_mies LOOP
                data_zlowienia := data_aktualna + DBMS_RANDOM.VALUE(0, ostatnia_sroda_miesiaca - data_aktualna);
                IF data_zlowienia < data_dzisiejsza THEN
                    tabMyszy(index1).nr_myszy := index1;
                    tabMyszy(index1).lowca := kocuryWStadku(i).pseudo;
                    tabMyszy(index1).waga_myszy := DBMS_RANDOM.VALUE(10, 40);
                    tabMyszy(index1).data_zlowienia := data_zlowienia;
                    IF ostatnia_sroda_miesiaca <= data_dzisiejsza THEN
                        tabMyszy(index1).data_wydania := ostatnia_sroda_miesiaca;
                    END IF;
                    index1 := index1 + 1;
                END IF;
            END LOOP;
        END LOOP;
        
        IF ostatnia_sroda_miesiaca <= data_dzisiejsza THEN
            FOR i IN 1..kocuryWStadku.COUNT LOOP
                FOR j IN 1..kocuryWStadku(i).sumaMyszy LOOP
                    tabMyszy(index2).zjadacz := kocuryWStadku(i).pseudo;
                    index2 := index2 + 1;
                END LOOP;
            END LOOP;
            WHILE index1 > index2 LOOP
                tabMyszy(index2).zjadacz := 'TYGRYS';
                index2 := index2 + 1;
            END LOOP;
        END IF;

        SELECT SUM(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)) INTO sumaMyszy
        FROM Kocury 
        WHERE w_stadku_od <= ostatnia_sroda_miesiaca;
        
        DBMS_OUTPUT.PUT_LINE('Data: ' || EXTRACT(YEAR FROM ostatnia_sroda_miesiaca) || '-' || EXTRACT(MONTH FROM ostatnia_sroda_miesiaca) ||
        ' ' || 'Liczba cz³onków: ' || kocuryWStadku.COUNT || ' Myszy wymagane: ' || sumaMyszy ||
        ' Myszy zebrane: '|| srednia_liczba_myszy_mies * kocuryWStadku.COUNT);
        
        data_aktualna := ostatnia_sroda_miesiaca + 1;
        IF  EXTRACT(MONTH FROM data_aktualna) =  EXTRACT(MONTH FROM ostatnia_sroda_miesiaca) THEN
            ostatnia_sroda_miesiaca := next_day(last_day(ADD_MONTHS(data_aktualna,1)) - INTERVAL '7' DAY, 'œroda');
        ELSE
            ostatnia_sroda_miesiaca := next_day(last_day(data_aktualna) - INTERVAL '7' DAY, 'œroda');
        END IF;
    END LOOP;
    
    FORALL i IN 1..tabMyszy.COUNT
    INSERT INTO Myszy VALUES (
    tabMyszy(i).nr_myszy,
    tabMyszy(i).lowca,
    tabMyszy(i).zjadacz,
    tabMyszy(i).waga_myszy,
    tabMyszy(i).data_zlowienia,
    tabMyszy(i).data_wydania);
END;


--ZEWNETRZNA RELACJA Z DANYMI--
BEGIN
    FOR Kot IN (SELECT Pseudo FROM Kocury) LOOP
        EXECUTE IMMEDIATE 'CREATE TABLE MYSZY_' || KOT.PSEUDO || '(
        nr_myszy INTEGER CONSTRAINT ' || KOT.PSEUDO || '_pk PRIMARY KEY,
        waga_myszy NUMBER(3) CONSTRAINT ' || KOT.PSEUDO || '_wm_ch CHECK (waga_myszy BETWEEN 10 AND 40),
        data_zlowienia DATE CONSTRAINT ' || KOT.PSEUDO || '_dz_nn NOT NULL)';
    END LOOP;
END;

--USUWANIE--
BEGIN
    FOR KOT IN (SELECT PSEUDO FROM KOCURY) LOOP
        EXECUTE IMMEDIATE 'DROP TABLE MYSZY_' || KOT.PSEUDO || '';
    END LOOP;
END;


--PERSPEKTYWA DO WSTAWIANIA--
CREATE OR REPLACE PROCEDURE przyjmij_myszy(pseudoKota Kocury.pseudo%TYPE, dzien DATE) AS
    liczbaPseudo NUMBER;
    BLEDNE_PSEUDO EXCEPTION;
    TYPE TablicaMyszy IS TABLE OF Myszy%ROWTYPE INDEX BY BINARY_INTEGER;
    tabMyszy TablicaMyszy;
    TYPE MYSZY_KOTA_REKORD IS RECORD (nr_myszy MYSZY.nr_myszy%TYPE, waga_myszy MYSZY.waga_myszy%TYPE, data_zlowienia MYSZY.data_zlowienia%TYPE);
    TYPE MYSZY_KOTA IS TABLE OF MYSZY_KOTA_REKORD INDEX BY BINARY_INTEGER;
    upolowane_myszy MYSZY_KOTA;
    zapytanieOMyszy VARCHAR2(500);
    ostatniIndex  NUMBER;

BEGIN
    SELECT COUNT(*)
    INTO liczbaPseudo
    FROM Kocury K
    WHERE K.pseudo = pseudoKota;

    IF liczbaPseudo != 1 THEN
      RAISE BLEDNE_PSEUDO;
    END IF;

    SELECT MAX(NVL(nr_myszy, 0))+1
    INTO ostatniIndex
    FROM Myszy;

    EXECUTE IMMEDIATE 'SELECT * FROM MYSZY_' || pseudoKota || ' WHERE data_zlowienia=''' || dzien || ''''
    BULK COLLECT INTO upolowane_myszy;
    
    DBMS_OUTPUT.PUT_LINE(upolowane_myszy.COUNT);
    FOR i IN 1..upolowane_myszy.COUNT LOOP
        tabMyszy(i).nr_myszy := ostatniIndex;
        tabMyszy(i).waga_myszy := upolowane_myszy(i).waga_myszy;
        tabMyszy(i).data_zlowienia := upolowane_myszy(i).data_zlowienia;
        ostatniIndex := ostatniIndex + 1;
    END LOOP;

    FORALL i IN 1..tabMyszy.COUNT
    INSERT INTO Myszy VALUES (tabMyszy(i).nr_myszy, pseudoKota, NULL, tabMyszy(i).waga_myszy,
                              tabMyszy(i).data_zlowienia, NULL);

    EXECUTE IMMEDIATE 'DELETE FROM MYSZY_' || pseudoKota || ' WHERE data_zlowienia=''' || dzien || '''';

    EXCEPTION
    WHEN BLEDNE_PSEUDO THEN dbms_output.put_line('Podane pseudo jest nieprawidlowe!');
END;


INSERT INTO MYSZY_BOLEK VALUES (1, 20, TO_DATE('2019-01-18'));
INSERT INTO MYSZY_BOLEK VALUES (2, 30, TO_DATE('2019-01-18'));
INSERT INTO MYSZY_BOLEK VALUES (3, 35, TO_DATE('2019-01-18'));

SELECT COUNT(*)
FROM myszy
WHERE data_wydania IS NULL;

BEGIN
    przyjmij_myszy('BOLEK',TO_DATE('2019-01-18'));
END;
SET SERVEROUTPUT ON;

SELECT *
FROM MYSZY_BOLEK;

SELECT *
FROM Myszy
ORDER BY 5 DESC;

--PERSPEKTYWA DO WYPLATY--
CREATE OR REPLACE PROCEDURE wyplata AS
    indexM NUMBER := 1;
    indexK NUMBER := 1;
    sumaMyszyKotow NUMBER := 0;
    przydzielonoMysz BOOLEAN;
    ostatniaSroda DATE := NEXT_DAY(LAST_DAY(SYSDATE) - 7, 'Œroda');
    TYPE KocuryIWyplata IS RECORD (pseudo Kocury.pseudo%TYPE, sumaMyszy NUMBER(3));
    TYPE TablicaKocurow IS TABLE OF KocuryIWyplata INDEX BY BINARY_INTEGER;
    kocuryWStadku TablicaKocurow;
    TYPE TablicaMyszy IS TABLE OF Myszy%ROWTYPE INDEX BY BINARY_INTEGER;
    tabMyszy TablicaMyszy;
BEGIN
    SELECT *
    BULK COLLECT INTO tabMyszy
    FROM Myszy
    WHERE zjadacz IS NULL;

    SELECT pseudo, NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)
    BULK COLLECT INTO kocuryWStadku
    FROM Kocury
    WHERE w_stadku_od <= NEXT_DAY(LAST_DAY(ADD_MONTHS(SYSDATE, -1)) - INTERVAL '7' DAY, 'ŒRODA')
    START WITH szef IS NULL
    CONNECT BY PRIOR pseudo = szef
    ORDER BY LEVEL ASC;

    FOR i IN 1..kocuryWStadku.COUNT LOOP
        sumaMyszyKotow := sumaMyszyKotow + kocuryWStadku(i).sumaMyszy;
    END LOOP;

    WHILE indexM <= tabMyszy.COUNT AND sumaMyszyKotow > 0 LOOP
        IF kocuryWStadku(indexK).sumaMyszy > 0 THEN
          tabMyszy(indexM).zjadacz := kocuryWStadku(indexK).pseudo;
          tabMyszy(indexM).data_wydania := ostatniaSroda;
          kocuryWStadku(indexK).sumaMyszy := kocuryWStadku(indexK).sumaMyszy- 1;
          sumaMyszyKotow := sumaMyszyKotow - 1;
          przydzielonoMysz := TRUE;
          indexM := indexM + 1;
        ELSE
            DBMS_OUTPUT.PUT_LINE(kocuryWStadku(indexK).pseudo || ' otrzyma³ pe³n¹ wyp³ate.');
        END IF;
        indexK := indexK + 1;
        IF indexK > kocuryWStadku.COUNT THEN
            indexK := 1;
        END IF;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('Zosta³o: ' || (tabMyszy.COUNT - indexM + 1) || ' myszy dla Tygrysa.');

    FORALL i IN 1..tabMyszy.COUNT
    UPDATE Myszy
    SET data_wydania = tabMyszy(i).data_wydania, zjadacz = tabMyszy(i).zjadacz
    WHERE nr_myszy = tabMyszy(i).nr_myszy;
END wyplata;
EXECUTE wyplata;
SELECT *
FROM Myszy
ORDER BY 5 DESC;