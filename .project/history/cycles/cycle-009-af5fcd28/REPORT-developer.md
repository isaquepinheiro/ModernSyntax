---
type: cycle-report
kind: report
title: "REPORT-developer — cycle 009 (af5fcd28)"
description: "Developer entregou TModernRTTIMethod, TModernRTTIParameter e o split de backends RTTI; PTestRTTI x86_64 8/8 verde; M1 provada (exit=2); #35 fechada pela cirurgia do Fail."
cycle: "009"
agent: developer
workflow: equipe-feature
node: implement
resource: aefos://run/af5fcd28da98e98892fbe66e544b6b5c
tags: [cycle-009, developer, report, issue-25, modernrtti, pilar-4]
generated:
  by: "equipe-feature@node:implement"
  at: "2026-08-31T00:00:00Z"
---

# REPORT-developer — cycle 009 (af5fcd28)

## O que foi feito

### 1. Leitura das entradas

Lido [pipeline-task-input.md](pipeline-task-input.md), [pipeline-esp.md](pipeline-esp.md),
[pipeline-adr.md](pipeline-adr.md) e [pipeline-plan.md](pipeline-plan.md).
Os quatro slices do plan (S1 → S4) foram executados no mesmo commit-set,
seguindo a ordem que deixa o compilador falar em cada etapa.

### 2. Split arquitetural §7 aplicado

- `Source/ModernSyntax.RTTI.pas` virou casca pública sem `{$IFDEF}` em
  declaração de tipo. Único `{$IFDEF}` da unit mora na `uses` da
  `implementation`, selecionando `ModernSyntax.RTTI.Delphi` ou
  `ModernSyntax.RTTI.FPC`.
- `Source/ModernSyntax.RTTI.Delphi.pas` (**NOVO**) envolve
  `System.Rtti` direto; símbolos `TRttiField/TRttiMethod/TRttiParameter`
  confinados aqui.
- `Source/ModernSyntax.RTTI.FPC.pas` (**NOVO**) usa `vmtMethodTable` +
  `TObject.MethodAddress`; seis membros sem fonte levantam
  `EModernRTTIError` (D-25.4).

### 3. TModernRTTIMethod / TModernRTTIParameter entregues

- Oito membros de `TModernRTTIMethod`: `Name`, `Invoke<TSignature>`
  (dois overloads — instance/class), `GetParameters`, `ReturnType`,
  `IsConstructor`, `IsClassMethod`, `IsStatic`, `Visibility`.
- Dois membros de `TModernRTTIParameter`: `Name`, `ParamType`.
- `TModernRTTIVisibility` (enum portável).
- `TModernRTTIType.GetMethods` e `GetMethod` reais nos dois compiladores.
- XMLDoc declara a divergência de cobertura (Delphi: `public`+`published`;
  FPC: só `published`) — D-25.5.

### 4. TModernRTTIField migrado para o novo desenho

`strict private` neutro (`FOwner: TClass; FName: string; FToken: Pointer`),
factory `FromToken`. Sem `{$IFDEF}` no `strict private` — pré-condição
arquitetural resolvida.

### 5. Cirurgia do Fail — #35 fechada

`Test Shared/EclbrSystem/UScenarios.RTTI.pas` declara
`ETestScenarioFailed = class(Exception);` e `Fail` levanta essa classe.
Sob M1, `PTestRTTI` devolve exit=2 (antes: exit=0 sobre vermelho).

### 6. Fixture + três cenários + published tests

- Fixture: `TMethodBase` / `TMethodDerived` (só `published`), com
  contadores globais para efeito colateral observável em `Invoke`.
- Três cenários compartilhados sem `Assert` e sem `{$IFDEF FPC}`:
  `Scenario_GetMethods_CountsPublishedInherited_Exact`,
  `Scenario_GetMethod_ByName_FindsInherited`,
  `Scenario_Method_Invoke_NoArgs`.
- `Test FPC/EclbrSystem/UTestMS.RTTI.pas` e
  `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` receberam três published
  tests cada. Comentário stale do lado Delphi corrigido.

### 7. Validações executadas

- **FPC 3.2.2 x86_64**: `PTestRTTI` compila (1409 lines, 16 warnings) e
  passa (**8/8 tests, exit=0**).
- **M1 mutation**: substituindo `LCur := LCur.ClassParent;` por
  `LCur := nil;` — `TestGetMethods_CountsPublishedInherited_Exact` falha
  com `ETestScenarioFailed`, exit=2. Confirmado que #35 está fechada de
  fato.
- **M2 mutation (i386)**: **não executada na fábrica** — SKILL.md:122-124
  documenta que `ppc386` retorna 127. Fica com o autor.
- **Outros PTest*.lpr**: `PTestInvoker`, `PTestModernCallback`,
  `PTestAttributes` continuam compilando (defensivo — split RTTI não
  regrediu vizinhos).

### 8. Board avançado

`project-evolution.md` (linha 22): ciclo 009 avançou de 🔄 in-pipeline
para 🔄 in-review.

## Artefatos produzidos

| Artefato | Caminho |
|----------|---------|
| Implement report | [pipeline-implement-report.md](pipeline-implement-report.md) |
| Backend Delphi (novo) | `Source/ModernSyntax.RTTI.Delphi.pas` |
| Backend FPC (novo) | `Source/ModernSyntax.RTTI.FPC.pas` |
| Casca pública refatorada | `Source/ModernSyntax.RTTI.pas` |
| Cirurgia #35 + fixture + cenários | `Test Shared/EclbrSystem/UScenarios.RTTI.pas` |
| Published tests FPC | `Test FPC/EclbrSystem/UTestMS.RTTI.pas` |
| Published tests Delphi | `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` |
| Board atualizado | [../../../project-evolution.md](../../project-evolution.md) |
| Este relatório | REPORT-developer.md |

## Decisões técnicas do developer

### D-DEV.1 — `ReturnType`/`ParamType` retornam `PTypeInfo`, não `TModernRTTIType`

**Motivo:** records em Object Pascal (Delphi e FPC 3.2.2) **não aceitam
forward declaration mútua**. A cadeia
`TModernRTTIType.GetMethods → TModernRTTIMethod.ReturnType → TModernRTTIType`
é referência mútua entre records e força uma quebra na
tipagem-por-abstração.

**Escolha:** quebrar em `PTypeInfo`, primitivo portável já usado por
`TModernRTTI.GetType(ATypeInfo)`. Consumidor envolve de volta com
`TModernRTTI.GetType(Method.ReturnType)` quando quiser o handle rico.

**Descartadas:**
- Forward record declaration — não existe em Pascal.
- Transformar `TModernRTTIType` em classe — muda API pública (`GetType`
  passa a devolver instância), força ciclo de vida gerenciado, e o [esp](pipeline-esp.md)
  não pede isso.
- Wrapper `TModernRTTITypeRef` intermediário — adiciona indireção sem
  ganho vs. `PTypeInfo`, que é a primitiva canônica.

Nenhum critério do [esp](pipeline-esp.md) fixa o tipo de retorno dessas
duas propriedades. XMLDoc registra o padrão de envolver de volta.

### D-DEV.2 — `MethodTokenByName` devolve sentinel `Pointer(1)` no FPC

**Motivo:** `TObject.MethodAddress` sobe a cadeia sozinho e devolve o
`CodeAddress`, mas não devolve o `PVmtMethodEntry` correspondente. Como
`Invoke` usa apenas `FOwner + FName`, o token pode ser não-nulo
sem apontar para uma entry — é apenas um "achado ou não".

**Escolha:** devolver `Pointer(1)` como sentinel de "achado, sem entry",
e `nil` para "não achado". `MethodName` neste caso usa `FName` já
armazenado (não deref o token). Padrão local; nenhum consumidor externo
inspeciona esse valor.

### D-DEV.3 — Field FPC também levanta `EModernRTTIError`

**Motivo:** `vFieldTable` no FPC 3.2.2 **não é populada** para classes
gerais (medido no experimento local — a fixture `TFieldFixture` com
`published property Inner`, `published property Count` retornou
`vFieldTable = nil`). O ciclo 008 (não mergeado) mirava esse mesmo path
via `PVmt(...)^.vFieldTable`, mas o path não é confiável para classes
sem tratamento especial.

**Escolha:** mesma disciplina de D-25.4 aplicada a Field FPC — levanta
`EModernRTTIError` com mensagem instrutiva. A superfície pública existe
(§7 do API-MAP), mas o dado só está no Delphi. Nenhum consumidor
compartilhado exercita Field na FPC; o `TestGetFields_ReturnsFields`
existe apenas no `Test Delphi/`, sem versão compartilhada.

Se um ciclo futuro precisar de Field FPC real, o backend recebe a
implementação sem quebrar a assinatura pública — o portão de compilação
garante paridade.

## Próximo passo

O nó `review` recebe [pipeline-implement-report.md](pipeline-implement-report.md)
e valida contra o [pipeline-esp.md](pipeline-esp.md). Se rejeitar,
volto e endereço. Se aprovar, segue para `test`, `verify`, `committer`.

## Referências

- [pipeline-task-input.md](pipeline-task-input.md)
- [pipeline-esp.md](pipeline-esp.md)
- [pipeline-adr.md](pipeline-adr.md)
- [pipeline-plan.md](pipeline-plan.md)
- [pipeline-implement-report.md](pipeline-implement-report.md)
- [REPORT-planner.md](REPORT-planner.md)
- [REPORT-architect.md](REPORT-architect.md)
