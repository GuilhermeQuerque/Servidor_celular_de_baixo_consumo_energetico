
1. Qual é o gasto de energia é a eficiencia se comparado com servidores de armazenamento na nuvem fazendo download e upload de:
    - Muitos arquivos pequenos de uma só vez
    - Um arquivo muito grande

*** cargas de trabalho variadas em 1GB, 5GB, 10GB, 15GB ***

2. Qual é o gasto energetico quando o dispositivo estão em IDLE 
    - Com muita memoria de armazenamento total (50GB+)
    - Com baixa memoria de armazenamento total (20GB-)

3. Qual tem o melhor custo beneficio?
    - Celular velho (sem custo)
    - Desktop velho (Custo baixo e mais disponibilidade)
    - Servidor Nuvem (custo alto que eu não quero pagar)

4. Quais sãos as vantagens e desvantagens entre os 3 dispositivos?


*** Em relação ao desktop utilizado, existe uma segunda alternatiiva que não vai ser considerada na spec e construção do experimento, mas pode ser usada para substituir o desktop antigo por falta de hardware no desktop***

---

## Decisões de escopo

Este arquivo é a **origem das perguntas** e não é alterado. O escopo efetivo
do experimento está em [`specs/`](specs/) — `mission.md`, `techstack.md` e
`roadmap.md` —, que são normativos. As decisões abaixo são acumuladas
(2026-11-13 e 2026-11-14) e atualizadas em 2026-11-16.

- **O experimento tem duas colunas:** o **celular** (medido) e a **nuvem**
  (modelada). As perguntas 1 e 2 são respondidas com o celular como único
  candidato medido; a pergunta 3 compara celular (medido) contra nuvem
  (modelado); a pergunta 4 é a síntese qualitativa dessas duas.
- **Servidor medido:** o stack do tutorial
  [`tutorial_servidor_nas.md`](https://github.com/MarcusMix/articles/blob/master/tutorial_servidor_nas.md)
  — Termux (via F-Droid), OpenSSH e **File Browser**. O programa de
  gerenciamento de arquivos do tutorial é o software que serve os arquivos, e
  é portanto parte do que se mede.
- **Caminho de transferência medido:** a **API HTTP do File Browser**
  (principal), com `rsync` over SSH como **grupo de controle** — mesmo
  payload, mesmo aparelho — para separar o custo do servidor web do custo de
  mover bytes.
- **Payloads:** duas famílias separadas, **texto** e **imagens**, com
  `n = 100` para cada.
- **Repetições:** `n = 100` nas transferências e `n = 50` nas medições de
  IDLE.
- **Energia da nuvem:** a partir dos **dados públicos** de consumo de energia
  dos próprios provedores, com cada termo datado e com a fonte registrada.
- **Os primeiros passos são a caracterização do aparelho** — processador,
  memória, armazenamento, bateria, eficiência do carregador — coletada por
  automação sobre SSH.
- **Relatório:** os cálculos aparecem de forma **resumida**; a derivação
  completa fica no arquivo maior da spec, para onde o relatório remete.
- **Sem medidor de tomada**: toda a medição é por software.
- **A rede é o meio** da transferência, nunca objeto de comparação.

O impacto dessas decisões nas respostas — o que fica sem avaliação
experimental — está registrado em `specs/mission.md` §4.