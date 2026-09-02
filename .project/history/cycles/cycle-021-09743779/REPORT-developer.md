---
type: cycle-report
kind: report
title: "REPORT — developer (ciclo 021, issue #56)"
description: "Guarda em PropAttributes + uniformizacao dos cinco blocos (Pos → igualdade estrita) + sexto bloco Attributes em Scenario_NilHandle_AllMembers_Raises; promocao de SModernRTTINilHandle ao interface (friction do pipeline); build FPC 3.2.2 x86_64 verde, 42 testes/0 falhas."
cycle: "021"
agent: developer
workflow: equipe-bug
node: implement
resource: aefos://run/09743779c7c9860b5fa380f6979d94ca
tags: [cycle-021, issue-56, developer, nil-handle, modernrtti, rtti, attributes]
generated:
  by: "equipe-bug@node:implement"
  at: "2026-09-02T16:22:00Z"
sources:
  - id: esp
    resource: "pipeline-esp.md"
    title: "ESP — issue #56 (espelhado)"
  - id: adr
    resource: "pipeline-adr.md"
    title: "ADR — issue #56 (espelhado)"
  - id: plan
    resource: "pipeline-plan.md"
    title: "PLAN — issue #56 (espelhado)"
  - id: implement-report
    resource: "pipeline-implement-report.md"
    title: "IMPLEMENT-REPORT — issue #56 (espelhado)"
---

# REPORT — developer (ciclo 021)

## O que fiz

Entreguei o slice unico do plano em um unico commit pendente:

1. **`Source/ModernSyntax.RTTI.pas`** — guarda `if FType = nil then
   raise EModernRTTIError.CreateFmt(SModernRTTINilHandle, ['Attributes']);`
   como primeira instrucao de `PropAttributes`; comentario `// Issue #27:`
   permanece intacto em texto, so desceu de posicao (D-56.1 do ADR); ramo
   `else Result := nil` preservado (B-56.2 do ESP).
2. **`Test Shared/EclbrSystem/UScenarios.RTTI.pas`** — nos cinco blocos
   existentes (`Name`, `GetProperties`, `GetFields`, `GetMethods`,
   `GetMethod`) troquei `Pos(...) = 0` por `LMsg <> Format(SModernRTTINilHandle,
   ['<nome>'])` e reescrevi a mensagem do `Fail` para o padrao unico
   `'Mensagem de <nome> incorreta: "%s"'` (D-56.2, D-56.3). Adicionei o
   sexto bloco (`Attributes`) apos o quinto em ordem cronologica, antes
   do `end;` (D-56.4).
3. **Board local (`.project/project-evolution.md`)** — flipei o marker do
   ciclo 021 de `🔄 in-pipeline` para `🔄 in-review`.

## Ajuste tecnico necessario que o plano nao previa

A `resourcestring SModernRTTINilHandle` estava em `implementation`
(linhas 892-893 originais) — invisivel para consumidores. O padrao
especificado no ESP/ADR/plan (`Format(SModernRTTINilHandle, ['<nome>'])`
no cenario compartilhado) nao compila com ela privada — o primeiro
rebuild deu seis erros `Identifier not found "SModernRTTINilHandle"`.

Decisao: promovi apenas essa `resourcestring` para o `interface` (bloco
proprio apos `EModernRTTIError`, com XMLDoc explicando por que foi
exposta — passou a ser contrato observavel comparado por igualdade
estrita). Alternativas (repetir o literal no cenario; manter `Pos`)
contradiziam a ADR. Registrado em [FLOW-FEEDBACK](FLOW-FEEDBACK.md) para
o arquiteto rever se prefere fixar essa consequencia no ESP/ADR de
futuras issues.

## Validacoes rodadas (comandos de qualidade)

Comando canonico do [SKILL](../../../SKILL.md) (secao "Toolchain & quality
commands", agent-discovered 2026-08-28):

```bash
rm -rf /tmp/fpcbuild && mkdir -p /tmp/fpcbuild
fpc -Mdelphi \
    -Fu"Source" -Fu"Test Shared/EclbrSystem" -Fu"Test FPC/EclbrSystem" \
    -FU/tmp/fpcbuild -FE/tmp/fpcbuild \
    "Test FPC/EclbrSystem/PTestRTTI.lpr"
/tmp/fpcbuild/PTestRTTI --all -a --format=plain
```

**Resultado:** compilou (4621 linhas, 1.2s, warnings/notes todos pre-existentes),
`PTestRTTI --all -a --format=plain` executou **42 testes, 0 erros, 0 falhas**.
`TestNilHandle_AllMembers_Raises` presente e verde — cobre os seis membros.
`TestAttributes_ForIn_IteratesAttributes` e `TestRecordType_NameAndSize`
continuam verdes (nao-regressao: `Attributes` sobre handle valido de classe
funciona; sobre record continua devolvendo vazio sem excecao).

## Fronteira do ciclo (para o PR)

Rodei apenas FPC 3.2.2 x86_64. Container nao tem `ppc386` (`error code:
127`) nem `dcc32`. Alvos FPC i386, Delphi Win32, Delphi Win64 ficam com
o mantenedor (D-56.6, padrao herdado da serie #43–#49). Texto literal
que o committer deve incluir no PR esta na secao 5 do
[implement-report](pipeline-implement-report.md).

## Handoff

- Committer: um unico commit com os tres passos + a promocao da
  `resourcestring`; mensagem sugerida no plano (§ Commit). Referenciar
  a issue #56.
- Review/test/verify: comparar contra [ESP §4](pipeline-esp.md) e ADR;
  atencao especial ao ramo `else Result := nil` (nao pode ter colapsado
  o vazio legitimo).
