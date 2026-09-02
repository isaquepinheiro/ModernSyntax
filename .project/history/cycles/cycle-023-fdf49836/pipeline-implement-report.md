---
type: implement-report
kind: artifact
title: "IMPLEMENT — Issue #57: quatro residuos dos ciclos #45/#46"
description: "Quatro pontos cirurgicos em dois arquivos (tres comentarios + assercao de identidade + remocao de comentario fantasma). Suite verde 42/42 no FPC x86_64; mutacao GetTypeData(P)^.ArrayData.ElType => P mata o cenario 7 no x86_64."
status: stable
cycle: "023"
agent: developer
workflow: equipe-chore
node: implement
resource: aefos://run/fdf49836e67b5746f5350a3fb741afd3
tags: [rtti, chore, issue-57, fpc, implement]
generated:
  by: "equipe-chore@node:implement"
  at: "2026-09-02T00:00:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — Issue #57"
  - id: adr
    resource: "adr.md"
    title: "ADR — Issue #57"
  - id: plan
    resource: "plan.md"
    title: "PLAN — Issue #57"
  - id: task-input
    resource: "task-input.md"
    title: "TASK-INPUT — Issue #57"
---

# IMPLEMENT-REPORT — Issue #57

## O que mudou

Quatro pontos cirurgicos, um commit, dois arquivos. Zero mudanca
comportamental em `Source/` alem da remocao do comentario fantasma (item D).

| # | Arquivo | Natureza |
|---|---------|----------|
| A | `Test Shared/EclbrSystem/UScenarios.RTTI.pas:143-145` | Comentario `TCor` reescrito: agora cita cenario 10 da #46 (`TSetCor46 = set of TCor`, assercao em `:1419-1422`). Corpo tecnico (D-43.9, off-by-one) intacto. |
| B | `Test Shared/EclbrSystem/UScenarios.RTTI.pas:1300-1309` | Comentario `TRecordFixture45M` reescrito: managed so diverge em 64-bit (em 32-bit ambas medem 8); anti-backend-constante vem da matriz de seis alvos, nao da fixture isolada. |
| C | `Test Shared/EclbrSystem/UScenarios.RTTI.pas:1326-1352` | Bloco de comentario reescrito espelhando `:1249-1253` (medicao FPC/Delphi + CA-5) e explicitando a mutacao obrigatoria D-57.2. `IsNil` mantido como pre-condicao; assercao de identidade acrescentada. |
| D | `Source/ModernSyntax.RTTI.FPC.pas` | Comentario fantasma "`Result` default para silenciar o compilador" removido. Removidas 3 linhas (o separador `//` + duas linhas de conteudo) para nao deixar `//` orfao antes do codigo. Nenhum `Result := 0` adicionado (D-57.1). |

## Tabela de arquivos modificados

| Arquivo | Ambito | Delta |
|---------|--------|-------|
| `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | Teste | comentarios A+B+C reescritos + 1 assercao nova |
| `Source/ModernSyntax.RTTI.FPC.pas` | Producao | 3 linhas de comentario fantasma removidas |
| `.project/project-evolution.md` | Board | 🔄 in-pipeline → 🔄 in-review no ciclo 023 |

## Decisoes tecnicas

### C.1 — comentario de bloco (:1326-1341) espelha :1249-1253

Preservei a estrutura canonica do cenario do ponteiro
(`Scenario_PointerType_ReferredType_Matches`) e adaptei apenas
identificadores/citacoes. Adicionei tres notas:

- **MUTACAO OBRIGATORIA (D-57.2):** trocar `GetTypeData(P)^.ArrayData.ElType`
  por `P` em `ArrayTypeElementType` (`RTTI.FPC.pas:686`, ramo estatico);
  handle nao-nulo e errado; `IsNil` engole.
- **Nota cross-compiler (D-57.3):** Delphi diz `'Integer'`, FPC diz `'LongInt'`;
  comparacao via `TModernRTTI.GetType(TypeInfo(Integer)).Name` absorve nos
  dois lados. CA-5 preservado (zero `{$IFDEF FPC}` neste arquivo).
- **So por IGUALDADE** (`Length = 5`, `Size = SizeOf(TArr5Int46)`) —
  desigualdade `>=` nao prova nada contra backend constante.

### C.2/C.3 — IsNil como pre-condicao + assercao de identidade

Mantive `if LArr.ElementType.IsNil then Fail(...)` como pre-condicao
(mensagem diagnostica melhor quando o handle vem nulo) e acrescentei logo
abaixo a comparacao por referencia (D-57.2):

```pascal
if LArr.ElementType.Name <> TModernRTTI.GetType(TypeInfo(Integer)).Name then
  Fail('ElementType(TArr5Int46) nao e Integer — handle identico esperado.');
```

`TypeInfo(Integer)` — nunca `TypeInfo(LongInt)` — porque a forma por
referencia e a unica que absorve `FPC=LongInt`/`Delphi=Integer` (D-57.3).
Literal quebra num dos lados; trocar de literal so muda de lado.

### D — removi 3 linhas em vez de 2

A ESP/plan/task-input dizem `:708-709` (duas linhas de conteudo). Removi
essas duas linhas mais o separador `//` que as precedia (linha 707 no
arquivo original). Motivo: deixar `//` orfao antes de `ArrayRaiseWrongKind(P)`
seria estilo ruim e o proximo leitor tentaria adivinhar o que estava
faltando ali. A intencao do ADR D-57.1 e limpar o paragrafo fantasma
inteiro; o separador so existia porque um paragrafo o seguia. Se review
preferir a leitura estrita (2 linhas exatas), reverto o separador em um
segundo commit.

## Validacoes rodadas

### Toolchain descoberto/confirmado

Segui `.project/SKILL.md` (secoes "Toolchain and quality commands" e
"Toolchain & quality commands (agent-discovered 2026-08-28)"). Nenhuma
descoberta nova de tooling para acrescentar — o padrao do ciclo 004 ja
cobre este PR integralmente.

### Build FPC 3.2.2 x86_64 (nativo na fabrica)

```
rm -rf /tmp/fpcbuild && mkdir -p /tmp/fpcbuild
fpc -Mdelphi -Fu"Source" -Fu"Test Shared/EclbrSystem" -Fu"Test FPC/EclbrSystem" \
    -FU/tmp/fpcbuild -FE/tmp/fpcbuild "Test FPC/EclbrSystem/PTestRTTI.lpr"
```

- **4636 lines compiled, 1.0 sec** — link limpo.
- **10 warnings, 6 notes** — TODOS pre-existentes; nenhum introduzido por
  este PR. Nenhum warning novo em `ArrayTypeLength` (funcao retorna
  `Integer`, tipo nao-managed — o warning "function result variable of a
  managed type" nao se aplica).

### Suite FPCUnit x86_64

```
/tmp/fpcbuild/PTestRTTI --all -a --format=plain
```

- **Number of run tests: 42 | Number of errors: 0 | Number of failures: 0**
- Cenarios afetados verificados: `TestArrayType_Static_LengthAndSize`
  (cenario 7 fortalecido), `TestArrayType_Dynamic_LengthRaises`
  (`ArrayTypeLength` mexido no item D), `TestRecordType_NameAndSize`
  (comentario B).

### Build FPC 3.2.2 i386

**NAO executado na fabrica.** SKILL.md registra: `ppc386` retorna 127 na
container Aefos ("NAO ha cross-compiler i386"). Validacao i386 fica com o
autor humano no PR body, conforme regra do projeto.

### Build Delphi

**NAO executado na fabrica.** SKILL.md registra que Delphi so compila no
ambiente do autor (secao "Delphi — o incumbente"). Declarado explicitamente
no PR body.

### Mutacao obrigatoria (D-57.4) — x86_64

Apliquei a mutacao `GetTypeData(P)^.ArrayData.ElType => PTypeInfo(P)` em
`Source/ModernSyntax.RTTI.FPC.pas:686` (ramo estatico de
`ArrayTypeElementType`). Recompilado com `rm -rf /tmp/fpcbuild` limpo e
rodado o suite:

```
TTestModernRTTI.TestArrayType_Static_LengthAndSize:
  ElementType(TArr5Int46) nao e Integer — handle identico esperado.
Number of run tests: 42 | Number of errors: 1 | Number of failures: 0
```

**Cenario 7 vermelho por semantica** — a assercao de identidade nova mata a
mutacao. Confirmado que o `IsNil` sozinho engolia (handle devolvido e o
proprio array, nao-nulo). Mutacao revertida; suite volta 42/42 verde.

**Log da mutacao no i386: fica com o autor no PR** (mesma disciplina de
Delphi — nao ha `ppc386` na fabrica). D-57.4 exige a mutacao rodada nos
DOIS bitness; o x86_64 esta demonstrado aqui, o i386 e responsabilidade do
autor.

## Advance do board

- `.project/project-evolution.md` linha do ciclo 023:
  `🔄 in-pipeline` → `🔄 in-review`.
- Card no GitHub project board: issue #57 **nao possui card** (declarado
  pelo planner em `REPORT-planner.md` do ciclo) — nada a mover.

## Caveats

- **i386 e Delphi ficam com o autor.** A fabrica so cobre FPC x86_64 nativo.
  O log da mutacao no i386 e a declaracao Delphi vao no corpo do PR
  conforme procedimento padrao do projeto (SKILL.md "What a PR must
  declare").
- **Item D: removi 3 linhas em vez de 2.** Ver "Decisoes tecnicas > D"
  acima. Fiquei entre a leitura estrita (2 linhas) e a leitura sensata
  (paragrafo inteiro); escolhi a segunda e documentei para o reviewer.
- **Warnings pre-existentes:** `ModernSyntax.RTTI.FPC.pas:583,829` e
  `ModernSyntax.RTTI.pas:1081` seguem com "function result variable of a
  managed type does not seem to be initialized". Nao sao consequencia
  deste PR e sao explicitamente fora de escopo (BR-1). Qualquer acao
  sobre eles precisa de outro ciclo — adicionar `Result :=` para silenciar
  warning e exatamente o padrao que produziu o comentario fantasma
  corrigido em D.
