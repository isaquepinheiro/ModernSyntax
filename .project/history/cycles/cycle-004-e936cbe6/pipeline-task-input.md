---
type: task-input
kind: artifact
title: "Task input — implementar Source/ModernSyntax.Attributes.pas e as duas cascas de teste"
description: "Handoff operacional para o implementador: criar a unit de atributos portáveis com registry + fusão nativo/registrado (regra 2 do ADENDO), a unit comum de cenários, e as duas cascas finas (DUnitX + FPCUnit) com projetos .dproj e .lpi."
status: draft
cycle: "004"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/e936cbe6a17a8e76ec8ca9a02ec30735
tags: [task-input, modernrtti, attributes, issue-9, feature]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-08-28T13:30:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — Atributos portáveis"
  - id: adr
    resource: "adr.md"
    title: "ADR — Design da unit ModernSyntax.Attributes"
  - id: plan
    resource: "plan.md"
    title: "Plan — Atributos"
---

# Task input — Atributos portáveis (issue #9)

**Issue:** [isaquepinheiro/ModernSyntax#9](https://github.com/isaquepinheiro/ModernSyntax/issues/9)
**Tipo:** feature
**Labels:** `feature`, `aefos:running`

## Objetivo (uma frase)

Criar `Source/ModernSyntax.Attributes.pas` com `TModernAttribute` (base obrigatória para
atributos portáveis) e o record `ModernAttributes` com `Register` e `GetAttributes`, unificando
atributos nativos Delphi e registrados, com **regra 2 do ADENDO** (registrado prevalece por
classe) fazendo CA-2 do PRD valer na letra; testes cobrindo os dois compiladores via unit
compartilhada + duas cascas finas.

## Divergências / esclarecimentos **declarados** do texto da issue

- **CA-2 na letra** (`ModernRTTI.GetType(T).GetAttributes`) — não é entregue por esta issue.
  A API pública desta entrega é `ModernAttributes.GetAttributes(TFoo)`. A fachada `ModernRTTI`
  é entregável da issue #8 (Pilar 1), que delegará para `ModernAttributes.GetAttributes`. Não
  é CA-2 diluído — é ordem de entrega. **Declarar no corpo do PR em voz alta.**
- **Regra 2 do ADENDO** (`GetAttributes` no Delphi descarta a instância nativa se `Owned`
  contém instância da mesma classe) **é parte integral desta issue**, não opcional. Sem ela,
  o cenário "prova viva de CA-2" quebra o próprio CA-2. Ver [adr.md, D-A6](pipeline-adr.md).

## Escopo

Ver [esp.md](pipeline-esp.md) seções 2 e 3. Em resumo:

- Uma unit nova em `Source/ModernSyntax.Attributes.pas`.
- Um `.inc` de símbolos em `Test Shared/EclbrSystem/UTestMS.Attributes.Symbols.inc`.
- Uma unit comum de cenários em `Test Shared/EclbrSystem/UTestMS.Attributes.Scenarios.pas`.
- Uma casca fina DUnitX + `.dpr` + `.dproj` em `Test Delphi/EclbrSystem/`.
- Uma casca fina FPCUnit + `.lpi` + `.lpr` em `Test FPC/EclbrSystem/`.

**Fora deste ciclo:**

- Fachada `ModernSyntax.RTTI.pas` (entregável da issue #8).
- Obrigar `Register` no Delphi para atributos que já têm sintaxe nativa (recusado por D1 do
  PRD).
- Correção do bug `{$IFDEF FCP}` em `ModernSyntax.inc:256` (R3 do PRD).
- Adicionar `PTestAttributes` ao `Test Delphi/EclbrSystem/DCC.bat` (gap conhecido pós-entrega).

## Checklist de aceite

### Unit de produção

- [ ] `Source/ModernSyntax.Attributes.pas` criado. Header MIT em `(* ... *)`
  (R-Comment-Nest / [adr D-A10](pipeline-adr.md)). Sem `{$I ModernSyntax.inc}`. Sem token `FCP`.
- [ ] `uses` da `interface`: `SysUtils, Generics.Collections, SyncObjs {$IFNDEF FPC}, Rtti{$ENDIF};`.
- [ ] `TModernAttribute = class(TObject)` no FPC; `TModernAttribute = class(TCustomAttribute)`
  no Delphi ([adr D-A2](pipeline-adr.md)).
- [ ] `TAttributeRecord = record Owned: TArray<TObject>; end;` **na interface**
  ([adr D-A9](pipeline-adr.md), R-FPC-Generic).
- [ ] `ModernAttributes = record` com duas class functions estáticas: `Register` e
  `GetAttributes`. `GetAttributes` documentado por XMLDoc com o contrato "vista emprestada"
  exato ([esp RN-5](pipeline-esp.md)).
- [ ] Registry: `TDictionary<TClass, TAttributeRecord>` com `TCriticalSection` protegendo
  ambas as operações ([adr D-A3](pipeline-adr.md)).
- [ ] `TRttiContext` **próprio da unit** (não reutiliza `Objects.pas`), criado na
  `initialization` e liberado na `finalization` **apenas no Delphi**.
- [ ] `Register`: append com dedup por **identidade de referência**; se uma instância
  duplicada chega, `Register` **libera a duplicata** (o consumidor não deve depender da
  extra continuar viva).
- [ ] `GetAttributes` no FPC: cópia de `Owned` ou array vazio.
- [ ] `GetAttributes` no Delphi: `Owned + Native filtrado`, onde uma instância nativa é
  descartada se `Owned` contém alguma com a mesma `ClassType` (**regra 2 do ADENDO**,
  [adr D-A6](pipeline-adr.md)). Retorna sempre `defined`; ausência = `Length = 0`.
- [ ] `finalization`: libera **apenas** `Owned` de cada `TAttributeRecord`; depois
  `FRegistry.Free`, `FLock.Free`, `FContext.Free` (o último só no Delphi).

### Cenários compartilhados

- [ ] `Test Shared/EclbrSystem/UTestMS.Attributes.Symbols.inc` existe, com exatamente:
  ```
  {$IFDEF FPC}{$DEFINE NO_NATIVE_ATTRS}{$ELSE}{$DEFINE HAS_NATIVE_ATTRS}{$ENDIF}
  ```
- [ ] `Test Shared/EclbrSystem/UTestMS.Attributes.Scenarios.pas` existe, sem `{$IFDEF}`,
  sem `uses` de framework de teste. Contém as classes de atributo de teste (`TMyAttr`,
  `TOtherAttr`) declaradas localmente.
- [ ] Cenários implementados (uma procedure por caso, exceção na falha):
  `Scenario_Register_ThenGetAttributes_ReturnsRegistered`,
  `Scenario_GetAttributes_NeverRegistered_ReturnsEmpty`,
  `Scenario_Register_SameInstanceTwice_IsDeduplicated`,
  `Scenario_Register_TwoInstances_BothAppear`,
  `Scenario_NativePlusRegister_IsIdentical`.

### Casca Delphi

- [ ] `Test Delphi/EclbrSystem/UTestMS.Attributes.pas` criado. Abre com:
  ```
  {$I UTestMS.Attributes.Symbols.inc}
  {$IF NOT DEFINED(HAS_NATIVE_ATTRS) AND NOT DEFINED(NO_NATIVE_ATTRS)}
    {$MESSAGE FATAL 'UTestMS.Attributes.Symbols.inc nao foi incluido'}
  {$IFEND}
  ```
- [ ] `[TestFixture] TAttributesTests` com um `[Test]` por cenário compartilhado; cada
  método tem **até uma linha útil** que chama o cenário.
- [ ] Dois testes Delphi-only atrás de `{$IFDEF HAS_NATIVE_ATTRS}`:
  `TestDelphi_NativeAlone_NoRegister_ReturnsNonEmpty` (usa classe local com `[TMyAttr(...)]`)
  e `TestDelphi_NativeSuppressedByRegistered_ReturnsRegisteredOnly` (prova a regra 2 do
  ADENDO).
- [ ] `PTestAttributes.dpr` criado no padrão de `PTestObjects.dpr`, com
  `ReportMemoryLeaksOnShutdown := True;` no início do `begin ... end.`.
- [ ] `PTestAttributes.dpr` **não** contém `{$IFNDEF FPC}` nem `{$MESSAGE FATAL}` (a guarda
  vive na casca `.pas`).
- [ ] `PTestAttributes.dproj` inclui `..\..\Test Shared\EclbrSystem` em `<DCC_UnitSearchPath>`
  (ou o campo equivalente — **sintaxe exata é verificação pendente**, o autor confirma).

### Casca FPC

- [ ] `Test FPC/EclbrSystem/UTestMS.Attributes.pas` criado, abre com o mesmo `{$I}` +
  guarda `{$MESSAGE FATAL}` da casca Delphi.
- [ ] `TAttributesTests = class(TTestCase) published` com um método por cenário
  compartilhado, cada um com uma linha útil.
- [ ] Um teste FPC-only atrás de `{$IFDEF NO_NATIVE_ATTRS}`:
  `TestFPC_NativeAlone_NoRegister_ReturnsEmpty`.
- [ ] `initialization RegisterTest(TAttributesTests);`.
- [ ] `PTestAttributes.lpr` usa `consoletestrunner`; `uses UTestMS.Attributes,
  UTestMS.Attributes.Scenarios, ModernSyntax.Attributes;`.
- [ ] `PTestAttributes.lpi` tem dois build modes (`Debug-i386` e `Debug-x86_64`);
  `<OtherUnitFiles>` aponta para `../../Source` e `../../Test Shared/EclbrSystem`;
  `<CompilerOptions><Parsing><IncludeFiles>` contém
  `-Fi"$(ProjPath)../../Test Shared/EclbrSystem"`.

### Verificação por grep (aceitação final)

- [ ] `grep -rn '{\$IFDEF FPC}' 'Test Shared/EclbrSystem/UTestMS.Attributes.Scenarios.pas' 'Test Delphi/EclbrSystem/UTestMS.Attributes.pas' 'Test FPC/EclbrSystem/UTestMS.Attributes.pas'`
  → **0** (CA-4 do esp; CA-5 do PRD).
- [ ] `grep -n '{$I ModernSyntax.inc}' Source/ModernSyntax.Attributes.pas` → **0**.
- [ ] `grep -n 'FCP' Source/ModernSyntax.Attributes.pas` → **0**.
- [ ] `grep -rn 'DUnitX' 'Test FPC/EclbrSystem/'*.pas 'Test FPC/EclbrSystem/'*.lpr` → **0**.

### PR body (mandatório)

- [ ] Declaração de compilação: *"compilado em FPC 3.2.2 x86_64 e i386; não compilado em
  Delphi — Delphi permanece com o autor."*
- [ ] Linha de fronteira: *"atributo portável TEM de passar por `Register`; `[MyAttr]`
  nativo sozinho é conveniência Delphi e não atravessa. Quando ambos coexistem, o registrado
  prevalece por classe (regra 2 do ADENDO)."*
- [ ] Ordem de entrega: *"CA-2 na letra (`ModernRTTI.GetType(T).GetAttributes`) fica para a
  issue #8 delegar — esta issue entrega implementação; a #8 entrega fachada."*
- [ ] Verificações pendentes do lado Delphi listadas: (a) `[MyAttr]` aceita descendente
  transitivo de `TCustomAttribute`; (b) sintaxe exata do `.dproj` para "Search path" de
  include; (c) `TRttiType.GetAttributes` devolve instância nova ou mesma referência entre
  chamadas.

## Arquivos prováveis impactados

**Criados (novos):**

- `Source/ModernSyntax.Attributes.pas`
- `Test Shared/EclbrSystem/UTestMS.Attributes.Symbols.inc`
- `Test Shared/EclbrSystem/UTestMS.Attributes.Scenarios.pas`
- `Test Delphi/EclbrSystem/UTestMS.Attributes.pas`
- `Test Delphi/EclbrSystem/PTestAttributes.dpr` (+ `.dproj` + `.res`)
- `Test FPC/EclbrSystem/UTestMS.Attributes.pas`
- `Test FPC/EclbrSystem/PTestAttributes.lpr`
- `Test FPC/EclbrSystem/PTestAttributes.lpi`

**Não tocar nesta issue:**

- `Source/ModernSyntax.RTTI.pas` — entregável da issue #8.
- `Source/ModernSyntax.Objects.pas` — evita acoplamento (D-A1 do adr).
- `Source/ModernSyntax.inc` — bug do `FCP` fica para outra linha (R3 do PRD).
- `Test Delphi/EclbrSystem/DCC.bat` — gap conhecido pós-entrega.
- Nenhuma unit de `Source/` existente é modificada (o Pilar 2 é extensão pura; `grep`
  medido no relatório = zero atributos hoje).

## Notas de implementação

- **`uses` da unit nova:** somente `SysUtils`, `Generics.Collections`, `SyncObjs`, e
  `Rtti` no Delphi. Não usar `Objects.pas` (custo transitivo).
- **Ramificação:** `{$IFDEF FPC} ... {$ELSE} ... {$ENDIF}` **direto** no arquivo, **jamais**
  via `{$I ModernSyntax.inc}` (R3 do PRD).
- **Regra 2 do ADENDO** é o coração desta entrega. Sem ela, o cenário "prova viva de CA-2"
  quebra CA-2. Implementar como filtro sobre `LNative` antes de concatenar com `LOwned`.
- **Ownership de duplicatas rejeitadas** (dedup por identidade): `Register` é declarado
  como "toma posse"; se uma instância que chegou já está por identidade em `Owned`, é a mesma
  referência — não há duplicata para liberar. Se o consumidor passar `[X, X]` (a mesma
  referência duas vezes no mesmo array), o loop de append encontra a primeira, adiciona;
  encontra a segunda, detecta dedup, **não faz nada** (a instância é a mesma que já está
  em `Owned`). Não há liberação em jogo.
- **XMLDoc no `GetAttributes`** — palavra por palavra o texto de RN-5 do esp: "O array
  retornado é uma vista emprestada. As instâncias não pertencem ao chamador; não libere.
  Elas são gerenciadas pela registry (para as registradas via `Register`) ou pelo
  `TRttiContext` interno (para as vindas de `[MyAttr]` nativo)."
- **Cascas devem ter apenas UMA linha útil** por caso. Se aparecer `if/then` de asserção
  na casca, é vazamento — volta a lógica para o `Scenarios.pas`.

## Dependências externas

- Nenhuma. Este ciclo cria o `.lpi` próprio dos testes desta unit; a convenção da família
  ModernRTTI (`Test FPC/EclbrSystem/` + `Test Shared/EclbrSystem/`) foi criada no ciclo #7
  e é reusada aqui.

## Verificação final (checklist de PR)

- [ ] Todas as verificações por grep acima retornam **0** ou o esperado.
- [ ] `lazbuild --build-mode=Debug-i386 "Test FPC/EclbrSystem/PTestAttributes.lpi"`
  (executado pelo orquestrador na máquina do autor) compila e roda os testes com sucesso.
- [ ] `lazbuild --build-mode=Debug-x86_64 "Test FPC/EclbrSystem/PTestAttributes.lpi"` idem.
- [ ] Delphi compila `PTestAttributes.dproj` (pelo autor); todos os testes DUnitX passam.
- [ ] `ReportMemoryLeaksOnShutdown` não reporta vazamento.
- [ ] Body do PR carrega as três declarações mandatórias acima.
