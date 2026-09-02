---
type: spec
kind: artifact
title: "ESP #66 — Corrigir XMLDoc falso de TModernRTTIProperty.Visibility (RTTI.pas:161-167)"
description: "Especificacao formal: reescrever o bloco remarks publico e alinhar citacao de ADR no comentario de implementacao; zero linhas executaveis mudam."
cycle: "026"
agent: architect
workflow: equipe-bug
node: architect
resource: aefos://run/a2c4f4bd7a43e634bf43104b21a56468
generated:
  by: "equipe-bug@node:architect"
  at: "2026-09-02T00:00:00Z"
tags: [spec, rtti, xmldoc, documentation, bug, issue-66, modernrtti, cycle-026]
---

# ESP #66 — Corrigir XMLDoc falso de `TModernRTTIProperty.Visibility`

## 1. Objetivo

Reescrever o bloco `<remarks>` público de `TModernRTTIProperty.Visibility` em
`Source/ModernSyntax.RTTI.pas:161-167` para que deixe de afirmar "aqui NAO ha
raise no FPC" — frase que se tornou **falsa** após o PR #65 inserir
`else raise EModernRTTIError` em `Source/ModernSyntax.RTTI.FPC.pas:505-507`.

Simultaneamente, alinhar a citação de ADR no comentário de implementação em
`Source/ModernSyntax.RTTI.pas:987-990`: trocar `(D-42.2 do ADR issue #42)` por
`(D-42.2/D-51.1/D-60.1 do ADR issues #42/#51/#60)`.

Zero linhas executáveis mudam. Nenhum teste novo.

## 2. Contexto

O PR #65 (issue #60) inseriu `else raise EModernRTTIError.CreateFmt` no
`PropertyVisibility` do backend FPC (`RTTI.FPC.pas:505-507`). Esse código é
correto e já está mergeado (ou em via de merge).

O bloco `<remarks>` de `TModernRTTIProperty.Visibility` em `RTTI.pas:161-167`
— que não foi tocado pelo PR #65 — continua afirmando "aqui NAO ha raise no
FPC". Essa frase era verdadeira no `main` antes do PR #65; depois dele, é
**falsa**. O mesmo arquivo já descreve, em `RTTI.pas:79-81`, que ambos os
backends levantam `EModernRTTIError` — criando contradição visível dentro da
mesma `interface`.

A armadilha de varredura que gerou esta issue: `RTTI.pas:163` não cita o número
da issue nem palavras-chave de exaustividade, então qualquer grep por `#60` ou
`exaustividade` a ignora. O gatilho correto é varrer por **afirmações de
ausência** (`NAO ha raise`, `nao levanta`, `nunca levanta`, `sem raise`) sempre
que um backend ganha um `raise` novo.

## 3. Escopo

**1 arquivo, 2 edições. Zero linhas executáveis.**

| # | Arquivo | Linhas | Tipo de mudança |
|---|---------|--------|-----------------|
| 1 | `Source/ModernSyntax.RTTI.pas` | 161–167 | reescrita do `<remarks>` público (bloqueante) |
| 2 | `Source/ModernSyntax.RTTI.pas` | 987–990 | atualização da citação de ADR no comentário de implementação (free-ride) |

## 4. Fora do escopo

- Backends (`RTTI.FPC.pas`, `RTTI.Delphi.pas`) — intocados; o código executável
  inserido pelo PR #65 permanece exatamente como está.
- Testes — a suite FPC permanece com 42 procedimentos; nenhum cenário novo.
- Header da unit (`RTTI.pas:19-21`) — sem `{$IFDEF}` novo.
- Bloco `<summary>` de `TModernRTTIProperty.Visibility` (`RTTI.pas:155-160`) —
  segue verdadeiro após o PR #65; não tocar.
- Outros sítios de afirmação de ausência já verificados e sadios:
  `RTTI.pas:536`, `:578`, `:675`, `RTTI.FPC.pas:868` — tratam de outros
  membros e permanecem verdadeiros.
- Qualquer drift adicional encontrado pela varredura de aceitação fora do
  escopo desta issue — registrar no corpo do PR como "Achado — nova issue";
  não ampliar o diff.

## 5. Regras de negócio e restrições

1. **`<remarks>` descreve a assimetria estruturalmente** — sem citar
   `SFPCNoVisibility` nem qualquer símbolo interno do backend. Descrever:
   `TModernRTTIMethod.Visibility` levanta **SEMPRE** no FPC (o dado não existe
   no `vmtMethodTable`); `TModernRTTIProperty.Visibility` levanta **APENAS** no
   ramo `else`, inalcançável com o `TMemberVisibility` atual.
2. **Âncora externa `rtti.pp:308`** — a quantidade de valores atuais de
   `TMemberVisibility` é ancorada em `rtti.pp:308` (código externo do FPC RTL),
   não em linha do próprio repo. Precedente estabelecido: `RTTI.pas:157`, `:280`,
   `:335`.
3. **Forma canônica de citação de ADR** — `D-42.2/D-51.1/D-60.1 do ADR issues
   #42/#51/#60` (barra, sem colchetes, nome das issues uma única vez ao final).
   Padrão medido no repo 5×.
4. **Um único commit** — as duas edições vivem no mesmo `<remarks>` conceitual;
   reverter uma sem a outra deixaria o bloco incoerente.
5. **Varredura de aceitação sobre `Source/` inteira** — antes de abrir o PR,
   rodar `grep -rn "NAO ha raise\|nao levanta\|nunca levanta\|sem raise" Source/`.
   Alvo: **zero** afirmações contaminadas relacionadas ao sítio Visibility. As
   linhas sadias já mapeadas permanecem — elas falam de outros membros.

## 6. Critérios de aceitação

- [ ] `RTTI.pas:161-167` não afirma que o FPC não levanta; descreve a assimetria
  pelo motivo real: Method levanta SEMPRE no FPC (dado ausente no `vmtMethodTable`);
  Property levanta APENAS no ramo `else`, inalcançável com o `TMemberVisibility`
  atual (4 valores, `rtti.pp:308`).
- [ ] A citação de ADR no bloco `<remarks>` inclui `D-51.1/D-60.1` ao lado de
  `D-42.2` — forma `D-42.2/D-51.1/D-60.1 do ADR issues #42/#51/#60`.
- [ ] `RTTI.pas:987-990` alinhado: `(D-42.2 do ADR issue #42)` → `(D-42.2/D-51.1/D-60.1 do ADR issues #42/#51/#60)`.
- [ ] **Zero linha executável muda.** Nenhum teste novo.
- [ ] Varredura `grep -rn "NAO ha raise\|nao levanta\|nunca levanta\|sem raise" Source/`
  devolve **zero** linhas contaminadas (linhas sadias de outros membros não contam).
- [ ] Suite FPC verde nos dois bitness (fábrica prova x86_64; i386 e Delphi nos 4
  alvos ficam com o autor — fronteira declarada e não simulada).

## 7. Riscos

| Risco | Probabilidade | Impacto | Mitigação |
|-------|--------------|---------|-----------|
| Novo `<remarks>` introduz afirmação equivocada sobre o FPC | Baixa | Médio | Texto aprovado na investigação; describe estruturalmente, sem afirmações sobre exaustividade em compile-time. |
| Âncora `rtti.pp:308` envelhece se o FPC mover a linha | Baixa | Baixo | Precedente declarado e aceito (`:157`, `:280`, `:335`); qualquer drift nessa linha é detectável por revisão. |
| Varredura encontra drift adicional e dev amplia diff | Baixa | Médio | Restrição explícita: achados fora do escopo desta issue vão no corpo do PR como "Achado — nova issue"; não entram no diff. |
