---
type: implement-report
kind: artifact
title: "IMPLEMENT-REPORT — issue #51: else raise nos dois sites de Visibility (backend Delphi)"
description: "Slice unico entregue: resourcestring privada SDelphiUnknownVisibility + else raise em MethodVisibility/PropertyVisibility + reescrita dos 2 comentarios + reescrita do XML-doc de TModernVisibility. FPC x86_64 verde (42/42)."
status: stable
cycle: "022"
agent: developer
workflow: equipe-bug
node: implement
resource: aefos://run/de0826deb51365cb442a8acd3e0fd103
tags: [implement-report, modernrtti, rtti, issue-51, bug, delphi, visibility]
generated:
  by: "equipe-bug@node:implement"
  at: "2026-09-02T00:00:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — issue #51"
  - id: plan
    resource: "plan.md"
    title: "PLAN — issue #51"
  - id: adr
    resource: "adr.md"
    title: "ADR D-51.1 — issue #51"
  - id: task-input
    resource: "task-input.md"
    title: "TASK-INPUT — issue #51"
---

# IMPLEMENT-REPORT — issue #51

## Escopo entregue

Slice unico (`fits`), commit unico. Executados os 6 passos do
[plan](pipeline-plan.md), na ordem: passo 0 (resourcestring) -> passos 1-2 (`else
raise` em `MethodVisibility` e `PropertyVisibility`) -> passos 3-4
(reescrita dos comentarios) -> passo 5 (XML-doc de `TModernVisibility`).

## Arquivos modificados

| Arquivo | Trecho | Mudanca |
|---------|--------|---------|
| `Source/ModernSyntax.RTTI.Delphi.pas` | `implementation`, apos `SSetWrongKind` (~linha 155) | Passo 0: nova resourcestring `SDelphiUnknownVisibility` + comentario D-51.3 explicando por que fica na `implementation` (contraste com PR #58) |
| `Source/ModernSyntax.RTTI.Delphi.pas` | `MethodVisibility` (linhas 307-347) | Passos 1 + 3: `else raise EModernRTTIError.CreateFmt(SDelphiUnknownVisibility, [Ord(TRttiMethod(AToken).Visibility), 'MethodVisibility'])` antes do `end;`; comentario D-42.2 substituido por D-51.1 (novo framing: fail-loud vs. errado-em-silencio; enum do RTL vs. da casca; ramo inalcancavel por dado real; qualificacao dos labels preservada) |
| `Source/ModernSyntax.RTTI.Delphi.pas` | `PropertyVisibility` (linhas 349-378) | Passos 2 + 4: `else raise` identico, com `TRttiProperty(AToken).Visibility` e `'PropertyVisibility'`; comentario reescrito (mesmo framing D-51.1); nota sobre `AOwner` preservada (justifica `%s = nome da funcao` em vez de `%s = owner`) |
| `Source/ModernSyntax.RTTI.pas` | `TModernVisibility` XML-doc (linhas 71-83) | Passo 5: frase antiga ("o `case` explicito nos backends (D-42.2) acusa erro no primeiro build") substituida por "o backend Delphi levanta `EModernRTTIError` no primeiro chamador (D-51.1); o backend FPC valida exaustividade em compile-time" |
| `.project/project-evolution.md` | linha 33 (issue #51) | Estado do ciclo 022 avancado: `🔄 in-pipeline` -> `🔄 in-review` |

**Nao tocado (conforme escopo declarado):**
- `Source/ModernSyntax.RTTI.FPC.pas` — inalterado (D-51.8).
- Qualquer arquivo em `Test Shared/`, `Test Delphi/`, `Test FPC/` —
  inalterado (D-51.7: ramo `else raise` inalcancavel por dado real).

## Decisoes tecnicas locais

- **Local da resourcestring:** anexei `SDelphiUnknownVisibility` ao BLOCO
  `resourcestring` existente da `implementation` (apos `SSetWrongKind`),
  em vez de abrir um bloco novo. Motivo: o padrao vigente do arquivo e
  UM bloco `resourcestring` unico na `implementation` (linhas 126-155
  originais reunem `SEnum*`, `SPointer*`, `SRecord*`, `SArray*`, `SSet*`).
  Um segundo bloco fragmentaria o padrao sem ganho.
- **Enum no `Ord(...)`:** confirmado como `TRttiMethod(AToken).Visibility`
  / `TRttiProperty(AToken).Visibility` (o `TMemberVisibility` do RTL), NAO
  `TModernVisibility` da casca — reporta o ordinal REAL que o RTL passou
  (task-input nota 2, ESP R-51.2).
- **Comentarios expandidos alem do minimo pedido:** os dois comentarios
  novos citam explicitamente a medicao (`run
  2e4913d83ea2e1f06b3d8e8589bcbc4f`, valores 204/16/252/16 por bitness) e
  a assimetria do desempate (`else cast` vs. `else raise` matam W1035
  igualmente — o desempate e semantico, nao warning). O plan §Passo 3
  pedia "framing correto" e o ADR D-51.2 documenta o desempate com esse
  conteudo; escrever isso no comentario evita que a proxima pessoa releia
  o ADR inteiro para entender por que nao foi `else cast`.
- **Preservacao das notas obrigatorias:**
  - `MethodVisibility`: paragrafo sobre qualificacao dos case labels
    (`TMemberVisibility.` vs. `TModernVisibility.`) preservado literalmente.
  - `PropertyVisibility`: nota "seria ruido — AOwner ficaria morto"
    preservada e atualizada para citar D-51.5 (que preserva D-42.6);
    reformulada para amarrar explicitamente com a escolha do `%s` na
    mensagem.

## Validacoes executadas

Toolchain seguindo `.project/SKILL.md` (secoes agent-discovered
2026-08-28 e 2026-08-31).

**Build FPC x86_64 do binario de testes `PTestRTTI`:**

```
rm -rf /tmp/fpcbuild && mkdir -p /tmp/fpcbuild && \
fpc -Mdelphi \
    -Fu"Source" -Fu"Test Shared/EclbrSystem" -Fu"Test FPC/EclbrSystem" \
    -Fi"Test Shared/EclbrSystem" \
    -FU/tmp/fpcbuild -FE/tmp/fpcbuild \
    "Test FPC/EclbrSystem/PTestRTTI.lpr"
```

Resultado: `4622 lines compiled, 1.2 sec` — link OK. Os 10 warnings e 6
notes emitidos sao os PRE-EXISTENTES do repo (unit `Rtti` experimental,
resultados de funcao gerenciada nao inicializados em
`ModernSyntax.RTTI.FPC.pas` linhas 583/832 e em `RTTI.pas` linha 1081,
`unreachable code` em `Invoker.pas:80`, notas de `generics.collections`).
Nenhum warning novo foi introduzido por esta mudanca no lado FPC — o
codigo tocado em `RTTI.pas` foi so o texto do XML-doc.

**Execucao dos testes:**

```
/tmp/fpcbuild/PTestRTTI --all -a --format=plain
```

Resultado:

```
Number of run tests: 42
Number of errors:    0
Number of failures:  0
```

Os dois cenarios de Visibility ativos no FPC (`TestMethod_Visibility_
FPC_Raises` e `TestProperty_Visibility_Returns_mvPublished`, tabela do
ESP §4) passaram junto com os outros 40. FPC nao exercita o backend
Delphi; a cobertura Delphi (`Scenario_Method_Visibility_Delphi_Returns_
mvPublished` na casca DUnitX) fica com o mantenedor.

## O que NAO foi provado nesta fabrica

- **Delphi 23.0 x Win32/Win64 e Delphi 37.0 x Win32/Win64** — os 4 alvos
  onde o W1035 foi medido. A fabrica nao tem `dcc32`/`bcc32` (SKILL.md
  agent-discovered 2026-08-28 confirma "Zero cobertura Delphi na
  fabrica"). O acceptance §1 do task-input ("W1035 zerado nos 4 alvos
  Delphi") fica com o mantenedor humano antes do merge — e argumentado
  em D-51.2 do ADR: tanto `else cast` quanto `else raise` matam W1035
  igualmente nos 4 alvos, e o `else raise` desta implementacao segue a
  mesma forma que a medicao usou.
- **FPC i386** — sem cross-compiler na fabrica (`ppc386` retorna 127).
  Fica com o mantenedor.

O PR deve declarar literalmente:

> "ciclo rodou FPC x86_64 no container. i386 e os 4 alvos Delphi nao
> foram executados nesta fabrica — ficam com o mantenedor antes do merge."

## Caveats / riscos residuais

- **R-51.1 (nota sobre `AOwner` apagada):** revisor pode conferir no
  diff que o texto "AOwner ficaria morto" ainda existe em
  `PropertyVisibility`. Verificado durante a implementacao — presente
  no comentario correspondente ao passo 4.
- **R-51.2 (enum errado no `Ord`):** verificado nos dois sitios que o
  cast e `TRttiMethod(AToken).Visibility` / `TRttiProperty(AToken).
  Visibility`, produzindo o ordinal do `TMemberVisibility` do RTL.
- **R-51.3 (promocao acidental para `interface`):**
  `SDelphiUnknownVisibility` esta na `implementation` (apos
  `SSetWrongKind`), nunca aparece na `interface`. Verificavel pelo diff.
- **Ramo `else raise` inalcancavel por dado real:** confirmado por
  D-51.7 do ADR — `TMemberVisibility` do Delphi tem 4 valores em
  `System.TypInfo.pas:232`. Cobertura executavel do ramo dependeria de
  um enum estendido; documentado no comentario, sem novo cenario.

## Handoff

Proximos nos do workflow: review/test/verify. Se algum deles rejeitar,
o proximo `implement` re-le este relatorio + os reports de rejeicao em
`.project/pipeline/` e aborda cada finding.
