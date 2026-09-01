---
type: cycle-report
kind: report
title: "REPORT — architect (cycle 012, issue #27)"
description: "Arquiteto derivou esp/adr/plan/task-input do relatorio de investigacao PRESENTE da issue #27: cinco properties alias no TModernRTTITypeHelper existente + Parameters em TModernRTTIMethod entregam a issue; zero enumerator/collection novo; Types delegado para a #28; scope=fits."
status: stable
cycle: "012"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/d3f7942e59d0ba69094d93420fef84db
tags: [modernrtti, issue-27, architect, cycle-012, report, enumerators]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-08-31T00:00:00Z"
---

# REPORT — architect (cycle 012)

## Demanda

Issue **#27** — *Enumerators nas coleções: `for..in` sobre `Fields`,
`Properties`, `Methods`, `Parameters`, `Attributes` e `Types`.*

## Estado do relatório de investigação

**PRESENT.** Fonte: comentário na issue #27 do
`isaquepinheiro/ModernSyntax`, run `9db5013b320820890838e1578fb0df4f`.
Duas voltas fechadas (humano + agente). O ADR **deriva** dele — não há
divergência de mérito.

## O que decidi (restatement, sem reabertura)

- **Cinco properties alias no `TModernRTTITypeHelper` existente e no
  `TModernRTTIMethod`**, delegando aos `Get*` que já devolvem
  `TArray<T>`. `for..in` sobre `TArray<T>` já compila e roda nos dois
  compiladores/bitness (medido M-A do relatório).
- **Zero enumerator/collection novo.** `Source/` tem zero
  `GetEnumerator` hoje; 12 records novos seriam a maior expansão de
  superfície pública do framework sem entregar nada que `for..in
  TArray<T>` já não entregue.
- **`Types` fora**, delegada à issue **#28** (aberta). Registrar no PR
  a nota para a #28 nascer sabendo: expor `property Types` na mesma
  passada.
- **`Attributes` só por-tipo**, via caminho (a): `uses
  ModernSyntax.Attributes` na `interface` de `RTTI.pas`;
  `TModernRTTITypeHelper.GetAttributes` chama
  `ModernAttributes.GetAttributes(FType.Handle)` direto.
- **`Parameters` no FPC continua levantando `EModernRTTIError`**
  (D-26). A property é alias puro; XMLDoc obrigatório declara em voz
  alta.
- **Testes**: sete cenários compartilhados (`UScenarios.RTTI.pas`),
  zero `{$IFDEF}` (CA-5); padrão "dois cenários distintos + duas
  cascas" da #25 para o par `Parameters`. Casca FPC publica seis
  (cinco comuns + `RaisesOnFPC`); casca Delphi publica seis (cinco
  comuns + `IteratesRealParameters`).
- **`AssertException` NÃO usar** — símbolo não existe no repo (grep
  zero). Padrão real é try/except + `Fail(...)`
  (`UScenarios.RTTI.pas:315-323`).
- **Mutação obrigatória**: `read GetFields` trocado por
  `read GetFieldsNil` (função temporária local que retorna `nil`) →
  `Scenario_Fields_ForIn_IteratesFields` fica vermelho, runner
  devolve `exit != 0`. Reverter antes de commitar.

## Escopo do ciclo

**scope: `fits`.** Uma única entrega:

- **Test 1 (size):** implementação é 4 properties + 1 método privado
  (5 linhas cada) + 1 property com XMLDoc + 1 aresta em `uses`. Testes
  são 7 procedures pequenas em um arquivo + 6+6 wrappers de uma linha.
  Cabe folgado num único ciclo de implement. Não exigiria mais que os
  ~2 slices do plan.
- **Test 2 (independence):** as duas slices do plan **não** são
  entregáveis isoladamente — Slice 1 sem Slice 2 fica sem prova (e
  sem cenário de coleção vazia); Slice 2 sem Slice 1 nem compila. É
  uma demanda única em passos ordenados, não duas issues.

Como não é `split`, não escrevi `split-proposal.md`.

## Artefatos entregues

- [esp](pipeline-esp.md) — critérios formais e checklist (objetivo,
  escopo, regras, CA, restrições, riscos).
- [adr](pipeline-adr.md) — decisões nos termos do relatório de
  investigação; o que foi descartado e a medição que derrubou; regras
  registradas para próximos ciclos.
- [plan](pipeline-plan.md) — duas slices ordenadas: (1) properties na
  unit pública + `uses ModernSyntax.Attributes`; (2) sete cenários +
  wrappers das cascas + mutação obrigatória.
- [task-input](pipeline-task-input.md) — handoff operacional com
  checklist de aceitação, comandos de verificação e nota para a #28.

## Observações para o próximo nó

- **Delphi não medido** para a nova property (evidência forte por
  analogia com as seis já no helper). Primeiro passo do build Delphi:
  confirmar. Se falhar, investigar isolado — não há alternativa
  contida nas slices porque não há genérico novo (todas as properties
  devolvem `TArray<T>` já parametrizado por membros existentes).
- **Ciclo `RTTI.pas ↔ Attributes.pas`** não é esperado
  (`Attributes.pas` não importa `RTTI.pas`), mas é a **primeira coisa
  a verificar** ao compilar `PTestRTTI` na Slice 1.
- **Mutação de `Fields → nil`** é o único gate mecânico. Se
  `Scenario_Fields_ForIn_IteratesFields` **não** ficar vermelho sob
  mutação, o teste é decorativo e a slice não fecha.
