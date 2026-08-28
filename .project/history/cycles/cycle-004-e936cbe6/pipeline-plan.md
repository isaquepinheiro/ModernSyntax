---
type: plan
kind: artifact
title: "Plan — Atributos portáveis da ModernRTTI (issue #9)"
description: "Plano de execução em cinco fatias sequenciais: unit ModernSyntax.Attributes; .inc de símbolos + unit comum de cenários em Test Shared/; casca fina DUnitX + .dproj no lado Delphi; casca fina FPCUnit + .lpi/.lpr no lado FPC; ajustes de search path."
status: draft
cycle: "004"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/e936cbe6a17a8e76ec8ca9a02ec30735
tags: [plan, modernrtti, attributes, issue-9]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-08-28T13:30:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — Atributos portáveis"
  - id: adr
    resource: "adr.md"
    title: "ADR — Design da unit ModernSyntax.Attributes"
---

# Plano de execução — Atributos (issue #9)

**Scope estimate.** Pilar do ModernRTTI: uma unit de produção enxuta (uma classe base + um
record de fachada + registry + fusão nativo/registrado com regra 2 do ADENDO) mais os testes
na convenção da família (`Test Shared/` + `Test Delphi/` + `Test FPC/`). **Test 1 (SIZE):**
implementação cabe em um orçamento de implementação normal — a unit é pequena, os testes são
cascas finas. **Test 2 (INDEPENDENCE):** nenhuma fatia é mergeável sozinha — sem a unit os
cenários não compilam; sem cenários compartilhados as cascas divergem; sem casca FPC não há
CA-5/CA-6 do esp; sem a regra 2 do ADENDO na §1, o próprio teste "prova viva de CA-2" falha
(§3). Conclusão: **`scope = fits`**, cinco fatias sequenciais no mesmo ciclo.

## Fatia 1 — `Source/ModernSyntax.Attributes.pas`

**Arquivos criados:**

- `Source/ModernSyntax.Attributes.pas` — a unit nova.

**O que entra:**

1. Header MIT com **`(* ... *)`** (R-Comment-Nest / D-A10 do [adr](pipeline-adr.md)). Zero
   `{$...}` dentro de `{ }`.
2. `unit ModernSyntax.Attributes;` — **sem** `{$I ModernSyntax.inc}` (D-A1/RN-6 do
   [esp](pipeline-esp.md)).
3. `interface` com `uses SysUtils, Generics.Collections, SyncObjs {$IFNDEF FPC}, Rtti{$ENDIF};`
   (RN-8 do esp).
4. Declaração de `TModernAttribute` no formato bifurcado por `{$IFDEF FPC}` (D-A2 do adr,
   RN-2 do esp).
5. Declaração de `TAttributeRecord = record Owned: TArray<TObject>; end;` **na interface**
   por R-FPC-Generic (D-A9 do adr, RN-1 do esp).
6. Declaração do record `ModernAttributes` com **duas** class functions estáticas:
   - `class procedure Register(AClass: TClass; const AAttrs: array of TObject); static;`
   - `class function GetAttributes(AClass: TClass): TArray<TObject>; static;` — com
     **XMLDoc** contendo, palavra por palavra, o contrato "vista emprestada" de RN-5 do esp.
7. Implementação:
   - Variáveis de unit: `FRegistry`, `FLock`, e `FContext` sob `{$IFNDEF FPC}` (D-A3 do adr).
   - `Register`: entra no lock; obtém ou cria `TAttributeRecord`; percorre `AAttrs` e faz
     append em `Owned` com dedup por **identidade de referência** (D-A5 do adr); grava de
     volta; sai do lock. Instâncias que não passam pelo dedup e não foram absorvidas
     precisam ser liberadas (a decisão canônica é: se a instância for descartada por já
     existir por identidade em `Owned`, `Register` **libera a duplicata recebida** — o
     consumidor não deve depender da instância "extra" continuar viva). Registrar essa
     regra em comentário de código no ponto.
   - `GetAttributes`: entra no lock; monta o resultado:
     - **FPC**: cópia de `FRegistry[AClass].Owned` (ou array vazio se ausente).
     - **Delphi**: monta `LOwned := FRegistry[AClass].Owned`; obtém `LNative :=
       FContext.GetType(AClass).GetAttributes`; **filtra `LNative`** removendo toda
       instância cuja `ClassType` já apareça em `LOwned` (**regra 2 do ADENDO / D-A6 do
       adr**); retorna `LOwned` + `LNative` filtrado.
     - Nunca retorna `nil`; ausência de registro devolve `Length = 0` (RN-4 do esp, CA-3
       do esp).
   - `initialization`: cria `FRegistry`, `FLock`, `FContext` (o último só no Delphi).
   - `finalization`: para cada valor de `FRegistry`, libera **apenas** `Owned` (D-A4 do
     adr); `FRegistry.Free`; `FLock.Free`; `FContext.Free` (apenas no Delphi).

**Como conferir (leitura + grep — a fábrica não compila):**

- `grep -n '{$I ModernSyntax.inc}' Source/ModernSyntax.Attributes.pas` → **0**.
- `grep -n 'FCP' Source/ModernSyntax.Attributes.pas` → **0**.
- `grep -n '^uses' Source/ModernSyntax.Attributes.pas` — apenas `uses SysUtils,
  Generics.Collections, SyncObjs {$IFNDEF FPC}, Rtti{$ENDIF};` na `interface`.
- Superfície pública: `TModernAttribute`, `TAttributeRecord`, `ModernAttributes` — nada mais.
- `TAttributeRecord` declarado **na `interface`** (R-FPC-Generic).
- Header em `(* ... *)`; nenhum `{$...}` dentro de `{ }`.

## Fatia 2 — `.inc` de símbolos + unit comum de cenários em `Test Shared/EclbrSystem/`

**Diretórios usados (primeiro uso pela família #9, já criado pela família #7):**
`Test Shared/EclbrSystem/`.

**Arquivos criados:**

- `Test Shared/EclbrSystem/UTestMS.Attributes.Symbols.inc` — o `.inc` de uma linha.
- `Test Shared/EclbrSystem/UTestMS.Attributes.Scenarios.pas` — cenários sem framework.

**O que entra em `UTestMS.Attributes.Symbols.inc` (uma linha exata):**

```pascal
{$IFDEF FPC}{$DEFINE NO_NATIVE_ATTRS}{$ELSE}{$DEFINE HAS_NATIVE_ATTRS}{$ENDIF}
```

**O que entra em `UTestMS.Attributes.Scenarios.pas`:**

1. `uses SysUtils, Generics.Collections, ModernSyntax.Attributes;` — **zero** framework de
   teste, **zero** `{$IFDEF}`.
2. `type ETestScenarioFailed = class(Exception);`
3. Uma **classe de atributo portável** para os cenários (declarada localmente para não
   depender de nada externo):
   ```pascal
   TMyAttr = class(TModernAttribute)
   private
     FTag: string;
   public
     constructor Create(const ATag: string);
     property Tag: string read FTag;
   end;

   TOtherAttr = class(TModernAttribute);
   ```
4. Procedures/functions de cenário obrigatórias:
   - `procedure Scenario_Register_ThenGetAttributes_ReturnsRegistered;`
     → cria classe alvo local, chama `ModernAttributes.Register(TAlvo, [TMyAttr.Create('a')])`,
       chama `GetAttributes(TAlvo)`, verifica que tem 1 elemento e que é `TMyAttr` com
       `Tag = 'a'`. (CA-1 do esp)
   - `procedure Scenario_GetAttributes_NeverRegistered_ReturnsEmpty;`
     → chama `GetAttributes(TClasseNuncaRegistrada)`, verifica `Length = 0`, nunca `nil`,
       nunca exceção. (CA-3 do esp; Q2 do PRD; RN-10 do esp)
   - `procedure Scenario_Register_SameInstanceTwice_IsDeduplicated;`
     → `LAttr := TMyAttr.Create('x')`; `Register(TAlvo, [LAttr])`; `Register(TAlvo, [LAttr])`;
       `GetAttributes(TAlvo)` retorna array com Length = 1. (D-A5 do adr / Q4 do relatório)
   - `procedure Scenario_Register_TwoInstances_BothAppear;`
     → `Register(TAlvo, [TMyAttr.Create('a'), TMyAttr.Create('b')])`; verifica Length = 2 e
       ambos os tags presentes. (D-A5 do adr / Q4 do relatório)
   - `procedure Scenario_NativePlusRegister_IsIdentical;`
     → esta é a **"prova viva de CA-2"**. Toma uma classe (declarada em módulo compartilhado
       via `TClassComAttrNativo` — no Delphi anota com `[TMyAttr]` real; no FPC a mesma classe
       simplesmente não recebe anotação). Chama
       `Register(TClassComAttrNativo, [TMyAttr.Create('reg')])`. Executa `GetAttributes`.
       Afirma **contagem idêntica** e **classe idêntica** nos dois compiladores: 1
       elemento, `TMyAttr` com `Tag = 'reg'` (a instância registrada; a nativa foi
       descartada pela regra 2 do ADENDO no Delphi). Não há mais cláusula de escape.
   - `procedure Scenario_NativeSuppressedByRegistered_DelphiOnly;` (chamado só pela casca
     Delphi via `{$IFDEF HAS_NATIVE_ATTRS}` — **na casca**, não aqui)
     → o cenário em si é **portável** (chama `Register(TComNativo, [TMyAttr.Create('reg')])`,
     lê `GetAttributes`, afirma 1 entrada `TMyAttr` com `Tag='reg'`). No FPC, `TComNativo`
     simplesmente não tem atributo nativo, então o resultado também é 1 entrada `TMyAttr`
     com `Tag='reg'`. **O cenário é o mesmo nos dois; o que muda é a existência do teste
     na casca.** Alternativa: o cenário aceita ficar aqui **sem chamada da casca FPC**.
5. Cada cenário levanta `ETestScenarioFailed` (ou `Exception`) na falha; nenhum retorna
   Boolean. A **exceção é o contrato**.

**Notas de coordenação com as classes-alvo dos cenários:**

- As classes-alvo que precisam de **anotação nativa Delphi** (para provar coexistência)
  devem ficar **dentro do escopo compartilhado**, mas a anotação `[TMyAttr(...)]` só existe
  no Delphi. Portanto: a classe `TClassComAttrNativo` é declarada com **anotação nativa
  ausente** no shared (compila nos dois), e o cenário testa apenas a via `Register`. O
  teste que **exige** a anotação nativa presente vive **na casca Delphi** — usa uma classe
  declarada **localmente na casca** (dentro de `{$IFDEF HAS_NATIVE_ATTRS}`). Isto mantém
  CA-4 do esp válido: o `Scenarios.pas` continua sem `{$IFDEF}`.

**Como conferir:**

- `grep -n '{\$IFDEF' 'Test Shared/EclbrSystem/UTestMS.Attributes.Scenarios.pas'` → **0**.
- `grep -n 'DUnitX\|fpcunit\|TestFramework' 'Test Shared/EclbrSystem/UTestMS.Attributes.Scenarios.pas'` → **0**.
- Cada cenário levanta `Exception` na falha; nenhum retorna Boolean/string de status.

## Fatia 3 — Casca fina Delphi (DUnitX) + `.dpr`/`.dproj`

**Arquivos criados:**

- `Test Delphi/EclbrSystem/UTestMS.Attributes.pas` — casca DUnitX.
- `Test Delphi/EclbrSystem/PTestAttributes.dpr` — projeto de teste.
- `Test Delphi/EclbrSystem/PTestAttributes.dproj` (+ `.res` no padrão dos outros `PTest*`).

**O que entra em `UTestMS.Attributes.pas` (Delphi):**

1. Cabeçalho + `unit UTestMS.Attributes; interface`.
2. **Guarda de include** logo após `interface uses ...;`:
   ```pascal
   {$I UTestMS.Attributes.Symbols.inc}
   {$IF NOT DEFINED(HAS_NATIVE_ATTRS) AND NOT DEFINED(NO_NATIVE_ATTRS)}
     {$MESSAGE FATAL 'UTestMS.Attributes.Symbols.inc nao foi incluido'}
   {$IFEND}
   ```
3. `uses DUnitX.TestFramework, UTestMS.Attributes.Scenarios, ModernSyntax.Attributes;`
4. `[TestFixture] TAttributesTests = class` com um `[Test]` por cenário compartilhado. Cada
   método tem **até uma linha útil** delegando ao cenário (D-A7 do adr):
   ```pascal
   [Test] procedure Register_ThenGetAttributes_ReturnsRegistered;
   // implementação:
   Scenario_Register_ThenGetAttributes_ReturnsRegistered;
   ```
5. **Testes Delphi-only** atrás de `{$IFDEF HAS_NATIVE_ATTRS}` (símbolo de **capacidade**, não
   de compilador):
   - Declaração local dentro do bloco: uma classe `TClasseNativa` com `[TMyAttr('nat')]`.
   - `[Test] procedure TestDelphi_NativeAlone_NoRegister_ReturnsNonEmpty;`
     → chama `GetAttributes(TClasseNativa)` sem `Register` prévio; verifica Length ≥ 1.
   - `[Test] procedure TestDelphi_NativeSuppressedByRegistered_ReturnsRegisteredOnly;`
     → chama `Register(TClasseNativa, [TMyAttr.Create('reg')])`, depois `GetAttributes`,
     verifica Length = 1 e Tag = 'reg' (prova a regra 2 do ADENDO / D-A6 do adr no Delphi).
6. `[TearDown]` para cada teste (ou `Setup`): a registry é global; para evitar interferência,
   cada cenário usa classes-alvo **próprias** (declaradas localmente na função de cenário
   ou como classes distintas por caso). Nada precisa "limpar" a registry — a política é
   append + dedup, não replace.

**`PTestAttributes.dpr`:**

- Espelha `PTestObjects.dpr` — `DUnitX.Loggers.Console`, `DUnitX.Loggers.Xml.NUnit`,
  `DUnitX.TestFramework`.
- **`ReportMemoryLeaksOnShutdown := True;`** no início do `begin ... end.` (CA-6 do esp).
- `uses`: `UTestMS.Attributes in 'UTestMS.Attributes.pas'`,
  `UTestMS.Attributes.Scenarios in '..\..\Test Shared\EclbrSystem\UTestMS.Attributes.Scenarios.pas'`,
  `ModernSyntax.Attributes in '..\..\Source\ModernSyntax.Attributes.pas'`.
- **NÃO** contém `{$IFNDEF FPC}` nem `{$MESSAGE FATAL}` — a guarda vive **na casca `.pas`**
  (D-A8 do adr).

**`PTestAttributes.dproj` (search path):**

- Adicionar `..\..\Test Shared\EclbrSystem` no campo **"Search path"** (equivalente do `-Fi`
  do FPC). **Sintaxe exata é verificação pendente do lado Delphi** — o autor confirma no PR.

**Como conferir:**

- `grep -n '{\$IFDEF' 'Test Delphi/EclbrSystem/UTestMS.Attributes.pas'` — apenas
  `{$IFDEF HAS_NATIVE_ATTRS}` (símbolo de **capacidade**, não de compilador — CA-5 do PRD
  no espírito, D-A7 do adr do ciclo #7). **Zero** `{$IFDEF FPC}` na casca.
- `grep -n '{\$IFDEF' 'Test Delphi/EclbrSystem/PTestAttributes.dpr'` → **0**.
- Cada `procedure` `[Test]` tem no máximo **uma linha útil** que chama o cenário.
- `PTestAttributes.dproj` contém referência a `..\..\Test Shared\EclbrSystem` no search path.
- `ReportMemoryLeaksOnShutdown := True;` presente no `.dpr`.

## Fatia 4 — Casca fina FPC (FPCUnit) + `.lpi`/`.lpr`

**Arquivos criados:**

- `Test FPC/EclbrSystem/UTestMS.Attributes.pas` — casca FPCUnit.
- `Test FPC/EclbrSystem/PTestAttributes.lpr` — programa de teste `consoletestrunner`.
- `Test FPC/EclbrSystem/PTestAttributes.lpi` — projeto Lazarus escrito à mão.

**O que entra em `UTestMS.Attributes.pas` (FPC):**

1. Cabeçalho + `unit UTestMS.Attributes; interface`.
2. **Mesma guarda** de include da casca Delphi (D-A8 do adr):
   ```pascal
   {$I UTestMS.Attributes.Symbols.inc}
   {$IF NOT DEFINED(HAS_NATIVE_ATTRS) AND NOT DEFINED(NO_NATIVE_ATTRS)}
     {$MESSAGE FATAL 'UTestMS.Attributes.Symbols.inc nao foi incluido'}
   {$IFEND}
   ```
3. `uses fpcunit, testregistry, UTestMS.Attributes.Scenarios, ModernSyntax.Attributes;`
4. `TAttributesTests = class(TTestCase) published ...` com um método por cenário
   compartilhado. Cada método tem uma linha útil.
5. **Teste FPC-only** atrás de `{$IFDEF NO_NATIVE_ATTRS}`:
   - `procedure TestFPC_NativeAlone_NoRegister_ReturnsEmpty;`
     → confirma que `GetAttributes(TClasseArbitraria)` **sem** `Register` prévio retorna
     `Length = 0`. O caso existe para **provar a divergência silenciosa** entre compiladores
     e amarrar a fronteira portável (RSK-1 do esp).
6. `initialization RegisterTest(TAttributesTests);`

**`PTestAttributes.lpr`:**

```pascal
program PTestAttributes;
{$mode objfpc}{$H+}
uses
  consoletestrunner,
  UTestMS.Attributes,
  UTestMS.Attributes.Scenarios,
  ModernSyntax.Attributes;
type
  TAppRunner = class(TTestRunner);
var
  App: TAppRunner;
begin
  App := TAppRunner.Create(nil);
  App.Title := 'PTestAttributes';
  App.Run;
  App.Free;
end.
```

**`PTestAttributes.lpi`** (escrito à mão, forward slashes):

- Alvo: `PTestAttributes.lpr`.
- Dois build modes: `Debug-i386` e `Debug-x86_64` (mesmo padrão do `.lpi` do ciclo #7).
- `<CompilerOptions><Parsing><IncludeFiles>` contendo
  `-Fi"$(ProjPath)../../Test Shared/EclbrSystem"` (D-A11 do adr).
- `<CompilerOptions><SearchPaths><OtherUnitFiles>` apontando para `../../Source` e
  `../../Test Shared/EclbrSystem` (para achar `ModernSyntax.Attributes.pas` e
  `UTestMS.Attributes.Scenarios.pas`).
- `<RequiredPackages>` incluindo `FCL` (traz `fpcunit` e `consoletestrunner`, medido no
  ciclo #7).

**Como conferir:**

- `grep -n '{\$IFDEF' 'Test FPC/EclbrSystem/UTestMS.Attributes.pas'` — apenas
  `{$IFDEF NO_NATIVE_ATTRS}` (símbolo de **capacidade**). **Zero** `{$IFDEF FPC}` na casca.
- `grep -n 'DUnitX' 'Test FPC/EclbrSystem/'*.pas 'Test FPC/EclbrSystem/'*.lpr` → **0**.
- Cada método `published` da fixture tem no máximo **uma linha útil**.
- `PTestAttributes.lpi` inclui `../../Source` e `../../Test Shared/EclbrSystem` em
  `<OtherUnitFiles>`, e `-Fi"$(ProjPath)../../Test Shared/EclbrSystem"` em `<IncludeFiles>`.
- Dois build modes: `Debug-i386` e `Debug-x86_64`.

## Fatia 5 — Ajustes de include search path e verificação final

Não cria arquivos novos; garante que a fatia 3 (`.dproj`) e a fatia 4 (`.lpi`) tenham os
paths corretos, e roda os greps de aceitação:

**Ajustes:**

- Confirmar que `PTestAttributes.dproj` tem `..\..\Test Shared\EclbrSystem` no search path
  (RSK-3 do esp — verificação pendente do lado Delphi, autor mede).
- Confirmar que `PTestAttributes.lpi` tem `-Fi"$(ProjPath)../../Test Shared/EclbrSystem"`
  e `../../Source` em `<OtherUnitFiles>`.

**Verificação final (o `implementer` roda antes de fechar):**

- `grep -rn '{\$IFDEF FPC}' 'Test Shared/EclbrSystem/UTestMS.Attributes.Scenarios.pas' 'Test Delphi/EclbrSystem/UTestMS.Attributes.pas' 'Test FPC/EclbrSystem/UTestMS.Attributes.pas'`
  → **0** (CA-4 do esp).
- `grep -n '{$I ModernSyntax.inc}' Source/ModernSyntax.Attributes.pas` → **0** (CA-9 do esp).
- `grep -n 'FCP' Source/ModernSyntax.Attributes.pas` → **0** (CA-9 do esp).
- O orquestrador executa `lazbuild --build-mode=Debug-i386 "Test FPC/EclbrSystem/PTestAttributes.lpi"`
  e `lazbuild --build-mode=Debug-x86_64 ...` **na máquina do autor** (R2 do PRD).
- Autor compila `PTestAttributes.dproj` no Delphi.

## Pós-condições do ciclo

- [ ] `Source/ModernSyntax.Attributes.pas` existe, sem `{$I ModernSyntax.inc}` e sem token `FCP`.
- [ ] `interface` expõe `TModernAttribute`, `TAttributeRecord`, `ModernAttributes` — e nada
  mais público além do que R-FPC-Generic obriga.
- [ ] `GetAttributes` aplica **regra 2 do ADENDO** no Delphi (dedup por classe entre nativo
  e Owned, registrado prevalece).
- [ ] `Register` é append com dedup por **identidade de referência**.
- [ ] `finalization` libera apenas `Owned`; nunca instâncias vindas da RTTI.
- [ ] `Test Shared/EclbrSystem/UTestMS.Attributes.Symbols.inc` existe com a linha exata
  `{$IFDEF FPC}{$DEFINE NO_NATIVE_ATTRS}{$ELSE}{$DEFINE HAS_NATIVE_ATTRS}{$ENDIF}`.
- [ ] `Test Shared/EclbrSystem/UTestMS.Attributes.Scenarios.pas` existe, sem `{$IFDEF}`, sem
  framework, com os cinco cenários obrigatórios.
- [ ] `Test Delphi/EclbrSystem/UTestMS.Attributes.pas` + `PTestAttributes.dpr`/`.dproj`
  existem; o `.dproj` inclui `..\..\Test Shared\EclbrSystem` no search path; o `.dpr` tem
  `ReportMemoryLeaksOnShutdown := True`.
- [ ] Casca Delphi tem o `{$I}` mais a guarda `{$IF NOT DEFINED(...) AND NOT DEFINED(...)}
  {$MESSAGE FATAL ...}{$IFEND}`; único `{$IFDEF}` de compilador é `HAS_NATIVE_ATTRS`
  (capacidade).
- [ ] `Test FPC/EclbrSystem/UTestMS.Attributes.pas` + `PTestAttributes.lpr` + `.lpi`
  existem; `.lpi` tem dois build modes; `<IncludeFiles>` tem `-Fi` para
  `../../Test Shared/EclbrSystem`; `<OtherUnitFiles>` tem `../../Source` e
  `../../Test Shared/EclbrSystem`.
- [ ] Casca FPC tem o `{$I}` + guarda idêntica; único `{$IFDEF}` de compilador é
  `NO_NATIVE_ATTRS` (capacidade).
- [ ] `grep -rn '{\$IFDEF FPC}' 'Test Shared/' 'Test Delphi/' 'Test FPC/'` → **0** (CA-4).
- [ ] Body do PR declara: *"compilado em FPC 3.2.2 x86_64 e i386; não compilado em Delphi —
  Delphi permanece com o autor"* + *"atributo portável TEM de passar por `Register`;
  `[MyAttr]` nativo sozinho é conveniência Delphi e não atravessa. Quando ambos coexistem,
  o registrado prevalece por classe."* + *"CA-2 na letra (`ModernRTTI.GetType(T).GetAttributes`)
  fica para a issue #8 delegar — esta issue entrega implementação; a #8 entrega fachada."*
