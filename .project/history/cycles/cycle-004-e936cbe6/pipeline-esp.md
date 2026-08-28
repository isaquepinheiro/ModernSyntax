---
type: spec
kind: artifact
title: "ESP — Pilar 2 ModernRTTI: atributos portáveis (unit ModernSyntax.Attributes)"
description: "Especifica ModernAttributes.Register e GetAttributes, com TModernAttribute como base obrigatória para atributos portáveis, política de ordem de inicialização declarada e fusão nativo+registrado com dedup por classe do lado registrado."
status: draft
cycle: "004"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/e936cbe6a17a8e76ec8ca9a02ec30735
tags: [modernrtti, attributes, fpc, delphi, spec, issue-9]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-08-28T13:30:00Z"
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
---

# ESP — Pilar 2: Atributos portáveis (issue #9)

## 1. Objetivo

Entregar o **Pilar 2 do ModernRTTI**: `ModernAttributes.Register(TFoo, [MyAttr.Create])` disponível
nos dois compiladores, e `ModernAttributes.GetAttributes(TFoo)` que unifica atributos declarados
via sintaxe nativa `[MyAttr]` (Delphi) e via `Register` (ambos), com **resultado observável idêntico
nos dois compiladores para o mesmo conjunto de metadados que atravessa a fronteira portável**
(CA-2 do [PRD](../../../strategy/2026-08-27-modernrtti/PRD.md)).

Contexto medido no [STUDY](../../../strategy/2026-08-27-modernrtti/STUDY.md) e reafirmado na investigação:
`TCustomAttribute` não existe no FPC 3.2.2 (0 ocorrências em `packages/rtl-objpas/src/inc/rtti.pp`)
e a sintaxe nativa `[MyAttr]` não compila. Portanto, escrever atributo portável exige que a
biblioteca **forneça a classe base** — sem isso, o consumidor cai em `{$IFDEF FPC}` na própria
declaração da classe de atributo, o que viola CA-5/D2 do PRD diretamente.

## 2. Escopo

Entra nesta entrega:

- Nova unit `Source/ModernSyntax.Attributes.pas` contendo:
  - `TModernAttribute` — classe base **real e obrigatória** para atributos portáveis (herda
    de `TObject` no FPC, de `TCustomAttribute` no Delphi).
  - `TAttributeRecord = record Owned: TArray<TObject>; end;` — na `interface` por causa
    da R-FPC-Generic (métodos genéricos declarados na `interface` que instanciam este tipo
    exigem que o tipo também esteja na `interface`).
  - `ModernAttributes` — record com `class function Register`/`class function GetAttributes`,
    estáticos.
  - Registry interna `TDictionary<TClass, TAttributeRecord>` com lock, e `TRttiContext` **próprio
    da unit** (nunca reutiliza o de `ModernSyntax.Objects`).
- Ramificação `{$IFDEF FPC}` **contida na unit** (D2/R3 do PRD; sem `{$I ModernSyntax.inc}`).
- Testes portáveis em três diretórios:
  - `Test Shared/EclbrSystem/UTestMS.Attributes.Scenarios.pas` — cenários **sem framework**.
  - `Test Shared/EclbrSystem/UTestMS.Attributes.Symbols.inc` — define **exatamente um de dois**
    símbolos de capacidade (`HAS_NATIVE_ATTRS` XOR `NO_NATIVE_ATTRS`).
  - `Test Delphi/EclbrSystem/UTestMS.Attributes.pas` + `PTestAttributes.dpr` — casca fina DUnitX.
  - `Test FPC/EclbrSystem/UTestMS.Attributes.pas` + `PTestAttributes.lpr` + `.lpi` — casca fina
    FPCUnit (nativa do FPC 3.2.2, medido no ciclo #7).

Fora do escopo:

- **Fachada `ModernRTTI.GetType(T).GetAttributes`** — entregável do Pilar 1 (issue #8), que
  delegará para `ModernAttributes.GetAttributes(T)`. A satisfação de CA-2 **na letra** (com
  o nome `ModernRTTI`) fica para a #8. Esta issue satisfaz CA-2 **no espírito**, com a API
  `ModernAttributes.GetAttributes`. Não é CA-2 redefinido — é ordem de entrega.
- **Obrigar `Register` no Delphi** quando `[MyAttr]` nativo está disponível (recusado por D1
  do PRD — degrada o lado bom para igualar o lado ruim).
- **Conversão de qualquer atributo existente**: `grep -rn "TCustomAttribute|GetAttribute" Source/*.pas`
  → 0. Nenhum consumidor da biblioteca lê atributos hoje.
- **Correção do bug `{$IFDEF FCP}`** em `ModernSyntax.inc:256` (R3 do PRD — contornada por
  RN-4 abaixo).
- **`DCC.bat` incluindo `PTestAttributes`** — gap conhecido pós-entrega, não bloqueante.

## 3. Regras de negócio

- **RN-1.** A unit expõe **apenas** `TModernAttribute`, `TAttributeRecord`, `ModernAttributes` e
  o tipo `TObjectArray = TArray<TObject>` (se preciso para satisfazer generic bounds do FPC).
  Nenhum tipo interno de wrapper ou tipo auxiliar de dicionário vaza para a `interface` — salvo
  o que R-FPC-Generic força (`TAttributeRecord`).
- **RN-2.** `TModernAttribute` é declarada assim:
  ```pascal
  {$IFDEF FPC}
    TModernAttribute = class(TObject);
  {$ELSE}
    TModernAttribute = class(TCustomAttribute);
  {$ENDIF}
  ```
  O consumidor escreve `TMyAttr = class(TModernAttribute)` **idêntico nos dois compiladores**.
  No Delphi, essa classe é aceita pela sintaxe nativa `[MyAttr]` por descender transitivamente
  de `TCustomAttribute` (comportamento documentado da linguagem; **verificação pendente do lado
  Delphi** — a fábrica não tem Delphi, o autor confirma no PR).
- **RN-3.** `Register(AClass, AAttrs)` **toma posse** de cada instância em `AAttrs`,
  concatena em `FRegistry[AClass].Owned` com dedup por **identidade de referência** — a mesma
  instância registrada duas vezes conta uma; duas instâncias distintas da mesma classe contam
  duas.
- **RN-4.** `GetAttributes(AClass)`:
  - No **FPC**: retorna cópia de `FRegistry[AClass].Owned`. Se `AClass` não está registrada,
    retorna array com `Length = 0` (nunca `nil`, nunca exceção).
  - No **Delphi**: monta o resultado em duas partes:
    1. `LOwned := FRegistry[AClass].Owned` (as instâncias registradas — **prevalecem**).
    2. `LNative := FContext.GetType(AClass).GetAttributes` (instâncias da RTTI do Delphi).
    3. Filtra `LNative`: uma instância nativa é **descartada** se `LOwned` contém qualquer
       instância cuja `ClassType` seja igual à `ClassType` da nativa. Isto é a **regra 2 do
       ADENDO da investigação** — a que faz CA-2 valer na letra sem reescrever o critério.
    4. Retorna `LOwned` concatenado com o `LNative` filtrado.
- **RN-5.** Ambos os arrays retornados por `GetAttributes` são **vista emprestada**. O chamador
  **não libera**. As instâncias são gerenciadas pela registry (para as registradas) ou pelo
  `TRttiContext` interno (para as vindas de `[MyAttr]` nativo). Este contrato está escrito
  em XMLDoc na assinatura pública, palavra por palavra.
- **RN-6.** A unit **não inclui** `ModernSyntax.inc` (R3 do PRD; bloco morto `FCP` em
  `ModernSyntax.inc:250-262` fica isolado). Todo guard é `{$IFDEF FPC}` direto.
- **RN-7.** A unit é escrita com header SPDX-MIT no formato `(* ... *)` externo. Nenhuma
  diretiva `{$...}` aparece dentro de comentário `{ }` (R-Comment-Nest — o `}` da diretiva
  fecha o comentário; defeito medido no PR #12 do ciclo #7).
- **RN-8.** `uses` da `interface` da unit: `SysUtils`, `Generics.Collections`, `Rtti`,
  `SyncObjs`. `Rtti` só entra sob `{$IFDEF DELPHI}` conceitual — mas escrito como
  `{$IFDEF FPC}`/`{$ELSE}`. O FPC não precisa de `Rtti` porque não lê nada nativo.
- **RN-9.** No `finalization`: libera **apenas** `Owned` de cada `TAttributeRecord`; depois
  `FRegistry.Free`, `FLock.Free`, `FContext.Free`. O `FContext.Free` derruba as instâncias
  vindas da RTTI — correto, o contexto é da unit.
- **RN-10.** **Política de ordem de inicialização (Q2 do PRD)** declarada: se uma unit lê
  atributos no seu `initialization` antes da unit que os registra ter carregado, `GetAttributes`
  devolve o que **está registrado nesse instante** — array vazio se ninguém registrou ainda,
  ou lista parcial se registro anterior existir. Este é comportamento **definido**, não
  silenciosamente errado. Coberto por teste (CA-3 abaixo).

## 4. Critérios de aceitação

Vinculam CA-2/CA-5/CA-7/D1/D2/R2/R3/Q2 do
[PRD](../../../strategy/2026-08-27-modernrtti/PRD.md) ao entregável concreto:

- **CA-1.** `ModernAttributes.GetAttributes(TFoo)` devolve **resultado observável idêntico**
  nos dois compiladores para uma classe cujos atributos entraram pela fronteira portável (via
  `Register`), independente de existir também anotação nativa `[MyAttr]` no lado Delphi
  (CA-2 do PRD, no espírito; CA-2 na letra é entregue pela #8 que delegará).
- **CA-2.** No Delphi, uma classe com **ambas** as formas — `[MyAttr]` nativo e `Register(...,
  [TMyAttr.Create])` — devolve **uma única entrada** por classe de atributo (o registrado
  prevalece). Coberto por `Scenario_NativeSuppressedByRegistered` (regra 2 do ADENDO).
- **CA-3.** Política Q2 coberta: `Scenario_GetAttributes_NeverRegistered_ReturnsEmpty` afirma
  `Length = 0` (nunca `nil`, nunca exceção) para uma classe sem `Register` prévio.
- **CA-4.** `grep -rn '{\$IFDEF FPC}' 'Test Shared/EclbrSystem/UTestMS.Attributes.Scenarios.pas'
  'Test Delphi/EclbrSystem/UTestMS.Attributes.pas' 'Test FPC/EclbrSystem/UTestMS.Attributes.pas'`
  → **zero linhas** (CA-5 do PRD; a única ramificação de compilador do lado de teste vive
  dentro do `.inc` compartilhado).
- **CA-5.** A entrega inclui `Test FPC/EclbrSystem/PTestAttributes.lpi` (+ `.lpr`) que o
  FPC 3.2.2 constrói (CA-6/CA-7 do PRD). O `.lpi` traz dois build modes: `Debug-i386` e
  `Debug-x86_64`.
- **CA-6.** Registry libera apenas o que possui: `ReportMemoryLeaksOnShutdown := True` no
  `.dpr` do Delphi não reporta vazamento nem AV no shutdown mesmo com múltiplos `Register`
  e `[MyAttr]` nativo simultâneos (RSK-5 abaixo).
- **CA-7.** Testes compilam e passam nos dois compiladores: FPC 3.2.2 x86_64 e i386 (pelo
  orquestrador na máquina do autor) e Delphi (pelo autor). O ciclo **não** compila (R2 do PRD).
- **CA-8.** O corpo do PR declara literalmente: *"compilado em FPC 3.2.2 x86_64 e i386; não
  compilado em Delphi — Delphi permanece com o autor"*, mais a linha de fronteira: *"atributo
  portável TEM de passar por `Register`; `[MyAttr]` nativo sozinho é conveniência Delphi e não
  atravessa. Quando ambos coexistem, o registrado prevalece por classe."*
- **CA-9.** `Source/ModernSyntax.Attributes.pas` **não contém** `{$I ModernSyntax.inc}`
  nem o token `FCP`. Verificável por grep (RN-6).

## 5. Restrições

- **Alvo FPC:** 3.2.2 estável, 32 e 64 bits (`i386` e `x86_64`).
- **Alvo Delphi:** XE+ (o suporte histórico da biblioteca), compilação verificada pelo autor.
- **Fábrica sem compilador Pascal** (R2). Revisão é por leitura.
- **`uses` da unit nova:** `SysUtils`, `Generics.Collections`, `SyncObjs`, e `Rtti` **apenas
  no Delphi** (via `{$IFNDEF FPC}` interno). Não usa `Windows`, não usa `Objects.pas`, não
  usa nenhuma unit da biblioteca — evita o custo transitivo medido no STUDY §C-4.
- **Diretório espelhado por compilador:** `Test Delphi/…`, `Test FPC/…`, `Test Shared/…`.
  Zero `Test Lazarus/`.
- **Sem DUnitX no lado FPC**: DUnitX não está vendorizado (medido no ciclo #7); FPCUnit
  é nativo do FPC 3.2.2 (`fpcunit.ppu`, `consoletestrunner.ppu` medidos).
- **Include path**: `{$I UTestMS.Attributes.Symbols.inc}` **sem caminho e sem contrabarra**.
  O diretório `Test Shared/EclbrSystem/` entra no include search path do projeto (`-Fi` no
  `.lpi`; "Search path" equivalente no `.dproj`).

## 6. Riscos

- **RSK-1 — Divergência silenciosa entre compiladores.** Uma classe Delphi só com `[MyAttr]`
  nativo devolve lista cheia; a mesma classe no FPC devolve vazio. Mitigação: fronteira
  **declarada** no PR (CA-8) mais dois testes específicos de compilador
  (`TestDelphi_NativeAlone_NoRegister_ReturnsNonEmpty`, `TestFPC_NativeAlone_NoRegister_ReturnsEmpty`)
  atrás dos símbolos `HAS_NATIVE_ATTRS`/`NO_NATIVE_ATTRS` — capacidade, não marca de compilador.
- **RSK-2 — AV no shutdown por liberar referência da RTTI.** Ownership por origem via
  `TAttributeRecord.Owned` (RN-9). `ReportMemoryLeaksOnShutdown` no `.dpr` (CA-6) torna a
  regressão observável.
- **RSK-3 — Sintaxe de search path do `.dproj`** (equivalente do `-Fi` do FPC) para
  `Test Shared/EclbrSystem/`. Não medido pela fábrica; o autor confirma no PR.
- **RSK-4 — Sintaxe `[MyAttr]` nativa Delphi aceitando descendente transitivo de
  `TCustomAttribute`.** Comportamento documentado da linguagem; sem Delphi na fábrica, o
  autor mede.
- **RSK-5 — R-FPC-Generic**: `TAttributeRecord` promovido à `interface` porque o `TDictionary`
  o instancia por método público da `interface`. Sem essa promoção, o FPC emite `Global Generic
  template references static symtable` (defeito medido no PR #12 do ciclo #7). Registrado como
  restrição operacional, aceita.
- **RSK-6 — R-Comment-Nest**: `{$...}` dentro de `{ }` fecha o comentário. Header SPDX é
  escrito com `(* ... *)` (RN-7). Registrado como restrição operacional, aceita.
- **RSK-7 — `{$DEFINE}` não atravessa fronteira de arquivo** (medido pela investigação, volta
  2). Guarda `{$MESSAGE FATAL}` vive **na casca `.pas`**, logo após o `{$I}`, não no `.dpr`.
  Registrado como "mecanismo de segurança que não mede o que promete medir" — mesma família
  dos defeitos dos PRs #11 e #12.
- **RSK-8 — Thread-safety básica.** `Register` e `GetAttributes` protegidos por `TCriticalSection`.
  Não é lock-free nem otimizado — a expectativa é que `Register` aconteça em `initialization` e
  `GetAttributes` seja majoritariamente leitura. Se um consumidor futuro fizer registro
  concorrente pesado, revisitar; hoje, custo baixo por corretude.
