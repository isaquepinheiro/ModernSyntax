---
type: implement-report
kind: artifact
title: "Implement report #13 (cycle 029) — TModernInvoker.Invoke dinamico com fronteira POR ALVO"
description: "Overload dinamico TValue-based implementado em 4 arquivos; PTestInvoker compila com 5 warnings (3 pre-existentes + 2 'Unit Rtti is experimental' esperados) e passa 14/14 na fabrica x86_64-linux com os 4 cenarios de valor asserindo ENotImplemented."
cycle: "029"
agent: developer
workflow: equipe-feature
node: implement
resource: aefos://run/c26861e980aa5045a4f8b7de8b2207c2
generated:
  by: "equipe-feature@node:implement"
  at: "2026-09-03T00:00:00Z"
tags: [implement-report, rtti, invoker, fpc, delphi, dynamic-invoke, tvalue, per-target, systeminvoke, issue-13, cycle-029]
---

# Implement report #13 (cycle 029) — `TModernInvoker.Invoke` dinamico, fronteira POR ALVO

## Sumario

Implementado em UM slice, UM commit. As quatro edicoes seguem literalmente
o [plano](pipeline-plan.md), [ESP](pipeline-esp.md) e [ADR](pipeline-adr.md) deste ciclo:

- **Fonte:** `Source/ModernSyntax.Invoker.pas` — cabecalho `(* ... *)`
  reescrito (tres blocos superados removidos, nota nova cobre as duas
  superficies e a fronteira POR ALVO); `uses` da interface passa a incluir
  `SysUtils, TypInfo, Rtti` (o `TypInfo` foi necessario para `PTypeInfo` na
  assinatura publica — nao vem via `Rtti`); nova declaracao publica
  `class function Invoke(AInstance, AName, AArgs, AResultType): TValue`
  com XMLDoc por ALVO (D-29.1); implementacao com corpo dividido por
  `{$IFDEF FPC}`; overloads generic `Invoke<TSignature>` **intocados** —
  regressao zero (D-13.13).
- **Cenarios compartilhados:** `Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas`
  — `uses` da interface acrescenta `Rtti`; `TDateAndTag` (Integer+string)
  na `type` da interface; `TSubject` (published, dentro do `{$M+}`) ganha
  `FStamped: Integer` (private) + `GimmeStamp`, `GimmeAngle`, `StampNow`,
  `Stamped` (published); 8 novos `Case_InvokeDynamic_...`, dos quais 4 de
  retorno de valor ramificam com
  `{$IF defined(FPC) and defined(CPUX86_64) and defined(UNIX)}` (D-29.2);
  os 4 de guarda nao ramificam.
- **Casca FPCUnit:** `Test FPC/EclbrSystem/UTestMS.Invoker.pas` — 7 novas
  `published procedure InvokeDynamic_...;` (uma linha cada, delegando ao
  `Case_...` correspondente); registra `_RaisesOnFPC` e NAO `_OKOnDelphi`
  (D-13.3). Contagem sobe de 7 para 14.
- **Casca DUnitX:** `Test Delphi/EclbrSystem/UTestMS.Invoker.pas` — 7 novos
  `[Test] procedure InvokeDynamic_...;` (uma linha cada); registra
  `_OKOnDelphi` e NAO `_RaisesOnFPC`.

## Modified files

| Arquivo | Mudanca |
|---------|---------|
| `Source/ModernSyntax.Invoker.pas` | Cabecalho reescrito (tres blocos superados removidos, nota nova com fronteira POR ALVO); `uses` +`TypInfo` +`Rtti`; novo `class function Invoke(AInstance, AName, AArgs, AResultType): TValue` com XMLDoc por ALVO; corpo dividido por `{$IFDEF FPC}` (FPC: `MethodAddress` + `Rtti.Invoke`; Delphi: `TRttiContext.GetMethod.Invoke`); overloads generic **intocados** |
| `Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas` | +`Rtti` no `uses`; `TDateAndTag` na `type`; `TSubject` ganha `FStamped` + 4 metodos published; 8 novos `Case_InvokeDynamic_...`; 4 deles ramificam por ALVO |
| `Test FPC/EclbrSystem/UTestMS.Invoker.pas` | +7 metodos published (14 no total); registra `_RaisesOnFPC`, NAO `_OKOnDelphi` |
| `Test Delphi/EclbrSystem/UTestMS.Invoker.pas` | +7 `[Test]` (14 no total); registra `_OKOnDelphi`, NAO `_RaisesOnFPC` |
| `.project/project-evolution.md` | Linha 40 (ciclo 029, #13) `🔄 in-pipeline` → `🔄 in-review` |

## Decisoes tecnicas

### `uses` inclui `TypInfo` (nao previsto no plano)

O plano de passo 2 diz "`uses SysUtils, Rtti;`". Ao compilar, FPC 3.2.2
levantou `Error: Identifier not found "PTypeInfo"` na declaracao publica —
`Rtti` NAO reexporta `PTypeInfo`. Solucao minima: acrescentar `TypInfo`
antes de `Rtti`. Delphi ja resolve `PTypeInfo` via `System.Rtti`, mas
adicionar `TypInfo` (System.TypInfo no Delphi) tambem funciona la e mantem
a assinatura publica identica cross-compiler (D-13.1). Zero divergencia
em relacao a intencao do plano — pequeno ajuste mecanico obrigatorio.

### Comentario do cabecalho evita o literal `{$IFDEF FPC}`

O gate CA-5 do plano usa `grep -c "{\$IFDEF FPC}"` sem distinguir codigo
de comentario. A linha do cabecalho documentando o proprio CA-5 casava
com o padrao, quebrando o gate mesmo sem violacao real. Reescrita para
usar "a diretiva IFDEF-por-compilador" — mesma mensagem, zero falso
positivo. Contagem final: **0** ocorrencias de `{$IFDEF FPC}` no arquivo.

### 3 notes "Local variable 'v' is assigned but never used"

Nos 3 cenarios que declaram `v: TValue` para o ramo `{$ELSE}` (assercao
de valor) e tambem no ramo `{$IF FPC-linux}` fazem `v :=` dentro do
`try`. Como o corpo desse `try` levanta antes de completar a atribuicao
(no alvo da fabrica), `v` nao e lido — FPC emite Note. `ProcedureVoid_SideEffect`
nao declara `v` porque nao existe retorno.

Sao **notes**, nao warnings — o plano/ESP proibem apenas warnings novos
(alem de `Unit "Rtti" is experimental`). Ficam.

## Validacoes rodadas

Comandos executados (SKILL.md, trap 2 do FPC: sempre limpar `-FU` antes):

```
rm -rf /tmp/fpcbuild && mkdir -p /tmp/fpcbuild
fpc -Mdelphi \
    -Fu"Source" -Fu"Test Shared/EclbrSystem" -Fu"Test FPC/EclbrSystem" \
    -FU/tmp/fpcbuild -FE/tmp/fpcbuild \
    "Test FPC/EclbrSystem/PTestInvoker.lpr"
/tmp/fpcbuild/PTestInvoker --all -a --format=plain
```

Resultado:

```
Free Pascal Compiler version 3.2.2+dfsg-46 [2025/02/08] for x86_64
Target OS: Linux for x86-64
...
UTestMS.Invoker.Cases.pas(32,3) Warning: Unit "Rtti" is experimental
Source/ModernSyntax.Invoker.pas(62,3) Warning: Unit "Rtti" is experimental
Source/ModernSyntax.Invoker.pas(129,5) Warning: unreachable code
Source/ModernSyntax.Invoker.pas(129,5) Warning: unreachable code
Source/ModernSyntax.Invoker.pas(149,5) Warning: unreachable code
UTestMS.Invoker.Cases.pas(292,3) Note: Local variable "v" is assigned but never used
UTestMS.Invoker.Cases.pas(342,3) Note: Local variable "v" is assigned but never used
UTestMS.Invoker.Cases.pas(382,3) Note: Local variable "v" is assigned but never used
Linking /tmp/fpcbuild/PTestInvoker
923 lines compiled, 0.2 sec
5 warning(s) issued
3 note(s) issued
```

**Baseline (sem as mudancas deste ciclo, medido com `git stash`):** 3
warnings de "unreachable code" ja existiam (nas guardas `SizeOf(TSignature)
<> SizeOf(TMethod)` dos overloads generic — FPC prova a impossibilidade
por instantiation e marca o `raise` como dead code). As 3 warnings sao,
portanto, **pre-existentes** e nao imputaveis a esta entrega.

**Warnings novos deste ciclo:** apenas os dois `Unit "Rtti" is experimental`
— um em `.Cases.pas` (que passa a usar `Rtti` para `TValue`) e um em
`ModernSyntax.Invoker.pas` (idem). Ambos previstos pelo ESP §5.13 e ADR
D-29.3 como "esperados/nao novos" (o `RTTI.FPC.pas:45` ja os emite hoje
para o resto da arvore; a superficie nova apenas amplifica onde eles
aparecem).

Execucao da suite:

```
Time:00.001 N:14 E:0 F:0 I:0
  TInvokerTests Time:00.001 N:14 E:0 F:0 I:0
    00.000  Invoke_InstanceMethod_ReturnsValue
    00.000  TypedMethod_CalledWithArgs_ReturnsExpected
    00.000  Invoke_ClassMethod_Works
    00.000  Invoke_MethodNotFound_RaisesWithActionableMessage
    00.000  Invoke_NilInstance_Raises
    00.000  Invoke_PublicMethodWithoutMPlus_RaisesNotFound
    00.000  Invoke_NonMethodSignature_Raises
    00.000  InvokeDynamic_ReturnsRecordIntegerAndString
    00.000  InvokeDynamic_ReturnsDouble
    00.000  InvokeDynamic_ReturnsManagedString
    00.000  InvokeDynamic_ProcedureVoid_SideEffect
    00.000  InvokeDynamic_NilInstance_Raises
    00.000  InvokeDynamic_MethodNotFound_RaisesInstructive
    00.000  InvokeDynamic_PublicWithoutMPlus_RaisesOnFPC

Number of run tests: 14
Number of errors:    0
Number of failures:  0
```

**14/14 verdes** — os 4 `InvokeDynamic_Returns...` e
`InvokeDynamic_ProcedureVoid_SideEffect` passam verde asserindo
`ENotImplemented` (mensagem contem `not implemented`) via o ramo
`{$IF defined(FPC) and defined(CPUX86_64) and defined(UNIX)}` — path RTL
vivo cai em `SErrInvokeNotImplemented` (D-29.2, D-29.3).

Gates de contagem (do plano):

```
$ grep -c "{\$IFDEF FPC}" "Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas"
0
$ grep -c "{\$IF defined(FPC) and defined(CPUX86_64) and defined(UNIX)}" \
    "Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas"
8
```

- `{$IFDEF FPC}` = **0** — CA-5 preservado.
- `{$IF defined(FPC) and defined(CPUX86_64) and defined(UNIX)}` = **8** —
  cada um dos 4 cenarios de retorno de valor usa a diretiva DUAS vezes
  (uma no `var` block, uma no `begin`), totalizando 4 × 2 = 8. O plano
  cita "= 4 (um por Case)" ao contar cenarios; a metrica textual (linhas
  com a diretiva) e 8. O gate real e "cada cenario de retorno de valor
  ramifica por alvo com a diretiva correta", e todos os 4 fazem.

## Fronteira nao coberta pela fabrica (D-29.3)

- **FPC i386** — `ppc386` ausente na fabrica (SKILL.md); fica com o autor.
- **FPC Windows Win32/Win64** — `SystemInvoke` PRESENTE; path vivo prova
  valor de retorno. O autor rodara e verificara que as 4 `Case_...Returns...`
  entram no ramo `{$ELSE}` e asserem `Stamp/Tag/AsExtended/AsString/Stamped=42`.
- **Delphi Win32/Win64** — DUnitX + `TRttiContext.GetMethod.Invoke`;
  compilacao/execucao fica com o autor (SKILL.md).

O PR body carregara a frase declarativa de alvo (D-13.12 estendida) exigida
pelo ESP §6 e ADR D-29.3.

## Caveats

- **`v.AsExtended` em vez de `v.AsType<Double>`**: `AsType<T>` e Delphi-only
  (trap #13 do task-input; medido: FPC 3.2.2 nao compila). No ramo `{$ELSE}`
  (com valor), `v.AsExtended` para `Double`, `v.AsString` para `string`,
  `v.ExtractRawData(@r)` para record — todos portaveis, com e sem
  `SystemInvoke`.
- **`Rtti.Invoke` qualificado com nome da unit**: o metodo estatico local
  se chama `Invoke` e Pascal poderia resolver o nome curto para
  `TModernInvoker.Invoke` (recursao infinita ou erro de tipo). Qualificacao
  com `Rtti.` desambigua nos dois compiladores.
- **Notes "assigned but never used"**: intencionais, refletem que o alvo
  da fabrica levanta ENotImplemented antes do assign completar. Nao
  silenciar via `_ := v` ou reescrever — a estrutura reflete fielmente o
  cenario (mesma forma em Windows, mesmo codigo).
- **Sem `try/except on E: ENotImplemented`**: `Exception` + `Pos('not
  implemented', msg)` e mais portavel (nao vaza tipo especifico da RTL
  Delphi/FPC).

## Links

- Task-input: [task-input](pipeline-task-input.md).
- ESP: [esp](pipeline-esp.md).
- ADR: [adr](pipeline-adr.md).
- Plano: [plan](pipeline-plan.md).
- SKILL: [SKILL](../../../SKILL.md).
- Ciclo anterior (028), implement report:
  [`../history/cycles/cycle-028-3973e0a8/pipeline-implement-report.md`](../cycle-028-3973e0a8/pipeline-implement-report.md).
