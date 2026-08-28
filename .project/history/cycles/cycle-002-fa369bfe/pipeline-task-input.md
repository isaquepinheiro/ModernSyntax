---
type: task-input
kind: artifact
title: "Task input — implementar Source/ModernSyntax.RTTI.pas (Pilar 1)"
description: "Handoff operacional para o implementador: criar a unit da leitura de RTTI, seus wrappers, deteccao FPC de {$M+}, testes DUnitX e projeto Lazarus."
status: draft
cycle: "002"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/fa369bfebcbab23d74f445cede226eb0
tags: [task-input, modernrtti, pilar-1, issue-8, feature]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-08-28T00:50:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — Pilar 1"
  - id: adr
    resource: "adr.md"
    title: "ADR — Design do Pilar 1"
  - id: plan
    resource: "plan.md"
    title: "Plan — Pilar 1"
---

# Task input — Pilar 1 da ModernRTTI

**Issue:** [isaquepinheiro/ModernSyntax#8](https://github.com/isaquepinheiro/ModernSyntax/issues/8)
**Tipo:** feature
**Labels:** `feature`, `aefos:running`

## Objetivo (uma frase)

Criar `Source/ModernSyntax.RTTI.pas` com `ModernRTTI.GetType(T)`
retornando `TModernRTTIType` cujo `GetProperties`/`GetFields` funciona
com a mesma chamada no Delphi e no FPC 3.2.2, detectando ausencia de
`{$M+}` no FPC.

## Escopo

Ver [esp.md](pipeline-esp.md), secoes 2 e 3. Em resumo: cria a unit, tres
records wrapper, `EModernRTTIError`, testes DUnitX e um `.lpi` para
os testes (novo ou reuso do da issue #7).

## Checklist de aceite

- [ ] `Source/ModernSyntax.RTTI.pas` criado, sem `{$I ModernSyntax.inc}`
  (CA-3 do ESP).
- [ ] `ModernRTTI.GetType(T).GetProperties` funciona no Delphi e no FPC
  com a **mesma chamada** no consumidor (CA-1).
- [ ] No FPC, classe sem `{$M+}` gera `EModernRTTIError` — **nunca**
  lista vazia silenciosa (CA-2, R4).
- [ ] Nenhum arquivo em `Test Delphi/` ou `Test Lazarus/` contem
  `{$IFDEF FPC}` no codigo do consumidor (CA-4).
- [ ] Suite DUnitX com pelo menos: 1 teste positivo de property, 1
  teste positivo de field, 1 teste negativo (classe sem `{$M+}` no
  FPC) — ver [plan.md](pipeline-plan.md), fatia 3.
- [ ] Projeto Lazarus (`.lpi`/`.lpr`) presente e listando o novo
  `UTestMS.RTTI.pas` — reusa o da issue #7 se ja existir; caso
  contrario cria um minimo (CA-6).
- [ ] Body do PR declara: "compilado em FPC 3.2.2 x86_64 e i386;
  nao compilado em Delphi" (CA-7, R2).
- [ ] Superficie publica nao expoe `TRttiType`/`TRttiProperty`/
  `TRttiField` — apenas os wrappers `TModernRTTI*` (CA-8, RN-5).

## Arquivos provavelmente impactados

**Criados:**

- `Source/ModernSyntax.RTTI.pas` — a unit nova.
- `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` — suite DUnitX.
- `Test Delphi/EclbrSystem/PTestModernRTTI.dpr` (+ `.dproj` +
  `.res`) — projeto Delphi para a suite.
- `Test Lazarus/PTestModernRTTI.lpi` (+ `.lpr`) — **se e somente
  se** o `.lpi` da issue #7 nao existir ainda.

**Alterados (condicional):**

- O `.lpi` criado pela issue #7 (se ja mergeado): adicionar
  `UTestMS.RTTI.pas` na lista de units.

**Nao tocar nesta issue:**

- `Source/ModernSyntax.Objects.pas` (D5 do PRD).
- `Source/ModernSyntax.inc` (R3 — bug do `FCP` fica para outra linha).
- `Source/ModernSyntax.Std.pas`, `Source/ModernSyntax.DotEnv.pas`
  (F-ARCH-01 fora do escopo).

## Notas de implementacao

- Padrao `TRttiContext` compartilhado: replicar o padrao ja usado
  em `ModernSyntax.Objects.pas:191-201` (ver
  [03-architecture.md](../../../analysis/03-architecture.md)).
- Ramificacao FPC: **sempre** `{$IFDEF FPC}` direto, nunca via
  `.inc` (evita o bug `{$IFDEF FCP}` de `ModernSyntax.inc:256`).
- Mensagem da excecao de `{$M+}` ausente: incluir o `ClassName` e
  a instrucao literal "add `{\$M+}` and mark properties as
  `published`". Isso e teste-avel por substring.

## Dependencias externas

- Issue #7 (callbacks) — opcional; se ja tiver criado o `.lpi`, esta
  entrega o reusa. Se nao, este ciclo cria um `.lpi` minimo. Nao
  bloqueia.

## Verificacao final (checklist de PR)

- [ ] `grep -n '{$I ModernSyntax.inc}' Source/ModernSyntax.RTTI.pas`
  retorna zero.
- [ ] `grep -rn 'FCP' Source/ModernSyntax.RTTI.pas` retorna zero.
- [ ] `grep -rn '{$IFDEF FPC}' 'Test Delphi/' 'Test Lazarus/'`
  retorna zero.
- [ ] `lazbuild` (executado pelo orquestrador na maquina do autor,
  na `.lpi` alvo) compila em `i386` e `x86_64`.
