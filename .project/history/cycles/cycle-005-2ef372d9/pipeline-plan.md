---
type: plan
kind: artifact
title: "Plan — TModernInvoker (issue #10)"
description: "Plano de execução em quatro fatias sequenciais: unit ModernSyntax.Invoker; unit comum de cenários em Test Shared/; casca fina DUnitX + .dpr/.dproj; casca fina FPCUnit + .lpi/.lpr."
status: draft
cycle: "005"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/2ef372d993ff75b8dcd8c707bb79d636
tags: [plan, modernrtti, invoker, issue-10]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-08-28T14:15:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — TModernInvoker"
  - id: adr
    resource: "adr.md"
    title: "ADR — Design da unit ModernSyntax.Invoker"
---

# Plano de execução — TModernInvoker (issue #10)

**Scope estimate.** Um pilar do ModernRTTI: uma unit de produção **enxuta** (`record` com
dois overloads sobre `MethodAddress`, ~66 linhas com header — o dono compilou o desenho
inteiro no FPC 3.2.2 na volta 2 da investigação), mais os testes na convenção da família
(`Test Shared/` + `Test Delphi/` + `Test FPC/`).

- **Test 1 (SIZE)** — implementação cabe folgado em um orçamento normal: a unit é
  pequena, os testes são cascas finas, nenhum arquivo existente é modificado (`grep -rn
  "Invoker\|ModernInvoker" Source/` = 0).
- **Test 2 (INDEPENDENCE)** — nenhuma fatia é mergeável sozinha: sem a unit os cenários
  não compilam; sem cenários compartilhados as cascas divergem; sem a casca FPC não há
  CA-9 do esp/CA-7 do PRD.

Conclusão: **`scope = fits`**, quatro fatias sequenciais no mesmo ciclo.

## Fatia 1 — `Source/ModernSyntax.Invoker.pas`

**Arquivos criados:**

- `Source/ModernSyntax.Invoker.pas`.

**O que entra:**

1. Header MIT/SPDX em **`(* ... *)`** (R-Comment-Nest / D-A6 do [adr](pipeline-adr.md)). Zero
   `{$...}` dentro de `{ }`. Documenta em comentário do header:
   - por que a unit é autocontida (D-A1 do adr);
   - por que a guarda `SizeOf` é incompleta (D-A5 do adr, RSK-1 do esp);
   - por que o corpo do genérico só toca `TMethod` (D-A7 do adr — evita static symtable).
2. `unit ModernSyntax.Invoker;` — **sem** `{$I ModernSyntax.inc}` (RN-6 do
   [esp](pipeline-esp.md); R3 do PRD).
3. `interface` com **apenas** `uses SysUtils;` (RN-5/CA-11 do esp).
4. Declaração de `TModernInvoker` com **dois** `class function` estáticos genéricos:
   ```pascal
   type
     TModernInvoker = record
     public
       class function Invoke<TSignature>(const AInstance: TObject;
         const AMethodName: string): TSignature; overload; static;
       class function Invoke<TSignature>(const AClass: TClass;
         const AMethodName: string): TSignature; overload; static;
     end;
   ```
5. Implementação — **os dois overloads têm o mesmo shape**, mudando só o alvo do
   `MethodAddress` e o `m.Data`:
   ```pascal
   class function TModernInvoker.Invoke<TSignature>(
     const AInstance: TObject; const AMethodName: string): TSignature;
   var
     addr: Pointer;
     m: TMethod;
   begin
     if SizeOf(TSignature) <> SizeOf(TMethod) then
       raise Exception.Create('TSignature nao e um tipo de metodo-de-objeto');
     if AInstance = nil then
       raise Exception.Create('AInstance e nil');
     addr := AInstance.MethodAddress(AMethodName);
     if addr = nil then
       raise Exception.CreateFmt(
         'metodo "%s" nao encontrado em %s; no FPC isso exige {$M+} e secao published',
         [AMethodName, AInstance.ClassName]);
     m.Code := addr;
     m.Data := AInstance;
     Move(m, Result, SizeOf(TMethod));
   end;

   class function TModernInvoker.Invoke<TSignature>(
     const AClass: TClass; const AMethodName: string): TSignature;
   var
     addr: Pointer;
     m: TMethod;
   begin
     if SizeOf(TSignature) <> SizeOf(TMethod) then
       raise Exception.Create('TSignature nao e um tipo de metodo-de-objeto');
     if AClass = nil then
       raise Exception.Create('AClass e nil');
     addr := AClass.MethodAddress(AMethodName);
     if addr = nil then
       raise Exception.CreateFmt(
         'metodo "%s" nao encontrado em %s; no FPC isso exige {$M+} e secao published',
         [AMethodName, AClass.ClassName]);
     m.Code := addr;
     m.Data := Pointer(AClass);
     Move(m, Result, SizeOf(TMethod));
   end;
   ```
   **Observações:**
   - A guarda `SizeOf` é **a primeira linha** dos dois corpos (RN-3 do esp, D-A5 do adr).
   - A guarda `nil` vem imediatamente depois, evita AV ao chamar `MethodAddress` em
     `nil.MethodAddress(...)` (CA-5 do esp).
   - `AInstance.ClassName` / `AClass.ClassName` compõem a mensagem acionável (RN-4 do esp).
6. Nenhum bloco `initialization`/`finalization` — a unit não tem estado.

**Como conferir (leitura + grep — a fábrica não compila):**

- `grep -n '{$I ModernSyntax.inc}' Source/ModernSyntax.Invoker.pas` → **0** (CA-10 do esp).
- `grep -n 'FCP' Source/ModernSyntax.Invoker.pas` → **0** (CA-10 do esp).
- `grep -n '{\$IFDEF FPC}' Source/ModernSyntax.Invoker.pas` → **0** (CA-10 do esp).
- `grep -n '^uses' Source/ModernSyntax.Invoker.pas` — apenas `uses SysUtils;` na
  `interface` (CA-11 do esp).
- Header em `(* ... *)`; nenhum `{$...}` dentro de `{ }`.
- Superfície pública: **apenas** `TModernInvoker`; nada mais.

## Fatia 2 — Unit comum de cenários em `Test Shared/EclbrSystem/`

**Arquivos criados:**

- `Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas` — cenários sem framework.

**O que entra:**

1. `uses SysUtils, ModernSyntax.Invoker;` — **zero** framework de teste, **zero** `{$IFDEF}`.
2. `type ETestScenarioFailed = class(Exception);` (opcional — pode usar `Exception` cru,
   contanto que a casca não trate: qualquer exceção vira `Fail`).
3. **Classes-alvo locais** à unit, com `{$M+}` (obrigatório) e seção `published`:
   ```pascal
   {$M+}
   type
     TSubject = class
     published
       function Echo(const s: string): string;
       function Sum(a, b: Integer): Integer;
       function GreetPublic(const s: string): string;  // fica em public, NAO published
     public
       function GreetPublic(const s: string): string;
     end;

     TSubjectWithClassMethod = class
     published
       class function Answer: Integer;
     end;

     TNoM = class  // SEM {$M+} — método public que MethodAddress NAO acha
     public
       function Echo(const s: string): string;
     end;
   {$M-}
   ```
   (A separação exata `{$M+}`/`{$M-}` fica a cargo do implementador; o importante é que
   `TNoM` seja compilada **sem** `{$M+}` para que `MethodAddress('Echo')` retorne `nil`.)
4. **Tipo de assinatura** declarado na unit para os cenários que precisam dele:
   ```pascal
   type
     TEchoFn   = function(const s: string): string of object;
     TSumFn    = function(a, b: Integer): Integer of object;
     TAnswerFn = function: Integer of object;
   ```
5. **Sete procedures de cenário** (cada uma levanta `Exception` na falha):
   - `procedure Case_Invoke_InstanceMethod_ReturnsValue;`
     → cria `TSubject`; `fn := TModernInvoker.Invoke<TEchoFn>(o, 'Echo');` chama `fn('x')`;
     verifica `= 'echo:x'`. (CA-1 do esp)
   - `procedure Case_TypedMethod_CalledWithArgs_ReturnsExpected;`
     → cria `TSubject`; `fn := TModernInvoker.Invoke<TSumFn>(o, 'Sum');` chama `fn(2, 3)`;
     verifica `= 5`. Nome descreve o que o teste **de fato** prova (D-A10 do adr).
     (CA-3 do esp)
   - `procedure Case_Invoke_ClassMethod_Works;`
     → `fn := TModernInvoker.Invoke<TAnswerFn>(TSubjectWithClassMethod, 'Answer');`
     chama `fn()`; verifica `= 42`. Overload de `TClass`, `m.Data := Pointer(AClass)`.
     (CA-2 do esp)
   - `procedure Case_Invoke_MethodNotFound_RaisesWithActionableMessage;`
     → cria `TSubject`; espera `Exception` de `TModernInvoker.Invoke<TEchoFn>(o, 'NaoExiste')`;
     verifica que a **mensagem** contém `{$M+}` **e** `published`. (CA-4 do esp)
   - `procedure Case_Invoke_NilInstance_Raises;`
     → passa `nil` como `AInstance`; espera `Exception`. (CA-5 do esp)
   - `procedure Case_Invoke_PublicMethodWithoutMPlus_RaisesNotFound;`
     → cria `TNoM` (classe **sem** `{$M+}`); chama `Invoke<TEchoFn>(o, 'Echo')`; espera
     `Exception` de "não encontrado" com a mesma mensagem acionável.
     (CA-6 do esp — herança da família #8)
   - `procedure Case_Invoke_NonMethodSignature_Raises;`
     → chama `TModernInvoker.Invoke<Integer>(o, 'Echo')`; espera `Exception` com a
     mensagem *"TSignature nao e um tipo de metodo-de-objeto"*. (CA-7 do esp)
6. Cada cenário levanta `Exception` na falha; nenhum retorna `Boolean`. **A exceção é o
   contrato.**

**Notas de coordenação:**

- **Não há `.inc` de símbolos** nesta issue — a Invoker se comporta **igual** em Delphi e
  FPC (RN-7 do esp; D-A8 do adr). Portanto **não há** `HAS_NATIVE_ATTRS`/`NO_NATIVE_ATTRS`
  neste ciclo; a guarda `{$MESSAGE FATAL}` da família #8/#9 **não se aplica**.
- Classes-alvo são **locais à Cases.pas** — não vaza para casca nem para outra unit
  (evita colisão em fixtures futuras).

**Como conferir:**

- `grep -n '{\$IFDEF' 'Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas'` → **0** (CA-8 do esp).
- `grep -n 'DUnitX\|fpcunit\|TestFramework' 'Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas'`
  → **0**.
- Cada cenário levanta `Exception` na falha; nenhum retorna Boolean/string de status.

## Fatia 3 — Casca fina Delphi (DUnitX) + `.dpr`/`.dproj`

**Arquivos criados:**

- `Test Delphi/EclbrSystem/UTestMS.Invoker.pas` — casca DUnitX.
- `Test Delphi/EclbrSystem/PTestInvoker.dpr` — projeto de teste.
- `Test Delphi/EclbrSystem/PTestInvoker.dproj` (+ `.res` no padrão dos outros `PTest*`).

**O que entra em `UTestMS.Invoker.pas` (Delphi):**

1. Cabeçalho + `unit UTestMS.Invoker;`.
2. `interface`, `uses DUnitX.TestFramework, UTestMS.Invoker.Cases, ModernSyntax.Invoker;`.
3. `[TestFixture] TInvokerTests = class` com **um** `[Test]` por cenário compartilhado.
   Cada método tem **até uma linha útil** (RN-10 do esp / D-A7 do adr):
   ```pascal
   [Test] procedure Invoke_InstanceMethod_ReturnsValue;
   // implementação:
   Case_Invoke_InstanceMethod_ReturnsValue;
   ```
   Os sete `[Test]`:
   - `Invoke_InstanceMethod_ReturnsValue`
   - `TypedMethod_CalledWithArgs_ReturnsExpected`
   - `Invoke_ClassMethod_Works`
   - `Invoke_MethodNotFound_RaisesWithActionableMessage`
   - `Invoke_NilInstance_Raises`
   - `Invoke_PublicMethodWithoutMPlus_RaisesNotFound`
   - `Invoke_NonMethodSignature_Raises`
4. **Sem `Setup`/`TearDown` explícito** — a Invoker é sem estado; cada teste cria a
   instância-alvo local, verifica, libera. Nada precisa de escopo compartilhado.
5. **Zero `{$IFDEF FPC}`** e **zero `{$IFDEF DELPHI}`** na casca. Nada de guarda de
   `.inc` — não há `.inc` (D-A8 do adr).

**`PTestInvoker.dpr`:**

Espelha `PTestObjects.dpr` (padrão da família):

```pascal
program PTestInvoker;
{$IFNDEF TESTINSIGHT}{$APPTYPE CONSOLE}{$ENDIF}
{$STRONGLINKTYPES ON}
uses
  System.SysUtils,
  {$IFDEF TESTINSIGHT}
  TestInsight.DUnitX,
  {$ELSE}
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  {$ENDIF}
  DUnitX.TestFramework,
  UTestMS.Invoker in 'UTestMS.Invoker.pas',
  UTestMS.Invoker.Cases in '..\..\Test Shared\EclbrSystem\UTestMS.Invoker.Cases.pas',
  ModernSyntax.Invoker in '..\..\Source\ModernSyntax.Invoker.pas';
begin
  ReportMemoryLeaksOnShutdown := True;
  { ... corpo padrão DUnitX, cópia de PTestObjects.dpr ... }
end.
```

- **`ReportMemoryLeaksOnShutdown := True;`** logo no início do `begin ... end.`.
- **NÃO** contém `{$IFNDEF FPC}` nem `{$MESSAGE FATAL}`.

**`PTestInvoker.dproj`:**

- **Padrão dos outros `PTest*.dproj`** do repositório — copiar `PTestObjects.dproj` como
  base, trocar nomes de arquivo e o `MainSource`.
- **Não precisa** de search path adicional para `Test Shared/` — a Fatia 3 usa
  `in '..\..\Test Shared\...'` no `.dpr` (caminho explícito), padrão do repositório.
  *(Este ciclo, diferente do ciclo #8, não tem `.inc` para carregar — logo, sem `-Fi`
  equivalente no Delphi.)*

**Como conferir:**

- `grep -n '{\$IFDEF' 'Test Delphi/EclbrSystem/UTestMS.Invoker.pas'` → **0** (CA-8 do esp).
- `grep -n '{\$IFDEF' 'Test Delphi/EclbrSystem/PTestInvoker.dpr'` — apenas `{$IFNDEF TESTINSIGHT}`
  padrão da família (não é `FPC`).
- Cada `procedure [Test]` tem no máximo **uma linha útil** que chama o `Case_...`.
- `ReportMemoryLeaksOnShutdown := True;` presente no `.dpr`.

## Fatia 4 — Casca fina FPC (FPCUnit) + `.lpi`/`.lpr`

**Arquivos criados:**

- `Test FPC/EclbrSystem/UTestMS.Invoker.pas` — casca FPCUnit.
- `Test FPC/EclbrSystem/PTestInvoker.lpr` — programa de teste `consoletestrunner`.
- `Test FPC/EclbrSystem/PTestInvoker.lpi` — projeto Lazarus escrito à mão.

**O que entra em `UTestMS.Invoker.pas` (FPC):**

1. Cabeçalho + `unit UTestMS.Invoker;`.
2. `{$mode delphi}{$H+}` no topo (compatibilidade com sintaxe Delphi para o `Invoker`).
3. `interface`, `uses fpcunit, testregistry, UTestMS.Invoker.Cases, ModernSyntax.Invoker;`.
4. `type TInvokerTests = class(TTestCase) published ...` com **sete** métodos, um por
   cenário compartilhado. Cada um com **uma linha útil**:
   ```pascal
   procedure TInvokerTests.Invoke_InstanceMethod_ReturnsValue;
   begin
     Case_Invoke_InstanceMethod_ReturnsValue;
   end;
   ```
5. `initialization RegisterTest(TInvokerTests);`
6. **Zero `{$IFDEF FPC}`** na casca (CA-8 do esp).

**`PTestInvoker.lpr`:**

```pascal
program PTestInvoker;
{$mode objfpc}{$H+}
uses
  consoletestrunner,
  UTestMS.Invoker,
  UTestMS.Invoker.Cases,
  ModernSyntax.Invoker;
type
  TAppRunner = class(TTestRunner);
var
  App: TAppRunner;
begin
  App := TAppRunner.Create(nil);
  App.Title := 'PTestInvoker';
  App.Run;
  App.Free;
end.
```

**`PTestInvoker.lpi`** (escrito à mão, forward slashes; **espelha o `.lpi` do ciclo #8**):

- Alvo: `PTestInvoker.lpr`.
- Dois build modes: `Debug-i386` e `Debug-x86_64` (mesmo padrão do ciclo #7/#8).
- `<CompilerOptions><SearchPaths><OtherUnitFiles>` apontando para `../../Source` e
  `../../Test Shared/EclbrSystem` (para achar `ModernSyntax.Invoker.pas` e
  `UTestMS.Invoker.Cases.pas`).
- `<RequiredPackages>` incluindo `FCL` (traz `fpcunit` e `consoletestrunner`, medido no
  ciclo #7).
- **Sem `<IncludeFiles>` com `-Fi`** — esta issue **não usa `.inc`** (Fatia 2).

**Como conferir:**

- `grep -n '{\$IFDEF' 'Test FPC/EclbrSystem/UTestMS.Invoker.pas'` → **0** (CA-8 do esp).
- `grep -rn 'DUnitX' 'Test FPC/EclbrSystem/'*.pas 'Test FPC/EclbrSystem/'*.lpr` → **0**.
- Cada método `published` da fixture tem no máximo **uma linha útil**.
- `PTestInvoker.lpi` inclui `../../Source` e `../../Test Shared/EclbrSystem` em
  `<OtherUnitFiles>`.
- Dois build modes: `Debug-i386` e `Debug-x86_64`.
- O comando canônico da SKILL compila:
  ```
  fpc -Mdelphi \
      -Fu"<repo>/Source" \
      -Fu"<repo>/Test Shared/EclbrSystem" \
      -FU<out> -FE<out> \
      "Test FPC/EclbrSystem/PTestInvoker.lpr"
  ```
  para os dois bitnesses, precedido de `rm -rf <out>` (SKILL §"Two traps" trap 2).

## Pós-condições do ciclo

- [ ] `Source/ModernSyntax.Invoker.pas` existe, sem `{$I ModernSyntax.inc}`, sem token
  `FCP`, sem `{$IFDEF FPC}`, com header em `(* ... *)` e `uses SysUtils;` apenas.
- [ ] `interface` expõe **apenas** `TModernInvoker`. Nenhum tipo auxiliar público.
- [ ] Os dois corpos de `Invoke<TSignature>` têm a **guarda `SizeOf` como primeira linha**
  e a mensagem *"TSignature nao e um tipo de metodo-de-objeto"*.
- [ ] Os dois corpos têm guarda de `nil` (na instância ou na classe) antes de
  `MethodAddress`.
- [ ] Mensagem de "não encontrado" contém `{$M+}` **e** `published` (herança #8).
- [ ] `Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas` existe, sem `{$IFDEF}`, sem
  framework, com os **sete** cenários obrigatórios (incluindo o rename D-A10).
- [ ] `Test Delphi/EclbrSystem/UTestMS.Invoker.pas` + `PTestInvoker.dpr`/`.dproj`
  existem; `.dpr` tem `ReportMemoryLeaksOnShutdown := True`.
- [ ] Casca Delphi tem **zero** `{$IFDEF FPC}` e **zero** `{$IFDEF HAS_NATIVE_ATTRS}`
  (símbolo do ciclo #8 que **não se aplica** aqui).
- [ ] `Test FPC/EclbrSystem/UTestMS.Invoker.pas` + `PTestInvoker.lpr` + `.lpi`
  existem; `.lpi` tem dois build modes; `<OtherUnitFiles>` tem `../../Source` e
  `../../Test Shared/EclbrSystem`.
- [ ] Casca FPC tem **zero** `{$IFDEF FPC}`.
- [ ] `grep -rn '{\$IFDEF FPC}' 'Test Shared/' 'Test Delphi/' 'Test FPC/'` → **0** (CA-8).
- [ ] Body do PR declara: *"compilado em FPC 3.2.2 x86_64 e i386; não compilado em Delphi
  — Delphi permanece com o autor"* + a resposta explícita de Q1 do PRD (*"Q1 não exigiu
  `{$IFDEF}` interno; a divergência que replaneou o Pilar 3 foi `GetMethods = 0` no FPC
  3.2.2, medida na volta 1 da investigação; o mecanismo é `TObject.MethodAddress`, símbolo
  comum aos dois compiladores"*) + a **recomendação de issue irmã** para a API dinâmica
  no padrão da RTTI nova do Delphi (Delphi-only por compilação; D-A9 do adr).
