---
type: task-input
kind: artifact
title: "Task input — implementar Source/ModernSyntax.Invoker.pas e as duas cascas de teste"
description: "Handoff operacional para o implementador: criar a unit ModernSyntax.Invoker (record com dois overloads Invoke<TSignature> sobre MethodAddress), a unit comum de sete cenários, e as duas cascas finas (DUnitX + FPCUnit) com projetos .dproj e .lpi."
status: draft
cycle: "005"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/2ef372d993ff75b8dcd8c707bb79d636
tags: [task-input, modernrtti, invoker, issue-10, feature]
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
  - id: plan
    resource: "plan.md"
    title: "Plan — TModernInvoker"
---

# Task input — TModernInvoker (issue #10)

**Issue:** [isaquepinheiro/ModernSyntax#10](https://github.com/isaquepinheiro/ModernSyntax/issues/10)
**Tipo:** feature
**Labels:** `feature`, `aefos:running`

## Objetivo (uma frase)

Criar `Source/ModernSyntax.Invoker.pas` com `TModernInvoker` — `record` com dois overloads
`class function Invoke<TSignature>(TObject|TClass, string): TSignature; static;` sobre
`TObject.MethodAddress` — para dar a **mesma chamada nos dois compiladores** (CA-3 do PRD),
com testes portáveis via unit compartilhada + duas cascas finas (DUnitX e FPCUnit).

## Divergências / esclarecimentos **declarados** do texto da issue

- **Mecanismo mudou da premissa do STUDY para `TObject.MethodAddress`.** O STUDY apostava
  em `TRttiContext.GetType(...).GetMethod(...).Invoke`; a investigação (volta 1) mediu
  no alvo (FPC 3.2.2 x86_64) que `GetMethods = 0` e `GetMethod('Echo') = nil` para
  qualquer classe, mesmo com `{$M+}` e `published`. **Q1 do PRD não exigiu `{$IFDEF}`
  interno; exigiu trocar o mecanismo.** O PR declara isso em voz alta.
- **API dinâmica no padrão da RTTI nova do Delphi** (`GetType(T).GetMethod('X').Invoke(obj,
  [args]): TValue`) — pedida pelo dono na volta 2, avaliada como impossível no FPC 3.2.2,
  **fica fora desta issue**. Recomendação: abrir issue irmã, superfície Delphi-only
  **ausente por compilação no FPC** (ver [adr.md D-A9](pipeline-adr.md)).

## Escopo

Ver [esp.md](pipeline-esp.md) §2 e §3, e [plan.md](pipeline-plan.md). Em resumo:

- Uma unit nova em `Source/ModernSyntax.Invoker.pas`.
- Uma unit comum de cenários em `Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas`.
- Uma casca fina DUnitX + `.dpr` + `.dproj` em `Test Delphi/EclbrSystem/`.
- Uma casca fina FPCUnit + `.lpi` + `.lpr` em `Test FPC/EclbrSystem/`.

**Não há `.inc` de símbolos nesta issue** (diferente do ciclo #8): a Invoker se comporta
igual em Delphi e FPC, então não há símbolo de capacidade a definir.

**Fora deste ciclo:**

- Fachada `ModernSyntax.RTTI.pas` (entregável da issue #8; delegará para
  `ModernAttributes.GetAttributes`, não para o Invoker).
- API dinâmica no padrão da RTTI nova do Delphi (issue irmã; ver [adr.md D-A9](pipeline-adr.md)).
- Extensão/modificação de `TModernObject.Factory` em `Source/ModernSyntax.Objects.pas`
  (D5 do PRD).
- Correção do bug `{$IFDEF FCP}` em `ModernSyntax.inc:256` (R3 do PRD).
- Adicionar `PTestInvoker` ao `TestMSGroup.groupproj` e ao `DCC.bat` (gap conhecido
  pós-entrega — passo manual do autor).

## Checklist de aceite

### Unit de produção

- [ ] `Source/ModernSyntax.Invoker.pas` criado. Header MIT/SPDX em `(* ... *)`
  (R-Comment-Nest / [adr D-A6](pipeline-adr.md)). Sem `{$I ModernSyntax.inc}`. Sem token `FCP`.
- [ ] `uses` da `interface`: **apenas** `SysUtils`. Sem `Rtti`, sem `TypInfo`, sem
  `Windows`, sem qualquer unit de `Source/`.
- [ ] Superfície pública: **apenas** `TModernInvoker = record ... end;` com **dois**
  `class function Invoke<TSignature>(...) : TSignature; overload; static;`.
- [ ] **Primeira linha** dos dois corpos: `if SizeOf(TSignature) <> SizeOf(TMethod) then
  raise Exception.Create('TSignature nao e um tipo de metodo-de-objeto');`
- [ ] Guarda de `nil` no `AInstance`/`AClass` **imediatamente depois** da guarda `SizeOf`.
- [ ] `addr := AInstance.MethodAddress(AMethodName);` (ou `AClass.MethodAddress(...)`).
- [ ] Se `addr = nil`: `raise Exception.CreateFmt('metodo "%s" nao encontrado em %s; no
  FPC isso exige {$M+} e secao published', [AMethodName, <ClassName do alvo>])`.
- [ ] Se `addr <> nil`: `m.Code := addr; m.Data := AInstance` (ou `Pointer(AClass)`);
  `Move(m, Result, SizeOf(TMethod));`.
- [ ] **Zero `{$IFDEF FPC}`** no arquivo inteiro.
- [ ] Header documenta em texto: (a) por que a unit é autocontida; (b) que a guarda
  `SizeOf` cobre "não é método", não "outro tipo de 16 bytes"; (c) que o corpo do
  genérico só toca `TMethod` da RTL para evitar *"Global Generic template references
  static symtable"*.

### Cenários compartilhados

- [ ] `Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas` criado, sem `{$IFDEF}`, sem
  `uses` de framework de teste. Contém as **classes-alvo locais** (`TSubject`,
  `TSubjectWithClassMethod`, `TNoM`) — as duas primeiras com `{$M+}` + `published`,
  `TNoM` **sem** `{$M+}` (para provar o CA-6 do esp).
- [ ] Tipos de assinatura declarados na unit: `TEchoFn`, `TSumFn`, `TAnswerFn`
  (`... of object`).
- [ ] Cenários implementados (uma procedure por caso, `Exception` na falha):
  - `Case_Invoke_InstanceMethod_ReturnsValue`
  - `Case_TypedMethod_CalledWithArgs_ReturnsExpected` (**rename** — [adr D-A10](pipeline-adr.md))
  - `Case_Invoke_ClassMethod_Works`
  - `Case_Invoke_MethodNotFound_RaisesWithActionableMessage` (verifica que a mensagem
    contém tanto `{$M+}` quanto `published`)
  - `Case_Invoke_NilInstance_Raises`
  - `Case_Invoke_PublicMethodWithoutMPlus_RaisesNotFound`
  - `Case_Invoke_NonMethodSignature_Raises`

### Casca Delphi

- [ ] `Test Delphi/EclbrSystem/UTestMS.Invoker.pas` criado. `uses DUnitX.TestFramework,
  UTestMS.Invoker.Cases, ModernSyntax.Invoker;`.
- [ ] `[TestFixture] TInvokerTests = class` com **um `[Test]` por cenário compartilhado**
  (sete no total). Cada método tem **até uma linha útil** — chamada do `Case_...`.
- [ ] `PTestInvoker.dpr` criado copiando `PTestObjects.dpr` como base, com
  `ReportMemoryLeaksOnShutdown := True;` no início do `begin ... end.`.
- [ ] `PTestInvoker.dpr` **não** contém `{$IFNDEF FPC}` nem `{$MESSAGE FATAL}` de guarda
  de include (não há `.inc` nesta issue).
- [ ] `PTestInvoker.dproj` criado copiando `PTestObjects.dproj` como base, trocando
  `MainSource` e nomes de arquivo.
- [ ] Casca Delphi tem **zero** `{$IFDEF FPC}` e **zero** `{$IFDEF HAS_NATIVE_ATTRS}`
  (símbolo da issue #9 que **não se aplica** aqui).

### Casca FPC

- [ ] `Test FPC/EclbrSystem/UTestMS.Invoker.pas` criado. `{$mode delphi}{$H+}` no topo;
  `uses fpcunit, testregistry, UTestMS.Invoker.Cases, ModernSyntax.Invoker;`.
- [ ] `TInvokerTests = class(TTestCase) published` com **um método por cenário
  compartilhado**, cada um com uma linha útil.
- [ ] `initialization RegisterTest(TInvokerTests);`.
- [ ] Casca FPC tem **zero** `{$IFDEF FPC}`.
- [ ] `PTestInvoker.lpr` criado com `program PTestInvoker;`, `{$mode objfpc}{$H+}`,
  `uses consoletestrunner, UTestMS.Invoker, UTestMS.Invoker.Cases, ModernSyntax.Invoker;`,
  e o corpo padrão `TAppRunner`.
- [ ] `PTestInvoker.lpi` escrito à mão, forward slashes, dois build modes (`Debug-i386`
  e `Debug-x86_64`); `<OtherUnitFiles>` aponta para `../../Source` e
  `../../Test Shared/EclbrSystem`; `<RequiredPackages>` inclui `FCL`.
- [ ] **Sem `<IncludeFiles>` com `-Fi`** — não há `.inc` nesta issue.

### Verificação por grep (aceitação final)

- [ ] `grep -rn '{\$IFDEF FPC}' 'Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas'
  'Test Delphi/EclbrSystem/UTestMS.Invoker.pas' 'Test FPC/EclbrSystem/UTestMS.Invoker.pas'`
  → **0** (CA-8 do esp; CA-5 do PRD).
- [ ] `grep -n '{$I ModernSyntax.inc}' Source/ModernSyntax.Invoker.pas` → **0**.
- [ ] `grep -n 'FCP' Source/ModernSyntax.Invoker.pas` → **0**.
- [ ] `grep -n '{\$IFDEF' Source/ModernSyntax.Invoker.pas` → **0** (unit não tem
  ramificação alguma).
- [ ] `grep -rn 'DUnitX' 'Test FPC/EclbrSystem/'*.pas 'Test FPC/EclbrSystem/'*.lpr` → **0**.
- [ ] `grep -n '^uses' Source/ModernSyntax.Invoker.pas` — apenas `uses SysUtils;` na
  `interface`.

### PR body (mandatório)

- [ ] Declaração de compilação: *"compilado em FPC 3.2.2 x86_64 e i386; não compilado em
  Delphi — Delphi permanece com o autor."*
- [ ] Resposta explícita de **Q1 do PRD**: *"Q1 não exigiu `{$IFDEF}` interno; a
  divergência real que replaneou o Pilar 3 foi `GetMethods = 0` no FPC 3.2.2, medida na
  volta 1 da investigação da #10 (`{$mode delphi}{$M+}`, seção `published`). O mecanismo
  escolhido é `TObject.MethodAddress`, símbolo comum aos dois compiladores; a unit
  `Rtti` não é usada."*
- [ ] Contrato da API: *"`TModernInvoker.Invoke<TSignature>(AInstance, 'Nome')` devolve
  o método já tipado; consumidor declara `type TFn = function(...) : T of object;` antes
  de invocar. Não existe `Invoke(obj, 'Nome', [args]): TValue` nesta entrega — o custo
  estrutural de mecanismo único."*
- [ ] Recomendação de issue irmã: *"API dinâmica no padrão da RTTI nova do Delphi
  (`GetType(T).GetMethod('X').Invoke(obj,[args]): TValue`) sai para issue irmã, com
  superfície declaradamente Delphi-only ausente por compilação no FPC (`{$IFDEF DELPHI}`
  na declaração inteira). Divergência que quebra o build é honesta; divergência silenciosa
  em runtime é o defeito nº 1 do PRD."*

## Arquivos prováveis impactados

**Criados (novos):**

- `Source/ModernSyntax.Invoker.pas`
- `Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas`
- `Test Delphi/EclbrSystem/UTestMS.Invoker.pas`
- `Test Delphi/EclbrSystem/PTestInvoker.dpr` (+ `.dproj` + `.res`)
- `Test FPC/EclbrSystem/UTestMS.Invoker.pas`
- `Test FPC/EclbrSystem/PTestInvoker.lpr`
- `Test FPC/EclbrSystem/PTestInvoker.lpi`

**Não tocar nesta issue:**

- `Source/ModernSyntax.Objects.pas` — D5 do PRD (não estender `TModernObject.Factory`).
- `Source/ModernSyntax.RTTI.pas` — issue #8.
- `Source/ModernSyntax.Attributes.pas` — issue #9 (não é dependência do Invoker).
- `Source/ModernSyntax.inc` — R3 do PRD.
- `Test Delphi/EclbrSystem/DCC.bat` e `TestMSGroup.groupproj` — passo manual pós-entrega.
- Nenhuma unit de `Source/` existente é importada (nenhuma compila em FPC 3.2.2; ver
  [SKILL](../../../SKILL.md) §"Two traps" #1).

## Notas de implementação

- **`uses` da unit nova:** somente `SysUtils`. Nada mais. Nenhuma unit `Rtti`/`TypInfo`.
  Nenhuma unit de `Source/`.
- **Ramificação:** **zero** `{$IFDEF FPC}` na unit. `MethodAddress` é o mesmo símbolo com
  a mesma assinatura nos dois compiladores.
- **Guarda `SizeOf`** é literalmente a **primeira linha** de cada corpo — se aparecer
  qualquer código antes dela, é bug.
- **Guarda `nil`** de `AInstance`/`AClass` vem imediatamente depois — antes de chamar
  `MethodAddress` (que dispararia AV em `nil`).
- **Mensagem acionável** de "não encontrado" **deve** citar `{$M+}` **e** `published` —
  o teste `Case_Invoke_MethodNotFound_RaisesWithActionableMessage` verifica os dois.
- **Cascas com UMA linha útil** por caso. `if/then` de asserção na casca é vazamento —
  a lógica pertence ao `Cases.pas`.
- **Classes-alvo dos cenários são LOCAIS ao `Cases.pas`** — não vazam para casca, não
  vazam para outra unit. `TSubject` e `TSubjectWithClassMethod` têm `{$M+}` + `published`;
  `TNoM` **não** tem `{$M+}` (é o próprio ponto do teste de CA-6).
- **Convenção do repositório para `.dpr`/`.dproj`:** copiar `PTestObjects.dpr`/`.dproj`
  como base — é o padrão da família Delphi (mais próximo do padrão atual do repositório
  do que qualquer template genérico DUnitX).

## Dependências externas

- Nenhuma. Este ciclo cria o `.lpi` próprio dos testes desta unit; a convenção da família
  ModernRTTI (`Test FPC/EclbrSystem/` + `Test Shared/EclbrSystem/`) já existe (ciclos #7,
  #8) e é reutilizada aqui.

## Verificação final (checklist de PR)

- [ ] Todas as verificações por grep acima retornam **0** ou o esperado.
- [ ] O orquestrador compila `PTestInvoker.lpr` (via `fpc -Mdelphi -Fu... -FU... -FE...`,
  precedido de `rm -rf <out>`) na máquina do autor, **nos dois bitnesses** — SKILL §"The
  command". Ambos passam sete testes.
- [ ] Delphi compila `PTestInvoker.dproj` (pelo autor); todos os testes DUnitX passam.
- [ ] `ReportMemoryLeaksOnShutdown` não reporta vazamento.
- [ ] Body do PR carrega as quatro declarações mandatórias acima.
