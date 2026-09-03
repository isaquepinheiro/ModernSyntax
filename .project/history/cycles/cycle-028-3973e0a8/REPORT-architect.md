---
type: cycle-report
kind: report
title: "Cycle 028 — Architect report: TModernInvoker.Invoke dinamico cross-compiler (#13)"
description: "Overload dinamico TValue-based com assinatura publica identica e mecanismo divergente por IFDEF; decisoes derivadas do proprio corpo da issue (investigation status NONE); scope=fits."
cycle: "028"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/3973e0a8a9fb319c0e20e1154e93d8d3
generated:
  by: "equipe-feature@node:architect"
  at: "2026-09-03T00:00:00Z"
tags: [cycle-report, architect, invoker, rtti, dynamic-invoke, tvalue, fpc, delphi, issue-13, cycle-028]
---

# Cycle 028 — Architect report

Issue **#13** — *Invocacao dinamica no padrao da RTTI nova do Delphi*.
Investigation status: **NONE** (0 comentarios; nenhum abre com marcador
`investigate`). Mas o **corpo da propria issue**, na secao datada
2026-09-03 *"CORRECAO DE PREMISSA — 03/09/2026, medida rodando"*, carrega
o desenho ja acordado com o dono e derruba os criterios originais 1 e 2.
Decidi conforme o rito de status NONE, honrando o desenho ali registrado.

## Decisoes centrais (detalhe em [adr](pipeline-adr.md))

- **D-13.1** — Assinatura publica **identica** cross-compiler, sem
  `{$IFDEF}` na declaracao. Corpo diverge por `{$IFDEF FPC}` na
  implementation. Pedido literal do dono: *"preciso da mesma sintaxe
  como internamente cada um poderia fazer"*.
- **D-13.2** — Sem excecao "nao suportado" no FPC. O FPC **executa** via
  `Rtti.Invoke` livre (`rtti.pp:583`) — a medicao no corpo da issue
  provou nos dois bitness (`Somar(2,3)=5`, `Concat('id-',42)='id-42'`,
  `SemRetorno(6)` mutou estado).
- **D-13.3** — Alcance por compilador (**opcao (a)** da issue): Delphi
  cobre `public` + `published`; FPC cobre `published` apenas. "Cada
  compilador entrega o que PODE." Assimetria remanescente e teste
  executavel (Case dividido por casca, CA-5 preservado).
- **D-13.7** — Os **tres blocos superados** do cabecalho da unit
  (`Invoker.pas:12-18`, `:20-25`, `:44-51`) caem na MESMA edicao. Doc
  superado gera issue nova (padrao #62); consertar junto e barato.
- **D-13.8** — XMLDoc declara alcance **por compilador** e as tres
  fronteiras medidas: `ccReg` apenas; construtor levanta na RTL do FPC
  (`rtti.pp:2334`); record grande por referencia oculta nao coberto.
- **D-13.11** — Fixtures com layouts **ABI-divergentes** entre i386 e
  x86_64: record `Int64 + string` e `Double`. **Nunca `Integer`
  sozinho** — cabe em registrador nos dois bitness. Motivo tecnico
  registrado (na #53, mutacao morreu em campos diferentes por bitness).
- **D-13.13** — Overload portavel `Invoke<TSignature>` da #10
  **byte-por-byte identico** apos a edicao. Regressao zero.

## Escopo — `fits`

- **TEST 1 (tamanho):** 1 unit de producao + 1 cenario compartilhado + 2
  cascas. Dentro do orcamento de um implement tipico.
- **TEST 2 (independencia):** os passos formam UMA peca — sem os dois
  backends o cenario nao roda; sem o cenario os backends nao sao
  provados; sem o cabecalho reescrito, mergeia doc superado.

Plano: um slice, um commit, um PR. Contagem FPC de testes sobe de 7 para
14. Ver [plan](pipeline-plan.md) para o passo-a-passo.

## Fronteiras declaradas (FORA)

- Alterar o portavel `Invoke<TSignature>` (D-13.13).
- Emular `TRttiContext.GetMethods` no FPC (`GetMethods = 0` continua).
- Outras convencoes de chamada (`ccCdecl`/`ccStdCall`/`ccPascal`).
- Record grande por referencia oculta (ABI-dependente).
- Construtor (`aIsConstructor = True` levanta `ENotImplemented` na RTL
  do FPC).
- Overload que aceita `TClass` (analogo ao portavel; sem demanda).

## Artefatos entregues

- [esp](pipeline-esp.md) — especificacao formal (7 secoes; 14 CAs; 8
  riscos).
- [adr](pipeline-adr.md) — 13 decisoes (D-13.1..D-13.13) com
  alternativas descartadas e consequencias.
- [plan](pipeline-plan.md) — 10 passos, um slice.
- [task-input](pipeline-task-input.md) — checklist operacional + 12
  traps ja pagas.

## Observacoes ao downstream

- **Assimetria em teste executavel:** o Case
  `PublicWithoutMPlus_...` e **partido em dois** pela casca — FPC
  registra `_RaisesOnFPC`, Delphi registra `_OKOnDelphi`. Ambos os Case
  existem no `.Cases.pas` sem diretiva; CA-5 preservado.
- **`Rtti.Invoke` deve ser qualificado com o nome da unit** — Delphi/FPC
  podem resolver `Invoke(...)` no corpo estatico para
  `TModernInvoker.Invoke` (recursao infinita ou erro de tipo).
- **`AResultType` e usado no FPC e IGNORADO no Delphi** — intencional
  (D-13.4/D-13.8). Consumidor cross-compiler passa sempre
  `TypeInfo(<tipo esperado>)` e funciona nos dois.
- **i386 e Delphi ficam com o autor** (D-13.12); a fabrica so prova FPC
  x86_64. PR body carrega o log das duas execucoes do FPC (x86_64 dela,
  i386 do autor).
