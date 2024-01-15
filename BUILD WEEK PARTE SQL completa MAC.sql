SELECT MONTH(DataTransazione) AS Mese, ROUND(SUM(QuantitaAcquistata*Prezzo), 2) AS TotaleVendite
FROM prodotti JOIN transazioni ON prodotti.ProdottoID = transazioni.ProdottoID
GROUP BY MONTH(DataTransazione);

/*--RISPOSTA_2--*/
SELECT ProdottoID, SUM(QuantitaAcquistata) AS totale_quantita_venduta
FROM transazioni
GROUP BY ProdottoID
ORDER BY totale_quantita_venduta DESC, ProdottoID ASC
LIMIT 3;
/*--RISPOSTA_3--*/

SELECT ClienteID, COUNT(QuantitaAcquistata) AS totale_acquisti
FROM transazioni
GROUP BY ClienteID
ORDER BY totale_acquisti DESC, ClienteID ASC
LIMIT 3;

/*--RISPOSTA_4.1 SPEDIZIONE--*/
SELECT AVG(ImportoTransazione) AS valore_medio_spedizione
FROM transazioni;
/*--RISPOSTA_4.2 AZIENDA--*/
SELECT AVG(QuantitaAcquistata*Prezzo) AS spesa_media
FROM prodotti
JOIN transazioni
ON prodotti.prodottoID = transazioni.prodottoID;
/*--RISPOSTA_4.3 CLIENTE--*/
SELECT AVG(QuantitaAcquistata*Prezzo+ImportoTransazione) AS spesa_mediatot
FROM prodotti
JOIN transazioni
ON prodotti.prodottoID = transazioni.prodottoID;


/*-DOMANDA BONUS: CALCOLO QUANTITA PER CATEGORIA IN STORE*/

SELECT Categoria, SUM(QuantitaDisponibile) AS Totale_quantita
FROM prodotti
GROUP BY Categoria
ORDER BY Totale_quantita DESC
LIMIT 3; #3 CATEGORIE di prodotti

/*--RISPOSTA_5--Determina la categoria di prodotto con il maggior numero di vendite.*/
SELECT Categoria, SUM(QuantitaAcquistata) AS Numero_oggetti_venduti_per_categoria
FROM prodotti
JOIN transazioni
ON prodotti.prodottoID = transazioni.prodottoID
GROUP BY Categoria
ORDER BY SUM(QuantitaAcquistata) DESC;

/*RISPOSTA_6--Cliente Fedele: Identifica il cliente con il maggior valore totale di acquisti*/


SELECT ClienteID, QuantitaAcquistata*Prezzo+ImportoTransazione AS spesa_TOT_cliente
FROM prodotti
JOIN transazioni
ON prodotti.prodottoID = transazioni.prodottoID
GROUP BY ClienteID, spesa_TOT_cliente #mac
ORDER BY spesa_TOT_cliente DESC
LIMIT 1;

/*--RISPOSTA_7 PLUS--percentuale di spedizioni con "consegna riuscita"*/

SELECT MetodoSpedizione, StatusConsegna, 
COUNT(StatusConsegna)/(SELECT COUNT(*) FROM spedizioni)*100 AS percentuale
FROM spedizioni 
GROUP BY MetodoSpedizione,StatusConsegna;

SELECT StatusConsegna, COUNT(StatusConsegna)/(SELECT COUNT(*) FROM spedizioni)*100 AS percentuale
FROM spedizioni WHERE StatusConsegna = "Consegna Riuscita" GROUP BY StatusConsegna;

/*--RISPOSTA_8--prodotto con la recensione media più alta*/

SELECT ProductID, AVG(Rating) AS recensione_media_piu_alta, COUNT(Rating) AS conteggio
FROM ratings_dataset GROUP BY ProductID
ORDER BY recensione_media_piu_alta DESC, conteggio DESC, ProductID ASC
LIMIT 3; /*VERIFICA CONTEGGIO*/

/*--RISPOSTA_9--variazione percentuale nelle vedite rispetto al mese precedente*/
with trans_grouped as ( -- common table expression (cte)
	select sum(importotransazione) AS importo
		, year(datatransazione) AS anno
        , month(datatransazione) AS mese
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
	), decimal(8,2)) percentuale
from trans_grouped t 
order by anno, mese
)
select anno, mese, importo, mese_precedente, percentuale, 
case when percentuale is null then '▬' when percentuale >= 1 then '▲' else '▼' end andamento 
from analisi;

SELECT
   Mese, Tot_merce_venduta_mese, LAG(Tot_merce_venduta_mese) OVER (ORDER BY Mese) AS Tot_merce_venduta_mese_precedente,
    (Tot_merce_venduta_mese - LAG(Tot_merce_venduta_mese) OVER (ORDER BY Mese))/(SELECT COUNT(*) FROM transazioni)*100 AS Incremento_decremento_percentuale
FROM (
    SELECT MONTH(DataTransazione) AS Mese, SUM(QuantitaAcquistata) AS Tot_merce_venduta_mese
    FROM transazioni t
    GROUP BY MONTH(DataTransazione)
) AS VenditeMese;


/*--RISPOSTA_10--quantità media disponibile per categoria di prodotto*/
SELECT Categoria, AVG(QuantitaDisponibile) AS quanita_media_categoria
FROM prodotti GROUP BY Categoria;

/*--RISPOSTA_11--metodo di spedizione più utilizzato */
SELECT MetodoSpedizione, COUNT(MetodoSpedizione) AS spedizione_piu_utilizzata
FROM spedizioni GROUP BY MetodoSpedizione
ORDER BY spedizione_piu_utilizzata DESC LIMIT 1;

/*--RISPOSTA_12--Calcola il numero medio di clienti registrati al mese */

/* siamo partiti da questa query per poi proseguire con quelle che seguono
SELECT MONTH(DataRegistrazione) AS mese, 
COUNT(ClienteID) AS numero_clienti_registrazione_mese
FROM clienti GROUP BY mese ORDER BY mese ASC;*/

WITH conteggio_n_clienti_registrati AS (
SELECT MONTH(DataRegistrazione) AS mese, COUNT(ClienteID) AS numero_clienti_registrati_mese
FROM clienti GROUP BY MONTH(DataRegistrazione) 
)
SELECT AVG(numero_clienti_registrati_mese) AS media_clienti_registrati_mese
FROM conteggio_n_clienti_registrati;

WITH conteggio_n_clienti_registrati AS (
SELECT MONTH(DataRegistrazione) AS mese, COUNT(ClienteID) AS numero_clienti_registrati_mese
FROM clienti GROUP BY MONTH(DataRegistrazione) 
)
SELECT SUM(numero_clienti_registrati_mese)/12 AS media_regitro_cliente_annuale
FROM conteggio_n_clienti_registrati;

/*--RISPOSTA_13--Identifica i prodotti con una quantità disponibile inferiore alla media */

SELECT ProdottoID AS prodottoraro, QuantitaDisponibile AS quantita_disponibile 
FROM prodotti WHERE QuantitaDisponibile < (SELECT AVG(QuantitaDisponibile) FROM prodotti) 
GROUP BY ProdottoID, QuantitaDisponibile ;

/*--RISPOSTA_14--Per ogni cliente, elenca i prodotti acquistati e il totale speso */
SELECT ClienteID, transazioni.ProdottoID, QuantitaAcquistata,QuantitaAcquistata*Prezzo+ImportoTransazione AS spesa_cliente
FROM prodotti JOIN transazioni ON prodotti.ProdottoID = transazioni.ProdottoID 
GROUP BY ClienteID, transazioni.ProdottoID, QuantitaAcquistata, spesa_cliente ORDER BY transazioni.ProdottoID;

/*--RISPOSTA_15--Identifica il mese con il maggior importo totale delle vendite */
SELECT MONTH(DataTransazione) AS Mese, ROUND(SUM(QuantitaAcquistata*Prezzo), 2) AS Incasso_Totale_Mese
    FROM prodotti
    JOIN transazioni
    ON prodotti.ProdottoID = transazioni.ProdottoID
    GROUP BY MONTH(DataTransazione)
    ORDER BY Incasso_Totale_Mese DESC 
    LIMIT 1;


/*--RISPOSTA_16--Trova la quantità totale di prodotti disponibili in magazzino */
SELECT SUM(QuantitaDisponibile) AS Tot_merce_magazzino FROM prodotti
ORDER BY Tot_merce_magazzino DESC;


/*--RISPOSTA_17--Identifica i clienti che non hanno effettuato alcun acquisto */
#METODO 1:
SELECT clienti.ClienteID AS clienti_senza_acquisti  
	FROM clienti  
	LEFT JOIN transazioni
    ON clienti.ClienteID = transazioni.ClienteID
	GROUP BY clienti.ClienteID HAVING COUNT(transazioni.TransazioneID) = 0;

#METODO 2:
SELECT clienti.ClienteID AS clienti_senza_acquisti  
	FROM clienti 
	WHERE NOT EXISTS (
		SELECT 1
		FROM transazioni 
		WHERE clienti.ClienteID = transazioni.ClienteID);

/*--RISPOSTA_18--Calcola il totale delle vendite per ogni anno */
SELECT YEAR(DataTransazione) AS Anno, ROUND(SUM(QuantitaAcquistata*Prezzo), 1) AS totale_vendite_anno
FROM prodotti JOIN transazioni ON prodotti.ProdottoID = transazioni.ProdottoID GROUP BY Anno;


/*--RISPOSTA_19--Trova la percentuale di spedizioni con "In Consegna" rispetto al totale */
SELECT StatusConsegna AS in_consegna, COUNT(StatusConsegna)/(SELECT COUNT(*) FROM spedizioni)*100 AS percentuale
FROM spedizioni WHERE StatusConsegna = "In Consegna" GROUP BY  StatusConsegna;
