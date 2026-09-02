---
type: spec
kind: artifact
title: "ESP #60 — else raise no PropertyVisibility do backend FPC"
description: "Especificacao formal: adicionar guarda else raise EModernRTTIError ao case de PropertyVisibility no backend FPC, com resourcestring e reescrita de XMLDoc/comentario."
cycle: "025"
agent: architect
workflow: equipe-bug
node: architect
resource: aefos://run/4c9ae8e8f3b0ca77a166f343e7d3f098
generated:
  by: "equipe-bug@node:architect"
  at: "2026-09-02T00:00:00Z"
tags: [spec, fpc, rtti, visibility, bug, issue-60, modernrtti, cycle-025]
---

# ESP #60 — `else raise` no `PropertyVisibility` do backend FPC

## 1. Objetivo

Aplicar no `PropertyVisibility` de `Source/ModernSyntax.RTTI.FPC.pas` a
mesma guarda `else raise EModernRTTIError` que o PR #59 inseriu no backend
Delphi (issue #51). Corrigir simultaneamente o XMLDoc de `TModernVisibility`
em `Source/ModernSyntax.RTTI.pas`, que afirma em presente que o `case` sem
`else` no FPC é correto — e que, sem esta fix, seria publicado como falso.

## 2. Contexto

O backend Delphi foi corrigido na issue #51 / PR #59: ambos os sites de
Visibility receberam `else raise EModernRTTIError.CreateFmt`. O backend FPC
ficou intocado sob a justificativa (D-51.8) de que o FPC confirmaria
exaustividade em compile-time.

Essa premissa foi medida e é falsa. O FPC 3.2.2 aceita o `case` de 4 ramos
sem `else` sem emitir erro, warning ou hint. O valor não mapeado vem como
ordinal 229 no i386 e **0 no x86_64** — e `0` é `mvPrivate`, um
`TModernVisibility` semanticamente plausível. Falha silenciosa e convincente
é a pior combinação; o Delphi ao menos emite W1035.

O site `MethodVisibility` do FPC já levanta com `SFPCNoVisibility` por design
(`vmtMethodTable` não carrega o dado). Esta issue cobre apenas
`PropertyVisibility`.

## 3. Escopo

**2 arquivos, 4 edições. Zero linhas executáveis novas além da guarda.**

| # | Arquivo | Linha | Tipo de mudança |
|---|---------|-------|-----------------|
| 1 | `Source/ModernSyntax.RTTI.FPC.pas` | após linha 193 | + `resourcestring SFPCUnknownVisibility` na `implementation` |
| 2 | `Source/ModernSyntax.RTTI.FPC.pas` | 474–487 | reescrita do comentário do `PropertyVisibility` |
| 3 | `Source/ModernSyntax.RTTI.FPC.pas` | antes do `end;` em ~493 | + `else raise EModernRTTIError.CreateFmt(...)` |
| 4 | `Source/ModernSyntax.RTTI.pas` | 79–85 | reescrita do XMLDoc de `TModernVisibility` |

## 4. Fora do escopo

- `MethodVisibility` do backend FPC — já levanta com `SFPCNoVisibility` por design; nenhum defeito.
- Backend Delphi (`Source/ModernSyntax.RTTI.Delphi.pas`) — PR #59 corrigiu ambos os sites.
- Novos cenários de teste — ramo `else raise` inalcançável por dado real
  (valor vem de `TRttiProperty(AToken).Visibility`, RTTI real, não injetável).
- Alterações de interface pública — `resourcestring` fica na `implementation`.
- Validação i386 pela fábrica — FPC disponível é x86_64-linux; i386 fica com o autor.

## 5. Regras de negócio e restrições

1. **`resourcestring` na `implementation`** — segue D-51.3; nenhum símbolo novo na interface.
2. **Nome `SFPCUnknownVisibility`** — prefixo `SFPCUnknown*` (enum existe, não mapeia),
   distinto de `SFPCNo*` (feature indisponível no RTTI); simetria com `SDelphiUnknownVisibility`.
3. **Mensagem com `%d + %s`** — ordinal + nome da função; cópia literal do Delphi
   trocando apenas `#51` → `#60` (D-51.4 estendido).
4. **Sem `AOwner`** — `PropertyVisibility(AToken: Pointer)` não recebe `AOwner` (D-51.5).
5. **Linhagem citada** — comentário e XMLDoc citam #51 e #60 como primeiro e segundo
   movimento da mesma decisão.
6. **Medição no passado** — prosa nova descreve o comportamento *antes* das guardas como
   motivação histórica; não afirma nada sobre capacidades atuais do compilador FPC.
7. **PR declara plataforma** — "compilado em FPC 3.2.2 x86_64"; i386 e Delphi ficam com
   o autor. Sem checklist de cobertura humana bloqueante.

## 6. Critérios de aceitação

- [ ] `PropertyVisibility` do backend FPC tem `else raise EModernRTTIError.CreateFmt(SFPCUnknownVisibility, [Ord(TRttiProperty(AToken).Visibility), 'PropertyVisibility'])` dentro do `case`.
- [ ] `SFPCUnknownVisibility` declarada na seção `resourcestring` da `implementation` de `RTTI.FPC.pas`; zero símbolo novo na interface.
- [ ] Comentário de `PropertyVisibility` **não** afirma que o `else` seria código morto; descreve o comportamento medido (sem erro, sem warning, sem hint; ordinal 229 no i386, 0 = `mvPrivate` no x86_64) como razão histórica da guarda.
- [ ] Comentário cita #51 e #60 como primeiro e segundo movimento da mesma decisão.
- [ ] XMLDoc de `TModernVisibility` em `RTTI.pas:79–85` descreve o que os dois backends fazem após as guardas (ambos levantam `EModernRTTIError`) e coloca a medição no passado; não afirma exaustividade em compile-time no FPC.
- [ ] Nenhum teste novo — ramo `else` inalcançável por dado real; fronteira declarada explicitamente no PR.
- [ ] PR **não** afirma redução de warning (não havia warning no FPC antes da fix).
- [ ] PR declara explicitamente que o ramo `else` é inalcançável por dado real e por quê.
- [ ] Suite FPC verde em x86_64 (fábrica); contagem permanece 42.
- [ ] Backend Delphi intocado.

## 7. Riscos

| Risco | Probabilidade | Impacto | Mitigação |
|-------|--------------|---------|-----------|
| Regressão no único ramo alcançável (`mvPublished`) | Baixa | Alta | `Scenario_Property_Visibility_Returns_mvPublished` (`UScenarios.RTTI.pas:1086`) cobre esse ramo; qualquer erro no `case` o quebraria. |
| XMLDoc novo substitui afirmação falsa por outra | Baixa | Média | Prosa aprovada na investigação; descreve o estado *depois* das guardas, não afirma nada sobre o compilador. |
| `SFPCUnknownVisibility` colocada na `interface` por engano | Baixa | Baixa | Revisão de diff confirma seção `implementation`. |
| Drift i386 vs x86_64 não detectado pela fábrica | Média | Baixa | Impacto limitado: a guarda levanta em ambos; apenas o ordinal difere (229 vs 0) na mensagem de exceção. |
