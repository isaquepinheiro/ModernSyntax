---
type: task-input
kind: artifact
title: "TASK-INPUT #60 — else raise no PropertyVisibility do backend FPC"
description: "Handoff operacional: 4 edicoes em 2 arquivos Pascal (resourcestring + else raise + comentario + XMLDoc), um commit, PR com declaracao de fronteira de plataforma."
cycle: "025"
agent: architect
workflow: equipe-bug
node: architect
resource: aefos://run/4c9ae8e8f3b0ca77a166f343e7d3f098
generated:
  by: "equipe-bug@node:architect"
  at: "2026-09-02T00:00:00Z"
tags: [task-input, fpc, rtti, visibility, bug, issue-60, modernrtti, cycle-025]
---

# TASK-INPUT — Issue #60

## Título do PR

`fix(rtti-fpc): else raise EModernRTTIError no PropertyVisibility (issue #60)`

## Tipo / Labels

`bug`, `fpc`, `rtti`

## Escopo

4 edições em 2 arquivos Pascal. A única linha executável nova é o `else raise`.

## Arquivos impactados

| Arquivo | Edições | Descrição |
|---------|---------|-----------|
| `Source/ModernSyntax.RTTI.FPC.pas` | 3 | + `SFPCUnknownVisibility` (resourcestring); reescrita do comentário; + `else raise` |
| `Source/ModernSyntax.RTTI.pas` | 1 | reescrita do XMLDoc de `TModernVisibility` (linhas 79–85) |

## Acceptance checklist

- [ ] `PropertyVisibility` em `RTTI.FPC.pas` tem `else raise EModernRTTIError.CreateFmt(SFPCUnknownVisibility, [Ord(TRttiProperty(AToken).Visibility), 'PropertyVisibility'])` dentro do `case`.
- [ ] `SFPCUnknownVisibility` na seção `resourcestring` da **`implementation`** de `RTTI.FPC.pas`; zero símbolo novo na interface.
- [ ] Comentário de `PropertyVisibility` não afirma que o `else` seria código morto; descreve o comportamento medido (sem erro, sem warning, ordinal 229/i386, 0 = `mvPrivate`/x86_64) como razão histórica.
- [ ] Comentário cita #51 e #60 como primeiro e segundo movimento da mesma decisão.
- [ ] XMLDoc de `TModernVisibility` (`RTTI.pas:79–85`) descreve o comportamento dos dois backends após as guardas; medição no passado; sem afirmação de exaustividade em compile-time no FPC.
- [ ] PR não afirma redução de warning (não havia warning no FPC antes da fix).
- [ ] PR declara que o ramo `else` é inalcançável por dado real e por quê.
- [ ] Suite FPC 3.2.2 x86_64 verde; contagem permanece 42.
- [ ] Backend Delphi intocado; `RTTI.Delphi.pas` sem diff.

## PR body (texto a usar, verbatim)

> Compilado em FPC 3.2.2 x86_64. i386 e os 4 alvos Delphi ficam com o autor.
>
> O ramo `else raise` é inalcançável por dado real: o valor vem de
> `TRttiProperty(AToken).Visibility`, RTTI real, não injetável. Não há
> redução de warning — o FPC 3.2.2 nunca emitiu warning para este padrão
> (Delphi emite W1035; FPC compila limpo). A guarda protege contra crescimento
> futuro de `TMemberVisibility`, não contra dado atual.

**Sem checklist de combinações** — caixas marcadas sem execução comprometem a
confiabilidade do PR (padrão derivado de D-62.4 / aefos-studio#375).

## Restrições críticas

1. **`SFPCUnknownVisibility` na `implementation`**, nunca na `interface`.
   Verificar no diff que a adição está após `SFPCNoParamType` (linha 193), dentro
   do bloco `implementation`.
2. **Simetria com o Delphi** — a string segue o padrão literal de
   `SDelphiUnknownVisibility` em `RTTI.Delphi.pas:163-165`, trocando apenas `#51`
   → `#60`. Qualquer variação textual seria drift novo.
3. **Não divergir do texto aprovado na investigação** — o XMLDoc e o comentário
   do FPC foram acordados palavra a palavra. Ver [plan](pipeline-plan.md) para o texto exato.
4. **Medição no passado** — o XMLDoc descreve o que *era* antes das guardas, não
   o que o compilador faz hoje. Não introduzir afirmação nova sobre exaustividade
   ou comportamento do FPC.

## Verificação na fábrica

```bash
# Compilar a unit isolada (verificação de sintaxe)
mkdir -p /tmp/fpcbuild
rm -f /tmp/fpcbuild/*.o /tmp/fpcbuild/*.ppu
fpc -Mdelphi -FU/tmp/fpcbuild Source/ModernSyntax.RTTI.FPC.pas
# Esperado: zero erros, zero warnings

# Suite completa (substituir PTestRTTI pelo nome real do lpr de testes RTTI do FPC)
rm -f /tmp/fpcbuild/*.o /tmp/fpcbuild/*.ppu
fpc -Mdelphi -FU/tmp/fpcbuild \
    -Fu"Source" -Fu"Test Shared/EclbrSystem" -Fu"Test FPC/EclbrSystem" \
    -o/tmp/fpcbuild/PTestRTTI "Test FPC/EclbrSystem/PTestRTTI.lpr"
/tmp/fpcbuild/PTestRTTI --all -a --format=plain
# Esperado: 42 testes, todos passando
```

## Referências

- Issue: [#60](https://github.com/isaquepinheiro/ModernSyntax/issues/60)
- Relatório de investigação: run `b33995300ee8f88b88df1cf389b6248b`
- Spec: [esp](pipeline-esp.md)
- ADR: [adr](pipeline-adr.md)
- Plano: [plan](pipeline-plan.md)
- ADR ciclo 022 (D-51.x): `/history/cycles/cycle-022-de0826de/pipeline-adr.md`
