---
type: board
title: "ModernSyntax — project-evolution board"
description: "Registro evolutivo das demandas do projeto: estado atual de cada ciclo rastreado."
tags: [board, modernrtti, pilar-1]
---

# ModernSyntax — project evolution board

Quadro de estado das demandas. Cada entrada referencia a issue GitHub
correspondente e o ciclo ativo.

| Ciclo | Issue | Demanda | Estado |
|-------|-------|---------|--------|
| 002 | [#8](https://github.com/isaquepinheiro/ModernSyntax/issues/8) | Implementar Pilar 1 — Leitura de RTTI (TModernRTTIType, TModernRTTIProperty, TModernRTTIField) | 📤 PR aberto — [#11](https://github.com/isaquepinheiro/ModernSyntax/pull/11) |
| 003 | [#7](https://github.com/isaquepinheiro/ModernSyntax/issues/7) | Implementar callbacks transversais — IModernFunc, IModernProc, IModernPredicate + factory Callback.Of | 📤 PR aberto — [#12](https://github.com/isaquepinheiro/ModernSyntax/pull/12) |
| 004 | [#9](https://github.com/isaquepinheiro/ModernSyntax/issues/9) | Implementar Pilar 2 — Atributos portáveis (ModernSyntax.Attributes.pas + cenários + cascas DUnitX e FPCUnit) | 📤 PR aberto — [#16](https://github.com/isaquepinheiro/ModernSyntax/pull/16) |
| 005 | [#10](https://github.com/isaquepinheiro/ModernSyntax/issues/10) | Implementar Pilar 3 — TModernInvoker (ModernSyntax.Invoker.pas + cenários + cascas DUnitX e FPCUnit) | 📤 PR aberto — [#19](https://github.com/isaquepinheiro/ModernSyntax/pull/19) |
| 006 | [#8](https://github.com/isaquepinheiro/ModernSyntax/issues/8) | Pilar 1 ModernRTTI — Source/ModernSyntax.RTTI.pas + cascas de teste (re-entrada pós plan-gate:on_reject) | 📤 PR aberto — [#20](https://github.com/isaquepinheiro/ModernSyntax/pull/20) |
| 004 | [#7](https://github.com/isaquepinheiro/ModernSyntax/issues/7) | Reimplementar callbacks transversais — nova iteração após plan-gate:on_reject (ciclo 003) | 📤 PR aberto — [#18](https://github.com/isaquepinheiro/ModernSyntax/pull/18) |
| 008 | [#21](https://github.com/isaquepinheiro/ModernSyntax/issues/21) | TModernRTTIField portável nos dois compiladores — mesmo tipo, dois mecanismos por dentro (FPC via vmtFieldTable, Delphi via TRttiField) | 📤 PR aberto — [#34](https://github.com/isaquepinheiro/ModernSyntax/pull/34) |
| 010 | [#25](https://github.com/isaquepinheiro/ModernSyntax/issues/25) | TModernRTTIMethod pela vmtMethodTable — enumerar published, split de backends RTTI, migrar TModernRTTIField, fechar #35 | 📤 PR aberto — [#37](https://github.com/isaquepinheiro/ModernSyntax/pull/37) |
| 011 | [#26](https://github.com/isaquepinheiro/ModernSyntax/issues/26) | TModernValue.AsType<T> portavel — TValueOps nos backends Delphi+FPC, reescrever GetValue<T>, 7 cenarios compartilhados + 1 published local FPC | 📤 PR aberto — [#39](https://github.com/isaquepinheiro/ModernSyntax/pull/39) |
| 012 | [#27](https://github.com/isaquepinheiro/ModernSyntax/issues/27) | Enumerators nas colecoes: for..in sobre Fields, Properties, Methods, Parameters, Attributes — property alias sobre TArray<T> nos dois compiladores | 📤 PR aberto — [#40](https://github.com/isaquepinheiro/ModernSyntax/pull/40) |
| 013 | [#28](https://github.com/isaquepinheiro/ModernSyntax/issues/28) | TModernRTTIContext com GetTypes e FindType nos dois compiladores — token opaco IInterface, registry per-instancia FPC, GetPackages fora com motivo, cinco cenarios compartilhados | 📤 PR aberto — [#41](https://github.com/isaquepinheiro/ModernSyntax/pull/41) |
| 015 | [#42](https://github.com/isaquepinheiro/ModernSyntax/issues/42) | TModernVisibility publico; fechar vazamento em TModernRTTIMethod.Visibility; adicionar TModernRTTIProperty.Visibility — backends Delphi/FPC, tres cenarios, mutacao de sanidade | 📤 PR aberto — [#47](https://github.com/isaquepinheiro/ModernSyntax/pull/47) |
| 016 | [#43](https://github.com/isaquepinheiro/ModernSyntax/issues/43) | TModernRTTIEnumerationType com guards M-1/M-2 nos dois backends; seis funcoes livres FPC, paridade Delphi, quatro cenarios compartilhados, mutacao de sanidade | 📤 PR aberto — [#48](https://github.com/isaquepinheiro/ModernSyntax/pull/48) |
| 017 | [#44](https://github.com/isaquepinheiro/ModernSyntax/issues/44) | TModernRTTIPointerType com ReferredType nos dois compiladores; backend FPC com property RefType e MUTACAO OBRIGATORIA; backend Delphi com paridade; dois cenarios compartilhados; mutacao de sanidade | 🔄 in-review |
| 018 | [#45](https://github.com/isaquepinheiro/ModernSyntax/issues/45) | TModernRTTIRecordType com Name + Size nos dois compiladores; duas fixtures obrigatorias (TRecordFixture45 unmanaged + TRecordFixture45M managed); helper RecordRaiseWrongKind; issue-filha GetFields fora do commit | 📤 PR aberto — [#52](https://github.com/isaquepinheiro/ModernSyntax/pull/52) |
| 019 | [#46](https://github.com/isaquepinheiro/ModernSyntax/issues/46) | TModernRTTIArrayType + TModernRTTISetType nos dois compiladores; Length levanta em dinamico; helpers ArrayRaiseWrongKind/SetRaiseWrongKind; quatro cenarios compartilhados; duas mutacoes obrigatorias com log no PR | 📤 PR aberto — [#54](https://github.com/isaquepinheiro/ModernSyntax/pull/54) |
| 020 | [#49](https://github.com/isaquepinheiro/ModernSyntax/issues/49) | Contrato unico de handle nil em TModernRTTIType — cinco guardas (Name/GetProperties/GetFields/GetMethods/GetMethod); EModernRTTIError + SModernRTTINilHandle; XMLDocs; cenario NilHandle_AllMembers_Raises; desbloqueio D-44.6 | 📤 PR aberto — [#55](https://github.com/isaquepinheiro/ModernSyntax/pull/55) |
| 021 | [#56](https://github.com/isaquepinheiro/ModernSyntax/issues/56) | TModernRTTIType.Attributes fora do contrato nil da #49 — guarda em PropAttributes; uniformizacao dos cinco blocos (Pos → igualdade estrita); sexto bloco Attributes em Scenario_NilHandle_AllMembers_Raises | 📤 PR aberto — [#58](https://github.com/isaquepinheiro/ModernSyntax/pull/58) |
| 022 | [#51](https://github.com/isaquepinheiro/ModernSyntax/issues/51) | Fix: else raise nos dois sites de Visibility do backend Delphi — resourcestring privada SDelphiUnknownVisibility + else raise em MethodVisibility e PropertyVisibility + reescrita de 2 comentarios + reescrita de 1 XML-doc. Dois arquivos, commit unico. | 🔄 in-review |

## Legenda

- 🔄 in-pipeline — ciclo ativo; artefatos em produção
- 🔄 in-review — implementação entregue; aguardando review/test/verify
- 📤 PR aberto — branch commitada e PR aberto para revisão humana
- ✅ done — PR mergeado, ciclo encerrado
- ⏸ blocked — aguardando dependência externa
- ❌ rejected — descartado com registro de decisão

## Notas de rastreamento

**Ciclo 002** — MAESTRO MODE. A issue #8 foi criada pelo maestro como
`aefos:investigated` e é a demanda oficial deste ciclo. Nenhuma issue ou
Epic adicional foi criada. Label atual: `aefos:running, feature`.

**Ciclo 003** — MAESTRO MODE. A issue #7 é a demanda oficial deste ciclo
(intake do maestro). Nenhuma issue ou Epic adicional criada. Label atual:
`aefos:running, feature`. Entrega: `Source/ModernSyntax.Callback.pas` com
três interfaces genéricas e factory `Callback.Of`; unit de cenários em
`Test Shared/`; cascas finas DUnitX e FPCUnit.

**Ciclo 004** — MAESTRO MODE. A issue #9 é a demanda oficial deste ciclo
(intake do maestro). Nenhuma issue ou Epic adicional criada. Demanda:
implementar `Source/ModernSyntax.Attributes.pas` com `TModernAttribute` e
`ModernAttributes` (Register + GetAttributes + regra 2 do ADENDO), unit
compartilhada de cenários e duas cascas finas (DUnitX + FPCUnit).

**Ciclo 005** — MAESTRO MODE. A issue #10 é a demanda oficial deste ciclo
(intake do maestro). Nenhuma issue ou Epic adicional criada. Demanda:
implementar `Source/ModernSyntax.Invoker.pas` com `TModernInvoker` (record
com dois overloads `Invoke<TSignature>` sobre `TObject.MethodAddress`),
unit compartilhada de sete cenários e duas cascas finas (DUnitX + FPCUnit).

**Ciclo 006** — MAESTRO MODE. A issue #8 é a demanda oficial deste ciclo
(re-entrada da demanda Pilar 1 ModernRTTI, após plan-gate:on_reject nos
ciclos anteriores). Nenhuma issue ou Epic adicional criada. Demanda:
criar `Source/ModernSyntax.RTTI.pas` (TModernRTTI, TModernRTTIProperty
portável; TModernRTTIField Delphi-only em {$IFNDEF FPC}; EModernRTTIError),
unit compartilhada de cenários, cascas DUnitX + FPCUnit, runner Delphi e
PTestRTTI.lpr + .lpi standalone FPC (padrão commit 7114cdc). Compilar FPC
antes de entregar.

**Ciclo 008** — MAESTRO MODE. A issue #21 é a demanda oficial deste ciclo
(intake do maestro: `aefos:investigated`). Nenhuma issue ou Epic adicional
criada. Demanda: tornar `TModernRTTIField` e `TModernRTTIType.GetFields`
portáveis nos dois compiladores — declaração pública incondicional, factories
privadas `FromRaw` (FPC) / `FromRtti` (Delphi), loop de herança via
`vmtFieldTable` tipada no FPC, subindo por `ClassParent`. Três arquivos
modificados: `Source/ModernSyntax.RTTI.pas`, `Test Shared/EclbrSystem/UScenarios.RTTI.pas`,
`Test FPC/EclbrSystem/UTestMS.RTTI.pas`. Build FPC 3.2.2 x86_64 e i386 obrigatório.

**Ciclo 010** — MAESTRO MODE. A issue #25 é a demanda oficial deste ciclo
(intake do maestro: `aefos:investigated`). Nenhuma issue ou Epic adicional
criada. Demanda: adicionar `TModernRTTIMethod`/`TModernRTTIParameter` com
`GetMethods`/`GetMethod` nos dois compiladores; split de backends em
`ModernSyntax.RTTI.Delphi.pas` e `ModernSyntax.RTTI.FPC.pas`; migrar
`TModernRTTIField` para campos neutros + `FromToken`; fechar #35 com
declaração de `ETestScenarioFailed` em `UScenarios.RTTI.pas`; três cenários
compartilhados; cascas de teste FPC e Delphi. Build FPC x86_64 e i386 obrigatório.

**Ciclo 012** — MAESTRO MODE. A issue #27 é a demanda oficial deste ciclo
(intake do maestro: `aefos:investigated`). Nenhuma issue ou Epic adicional criada.
Demanda: adicionar quatro properties alias ao `TModernRTTITypeHelper` (`Fields`,
`Properties`, `Methods`, `Attributes`) e uma property alias ao `TModernRTTIMethod`
(`Parameters`) em `Source/ModernSyntax.RTTI.pas`; método privado `GetAttributes`;
importar `ModernSyntax.Attributes` na `uses` da `interface`; sete cenários compartilhados
em `UScenarios.RTTI.pas`; seis published/[Test] em cada casca FPC e Delphi.
Zero `{$IFDEF}` nos cenários (CA-5). Build FPC x86_64 e i386 obrigatório; autor confirma Delphi 12.

**Ciclo 015** — MAESTRO MODE. A issue #42 é a demanda oficial deste ciclo
(intake do maestro: `aefos:investigated`; re-entrada após plan-gate:on_reject
no ciclo 014). Nenhuma issue ou Epic adicional criada. Demanda: declarar
`TModernVisibility = (mvPrivate, mvProtected, mvPublic, mvPublished)` antes
de `TModernRTTIField` na interface de `Source/ModernSyntax.RTTI.pas`; trocar
tipo de retorno de `TModernRTTIMethod.Visibility`; adicionar
`TModernRTTIProperty.Visibility`; backends Delphi (`case` explícito de 4
ramos em `MethodVisibility` e novo `PropertyVisibility`) e FPC
(`MethodVisibility` levanta com `SFPCNoVisibility` reescrita; `PropertyVisibility`
com `case` de 4 ramos, sem `mvAutomated`, sem raise); três cenários em
`UScenarios.RTTI.pas`; cascas FPC e Delphi atualizadas; mutação de sanidade
obrigatória (`CA-9`). Build FPC 3.2.2 x86_64 e i386 obrigatório.

**Ciclo 011** — MAESTRO MODE. A issue #26 é a demanda oficial deste ciclo
(intake do maestro: `aefos:running`). Nenhuma issue ou Epic adicional criada.
Demanda: implementar `TModernValue` (record portável com `From<T>`, `FromValue`,
`AsType<T>`) e `TValueOps` em cada backend — Delphi delega a `TValue.AsType<T>`;
FPC converte via `IsType(TypeInfo(T))` + `ExtractRawData` + raise com mensagem
acionável (origem + destino). Reescrever `TModernRTTIProperty.GetValue<T>` em
uma linha via `TModernValue`; remover `{$IFDEF FPC}` das linhas 385–397.
Sete cenários compartilhados + 1 published local FPC para caso de exceção.
Build FPC x86_64 e i386 obrigatório; autor confirma Delphi 12.

**Ciclo 016** — MAESTRO MODE. A issue #43 é a demanda oficial deste ciclo
(intake do maestro: `aefos:investigated`). Nenhuma issue ou Epic adicional criada.
Demanda: implementar `TModernRTTIEnumerationType` com seis funções livres nos
backends FPC e Delphi, guards M-1/M-2, três `resourcestring` novas por backend,
quatro cenários compartilhados com fixtures `TCor` e `TDia`, mutação de sanidade
obrigatória. Build FPC 3.2.2 x86_64 e i386 obrigatório.

**Ciclo 018** — MAESTRO MODE. A issue #45 é a demanda oficial deste ciclo
(intake do maestro: `aefos:investigated`). Nenhuma issue ou Epic adicional criada.
Demanda: implementar `TModernRTTIRecordType` — record público em
`Source/ModernSyntax.RTTI.pas` com `strict private FToken: PTypeInfo`, factory
`FromTypeInfo` sem guarda de Kind, properties `Name` e `Size`; backend FPC com
`RecordTypeName` (`string(P^.Name)`) e `RecordTypeSize` (`GetTypeData(P)^.RecSize`),
`resourcestring SRecordWrongKind`, helper `RecordRaiseWrongKind`; backend Delphi com
paridade — `RecordTypeName` com `LCtx` local e `try/finally`, `RecordTypeSize` direto
via `GetTypeData`; duas fixtures obrigatórias `TRecordFixture45` (unmanaged) e
`TRecordFixture45M` (managed); cenário compartilhado com quatro asserções; uma
procedure por casca. XMLDoc do record com frase-verbatim do acceptance. Issue-filha
`GetFields` aberta após merge. Fecha `Closes #45`; parte de `#29`. Build FPC 3.2.2
x86_64 e i386 obrigatório.

**Ciclo 019** — MAESTRO MODE. A issue #46 é a demanda oficial deste ciclo
(intake do maestro: `aefos:investigated`). Nenhuma issue ou Epic adicional criada.
Demanda: implementar `TModernRTTIArrayType` e `TModernRTTISetType` em `Source/ModernSyntax.RTTI.pas`
(após `TModernRTTIRecordType`); backends FPC e Delphi com cinco funções livres cada, helpers
`ArrayRaiseWrongKind` (guarda combinada `[tkArray, tkDynArray]`) e `SetRaiseWrongKind`,
três `resourcestring` por backend (`SArrayWrongKind`, `SArrayDynamicLength`, `SSetWrongKind`);
`Length` levanta `EModernRTTIError` no dinamico nos dois compiladores; quatro cenarios
compartilhados (7–10) com fixtures `TArr5Int46`, `TDynByteArr46`, `TDynStrArr46`, `TSetCor46`;
+4 published FPC (37→41), +4 [Test] Delphi (35→39); duas mutacoes obrigatorias com log no PR.
Fecha `Closes #46`; parte de `#29`. Build FPC 3.2.2 x86_64 e i386 obrigatorio.

**Ciclo 020** — MAESTRO MODE. A issue #49 é a demanda oficial deste ciclo
(intake do maestro: `aefos:investigated`). Nenhuma issue ou Epic adicional criada.
Demanda: adicionar `resourcestring SModernRTTINilHandle` em `Source/ModernSyntax.RTTI.pas`;
cinco guardas `if FType = nil then raise EModernRTTIError.CreateFmt(SModernRTTINilHandle, [membro])`
em `Name`, `GetProperties`, `GetFields` (antes do `is TRttiInstanceType` check),
`GetMethods` e `GetMethod`; cinco XMLDoc `<remarks>` nas declaracoes da interface;
`Scenario_NilHandle_AllMembers_Raises` em `UScenarios.RTTI.pas` com cinco blocos
try/except verificando mensagem por `Pos`; desbloqueio D-44.6 em
`Scenario_PointerType_ReferredType_Nil_ForBarePointer`; duas cascas de uma linha (FPC e Delphi).

**Ciclo 021** — MAESTRO MODE. A issue #56 é a demanda oficial deste ciclo
(intake do maestro: `aefos:running`). Nenhuma issue ou Epic adicional criada.
Demanda: estender o contrato de nil-handle da #49 para `TModernRTTIType.Attributes`
— inserir guarda `if FType = nil then raise EModernRTTIError.CreateFmt(SModernRTTINilHandle, ['Attributes'])`
como primeira instrucao de `PropAttributes` (antes do `// Issue #27:` e do
`if (FType is TRttiInstanceType)`); uniformizar os cinco blocos existentes em
`Scenario_NilHandle_AllMembers_Raises` (trocar `Pos` por igualdade estrita da
mensagem); inserir sexto bloco para `Attributes` apos o quinto. Dois arquivos,
commit unico, build FPC 3.2.2 x86_64. Nenhuma `resourcestring` nova — `SModernRTTINilHandle`
ja existe em linha 892.

**Ciclo 017** — MAESTRO MODE. A issue #44 é a demanda oficial deste ciclo
(intake do maestro: `aefos:running`). Nenhuma issue ou Epic adicional criada.
Demanda: implementar `TModernRTTIPointerType` — record público em
`Source/ModernSyntax.RTTI.pas` com `strict private FToken: PTypeInfo`, factory
`FromTypeInfo` sem guarda de Kind e property `ReferredType: TModernRTTIType`;
backend FPC com `PointerTypeReferredType` usando property `RefType`, guarda por
Kind, `resourcestring SPointerWrongKind` e comentário `MUTACAO OBRIGATORIA`
prescrevendo `PTypeInfo(GetTypeData(P)^.RefTypeRef)` com cast; backend Delphi com
paridade via `TRttiPointerType(...).ReferredType` sem `is` nem `try/except` extra;
fixture `PInt44 = ^Integer`; dois cenários compartilhados; duas procedures em cada
casca; mutação verificada. Fecha `Closes #44`; parte de `#29`. Build FPC 3.2.2
x86_64 e i386 obrigatório.
