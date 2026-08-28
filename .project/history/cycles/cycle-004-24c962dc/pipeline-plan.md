---
type: plan
kind: artifact
title: "Plan — Callbacks transversais da ModernRTTI (issue #7)"
description: "Plano de execução em quatro fatias: unit ModernSyntax.Callback; unit comum de cenários em Test Shared/; casca fina DUnitX + .dproj no lado Delphi; casca fina FPCUnit + .lpi no lado FPC."
status: draft
cycle: "004"
agent: architect
workflow: equipe-feature
node: "plan-gate:on_reject"
resource: aefos://run/24c962dcc2be1819336ca1fea18ae949
tags: [plan, modernrtti, callbacks, issue-7]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-08-28T13:30:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — Callbacks transversais"
  - id: adr
    resource: "adr.md"
    title: "ADR — Design da unit ModernSyntax.Callback"
---

# Plano de execução — Callbacks (issue #7)

**Scope estimate.** Foundation module de três interfaces + factory
(implementação enxuta) + nova convenção de testes com **três diretórios
tocados** (`Test Shared/`, `Test Delphi/`, `Test FPC/`) e **dois projetos**
(`.dproj` e `.lpi`). Nenhuma das fatias abaixo é mergeável sozinha — a
unit sem os testes não prova portabilidade; os testes sem a unit não
compilam; a casca FPC sem o `.lpi` não roda (CA-6 do PRD). **Test 1
(SIZE):** implementação cabe em um orçamento de implementação normal —
a unit é pequena e os testes são cascas finas com uma unit comum.
**Test 2 (INDEPENDENCE):** **não** há independência entre as fatias.
Conclusão: `scope = fits`, quatro fatias sequenciais no mesmo ciclo.

## Fatia 1 — `Source/ModernSyntax.Callback.pas`

**Arquivos criados:** `Source/ModernSyntax.Callback.pas`.

**O que entra:**

1. Cabeçalho MIT em `(* ... *)` — **não** `{ }`. Diretivas `{$...}`
   não podem aparecer dentro de comentário `{ }` em Pascal: o `}` da
   diretiva fecha o comentário externo e o resto do cabeçalho vira
   código (D-A12 do [adr](pipeline-adr.md); quebra nos dois compiladores).
2. `unit ModernSyntax.Callback;` — **sem** `{$I ModernSyntax.inc}`
   (D-A5 do [adr](pipeline-adr.md)).
3. `interface` com `uses SysUtils;` — **só isso** (D-A1 do adr, RN-5 do
   [esp](pipeline-esp.md)).
4. Declaração das três interfaces sem GUID (D-A2 do adr):
   - `IModernFunc<T, R>` com `function Invoke(const AValue: T): R;`
   - `IModernProc<T>` com `procedure Invoke(const AValue: T);`
   - `IModernPredicate<T>` com `function Invoke(const AValue: T): Boolean;`
5. Declaração do factory `Callback` (record de métodos de classe) com
   **três** sobrecargas `Of` (D-A3 e D-A6 do adr — **sem** a sobrecarga
   `TFunc<T,R>`):
   - método de objeto que retorna R (para `IModernFunc<T,R>`);
   - método de objeto que só executa (para `IModernProc<T>`);
   - método de objeto que retorna Boolean (para `IModernPredicate<T>`).
6. Três classes wrapper declaradas na **`interface`** (não na
   `implementation`) — exigência do FPC 3.2.2 (D-A13 do
   [adr](pipeline-adr.md)): `TFuncOfObjectWrapper<T,R>`, `TProcOfObjectWrapper<T>`,
   `TPredicateOfObjectWrapper<T>`, cada uma herdando de
   `TInterfacedObject` e guardando o `TMethod` em campo. Posicionadas
   na `interface` logo após a declaração do factory. O factory instancia
   o wrapper e o devolve pela interface — o consumidor nunca vê a classe
   wrapper.
7. Ramificação (typedefs internos, se necessário) via
   `{$IFDEF FPC} ... {$ELSE} ... {$ENDIF}` **direto** no arquivo —
   nunca via `.inc` (D-A5 do adr).

**Como conferir:**

- `grep -n '{$I ModernSyntax.inc}' Source/ModernSyntax.Callback.pas` → 0
- `grep -n 'FCP' Source/ModernSyntax.Callback.pas` → 0
- `grep -n '^uses' Source/ModernSyntax.Callback.pas` — apenas
  `uses SysUtils;` na `interface`.
- Superfície pública contém `IModernFunc`, `IModernProc`,
  `IModernPredicate`, `Callback` e as três classes wrapper na
  `interface` (D-A13 do adr / RN-1 do esp atualizado).
- **Compilação FPC (obrigatória antes de qualquer outra verificação):**
  compilar apenas `Source/ModernSyntax.Callback.pas`, não `Source/*.pas`
  inteiro (0 de 16 units compilam hoje). Limpar o diretório de saída
  antes de cada build — build incremental do FPC reporta verde sobre
  código velho. Executar para x86_64 e i386. Zero erros de symtable e
  zero erros de sintaxe = pré-condição para abrir o PR.

## Fatia 2 — `Test Shared/EclbrSystem/UTestMS.Callback.Scenarios.pas`

**Diretório novo:** `Test Shared/EclbrSystem/`.

**Arquivos criados:**

- `Test Shared/EclbrSystem/UTestMS.Callback.Scenarios.pas` — unit de
  cenários **sem framework de teste** (D-A7 do adr).

**O que entra:**

1. `uses SysUtils, ModernSyntax.Callback;` — nada de DUnitX, nada de
   FPCUnit.
2. Exceção interna para falha: `ETestScenarioFailed = class(Exception);`
3. Classe helper de captura declarada **na própria unit de cenários**,
   como exemplo canônico:
   ```pascal
   TAccumulator = class(TInterfacedObject, IModernFunc<Integer, Integer>)
   private
     FAcc: Integer;
   public
     function Invoke(const AValue: Integer): Integer;
     property Acc: Integer read FAcc;
   end;
   ```
4. Classe host com métodos de objeto para o cenário
   `Callback.Of(Self.MinhaProc)`:
   ```pascal
   THost = class
     function Double(const AValue: Integer): Integer;
     procedure LogSeen(const AValue: Integer);
     function IsPositive(const AValue: Integer): Boolean;
   end;
   ```
5. Procedures de cenário — cada uma executa e levanta na falha:
   - `procedure CallbackOf_MethodOfObject_Func_Returns;`
   - `procedure CallbackOf_MethodOfObject_Proc_Executes;`
   - `procedure CallbackOf_MethodOfObject_Predicate_ReturnsBoolean;`
   - `procedure Interface_CapturesState_ViaHelperClass;`
6. **Nenhum `{$IFDEF}`** nesta unit (CA-4 do esp).

**Como conferir:**

- `grep -n '{\$IFDEF' 'Test Shared/EclbrSystem/UTestMS.Callback.Scenarios.pas'` → 0
- `grep -n 'DUnitX\|FPCUnit\|TestFramework\|fpcunit' 'Test Shared/EclbrSystem/UTestMS.Callback.Scenarios.pas'` → 0
- Cada cenário levanta `ETestScenarioFailed` (ou qualquer `Exception`)
  na falha; nenhum retorna Boolean/string de status — a exceção **é** o
  contrato.

## Fatia 3 — Casca fina Delphi (DUnitX) + `.dproj`

**Arquivos criados:**

- `Test Delphi/EclbrSystem/UTestMS.Callback.pas` — casca DUnitX.
- `Test Delphi/EclbrSystem/PTestModernCallback.dpr` — projeto de teste
  (+ `.dproj` e `.res` no padrão dos outros `PTest*.dpr`).

**O que entra:**

1. `UTestMS.Callback.pas`: `uses DUnitX.TestFramework,
   UTestMS.Callback.Scenarios;` e uma classe `[TestFixture]
   TCallbackTests` com **um método por cenário**, cada método com **até
   uma linha útil**:
   ```pascal
   [Test]
   procedure CallbackOf_MethodOfObject_Func_Returns;
   // implementação:
   UTestMS.Callback.Scenarios.CallbackOf_MethodOfObject_Func_Returns;
   ```
2. `PTestModernCallback.dpr` espelha `PTest*.dpr` já existentes; usa
   `DUnitX.Loggers.Console`, `DUnitX.Loggers.Xml.NUnit`, `DUnitX.TestFramework`.
3. **Search path do `.dproj`:** adicionar `..\..\Test Shared\EclbrSystem`
   em `<DCC_UnitSearchPath>` (Q2 do relatório de investigação).

**Como conferir:**

- `grep -n '{\$IFDEF' 'Test Delphi/EclbrSystem/UTestMS.Callback.pas' 'Test Delphi/EclbrSystem/PTestModernCallback.dpr'` → 0.
- Cada `procedure` da fixture tem no máximo uma linha útil e chama uma
  função de `UTestMS.Callback.Scenarios` (D-A7 do adr — sem `if/then`
  de asserção na casca).
- O `.dproj` contém o path para `Test Shared\EclbrSystem` no search
  path.

## Fatia 4 — Casca fina FPC (FPCUnit) + `.lpi`

**Diretórios novos:** `Test FPC/`, `Test FPC/EclbrSystem/`.

**Arquivos criados:**

- `Test FPC/EclbrSystem/UTestMS.Callback.pas` — casca FPCUnit.
- `Test FPC/EclbrSystem/PTestModernCallback.lpr` — programa de teste
  usando `consoletestrunner`.
- `Test FPC/EclbrSystem/PTestModernCallback.lpi` — projeto Lazarus com:
  - alvo `PTestModernCallback.lpr`
  - dois modos de build: `Debug-i386` e `Debug-x86_64`
  - `<OtherUnitFiles>` apontando para `../../Source` **e**
    `../../Test Shared/EclbrSystem`
  - `<RequiredPackages>` incluindo `FCL` (traz `fpcunit` e
    `consoletestrunner`).

**O que entra em `UTestMS.Callback.pas` (FPCUnit):**

```pascal
uses fpcunit, testregistry, UTestMS.Callback.Scenarios;

type
  TCallbackTests = class(TTestCase)
  published
    procedure CallbackOf_MethodOfObject_Func_Returns;
    procedure CallbackOf_MethodOfObject_Proc_Executes;
    procedure CallbackOf_MethodOfObject_Predicate_ReturnsBoolean;
    procedure Interface_CapturesState_ViaHelperClass;
  end;

// cada método: uma linha
procedure TCallbackTests.CallbackOf_MethodOfObject_Func_Returns;
begin
  UTestMS.Callback.Scenarios.CallbackOf_MethodOfObject_Func_Returns;
end;

initialization
  RegisterTest(TCallbackTests);
```

**Como conferir:**

- `grep -rn '{\$IFDEF FPC}' 'Test FPC/'` → 0 (CA-4 do esp).
- `grep -n 'DUnitX' 'Test FPC/EclbrSystem/'*.pas 'Test FPC/EclbrSystem/'*.lpr` → 0.
- Cada método da fixture tem no máximo uma linha útil.
- `PTestModernCallback.lpi` inclui `../../Source` e
  `../../Test Shared/EclbrSystem` em `<OtherUnitFiles>`.
- Orquestrador executa `lazbuild --build-mode=Debug-i386
  PTestModernCallback.lpi` e `lazbuild --build-mode=Debug-x86_64
  PTestModernCallback.lpi` **na máquina do autor** — a fábrica não roda
  (R2 do PRD).

## Pós-condições do ciclo

- [ ] `Source/ModernSyntax.Callback.pas` existe, passa nos greps de
  `ModernSyntax.inc` e `FCP` retornando zero, e a interface `uses`
  apenas `SysUtils`.
- [ ] `Test Shared/EclbrSystem/UTestMS.Callback.Scenarios.pas` existe,
  não contém `{$IFDEF}`, não referencia framework de teste.
- [ ] `Test Delphi/EclbrSystem/UTestMS.Callback.pas` +
  `PTestModernCallback.dpr` existem; `.dproj` inclui `Test Shared/`
  no search path.
- [ ] `Test FPC/EclbrSystem/UTestMS.Callback.pas` +
  `PTestModernCallback.lpr` + `PTestModernCallback.lpi` existem; o
  `.lpi` inclui `Source/` e `Test Shared/EclbrSystem/` em
  `<OtherUnitFiles>`; dois build modes: `Debug-i386` e `Debug-x86_64`.
- [ ] `grep -rn '{\$IFDEF FPC}' 'Test Shared/' 'Test Delphi/' 'Test FPC/'` → 0
  (CA-4 do esp).
- [ ] FPC 3.2.2 compilou `Source/ModernSyntax.Callback.pas` sem erros
  de symtable e sem erros de sintaxe em x86_64 e i386 (evidência no
  corpo do PR).
- [ ] FPCUnit executou `PTestModernCallback.lpi` e todos os casos
  passaram em x86_64 e i386 (evidência no corpo do PR).
- [ ] Body do PR declara: "compilado em FPC 3.2.2 x86_64 e i386; não
  compilado em Delphi — Delphi permanece com o autor" (CA-7 do esp, R2
  do PRD).
