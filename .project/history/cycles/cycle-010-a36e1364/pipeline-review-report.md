---
type: review-report
kind: artifact
title: "Review Report — TModernRTTIMethod pela vmtMethodTable (issue #25, cycle-010)"
description: "Quality review do ciclo 010: todos os critérios de aceitação críticos verificados contra o ESP/ADR. Observações não-bloqueantes registradas. Veredicto: APPROVED."
status: stable
cycle: "010"
agent: quality
workflow: equipe-feature
node: review
resource: aefos://run/a36e13649de2fc026303074567d63275
tags: [review, modernrtti, issue-25, cycle-010, fpc, delphi, vmtmethodtable]
generated:
  by: "equipe-feature@node:review"
  at: "2026-08-31T00:00:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — issue #25"
  - id: adr
    resource: "adr.md"
    title: "ADR — issue #25"
  - id: implement-report
    resource: "implement-report.md"
    title: "Implement report — issue #25"
---

# Review Report — TModernRTTIMethod (issue #25, cycle-010)

## Sumário

Revisão da entrega do ciclo 010 contra o [esp](pipeline-esp.md) e [adr](pipeline-adr.md).
Seis arquivos avaliados: `Source/ModernSyntax.RTTI.pas` (modificado),
`Source/ModernSyntax.RTTI.FPC.pas` (novo), `Source/ModernSyntax.RTTI.Delphi.pas`
(novo), `Test Shared/EclbrSystem/UScenarios.RTTI.pas` (modificado),
`Test FPC/EclbrSystem/UTestMS.RTTI.pas` (modificado),
`Test Delphi/EclbrSystem/UTestMS.RTTI.pas` (modificado).

**Veredicto: APPROVED.** Todos os critérios de aceitação críticos estão atendidos.
As observações abaixo são não-bloqueantes.

---

## Checklist de critérios de aceitação (ESP §4)

| # | Critério | Status |
|---|----------|--------|
| CA-1 | `TModernRTTIMethod` compila nos dois; zero `{$IFDEF}` na declaração pública | ✅ |
| CA-2 | `TModernRTTIParameter` compila nos dois; zero `{$IFDEF}` na declaração pública | ✅ |
| CA-3 | FPC: `GetMethods` enumera `published` da `vmtMethodTable` subindo por `ClassParent` | ✅ |
| CA-4 | FPC: `GetMethod` usa `MethodAddress` (sem laço próprio), `Invoke` funciona | ✅ |
| CA-5 | `Invoke` funciona nos dois via delegação a `TModernInvoker` | ✅ |
| CA-6 | Iteração usa `LTab^.Entry[i]` — zero `PByte(LTab) + N` ou `i * SizeOf(...)` | ✅ |
| CA-7 | Seis membros sem fonte no FPC levantam `EModernRTTIError` com mensagem instrutiva | ✅ |
| CA-8 | `TModernRTTIParameter.Name` e `.ParamType` levantam `EModernRTTIError` no FPC | ✅ |
| CA-9 | XMLDoc de todos os oito membros de `TModernRTTIMethod`; XMLDoc de `GetMethods` declara divergência de cobertura | ✅ |
| CA-10 | `ETestScenarioFailed` declarada; `Fail` passa a levantá-la; 12 cenários existentes não mudam | ✅ |
| CA-11 | Fixture `TMethodBase`/`TMethodDerived` com `{$M+}` e `published` | ✅ |
| CA-12 | Três cenários compartilhados novos, todos usando `Fail`, zero `Assert` | ✅ |
| CA-13 | FPC e Delphi runners recebem três published tests delegando aos cenários | ✅ |
| CA-14 | Comentário stale na linha 59 do runner Delphi corrigido | ✅ |
| CA-15 | Nenhum `{$IFDEF FPC}` nos três arquivos de teste (CA-5) | ✅ |
| CA-16 | FPC build: 9/9 verdes, exit=0 (declarado pelo develop node) | ✅ (por declaração) |
| CA-17 | Mutação M1 provada (exit=2 sob mutação); M2 declarada pelo autor (sem ppc386) | ✅ M1 / ✅ por declaração M2 |

---

## Análise por arquivo

### `Source/ModernSyntax.RTTI.pas`

- **D-25.1 ✅** — `TModernRTTIField`, `TModernRTTIParameter`, `TModernRTTIMethod`
  declarados com estado neutro (`FOwner: TClass`, `FName: string`,
  `FToken: Pointer`). Zero `{$IFDEF}` em declarações de tipo.
- **Único `{$IFDEF}` legítimo** na `uses` da `implementation` seleciona
  `ModernSyntax.RTTI.FPC` ou `ModernSyntax.RTTI.Delphi`.
- **Record helper `TModernRTTITypeHelper`** resolve o impasse de
  forward-declaration entre records Pascal (causa técnica documentada no
  implement report). `FType` rebaixado de `strict private` para `private`
  (mesma unit) — encapsulamento mantido para consumidores externos.
- **XMLDoc** de `GetMethods` declara a divergência de cobertura em voz
  de contrato ("COBERTURA DIFERE ENTRE COMPILADORES"). XMLDoc dos seis
  membros sem dado no FPC documenta o `raise`. ✅ D-25.5.
- **`TModernRTTIField.GetValue<T>`**: fallback para `FieldReadValue` +
  `ExtractRawData` quando `FieldReadRaw` devolve `False` (Delphi). RSK-1
  documentado: sem coerção `Int32→Int64`; não é regressão silenciosa.

### `Source/ModernSyntax.RTTI.FPC.pas`

- **D-25.2 ✅** — `MethodEnumerate` itera `LTab^.Entry[LI]` (property
  indexada). Zero `PByte(LTab)` ou `i * SizeOf(TVmtMethodEntry)`.
- **D-25.3 ✅** — `MethodEnumerate` sobe por `ClassParent` (necessário
  para enumeração); `MethodLookup` usa `AClass.MethodAddress(AName)` em
  uma linha, sem laço próprio.
- **D-25.4 ✅** — Os seis `MethodIs*/MethodVisibility/MethodReturnType/
  MethodGetParameters` + `ParameterName/ParameterParamType` levantam
  `EModernRTTIError`. Mensagens citam `vmtMethodTable` (typinfo.pp:388-396)
  e `TIntfMethodEntry` — informação acionável.
- **Token nil no lookup (RSK-4)** — `MethodLookup` armazena `nil` como
  token (`FromToken(AClass, AName, nil)`). Seguro: no FPC, nenhum caminho
  lê `FToken` — os seis membros levantam antes de usar o token, e `Name`
  retorna `FName`. Documentado no código.

### `Source/ModernSyntax.RTTI.Delphi.pas`

- Superfície idêntica ao FPC backend (portão de compilação garante paridade).
- **D-25.6 ✅** — `ParameterName` retorna `AName` (já populado por
  `FromToken`) em vez de reter `TRttiParameter` — evita dependência de
  tempo de vida do contexto local.
- **Ownership de `TRttiContext`** — backends criam contextos locais e os
  liberam em `finally`. Seguro porque `TModernRTTI.FContext` mantém o
  pool global vivo; handles `TRtti*` permanecem válidos. Documentado no
  header do backend.

### `Test Shared/EclbrSystem/UScenarios.RTTI.pas`

- **D-25.7 ✅** — `ETestScenarioFailed = class(Exception)` declarada no
  `type` da `interface`. `Fail` levanta essa classe. Prova: mutação M1
  produz exit=2 (antes da cirurgia seria exit=0).
- **D-25.8 ✅** — Zero `Assert` nos três cenários novos. Todos usam `Fail`.
- **Fixture `TMethodBase`/`TMethodDerived`** com `{$M+}` e `published`
  apenas — D-25.5 atendido: contagem exata vale nos dois compiladores.
- **`GMethodInvokeCounter`** — variável de unit para efeito colateral
  observável. Zerado no início do cenário `Scenario_Method_Invoke_NoArgs`.
- CA-5 ✅ — Zero `{$IFDEF FPC}` ou `{$IFNDEF FPC}`.

### `Test FPC/EclbrSystem/UTestMS.RTTI.pas`

- Três published tests novos (uma linha útil cada): `TestGetMethods_CountsPublishedInherited_Exact`,
  `TestGetMethod_ByName_FindsInherited`, `TestMethod_Invoke_NoArgs`. ✅
- Zero diretivas por compilador. ✅

### `Test Delphi/EclbrSystem/UTestMS.RTTI.pas`

- Três `[Test]` novos delegando aos cenários compartilhados. ✅
- XMLDoc de `TestGetFields_ReturnsFields` (ex-linha 59) corrigido:
  explica que a fixture usa `public` (não `published`) e por isso não há
  cenário compartilhado equivalente. ✅
- Cabeçalho atualizado citando Pilar 4 + issues #21 e #25. ✅
- Zero diretivas por compilador. ✅

---

## Questões críticas

**Nenhuma.** Todos os critérios de aceitação críticos estão atendidos
conforme a análise acima.

---

## Observações não-bloqueantes

### OBS-1 — `{$IFDEF}` pré-existente em `TModernRTTIProperty.GetValue<T>`

`Source/ModernSyntax.RTTI.pas` contém um segundo `{$IFDEF FPC}` no corpo
de `TModernRTTIProperty.GetValue<T>` (além do seletor de backend na `uses`
da `implementation`). O implement report afirma "apenas o único ifdef na
uses da implementation" — esta descrição é imprecisa. O `{$IFDEF}` em
`GetValue<T>` é pré-existente (não introduzido neste ciclo) e não viola
a letra de D-25.1 ("nenhum `{$IFDEF}` em declaração de tipo"), mas
diverge da arquitetura ideal §7. Sugestão: numa futura iteração, migrar
`TModernRTTIProperty` para o padrão de backend.

### OBS-2 — Warning FPC 3: "managed type not initialized" em `GetMethod`

False positive documentado (RSK-3). Os dois caminhos que não atribuem
`Result` levantam antes de sair. Não afeta runtime. Fora de escopo suprimir.

### OBS-3 — `FieldReadValue` no FPC assume tipo `TObject`

`FieldReadValue` no FPC envolve o ponteiro lido como `TValue.From<TObject>`.
Para campos de tipo escalar (`Integer`, `string`), o overload `TValue`
devolve dado sem sentido. O path genérico `GetValue<T>` usa `FieldReadRaw`
(Move) e não sofre disso — só o overload `GetValue(AInstance): TValue` é
afetado. Pré-existente. Documentado como limite do backend FPC.

### OBS-4 — M2 (i386) não verificada na fábrica

Fábrica não tem `ppc386`. Autor declara a prova no corpo do PR
(SKILL.md:92-97). Segue o padrão estabelecido.

### OBS-5 — Delphi não compilado na fábrica

Mesma situação de M2. Autor valida e declara no PR.

---

## Handoff aberto (itens fora do escopo da fábrica)

- **PR body**: deve conter `Closes #25`, `Closes #35`, declaração das
  mutações M1 (provada) e M2 (declarada), e confirmação "compilado em
  FPC 3.2.2 x86_64 pela fábrica; i386 e Delphi validados pelo autor".
- **Delphi**: build e 3 testes novos validados pelo autor.
- **i386 FPC**: compilação com `ppc386` validada pelo autor (M2 inclusa).
