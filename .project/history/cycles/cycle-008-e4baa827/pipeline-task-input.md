---
type: task-input
kind: artifact
title: "Task input — TModernRTTIField portável nos dois compiladores (issue #21)"
description: "Handoff operacional: 6 pontos em Source/ModernSyntax.RTTI.pas (remover {$IFNDEF FPC} externo, factories FromRaw/FromRtti distintas por branch, GetFields FPC com loop de herança via vmtFieldTable tipada, property Field[i], cast ShortString→string), nova fixture com herança + cenário em UScenarios.RTTI.pas, casca fina em UTestMS.RTTI.pas (FPC). Compilar FPC 3.2.2 x86_64 e i386 antes de abrir o PR."
status: draft
cycle: "008"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/e4baa827945b3dd3a372629b831d73a9
tags: [modernrtti, task-input, issue-21, fpc, delphi]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-08-31T00:00:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — issue #21"
  - id: adr
    resource: "adr.md"
    title: "ADR — issue #21"
  - id: plan
    resource: "plan.md"
    title: "Plan — issue #21"
---

# Task Input — TModernRTTIField portável (issue #21)

## Título

`feat(rtti): TModernRTTIField existe nos dois compiladores — mesmo tipo, dois mecanismos por dentro (issue #21)`

## Tipo / labels

- `enhancement`
- `modernrtti`
- `pilar-1`
- `fpc`
- `delphi`

## Escopo (arquivos)

### Modificados
- `Source/ModernSyntax.RTTI.pas` — 6 pontos de mudança (A1..A6 do
  [plan.md](pipeline-plan.md) fatia 1).
- `Test Shared/EclbrSystem/UScenarios.RTTI.pas` — nova fixture com
  herança (`TInner`/`TBase`/`TPortableFieldFixture`) + procedure
  `Scenario_GetFields_EnumeratesInheritedPublishedClassFields`.
- `Test FPC/EclbrSystem/UTestMS.RTTI.pas` — remove a linha 16 (comentário
  agora falso) e adiciona a casca fina
  `TestGetFields_EnumeratesInheritedPublishedClassFields` (uma linha
  útil).

### Novos
Nenhum.

### **Não** tocar
- `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` — o `TestGetFields_ReturnsFields`
  sobre `TFieldFixture` (campos `public` escalares) permanece como
  cobertura Delphi-only real.
- Qualquer outra unit de `Source/` — nota da issue: "nenhuma outra unit
  tocada".
- `Source/ModernSyntax.inc` — R3 do PRD (contornar o typo `FCP:261`).
- `Test Delphi/EclbrSystem/PTestRTTI.dpr`/`.dproj`,
  `Test FPC/EclbrSystem/PTestRTTI.lpr`/`.lpi`,
  `TestMSGroup.groupproj`, `DCC.bat` — nada de mudanças estruturais.

## Checklist de aceitação (mapa 1-para-1 com o ESP)

- [ ] **CA-1.** `TModernRTTIField` e `TModernRTTIType.GetFields` existem
      e compilam nos dois compiladores. `grep -n
      'TModernRTTIField\|GetFields' Source/ModernSyntax.RTTI.pas` não
      mostra ocorrências dentro de `{$IFNDEF FPC}`.
- [ ] **CA-2.** Zero `{$IFDEF FPC}`/`{$IFNDEF FPC}` nos três arquivos de
      teste (grep restrito).
- [ ] **CA-3.** No FPC, `GetFields` enumera campos `published` de tipo
      classe subindo por `ClassParent`; `GetValue<T>`/`SetValue<T>`
      lêem/escrevem por offset. Cenário
      `Scenario_GetFields_EnumeratesInheritedPublishedClassFields`
      passa com `Length = 2` exato.
- [ ] **CA-4.** XMLDoc em voz de contrato; palavra "no FPC" aparece
      ao menos duas vezes no arquivo (`TModernRTTIField` e `GetFields`);
      linha "ordem não especificada" no XMLDoc de `GetFields`.
- [ ] **CA-5.** Build FPC verde em x86_64 e i386 (SKILL: `rm -rf <out>`
      antes de cada run).
- [ ] **CA-6.** `git diff --name-only` mostra **apenas** os três
      arquivos listados em "Modificados".
- [ ] **CA-7.** A linha "Sem TestGetFields aqui: TModernRTTIField é
      Delphi-only" **não existe mais** em
      `Test FPC/EclbrSystem/UTestMS.RTTI.pas`.
- [ ] **CA-8.** Corpo do PR declara: *"Compilado em FPC 3.2.2 x86_64 e
      i386 — verde nos dois; não compilado em Delphi — Delphi permanece
      com o autor."*

## Ordem de execução (do [plan.md](pipeline-plan.md))

1. **F1** — 6 pontos de mudança em `Source/ModernSyntax.RTTI.pas`
   (declaração incondicional, factories `FromRaw`/`FromRtti`, XMLDoc de
   contrato com "no FPC", implementação ramificada, loop de herança FPC
   via `vmtFieldTable` tipada).
2. **F2** — nova fixture com herança + procedure de cenário em
   `Test Shared/EclbrSystem/UScenarios.RTTI.pas`.
3. **F3** — remover linha 16 e adicionar casca fina em
   `Test FPC/EclbrSystem/UTestMS.RTTI.pas`.
4. **Build FPC** — `rm -rf <out>` antes de cada bitness; declarar
   resultado no corpo do PR.

## Regras estruturais críticas (não negociáveis)

- **Zero `{$IFDEF FPC}` na declaração pública** de `TModernRTTIField` ou
  `GetFields` — a ramificação vive **só** em `strict private` e no corpo
  dos métodos (D2 do [adr](pipeline-adr.md)).
- **Factories privadas com nomes distintos por branch:** `FromRaw` no
  FPC, `FromRtti` no Delphi (D3 do adr). Nomes iguais + assinaturas
  diferentes sob `{$IFDEF}` são recusados.
- **No FPC, `PVmtFieldTable(PVmt(LCur)^.vFieldTable)` — sempre tipado.**
  Proibido `PByte(LClass) + vmtFieldTable` (D4 do adr).
- **No FPC, `LTab^.Field[i]` — sempre property.** Proibido `LTab^.Fields[i]`
  como array (D5 do adr; entradas têm tamanho variável).
- **No FPC, subir por `ClassParent`** — sem subida, Delphi/FPC divergem
  em silêncio (D6 do adr). `vFieldTable = nil` num elo = pula, não erra.
- **No FPC, cast explícito `string(LEntry^.Name)`** — `ShortString` da
  `TVmtFieldEntry.Name` (D8 do adr).
- **Ordem NÃO especificada** no contrato público — buscar por nome, não
  indexar por posição (D10 do adr).
- **XMLDoc em voz de contrato**, palavra "no FPC" obrigatória (D11 do adr,
  CA-4 do esp).
- **Fixture com herança e assertiva de contagem exata** `= 2` (D12 do adr).
- **Zero `{$mode objfpc}` na unit de produção** (RN-4a do ESP ciclo 006;
  derruba `strict private` em records).
- **Cabeçalho SPDX-MIT em `(* … *)`** — mudança não toca no header
  (D10 do ADR ciclo 006).
- **`rm -rf <out>`** antes de cada build FPC (SKILL trap 2).

## Riscos declarados (do ESP §6)

- **RSK-1** — fixture `{$M+}` com herança não medida em `dcc32` neste
  ciclo. Sintaxe padrão, risco baixo. Fallback: `{$M+}` só em `TInner`
  em vez de bloco.
- **RSK-2** — `TValue.From<TObject>` no FPC 3.2.2 pode falhar para `T`
  genérico complexo. Overload `TValue` cru é o caminho recomendado
  nesses casos.
- **RSK-3** — build FPC incremental mentiroso. Mitigação obrigatória:
  `rm -rf <out>` antes de cada run.
- **RSK-4** — `TypInfo` já autorizado no `uses` da unit (RN-3 do ESP
  ciclo 006). Sem impacto novo em dependências.

## Referências

- [esp.md](pipeline-esp.md)
- [adr.md](pipeline-adr.md)
- [plan.md](pipeline-plan.md)
- [PRD](/strategy/2026-08-27-modernrtti/PRD.md)
- [ADR ciclo 006 (D12 substituída)](/history/cycles/cycle-006-0432fa58/pipeline-adr.md)
- [ESP ciclo 006](/history/cycles/cycle-006-0432fa58/pipeline-esp.md)
- [SKILL](/SKILL.md)
