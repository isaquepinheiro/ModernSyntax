---
type: adr
kind: artifact
title: "ADR — Design de ModernSyntax.Callback (fundação de callbacks portáveis)"
description: "Decisões arquiteturais para os três contratos de interface, o factory Callback.Of, a convenção de testes com unit comum + duas cascas finas, e a fixação do nome dos contratos como IModern* (decisão de gate)."
status: draft
cycle: "004"
agent: architect
workflow: equipe-feature
node: "plan-gate:on_reject"
resource: aefos://run/24c962dcc2be1819336ca1fea18ae949
tags: [adr, modernrtti, callbacks, fpc, delphi, transversal, issue-7]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-08-28T13:30:00Z"
sources:
  - id: prd
    resource: "../strategy/2026-08-27-modernrtti/PRD.md"
    title: "ModernRTTI PRD"
  - id: study
    resource: "../strategy/2026-08-27-modernrtti/STUDY.md"
    title: "ModernRTTI Study"
  - id: arch
    resource: "../analysis/03-architecture.md"
    title: "03 Architecture — ModernSyntax"
  - id: investigation
    title: "Investigation report — issue #7 (run d8638f50)"
---

# ADR — Design da unit ModernSyntax.Callback

> Investigation report: **PRESENT** (run `d8638f50`, comentário na issue
> #7). Este ADR **deriva** desse relatório e restaura as decisões nos
> mesmos termos em que a discussão as fechou. Onde este ADR **estende**
> o relatório, é para responder à decisão pendente que ele explicitamente
> devolveu para o portão de design (o nome dos três contratos, D-A9
> abaixo). Não há divergência silenciosa: se este ADR discorda de algo
> do relatório, está dito com todas as letras.

## Contexto

O PRD ([ModernRTTI](/strategy/2026-08-27-modernrtti/PRD.md)) pede uma
camada transversal de callbacks que sirva de fundação para os três
pilares (RTTI, atributos, invoker). Medido no
[Study](/strategy/2026-08-27-modernrtti/STUDY.md) e reafirmado no
relatório de investigação: o FPC 3.2.2 **não tem** `reference to` nem os
modeswitches de anônimos. Não há duas formas do mesmo recurso a
abstrair; há um recurso **inexistente** a construir onde ele falta.

## Decisões

### D-A1 — Unit nova, autocontida, com apenas `uses SysUtils`

Cria-se `Source/ModernSyntax.Callback.pas`. A `uses` da interface tem
**exatamente** `SysUtils`.

**Motivo (do relatório, medido).** Qualquer outra unit da própria
biblioteca (`Option`, `ResultPair`, `Objects`, `Windows`, `Rtti`) traz
transitivamente `reference to` ou o `.inc`, e a unit **é** a fundação —
não pode depender das que ela vai servir.

**Descartado — herdar da árvore de utilitários já existente:** cria
ciclo de dependência com a própria camada que este contrato precisa
ancorar.

### D-A2 — Três interfaces de contrato, sem GUID

```pascal
type
  IModernFunc<T, R> = interface
    function Invoke(const AValue: T): R;
  end;

  IModernProc<T> = interface
    procedure Invoke(const AValue: T);
  end;

  IModernPredicate<T> = interface
    function Invoke(const AValue: T): Boolean;
  end;
```

**Sem `['{GUID}']`.** São contrato de **chamada**, não de descoberta —
não há `Supports`/`QueryInterface` no caminho. Interface genérica com
GUID tem comportamento sutil em compiladores antigos e o FPC 3.2.2 é
mais restritivo (D-5 do relatório).

**O precedente do `IMSObserver` não vale** para justificar GUID: é
código morto (medido: 1 ocorrência no repositório inteiro, ninguém
implementa).

### D-A3 — Factory `Callback.Of` com sobrecarga para método de objeto

```pascal
type
  Callback = record
  public
    class function Of<T, R>(const AMethod: function(const AValue: T): R of object): IModernFunc<T, R>; overload; static;
    class function Of<T>(const AMethod: procedure(const AValue: T) of object): IModernProc<T>; overload; static;
    class function Of<T>(const AMethod: function(const AValue: T): Boolean of object): IModernPredicate<T>; overload; static;
  end;
```

**Escopo desta entrega, do relatório (D-4):** só as três sobrecargas
**de método de objeto**.

**Descartado — sobrecarga aceitando procedure global:** fora do escopo
(D-4).

### D-A4 — Captura de variável via classe helper declarada pelo consumidor

O padrão de uso portável para o CA-4 do PRD é o consumidor declarar uma
classe que carrega o estado em campo e implementa a interface:

```pascal
type
  TSomandoAcumulado = class(TInterfacedObject, IModernFunc<Integer, Integer>)
  private
    FAcc: Integer;
  public
    function Invoke(const AValue: Integer): Integer;
  end;

var LCaptura: IModernFunc<Integer, Integer>;
begin
  LCaptura := TSomandoAcumulado.Create;
  Consumidor.Aplicar(LCaptura);
end;
```

**Motivo (D-3 do relatório).** O CA-5 do PRD proíbe **ramificação** no
consumidor, não **verbosidade**. A classe helper é a mesma nos dois
compiladores: o consumidor **não escreve `{$IFDEF}`**. Satisfaz CA-4 e
CA-5 simultaneamente.

**Descartado — devolver uma anônima via `TFunc<...>` capturando:**
funciona no Delphi, não compila no FPC 3.2.2, contradiz D3 do PRD.

**Descartado — objeto de captura pronto na biblioteca por reflexão:**
exigiria pré-processamento ou geração de código; recusado por D3 do PRD.

### D-A5 — Ramificação `{$IFDEF FPC}` direta, sem `.inc`

A unit escreve `{$IFDEF FPC} ... {$ELSE} ... {$ENDIF}` diretamente e
**não inclui** `ModernSyntax.inc`.

**Motivo (R3 do PRD, medido).** `ModernSyntax.inc:256` escreve
`{$IFDEF FCP}` (letras trocadas). O bloco Lazarus nunca disparou.
Qualquer unit que inclua o `.inc` herda o bug.

**Descartado — corrigir o `.inc` neste mesmo ciclo:** mistura duas
linhas de trabalho independentes.

### D-A6 — Neste ciclo, **sem** sobrecarga `TFunc<T,R>`

**Descartado explicitamente pelo relatório (D-4):** aceitar `TFunc<T,R>`
sob `{$IFNDEF FPC}` não violaria o CA-5 na letra, mas cria armadilha
pior — o consumidor Delphi escreve código que **parece** portável, e só
descobre no `lazbuild`. Se vier, vem em issue própria com aviso em voz
alta.

### D-A7 — Testes: unit comum em `Test Shared/` + duas cascas finas

Segue exatamente o desenho fixado no relatório (D-1 e D-2), medido no
próprio repositório:

- `find . -iname "DUnitX*.pas"` → **zero**. DUnitX **não está
  vendorizado**; vem instalado com a IDE Delphi.
- `units/x86_64-win64/fcl-fpcunit/fpcunit.ppu` — **FPCUnit é nativo**
  no FPC 3.2.2. Também presentes `consoletestrunner.ppu` e
  `digesttestreport.ppu`.

**A lógica dos cenários mora em `Test Shared/EclbrSystem/`** — uma
terceira pasta neutra, sem framework, com funções que executam o caso
e levantam exceção na falha. **Escrita uma única vez.**

**Cada fixture é uma casca fina** que chama o cenário e deixa a exceção
virar `Fail`:

```pascal
// Test Delphi/EclbrSystem/UTestMS.Callback.pas (DUnitX)
procedure TCallbackTests.CallbackOf_MethodOfObject_Returns;
begin
  UTestMS.Callback.Scenarios.CallbackOf_MethodOfObject_Returns;
end;
```

**Descartado — DUnitX no FPC via vendor:** custo desproporcional para
uma fundação de três interfaces.

**Descartado — duplicar a lógica dos testes:** duas cópias divergem em
silêncio.

**Descartado — colocar a unit comum em `Test Delphi/` e apontar o
`.lpi` para lá:** cria a assimetria de diretório que esta issue existe
para evitar (D-1).

**Descartado — casca fina com `if/then` de asserção próprio:** o
relatório fecha textualmente: *"se uma casca começar a ter if/then de
asserção, é vazamento e volta para discussão"*.

### D-A8 — Diretório espelhado por compilador: `Test FPC/EclbrSystem/`

Novo diretório de teste, espelhando `Test Delphi/EclbrSystem/`. Quem
abre a raiz do repositório entende o desenho sem ler documento.

**Descartado — misturar `.lpi` dentro de `Test Delphi/`:** força o
próximo ciclo a adivinhar de qual compilador é cada arquivo.

### D-A9 — Nome dos três contratos: `IModernFunc`/`IModernProc`/`IModernPredicate`

**Esta é a decisão pendente que o relatório devolveu para o portão de
design.** O relatório mediu, e a medição não é ambígua:

- Interfaces públicas em `Source/`: `IAutoLock`, `IScheduler`,
  `ICleanup`, `INumeric<T>`, `IModernObject`, `ISmartPtr<T>`,
  `IAutoRefLock`, `ITupleDict<K>`, `IMSObserver` — **nove** ao todo.
- Apenas **uma** com prefixo `IMS`, e é `IMSObserver` — **código morto**.
- O padrão dominante é `I<Nome>`; quando a intenção foi marcar família,
  escreveu-se **por extenso**: `IModernObject`.

**Decisão: `IModernFunc<T,R>`, `IModernProc<T>`, `IModernPredicate<T>`.**

**Trade-off honesto (do relatório).** São 5 caracteres a mais em cada
tipo, e estes tipos aparecem em **assinatura de método**, onde
comprimento incomoda. Aceito porque:

1. Alinha com o único precedente **vivo** de família de interface no
   repositório (`IModernObject`).
2. Trocar depois de espalhar pela API é caro; agora é uma linha.
3. Copiar `IMS*` de código morto seria formalizar dívida.

**Divergência do texto da issue e do PRD assumida com todas as letras:**
o corpo da issue #7 e o PRD dizem `IMSFunc<T,R>`. Este ADR **renomeia**
para `IModernFunc<T,R>` (e simétricos).

### D-A10 — Correção de medição do PRD/issue: 415 usos, não 451

O corpo da issue e o PRD mencionam **451** usos de `TProc`/`TFunc`. O
relatório de investigação mediu de novo: `grep -rn "TProc\b\|TFunc\b"
Source/*.pas | wc -l` → **415**. Por arquivo: Match 215, Currying 48,
ResultPair 32, ArrowFun 30, Async 23, Coroutine 19, Safetry 16, Stream
14, Option 10, Objects 8.

Este ADR **não** depende do número (D4 do PRD tira essa conversão de
escopo). Mas registra o número certo aqui para que a próxima decisão que
o citar não repita o 451.

### D-A11 — Sem `{$I ModernSyntax.inc}` na unit; ramificação direta

Reafirmação prática do D-A5, específica para o auditor de PR:
`grep -n 'ModernSyntax.inc' Source/ModernSyntax.Callback.pas` deve
retornar zero linhas. `grep -n 'FCP' Source/ModernSyntax.Callback.pas`
deve retornar zero linhas.

### D-A12 — Cabeçalho usa `(* ... *)`; `{ }` não aninha diretivas em Pascal

**Restrição de implementação obrigatória.**

O cabeçalho MIT/SPDX de todas as units usa `(* ... *)`. É proibido
escrever diretivas `{$...}` dentro de um comentário `{ }`: o `}` da
diretiva fecha o comentário externo, e o resto do cabeçalho vira código.

**Erro medido no FPC 3.2.2 e no Delphi (regra de linguagem — os dois compiladores):**

```
ModernSyntax.Callback.pas(20,73) Fatal: Syntax error, "UNIT" expected but "." found
UTestMS.Callback.Scenarios.pas(23,43) Fatal: Syntax error, "UNIT" expected but "(" found
```

**Regra:** cabeçalho sempre em `(* ... *)`. Se precisar citar uma
diretiva em prosa dentro de um comentário `{ }`, escrever `IFDEF FPC`
sem chaves.

**Por que isso não aparece em leitura de código:** o padrão visual dos
dois blocos é idêntico; o erro só emerge na compilação.

### D-A13 — Classes wrapper declaradas na `interface` (restrição do symtable do FPC)

**Restrição de implementação obrigatória.**

O body de `Callback.Of<T,R>` (factory declarado na `interface`) instancia
`TFuncOfObjectWrapper<T,R>`, `TProcOfObjectWrapper<T>` e
`TPredicateOfObjectWrapper<T>`. O FPC 3.2.2 expande o template genérico
no **ponto de uso** do factory — nesse ponto, os símbolos da seção
`implementation` não são visíveis.

**Erro medido no FPC 3.2.2 (três linhas, um por wrapper):**

```
ModernSyntax.Callback.pas(156,4) Error: Global Generic template references static symtable
ModernSyntax.Callback.pas(161,4) Error: Global Generic template references static symtable
ModernSyntax.Callback.pas(166,4) Error: Global Generic template references static symtable
```

**Conserto medido:** as três classes wrapper ficam na seção `interface`,
após a declaração do factory. Os três erros desaparecem.

**Custo declarado:** os wrappers ficam visíveis a qualquer unit que
importar `ModernSyntax.Callback`. Aceito porque o consumidor não
instancia os wrappers diretamente; o único ponto de entrada é
`Callback.Of`, que devolve a interface. A RN-1 do [esp](pipeline-esp.md) foi
corrigida para refletir isso.

**Regra geral para toda a família ModernRTTI:** todo tipo que o corpo de
um método genérico declarado na `interface` instancia TEM de estar
declarado na `interface`. Se isso obriga a expor um tipo que se preferia
privado, expõe-se e registra-se o custo aqui — é o preço de suportar
o FPC 3.2.2.

**Por que isso não aparece em leitura de código:** o Delphi aceita
referências a tipos da `implementation` em generics da `interface`; o
erro é exclusivo do FPC 3.2.2 e só emerge na compilação.

## Perguntas em aberto (do relatório)

Não são decisões deste ADR — são medições a fazer em implementação:

- **Q2 do relatório.** O `.dproj` do lado Delphi precisa de ajuste de
  search path para achar `Test Shared/EclbrSystem/`. Cai na fatia 3 do
  [plan](pipeline-plan.md).
- **Q3 do relatório.** O FPCUnit precisa de configuração para saída
  legível por CI. Não bloqueia esta entrega.

## Consequências

- Consumidor escreve `Callback.Of(Self.MinhaProc)` para o caso simples e
  a **mesma classe helper** para o caso com captura, nos dois
  compiladores. Cumpre CA-1/CA-2/CA-3 do [esp](pipeline-esp.md) e CA-4/CA-5 do
  PRD.
- A convenção de teste fixada aqui (D-A7/D-A8) **vale para toda a
  família ModernRTTI**. Impacto imediato na issue #8, cujo plano manda
  o projeto Lazarus rodar os mesmos testes DUnitX — o que **não
  compila** no lado FPC pelo medido.
- A renomeação para `IModern*` (D-A9) altera o texto da issue e do
  PRD. Divergência **declarada**, não silenciosa.
- Nenhum dos 415 usos existentes de `TProc`/`TFunc` é tocado (D4 do
  PRD).
