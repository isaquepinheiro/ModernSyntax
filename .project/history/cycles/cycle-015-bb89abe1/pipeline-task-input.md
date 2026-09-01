---
type: task-input
kind: artifact
title: "TASK-INPUT — Implementar TModernVisibility, fechar vazamento em Method e adicionar Property.Visibility (issue #42)"
description: "Handoff operacional para o implementador: enum publico TModernVisibility na casca; troca de tipo em TModernRTTIMethod.Visibility; adicao de TModernRTTIProperty.Visibility; backends Delphi (case explicito em Method e Property, mvAutomated levanta) e FPC (Method continua levantando com SFPCNoVisibility reescrita, Property devolve dado real por case explicito); tres cenarios em UScenarios.RTTI.pas (par Method FPC-only/Delphi-only + Property cross-compiler); mutacao de sanidade obrigatoria; PR unico fechando #42; compilar FPC nos dois bitness."
status: draft
cycle: "015"
agent: architect
workflow: equipe-feature
node: plan-gate:on_reject
resource: aefos://run/bb89abe1aa455add801745cb2a527e99
tags: [modernrtti, task-input, issue-42, fpc, delphi, visibility, feature]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-09-01T00:00:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — TModernVisibility (issue #42)"
  - id: adr
    resource: "adr.md"
    title: "ADR — TModernVisibility (issue #42)"
  - id: plan
    resource: "plan.md"
    title: "PLAN — TModernVisibility em 3 slices sequenciais (issue #42)"
---

# TASK-INPUT — issue #42 (TModernVisibility)

## Titulo (para commit / PR)

`feat(rtti): TModernVisibility publico; fecha vazamento em Method.Visibility, adiciona Property.Visibility (#42)`

## Tipo / labels

- **Tipo:** `feature`.
- **Labels GitHub:** `feature`, `aefos:running` (removida no fechamento),
  parent link `Parte de #29`.
- **Milestone:** o mesmo do parent #29 (se houver).

## Escopo operacional

Ler [`esp.md`](pipeline-esp.md) §2 para o escopo detalhado, [`adr.md`](pipeline-adr.md)
para o racional das nove decisoes (D-42.1..D-42.9), e [`plan.md`](pipeline-plan.md)
para a sequencia das 3 slices.

**Sintese executiva:**

1. **Casca** (`Source/ModernSyntax.RTTI.pas`): declarar
   `TModernVisibility = (mvPrivate, mvProtected, mvPublic, mvPublished);`
   antes de `TModernRTTIField`; trocar tipo de retorno de
   `TModernRTTIMethod.Visibility`; adicionar
   `TModernRTTIProperty.Visibility`.
2. **Backend Delphi** (`Source/ModernSyntax.RTTI.Delphi.pas`):
   `MethodVisibility` com `case` explicito de **exatamente 4 ramos**
   (`mvPrivate`, `mvProtected`, `mvPublic`, `mvPublished`); novo
   `PropertyVisibility(AToken: Pointer)` com o mesmo `case` de 4 ramos.
   **Sem ramo `mvAutomated`**, sem resourcestring nova. Se o Delphi
   tiver valor adicional, o compilador acusa no primeiro build.
3. **Backend FPC** (`Source/ModernSyntax.RTTI.FPC.pas`):
   `MethodVisibility` continua levantando (reescrever `SFPCNoVisibility`
   segundo D-42.5); novo `PropertyVisibility(AToken: Pointer)` com `case`
   de **exatamente 4 ramos** (`mvPrivate`, `mvProtected`, `mvPublic`,
   `mvPublished`) — **sem ramo `mvAutomated`**, identificador inexistente
   em `rtti.pp:308` do FPC 3.2.2 (**sem raise, sem resourcestring nova**).
4. **Cenarios** (`Test Shared/EclbrSystem/UScenarios.RTTI.pas`): 3
   cenarios novos com fixtures locais; classe de fixture do cenario
   cross-compiler tem propriedade `published` em classe `{$M+}`.
5. **Cascas de teste** (`Test FPC/.../UTestMS.RTTI.pas` e
   `Test Delphi/.../UTestMS.RTTI.pas`): publicar cenarios conforme a
   matriz do ESP §2.
6. **Mutacao de sanidade** (`CA-9`): trocar `case` de `PropertyVisibility`
   por valor fixo, provar vermelho, reverter, registrar no PR.

## Checklist de aceitacao (copiar para o PR body)

- [ ] `TModernVisibility = (mvPrivate, mvProtected, mvPublic, mvPublished);`
  declarado antes de `TModernRTTIField` na `interface`.
- [ ] `TModernRTTIMethod.Visibility: TModernVisibility` (decl + impl).
- [ ] `TModernRTTIProperty.Visibility: TModernVisibility` (decl + impl).
- [ ] Backend Delphi: `case` explicito em `MethodVisibility` e em
  `PropertyVisibility` — **exatamente 4 ramos** (`mvPrivate`,
  `mvProtected`, `mvPublic`, `mvPublished`), sem ramo `mvAutomated`,
  sem resourcestring nova, sem `else` levantando. Se o Delphi tiver
  valor adicional, o compilador acusa no primeiro build.
- [ ] Backend FPC: `MethodVisibility` levanta em ambos os fluxos;
  `SFPCNoVisibility` reescrita conforme D-42.5.
- [ ] Backend FPC: `PropertyVisibility` com `case` de **exatamente 4
  ramos** (`mvPrivate`, `mvProtected`, `mvPublic`, `mvPublished`) — **sem
  ramo `mvAutomated`** (identificador inexistente em `rtti.pp:308` do FPC
  3.2.2; inclui-lo nao compila), sem `else` levantando, **sem raise
  incondicional**.
- [ ] `grep -rn "TMemberVisibility" Source/ModernSyntax.RTTI.pas` retorna
  zero fora da `uses` da `implementation`.
- [ ] `Scenario_Method_Visibility_FPC_Raises` publicado apenas na casca FPC.
- [ ] `Scenario_Method_Visibility_Delphi_Returns_mvPublished` publicado
  apenas na casca Delphi.
- [ ] `Scenario_Property_Visibility_Returns_mvPublished` publicado nas
  DUAS cascas.
- [ ] Fixture do cenario cross-compiler inclui propriedade `published`
  em classe `{$M+}`.
- [ ] Mutacao de sanidade executada e registrada no PR body.
- [ ] Compila FPC 3.2.2 x86_64 verde (`rm -rf out` antes).
- [ ] Compila FPC 3.2.2 i386 verde (`rm -rf out` antes).
- [ ] PR body declara explicitamente o que foi compilado (SKILL §"What
  a PR must declare"): "compilado em FPC 3.2.2 x86_64 e i386; nao
  compilado em Delphi neste ambiente — validacao Delphi cabe ao autor".
- [ ] XMLDoc de `TModernRTTIMethod.Visibility` mantem clausula "no FPC
  levanta"; XMLDoc de `TModernRTTIProperty.Visibility` **nao** carrega.

## Arquivos provavelmente impactados

| Arquivo | Natureza |
|---------|----------|
| `Source/ModernSyntax.RTTI.pas` | edicao (enum + 2 assinaturas + 1 novo) |
| `Source/ModernSyntax.RTTI.Delphi.pas` | edicao |
| `Source/ModernSyntax.RTTI.FPC.pas` | edicao + reescrita de resourcestring |
| `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | edicao (3 cenarios novos) |
| `Test FPC/EclbrSystem/UTestMS.RTTI.pas` | edicao (2 metodos published) |
| `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` | edicao (2 metodos [Test]) |

Nenhum arquivo novo. Nenhum arquivo removido.

## Convencoes que governam a implementacao

- D-25.1 (sem `{$IFDEF}` em declaracao de tipo publico).
- D-25.4 (governa **apenas** `MethodVisibility` FPC).
- CA-5 (zero `{$IFDEF}` em `UScenarios.RTTI.pas`).
- Padrao "dois cenarios distintos + duas cascas" (governa **apenas** o
  par de Method).
- `Fail(...)` sempre; **nunca `Assert`**.
- `case` explicito; **nunca `TModernVisibility(Ord(...))`**.
- Prefixos: `mv` (enum values), `L` (locais), `A` (parametros); XMLDoc
  `///` em membros publicos novos ou alterados.

## Notas para o PR

- **Fechamento:** `Closes #42`. Manter link `Parte de #29`.
- **Nao atualiza API-MAP** por default (ver D-42, pergunta em aberto).
  Se o revisor pedir, e um commit adicional no mesmo PR.
- **Mutacao registrada no PR body** com o diff aplicado (antes/depois)
  e o log da suite mostrando vermelho, seguido do log mostrando verde
  apos reverter.
