---
type: committer-report
kind: artifact
title: "Committer-report — cycle 015 / issue #42 — TModernVisibility"
description: "Release receipt: branch pushed, PR #47 aberto, commit a6183c40b0ea3fa760e2a3dbf12a1487b17485a9."
cycle: "015"
agent: release
workflow: equipe-feature
node: release
resource: aefos://run/bb89abe1aa455add801745cb2a527e99
status: stable
tags: [committer-report, cycle-015, issue-42, modernrtti, fpc, delphi, visibility, tmodernvisibility]
generated:
  by: "equipe-feature@node:release"
  at: "2026-09-01T00:00:00Z"
---

# Committer-report — cycle 015 / issue #42

## Branch e commit

| Chave | Valor |
|-------|-------|
| Work branch | `aefos/cycle-bb89abe1-maestro-repo-isaquepinheiro-modernsyntax` |
| Base | `main` |
| Commit sha | `a6183c40b0ea3fa760e2a3dbf12a1487b17485a9` |
| PR | [#47 — feat(rtti): TModernVisibility público, fecha vazamento Method.Visibility, adiciona Property.Visibility](https://github.com/isaquepinheiro/ModernSyntax/pull/47) |

## Commit manifest

```commit-manifest
a6183c40b0ea3fa760e2a3dbf12a1487b17485a9
Source/ModernSyntax.RTTI.Delphi.pas
Source/ModernSyntax.RTTI.FPC.pas
Source/ModernSyntax.RTTI.pas
Test Delphi/EclbrSystem/UTestMS.RTTI.pas
Test FPC/EclbrSystem/UTestMS.RTTI.pas
Test Shared/EclbrSystem/UScenarios.RTTI.pas
```

## O que este commit carrega

### Código (feat issue #42)

| Arquivo | Ação |
|---------|------|
| `Source/ModernSyntax.RTTI.pas` | +`TModernVisibility = (mvPrivate, mvProtected, mvPublic, mvPublished)` declarado antes de `TModernRTTIField`; troca de tipo de retorno em `TModernRTTIMethod.Visibility` de `TMemberVisibility` para `TModernVisibility`; +`TModernRTTIProperty.Visibility: TModernVisibility` (decl + delegação ao backend) |
| `Source/ModernSyntax.RTTI.Delphi.pas` | `MethodVisibility` reescrita com `case` de 4 ramos qualificados; +`PropertyVisibility(AToken: Pointer): TModernVisibility` com `case` de 4 ramos — sem `mvAutomated`, sem resourcestring nova |
| `Source/ModernSyntax.RTTI.FPC.pas` | `MethodVisibility` continua levantando; `SFPCNoVisibility` reescrita com raiz `vmtMethodTable`+D-25; +`PropertyVisibility(AToken: Pointer): TModernVisibility` com `case` de 4 ramos sobre `TRttiProperty.Visibility` — sem `mvAutomated`, sem raise, sem resourcestring nova |
| `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | +3 cenários: `Scenario_Method_Visibility_FPC_Raises` (+ assert mensagem contém `vmtMethodTable`), `Scenario_Method_Visibility_Delphi_Returns_mvPublished`, `Scenario_Property_Visibility_Returns_mvPublished` (cross-compiler) — zero `{$IFDEF}`, zero `Assert`, `Fail(...)` sempre |
| `Test FPC/EclbrSystem/UTestMS.RTTI.pas` | +2 `published` wrappers FPCUnit: `TestMethod_Visibility_FPC_Raises`, `TestProperty_Visibility_Returns_mvPublished` |
| `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` | +2 `[Test]` wrappers DUnitX: `TestMethod_Visibility_Delphi_Returns_mvPublished`, `TestProperty_Visibility_Returns_mvPublished` |

### Bundle OKF (`.project/`)

- `.project/history/cycles/cycle-015-bb89abe1/` — 7 REPORT-*.md do ciclo 015 (architect, developer, planner, quality-review, quality-test, quality-verify, release)
- `.project/history/cycles/cycle-014-f42b5faa/` — 11 artefatos do ciclo 014 (pipeline durável)
- `.project/project-evolution.md` — marcador ciclo 015 em `🔄 in-review` (flip para `📤 PR aberto` feito após o commit — veja seção Board abaixo)
- `.project/SKILL.md` — atualizado com descobertas do ciclo

`.project/pipeline/` foi EXCLUÍDO do commit (estado de trabalho — evita conflito entre ciclos).

## Validações antes do commit

- Todos os 10 CAs do ESP verificados nos nós `review` (APROVADO), `test` (APPROVED) e `verify` (PASSED).
- FPC 3.2.2 x86_64: 30/30 testes verdes, exit=0 (baseline era 28; +2 novos cenários).
- Mutação CA-9 verificada: trocar `PropertyVisibility` FPC por `Result := mvPrivate` → `TestProperty_Visibility_Returns_mvPublished` cai com `exit=2`. Revertido; rebuild verde confirmado.
- Regressão: `PTestInvoker` (450 linhas, 0 errors) e `PTestModernCallback` (513 linhas, 0 errors).
- Guardrail CA-7: `grep TMemberVisibility Source/ModernSyntax.RTTI.pas` → zero hits fora de XMLDoc.
- Guardrail CA-5: zero `{$IFDEF}` em `UScenarios.RTTI.pas`.
- Guardrail CA-4: zero `mvAutomated` em `Source/`.

## Board

Após o commit, o marcador do ciclo 015 / issue #42 em `.project/project-evolution.md`
foi flipado de `🔄 in-review` para `📤 PR aberto — [#47](https://github.com/isaquepinheiro/ModernSyntax/pull/47)`.
Este arquivo fica fora do commit de código; o nó `bundle-commit` o carrega
num segundo commit nesta mesma branch.

## Itens abertos (limitações de ambiente)

- **Delphi build (CA-8 do ESP):** fábrica sem `dcc32`. `case` sem `else` garante erro em build time se Delphi tiver valor extra. Confirmar no ambiente Delphi do autor.
- **FPC i386:** fábrica é x86_64-linux. Código novo é puramente `case`+enum, sem aritmética de ponteiro. Autor confirma no Windows se necessário.

## Próximos passos

1. **Autor:** compilar Delphi e declarar resultado no PR body.
2. **Revisor humano:** acessar [PR #47](https://github.com/isaquepinheiro/ModernSyntax/pull/47), revisar, aprovar/mergear para `main`.
3. **`bundle-commit`:** segundo commit com board atualizado e pipeline durável.
