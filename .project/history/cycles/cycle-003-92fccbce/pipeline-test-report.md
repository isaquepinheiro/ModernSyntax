---
type: test-report
kind: artifact
title: "Test report — Callbacks transversais (ciclo 003)"
description: "Verificação por leitura e grep dos critérios de aceitação do ESP para ModernSyntax.Callback; todos os gates automatizáveis verdes; compilação diferida ao autor per R2."
cycle: "003"
agent: quality
workflow: equipe-feature
node: test
resource: aefos://run/92fccbce1ddb8c2d37df799793017636
status: stable
tags: [test-report, quality, modernrtti, callbacks, cycle-003, issue-7]
generated:
  by: "equipe-feature@node:test"
  at: "2026-08-28T11:20:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — Callbacks transversais"
  - id: implement-report
    resource: "implement-report.md"
    title: "Implement report — ciclo 003"
  - id: verify-report
    resource: "verify-report.md"
    title: "Verify report — ciclo 003"
---

# Test report — Callbacks transversais (ciclo 003)

**Verdict: APPROVED**

Issue: [isaquepinheiro/ModernSyntax#7](https://github.com/isaquepinheiro/ModernSyntax/issues/7).  
Insumos: [esp](pipeline-esp.md), [implement-report](pipeline-implement-report.md), [verify-report](pipeline-verify-report.md).

## Contexto de execução

A fábrica não tem compilador Pascal (R2 do PRD, confirmado no
[implement-report](pipeline-implement-report.md)). Validação é por **leitura de código +
grep**; compilação real (CA-6) fica com o orquestrador na máquina do autor.

## Testes executados

### Grupo 1 — Grep gates (automatizados)

| Gate | Critério | Comando | Resultado |
|------|----------|---------|-----------|
| CA-8a | Sem `{$I ModernSyntax.inc}` | `grep -n '{\$I ModernSyntax.inc}' Source/ModernSyntax.Callback.pas` | **exit 1** — zero linhas ✅ |
| CA-8b | Sem token `FCP` | `grep -n 'FCP' Source/ModernSyntax.Callback.pas` | **exit 1** — zero linhas ✅ |
| CA-4 | Sem `{$IFDEF FPC}` em Test Shared/, Test Delphi/, Test FPC/ | `grep -rn '{\$IFDEF FPC}' "Test Shared/" "Test Delphi/..." "Test FPC/"` | **exit 1** — zero linhas ✅ |
| RN-5 | `uses SysUtils` somente na unit nova | `grep -n '^uses' Source/ModernSyntax.Callback.pas` (seguido de leitura) | Único bloco `uses` tem apenas `SysUtils;` ✅ |
| D-A7 | Shared sem referência a framework de teste | `grep -rn 'DUnitX\|TestFramework\|fpcunit\|testregistry' Test Shared/...` | **exit 1** — zero linhas ✅ |

**Nota sobre CA-4:** O texto da `UTestMS.Callback.Scenarios.pas` menciona `{$IFDEF}` em dois blocos de comentário (doc-text, linhas 23 e 29), o que produz matches para a busca ampla `{\$IFDEF` mas **não** para `{\$IFDEF FPC}`. Nenhuma diretiva condicional efetiva existe na shared unit. Gate CA-4 verde por design (DEV-6 do implement-report).

### Grupo 2 — Leitura de código e rastreio lógico

#### CA-1 — Três interfaces sem GUID

Lidas em `Source/ModernSyntax.Callback.pas` (linhas 48–60):

```pascal
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

Nenhuma das três tem GUID. ✅

#### CA-2 — `Callback.&Of` como atalho para método de objeto

Factory `Callback = record` com três sobrecargas `&Of` (linhas 76–79 da unit):

```pascal
class function &Of<T, R>(const AMethod: TModernFuncMethod<T, R>): IModernFunc<T, R>; overload; static;
class function &Of<T>(const AMethod: TModernProcMethod<T>): IModernProc<T>; overload; static;
class function &Of<T>(const AMethod: TModernPredicateMethod<T>): IModernPredicate<T>; overload; static;
```

Coberto por três cenários em `UTestMS.Callback.Scenarios.pas`. ✅

#### CA-3 — Captura de variável via classe helper

`TAccumulator` implementa `IModernFunc<Integer, Integer>` diretamente, com campo `FAcc`
para estado. Cenário `Interface_CapturesState_ViaHelperClass` verifica:

| Invocação | FAcc esperado | Retorno esperado | Asserção |
|-----------|---------------|------------------|---------|
| `Invoke(2)` | 2 | 2 | `AssertEqualInt(2, LFirst, ...)` ✅ |
| `Invoke(3)` | 5 | 5 | `AssertEqualInt(5, LSecond, ...)` ✅ |
| `Invoke(5)` | 10 | 10 | `AssertEqualInt(10, LThird, ...)` ✅ |

Aritmética verificada por rastreio manual. ✅

#### CA-5 — Projeto FPC existe

`Test FPC/EclbrSystem/PTestModernCallback.lpi` presente. Lido e verificado:
- Dois build modes: `Debug-x86_64` (default) e `Debug-i386`.
- `<SyntaxMode Value="Delphi"/>` em ambos os modos — garante que a shared unit
  compile em modo Delphi sem precisar de diretiva interna.
- `<OtherUnitFiles>` inclui `..\..\Source` e `..\..\Test Shared\EclbrSystem` em
  ambos os modos.
- `<RequiredPackages>` = `FCL` (provê `fpcunit` e `consoletestrunner`). ✅

#### RN-1 — Nenhum wrapper vaza na interface

Wrappers (`TFuncOfObjectWrapper<T,R>`, `TProcOfObjectWrapper<T>`,
`TPredicateOfObjectWrapper<T>`) declarados **exclusivamente** na seção
`implementation`. A seção `interface` expõe apenas os três contratos, o factory
`Callback`, e os aliases de método-de-objeto (`TModernFuncMethod<T,R>` etc.).

Os aliases são infraestrutura de tipagem exigida pelo FPC 3.2.2 para evitar erros
de parser com tipos genéricos inline — justificativa documentada em DEV-2 do
[implement-report](pipeline-implement-report.md). Não são wrappers de implementação; o
consumidor nunca precisa nomeá-los. ✅

#### RN-4 — Sem `{$I ModernSyntax.inc}`

Verificado por CA-8a. ✅

### Grupo 3 — Cobertura de casos de teste (cenários da shared unit)

| Cenário | O que exercita | Corretude |
|---------|---------------|-----------|
| `CallbackOf_MethodOfObject_Func_Returns` | `IModernFunc` via `Callback.&Of<Integer,Integer>`, chama `Invoke(21)`, espera `42` (`2×21`). | ✅ lógica correta |
| `CallbackOf_MethodOfObject_Proc_Executes` | `IModernProc` via `Callback.&Of<Integer>`, chama `Invoke(7)`, verifica `LastSeen=7` e `SeenCount=1`. | ✅ lógica correta |
| `CallbackOf_MethodOfObject_Predicate_ReturnsBoolean` | `IModernPredicate` via `Callback.&Of<Integer>`, verifica `Invoke(3)=True` e `Invoke(-1)=False`. | ✅ lógica correta |
| `Interface_CapturesState_ViaHelperClass` | Captura via `TAccumulator`; verifica acumulação em três chamadas. | ✅ aritmética verificada |

Casos negativos não têm cobertura de cenário dedicado (e.g., `Invoke(0)` para
`IsPositive`, boundary conditions). Os quatro cenários cobrem os dois eixos de
CA-2 e CA-3, que era o escopo desta entrega.

## Checklist de aceite (ESP §4)

| CA | Critério | Status |
|----|----------|--------|
| CA-1 | Três interfaces genéricas sem GUID compilam sem modificação | ✅ verificado por leitura |
| CA-2 | `Callback.&Of(Self.MinhaProc)` como atalho, coberto por cenário | ✅ |
| CA-3 | Captura via classe helper, coberto por cenário `Interface_CapturesState_ViaHelperClass` | ✅ |
| CA-4 | Grep `{$IFDEF FPC}` em Test Shared/Test Delphi/Test FPC → 0 linhas | ✅ exit 1 |
| CA-5 | `Test FPC/EclbrSystem/PTestModernCallback.lpi` presente e correto | ✅ |
| CA-6 | Compilação em FPC 3.2.2 x86_64 e i386 | ⏳ diferido ao autor (R2 do PRD) |
| CA-7 | Body do PR com declaração literal | ⏳ diferido ao nó release (pendente no implement-report) |
| CA-8 | Sem `{$I ModernSyntax.inc}` e sem token `FCP` na unit | ✅ exit 1 |

## Edge cases verificados

1. **Desambiguação de sobrecargas `&Of<T>`.** Duas sobrecargas de parâmetro único
   diferem no tipo retornado pelo método passado (`procedure of object` vs
   `function: Boolean of object`). A desambiguação depende do compilador inferir
   o tipo a partir do argumento — padrão em ambos os compiladores. ✅ coberto
   pelos cenários Proc e Predicate.

2. **Gerenciamento de memória nos cenários.** Em
   `CallbackOf_MethodOfObject_Proc_Executes`, `LHost` é liberado no bloco
   `finally` enquanto `LProc` (interface) ainda está no escopo. A destruição da
   interface (`TInterfacedObject`) ao sair do procedimento apenas libera o wrapper
   — nenhum callback para o objeto já liberado. Seguro. ✅

3. **`TAccumulator` sem `Callback.&Of`.** O cenário CA-3 passa `TAccumulator`
   diretamente como `IModernFunc<Integer,Integer>` (sem o factory), provando que
   a interface funciona independentemente do factory. O factory é um atalho, não
   um requirement para usar a interface. ✅

4. **Shared sem modo explícito.** O arquivo `UTestMS.Callback.Scenarios.pas` não
   tem `{$MODE DELPHI}` nem nenhuma diretiva de compilação. O modo vem do projeto
   (`.lpi` no lado FPC, modo default Delphi no lado Delphi). DEV-6 do
   implement-report documenta e justifica. ✅

## Observações e caveats

- **`&Of` em vez de `Of`:** consumidor precisa lembrar do `&`. Documentado como
  Caveat 1 no implement-report; único caminho válido sem renomear e sem
  infringe a gramática Object Pascal.
- **`.res` ausente no lado Delphi:** comportamento esperado, mesmo padrão do
  ciclo 002.
- **Compilação não executada:** pela natureza da fábrica (R2 do PRD), CA-6 e
  CA-7 são responsabilidade do autor e do nó release respectivamente.
