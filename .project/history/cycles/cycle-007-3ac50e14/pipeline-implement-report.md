---
type: implement-report
kind: artifact
title: "Implement report — Rename addr/m para LAddress/LMethod em ModernSyntax.Invoker (issue #23)"
description: "Rename mecânico de 4 variáveis locais nos dois overloads de Invoke<TSignature>; build FPC 3.2.2 x86_64 limpo com 7/7 testes verdes."
status: stable
cycle: "007"
agent: developer
workflow: equipe-chore
node: implement
resource: aefos://run/3ac50e14ab113cabde9efa632dc2fccf
tags: [implement-report, chore, naming-convention, invoker, modernrtti, issue-23]
generated:
  by: "equipe-chore@node:implement"
  at: "2026-08-28T00:00:00Z"
sources:
  - id: esp
    resource: .project/pipeline/esp.md
    title: "ESP — Conformidade de nomes em Invoker"
  - id: plan
    resource: .project/pipeline/plan.md
    title: "Plan — Fatia única rename+verify"
  - id: adr
    resource: .project/pipeline/adr.md
    title: "ADR — Sem nova decisão; convenção existente aplicada"
  - id: task-input
    resource: .project/pipeline/task-input.md
    title: "Task input — Handoff operacional"
---

# Implement report — chore issue #23

## O que mudou

Renomeadas as 4 variáveis locais fora da convenção `L`+PascalCase nos
dois overloads de `Invoke<TSignature>` em
`Source/ModernSyntax.Invoker.pas`:

| Overload | Antes | Depois |
|---|---|---|
| `Invoke<TSignature>(AInstance: TObject; ...)` linhas 76-77 | `addr: Pointer` | `LAddress: Pointer` |
| `Invoke<TSignature>(AInstance: TObject; ...)` linhas 76-77 | `m: TMethod` | `LMethod: TMethod` |
| `Invoke<TSignature>(AClass: TClass; ...)` linhas 96-97 | `addr: Pointer` | `LAddress: Pointer` |
| `Invoke<TSignature>(AClass: TClass; ...)` linhas 96-97 | `m: TMethod` | `LMethod: TMethod` |

Todos os usos no corpo dos overloads (atribuições a `.Code`, `.Data`,
condições `if ... = nil`, chamada a `Move`) foram atualizados. Nenhuma
outra unit tocada. Comentário-cabeçalho, assinatura pública, `interface`
e `implementation` do record permanecem idênticos ao original.

## Arquivos modificados

| Arquivo | Tipo de mudança |
|---|---|
| `Source/ModernSyntax.Invoker.pas` | Rename de 4 variáveis locais (10 linhas alteradas: 10 removidas + 10 adicionadas) |
| `.project/project-evolution.md` | Marcador do ciclo 007 movido `in-pipeline` → `in-review` |

## Decisões técnicas

Nenhuma decisão nova. O [adr](pipeline-adr.md) já registrou que não há decisão a
tomar: aplica-se a convenção `L`+PascalCase existente, exatamente como
prescrito nas tabelas do [esp](pipeline-esp.md) e do [task-input](pipeline-task-input.md).

## Merge preparatório

A branch do ciclo (`aefos/cycle-3ac50e14-…`) foi criada a partir de
`origin/develop`, que **não contém** o arquivo alvo —
`ModernSyntax.Invoker.pas` foi entregue pelo PR #19 e mergeada em `main`.
Sem o arquivo, não há o que renomear. Segui o padrão dos ciclos
anteriores (ver histórico: *"merge: traz o main para a branch do X"*):
merge de `origin/main` na branch antes do rename. O trabalho substantivo
deste ciclo (o único diff versus main) permanece limitado a um único
arquivo de código (`Source/ModernSyntax.Invoker.pas`) mais o marcador do
board. O desvio de base branch foi registrado em
[FLOW-FEEDBACK](FLOW-FEEDBACK.md).

## Validações executadas

Toolchain descoberto: seção *"Toolchain & quality commands"* de
[SKILL](../../../SKILL.md) (agent-discovered 2026-08-28). Fábrica só tem FPC
3.2.2 x86_64 — validação Delphi e i386 fica com o autor humano
([SKILL](../../../SKILL.md) §*"What a PR must declare"*).

Build limpo (obrigatório — FPC reporta verde sobre `.ppu` velhos):

```
rm -rf /tmp/fpcbuild && mkdir -p /tmp/fpcbuild
fpc -Mdelphi \
    -Fu"Source" \
    -Fu"Test Shared/EclbrSystem" \
    -Fu"Test FPC/EclbrSystem" \
    -FU/tmp/fpcbuild \
    -o/tmp/fpcbuild/PTestInvoker \
    "Test FPC/EclbrSystem/PTestInvoker.lpr"
```

Resultado: **450 linhas compiladas, 0 erros, 3 warnings**
(`unreachable code` nas linhas 80 e 100 — pré-existentes na entrega do
PR #19, causados pelo `raise` incondicional após o `if SizeOf(...) <> …`
para o caso em que `TSignature` tem o mesmo tamanho que `TMethod`; fora
do escopo desta issue).

Execução dos testes:

```
/tmp/fpcbuild/PTestInvoker --all -a --format=plain
```

Resultado: **7 testes, 0 erros, 0 falhas.**

```
Time:00.000 N:7 E:0 F:0 I:0
  TInvokerTests Time:00.000 N:7 E:0 F:0 I:0
    Invoke_InstanceMethod_ReturnsValue
    TypedMethod_CalledWithArgs_ReturnsExpected
    Invoke_ClassMethod_Works
    Invoke_MethodNotFound_RaisesWithActionableMessage
    Invoke_NilInstance_Raises
    Invoke_PublicMethodWithoutMPlus_RaisesNotFound
    Invoke_NonMethodSignature_Raises
```

Diff limitado (verificado):

```
git diff HEAD --name-only
.project/project-evolution.md
Source/ModernSyntax.Invoker.pas
```

## Checklist de aceitação (do [esp](pipeline-esp.md))

- [x] Zero variáveis locais sem prefixo `L` em
      `ModernSyntax.Invoker.pas`.
- [x] `PTestInvoker.lpr` compila e executa com **7 testes, 0 falhas** no
      FPC 3.2.2 x86_64 (build limpo).
- [x] Diff de código-fonte limitado a `Source/ModernSyntax.Invoker.pas`
      (o marcador do board em `.project/project-evolution.md` não é
      código de produto e é exigido pela regra *"advance the local board"*
      do próprio nó `implement`).

## Caveats

1. **Validação i386 e Delphi ausentes.** A fábrica só tem FPC 3.2.2
   x86_64 ([SKILL](../../../SKILL.md) §*"agent-discovered"*): sem `ppc386` e
   sem `dcc32`. O PR declarará explicitamente a lacuna. Como o rename é
   puramente léxico e não toca sintaxe específica de arquitetura nem de
   compilador, o risco de regressão nos alvos ausentes é nulo.

2. **Warnings de `unreachable code` pré-existentes.** Introduzidos pelo
   PR #19 na entrega original; não são consequência deste rename. Ficam
   para issue separada se se decidir suprimi-los.

3. **Merge preparatório de `origin/main`.** Necessário para trazer o
   arquivo alvo à branch do ciclo (ver seção *"Merge preparatório"*
   acima); padrão idêntico ao dos ciclos 004, 005 e 006.
   [FLOW-FEEDBACK](FLOW-FEEDBACK.md)
   registra a sugestão de que a maestro escolha a base branch correta
   na criação do ciclo.
