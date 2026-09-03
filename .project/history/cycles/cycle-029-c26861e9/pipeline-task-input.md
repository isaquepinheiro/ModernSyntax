---
type: task-input
kind: artifact
title: "Task-input #13 (cycle 029) — TModernInvoker.Invoke dinamico com fronteira POR ALVO"
description: "Handoff operacional para o implementador: novo overload TValue-based, assinatura identica cross-compiler, backends por IFDEF, XMLDoc por alvo, cenarios de retorno de valor ramificando por alvo com {$IF defined(FPC) and defined(CPUX86_64) and defined(UNIX)}, cascas de teste com assimetria deliberada, cabecalho reescrito, um commit."
cycle: "029"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/c26861e980aa5045a4f8b7de8b2207c2
generated:
  by: "equipe-feature@node:architect"
  at: "2026-09-03T00:00:00Z"
tags: [task-input, rtti, invoker, fpc, delphi, dynamic-invoke, tvalue, per-target, systeminvoke, issue-13, cycle-029]
---

# Task-input #13 (cycle 029) — `TModernInvoker.Invoke` dinamico, fronteira POR ALVO

## Titulo

feat(invoker): overload dinamico TValue-based cross-compiler, fronteira por alvo (#13)

## Tipo / labels

- `feature`
- `rtti`
- `fpc`
- `delphi`
- `modernrtti`
- `invoker`

## Escopo em uma linha

Entregar o overload dinamico `TModernInvoker.Invoke(AInstance, AName,
AArgs, AResultType): TValue` com **assinatura publica identica** em Delphi
e FPC 3.2.2, mecanismo interno divergente por `{$IFDEF FPC}`, **XMLDoc por
alvo** (Delphi | FPC-Windows | FPC-outros) e **testes de retorno de valor
ramificando por alvo** com `{$IF defined(FPC) and defined(CPUX86_64) and
defined(UNIX)}` — porque a RTL do FPC 3.2.2 so implementa `SystemInvoke` em
alvos Windows; em `x86_64-linux` (alvo da fabrica) qualquer chamada real
propaga `ENotImplemented`. O portavel `Invoke<TSignature>` da #10 **nao
muda**.

## Arquivos impactados

| Arquivo | Mudanca |
|---------|---------|
| `Source/ModernSyntax.Invoker.pas` | Novo overload dinamico; `uses` da interface acrescenta `Rtti`; corpo por `{$IFDEF FPC}`; cabecalho reescrito — tres blocos superados removidos + nota nova com a fronteira POR ALVO |
| `Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas` | Fixtures `TDateAndTag` (`Integer+string`) + metodos `published` novos em `TSubject` (`GimmeStamp`, `GimmeAngle`, `StampNow`, `Stamped` + campo `FStamped`); 8 novos `Case_InvokeDynamic_...`; os 4 de retorno de valor **ramificam por alvo** com `{$IF defined(FPC) and defined(CPUX86_64) and defined(UNIX)}`; `uses` acrescenta `Rtti` |
| `Test FPC/EclbrSystem/UTestMS.Invoker.pas` | 7 `published procedure InvokeDynamic_...;` (uma linha cada); registra `_RaisesOnFPC`, **NAO** `_OKOnDelphi` |
| `Test Delphi/EclbrSystem/UTestMS.Invoker.pas` | 7 `[Test] procedure InvokeDynamic_...;` (uma linha cada); registra `_OKOnDelphi`, **NAO** `_RaisesOnFPC` |

## Pre-condicao — decisoes fechadas

- **Assinatura unica**, sem `{$IFDEF}` em torno da declaracao (D-13.1).
- **Alcance por compilador** — opcao (a) da issue (D-13.3):
  - Delphi: `public` + `published`.
  - FPC 3.2.2: `published` apenas.
- **Fronteira POR ALVO** (D-29.1):
  - Delphi: invocacao viva em todo alvo suportado.
  - FPC 3.2.2 Windows (Win32/Win64): invocacao viva via `SystemInvoke`.
  - FPC 3.2.2 outros alvos (`x86_64-linux` etc): `ENotImplemented` da RTL
    aflora; **nao mascarar, nao re-embrulhar**.
- **Mensagens de guarda reusadas** literais do portavel da #10 (D-13.9 /
  D-13.10), nas duas guardas (`AInstance = nil`; `LAddress = nil` /
  `LMethod = nil`).
- **`ccReg` apenas**; XMLDoc declara essa fronteira (D-13.6 / D-29.1).
- **Construtor** e **record grande por referencia oculta**: FORA do
  escopo; XMLDoc documenta (D-29.1).
- **Overload portavel `Invoke<TSignature>` byte-por-byte identico** apos
  a edicao (D-13.13).
- **Ramificacao permitida no `.Cases.pas`**: `{$IF defined(FPC) and
  defined(CPUX86_64) and defined(UNIX)}` (por ALVO). **Zero `{$IFDEF FPC}`**
  no arquivo (CA-5).

## Checklist de aceitacao

- [ ] `Source/ModernSyntax.Invoker.pas`:
  - Cabecalho `(* ... *)`: tres blocos superados removidos —
    `:12-18` (uses SysUtils apenas), `:20-25` (sem ramificacao por
    compilador), `:44-51` (nao existe Invoke TValue-based). Nota nova
    acrescentada explicando as duas superficies + a **fronteira POR
    ALVO** (cita `SystemInvoke`, `SErrInvokeNotImplemented`,
    `rtti.pp:583`, `packages/rtl-objpas/src/<arch>/invoke.inc`).
  - `uses` da `interface` acrescenta `Rtti`.
  - `TModernInvoker` acrescenta UM `class function Invoke(const
    AInstance: TObject; const AMethodName: string; const AArgs: array
    of TValue; const AResultType: PTypeInfo = nil): TValue; overload;
    static;` com XMLDoc por ALVO (D-29.1) — TRES linhas de fronteira
    (Delphi / FPC-Windows / FPC-outros) + fronteira metodica (`ccReg`,
    construtor, record grande). **Sem `{$IFDEF}` em torno da
    declaracao.**
  - Implementacao dividida por `{$IFDEF FPC} ... {$ELSE} ... {$ENDIF}`:
    - **FPC**: guarda `AInstance = nil`; `MethodAddress`; guarda
      `LAddress = nil` com mensagem reusada; monta `TValueArray` com
      `TValue.From<TObject>(AInstance)` em `[0]` + `AArgs` a partir de
      `[1]`; chama `Rtti.Invoke(LAddress, LArgs, ccReg, AResultType,
      False, False)` **qualificado com nome da unit**; devolve o
      retorno. **NAO acrescentar guarda para `ENotImplemented` da
      RTL** — deve aflorar (D-13.2 / D-29.1).
    - **Delphi**: guarda `AInstance = nil`; `TRttiContext.Create` +
      `try/finally .Free`; `LCtx.GetType(AInstance.ClassType).GetMethod
      (AMethodName)`; guarda `LMethod = nil` com a **mesma** mensagem
      reusada; `Result := LMethod.Invoke(AInstance, AArgs)` DENTRO do
      `try`.
  - Overloads `Invoke<TSignature>` (`:65-69` interface + `:73-111`
    implementation): **NAO EDITAR**. Diff mostra zero mudanca nessas
    linhas.
- [ ] `Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas`:
  - `uses` da interface acrescenta `Rtti`.
  - `TDateAndTag = record Stamp: Integer; Tag: string; end;` na secao
    `type` da interface.
  - `TSubject` (na implementation, dentro do `{$M+}`) ganha:
    - campo `FStamped: Integer` (private);
    - `function GimmeStamp(ATag: string): TDateAndTag;` (published);
    - `function GimmeAngle: Double;` (published);
    - `procedure StampNow(AValue: Integer);` (published);
    - `function Stamped: Integer;` (published — observador do efeito
      colateral).
  - 8 novos `Case_InvokeDynamic_...` implementados conforme plano.
  - **Os 4 de retorno de valor RAMIFICAM POR ALVO** com
    `{$IF defined(FPC) and defined(CPUX86_64) and defined(UNIX)}` — no
    ramo verdadeiro, asserem `ENotImplemented` (mensagem contem `not
    implemented`); no `{$ELSE}`, asserem o valor de retorno via
    `ExtractRawData`/`AsExtended`/`AsString`/`o.Stamped`:
    `ReturnsRecordIntegerAndString`, `ReturnsDouble`,
    `ReturnsManagedString`, `ProcedureVoid_SideEffect`.
  - Os 4 restantes NAO ramificam (guarda dispara antes da RTL):
    `NilInstance_Raises`, `MethodNotFound_RaisesInstructive`,
    `PublicWithoutMPlus_RaisesOnFPC`, `PublicWithoutMPlus_OKOnDelphi`.
  - `grep -c "{\$IFDEF FPC}" "Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas"` = **0** (CA-5).
  - `grep -c "{\$IF defined(FPC) and defined(CPUX86_64) and defined(UNIX)}" "Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas"` = **4**
    (um por Case de retorno de valor).
- [ ] `Test FPC/EclbrSystem/UTestMS.Invoker.pas` acrescenta 7 metodos
  `published procedure InvokeDynamic_...;` (corpo de uma linha cada),
  registrando `InvokeDynamic_PublicWithoutMPlus_RaisesOnFPC` e
  **NAO** `_OKOnDelphi`. Contagem sobe de 7 para **14**.
- [ ] `Test Delphi/EclbrSystem/UTestMS.Invoker.pas` acrescenta 7 metodos
  `[Test] procedure InvokeDynamic_...;` (corpo de uma linha cada),
  registrando `InvokeDynamic_PublicWithoutMPlus_OKOnDelphi` e
  **NAO** `_RaisesOnFPC`.
- [ ] Nenhuma citacao NOVA de linha do proprio repo em teste/fixture
  (classe #64). Simbolo, RTL externa ou nada.
- [ ] `PTestInvoker` compila limpo no FPC 3.2.2 x86_64-linux (fabrica):
  zero erros; zero warnings novos alem do eventual `Unit "Rtti" is
  experimental` (ja emitido por `RTTI.FPC.pas:45`). `--all` passa
  **14/14** — os 4 cenarios de valor VERDES asserindo `ENotImplemented`.
- [ ] FPC i386, FPC Windows (Win32/Win64) e Delphi (Win32/Win64): **nao**
  verificados na fabrica; ficam com o autor (D-29.3 / SKILL.md).
- [ ] PR body carrega:
  - Frase declarativa: *"compilado em FPC 3.2.2 x86_64-linux (fabrica,
    com o path RTL vivo caindo em ENotImplemented — comportamento
    documentado); Delphi (Win32/Win64) e FPC Windows (Win32/Win64)
    ficam com o autor."*
  - Log da execucao FPC da fabrica em `<details>` (14/14 verdes).
  - Referencia a `rtti.pp:583` e
    `packages/rtl-objpas/src/<arch>/invoke.inc` como fontes da
    divergencia por alvo.
  - Referencia a secao *"CORRECAO 2 — 03/09/2026, medida DENTRO da
    fabrica"* do corpo da issue como origem das decisoes.
- [ ] Commit unico; mensagem no formato do plano.

## Traps ja pagas (nao repetir)

1. **"Prova em i386" como criterio da fabrica** — impossivel: `ppc386`
   ausente na fabrica (`SKILL.md`). Foi a causa das 9 rejeicoes do ciclo
   028. Aqui o log i386 e opcional, fica com o autor.
2. **"Asserir valor de retorno no FPC" como criterio da fabrica** —
   impossivel em `x86_64-linux`: `SystemInvoke` ausente no FPC 3.2.2.
   Substituido por assertiva de `ENotImplemented` no ramo do alvo (D-29.2).
3. **Ausencia sob `{$IFDEF}` de capacidade** — era o criterio original 1
   da issue, superado. A medicao provou que Delphi + FPC Windows
   EXECUTAM. Ausencia seria desperdicio.
4. **Excecao "nao suportado" inventada por nos no FPC** — introduz
   divergencia inventada. Deixe a `ENotImplemented` da RTL aflorar.
5. **Achatar Delphi para `published` apenas por "simetria"** — joga fora
   capacidade medida; contradiz "cada um faz o que PODE" (D-13.3).
6. **`{$IFDEF FPC}` no cenario compartilhado** — quebra CA-5. Use
   `{$IF defined(FPC) and defined(CPUX86_64) and defined(UNIX)}` (por
   ALVO) onde a divergencia e por alvo.
7. **Ramificar por bitness (`{$IFDEF CPU32/CPU64}`)** — nao corresponde a
   existencia de `SystemInvoke` na RTL. Foi o erro do ciclo 028.
8. **Ramificar por SO apenas (`{$IFDEF UNIX}`)** — pega Delphi Linux
   (LSB) por engano. Sempre `defined(FPC) and defined(CPUX86_64) and
   defined(UNIX)`.
9. **Mensagem de guarda diferente entre backends** — quebra D-2 / D-13.9 /
   D-13.10. Reusar literal do portavel.
10. **`Rtti.Invoke` sem qualificacao** — Delphi/FPC podem resolver
    `Invoke(...)` para `TModernInvoker.Invoke` (recursao infinita ou
    erro de tipo). Sempre `Rtti.Invoke(...)`.
11. **Enumerar Delphi sem `try/finally .Free`** — vaza contexto RTTI ao
    propagar excecao. Toda a enumeracao dentro do bloco (D-13.4).
12. **Fixture `Int64+string`** — SizeOf=16 identico nos dois bitness
    (medido); nao exercita ABI. Usar `Integer+string` (SizeOf=8 i386, 16
    x86_64) e `Double` (D-13.11). Fixture `Integer` sozinho: idem, cabe
    em registrador.
13. **`TValue.AsType<T>`** — Delphi-only. FPC 3.2.2 nao compila
    (`Error: identifier idents no member "AsType"`). Substituir: record
    → `v.ExtractRawData(@r)`; `Double` → `v.AsExtended`; `string` →
    `v.AsString`.
14. **`BoolToStr`** — assinatura divergente FPC vs Delphi
    (`E2010 Incompatible types` no Delphi). `if..then..else` explicito.
15. **FPC compila green sobre `.ppu` velhos** — sempre `rm -rf
    /tmp/fpcbuild` antes de cada compilacao (SKILL.md, trap 2).
16. **Editar os overloads generic da #10** — regressao zero exige que
    fiquem byte-por-byte identicos (D-13.13).
17. **Passar Self implicito na TValueArray do FPC** — `SErrMissingSelfParam`.
    Self e o primeiro elemento (D-13.5).
18. **Mascarar `ENotImplemented` do RTL** — perde o rastro da fonte real
    do erro; o consumidor cross-target precisa ver a mensagem literal
    (`Invoke functionality is not implemented`) para saber que caiu no
    limite da RTL, nao da nossa unit (D-13.2 / D-29.1).

## Contexto de referencia

- ESP: [esp](pipeline-esp.md) (irmao neste diretorio).
- ADR: [adr](pipeline-adr.md) (irmao neste diretorio) — D-13.1..D-13.13
  carregadas + D-29.1..D-29.3 novas.
- Corpo da issue:
  `https://github.com/isaquepinheiro/ModernSyntax/issues/13` — secoes
  "CORRECAO DE PREMISSA — 03/09/2026, medida rodando" e **"CORRECAO 2 —
  03/09/2026, medida DENTRO da fabrica"** (esta ultima e a origem das
  decisoes deste ciclo).
- ADR do ciclo 028:
  [`../history/cycles/cycle-028-3973e0a8/pipeline-adr.md`](../cycle-028-3973e0a8/pipeline-adr.md).
- Implement report do ciclo 028:
  [`../history/cycles/cycle-028-3973e0a8/pipeline-implement-report.md`](../cycle-028-3973e0a8/pipeline-implement-report.md)
  — mede `SystemInvoke` ausente em `x86_64-linux`.
- Antecessora: PR da #10 / commit que introduziu
  `Source/ModernSyntax.Invoker.pas` (nucleo portavel).
- Toolchain: [`SKILL.md`](../../../SKILL.md) — comando de compilacao FPC,
  trap dos `.ppu` velhos, ausencia de `ppc386` na fabrica, fronteira
  Delphi (autor).
- Nao ha investigation report externo (status NONE). O desenho vem do
  proprio corpo da issue (secao CORRECAO 2).
