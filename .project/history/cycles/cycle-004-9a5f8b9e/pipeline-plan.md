---
type: plan
kind: artifact
title: "Plan — Pilar 1 da ModernRTTI: unit de leitura de RTTI + cenários + cascas de teste (issue #8)"
description: "Plano de execução em cinco fatias sequenciais: unit ModernSyntax.RTTI; cenários compartilhados; casca Delphi + runner + registro no groupproj/DCC.bat; casca FPC entrando no .lpi criado pela #7."
status: draft
cycle: "004"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/9a5f8b9e974c23d88b7b6aba11e2973d
tags: [plan, modernrtti, rtti, pilar-1, issue-8]
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
---

# Plano de execução — Pilar 1 da ModernRTTI (issue #8)

**Scope estimate.** Uma unit de produção greenfield (~200-300 linhas
com XML doc), uma unit de cenários (~150 linhas com fixtures), duas
cascas finas de teste (~30-50 linhas cada) e edição de três arquivos
de projeto (`TestMSGroup.groupproj`, `DCC.bat`, `.lpi` da #7).

**Test 1 (SIZE):** cabe em um orçamento de implementação normal — a
unit é pequena, os testes são cascas finas com cenários compartilhados,
nenhuma package/plataforma adicional. **NÃO exaure** um budget de
implementação.

**Test 2 (INDEPENDENCE):** as cinco fatias abaixo **não** são
independentes — a unit sem os testes não prova portabilidade; os
testes sem a unit não compilam; a casca FPC sem o registro no `.lpi`
não roda (CA-10). Sequência obrigatória.

**Conclusão: `scope = fits`, cinco fatias sequenciais no mesmo ciclo.**

## Fatia 1 — `Source/ModernSyntax.RTTI.pas` (unit de produção)

**Arquivos criados:**

- `Source/ModernSyntax.RTTI.pas`

**O que entra (ordem no arquivo):**

1. Cabeçalho MIT SPDX no padrão de `Source/ModernSyntax.Objects.pas:1-12`
   (`/analysis/05-conventions.md` §1.5).
2. `unit ModernSyntax.RTTI;` — **sem** `{$I ModernSyntax.inc}` (D-7 do
   [adr](pipeline-adr.md)).
3. `interface` com `uses Rtti, TypInfo, SysUtils;` — **exatamente
   essas três** (D-8 do adr; RN-7 do [esp](pipeline-esp.md)).
4. `type EModernRTTIError = class(Exception);` (RN-1 do esp).
5. `TModernRTTIField = record` (D-2 do adr):
   - `strict private FField: TRttiField;`
   - `class function Wrap(AField: TRttiField): TModernRTTIField; static;`
     (construtor interno usado por `TModernRTTIType.GetFields`).
   - `public`:
     - `function Name: string;` (delega a `FField.Name`).
     - `function GetValue<T>(const AInstance: TObject): T;`
     - `procedure SetValue<T>(const AInstance: TObject; const AValue: T);`
     - `function GetValue(const AInstance: TObject): TValue; overload;`
       com `/// <remarks>Escape hatch — obriga uses Rtti no consumidor.
       Prefira o overload genérico.</remarks>`
     - `procedure SetValue(const AInstance: TObject; const AValue: TValue); overload;`
       (idem `<remarks>`).
6. `TModernRTTIProperty = record` (mesmo padrão), adicionando:
   - `function IsReadable: Boolean;`
   - `function IsWritable: Boolean;`
7. `TModernRTTIType = record`:
   - `strict private FType: TRttiType;`
   - `class function Wrap(AType: TRttiType): TModernRTTIType; static;`
   - `public`:
     - `function Name: string;`
     - `function GetProperties: TArray<TModernRTTIProperty>;` com
       `/// <remarks>` de ownership (D-4 do adr).
     - `function GetFields: TArray<TModernRTTIField>;` com `/// <remarks>`
       de ownership.
8. `TModernRTTI = record`:
   - `strict private class var FContext: TRttiContext;`
   - `public`:
     - `class function GetType(AClass: TClass): TModernRTTIType; overload; static;`
       com `/// <remarks>` de ownership.
     - `class function GetType(ATypeInfo: PTypeInfo): TModernRTTIType; overload; static;`
       (mesmo `<remarks>`).
9. `implementation`:
   - Wrappers `Wrap` triviais atribuindo o campo.
   - `TModernRTTIType.GetProperties`:
     ```pascal
     var LProps: TArray<TRttiProperty>;
     begin
       LProps := FType.GetProperties;
       if (Length(LProps) = 0) and MissingPublishedRTTI then
         raise EModernRTTIError.CreateFmt(SNoRTTI, [FType.Name]);
       // envelopa em TArray<TModernRTTIProperty> e devolve
     end;
     ```
   - `MissingPublishedRTTI: Boolean` — helper local privado que
     encapsula a heurística R4 (D-6 do adr): `FType is TRttiInstanceType`,
     não é `TObject`, `PropCount == 0` em `TypeData`.
     `{$IFDEF FPC}`/`{$ELSE}` **direto** aqui se a implementação
     precisar divergir por compilador (D-7 do adr).
   - `SNoRTTI: string` — constante local com o rascunho da mensagem
     (D-6 do adr): *"A classe %s não expõe propriedades à RTTI. No
     Delphi isso indica ausência real de propriedades `public`/`published`;
     no FPC exige `{$M+}` antes da declaração da classe e uma seção
     `published` com as propriedades desejadas. Adicione ambos e
     recompile."*
   - `GetValue<T>` genérico: delega a `FProp.GetValue(AInstance).AsType<T>`
     (Delphi) / equivalente FPC via `{$IFDEF FPC}` interno se
     `TValue.AsType<T>` falhar (RSK-2 do esp).
   - `SetValue<T>` genérico: constrói `TValue.From<T>(AValue)` e
     delega.
   - `initialization`:
     ```pascal
     TModernRTTI.FContext := TRttiContext.Create;
     ```
   - `finalization`:
     ```pascal
     TModernRTTI.FContext.Free;
     ```
   - Padrão medido em `Source/ModernSyntax.Objects.pas:195,601`.
10. `end.`

**Como conferir (leitura + grep — a fábrica não compila; R2 do PRD):**

- `grep -n '{\$I ModernSyntax.inc}' Source/ModernSyntax.RTTI.pas` → 0
  (CA-6 do esp).
- `grep -n 'FCP' Source/ModernSyntax.RTTI.pas` → 0 (CA-6 do esp).
- `grep -n '^uses' Source/ModernSyntax.RTTI.pas` — a linha `uses` da
  `interface` contém exatamente `Rtti, TypInfo, SysUtils`.
- `grep -n 'Windows\|Classes\|Variants\|SyncObjs' Source/ModernSyntax.RTTI.pas`
  → 0.
- `grep -n 'ModernSyntax\.' Source/ModernSyntax.RTTI.pas` → só o
  cabeçalho e o `unit ModernSyntax.RTTI;` (nenhuma unit interna
  importada — RN-7 do esp).
- Superfície pública contém `EModernRTTIError`, `TModernRTTIField`,
  `TModernRTTIProperty`, `TModernRTTIType`, `TModernRTTI` — e nenhum
  outro identificador não prefixado com `E`/`T` (RN-1 do esp).
- XML doc `///` em todos os membros públicos (RN-10 do esp;
  `/analysis/05-conventions.md` §4.3).

## Fatia 2 — `Test Shared/EclbrSystem/UScenarios.RTTI.pas` (cenários)

**Diretório:** `Test Shared/EclbrSystem/` já **criado pela #7** — este
ciclo apenas adiciona um arquivo. Se a #7 ainda não mergeou, o commit
cria o diretório (mas então o PR também declara o bloqueio de CA-7/CA-10).

**Arquivos criados:**

- `Test Shared/EclbrSystem/UScenarios.RTTI.pas` — unit de cenários
  **sem framework** (D-9 do [adr](pipeline-adr.md)).

**O que entra:**

1. `unit UScenarios.RTTI;`
2. `interface uses SysUtils, ModernSyntax.RTTI;` — nada de DUnitX,
   nada de FPCUnit.
3. Classes de fixture com `{$M+}` + `published`, declaradas no
   próprio arquivo:
   ```pascal
   type
     {$M+}
     TFixturePropertied = class
     private
       FValue: Integer;
       FName: string;
     published
       property Value: Integer read FValue write FValue;
       property Name: string read FName write FName;
     end;
     {$M-}

     TFixtureFielded = class
     public
       IntField: Integer;
       StrField: string;
     end;

     TFixtureMissingM = class  // sem {$M+}
     public
       IntField: Integer;
     end;
   ```
4. Uma exceção interna para falha do cenário:
   `ETestScenarioFailed = class(Exception);`
5. Um helper local `procedure Ensure(ACond: Boolean; const AMsg: string);`
   que levanta `ETestScenarioFailed` na falha.
6. Cenários (procedures top-level; CA-1..CA-4 do esp):
   - `Scenario_GetProperties_ReturnsPublishedProps`:
     - Instancia `ModernRTTI.GetType(TFixturePropertied).GetProperties`.
     - `Ensure(Length(props) = 2, '...');`
     - Verifica nomes `Value` e `Name`.
     - **Também exercita `GetValue<Integer>`/`GetValue<string>`** contra
       uma instância `TFixturePropertied` populada (CA-3 do esp).
   - `Scenario_GetFields_ReturnsFields`:
     - `ModernRTTI.GetType(TFixtureFielded).GetFields`.
     - `Ensure(Length(fields) = 2, '...');`
     - Verifica nomes `IntField` e `StrField`.
     - Exercita `GetValue<T>`/`SetValue<T>` numa instância.
   - `Scenario_MissingM_RaisesEModernRTTIError` (CA-4 do esp):
     ```pascal
     try
       ModernRTTI.GetType(TFixtureMissingM).GetProperties;
       Ensure(False, 'esperava EModernRTTIError');
     except
       on E: EModernRTTIError do
         Ensure(Pos('{$M+}', E.Message) > 0,
                'mensagem deve mencionar {$M+}');
     end;
     ```
   - `Scenario_GetValue_RoundTripsGenericT` — cobre `Integer`, `string`
     e um record simples (`type TFixtureRec = record I: Integer; end;`
     como campo de uma classe fixture). Se `TValue.AsType<T>` do FPC
     falhar para o record (RSK-2 do esp), o cenário registra a
     limitação como mensagem informativa e continua — não é falha do
     esp, é limite conhecido.
7. **Nenhum `{$IFDEF}`** nesta unit (CA-5 do esp).

**Como conferir:**

- `grep -n '{\$IFDEF' 'Test Shared/EclbrSystem/UScenarios.RTTI.pas'` → 0.
- `grep -n 'DUnitX\|fpcunit\|TestFramework' 'Test Shared/EclbrSystem/UScenarios.RTTI.pas'`
  → 0.
- Cada cenário levanta `ETestScenarioFailed` (ou `EModernRTTIError`
  no caso do MissingM) na falha — nenhum retorna Boolean/string.

## Fatia 3 — Casca fina Delphi (DUnitX) — `Test Delphi/EclbrSystem/UTestMS.RTTI.pas`

**Arquivos criados:**

- `Test Delphi/EclbrSystem/UTestMS.RTTI.pas`

**O que entra:**

1. `unit UTestMS.RTTI;`
2. `interface uses DUnitX.TestFramework, UScenarios.RTTI;`
3. `type [TestFixture] TRTTITests = class` com `[Setup]`, `[TearDown]`
   e um `[Test]` por cenário. Cada método tem **até uma linha útil**:
   ```pascal
   [Test]
   procedure GetProperties_ReturnsPublishedProps;
   // implementação:
   UScenarios.RTTI.Scenario_GetProperties_ReturnsPublishedProps;
   ```
4. Padrão dos outros `UTestMS.*.pas` (ver
   `Test Delphi/EclbrSystem/UTestMS.Objects.pas:1`).

**Como conferir:**

- `grep -n '{\$IFDEF' 'Test Delphi/EclbrSystem/UTestMS.RTTI.pas'` → 0
  (CA-5 do esp).
- Cada `procedure` da fixture tem no máximo uma linha útil e delega a
  `UScenarios.RTTI.*` (D-9 do adr — sem `if/then` de asserção na casca;
  D-A7 do adr #7).

## Fatia 4 — Runner Delphi + registro no `groupproj` + `DCC.bat`

**Arquivos criados:**

- `Test Delphi/EclbrSystem/PTestRTTI.dpr`
- `Test Delphi/EclbrSystem/PTestRTTI.dproj` (+ `.res` se o padrão dos
  outros `PTest*` exigir).

**Arquivos modificados:**

- `Test Delphi/EclbrSystem/TestMSGroup.groupproj` — adicionar entrada
  `PTestRTTI.dproj` (hoje 13, passa a 14 — CA-9 do esp).
- `Test Delphi/EclbrSystem/DCC.bat` — adicionar `PTestRTTI` à lista
  (hoje 13 projetos, passa a 14 — CA-9 do esp).

**O que entra em `PTestRTTI.dpr`:**

Espelhar `Test Delphi/EclbrSystem/PTestObjects.dpr:1-74` (D-2 do STUDY
— 11/11 runners Delphi usam `FastMM4`). Estrutura mínima:

- `uses FastMM4, System.SysUtils, DUnitX.Loggers.Console,
   DUnitX.Loggers.Xml.NUnit, DUnitX.TestFramework,
   {$IFDEF TESTINSIGHT} TestInsight.DUnitX, {$ENDIF}
   UTestMS.RTTI in 'UTestMS.RTTI.pas',
   UScenarios.RTTI in '..\..\Test Shared\EclbrSystem\UScenarios.RTTI.pas';`
- Bloco `try/except` padrão dos outros `PTest*.dpr`.

**O que entra no `.dproj`:**

- Search path incluindo `..\..\Source` e `..\..\Test Shared\EclbrSystem`
  em `<DCC_UnitSearchPath>` (mesmo ajuste que a #7 fez para
  `Test Shared/`).
- Padrão dos outros `PTest*.dproj` (verificar contra `PTestObjects.dproj`
  antes de commitar).

**Como conferir:**

- `grep -n '{\$IFDEF' 'Test Delphi/EclbrSystem/PTestRTTI.dpr'
  'Test Delphi/EclbrSystem/UTestMS.RTTI.pas'` → só o `{$IFDEF TESTINSIGHT}`
  do padrão (não é `{$IFDEF FPC}`; CA-5 do esp).
- `grep -c 'dproj' 'Test Delphi/EclbrSystem/TestMSGroup.groupproj'`
  cresce em relação ao valor anterior (13 → 14).
- `grep -c 'PTest' 'Test Delphi/EclbrSystem/DCC.bat'` idem (13 → 14).
- Só adicionar as entradas no groupproj/DCC.bat **depois** que o
  autor confirmar que `PTestRTTI.dpr` compila localmente em Delphi
  (RSK-6 do esp).

## Fatia 5 — Casca fina FPC (FPCUnit) + registro no `.lpi` da #7

**Dependência:** infra da #7 mergeada — `Test FPC/EclbrSystem/` existe,
`Test FPC/EclbrSystem/PTestModern*.lpi` (nome exato definido pela #7)
existe.

**Arquivos criados:**

- `Test FPC/EclbrSystem/UTestMS.RTTI.pas`

**Arquivos modificados:**

- `Test FPC/EclbrSystem/<nome-do-lpi-da-#7>.lpi` — adicionar
  `UTestMS.RTTI.pas` como `<Unit>` do projeto (padrão Lazarus). Adicionar
  também `UScenarios.RTTI` ao `<OtherUnitFiles>` se a #7 ainda não
  incluir `Test Shared/EclbrSystem/` (ela deve incluir; verificar).

**O que entra em `UTestMS.RTTI.pas` (FPCUnit):**

```pascal
unit UTestMS.RTTI;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, UScenarios.RTTI;

type
  TRTTITests = class(TTestCase)
  published
    procedure GetProperties_ReturnsPublishedProps;
    procedure GetFields_ReturnsFields;
    procedure MissingM_RaisesEModernRTTIError;
    procedure GetValue_RoundTripsGenericT;
  end;

implementation

procedure TRTTITests.GetProperties_ReturnsPublishedProps;
begin
  UScenarios.RTTI.Scenario_GetProperties_ReturnsPublishedProps;
end;

// (etc — uma linha útil por método)

initialization
  RegisterTest(TRTTITests);

end.
```

**Como conferir:**

- `grep -rn '{\$IFDEF FPC}' 'Test FPC/EclbrSystem/UTestMS.RTTI.pas'`
  → 0 (CA-5 do esp).
- `grep -n 'DUnitX' 'Test FPC/EclbrSystem/UTestMS.RTTI.pas'` → 0
  (D-9 do adr — FPCUnit no lado FPC).
- Cada método da fixture tem no máximo uma linha útil.
- O `.lpi` da #7 lista `UTestMS.RTTI.pas` como `<Unit>` e resolve
  `UScenarios.RTTI` via `<OtherUnitFiles>`.
- Orquestrador executa `lazbuild --build-mode=Debug-i386 <lpi-da-#7>`
  e `lazbuild --build-mode=Debug-x86_64 <lpi-da-#7>` **na máquina do
  autor** — a fábrica não roda (R2 do PRD).

**Fallback se a #7 não mergeou.** Esta fatia **não** cria `.lpi`
próprio (lição do commit `06fccea`). Se `Test FPC/EclbrSystem/` não
existir na base de trabalho, criar apenas `Test FPC/EclbrSystem/UTestMS.RTTI.pas`
como *skeleton* e o body do PR declara: *"CA-10 pendente: `.lpi` da
#7 ainda não mergeado; casca FPC registrada mas não construída"*.

## Pós-condições do ciclo

- [ ] `Source/ModernSyntax.RTTI.pas` existe; grep de `{\$I ModernSyntax.inc}`
  e de `FCP` retorna 0; `interface` `uses Rtti, TypInfo, SysUtils`
  e nada mais (CA-6 do esp).
- [ ] `Test Shared/EclbrSystem/UScenarios.RTTI.pas` existe; sem
  `{$IFDEF}`; sem framework de teste; classes de fixture com `{$M+}`
  + `published` declaradas no próprio arquivo.
- [ ] `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` + `PTestRTTI.dpr` +
  `.dproj` existem; `.dproj` inclui `..\..\Test Shared\EclbrSystem`
  no search path; groupproj passa a 14 entradas; `DCC.bat` passa a
  14 projetos (CA-9 do esp).
- [ ] `Test FPC/EclbrSystem/UTestMS.RTTI.pas` existe e está
  registrado no `.lpi` da #7 (CA-10 do esp) — **ou** o PR declara o
  bloqueio explicitamente.
- [ ] `grep -rn '{\$IFDEF FPC}' 'Test Shared/EclbrSystem/UScenarios.RTTI.pas'
  'Test Delphi/EclbrSystem/UTestMS.RTTI.pas'
  'Test FPC/EclbrSystem/UTestMS.RTTI.pas'` → 0 (CA-5 do esp).
- [ ] Body do PR declara: *"compilado em FPC 3.2.2 x86_64 e i386; não
  compilado em Delphi — Delphi permanece com o autor"* (CA-8 do esp,
  R2 do PRD). Se a #7 não mergeou, adiciona *"CA-7/CA-10 pendentes:
  bloqueado por #7"*.
