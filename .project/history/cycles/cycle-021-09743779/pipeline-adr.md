---
type: adr
kind: artifact
title: "ADR — Guarda de nil em Attributes e uniformizacao do cenario (issue #56)"
description: "Decisoes acordadas na investigacao: posicao da guarda, uniformizacao dos seis blocos de assert, ordem cronologica do sexto bloco, commit unico, e declaracao de fronteira do ciclo no PR."
status: draft
cycle: "021"
agent: architect
workflow: equipe-bug
node: architect
resource: aefos://run/09743779c7c9860b5fa380f6979d94ca
tags: [adr, issue-56, nil-handle, modernrtti, rtti, fpc, bug]
generated:
  by: "equipe-bug@node:architect"
  at: "2026-09-02T15:40:00Z"
sources:
  - id: investigation
    resource: "https://github.com/isaquepinheiro/ModernSyntax/issues/56"
    title: "Relatorio de investigacao — Issue #56 (run c85a5115026d0a220da0a27064774fdd)"
  - id: esp
    resource: "esp.md"
    title: "ESP — issue #56"
---

# ADR — Issue #56 (`Attributes` — resíduo do nil-handle)

> **Este ADR deriva integralmente do relatorio de investigacao (run
> `c85a5115026d0a220da0a27064774fdd`)**, que registra duas voltas de
> discussao entre o arquiteto e o mantenedor. As decisoes abaixo
> restituem o que foi acordado la; nenhuma foi tomada de novo aqui.
> Qualquer divergencia seria nomeada explicitamente.

---

## D-56.1 — Guarda de nil como primeira instrucao visivel de `PropAttributes`

**Decisao:** inserir `if FType = nil then raise EModernRTTIError.CreateFmt(SModernRTTINilHandle, ['Attributes'])` **antes** do comentario `// Issue #27:` (hoje linha 1126 do corpo de `PropAttributes`). O comentario se move para ficar colado ao `if (FType is TRttiInstanceType)`.

**Racional:** a guarda e pre-condicao do metodo inteiro, nao parte da logica de delegacao que o comentario explica. Uniformidade com os outros cinco membros: em todos eles a guarda e a primeira instrucao visivel. Quem varre o arquivo perguntando "este membro guarda nil?" acha a resposta sempre no mesmo lugar. (volta 1, Q4 do relatorio.)

**O ramo `else Result := nil` nao e tocado.** Ele representa o vazio legitimo para handle valido nao-classe (record, enum) — e precisamente o cuidado que a #49 teve no `GetFields` (ESP B-56.2).

---

## D-56.2 — Uniformizar os seis blocos de assert, nao so o de `GetMethod`

**Decisao:** trocar `Pos(...)` por `<>` em **todos os seis** blocos de `Scenario_NilHandle_AllMembers_Raises` (`Name`, `GetProperties`, `GetFields`, `GetMethods`, `GetMethod`, `Attributes`), mesmo nos quatro em que `Pos` nao aliaseia por substring.

**Racional:** manter dois estilos dentro do mesmo procedimento cria a pergunta "por que este e diferente?" para todo leitor futuro, e a resposta ("porque so `GetMethod` colidia com `GetMethods` por substring") nao esta visivel no codigo. O custo de uniformizar e 4 linhas × 2 no mesmo procedimento. (volta 1, Q1 do relatorio.)

---

## D-56.3 — Consequencia mecanica de D-56.2: reescrever as mensagens do `Fail`

**Decisao:** ao trocar `Pos → <>`, reescrever tambem as **cinco mensagens de `Fail`** dos blocos existentes, de `'nao cita o membro chamado: %s'` para `'Mensagem de X incorreta: "%s"'`. O sexto bloco usa o mesmo padrao diretamente.

**Racional:** `'nao cita o membro chamado'` e linguagem de `Pos`; sob igualdade estrita a assertiva verifica o valor inteiro, e o diagnostico correto e `'Mensagem de X incorreta'`. Manter a mensagem antiga com o assert novo seria um diagnostico que mente. (volta 1, Q1, resposta do arquiteto no relatorio.)

**Padrao unico dos seis blocos:**
```pascal
if LMsg <> Format(SModernRTTINilHandle, ['<nome>']) then
  Fail(Format('Mensagem de <nome> incorreta: "%s"', [LMsg]));
```

---

## D-56.4 — Sexto bloco em ordem cronologica (append puro)

**Decisao:** inserir o bloco de `Attributes` **apos a linha 1534** (ultima linha do quinto bloco), antes do `end;` do procedimento. Nao em ordem alfabetica.

**Racional:** a ordem cronologica torna o diff um append puro (nao toca os cinco blocos existentes) e documenta que `Attributes` foi o membro que a #49 nao pegou. Ordem alfabetica otimizaria para um leitor que nao existe. (volta 1, Q2 do relatorio.)

---

## D-56.5 — Commit unico com os tres passos

**Decisao:** guarda em `PropAttributes` + uniformizacao dos cinco blocos + sexto bloco entram em **um unico commit**.

**Racional:** separar a uniformizacao em commit proprio criaria um commit que mexe em teste sem mudar comportamento — ruido no bisect, nao sinal. O nit e o endurecimento do mesmo assert que esta sendo estendido. (volta 1, Q3 do relatorio.)

---

## D-56.6 — PR declara apenas o que o ciclo rodou (FPC x86_64)

**Decisao:** o PR declara literalmente: *"ciclo rodou FPC x86_64 no container (compila e roda). i386 e os 4 alvos Delphi nao foram executados nesta fabrica — ficam com o mantenedor antes do merge."*

**Racional:** o container da fabrica so tem `ppcx64`/`fpc` para x86_64 (`ppc386` retorna `error code: 127`; `/usr/lib/fpc/3.2.2/units/i386-linux` inexistente). A afirmacao inicial de "2 bitness" foi corrigida na volta 2 do relatorio — declarar 2 bitness reproduziria o defeito da familia #296–#300 (PR que afirma prova que nao produziu). O acceptance item "dois compiladores × dois bitness" cobre 1 de 4 pelo ciclo; os outros 3 ficam com o mantenedor. (volta 2, Q5 corrigido do relatorio.)

Esta e uma secao propria no PR — nao nota de rodape — padrao herdado da serie #43–#49.

---

## Descartado

| Proposta | Motivo do descarte |
|----------|-------------------|
| Uniformizar so o bloco de `GetMethod` (proposta inicial do estudo) | Deixa dois estilos no mesmo procedimento; custo de uniformizar todos: 4 linhas × 2, mesmo commit (D-56.2) |
| Ordem alfabetica do sexto bloco | Otimiza para leitor que nao existe; ordem cronologica documenta que `Attributes` e residuo da #49 (D-56.4) |
| Commit separado para a uniformizacao | Cria commit que mexe em teste sem mudar comportamento — ruido no bisect (D-56.5) |
| Guarda apos o comentario `// Issue #27:` | Rompe uniformidade com os outros cinco; a guarda e pre-condicao, nao parte da logica de delegacao (D-56.1) |
| Declarar "FPC 2 bitness" no PR | Medido: `ppc386` retorna `error code: 127`; `/usr/lib/fpc/3.2.2/units/i386-linux` nao existe (D-56.6) |
| Marcar acceptance "2 compiladores × 2 bitness" como provado pelo ciclo | Cobertura e 1 de 4; os 3 restantes ficam com o mantenedor (D-56.6) |
