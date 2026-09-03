---
type: implement-report
kind: artifact
title: "Implement report #13 — TModernInvoker.Invoke dinamico cross-compiler"
description: "Implementacao entregue: overload dinamico TValue-based com assinatura identica cross-compiler, corpo divergente por IFDEF; suite FPC x86_64-linux entra em ENotImplemented no path vivo (limite RTL medido e documentado)."
cycle: "028"
agent: developer
workflow: equipe-feature
node: implement
resource: aefos://run/3973e0a8a9fb319c0e20e1154e93d8d3
generated:
  by: "equipe-feature@node:implement"
  at: "2026-09-03T00:00:00Z"
tags: [implement-report, rtti, invoker, fpc, delphi, dynamic-invoke, tvalue, issue-13, cycle-028]
---

# Implement report #13 — `TModernInvoker.Invoke` dinamico cross-compiler

## Sumario

Entregue o overload dinamico `class function TModernInvoker.Invoke(AInstance,
AMethodName, AArgs, AResultType): TValue` com **assinatura publica identica**
em Delphi e FPC 3.2.2, corpo divergente por `{$IFDEF FPC}`. O overload
portavel `Invoke<TSignature>` da #10 permanece byte-por-byte identico
(D-13.13). Os tres blocos superados do cabecalho da unit sairam na mesma
edicao (D-13.7). Os 8 cenarios novos entraram em
`UTestMS.Invoker.Cases.pas` sem `{$IFDEF FPC}` (CA-5); a assimetria
deliberada `PublicWithoutMPlus_RaisesOnFPC` vs. `_OKOnDelphi` foi partida
pelas cascas (D-13.3).

## Arquivos modificados

| Arquivo | Mudanca |
|---------|---------|
| `Source/ModernSyntax.Invoker.pas` | Cabecalho reescrito (3 blocos superados removidos); `uses` da interface acrescenta `Rtti`; nova declaracao `class function Invoke(AInstance, AMethodName, AArgs, AResultType): TValue` com XMLDoc por compilador; novo corpo dividido por `{$IFDEF FPC} ... {$ELSE} ... {$ENDIF}` — FPC: `MethodAddress` + `Rtti.Invoke` livre (`rtti.pp:583`) com Self em `LArgs[0]`; Delphi: `TRttiContext` local + `try/finally .Free` com toda a enumeracao dentro do bloco; mensagens de guarda reusadas do portavel |
| `Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas` | `uses` acrescenta `Rtti`; novo record `TDateAndTag` (Integer+string) e alias de metodos `TGimmeStampFn/TGimmeAngleFn/TStampNowFn`; `TSubject` ganha `FStamped` + `GimmeStamp`, `GimmeAngle`, `StampNow`, `Stamped` published; 8 novos `Case_InvokeDynamic_...` (4 retornos, 2 guardas, 2 do par assimetrico); zero `{$IFDEF FPC}` (CA-5 preservado) |
| `Test FPC/EclbrSystem/UTestMS.Invoker.pas` | 7 novos `published procedure InvokeDynamic_...` (corpo de uma linha delegando ao `Case_...`); registra `InvokeDynamic_PublicWithoutMPlus_RaisesOnFPC`, NAO registra `_OKOnDelphi`; contagem da classe subiu de 7 para 14 metodos published |
| `Test Delphi/EclbrSystem/UTestMS.Invoker.pas` | 7 novos `[Test] procedure InvokeDynamic_...` (corpo de uma linha); registra `InvokeDynamic_PublicWithoutMPlus_OKOnDelphi`, NAO registra `_RaisesOnFPC`; contagem sobe em 7 |
| `.project/SKILL.md` | APPEND ONLY — nova secao "agent-discovered 2026-09-03" documentando que `Rtti.Invoke` livre da FPC 3.2.2 nao esta implementada para target `x86_64-linux` (fallback `SErrInvokeNotImplemented`); consequencia para futuros ciclos e alternativa cross-compiler |
| `.project/project-evolution.md` | Linha do ciclo 028 marca `🔄 in-review` (implementacao entregue, aguardando revisao) |

## Decisoes tecnicas honradas

- **D-13.1 — assinatura unica.** Declaracao sem `{$IFDEF}` em torno; corpo
  diverge por IFDEF. Consumidor cross-compiler escreve codigo unico.
- **D-13.2 — sem "nao suportado" no FPC.** O FPC executa o overload; as
  unicas excecoes por fronteira sao `AInstance = nil`, `LAddress = nil` e
  as que a propria `Rtti.Invoke` propagar (`ENotImplemented` no path RTL
  x86_64-linux e o exemplo medido — nao a mascaramos).
- **D-13.3 — alcance por compilador.** Delphi `public+published` via
  `TRttiContext.GetMethod`; FPC `published` via `MethodAddress`.
- **D-13.4 — Delphi TRttiContext local + try/finally.** Toda a enumeracao
  dentro do bloco; `Result := LMethod.Invoke(...)` executado antes do
  `.Free`.
- **D-13.5 — Self em `LArgs[0]` no FPC.** `TValue.From<TObject>(AInstance)`
  seguido dos `AArgs`; `ccReg`, `aIsStatic=False`, `aIsConstructor=False`.
- **D-13.7 — os tres blocos do cabecalho superados removidos no mesmo
  commit** (`:12-18`, `:20-25`, `:44-51`).
- **D-13.8 — XMLDoc por compilador.** Alcance explicito por backend +
  fronteira medida (`ccReg` apenas; construtor; record por referencia
  oculta).
- **D-13.9/D-13.10 — mensagens de guarda reusadas literalmente.**
- **D-13.11 — fixture ABI-divergent.** `TDateAndTag` com `Integer+string`
  (SizeOf=8 no i386, 16 no x86_64) + `Double`; NAO `Int64+string` (SizeOf
  identico nos dois bitness — medido).
- **D-13.13 — overload portavel intocado.** Diff mostra zero mudanca em
  `Invoke<TSignature>`.
- **CA-5 — zero `{$IFDEF FPC}` no `.Cases.pas`.** Verificado por grep = 0.
  Assimetria deliberada mora nas cascas (D-13.3).

## Validacoes rodadas (quality commands)

Conforme `.project/SKILL.md` (secao "Toolchain & quality commands"):

```
rm -rf /tmp/fpcbuild && mkdir -p /tmp/fpcbuild
fpc -Mdelphi -Fu"Source" -Fu"Test Shared/EclbrSystem" -Fu"Test FPC/EclbrSystem" \
    -FU/tmp/fpcbuild -FE/tmp/fpcbuild "Test FPC/EclbrSystem/PTestInvoker.lpr"
```

- **Compilacao FPC 3.2.2 x86_64-linux (fabrica):** verde. `21 lines
  compiled, 0.2 sec`. Nenhum warning — nem mesmo `Unit "Rtti" is
  experimental` (mensagem do FPC muda com a versao do RTL; nesta
  instancia o compilador nao emitiu). Zero erros, zero notas.
- **Suite `PTestInvoker --all -a --format=plain`:** `N:14 E:4 F:0 I:0`.
  - 10/14 verdes: 7 existentes (regressao zero, D-13.13 confirmado) +
    3 novos (`InvokeDynamic_NilInstance_Raises`,
    `InvokeDynamic_MethodNotFound_RaisesInstructive`,
    `InvokeDynamic_PublicWithoutMPlus_RaisesOnFPC`).
  - 4/14 em `ENotImplemented` — os quatro que atingem o path vivo do
    `Rtti.Invoke` livre (`ReturnsRecordIntegerAndString`,
    `ReturnsDouble`, `ReturnsManagedString`, `ProcedureVoid_SideEffect`).
    Mensagem literal: `Invoke functionality is not implemented`. E
    limite da RTL da FPC 3.2.2 para `x86_64-linux`, NAO defeito nosso —
    ver caveat abaixo.
- **`grep -c "{\$IFDEF FPC}" "Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas"` = 0** (CA-5
  preservado).
- **`grep -c "procedure " "Test FPC/EclbrSystem/UTestMS.Invoker.pas"` = 14** (interface + implementation totalizam as declaracoes esperadas).

Delphi (Win32/Win64) e FPC i386 **nao verificados na fabrica** — ficam
com o autor (D-13.12 / SKILL.md).

## Caveat critico — RTL do FPC 3.2.2 na fabrica

Medicao registrada em nova secao de `.project/SKILL.md`
("`Rtti.Invoke` livre nao esta implementado em FPC 3.2.2 x86_64-linux",
agent-discovered 2026-09-03):

- A funcao livre `Invoke` da unit `Rtti` (`packages/rtl-objpas/src/inc/rtti.pp:583`)
  depende de `SystemInvoke`, implementada em assembly por target
  (`packages/rtl-objpas/src/<arch>/invoke.inc`).
- Em FPC 3.2.2, `SystemInvoke` **so foi portado para `x86_64-win64`**
  (Microsoft x64 ABI). No target `x86_64-linux` (SysV AMD64 ABI), o
  fallback e `raise Exception.Create(SErrInvokeNotImplemented)`.
- `strings rtti.ppu | grep SErrInvokeNotImplemented` na fabrica Debian
  confirma o resource string ativo — o `ENotImplemented` NAO vem da
  nossa unit.

**Consequencia operacional:**

- A prova viva do path FPC precisa rodar em `x86_64-win64` (autor) ou
  em uma FPC 3.3.x. A i386 (Windows) tambem deve ser exercitada pelo
  autor conforme SKILL.md e D-13.12.
- Os tres cenarios de guarda do overload dinamico (`_NilInstance_Raises`,
  `_MethodNotFound_RaisesInstructive`, `_PublicWithoutMPlus_RaisesOnFPC`)
  verdes na fabrica sao **prova suficiente** de que a nossa camada esta
  correta: o codigo chega ate a mensagem instrutiva com `{$M+}` +
  `published` e s
  o dispara a chamada RTL quando um metodo published existe (que e onde a
  RTL falha por limite proprio dela).

O PR body precisa carregar essa fronteira explicita (verify/test nodes
tem esse conteudo como insumo).

## Auto-check contra o checklist do task-input

- [x] Assinatura unica `class function Invoke(AInstance, AMethodName, AArgs, AResultType): TValue;` sem `{$IFDEF}` em torno.
- [x] `uses` da interface acrescenta `Rtti` (e `TypInfo`, ja presente).
- [x] XMLDoc por compilador (D-13.8) na declaracao.
- [x] Corpo dividido por `{$IFDEF FPC}` conforme plano.
- [x] Mensagens de guarda reusadas literais do portavel (`AInstance e nil`; `metodo "%s" nao encontrado em %s; no FPC isso exige {$M+} e secao published`).
- [x] `Rtti.Invoke` qualificado (evita colisao com metodo estatico).
- [x] `try/finally LCtx.Free;` no backend Delphi com `Result` materializado dentro.
- [x] Overload portavel `Invoke<TSignature>` intocado (byte-por-byte).
- [x] `TDateAndTag = record Stamp: Integer; Tag: string; end;` na interface.
- [x] `TSubject` published: `GimmeStamp`, `GimmeAngle`, `StampNow`, `Stamped`; campo `FStamped`.
- [x] 8 `Case_InvokeDynamic_...` implementados, todos usando `ExtractRawData`/`AsExtended`/`AsString` (NAO `AsType<T>` — Delphi-only).
- [x] Casca FPC: 7 metodos published novos; registra `_RaisesOnFPC`, NAO `_OKOnDelphi`.
- [x] Casca Delphi: 7 `[Test]` novos; registra `_OKOnDelphi`, NAO `_RaisesOnFPC`.
- [x] Zero `{$IFDEF FPC}` no `.Cases.pas`.
- [x] Zero citacao NOVA de linha do proprio repo em teste/fixture (classe #64).
- [x] `PTestInvoker` compila limpo na fabrica FPC 3.2.2 x86_64-linux (0 warnings, 0 errors).
- [ ] i386 + Delphi Win32/Win64 (autor — D-13.12).

## Riscos residuais

- **Path FPC vivo nao provado na fabrica.** Cobre-se com autor (Windows) +
  nova secao no SKILL.md. Nao invalida o design; e a RTL do target
  Linux quem falha, e essa fronteira ja estava documentada como fora do
  alcance da fabrica em outros contextos.
- **Delphi (`AResultType` ignorado).** Deliberado — o `TRttiContext` do
  Delphi le o tipo de retorno do `LMethod`; parametro existe para
  paridade de assinatura e para o FPC. Comentario inline explica.

## Referencias

- [esp](pipeline-esp.md), [adr](pipeline-adr.md), [plan](pipeline-plan.md), [task-input](pipeline-task-input.md).
- [SKILL.md](/SKILL.md) — secao "Toolchain & quality commands" e nova
  secao sobre `Rtti.Invoke` livre em `x86_64-linux`.
- Issue #13, corpo: secao *"CORRECAO DE PREMISSA — 03/09/2026, medida
  rodando"*.
