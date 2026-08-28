---
type: task-input
kind: artifact
title: "Task input — implementar Source/ModernSyntax.RTTI.pas + cenários compartilhados + cascas de teste (Pilar 1 da ModernRTTI)"
description: "Handoff operacional para o implementador: criar a unit de leitura de RTTI, os cenários compartilhados, e as duas cascas de teste (DUnitX + FPCUnit), registrando o runner Delphi no groupproj/DCC.bat e a casca FPC no .lpi criado pela #7."
status: draft
cycle: "004"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/9a5f8b9e974c23d88b7b6aba11e2973d
tags: [task-input, modernrtti, rtti, pilar-1, issue-8, feature]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-08-28T00:00:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — Pilar 1 da ModernRTTI"
  - id: adr
    resource: "adr.md"
    title: "ADR — Design da unit ModernSyntax.RTTI"
  - id: plan
    resource: "plan.md"
    title: "Plan — Pilar 1 da ModernRTTI"
---

# Task input — Pilar 1 da ModernRTTI (issue #8)

**Issue:** [isaquepinheiro/ModernSyntax#8](https://github.com/isaquepinheiro/ModernSyntax/issues/8)
**Tipo:** feature
**Labels:** `feature`, `aefos:running`

## Objetivo (uma frase)

Criar `Source/ModernSyntax.RTTI.pas` (Pilar 1 da ModernRTTI) com
`TModernRTTI`, `TModernRTTIType`, `TModernRTTIProperty`,
`TModernRTTIField` e `EModernRTTIError`, com a mesma API no Delphi e
no FPC 3.2.2, detecção obrigatória de `{$M+}` ausente no FPC (nunca
lista vazia silenciosa), e testes cobrindo os dois compiladores via
cenários compartilhados + duas cascas finas (DUnitX + FPCUnit).

## Dependência declarada

Este ciclo **assume** que a issue #7 já mergeou e criou:

- `Test Shared/EclbrSystem/` — diretório de cenários compartilhados.
- `Test FPC/EclbrSystem/` — diretório de testes FPC.
- Um `.lpi` FPCUnit em `Test FPC/EclbrSystem/` (nome exato definido
  pela #7 — provavelmente `PTestModernCallback.lpi`; verificar).

**Se a #7 não mergeou até este ciclo entrar em implementação:**

- Criar `Test Shared/EclbrSystem/UScenarios.RTTI.pas` mesmo assim (o
  diretório passa a existir por este commit).
- Criar `Test FPC/EclbrSystem/UTestMS.RTTI.pas` como skeleton, mas
  **não inventar `.lpi` próprio** (lição do commit rejeitado `06fccea`
  do ciclo anterior desta mesma issue #8, que importou DUnitX
  inexistente no FPC 3.2.2).
- Body do PR declara literalmente: *"CA-7/CA-10 pendentes: bloqueado
  por #7. Compilado em Delphi; não compilado em FPC."*

## Escopo

Ver [esp.md](pipeline-esp.md) §2 e [plan.md](pipeline-plan.md) para detalhamento. Em
resumo, cinco fatias sequenciais:

1. `Source/ModernSyntax.RTTI.pas` — unit de produção nova.
2. `Test Shared/EclbrSystem/UScenarios.RTTI.pas` — cenários sem
   framework, com classes de fixture com `{$M+}` + `published` no
   próprio arquivo.
3. `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` — casca fina DUnitX.
4. Runner Delphi `PTestRTTI.dpr` + `.dproj` + entrada no
   `TestMSGroup.groupproj` (13 → 14) + `DCC.bat` (13 → 14).
5. Casca FPC `Test FPC/EclbrSystem/UTestMS.RTTI.pas` + registro no
   `.lpi` da #7.

**Fora deste ciclo** (ver [esp.md](pipeline-esp.md) §2 "Fora"):

- Extensão de `TModernObject.Factory` ou modificação de
  `Source/ModernSyntax.Objects.pas` (D5 do PRD).
- Pilares 2 (atributos) e 3 (Invoker).
- Correção do bug `{$IFDEF FCP}` em `Source/ModernSyntax.inc:256`.
- Criação da infra FPC (é entrega da #7).

## Divergência declarada do texto original da issue

A issue #8 diz "testes DUnitX" e "adicionados ao projeto Lazarus
criado na issue de Callbacks". O ciclo anterior desta mesma #8
interpretou isso como "criar `.lpi` importando DUnitX", commitou
`06fccea`, e o PR foi fechado sem merge — DUnitX **não existe** no
FPC 3.2.2 e não está vendorizado. A decisão em vigor é:

- **Lado FPC = FPCUnit** (medido no cycle-003, D-A7 do
  [adr #7](/history/cycles/cycle-003-92fccbce/pipeline-adr.md);
  `units/x86_64-win64/fcl-fpcunit/fpcunit.ppu` presente).
- **Runner FPC entra no `.lpi` versionado pela #7**, sem inventar
  `.lpi` próprio.

Motivo detalhado no [adr.md, D-9](pipeline-adr.md).

## Checklist de aceite

Todos vinculam CAs do [esp](pipeline-esp.md).

- [ ] `Source/ModernSyntax.RTTI.pas` criado; `interface` `uses Rtti,
      TypInfo, SysUtils` — **exatamente essas três**, nada mais (RN-7,
      D-8 do adr).
- [ ] Cinco tipos públicos: `EModernRTTIError`, `TModernRTTIField`,
      `TModernRTTIProperty`, `TModernRTTIType`, `TModernRTTI` — e
      nenhum tipo interno de wrapper vaza para a `interface` (RN-1).
- [ ] `TModernRTTIField` e `TModernRTTIProperty` têm campo `strict
      private` (`FField`/`FProp`) e expõem `GetValue<T>`/`SetValue<T>`
      genéricos + overloads `TValue` marcados como escape hatch em
      `/// <remarks>` (RN-5, D-3 do adr).
- [ ] `TModernRTTIType.GetProperties` e `.GetFields` retornam
      `TArray<...>` com contrato de ownership em `/// <remarks>`
      (RN-6, D-4 do adr).
- [ ] `TModernRTTIType.GetProperties` executa a verificação R4 antes
      de retornar; ausência de `{$M+}` no FPC dispara `EModernRTTIError`
      com mensagem instrutiva (RN-2, D-6 do adr, CA-4 do esp).
- [ ] `Source/ModernSyntax.RTTI.pas` **não contém** `{$I ModernSyntax.inc}`
      nem o token `FCP` (RN-3, D-7 do adr, CA-6 do esp).
- [ ] `initialization`/`finalization` criam e liberam `TModernRTTI.FContext`
      (padrão de `Source/ModernSyntax.Objects.pas:195,601`).
- [ ] Cabeçalho MIT SPDX no topo (`/analysis/05-conventions.md` §1.5);
      XML doc `///` em todos os membros públicos (§4.3).
- [ ] `Test Shared/EclbrSystem/UScenarios.RTTI.pas` existe, sem
      framework, com `TFixturePropertied`, `TFixtureFielded`,
      `TFixtureMissingM` declaradas no próprio arquivo.
- [ ] Casca DUnitX (`Test Delphi/EclbrSystem/UTestMS.RTTI.pas`) com
      cada método `[Test]` contendo **até uma linha útil** que delega
      ao cenário (D-9 do adr, D-A7 do adr #7).
- [ ] `PTestRTTI.dpr` + `.dproj` criados no padrão dos `PTest*.dpr`
      existentes; `.dproj` inclui `..\..\Source` e `..\..\Test
      Shared\EclbrSystem` em `<DCC_UnitSearchPath>`.
- [ ] `TestMSGroup.groupproj` passa de 13 para 14 entradas
      (`PTestRTTI.dproj` incluído); `DCC.bat` passa de 13 para 14
      projetos (CA-9 do esp). **Só adicionar após confirmar que
      `PTestRTTI.dpr` compila localmente em Delphi** (RSK-6).
- [ ] Casca FPCUnit (`Test FPC/EclbrSystem/UTestMS.RTTI.pas`) com
      cada método `published` delegando ao cenário;
      `initialization` registra a `TTestCase` via `RegisterTest`.
- [ ] `UTestMS.RTTI.pas` registrado no `.lpi` da #7 (CA-10 do esp) —
      **ou** PR declara o bloqueio explicitamente.
- [ ] `grep -rn '{\$IFDEF FPC}' 'Test Shared/EclbrSystem/UScenarios.RTTI.pas'
      'Test Delphi/EclbrSystem/UTestMS.RTTI.pas'
      'Test FPC/EclbrSystem/UTestMS.RTTI.pas'` → 0 (CA-5 do esp).
- [ ] Body do PR declara literalmente: *"compilado em FPC 3.2.2
      x86_64 e i386; não compilado em Delphi — Delphi permanece com o
      autor"* (CA-8 do esp, R2 do PRD).

## Arquivos prováveis impactados

**Criados (novos):**

- `Source/ModernSyntax.RTTI.pas`
- `Test Shared/EclbrSystem/UScenarios.RTTI.pas`
  (o diretório é criado pela #7)
- `Test Delphi/EclbrSystem/UTestMS.RTTI.pas`
- `Test Delphi/EclbrSystem/PTestRTTI.dpr` (+ `.dproj` e `.res` no
  padrão dos `PTest*.dpr` existentes)
- `Test FPC/EclbrSystem/UTestMS.RTTI.pas`
  (o diretório é criado pela #7)

**Modificados:**

- `Test Delphi/EclbrSystem/TestMSGroup.groupproj` (13 → 14 entradas)
- `Test Delphi/EclbrSystem/DCC.bat` (13 → 14 projetos)
- `Test FPC/EclbrSystem/<lpi-da-#7>.lpi` (adiciona `UTestMS.RTTI.pas`
  como `<Unit>`)

**NÃO tocar nesta issue:**

- `Source/ModernSyntax.Objects.pas` (D5 do PRD).
- `Source/ModernSyntax.inc` (R3 do PRD — bug do `FCP` fica para outra
  linha).
- `Source/ModernSyntax.Std.pas`, `Source/ModernSyntax.DotEnv.pas`
  (F-02 do intake).
- Qualquer arquivo de teste existente (a convenção de cascas finas
  vale só para o que **este** ciclo entrega).

## Notas de implementação

- **`uses` da unit nova:** `Rtti, TypInfo, SysUtils` e mais nada.
  Trazer outra unit da biblioteca reintroduz `.inc` ou dependência
  Delphi-only (C-3 do STUDY).
- **Ramificação:** `{$IFDEF FPC} ... {$ELSE} ... {$ENDIF}` **direto**
  no arquivo, **jamais** via `{$I ModernSyntax.inc}` (R3 do PRD).
- **Contexto RTTI:** `class var FContext: TRttiContext` em
  `TModernRTTI`, criado em `initialization`, liberado em `finalization`.
  **Não** reusar `TModernObject.FContext` (D-5 do adr).
- **Heurística R4** (detectar `{$M+}` ausente): `Length(GetProperties) = 0`
  + `FType is TRttiInstanceType` + não é `TObject` + `PropCount == 0`
  no `TypeData`. Confirmar no primeiro build FPC (R2 do PRD);
  variação, se necessária, vive dentro da unit.
- **Mensagem da `EModernRTTIError`** — rascunho no [adr, D-6](pipeline-adr.md).
  Se o dono ratificar o texto, ele vira `resourcestring` (ou `const`)
  na `implementation`. Se preferir dois textos (ramificados por
  compilador), usar `{$IFDEF FPC}` no `raise` — permitido dentro da
  unit (D-2 do PRD).
- **Overloads `TValue`** como escape hatch: `/// <remarks>` deixa
  explícito o custo (obriga o consumidor a `uses Rtti`, que é
  `experimental` no FPC 3.2.2).
- **`GetValue<T>` genérico:** delega a `FProp.GetValue(AInstance).AsType<T>`
  no Delphi; no FPC, se `AsType<T>` falhar para algum `T` (RSK-2 do
  esp), o overload `TValue` cru vira o caminho recomendado para esses
  tipos — decisão do autor no primeiro build FPC.
- **Cenários em `Test Shared/`:** procedures top-level, sem estado
  global. Falha = exceção. Nenhuma dependência de framework.
- **Classes de fixture** com `{$M+}` + `published` são declaradas
  **no próprio `UScenarios.RTTI.pas`** — não são unit à parte.
- **DUnitX vs FPCUnit:** DUnitX no lado Delphi, FPCUnit no lado FPC.
  A unificação está nos cenários compartilhados, não no framework
  (D-A7 do adr #7).
- **Ordem de commit para `TestMSGroup.groupproj` e `DCC.bat`:** só
  adicionar as entradas **depois** de o autor confirmar que
  `PTestRTTI.dpr` compila isoladamente em Delphi (RSK-6 do esp).

## Dependências externas

- **Issue #7** — infra FPC (`Test FPC/`, `Test Shared/`, `.lpi` FPCUnit).
  Se não mergear, PR desta declara bloqueio (ver "Dependência
  declarada" acima).
- Nenhuma outra.

## Verificação final (checklist de PR)

- [ ] `grep -n '{\$I ModernSyntax.inc}' Source/ModernSyntax.RTTI.pas` → 0
- [ ] `grep -n 'FCP' Source/ModernSyntax.RTTI.pas` → 0
- [ ] `grep -rn '{\$IFDEF' 'Test Shared/EclbrSystem/UScenarios.RTTI.pas'` → 0
- [ ] `grep -n '{\$IFDEF FPC}' 'Test Delphi/EclbrSystem/UTestMS.RTTI.pas'
      'Test FPC/EclbrSystem/UTestMS.RTTI.pas'` → 0
- [ ] `TestMSGroup.groupproj` tem entrada `PTestRTTI.dproj`.
- [ ] `DCC.bat` tem entrada `PTestRTTI`.
- [ ] `Test FPC/EclbrSystem/<lpi-da-#7>.lpi` lista `UTestMS.RTTI.pas`
      como `<Unit>` — ou PR declara `#7-block`.
- [ ] `lazbuild --build-mode=Debug-i386 <lpi>` (pelo orquestrador na
      máquina do autor) compila.
- [ ] `lazbuild --build-mode=Debug-x86_64 <lpi>` idem.
- [ ] Delphi compila `PTestRTTI.dproj` (pelo autor).
- [ ] Body do PR carrega a declaração do CA-8 do esp.

## Perguntas em aberto para o dono (não bloqueiam a implementação, mas ratifique antes do merge)

- **Texto exato da mensagem da `EModernRTTIError`** (rascunho em
  [adr.md, D-6](pipeline-adr.md)). Recomendação do arquiteto: unificar (uma
  string, sem `{$IFDEF FPC}` no `raise`).
- **Prefixo de interface da família ModernRTTI** (`IModern*` /
  bare `I*` / `IMS*`). Não bloqueia esta issue (Pilar 1 só introduz
  records), trava a próxima que introduzir interface. Medições em
  [adr.md, D-11](pipeline-adr.md).
- **Nomenclatura do arquivo de cenários** — `UScenarios.RTTI.pas`
  (adotado, do relatório) vs `UTestMS.RTTI.Scenarios.pas` (padrão da
  #7). Rename mecânico se preferir alinhar. Ver [adr.md, D-10](pipeline-adr.md).
