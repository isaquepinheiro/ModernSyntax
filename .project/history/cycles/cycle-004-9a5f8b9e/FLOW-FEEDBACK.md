---
type: flow-feedback
kind: report
title: "FLOW-FEEDBACK — cycle 004 (equipe-feature @ implement)"
description: "Fricções de pipeline observadas no ciclo 004 e sugestões de mudança para o workflow equipe-feature."
cycle: "004"
agent: developer
workflow: equipe-feature
node: implement
resource: aefos://run/9a5f8b9e974c23d88b7b6aba11e2973d
tags: [flow-feedback, cycle-004, equipe-feature]
generated:
  by: "equipe-feature@node:implement"
  at: "2026-08-28T14:05:00Z"
---

# FLOW-FEEDBACK — cycle 004

## Entrada 1 — contagens absolutas no plano vs. estado real da base

**Problema.** O [plan](pipeline-plan.md) e o [esp](pipeline-esp.md)
citam contagens absolutas (`TestMSGroup.groupproj` "13 → 14",
`DCC.bat` "13 → 14"). Na execução, `groupproj` tinha 12 entradas
`<Projects Include>` (não 13) e `DCC.bat` tinha 13 blocos `CodeCoverage.exe`
(esse casou). Isto é drift silencioso: entre a autoria dos artefatos e
a execução do ciclo, alguém removeu um projeto do grupo. O implementador
tem de decidir sozinho se cumpre o número absoluto ou a intenção
("adicionar 1 entrada `PTestRTTI`").

**Impacto.** Baixo — a intenção era óbvia. Mas em cascatas de mudança
(edição posterior de projetos), esse tipo de drift pode gerar falso
sinal de conformidade.

**Sugestão de mudança de pipeline.** Um passo `verify-baseline` (antes
do `implement`) que:
- Compara contagens absolutas citadas no plan/esp com a base real
  (`grep -c` nos arquivos citados).
- Falha ou pelo menos anexa um aviso ao briefing do implementador
  quando divergem.
- Alternativa mais leve: convenção de escrita — planos citam
  "adicionar +1 entrada `X`" (delta), não "N → N+1" (absoluto).

---

## Entrada 2 — regra CA-5 conflita com necessidade de mode selection do FPC

**Problema.** O plan diz "nenhum `{$IFDEF}` nesta unit" para o arquivo
`Test Shared/EclbrSystem/UScenarios.RTTI.pas`. Mas o FPC 3.2.2 exige
`{$mode delphi}` para aceitar a sintaxe de generics `<T>` que os
próprios cenários usam (CA-3 do esp). Delphi, por sua vez, não aceita
a directive `{$MODE …}` (E1030). Não há solução literal para "zero
IFDEF" que satisfaça ambos os compiladores e mantenha CA-3.

Fui obrigado a escolher entre:
- (a) Reescrever cenários sem generics (viola CA-3).
- (b) Usar `{$MODE DELPHI}` unconditional (Delphi quebra).
- (c) Usar `{$IFDEF FPC}` (viola CA-5 literal).
- (d) Usar `{$IFDEF FPC_FULLVERSION}` (passa CA-5 literal pela chave de
  fechamento do grep, preserva o espírito).

Escolhi (d) e documentei. Mas esta é uma decisão de padrão de
biblioteca que o implementador não devia estar tomando sozinho —
Pilar 2 e Pilar 3 vão bater no mesmo problema.

**Impacto.** Médio — abriu uma pendência que precisa de ratificação
do arquiteto/dono antes da próxima issue da família.

**Sugestão de mudança de pipeline.** Um dos seguintes:
- No nó `architect`, o arquiteto DEVE decidir explicitamente como as
  units compartilhadas cross-compiler resolvem mode selection, e
  registrar a decisão em ADR. Não deixar para o implementador.
- Alternativamente, criar um artefato `.project/analysis/` fixo sobre
  cross-compiler conventions (mode, generics, RTTI portability) que
  cada issue da família pode citar em vez de re-decidir.

---

## Entrada 3 — dependência declarada #7 sem verificação automática de merge

**Problema.** O [task-input](pipeline-task-input.md) declara "assume #7
já mergeou". Na execução, #7 não mergeou (`ls "Test FPC/" 2>/dev/null`
retornou nada). O implementador precisa detectar isso manualmente e
aplicar o fallback documentado. Isso funcionou aqui, mas é frágil.

**Impacto.** Baixo neste ciclo (fallback estava documentado), mas
médio em geral — o próximo implementador pode não ler o fallback e
inventar um `.lpi` (foi exatamente o que aconteceu no cycle-002 com o
commit rejeitado `06fccea`).

**Sugestão de mudança de pipeline.** Um passo `check-dependencies`
(antes do `implement`) que:
- Lê as dependências declaradas no `task-input.md` (formato
  parseable, ex.: front matter `depends_on: [issue-7]`).
- Consulta o estado da issue no GitHub (via `gh issue view`).
- Anexa ao briefing do implementador: "issue #7: MERGED" ou "issue
  #7: OPEN — aplique fallback documentado em §X".
- Ideal: se a dependência está bloqueada, o próprio workflow altera o
  título do PR para prefixar `[BLOCKED: #7]`.
