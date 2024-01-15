/*--RISPOSTA_1--1.	Analisi delle Vendite Mensili:
	Domanda: Trova il totale delle vendite per ogni mese.
*/

SELECT MONTH(DataTransazione) AS Mese, ROUND(SUM(QuantitaAcquistata*Prezzo), 2) AS TotaleVendite
	FROM prodotti
	JOIN transazioni
	ON prodotti.ProdottoID = transazioni.ProdottoID
	GROUP BY MONTH(DataTransazione);

/*--RISPOSTA_2-2.	Prodotti più Venduti:
	Domanda: Identifica i tre prodotti più venduti e la loro quantità venduta.
-*/
SELECT ProdottoID, SUM(QuantitaAcquistata) AS totale_quantita_venduta
	FROM transazioni
	GROUP BY ProdottoID
	ORDER BY totale_quantita_venduta DESC,ProdottoID ASC
	LIMIT 3;
/*--RISPOSTA_3-3.	Analisi Cliente:
	Domanda: Trova il cliente che ha effettuato il maggior numero di acquisti.
-*/

SELECT ClienteID, COUNT(QuantitaAcquistata) AS totale_acquisti
	FROM transazioni
	GROUP BY ClienteID
	ORDER BY totale_acquisti DESC,ClienteID ASC
	LIMIT 3;

/*--RISPOSTA_4.1-SPEDIZIONE.	Valore medio della transazione:
	Domanda: Calcola il valore medio di ogni transazione.
-*/
SELECT AVG(ImportoTransazione) AS valore_medio_spedizione
	FROM transazioni;
/*--RISPOSTA_4.2-AZIENDA-*/
SELECT AVG(QuantitaAcquistata*Prezzo) AS spesa_media
	FROM prodotti
	JOIN transazioni
	ON prodotti.prodottoID = transazioni.prodottoID;
/*--RISPOSTA_4.3-CLIENTE-*/
SELECT AVG(QuantitaAcquistata*Prezzo+ImportoTransazione) AS spesa_mediatot
	FROM prodotti
	JOIN transazioni
	ON prodotti.prodottoID = transazioni.prodottoID;


/*-domanda bonus_DI 10 PUNTI CALCOLO QUANTITA PER CATEGORIA IN STORE*/

SELECT Categoria, SUM(QuantitaDisponibile) AS Totale_disponibilita_categorie
	FROM prodotti
	GROUP BY Categoria
	ORDER BY Totale_disponibilita_categorie DESC
	LIMIT 1;

/*--RISPOSTA_5--Determina la categoria di prodotto con il maggior numero di vendite.*/
SELECT Categoria, SUM(QuantitaAcquistata) AS Numero_oggetti_venduti_per_categoria
	FROM prodotti
	JOIN transazioni
	ON prodotti.prodottoID = transazioni.prodottoID
	GROUP BY Categoria
	ORDER BY SUM(QuantitaAcquistata) DESC;

/*RISPOSTA_6--Cliente Fedele: Identifica il cliente con il maggior valore totale di acquisti*/


SELECT ClienteID,QuantitaAcquistata*Prezzo+ImportoTransazione AS spesa_TOT_cliente
	FROM prodotti
	JOIN transazioni
	ON prodotti.prodottoID = transazioni.prodottoID
	GROUP BY ClienteID
	ORDER BY spesa_TOT_cliente DESC
	LIMIT 1;

/*RISPOSTA_7PLUS--	Domanda: Calcola la percentuale di spedizioni con "Consegna Riuscita"*/

SELECT MetodoSpedizione, StatusConsegna, COUNT(StatusConsegna)/(SELECT COUNT(*) FROM spedizioni)* 100 AS percentuale
	FROM spedizioni
	GROUP BY MetodoSpedizione, StatusConsegna;
    
	SELECT StatusConsegna, COUNT(StatusConsegna)/(SELECT COUNT(*) FROM spedizioni)* 100 AS percentuale
	FROM spedizioni
    WHERE StatusConsegna='Consegna Riuscita'
	GROUP BY StatusConsegna
    ;

/*RISPOSTA_8--Trova il prodotto con la recensione media più alta*/
SELECT ProductID, AVG(Rating) AS recensione_media_piu_alta, COUNT(Rating) AS conteggio_recensione
	FROM ratings
	GROUP BY ProductID
	ORDER BY recensione_media_piu_alta DESC, conteggio_recensione DESC, ProductID ASC
	LIMIT 3;


/*---9.	Analisi Temporale:
○	Domanda: Calcola la variazione percentuale nelle vendite rispetto al mese precedente.*/

SELECT
    Mese, Tot_merce_venduta_mese, LAG(Tot_merce_venduta_mese) OVER (ORDER BY Mese) AS Tot_merce_venduta_mese_precedente,
    (Tot_merce_venduta_mese - LAG(Tot_merce_venduta_mese) OVER (ORDER BY Mese))/(SELECT COUNT(*) FROM transazioni)*100 AS Incremento_decremento_percentuale

FROM (
    SELECT MONTH(DataTransazione) AS Mese, SUM(QuantitaAcquistata) AS Tot_merce_venduta_mese
		FROM transazioni t
		#JOIN DETTAGLI_VENDITE D ON V.ID_transazione = D.ID_transazione
		GROUP BY MONTH(DataTransazione)
)	 AS VenditeMese
	ORDER BY Mese ASC,
	CASE WHEN Incremento_decremento_percentuale IS NULL THEN '▬' WHEN Incremento_decremento_percentuale>= 1 THEN '▲' ELSE '▼' END;


with trans_grouped as ( -- common table expression (cte)
    select sum(importotransazione) importo
        , year(datatransazione) anno
        , month(DataTransazione) mese
        from transazioni 
        group by year(datatransazione), month(datatransazione)
), 
analisi as ( -- altra common table expression
select 
    anno, 
    mese, 
    importo,
    (select importo 
        from trans_grouped g 
        where g.mese = t.mese -1
    ) mese_precedente,
    convert(importo / (select importo 
        from trans_grouped g 
        where g.mese = t.mese -1
    ), decimal(10,2)) percentuale
from trans_grouped t 
order by anno, mese
)
select anno, mese, importo, mese_precedente, percentuale, 
case when percentuale is null then '▬' when percentuale >= 1 then '▲' else '▼' end andamento 
from analisi;


/*---10.	Quantità di Prodotti Disponibili:
	Domanda: Determina la quantità media disponibile per categoria di prodotto.*/

SELECT Categoria, AVG (QuantitaDisponibile) AS quantita_media_categoria 
	FROM prodotti
	GROUP BY Categoria
	ORDER BY quantita_media_categoria DESC;

/*---11.	Analisi Spedizioni:
	Domanda: Trova il metodo di spedizione più utilizzato.*/
 SELECT MetodoSpedizione,COUNT(MetodoSpedizione) AS spedizione_più_utilizzata
	FROM spedizioni
	GROUP BY MetodoSpedizione
    ORDER BY spedizione_più_utilizzata DESC LIMIT 1; 
    
/*---12.	Analisi dei Clienti:
	Domanda: Calcola il numero medio di clienti registrati al mese.
**** siamo partiti da questa query per sviluppare quelle che seguono---
SELECT MONTH(DataRegistrazione) AS mese, COUNT(ClienteID) AS numero_clienti_registrati_mese
FROM clienti
GROUP BY MONTH(DataRegistrazione)
ORDER BY mese ASC;
--MEDIA ANNO-*/
WITH conteggio_n_clienti_registrati AS (
    -- Query della CTE
	SELECT MONTH(DataRegistrazione) AS mese, COUNT(ClienteID) AS numero_clienti_registrati_mese
	FROM clienti
	GROUP BY MONTH(DataRegistrazione)
)
-- Query principale che fa riferimento alla CTE
	SELECT AVG(numero_clienti_registrati_mese) AS media_registrazioni_clienti
	FROM conteggio_n_clienti_registrati;

	WITH conteggio_n_clienti_registrati AS (
    -- Query della CTE
		SELECT MONTH(DataRegistrazione) AS mese, COUNT(ClienteID) AS numero_clienti_registrati_mese
		FROM clienti
		GROUP BY MONTH(DataRegistrazione)
)
SELECT SUM(numero_clienti_registrati_mese)/12 AS media_registrazioni_clienti_annuale
	FROM conteggio_n_clienti_registrati;


/*---
13.	Prodotti Rari:
○	Domanda: Identifica i prodotti con una quantità disponibile inferiore alla media.*/


SELECT ProdottoID AS prodotto_raro, QuantitaDisponibile AS quantita_disp
	FROM prodotti
	WHERE QuantitaDisponibile < (SELECT AVG(QuantitaDisponibile) FROM prodotti)
	GROUP BY ProdottoID;

/*---
14.	Analisi dei Prodotti per Cliente:
	Domanda: Per ogni cliente, elenca i prodotti acquistati e il totale speso.*/

SELECT ClienteID,transazioni.ProdottoID,QuantitaAcquistata, QuantitaAcquistata*Prezzo+ImportoTransazione AS spesa_cliente
	FROM prodotti
	JOIN transazioni
	ON prodotti.ProdottoID = transazioni.ProdottoID
	GROUP BY ClienteID,transazioni.ProdottoID,QuantitaAcquistata
    ORDER BY transazioni.prodottoID;


/*---15.	Miglior Mese per le Vendite:
	Domanda: Identifica il mese con il maggior importo totale delle vendite.*/

SELECT MONTH(DataTransazione) AS Mese, ROUND(SUM(QuantitaAcquistata*Prezzo), 2) AS Incasso_Totale_Mese
	FROM prodotti
	JOIN transazioni
	ON prodotti.ProdottoID = transazioni.ProdottoID
	GROUP BY MONTH(DataTransazione)
    ORDER BY Incasso_Totale_Mese DESC 
    LIMIT 1;


/*
16.	Analisi dei Prodotti in Magazzino:
	Domanda: Trova la quantità totale di prodotti disponibili in magazzino.*/

SELECT SUM(QuantitaDisponibile) AS Tot_merce_magazzino
	FROM prodotti
	ORDER BY Tot_merce_magazzino DESC;

/*17.	Clienti Senza Acquisti:
	Domanda: Identifica i clienti che non hanno effettuato alcun acquisto.*/



/*17.1*/
SELECT clienti.ClienteID AS clienti_senza_acquisti
	FROM clienti
	LEFT JOIN transazioni
	ON clienti.ClienteID=transazioni.ClienteID
	GROUP BY clienti.ClienteID
	HAVING COUNT(transazioni.TransazioneID) = 0;

/*17.2*/
SELECT clienti.ClienteID AS clienti_senza_acquisti
	FROM clienti
	WHERE NOT EXISTS (
		SELECT 1
		FROM transazioni
		WHERE clienti.ClienteID = transazioni.ClienteID
);

/*
18.	Analisi Annuale delle Vendite:
	Domanda: Calcola il totale delle vendite per ogni anno.*/


SELECT YEAR(DataTransazione), ROUND(SUM(QuantitaAcquistata*Prezzo), 2) AS TotaleVendite_anno
	FROM prodotti
	JOIN transazioni
	ON prodotti.ProdottoID = transazioni.ProdottoID;

/*
19.	Spedizioni in Ritardo:
	Domanda: Trova la percentuale di spedizioni con "In Consegna" rispetto al totale*/
 
 SELECT StatusConsegna, COUNT(StatusConsegna)/(SELECT COUNT(*) FROM spedizioni)* 100 AS percentuale
	FROM spedizioni
    WHERE StatusConsegna='In Consegna'
	GROUP BY StatusConsegna
    ;
