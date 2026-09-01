---
type: task-input
kind: artifact
title: "TASK-INPUT — Implementar TModernRTTIEnumerationType com guards de M-1/M-2 nos dois backends e quatro cenarios (issue #43)"
description: "Handoff operacional para o implementador: record publico TModernRTTIEnumerationType com FToken PTypeInfo e FromTypeInfo (sem guarda de Kind na fabrica); backend FPC com seis funcoes livres, cada uma abrindo com guarda por Kind, mais guards de M-1 (faixa em GetName) e M-2 (raise em GetValue quando -1); backend Delphi com paridade de assinatura e mesmos guards antes de delegar a TRttiEnumerationType; tres resourcestring novas em cada backend (nao na unit publica); quatro cenarios em UScenarios.RTTI.pas com fixture TCor + TDia; mutacao de sanidade MaxValue-1 obrigatoria; PR unico fechando #43; compilar FPC nos dois bitness."
status: draft
cycle: "016"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/9ac0699c1b65c18950220f022dfbb179
tags: [modernrtti, task-input, issue-43, fpc, delphi, enumeration, feature]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-09-01T00:00:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — TModernRTTIEnumerationType (issue #43)"
  - id: adr
    resource: "adr.md"
    title: "ADR — TModernRTTIEnumerationType (issue #43)"
  - id: plan
    resource: "plan.md"
    title: "PLAN — TModernRTTIEnumerationType em 3 slices (issue #43)"
---

# TASK-INPUT — issue #43 (TModernRTTIEnumerationType)

## Titulo (para commit / PR)

`feat(rtti): TModernRTTIEnumerationType publico; guards de M-1/M-2 nos dois backends (#43)`

## Tipo / labels

- **Tipo:** `feature`.
- **Labels GitHub:** `feature`, `aefos:running` (removida no fechamento),
  parent link `Parte de #29`.
- **Milestone:** o mesmo do parent #29 (se houver).

## Escopo operacional

Ler [`esp.md`](pipeline-esp.md) §2 para o escopo detalhado, [`adr.md`](pipeline-adr.md)
para o racional das nove decisoes (D-43.1..D-43.9), e [`plan.md`](pipeline-plan.md)
para a sequencia das 3 slices.

**Sintese executiva:**

1. **Casca** (`Source/ModernSyntax.RTTI.pas`): declarar
   `TModernRTTIEnumerationType` com `strict private FToken: PTypeInfo`,
   fabrica `FromTypeInfo` **sem guarda de `Kind`**, e seis metodos
   que delegam ao backend. XMLDoc `///` em cada um declarando o
   contrato de erros.
2. **Backend FPC** (`Source/ModernSyntax.RTTI.FPC.pas`): seis funcoes
   livres, cada uma abrindo com `if (P = nil) or (P^.Kind <>
   tkEnumeration) then raise ...`; `EnumGetName` com guarda de faixa
   antes de `TypInfo.GetEnumName` (M-1); `EnumGetValue` capturando
   retorno e levantando em `-1` (M-2). Tres `resourcestring` novas no
   bloco existente (:125): `SEnumWrongKind`, `SEnumOrdinalOutOfRange`,
   `SEnumNameUnknown`.
3. **Backend Delphi** (`Source/ModernSyntax.RTTI.Delphi.pas`): paridade
   de assinatura (D-2); espelhar os guards de M-1/M-2 antes de delegar
   a `TRttiEnumerationType`; duplicar as tres `resourcestring` no bloco
   local do arquivo (padrao do repo).
4. **Cenarios** (`Test Shared/EclbrSystem/UScenarios.RTTI.pas`):
   adicionar `TypInfo` a `uses` da `interface`; declarar `TCor` **e**
   `TDia`; quatro procedures compartilhadas (`NameAndBounds`,
   `GetNameGetValue`, `GetNames_LengthAndPresence`,
   `OutOfRangeAndUnknownRaises`). **`TDia` (7 elementos) obrigatorio**
   no cenario de contagem para matar a mutacao `MaxValue-1`.
5. **Cascas de teste** (`Test FPC/.../UTestMS.RTTI.pas` e
   `Test Delphi/.../UTestMS.RTTI.pas`): quatro metodos em cada,
   `published` no FPC e `[Test]` no Delphi, mesmos nomes.
6. **Mutacao de sanidade** (D-43.8 / CA-12): trocar `MaxValue` por
   `MaxValue - 1` no laco de `EnumGetNames`, provar vermelho, reverter,
   registrar no PR body.

## Checklist de aceitacao (copiar para o PR body)

- [ ] `TModernRTTIEnumerationType` declarado com `strict private
  FToken: PTypeInfo` (nao `FType: TRttiType`), antes de `TModernRTTI`
  na `interface` de `Source/ModernSyntax.RTTI.pas`.
- [ ] `class function FromTypeInfo(P: PTypeInfo): TModernRTTIEnumerationType; static;`
  publico, **sem validar `Kind`** na fabrica.
- [ ] Seis metodos publicos (`Name`, `MinValue`, `MaxValue`, `GetName`,
  `GetValue`, `GetNames`) com XMLDoc `///` declarando o contrato de
  erros.
- [ ] Backend FPC: seis funcoes livres em novo grupo `// ---
  Enumeration (issue #43) ---`, cada uma abrindo com guarda por `Kind`.
- [ ] Backend FPC: `EnumGetName` valida `[MinValue..MaxValue]` **antes**
  de `TypInfo.GetEnumName` (M-1).
- [ ] Backend FPC: `EnumGetValue` captura retorno de
  `TypInfo.GetEnumValue` e levanta em `-1` (M-2).
- [ ] Backend FPC: tres `resourcestring` novas no bloco existente
  (`SEnumWrongKind`, `SEnumOrdinalOutOfRange`, `SEnumNameUnknown`).
- [ ] Backend Delphi: seis funcoes com paridade de assinatura e mesmos
  guards de M-1/M-2 espelhados antes de delegar a
  `TRttiEnumerationType`.
- [ ] Backend Delphi: as tres `resourcestring` duplicadas no bloco local
  (padrao do repo).
- [ ] Zero `{$IFDEF}` novo em `Source/ModernSyntax.RTTI.pas`.
- [ ] `TypInfo` esta na `uses` da `interface` de `UScenarios.RTTI.pas`.
- [ ] `TCor = (cA, cB, cC);` e `TDia = (dSeg, dTer, dQua, dQui, dSex,
  dSab, dDom);` declarados no `type` da `interface` de
  `UScenarios.RTTI.pas`, apos `TColor`.
- [ ] Cenario `Scenario_EnumerationType_NameAndBounds` afirma
  `Name='TDia'`, `MinValue=0`, `MaxValue=6`.
- [ ] Cenario `Scenario_EnumerationType_GetNameGetValue` faz roundtrip
  por presenca em `TDia` (todos os 7 nomes).
- [ ] Cenario `Scenario_EnumerationType_GetNames_LengthAndPresence`
  afirma `Length=7` e presenca dos 7 nomes de `TDia`.
- [ ] Cenario `Scenario_EnumerationType_OutOfRangeAndUnknownRaises`
  tem tres afirmacoes independentes com `try/except + Fail(...)`.
- [ ] Quatro metodos `published` em `Test FPC/.../UTestMS.RTTI.pas`,
  quatro `[Test]` em `Test Delphi/.../UTestMS.RTTI.pas`, mesmos nomes.
- [ ] **Mutacao de sanidade executada e registrada no PR body:** trocar
  `MaxValue` por `MaxValue - 1` no laco de `EnumGetNames` (FPC ou
  Delphi) → `GetNames_LengthAndPresence` fica vermelho. Reverter,
  verde outra vez.
- [ ] `rm -rf /tmp/fpcbuild` antes de cada compilacao (SKILL Trap #2).
- [ ] Compila FPC 3.2.2 x86_64 verde.
- [ ] Compila FPC 3.2.2 i386 verde.
- [ ] PR body declara explicitamente o que foi compilado: "compilado em
  FPC 3.2.2 x86_64 e i386; nao compilado em Delphi neste ambiente —
  validacao Delphi cabe ao autor" (SKILL §"What a PR must declare").

## Arquivos provavelmente impactados

| Arquivo | Natureza |
|---------|----------|
| `Source/ModernSyntax.RTTI.pas` | edicao (record novo + 6 metodos) |
| `Source/ModernSyntax.RTTI.FPC.pas` | edicao (6 funcoes + 3 resourcestring) |
| `Source/ModernSyntax.RTTI.Delphi.pas` | edicao (6 funcoes + 3 resourcestring) |
| `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | edicao (TCor + TDia + 4 cenarios + TypInfo em uses) |
| `Test FPC/EclbrSystem/UTestMS.RTTI.pas` | edicao (4 metodos published) |
| `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` | edicao (4 metodos [Test]) |

Nenhum arquivo novo. Nenhum arquivo removido.

## Convencoes que governam a implementacao

- **D-1 / D-25.1** — zero `{$IFDEF}` novo em tipo publico
  (`Source/ModernSyntax.RTTI.pas`).
- **D-2** — paridade de assinatura nos dois backends.
- **D-4** — guarda explicita por `Kind` no FPC, cada funcao.
- **D-6** — assertivas por relacao, nao por posicao fragil (cenarios
  2 e 3 por presenca de nomes).
- **D-26** — nao devolver valor que tambem e resposta legitima (M-1 em
  `GetName`, M-2 em `GetValue`).
- **CA-5 do repo** — zero `{$IFDEF}` em `UScenarios.RTTI.pas`.
- **`Fail(...)` sempre; nunca `Assert`; nunca `Exception` generica.**
- **`case` explicito nao se aplica aqui** — nao ha `case` sobre valores
  do enum na camada; o record e polimorfico sobre `PTypeInfo`.
- **Prefixos:** `T` no tipo, `A` em parametros, `L` em locais; XMLDoc
  `///` em membros publicos novos.

## Notas para o PR

- **Fechamento:** `Closes #43`. Manter link `Parte de #29`.
- **Nao atualiza API-MAP §3** por default (herdado do #42). Se o
  revisor pedir, e um commit adicional no mesmo PR.
- **Mutacao registrada no PR body** com o diff aplicado (antes/depois)
  e o log da suite mostrando vermelho, seguido do log mostrando verde
  apos reverter.
- **Nao "otimizar" o laco de `EnumGetNames`** para uma forma que
  presuma faixa contigua sem antes reler o ADR (D-43.7 e a nota M-3):
  se o FPC passar a emitir RTTI para enums descontinuos, o laco atual
  se torna alarme; qualquer refatoracao que assuma contiguidade quebra
  o alarme silenciosamente.
