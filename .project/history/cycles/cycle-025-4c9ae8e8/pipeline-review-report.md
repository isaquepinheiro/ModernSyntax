---
type: review-report
kind: artifact
title: "REVIEW #60 — else raise no PropertyVisibility do backend FPC"
description: "Revisao de qualidade do ciclo 025: 4 edicoes em 2 arquivos Pascal verificadas contra ESP, ADR e convencoes. Todos os criterios de aceitacao satisfeitos."
cycle: "025"
agent: quality
workflow: equipe-bug
node: review
resource: aefos://run/4c9ae8e8f3b0ca77a166f343e7d3f098
generated:
  by: "equipe-bug@node:review"
  at: "2026-09-02T00:00:00Z"
tags: [review, cycle-025, issue-60, fpc, rtti, visibility, fail-loud]
---

# REVIEW-REPORT — Issue #60: `else raise` no `PropertyVisibility` do backend FPC

## Sumário

Revisão do ciclo 025. Quatro edições cirúrgicas em dois arquivos Pascal verificadas
linha a linha contra o [ESP](pipeline-esp.md), o [ADR](pipeline-adr.md) e as convenções do SKILL.md.
Todos os dez critérios de aceitação do ESP satisfeitos. Zero violação de ADR. Zero
símbolo novo na interface pública. Suite FPC 42/42 verde. Backend Delphi intocado.

**Decisão própria do developer reconhecida e aprovada:** comentário do `PropertyVisibility`
transliterado para ASCII (sem acentos) para alinhar à convenção histórica do arquivo
`RTTI.FPC.pas`; o XMLDoc de `RTTI.pas` manteve acentos (consistente com o padrão já
estabelecido na edição de #62). O conteúdo semântico exigido pelo ADR D-60.6 está
integralmente presente.

**Veredicto: APPROVED**

---

## Checklist de critérios de aceitação (ESP §6)

| # | Critério | Estado | Evidência |
|---|---------|--------|-----------|
| 1 | `PropertyVisibility` tem `else raise EModernRTTIError.CreateFmt(SFPCUnknownVisibility, [Ord(...), 'PropertyVisibility'])` | ✅ | `RTTI.FPC.pas:505-507` |
| 2 | `SFPCUnknownVisibility` na `resourcestring` da `implementation`; zero símbolo novo na interface | ✅ | `RTTI.FPC.pas:201-203`; após `implementation` (linha 149) |
| 3 | Comentário NÃO afirma `else` seria código morto; descreve medição (229/i386, 0=`mvPrivate`/x86_64) como razão histórica | ✅ | `RTTI.FPC.pas:481-499` |
| 4 | Comentário cita #51 e #60 como primeiro e segundo movimento | ✅ | `RTTI.FPC.pas:481-485`: "segundo movimento da mesma decisao" |
| 5 | XMLDoc de `TModernVisibility` descreve ambos backends levantando após guardas; medição no passado; sem afirmação de exaustividade no FPC | ✅ | `RTTI.pas:79-85` |
| 6 | Nenhum teste novo; fronteira declarada explicitamente | ✅ | Contagem FPC: 42 (implement-report §Validações) |
| 7 | PR não afirma redução de warning | ✅ | Implement-report declara: "zero warning novo"; "o FPC nunca emitiu warning para este padrão" |
| 8 | PR declara ramo `else` inalcançável por dado real e por quê | ✅ | Implement-report §Caveats e PR body (D-60.7) |
| 9 | Suite FPC verde em x86_64; contagem permanece 42 | ✅ | `PTestRTTI --all`: 42/0/0 (implement-report §Validações) |
| 10 | Backend Delphi intocado | ✅ | `git diff Source/ModernSyntax.RTTI.Delphi.pas` vazio |

---

## Checklist ADR

| Decisão | Descrição | Estado |
|---------|-----------|--------|
| D-60.1 | `else raise EModernRTTIError.CreateFmt(SFPCUnknownVisibility, [Ord(TRttiProperty(AToken).Visibility), 'PropertyVisibility'])` | ✅ Cópia literal do Delphi trocando só o nome da resourcestring |
| D-60.2 | `SFPCUnknownVisibility` na `implementation`, após `SFPCNoParamType` | ✅ `RTTI.FPC.pas:197-203` |
| D-60.3 | Nome `SFPCUnknownVisibility`, não `SFPCNo*` | ✅ Nova convenção registrada no comentário-cabeçalho |
| D-60.4 | Mensagem cópia literal do Delphi, `#51` → `#60` | ✅ Texto idêntico com issue corrigida |
| D-60.5 | XMLDoc de `TModernVisibility` entra no PR | ✅ `RTTI.pas:79-85` reescrito |
| D-60.6 | Comentário do `PropertyVisibility` cita ambas as issues; retira "código morto"; medição no passado | ✅ Todos os requisitos presentes em ASCII |
| D-60.7 | PR declara plataforma; sem checklist de cobertura humana | ✅ Declarado no PR body e implement-report |
| D-60.8 | Nenhum teste novo; contagem FPC = 42 | ✅ Confirmado |
| D-51.5 (herdado) | Sem `AOwner` no `PropertyVisibility` | ✅ Assinatura `PropertyVisibility(AToken: Pointer)` inalterada |

---

## Verificações de convenção

| Convenção | Estado |
|-----------|--------|
| `SFPCNo*` vs `SFPCUnknown*` — nova distinção semântica registrada (D-60.3) | ✅ Comentário-cabeçalho em `RTTI.FPC.pas:197-200` documenta explicitamente |
| Labels qualificados no `case` (`TMemberVisibility.` / `TModernVisibility.`) | ✅ `RTTI.FPC.pas:501-504` |
| `resourcestring` na `implementation`, não na `interface` | ✅ Linha 201 está após `implementation` (linha 149) |
| Sem ramo `mvAutomated` (não existe em FPC 3.2.2) | ✅ Nota preservada em `RTTI.FPC.pas:494-496` |
| Board `.project/project-evolution.md` avançado para `🔄 in-review` | ✅ Linha 025 atualizada |
| OKF frontmatter em todos os artefatos do pipeline | ✅ `esp.md`, `adr.md`, `plan.md`, `implement-report.md` conformes |

---

## Questões críticas

Nenhuma.

---

## Observações não bloqueantes

1. **Em-dash (`—`) na resourcestring.** `SFPCUnknownVisibility` contém o caractere
   U+2014 (`—`) na string literal (linha 202), enquanto os comentários do arquivo foram
   transliterados para ASCII. Isso é intencional e correto: a cópia literal do Delphi
   (D-60.4) carrega esse caractere; o FPC lida com UTF-8 em string literals sem problema.
   Não é inconsistência — é a fronteira precisa entre "string literal renderizada" e
   "comentário de código".

2. **Comentário em ASCII vs. XMLDoc com acentos.** O developer documentou a decisão
   nos caveats do implement-report e na decisão própria do REPORT-developer. A
   distinção é defensável (RTTI.FPC.pas histórico = ASCII; RTTI.pas XMLDoc = acentos
   introduzidos em #62). Aprovado sem ressalva.

3. **i386 não validado na fábrica.** Registrado como fronteira explícita conforme D-60.7.
   A guarda levantará em ambas as plataformas; apenas o ordinal difere na mensagem
   (229 vs 0). Não bloqueante.
