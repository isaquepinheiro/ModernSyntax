---
type: review-report
kind: artifact
title: "Review report — ModernSyntax.Callback (ciclo 004, issue #7)"
description: "Revisão de qualidade da implementação de callbacks transversais: APROVADO com duas observações bloqueantes leves (i386 + PR body) e três não-bloqueantes."
cycle: "004"
agent: quality
workflow: equipe-feature
node: review
resource: aefos://run/24c962dcc2be1819336ca1fea18ae949
status: stable
tags: [review-report, modernrtti, callbacks, issue-7, cycle-004]
generated:
  by: "equipe-feature@node:review"
  at: "2026-08-28T15:45:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — Callbacks transversais"
  - id: adr
    resource: "adr.md"
    title: "ADR — Design da unit ModernSyntax.Callback"
  - id: implement-report
    resource: "implement-report.md"
    title: "Implement report — ciclo 004"
---

# Review report — ModernSyntax.Callback (ciclo 004)

## Sumário

Implementação **APROVADA** com duas observações que o committer deve
tratar no corpo do PR antes do merge humano, e três observações
não-bloqueantes documentadas abaixo.

A unit `Source/ModernSyntax.Callback.pas` está correta contra o
[esp](pipeline-esp.md) e o [adr](pipeline-adr.md): três interfaces sem GUID, factory
`Callback` com três sobrecargas, wrappers na `interface`, cabeçalho
`(* ... *)`, sem `{$I ModernSyntax.inc}`, sem token `FCP`, e
`{$IFDEF FPC}` exclusivamente no arquivo de produção. Quatro cenários
passam no FPC 3.2.2 x86_64 (evidência no [implement-report](pipeline-implement-report.md)).

---

## Checklist de aceitação (ESP seção 4)

| CA | Critério | Resultado |
|----|----------|-----------|
| CA-1 | Três interfaces compilam nos dois compiladores sem modificação no consumidor | ✅ PASS — nomes corretos (`IModernFunc`, `IModernProc`, `IModernPredicate`); FPC x86_64 compilou |
| CA-2 | `Callback.&Of(Self.MinhaProc)` funciona como atalho | ✅ PASS — `&Of` é a fuga Pascal padrão para o símbolo `Of`; caso coberto em cenários |
| CA-3 | Captura de variável via classe helper nos dois compiladores | ✅ PASS — `TAccumulator` em `UTestMS.Callback.Scenarios.pas` demonstra o padrão canônico |
| CA-4 | `grep -rn "{$IFDEF FPC}" Test Shared/ Test Delphi/ Test FPC/` → 0 | ✅ PASS — verificado; resultado: exit 1 (sem ocorrências) |
| CA-5 | `Test FPC/EclbrSystem/PTestModernCallback.lpi` presente | ✅ PASS — arquivo existe com dois build modes (x86_64 e i386) |
| CA-6 | Testes compilam e passam em FPC x86_64 **e** i386 | ⚠️ PARCIAL — x86_64: 4/4 passaram (evidência no implement-report); i386: `ppc386` ausente na fábrica (env gap); `.lpi` configurado para autor rodar |
| CA-7 | PR body declara literalmente compilação FPC e ausência Delphi | ⚠️ PENDENTE — PR não existe ainda; committer deve escrever declaração honesta (ver observação O-1) |
| CA-8 | Sem `{$I ModernSyntax.inc}` e sem token `FCP` | ✅ PASS — ambos os greps retornam exit 1 |

**Regras de negócio (ESP seção 3):**

| RN | Critério | Resultado |
|----|----------|-----------|
| RN-1 | Três interfaces + factory + wrappers na `interface` | ✅ PASS |
| RN-2 | Interfaces sem GUID | ✅ PASS |
| RN-3 | `{$IFDEF FPC}` só em `ModernSyntax.Callback.pas`; proibido em consumer | ✅ PASS — `{$MODE DELPHI}` na casca FPC não é `{$IFDEF FPC}` e é aceitável |
| RN-4 | Sem `{$I ModernSyntax.inc}` | ✅ PASS |
| RN-5 | `uses SysUtils;` apenas | ✅ PASS |
| RN-6 | Captura via classe helper | ✅ PASS |

---

## Observações (pré-merge)

### O-1 — CA-7 / corpo do PR: declaração deve ser honesta sobre i386 (atenção ao committer)

CA-7 exige que o PR declare literalmente:
> *"compilado em FPC 3.2.2 x86_64 e i386; não compilado em Delphi —
> Delphi permanece com o autor"*

A fábrica não tem `ppc386` (cross-compiler i386); o implement-report
documenta isso no caveat 3. O committer **não deve** copiar a declaração
literal do CA-7 sem ajustá-la para o estado real. Forma honesta
recomendada:

> *"Compilado em FPC 3.2.2 x86_64-linux (4/4 testes passaram). Build
> i386: configurado no .lpi (build mode Debug-i386); ppc386 ausente
> na fábrica — autor valida antes do merge. Não compilado em Delphi —
> Delphi permanece com o autor."*

**Ação:** committer escreve o PR body com a declaração honesta acima;
merge humano aguarda confirmação do autor sobre i386 e Delphi.

### O-2 — `Callback.&Of` em lugar de `Callback.Of` (divergência formal do ADR D-A3)

O ADR (D-A3) declarou `class function Of<T,R>(...)`. `of` é palavra
reservada em Pascal (Delphi e FPC). A declaração não compila em nenhum
dos dois compiladores. O desenvolvedor usou o escape padrão Pascal
(`&Of`), que mantém o nome do símbolo como `Of`. O consumidor chama
`Callback.&Of(...)` com um `&` extra.

**Avaliação:** correção tecnicamente obrigatória; o ADR tinha um oversight.
A decisão D-A3 foi preservada em espírito. O develop-report documenta
o custo (1 caractere `&`) e o impacto. Não há alternativa que preserve
`Of` sem o `&`. **Não-bloqueante**, mas o committer deve mencionar no PR.

---

## Observações não-bloqueantes

### NB-1 — `{$MODE DELPHI}` na casca FPC fora de `{$IFDEF FPC}`

`Test FPC/EclbrSystem/UTestMS.Callback.pas` abre com `{$MODE DELPHI}`
incondicional (linha 23). RN-3 proíbe `{$IFDEF FPC}` em arquivos de
consumidor — esta diretiva não é `{$IFDEF FPC}` e é FPC-only (Delphi
a ignora silenciosamente). Funcional; aceitável. Mera observação de
limpeza para ciclo futuro.

### NB-2 — `.res` é placeholder binário

`PTestModernCallback.res` é cópia de `PTestOption.res`. O Delphi RC
regenera no primeiro build local. Não afeta FPC nem qualidade do
artefato principal. Sem ação necessária neste ciclo.

### NB-3 — `IFDEF TESTINSIGHT` no `.dpr`

`PTestModernCallback.dpr` usa `{$IFDEF TESTINSIGHT}` (padrão vivo de
todos os outros `PTest*.dpr`). O plano mencionava grep de IFDEF em
geral; o CA relevante é CA-4 (`{$IFDEF FPC}` — passado). Manter o
padrão do repositório é correto.

---

## Veredicto final

**APROVADO** — implementação conforme o [esp](pipeline-esp.md) e o [adr](pipeline-adr.md).
Committer segue com as observações O-1 e O-2 incorporadas ao PR body.
Merge humano aguarda confirmação de i386 + Delphi pelo autor.
