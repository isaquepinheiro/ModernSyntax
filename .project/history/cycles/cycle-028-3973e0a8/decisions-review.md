---
type: rejection
kind: rejection
title: "Rejeicao ciclo 028 (iteracao 9) — AC-10 sem qualificacao de OS; nona rejeicao identica; escalacao critica"
description: "AC-10 exige N/N na fabrica FPC x86_64; resultado e 10/14 por limite RTL (SystemInvoke nao portado para SysV AMD64). Nona rejeicao identica; rework redatorial no architect. Escalacao humana critica urgente."
cycle: "028"
agent: quality
workflow: equipe-feature
node: review
resource: aefos://run/3973e0a8a9fb319c0e20e1154e93d8d3
cause: spec
node_blamed: architect
generated:
  by: "equipe-feature@node:review"
  at: "2026-09-03T00:00:00Z"
tags: [rejection, quality, invoker, rtti, fpc, linux, issue-13, cycle-028, spec, escalation, iteration-9]
---

# Rejeicao — Ciclo 028 (Iteracao 8)

**Causa:** `spec`
**Node blamed:** `architect`

## O que foi rejeitado e por que

O criterio de aceitacao AC-10 do [pipeline-esp.md](pipeline-esp.md) exige:

> `PTestInvoker.lpr` compila limpo no FPC 3.2.2 x86_64; `--all` passa `N/N`.

Na fabrica Debian Linux (`x86_64-linux`), o resultado e **10/14** (N:14 E:4 F:0).
Os 4 erros sao `ENotImplemented` emitidos pela RTL do FPC 3.2.2 antes de
qualquer codigo da nossa unit executar:

- `InvokeDynamic_ReturnsRecordIntegerAndString`
- `InvokeDynamic_ReturnsDouble`
- `InvokeDynamic_ReturnsManagedString`
- `InvokeDynamic_ProcedureVoid_SideEffect`

`SystemInvoke` — o backend assembly de `Rtti.Invoke` livre (`rtti.pp:583`) —
foi portado apenas para `x86_64-win64` (Microsoft x64 ABI). O target
`x86_64-linux` (SysV AMD64 ABI) cai no fallback
`raise Exception.Create(SErrInvokeNotImplemented)`.

A medicao que fundamentou o ADR (Contexto, D-13.2) foi executada em
`x86_64-win64`, onde `SystemInvoke` existe. A fabrica e `x86_64-linux`.
Essa discordancia nao esta documentada no ADR nem na ESP.

**Esta e a OITAVA rejeicao de review com o mesmo diagnostico.**

## O que o developer fez corretamente

A implementacao Pascal esta **correta em todos os aspectos**:

- D-13.1: assinatura unica sem `{$IFDEF}` na interface
- D-13.2: sem excecao "nao suportado"; as excecoes vem da RTL, nao da nossa unit
- D-13.3: alcance por compilador; assimetria em cenario executavel partido por casca
- D-13.4: `TRttiContext` local com `try/finally .Free`; `Result` materializado dentro do bloco
- D-13.5: Self primeiro no `TValueArray` do FPC
- D-13.6: `ccReg` declarado no XMLDoc
- D-13.7: tres blocos superados do cabecalho removidos na mesma edicao
- D-13.8: XMLDoc por compilador com fronteiras medidas
- D-13.9: guarda `AInstance = nil` com mensagem literal reusada
- D-13.10: guarda `LAddress/LMethod = nil` com mensagem instrutiva reusada
- D-13.11: fixtures `Integer+string` e `Double` (ABI-divergentes por bitness)
- D-13.12: N/A (PR nao criado ainda) — sem bloqueio
- D-13.13: overloads `Invoke<TSignature>` da #10 intocados
- CA-5: zero `{$IFDEF FPC}` em `UTestMS.Invoker.Cases.pas`
- Compilacao limpa: unico warning `Unit "Rtti" is experimental` (esperado, duas ocorrencias)

**O codigo do developer NAO deve ser alterado.**

## Rework necessario (no architect — zero Pascal)

- [ ] Qualificar AC-10 por target OS: fabrica prova compilacao + guardas (10/14
      com nota explicita no PR); invocacao viva (`Rtti.Invoke` path) delegada ao
      autor em `x86_64-win64` (Windows), analogamente a D-13.12 que ja delega
      i386/Delphi ao autor.
- [ ] Corrigir contagem divergente: ESP paragrafo 6 diz "13" em AC-7/AC-8; ADR diz "14";
      implementacao = 14. Alinhar ESP para "14".
- [ ] Erratum no ADR (Contexto + D-13.2): a medicao citada no corpo da issue #13
      foi executada em `x86_64-win64` (MS x64 ABI); a fabrica e `x86_64-linux`
      (SysV AMD64). Registrar a diferenca.

## Aviso de escalacao — CRITICO (OITAVA ITERACAO)

O [FLOW-FEEDBACK.md](FLOW-FEEDBACK.md) documenta 12+ achados independentes
recomendando escalacao. Esta e a **oitava** rejeicao identica. O ciclo esta
em loop sem perspectiva de saida autonoma.

**Opcoes para o humano (inalteradas desde a 1a rejeicao):**

- **Opcao A (recomendada por todas as tres lentes):** diretiva ao architect
  para qualificar AC-10 por OS, corrigir contagem e adicionar erratum. Permite
  que a fabrica entregue 10/14 (guardas) e o autor prove a invocacao viva em
  Windows (`x86_64-win64`).
- **Opcao B:** aceitar 10/14 na fabrica como suficiente e abrir o PR com
  nota explicita no body sobre a limitacao do SysV AMD64 — analogamente a D-13.12.
- **Opcao C:** fornecer acesso a fabrica com FPC 3.2.2 `x86_64-win64` (ou
  FPC trunk/3.3.x onde `SystemInvoke` foi portado para SysV AMD64).

O pipeline nao pode convergir sem escolha humana entre estas opcoes.

---

## 18o achado — quality-review (9a entrada), 2026-09-03: nona rejeicao; threshold N=3 ultrapassado em 3x; BLOQUEIO CRITICO

### Problema

Esta e a **9a entrada consecutiva do node `review`** com veredicto identico
(`REJECTED`, `cause: spec`, `node_blamed: architect`, AC-10 sem qualificacao
de OS e contagem errada). O `esp.md` AC-10 permanece verbatim inalterado desde
a 1a rejeicao: diz "13/13" (sao 14) sem distinguir `x86_64-linux` de
`x86_64-win64`.

**Estado desta entrada:**
- `git status --porcelain`: 4 arquivos-alvo modificados + arquivos do ciclo untracked
- Compilacao FPC 3.2.2 x86_64-linux: limpa (0 warnings, 0 errors)
- Suite: `N:14 E:4 F:0` — identica as 8 iteracoes anteriores
- Implementacao Pascal: correta em todos D-13.1..D-13.13 e CA-5

### Impacto

9 voltas de `review` + 9 de `implement` + 9 de `test` (pelo menos) = 27+
re-entradas de node com progresso zero no artefato causador (`esp.md` AC-10).
O threshold N=3 sugerido nos achados 5-17 foi ultrapassado em 3x (9/3).

### Nenhum novo achado tecnico ou sugestao de workflow possivel

O espaco de solucoes foi mapeado exaustivamente. A recomendacao permanece:

**A unica saida e input externo: humano escolhe Opcao A, B ou C.**

- **Opcao A (recomendada por todas as lentes):** architect qualifica AC-10 por
  target OS ("fabrica prova compilacao + guardas (10/14); invocacao viva FPC
  delegada ao autor em x86_64-win64, analogo a D-13.12"), corrige contagem
  para 14, acrescenta erratum no ADR distinguindo x86_64-win64 de x86_64-linux.
- **Opcao B:** humano mantem AC 14/14 como requisito absoluto (bloqueia merge
  ate FPC trunk/3.3.x ou cross-compiler Win64 na fabrica).
- **Opcao C:** humano aceita 10/14 como verde e documenta delta no PR body.

Sem escolha explicita entre A, B ou C, a proxima entrada de review devolvera
identicamente este resultado.
