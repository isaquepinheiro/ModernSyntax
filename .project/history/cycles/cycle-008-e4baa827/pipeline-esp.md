---
type: spec
kind: artifact
title: "ESP — TModernRTTIField portável nos dois compiladores (issue #21)"
description: "TModernRTTIField e TModernRTTIType.GetFields passam a existir e funcionar em Delphi e FPC com superfície pública idêntica; ramificação vive apenas em strict private e implementação. No FPC, GetFields enumera campos published de tipo classe subindo a cadeia por ClassParent."
status: draft
cycle: "008"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/e4baa827945b3dd3a372629b831d73a9
tags: [modernrtti, rtti, spec, issue-21, fpc, delphi]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-08-31T00:00:00Z"
sources:
  - id: issue-21
    title: "Issue #21 — TModernRTTIField tem que existir nos dois compiladores"
  - id: prd
    resource: "/strategy/2026-08-27-modernrtti/PRD.md"
    title: "ModernRTTI PRD"
  - id: adr-006
    resource: "/history/cycles/cycle-006-0432fa58/pipeline-adr.md"
    title: "ADR — Pilar 1 ModernRTTI (D12 é substituída por esta issue)"
  - id: esp-006
    resource: "/history/cycles/cycle-006-0432fa58/pipeline-esp.md"
    title: "ESP — Pilar 1 ModernRTTI"
---

# ESP — TModernRTTIField portável nos dois compiladores (issue #21)

## 1. Objetivo

Fazer `TModernRTTIField` e `TModernRTTIType.GetFields` **existirem e
compilarem** nos dois compiladores, com a **mesma superfície pública**. A
ramificação por compilador vive apenas na seção `strict private` do record e
no corpo dos métodos — o consumidor **nunca** vê `{$IFDEF FPC}` no seu
próprio código.

O que a entrega do Pilar 1 (ciclo 006, D12 do [ADR](/history/cycles/cycle-006-0432fa58/pipeline-adr.md))
deixou como Delphi-only por ausência de símbolo (`TRttiField`/`GetFields` no
FPC 3.2.2) passa a ser **portável** por outro caminho: no FPC, `vmtFieldTable`
para enumerar e offset para ler/escrever. A superfície permanece idêntica; a
mecânica difere só por dentro.

## 2. Escopo

**Entra:**

- `Source/ModernSyntax.RTTI.pas` — remoção do `{$IFNDEF FPC}` externo sobre
  `TModernRTTIField` e `TModernRTTIType.GetFields`; declaração pública
  incondicional; ramificação em `strict private` e nas implementações;
  factories privadas com **nomes distintos por branch** (`FromRaw` no FPC,
  `FromRtti` no Delphi); XMLDoc reescrito em voz de contrato.
- `Test Shared/EclbrSystem/UScenarios.RTTI.pas` — nova fixture **com
  herança** (`TInner`/`TBase`/`TPortableFieldFixture`) e nova procedure
  `Scenario_GetFields_EnumeratesInheritedPublishedClassFields`.
- `Test FPC/EclbrSystem/UTestMS.RTTI.pas` — remove o comentário-mentira da
  linha 16 e adiciona a casca fina
  `TestGetFields_EnumeratesInheritedPublishedClassFields` (uma única linha
  útil que chama o cenário compartilhado).

**Fora do escopo:**

- `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` — inalterado. O teste Delphi
  existente sobre `TFieldFixture` (campos `public` escalares) permanece como
  cobertura Delphi-only real (a `vmtFieldTable` do FPC não veria).
- Qualquer outra unit de `Source/` — proibido pela nota da issue ("nenhuma
  outra unit tocada").
- Correção do `FCP` em `Source/ModernSyntax.inc` — R3 do PRD; contornar,
  não consertar.
- Prometer paridade de **ordem** de elementos entre Delphi e FPC — o
  contrato declara ordem NÃO especificada.

## 3. Regras de negócio

- **RN-1 — superfície pública idêntica.** Nos dois compiladores, o record
  `TModernRTTIField` expõe exatamente `Name`, `GetValue<T>`, `SetValue<T>`
  (genéricos) e os overloads `GetValue: TValue`/`SetValue(TValue)`. O
  `TModernRTTIType.GetFields: TArray<TModernRTTIField>` também é público
  incondicional.
- **RN-2 — ramificação só por dentro (D2 do PRD).** `{$IFDEF FPC}` aparece
  apenas em `strict private` do record e no corpo dos métodos da
  `implementation`. Zero `{$IFDEF FPC}` na declaração pública ou no consumidor
  (CA-5 do PRD).
- **RN-3 — factories privadas distintas por branch.**
  - FPC: `class function FromRaw(AOwner: TClass; const AName: string; AOffset: PtrUInt): TModernRTTIField; static;`
  - Delphi: `class function FromRtti(const AField: TRttiField): TModernRTTIField; static;`
  Nomes iguais com assinaturas divergentes sob `{$IFDEF}` são recusados —
  o implementador escreveria a chamada errada e só descobriria no compilador.
- **RN-4 — no FPC, enumeração via `vmtFieldTable` tipada.**
  `PVmtFieldTable(PVmt(LCur)^.vFieldTable)` — caminho **público e tipado**
  (`objpash.inc:99-108` e `typinfo.pp:212-227`), com precedente na própria
  RTL (`reader.inc:588`). **Proibido** aritmética `PByte(LClass) + vmtFieldTable`.
- **RN-5 — no FPC, iteração pela property `Field[i]`.** Entradas
  `TVmtFieldEntry` têm **tamanho variável** (`Name: ShortString`) — a
  própria RTL alerta em `typinfo.pp:224-226`. Usar a property `Field[i]`,
  nunca indexar `Fields[i]` como array.
- **RN-6 — no FPC, subir a cadeia por `ClassParent`.** `vmtFieldTable` do
  FPC **não é recursiva** (`jitclass.pas:1187-1188`), enquanto
  `TRttiType.GetFields` do Delphi **inclui herdados**. Sem subir a cadeia,
  `GetFields` divergiria em silêncio entre compiladores. `vFieldTable = nil`
  num elo é rotina — pular o elo, não interromper.
- **RN-7 — no FPC, cast explícito `string(LEntry^.Name)`.**
  `TVmtFieldEntry.Name` é `ShortString` (`typinfo.pp:205-210`). Sem o cast,
  warning ou perda em não-ASCII.
- **RN-8 — no FPC, `AOwner` guarda o elo declarante.** O offset é absoluto
  no layout e válido para qualquer descendente, mas guardar a classe real
  onde o campo mora preserva debug e mantém a semântica interna do handle.
- **RN-9 — overload `TValue` no FPC via `TValue.From<TObject>`.** Sempre
  classe (limite `published` do FPC). Custo (`uses Rtti` + warning
  `experimental`) **já está pago** pela unit hoje. Descartado (b) `raise` e
  (c) `{$IFDEF}` isolado no overload público — ambos violam a superfície
  única.
- **RN-10 — `vmtFieldTable = nil` na cadeia inteira devolve array vazio,
  não exceção.** Simetria com o Delphi, coerente com o cenário legítimo do
  `TDerived` medido.
- **RN-11 — contrato de ordem: NÃO especificada.** XMLDoc de `GetFields`
  declara que o array não tem ordem promissível — o consumidor deve
  **buscar por nome, não indexar por posição**, em ambos os compiladores.
  Ninguém mediu `dcc32` neste ciclo; nada de afirmar paridade não medida.
- **RN-12 — XMLDoc em voz de contrato, com a palavra "no FPC".** O tom é
  descritivo — "GetFields enumera os campos que a RTTI de cada compilador
  reconhece como enumeráveis; **no FPC**, campos `published` de tipo classe".
  Nunca "limite do compilador FPC 3.2.2". A palavra "no FPC" é obrigatória
  (CA-4).
- **RN-13 — casca fina, cenário compartilhado (D9 do ADR do ciclo 006).**
  `Test Shared/EclbrSystem/UScenarios.RTTI.pas` carrega a lógica; a casca
  FPC é uma linha útil. Sem `if/assert` na casca. Sem `{$IFDEF}` em nenhum
  dos arquivos de teste (CA-5 do PRD).
- **RN-14 — fixture com herança.** A fixture do cenário compartilhado
  **precisa** ter herança — sem ela, recursivo e não-recursivo dão o mesmo
  número e o teste passa cego. Forma B (`TInner` nomeado), porque torna
  visível a regra "só tipo classe":
  ```pascal
  {$M+}
  TInner  = class end;
  TBase   = class InnerA: TInner; end;
  TPortableFieldFixture = class(TBase) InnerB: TInner; end;
  {$M-}
  ```
- **RN-15 — assertiva por contagem exata.** O cenário afirma
  `Length(GetFields) = 2` **exato**, para pegar regressão (M3 do relatório)
  e duplicação. Os nomes `InnerA` e `InnerB` são verificados por busca no
  array, **sem depender de ordem** (RN-11).
- **RN-16 — cabeçalho `(* … *)` da unit permanece.** D10 do ADR do
  ciclo 006 — mudança não toca no header.

## 4. Critérios de aceitação

- **CA-1.** `TModernRTTIField` e `TModernRTTIType.GetFields` **existem e
  compilam** nos dois compiladores. `grep -n 'TModernRTTIField\|GetFields'
  Source/ModernSyntax.RTTI.pas` mostra as declarações públicas fora de
  qualquer `{$IFNDEF FPC}`.
- **CA-2 — zero `{$IFDEF}` no consumidor.** Um arquivo de teste que
  declare e use `TModernRTTIField` compila **sem nenhum `{$IFDEF FPC}` no
  código do teste**. Verificação:
  `grep -rn '{\$IFDEF FPC}\|{\$IFNDEF FPC}' 'Test Shared/EclbrSystem/UScenarios.RTTI.pas' 'Test FPC/EclbrSystem/UTestMS.RTTI.pas' 'Test Delphi/EclbrSystem/UTestMS.RTTI.pas'` → zero linhas.
- **CA-3 — FPC funcional.** No FPC, `GetFields` enumera campos `published`
  de tipo classe subindo a cadeia por `ClassParent`; `GetValue<T>` e
  `SetValue<T>` leem e escrevem por offset. Coberto por
  `Scenario_GetFields_EnumeratesInheritedPublishedClassFields` (contagem
  exata = 2 sobre `TPortableFieldFixture`).
- **CA-4 — XMLDoc de contrato com "no FPC".** O XMLDoc de
  `TModernRTTIField` e de `GetFields` documenta o contrato portável, cita a
  regra "só tipo classe **no FPC**" e declara "ordem dos elementos não é
  especificada". `grep -n 'no FPC' Source/ModernSyntax.RTTI.pas` mostra as
  duas ocorrências.
- **CA-5 — build FPC verde nos dois bitness.**
  `Test FPC/EclbrSystem/PTestRTTI.lpr` compila e o binário passa em
  `x86_64` **e** `i386`, receita da [SKILL](/SKILL.md) (LIMPAR output
  antes):
  ```
  rm -rf <out> && fpc -Mdelphi -Fu"Source" \
      -Fu"Test Shared/EclbrSystem" -FU<out> -FE<out> \
      "Test FPC/EclbrSystem/PTestRTTI.lpr"
  ```
- **CA-6 — nenhuma outra unit tocada.** `git diff --name-only main…HEAD`
  lista **apenas** `Source/ModernSyntax.RTTI.pas`,
  `Test Shared/EclbrSystem/UScenarios.RTTI.pas` e
  `Test FPC/EclbrSystem/UTestMS.RTTI.pas`.
- **CA-7 — comentário-mentira removido.** A linha 16 de
  `Test FPC/EclbrSystem/UTestMS.RTTI.pas` (que dizia "Sem TestGetFields
  aqui: TModernRTTIField é Delphi-only (D12 do ADR)") **não existe mais**.
- **CA-8 — corpo do PR declara build.** *"Compilado em FPC 3.2.2 x86_64 e
  i386 — verde nos dois; não compilado em Delphi — Delphi permanece com o
  autor."* (R2 do PRD).

## 5. Restrições

- **Alvo FPC:** 3.2.2 estável, 32 e 64 bits.
- **Alvo Delphi:** XE+ (compilação pelo autor — R2 do PRD).
- **Fábrica sem Delphi.** A fixture `{$M+} TInner = class end; TBase =
  class InnerA: TInner; end; TPortableFieldFixture = class(TBase) InnerB:
  TInner; end; {$M-}` **não** foi medida em `dcc32` neste ciclo; sintaxe
  padrão, risco baixo mas não zero (registrado em §6).
- **`{$mode delphi}` obrigatório** na unit de produção (RN-4a do
  [ESP do ciclo 006](/history/cycles/cycle-006-0432fa58/pipeline-esp.md)). Nunca
  `{$mode objfpc}` — derruba `strict private` em records.
- **Nenhum `{$I ModernSyntax.inc}`.** Contornar o typo `FCP` em
  `ModernSyntax.inc:261`, não consertar (R3 do PRD).
- **Nenhuma unit de `Source/` no `uses`** da unit de produção.
- **Cabeçalho SPDX-MIT em `(* … *)`** — preservar (D10 do ADR ciclo 006).
- **`rm -rf <out>`** obrigatório antes de cada build FPC (SKILL.md trap 2).

## 6. Riscos

- **RSK-1 — fixture com herança não medida em Delphi.** `{$M+} class end`
  com herança é sintaxe padrão, mas ninguém compilou em `dcc32` neste
  ciclo. Se falhar (improvável), o implementador Delphi decide entre
  `{$M+}...{$M-}` em bloco vs `{$M+}` isolado em `TInner`. Não altera o
  contrato.
- **RSK-2 — `TValue.From<TObject>` no FPC 3.2.2.** Ao ler o campo classe
  via ponteiro e envolver em `TValue`, a `Rtti` do FPC ainda pode se
  atrapalhar para `T` genérico. Fallback: o overload `TValue` cru é o
  caminho recomendado para esses `T`. Sem impacto na superfície pública.
- **RSK-3 — build incremental mentiroso no FPC.** `.ppu` reusado esconde
  regressão real. Mitigação obrigatória: `rm -rf <out>` antes de cada build
  de prova (SKILL.md trap 2). Sem fallback.
- **RSK-4 — `TypInfo` no `uses` do FPC.** A obtenção de
  `PVmt`/`PVmtFieldTable` exige `TypInfo` no FPC. Já é uma das três units
  autorizadas em RN-3 do [ESP do ciclo 006](/history/cycles/cycle-006-0432fa58/pipeline-esp.md);
  sem impacto novo em dependências.
