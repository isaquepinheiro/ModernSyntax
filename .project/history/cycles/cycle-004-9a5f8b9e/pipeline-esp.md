---
type: spec
kind: artifact
title: "ESP — Pilar 1 da ModernRTTI: leitura de RTTI (TModernRTTIType/Property/Field)"
description: "Especifica a unit nova Source/ModernSyntax.RTTI.pas com wrappers TModernRTTIType, TModernRTTIProperty, TModernRTTIField sobre TRttiContext, com a MESMA API no Delphi e no FPC 3.2.2, detecção obrigatória de {$M+} ausente no FPC e testes sem {$IFDEF} no consumidor."
status: draft
cycle: "004"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/9a5f8b9e974c23d88b7b6aba11e2973d
tags: [modernrtti, rtti, pilar-1, fpc, delphi, spec, issue-8]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-08-28T00:00:00Z"
sources:
  - id: prd
    resource: "../strategy/2026-08-27-modernrtti/PRD.md"
    title: "ModernRTTI PRD"
  - id: study
    resource: "../strategy/2026-08-27-modernrtti/STUDY.md"
    title: "ModernRTTI STUDY — medições de dia zero"
  - id: arch
    resource: "../analysis/03-architecture.md"
    title: "03 Architecture — ModernSyntax"
  - id: adr7
    resource: "../history/cycles/cycle-003-92fccbce/pipeline-adr.md"
    title: "ADR cycle-003 — convenções da família ModernRTTI (issue #7)"
---

# ESP — Pilar 1 da ModernRTTI: leitura de RTTI (issue #8)

## 1. Objetivo

Entregar o **Pilar 1** da camada ModernRTTI: uma unit nova
`Source/ModernSyntax.RTTI.pas` que expõe `TModernRTTI` (record com
`class function GetType`) e três wrappers — `TModernRTTIType`,
`TModernRTTIProperty`, `TModernRTTIField` — sobre `TRttiContext`. A
mesma chamada no consumidor compila e funciona no Delphi XE+ e no FPC
3.2.2 estável, sem `{$IFDEF FPC}` em nenhum arquivo consumido (D2/R4 do
[PRD](/strategy/2026-08-27-modernrtti/PRD.md); CA-1/CA-5 do PRD).

**Medido no [STUDY](/strategy/2026-08-27-modernrtti/STUDY.md)** e
reafirmado na investigação da issue: hoje o repositório tem **zero**
chamadas a `GetProperties`, `GetFields`, `TRttiProperty` ou `TRttiField`
em `Source/*.pas`. O único ponto de RTTI vivo é `TModernObject.Factory`
(`Source/ModernSyntax.Objects.pas:208-241`), que só invoca construtor.
Esta entrega é 100% aditiva sobre o código de produção.

## 2. Escopo

### Entra

- Unit nova `Source/ModernSyntax.RTTI.pas` com:
  - `EModernRTTIError = class(Exception)` — exceção da unit (R4).
  - `TModernRTTIField = record` (`strict private FField: TRttiField`) —
    `Name`, `GetValue<T>`, `SetValue<T>` genéricos; overloads `TValue`
    marcados como escape hatch documentado.
  - `TModernRTTIProperty = record` (`strict private FProp: TRttiProperty`)
    — `Name`, `IsReadable`, `IsWritable`, mesmos métodos de valor.
  - `TModernRTTIType = record` (`strict private FType: TRttiType`) —
    `Name`, `GetProperties: TArray<TModernRTTIProperty>`,
    `GetFields: TArray<TModernRTTIField>`. Ambos executam a verificação
    R4 antes de retornar.
  - `TModernRTTI = record` com `class var FContext: TRttiContext`,
    `class function GetType(AClass: TClass): TModernRTTIType`, overload
    para `PTypeInfo`. Bloco `initialization`/`finalization` cria/libera
    `FContext`.
- Ramificação **contida na unit**: `{$IFDEF FPC}` **direto** no arquivo,
  **sem** `{$I ModernSyntax.inc}` (R3 do PRD).
- `uses` da `interface` reduzida a `Rtti, TypInfo, SysUtils`. Nada de
  `Windows`, `Classes`, `Variants`, `SyncObjs`. Nada de importar unit
  interna do projeto (C-3 do STUDY: `ModernSyntax.Objects` arrasta
  dependências Delphi-only).
- Testes na convenção fixada pelo cycle-003
  ([adr #7 D-A7/D-A8](/history/cycles/cycle-003-92fccbce/pipeline-adr.md)):
  - `Test Shared/EclbrSystem/UScenarios.RTTI.pas` — cenários **sem
    framework**, com classes de fixture com `{$M+}` + `published`
    declaradas no próprio arquivo.
  - `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` — casca fina DUnitX
    (até uma linha útil por método).
  - `Test Delphi/EclbrSystem/PTestRTTI.dpr` + `.dproj` + entrada no
    `TestMSGroup.groupproj` + `DCC.bat` (13 → 14 projetos).
  - `Test FPC/EclbrSystem/UTestMS.RTTI.pas` — casca fina FPCUnit; entra
    no `.lpi` **criado pela #7**, sem inventar `.lpi` próprio.

### Fora

- Extensão de `TModernObject.Factory` ou modificação de
  `Source/ModernSyntax.Objects.pas` (D5 do PRD; C-3 do STUDY).
- Pilar 2 (atributos: `ModernAttributes.Register`, `GetAttributes`) —
  vem na próxima issue da família.
- Pilar 3 (Invoker: `TModernInvoker`) — vem depois do pilar 2.
- Correção do bug `{$IFDEF FCP}` em `Source/ModernSyntax.inc:256`. A
  unit contorna não incluindo o `.inc` (R3 do PRD).
- Correção de `Windows` na `interface` de `Source/ModernSyntax.Std.pas`
  e `Source/ModernSyntax.DotEnv.pas` (F-02 do intake).
- Criação de infraestrutura FPC (`Test FPC/EclbrSystem/`, `Test Shared/`,
  `.lpi` FPCUnit). Isso é **entrega da issue #7** e esta issue **assume**
  já mergeada. Se atrasar: PR desta declara "compilado em Delphi; não
  compilado em FPC — bloqueado por #7" e CA-6/CA-7 ficam pendentes.
- Conversão dos testes DUnitX existentes para o formato de cascas finas.
  Vale só para o que este ciclo entrega.
- Enumeradores customizados. `for … in TArray<T>` já funciona nos dois
  compiladores.

## 3. Regras de negócio

- **RN-1.** A unit expõe apenas `EModernRTTIError`, `TModernRTTIField`,
  `TModernRTTIProperty`, `TModernRTTIType`, `TModernRTTI`. Nenhum tipo
  de implementação interna vaza para a `interface`.
- **RN-2.** Ausência de `{$M+}` no FPC — detectada e reportada por
  `EModernRTTIError` com mensagem **instrutiva**, nunca lista vazia
  silenciosa (R4 do PRD). A detecção é feita **dentro de**
  `TModernRTTIType.GetProperties`: se `FType.GetProperties` volta vazio,
  a classe é `TRttiInstanceType` e não é `TObject`, e `PropCount == 0`
  no `TypeData`, dispara. Mecanismo interno da unit — invisível ao
  consumidor.
- **RN-3.** A unit **não inclui** `{$I ModernSyntax.inc}`. Todo guard é
  `{$IFDEF FPC}` direto (R3 do PRD).
- **RN-4.** O consumidor nunca escreve `{$IFDEF FPC}` (D2 do PRD; CA-5).
  Vale para os arquivos de teste e para qualquer código-exemplo.
- **RN-5.** A API principal de valor é **genérica**: `GetValue<T>: T` e
  `SetValue<T>(const AValue: T)` em `TModernRTTIProperty` e
  `TModernRTTIField`. Os overloads `TValue` existem como **escape
  hatch** documentado em `/// <remarks>`, marcando que obrigam o
  consumidor a importar `Rtti` (unit marcada `experimental` no FPC
  3.2.2 — R1 do PRD).
- **RN-6.** Retorno de `GetProperties`/`GetFields` é `TArray<...>`.
  Ownership: os wrappers são **handles leves** que apontam para dados
  de `TRttiContext` mantido em `class var TModernRTTI.FContext`, criado
  em `initialization` e liberado em `finalization`. O consumidor **não
  libera** nada e não deve reter referências após shutdown do binário.
  Este contrato **vive em `/// <remarks>`** de `GetType`,
  `GetProperties` e `GetFields`.
- **RN-7.** Contexto RTTI é **próprio da unit** — `class var
  TModernRTTI.FContext`. Não reusa `TModernObject.FContext`
  (`Source/ModernSyntax.Objects.pas:41`); importar `ModernSyntax.Objects`
  arrasta `SyncObjs`, `Variants`, `Classes` e `TProc<T>` (`Objects.pas:340`
  — ilegal no FPC 3.2.2). C-3 do STUDY.
- **RN-8.** Identificadores seguem `/analysis/05-conventions.md`:
  parâmetros `AClass`, `ATypeInfo`, `AInstance`, `AValue`; campos
  `FContext`, `FType`, `FProp`, `FField`; locais `LProp`, `LFields`,
  `LTypeData`; exceção `E<Nome>`.
- **RN-9.** `strict private` para os campos dos records wrapper
  (`FType`, `FProp`, `FField`). `/analysis/05-conventions.md` §1.4.
- **RN-10.** Cabeçalho MIT SPDX no topo da unit
  (`/analysis/05-conventions.md` §1.5). XML doc `///` em todos os
  membros públicos (§4.3), com `<remarks>` para o contrato de
  ownership em `GetType`/`GetProperties`/`GetFields` e para o aviso
  de escape hatch nos overloads `TValue`.

## 4. Critérios de aceitação

Vinculam CA-1/CA-5/CA-6/CA-7 e R2/R3/R4 do
[PRD](/strategy/2026-08-27-modernrtti/PRD.md) ao entregável concreto.

- **CA-1.** `ModernRTTI.GetType(T).GetProperties` devolve as
  propriedades de `T` **com a mesma chamada** no Delphi e no FPC
  3.2.2 (CA-1 do PRD). Coberto por
  `Scenario_GetProperties_ReturnsPublishedProps` em
  `UScenarios.RTTI.pas`.
- **CA-2.** `TModernRTTIType.GetFields` devolve os campos com a mesma
  chamada nos dois compiladores. Coberto por
  `Scenario_GetFields_ReturnsFields`.
- **CA-3.** `GetValue<T>`/`SetValue<T>` genéricos funcionam para
  `Integer`, `string` e um record simples nos dois compiladores. Cobre
  o representativo, não é exaustivo (limitação real de `TValue.AsType<T>`
  no FPC 3.2.2 pode reduzir o conjunto; ver RSK-2). Coberto pelos
  cenários de propriedade e campo.
- **CA-4.** Ausência de `{$M+}` no FPC dispara `EModernRTTIError` com
  mensagem instrutiva que **diz o que fazer** (R4 do PRD). Coberto por
  `Scenario_MissingM_RaisesEModernRTTIError`. O texto exato da mensagem
  fica **pendente de ratificação do dono** (ver perguntas em aberto do
  [adr](pipeline-adr.md)); rascunho no plano.
- **CA-5.** `grep -rn '{\$IFDEF FPC}' 'Test Shared/EclbrSystem/UScenarios.RTTI.pas'
  'Test Delphi/EclbrSystem/UTestMS.RTTI.pas' 'Test FPC/EclbrSystem/UTestMS.RTTI.pas'`
  retorna **zero linhas** (CA-5 do PRD).
- **CA-6.** `Source/ModernSyntax.RTTI.pas` **não contém**
  `{$I ModernSyntax.inc}` **nem** o token `FCP` (R3 do PRD; verificável
  por grep).
- **CA-7.** Os testes compilam e passam nos dois compiladores: FPC
  3.2.2 x86_64 e i386 (pelo orquestrador na máquina do autor, via o
  `.lpi` que a #7 versiona) e Delphi (pelo autor). O ciclo **não**
  compila (R2 do PRD).
- **CA-8.** Body do PR declara literalmente: *"compilado em FPC 3.2.2
  x86_64 e i386; não compilado em Delphi — Delphi permanece com o
  autor"* (R2 do PRD).
- **CA-9.** `TestMSGroup.groupproj` passa de 13 para **14 entradas**
  (inclui `PTestRTTI.dproj`); `DCC.bat` passa de 13 para **14 projetos**.
- **CA-10.** `Test FPC/EclbrSystem/UTestMS.RTTI.pas` está registrado no
  `.lpi` criado pela #7 — este ciclo **edita** o `.lpi` da #7, **não
  cria** um novo. Se a #7 não mergear a tempo, CA-7/CA-10 ficam
  explicitamente pendentes no body do PR.

## 5. Restrições

- **Alvo FPC:** 3.2.2 estável, 32 e 64 bits.
- **Alvo Delphi:** XE+ (conforme intake).
- **Fábrica sem compilador Pascal.** Revisão por leitura; compilação é
  do orquestrador na máquina do autor (R2 do PRD).
- **`uses` da unit de produção:** `Rtti`, `TypInfo`, `SysUtils`. Adicionar
  outra unit da biblioteca reintroduz `.inc` ou dependência Delphi-only.
- **Convenção de diretórios de teste** por compilador
  ([adr #7 D-A8](/history/cycles/cycle-003-92fccbce/pipeline-adr.md)):
  `Test Delphi/…` e `Test FPC/…` separados; `Test Shared/…` para
  cenários.
- **Framework FPC = FPCUnit**, medido no cycle-003 (D-A7 do adr #7).
  DUnitX **não** está vendorizado.

## 6. Riscos

- **RSK-1 — Dependência da issue #7.** A infraestrutura FPC (`Test FPC/`,
  `Test Shared/`, `.lpi`) é entregue pela #7. Mitigação: se a #7 não
  mergear a tempo, PR desta declara o bloqueio explicitamente (CA-8/CA-10)
  e CA-7 fica pendente. Não invente `.lpi` (lição do commit rejeitado
  `06fccea` do ciclo anterior desta mesma issue #8).
- **RSK-2 — `TValue.AsType<T>` no FPC 3.2.2 para T não trivial.** O
  suporte a genéricos em `Rtti` é o motivo do `experimental` (R1 do
  PRD). Se `AsType<T>` falhar para algum `T` (ex.: record customizado),
  o overload `TValue` cru passa a ser o caminho recomendado para esses
  tipos — decisão do autor no primeiro build FPC (R2 do PRD). Não
  bloqueia o design; testa-se `Integer`, `string` e um record simples.
- **RSK-3 — Mecanismo exato de "detectar `{$M+}` ausente" no FPC.**
  A investigação registra a heurística: `Length(GetProperties) = 0` +
  `FType is TRttiInstanceType` + não é `TObject` + `PropCount == 0` no
  `TypeData`. O implementador **confirma no primeiro build FPC**; se
  precisar variação, ela vive dentro da unit (invisível ao consumidor —
  CA-5 preservado). Mitigação: teste `Scenario_MissingM_RaisesEModernRTTIError`
  cobre o caso positivo.
- **RSK-4 — `Rtti` marcada `experimental` no FPC.** Warning em cada
  build da unit de produção. Não afeta o consumidor a menos que ele use
  o overload `TValue` (documentado como escape hatch). R1 do PRD.
- **RSK-5 — Bug R3 do PRD.** `Source/ModernSyntax.inc:256` tem
  `{$IFDEF FCP}` (typo). Mitigação **direta** pela RN-3: a unit não
  inclui o `.inc`. Verificável por grep (CA-6).
- **RSK-6 — Efeito colateral em `TestMSGroup.groupproj` / `DCC.bat`.**
  Adicionar `PTestRTTI` faz o grupo passar a compilar/rodar esse
  projeto. Se o `.dpr` estiver quebrado, o grupo quebra junto.
  Mitigação: só adicionar a entrada depois que `PTestRTTI.dpr` compila
  localmente em Delphi (autor).
- **RSK-7 — Contrato de ownership** (novo para a família). Reter
  `TModernRTTIProperty`/`TModernRTTIField` após shutdown do binário é
  undefined. Mitigação: contrato documentado em `<remarks>` (RN-6);
  zero consumidores hoje, então não quebra nada existente.
- **RSK-8 — Prefixo de interface (`IMS`/`IModern`/bare `I*`)** —
  decisão pendente do dono. **Não bloqueia esta issue** (Pilar 1 só
  introduz records), mas trava a próxima issue da família que
  introduzir interface. Medições: 7 bare `I*` / 1 `IModern*` / 1 `IMS*`
  (morto). Recomendação: alinhar com a #7 (`IModern*`) se e somente se
  o dono ratificar como padrão prospectivo.
