-- =====================================================================================
--  ARQUIVO 5:  AS CINCO PERGUNTAS DE NEGOCIO
--  Case: Pata Amiga - rede de petshops de SC  |  MySQL 8.0
-- =====================================================================================
--  Rode depois de: 04-fato.sql
--
--  Cada pergunta e UMA consulta: um SELECT com JOIN e GROUP BY. A subconsulta
--  aparece na P2 e na P5, e serve para trazer o total da rede como denominador.
-- =====================================================================================

USE dw_pata_amiga;

-- =====================================================================================
--  P1 - ONDE ESTA O GARGALO DO PROCESSO DE ENTREGA?
-- =====================================================================================
--  Media (AVG) dos quatro intervalos ja calculados na carga, agrupada por porte
--  de loja. AVG ignora NULL - por isso a etapa nao cumprida foi gravada como NULL.
--  dias_total_ate_entrega e o processo inteiro, nao um dos quatro intervalos.

-- >>> ESCREVA AQUI a consulta da P1

SELECT
    ROUND(AVG(dias_integracao_separacao), 2) AS media_integracao_separacao,
    ROUND(AVG(dias_separacao_nota), 2) AS media_separacao_nota,
    ROUND(AVG(dias_nota_despacho), 2) AS media_nota_despacho,
    ROUND(AVG(dias_despacho_entrega), 2) AS media_despacho_entrega,
    ROUND(AVG(dias_total_ate_entrega), 2) AS media_total_ate_entrega
FROM fato_pedido;
-- Resposta: Nota-se que no intervalo nota/despacho a média(4.11 dias) está significativamente acima dos outros intervalos.

-- ------------

-- Quantidade de pedidos em cada etapa
SELECT
    COUNT(dias_integracao_separacao) AS pedidos_integracao_separacao,
    COUNT(dias_separacao_nota) AS pedidos_separacao_nota,
    COUNT(dias_nota_despacho) AS pedidos_nota_despacho,
    COUNT(dias_despacho_entrega) AS pedidos_despacho_entrega
FROM fato_pedido;

-- ----------------

-- comparar os três portes de loja - pequena/media/grande
SELECT
    l.porte,
    ROUND(AVG(f.dias_integracao_separacao), 2) AS media_integracao_separacao,
    ROUND(AVG(f.dias_separacao_nota), 2)        AS media_separacao_nota,
    ROUND(AVG(f.dias_nota_despacho), 2)         AS media_nota_despacho,
    ROUND(AVG(f.dias_despacho_entrega), 2)      AS media_despacho_entrega,
    ROUND(AVG(f.dias_total_ate_entrega), 2)     AS media_total
FROM fato_pedido AS f
JOIN dim_loja AS l ON f.sk_loja = l.sk_loja
WHERE l.sk_loja <> -1
GROUP BY l.porte
ORDER BY l.porte;

-- Resposta: O porte de loja 'pequena' está com média total(15.16 dias),
-- o maior gargalo continua sendo em nota/despacho, porém no porte 'Pequena' se mostra mais que o dobro em relação a 'Media' e 'Grande'. 
-- Também pode-se ver uma diferença significativa do intervalo integração/separacao do porte 'Pequena' comparado com 'Media' e 'Grande'. 

-- ------------

-- Resposta completa: O intervalo Nota/Despacho apresenta a maior média, com 4,11 dias, sendo o principal gargalo do processo.
-- O porte de loja Pequena apresenta média total de 15,16 dias, mais que o dobro das médias observadas nos portes Média e Grande.
-- Também se observa uma diferença relevante no intervalo Integração/Separação das lojas Pequenas em relação às lojas Média e Grande.




-- =====================================================================================
--  P2 - QUAL CATEGORIA CONCENTRA O FATURAMENTO?
-- =====================================================================================
--  Esta e a pergunta que paga a dim_categoria. Agrupe pelo nome_categoria
--  PADRONIZADO (nunca pela grafia crua). O percentual do total usa uma
--  subconsulta com o faturamento da rede como denominador.

-- >>> ESCREVA AQUI a consulta da P2

SELECT
    c.nome_categoria,
    ROUND(SUM(f.vl_liquido), 2) AS faturamento_total
FROM fato_pedido AS f
JOIN dim_categoria AS c
    ON f.sk_categoria = c.sk_categoria
WHERE f.vl_liquido IS NOT NULL
  AND c.sk_categoria <> -1
GROUP BY c.nome_categoria
ORDER BY faturamento_total DESC;
-- Resposta: A categoria de Ração concentra o maior faturamento com R$ 1.076.202,55

-- -----------

-- verificar o percentual do total
SELECT
    c.nome_categoria,
    ROUND(SUM(f.vl_liquido), 2) AS faturamento_total,
    ROUND(100 * SUM(f.vl_liquido) /
        (SELECT SUM(vl_liquido) FROM fato_pedido WHERE vl_liquido IS NOT NULL), 2
    ) AS percentual
FROM fato_pedido AS f
JOIN dim_categoria AS c ON f.sk_categoria = c.sk_categoria
WHERE f.vl_liquido IS NOT NULL AND c.sk_categoria <> -1
GROUP BY c.nome_categoria
ORDER BY faturamento_total DESC;
-- Resposta: A categoria Ração representa 60.01% do total. 

-- ----------- 

-- comparar por porte de loja
SELECT
    l.porte,
    c.nome_categoria,
    ROUND(SUM(f.vl_liquido), 2) AS faturamento_total
FROM fato_pedido AS f
JOIN dim_categoria AS c ON f.sk_categoria = c.sk_categoria
JOIN dim_loja AS l ON f.sk_loja = l.sk_loja
WHERE f.vl_liquido IS NOT NULL
  AND c.sk_categoria <> -1
  AND l.sk_loja <> -1
GROUP BY l.porte, c.nome_categoria
ORDER BY l.porte, faturamento_total DESC;
-- Resposta: A categoria de Ração é a de maior faturamento nos três portes de loja. 

-- ------------

-- Resposta completa: A categoria de Ração concentra o maior faturamento, com R$ 1.076.202,55, representando 60,01% do faturamento total.
--                    A categoria de Ração também apresenta o maior faturamento nos três portes de loja: Pequena, Média e Grande.



-- =====================================================================================
--  P3 - O DESCONTO FUNCIONA IGUAL EM TODO CANAL?
-- =====================================================================================
--  Aqui NAO ha JOIN: desconto e canal foram padronizados na carga e moram na
--  propria fato. Compare o TICKET MEDIO com e sem desconto DENTRO de cada canal.
--  Confira se o WhatsApp aparece - se nao, o CASE do arquivo 04 testou APP antes
--  de WHATS.

-- >>> ESCREVA AQUI a consulta da P3

-- Como o desconto varia por canal?
SELECT
    f.canal_pedido,
    f.houve_desconto,
    COUNT(*) AS quantidade_pedidos
FROM fato_pedido AS f
GROUP BY
    f.canal_pedido,
    f.houve_desconto
ORDER BY
    f.canal_pedido,
    quantidade_pedidos DESC;
-- Resposta: Observa-se que em todos os canais a maior parte das vendas são com desconto. 

-- ------ 

-- percentual de pedidos com desconto por canal
SELECT
    canal_pedido,
    COUNT(*) AS total_pedidos,
    SUM(
        CASE
            WHEN houve_desconto = 'Sim' THEN 1
            ELSE 0
        END
    ) AS pedidos_com_desconto,
    ROUND(
        100 * SUM(
            CASE
                WHEN houve_desconto = 'Sim' THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS percentual_com_desconto
FROM fato_pedido
GROUP BY canal_pedido
ORDER BY percentual_com_desconto DESC;
-- Resposta: 85,23% dos pedidos feitos com canal 'Nao Informado' possuem desconto,
-- podemos concluir isso como uma limitação da qualidade dos dados que não nos permite avaliar adequadamente a política de descontos. 

-- -----------

 -- ticket médio com e sem desconto por canal
 SELECT
    canal_pedido,
    houve_desconto,
    COUNT(*) AS quantidade_pedidos,
    ROUND(AVG(vl_liquido), 2) AS ticket_medio,
    ROUND(SUM(vl_liquido), 2) AS faturamento_total,
    ROUND(100 * SUM(vl_liquido) /
        (SELECT SUM(vl_liquido) FROM fato_pedido WHERE vl_liquido IS NOT NULL), 2
    ) AS percentual_faturamento
FROM fato_pedido
WHERE vl_liquido IS NOT NULL
  AND houve_desconto <> 'Nao Informado'
GROUP BY canal_pedido, houve_desconto
ORDER BY canal_pedido, houve_desconto;
-- Resposta: Pode-se observar que os pedidos com desconto apresentam ticket médio superior aos pedidos sem desconto. 
--           O resultado indica uma associação entre desconto e maior ticket médio, mas não permite afirmar que o desconto seja a causa desse aumento. 
--           Os pedidos com desconto realizados pelos canais App e Site, em conjunto, representam aproximadamente 50% do faturamento total

-- ---------------

-- Resposta completa: 
-- Observa-se que, nos canais analisados, a maior parte dos pedidos foi realizada com desconto. Entre os canais conhecidos, os percentuais são relativamente próximos, variando de aproximadamente 79,75% a 82,88%, com o App apresentando o maior percentual e o Site o menor.
-- 85,23% dos pedidos com canal "Não Informado" possuem desconto, porém esse grupo não permite avaliar adequadamente a política de descontos por canal, sendo tratado como uma limitação da qualidade dos dados.
-- Observa-se também que, na amostra analisada, os pedidos com desconto apresentam ticket médio superior aos pedidos sem desconto. Esse resultado indica uma associação entre desconto e maior ticket médio, mas não permite afirmar que o desconto seja a causa desse aumento.
-- Os pedidos com desconto realizados pelos canais App e Site, em conjunto, representam aproximadamente 50% do faturamento total, indicando a relevância desses canais no faturamento associado a pedidos com desconto.



-- =====================================================================================
--  P4 - QUAL PRACA DE ATENDIMENTO CONCENTRA O FATURAMENTO?
-- =====================================================================================
--  Esta e a pergunta que paga a dim_praca e a ponte.
--  Caminho: fato_pedido -> dim_loja -> bridge_loja_praca -> dim_praca (a ponte
--  entra pelo cod_loja). O JOIN com a ponte DUPLICA a linha do pedido, uma por
--  praca - isso esta certo. Multiplique por b.fator_publico para o faturamento
--  nao ser contado duas vezes.

-- >>> ESCREVA AQUI a consulta da P4

SELECT
    p.nome_praca,
    ROUND(
        SUM(
            f.vl_liquido * b.fator_publico
        ),
        2
    ) AS faturamento_alocado
FROM fato_pedido AS f
JOIN dim_loja AS l
    ON f.sk_loja = l.sk_loja
JOIN bridge_loja_praca AS b
    ON l.cod_loja = b.cod_loja
JOIN dim_praca AS p
    ON b.sk_praca = p.sk_praca
WHERE f.vl_liquido IS NOT NULL
  AND f.sk_loja <> -1
  AND p.sk_praca <> -1
GROUP BY p.nome_praca
ORDER BY faturamento_alocado DESC;
-- Resposta: A praça 'Vale do Itajaí' lidera com folga o ranking de faturamento

-- ----------------

-- conferencia:
-- Soma do faturamento alocado deve reconciliar com o faturamento total da rede
SELECT
    ROUND(
        SUM(f.vl_liquido),
        2
    ) AS faturamento_rede
FROM fato_pedido AS f
WHERE f.vl_liquido IS NOT NULL;
-- Resposta: R$ 1.793.308.51 -- pequena diferença devido arredondamento do rateio 
-- esperado: R$ 1.793.309

-- -----------------

-- cruzar 'faturamento rateado' com 'domicílios com pet' de cada praça 
SELECT
    p.nome_praca,
    p.domicilios_com_pet,
    ROUND(SUM(f.vl_liquido * b.fator_publico), 2) AS faturamento_alocado,
    ROUND(SUM(f.vl_liquido * b.fator_publico) / p.domicilios_com_pet, 2) AS faturamento_por_domicilio
FROM fato_pedido AS f
JOIN dim_loja AS l ON f.sk_loja = l.sk_loja
JOIN bridge_loja_praca AS b ON l.cod_loja = b.cod_loja
JOIN dim_praca AS p ON b.sk_praca = p.sk_praca
WHERE f.vl_liquido IS NOT NULL
  AND f.sk_loja <> -1
  AND p.sk_praca <> -1
GROUP BY p.nome_praca, p.domicilios_com_pet
ORDER BY faturamento_por_domicilio DESC;
-- Resposta: Vale do Itajai apresenta o maior faturamento por domicilio,
-- com R$4,28, contra R$2,36 do Litoral Sul em segundo lugar. 


-- -----------------

-- Resposta completa:
-- A praça Vale do Itajaí concentra o maior faturamento alocado entre as praças.
-- obs: O faturamento foi distribuído entre as praças utilizando o fator público da bridge, permitindo uma alocação proporcional do faturamento das lojas.
-- Na análise por domicílios com animais de estimação, o Vale do Itajaí apresenta R$ 4,28 de faturamento alocado por domicílio, enquanto o Litoral Sul apresenta R$ 2,36, demonstrando diferença relevante entre as praças.
-- obs: A análise foi reconciliada com o faturamento total da rede, de aproximadamente R$ 1.793.309, considerando também os pedidos sem loja identificada.




-- =====================================================================================
--  P5 - ONDE ABRIR A PROXIMA LOJA, E O QUE OS DADOS NAO PERMITEM AFIRMAR?
-- =====================================================================================
--  (a) Ranqueie as lojas por itens POR MIL HABITANTES (numerador na fato,
--      denominador na dimensao), calculado AQUI na consulta - nunca gravado
--      pronto. Cruze com o tempo medio de entrega.
--  (b) Mostre o faturamento por faixa de franquia e explique por que ele NAO
--      responde "quanto veio de lojas que JA ERAM Ouro na data do pedido": o
--      cadastro so tem a foto de hoje.
--  (c) Meca o que ficou de fora: pedidos sem loja, entregas nao concluidas,
--      itens e valores em branco.

-- >>> ESCREVA AQUI as consultas da P5


-- ranking de itens por mil habitantes
SELECT
    l.nome_loja,
    l.cidade,
    l.porte,
    l.faixa_franquia,
    SUM(f.qt_itens) AS total_itens,
    l.populacao_cidade,
    ROUND(1000 * SUM(f.qt_itens) / l.populacao_cidade, 2) AS itens_por_mil_hab,
    ROUND(AVG(f.dias_total_ate_entrega), 2) AS media_dias_entrega
FROM fato_pedido AS f
JOIN dim_loja AS l ON f.sk_loja = l.sk_loja
WHERE l.sk_loja <> -1
  AND f.qt_itens IS NOT NULL
GROUP BY l.sk_loja, l.nome_loja, l.cidade, l.porte, l.faixa_franquia, l.populacao_cidade
ORDER BY itens_por_mil_hab DESC;
-- Resposta: As três melhores lojas em vendas por mil habitantes são 'Rio dos Cedros', 'Presidente Getútio' e 'Ibirama'
--           Observa-se que as três lojas são de porte 'pequena' e possuem uma média de dias de entrega acima de 14 dias. 
  
-- -----------------

-- faturamento por faixa de franquia
SELECT
    l.faixa_franquia,
    COUNT(DISTINCT f.sk_loja) AS total_lojas,
    ROUND(SUM(f.vl_liquido), 2) AS faturamento_total
FROM fato_pedido AS f
JOIN dim_loja AS l ON f.sk_loja = l.sk_loja
WHERE l.sk_loja <> -1
  AND f.vl_liquido IS NOT NULL
GROUP BY l.faixa_franquia
ORDER BY faturamento_total DESC;
-- Resposta: Observa-se que a faixa 'Ouro' lidera o faturamento total com 15 lojas. 
-- Não é possível afirmar, a partir desses dados, que uma determinada faixa histórica de franquia
-- gerou mais faturamento durante o período analisado, pois a classificação disponível representa o estado atual das lojas.

-- ------------------

-- medir o que ficou de fora
SELECT
    SUM(CASE WHEN sk_loja = -1 THEN 1 ELSE 0 END)          AS pedidos_sem_loja,
    SUM(CASE WHEN sk_tempo_entrega = -1 THEN 1 ELSE 0 END)  AS entregas_nao_concluidas,
    SUM(CASE WHEN qt_itens IS NULL THEN 1 ELSE 0 END)       AS itens_em_branco,
    SUM(CASE WHEN vl_liquido IS NULL THEN 1 ELSE 0 END)     AS valores_em_branco
FROM fato_pedido;
-- Resposta: Temos os seguintes dados
-- pedidos sem loja: 03
-- entregas não concluidas: 1953
-- itens em branco: 257
-- valores em branco: 121

-- -------------------

-- Resposta completa:
-- O ranking por itens vendidos por 1.000 habitantes aponta Rio dos Cedros (41,87), Presidente Getúlio (34,84) e Ibirama (32,07) como as três cidades com maior intensidade de vendas relativa à população.
-- Essas cidades, entretanto, também apresentam elevados tempos médios de entrega, de aproximadamente 14 a 16 dias, o que representa um ponto de atenção logístico.
-- Dessa forma, Rio dos Cedros seria a primeira cidade a ser investigada para uma possível expansão, seguida por Presidente Getúlio e Ibirama. Os dados disponíveis indicam potencial de demanda relativa, mas não permitem afirmar isoladamente qual cidade deve receber a próxima loja.
-- Para uma decissão mais assertiva, seria necessário complementar a análise com informações como distância das lojas, custos de implantação, potencial de crescimento da demanda, entre outros. 

