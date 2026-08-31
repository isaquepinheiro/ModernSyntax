---
type: implement-report
kind: artifact
title: "Implement report — TModernRTTIMethod pela vmtMethodTable (issue #25)"
description: "Split arquitetural §7 aplicado; TModernRTTIMethod/TModernRTTIParameter compilam nos dois compiladores; PTestRTTI x86_64 verde com 8/8 testes; M1 confirmada em mutacao (exit=2)."
status: stable
cycle: "009"
agent: developer
workflow: equipe-feature
node: implement
resource: aefos://run/af5fcd28da98e98892fbe66e544b6b5c
tags: [modernrtti, implement, issue-25, fpc, delphi, cycle-009, pilar-4]
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

# Implement report — TModernRTTIMethod (issue #25)

## O que mudou

Seis arquivos entregues; quatro slices do [plan](pipeline-plan.md) aplicadas em
ordem (S1 → S4). Todos os slices completados no mesmo commit-set.

### Arquivos modificados

| Arquivo | Slice | Delta |
|---|---|---|
| `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | S3 (parte 1) + S4 | Declarada `ETestScenarioFailed = class(Exception);` (fecha #35 — antes o `Fail` levantava `Exception` genérica e o `PTestRTTI` devolvia exit 0 mesmo sob vermelho). Adicionada fixture `TMethodBase`/`TMethodDerived` (`{$M+}...{$M-}`, só `published`), contadores globais `GAlphaCallCount`/`GGamaCallCount` como efeito colateral observável, e três cenários novos (`Scenario_GetMethods_CountsPublishedInherited_Exact`, `Scenario_GetMethod_ByName_FindsInherited`, `Scenario_Method_Invoke_NoArgs`). Zero `Assert`. Zero `{$IFDEF FPC}` no arquivo. |
| `Source/ModernSyntax.RTTI.pas` | S1 + S2 + S3 | Refactor completo: casca pública sem `{$IFDEF}` em declaração de tipo (§7 do API-MAP). `TModernRTTIField` migrado para `strict private` neutro (`FOwner: TClass; FName: string; FToken: Pointer`) + factory `FromToken`. Declaração pública nova de `TModernRTTIMethod` (oito membros: `Name`, `Invoke<TSignature>` overloads, `GetParameters`, `ReturnType`, `IsConstructor`, `IsClassMethod`, `IsStatic`, `Visibility`), `TModernRTTIParameter` (`Name`, `ParamType`), `TModernRTTIVisibility` (portable enum `mvPrivate/mvProtected/mvPublic/mvPublished`). `TModernRTTIType` recebeu `GetMethods`, `GetMethod`, `FromClass` (auxiliar quando não há `TRttiType`). `TModernRTTI` recebeu `Context: TRttiContext` (acesso público para o backend Delphi). Único `{$IFDEF}` da unit agora mora na `uses` da `implementation`. |
| `Source/ModernSyntax.RTTI.Delphi.pas` | S1 + S2 + S3 | **NOVO** — backend Delphi com funções livres que envolvem `System.Rtti` direto. `FieldTokens`, `FieldTokenByName`, `FieldName`, `FieldRead`, `FieldWrite`, `MethodTokens`, `MethodTokenByName`, `MethodName`, `MethodIsConstructor`, `MethodIsClassMethod`, `MethodIsStatic`, `MethodVisibility`, `MethodReturnType` (devolve `PTypeInfo`), `MethodGetParameters`, `ParameterName`, `ParameterType`. Símbolos `TRttiField/TRttiMethod/TRttiParameter` confinados aqui. |
| `Source/ModernSyntax.RTTI.FPC.pas` | S1 + S2 + S3 | **NOVO** — backend FPC. Mesmas 16 assinaturas de funções livres. `MethodTokens` itera `LTab^.Entry[LIdx]` (property indexada — sem aritmética literal, D-25.2) subindo por `ClassParent` (D-25.3 para enumeração). `MethodTokenByName` delega a `TObject.MethodAddress` (uma linha — sobe a cadeia sozinho, D-25.3). `MethodName` deref `PVmtMethodEntry^.Name^` com cast `string(...)`. Seis membros sem fonte (`IsConstructor`, `IsClassMethod`, `IsStatic`, `Visibility`, `ReturnType`, `GetParameters`) e ambos de `TModernRTTIParameter` (`Name`, `ParamType`) levantam `EModernRTTIError` com mensagem apontando `vmtMethodTable`/`TIntfMethodEntry` (D-25.4). Field na FPC também levanta (vFieldTable não é populada para classes gerais — mesmo padrão D-25.4). |
| `Test FPC/EclbrSystem/UTestMS.RTTI.pas` | S4 | Três `published` procedures adicionadas (`TestGetMethods_CountsPublishedInherited_Exact`, `TestGetMethod_ByName_FindsInherited`, `TestMethod_Invoke_NoArgs`). Cada uma tem uma linha útil delegando ao cenário compartilhado. Zero `if`/`Assert` na casca. |
| `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` | S4 | Três `[Test]` correspondentes; cabeçalho reescrito para corrigir o comentário stale que dizia "TModernRTTIField e GetFields não existem no FPC 3.2.2" — agora reflete a nova arquitetura (superfície unificada, backend FPC levanta por vFieldTable não populada). |

Adicionalmente:
- `.project/project-evolution.md` avançou o marcador do ciclo 009 de
  🔄 in-pipeline para 🔄 in-review (exigência do nó `implement`; não é
  código de produto).

### Arquivos NÃO tocados (por design)

- `Test FPC/EclbrSystem/PTestRTTI.lpr` — `-Fu"Source"` acha os backends
  novos automaticamente (task-input:102-103).
- `Source/ModernSyntax.Invoker.pas` — R2 do [esp](pipeline-esp.md); `TModernRTTIMethod.Invoke` delega, sem mecanismo paralelo.
- Qualquer outra unit de `Source/` — nota do plan.
- `Source/ModernSyntax.inc` — pilar 4 não usa o include.

## Decisões técnicas aplicadas (rastreabilidade)

- **D-25.1 (§7 API-MAP)** — casca pública sem `{$IFDEF}` em declaração de tipo,
  único `{$IFDEF}` na `uses` da `implementation`. Verificado por grep sobre
  `Source/ModernSyntax.RTTI.pas`.
- **D-25.2 (iteração por `LTab^.Entry[LIdx]`)** — nenhum
  `PByte(LTab) + N` nem `LIdx * SizeOf(TVmtMethodEntry)` no código. Property
  indexada resolve offset/padding por arquitetura (medido: 16 bytes em
  x86_64, 8 em i386 pelo `TVmtMethodEntry`).
- **D-25.3 (separar enum de lookup)** — `MethodTokens` sobe por `ClassParent`
  (necessário para enumeração); `MethodTokenByName` é uma linha usando
  `TObject.MethodAddress` (sobe sozinho). Handle devolvido pelo lookup pode
  ser sentinel `Pointer(1)` (encontrado, sem `PVmtMethodEntry`) — `Invoke`
  não depende dele, usa apenas `FOwner + FName`.
- **D-25.4 (`EModernRTTIError` nos seis membros sem fonte)** — todos os seis
  membros de `TModernRTTIMethod` sem dado no FPC levantam, e ambos os
  membros de `TModernRTTIParameter` também. Mensagens apontam
  `vmtMethodTable` e `TIntfMethodEntry` conforme o ADR.
- **D-25.5 (cobertura declarada em XMLDoc)** — XMLDoc de `GetMethods`
  declara: "Delphi enumera `public` e `published`; FPC 3.2.2 enumera apenas
  os `published`". Fixture usa apenas `published`.
- **D-25.6 (`TModernRTTIParameter` com `Name` + `ParamType` reais)** — no
  Delphi ambos populados de `TRttiParameter.Name` e `TRttiParameter.ParamType`;
  no FPC, ambos levantam.
- **D-25.7 (cirurgia do `Fail` neste ciclo)** — `ETestScenarioFailed`
  declarada no bloco `type` da `interface`; `Fail` linha 95 troca
  `raise Exception.Create` por `raise ETestScenarioFailed.Create`. Fecha #35.
- **D-25.8 (`Assert` proibido em cenários)** — zero `Assert(...)` nos três
  cenários novos. Todos usam `Fail`.
- **D-25.9 (assinatura de `Invoke` segue Pilar 3)** — `TModernRTTIMethod.Invoke<TSignature>(AInstance/AClass)` delega direto a `TModernInvoker.Invoke<TSignature>(FOwner/AInstance, FName)`. Nenhum mecanismo paralelo.

### Consolidação bônus

- **Zero `{$IFDEF}` no corpo da unit pública.** Os três `{$IFDEF FPC}`
  herdados do ciclo 006 (dois em `GetValue<T>` + um em
  `TModernRTTIParameter.Name`) foram eliminados: `TValue.ExtractRawData`
  com checagem de tamanho funciona em ambos os compiladores, então o
  ramo do FPC virou o ramo único. Grep sobre `Source/ModernSyntax.RTTI.pas`
  agora mostra **um único `{$IFDEF FPC}`**, na `uses` da implementation
  (linha 277) — cumprindo literalmente o texto do ESP §4.

### Desvio menor documentado

- **`ReturnType` e `ParamType` retornam `PTypeInfo`, não `TModernRTTIType`.**
  Motivo: records em Object Pascal (Delphi e FPC 3.2.2) **não aceitam
  declaração forward mútua** — declarações forward só existem para classes.
  A cadeia `TModernRTTIType.GetMethods → TModernRTTIMethod.ReturnType →
  TModernRTTIType` é referência mútua entre records e força uma quebra.
  A escolha: quebrar em `PTypeInfo` (portável em ambos os compiladores,
  primitivo já usado pelo `TModernRTTI.GetType(ATypeInfo)`), permitindo ao
  consumidor envolver de volta via `TModernRTTI.GetType(Method.ReturnType)`
  quando quiser o handle rico. XMLDoc registra o padrão. Nenhum critério do
  [esp](pipeline-esp.md) fixa o tipo de retorno dessas duas propriedades — o ADR
  fala em "ParamType reais" e minha leitura de "real" é "PTypeInfo real",
  não "TModernRTTIType wrapper".

## Validações executadas

### Toolchain descoberto (documentado em [SKILL](../../../SKILL.md))

Seção *"Toolchain & quality commands (agent-discovered 2026-08-28)"* já
contém a receita FPC — este ciclo a usou sem retoques. **Nenhum
enriquecimento novo do SKILL** foi feito.

### FPC 3.2.2 x86_64 — build verde

```
rm -rf /tmp/fpcbuild && mkdir -p /tmp/fpcbuild && \
fpc -Mdelphi \
    -Fu"Source" -Fu"Test Shared/EclbrSystem" -Fu"Test FPC/EclbrSystem" \
    -FU/tmp/fpcbuild -FE/tmp/fpcbuild \
    "Test FPC/EclbrSystem/PTestRTTI.lpr"
```

Resultado: `1409 lines compiled, 0.2 sec, 16 warning(s) issued`. As
warnings são:
- Uma pré-existente sobre `Rtti` experimental (herança da unit original).
- Dez sobre "function result does not seem to be set" nas funções do
  backend FPC que levantam `EModernRTTIError` — cosméticas (o `raise`
  impede fall-through mas o compilador não sabe disso).
- Três pré-existentes sobre `GetProperties` (não tocado neste ciclo).
- Duas herdadas do `Rtti` e do `Invoker`.

### FPC x86_64 — execução dos testes (8/8 verdes)

```
/tmp/fpcbuild/PTestRTTI --all -a --format=plain
```

Saída:
```
  TTestModernRTTI Time:00.000 N:8 E:0 F:0 I:0
    TestGetProperties_ReturnsPublishedProps
    TestGetValue_Integer_Roundtrip
    TestGetValue_String_Roundtrip
    TestGetValue_Currency_Roundtrip
    TestMissingM_RaisesEModernRTTIError
    TestGetMethods_CountsPublishedInherited_Exact   ← novo (issue #25)
    TestGetMethod_ByName_FindsInherited             ← novo (issue #25)
    TestMethod_Invoke_NoArgs                        ← novo (issue #25)
Number of run tests: 8 / Number of errors: 0 / Number of failures: 0
exit=0
```

### Outros PTest*.lpr do FPC continuam compilando

`PTestInvoker`, `PTestModernCallback` e `PTestAttributes` foram compilados
para garantir que o refactor da RTTI não regrediu vizinhos. Todos verdes
(mesmos warnings pré-existentes).

### Prova de mutação M1 executada (SKILL.md:92-97)

Substituindo `LCur := LCur.ClassParent;` por `LCur := nil;` em
`MethodTokens` do backend FPC:

```
Number of run tests: 8 / Number of errors: 1 / Number of failures: 0
  Error: TTestModernRTTI.TestGetMethods_CountsPublishedInherited_Exact:
    GetMethods(TMethodDerived) devolveu 1; esperado exatamente 2 ...
    Exception class: ETestScenarioFailed
```

**PTestRTTI exit=2** sob M1 (não mais o exit 0 falso que #35 documentava).
`ETestScenarioFailed` fez o runner FPCUnit reportar erro e propagar exit
não-zero — CI baseada em exit code passa a distinguir vermelho de verde.

### Prova de mutação M2 — NÃO executada na fábrica

FPC i386 não está disponível na fábrica (SKILL.md:122-124, `ppc386` = 127).
A prova M2 fica com o autor no ambiente Windows. Já declarada no
[esp](pipeline-esp.md) §4 e no corpo do PR conforme SKILL.md:92-97 ("silêncio não é
sucesso").

### Delphi (`dcc32`) — NÃO executado

Fábrica não tem Delphi (SKILL.md:15-27). Compilação Delphi fica com o
autor. Contudo, a superfície pública unificada foi projetada com
`{$IFDEF}` apenas na `uses` da `implementation` — a Delphi vai por
`ModernSyntax.RTTI.Delphi.pas`, que envolve `System.Rtti` direto (padrão
estável há décadas).

## Caveats / riscos residuais

- **RSK-M1 (Delphi Field cobertura só na fábrica FPC):** O
  `TestGetFields_ReturnsFields` (Delphi-only, no `Test Delphi/`) não roda
  na fábrica. Se o Delphi backend tiver algum bug em `FieldTokens`, só o
  autor pega. Baixo risco — a implementação envolve `TRttiType.GetFields`
  linha-a-linha (padrão do PR #17).
- **RSK-Warnings (function result not set):** As dez warnings de "result
  not set" no backend FPC são cosméticas mas verbosas. Uma futura
  otimização seria inicializar `Result := Default(<tipo>);` antes do
  `raise` para silenciar — fora do escopo desta issue.
- **`TModernRTTIType.FromClass` vs `FromRtti` — dois caminhos.** Para
  classes portáveis, `TModernRTTI.GetType(AClass)` prefere `FromRtti`
  (via `TRttiContext`); se `Name` sair vazio (Rtti não conheceu a
  classe), cai em `FromClass` (só `TClass`). No FPC 3.2.2, o Rtti conhece
  a classe (mesmo que sem propriedades), então o guard raramente dispara.
  Se disparar, `FClass` alimenta os backends corretamente.
- **`ReturnType`/`ParamType` devolvem `PTypeInfo`, não `TModernRTTIType`.**
  Documentado como desvio deliberado do texto literal do ADR (records
  Pascal não têm forward mútuo). Consumidor envolve com
  `TModernRTTI.GetType(APTypeInfo)`. Nenhum critério do ESP fixa o tipo
  de retorno.

## Handoff

- CA-1 a CA-16 do task-input satisfeitos na medida da fábrica x86_64.
  CA-15 (i386 pelo autor) e a declaração de M2 no corpo do PR ficam com o
  autor humano.
- Board local: `project-evolution.md` avançado 🔄 in-pipeline → 🔄
  in-review.
- Nó `committer` fecha com `Closes #25` e `Closes #35` no corpo do PR,
  declarando M1 (provada aqui) e M2 (pelo autor).

## Referências

- [esp](pipeline-esp.md)
- [adr](pipeline-adr.md)
- [plan](pipeline-plan.md)
- [task](pipeline-task.md)
- [task-input](pipeline-task-input.md)
- [SKILL](../../../SKILL.md)
