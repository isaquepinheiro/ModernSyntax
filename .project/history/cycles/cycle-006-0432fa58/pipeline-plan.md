---
type: plan
kind: artifact
title: "Plan — Pilar 1 ModernRTTI: leitura portável de RTTI (issue #8)"
description: "Quatro fatias: unit ModernSyntax.RTTI (skeleton + TModernRTTIField Delphi-only, sem {$mode objfpc}); getters R4; testes shared + casca DUnitX + runner Delphi; casca FPCUnit + .lpr + .lpi standalone (padrão commit 7114cdc)."
status: draft
cycle: "006"
agent: architect
workflow: equipe-feature
node: plan-gate:on_reject
resource: aefos://run/0432fa58eb504d5fa522f3e710649a41
tags: [modernrtti, plan, issue-8, pilar-1, fpc, delphi]
generated:
  by: "equipe-feature@node:plan-gate:on_reject"
  at: "2026-08-28T16:00:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — Pilar 1"
  - id: adr
    resource: "adr.md"
    title: "ADR — Pilar 1"
---

# Plan — Pilar 1 ModernRTTI (issue #8)

Quatro fatias sequenciais. **Uma única entrega** — as fatias existem para
revisibilidade, não para paralelismo (o Pilar 1 é um todo coerente: a unit
sem os testes é código morto; os testes sem a unit não compilam).

## Fatia 1 — Unit `ModernSyntax.RTTI.pas`: skeleton + valores

**Objetivo:** entregar o arquivo de produção com tipos, `TRttiContext`
próprio, `Name`/`IsReadable`/`IsWritable`, os 4 overloads de valor por
wrapper (2 genéricos + 2 `TValue`), `TModernRTTIField` e `GetFields` dentro
de `{$IFNDEF FPC}…{$ENDIF}` (D12), e stubs de `GetProperties` (+ `GetFields`
no bloco Delphi-only) **sem** a checagem R4 ainda (fica para a fatia 2).

**Arquivos:**
- `Source/ModernSyntax.RTTI.pas` — NOVO.

**Regras aplicáveis:** RN-1 a RN-5, RN-4a, RN-8, RN-9, RN-11 a RN-14 do
[ESP](pipeline-esp.md); D12 do [ADR](pipeline-adr.md).

**Atenção — dois defeitos do PR #17 a evitar:**
1. **Nunca `{$mode objfpc}` dentro da unit** (nem dentro de `{$IFDEF FPC}`):
   derruba `strict private` em records. Modo vem de `-Mdelphi` na CLI.
2. **Nunca `TRttiField` fora de `{$IFNDEF FPC}`**: o símbolo não existe no
   FPC 3.2.2 — erro de compilação imediato.

**Feito quando:**
- `grep -n 'unit ModernSyntax.RTTI' Source/ModernSyntax.RTTI.pas` casa.
- `grep -n 'EModernRTTIError\|TModernRTTIProperty\|TModernRTTIType\|TModernRTTI'
  Source/ModernSyntax.RTTI.pas` mostra as 4 declarações portáveis na `interface`.
- `grep -n 'TModernRTTIField\|TRttiField\|GetFields' Source/ModernSyntax.RTTI.pas`
  mostra todas as ocorrências **dentro** de blocos `{$IFNDEF FPC}`.
- `grep -n '{\$I ModernSyntax.inc}\|FCP\|mode objfpc'
  Source/ModernSyntax.RTTI.pas` → vazio (RN-4, RN-4a, R3).
- `grep -n "^uses" Source/ModernSyntax.RTTI.pas` na `interface` só cita
  `SysUtils`, `TypInfo`, `Rtti` (RN-3).
- `grep -n 'initialization\|finalization' Source/ModernSyntax.RTTI.pas`
  mostra os dois blocos com criação/liberação de `FContext` (RN-5).
- Cabeçalho SPDX em `(* … *)` (RN-11).

## Fatia 2 — R4: detecção de `{$M+}` ausente + `EModernRTTIError`

**Objetivo:** substituir os stubs de `GetProperties`/`GetFields` da fatia 1
pela verificação R4 (RN-6) que levanta `EModernRTTIError` com a mensagem
unificada (RN-7). Aqui vive o único ponto onde o implementador pode
precisar de `{$IFDEF FPC}` **interno** para acertar o sinal
`PropCount == 0` — se precisar, fica **dentro** da unit (invisível ao
consumidor, CA-5).

**Arquivos:**
- `Source/ModernSyntax.RTTI.pas` — MODIFICAR (só o corpo de `GetProperties`
  e `GetFields`; interface pública **não muda**).

**Regras aplicáveis:** RN-6, RN-7 do [ESP](pipeline-esp.md); D3, D4 do
[ADR](pipeline-adr.md); R4 do PRD.

**Feito quando:**
- `GetProperties` e `GetFields` fazem a verificação antes de retornar.
- A mensagem casa **exatamente** RN-7 (verificável por grep pela
  substring `'A classe %s não expõe propriedades à RTTI'`).
- Se houver `{$IFDEF FPC}`, ele está **dentro do corpo da
  `implementation`**, não na `interface`; o cabeçalho da unit continua
  sem `{$I ModernSyntax.inc}`.
- O `raise` referencia `AClass.ClassName`/`FType.Name` para preencher o
  `%s`.

**Ponto de risco declarado:** o implementador confirma o mecanismo
(PropCount, ou o análogo portável de `TypInfo`) no primeiro build FPC
(R2 do PRD, RSK-1 do ESP). Se um mecanismo diferente for necessário, ele
substitui a implementação **desta fatia** sem alterar a `interface`.

## Fatia 3 — Testes: cenário compartilhado + casca DUnitX + runner Delphi

**Objetivo:** cenários compartilhados executáveis sem framework, casca
DUnitX fina e runner Delphi com entrada nos artefatos de grupo.

**Arquivos:**
- `Test Shared/EclbrSystem/UScenarios.RTTI.pas` — NOVO. Procedures
  portáveis (compilam em FPC e Delphi):
  `Scenario_GetProperties_ReturnsPublishedProps`,
  `Scenario_GetValue_Integer_Roundtrip`,
  `Scenario_GetValue_String_Roundtrip`,
  `Scenario_GetValue_Record_Roundtrip`,
  `Scenario_MissingM_RaisesEModernRTTIError`.
  Fixtures com `{$M+}` + `published` no próprio arquivo. Asserts nativos
  (`Assert`) levantando `Exception` na falha. **Zero `{$IFDEF FPC}`.**
  `Scenario_GetFields_ReturnsFields` **não** entra aqui — é Delphi-only
  e `TModernRTTIField` não existe no FPC (D12 do ADR).
- `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` — NOVO. `[TestFixture]`,
  `[Setup]`/`[TearDown]`, `[Test]` para cada `Scenario_...` compartilhado
  (uma linha útil cada — RN-10). Adiciona `[Test] TestGetFields` que chama
  `TModernRTTI.GetType(TFieldFixture).GetFields` diretamente (uma linha
  útil; recurso Delphi-only não tem cenário compartilhado). Segue padrão
  de `Test Delphi/EclbrSystem/UTestMS.Objects.pas:1`.
- `Test Delphi/EclbrSystem/PTestRTTI.dpr` — NOVO. Importa `FastMM4`,
  `TestInsight.DUnitX` opcional. Modelo:
  `Test Delphi/EclbrSystem/PTestObjects.dpr:1-74`.
- `Test Delphi/EclbrSystem/PTestRTTI.dproj` — NOVO. Necessário para o IDE
  Delphi e para o `groupproj`.
- `Test Delphi/EclbrSystem/TestMSGroup.groupproj` — MODIFICAR (13 → 14
  entradas). **Só adicione depois que o `PTestRTTI.dpr` compila no Delphi
  do autor** (mitigação da nota do investigate sobre efeito colateral).
- `Test Delphi/EclbrSystem/DCC.bat` — MODIFICAR (13 → 14 projetos).

**Regras aplicáveis:** RN-10 do [ESP](pipeline-esp.md); D9 do [ADR](pipeline-adr.md).

**Feito quando:**
- Grep em cada um dos três arquivos de teste retorna **zero linhas**
  para `{\$IFDEF FPC}` (CA-5 do ESP, CA-5 do PRD).
- `[Test]` de cada cenário tem uma única chamada útil (`Scenario_…`);
  qualquer `if/then` de asserção na casca é vazamento.
- `TestMSGroup.groupproj` cita `PTestRTTI.dproj`; `DCC.bat` cita
  `PTestRTTI`.

## Fatia 4 — Casca FPCUnit + projeto FPC standalone

**Objetivo:** casca FPCUnit fina, runner `.lpr` e projeto `.lpi` criados
por esta issue (padrão commit `7114cdc` da #7, sem depender do merge da #7).

**Arquivos:**
- `Test FPC/EclbrSystem/UTestMS.RTTI.pas` — NOVO. `TTestRTTI = class(TTestCase)`
  com `procedure Test…` `published` para cada cenário portável de
  `UScenarios.RTTI.pas`. Cada método chama uma única linha útil (RN-10).
  **Sem** `TestGetFields` (TModernRTTIField não existe no FPC — D12).
  **Zero `{$IFDEF FPC}`.**
- `Test FPC/EclbrSystem/PTestRTTI.lpr` — NOVO. Padrão de
  `PTestModernCallback.lpr` (commit `7114cdc`):
  - Cabeçalho SPDX-MIT em `(* … *)` (RN-11).
  - `{$MODE OBJFPC}{$H+}` (aceitável no arquivo de programa — sem records
    `strict private`; modo Delphi vem do `.lpi` para as units compiladas).
  - `uses Classes, consoletestrunner, UScenarios.RTTI, UTestMS.RTTI,
    ModernSyntax.RTTI;`
  - `TMyTestRunner = class(TTestRunner)` + `Application := TMyTestRunner…`
- `Test FPC/EclbrSystem/PTestRTTI.lpi` — NOVO. Padrão de
  `PTestModernCallback.lpi` (commit `7114cdc`):
  - `<BuildModes Count="2" Active="Debug-x86_64">` com `Debug-i386` e
    `Debug-x86_64`.
  - Em **ambos** os build modes: `<SyntaxMode Value="Delphi"/>`.
  - `OtherUnitFiles`: `..\..\Source;..\..\Test Shared\EclbrSystem`.
  - `UnitOutputDirectory`: `lib\<arch>-$(TargetOS)`.
  - `<Units Count="4">`: `PTestRTTI.lpr`, `ModernSyntax.RTTI.pas`,
    `UScenarios.RTTI.pas`, `UTestMS.RTTI.pas`.

**Regras aplicáveis:** RN-4a, RN-10, RN-11 do [ESP](pipeline-esp.md); D7, D8, D9,
D12 do [ADR](pipeline-adr.md).

**Feito quando:**
- `grep -rn '{\$IFDEF FPC}\|mode objfpc'
  'Test FPC/EclbrSystem/UTestMS.RTTI.pas'` → vazio.
- `grep -rn 'TestGetFields' 'Test FPC/EclbrSystem/UTestMS.RTTI.pas'` →
  vazio (tipo Delphi-only ausente do lado FPC).
- `PTestRTTI.lpi` lista os 4 arquivos e tem `<SyntaxMode Value="Delphi"/>`
  em ambos os build modes.
- FPC 3.2.2 constrói o projeto nos dois alvos (SKILL.md):
  ```
  rm -rf out_x64 && fpc -Mdelphi \
      -Fu"Source" -Fu"Test Shared/EclbrSystem" \
      -FUout_x64 -FEout_x64 \
      "Test FPC/EclbrSystem/PTestRTTI.lpr"
  # → 0 errors
  rm -rf out_i386 && fpc -Mdelphi -Pi386 \
      -Fu"Source" -Fu"Test Shared/EclbrSystem" \
      -FUout_i386 -FEout_i386 \
      "Test FPC/EclbrSystem/PTestRTTI.lpr"
  # → 0 errors
  ```
  **Sempre limpar o diretório de saída antes** (SKILL.md trap 2).

## Dependência entre fatias

- **F1 → F2:** F2 substitui código de F1; não podem ir em PRs separados
  sem tornar F1 código morto (getters silenciosos).
- **F2 → F3:** os `Scenario_…` da F3 exigem a exceção da F2 para
  `Scenario_MissingM_RaisesEModernRTTIError` passar.
- **F3 → F4:** a F4 espelha a F3 no FPC; a lógica útil (F3) precisa
  existir antes de a casca (F4) ter o que chamar.

Por isso este plano é **fits, não split.**

## Verificações finais do PR (checklist executável)

Antes de abrir o PR, o implementador roda:

```bash
# CA-5 do PRD — zero {$IFDEF FPC} nos três arquivos de teste
grep -rn '{\$IFDEF FPC}' \
  'Test Shared/EclbrSystem/UScenarios.RTTI.pas' \
  'Test Delphi/EclbrSystem/UTestMS.RTTI.pas' \
  'Test FPC/EclbrSystem/UTestMS.RTTI.pas'
# → zero linhas

# RN-4 / RN-4a — sem .inc, sem FCP, sem mode objfpc na unit de produção
grep -n '{\$I ModernSyntax.inc}\|FCP\|mode objfpc' Source/ModernSyntax.RTTI.pas
# → vazio

# D12 — TModernRTTIField e GetFields só dentro de {$IFNDEF FPC}
grep -n 'TModernRTTIField\|TRttiField\|GetFields' Source/ModernSyntax.RTTI.pas
# → todas as ocorrências dentro de blocos {$IFNDEF FPC}

# RN-3 — uses da interface só cita SysUtils, TypInfo, Rtti
awk '/^interface/{f=1} f&&/^uses/{p=1} p{print} p&&/;/{exit}' \
  Source/ModernSyntax.RTTI.pas

# CA-9 do ESP — PTestRTTI entrou no group/bat
grep -n 'PTestRTTI' 'Test Delphi/EclbrSystem/TestMSGroup.groupproj'
grep -n 'PTestRTTI' 'Test Delphi/EclbrSystem/DCC.bat'

# CA-8 — build FPC nos dois alvos (LIMPAR output ANTES de cada run)
rm -rf /tmp/rtti_x64 && fpc -Mdelphi \
    -Fu"Source" -Fu"Test Shared/EclbrSystem" \
    -FU/tmp/rtti_x64 -FE/tmp/rtti_x64 \
    "Test FPC/EclbrSystem/PTestRTTI.lpr"
# → 0 errors  (se aparecer "Warning: Unit Rtti is experimental" é normal)

rm -rf /tmp/rtti_i386 && fpc -Mdelphi -Pi386 \
    -Fu"Source" -Fu"Test Shared/EclbrSystem" \
    -FU/tmp/rtti_i386 -FE/tmp/rtti_i386 \
    "Test FPC/EclbrSystem/PTestRTTI.lpr"
# → 0 errors
```

Declara no corpo do PR: *"compilado em FPC 3.2.2 x86_64 e i386 — verde nos
dois alvos; não compilado em Delphi — Delphi permanece com o autor"*
(CA-10 do ESP, R2 do PRD).
