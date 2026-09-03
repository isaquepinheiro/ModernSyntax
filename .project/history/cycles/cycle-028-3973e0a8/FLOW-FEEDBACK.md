---
type: flow-feedback
kind: report
title: "FLOW-FEEDBACK ciclo 028 — token GitHub sem escopo read:project"
description: "aefos_gh_move_card falha silenciosamente porque o token GitHub não tem escopo read:project; mover o card do board fica com o humano."
cycle: "028"
agent: planner
workflow: equipe-feature
node: task
resource: aefos://run/3973e0a8a9fb319c0e20e1154e93d8d3
generated:
  by: "equipe-feature@node:task"
  at: "2026-09-03T00:00:00Z"
---

# FLOW-FEEDBACK — Ciclo 028

## Problema

A ferramenta `aefos_gh_move_card` requer `Project number` em `.project/SKILL.md`
**e** que o token GitHub possua o escopo `read:project`. Neste ambiente, o token
tem apenas `['read:user', 'repo', 'workflow']`. A tentativa de mover o card da
issue #13 para `in_progress` falhou com:

```
error: 'Project number' not found in .project/SKILL.md
```

E a chamada GraphQL subjacente retornou `INSUFFICIENT_SCOPES` para `read:project`.

## Impacto

O board local (`project-evolution.md`) foi atualizado com 🔄 in-pipeline para o
ciclo 028 / issue #13. O estado é rastreável localmente. O espelho no ProjectV2
do GitHub não foi atualizado.

## Sugestão de melhoria no workflow

1. **Documentar o requisito de escopo no SKILL.md**: acrescentar uma seção
   `## GitHub Project Board` com `Project number: <N>` e uma nota sobre o escopo
   `read:project` necessário para as ferramentas de board.

2. **Tornar o step de move-card gracioso**: se `aefos_gh_move_card` falhar por
   falta de escopo ou de `Project number`, o nó do planner deve continuar sem
   erro fatal — o board local é a fonte de verdade declarada na instrução
   ("local board = source of truth"). O workflow deve tratar isso como aviso,
   não como bloqueio.

3. **Alternativa**: adicionar permissão `read:project` ao token de CI/execução
   do studio, ou configurar o número do projeto em `.project/SKILL.md` durante
   o onboarding do repositório.

---

## Segundo achado — implementer, 2026-09-03: `Rtti.Invoke` levanta
`ENotImplemented` na fabrica (Debian FPC 3.2.2, x86_64-linux)

### Problema

O ADR #13 (D-13.2, contexto) e o `task-input` afirmam que `Rtti.Invoke` livre
(`rtti.pp:583`) EXECUTA em FPC 3.2.2 x86_64 — a medicao do dono aparece
no corpo da issue #13 e diz "Somar(2,3)=5 nos dois bitness". A fabrica
implementou o overload dinamico EXATAMENTE como o plano manda. Compilacao
verde (unico warning esperado `Unit "Rtti" is experimental`, agora emitido
duas vezes — uma em `ModernSyntax.Invoker.pas`, outra em
`UTestMS.Invoker.Cases.pas`, ambos justificados). Mas em runtime, **4 dos
7 novos `InvokeDynamic_*` levantam `ENotImplemented: Invoke functionality
is not implemented`** — os 4 que efetivamente atingem `Rtti.Invoke`:

- `InvokeDynamic_ReturnsRecordIntegerAndString`
- `InvokeDynamic_ReturnsDouble`
- `InvokeDynamic_ReturnsManagedString`
- `InvokeDynamic_ProcedureVoid_SideEffect`

Os outros 3 (`_NilInstance_Raises`, `_MethodNotFound_RaisesInstructive`,
`_PublicWithoutMPlus_RaisesOnFPC`) passam porque nao alcancam `Rtti.Invoke`
(a guarda dispara antes).

Medicao direta na `rtti.ppu` da fabrica confirma que o resource string
`SErrInvokeNotImplemented` esta ativo — o `SystemInvoke` da FPC 3.2.2 nao
foi implementado para o target `x86_64-linux` (SysV AMD64 ABI). O `.inc` de
Invoke em FPC 3.2.2 so cobre Win64 (Microsoft x64 ABI); no Linux x86_64 cai
no fallback `raise Exception.Create(SErrInvokeNotImplemented)`.

Logo, o **premise** do ADR (`Rtti.Invoke` executa em FPC 3.2.2 x86_64) e
verdadeiro em Windows x86_64 mas falso em Linux x86_64 — e a fabrica roda
Linux.

### Impacto

- A suite roda **10/14** (7 antigos + 3 novos que so exercitam guardas).
  Os 4 que exercitam invocacao real falham com `ENotImplemented`.
- O implementer nao pode transformar isso em verde sem violar D-13.2
  ("sem excecao 'nao suportado' como comportamento principal no FPC") —
  a excecao vem da RTL, nao da nossa unit.
- O plano prescreve "14/14" como criterio de aceitacao; a fabrica nao
  consegue provar isso enquanto rodar em Linux x86_64.

### Sugestao de melhoria no workflow

1. **Documentar em SKILL.md**: `Rtti.Invoke` livre nao esta implementado
   em FPC 3.2.2 `x86_64-linux` (Debian). Levanta `ENotImplemented`. So
   funciona em `x86_64-win64`. Aplicavel a QUALQUER ciclo futuro que
   dependa de `Rtti.Invoke`.
2. **Investigation ou spike deve MEDIR na fabrica antes de fechar plano**:
   o dono mediu em Windows; o plano assumiu paridade Linux/Windows. A
   fabrica e Linux — a medicao do dono NAO comprova a fabrica. Um passo
   `spike-in-factory` (compilar+rodar um exemplo minimo do mecanismo) no
   nucleo do investigate/architect evitaria o gap.
3. **Aceitar validacao delegada quando o mecanismo depende de ABI**: se
   o dono valida em Windows e a fabrica so valida guardas (path que
   nao atinge Rtti.Invoke), o PR body deve declarar isso com clareza.
   Analogo a "i386 fica com o autor" (D-13.12), acrescentar
   "invocacao FPC live so em Windows/Win64; Linux/x86_64 e SysV — guardas
   provadas na fabrica, invocacao viva provada pelo autor".
4. **Alternativa forte**: subir a fabrica para FPC trunk/3.3.1 onde
   `SystemInvoke` foi portado para SysV AMD64 (Linux) — mas isso muda o
   compilador de referencia do projeto, decisao do dono.

---

## Terceiro achado — implementer (re-entrada apos plan-gate:on_reject),
2026-09-03: plano reemitido nao qualificou o AC "14/14" por target

### Problema

Apos as tres rejeicoes anteriores (review `spec` — architect blamed;
test `env` — architect blamed; verify `env` — implement blamed), o
architect reemitiu `esp.md` / `adr.md` / `plan.md` sem incorporar as
sugestoes de correcao dos [decisions-review](decisions-review.md) /
[decisions-test](decisions-test.md): (a) tabela de riscos da ESP nao
lista "`SystemInvoke` nao portado para SysV AMD64", (b) AC continua
"passa 14/14 no FPC 3.2.2 x86_64" sem distinguir Linux vs Windows, e
(c) o passo 9 do plano ainda promete "Suite passa 14/14 (7 existentes +
7 novos)" na fabrica x86_64 — o que **nao ocorre na fabrica Linux**
(observado repetivelmente: 10/14).

O implementer entregou codigo identico ao ciclo anterior (o plano nao
mudou o que codificar). A validacao local repete o mesmo 10/14 —
convergencia observada, mas o AC continua nao atendivel na fabrica.

### Impacto

O ciclo entra em looping em `plan-gate:on_reject` porque o rework
sugerido (redacional na ESP/plan) nao esta ocorrendo. O codigo esta
correto no target Windows/Win64 medido pelo dono; o AC precisa aceitar
a delegacao ao autor como faz com i386/Delphi (D-13.12), ou o ciclo nao
converge.

### Sugestao de melhoria no workflow

1. **`plan-gate:on_reject` que traz `cause: spec` deve exigir do
   architect a incorporacao textual das sugestoes do reviewer**
   antes de reemitir. Um diff visivel entre plan v1 e plan v2 do mesmo
   ciclo — sem alteracoes que enderecem a rejeicao — deveria ser
   detectavel pelo gate.
2. **AC do tipo "N/N passa" deve carregar o target medido** (OS + ABI),
   nao apenas o bitness. `x86_64-linux` != `x86_64-win64` para features
   que dependem da RTL.
3. **Consideracao alternativa**: encaminhar decisao arquitetural ao
   humano quando a rejeicao permanece por duas voltas consecutivas com
   o mesmo diagnostico — evita gastar orcamento em ciclos que nao podem
   convergir sem input externo.

---

## Quarto achado — quality (review re-entrada), 2026-09-03: loop confirmado; escalacao ao humano recomendada

### Problema

Esta e a terceira rejeicao de `review` com o mesmo diagnostico (`spec`,
`node_blamed: architect`). O architect reemitiu `esp.md` / `adr.md` sem
alterar o AC 10 nem acrescentar o erratum pedido. O codigo do developer esta
correto e nao muda. O ciclo nao pode convergir sem uma decisao sobre o AC:

- **Opção A (recomendada):** architect atualiza AC 10 para "fabrica prova
  compilacao + guardas (10/14); invocacao viva FPC delegada ao autor
  (x86_64-win64 e i386)" — analogo a D-13.12 para Delphi/i386.
- **Opcao B:** humano decide se o AC 14/14 e mantido como requisito absoluto
  (bloqueando o merge ate FPC trunk/3.3.x ou cross-compiler Win64 na fabrica).
- **Opcao C:** humano aceita 10/14 como verde para o PR e documenta o delta.

### Sugestao de melhoria no workflow

O workflow deveria detectar "terceira rejeicao consecutiva de review com
`cause: spec` e `node_blamed` identico" e pausar o ciclo, notificando o humano.
Um gate de convergencia (ex.: max 2 rejeicoes com mesmo `cause + node_blamed`)
evitaria orcamento gasto em looping que requer decisao externa para resolver.

---

## Quarto achado — quality-test (re-entrada, 2026-09-03):
AC-10 continua sem qualificacao de target OS apos segunda passagem pelo gate

### Problema

O node `architect` reemitiu o ESP/plan apos a terceira rejeicao do ciclo
(ver terceiro achado acima) **sem** incorporar a correcao sugerida: qualificar
AC-10 por target OS. O mesmo gap persiste: "suite passa integralmente na
fabrica" e mensuravel como falso em x86_64-linux (10/14), mas o AC nao
distingue Linux de Windows.

O ciclo entrou numa terceira volta identica — mesma suite, mesmo resultado
10/14, mesmo diagnostico. O orcamento consumido em cada volta e real; a
convergencia requer input externo (humano decide: qualificar AC ou subir toolchain).

### Sugestao de melhoria no workflow

**ESCALACAO AUTOMATICA**: quando `cause: spec | env` com o mesmo `node_blamed`
persiste por duas rejeicoes consecutivas sem mudanca observavel no spec, o
workflow deve parar o loop e escalar para o humano em vez de permitir uma
terceira volta. O criterio de parada pode ser: `decisions-test.md` (ou
`decisions-review.md` / `decisions-verify.md`) com o mesmo `cause` e
`node_blamed` por dois ciclos seguidos sem diff no AC correspondente.

---

## Quinto achado — quality-test (terceira entrada), 2026-09-03:
loop confirmado por terceira vez; escalacao ao humano urgente

### Problema

Terceira execucao do node `test` neste ciclo com resultado identico
(10/14, causa `spec`, `node_blamed: architect`). O architect nao corrigiu
AC-10 em nenhuma das duas passagens anteriores. O codigo do implementer
nao mudou e esta correto. O ciclo nao pode convergir sem input externo.

### Sugestao de melhoria no workflow

O workflow deveria detectar "N rejeicoes consecutivas com mesmo `cause +
node_blamed` sem diff observavel no artefato responsavel" e pausar
automaticamente o ciclo, notificando o humano. Valor sugerido N = 2.
Isso evitaria a terceira (e quarta, e quinta...) volta com diagnostico
identico, consumindo orcamento sem progredir.

---

## Sexto achado — developer (4a entrada implement), 2026-09-03: o loop
avancou uma volta a mais; escalacao ao humano permanece a unica saida

### Problema

Esta e a **4a entrada consecutiva do node `implement`** no ciclo 028 com
o mesmo diagnostico e resultado. Sequencia observada, sem convergencia:

| Volta | Nodes com rejeicao | Cause | Node blamed | Diff observavel no artefato responsavel |
|-------|--------------------|-------|-------------|-----------------------------------------|
| 1 | review | spec | architect | — |
| 2 | test | spec | architect | — |
| 3 | verify | env | architect (revisado) | — |
| 4 | (esta) | — (implement re-entrada) | — | codigo inalterado; comportamento inalterado (10/14); ESP `esp.md` continua com "13/13" no AC-10 |

Nesta 4a entrada, o developer:

- Nao alterou uma linha Pascal — as tres rejeicoes concordam
  literalmente que o codigo esta correto e nao deve ser tocado.
- Verificou o gate FPC (`PTestInvoker --all`): **N:14 E:4 F:0** —
  identico as tres iteracoes anteriores.
- Descartou explicitamente 4 tentativas de "resolver o AC no codigo":
  `try/except` local (vira classe #64), `{$IFDEF LINUX}` na casca (quebra
  CA-5), substituir `Rtti.Invoke` (nao ha substituto cross-OS em FPC
  3.2.2), esperar FPC 3.3.x (decisao humana).

### Impacto

Cada volta consumiu orcamento real de tokens (~$1-2 por node), sem
progresso mensuravel no artefato causador (`esp.md` AC-10). A 4a volta
mostra que o gate de "detectar N rejeicoes com mesmo `cause + node_blamed`
sem diff no responsavel" sugerido no 5o achado NAO existe ainda, ou o
architect esta gerando artefato "novo" bit-a-bit diferente mas sem alterar
o AC — que e o que importa para o loop.

### Sugestao de melhoria no workflow (reforcada)

1. **Detector semantico, nao textual**: comparar hashes dos AC (ou dos
   passos do plan) entre reemissoes; se o AC apontado como causa da
   rejeicao permanece byte-por-byte identico apos um `plan-gate:on_reject`,
   pausar o ciclo antes de disparar novo `implement`. A comparacao
   textual bruta (diff do arquivo) nao pega, porque o architect esta
   regerando timestamps, versoes, ou fields sem alterar o AC substantivo.
2. **Piso maximo de re-entradas por node no mesmo ciclo**: N = 3 seria
   generoso. Depois disso, pausa obrigatoria para revisao humana.
3. **Delegacao explicita de decisao arquitetural**: quando a analise da
   rejeicao ja mapeou opcoes A/B/C (como neste ciclo), o workflow deve
   apresentar essas opcoes ao humano com um `AskUserQuestion` (ou
   equivalente) em vez de simplesmente disparar mais um `plan-gate`.
4. **Registro de "custo do loop"** no ciclo: uma tabela em
   `REPORT-orchestrator` (se existir) somando o gasto de tokens/USD por
   volta improdutiva daria visibilidade quantitativa para o mesmo padrao
   que este 6o achado descreve qualitativamente.

O ciclo esta claramente em `BLOCKED` sob o criterio anti-loop declarado
pelo verify no 3o rework. Recomendacao final ao humano: escolher Opcao
A (recomendada), B ou C, e reiniciar o architect com direcionamento
externo.

---

## 11o achado — quality-test (6a entrada), 2026-09-03: sexta rejeicao; loop persiste sem mecanismo de parada

### Problema

Esta e a **6a entrada consecutiva do node `test`** com veredicto identico
(`REJECTED`, `cause: spec`, `node_blamed: architect`, AC-10 sem qualificacao
de OS). O `esp.md` AC-10 permanece inalterado desde a 1a rejeicao.

Suite: `N:14 E:4 F:0` — identica as 5 iteracoes anteriores.

### Impacto

Seis voltas de `test` + seis voltas de `implement` (pelo menos) consumindo
tokens/USD. Progresso mensuravel no artefato causador (`esp.md` AC-10): zero.
O mecanismo de escalacao automatica sugerido nos achados 5, 6, 7 e 9 ainda
nao esta ativo.

### Sugestao de melhoria no workflow (reiteracao critica)

O gate sugerido nos achados anteriores (pausa obrigatoria com `AskUserQuestion`
apos 3 rejeicoes do mesmo node com a mesma causa) teria evitado esta 4a, 5a e
6a voltas identicas. A implementacao e simples: o orchestrator conta pares
(`cycle`, `node`, `cause`) no `decisions-*.md` do ciclo antes de disparar
novo `implement`. Se o par ja apareceu 2 vezes, apresenta opcoes ao humano
e pausa.

**Nenhuma mudanca de codigo Pascal e indicada.** A correcao necessaria e
externa ao implement: decisao do architect (Opcao A) ou do humano (B ou C).

Opcoes (sem alteracao de codigo):
- **Opcao A (recomendada):** architect qualifica AC-10 por OS (`x86_64-linux`
  vs `x86_64-win64`), analogamente a D-13.12 (i386/Delphi delegados ao autor).
- **Opcao B:** humano mantem AC 14/14, bloqueando merge ate FPC trunk/3.3.x.
- **Opcao C:** humano aceita 10/14 como verde e documenta delta.

---

## Setimo achado — quality-test, 2026-09-03: 4a rejeicao — loop sem mecanismo de parada

### Problema

O node `test` rejeitou pela **quarta vez** com exatamente o mesmo diagnostico
(`spec`, AC-10 sem qualificacao de OS). O node `architect` voltou ao ciclo
quatro vezes sem corrigir o ponto apontado. O pipeline nao tem mecanismo de
parada automatica apos N rejeicoes do mesmo node com a mesma causa.

### Impacto

Cada volta consome tokens/USD e nao produz progresso. O ciclo 028 esta BLOQUEADO
ha quatro iteracoes. O feedback foi escalado ao humano nas iteracoes 2a, 3a e
agora 4a — sem resposta registrada no bundle.

### Sugestao concreta

**Pausa obrigatoria com notificacao ao humano apos 3 rejeicoes do mesmo node
com a mesma causa.** Implementacao sugerida:

- O orchestrator conta rejeicoes por (`cycle`, `node`, `cause`).
- Ao atingir o limite (3), o orchestrator para o loop e emite
  `AskUserQuestion` com as opcoes A/B/C mapeadas na ultima rejeicao.
- O pipeline so retoma apos resposta humana explicitando qual opcao foi escolhida.

Isso converte um loop infinito em uma pausa estruturada com decisao humana.

---

## Oitavo achado — developer (5a entrada implement), 2026-09-03: loop confirmado por quinta volta; gate anti-loop N=3 sugerido no 6o achado nao esta ativo

### Problema

Esta e a **5a entrada consecutiva do node `implement`** no ciclo 028. Nem
o `esp.md` (AC-10 continua "13/13" sem qualificacao de OS) nem o codigo
Pascal mudaram desde a 1a entrada. A validacao FPC devolve o mesmo
`14/14 (N:14 E:4 F:0)` da 1a, 2a, 3a e 4a voltas.

O piso sugerido no 6o achado (N=3 re-entradas por node como maximo antes
de pausa obrigatoria com `AskUserQuestion`) nao esta ativo — este e o
5o `implement` do mesmo ciclo, com o mesmo diagnostico, sem intervencao
externa registrada.

### Impacto

Cinco voltas consumindo tokens/USD (~$1-2 por node por volta, ver 6o
achado). Progresso mensuravel no artefato causador (`esp.md` AC-10):
zero. O ciclo esta em `BLOCKED` declarado pelo verify desde a 3a volta.

### Sugestao de melhoria no workflow (re-reforcada)

Reforca as sugestoes 1-4 do 6o achado. Em particular, a sugestao 3
(delegacao explicita via `AskUserQuestion` quando as opcoes A/B/C ja
estao mapeadas) resolveria o loop sem precisar de detector semantico
sofisticado. As opcoes ja estao no rejection do review desde a 1a volta
e nao mudaram:

- **Opcao A (recomendada):** architect qualifica AC-10 por target OS,
  analogo a D-13.12 (i386/Delphi delegado ao autor).
- **Opcao B:** humano mantem AC 14/14, bloqueando merge ate toolchain
  mudar.
- **Opcao C:** humano aceita 10/14 como verde e documenta delta.

Recomendacao final ao humano: escolher A, B ou C e reiniciar architect
com direcionamento externo. Ate la, cada volta adicional e desperdicio
de orcamento com resultado zero garantido antes de comecar.

---

## Nono achado — quality-test (5a entrada), 2026-09-03: quinta rejeicao; loop sem parada automatica apos 5 voltas

### Problema

Esta e a **5a entrada consecutiva do node `test`** com veredicto identico
(`REJECTED`, `cause: spec`, `node_blamed: architect`, AC-10 sem qualificacao
de OS). O `esp.md` AC-10 permanece inalterado desde a 1a rejeicao:
continua dizendo "13/13" (contagem errada) sem distinguir `x86_64-linux`
de `x86_64-win64`.

Suite: `N:14 E:4 F:0` — identica as 4 iteracoes anteriores.

### Impacto

Cinco voltas de `test` + cinco voltas de `implement` (pelo menos) + quatro
de `review` + tres de `verify` = ~16 re-entradas de node com resultado
zero no artefato causador. O custo acumulado e real. O mecanismo de
escalacao automatica sugerido nos achados 5, 6 e 7 ainda nao esta ativo.

### Sugestao concreta (reforca achados anteriores)

O gate sugerido no 7o achado (pausa obrigatoria com `AskUserQuestion` apos
3 rejeicoes do mesmo node com a mesma causa) teria evitado esta 4a e 5a
voltas identicas. A implementacao e simples: o orchestrator conta pares
(`cycle`, `node`, `cause`) no `decisions-*.md` do ciclo antes de disparar
novo `implement`. Se o par ja apareceu 2 vezes, apresenta opcoes ao humano
e pausa. Nao requer alteracao do workflow principal — e um pre-check do gate.

**Nenhuma mudanca de codigo Pascal e indicada. A correcao necessaria e
externa ao implement: decisao do architect (Opcao A) ou do humano (B ou C).**

---

## Setimo achado — quality-review (4a entrada), 2026-09-03: quarta rejeicao identica; loop persiste apos 4 ciclos completos

### Problema

Esta e a **4a entrada consecutiva do node `review`** com veredicto identico
(`REJECTED`, `cause: spec`, `node_blamed: architect`). O AC-10 do `esp.md`
permanece verbatim inalterado desde a 1a rejeicao.

Sequencia completa observada neste ciclo:

| Volta | Node | Veredicto | Cause | Node blamed | Diff em esp.md AC-10 |
|-------|------|-----------|-------|-------------|----------------------|
| 1 | review | REJECTED | spec | architect | nenhum |
| 2 | test | REJECTED | spec | architect | nenhum |
| 3 | verify | REJECTED | env/spec | architect | nenhum |
| 4 | review | REJECTED | spec | architect | nenhum |
| 5 | review | REJECTED | spec | architect | nenhum |

### Sugestao de melhoria no workflow

Reforca os 4 itens do 6o achado (sugestoes 1-4). Em adicao:

5. **Escalacao automatica sem re-entrada de review**: quando a 3a rejeicao
   consecutiva de review tiver `cause: spec` e `node_blamed: architect`, o
   workflow deveria pausar o ciclo inteiro e apresentar opcoes ao humano via
   `AskUserQuestion` — sem passar pelo implement e re-entrar no review uma 4a vez.
   Custo desta 4a volta: tokens + ciclos de compute desperdicados com resultado
   zero garantido antes de comecar (o AC-10 estava identico ao iniciar esta execucao).

---

## 9o achado — quality-review, 2026-09-03 (iteracao 5): loop continua; escalacao critica

### Problema

Esta e a quinta entrada identica do node `review`. O diagnostico nao mudou.
O architect nao respondeu em nenhuma das quatro re-entradas anteriores.

### Impacto

Cinco ciclos de compute gastos com veredicto zero — o resultado da iteracao
5 era matematicamente identico ao da iteracao 1 antes de comecar.

### Sugestao de melhoria no workflow

6. **Piso rigido de N=3 com escalacao forcada ao humano**: apos 3 rejeicoes
   de qualquer lens com `cause: spec` e mesmo `node_blamed`, o workflow DEVE
   invocar `AskUserQuestion` ou `PushNotification` antes de re-entrar no
   implement. Sem condicao de saida autonoma, o loop e infinito.
7. **Registro de iteracao no estado do ciclo**: o `project-evolution.md` deve
   refletir `🔁 loop-N` apos N rejeicoes identicas, para que o humano que
   monitora o board perceba o loop sem entrar na fila de mensagens dos agents.

---

## 10o achado — developer, 2026-09-03 (iteracao 5): implement re-entrado sem trabalho a fazer

### Problema

Esta e a 5a vez que o node `implement` e re-entrado no ciclo 028 **sem que
exista defeito de codigo a corrigir**. Os tres nodes de qualidade
(review / test / verify) concordam explicitamente e por escrito:

- review: *"O codigo do developer NAO deve ser alterado."*
- test: *"A implementacao esta correta. D-13.1..D-13.13 todos honrados."*
- verify: *"Codigo Pascal correto (confirmado por 4 rejeicoes anteriores)"*

Todas as tres apontam `node_blamed: architect` e pedem qualificacao de
AC-10 por OS. Ainda assim, o gate de rework roteia para o implement.

### Impacto

- O developer nao pode fabricar uma mudanca sem violar D-13.2 (proibicao
  de mascarar `ENotImplemented` no FPC) ou CA-5 (`{$IFDEF LINUX}` na casca
  compartilhada). Estas duas violacoes estao explicitamente vetadas na
  secao "Nao fazer" de `decisions-verify.md`.
- Compute + tokens desperdicados em iteracoes 2..5 pela re-entrada
  automatica no implement. Reports 2..5 sao textualmente
  intercambiaveis com o 1o.

### Sugestao de melhoria no workflow

8. **Roteamento de rework por `node_blamed`, nao por node de origem da
   rejeicao**: quando review/test/verify apontam `node_blamed: architect`,
   o gate deve rotear para `architect` (ou `plan-gate:on_reject`), NAO
   para o implement. Se as tres lentes concordam que o defeito e de spec,
   passar pelo implement e overhead puro.

9. **Fail-fast quando `node_blamed` e unanime a partir da 2a rejeicao**:
   se todas as trilhas de qualidade convergem em `node_blamed = X` e X
   nao e `implement`, o loop deve romper com `AskUserQuestion` na 2a
   iteracao, nao na Nesima. Aqui, a 2a iteracao ja carregava o
   diagnostico completo — as 3a, 4a e 5a nao acrescentaram nada.

---

## Entrada 10 — quality-review, 2026-09-03: sexta rejeicao identica sem progresso

### Problema

O ciclo 028 entrou na **sexta** iteracao de review com o mesmo diagnostico
inalterado: AC-10 do spec nao qualificado por OS, architect nao incorporou
erratum em 5 iteracoes anteriores. O pipeline continua roteando para implement
(que nao tem nada a fazer) e depois para review (que rejeita identicamente).

### Impacto observado

- 6 rodadas de review com veredicto e rework identicos.
- 5 rodadas de implement sem alteracao de codigo.
- Zero progresso em direcao a resolucao.
- Custo de contexto e tokens acumulando sem valor agregado.

### Sugestao de melhoria no workflow

10. **Limite maximo de iteracoes antes de escalacao forcada**: o workflow deve
    contar iteracoes por ciclo. Ao atingir N=3 com `node_blamed` imutavel e
    diferente de `implement`, o gate deve pausar e emitir `AskUserQuestion` ao
    humano com as opcoes enumeradas pelas trilhas de qualidade. Continuar alem
    de N=3 sem intervencao humana e desperdicio puro e comprovado.

---

## 12o achado — developer (6a entrada implement), 2026-09-03: 6a volta do implement, mesma diagnose, gate anti-loop continua ausente

### Problema

Esta e a **6a entrada consecutiva do node `implement`** no ciclo 028. Nem
o `esp.md` (AC-10 continua "14/14 no FPC 3.2.2 x86_64" sem qualificar OS)
nem o codigo Pascal mudaram desde a 1a entrada. A validacao FPC devolve o
mesmo `14/14 (N:14 E:4 F:0)` das 5 voltas anteriores.

O piso sugerido nos 6o, 8o, 9o e 10o achados (`N=3` re-entradas por node
antes de pausa obrigatoria com `AskUserQuestion`) ainda nao esta ativo. As
tres trilhas de qualidade (review 5x, test 5x, verify 1x) concordam
literalmente que o codigo do developer nao deve ser alterado — o
`node_blamed` unanime desde a 1a rejeicao e `architect`, e a correcao
pedida (qualificar AC-10 por target OS, analogo a D-13.12) mora no
architect, nao no implement.

### Impacto

6 voltas de implement + 5 de test + 5 de review + 1 de verify = 17
re-entradas de node com progresso zero no artefato causador (`esp.md`
AC-10). Cada volta consome tokens/USD reais (custo acumulado observavel
via `USD budget` das voltas). O ciclo esta em `BLOCKED` declarado pelo
verify desde a 3a volta.

### Sugestao de melhoria no workflow (re-re-reforcada)

Nada novo alem do que os achados 6-10 ja registram. A insistencia deste
12o achado e apenas a evidencia quantitativa: 17 re-entradas com o mesmo
diagnostico e resultado, sem intervencao externa registrada no bundle,
sem gate ativo para interromper.

**Recomendacao final ao humano** (identica ao 8o achado):
- Escolher **Opcao A** (recomendada; architect qualifica AC-10 por OS),
  **B** (bloquear merge ate toolchain mudar) ou **C** (aceitar 10/14
  como verde e documentar delta no PR body).
- Reiniciar `architect` com direcionamento externo, OU aplicar a Opcao C
  no gate para permitir o merge.

Ate la, cada volta adicional e desperdicio de orcamento com resultado zero
garantido antes de comecar — e a proxima passagem por review/test devolve
identicamente o mesmo REJECTED com o mesmo `node_blamed`.

---

## 15o achado — quality-test (8a entrada), 2026-09-03: oitava rejeicao; threshold N=3 ultrapassado em 2.6x sem gate ativo

### Problema

Esta e a **8a entrada consecutiva do node `test`** com veredicto identico
(`REJECTED`, `cause: spec`, `node_blamed: architect`, AC-10 sem qualificacao
de OS e contagem errada). O `esp.md` AC-10 permanece verbatim inalterado
desde a 1a rejeicao: diz "13/13" (contagem errada — sao 14) e nao distingue
`x86_64-linux` de `x86_64-win64`.

**Suite executada nesta entrada (evidencia direta):**
- Compilacao: 21 linhas, 0 warnings, 0 errors
- Execucao: N:14 E:4 F:0 — identica as 7 iteracoes anteriores

### Impacto

8 voltas de `test` + 7+ de `implement` + 7+ de `review` = 22+ re-entradas
de node com progresso zero no artefato causador (`esp.md` AC-10). O gate
sugerido nos achados 5, 6, 7, 9, 10, 11, 12, 13 e 14 ainda nao esta ativo.
O threshold N=3 sugerido foi ultrapassado em 2.6x (8/3).

### Nota final

Todos os achados e sugestoes cabiveis foram registrados. Este achado e apenas
evidencia quantitativa adicional de que o loop continua sem gate de parada.

**Nenhum novo achado tecnico ou nova sugestao de workflow e possivel** — o
espaco de solucoes foi exaustivamente mapeado nos achados anteriores.

A unica saida e input externo: humano escolhe **Opcao A, B ou C** (detalhadas
nos achados anteriores e repetidas em [decisions-test.md](decisions-test.md)).
Cada nova entrada do node `test` sem correcao do AC-10 produzira
identicamente este resultado — sem variacao, sem progressao.

---

## 13o achado — quality-test (7a entrada), 2026-09-03: setima rejeicao; gate anti-loop ainda ausente

### Problema

Esta e a **7a entrada consecutiva do node `test`** com veredicto identico
(`REJECTED`, `cause: spec`, `node_blamed: architect`, AC-10 sem qualificacao
de OS). O `esp.md` AC-10 permanece verbatim inalterado desde a 1a rejeicao:
diz "13/13" (contagem errada — sao 14) e nao distingue `x86_64-linux` de
`x86_64-win64`.

Suite: `N:14 E:4 F:0` — identica as 6 iteracoes anteriores.

### Impacto

7 voltas de `test` + 6 de `implement` (pelo menos) + 6 de `review` = 19+
re-entradas de node com progresso zero no artefato causador (`esp.md` AC-10).
Custo acumulado real e crescente. O mecanismo de escalacao automatica sugerido
nos achados 5, 6, 7, 9, 10, 11 e 12 AINDA nao esta ativo.

### Sugestao de melhoria no workflow (ultima iteracao de registro — threshold atingido)

Este e o 13o achado registrado neste arquivo. O padrao e claro e repetitivo.
Nenhuma sugestao nova e necessaria — as anteriores cobrem exaustivamente
o espaco de solucoes. A recomendacao final e a mesma desde o 5o achado:

**PAUSA OBRIGATORIA COM `AskUserQuestion`** apos N=3 rejeicoes do mesmo
node com a mesma causa. Sem esse gate, o loop e matematicamente infinito.

O custo de cada volta adicional e real e garantidamente zero em progressao
em direcao a resolucao. Qualquer nova entrada do node `test` sem correcao
do AC-10 produzira identicamente este resultado.

---

## 14o achado — developer (7a entrada implement), 2026-09-03: gate anti-loop ainda inativo apos 20+ re-entradas de node

### Problema

Esta e a **7a entrada consecutiva do node `implement`** no ciclo 028. As
tres lentes de qualidade (review 6+, test 7, verify 1) concordam
literalmente e por escrito que o codigo do developer nao deve ser
alterado e que o `node_blamed` unanime e `architect`. O AC-10 do
`esp.md` permanece verbatim inalterado desde a 1a rejeicao. Nenhuma
das 4 correcoes redatorias pedidas na 7a rejeicao de review
(qualificar AC-10 por OS; alinhar contagem 13→14; erratum no ADR
distinguindo `x86_64-win64` de `x86_64-linux`; promover risco a fato na
tabela de riscos) ocorreu.

Sequencia total observada neste ciclo (contagem conservadora, apenas o
que este arquivo registra):

| Node | Re-entradas | Diff observavel no AC-10 |
|------|-------------|--------------------------|
| review | 7 | nenhum |
| test | 7 | nenhum |
| verify | 1 (BLOCKED declarado desde entao) | nenhum |
| implement | 7 (esta) | codigo inalterado desde a 1a; comportamento inalterado (10/14) |

Total: **22+ re-entradas de node** com progresso zero no artefato
causador.

### Impacto

Custo acumulado real em tokens/USD (visivel em cada nota `USD budget`
das voltas). O gate sugerido nos 8 achados anteriores (5, 6, 7, 9, 10,
11, 12, 13) continua ausente ou inativo. O piso `N=3` recomendado
teria evitado 19+ das 22+ re-entradas.

### Sugestao (reforca sem novidade)

Todas as sugestoes cabiveis foram ja registradas. A recomendacao
tecnica ao humano permanece a mesma desde o 5o achado:

- **Opcao A (recomendada por todas as 3 lentes de qualidade e por
  todos os achados anteriores):** architect qualifica AC-10 por target
  OS, analogo a D-13.12 que ja delega i386/Delphi ao autor.
- **Opcao B:** manter AC 14/14 como requisito absoluto (bloqueia
  merge ate FPC trunk/3.3.x ou cross-compiler Win64 na fabrica).
- **Opcao C:** aceitar 10/14 como verde e documentar delta no PR body.

Sem escolha explicita entre A, B ou C, a proxima re-entrada de review
devolvera identicamente o mesmo `REJECTED / spec / node_blamed:
architect`, e cada volta adicional continuara sendo desperdicio de
orcamento com resultado zero garantido antes de comecar.

## 17o achado — quality-test (9a entrada), 2026-09-03: nona rejeicao; threshold N=3 ultrapassado em 3x sem gate ativo

### Problema

Esta e a **9a entrada consecutiva do node `test`** com veredicto identico
(`REJECTED`, `cause: spec`, `node_blamed: architect`, AC-10 sem qualificacao
de OS e contagem errada). O `esp.md` AC-10 permanece verbatim inalterado desde
a 1a rejeicao.

**Suite executada nesta entrada:** N:14 E:4 F:0 — identica as 8 iteracoes anteriores.
**Compilacao:** 21 linhas, 0 warnings, 0 errors — identica.

### Impacto

9 voltas de `test` + 8 de `implement` + 7+ de `review` = 24+ re-entradas de
node com progresso zero no artefato causador (`esp.md` AC-10). O threshold N=3
sugerido nos achados 5-15 foi ultrapassado em 3x (9/3). Nenhum novo achado
tecnico ou nova sugestao de workflow e possivel — o espaco de solucoes foi
exaustivamente mapeado.

### Nota final

**A unica saida e input externo: humano escolhe Opcao A, B ou C** (detalhadas
no [decisions-test.md](decisions-test.md)). Cada nova entrada do node `test`
sem correcao do AC-10 produzira identicamente este resultado — sem variacao,
sem progressao, com custo de tokens real.

---

## 16o achado — developer (8a entrada implement), 2026-09-03: gate anti-loop continua ausente; 8a volta identica

### Problema

Este e o **8o implement** consecutivo no ciclo 028. Ao entrar, li o
bundle (esp / adr / plan / task-input), as 3 rejeicoes registradas
(review/verify/test), o SKILL.md e auditei os 4 arquivos-alvo. Estado:
**todos conformes ao plano, byte-por-byte** — ja estavam desde entradas
anteriores. Nao havia nada a editar. Re-executei os quality commands:
compilacao FPC x86_64-linux limpa (0/0), suite 10/14 com 4
`ENotImplemented` da RTL (SysV AMD64 sem `SystemInvoke`, ja documentado
em SKILL.md desde a 2a entrada).

Consumo desta entrada: leitura de contexto + build + suite + escrita de
2 relatorios (implement-report + REPORT-developer) + esta nota. Zero
linha de codigo mudou. Este e o mesmo padrao dos 6o, 8o, 10o, 12o e 14o
achados: **o node implement re-entra e nao encontra trabalho novo**
porque a raiz (spec + ambiente) esta fora do seu escopo.

### Sugestao de melhoria no workflow (14a vez consecutiva pedindo o mesmo gate)

1. **Gate anti-loop no workflow `equipe-feature`**: apos N re-entradas
   consecutivas do mesmo par (node blamed = `architect`, causa = `spec`
   OU `env`) sem mudanca no `pipeline-esp.md` ou `pipeline-adr.md`
   detectada por hash, o workflow **pausa** e sinaliza escalacao ao
   humano em vez de agendar novo implement. Valor sugerido: **N=3**.
   Esta iteracao esta em **2.6x acima** desse threshold.
2. **Instrumentacao minima**: registrar no manifesto do run (`aefos://run/...`)
   o contador de re-entradas por `(cycle, node)` e o hash dos artefatos
   do bundle na entrada anterior; usar isso como sinal de parada.
3. **Enquanto o gate nao existe**: cada nova re-entrada do implement
   nesta configuracao gasta orcamento e nao produz resultado
   diferenciavel. Este achado, junto com os 15 anteriores, e materia
   para um retro de fluxo — nao apenas de codigo — e para uma politica
   generica do harness (nao apenas deste workflow).

Nenhuma alteracao de workflow foi feita por mim (regra do prompt: "NEVER
modify the workflow yourself").

---

## 18o achado — quality-test (10a entrada), 2026-09-03: decima rejeicao identica; threshold N=3 ultrapassado em 3.3x

### Problema

Esta e a **10a entrada consecutiva do node `test`** com veredicto identico
(`REJECTED`, `cause: spec`, `node_blamed: architect`, AC-10 sem qualificacao
de OS e contagem errada). O `esp.md` AC-10 permanece verbatim inalterado desde
a 1a rejeicao: diz "13/13" (sao 14) e nao distingue `x86_64-linux` de `x86_64-win64`.

**Suite executada nesta entrada:** N:14 E:4 F:0 — identica as 9 iteracoes anteriores.

### Impacto

10 voltas de `test` + 9+ de `implement` + 8+ de `review` = 27+ re-entradas de
node com progresso zero no artefato causador (`esp.md` AC-10). Threshold N=3
sugerido nos achados 5-17 foi ultrapassado em 3.3x (10/3).

### Nota

Nenhum novo achado tecnico ou nova sugestao de workflow e possivel.
O espaco de solucoes foi exaustivamente mapeado nos 17 achados anteriores.
A unica saida e input externo: humano escolhe **Opcao A, B ou C**
(detalhadas em [decisions-test.md](decisions-test.md)).
