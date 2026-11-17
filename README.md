# Energia e custo de um servidor de armazenamento pessoal

Um experimento acadêmico, não um produto: **quanto custa de fato, em joules,
em dinheiro e em esforço, um servidor de armazenamento que roda 24/7 em casa
— quando os candidatos são um celular Android velho e um serviço de
armazenamento na nuvem?**

O celular é **medido**, apenas por software. A nuvem é **modelada** a partir dos
**dados públicos de energia** publicados pelos próprios provedores. Todo número
do relatório final remete a um arquivo de medição bruta.

> Este README e o [`AGENTS.md`](AGENTS.md) — a origem das perguntas de pesquisa —
> estão em português. As especificações em [`specs/`](specs/) são mantidas em
> inglês por decisão de projeto — são o documento lido por revisores e
> ferramentas —, e o código e a saída de terminal ficam em pt-BR.

## O que está sendo estudado

| | |
|---|---|
| **O servidor sob estudo** | Um celular Android velho rodando o stack do [tutorial de referência](https://github.com/MarcusMix/articles/blob/master/tutorial_servidor_nas.md): Termux (via F-Droid), OpenSSH e **File Browser** na `:8080`, com raiz `~/storage/shared` e wake lock ativo — na tomada, tela apagada, Wi-Fi associado, notificações silenciadas |
| **O caminho medido** | A API HTTP do File Browser — o caminho que quem usa esse NAS realmente percorre |
| **O caminho de controle** | `rsync` sobre SSH, com o mesmo payload e no mesmo celular, para separar a parcela do servidor web no custo de mover bytes |
| **Os payloads** | Duas famílias de conteúdo, medidas separadamente: **texto** e **imagens**. A compressão fica **desligada** nos dois caminhos, de modo que as famílias diferem em conteúdo e em mais nada |
| **Repetições** | **n = 100** por célula de transferência; **n = 50** por baseline de IDLE |
| **A nuvem** | Modelada a partir dos **dados públicos de energia** que os operadores publicam — cada número citado com sua fonte, versão e data |

## As perguntas

As perguntas de pesquisa vêm do [`AGENTS.md`](AGENTS.md), o próprio enunciado do
pesquisador. O escopo efetivo está em [`specs/`](specs/).

1. **Energia por unidade de dado transferido** — muitos arquivos pequenos de
   uma só vez contra um arquivo muito grande, com conjuntos de trabalho de 1, 5,
   10 e 15 GB.
2. **Energia em IDLE em função do dado armazenado** — ocupação baixa (≤ 20 GB)
   contra ocupação alta (≥ 50 GB). É esta pergunta que decide o custo de longo
   prazo, porque um servidor de armazenamento fica ocioso a maior parte do
   tempo.
3. **Custo-benefício** contra um servidor de arquivos na nuvem, em horizontes de
   24, 36 e 60 meses, com o volume de tráfego de equilíbrio (break-even).
4. **Vantagens e desvantagens** de cada candidato, separando o que foi medido
   do que é juízo de engenharia.

## Onde o método mora

| Arquivo | Responde |
|---|---|
| [`specs/mission.md`](specs/mission.md) | *Por que* o estudo existe, o que é perguntado, o que está fora de escopo e as regras metodológicas inegociáveis — incluindo a **derivação completa**, da amostra bruta ao número publicado ([§5.1](specs/mission.md#51-the-quantities-defined)) |
| [`specs/techstack.md`](specs/techstack.md) | *Com o que* se mede — hardware, instrumentação, ferramentas de carga, contrato de dados e o registro de premissas |
| [`specs/roadmap.md`](specs/roadmap.md) | *Em que ordem* o trabalho acontece, fase por fase, com critérios de entrada e de saída |

O **relatório** mostra a aritmética de forma resumida e remete a
`specs/mission.md` §5.1 para a derivação completa.

## Princípios

- **Energia por unidade de trabalho** — J/GB e J/arquivo; o relógio pode
  acompanhar o número, mas nunca substitui o denominador.
- **Um dataset só, fixado** — os mesmos bytes em toda repetição e nas duas
  famílias, com o SHA-256 registrado; transferir "5 GB" significa os mesmos
  5 GB em toda parte.
- **IDLE é uma medida de primeira classe** — todo cenário é reportado em bruto
  (`E_tot`) e marginal (`E_Δ`), esta última contra um baseline de IDLE
  correspondente.
- **A nuvem é modelada, nunca medida** — todo número da nuvem viaja com a sua
  cadeia de derivação.
- **Rastreabilidade** — todo número cita o arquivo bruto de onde veio.

## Status

A campanha ainda não começou. A **Fase 0** — caracterização do aparelho,
instalação do stack do tutorial, escolha da rota de medição, o collector e sua
validação contra o mock, o dataset fixado e o orçamento de duração e escrita
da campanha — é a fase atual.

## Licença

Sem licença explícita — **todos os direitos reservados**. O material é público
para leitura e auditoria, mas não pode ser reusado, modificado ou
redistribuído sem permissão. A licença definitiva será definida antes do
depósito do relatório final.
