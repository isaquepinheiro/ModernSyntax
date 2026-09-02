---
type: task
kind: artifact
title: "TASK-020 — nil-handle contract para TModernRTTIType (issue #49)"
description: "Cinco guardas identicas + resourcestring + XMLDocs em ModernSyntax.RTTI.pas; cenario Scenario_NilHandle_AllMembers_Raises; desbloqueio D-44.6; duas cascas de uma linha."
cycle: "020"
agent: planner
workflow: equipe-bug
node: task
resource: aefos://run/fd87755097391831d283adc83e6b8813
status: draft
tags: [task, modernrtti, issue-49, bug, nil-handle, fpc, delphi, cycle-020]
generated:
  by: "equipe-bug@node:task"
  at: "2026-09-02T00:00:00Z"
sources:
  - id: task-input
    resource: "task-input.md"
    title: "TASK-INPUT — issue #49"
  - id: gh-49
    resource: "https://github.com/isaquepinheiro/ModernSyntax/issues/49"
    title: "Issue #49 — nil-handle contract TModernRTTIType"
---

# TASK-020 — issue #49 (nil-handle contract para TModernRTTIType)

## Rastreamento

**Modo:** MAESTRO MODE — `has_remote: true`, `from_maestro: true`.

A issue [#49](https://github.com/isaquepinheiro/ModernSyntax/issues/49) já existe
como intake do maestro (`aefos:investigated`) e é a demanda oficial deste ciclo.
Nenhuma issue nova criada. Nenhum Epic criado neste ciclo.

**Board:** entrada adicionada em `project-evolution.md` com estado 🔄 in-pipeline.

**Ciclo:** 020

## Briefing

Implementar o contrato único de handle nil em `TModernRTTIType` — cinco membros
(`Name`, `GetProperties`, `GetFields`, `GetMethods`, `GetMethod`) devem levantar
`EModernRTTIError` com `SModernRTTINilHandle` quando `FType = nil`.

### Escopo em uma linha

Cinco guardas idênticas de nil + resourcestring + XMLDocs em `ModernSyntax.RTTI.pas`;
um cenário compartilhado + desbloqueio de dívida em `UScenarios.RTTI.pas`;
duas cascas de uma linha cada.

## Arquivos impactados

| Arquivo | O que muda |
|---------|-----------|
| `Source/ModernSyntax.RTTI.pas` | `resourcestring SModernRTTINilHandle`; cinco guardas `if FType = nil`; cinco XMLDoc `<remarks>` |
| `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | Novo `Scenario_NilHandle_AllMembers_Raises`; desbloqueio D-44.6 em `Scenario_PointerType_ReferredType_Nil_ForBarePointer` |
| `Test FPC/EclbrSystem/UTestMS.RTTI.pas` | `published TestNilHandle_AllMembers_Raises` de uma linha |
| `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` | `[Test] TestNilHandle_AllMembers_Raises` de uma linha |

**Nenhum arquivo novo. Nenhum arquivo removido.**

## Instrucoes criticas

### 1. `Source/ModernSyntax.RTTI.pas`

Adicionar `resourcestring` no bloco existente (`:860-873`):

```pascal
SModernRTTINilHandle =
  'handle nao inicializado (IsNil = True). Verifique IsNil antes de chamar %s.';
```

Cinco guardas identicas — uma por membro — antes de qualquer acesso a `FType`:

| Membro | Linha ref | Parametro `%s` |
|--------|-----------|----------------|
| `Name` | antes de `:1022` | `'Name'` |
| `GetProperties` | antes de `:1033` | `'GetProperties'` |
| `GetFields` | **antes do `is TRttiInstanceType` check** (`:1053`) | `'GetFields'` |
| `GetMethods` | antes do `is` check (`:1067`) | `'GetMethods'` |
| `GetMethod` | antes das referencias a `FType.Name` (`:1074`) | `'GetMethod'` |

> **CRITICO para `GetFields`:** a guarda precede o `is TRttiInstanceType`.
> Records e enums com `FType <> nil` continuam retornando `nil` silenciosamente.

Cinco XMLDocs `<remarks>` nas declaracoes da `interface` (linhas `:176`, `:193`,
`:205`, `:373`, `:380`). Em `GetMethod` (`:380`) SOMAR ao `<remarks>` existente;
nao substituir.

### 2. `Test Shared/EclbrSystem/UScenarios.RTTI.pas`

- Novo `Scenario_NilHandle_AllMembers_Raises` — declara na `interface` perto de
  `:305-311`; implementa com cinco blocos try/except verificando mensagem por `Pos`.
- Desbloqueio D-44.6 em `Scenario_PointerType_ReferredType_Nil_ForBarePointer`
  (`:1254-1269`): remover comentario "NAO tocar"; substituir por asserção que
  espera `EModernRTTIError`; reescrever comentarios `:310-311` para citar "#49 resolvido".

### 3. Cascas de teste (uma linha cada)

**FPC** — apos `TestPointerType_ReferredType_Nil_ForBarePointer` (`:329-331`):
```pascal
published
procedure TestTModernRTTI.TestNilHandle_AllMembers_Raises;
begin
  Scenario_NilHandle_AllMembers_Raises;
end;
```

**Delphi** — apos `:364-366`:
```pascal
[Test]
procedure TestNilHandle_AllMembers_Raises;
begin
  Scenario_NilHandle_AllMembers_Raises;
end;
```

## Traps a evitar

- **NAO** inserir a guarda de `GetFields` APOS o `is TRttiInstanceType` check.
- **NAO** usar `{$IFDEF FPC}` no cenario — Pascal puro.
- **NAO** compilar `Source/*.pas` inteiro — 0 de 16 units compilam no FPC 3.2.2.
- **Limpar o diretorio `-FU` antes de recompilar** — FPC reutiliza `.ppu`.
- **NAO** omitir `GetMethod` (singular) — e o quinto membro medido.

## Checklist de aceitacao

- [ ] `grep -n 'SModernRTTINilHandle' Source/ModernSyntax.RTTI.pas` → 6 linhas (1 decl + 5 usos)
- [ ] `grep -c 'if FType = nil then' Source/ModernSyntax.RTTI.pas` → 5
- [ ] `GetFields` sobre record/enum com `FType <> nil` retorna `nil` (nao levanta)
- [ ] `Scenario_NilHandle_AllMembers_Raises` verde em FPC 3.2.2 x86_64
- [ ] `Scenario_PointerType_ReferredType_Nil_ForBarePointer` verde (sem "NAO tocar")
- [ ] Nenhum `{$IFDEF FPC}` novo em `UScenarios.RTTI.pas`
- [ ] PR body declara resultado i386 e Delphi (pelo autor humano)
- [ ] PR fecha `Closes #49`

## Fontes

- [task-input](pipeline-task-input.md) — briefing operacional completo do arquiteto
- [esp](pipeline-esp.md) — especificacao formal
- [plan](pipeline-plan.md) — plano de implementacao
