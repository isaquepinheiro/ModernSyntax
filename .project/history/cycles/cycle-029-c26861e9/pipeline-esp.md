---
type: spec
kind: artifact
title: "ESP #13 (cycle 029) — TModernInvoker.Invoke dinamico com fronteira POR ALVO"
description: "Especificacao formal do overload dinamico TValue-based com assinatura identica cross-compiler; testes e XMLDoc ramificam por alvo (Delphi | FPC win32|win64 | FPC x86_64-linux) porque a RTL do FPC 3.2.2 so implementa SystemInvoke em alvos Windows."
cycle: "029"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/c26861e980aa5045a4f8b7de8b2207c2
generated:
  by: "equipe-feature@node:architect"
  at: "2026-09-03T00:00:00Z"
tags: [spec, rtti, invoker, fpc, delphi, dynamic-invoke, tvalue, per-target, systeminvoke, issue-13, cycle-029]
---

# ESP #13 (cycle 029) — `TModernInvoker.Invoke` dinamico, fronteira POR ALVO

## 1. Objetivo

Entregar o overload dinamico do `TModernInvoker`, no formato da `System.Rtti`:

```pascal
class function Invoke(const AInstance: TObject; const AMethodName: string;
  const AArgs: array of TValue;
  const AResultType: PTypeInfo = nil): TValue; overload; static;
```

com **assinatura publica identica** em Delphi e FPC 3.2.2, mecanismo interno
divergente por `{$IFDEF FPC}` e **fronteira de execucao declarada por ALVO**,
nao por compilador — porque a RTL do FPC 3.2.2 so implementa `SystemInvoke` em
alvos Windows (`x86_64-win64`, `i386-win32`); em `x86_64-linux` (SysV AMD64) o
`Rtti.Invoke` livre cai em `raise Exception.Create(SErrInvokeNotImplemented)`.

O overload portavel `Invoke<TSignature>(TObject|TClass, string)` da #10 **nao
muda**.

## 2. Contexto — o que este ciclo corrige da rodada anterior

A rodada anterior (cycle 028, run `3973e0a8`) foi rejeitada nove vezes com o
mesmo veredito (`REJECTED · causa: spec · node blamed: architect`, com
`node_rework_triggered → target: implement`, que nao pode consertar spec). A
causa: dois criterios do ESP/plano anterior eram **impossiveis de satisfazer
dentro do container da fabrica**:

1. *"Prova nos DOIS bitness do FPC (i386 e x86_64)"* — a fabrica **nao tem
   `ppc386`**: `fpc -iTP → x86_64`; `ppc386 → error 127` (`SKILL.md`, secao
   "FPC disponivel na fabrica"). i386 nunca foi executavel na fabrica.
2. *"O backend FPC invoca metodo `published` e assere valor de retorno"* — a
   `Rtti.Invoke` livre (`rtti.pp:583`) depende de `SystemInvoke`, implementado
   em assembly **por alvo** (`packages/rtl-objpas/src/<arch>/invoke.inc`). Em
   FPC 3.2.2 esse assembly so existe para `x86_64-win64` e `i386-win32`. No
   alvo da fabrica (`x86_64-linux`, SysV AMD64), o fallback e
   `raise Exception.Create(SErrInvokeNotImplemented)` — medido dentro do
   container (`strings rtti.ppu | grep SErrInvokeNotImplemented` confirma o
   resource string ativo).

A correcao registrada pelo dono no proprio corpo da #13, secao **"CORRECAO 2 —
03/09/2026, medida DENTRO da fabrica"**, e clara: a assinatura identica e as
tres remocoes de cabecalho **continuam valendo**; o que muda e a ancoragem da
prova — de **bitness** para **alvo** — e o teste passa a **ramificar por alvo**
com `{$IF defined(CPUX86_64) and defined(UNIX)}`.

## 3. Escopo

**4 arquivos, 1 slice, 1 commit.**

| # | Arquivo | Mudanca |
|---|---------|---------|
| 1 | `Source/ModernSyntax.Invoker.pas` | Novo overload dinamico `Invoke(AInstance, AName, AArgs, AResultType): TValue`; corpo por `{$IFDEF FPC}`; `uses` da `interface` acrescenta `Rtti`; tres blocos superados do cabecalho removidos; XMLDoc declarando alcance e fronteira **por alvo** |
| 2 | `Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas` | Fixtures `TDateAndTag` (`Integer+string`) e metodos `published` novos em `TSubject`; 8 novos `Case_InvokeDynamic_...` — os quatro cenarios de retorno de valor **ramificam por alvo** com `{$IF defined(CPUX86_64) and defined(UNIX)}`, asserindo `ENotImplemented` no alvo sem `SystemInvoke` e o valor onde houver |
| 3 | `Test FPC/EclbrSystem/UTestMS.Invoker.pas` | 7 novas `published procedure InvokeDynamic_...;` (corpo de uma linha delegando ao `Case_...`); registra `_RaisesOnFPC`, NAO `_OKOnDelphi` |
| 4 | `Test Delphi/EclbrSystem/UTestMS.Invoker.pas` | 7 novos `[Test] procedure InvokeDynamic_...;` (corpo de uma linha delegando ao `Case_...`); registra `_OKOnDelphi`, NAO `_RaisesOnFPC` |

## 4. Fora do escopo

- **Alterar o overload portavel `Invoke<TSignature>` da #10.** Fica identico
  em assinatura e corpo. Nao mexer (regressao zero).
- **Emular `TRttiContext.GetMethods` no FPC.** Enumeracao continua vazia; a
  #13 nao a resolve.
- **Portar `SystemInvoke` para SysV AMD64.** Limite da RTL do FPC 3.2.2 —
  documenta-se, nao se conserta.
- **Outras convencoes de chamada.** So `ccReg` (padrao de metodo no FPC)
  entra medida — `ccCdecl`, `ccStdCall`, `ccPascal` ficam fora; XMLDoc nao
  promete.
- **Retorno de record grande passado por referencia oculta** (ABI-dependente).
  Fora do escopo; XMLDoc registra a fronteira.
- **Construtor** (`aIsConstructor = True`). `rtti.pp:2334` marca
  `{ ToDo: handle IsConstructor }` e levanta `ENotImplemented` na propria RTL
  do FPC — limite do FPC, uma linha no XMLDoc registra e fica ai.
- **Overload que aceita `TClass`** analogo. Nao pedido; se aparecer demanda,
  vira issue propria.
- **Prova i386.** A fabrica nao tem `ppc386`; **nao e criterio da fabrica**.
  Se o autor rodar, cola no PR; se nao rodar, o PR nao mente sobre isso.

## 5. Regras de negocio e restricoes

1. **Assinatura publica identica** (D-13.1): declaracao unica, **sem** `{$IFDEF}`
   em torno do `class function ... : TValue;`. Divergencia mora no CORPO da
   implementacao, guardada por `{$IFDEF FPC} ... {$ELSE} ... {$ENDIF}`.
2. **Sem excecao "nao suportado" INVENTADA por nos** (D-13.2). A unica excecao
   de "nao implementado" que o FPC devolve nesta superficie e a que **a
   propria RTL do FPC** propaga — `SErrInvokeNotImplemented` em alvo sem
   `SystemInvoke`. Nao a mascaramos, nao a re-embrulhamos com texto proprio,
   nao acrescentamos guarda para preveni-la. Ela **aflora**.
3. **Alcance por compilador** (D-13.3): Delphi mantem o alcance maior (`public`
   + `published`) via `TRttiContext.GetMethod`; FPC 3.2.2 cobre **`published`
   apenas** via `TObject.MethodAddress`. Cada compilador entrega o que PODE.
4. **Backend Delphi cria `TRttiContext` local com `try/finally .Free`**
   (D-13.4): materializa `Result` dentro do bloco. `LMethod.Invoke` devolve
   `TValue`; o valor sobrevive ao `.Free` do contexto (copia).
5. **Backend FPC monta `TValueArray` com Self primeiro** (D-13.5): primeiro
   elemento e `TValue.From<TObject>(AInstance)`, seguido dos `AArgs` em
   ordem. `aIsStatic = False`, `aIsConstructor = False`. `aCallConv = ccReg`.
6. **Convencao de chamada: `ccReg`** (D-13.6). Padrao de metodo no FPC. XMLDoc
   declara.
7. **Cabecalho da unit reescrito na MESMA edicao** (D-13.7): os tres blocos
   superados caem juntos — `:12-18` (uses SysUtils apenas), `:20-25` (sem
   ramificacao por compilador), `:44-51` (nao existe overload TValue). Nota
   nova acrescentada explicando as DUAS superficies (portavel + dinamica) e
   citando a fronteira por alvo (item 8 abaixo).
8. **XMLDoc por ALVO, nao por compilador** (D-29.1 — nova neste ciclo). A
   declaracao publica leva XMLDoc dizendo, em prosa, o alcance de cada backend
   E a fronteira por alvo:
   - `Delphi: public + published (via TRttiContext.GetMethod).`
   - `FPC 3.2.2 win32/win64: published (via TObject.MethodAddress + Rtti.Invoke livre).`
   - `FPC 3.2.2 x86_64-linux (e outros alvos sem SystemInvoke): ENotImplemented da RTL (SErrInvokeNotImplemented, rtti.pp:583 + packages/rtl-objpas/src/<arch>/invoke.inc). Limite do FPC, nao escolha nossa.`
   - Fronteira metodica: `ccReg` apenas; construtor levanta `ENotImplemented`
     no FPC (RTL `rtti.pp:2334`); record grande por referencia oculta nao
     coberto.
9. **Guarda `AInstance = nil`** (D-13.9): mesma mensagem do portavel
   (`'AInstance e nil'`). Simetria.
10. **Guarda `LAddress = nil` / `LMethod = nil`** (D-13.10): mensagem
    instrutiva reusada do portavel — literal — nos DOIS backends.
11. **Fixture com layouts ABI-divergentes** (D-13.11): record com
    `Integer + string` (SizeOf=8 no i386, SizeOf=16 no x86_64 — medido) e
    metodo devolvendo `Double`. **Nunca `Int64 + string`** — SizeOf=16 nos
    dois bitness (identico; nao exercita ABI). **Nunca `Integer` sozinho** —
    cabe em registrador; sem divergencia. A fixture escolhida pega mutacao
    de offset **quando o alvo souber invocar** (a fabrica hoje **nao sabe**;
    o autor prova nos alvos Windows).
12. **Testes de retorno de valor ramificam por ALVO** (D-29.2 — nova neste
    ciclo): usar `{$IF defined(CPUX86_64) and defined(UNIX)}` (equivalente ao
    alvo `x86_64-linux` da RTL FPC 3.2.2 sem `SystemInvoke`) para asserir
    `ENotImplemented`; no `{$ELSE}`, asserir o **valor de retorno**. Isto
    vale para os quatro cenarios que chamam `Rtti.Invoke` de verdade
    (`ReturnsRecordIntegerAndString`, `ReturnsDouble`, `ReturnsManagedString`,
    `ProcedureVoid_SideEffect`). Os tres cenarios de **guarda** (`Nil`,
    `MethodNotFound`, `PublicWithoutMPlus`) **NAO ramificam** — a guarda
    dispara antes da RTL, o comportamento e o mesmo em qualquer alvo.
13. **A fabrica prova o que o ambiente dela permite** (D-29.3 — nova neste
    ciclo): compilacao limpa da suite (0 warnings novos alem de eventual
    `Unit "Rtti" is experimental`, ja emitido por `RTTI.FPC.pas:45`) + suite
    verde **14/14** em `x86_64-linux` — os 4 cenarios de retorno passam
    verde asserindo `ENotImplemented` (por D-29.2). i386 e alvos Windows
    ficam com o autor.
14. **PR body declara a fronteira** (D-13.12 estendida): frase declarativa
    de alvo, sem checklist bloqueante. *"compilado em FPC 3.2.2 x86_64-linux
    (fabrica, com o path RTL vivo caindo em ENotImplemented — comportamento
    documentado); Delphi (Win32/Win64) e FPC Windows (Win32/Win64) ficam com
    o autor."* Log da execucao FPC da fabrica em `<details>`.
15. **Sem `resourcestring` novo** (D-1 do bundle). Mensagens de guarda sao
    literais, seguindo o padrao do portavel da #10.
16. **A superficie portavel `Invoke<TSignature>` da #10 nao muda**
    (D-13.13). Compilacao continua verde e os 7 cenarios existentes seguem
    passando nos dois compiladores.
17. **Sem `{$IFDEF FPC}` no `.Cases.pas` para separar backends** (CA-5). A
    ramificacao permitida neste arquivo e **por ALVO** (`{$IF defined(...)}`),
    nao por compilador. A separacao `RaisesOnFPC` vs `OKOnDelphi` mora nas
    CASCAS.

## 6. Criterios de aceitacao

- [ ] `Source/ModernSyntax.Invoker.pas` declara **um unico** `class function
      Invoke(const AInstance: TObject; const AMethodName: string;
      const AArgs: array of TValue; const AResultType: PTypeInfo = nil): TValue;`
      na `interface`, **sem `{$IFDEF}` em torno da declaracao**.
- [ ] `uses` da `interface` acrescenta `Rtti` (para `TValue`, `PTypeInfo`,
      `TCallConv`, `TValueArray`, `ccReg`).
- [ ] Corpo do overload dinamico dividido por `{$IFDEF FPC}`:
      - **FPC**: guarda `AInstance = nil`; `MethodAddress`; guarda
        `LAddress = nil` com a mensagem reusada; monta `LArgs` com
        `TValue.From<TObject>(AInstance)` em `[0]` seguido dos `AArgs`;
        chama `Rtti.Invoke(LAddress, LArgs, ccReg, AResultType, False, False)`
        (qualificado com o nome da unit para nao colidir com o metodo
        estatico local); devolve o retorno **sem** re-embrulhar excecoes
        da RTL.
      - **Delphi**: guarda `AInstance = nil`; `TRttiContext.Create` +
        `try/finally .Free`; `LType := LCtx.GetType(AInstance.ClassType)`;
        `LMethod := LType.GetMethod(AMethodName)`; se `LMethod = nil`
        levanta com a **mesma** mensagem reusada; `Result := LMethod.Invoke
        (AInstance, AArgs)` DENTRO do `try`.
- [ ] Os tres blocos do cabecalho (`:12-18`, `:20-25`, `:44-51`) removidos
      na mesma edicao. Nota nova cobre as duas superficies e cita a
      fronteira **por alvo** (D-29.1).
- [ ] XMLDoc na declaracao publica declara alcance por compilador E
      fronteira por alvo (D-29.1), citando `SErrInvokeNotImplemented`,
      `rtti.pp:583` e `packages/rtl-objpas/src/<arch>/invoke.inc`.
- [ ] `Source/ModernSyntax.Invoker.pas` **nao** altera nada do overload
      portavel `Invoke<TSignature>` (linhas dos generics intocadas).
- [ ] `Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas` acrescenta:
  - `TDateAndTag = record Stamp: Integer; Tag: string; end;` na secao `type`
    da interface;
  - `TSubject` (na `implementation`, dentro do `{$M+}`) ganha `FStamped`
    (private) + `GimmeStamp`, `GimmeAngle`, `StampNow`, `Stamped`
    (published);
  - **`uses` da interface acrescenta `Rtti`**;
  - 8 `Case_InvokeDynamic_...` novos:
    - **Ramificam por alvo** (D-29.2) — os 4 de valor:
      `Case_InvokeDynamic_ReturnsRecordIntegerAndString`,
      `Case_InvokeDynamic_ReturnsDouble`,
      `Case_InvokeDynamic_ReturnsManagedString`,
      `Case_InvokeDynamic_ProcedureVoid_SideEffect` — usam
      `{$IF defined(CPUX86_64) and defined(UNIX)}` para asserir
      `ENotImplemented` (mensagem `Invoke functionality is not implemented`);
      no `{$ELSE}`, asserem o valor de retorno via `ExtractRawData(@r)`,
      `AsExtended`, `AsString`, e (para o void) `o.Stamped = 42`.
    - **Nao ramificam** (guardas disparam antes da RTL):
      `Case_InvokeDynamic_NilInstance_Raises`,
      `Case_InvokeDynamic_MethodNotFound_RaisesInstructive`,
      `Case_InvokeDynamic_PublicWithoutMPlus_RaisesOnFPC`,
      `Case_InvokeDynamic_PublicWithoutMPlus_OKOnDelphi`.
  - **Zero `{$IFDEF FPC}`** no arquivo (CA-5). Ramificacao permitida e
    `{$IF defined(CPUX86_64) and defined(UNIX)}` (por alvo, nao por
    compilador).
- [ ] `Test FPC/EclbrSystem/UTestMS.Invoker.pas` acrescenta 7 metodos
      `published procedure InvokeDynamic_...;` (corpo de uma linha
      delegando ao `Case_...`), registrando `_RaisesOnFPC` e **NAO**
      `_OKOnDelphi`. Contagem sobe de 7 para **14**.
- [ ] `Test Delphi/EclbrSystem/UTestMS.Invoker.pas` acrescenta 7 metodos
      `[Test] procedure InvokeDynamic_...;` (corpo de uma linha delegando
      ao `Case_...`), registrando `_OKOnDelphi` e **NAO** `_RaisesOnFPC`.
- [ ] O overload portavel `Invoke<TSignature>` compila e passa 7/7 nos
      dois compiladores (regressao zero).
- [ ] `PTestInvoker.lpr` compila limpo no FPC 3.2.2 x86_64-linux (fabrica);
      `--all` passa **14/14**. Nenhum warning novo alem do esperado
      `Unit "Rtti" is experimental` (se o compilador o emitir — depende da
      subversao da RTL).
- [ ] PR body carrega:
      - Frase declarativa: *"compilado em FPC 3.2.2 x86_64-linux (fabrica,
        path RTL vivo cai em ENotImplemented — comportamento documentado);
        Delphi (Win32/Win64) e FPC Windows (Win32/Win64) ficam com o autor."*
      - Log da execucao FPC da fabrica em `<details>`.
      - Referencia a `rtti.pp:583` e a
        `packages/rtl-objpas/src/<arch>/invoke.inc` como fontes da
        divergencia por alvo.
      - Referencia a secao *"CORRECAO 2 — 03/09/2026, medida DENTRO da
        fabrica"* do corpo da issue como origem das decisoes deste ciclo.

## 7. Riscos

| Risco | Prob | Impacto | Mitigacao |
|-------|------|---------|-----------|
| Consumidor cross-target confundir alcance ou fronteira | Media | Medio | XMLDoc por ALVO (D-29.1), com tres linhas: Delphi / FPC-Windows / FPC-Linux — cita `SErrInvokeNotImplemented` literal |
| Teste ramificar por alvo errado (usar `{$IFDEF FPC}`) e mascarar o defeito | Baixa | Alto | CA-5 mantido: `grep -c "{\$IFDEF FPC}" ".../UTestMS.Invoker.Cases.pas"` = 0. Ramificacao permitida e `{$IF defined(CPUX86_64) and defined(UNIX)}` — inspecao explicita no gate |
| FPC 3.3.x portar `SystemInvoke` para SysV AMD64 e mudar o comportamento do teste | Baixa | Baixo | Piso do projeto e 3.2.2 (`SKILL.md`). Se um dia mudar, o teste `Fail`a; entao adaptar |
| RTL FPC mudar assinatura de `Rtti.Invoke` livre | Baixa | Alto (nao compila) | 3.2.2 fixado como piso; `rtti.pp:583` citado no XMLDoc; nova versao vira issue |
| `TRttiContext` local do Delphi vazar contexto se `Invoke` levantar | Baixa | Medio | `try/finally .Free` (D-13.4) |
| Regressao no portavel `Invoke<TSignature>` | Baixa | Alto | 7 cenarios existentes intocados; compilacao + suite provam |
| Autor esquecer de rodar Windows antes do merge | Media | Alto | Frase declarativa OBRIGATORIA no PR body (D-13.12 estendida); revisor humano gate final |
| Fixture passar verde num alvo por coincidencia | Baixa | Medio | D-13.11 (Integer+string diverge; Double idem); analogia com #53 registrada |
| Warning "Rtti is experimental" contaminar CI | Baixa | Baixo | Ja emitido por `RTTI.FPC.pas:45`; nao muda o quadro |
