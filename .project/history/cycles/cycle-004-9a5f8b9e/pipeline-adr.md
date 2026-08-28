---
type: adr
kind: artifact
title: "ADR — Design de Source/ModernSyntax.RTTI.pas (Pilar 1 da ModernRTTI)"
description: "Decisões arquiteturais para a unit de leitura de RTTI: TModernRTTI + TModernRTTIType/Property/Field, API de valor genérica, contexto próprio, detecção obrigatória de {$M+} ausente no FPC, e reutilização da convenção de testes fixada no cycle-003."
status: draft
cycle: "004"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/9a5f8b9e974c23d88b7b6aba11e2973d
tags: [adr, modernrtti, rtti, pilar-1, fpc, delphi, issue-8]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-08-28T00:00:00Z"
sources:
  - id: prd
    resource: "../strategy/2026-08-27-modernrtti/PRD.md"
    title: "ModernRTTI PRD"
  - id: study
    resource: "../strategy/2026-08-27-modernrtti/STUDY.md"
    title: "ModernRTTI STUDY"
  - id: adr7
    resource: "../history/cycles/cycle-003-92fccbce/pipeline-adr.md"
    title: "ADR cycle-003 — convenções da família ModernRTTI"
  - id: arch
    resource: "../analysis/03-architecture.md"
    title: "03 Architecture — ModernSyntax"
  - id: conv
    resource: "../analysis/05-conventions.md"
    title: "05 Convenções — ModernSyntax"
---

# ADR — Design da unit ModernSyntax.RTTI (Pilar 1)

> Investigation report: **PRESENT** (run `6326ac737a7550e0c239b5b28be40624`,
> comentário na issue #8). Este ADR **deriva** desse relatório e restaura
> as decisões nos mesmos termos em que a discussão as fechou. Onde este
> ADR **estende** o relatório, é para fixar as convenções que a família
> ModernRTTI já herdou do cycle-003 (issue #7) e para deixar explícito
> o contrato de ownership. Não há divergência silenciosa: se este ADR
> discorda de algo do relatório, está dito com todas as letras (não há
> nenhum caso aqui).

## Contexto

O PRD ([ModernRTTI](/strategy/2026-08-27-modernrtti/PRD.md)) organiza a
entrega em três pilares. Este é o **Pilar 1**: leitura de RTTI com a
mesma API nos dois compiladores. As convenções transversais (diretório
`Test Shared/`, FPCUnit no lado FPC, casca fina de teste, sem `{$I
ModernSyntax.inc}` na unit nova) foram fixadas no cycle-003 pelo
[ADR da issue #7](/history/cycles/cycle-003-92fccbce/pipeline-adr.md)
e valem sem revisão para toda a família.

Medido no [STUDY](/strategy/2026-08-27-modernrtti/STUDY.md): o projeto
tem **zero** chamadas a `GetProperties`/`GetFields`/`TRttiProperty`/
`TRttiField` em `Source/*.pas`. O único ponto de RTTI vivo é
`TModernObject.Factory` (`Source/ModernSyntax.Objects.pas:208-241`),
que só invoca construtor. A entrega é 100% aditiva.

## Decisões

### D-1 — Nome da unit e entry point: `Source/ModernSyntax.RTTI.pas`, `TModernRTTI`

Unit `Source/ModernSyntax.RTTI.pas`, entry point `TModernRTTI` (record
com `class function GetType`).

**Motivo (relatório, volta 1).** Segue a convenção `ModernSyntax.<Assunto>.pas`
observada em 16/16 units da produção (D-1 do STUDY).

**Descartado — `ModernSyntax.ModernRTTI.pas`:** repete a palavra
"Modern" sem acrescentar informação, quebra a economia da convenção.

**Descartado — `ModernRTTI.pas` (sem prefixo):** quebra a convenção
`ModernSyntax.*.pas` em 16/16 units. Nunca esteve seriamente em jogo.

### D-2 — Três wrappers `record`, campo `strict private`

```pascal
type
  TModernRTTIField = record
  strict private
    FField: TRttiField;
    // ...
  end;

  TModernRTTIProperty = record
  strict private
    FProp: TRttiProperty;
    // ...
  end;

  TModernRTTIType = record
  strict private
    FType: TRttiType;
    // ...
  end;

  TModernRTTI = record
  strict private
    class var FContext: TRttiContext;
    // ...
  public
    class function GetType(AClass: TClass): TModernRTTIType; overload; static;
    class function GetType(ATypeInfo: PTypeInfo): TModernRTTIType; overload; static;
  end;
```

**Motivo.** Records como handles leves eliminam a necessidade de gestão
de ciclo de vida por parte do consumidor (RN-6 do [esp](pipeline-esp.md)); segue
`/analysis/05-conventions.md` §1.4 (`strict private` para campos de
implementação). O uso de `TRttiType` como campo — em vez de expor o
tipo cru — é o que permite acrescentar a verificação R4 sem afetar a
API pública.

**Descartado — expor `TRttiType`/`TRttiProperty`/`TRttiField` direto:**
vaza a implementação, obriga o consumidor a `uses Rtti` e reintroduz
o warning `experimental` do FPC 3.2.2 (R1 do PRD) no consumidor.

### D-3 — API de valor: **genéricos** como caminho principal, `TValue` como escape hatch

```pascal
function TModernRTTIProperty.GetValue<T>(const AInstance: TObject): T;
procedure TModernRTTIProperty.SetValue<T>(const AInstance: TObject; const AValue: T);

/// <remarks>Escape hatch: obriga o consumidor a importar Rtti (marcada
/// experimental no FPC 3.2.2). Prefira o overload genérico.</remarks>
function TModernRTTIProperty.GetValue(const AInstance: TObject): TValue; overload;
procedure TModernRTTIProperty.SetValue(const AInstance: TObject; const AValue: TValue); overload;
```

Idem para `TModernRTTIField`.

**Motivo (relatório, volta 1).** Duas razões medidas:
(a) `TValue` como caminho principal obriga o consumidor a `uses Rtti`,
vazando a implementação pela API pública; (b) `Rtti` no FPC 3.2.2 é
marcada `experimental` — o compilador emite `Warning: Unit "Rtti" is
experimental` a cada build. Uma camada de absorção não pode arrastar
o consumidor para dentro da unit instável de um dos compiladores.

**Descartado — expor `TValue` como caminho principal:** ver acima.
Overload `TValue` fica como escape hatch documentado — o consumidor
que optar por usá-lo escolhe conscientemente pagar o custo.

**Risco assumido (RSK-2 do [esp](pipeline-esp.md)).** `TValue.AsType<T>` no FPC
3.2.2 tem limitações reais (motivo do `experimental`). Se `AsType<T>`
falhar para algum `T` não trivial (record customizado, generic
aninhado), o overload `TValue` cru passa a ser o caminho recomendado
para esses tipos — decisão do autor no primeiro build FPC (R2 do PRD).
Não bloqueia o design; testa-se `Integer`, `string` e um record simples
(CA-3 do esp).

### D-4 — Retorno: `TArray<TModernRTTIProperty>` / `TArray<TModernRTTIField>`, com contrato de ownership

`GetProperties` e `GetFields` devolvem `TArray<...>`. Contrato de
ownership em `/// <remarks>` (mesmo padrão do `TResultPair.Dispose` da
#7):

> Ownership: `TModernRTTIType`, `TModernRTTIProperty` e
> `TModernRTTIField` são handles leves que apontam para dados de
> `TRttiContext` mantido em `class var TModernRTTI.FContext`. O
> contexto é criado em `initialization` e liberado em `finalization` de
> `ModernSyntax.RTTI`. O consumidor **não deve** reter essas
> referências após shutdown do binário (comportamento de fim de
> processo é undefined). Dentro da vida da aplicação, o array retornado
> por `GetProperties`/`GetFields` é seguro para uso, iteração e
> armazenamento — nenhum `Free` do consumidor é necessário nem
> permitido.

**Motivo (relatório, volta 1).** `for … in TArray<T>` já funciona nos
dois compiladores. Enumerator adicionaria tipo público, arquivo e
docs XML por ganho puramente estético — custo real por benefício zero.

**Descartado — `TEnumerator<TModernRTTIProperty>`:** ver acima.

### D-5 — Contexto RTTI próprio da unit; **não** reusa `TModernObject.FContext`

`TModernRTTI` declara `class var FContext: TRttiContext`, cria em
`initialization` e libera em `finalization` — mesmo padrão de
`Source/ModernSyntax.Objects.pas:195,601`.

**Motivo (relatório; C-3 do STUDY).** Importar `ModernSyntax.Objects`
para reusar seu `FContext` (`Objects.pas:41`) arrastaria transitivamente
`SyncObjs`, `Variants`, `Classes` e `TProc<T>` (`Objects.pas:340`, ilegal
no FPC 3.2.2). A unit **é** a fundação para Delphi+FPC — não pode
depender de uma unit 100% Delphi.

**Descartado — reusar `TModernObject.FContext`:** ver acima.

**Descartado — receber o contexto por parâmetro em `GetType`:** empurra
gestão de ciclo de vida para o consumidor, contrariando o contrato de
ownership (D-4).

### D-6 — Ausência de `{$M+}` no FPC: exceção **sempre**, mensagem instrutiva

Dentro de `TModernRTTIType.GetProperties`, se `FType.GetProperties`
volta vazio, `FType is TRttiInstanceType`, a classe não é `TObject`, e
`PTypeData(GetTypeData(FType.Handle))^.PropCount == 0` (ou análogo
portável), levantar `EModernRTTIError` com mensagem instrutiva
**uniforme nos dois compiladores** (rascunho para ratificação do dono):

> A classe %s não expõe propriedades à RTTI. No Delphi isso indica
> ausência real de propriedades `public`/`published`; no FPC exige
> `{$M+}` antes da declaração da classe e uma seção `published` com
> as propriedades desejadas. Adicione ambos e recompile.

**Motivo (relatório, volta 1).** Uma leitura falha "vestida de nada"
é exatamente a classe de defeito que a família ModernRTTI existe para
prevenir. Opt-in transfere para o consumidor a obrigação de lembrar de
uma diferença entre compiladores — o oposto do CA-5 do PRD. E a
mensagem tem de **dizer o que fazer**, não só o que houve.

**Descartado — opt-in (parâmetro `AStrict`):** transferir a decisão
para o consumidor recria a assimetria entre compiladores que o CA-5
existe para eliminar.

**Descartado — retornar lista vazia silenciosa no FPC quando falta
`{$M+}`:** viola R4 do PRD explicitamente.

**Pendência (dono ratifica).** Mensagem unificada (uma string) vs.
duas mensagens ramificadas por `{$IFDEF FPC}` no `raise`. Recomendação
do arquiteto: unificar. Ramificar é permitido (D-2 do PRD só proíbe
`{$IFDEF FPC}` no consumidor), mas custa manutenção sem ganho claro.

### D-7 — `{$IFDEF FPC}` direto, sem `{$I ModernSyntax.inc}`

A unit escreve `{$IFDEF FPC} ... {$ELSE} ... {$ENDIF}` diretamente e
**não inclui** `ModernSyntax.inc`.

**Motivo (R3 do PRD, medido).** `Source/ModernSyntax.inc:256` tem
`{$IFDEF FCP}` (letras trocadas — o símbolo do FPC é `FPC`). O bloco
Lazarus nunca disparou; o comentário que documenta isso existe **apenas
na branch `main`** — na `develop`, que é a base de trabalho, ele não
está. Qualquer unit que inclua o `.inc` herda o bug enquanto ele não
for corrigido, e a correção está **fora** desta linha (fora do escopo
do PRD ModernRTTI).

**Descartado — corrigir o `.inc` neste ciclo:** expande a mudança sem
necessidade e mistura duas linhas de trabalho independentes. Já foi
recusado no [adr #7 D-A5](/history/cycles/cycle-003-92fccbce/pipeline-adr.md).

### D-8 — `uses` da `interface`: `Rtti, TypInfo, SysUtils`

Nada de `Windows`, `Classes`, `Variants`, `SyncObjs`. Nada de importar
outra unit da própria biblioteca.

**Motivo (relatório).** A unit precisa de:
- `Rtti` — `TRttiContext`, `TRttiType`, `TRttiProperty`, `TRttiField`,
  `TValue`.
- `TypInfo` — `PTypeInfo`, `GetTypeData`, `TTypeData` (mecanismo R4).
- `SysUtils` — `Exception`, `Format`.

Qualquer unit adicional da biblioteca reintroduz o `.inc` ou uma
dependência Delphi-only (C-3 do STUDY).

### D-9 — Convenção de teste: herdada do cycle-003, **sem revisão**

- Cenários em `Test Shared/EclbrSystem/UScenarios.RTTI.pas` — sem
  framework, classes de fixture com `{$M+}` + `published` no próprio
  arquivo.
- Casca fina Delphi em `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` —
  DUnitX, uma linha útil por método `[Test]`.
- Casca fina FPC em `Test FPC/EclbrSystem/UTestMS.RTTI.pas` — FPCUnit,
  uma linha útil por `procedure Test*`.
- Runner Delphi: `PTestRTTI.dpr` + `.dproj`, entrada em
  `TestMSGroup.groupproj` (13 → 14) e em `DCC.bat` (13 → 14).
- Runner FPC: **entra no `.lpi` versionado pela #7** — este ciclo
  edita o `.lpi` da #7, não cria um novo.

**Motivo.** Convenção fechada no
[adr #7 D-A7/D-A8](/history/cycles/cycle-003-92fccbce/pipeline-adr.md),
que declarou explicitamente valer para **toda a família ModernRTTI**.
Reabrir essa decisão nesta issue seria refazer trabalho já decidido.

**Divergência declarada do texto original da issue #8:** a issue diz
"testes DUnitX" e "adicionados ao projeto Lazarus criado na issue de
Callbacks". O ciclo anterior desta mesma #8 interpretou isso como
"criar `.lpi` importando DUnitX", commitou `06fccea`, e o PR foi
fechado sem merge — DUnitX não existe no FPC 3.2.2 e não está
vendorizado. A decisão em vigor é FPCUnit no lado FPC (medido:
`fpcunit.ppu` em `units/x86_64-win64/fcl-fpcunit/`).

**Descartado — criar `.lpi` próprio desta issue:** invadiria o escopo
da #7 e repetiria o defeito do ciclo anterior.

**Descartado — DUnitX no lado FPC via vendor:** custo desproporcional
para um wrapper de leitura de RTTI.

### D-10 — Nome dos arquivos de teste

- `Test Shared/EclbrSystem/UScenarios.RTTI.pas` — nome que o relatório
  usa. Observe a **divergência de nomenclatura** com a #7, que
  escolheu `UTestMS.Callback.Scenarios.pas`. O relatório desta issue
  registra o nome `UScenarios.RTTI.pas` e é o que este ADR adota; se o
  dono preferir uniformizar com o padrão da #7 (`UTestMS.RTTI.Scenarios.pas`),
  é rename mecânico de zero risco e cabe no mesmo commit. Registrado
  como pendência opcional em §"Perguntas em aberto".
- `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` — casca DUnitX, padrão
  `UTestMS.<Feature>.pas` (`/analysis/05-conventions.md` §1.2).
- `Test Delphi/EclbrSystem/PTestRTTI.dpr` — runner, padrão
  `PTest<Feature>.dpr` (§1.2).
- `Test FPC/EclbrSystem/UTestMS.RTTI.pas` — casca FPCUnit, mesmo nome
  do lado Delphi (D-A8 do adr #7 — diretório espelhado).

### D-11 — Prefixo de interface — **fora do escopo desta issue**

Pilar 1 **não introduz interface pública** (só records e uma exceção).
A decisão de prefixo (`IMS` / `IModern` / bare `I*`) — em aberto — não
afeta este entregável, mas **trava** a próxima issue da família que
introduzir interface (Pilar 2 pode introduzir; Pilar 3 quase certamente
introduz).

**Medições registradas** (do relatório): em 9 interfaces públicas de
`Source/*.pas`, **7 bare `I*`** (`IAutoLock`, `IScheduler`, `ICleanup`,
`INumeric<T>`, `ISmartPtr<T>`, `IAutoRefLock`, `ITupleDict<K>`),
**1 `IModern*`** (`IModernObject`), **1 `IMS*`** (`IMSObserver`,
código morto em `Source/ModernSyntax.pas:27`).

**Nota de coerência de família.** A #7 escolheu `IModern*` no
[adr #7 D-A9](/history/cycles/cycle-003-92fccbce/pipeline-adr.md).
Recomendação: alinhar com `IModern*` se e somente se o dono ratificar
como padrão prospectivo da família — não como inferência silenciosa
sobre um único precedente vivo.

### D-12 — Ligação com pilares subsequentes

Este ADR **não decide**:

- Como `ModernAttributes.Register` (Pilar 2) e `GetAttributes` unificarão
  origens `[MyAttr]` nativo (Delphi) e `Register` (FPC). Vem em ADR
  próprio da issue do Pilar 2.
- Como `TModernInvoker` (Pilar 3) se relaciona com `TModernRTTI.FContext`.
  Vem em ADR próprio da issue do Pilar 3. Q1 do PRD ("`TRttiMethod.Invoke`
  do FPC é igual à do Delphi?") não é medida aqui.

**Motivo.** Cada pilar é uma issue autônoma no PRD. Decidir por antecipação
o Pilar 2/3 aqui seria trabalho não pedido e não medido.

## Perguntas em aberto (do relatório, e uma acrescentada)

Não são decisões deste ADR — são medições a fazer em implementação, ou
ratificações do dono:

- **Texto exato da mensagem da `EModernRTTIError` (R4).** Rascunho em
  D-6. Sub-decisão: unificar ou ramificar por compilador. Recomendação:
  unificar. **Dono ratifica.**
- **Prefixo de interface da família ModernRTTI** (`IModern*` vs bare
  `I*` vs `IMS*`). **Dono decide** — não bloqueia esta issue, trava a
  próxima. Medições em D-11.
- **Portabilidade real da verificação `PropCount == 0` como sinal de
  `{$M+}` ausente no FPC 3.2.2.** O implementador confirma no primeiro
  build FPC (R2 do PRD). Se precisar de variação, ela vive **dentro
  da unit** (CA-5 preservado).
- **Limitações de `TValue.AsType<T>` no FPC 3.2.2 para T não trivial.**
  Se `AsType<T>` falhar, o overload `TValue` cru vira o caminho
  recomendado para esses tipos — decisão do autor no primeiro build
  FPC (R2 do PRD). Não bloqueia o design.
- **Nomenclatura opcional do arquivo de cenários** — `UScenarios.RTTI.pas`
  (adotado) vs `UTestMS.RTTI.Scenarios.pas` (padrão da #7). Rename
  mecânico se o dono preferir alinhar. **Não bloqueia.** Ver D-10.

## Consequências

- Consumidor escreve `ModernRTTI.GetType(TFoo).GetProperties` nos dois
  compiladores, com **a mesma linha**. Cumpre CA-1 do [esp](pipeline-esp.md) e do
  PRD.
- Consumidor de `GetValue<T>`/`SetValue<T>` não importa `Rtti` e não vê
  o warning `experimental` do FPC. Cumpre R1 do PRD como camada de
  absorção.
- Zero mudança em `Source/ModernSyntax.Objects.pas` (D5 do PRD) e em
  `Source/ModernSyntax.inc` (R3 do PRD). Entrega 100% aditiva sobre
  código de produção; nenhuma regressão possível nas 431 asserts
  existentes (medição do STUDY).
- `TestMSGroup.groupproj` e `DCC.bat` ganham uma entrada cada (13 → 14).
  Efeito colateral: o grupo passa a compilar `PTestRTTI` — mitigado
  pela ordem de commit (só adicionar depois de compilar o `.dpr`
  isoladamente).
- A convenção de teste da família (D-A7/D-A8 do adr #7) fica **reforçada**:
  Pilar 2 e Pilar 3 herdarão o mesmo desenho sem reabertura.
- Contrato de ownership (D-4) fica público e documentado. Zero
  consumidores hoje, mas define o comportamento esperado da família
  ModernRTTI daqui para frente.
- Dependência de ordem: esta issue **precisa** que a #7 mergeie para
  CA-7 e CA-10 fecharem. Se não mergear, o PR declara o bloqueio e
  segue com Delphi compilado (CA-8 modificado). Não é regressão — é
  falta de infra alheia.
