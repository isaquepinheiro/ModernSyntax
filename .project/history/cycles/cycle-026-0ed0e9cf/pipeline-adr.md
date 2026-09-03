---
type: adr
kind: artifact
title: "ADR #6 — estrategia de correcao para os 10 itens de texto do bundle OKF"
description: "Decisoes de como aplicar as 10 correcoes de texto no bundle, derivadas da investigacao run 0bc05ff9b241c9abcd326272568f1086."
cycle: "026"
agent: architect
workflow: equipe-chore
node: architect
resource: aefos://run/0ed0e9cf6250cee7ab26731ee07d3ccc
generated:
  by: "equipe-chore@node:architect"
  at: "2026-09-02T00:00:00Z"
tags: [adr, okf, bundle, text-correction, chore, issue-6, cycle-026]
---

# ADR #6 — Estratégia de correção para os 10 itens de texto do bundle OKF

> Este ADR **deriva** do relatório de investigação escrito em run
> `0bc05ff9b241c9abcd326272568f1086` (comment na issue #6,
> `isaquepinheiro/ModernSyntax`). As decisões abaixo são as que foram
> **acordadas naquela discussão**; qualquer divergência é declarada
> explicitamente.

## Contexto

O bundle `.project/analysis/` foi auditado em três rodadas (2026-08-27) e
aprovado com ressalvas — números divergentes e âncoras fora do lugar. A
issue #6 listou 11 itens + 2 ausências declaradas. A investigação derrubou
2 itens (11 e `.inc`) após medição contra `main 8d4275b`, e separou 2
achados estruturais em issues próprias.

## Decisões acordadas

### D-1: 10 itens editados, 2 verificados sem edição

**Decidido:** Os itens 1..10 são editados. Item 11 e o item `.inc` são
**verificados sem edição**.

**Motivo:** Medição contra `main 8d4275b` mostrou que o arquivo já contém
a correção pedida no item 11 (`05-conventions.md:267/270/271` já diz
"VER220" / "starts at Delphi XE"). Para o `.inc`, `grep -E '\{\$ELSE +[A-Za-z]'
Source/ModernSyntax.inc` retorna 0 — o construto real em `:271` é
`{$ELSEIF Defined(DELPHI16_UP)}`, válido; `HAS_ENCDDECD` está no
`{$ELSE}` alcançável em `:273`. Editar o que já está correto produziria
mudança sem causa.

**Descartado:** Editar item 11 ou o `.inc`. Recusado — a afirmação da issue
não se sustenta na leitura do arquivo em `main`.

---

### D-2: Item 1 usa o intervalo medido (32-50), não o da issue nem o do dossiê

**Decidido:** `TCaseType` abre em `Match.pas:32` e fecha em `:50`. Correção
vai para **32-50 medido**.

**Motivo:** A issue afirma 33-49 (erra os dois lados). O dossiê afirma 32-51
(off-by-one no fechamento — linha 51 é em branco). A medição é a fonte
de autoridade; não se aceita o intervalo de nenhuma das duas fontes sem
verificação.

**Descartado:** `33-49` (da issue) e `32-51` (do dossiê). Ambos derrubados
por medição direta do código.

---

### D-3: Finding A sai deste PR — vira issue própria

**Decidido:** O defeito de `Map<R>` (`ResultPair.pas:832-844`, que faz
`AsType<S>` in-place causando `EInvalidCast` em runtime quando `R` não
converte para `S`) **não entra neste PR**.

**Motivo:** Pela lição da aefos-studio#375, achado de código novo deve
nascer no corpo de uma issue própria com medição — não pendurado no escopo
de uma issue de correção de texto.

**Descartado:** Incluir Finding A neste PR. Recusado — perde na revisão e
não tem corpo medido próprio.

---

### D-4: Item 10 leva número datado com o comando ao lado

**Decidido:** `→ 2 475 (medido 2026-09-02: grep -rc '///' Source/*.pas)`.
Nota adicional de que a contagem de unidades cresceu de 16 para 22.

**Motivo:** Convenção da casa — todo número no bundle vem com o comando que
o gerou, ao lado. Nota de drift sem número é mais vaga, não mais honesta.

---

### D-5: Item 8 acrescenta frase citando PR #7

**Decidido:** Uma linha ao final dos números de linha corrigidos:
"posições atualizadas após PR #7 no bloco de `ResultPair.pas`".

**Motivo:** PR #7 em `ResultPair.pas` causou o deslocamento de
`_DestroySuccess`/`_DestroyFailure`. Citar o PR preserva a trilha de causa
e evita que o próximo leitor gaste tempo investigando de onde veio o
deslocamento.

---

### D-6: Issue-companheira de cadência aberta agora, com corpo medido

**Decidido:** A raiz da drift (bundle fechado em 27/08; `Source/` teve 8 PRs
desde então) vira issue própria. Não fica como rodapé de
`05-conventions.md`.

**Motivo:** Uma nota de rodapé não sobrevive ao squash desta issue e não
impede a repetição. A issue carrega o argumento inteiro.

---

### D-7: Um único commit; mensagem enumera itens com desfecho, não contagem de edições

**Decidido:** Um commit. Mensagem cita itens 1..10 como editados; item 11 e
`.inc` como "verificado, não editado". Não anuncia contagem de edições.

**Motivo:** Número de edições é derivado do diff e apodrece na revisão.
Número de itens com desfecho é verificável e não muda. Mesmo princípio da
ancoragem por símbolo, não por linha (issue #64, generalizada na volta 2
da investigação).

---

### D-8: Varredura de cross-refs antes de cada edição

**Decidido:** Antes de cada edição, rodar:
`grep -rn "593|597|1 581|14-variant|12.*INumeric|FError|Byte>" .project/analysis/`.

**Motivo:** Cross-refs internas ao bundle podem citar os valores antigos.
A varredura detecta referências órfãs antes que o commit as fixe.

## O que não muda

Nenhum código de produção muda. Todas as 10 edições são texto em markdown
sob `.project/analysis/`. Nenhuma interface, contrato, schema, API ou teste
é alterado.
