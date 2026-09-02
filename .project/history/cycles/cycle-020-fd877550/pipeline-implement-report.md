---
type: implement-report
kind: artifact
title: "IMPLEMENT-REPORT — issue #49: contrato unico de handle nil em TModernRTTIType (Name, GetProperties, GetFields, GetMethods, GetMethod)"
description: "Implementacao entregue em slice unico: resourcestring SModernRTTINilHandle + cinco guardas identicas em ModernSyntax.RTTI.pas, XMLDocs remarks nas cinco declaracoes, cenario compartilhado Scenario_NilHandle_AllMembers_Raises com verificacao de mensagem, desbloqueio da divida D-44.6 em Scenario_PointerType_ReferredType_Nil_ForBarePointer, duas cascas de uma linha (FPC e Delphi); build FPC 3.2.2 x86_64 verde na fabrica, 42 testes (0 falhas, 0 erros) — TestNilHandle_AllMembers_Raises presente."
status: stable
cycle: "020"
agent: developer
workflow: equipe-bug
node: implement
resource: aefos://run/fd87755097391831d283adc83e6b8813
tags: [modernrtti, implement-report, issue-49, bug, nil-handle, fpc, delphi]
generated:
  by: "equipe-bug@node:implement"
  at: "2026-09-02T00:00:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — issue #49"
  - id: adr
    resource: "adr.md"
    title: "ADR — issue #49"
  - id: plan
    resource: "plan.md"
    title: "PLAN — issue #49"
  - id: task-input
    resource: "task-input.md"
    title: "TASK-INPUT — issue #49"
  - id: skill
    resource: "/SKILL.md"
    title: "SKILL — toolchain e traps"
---

# IMPLEMENT-REPORT — issue #49

## O que mudou

Contrato unico de handle nil em `TModernRTTIType` (cinco membros) conforme
[esp](pipeline-esp.md), [adr](pipeline-adr.md), [plan](pipeline-plan.md) e [task-input](pipeline-task-input.md).
Sobre um handle com `IsNil = True`, os membros `Name`, `GetProperties`,
`GetFields`, `GetMethods` e `GetMethod` passam a levantar
`EModernRTTIError.CreateFmt(SModernRTTINilHandle, ['<membro>'])` em vez de
`EAccessViolation` (quatro) ou vazio silencioso (`GetFields`).

## Arquivos modificados

| Arquivo | Mudanca |
|---------|---------|
| `Source/ModernSyntax.RTTI.pas` | Nova `resourcestring SModernRTTINilHandle` no bloco existente (agora `:892`). Cinco guardas `if FType = nil then raise EModernRTTIError.CreateFmt(SModernRTTINilHandle, ['<membro>'])` em `TModernRTTIType.Name`, `TModernRTTIType.GetProperties`, `TModernRTTIType.GetFields` (**antes** do `is TRttiInstanceType` check — ADR D-49.4), `TModernRTTITypeHelper.GetMethods` (antes do `is` check e antes do `raise SModernRTTIGetMethodsNotClass` que usa `FType.Name`), `TModernRTTITypeHelper.GetMethod` (antes das duas referencias a `FType.Name` nos `raise`). Cinco `<remarks>` XMLDoc: bloco novo em `Name` (que so tinha `<summary>`); paragrafo adicional dentro do `<remarks>` existente em `GetProperties`, `GetFields`, `GetMethods` e `GetMethod` — este ultimo com a nota SOMANDO ao texto pre-existente sobre `MethodAddress`/D-25.3, nao substituindo. |
| `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | Novo `Scenario_NilHandle_AllMembers_Raises` (declaracao na `interface` + implementacao no fim do arquivo). Constroi o handle pelo caminho publico (`TModernRTTIContext.Create` + `FindType('TipoQueNaoExiste_Issue49')`), verifica pre-condicao `IsNil = True`, e afirma `EModernRTTIError` nos cinco membros com verificacao (via `Pos(...)`) de que a mensagem cita o nome do membro chamado (B-49.2). Desbloqueio da divida D-44.6/R-4 em `Scenario_PointerType_ReferredType_Nil_ForBarePointer`: comentario "NAO tocar em `LReferred.Name`" removido; nova asserção `try LReferred.Name except on EModernRTTIError do LRaised := True end`. Comentarios `D-44.6 / R-4` em `:310-311` e em `:1259-1265` reescritos citando #49 como *resolvido* (nao como bloqueio). |
| `Test FPC/EclbrSystem/UTestMS.RTTI.pas` | `published TestNilHandle_AllMembers_Raises` de uma linha delegando ao cenario compartilhado (padrao D-7 "um cenario, duas cascas"). |
| `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` | `[Test] TestNilHandle_AllMembers_Raises` de uma linha delegando ao cenario compartilhado. |
| `.project/project-evolution.md` | Marker do ciclo 020 (linha 31) avancado de `🔄 in-pipeline` para `🔄 in-review`. |

## Decisoes tecnicas

- **XMLDoc — como somar ao `<remarks>` existente.** Para `GetProperties`,
  `GetFields`, `GetMethods` e `GetMethod`, optei por **paragrafo adicional
  dentro do `<remarks>` existente** (separado por linha em branco), em vez
  de um segundo bloco `<remarks>`. XMLDoc convencional usa apenas um
  `<remarks>` por membro; a instrucao do [esp](pipeline-esp.md) §2.1 ("adicionar
  (ou somar ao existente)") acomoda esta forma, e ela e a minimamente
  invasiva. `Name` recebeu um `<remarks>` novo — nao tinha nenhum antes.
- **`GetFields` para tipos nao-classe — preservado.** A guarda de nil precede
  o `is TRttiInstanceType` check (ESP §2.1, ADR D-49.4, plan Passo 1 item 4).
  Handles validos de records/enums continuam retornando `nil`
  silenciosamente. Preservacao verificada indiretamente pelo build/teste
  (nenhum dos 41 cenarios pre-existentes que exercitam esse caminho
  quebrou — 42/42 verdes).
- **Convencao do arquivo de cenarios — `Fail(...)` em vez de `raise
  ETestScenarioFailed.Create(...)`.** O [task-input](pipeline-task-input.md) mostra
  `raise ETestScenarioFailed.Create(...)`; o arquivo vivo usa `Fail(...)`
  (declarado em `UScenarios.RTTI.pas:381`, que internamente levanta
  `ETestScenarioFailed` por D-25.7). Segui a convencao do arquivo —
  resultado observavel identico, padrao consistente com os demais 41
  cenarios (101 usos de `Fail(...)` medidos).
- **Pre-condicao explicita no cenario.** Alem das cinco asserções, o cenario
  faz `if not LType.IsNil then Fail(...)` antes de comecar — se algum dia
  `FindType` mudar de comportamento sobre nome inexistente, a falha aponta
  a pre-condicao, nao um dos cinco membros.

## Validacoes rodadas

Comandos executados na fabrica x86_64 (SKILL.md § "FPC / Lazarus"):

```
rm -rf /tmp/fpcbuild && mkdir -p /tmp/fpcbuild
fpc -Mdelphi \
    -Fu"Source" \
    -Fu"Test Shared/EclbrSystem" \
    -Fu"Test FPC/EclbrSystem" \
    -FU/tmp/fpcbuild -FE/tmp/fpcbuild \
    "Test FPC/EclbrSystem/PTestRTTI.lpr"
/tmp/fpcbuild/PTestRTTI --all -a --format=plain
```

Resultados:

- **Compilacao FPC 3.2.2 x86_64:** verde. `4595 lines compiled, 1.2 sec`.
  10 warnings + 6 notes — todos pre-existentes (`Unit "Rtti" is
  experimental`, `function result variable of a managed type does not seem
  to be initialized` nos backends, `unreachable code` em
  `ModernSyntax.Invoker.pas`, warnings de `generics.dictionaries.inc`,
  notes de inline / never used em `generics.collections.pas`).
- **Suite FPCUnit x86_64:** `Number of run tests: 42 | Number of errors: 0 |
  Number of failures: 0`. `TestNilHandle_AllMembers_Raises` presente e
  verde (ultimo na lista). Contagem passou de 41 -> 42.
- **Check rapido do [plan](pipeline-plan.md) "Criterios de done":**
  - `grep -c 'if FType = nil then' Source/ModernSyntax.RTTI.pas` → **5**
    (exatamente cinco guardas — bate).
  - `grep -n 'SModernRTTINilHandle' Source/ModernSyntax.RTTI.pas` → 6
    linhas (1 declaracao em `:892` + 5 usos em `:1044`, `:1056`, `:1078`,
    `:1094`, `:1103` — bate com o esperado do plan: >= 6).

**i386 e Delphi:** nao compilados na fabrica (sem `ppc386`, sem `dcc32` —
SKILL.md § "FPC / Lazarus" confirma ausencia de cross-compiler i386;
SKILL.md § "Delphi" confirma ausencia de instalacao Delphi). Ficam para o
autor humano; o PR body precisa declarar o resultado dos dois, conforme
SKILL.md § "What a PR must declare" e checklist do
[task-input](pipeline-task-input.md).

## Caveats

- **`GetFields` sobre record/enum valido — cobertura implicita.** O contrato
  preservado (retorno `nil` silencioso quando `FType` e nao-classe) e
  garantido pela ordem guarda-antes-de-`is`, mas nenhum cenario existente
  afirma explicitamente esse caminho para um handle valido de record/enum.
  O checklist de aceitacao do [task-input](pipeline-task-input.md) autoriza
  verificacao "manualmente ou por cenario existente de iteracao vazia" —
  aqui, a preservacao emerge do fato de nenhum dos 41 cenarios pre-existentes
  ter quebrado. Um cenario dedicado esta EXPLICITAMENTE fora do escopo da
  issue #49 (ESP §2.5) — nao adicionado.
- **XMLDoc como paragrafo adicional.** Se o gerador de docs do projeto
  concatenar apenas o primeiro paragrafo do `<remarks>`, a nota nova ficara
  visivel apenas em `Name` (bloco novo) — nos outros quatro, aparece so na
  documentacao completa. Se essa for a expectativa, o revisor pode pedir
  para migrar para um segundo bloco `<remarks>` por membro.
- **Warning novo em `ModernSyntax.RTTI.pas:1070`** (`function result
  variable of a managed type does not seem to be initialized` em
  `TModernRTTIType.GetFields`) — provocado pelo `Result := nil` continuar
  no path `not (FType is TRttiInstanceType)` com o `Exit` explicito, mesma
  familia dos warnings ja existentes nos backends. Nao afeta comportamento
  e e consistente com o codigo do arquivo.

## Sources compiladas

- Contrato governado por [esp](pipeline-esp.md) e [adr](pipeline-adr.md).
- Execucao seguiu [plan](pipeline-plan.md) e [task-input](pipeline-task-input.md) sem desvios
  materiais (uma decisao de estilo em XMLDoc, uma de convencao em `Fail`).
- Toolchain e traps: [/SKILL.md](/SKILL.md).
