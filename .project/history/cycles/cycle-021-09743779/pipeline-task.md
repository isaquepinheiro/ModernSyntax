---
type: task
kind: artifact
title: "TASK-021 — TModernRTTIType.Attributes: guarda nil-handle (issue #56)"
description: "Guarda em PropAttributes + uniformizacao de cinco blocos (Pos para igualdade estrita) + sexto bloco Attributes em Scenario_NilHandle_AllMembers_Raises. Dois arquivos, commit unico."
cycle: "021"
agent: planner
workflow: equipe-bug
node: task
resource: aefos://run/09743779c7c9860b5fa380f6979d94ca
status: draft
tags: [task, modernrtti, issue-56, bug, nil-handle, attributes, fpc, delphi, cycle-021]
generated:
  by: "equipe-bug@node:task"
  at: "2026-09-02T15:41:00Z"
sources:
  - id: task-input
    resource: "task-input.md"
    title: "TASK-INPUT — issue #56"
  - id: gh-56
    resource: "https://github.com/isaquepinheiro/ModernSyntax/issues/56"
    title: "Issue #56 — TModernRTTIType.Attributes nil-handle residual"
---

# TASK-021 — Issue #56: Attributes herda contrato de nil-handle da #49

## Tracking

- **Modo:** MAESTRO MODE
- **Issue original:** [#56](https://github.com/isaquepinheiro/ModernSyntax/issues/56)
  (demanda criada pelo maestro — `aefos:running`)
- **Epic:** nenhum Epic preexistente identificado; nenhum criado (MAESTRO MODE)
- **Board:** issue #56 ja carrega `aefos:running`

## Demanda em uma linha

`TModernRTTIType.Attributes` ficou fora do contrato de nil-handle da #49 (PR #55):
`PropAttributes` devolve vazio silenciosamente quando `FType = nil`, tornando o
resultado indistinguivel de "o tipo nao tem atributos".

## Escopo

Dois arquivos, nenhuma `resourcestring` nova, nenhuma decisao de design nova.
`SModernRTTINilHandle` ja existe em `Source/ModernSyntax.RTTI.pas:892`.

| Arquivo | O que muda |
|---------|-----------|
| `Source/ModernSyntax.RTTI.pas` | Inserir guarda de 2 linhas em `PropAttributes` (:1124), antes do comentario `// Issue #27:` |
| `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | 5 blocos x 2 linhas (Pos para igualdade estrita) + sexto bloco Attributes (~18 linhas) |

Cascas FPC e Delphi **nao mudam** — ja delegam em uma linha ao cenario compartilhado.

## Tres passos (commit unico)

### Passo 1 — Guarda em `PropAttributes`

Inserir como primeira instrucao do corpo (antes de `// Issue #27:`):

```pascal
if FType = nil then
  raise EModernRTTIError.CreateFmt(SModernRTTINilHandle, ['Attributes']);
```

Critico: `Attributes` sobre handle valido nao-classe (record, enum) deve
continuar devolvendo vazio — o `else Result := nil` permanece intacto.

### Passo 2 — Uniformizar cinco blocos existentes

Em cada um dos cinco blocos de `Scenario_NilHandle_AllMembers_Raises`, trocar:

```pascal
if Pos('<nome>', LMsg) = 0 then
  Fail(Format('Mensagem de <nome> nao cita o membro chamado: "%s"', [LMsg]));
```

por:

```pascal
if LMsg <> Format(SModernRTTINilHandle, ['<nome>']) then
  Fail(Format('Mensagem de <nome> incorreta: "%s"', [LMsg]));
```

Membros: `Name` (:1461), `GetProperties` (:1478), `GetFields` (:1497),
`GetMethods` (:1514), `GetMethod` (:1532).

### Passo 3 — Sexto bloco (Attributes)

Inserir apos linha 1534, antes do `end;` do procedimento. Reutilizar as
variaveis `LRaised` e `LMsg` ja declaradas no escopo — nao redeclarar.

## Criterios de aceite

- [ ] `Attributes` sobre `IsNil = True` levanta `EModernRTTIError` com
      `Format(SModernRTTINilHandle, ['Attributes'])`.
- [ ] `Attributes` sobre handle valido nao-classe devolve vazio sem excecao.
- [ ] Sexto bloco presente no cenario, usando igualdade estrita (sem `Pos`).
- [ ] Nenhum dos seis blocos usa `Pos(...)`.
- [ ] Build FPC 3.2.2 x86_64 verde.
- [ ] PR declara fronteira: FPC x86_64 (fabrica); i386 + Delphi (mantenedor).
- [ ] PR fecha `Closes #56`.

## Armadilhas

- Nao inserir a guarda APOS o `if (FType is TRttiInstanceType)` check —
  `is` sobre `nil` retorna `False` sem AV, e a guarda depois nao seria alcancada
  no caminho de nil.
- Sempre limpar `/tmp/fpcbuild` antes de compilar — FPC reutiliza `.ppu` velhos.
- Nao compilar `Source/*.pas` diretamente — compilar so o projeto de teste.
