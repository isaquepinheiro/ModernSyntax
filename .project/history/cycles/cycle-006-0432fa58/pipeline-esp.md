---
type: spec
kind: artifact
title: "ESP — Pilar 1 ModernRTTI: leitura portável de RTTI (TModernRTTI, TModernRTTIType, TModernRTTIProperty; TModernRTTIField Delphi-only)"
description: "Unit greenfield ModernSyntax.RTTI expondo TModernRTTI.GetType nos dois compiladores; GetProperties portável; GetFields e TModernRTTIField Delphi-only (TRttiField ausente no FPC 3.2.2); GetValue<T>/SetValue<T>; EModernRTTIError instrutiva para {$M+} ausente; FPC project standalone (.lpr+.lpi) seguindo o padrão da issue #7."
status: draft
cycle: "006"
agent: architect
workflow: equipe-feature
node: plan-gate:on_reject
resource: aefos://run/0432fa58eb504d5fa522f3e710649a41
tags: [modernrtti, rtti, fpc, delphi, spec, issue-8, pilar-1]
generated:
  by: "equipe-feature@node:plan-gate:on_reject"
  at: "2026-08-28T16:00:00Z"
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
  - id: conv
    resource: "../analysis/05-conventions.md"
    title: "05 Conventions — ModernSyntax"
---

# ESP — Pilar 1: leitura portável de RTTI (issue #8)

## 1. Objetivo

Entregar o **Pilar 1 do ModernRTTI** conforme
[PRD](../../../strategy/2026-08-27-modernrtti/PRD.md): `TModernRTTI.GetType(T).GetProperties`
funciona nos dois compiladores com a **mesma chamada no código do consumidor**
(CA-1 do PRD), sem `{$IFDEF FPC}` no consumidor (D2/CA-5) e **sem lista vazia
silenciosa** quando o FPC precisa de `{$M+}`/`published` (R4).

`TModernRTTI.GetType(T).GetFields` é **Delphi-only**: `TRttiField` e
`TRttiType.GetFields` não existem no FPC 3.2.2 (medido — erro de compilador:
`"Identifier not found TRttiField"`). `TModernRTTIField` e `GetFields` são
ausentes por compilação no FPC via `{$IFNDEF FPC}`, não por runtime — o
consumidor FPC que tentar usá-los recebe erro de compilação, não comportamento
silencioso.

A ausência de `{$M+}` em FPC vira `EModernRTTIError` com mensagem que **diz o
que fazer** — o consumidor Delphi vê propriedades e o consumidor FPC vê exceção
instrutiva no lugar do vazio silencioso que a família ModernRTTI existe para
prevenir.

## 2. Escopo

**Entra:**

- Nova unit `Source/ModernSyntax.RTTI.pas` (autocontida, sem importar unit de
  `Source/`).
- Testes em três diretórios (`Test Shared/EclbrSystem/` e `Test FPC/EclbrSystem/`
  são criados por esta issue seguindo o padrão do commit `7114cdc` da issue #7):
  - `Test Shared/EclbrSystem/UScenarios.RTTI.pas` — cenários **sem framework**,
    procedures livres que levantam `Exception` na falha; fixtures com `{$M+}`
    e `published` declaradas dentro do próprio arquivo. **Zero** `{$IFDEF FPC}`.
    Contém apenas cenários portáveis (propriedades, valores, detecção R4).
    `Scenario_GetFields_ReturnsFields` é **Delphi-only** e vive diretamente em
    `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` (não no arquivo compartilhado).
  - `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` — casca fina DUnitX (`[Test]`
    chama uma linha útil por cenário; `TestGetFields` chama `GetFields`
    diretamente, pois não há cenário compartilhado para recurso Delphi-only).
  - `Test Delphi/EclbrSystem/PTestRTTI.dpr` (+ `.dproj`) — runner Delphi.
  - `Test FPC/EclbrSystem/UTestMS.RTTI.pas` — casca fina FPCUnit. **Sem**
    `TestGetFields` (tipo inexistente no FPC). **Zero** `{$IFDEF FPC}`.
  - `Test FPC/EclbrSystem/PTestRTTI.lpr` — runner FPCUnit, **NOVO** (padrão
    `PTestModernCallback.lpr` do commit `7114cdc`). Usa `{$MODE OBJFPC}{$H+}`
    no arquivo do programa; modo Delphi vem do `.lpi` e do `-Mdelphi` da CLI.
  - `Test FPC/EclbrSystem/PTestRTTI.lpi` — projeto Lazarus, **NOVO** (padrão
    `PTestModernCallback.lpi` do commit `7114cdc`). `<SyntaxMode Value="Delphi"/>`
    em ambos os build modes (`Debug-i386`, `Debug-x86_64`).
  - Entrada em `TestMSGroup.groupproj` (13 → 14).
  - Entrada em `DCC.bat` (13 → 14).

**Fora do escopo:**

- **Estender `TModernObject.Factory`** (`Source/ModernSyntax.Objects.pas:208-241`)
  — D5 do PRD.
- **Fachada `GetAttributes`** — é do Pilar 2 (issue #9, ciclo 004 e-936cbe6, já
  entregue como `ModernAttributes.GetAttributes`); a versão sob
  `ModernRTTI.GetType(T).GetAttributes` fica para issue irmã e não bloqueia
  esta.
- **Extensão do Pilar 3** (issue #10, ciclo 005) — invocação não muda.
- **Correção do `{$IFDEF FCP}`** em `Source/ModernSyntax.inc:261` — R3 do PRD:
  a nova unit contorna sem tocar no `.inc` (linha `:261` em `main`; as linhas
  251-260 trazem comentário do autor explicando que `FCP` é typo deliberado,
  encerrando com *"Fix it together with a real FPC target and a build that
  proves it"*).
- **`{$IFDEF FPC}` no código do consumidor** (CA-5 do PRD).

## 3. Regras de negócio

- **RN-1 — tipos da `interface`.** A unit expõe **exatamente**
  `EModernRTTIError`, `TModernRTTIProperty`, `TModernRTTIType` e `TModernRTTI`
  nos dois compiladores. No Delphi, adicionalmente `TModernRTTIField` via bloco
  `{$IFNDEF FPC}…{$ENDIF}` — ausente por compilação no FPC (não por runtime).
  Nenhum tipo auxiliar vaza.

- **RN-2 — assinaturas públicas.** `TModernRTTIField` e o membro `GetFields` de
  `TModernRTTIType` ficam dentro de `{$IFNDEF FPC}…{$ENDIF}` porque `TRttiField`
  não existe no FPC 3.2.2. `strict private` exige modo Delphi (ver RN-4a).
  ```pascal
  {$IFNDEF FPC}
  TModernRTTIField = record
  strict private
    FField: TRttiField;
  public
    function Name: string;
    function GetValue<T>(const AInstance: TObject): T; overload;
    procedure SetValue<T>(const AInstance: TObject; const AValue: T); overload;
    /// <remarks>Escape hatch: obriga o consumidor a importar Rtti.
    /// Prefira o overload genérico.</remarks>
    function GetValue(const AInstance: TObject): TValue; overload;
    procedure SetValue(const AInstance: TObject; const AValue: TValue); overload;
  end;
  {$ENDIF}

  TModernRTTIProperty = record
  strict private
    FProp: TRttiProperty;
  public
    function Name: string;
    function IsReadable: Boolean;
    function IsWritable: Boolean;
    function GetValue<T>(const AInstance: TObject): T; overload;
    procedure SetValue<T>(const AInstance: TObject; const AValue: T); overload;
    /// <remarks>Escape hatch: obriga o consumidor a importar Rtti.
    /// Prefira o overload genérico.</remarks>
    function GetValue(const AInstance: TObject): TValue; overload;
    procedure SetValue(const AInstance: TObject; const AValue: TValue); overload;
  end;

  TModernRTTIType = record
  strict private
    FType: TRttiType;
  public
    function Name: string;
    function GetProperties: TArray<TModernRTTIProperty>;
    {$IFNDEF FPC}
    function GetFields: TArray<TModernRTTIField>;
    {$ENDIF}
  end;

  TModernRTTI = record
  strict private
    class var FContext: TRttiContext;
  public
    class function GetType(AClass: TClass): TModernRTTIType; overload; static;
    class function GetType(ATypeInfo: PTypeInfo): TModernRTTIType; overload; static;
  end;
  ```

- **RN-3 — `uses` da `interface`.** Apenas `SysUtils`, `TypInfo`, `Rtti`.
  **Não** usa `Windows`, `Classes`, `Variants`, `SyncObjs`. **Não** importa
  nenhuma unit de `Source/` (nenhuma das 16 units compila em FPC 3.2.2 hoje —
  medido pelo dono, ver [SKILL](../../../SKILL.md); estudo §C-4).

- **RN-4 — nada de `{$I ModernSyntax.inc}`.** Toda ramificação é `{$IFDEF FPC}`
  / `{$IFNDEF FPC}` direto (R3 do PRD; contorna sem consertar o token `FCP` de
  `ModernSyntax.inc:261` em `main`).

- **RN-4a — modo FPC.** A unit de produção **não declara `{$mode objfpc}`**.
  Modo vem de `-Mdelphi` na CLI (SKILL.md) e de `<SyntaxMode Value="Delphi"/>` no
  `.lpi`. Se precisar de diretiva de modo explícita **dentro da unit**, usar
  `{$mode delphi}{$H+}` — **nunca `{$mode objfpc}`**: ele desliga `strict private`
  em records no FPC 3.2.2 e sobrescreve o `-Mdelphi` da linha de comando (defeito
  medido no PR #17).

- **RN-5 — contexto RTTI próprio.** `TModernRTTI.FContext: TRttiContext` é
  criado em `initialization` e liberado em `finalization` da unit. **Não
  reutiliza** `TModernObject.FContext` (`Source/ModernSyntax.Objects.pas:41`):
  importar `Objects.pas` arrasta `SyncObjs`/`Variants`/`Classes`/`TProc<T>`
  (STUDY §C-3). Padrão idêntico ao de `Source/ModernSyntax.Objects.pas:195,601`.

- **RN-6 — detecção obrigatória de `{$M+}` ausente (R4).** Dentro de
  `TModernRTTIType.GetProperties`:
  1. Ler `LProps := FType.GetProperties`.
  2. Se `Length(LProps) = 0` **e** `FType is TRttiInstanceType` **e** o
     `FType.Handle` não é o de `TObject`, verificar via `TypInfo`
     (`PTypeData(GetTypeData(FType.Handle))^.PropCount` ou equivalente
     portável) se a classe **deveria** ter propriedades expostas.
  3. Se a verificação indicar exposição inexistente, **levantar
     `EModernRTTIError`** com a mensagem instrutiva **única** (RN-7).
  4. Caso contrário, empacotar `LProps` em `TArray<TModernRTTIProperty>` e
     devolver.

  O implementador **confirma o mecanismo exato** de verificação
  (`PropCount == 0` como sinal) no primeiro build FPC (PRD R2). Se o
  mecanismo escolhido exigir ramificação por compilador, ela fica **dentro
  da unit** (invisível ao consumidor — CA-5).

  `GetFields` é Delphi-only (`{$IFNDEF FPC}`) e não precisa desta lógica no FPC
  — `TRttiField` simplesmente não existe no FPC 3.2.2.

- **RN-7 — mensagem da exceção, unificada.** Texto único (não ramifica por
  compilador):
  > *"A classe %s não expõe propriedades à RTTI. No Delphi isso indica
  > ausência real de propriedades `public`/`published`; no FPC exige
  > `{$M+}` antes da declaração da classe e uma seção `published` com as
  > propriedades desejadas. Adicione ambos e recompile."*

  Rationale: uma única string mantém a coerência com o próprio princípio
  ("verificação uniforme dentro da unit"); ramificar por compilador
  pouparia poucas palavras em Delphi ao custo de duas versões da mesma
  frase. Se o dono ratificar dois textos, a mudança fica em RN-7 e o
  `raise` ganha um `{$IFDEF FPC}` interno — mudança contida, invisível ao
  consumidor.

- **RN-8 — API pública NÃO expõe `TValue` como caminho principal.**
  `GetValue<T>: T` e `SetValue<T>(const AValue: T)` são o caminho recomendado.
  Motivo: (a) obrigar `uses Rtti` no consumidor vaza implementação; (b)
  `Rtti` no FPC 3.2.2 é `experimental` (aviso a cada build — PRD R1). O
  overload `TValue` existe como escape hatch marcado em `<remarks>`.

- **RN-9 — contrato de ownership dos handles.** Registrado como `<remarks>` em
  `TModernRTTI.GetType`, `TModernRTTIType.GetProperties` e
  `TModernRTTIType.GetFields`, texto integral:
  > *"Ownership: `TModernRTTIType`, `TModernRTTIProperty` (e `TModernRTTIField`
  > no Delphi) são handles leves que apontam para dados de `TRttiContext`
  > mantido em `class var TModernRTTI.FContext`. O contexto é criado em
  > `initialization` e liberado em `finalization` de `ModernSyntax.RTTI`. O
  > consumidor NÃO deve reter essas referências após shutdown do binário
  > (comportamento de fim de processo é undefined). Dentro da vida da aplicação,
  > o array retornado por `GetProperties` (e `GetFields` no Delphi) é seguro para
  > uso, iteração e armazenamento — nenhum `Free` do consumidor é necessário nem
  > permitido."*

- **RN-10 — casca de teste.** Cada `[Test]` (Delphi) / `published`/`procedure Test…`
  (FPC) chama **exatamente uma linha útil** — a `Scenario_...` da unit
  compartilhada. Se aparecer `if/then` de asserção na casca, é vazamento
  (padrão herdado da #7/#9/#10).

- **RN-11 — cabeçalho SPDX-MIT em `(* ... *)`.** RN medida como defeito
  histórico: `{ … {$…} … }` fecha o comentário no primeiro `}`. Convenção
  RN-8 do ESP #10 e RN-7 do ESP #9. Idem `(* … *)`.

- **RN-12 — prefixos de identificadores.** `AClass`, `ATypeInfo`, `AInstance`,
  `AValue` (parâmetros); `FContext`, `FType`, `FProp`, `FField` (campos);
  `LProps`, `LFields`, `LTypeData` (locais). Convenção
  [05-conventions §1.3](../../../analysis/05-conventions.md).

- **RN-13 — `strict private` para campos de implementação** dos records
  wrapper — convenção [05-conventions §1.4](../../../analysis/05-conventions.md).

- **RN-14 — XML doc `///`** em todos os membros públicos
  (`<summary>`, `<param>`, `<returns>`, `<remarks>`) — convenção
  [05-conventions §4.3](../../../analysis/05-conventions.md). Contrato de
  ownership (RN-9) e alerta de escape hatch (RN-8) vivem em `<remarks>`.

## 4. Critérios de aceitação

Vinculam CA-1/CA-5/CA-7/D2/R2/R3/R4 do
[PRD](../../../strategy/2026-08-27-modernrtti/PRD.md) ao entregável concreto.

- **CA-1.** `TModernRTTI.GetType(T).GetProperties` devolve as propriedades de
  `T` no Delphi e no FPC com a **mesma chamada** no consumidor (CA-1 do PRD).
  Coberto por `Scenario_GetProperties_ReturnsPublishedProps`.

- **CA-2 (Delphi-only).** No Delphi, `TModernRTTI.GetType(T).GetFields` devolve
  os campos de `T`. No FPC, `TModernRTTIField` e `GetFields` não existem —
  ausentes por compilação (`{$IFNDEF FPC}`), não por runtime. Verificação: `grep
  -n 'TModernRTTIField\|GetFields'
  Source/ModernSyntax.RTTI.pas` mostra os dois dentro de `{$IFNDEF FPC}`. Cenário
  `Scenario_GetFields_ReturnsFields` vive diretamente em
  `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` (não no arquivo compartilhado, que
  compila em ambos os compiladores).

- **CA-3.** `GetValue<T>` e `SetValue<T>` funcionam para pelo menos `Integer`,
  `string` e um `record` simples de fixture — cobertura representativa dos
  tipos que aparecem nas fixtures, não exaustiva. Coberto por
  `Scenario_GetValue_Integer_Roundtrip`, `Scenario_GetValue_String_Roundtrip`,
  `Scenario_GetValue_Record_Roundtrip`.

- **CA-4 — R4.** Ausência de `{$M+}` no FPC (e classe sem propriedades
  expostas no Delphi) levanta `EModernRTTIError` com a mensagem RN-7.
  **Nunca lista vazia silenciosa**. Coberto por
  `Scenario_MissingM_RaisesEModernRTTIError`.

- **CA-5 — CA-5 do PRD.**
  `grep -rn '{\$IFDEF FPC}' 'Test Shared/EclbrSystem/UScenarios.RTTI.pas'
  'Test Delphi/EclbrSystem/UTestMS.RTTI.pas'
  'Test FPC/EclbrSystem/UTestMS.RTTI.pas'` → **zero linhas**.

- **CA-6.** `Source/ModernSyntax.RTTI.pas` **não contém** `{$I ModernSyntax.inc}`
  nem o token `FCP` — verificável por grep (RN-4, R3 do PRD).

- **CA-7.** `Source/ModernSyntax.RTTI.pas` **não `uses`** nenhuma unit de
  `Source/` (RN-3, STUDY §C-4). Verificável por grep restrito à cláusula
  `uses` da `interface` e da `implementation`.

- **CA-8.** A entrega cria `Test FPC/EclbrSystem/PTestRTTI.lpr` e
  `PTestRTTI.lpi` (padrão do commit `7114cdc`). O FPC 3.2.2 constrói o alvo
  pelo orquestrador na máquina do autor, em `i386` **e** `x86_64`, usando o
  comando da SKILL.md:
  ```
  rm -rf <out> && fpc -Mdelphi -Fu"Source" -Fu"Test Shared/EclbrSystem" \
      -FU<out> -FE<out> "Test FPC/EclbrSystem/PTestRTTI.lpr"
  ```
  (CA-6/CA-7 do PRD). Esta issue **não depende** do `.lpi` da #7 mergear.

- **CA-9.** A entrega adiciona `PTestRTTI` ao `TestMSGroup.groupproj`
  (13 → 14) e ao `DCC.bat` (13 → 14).

- **CA-10.** O corpo do PR declara literalmente: *"compilado em FPC 3.2.2
  x86_64 e i386 — `rm -rf <out> && fpc -Mdelphi …` verde nos dois; não
  compilado em Delphi — Delphi permanece com o autor"* (R2 do PRD).

- **CA-11.** Esta issue cria seu próprio `PTestRTTI.lpr` e `PTestRTTI.lpi` e
  **não depende** do `.lpi` da #7. CA-8 não fica pendente por causa da #7.
  Compile e prove antes de abrir o PR (SKILL.md: limpar output antes;
  não compilar `Source/` inteiro).

## 5. Restrições

- **Alvo FPC:** 3.2.2 estável, 32 e 64 bits (`i386` e `x86_64`).
- **Alvo Delphi:** XE+ (histórico da biblioteca); compilação pelo autor
  (R2 do PRD).
- **Fábrica sem compilador Pascal** — compilar antes de entregar (SKILL.md).
- **`uses` da unit nova:** `SysUtils`, `TypInfo`, `Rtti` — nada mais. Zero
  units de `Source/`, zero `Windows`, zero `SyncObjs`, zero `Classes`.
- **Diretório espelhado por compilador:** `Test Delphi/…`, `Test FPC/…`,
  `Test Shared/…`. **Zero** `Test Lazarus/` (decisão da família #7/#9/#10).
- **Sem DUnitX no lado FPC** — FPCUnit é nativo do FPC 3.2.2 (medido no
  ciclo #7). Não replicar `06fccea`.
- **Cabeçalho SPDX-MIT em `(* … *)`** (RN-11).
- **FPC project standalone:** `PTestRTTI.lpr` + `PTestRTTI.lpi` criados por
  esta issue (padrão commit `7114cdc`). **Sem dependência de merge da #7.**
- **`{$mode delphi}` — nunca `{$mode objfpc}` — na unit de produção** (RN-4a).
  O `.lpr` do runner FPC pode usar `{$MODE OBJFPC}` (é só o programa, sem
  records `strict private`); o `.lpi` usa `<SyntaxMode Value="Delphi"/>`.

## 6. Riscos

- **RSK-1 — Portabilidade do sinal `PropCount == 0` no FPC 3.2.2.** O
  mecanismo exato de detecção precisa de confirmação no primeiro build
  FPC (R2 do PRD). Se exigir ramificação, fica **dentro** da unit
  (invisível ao consumidor — CA-5). Registrado no plano como
  primeiro-uso-no-FPC.
- **RSK-2 — `TValue.AsType<T>` no FPC 3.2.2 para `T` não trivial.** O
  suporte a genéricos da `Rtti` do FPC é a razão do `experimental` (R1 do
  PRD). Se `AsType<T>` falhar para algum `T` (ex.: record customizado
  aninhado), o overload `TValue` cru vira o caminho **recomendado** para
  esses tipos — decisão do autor no primeiro build FPC. **Não bloqueia** o
  design: o escape hatch já existe (RN-8) exatamente para este cenário.
  Se a decisão pender, o teste `Scenario_GetValue_Record_Roundtrip` pode
  ser reforçado com fixture mais simples sem violar CA-3.
- **RSK-3 — Aviso `experimental` no build da unit de produção.** A `Rtti`
  no FPC 3.2.2 emite `Warning: Unit "Rtti" is experimental` a cada
  compilação — é o aviso normal desta biblioteca, não regressão.
  Documentar no `<remarks>` do overload `TValue` (para o consumidor que
  optar pelo escape hatch, o aviso também bate no build dele).
- **RSK-4 — Build incremental mentiroso no FPC.** FPC reutiliza `.ppu` do run
  anterior e pode reportar verde sobre código velho (medido no ciclo #7 — SKILL.md
  trap 2). Mitigação obrigatória: `rm -rf <out>` antes de cada build de prova.
  Zero risco de resultado falso se a limpeza for feita.
- **RSK-5 — Dependência transitiva por engano.** Um `uses` a mais em
  `Source/ModernSyntax.RTTI.pas` pode arrastar unit contaminada
  (`Windows` na `interface` de `Std.pas:21`/`DotEnv.pas:22`, STUDY).
  Mitigação: CA-7 grep restrito à cláusula `uses`.
- **RSK-6 — Prefixo de interface pendente.** Pilar 1 **não** introduz
  interface pública (só records e uma exceção), portanto **não afeta esta
  entrega**. Registrado que a próxima issue da família que introduzir
  interface trava até o dono ratificar `IModern*` vs bare `I*` vs `IMS*`
  (medições: 7 bare / 1 `IModern*` / 1 `IMS*` morto — investigação).
