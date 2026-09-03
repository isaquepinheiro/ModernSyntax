---
type: spec
kind: artifact
title: "ESP #13 — TModernInvoker.Invoke dinamico cross-compiler (assinatura identica, mecanismo divergente)"
description: "Especificacao formal: entregar o overload dinamico TValue-based do TModernInvoker com superficie publica identica em Delphi e FPC 3.2.2, mecanismo interno divergente por IFDEF."
cycle: "028"
agent: architect
workflow: equipe-feature
node: "plan-gate:on_reject"
resource: aefos://run/3973e0a8a9fb319c0e20e1154e93d8d3
generated:
  by: "equipe-feature@node:architect"
  at: "2026-09-03T00:00:00Z"
tags: [spec, rtti, invoker, fpc, delphi, dynamic-invoke, tvalue, issue-13, cycle-028]
---

# ESP #13 — `TModernInvoker.Invoke` dinamico cross-compiler

## 1. Objetivo

Entregar o overload dinamico do `TModernInvoker`, com forma da `System.Rtti`:

```pascal
class function Invoke(const AInstance: TObject; const AMethodName: string;
  const AArgs: array of TValue;
  const AResultType: PTypeInfo = nil): TValue; overload; static;
```

com **assinatura publica identica** em Delphi e FPC 3.2.2, sem `{$IFDEF}` na
superficie, e mecanismo interno divergente por `{$IFDEF FPC}`:

- **Delphi**: `TRttiContext.GetType(...).GetMethod(AName).Invoke(AInstance, AArgs)`.
- **FPC 3.2.2**: `AInstance.MethodAddress(AName)` + `Rtti.Invoke(CodePointer, TValueArray, ccReg, AResultType, False, False)` (funcao livre de `rtti.pp:583`).

O overload portavel `Invoke<TSignature>(TObject|TClass, string)` da #10
**nao muda**.

## 2. Contexto

A #10 entregou o nucleo portavel (`Invoke<TSignature>` sobre `MethodAddress`).
O cabecalho da unit `ModernSyntax.Invoker.pas` afirma em `:44-51`:

> *"Nao existe `Invoke(obj, 'Nome', [args]): TValue` nesta entrega — no FPC
> 3.2.2 nao ha de onde ler os tipos dos parametros para montar a chamada
> (`GetMethods = 0` para qualquer classe, medido)."*

Essa frase **conflaciona duas coisas**: *ler os tipos por RTTI* (descoberta,
que de fato e vazia no FPC 3.2.2) e *montar a chamada* (invocacao). A
medicao registrada no corpo da #13 em 2026-09-03 prova que **o FPC 3.2.2 FAZ
invocacao dinamica**, e o caminho e a funcao livre `rtti.pp:583`:

```pascal
function Invoke(aCodeAddress: CodePointer; const aArgs: TValueArray;
  aCallConv: TCallConv; aResultType: PTypeInfo;
  aIsStatic: Boolean; aIsConstructor: Boolean): TValue;
```

`SystemInvoke` esta implementado em assembly por arquitetura
(`packages/rtl-objpas/src/x86_64/invoke.inc:126` e o par em `i386/invoke.inc`).
Nao le tipo nenhum: os `TValue` de entrada ja carregam `TypeInfo`, e
`aResultType` vem do consumidor (`nil` para `procedure`).

Medicao no corpo da #13 nos dois bitness do FPC 3.2.2:

```
                                        i386        x86_64
Somar(2,3) via array of TValue          = 5         = 5
Concat('id-', 42)                       = id-42     = id-42   <- managed
SemRetorno(6) -> efeito colateral       = 42        = 42      <- caminho void
SoPublic (public nao-published)         levanta     levanta   <- fronteira
```

Isto derruba a premissa dos criterios 1 e 2 da issue original e habilita o
overload dinamico com **superficie identica** — o desenho registrado no ADR.

## 3. Escopo

**4 arquivos, 1 slice, 1 commit.**

| # | Arquivo | Mudanca |
|---|---------|---------|
| 1 | `Source/ModernSyntax.Invoker.pas` | Novo overload `Invoke(AInstance, AName, AArgs, AResultType): TValue`; corpo por `{$IFDEF FPC}`; `Rtti` acrescentado ao `uses` (Delphi e FPC); tres blocos superados do cabecalho removidos; XMLDoc novo declarando alcance por compilador e fronteira medida |
| 2 | `Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas` | Fixtures `published` novas cobrindo record `Integer+string`, `Double` e caminho void; cenarios `Case_InvokeDynamic_...` que assertam o valor de retorno via `ExtractRawData` / `AsExtended` / `AsString` |
| 3 | `Test FPC/EclbrSystem/UTestMS.Invoker.pas` | `published procedure InvokeDynamic_...;` para cada cenario novo, corpo de uma linha delegando ao `Case_...` |
| 4 | `Test Delphi/EclbrSystem/UTestMS.Invoker.pas` | `[Test] procedure InvokeDynamic_...;` para cada cenario novo, corpo de uma linha delegando ao `Case_...` |

## 4. Fora do escopo

- **Alterar o overload portavel `Invoke<TSignature>` da #10.** Fica identico
  em assinatura e corpo. Nao mexer.
- **Emular `TRttiContext.GetType(T).GetMethods` no FPC.** Enumeracao continua
  vazia; a #13 nao a resolve.
- **Outras convencoes de chamada.** So `ccReg` (padrao de metodo no FPC)
  entra medida — `ccCdecl`, `ccStdCall`, `ccPascal` ficam fora e o XMLDoc
  nao promete.
- **Retorno de record grande passado por referencia oculta** (ABI-dependente).
  Fora, XMLDoc nao promete.
- **Construtor** (`aIsConstructor = True`). `rtti.pp:2334` marca
  `{ ToDo: handle IsConstructor }` e levanta `ENotImplemented` na RTL do
  FPC — limite do FPC, nao escolha nossa. Uma linha no XMLDoc registra e
  fica ai.
- **Overload que aceita `TClass`** (analogo ao portavel `Invoke<TSignature>(AClass, ...)`).
  Nao pedido; se aparecer demanda, vira issue propria.
- **Sobrescrever a mensagem da guarda `LAddress = nil`.** Reusar a
  existente (`:85-87` do arquivo atual): *"metodo "%s" nao encontrado em
  %s; no FPC isso exige {$M+} e secao published"*. Simetria com o portavel.

## 5. Regras de negocio e restricoes

1. **Assinatura publica identica** (D-13.1): declaracao unica, **sem**
   `{$IFDEF}` em torno do `class function ... : TValue;`. Divergencia mora
   no CORPO da implementacao, guardada por `{$IFDEF FPC} ... {$ELSE} ... {$ENDIF}`.
2. **Sem excecao "nao suportado"** como comportamento principal
   (D-13.2). O FPC **implementa**. A unica excecao que o FPC devolve por
   fronteira e a de `AInstance = nil` (reusada do portavel) e a de
   `LAddress = nil` (mesmo texto instrutivo do portavel, `:85-87` do
   arquivo atual).
3. **Alcance por compilador** (D-13.3): opcao (a) da issue — o Delphi
   mantem o alcance maior. `public` + `published` no Delphi;
   **`published` apenas** no FPC. Cada compilador entrega o que PODE. Nao
   se achata o Delphi para caber no FPC.
4. **Backend Delphi cria `TRttiContext` local com `try/finally .Free`**
   (D-13.4): materializar o `Result` **dentro** do bloco. `LMethod.Invoke`
   devolve `TValue`; o valor sobrevive ao `.Free` do contexto (o `TValue`
   copia seu conteudo), mas a **enumeracao** nao — logo tudo dentro do
   bloco.
5. **Backend FPC monta `TValueArray` com Self primeiro** (D-13.5):
   `SErrMissingSelfParam` do proprio `rtti.pp` obriga que o primeiro
   elemento seja `TValue.From<TObject>(AInstance)`, seguido dos `AArgs`
   em ordem. `aIsStatic = False`, `aIsConstructor = False` sempre neste
   overload. `aCallConv = ccReg`.
6. **Convencao de chamada assumida: `ccReg`** (D-13.6). Padrao de metodo
   no FPC. XMLDoc declara. Outras convencoes: fora do escopo.
7. **Cabecalho da unit reescrito na MESMA edicao** (D-13.7): os tres
   blocos superados **caem juntos** — nao ficam para "commit de doc"
   futuro:
   - `:12-18` (*"uses SysUtils; apenas / Rtti e TypInfo nao sao
     necessarios"*): superado. `TValue` na assinatura obriga `Rtti` nos
     dois. O aviso `Unit "Rtti" is experimental` passa a ser emitido
     tambem por esta unit — o mesmo que `RTTI.FPC.pas:45` ja emite.
   - `:20-25` (*"nao ha ramificacao por compilador"*): superado. O CORPO
     do novo overload diverge por IFDEF; a assinatura nao.
   - `:44-51` (*"Nao existe `Invoke(obj, ...): TValue`"*): superado. E
     a afirmacao falsa que originou os criterios 1 e 2 da issue.
8. **XMLDoc por compilador** (D-13.8): a declaracao publica leva XMLDoc
   dizendo, em prosa, o alcance de **cada** backend, nao uma frase
   generica:
   - `Delphi: public + published (via TRttiContext.GetType/GetMethod).`
   - `FPC 3.2.2: published (via TObject.MethodAddress + Rtti.Invoke).`
   - Frontera: `ccReg` apenas; construtor levanta no FPC (RTL
     `rtti.pp:2334`); record grande por referencia oculta nao coberto.
9. **Guard `AInstance = nil`** (D-13.9): mesma mensagem do portavel
   (`"AInstance e nil"`). Simetria.
10. **Guard `LAddress = nil` no FPC** (D-13.10): reusar a mensagem
    instrutiva ja existente (`:85-87`): *"metodo "%s" nao encontrado em
    %s; no FPC isso exige {$M+} e secao published"*. Nao inventar outra.
11. **Fixture com layouts que DIVERGEM entre i386 e x86_64** (D-13.11):
    record com `Integer + string` e "outro devolvendo `Double`".
    **Nunca `Int64 + string`** — medido: Int64 (8 bytes) com padding
    resulta em SizeOf=16 nos DOIS bitness (layout identico). `Integer +
    string` diverge: SizeOf=8 no i386, SizeOf=16 no x86_64. Analogia
    com #53: fixture escolhida pela razao errada passa verde — escolha
    pela razao certa (divergencia medida) e o padrao. A fixture precisa
    **valor de retorno** que exercite ABI divergente por bitness.
12. **PR body carrega o log das duas execucoes** (D-13.12): FPC 3.2.2
    x86_64 e **i386** — este ultimo fica com o autor (a fabrica nao tem
    cross-compiler i386; ver `SKILL.md`). Os 4 alvos Delphi tambem ficam
    com o autor. Sem checklist bloqueante; frase declarativa como em
    D-53.12.
13. **Sem `resourcestring` novo** (D-1 do bundle). As mensagens sao
    literais nas guardas, seguindo o padrao do portavel da #10.
14. **A superficie portavel `Invoke<TSignature>` da #10 nao muda**
    (D-13.13). Compilacao continua verde nos dois compiladores para os
    7 cenarios existentes.

## 6. Criterios de aceitacao

- [ ] `Source/ModernSyntax.Invoker.pas` declara **um unico** `class function
      Invoke(const AInstance: TObject; const AMethodName: string;
      const AArgs: array of TValue; const AResultType: PTypeInfo = nil): TValue;`
      na `interface`, **sem `{$IFDEF}` em torno da declaracao**.
- [ ] `uses` da `interface` acrescenta `Rtti` (para `TValue`, `PTypeInfo`,
      `TCallConv`); a `implementation` acrescenta `Rtti` **e** (no FPC)
      o modulo que expoe `SysUtils.TObject.MethodAddress` — se `SysUtils`
      ja cobre, manter. Aviso `Unit "Rtti" is experimental` do FPC
      esperado e documentado no ADR.
- [ ] Corpo do overload dinamico dividido por `{$IFDEF FPC}`:
      - **FPC**: `RecordRaiseWrongKind`-analogo nao se aplica (metodo,
        nao record); primeiro guarda `AInstance = nil`, chama
        `AInstance.MethodAddress(AMethodName)`, guarda `LAddress = nil`
        com a mensagem reusada, monta `LArgs: TValueArray` com
        `TValue.From<TObject>(AInstance)` em `[0]` seguido dos `AArgs`,
        chama `Rtti.Invoke(LAddress, LArgs, ccReg, AResultType, False, False)`
        e devolve o retorno.
      - **Delphi**: primeiro guarda `AInstance = nil`; cria
        `TRttiContext` local; `LType := LCtx.GetType(AInstance.ClassType)`;
        `LMethod := LType.GetMethod(AMethodName)`; se `LMethod = nil`
        levanta com a **mesma** mensagem reusada do FPC (simetria de
        mensagem); `Result := LMethod.Invoke(AInstance, AArgs);` dentro
        do `try/finally LCtx.Free;`.
- [ ] Os tres blocos do cabecalho (`:12-18`, `:20-25`, `:44-51`) removidos
      na mesma edicao. XMLDoc novo cobre o alcance por compilador
      (D-13.8) e as tres fronteiras medidas.
- [ ] `Source/ModernSyntax.Invoker.pas` **nao** altera nada do overload
      portavel `Invoke<TSignature>` (linhas de codigo dos generics
      intocadas).
- [ ] `Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas` acrescenta:
  - `TDateAndTag = record` (com `Integer` + `string`) na secao `type`,
    junto com `TSubject`;
  - `published function` novos em `TSubject` (ou classe irma) que
    devolvem: (a) `TDateAndTag` completo; (b) `Double`; (c) `procedure`
    void que muta estado interno observavel; (d) `function` cujo retorno
    e `string` (managed);
  - `Case_InvokeDynamic_ReturnsRecordIntegerAndString` — chama via
    `TModernInvoker.Invoke(o, 'GimmeStamp', [TValue.From<string>('lote')], TypeInfo(TDateAndTag))`,
    extrai com `v.ExtractRawData(@r)` e assere `r.Stamp` e `r.Tag`;
  - `Case_InvokeDynamic_ReturnsDouble` — mesma logica, retorno `Double`;
  - `Case_InvokeDynamic_ProcedureVoid_SideEffect` — `AResultType = nil`;
    afere o efeito colateral (o metodo published grava algo observavel
    na instancia);
  - `Case_InvokeDynamic_ReturnsManagedString` — retorno `string`; assere
    o valor;
  - `Case_InvokeDynamic_NilInstance_Raises` — mensagem do portavel
    reusada;
  - `Case_InvokeDynamic_MethodNotFound_RaisesInstructive` — mensagem
    reusada (`{$M+}` + `published`);
  - `Case_InvokeDynamic_PublicWithoutMPlus_RaisesOnFPC_OKOnDelphi` —
    documenta a **assimetria aceita** (D-13.3): no FPC levanta com a
    mensagem instrutiva; no Delphi executa e devolve o valor (D-2 do
    bundle NAO aplica aqui: o alcance e explicitamente por compilador,
    conforme D-13.3). Este cenario e **partido em dois** pela casca de
    teste — Case FPC assere `Raises`, Case Delphi assere valor.
- [ ] `Test FPC/EclbrSystem/UTestMS.Invoker.pas` acrescenta uma
      `published procedure InvokeDynamic_...;` para cada `Case_` novo,
      corpo de uma linha delegando ao cenario compartilhado. Contagem
      de testes FPC sobe de 7 para **13** (7 novos: 4 de retorno + 2 de
      guarda + 1 do assimetrico lado FPC).
- [ ] `Test Delphi/EclbrSystem/UTestMS.Invoker.pas` acrescenta um
      `[Test] procedure InvokeDynamic_...;` para cada `Case_` novo,
      corpo de uma linha delegando ao cenario compartilhado. Contagem
      Delphi sobe em 7 (mesmos 6 comuns + o assimetrico lado Delphi).
- [ ] O overload portavel `Invoke<TSignature>` compila e passa 7/7 nos
      dois compiladores (regressao zero).
- [ ] `PTestInvoker.lpr` compila limpo no FPC 3.2.2 x86_64; `--all`
      passa 13/13.
- [ ] PR body carrega **o log das duas execucoes do FPC** — x86_64
      (fabrica) e i386 (autor) — colados em `<details>`. Os 4 alvos
      Delphi ficam com o autor.
- [ ] PR body declara: *"compilado em FPC 3.2.2 x86_64 (fabrica) e i386
      (autor); Delphi (Win32/Win64) fica com o autor."*
- [ ] Aviso `Unit "Rtti" is experimental` do FPC apenas — nenhum
      warning novo alem desse. Se aparecer, cite no PR body.

## 7. Riscos

| Risco | Prob | Impacto | Mitigacao |
|-------|------|---------|-----------|
| `Rtti.Invoke` livre mudar assinatura entre releases do FPC | Baixa | Alto (nao compila) | Fixamos FPC 3.2.2 como piso (SKILL.md); `rtti.pp:583` referenciado no XMLDoc. Nova versao muda? Vira issue de suporte |
| Consumidor confundir alcance (esperar `public` no FPC) | Media | Medio | XMLDoc explicito por compilador (D-13.8); cenario `Case_InvokeDynamic_PublicWithoutMPlus_RaisesOnFPC_OKOnDelphi` documenta a assimetria em teste executavel |
| Fixture `Int64+string` passar verde por coincidencia num bitness | Baixa | Alto | Escolha explicita do dono (D-13.11): `Int64+string` diverge de layout entre i386/x86_64; `Double` idem. Prova pelos dois bitness (i386 fica com o autor) |
| Convencao de chamada diferente de `ccReg` (metodo `stdcall`) | Media | Medio | XMLDoc declara `ccReg` apenas; teste nao exercita outra; se consumidor chamar com `stdcall`, comportamento indefinido — documentado como fronteira |
| `TRttiContext` local do Delphi vazar contexto se `Invoke` levantar | Baixa | Medio | `try/finally .Free` em torno de tudo (D-13.4); a excecao propaga com contexto ja liberado |
| Regressao no portavel `Invoke<TSignature>` | Baixa | Alto | 7 cenarios existentes intocados; compilacao + suite provam |
| Warning "Rtti is experimental" contaminar CI | Baixa | Baixo | Ja aparece em `RTTI.FPC.pas:45`; adicionar em uma unit a mais nao muda o quadro. XMLDoc documenta |
| Construtor invocado por engano | Baixa | Medio | XMLDoc cita explicito: `rtti.pp:2334` levanta `ENotImplemented`; consumidor recebe erro claro da RTL do FPC — nao mascaramos |
