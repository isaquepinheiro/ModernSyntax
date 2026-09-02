---
type: implement-report
kind: artifact
title: "IMPLEMENT #62 — sete edições documentais em 4 arquivos Pascal"
description: "Sete substituições cirúrgicas de XMLDoc/comentário (nenhuma linha executável muda). FPC 3.2.2 x86_64 verde 42/42; encoding UTF-8 sem BOM preservado; nenhuma nova âncora de linha introduzida."
status: stable
cycle: 24
agent: developer
workflow: equipe-chore
node: implement
resource: aefos://run/f69e24c9cc1b815b6d73589b1c79f193
tags: [cycle-024, issue-62, chore, documentation, xmldoc, rtti, fpc]
generated:
  by: equipe-chore@node:implement
  at: "2026-09-02T00:00:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — Issue #62"
  - id: adr
    resource: "adr.md"
    title: "ADR — Issue #62"
  - id: plan
    resource: "plan.md"
    title: "PLAN — Issue #62"
  - id: task-input
    resource: "task-input.md"
    title: "TASK-INPUT — Issue #62"
---

# IMPLEMENT-REPORT — Issue #62

## O que mudou

Sete pontos cirúrgicos em quatro arquivos Pascal, um único commit lógico.
**Nenhuma linha executável muda.** Ordem de execução exatamente a do
[plan](pipeline-plan.md) — item 1 (âncora `:145`) primeiro para não depender de
contagem de linha das edições seguintes no mesmo arquivo.

| # | Arquivo | Natureza da edição |
|---|---------|--------------------|
| 1 | `Test Shared/EclbrSystem/UScenarios.RTTI.pas:145` | Âncora `:1419-1422` → nome do procedimento `Scenario_SetType_ElementType`. Ponteiro imune a crescimento do arquivo. |
| 2 | `Test Shared/EclbrSystem/UScenarios.RTTI.pas:318-321` | Declaração de `Scenario_NilHandle_AllMembers_Raises`: "cinco" → "seis"; acrescentado `Attributes` à lista; "cita o nome do membro chamado" → "é exatamente `Format(SModernRTTINilHandle, [<membro>])`". |
| 3 | `Test Shared/EclbrSystem/UScenarios.RTTI.pas:1452-1457` | Cabeçalho do corpo do mesmo cenário: mesmas duas correções do item 2. |
| 4 | `Test Delphi/EclbrSystem/UTestMS.RTTI.pas:171` | "nos cinco membros afetados" → "nos seis membros afetados". `:97` (comentário de `for..in` da #27) intacto. |
| 5 | `Test FPC/EclbrSystem/UTestMS.RTTI.pas:105` | Idem ao item 4. `:56` intacto. |
| 6 | `Source/ModernSyntax.RTTI.pas:80-82` | `<summary>` de `TModernVisibility`: parte final substituída pelo texto verbatim da §1 da issue #62 (com acentos, com "Ver #60."). |
| 7 | `Source/ModernSyntax.RTTI.pas:427-433` | Property `Attributes`: bloco `<remarks>` de nil inserido entre `</summary>` e a declaração, no mesmo formato dos cinco irmãos (`Name`, `GetProperties`, `GetFields`, `GetMethods`, `GetMethod`). |

## Tabela de arquivos modificados

| Arquivo | Âmbito | Delta |
|---------|--------|-------|
| `Source/ModernSyntax.RTTI.pas` | Produção (só XMLDoc) | +10 / −3 |
| `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | Teste (só comentários) | +9 / −8 |
| `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` | Teste (só comentário) | +1 / −1 |
| `Test FPC/EclbrSystem/UTestMS.RTTI.pas` | Teste (só comentário) | +1 / −1 |
| `.project/project-evolution.md` | Board | linha 024: 🔄 in-pipeline → 🔄 in-review |

## Decisões técnicas

### Item 1 — âncora `:1419-1422` → `Scenario_SetType_ElementType`

Substituição feita **primeiro** conforme D-62.6 do [adr](pipeline-adr.md). O
`Scenario_SetType_ElementType` é o nome do procedimento — âncora de texto
imune a deslocamento futuro (D2 do [esp](pipeline-esp.md)).

### Itens 2 e 3 — cascas idênticas (D-62.2)

As duas revisões dizem exatamente o mesmo:

- **"seis" no lugar de "cinco"** (o PR #58 acrescentou `Attributes` ao
  cenário; são seis membros que levantam `EModernRTTIError` sobre um handle
  nil — `Name`, `GetProperties`, `GetFields`, `GetMethods`, `GetMethod` e
  `Attributes`).
- **`Attributes` acrescentado à lista** de membros nos dois pontos.
- **"é exatamente `Format(SModernRTTINilHandle, [<membro>])`"** no lugar
  de "cita o nome do membro chamado" — nomeia a expressão real que o
  leitor vai procurar no código (D-62.2), depois que o PR #58 trocou o
  `Pos(...)` por igualdade estrita.

Os quatro `//` do item 3 ficaram intactos onde já estavam corretos; só as
duas frases-alvo foram tocadas. Encoding do arquivo preservado — só as
linhas-alvo mudaram.

### Itens 4 e 5 — cascas Delphi e FPC (D-62.1 + D-62.7)

Ancoragem pela frase inteira "nos cinco membros afetados" (D-62.7): há
dois "cinco" em cada casca — `:97` (Delphi) / `:56` (FPC) documenta o
`for..in` da issue #27 e é correto, não foi tocado. Confirmado por
inspeção antes de editar.

### Item 6 — texto verbatim da §1 da #62

Substituí apenas as três linhas 80-82 (a cláusula que afirma "backend FPC
valida exaustividade em compile-time"). A cláusula do Delphi (`mvAutomated`
→ `EModernRTTIError` no primeiro chamador, D-51.1) e o parágrafo aberto do
`<summary>` ficam **intactos**. O texto novo é verbatim do que a issue
propõe na §1 (D-62.5), com acentos e com "Ver #60." ao final:

```
///   no FPC os 4 ramos esgotam o `TMemberVisibility` atual
///   (`rtti.pp:308`), então o `case` sem `else` é correto **hoje** — mas
///   o FPC **tampouco** faz análise de exaustividade: medido no 3.2.2,
///   valor não mapeado compila **sem erro e sem warning** e devolve lixo
///   (229 em i386, 0 em x86_64 — e 0 é `mvPrivate`, um valor plausível).
///   Ver #60.
```

**Sobre `rtti.pp:308`:** essa citação já existia no texto removido
("4 valores em `rtti.pp:308`") e o verbatim da issue a preserva. **Não é
uma âncora de linha nova** — é a mesma citação, no mesmo arquivo, e
aponta para o RTL do FPC (`rtti.pp` do próprio compilador), não para o
código deste projeto. A proibição D-62/D2 é de âncoras de linha novas
para código do projeto; citar a linha de origem no RTL do compilador é o
próprio ponto do texto ("os 4 ramos esgotam o enum ATUAL, definido em
tal posição do RTL").

**Sobre `**bold**` no XMLDoc:** o texto proposto na issue usa markdown
`**` como ênfase. O verbatim exigido por D-62.5 preserva a marcação; o
XMLDoc não renderiza markdown, mas essa é uma decisão do autor da issue
e do ADR, não a inventar aqui.

### Item 7 — `<remarks>` de `Attributes` como cópia literal dos irmãos (D-62.3)

Bloco inserido entre `</summary>` e `property Attributes`, no mesmo
formato multi-linha dos cinco irmãos (linhas 189-192, 210-211, 225-226,
398-399, 408-409):

```
    /// <remarks>
    ///   Quando <c>IsNil = True</c>, levanta <c>EModernRTTIError</c>;
    ///   verifique <c>IsNil</c> antes de chamar.
    /// </remarks>
```

**Cópia literal, sem mencionar `PropAttributes` nem `strict private`**
(D-62.3) — o consumidor de XMLDoc quer saber *o que acontece*, não
detalhes internos. `PropAttributes` já implementa o guard idêntico
(`Source/ModernSyntax.RTTI.pas:1137-1138`), então o `<remarks>` reflete
comportamento medido, não aspiração.

## Validações rodadas

### Toolchain (por SKILL.md)

Segui `.project/SKILL.md` (seção "Toolchain and quality commands" +
"Toolchain & quality commands (agent-discovered 2026-08-28)"). Nenhuma
descoberta nova para acrescentar.

### Encoding preservado (UTF-8 sem BOM, sem reencoding)

Os quatro `.pas` continuam UTF-8 sem BOM. Medido:

```
Source/ModernSyntax.RTTI.pas                282a0a  no-BOM  (começa por "(*")
Test Shared/EclbrSystem/UScenarios.RTTI.pas 282a0a  no-BOM
Test Delphi/EclbrSystem/UTestMS.RTTI.pas    282a0a  no-BOM
Test FPC/EclbrSystem/UTestMS.RTTI.pas       282a0a  no-BOM
```

`git diff --numstat` confirma diff proporcional apenas às linhas-alvo:
`Source/ModernSyntax.RTTI.pas` 10+/3−; `UScenarios.RTTI.pas` 9+/8−;
duas cascas 1+/1−. Nenhum sinal de re-encoding.

### Build FPC 3.2.2 x86_64

```
rm -rf /tmp/fpcbuild && mkdir -p /tmp/fpcbuild
fpc -Mdelphi -Fu"Source" -Fu"Test Shared/EclbrSystem" -Fu"Test FPC/EclbrSystem" \
    -Fi"Test Shared/EclbrSystem" \
    -FU/tmp/fpcbuild -FE/tmp/fpcbuild "Test FPC/EclbrSystem/PTestRTTI.lpr"
```

- **4644 lines compiled, 1.3 sec** — link limpo.
- **10 warnings, 6 notes** — TODOS pré-existentes; nenhum introduzido por
  este PR (mesmos warnings de gerenciamento de resultado em
  `RTTI.FPC.pas:583,829` e `RTTI.pas:1088` que já estavam no `main`).
  Nenhuma linha executável muda; regressão de warnings seria impossível
  sem re-encoding.

### Suite FPCUnit x86_64

```
/tmp/fpcbuild/PTestRTTI --all -a --format=plain
```

- **Number of run tests: 42 | Number of errors: 0 | Number of failures: 0**
- Cenário mais afetado por documentação:
  `TestNilHandle_AllMembers_Raises` — passa, confirmando que o
  comportamento descrito no XMLDoc corrigido é o comportamento medido.

### Build FPC 3.2.2 i386

**NÃO executado na fábrica.** `SKILL.md` registra que `ppc386` retorna 127
no container Aefos ("NÃO ha cross-compiler i386"). Validação i386 fica
com o autor humano — declarado no PR body conforme D-62.4.

### Build Delphi

**NÃO executado na fábrica.** `SKILL.md` registra que Delphi só compila
no ambiente do autor ("Delphi — o incumbente"). Declarado no PR body.

### Guard-rail: âncora de linha nova para código do projeto

Executado `git diff | grep -E '^\+' | grep ':[0-9]{2,4}'` sobre os quatro
`.pas`. Único hit: `rtti.pp:308` no item 6 — não é código do projeto (é
o RTL do FPC), e a citação já existia no texto substituído. Nenhuma
âncora de linha nova para código deste repositório foi introduzida (D2).

## Advance do board

- `.project/project-evolution.md` linha do ciclo 024:
  `🔄 in-pipeline` → `🔄 in-review`.
- Card no GitHub project board: `mcp__aefos-dynamic-tools__aefos_gh_move_card`
  falhou com `'Project number' not found in .project/SKILL.md` — não há
  board ProjectV2 configurado para este repositório. Nada a mover.

## Caveats

- **`rtti.pp:308` no XMLDoc:** preservado da citação original (não é âncora
  nova de código do projeto). Se um reviewer estrito ler D2 como
  "nenhuma citação de linha em nenhum arquivo, incluindo RTL", o texto
  precisará ser ajustado — mas a §1 da issue #62 exige verbatim COM essa
  citação, então mudar aqui seria descumprir D-62.5.
- **`**bold**` no XMLDoc:** o texto verbatim traz `**` (markdown). XMLDoc
  não renderiza. Se o reviewer preferir remover, faço num commit de
  ajuste — mas D-62.5 pede verbatim.
- **i386 e Delphi ficam com o autor.** Fronteira declarada no PR body,
  não simulada (D-62.4 / D3).
- **Warnings pré-existentes** de `function result variable of a managed
  type does not seem to be initialized` seguem em três locais; **não são
  consequência deste PR** e são explicitamente fora de escopo (a issue é
  documental).
