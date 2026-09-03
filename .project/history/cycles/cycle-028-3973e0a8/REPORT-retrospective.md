---
type: retrospective
kind: report
title: "Retrospective — ciclo 028 — loop infinito por spec sem qualificacao de OS em AC-10"
description: "Ciclo bloqueado em loop de 10+ iteracoes por AC-10 sem qualificacao de OS/ABI; implementacao correta em todas as voltas; nenhum mecanismo de parada automatica ativou."
cycle: "028"
agent: retrospective
workflow: equipe-feature
node: retrospective
resource: aefos://run/3973e0a8a9fb319c0e20e1154e93d8d3
generated:
  by: "equipe-feature@node:retrospective"
  at: "2026-09-03T00:00:00Z"
tags: [retrospective, cycle-028, loop, spec, architect, fpc, rtti, issue-13, blocked]
---

# Retrospective — Ciclo 028

## Status: CICLO BLOQUEADO — LOOP INFINITO

O ciclo 028 **não convergiu**. Ele rodou em loop por 10+ iterações completas
sem que nenhum mecanismo de parada automática interviesse. Nenhum PR foi aberto.
Todos os reports de ciclo estão presentes (`REPORT-architect`, `REPORT-planner`,
`REPORT-developer`, `REPORT-quality-review`, `REPORT-quality-test`,
`REPORT-quality-verify`), mas o ciclo terminou em estado `BLOCKED`, não em `DONE`.

---

## Iterações por lens

| Lens | Rejeições | Veredicto | Variação entre iterações |
|------|-----------|-----------|--------------------------|
| review | **9** | REJECTED em todas | Zero — diagnóstico byte-a-byte idêntico |
| test | **10** | REJECTED em todas | Zero — suite N:14 E:4 F:0 em todas |
| verify | **8** | REJECTED/BLOCKED em todas | Zero — mesmo 10/14 com mesma causa |
| implement | **9+** re-entradas | Sem defeito de código em nenhuma | Zero — código Pascal inalterado desde a 1ª |

Total conservador: **≥ 36 re-entradas de node** com progresso zero no artefato
causador (`esp.md` AC-10).

---

## Classificação de causa por rework

Todas as rejeições convergiram no mesmo par desde a 1ª iteração:

| Campo | Valor |
|-------|-------|
| `cause` | `spec` (review, test); `env` reclassificado para `spec` a partir da 2ª (verify) |
| `node_blamed` | `architect` — unânime nas 3 lentes em todas as iterações |
| Artefato causador | `esp.md` AC-10 — contagem "13/13" (deveria ser "14") e ausência de qualificação de OS (`x86_64-linux` vs `x86_64-win64`) |

### Raiz técnica

`Rtti.Invoke` livre no FPC 3.2.2 está implementada apenas para `x86_64-win64`
(Microsoft x64 ABI). Na fábrica (`x86_64-linux`, SysV AMD64 ABI), o backend
`SystemInvoke` não existe e a RTL levanta `ENotImplemented`. O dono mediu a
feature em Windows; o AC assumiu paridade de plataforma sem qualificá-la. A
implementação Pascal está correta e honra todos os D-13.1..D-13.13 — as 3
lentes confirmaram isso por escrito em todas as iterações. O defeito é
**exclusivamente editorial no spec**, não de código.

---

## Análise de custo

Cada rejeição re-roteia implement → review → test → verify. Com **≥ 36
re-entradas** de node:

- **Custo de rework = ≥ 9 passes completos de qualidade** além do 1º.
- Nenhum desses 9 passes adicionou informação nova; o diagnóstico era completo
  e idêntico desde a 1ª iteração.
- O `FLOW-FEEDBACK.md` acumula **18 achados independentes** documentando o loop
  e pedindo um gate de escalação — nenhum foi implementado durante o ciclo.

### Causa dominante: `spec` (e ausência de gate de flow)

A causa raiz é `spec` — um AC mal redigido. Mas o multiplicador de custo é
`flow`: a ausência de um mecanismo de parada automática transformou 1 defeito
editorial em ≥ 9 voltas completas. Um modelo mais forte no node `architect`
**não resolveria** este loop — o architect reemitiu os artefatos em cada volta
sem corrigir o AC-10, sugerindo que o gap não é de capacidade de modelo mas de
**ausência de constraint no gate que force a incorporação das correções
apontadas antes de reemitir**.

O lever correto é **flow/process**: gate de convergência que detecte N
rejeições consecutivas com mesmo `cause + node_blamed` e pause o ciclo.

---

## Recomendação — única, concreta, para o humano

**Implementar um gate de convergência no workflow `equipe-feature`:**

> Antes de re-disparar `implement` após uma rejeição com `cause: spec` ou
> `cause: env`, o orchestrator deve contar rejeições consecutivas com o mesmo
> par `(node, cause, node_blamed)` no arquivo `decisions-<lens>.md` do ciclo
> corrente. Se o par apareceu ≥ 3 vezes sem diff observável no AC apontado
> (comparação de hash do parágrafo do AC entre emissões do architect), o
> orchestrator **pausa** o ciclo e emite `AskUserQuestion` ao humano com as
> opções A/B/C mapeadas pela última rejeição. O ciclo só retoma após resposta
> humana explícita.

Limiar sugerido: **N = 3**. Isso teria evitado ≥ 27 das ≥ 36 re-entradas deste
ciclo. A implementação não requer alteração de modelo — é lógica de contagem no
orchestrator, aplicável a qualquer workflow com gate `plan-gate:on_reject`.

---

## Nota sobre PR

Nenhum PR foi aberto neste ciclo. Quando o ciclo convergir (após decisão humana
entre Opção A, B ou C documentadas em [decisions-review.md](decisions-review.md)
e [decisions-test.md](decisions-test.md)), o corpo do PR deverá incluir uma
seção **"## Rework analysis"** registrando:

- Que o bloqueio foi causado por AC-10 sem qualificação de OS, não por defeito
  de implementação.
- Qual opção (A/B/C) foi escolhida e como o AC foi ajustado.
- Referência a este retrospective para auditoria de custo.

---

## Nota sobre `FLOW-FEEDBACK.md`

O [FLOW-FEEDBACK.md](FLOW-FEEDBACK.md) contém 18 achados acumulados por todos
os nodes durante o loop. O primeiro achado (token GitHub sem escopo `read:project`)
é um problema de ambiente independente do loop principal e pode ser resolvido
separadamente: adicionar `Project number` ao `SKILL.md` e conceder escopo
`read:project` ao token de CI.
