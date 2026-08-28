---
type: spec
kind: artifact
title: "ESP — Conformidade de nomes: variáveis locais em ModernSyntax.Invoker.pas"
description: "Renomear as 4 variáveis locais de ModernSyntax.Invoker.pas para o padrão L+PascalCase vigente no projeto."
status: draft
cycle: "007"
agent: architect
workflow: equipe-chore
node: architect
resource: aefos://run/3ac50e14ab113cabde9efa632dc2fccf
tags: [chore, naming-convention, invoker, modernrtti, issue-23]
generated:
  by: "equipe-chore@node:architect"
  at: "2026-08-28T00:00:00Z"
sources:
  - id: conventions
    resource: "/analysis/05-conventions.md"
    title: "05 Conventions — ModernSyntax"
---

# ESP — Conformidade de nomes: variáveis locais em ModernSyntax.Invoker

## 1. Objetivo

Eliminar as 4 variáveis locais não conformes em
`Source/ModernSyntax.Invoker.pas`, aplicando o prefixo `L` + PascalCase
exigido pela [convenção do projeto](/analysis/05-conventions.md) (§1.3).

Nenhum comportamento, assinatura pública ou teste é alterado. A mudança
é exclusivamente de nomeação.

## 2. Escopo

### 2.1 Dentro do escopo

- Renomear `addr` → `LAddress` e `m` → `LMethod` nos dois overloads de
  `Invoke<TSignature>` em `Source/ModernSyntax.Invoker.pas`
  (linhas 75-77 e 95-97).
- Verificar que os 7 testes de `Test FPC/EclbrSystem/PTestInvoker.lpr`
  compilam e passam com zero falhas no FPC 3.2.2 x86_64.

### 2.2 Fora do escopo

- Qualquer outra unit além de `ModernSyntax.Invoker.pas`.
- Alteração de comportamento, assinatura ou API pública.
- Criação ou modificação de testes.
- Correção do ADR faltante do ciclo do Pilar 3 (observação secundária
  da issue; endereçada separadamente).

## 3. Regras de negócio

**RN-1 — Prefixo obrigatório.** Toda variável local de rotina leva
prefixo `L` seguido de nome descritivo em PascalCase (ex.: `LAddress`,
`LMethod`). Abreviações de uma letra (`m`, `addr`) não são permitidas.
Medido em `Source/ModernSyntax.Objects.pas` (padrão: `LType`,
`LInstance`, `LConstructor`) e nas demais três units ModernRTTI
(Callback, RTTI, Attributes — todas 100% conformes).

**RN-2 — Escopo unitário.** A issue nº 23 mede exatamente 4 locais fora
do padrão, todos em Invoker. Nenhuma outra unit é tocada.

## 4. Critérios de aceitação

- [ ] Zero variáveis locais sem prefixo `L` em `ModernSyntax.Invoker.pas`.
- [ ] `Test FPC/EclbrSystem/PTestInvoker.lpr` compila e executa
      com **7 testes, 0 falhas** no FPC 3.2.2 x86_64 (build limpo
      conforme [SKILL](/SKILL.md)).
- [ ] Nenhuma outra unit modificada (`git diff --name-only` mostra
      somente `Source/ModernSyntax.Invoker.pas`).

## 5. Restrições

- Compilação Delphi permanece com o autor humano (sem `dcc32` na
  fábrica — ver [SKILL](/SKILL.md)).
- Verificação i386 também fica com o autor; a fábrica só tem
  x86_64-linux.

## 6. Riscos

Risco nulo. O rename é mecânico, totalmente local e não altera semântica.
Os 7 testes existentes cobrem o comportamento do Invoker.
