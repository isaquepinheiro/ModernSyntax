---
type: task-input
kind: artifact
title: "TASK-INPUT — Tipos de categoria (issue #29): RECOMENDA SPLIT em 5 sub-issues, uma por tipo"
description: "Handoff operacional: esta issue e um SPLIT (ver split-proposal.md). Cinco sub-issues, cada uma stand-alone: TModernVisibility + F-1/F-2; TModernRTTIEnumerationType; TModernRTTIPointerType; TModernRTTIRecordType (Name+Size); TModernRTTIArrayType + TModernRTTISetType. Padrao FToken: PTypeInfo em todos os records (as subclasses Enum/Record/Array/Set nao existem no FPC 3.2.2 — medido M-1). Backend FPC sempre pelas properties (CompType, ElType2, ElType, RefType), nunca campos *Ref crus (M-2). Guarda por Kind em cada funcao (D-27 novo). ArrayType.Length levanta em dinamico nos dois compiladores (D-26). Cenario obrigatorio com TArray<Integer> — o unico que separa ElType2 (certo) de ElType (AV). IndexedProperty NAO entra — vira issue propria com blocked:fpc-3.4."
status: stable
cycle: "014"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/f42b5faad0107a1daea308f52bd50ed4
tags: [modernrtti, task-input, issue-29, split, fpc, delphi, visibility, enumeration, pointer, record, array, set, feature]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-09-01T00:00:00Z"
---

# TASK-INPUT — issue #29

## Titulo

Tipos de categoria: `Record`, `Array`, `Enumeration`, `Set`, `Pointer`
e `Visibility` — os seis pares `Modern` que fecham a categoria de forma
da RTTI, cada um como sub-issue propria (SPLIT recomendado). Sete
menos um: **`TModernRTTIIndexedProperty` sai desta issue** (M-7 do
relatorio) e vira issue propria com `blocked:fpc-3.4`.

## Tipo / labels

- `type: feature`
- `route: feature`
- labels na issue-mae: `enhancement`, `rtti`, `fpc`, `delphi`,
  `pilar-4`, `split-approved` (quando o split for aceito).
- labels por sub-issue: ver [split-proposal](pipeline-split-proposal.md).

## Escopo curto

**Este PR nao implementa — este PR e o split.** Ver
[split-proposal](pipeline-split-proposal.md) para as cinco sub-issues.

Se o split for **rejeitado** pelo human-in-the-loop e a diretriz for
"entregar tudo num so", o escopo integral e:

- **Fase 1** — `TModernVisibility` como enum publico proprio; fix de
  `TModernRTTIMethod.Visibility` (F-1: hoje vaza `TMemberVisibility`
  do `TypInfo`) e adicao de `TModernRTTIProperty.Visibility` (F-2:
  API-MAP §2 promete, codigo nao entrega).
- **Fase 2** — `TModernRTTIEnumerationType` (`Name`, `GetNames`,
  `GetName`, `GetValue`, `MinValue`, `MaxValue`).
- **Fase 3** — `TModernRTTIPointerType` (`ReferredType`).
- **Fase 4** — `TModernRTTIRecordType` (`Name`, `Size` **apenas** —
  sem `GetFields`, que vira issue propria).
- **Fase 5** — `TModernRTTIArrayType` (`ElementType`, `Size`, `Length`
  que levanta em dinamico, `IsDynamic`) + `TModernRTTISetType`
  (`ElementType`).

**`TModernRTTIIndexedProperty` fora** — nao aparece em `rtti.pp` do FPC
3.2.2 (M-7 do relatorio); vira issue propria com `blocked:fpc-3.4`.

## Checklist de aceitacao

O checklist comum (aplica a QUALQUER estrategia — PR unico ou
sub-issue) esta na [esp](pipeline-esp.md) §4 "Comuns". Reproduzido aqui em
sintese:

- [ ] Zero `{$IFDEF}` novo em `Source/ModernSyntax.RTTI.pas` fora da
      `uses` da `implementation` (API-MAP §7).
- [ ] Zero `{$IFDEF FPC}` novo em
      `Test Shared/EclbrSystem/UScenarios.RTTI.pas` (CA-5).
- [ ] Zero `Assert`, `Exception` generica ou `AssertException` novo
      em `UScenarios.RTTI.pas` (RB-6).
- [ ] Paridade estrita: mesmo numero de funcoes livres novas em
      `Source/ModernSyntax.RTTI.Delphi.pas` e `Source/ModernSyntax.RTTI.FPC.pas`
      (API-MAP §7).
- [ ] Todos os novos records de forma usam `FToken: PTypeInfo` (nao
      `FType: TRttiType`), com `class function FromTypeInfo(P: PTypeInfo)`.
- [ ] Backend FPC usa sempre as properties (`CompType`, `ElType2`,
      `ElType`, `RefType`) — `grep` retorna zero para
      `CompTypeRef|elTypeRef|elType2Ref|RefTypeRef` em `.FPC.pas`.
- [ ] Backend FPC comeca cada funcao com guarda por `Kind` (D-27 novo).
- [ ] `TModernRTTIArrayType.Length` **levanta** `EModernRTTIError` em
      `tkDynArray` **nos dois compiladores** (D-26; RB-4).
- [ ] Cenario com `TArray<Integer>` **existe** e afirma `Length`
      levanta; comentario declara a mutacao obrigatoria `ElType2 → ElType`.
- [ ] Cenario com `set of TCor` **existe** e afirma
      `ElementType.Name = 'TCor'`; comentario declara a mutacao
      obrigatoria `CompType → CompTypeRef`.
- [ ] Afirmacoes de tamanho por relacao (`Size = SizeOf(T)`;
      `MaxValue - MinValue + 1 = Length(GetNames)`), nunca numero
      absoluto (M-6 — bitness).
- [ ] Multiplicidade: enum com >= 3 constantes; record com >= 2 campos.
- [ ] Compila e passa **nos dois bitness** FPC (x86_64 e i386) com a
      receita de `.project/SKILL.md` (`rm -rf` do `-FU` antes de cada
      recompilar; nao compilar `Source/` inteiro).
- [ ] PR **declara em palavras** o que foi compilado.

Por-fase (aplica a **cada** sub-issue quando split; a todas em conjunto
quando PR unico):

- [ ] **Fase 1:** enum publico + fix F-1 (`Method.Visibility` deixa de
      ser `TMemberVisibility`) + adicao F-2 (`Property.Visibility`
      existe). Dois pares de cenarios FPC-only/Delphi-only (padrao
      dois cenarios distintos D-25).
- [ ] **Fase 2:** enum tipo entrega os seis metodos; guarda por
      `tkEnumeration`; `GetValue('cB') = 1` e
      `Length(GetNames) = MaxValue - MinValue + 1`.
- [ ] **Fase 3:** pointer tipo entrega `ReferredType`; mutacao
      `RefType → RefTypeRef` verificada (vermelha ou AV).
- [ ] **Fase 4:** record tipo entrega `Name` + `Size` (sem
      `GetFields`); `Size = SizeOf(TFixture)` nos dois bitness.
- [ ] **Fase 5:** array + set entregam. Cenario `TArray<Integer>`
      verde; `Length` levanta em dinamico; mutacoes `ElType2 → ElType`
      e `CompType → CompTypeRef` verificadas (vermelhas ou AV).

## Arquivos provavelmente impactados

Em qualquer estrategia (unico PR ou sub-issue), os arquivos sao os
mesmos — sub-issue toca so a parte dela:

- `Source/ModernSyntax.RTTI.pas` — declaracoes publicas
  (`TModernVisibility`, seis records de forma), XMLDocs, corpos delegando
  aos backends; alteracao da assinatura de `TModernRTTIMethod.Visibility`;
  adicao de `TModernRTTIProperty.Visibility`.
- `Source/ModernSyntax.RTTI.Delphi.pas` — funcoes livres novas
  (`EnumType*`, `PointerTypeReferredType`, `RecordType*`, `ArrayType*`,
  `SetTypeElementType`, `PropertyVisibility`); alteracao de assinatura
  de `MethodVisibility`.
- `Source/ModernSyntax.RTTI.FPC.pas` — mesmas funcoes livres (paridade
  estrita); nova `resourcestring` `SModernRTTIError_DynArrayLength` (na
  Fase 5) e possivelmente `SModernRTTIError_PropertyVisibility` (Fase 1
  — pode reusar `SModernRTTIError_MethodVisibility` se ja generica).
- `Test Shared/EclbrSystem/UScenarios.RTTI.pas` — fixtures novas
  (`TCor`, `TFixture` de record, `PInteger`, `TStat`, `TCoresSet`,
  possivelmente `TVisibilityFixture`) e cenarios (dois pares casca-only
  na Fase 1; oito compartilhados nas Fases 2-5).
- `Test FPC/EclbrSystem/UTestMS.RTTI.pas` — wrappers `published` (dois
  FPC-only na Fase 1; um por cenario compartilhado nas outras fases).
- `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` — wrappers `[Test]` (dois
  Delphi-only na Fase 1; um por cenario compartilhado nas outras fases).
- `.project/strategy/2026-08-27-modernrtti/API-MAP.md` — edicao em
  prosa: nota "adiada" na linha do `TRttiIndexedProperty` (D-29.10).

**Nao mexer:**
- `Source/ModernSyntax.RTTI.Delphi.pas` fora das funcoes novas.
- `Source/ModernSyntax.RTTI.FPC.pas` fora das funcoes novas e da
  resourcestring.
- Records existentes `TModernRTTIField`, `TModernRTTIProperty`,
  `TModernRTTIMethod` — o `FToken: Pointer` deles **continua valido**
  (nao sao donos de heap; ver D-28.2 do ciclo 013 e D-29.3 do
  [adr](pipeline-adr.md)).
- `Test FPC/EclbrSystem/PTestRTTI.lpr` e `Test Delphi/EclbrSystem/PTestRTTI.dpr`
  (ja usam `UTestMS.RTTI`).

## Convencoes de codigo aplicaveis

- **API-MAP §7:** unico `{$IFDEF}` da unit publica na `uses` da
  `implementation`; paridade estrita entre backends; nenhum `{$IFDEF}`
  em declaracao de tipo, membro ou implementacao.
- **CA-5 (PRD.md):** zero `{$IFDEF FPC}` no consumidor. Onde o
  comportamento diverge por compilador (visibilidade), dois cenarios
  distintos (D-25).
- **D-25.4:** membros sem fonte no FPC levantam `EModernRTTIError` com
  mensagem instrutiva.
- **D-26:** nao silenciar divergencia. `Length` em dinamico levanta,
  nunca `Result := 0`.
- **D-27 novo:** guarda por `Kind` em cada funcao do backend FPC
  (`TTypeData` e registro variante).
- **D-28.2:** `Pointer` em record e seguro enquanto o record nao e
  dono. Os seis novos records apontam para `PTypeInfo` **estatico do
  binario** — nao donos.
- **RB-6:** `Fail(...)` sempre; nunca `Assert`, nunca `Exception`
  generica, `AssertException` nao existe (#27, #35).
- **RB-8:** sempre pelas properties (`CompType`, `ElType2`, `ElType`,
  `RefType`), nunca pelos campos `*Ref` crus (M-2).
- **SKILL.md:** limpar `-FU` antes de recompilar; nao compilar
  `Source/` inteiro; PR declara o que foi compilado.

## Fontes

- [esp](pipeline-esp.md), [adr](pipeline-adr.md), [plan](pipeline-plan.md),
  [split-proposal](pipeline-split-proposal.md).
- `[investigation report — issue #29]` (INVESTIGATION REPORT
  reproduzido no prompt deste no).
- [/strategy/2026-08-27-modernrtti/API-MAP.md](/strategy/2026-08-27-modernrtti/API-MAP.md)
  §§1, 2, 7.
- [/strategy/2026-08-27-modernrtti/PRD.md](/strategy/2026-08-27-modernrtti/PRD.md)
  — CA-5.
- [/SKILL.md](/SKILL.md) — receita FPC, mutacao, traps.
- [/history/cycles/cycle-010-a36e1364/pipeline-adr.md](/history/cycles/cycle-010-a36e1364/pipeline-adr.md)
  — D-25.
- [/history/cycles/cycle-011-38e3bcee/pipeline-adr.md](/history/cycles/cycle-011-38e3bcee/pipeline-adr.md)
  — D-26.
- [/history/cycles/cycle-013-5a8dfb58/pipeline-adr.md](/history/cycles/cycle-013-5a8dfb58/pipeline-adr.md)
  — D-28.2.
