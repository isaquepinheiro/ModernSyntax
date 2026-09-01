---
type: task
kind: artifact
title: "TASK-015 — TModernVisibility publico; fechar vazamento em Method.Visibility; adicionar Property.Visibility (#42)"
description: "Declarar TModernVisibility na casca; trocar tipo em TModernRTTIMethod.Visibility; adicionar TModernRTTIProperty.Visibility; backends Delphi e FPC; tres cenarios; mutacao de sanidade; PR fechando #42."
cycle: "015"
agent: planner
workflow: equipe-feature
node: task
resource: aefos://run/bb89abe1aa455add801745cb2a527e99
tags: [modernrtti, task, issue-42, fpc, delphi, visibility, feature, cycle-015]
generated:
  by: "equipe-feature@node:task"
  at: "2026-09-01T00:00:00Z"
sources:
  - id: task-input
    resource: "task-input.md"
    title: "TASK-INPUT — Implementar TModernVisibility, fechar vazamento em Method e adicionar Property.Visibility (issue #42)"
  - id: gh-42
    resource: "https://github.com/isaquepinheiro/ModernSyntax/issues/42"
    title: "Issue #42 — TModernVisibility publico + Property.Visibility"
---

# TASK-015 — TModernVisibility completo nos dois compiladores

## Rastreamento

**Modo:** MAESTRO MODE — issue #42 já existe no GitHub como intake do
maestro (`aefos:investigated`; re-entrada após plan-gate:on_reject no ciclo
014). Nenhuma issue ou Epic adicional criada.

**Issue de referência:** [#42](https://github.com/isaquepinheiro/ModernSyntax/issues/42) — TModernVisibility publico + Property.Visibility

**Parent Epic:** [#29](https://github.com/isaquepinheiro/ModernSyntax/issues/29) — Parte de #29 (link mantido no PR body)

**Board:** entrada adicionada em [../project-evolution.md](../../../project-evolution.md) com estado 🔄 in-pipeline.

**Ciclo:** 015

## Briefing

O enum `TMemberVisibility` do RTTI Delphi vaza na interface pública de
`TModernRTTIMethod.Visibility`. Este ciclo fecha esse vazamento declarando
`TModernVisibility = (mvPrivate, mvProtected, mvPublic, mvPublished)` como
tipo público na casca, troca o tipo de retorno de `TModernRTTIMethod.Visibility`
e adiciona `TModernRTTIProperty.Visibility` (ausente até agora) — tudo sem
`{$IFDEF}` em declarações de tipo público (D-25.1).

## Escopo operacional (síntese)

1. **Casca** (`Source/ModernSyntax.RTTI.pas`): enum `TModernVisibility`
   antes de `TModernRTTIField`; troca de tipo de retorno em
   `TModernRTTIMethod.Visibility`; declaração + delegação de
   `TModernRTTIProperty.Visibility`.

2. **Backend Delphi** (`Source/ModernSyntax.RTTI.Delphi.pas`):
   `MethodVisibility` reescrita com `case` explícito de exatamente 4 ramos;
   novo `PropertyVisibility(AToken: Pointer)` com mesmo `case` de 4 ramos.
   Sem `mvAutomated`, sem resourcestring nova.

3. **Backend FPC** (`Source/ModernSyntax.RTTI.FPC.pas`):
   `MethodVisibility` continua levantando (`SFPCNoVisibility` reescrita
   conforme D-42.5); novo `PropertyVisibility` com `case` de exatamente
   4 ramos (`mvPrivate`, `mvProtected`, `mvPublic`, `mvPublished`) — sem
   `mvAutomated` (identificador inexistente no FPC 3.2.2), sem raise.

4. **Cenários** (`Test Shared/EclbrSystem/UScenarios.RTTI.pas`): 3 cenários
   novos com fixtures locais; fixture cross-compiler tem propriedade
   `published` em classe `{$M+}`.

5. **Cascas** (`Test FPC/…/UTestMS.RTTI.pas` e `Test Delphi/…/UTestMS.RTTI.pas`):
   publicar cenários conforme matriz do ESP §2.

6. **Mutação de sanidade** (`CA-9`): trocar `case` de `PropertyVisibility`
   por valor fixo, provar vermelho, reverter, registrar no PR body.

## Arquivos impactados

| Arquivo | Natureza |
|---------|----------|
| `Source/ModernSyntax.RTTI.pas` | edição (enum + 2 assinaturas + 1 novo) |
| `Source/ModernSyntax.RTTI.Delphi.pas` | edição |
| `Source/ModernSyntax.RTTI.FPC.pas` | edição + reescrita de resourcestring |
| `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | edição (3 cenários novos) |
| `Test FPC/EclbrSystem/UTestMS.RTTI.pas` | edição (2 métodos published) |
| `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` | edição (2 métodos [Test]) |

Nenhum arquivo novo. Nenhum arquivo removido.

## Convenções que governam a implementação

- D-25.1 — sem `{$IFDEF}` em declaração de tipo público
- D-25.4 — governa **apenas** `MethodVisibility` FPC
- CA-5 — zero `{$IFDEF}` em `UScenarios.RTTI.pas`
- `case` explícito; nunca `TModernVisibility(Ord(...))`
- `Fail(...)` sempre; nunca `Assert`
- Prefixos: `mv` (enum values), `L` (locais), `A` (parâmetros); XMLDoc `///` em membros públicos novos ou alterados

## Checklist de aceitação (resumido)

Ver checklist completo em [task-input](pipeline-task-input.md).

- [ ] `TModernVisibility = (mvPrivate, mvProtected, mvPublic, mvPublished)` declarado antes de `TModernRTTIField`
- [ ] `TModernRTTIMethod.Visibility: TModernVisibility` (decl + impl)
- [ ] `TModernRTTIProperty.Visibility: TModernVisibility` (decl + impl)
- [ ] Backend Delphi: `case` exatamente 4 ramos em `MethodVisibility` e `PropertyVisibility`
- [ ] Backend FPC: `MethodVisibility` levanta; `SFPCNoVisibility` reescrita
- [ ] Backend FPC: `PropertyVisibility` com `case` de 4 ramos, sem `mvAutomated`, sem raise
- [ ] `grep -rn "TMemberVisibility" Source/ModernSyntax.RTTI.pas` retorna zero fora da `uses` da `implementation`
- [ ] 3 cenários publicados nas cascas corretas (FPC-only, Delphi-only, cross-compiler)
- [ ] Fixture cross-compiler: propriedade `published` em classe `{$M+}`
- [ ] Mutação de sanidade executada e registrada no PR body
- [ ] Build FPC 3.2.2 x86_64 e i386 verdes
- [ ] PR body declara o que foi compilado; fecha `Closes #42`; mantém `Parte de #29`

## Fontes

- [task-input](pipeline-task-input.md) — briefing operacional completo
- [esp](pipeline-esp.md), [adr](pipeline-adr.md), [plan](pipeline-plan.md) — artefatos de arquitetura do ciclo
