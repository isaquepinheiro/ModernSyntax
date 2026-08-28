---
type: spec
kind: artifact
title: "ESP — Pilar 3 ModernRTTI: TModernInvoker (invocação portável por MethodAddress)"
description: "Especifica TModernInvoker: record com dois overloads Invoke<TSignature>(TObject|TClass, string) sobre TObject.MethodAddress, guarda SizeOf como primeira linha, mensagem acionável quando o método não é achado."
status: draft
cycle: "005"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/2ef372d993ff75b8dcd8c707bb79d636
tags: [modernrtti, invoker, fpc, delphi, spec, issue-10]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-08-28T14:15:00Z"
sources:
  - id: prd
    resource: "../strategy/2026-08-27-modernrtti/PRD.md"
    title: "ModernRTTI PRD"
  - id: study
    resource: "../strategy/2026-08-27-modernrtti/STUDY.md"
    title: "ModernRTTI Study"
  - id: arch
    resource: "../analysis/03-architecture.md"
    title: "03 Architecture — ModernSyntax"
  - id: adr-attrs
    resource: "../history/cycles/cycle-004-e936cbe6/pipeline-adr.md"
    title: "ADR ciclo #8 — Atributos (convenção de teste da família)"
---

# ESP — Pilar 3: `TModernInvoker` (issue #10)

## 1. Objetivo

Entregar o **Pilar 3 do ModernRTTI**: `TModernInvoker.Invoke<TSignature>(AInstance, 'Nome')`
e `TModernInvoker.Invoke<TSignature>(AClass, 'Nome')` disponíveis nos dois compiladores,
com a **mesma chamada no código do consumidor** (CA-3 do
[PRD](../../../strategy/2026-08-27-modernrtti/PRD.md)) e sem `{$IFDEF FPC}` no consumidor (D2).

O mecanismo é `TObject.MethodAddress` — símbolo comum e idêntico em Delphi e FPC 3.2.2,
medido pelo dono na volta 1 da investigação. **Não** se usa `TRttiContext.GetType(...).GetMethod(...).Invoke`
porque no FPC 3.2.2 `GetMethods` devolve `0` para qualquer classe, incluindo classes com
`{$M+}` e seção `published` (medição no alvo, volta 1 da investigação).

## 2. Escopo

**Entra:**

- Nova unit `Source/ModernSyntax.Invoker.pas` (autocontida, sem importar nada de `Source/`).
- Testes portáveis em três diretórios:
  - `Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas` — cenários **sem framework**,
    procedures livres que levantam `Exception` na falha.
  - `Test Delphi/EclbrSystem/UTestMS.Invoker.pas` + `PTestInvoker.dpr` (+ `.dproj` + `.res`) —
    casca fina DUnitX.
  - `Test FPC/EclbrSystem/UTestMS.Invoker.pas` + `PTestInvoker.lpr` + `PTestInvoker.lpi` —
    casca fina FPCUnit.

**Fora do escopo:**

- **Estender ou modificar `TModernObject.Factory`** (`Objects.pas:208-241`) — D5 do PRD.
- **Fachada `ModernRTTI` com `GetType(T).GetMethod('X').Invoke(obj,[args]): TValue`** — medida
  como impossível no FPC 3.2.2 (`GetMethods = 0`); decisão registrada na volta 2 da
  investigação: entra como **superfície Delphi-only ausente por compilação no FPC**, em
  **issue irmã**, fora da #10 (ninguém neste ciclo tem Delphi para provar).
- **`{$IFDEF FPC}` no código do consumidor** (incluindo testes) — CA-5/D2 do PRD.
- **Correção do bug `{$IFDEF FCP}`** em `ModernSyntax.inc:256` (R3 do PRD).
- **Adicionar `PTestInvoker` ao `TestMSGroup.groupproj` e ao `DCC.bat`** — gap conhecido
  pós-entrega, passo manual do autor (mesma nota da issue #9).

## 3. Regras de negócio

- **RN-1.** `TModernInvoker` é **record** (não classe, não interface). Sem estado por
  instância; coerente com `TMatch<T>`/`TAsync`. Decisão do dono na volta 1.
- **RN-2.** A `interface` expõe **apenas** `TModernInvoker` com dois overloads de
  `class function Invoke<TSignature>(...) : TSignature; static;`:
  ```pascal
  TModernInvoker = record
  public
    class function Invoke<TSignature>(const AInstance: TObject;
      const AMethodName: string): TSignature; overload; static;
    class function Invoke<TSignature>(const AClass: TClass;
      const AMethodName: string): TSignature; overload; static;
  end;
  ```
  Nenhum tipo auxiliar vaza para a `interface`.
- **RN-3.** A **primeira linha** de cada corpo é a guarda de tamanho:
  ```pascal
  if SizeOf(TSignature) <> SizeOf(TMethod) then
    raise Exception.Create('TSignature nao e um tipo de metodo-de-objeto');
  ```
  Transforma corrupção silenciosa de memória (ex.: `Invoke<Integer>(o, 'Echo')`) em exceção
  alta. **Limite declarado no header:** não cobre "outro tipo qualquer de 16 bytes"; cobre
  o erro real de passar tipo que não é método-de-objeto. Coberto por
  `Case_Invoke_NonMethodSignature_Raises`.
- **RN-4.** Corpo, após a guarda:
  1. `addr := AInstance.MethodAddress(AMethodName);` — ou `AClass.MethodAddress(AMethodName);`
     no overload de classe.
  2. Se `addr = nil`:
     ```pascal
     raise Exception.CreateFmt(
       'metodo "%s" nao encontrado em %s; no FPC isso exige {$M+} e secao published',
       [AMethodName, <nome do alvo>]);
     ```
     A mensagem **ensina o que fazer** (herança da família #8). O `<nome do alvo>` é
     `AInstance.ClassName` no primeiro overload e `AClass.ClassName` no segundo.
  3. Se `addr <> nil`: monta `TMethod` com `m.Code := addr` e `m.Data := AInstance` (ou
     `Pointer(AClass)` no overload de classe); devolve `TSignature(m)` via
     `Move(m, Result, SizeOf(TMethod))`.
- **RN-5.** A unit é **autocontida**. `uses` da `interface`: **apenas `SysUtils`**.
  **Não usar** `Rtti`/`TypInfo` (não são necessários). **Não importar nenhuma unit de
  `Source/`** — nenhuma das 16 units compila em FPC 3.2.2 hoje (medido pelo dono; ver
  [SKILL](../../../SKILL.md)).
- **RN-6.** **Zero `{$I ModernSyntax.inc}`** (R3 do PRD; o `.inc` tem o token `FCP` em
  `ModernSyntax.inc:256`).
- **RN-7.** **Zero `{$IFDEF FPC}`** no corpo da unit. `MethodAddress` é o mesmo símbolo com
  a mesma assinatura nos dois compiladores (medido).
- **RN-8.** Header SPDX-MIT no formato `(* ... *)` — nunca `{ ... }`. Motivo medido: se um
  dia aparecer `{$...}` dentro do comentário, o `}` da diretiva **fecha o comentário** e
  quebra o arquivo (defeito medido no PR #12 do ciclo #7). Convenção D-3 do estudo, com
  o formato corrigido pela conversa da investigação.
- **RN-9.** **Nenhum tipo declarado na `implementation` é instanciado pelo corpo do
  genérico** — só `TMethod`, que é da RTL. Esta é a evitação por desenho da armadilha
  *"Global Generic template references static symtable"* (medida no PR #12 do ciclo #7).
  Registrada aqui como propriedade estrutural, não como regra a lembrar.
- **RN-10.** Casca de teste: cada método `[Test]` (Delphi) ou `published` (FPC) tem
  **exatamente uma linha útil** — chama o `Case_...` da unit compartilhada, deixa a
  exceção virar `Fail`. Se aparecer `if/then` de asserção na casca, é vazamento.

## 4. Critérios de aceitação

Vinculam CA-3/CA-5/CA-7/D2/R2 do
[PRD](../../../strategy/2026-08-27-modernrtti/PRD.md) ao entregável concreto:

- **CA-1.** `TModernInvoker.Invoke<TFn>(AInstance, 'Nome')` invoca um método por nome nos
  dois compiladores com a **mesma chamada** no código do consumidor (CA-3 do PRD).
  Coberto por `Case_Invoke_InstanceMethod_ReturnsValue`.
- **CA-2.** `TModernInvoker.Invoke<TFn>(AClass, 'Nome')` invoca um `class function`/`class
  procedure` por nome, com a mesma chamada nos dois compiladores. Coberto por
  `Case_Invoke_ClassMethod_Works`.
- **CA-3.** Método achado é chamável com argumentos e devolve o valor esperado. Coberto por
  `Case_TypedMethod_CalledWithArgs_ReturnsExpected` (rename explícito pedido na volta 2:
  o `Invoke` **não** recebe args no desenho A; o teste prova que o `TMethod` montado é
  chamável com args).
- **CA-4.** Método não encontrado levanta exceção com **mensagem acionável** citando
  `{$M+}` e `published`. Coberto por `Case_Invoke_MethodNotFound_RaisesWithActionableMessage`.
- **CA-5.** `nil` como instância levanta exceção antes de tocar qualquer memória.
  Coberto por `Case_Invoke_NilInstance_Raises`.
- **CA-6.** Método `public` (não `published`) em classe **sem `{$M+}`** falha com "não
  encontrado" (herança da família #8: falha de exposição vira exceção, não silêncio).
  Coberto por `Case_Invoke_PublicMethodWithoutMPlus_RaisesNotFound`.
- **CA-7.** `Invoke<TSignature>` com `TSignature` que **não é** método-de-objeto (ex.:
  `Integer`) falha na guarda `SizeOf` com a mensagem *"TSignature nao e um tipo de metodo-de-objeto"*.
  Coberto por `Case_Invoke_NonMethodSignature_Raises`.
- **CA-8.** `grep -rn '{\$IFDEF FPC}' 'Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas'
  'Test Delphi/EclbrSystem/UTestMS.Invoker.pas' 'Test FPC/EclbrSystem/UTestMS.Invoker.pas'`
  → **zero linhas** (CA-5 do PRD).
- **CA-9.** A entrega inclui `Test FPC/EclbrSystem/PTestInvoker.lpi` (+ `.lpr`) que o
  FPC 3.2.2 constrói pelo orquestrador na máquina do autor (CA-6/CA-7 do PRD). O `.lpi`
  traz dois build modes: `Debug-i386` e `Debug-x86_64`.
- **CA-10.** `Source/ModernSyntax.Invoker.pas` **não contém** `{$I ModernSyntax.inc}`, nem
  o token `FCP`, nem `{$IFDEF FPC}`. Verificável por grep.
- **CA-11.** `Source/ModernSyntax.Invoker.pas` **não `uses`** nenhuma unit de `Source/`
  nem a unit `Rtti`. `uses` da `interface` = `SysUtils` apenas.
- **CA-12.** O corpo do PR declara literalmente: *"compilado em FPC 3.2.2 x86_64 e i386;
  não compilado em Delphi — Delphi permanece com o autor"* (R2 do PRD), e reporta o
  achado sobre Q1 do PRD (ver RN-7): **Q1 não exigiu `{$IFDEF}` interno**, porque o
  mecanismo escolhido não é `TRttiMethod.Invoke` — é `TObject.MethodAddress`, símbolo
  comum aos dois compiladores. A divergência real (`GetMethods = 0` no FPC 3.2.2) foi
  o que **derrubou** o mecanismo do estudo e é registrada como parte da resposta de Q1.

## 5. Restrições

- **Alvo FPC:** 3.2.2 estável, 32 e 64 bits (`i386` e `x86_64`).
- **Alvo Delphi:** XE+ (suporte histórico da biblioteca); compilação verificada pelo autor
  (R2 do PRD).
- **Fábrica sem compilador Pascal** — revisão é por leitura (R2 do PRD, ver [SKILL](../../../SKILL.md)).
- **`uses` da unit nova:** somente `SysUtils`. Não `Rtti`, não `TypInfo`, não `Windows`,
  não `Objects.pas`, não nenhuma unit de `Source/`. Motivo: **nenhuma das 16 units de
  `Source/` compila em FPC 3.2.2 hoje** (medido; SKILL §"Two traps" trap 1).
- **Diretório espelhado por compilador:** `Test Delphi/…`, `Test FPC/…`, `Test Shared/…`.
  **Zero** `Test Lazarus/` — decisão da família #7/#9, é diretório por **compilador**.
- **Sem DUnitX no lado FPC** — DUnitX não é vendorizado (medido no ciclo #7). Foi o que
  matou o PR #11. FPCUnit é nativo do FPC 3.2.2 (`fpcunit.ppu`, `consoletestrunner.ppu`
  medidos).
- **Header em `(* ... *)`** — nunca `{ ... }` (RN-8).

## 6. Riscos

- **RSK-1 — Guarda `SizeOf` cobre parcialmente.** `SizeOf(TSignature) = SizeOf(TMethod)`
  é `16` no x86_64 e `8` no i386; não distingue "método-de-objeto" de "outro tipo de mesmo
  tamanho". Cobre o erro real (passar `Integer` ou `string`), não cobre o corner-case de
  passar outro `record` ou `array` do mesmo tamanho. Limite declarado no header da unit
  e coberto por `Case_Invoke_NonMethodSignature_Raises`.
- **RSK-2 — `MethodAddress` só enxerga `published`** (medido pelo dono na volta 1).
  Consumidor que espera achar método `public` sem `{$M+}` recebe exceção com mensagem
  que ensina o que fazer. Não é bug: é o mesmo custo estrutural da família #8.
  Coberto por `Case_Invoke_PublicMethodWithoutMPlus_RaisesNotFound`.
- **RSK-3 — Cabo de assinatura errada pelo consumidor.** Se o consumidor declarar
  `type TEchoFn = function(const s: string): Integer of object;` e o método real
  devolver `string`, a chamada compila e a corrupção acontece no runtime. **Fora da
  proteção da guarda `SizeOf`** — o tipo passa na guarda porque tem tamanho de método.
  Registrado como limite da API tipada; sem defesa portável possível no FPC 3.2.2
  (`GetMethods = 0`).
- **RSK-4 — R-FPC-Generic evitado por desenho** (RN-9). O corpo do genérico só toca
  `TMethod`. Não é *risco* — é a razão pela qual o desenho **funcionou** quando o dono
  compilou e rodou na volta 2. Registrado para futuros mantenedores não introduzirem
  tipo local na `implementation` que o genérico venha a instanciar.
- **RSK-5 — R-Comment-Nest evitado por desenho** (RN-8). Header em `(* ... *)`. Nenhuma
  diretiva `{$...}` dentro de `{ }` na unit.
- **RSK-6 — Divergência silenciosa por API dinâmica pedida na volta 2** (Delphi-only
  `GetType(T).GetMethod('X').Invoke(obj,[args])`). Fica **fora desta issue**, em issue
  irmã como superfície declaradamente **ausente por compilação no FPC** (`{$IFDEF DELPHI}`
  na declaração inteira). Divergência que quebra o build é honesta; divergência silenciosa
  em runtime seria o defeito nº 1 do PRD. Registrado na §Recomendações do
  [`REPORT-architect.md`](REPORT-architect.md).
