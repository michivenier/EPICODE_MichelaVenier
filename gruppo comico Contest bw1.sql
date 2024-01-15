#1. Quali prodotti vendono meglio in determinati periodi dell’anno?

WITH VenditeQuadrimestrali AS (
    SELECT ProdottoID, QUARTER(DataTransazione) AS Trimestre_delle_vendite, SUM(QuantitaAcquistata) AS TotaleVendite,
        RANK() OVER (PARTITION BY QUARTER(DataTransazione) ORDER BY SUM(QuantitaAcquistata) DESC) AS Ranking
    FROM transazioni
    GROUP BY ProdottoID, QUARTER(DataTransazione)
)
SELECT ProdottoID, Trimestre_delle_vendite,TotaleVendite
FROM VenditeQuadrimestrali
WHERE   Ranking = 1
ORDER BY Trimestre_delle_vendite ASC, ProdottoID ASC;

#2. Selezione i primi 3 clienti che hanno il prezzo medio di acquisto più alto in ogni categoria di prodotto.
WITH SpesaMediaCategoriaCliente AS (
    SELECT
        Categoria, ClienteID, AVG(QuantitaAcquistata * Prezzo) AS SpesaMedia,
        RANK() OVER (PARTITION BY Categoria ORDER BY AVG(QuantitaAcquistata * Prezzo) DESC) AS Ranking
    FROM prodotti
    JOIN transazioni ON prodotti.ProdottoID = transazioni.ProdottoID
    GROUP BY Categoria, ClienteID
)
SELECT Categoria, ClienteID, SpesaMedia
FROM SpesaMediaCategoriaCliente
WHERE Ranking <= 3
ORDER BY Categoria ASC, SpesaMedia DESC;

/*3*/
SELECT ProdottoID AS prodotto_raro, QuantitaDisponibile AS quantita_disp
	FROM prodotti
	WHERE QuantitaDisponibile < (SELECT AVG(QuantitaDisponibile) FROM prodotti)
	GROUP BY ProdottoID, QuantitaDisponibile;

# 4. Media delle recensioni dei clienti il cui tempo di elaborazione dell'ordine è inferiore a 30gg
SELECT AVG(ratings_dataset.Rating), DATEDIFF(transazioni.DataSpedizione,transazioni.DataTransazione) AS Tempo_presa_in_consegna
 FROM transazioni
    JOIN  ratings_dataset
    ON transazioni.ClienteID=ratings_dataset.CustomerID
    GROUP BY ratings_dataset.Rating,Tempo_presa_in_consegna
    HAVING Tempo_presa_in_consegna<30
	ORDER BY Tempo_presa_in_consegna DESC;

/*5*/
SELECT transazioni.TransazioneID, DATEDIFF(transazioni.DataSpedizione,transazioni.DataTransazione) AS Tempo_presa_in_consegna,
	    CASE WHEN DATEDIFF (transazioni.DataSpedizione, transazioni.DataTransazione)>365 THEN 'Più di un anno'
        ELSE 'Meno di un anno' END AS piu_o_meno_di_un_anno
 FROM transazioni
    JOIN spedizioni ON spedizioni.SpedizioneID=transazioni.SpedizioneID
    GROUP BY transazioni.TransazioneID, transazioni.DataSpedizione, transazioni.DataTransazione
	ORDER BY Tempo_presa_in_consegna DESC;

/*6*/
SELECT Categoria, SUM(QuantitaDisponibile) AS Totale_disponibilita_categorie
	FROM prodotti
	GROUP BY Categoria
	ORDER BY Totale_disponibilita_categorie DESC
	LIMIT 3;
    
#7. Si vuole stampare Nome del cliente, Importo transazione (prezzo * quantità),Nome Prodotto e Rating MEDIO del prodotto. Aggiungere colonna OUTPUT che avrà i seguenti valori:
#SE la transazione supera il valore medio di tutte le transazioni dell’anno stampare “Sopra La Media” altrimenti “Sotto la media”
SELECT c.NomeCliente, (t.QuantitaAcquistata*p.Prezzo) AS incasso_transazione, p.NomeProdotto, AVG(r.Rating), AVG(t.QuantitaAcquistata*p.Prezzo),
CASE WHEN (t.QuantitaAcquistata*p.Prezzo)>AVG(t.QuantitaAcquistata*p.Prezzo) THEN 'Sopra La Media' ELSE 'Sotto la media' END AS output 
	FROM transazioni t
    JOIN clienti c
    ON t.ClienteID=c.ClienteID
    JOIN prodotti p
    ON t.ProdottoID=p.ProdottoID
    JOIN ratings_dataset r
    ON t.ProdottoID=r.ProductID
		GROUP BY c.NomeCliente, t.QuantitaAcquistata, p.Prezzo,p.NomeProdotto
		ORDER BY c.NomeCliente ASC;

#8. Trovare tutti i clienti che si sono registrati nel mese con più profitto
WITH mese_con_più_profitto AS (
    SELECT MONTH(DataRegistrazione) AS Mese_reg, ROUND(SUM(QuantitaAcquistata*Prezzo), 2) AS Incasso_Totale_Mese
    FROM prodotti
    JOIN transazioni
    ON prodotti.ProdottoID = transazioni.ProdottoID
    JOIN clienti
    ON transazioni.ClienteID=clienti.ClienteID
    GROUP BY MONTH(DataRegistrazione)
    ORDER BY Incasso_Totale_Mese DESC 
    LIMIT 1
)
SELECT ClienteID 
FROM mese_con_più_profitto
ORDER BY MONTH(DataRegistrazione) ASC;


/*3*/
SELECT ProdottoID AS prodotto_raro, QuantitaDisponibile AS quantita_disp
	FROM prodotti
	WHERE QuantitaDisponibile < (SELECT AVG(QuantitaDisponibile) FROM prodotti)
	GROUP BY ProdottoID, QuantitaDisponibile;

SELECT MONTH(DataTransazione) AS Mese, ROUND(SUM(QuantitaAcquistata*Prezzo), 2) AS Incasso_Totale_Mese
    FROM prodotti
    JOIN transazioni
    ON prodotti.ProdottoID = transazioni.ProdottoID
    GROUP BY MONTH(DataTransazione)
    ORDER BY Incasso_Totale_Mese DESC 
    LIMIT 1;