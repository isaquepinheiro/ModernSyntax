---
type: task-input
kind: artifact
title: "TASK-INPUT — issue #56: Attributes herda contrato de nil-handle da #49"
description: "Handoff operacional para o implementador: guarda em PropAttributes + uniformizacao dos cinco blocos (Pos para igualdade estrita) + sexto bloco de Attributes no cenario compartilhado. Dois arquivos, commit unico, build FPC x86_64."
status: draft
cycle: "021"
agent: architect
workflow: equipe-bug
node: architect
resource: aefos://run/09743779c7c9860b5fa380f6979d94ca
tags: [task-input, issue-56, nil-handle, modernrtti, rtti, fpc, bug]
generated:
  by: "equipe-bug@node:architect"
  at: "2026-09-02T15:40:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — issue #56"
  - id: adr
    resource: "adr.md"
    title: "ADR — issue #56"
  - id: plan
    resource: "plan.md"
    title: "PLAN — issue #56"
---

# TASK-INPUT — Issue #56

## Titulo e tipo

**Titulo:** `fix(rtti): Attributes herda contrato de nil-handle da #49 (#56)`
**Tipo / labels:** `bug`, `rtti`, `nil-handle`

## Contexto operacional

A issue #49 (PR #55) uniformizou o contrato de nil-handle em cinco
membros de `TModernRTTIType`. A property `Attributes` ficou de fora:
`PropAttributes` faz `if (FType is TRttiInstanceType)` e, para
`FType = nil`, o `is` devolve `False` sem AV — cai silenciosamente no
caminho de "nao e classe" e devolve vazio. Nao ha AV, mas o resultado e
indistinguivel de "o tipo nao tem atributos".

Esta tarefa aplica a guarda identica a dos outros cinco membros e
atualiza o cenario compartilhado.

## Arquivos impactados

| Arquivo | O que muda |
|---------|-----------|
| `Source/ModernSyntax.RTTI.pas` | Inserir 2 linhas no corpo de `PropAttributes` (linha 1124) |
| `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | Alterar 10 linhas (5 blocos × 2) + inserir ~18 linhas (sexto bloco) |

**Nao mudam:** cascas de teste FPC/Delphi (ja delegam em uma linha e
cobrem o cenario automaticamente), nenhuma `resourcestring` nova.

## Checklist de implementacao

### 1. Guarda em `PropAttributes` — `Source/ModernSyntax.RTTI.pas:1124`

- [ ] Inserir como **primeira instrucao do corpo** (antes do comentario
      `// Issue #27:`):
      ```pascal
      if FType = nil then
        raise EModernRTTIError.CreateFmt(SModernRTTINilHandle, ['Attributes']);
      ```
- [ ] Mover o comentario `// Issue #27:` (linhas 1126-1128) para colado
      ao `if (FType is TRttiInstanceType)`.
- [ ] Verificar que `else Result := nil` permanece intacto.
- [ ] Verificar que `SModernRTTINilHandle` (linha 892) ja existe — nao
      adicionar nova string.

### 2. Uniformizacao dos cinco blocos — `UScenarios.RTTI.pas`

Em cada bloco, trocar duas linhas:

**Antes:**
```pascal
if Pos('<nome>', LMsg) = 0 then
  Fail(Format('Mensagem de <nome> nao cita o membro chamado: "%s"', [LMsg]));
```

**Depois:**
```pascal
if LMsg <> Format(SModernRTTINilHandle, ['<nome>']) then
  Fail(Format('Mensagem de <nome> incorreta: "%s"', [LMsg]));
```

- [ ] **Name** (linha 1461-1462): `<nome>` = `'Name'`
- [ ] **GetProperties** (linha 1478-1480): `<nome>` = `'GetProperties'`
- [ ] **GetFields** (linha 1497-1498): `<nome>` = `'GetFields'`
- [ ] **GetMethods** (linha 1514-1516): `<nome>` = `'GetMethods'`
- [ ] **GetMethod** (linha 1532-1534): `<nome>` = `'GetMethod'`
      (este era o unico com aliasing real por substring — agora todos
      usam o mesmo padrao)

### 3. Sexto bloco — append em `UScenarios.RTTI.pas` apos linha 1534

- [ ] Inserir apos linha 1534, antes do `end;` (linha 1535):
      ```pascal

        // Attributes (sexto membro — issue #56)
        LRaised := False;
        LMsg := '';
        try
          LType.Attributes;
        except
          on E: EModernRTTIError do
          begin
            LRaised := True;
            LMsg := E.Message;
          end;
        end;
        if not LRaised then
          Fail('Attributes sobre handle nil nao levantou EModernRTTIError.');
        if LMsg <> Format(SModernRTTINilHandle, ['Attributes']) then
          Fail(Format('Mensagem de Attributes incorreta: "%s"', [LMsg]));
      ```
- [ ] Nao redeclarar `LRaised` e `LMsg` — ja existem no escopo.
- [ ] Confirmar que o `end;` do procedimento segue imediatamente.

### 4. Build e execucao FPC x86_64

- [ ] Limpar e compilar (trap: SEMPRE limpar antes):
      ```bash
      rm -rf /tmp/fpcbuild && mkdir -p /tmp/fpcbuild
      fpc -Mdelphi \
          -Fu"Source" -Fu"Test Shared/EclbrSystem" -Fu"Test FPC/EclbrSystem" \
          -FU/tmp/fpcbuild -FE/tmp/fpcbuild \
          "Test FPC/EclbrSystem/PTestRTTI.lpr"
      ```
- [ ] Executar: `/tmp/fpcbuild/PTestRTTI --all -a --format=plain`
- [ ] 0 falhas. Confirmar que `TestNilHandle_AllMembers_Raises` passa.

### 5. Verificacao de nao-regressao

- [ ] `Attributes` sobre handle valido de tipo nao-classe (ex.: record)
      continua devolvendo vazio sem levantar excecao.

### 6. Commit unico

- [ ] Um unico commit com os tres passos (guarda + uniformizacao +
      sexto bloco).
- [ ] Mensagem de commit inclui referencia a issue #56.

### 7. PR — texto obrigatorio (secao propria)

- [ ] Declarar literalmente: *"ciclo rodou FPC x86_64 no container
      (compila e roda). i386 e os 4 alvos Delphi nao foram executados
      nesta fabrica — ficam com o mantenedor antes do merge."*
- [ ] Secao separada (nao nota de rodape):
      *"Acceptance item 'dois compiladores × dois bitness': o ciclo
      cobre 1 de 4 (FPC x86_64). Os 3 restantes (FPC i386, Delphi
      Win32, Delphi Win64) exigem toolchain ausente da fabrica e ficam
      com o mantenedor. Padrao herdado da serie #43–#49."*

## Criterios de aceite (resumo verificavel)

- [ ] `Attributes` sobre `IsNil = True` levanta `EModernRTTIError` com
      `Format(SModernRTTINilHandle, ['Attributes'])`.
- [ ] `Attributes` sobre handle valido nao-classe devolve vazio sem excecao.
- [ ] Sexto bloco presente no cenario, com assertiva de igualdade estrita.
- [ ] Nenhum dos seis blocos usa `Pos(...)`.
- [ ] Build FPC 3.2.2 x86_64 verde.
- [ ] PR com secao de fronteira nomeada.

## Armadilhas conhecidas (SKILL.md)

- **Nao compilar `Source/*.pas` inteiro** — 0 de 16 units compilam no FPC
  3.2.2 estavel. Compilar so o projeto de teste (`PTestRTTI.lpr`).
- **Sempre limpar `/tmp/fpcbuild` antes de compilar** — FPC reutiliza `.ppu`
  velhos e reporta verde sobre codigo desatualizado.
- `ppc386` nao existe na fabrica; `fpc -Pi386` retorna `error code: 127`.
  Nao tentar provar i386 — esta com o mantenedor.
