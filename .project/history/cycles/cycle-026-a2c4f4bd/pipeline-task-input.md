---
type: task-input
kind: artifact
title: "TASK-INPUT #66 — Corrigir remarks falso de TModernRTTIProperty.Visibility"
description: "Handoff operacional: 2 edicoes em 1 arquivo Pascal (remarks publico + citacao ADR), um commit, varredura de aceitacao por afirmacoes de ausencia."
cycle: "026"
agent: architect
workflow: equipe-bug
node: architect
resource: aefos://run/a2c4f4bd7a43e634bf43104b21a56468
generated:
  by: "equipe-bug@node:architect"
  at: "2026-09-02T00:00:00Z"
tags: [task-input, rtti, xmldoc, documentation, bug, issue-66, modernrtti, cycle-026]
---

# TASK-INPUT — Issue #66

## Título do PR

`docs(rtti): corrigir remarks falso de TModernRTTIProperty.Visibility (issue #66)`

## Tipo / Labels

`bug`, `documentation`, `rtti`

## Pré-condição crítica

**Mergear o PR #65 antes de abrir este PR.** Este PR nasce em cima do #65;
sem o merge do #65, os dois conflitam em `RTTI.pas`.

## Escopo

2 edições em 1 arquivo Pascal. Zero linhas executáveis mudam. Nenhum teste novo.

## Arquivos impactados

| Arquivo | Linhas | Descrição |
|---------|--------|-----------|
| `Source/ModernSyntax.RTTI.pas` | 161–167 | reescrita do `<remarks>` público de `TModernRTTIProperty.Visibility` (bloqueante) |
| `Source/ModernSyntax.RTTI.pas` | 987–990 | substituição da citação `(D-42.2 do ADR issue #42)` → `(D-42.2/D-51.1/D-60.1 do ADR issues #42/#51/#60)` (free-ride) |

## Acceptance checklist

- [ ] `RTTI.pas:161-167` não afirma que o FPC não levanta; descreve a assimetria
  pelo motivo real: `TModernRTTIMethod.Visibility` levanta SEMPRE no FPC (dado ausente
  no `vmtMethodTable`); `TModernRTTIProperty.Visibility` levanta APENAS no ramo `else`,
  inalcançável com o `TMemberVisibility` atual (4 valores, `rtti.pp:308`).
- [ ] A citação de ADR no `<remarks>` é `D-42.2/D-51.1/D-60.1 do ADR issues #42/#51/#60`
  (barra, sem colchetes, nome das issues uma única vez ao final).
- [ ] `RTTI.pas:987-990` atualizado: `(D-42.2 do ADR issue #42)` → `(D-42.2/D-51.1/D-60.1 do ADR issues #42/#51/#60)`.
- [ ] O `<remarks>` **não cita** `SFPCNoVisibility` nem qualquer símbolo interno do backend.
- [ ] **Zero linha executável muda** — nenhum `begin`/`end`, nenhum `raise`, nenhum
  assignment, nenhum `{$IFDEF}`. O diff mostra apenas linhas `///` e `//`.
- [ ] Varredura `grep -rn "NAO ha raise\|nao levanta\|nunca levanta\|sem raise" Source/`
  devolve **zero** linhas contaminadas (as linhas sadias conhecidas em `:536`, `:578`,
  `:675`, `RTTI.FPC.pas:868` permanecem; não são o alvo).
- [ ] Suite FPC 3.2.2 x86_64 verde; contagem permanece 42.
- [ ] Backend Delphi intocado; `RTTI.Delphi.pas` sem diff.
- [ ] Quaisquer achados da varredura fora do escopo desta issue registrados no corpo
  do PR como "Achado — nova issue" — **não** entram no diff.

## Restrições críticas

1. **Não ampliar o diff** — se a varredura de aceitação encontrar afirmação de
   ausência contaminada em outra unit (além de `RTTI.pas:163`), registrar no PR e
   abrir nova issue; não consertar aqui.
2. **Texto estrutural, sem símbolo de backend** — o `<remarks>` descreve o
   comportamento observável (Method levanta sempre; Property levanta só no `else`),
   sem citar nomes de `resourcestring` internas.
3. **Forma canônica de citação** — `D-42.2/D-51.1/D-60.1 do ADR issues #42/#51/#60`;
   não usar colchetes nem separar por vírgula.
4. **`<summary>` não tocar** — `RTTI.pas:155-160` segue correto após o PR #65; não
   editar.
5. **`RTTI.pas:168` não tocar** — assinatura pública; não editar.

## PR body (texto a usar, verbatim)

> Correção exclusivamente documental: reescreve o `<remarks>` de
> `TModernRTTIProperty.Visibility` (`RTTI.pas:161-167`), que afirmava "aqui NAO ha
> raise no FPC" — frase que ficou falsa após o PR #65 inserir `else raise` em
> `RTTI.FPC.pas:505-507`. Alinha também a citação de ADR em `:987-990`.
>
> Zero linha executável muda. Nenhum teste novo.
>
> Compilado em FPC 3.2.2 x86_64. i386 e os 4 alvos Delphi ficam com o autor.
>
> Varredura de aceitação:
> ```
> grep -rn "NAO ha raise\|nao levanta\|nunca levanta\|sem raise" Source/
> ```
> Resultado pós-edição: zero linhas contaminadas (linhas sadias de outros membros
> em `:536`, `:578`, `:675`, `RTTI.FPC.pas:868` permanecem — falam de outros membros).

## Verificação na fábrica

```bash
# 1. Varredura de aceitação (alvo: zero linhas contaminadas)
grep -rn "NAO ha raise\|nao levanta\|nunca levanta\|sem raise" Source/

# 2. Compilar a unit isolada (confirma que os /// não quebraram sintaxe Pascal)
mkdir -p /tmp/fpcbuild
rm -f /tmp/fpcbuild/*.o /tmp/fpcbuild/*.ppu
fpc -Mdelphi -FU/tmp/fpcbuild Source/ModernSyntax.RTTI.pas
# Esperado: zero erros, zero warnings

# 3. Suite completa
rm -f /tmp/fpcbuild/*.o /tmp/fpcbuild/*.ppu
fpc -Mdelphi -FU/tmp/fpcbuild \
    -Fu"Source" -Fu"Test Shared/EclbrSystem" -Fu"Test FPC/EclbrSystem" \
    -o/tmp/fpcbuild/PTestRTTI "Test FPC/EclbrSystem/PTestRTTI.lpr"
/tmp/fpcbuild/PTestRTTI --all -a --format=plain
# Esperado: 42 testes, todos passando
```

## Referências

- Issue: [#66](https://github.com/isaquepinheiro/ModernSyntax/issues/66)
- Relatório de investigação: run `815396d406c2e93390d527508f06e778`
- Spec: [esp](pipeline-esp.md)
- ADR: [adr](pipeline-adr.md)
- Plano: [plan](pipeline-plan.md)
- ADR ciclo 025 (D-60.x): `pipeline-adr.md` (irmão no diretório do ciclo 026)
