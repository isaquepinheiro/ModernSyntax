---
type: task
kind: artifact
title: "TASK-016 — TModernRTTIEnumerationType com guards M-1/M-2 nos dois backends (issue #43)"
description: "Implementar record publico TModernRTTIEnumerationType com seis metodos, backends FPC/Delphi com guards de faixa e valor invalido, quatro cenarios compartilhados e mutacao de sanidade obrigatoria."
cycle: "016"
agent: planner
workflow: equipe-feature
node: task
resource: aefos://run/9ac0699c1b65c18950220f022dfbb179
tags: [task, modernrtti, issue-43, fpc, delphi, enumeration, feature, cycle-016]
generated:
  by: "equipe-feature@node:task"
  at: "2026-09-01T00:00:00Z"
sources:
  - id: task-input
    resource: "task-input.md"
    title: "TASK-INPUT — TModernRTTIEnumerationType (issue #43)"
  - id: gh-43
    resource: "https://github.com/isaquepinheiro/ModernSyntax/issues/43"
    title: "Issue #43 — TModernRTTIEnumerationType"
---

# TASK-016 — TModernRTTIEnumerationType (issue #43)

## Rastreamento

**Modo:** MAESTRO MODE — `has_remote: true`, `from_maestro: true`.

A issue [#43](https://github.com/isaquepinheiro/ModernSyntax/issues/43) já existe
como intake do maestro (`aefos:running`). Nenhuma issue nova criada. Nenhum Epic
criado. O card já está em `aefos:running` — estado correto para ciclo in-pipeline.

**Parent Epic:** [#29](https://github.com/isaquepinheiro/ModernSyntax/issues/29) —
link `Parte de #29` mantido no PR body.

**Board:** entrada adicionada em [../project-evolution.md](../../../project-evolution.md)
com estado 🔄 in-pipeline.

**Ciclo:** 016

## Briefing

Implementar `TModernRTTIEnumerationType` — record público portável que encapsula
`PTypeInfo` de um tipo de enumeração e expõe seis métodos com semântica clara
de erros. A casca pública fica em `Source/ModernSyntax.RTTI.pas` sem nenhum
`{$IFDEF}` novo (D-1 / D-25.1). Os backends FPC e Delphi implementam cada
função com guarda explícita por `Kind` antes de qualquer operação.

## Escopo operacional (síntese)

1. **Casca pública** (`Source/ModernSyntax.RTTI.pas`): declarar
   `TModernRTTIEnumerationType` com `strict private FToken: PTypeInfo`, antes
   de `TModernRTTI` na `interface`; factory `FromTypeInfo` **sem** guarda de
   `Kind`; seis métodos públicos (`Name`, `MinValue`, `MaxValue`, `GetName`,
   `GetValue`, `GetNames`) com XMLDoc `///` declarando contrato de erros.

2. **Backend FPC** (`Source/ModernSyntax.RTTI.FPC.pas`): 6 funções livres em
   novo grupo `// --- Enumeration (issue #43) ---`, cada uma abrindo com
   `if (P = nil) or (P^.Kind <> tkEnumeration) then raise ...`; `EnumGetName`
   valida `[MinValue..MaxValue]` antes de `TypInfo.GetEnumName` (M-1);
   `EnumGetValue` captura retorno e levanta em `-1` (M-2); 3 `resourcestring`
   novas no bloco existente (:125): `SEnumWrongKind`, `SEnumOrdinalOutOfRange`,
   `SEnumNameUnknown`.

3. **Backend Delphi** (`Source/ModernSyntax.RTTI.Delphi.pas`): paridade de
   assinatura (D-2); guards M-1/M-2 espelhados antes de delegar a
   `TRttiEnumerationType`; 3 `resourcestring` duplicadas no bloco local.

4. **Cenários** (`Test Shared/EclbrSystem/UScenarios.RTTI.pas`): adicionar
   `TypInfo` à `uses` da `interface`; declarar `TCor = (cA, cB, cC)` e
   `TDia = (dSeg, dTer, dQua, dQui, dSex, dSab, dDom)` no `type` da
   `interface` após `TColor`; 4 procedures compartilhadas
   (`NameAndBounds`, `GetNameGetValue`, `GetNames_LengthAndPresence`,
   `OutOfRangeAndUnknownRaises`). **`TDia` (7 elementos) obrigatório** no
   cenário de contagem para matar a mutação `MaxValue-1`.

5. **Cascas** (`Test FPC/…/UTestMS.RTTI.pas` e `Test Delphi/…/UTestMS.RTTI.pas`):
   4 métodos em cada (`published` no FPC, `[Test]` no Delphi), mesmos nomes.

6. **Mutação de sanidade** (D-43.8 / CA-12): trocar `MaxValue` por `MaxValue - 1`
   no laço de `EnumGetNames` → `GetNames_LengthAndPresence` fica vermelho.
   Reverter, verde outra vez. Registrar diff + logs no PR body.

## Arquivos impactados

| Arquivo | Natureza |
|---------|----------|
| `Source/ModernSyntax.RTTI.pas` | edição (record novo + 6 métodos) |
| `Source/ModernSyntax.RTTI.FPC.pas` | edição (6 funções + 3 resourcestring) |
| `Source/ModernSyntax.RTTI.Delphi.pas` | edição (6 funções + 3 resourcestring) |
| `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | edição (TCor + TDia + 4 cenários + TypInfo em uses) |
| `Test FPC/EclbrSystem/UTestMS.RTTI.pas` | edição (4 métodos published) |
| `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` | edição (4 métodos [Test]) |

Nenhum arquivo novo. Nenhum arquivo removido.

## Convenções que governam a implementação

- **D-1 / D-25.1** — zero `{$IFDEF}` novo em `Source/ModernSyntax.RTTI.pas`
- **D-2** — paridade de assinatura nos dois backends
- **D-4** — guarda explícita por `Kind` no FPC, cada função
- **D-6** — assertivas por relação, não por posição frágil
- **D-26** — não devolver valor que também é resposta legítima (M-1/M-2)
- **CA-5** — zero `{$IFDEF}` em `UScenarios.RTTI.pas`
- `Fail(...)` sempre; nunca `Assert`; nunca `Exception` genérica
- Prefixos: `T` tipo, `A` parâmetros, `L` locais; XMLDoc `///` em membros públicos novos
- `rm -rf /tmp/fpcbuild` antes de cada compilação (SKILL Trap #2)

## Checklist de aceitação (resumido)

Ver checklist completo (25 itens) em [task-input](pipeline-task-input.md).

- [ ] `TModernRTTIEnumerationType` com `strict private FToken: PTypeInfo` antes de `TModernRTTI`
- [ ] `FromTypeInfo` sem validar `Kind` na fábrica
- [ ] 6 métodos públicos com XMLDoc `///`
- [ ] Backend FPC: 6 funções livres, cada uma com guarda por `Kind`
- [ ] Backend FPC: `EnumGetName` valida faixa (M-1)
- [ ] Backend FPC: `EnumGetValue` levanta em `-1` (M-2)
- [ ] Backend FPC: 3 `resourcestring` novas (`SEnumWrongKind`, `SEnumOrdinalOutOfRange`, `SEnumNameUnknown`)
- [ ] Backend Delphi: paridade de assinatura + guards M-1/M-2 + 3 `resourcestring` locais
- [ ] Zero `{$IFDEF}` novo em `Source/ModernSyntax.RTTI.pas`
- [ ] `TypInfo` na `uses` da `interface` de `UScenarios.RTTI.pas`
- [ ] `TCor` e `TDia` (7 elementos) declarados em `UScenarios.RTTI.pas`
- [ ] 4 cenários compartilhados; `TDia` obrigatório nos cenários de contagem
- [ ] `OutOfRangeAndUnknownRaises` com 3 afirmações independentes via `try/except + Fail(...)`
- [ ] 4 métodos `published` no FPC; 4 `[Test]` no Delphi; mesmos nomes
- [ ] Mutação de sanidade executada e registrada no PR body
- [ ] Build FPC 3.2.2 x86_64 e i386 verdes
- [ ] PR body declara compilação; fecha `Closes #43`; mantém `Parte de #29`

## Fontes

- [task-input](pipeline-task-input.md) — briefing operacional completo (25 itens de checklist)
- [esp](pipeline-esp.md), [adr](pipeline-adr.md), [plan](pipeline-plan.md) — artefatos de arquitetura do ciclo
