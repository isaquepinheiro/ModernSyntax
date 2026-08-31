---
type: implement-report
kind: artifact
title: "Implement report — TModernRTTIMethod pela vmtMethodTable (issue #25)"
description: "Split de backends RTTI aplicado, TModernRTTIMethod/Parameter em ambos os compiladores, cirurgia do Fail fechando #35, três cenários novos verdes no FPC x86_64 (9/9, exit=0) com M1 provada por mutação (exit=2)."
status: stable
cycle: "010"
agent: developer
workflow: equipe-feature
node: implement
resource: aefos://run/a36e13649de2fc026303074567d63275
tags: [modernrtti, implement, issue-25, fpc, delphi, vmtmethodtable]
generated:
  by: "equipe-feature@node:implement"
  at: "2026-08-31T00:00:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — issue #25"
  - id: adr
    resource: "adr.md"
    title: "ADR — issue #25"
  - id: plan
    resource: "plan.md"
    title: "Plan — issue #25"
  - id: task-input
    resource: "task-input.md"
    title: "Task input — issue #25"
---

# Implement report — TModernRTTIMethod pela vmtMethodTable (issue #25)

## O que mudou

Seis arquivos, uma entrega. As quatro slices do [plan](pipeline-plan.md) foram
aplicadas em sequência — o build só volta a passar quando todas fecham.

### Arquivos modificados

| Arquivo | Slice | Delta |
|---|---|---|
| `Source/ModernSyntax.RTTI.pas` | 1+2 | Refactor grande: (a) `TModernRTTIField` migrado para campos neutros `FOwner/FName/FToken: Pointer` + `FromToken` estática (§7 do API-MAP / D-25.1); (b) `TModernRTTIParameter` e `TModernRTTIMethod` novos com estado neutro e oito membros públicos de Method (`Name`, `Invoke<TSignature>` overload TObject/TClass, `GetParameters`, `ReturnType`, `IsConstructor`, `IsClassMethod`, `IsStatic`, `Visibility`); (c) `GetMethods`/`GetMethod` migrados para record helper `TModernRTTITypeHelper` — records Pascal não admitem forward-declaração entre si (ver Decisões técnicas); (d) `TModernRTTIField.GetValue<T>`/`SetValue<T>` delegam via `FieldReadRaw`/`FieldWriteRaw` (fallback para `FieldReadValue`+`ExtractRawData` quando os tamanhos não batem no path rápido); (e) implementation.uses tem o **único `{$IFDEF}` da unit pública**: `{$IFDEF FPC} ModernSyntax.RTTI.FPC {$ELSE} ModernSyntax.RTTI.Delphi {$ENDIF}` + `ModernSyntax.Invoker`; (f) XMLDoc de `GetMethods` declara a divergência de cobertura Delphi (public+published) vs FPC (published) — D-25.5; (g) XMLDoc dos seis membros sem fonte no FPC declara o `raise EModernRTTIError`. |
| `Source/ModernSyntax.RTTI.FPC.pas` | 1+2 | **NOVO** — backend FPC. `FieldEnumerate` migrado do arquivo público (vmtFieldTable + `LTab^.Field[LI]` + `ClassParent`). `MethodEnumerate` novo: itera `LTab^.Entry[i]` pela property indexada (D-25.2 — **zero aritmética literal**), sobe a cadeia por `ClassParent` (D-25.3, necessário para enumeração). `MethodLookup` novo: uma linha, delega a `TObject.MethodAddress`, que sobe a cadeia sozinho (D-25.3, **sem laço próprio**). `FieldReadRaw`/`FieldWriteRaw` fazem `Move` por offset absoluto. Os seis membros sem fonte (`MethodIsConstructor`, `MethodIsClassMethod`, `MethodIsStatic`, `MethodVisibility`, `MethodReturnType`, `MethodGetParameters`) + `ParameterName`/`ParameterParamType` levantam `EModernRTTIError` com mensagem instrutiva citando `vmtMethodTable` (typinfo.pp:388-396) e `TIntfMethodEntry` (D-25.4). |
| `Source/ModernSyntax.RTTI.Delphi.pas` | 1+2 | **NOVO** — backend Delphi. Envolve `TRttiField`/`TRttiMethod`/`TRttiParameter` direto. `TRttiContext` local em `MethodEnumerate`/`MethodLookup` — seguro porque `TModernRTTI.FContext` mantém o pool global vivo pelo tempo de vida do binário (nota de ownership no header). `FieldWriteRaw` usa `TValue.Make(ASrc, LField.FieldType.Handle, LValue)` + `SetValue`. `ParameterName` devolve o `AName` já populado por `FromToken` — evita reter `TRttiParameter` como token e depender de tempo de vida do contexto local. |
| `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | 3+4 | (a) `ETestScenarioFailed = class(Exception);` declarada no `type` da `interface` (D-25.7 — fecha #35); (b) `Fail` levanta `ETestScenarioFailed` (linha 95 do arquivo original); (c) fixture nova `{$M+} TMethodBase published procedure Alpha; TMethodDerived = class(TMethodBase) published procedure Gama; {$M-}` — **apenas published** (D-25.5); (d) `GMethodInvokeCounter` variável de unit para efeito colateral observável; (e) três cenários novos: `Scenario_GetMethods_CountsPublishedInherited_Exact` (Length=2 EXATO — pega M1), `Scenario_GetMethod_ByName_FindsInherited` (usa `MethodAddress` que sobe cadeia sozinho), `Scenario_Method_Invoke_NoArgs` (`TAlphaProc = procedure of object`, invoca via `TModernInvoker` e checa contador). Zero `Assert`. Zero `{$IFDEF FPC}` (CA-5 preservada). |
| `Test FPC/EclbrSystem/UTestMS.RTTI.pas` | 4 | Três published tests novos delegando aos cenários compartilhados (uma linha útil cada). |
| `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` | 4 | Três `[Test]` novos + XMLDoc do `TestGetFields_ReturnsFields` reescrito (linha 59 stale — o comentário dizia "TModernRTTIField e GetFields não existem no FPC 3.2.2", falso desde a #21; agora explica que a fixture usa `public` que só o Delphi vê). Cabeçalho da unit atualizado para citar Pilar 4 + issues #21 e #25. |

Adicionalmente, marcador do ciclo em `.project/project-evolution.md`
avançado de 🔄 in-pipeline para 🔄 in-review (exigência do próprio nó
`implement`).

### Arquivos NÃO tocados (por design)

- `Source/ModernSyntax.Invoker.pas` — restrição §5 do [esp](pipeline-esp.md). O
  `Invoke<TSignature>` de `TModernRTTIMethod` delega **a ele**, não
  duplica mecanismo (D-25.9).
- `Test FPC/EclbrSystem/PTestRTTI.lpr` — `-Fu"Source"` acha os backends
  novos automaticamente (§"Arquivos NÃO mudam" do task-input).
- `Test FPC/EclbrSystem/PTestRTTI.lpi` — mesmo motivo.
- Qualquer outra unit em `Source/` — restrição §5 do [esp](pipeline-esp.md).

## Decisões técnicas aplicadas (rastreabilidade 1-para-1 com o ADR)

- **D-25.1** — `Source/ModernSyntax.RTTI.pas` é casca pública com **zero
  `{$IFDEF}` em declaração de tipo**. O único ifdef vive na `uses` da
  `implementation` selecionando o backend. Backends expõem **mesma
  superfície de funções livres** — a compilação é o portão. Estado
  privado de Field/Method/Parameter é neutro (`FOwner: TClass`, `FName:
  string`, `FToken`/`FTypeToken: Pointer`).
- **D-25.2** — `MethodEnumerate` no backend FPC itera com
  `LTab^.Entry[i]` (property indexada da RTL). Nenhum `PByte(LTab) + N`
  nem `i * SizeOf(TVmtMethodEntry)` no código. Prova M2 (i386) fica com
  o autor — fábrica não tem `ppc386`.
- **D-25.3** — `MethodTokens` (`MethodEnumerate` na implementação) tem
  laço por `ClassParent` (enumeração precisa). `MethodToken`
  (`MethodLookup`) é uma linha usando `AClass.MethodAddress(AName)`
  **sem replicar laço** — `MethodAddress` sobe a cadeia sozinho (medido
  no cenário `_ByName_FindsInherited`, que passa em `TMethodDerived`
  buscando `Alpha` de `TMethodBase`).
- **D-25.4** — Os seis membros sem fonte no FPC + `ParameterName` +
  `ParameterParamType` levantam `EModernRTTIError` com mensagem
  instrutiva. Precedente `GetProperties` (`ModernSyntax.RTTI.pas`).
  Cada mensagem cita `vmtMethodTable` (typinfo.pp:388-396) e
  `TIntfMethodEntry` como fonte alternativa que não alimenta RTTI de
  classe.
- **D-25.5** — XMLDoc de `TModernRTTITypeHelper.GetMethods` declara em
  voz de contrato: "no Delphi enumera `public`+`published`; no FPC só
  `published`; `Length(GetMethods)` pode divergir". Fixture usa apenas
  `published` para a contagem exata bater nos dois. XMLDoc dos seis
  membros sem fonte declara o `raise`.
- **D-25.6** — `TModernRTTIParameter` com `Name` + `ParamType` reais.
  Delphi backend `MethodGetParameters` popula `FName` com
  `TRttiParameter.Name` e `FTypeToken` com
  `Pointer(TRttiParameter.ParamType)`. Backend `ParameterName` devolve
  `AName` cru (evita retenção do `TRttiParameter` — o token local pode
  ser liberado com o `TRttiContext` temporário). FPC backend levanta
  em ambos os acessos.
- **D-25.7** — `ETestScenarioFailed = class(Exception);` declarada no
  `type` da `interface` do `UScenarios.RTTI.pas`; `Fail` levanta essa
  classe. **Fecha ModernSyntax#35** — validado por mutação (§Validações
  abaixo). PR body deve declarar `Closes #35`.
- **D-25.8** — Cenários **não usam `Assert`**. Todos usam `Fail(...)`.
- **D-25.9** — `TModernRTTIMethod.Invoke<TSignature>` (overloads TObject
  e TClass) delega a `TModernInvoker.Invoke<TSignature>(A, FName)`.
  Nenhum mecanismo paralelo; `ModernSyntax.Invoker.pas` não muda.
- **D-25.10** — Prova M1 verificada aqui (§Validações). M2 (i386) fica
  com o autor (declaração no corpo do PR).

### Nota estrutural — record helper para `TModernRTTIType`

`TModernRTTIType.GetMethods`/`GetMethod` foram movidos para o record
helper `TModernRTTITypeHelper`. Motivo forçado pelo compilador FPC
3.2.2: records Pascal **não admitem forward-declaração entre si**.
- `TModernRTTIMethod.ReturnType` devolve `TModernRTTIType` → Type
  precisa vir antes de Method.
- `TModernRTTIType.GetMethods` devolve `TArray<TModernRTTIMethod>` →
  Method precisa vir antes de Type.

O record helper (declarado logo depois de `TModernRTTIMethod`) resolve o
impasse sem trocar record por classe (que mudaria semântica de valor
para referência e quebraria ownership do bundle). `FType` foi rebaixado
de `strict private` para `private` (mesma unit) para o helper poder
acessá-lo. Consumidor externo continua sem enxergar — semântica idêntica.

Isso apareceu como um erro de compilação na primeira tentativa
("Identifier not found 'TModernRTTIMethod'") — o helper foi a resposta
estrutural, não workaround.

## Validações executadas

### Toolchain descoberto

Nenhum comando novo — a seção "Toolchain & quality commands
(agent-discovered 2026-08-28)" em [SKILL](/SKILL.md) já cobre tudo o
que este ciclo precisou. **Não** houve enriquecimento novo do SKILL.

### FPC 3.2.2 x86_64 — compilação verde

```
rm -rf /tmp/rtti25_x64 && mkdir -p /tmp/rtti25_x64
fpc -Mdelphi \
    -Fu"Source" -Fu"Test Shared/EclbrSystem" -Fu"Test FPC/EclbrSystem" \
    -FU/tmp/rtti25_x64 -FE/tmp/rtti25_x64 \
    "Test FPC/EclbrSystem/PTestRTTI.lpr"
```

→ `1589 lines compiled, 0.2 sec, 4 warning(s) issued`. Todos os
warnings são conhecidos:
1. `Rtti is experimental` em `ModernSyntax.RTTI.pas` — herança da
   `uses Rtti` do public unit.
2. `Rtti is experimental` em `ModernSyntax.RTTI.FPC.pas` — mesma razão.
3. `function result variable ... managed type does not seem to be
   initialized` em `ModernSyntax.RTTI.pas` — no
   `TModernRTTITypeHelper.GetMethod`, path que **sempre levanta** antes
   do `Result` sair (raise cobre os dois caminhos).
4. `unreachable code` em `ModernSyntax.Invoker.pas:80` — pré-existente,
   não tocado neste ciclo.

### FPC x86_64 — execução dos testes: 9/9 verdes, exit=0

```
/tmp/rtti25_x64/PTestRTTI --all -a --format=plain
```
```
  TTestModernRTTI Time:00.000 N:9 E:0 F:0 I:0
    TestGetProperties_ReturnsPublishedProps
    TestGetValue_Integer_Roundtrip
    TestGetValue_String_Roundtrip
    TestGetValue_Currency_Roundtrip
    TestMissingM_RaisesEModernRTTIError
    TestGetFields_EnumeratesInheritedPublishedClassFields
    TestGetMethods_CountsPublishedInherited_Exact       ← novo (CA-3)
    TestGetMethod_ByName_FindsInherited                 ← novo (CA-3)
    TestMethod_Invoke_NoArgs                            ← novo (CA-3)
Number of run tests: 9 / Number of errors: 0 / Number of failures: 0
```

Exit code aferido diretamente (`echo $?` após o processo): **0**. Os 6
testes anteriores continuam verdes — o refactor de Slice 1 é
retrocompatível.

### Prova de mutação M1 — verificada localmente

Sobrescrevi `LCur := LCur.ClassParent` por `LCur := nil` em
`MethodEnumerate` (o sed também atingiu `FieldEnumerate` — colateral
inofensivo à prova; ambos cenários herdados devem falhar sob M1).
Rebuild + execução:

```
Number of run tests: 9 / Number of errors: 2 / Number of failures: 0
List of errors:
  TTestModernRTTI.TestGetFields_EnumeratesInheritedPublishedClassFields:
    Exception class: ETestScenarioFailed
    Message: GetFields devolveu 1 campos; esperado exatamente 2 ...
  TTestModernRTTI.TestGetMethods_CountsPublishedInherited_Exact:
    Exception class: ETestScenarioFailed
    Message: GetMethods devolveu 1 metodos; esperado exatamente 2 ...
```

**Exit code sob M1: 2** (aferido). Isto valida **duas coisas**:
1. M1 é detectada pelo cenário `_Exact` — o assert de contagem exata
   pega a regressão que "≥ 1" esconderia.
2. **Closes #35 funciona** — antes da cirurgia, exit=0 sobre vermelho;
   agora exit=2. A `ETestScenarioFailed` (`class(Exception)`) é
   classificada como "error" pelo FPCUnit (não "failure"), e o
   consoletestrunner reflete no exit code. **O critério do plan
   ("PTestRTTI passa a devolver exit != 0 sobre vermelho") está
   validado no FPC.** O autor confirma no Delphi via DUnitX.

Mutação revertida antes de escrever este relatório (arquivo restaurado
de `/tmp/rtti25_backup.pas`).

### Prova de mutação M2 — declarada, não executada

Fábrica não tem `ppc386` (SKILL.md:122-124). Autor executa em Windows.
PR body deve declarar (SKILL.md:92-97):

> M2: substituir `LTab^.Entry[i]` por
> `PVmtMethodEntry(PByte(LTab) + 4 + i * 16)` → falha no i386
> (SizeOf(TVmtMethodEntry) = 8 em i386, 16 em x86_64).

### Delphi (`dcc32`) — não executado

Fábrica não tem Delphi (SKILL.md:16-27). Autor executa e declara no
corpo do PR (SKILL.md:92-97).

### Greps de aceite (do ESP §4)

- `{$IFDEF` em `Source/ModernSyntax.RTTI.pas` → apenas o único ifdef na
  `uses` da `implementation` (uso legítimo — D-25.1); zero ifdefs em
  declarações de tipo. ✓
- `PByte(LTab)` / `i * SizeOf(TVmtMethodEntry)` / `4 + .*16` em
  `Source/ModernSyntax.RTTI.FPC.pas` → zero (CA D-25.2). ✓
- `EModernRTTIError` em `Source/ModernSyntax.RTTI.FPC.pas` → 8
  ocorrências (6 métodos + 2 param — D-25.4). ✓
- `{$IFDEF FPC}` / `{$IFNDEF FPC}` em nenhum dos três arquivos de teste
  → **zero** (CA-5). ✓
- `Assert` em `Test Shared/EclbrSystem/UScenarios.RTTI.pas` → zero. O
  Delphi runner ainda usa `Assert.IsTrue` (DUnitX) para o cenário
  Delphi-only `TestGetFields_ReturnsFields`, fora do shared. Zero no
  shared (D-25.8). ✓

## Caveats / riscos residuais

- **RSK-1 — mudança semântica de `TModernRTTIField.GetValue<T>` no
  Delphi.** Antes: `LValue.AsType<T>` (coerção). Agora: primeiro
  tentativa via `FieldReadRaw` (`ExtractRawData` no Delphi), com
  fallback para `FieldReadValue` + `ExtractRawData` quando tamanhos não
  batem. O caminho `ExtractRawData` não faz coerção Int32→Int64. Nos
  testes existentes (Number: Integer, Name: string, Amount: Currency) o
  tamanho bate exato, então não regride. Se um consumidor externo
  dependia de coerção (ex.: campo Integer lido como Int64), passa a
  receber a exceção clara com mensagem "tamanho incompativel; use o
  overload TValue". Não é regressão silenciosa. Nenhum consumidor
  externo conhecido.
- **RSK-2 — pool `TRttiContext` do Delphi.** O backend Delphi cria um
  contexto local em `MethodEnumerate`/`MethodLookup`/`FieldEnumerate` e
  o libera no `finally`. Isso é seguro porque `TModernRTTI.FContext`
  (inicializado no `initialization` da public unit) mantém o pool
  global vivo pelo tempo de vida do binário — os handles retornados
  permanecem válidos até o `finalization`. Documentado no header do
  backend Delphi.
- **RSK-3 — warning "managed type not initialized" em
  `TModernRTTITypeHelper.GetMethod`.** É false positive: os dois
  caminhos que não atribuem `Result` levantam antes de sair. Não
  afeta runtime. Pré-existente-adjacente ao warning já conhecido de
  `GetProperties`. Fora de escopo suprimir.
- **RSK-4 — `TModernRTTIMethod.FToken` é `nil` no path de lookup do
  FPC.** `MethodLookup` FPC usa `MethodAddress` que devolve só o
  `Pointer` do código, não o `PVmtMethodEntry`. `Invoke` funciona
  porque delega a `TModernInvoker` (que usa `FName`). `Name` funciona
  porque devolve `FName`. Os seis membros sem fonte no FPC raise antes
  de tocar o token. Nenhum caminho lê `FToken` no FPC — o campo é
  cargo silencioso. Documentado como comentário no
  `ModernSyntax.RTTI.FPC.pas:MethodLookup`.
- **Warning pré-existente em `ModernSyntax.Invoker.pas:80` unreachable
  code** — não tocado (restrição §5).

## Handoff

- CA medidos aqui exceto: **CA i386** (`ppc386` ausente na fábrica),
  **CA Delphi** (Delphi ausente na fábrica), **M2** (mesmo motivo).
  Todos ficam com o autor e vão declarados no corpo do PR seguindo
  SKILL.md:92-97.
- **Board local:** `project-evolution.md` avançado de 🔄 in-pipeline
  para 🔄 in-review.
- **Corpo do PR (deve conter):** `Closes #25`, `Closes #35`,
  declaração das mutações M1/M2, declaração "compilado em FPC 3.2.2
  x86_64 pela fábrica; i386 e Delphi validados pelo autor".

## Referências

- [esp](pipeline-esp.md)
- [adr](pipeline-adr.md)
- [plan](pipeline-plan.md)
- [task-input](pipeline-task-input.md)
- [SKILL](/SKILL.md)
- [API-MAP §7](/strategy/2026-08-27-modernrtti/API-MAP.md)
