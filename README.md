# Pata Amiga — Data Warehouse

|                         |                                          |
| ----------------------- | ---------------------------------------- |
| **Autor**         | Rodrigo Maduell Fonseca                  |
| **Turma**         | Análise de Dados com Python - T2 - 2026 |
| **Instituição** | SCTEC/SENAI-SC                           |
| **Projeto**       | Mini-Projeto Avaliativo — Módulo 2     |

---

## Descrição do Case

A Pata Amiga é uma rede catarinense de pet shops com 32 lojas espalhadas pelo estado.
Em setembro de 2023 a rede integrou seus canais de venda (app, site, telefone, WhatsApp
e loja física) e em sete meses acumulou 4.044 pedidos.

A diretoria quer usar esses sete meses para responder cinco perguntas estratégicas:
onde está o gargalo da entrega; qual categoria sustenta o faturamento; se a política
de desconto funciona igual em todo canal; onde concentra o faturamento por praça e
onde abrir a próxima loja.

---

## Modelo Dimensional

O modelo dimensional foi estruturado em esquema estrela, tendo `fato_pedido`
como tabela central, com granularidade de uma linha por pedido.

![Modelo Estrela](diagrama/modelo_estrela.png)

---

## Como reproduzir o projeto

Execute os scripts SQL na ordem numérica apresentada na pasta `sql/`:

1. `01-carga-staging.sql` — carrega os dados de origem.
2. `02-dimensoes-prontas.sql` — cria as dimensões fornecidas.
3. `03-dimensoes.sql` — cria e popula as dimensões construídas no projeto.
4. `04-fato.sql` — popula a tabela fato.
5. `05-perguntas.sql` — executa as cinco consultas de negócio.

---

## Apresentação do Projeto

Neste vídeo, apresento brevemente o projeto discorrendo sobre alguns aspectos
e até mesmo executando brevemente uma consulta para resposta de uma das
perguntas de negócio.

🎥 **[Assistir à apresentação do projeto](https://drive.google.com/file/d/1LtJpn5rMJgLqBksRP40cgDXXhLcbcGJ_/view?usp=sharing)**

---


## Diagnóstico da Origem

Aas três tabelas de staging foram inspecionadas.
Os números abaixo orientaram todas as decisões de limpeza.

| Item                                      | Resultado                           |
| ----------------------------------------- | ----------------------------------- |
| Grafias distintas de nome de loja         | 50 grafias para 32 lojas            |
| Grafias distintas de categoria de produto | 18 grafias para 7 categorias        |
| Pedidos sem Código de Loja               | 1.575 (~39% do total)               |
| Pedidos sem Nome de Loja                  | 3 pedidos                           |
| Grafias distintas de HouveDesconto        | 12 grafias para 3 valores           |
| Grafias distintas de CanalPedido          | 8 grafias para 6 canais             |
| Grafias distintas de FormaPagamento       | 9 grafias                           |
| Marcos em branco — Separação           | 1.077 pedidos                       |
| Marcos em branco — Nota Fiscal           | 1.338 pedidos                       |
| Marcos em branco — Despacho              | 1.665 pedidos                       |
| Marcos em branco — Entrega               | 1.953 pedidos (processos em aberto) |

---

## Perguntas de Negócio Respondidas

### P1 — Onde está o gargalo do processo de entrega?

O intervalo **Nota - Despacho** é o principal gargalo, com média de **4,11 dias,**
significativamente acima dos demais intervalos.

O tempo total médio do processo é de **9,00 dias**.

| Intervalo                    | Média (dias)             |
| ---------------------------- | ------------------------- |
| Integração  - Separação | 2,13                      |
| Separação - Nota Fiscal    | 0,64                      |
| **Nota - Despacho**    | **4,11 ← gargalo** |
| Despacho - Entrega           | 2,14                      |
| **Total**              | **9,00**            |

Na análise por porte de loja, as lojas de porte **Pequena** apresentam média total
de **15,16 dias,** mais que o dobro das lojas de porte Média e Grande.

O intervalo Nota - Despacho também se mostra mais crítico nesse porte, reforçando que o gargalo
logístico é maior nas lojas menores.

---

### P2 — Qual categoria concentra o faturamento?

A categoria **Ração** lidera com **R$ 1.076.202,55**, representando **60,01%** do
faturamento total da rede nos 7 meses analisados.

| Categoria   | Faturamento     | %      |
| ----------- | --------------- | ------ |
| Ração     | R$ 1.076.202,55 | 60,01% |
| Medicamento | R$ 305.904,03   | 17,06% |
| Petisco     | R$ 128.590,16   | 7,17%  |
| Serviço    | R$ 94.001,37    | 5,24%  |
| Higiene     | R$ 92.314,45    | 5,15%  |
| Acessório  | R$ 64.661,39    | 3,61%  |
| Brinquedo   | R$ 31.634,56    | 1,76%  |

A categoria Ração também lidera nos três portes de loja (Pequena, Média e Grande),
confirmando sua posição dominante independente do tamanho da operação.

---

### P3 — O desconto funciona igual em todo canal?

Em todos os canais analisados, a maior parte dos pedidos foi realizada **com desconto**.
Os percentuais entre os canais conhecidos são relativamente próximos, variando de
**79,75%** (Site) a **82,88%** (App).

Na comparação do ticket médio, os pedidos **com desconto apresentam ticket médio
superior** aos pedidos sem desconto em todos os canais. Esse resultado indica uma
associação entre desconto e maior ticket médio, mas **não permite afirmar que o
desconto seja a causa** desse aumento, pode refletir um perfil de compra diferente
entre quem utiliza ou não cupons.

> **Limitação:** 85,23% dos pedidos com canal "Não Informado" possuem desconto.
> Esse grupo não permite avaliar adequadamente a política de descontos por canal,
> sendo tratado como limitação de qualidade dos dados.

Os canais **App e Site**, em conjunto, representam aproximadamente **50% do
faturamento** associado a pedidos com desconto, indicando relevância estratégica.

---

### P4 — Qual praça de atendimento concentra o faturamento?

O faturamento foi distribuído entre as praças utilizando o **fator público da
bridge_loja_praca**, permitindo alocação proporcional do faturamento das lojas
que atendem múltiplas praças.

| Praça                | Faturamento Alocado                      | Domicílios c/ Pet | Fat./Domicílio |
| --------------------- | ---------------------------------------- | ------------------ | --------------- |
| Vale do Itajaí       | R$ 633.746,09 | maior praça | R$ 4,28 |                    |                 |
| Grande Florianópolis | R$ 283.546,75                            | —                 | —              |
| Norte Industrial      | R$ 175.431,90                            | —                 | —              |
| Litoral Sul           | R$ 137.051,20 | — | R$ 2,36           |                    |                 |

A praça **Vale do Itajaí** lidera tanto em faturamento absoluto quanto em
faturamento por domicílio com pet (R$ 4,28), contra R$ 2,36 do Litoral Sul
em segundo lugar — demonstrando diferença relevante entre as praças.

> **Nota:** A soma rateada das praças reconcilia com o faturamento total da rede
> (R$ 1.793.309), com diferença mínima de arredondamento. Os 3 pedidos sem loja identificada ficam fora do rateio.

---

### P5 — Onde abrir a próxima loja, e o que os dados não permitem afirmar?

#### (a) Ranking por itens por mil habitantes

As três cidades com maior intensidade de vendas relativa à população são:

| Loja                           | Cidade              | Itens/mil hab. | Média entrega (dias) |
| ------------------------------ | ------------------- | -------------- | --------------------- |
| Pata Amiga Rio dos Cedros      | Rio dos Cedros      | 41,87          | ~16                   |
| Pata Amiga Presidente Getúlio | Presidente Getúlio | 34,84          | ~15                   |
| Pata Amiga Ibirama             | Ibirama             | 32,07          | ~14                   |

As três são de porte **Pequena** e apresentam tempos médios de entrega elevados
(acima de 14 dias), representando um ponto de atenção logístico.

**Rio dos Cedros** seria a primeira cidade a ser investigada para expansão,
seguida por Presidente Getúlio e Ibirama. Os dados indicam potencial de demanda
relativa, mas não permitem afirmar isoladamente qual cidade deve receber a próxima
loja sem complementar com informações de custo de implantação, distância logística
 e potencial de crescimento.

#### (b) Faturamento por faixa de franquia — limitação importante

A faixa **Ouro** lidera o faturamento com 15 lojas. Porém esta análise **não
responde** "quanto veio de lojas que já eram Ouro na data do pedido".

A coluna `faixa_franquia` na `dim_loja` representa a situação **atual** da loja.
O histórico de mudanças de faixa não foi preservado,  **0 passado foi sobrescrito**.

Qualquer análise por faixa reflete apenas a classificação de hoje, independente
de quando o pedido foi feito.

#### (c) O que ficou de fora

| Item                          | Quantidade |
| ----------------------------- | ---------- |
| Pedidos sem loja identificada | 3          |
| Entregas não concluídas     | 1.953      |
| Itens em branco               | 257        |
| Valores em branco             | 121        |

Os 1.953 pedidos sem entrega concluída representam processos em aberto na data
de corte da base (31/03/2024) — não são erros de dados.

---

## Limitações — O que os dados NÃO permitem afirmar

- **Faixa de franquia histórica** — o cadastro é foto do momento atual; mudanças
  passadas foram sobrescritas.
- **Causalidade do desconto** — pedidos com desconto têm ticket médio maior,
  mas os dados não permitem isolar se o desconto causa o aumento ou se são
  perfis de compra diferentes.
- **Recomendação de nova loja** — o ranking por itens/mil hab. indica potencial
  relativo, mas a decisão final exige dados externos: custo de implantação,
  distância logística e potencial de crescimento, entre outros que poderiam
  enriquecer a análise.
- **Canal Não Informado** — representa pedidos cujo canal de origem não foi
  registrado corretamente no sistema de origem, limitando a análise de
  descontos por canais de venda.

---

## Melhorias Possíveis

- Adicionar camada **Gold** com views analíticas prontas para Power BI
- Corrigir o preenchimento do canal de pedido na fonte para eliminar os
  "Não Informado"
- Incluir dados externos de concorrência e demografia para enriquecer a P5

---

## Recomendação Final

Com base nos dados disponíveis,  **Rio dos Cedros deve ser a primeira cidade
investigada para uma possível expansão** , seguida por Presidente Getúlio e Ibirama.

A recomendação considera o elevado índice de itens vendidos por 1.000 habitantes,
mas deve ser validada com informações adicionais sobre logística, custos, concorrência,
renda, implantação e potencial de crescimento, etc.

Dessa forma, o Data Warehouse permite  **priorizar oportunidades de investigação**,
mas não sustenta sozinho uma decisão definitiva sobre a localização da próxima loja.

---

## Tecnologias Utilizadas

* **MySQL 8**
* **SQL**
* **Modelagem Dimensional**
* **Data Warehouse**
* **Esquema Estrela**
* **Git / GitHub**

---

## Estrutura do Projeto

```
Pata-Amiga-Data-Warehouse/
├── README.md
├── diagrama/
│   └── modelo_estrela.png
├── sql/
│   ├── 01-staging.sql
│   ├── 02-dimensoes-prontas.sql
│   ├── 03-dimensoes.sql
│   ├── 04-fato.sql
│   └── 05-perguntas.sql
└── ...
```

---

## Conclusão

O projeto demonstra a construção de um Data Warehouse a partir de dados de staging com inconsistências, aplicando processos de padronização, modelagem dimensional e análise SQL para responder perguntas de negócio.

Além de identificar padrões de faturamento e operação, a análise evidencia as limitações existentes nos dados e evita conclusões que não podem ser sustentadas pelas informações disponíveis.
