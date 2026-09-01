---
type: cycle-report
kind: report
title: "Architect report — cycle 013 — TModernRTTIContext (issue #28)"
description: "Design dossier restatement: TModernRTTIContext estreia com IModernRTTIContextToken opaco (refcount), registry per-instancia no FPC alimentado por GetType/RegisterType, GetTypes com registry vazio levanta EModernRTTIError, FindType so resolve tkClass no FPC, GetPackages fora com motivo em XMLDoc, ContextFree eliminado. Frase-fronteira registrada: 'Pointer em record e seguro enquanto o record nao e dono; vira bomba no instante em que passa a ser.'"
status: stable
cycle: "013"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/5a8dfb58a24f74263fa58fa581f465c4
tags: [modernrtti, cycle-report, architect, issue-28, fpc, delphi, context]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-09-01T00:00:00Z"
---

# Architect report — cycle 013 (issue #28)

## Demanda

Issue #28: estreia do `TModernRTTIContext` publico com `Create/Free/
GetType/GetTypes/FindType`, funcionando **nos dois compiladores** sem
`{$IFDEF FPC}` no consumidor. `GetPackages` **fora** com motivo em
XMLDoc.

## Insumos consumidos

- **INVESTIGATION REPORT (PRESENT)** reproduzido no prompt — duas
  voltas (humano + agente) na issue #28, run
  `ca7057571a6e684f698e54f8a1d8721e`. Fechou com M-A/B/C/C2/D/E
  aceitos + opcao (a) para o token (interface vazia, so GUID).
- `.project/strategy/2026-08-27-modernrtti/API-MAP.md` §§1, 2, 7.
- `.project/SKILL.md` (toolchain FPC 3.2.2, receita de mutacao,
  traps).
- Handoff do analista sob `.project/analysis/*` (00–06).
- ADRs anteriores: D-25 (Fail sempre; dois cenarios distintos),
  D-26 (nao silenciar divergencia).

## Escolhas registradas (ADR)

Todas restatam o relatorio; **sem divergencia**. Destaque para a
frase-fronteira ganha na volta 2, que vale alem desta issue:

> ***"`Pointer` em record e seguro enquanto o record nao e dono; vira
> bomba no instante em que passa a ser."***

Ela justifica por que os `FToken: Pointer` dos records existentes
(`TModernRTTIField`, `TModernRTTIProperty`, `TModernRTTIMethod`)
continuam validos (offsets ou referencias nao-donas) e por que
`TModernRTTIContext` — primeiro record proprietario de heap — nao
pode ser `Pointer` e por isso usa `IInterface`. Registrada como D-28.2
no [adr](pipeline-adr.md).

Outras decisoes: token opaco (so GUID) com cast interno no backend
(D-28.1); registry per-instancia no FPC (D-28.3); `GetTypes` sobre
registry vazio **levanta** `EModernRTTIError` (D-28.4); `FindType`
so resolve `tkClass` no FPC (D-28.5); `ContextFree` eliminado e
`Free` publico opcional (D-28.6); `RegisterType` publico com XMLDoc
do no-op no Delphi (D-28.7); `GetPackages` fora (D-28.8);
`TModernRTTIType.IsNil` como predicado (D-28.9); cinco cenarios com
cenario 5 afirmando tres coisas para matar a regressao do `Pointer`
(D-28.10); padrao de teste reforcado (D-28.11).

## Plano (3 slices, um unico PR)

1. **Slice 1** — Unit publica: interface opaca +
   `TModernRTTIContext` + `IsNil`, corpos em stub temporario.
2. **Slice 2** — Dois backends em paridade estrita (portao de
   compilacao — API-MAP §7): cinco `Context*` identicas nas duas
   units, classe privada `T<...>ContextToken`. Substitui os stubs da
   slice 1 pela delegacao.
3. **Slice 3** — Cinco cenarios compartilhados + cinco `published`
   na casca FPC + quatro `[Test]` na Delphi + mutacao obrigatoria
   documentada.

Ordem escolhida para deixar o compilador falar em cada etapa.
Detalhamento em [plan](pipeline-plan.md).

## Scope: fits

- **Size:** modesto — tres arquivos de codigo e tres de teste; muito
  abaixo do budget de um implement.
- **Independence:** as tres slices sao **passos** (nao entregas
  independentes) — a 2 sem a 1 nao compila; a 3 sem a 2 nao
  funciona. Cortar em issues separadas pagaria o overhead do ciclo
  tres vezes por um trabalho unico e obrigaria re-integracao. **UM
  PR**.

Sem `split-proposal.md`.

## Artefatos produzidos

- [esp](pipeline-esp.md)
- [adr](pipeline-adr.md)
- [plan](pipeline-plan.md)
- [task-input](pipeline-task-input.md)

## Sinal para o proximo no

- **Handoff completo.** Task-input carrega o checklist executavel
  na ordem das slices e a lista de arquivos a nao tocar.
- **Ponto de atencao para o dev/reviewer:** cenario 5 e o cenario da
  regressao silenciosa; ele precisa afirmar as **tres** coisas
  encadeadas, senao passa verde com o `Pointer` de volta.
- **Ponto de atencao para o QA:** verificar a mutacao (remover o
  `raise` do `ContextGetTypes` no backend FPC) — o cenario 1 tem que
  ficar vermelho.
