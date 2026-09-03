---
type: task-input
kind: artifact
title: "Task-input #13 — TModernInvoker.Invoke dinamico cross-compiler"
description: "Handoff operacional para o implementador: novo overload TValue-based com assinatura identica cross-compiler, backends divergentes por IFDEF, fixtures ABI-divergent, cascas de teste com assimetria deliberada, cabecalho da unit reescrito, um commit."
cycle: "028"
agent: architect
workflow: equipe-feature
node: "plan-gate:on_reject"
resource: aefos://run/3973e0a8a9fb319c0e20e1154e93d8d3
generated:
  by: "equipe-feature@node:architect"
  at: "2026-09-03T00:00:00Z"
tags: [task-input, rtti, invoker, fpc, delphi, dynamic-invoke, tvalue, issue-13, cycle-028]
---

# Task-input #13 — `TModernInvoker.Invoke` dinamico cross-compiler

## Titulo

feat(invoker): overload dinamico TValue-based cross-compiler (#13)

## Tipo / labels

- `feature`
- `rtti`
- `fpc`
- `delphi`
- `modernrtti`
- `invoker`

## Escopo em uma linha

Entregar o overload dinamico `TModernInvoker.Invoke(AInstance, AName,
AArgs, AResultType): TValue` com **assinatura publica identica** em
Delphi e FPC 3.2.2 e mecanismo interno divergente por `{$IFDEF FPC}`;
Delphi via `TRttiContext.GetMethod.Invoke` (alcance `public` +
`published`), FPC via `TObject.MethodAddress` + `Rtti.Invoke` livre
(alcance `published` apenas). O portavel `Invoke<TSignature>` da #10
**nao muda**.

## Arquivos impactados

| Arquivo | Mudanca |
|---------|---------|
| `Source/ModernSyntax.Invoker.pas` | Novo overload dinamico; `uses` acrescenta `Rtti`; corpo por `{$IFDEF FPC}`; cabecalho reescrito — tres blocos superados removidos |
| `Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas` | Fixtures `TDateAndTag` + metodos `published` novos em `TSubject`; 8 novos cenarios `Case_InvokeDynamic_...`; `uses` acrescenta `Rtti` |
| `Test FPC/EclbrSystem/UTestMS.Invoker.pas` | 7 `published procedure InvokeDynamic_...;` (uma linha cada); registra `_RaisesOnFPC`, **NAO** `_OKOnDelphi` |
| `Test Delphi/EclbrSystem/UTestMS.Invoker.pas` | 7 `[Test] procedure InvokeDynamic_...;` (uma linha cada); registra `_OKOnDelphi`, **NAO** `_RaisesOnFPC` |

## Pre-condicao — decisoes fechadas

- **Assinatura unica**, sem `{$IFDEF}` em torno da declaracao (D-13.1).
- **Alcance por compilador** — opcao (a) da issue (D-13.3):
  - Delphi: `public` + `published`.
  - FPC 3.2.2: `published` apenas.
- **Mensagens de guarda reusadas** do portavel da #10 (D-13.9 / D-13.10),
  literais nas duas guardas (`AInstance = nil`; `LAddress = nil` /
  `LMethod = nil`).
- **`ccReg` apenas**; XMLDoc declara essa fronteira (D-13.6 / D-13.8).
- **Construtor** e **record grande por referencia oculta**: FORA do
  escopo; XMLDoc documenta (D-13.8).
- **Overload portavel `Invoke<TSignature>` byte-por-byte identico**
  apos a edicao (D-13.13).

## Checklist de aceitacao

- [ ] `Source/ModernSyntax.Invoker.pas`:
  - Cabecalho `(* ... *)`: tres blocos superados removidos —
    `:12-18` (uses SysUtils apenas / Rtti nao necessario);
    `:20-25` (sem ramificacao por compilador); `:44-51` (nao existe
    Invoke TValue-based). Nota nova acrescentada explicando as duas
    superficies (portavel + dinamica).
  - `uses` da `interface` acrescenta `Rtti`.
  - `TModernInvoker` acrescenta UM `class function Invoke(const
    AInstance: TObject; const AMethodName: string; const AArgs: array of
    TValue; const AResultType: PTypeInfo = nil): TValue; overload;
    static;` com XMLDoc por compilador (D-13.8). **Sem `{$IFDEF}` em
    torno da declaracao.**
  - Implementacao dividida por `{$IFDEF FPC} ... {$ELSE} ... {$ENDIF}`:
    - **FPC**: guarda `AInstance = nil`; `MethodAddress`; guarda
      `LAddress = nil` com mensagem reusada; monta `TValueArray` com
      `TValue.From<TObject>(AInstance)` em `[0]` + `AArgs` a partir de
      `[1]`; chama `Rtti.Invoke(LAddress, LArgs, ccReg, AResultType,
      False, False)`; devolve o retorno.
    - **Delphi**: guarda `AInstance = nil`; `TRttiContext.Create` +
      `try/finally .Free`; `LCtx.GetType(AInstance.ClassType).GetMethod
      (AMethodName)`; guarda `LMethod = nil` com a **mesma** mensagem
      reusada; `Result := LMethod.Invoke(AInstance, AArgs)` DENTRO do
      `try`.
  - `Rtti.Invoke` qualificado com nome da unit (evita colisao com o
    metodo estatico local).
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
  - 8 novos `Case_InvokeDynamic_...` implementados conforme plano
    (`ReturnsRecordIntegerAndString`, `ReturnsDouble`,
    `ReturnsManagedString`, `ProcedureVoid_SideEffect`,
    `NilInstance_Raises`, `MethodNotFound_RaisesInstructive`,
    `PublicWithoutMPlus_RaisesOnFPC`,
    `PublicWithoutMPlus_OKOnDelphi`).
  - Todos os Case usam `TValue.From<T>` para args, `TypeInfo(<tipo>)`
    para `AResultType`, e acessores portaveis para extrair o retorno:
    `ExtractRawData(@r)` para record, `AsExtended` para `Double`,
    `AsString` para `string`. NAO usar `AsType<T>` — Delphi-only
    (FPC 3.2.2 nao compila: `identifier idents no member "AsType"`).
  - `Case_InvokeDynamic_ProcedureVoid_SideEffect` passa `nil` como
    `AResultType` e assere o efeito colateral via `o.Stamped`.
  - `grep -c "{\$IFDEF FPC}"
    "Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas"` retorna 0
    (CA-5).
- [ ] `Test FPC/EclbrSystem/UTestMS.Invoker.pas` acrescenta 7 metodos
  `published procedure InvokeDynamic_...;` (corpo de uma linha cada),
  registrando `InvokeDynamic_PublicWithoutMPlus_RaisesOnFPC` e
  **NAO** `_OKOnDelphi`. Contagem sobe de 7 para **14**.
- [ ] `Test Delphi/EclbrSystem/UTestMS.Invoker.pas` acrescenta 7 metodos
  `[Test] procedure InvokeDynamic_...;` (corpo de uma linha cada),
  registrando `InvokeDynamic_PublicWithoutMPlus_OKOnDelphi` e
  **NAO** `_RaisesOnFPC`.
- [ ] Nenhuma citacao NOVA de linha do proprio repo em teste/fixture
  (classe #64). Simbolo ou RTL externa apenas.
- [ ] `PTestInvoker` compila limpo no FPC 3.2.2 x86_64 (fabrica) com
  UNICO warning esperado `Unit "Rtti" is experimental`. `--all` passa
  14/14.
- [ ] i386 e os 4 alvos Delphi: **nao** verificados na fabrica; ficam
  com o autor (D-13.12).
- [ ] PR body carrega:
  - Frase declarativa: *"compilado em FPC 3.2.2 x86_64 (fabrica) e i386
    (autor); Delphi (Win32/Win64) fica com o autor."*
  - Log das duas execucoes do FPC em `<details>` (x86_64 + i386 — o
    i386 vem do autor antes do merge).
  - Referencia a `rtti.pp:583` (funcao `Invoke` livre usada no backend
    FPC).
  - Referencia a secao *"CORRECAO DE PREMISSA — 03/09/2026, medida
    rodando"* do corpo da issue como origem das decisoes.
- [ ] Commit unico; mensagem no formato do plano.

## Traps ja pagas (nao repetir)

1. **Ausencia sob `{$IFDEF}` de capacidade** — era o criterio original
   1 da issue, superado. A medicao do dono em 2026-09-03 provou que o
   FPC EXECUTA (`Rtti.Invoke` livre em `rtti.pp:583`). Ausencia seria
   desperdicio deliberado.
2. **Excecao "nao suportado" no FPC** — era o "criterio 2 na pratica".
   Introduz divergencia inventada; foi o defeito que fechou PRs #11 e
   #12. NAO fazer.
3. **Achatar Delphi para `published` apenas por "simetria"** — joga
   fora capacidade medida do compilador mais forte; contradiz "cada um
   faz o que PODE" (D-13.3).
4. **`{$IFDEF FPC}` no cenario compartilhado** — quebra CA-5. A
   assimetria fica na CASCA: FPC registra `_RaisesOnFPC`, Delphi
   registra `_OKOnDelphi`; ambos os Case existem no `.Cases.pas` sem
   diretiva.
5. **Mensagem de guarda diferente entre backends** — quebra D-2 e D-13.9/
   D-13.10. Reusar literal do portavel.
6. **`Rtti.Invoke` sem qualificacao** — Delphi/FPC podem resolver
   `Invoke(...)` para `TModernInvoker.Invoke` (recursao infinita ou erro
   de tipo). Sempre `Rtti.Invoke(...)`.
7. **Enumerar Delphi e ignorar `try/finally .Free`** — vaza contexto
   RTTI ao propagar excecao. Toda a enumeracao dentro do bloco (D-13.4).
8. **Fixture com `Int64+string`** — layout identico nos dois bitness
   (SizeOf=16 em ambos; medido): nao exercita ABI divergente.
   Usar `Integer+string` (record — SizeOf=8 i386, SizeOf=16 x86_64)
   e `Double` (D-13.11). Fixture com `Integer` sozinho: idem, cabe
   em registrador nos dois.
13. **`TValue.AsType<T>` e Delphi-only** — FPC 3.2.2 nao compila
    (`Error: identifier idents no member "AsType"`). Substituir:
    record → `v.ExtractRawData(@r)`; Double → `v.AsExtended`;
    string → `v.AsString`. Estes tres existem nos dois compiladores.
9. **`BoolToStr`** — assinatura divergente FPC vs Delphi
   (`E2010 Incompatible types` no Delphi). `if..then..else` explicito.
10. **FPC compila green sobre `.ppu` velhos** — sempre `rm -rf /tmp/fpcbuild`
    antes de cada compilacao (SKILL.md, trap 2).
11. **Editar os overloads generic da #10** — regressao zero exige que
    fiquem byte-por-byte identicos (D-13.13).
12. **Passar Self por dentro (implicito) na TValueArray do FPC** —
    `SErrMissingSelfParam`. Self e o primeiro elemento (D-13.5).

## Contexto de referencia

- ESP: `esp.md` (irmao neste diretorio).
- ADR: `adr.md` (irmao neste diretorio) — 13 decisoes (D-13.1..D-13.13).
- Corpo da issue: `https://github.com/isaquepinheiro/ModernSyntax/issues/13`
  — secao *"CORRECAO DE PREMISSA — 03/09/2026, medida rodando"* carrega
  a medicao e o desenho acordado com o dono.
- Antecessora: PR da #10 / commit que introduziu
  `Source/ModernSyntax.Invoker.pas` (nucleo portavel).
- Toolchain: [`SKILL.md`](../../../SKILL.md) — comando de compilacao FPC,
  trap dos `.ppu` velhos, ausencia de cross-compiler i386 na fabrica,
  fronteira Delphi (autor).
- Nao ha investigation report externo (status NONE; 0 comentarios). O
  desenho vem do proprio corpo da issue.
