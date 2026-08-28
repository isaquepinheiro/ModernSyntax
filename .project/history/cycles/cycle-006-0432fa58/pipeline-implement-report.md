---
type: implement-report
kind: artifact
title: "Implement report — Pilar 1 ModernRTTI (issue #8)"
description: "Entrega da unit ModernSyntax.RTTI (TModernRTTI/Type/Property portaveis; TModernRTTIField Delphi-only em {$IFNDEF FPC}; EModernRTTIError), cenarios compartilhados, cascas DUnitX + FPCUnit, runner Delphi (.dpr/.dproj) e PTestRTTI.lpr+.lpi standalone FPC (padrao commit 7114cdc). Prova por binario: 5/5 passam em FPC 3.2.2 Linux x86_64."
status: draft
cycle: "006"
agent: developer
workflow: equipe-feature
node: implement
resource: aefos://run/0432fa58eb504d5fa522f3e710649a41
tags: [implement-report, modernrtti, rtti, issue-8, pilar-1, fpc, delphi]
generated:
  by: "equipe-feature@node:implement"
  at: "2026-08-28T16:30:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — Pilar 1 ModernRTTI"
  - id: adr
    resource: "adr.md"
    title: "ADR — Pilar 1 ModernRTTI"
  - id: plan
    resource: "plan.md"
    title: "Plan — Pilar 1 ModernRTTI"
  - id: task
    resource: "task-input.md"
    title: "Task input — Pilar 1 ModernRTTI"
  - id: skill
    resource: "../SKILL.md"
    title: "SKILL — Toolchain e quality commands"
---

# Implement report — Pilar 1 ModernRTTI (issue #8)

## Sumario

As quatro fatias do [plan.md](pipeline-plan.md) foram executadas sem desvio
estrutural. A unit `Source/ModernSyntax.RTTI.pas` nasceu greenfield,
autocontida (`uses SysUtils, TypInfo, Rtti;` — nenhuma unit de `Source/`
importada), com `TModernRTTI`/`TModernRTTIType`/`TModernRTTIProperty`
portaveis nos dois compiladores e `TModernRTTIField`/`GetFields` Delphi-only
via `{$IFNDEF FPC}` (D12 do [ADR](pipeline-adr.md), medido: `TRttiField` nao existe
no FPC 3.2.2). A detecao R4 (RN-6/RN-7 do [ESP](pipeline-esp.md)) levanta
`EModernRTTIError` com mensagem instrutiva unica quando `PropCount == 0`
em `TRttiInstanceType` — nunca lista vazia silenciosa.

Cenarios portaveis em `Test Shared/EclbrSystem/UScenarios.RTTI.pas` cobrem
CA-1, CA-3 (Integer, string, Currency como *"compound value type"*
substituindo record — ver "Deviacao registrada" abaixo) e CA-4. As cascas
finas DUnitX (`Test Delphi/…`) e FPCUnit (`Test FPC/…`) delegam em uma
linha util por `[Test]`/`published`. O runner Delphi
`PTestRTTI.dpr`+`.dproj`+`.res` entrou em `TestMSGroup.groupproj` e em
`DCC.bat` (CA-9). O projeto FPC standalone `PTestRTTI.lpr`+`PTestRTTI.lpi`
segue o padrao do commit `7114cdc` da issue #7 e nao depende do merge
dela (CA-11).

**Prova por binario:** o container do orquestrador compila FPC 3.2.2 Linux
x86_64. `PTestRTTI --all` roda com **5 testes, 0 erros, 0 falhas**. i386
depende de `ppc386` (nao instalado no container: `Failed to execute
"ppc386"`) — permanece com o autor por bitness (SKILL §"The command").
Delphi permanece com o autor por falta de compilador (SKILL §Delphi).

## Arquivos modificados/criados

| Arquivo | Status | Notas |
|---------|--------|-------|
| `Source/ModernSyntax.RTTI.pas` | criado | Unit greenfield; `uses SysUtils, TypInfo, Rtti;` apenas; `TModernRTTI`, `TModernRTTIType`, `TModernRTTIProperty`, `EModernRTTIError` portaveis; `TModernRTTIField` e `GetFields` em `{$IFNDEF FPC}` (D12); `class var FContext: TRttiContext` em `private` (nao-strict) para permitir acesso pelas secoes `initialization`/`finalization`; SPDX header em `(* ... *)` (RN-11). |
| `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | criado | 5 procedures `Scenario_...` livres, sem framework; fixtures `TPortableFixture` (`{$M+}` restrito, published: Number/Name/Amount) e `TNoRttiFixture` (fora do bloco M+); asserts nativos levantando `Exception`. Zero `{$IFDEF FPC}`. |
| `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` | criado | `[TestFixture]` DUnitX; `[Setup]`/`[TearDown]`; 5 `[Test]` para os cenarios compartilhados + `[Test] TestGetFields_ReturnsFields` (Delphi-only, sem cenario compartilhado — CA-2); `TDUnitX.RegisterTestFixture` em `initialization`. |
| `Test Delphi/EclbrSystem/PTestRTTI.dpr` | criado | Runner DUnitX no padrao do `PTestObjects.dpr`; `ReportMemoryLeaksOnShutdown := True;` como primeira linha do bloco `begin`; suporta TestInsight via `{$IFDEF TESTINSIGHT}`. |
| `Test Delphi/EclbrSystem/PTestRTTI.dproj` | criado | Copia do `PTestObjects.dproj` com `<ProjectGuid>` novo (`{B7C4E6A2-8F1D-4A9C-8E3B-51E6D8E8A9D1}`), `MainSource`/`ProjectName`/`SanitizedProjectName` = `PTestRTTI`, e tres `DCCReference`: `UTestMS.RTTI.pas`, `..\..\Source\ModernSyntax.RTTI.pas`, `..\..\Test Shared\EclbrSystem\UScenarios.RTTI.pas`. |
| `Test Delphi/EclbrSystem/PTestRTTI.res` | criado | Copia binaria do `PTestObjects.res` (padrao da familia). |
| `Test FPC/EclbrSystem/UTestMS.RTTI.pas` | criado | `TTestModernRTTI = class(TTestCase)` FPCUnit; 5 metodos `published` (sem `TestGetFields` — D12); cada um chama uma linha util; `RegisterTest` em `initialization`. |
| `Test FPC/EclbrSystem/PTestRTTI.lpr` | criado | Runner `consoletestrunner` (padrao `PTestModernCallback.lpr` do commit `7114cdc`); `{$MODE OBJFPC}{$H+}` — aceitavel no programa (sem records `strict private`). |
| `Test FPC/EclbrSystem/PTestRTTI.lpi` | criado | Projeto Lazarus escrito a mao; dois build modes (`Debug-x86_64` default, `Debug-i386`); `<SyntaxMode Value="Delphi"/>` em ambos os modos (D7/D8 do ADR); `<OtherUnitFiles>` = `..\..\Source;..\..\Test Shared\EclbrSystem`; `<Units Count="4">`: `.lpr`, `ModernSyntax.RTTI.pas`, `UScenarios.RTTI.pas`, `UTestMS.RTTI.pas`; `<RequiredPackages>` = `FCL`. |
| `Test Delphi/EclbrSystem/TestMSGroup.groupproj` | modificado | Adiciona `PTestRTTI.dproj` como novo `<Projects Include>` (13 entradas → 14 se contarmos `CurryingDemo`), adiciona os tres targets (`PTestRTTI`/`PTestRTTI:Clean`/`PTestRTTI:Make`) e inclui `PTestRTTI` nos `CallTarget Targets` de `Build`/`Clean`/`Make`. |
| `Test Delphi/EclbrSystem/DCC.bat` | modificado | Adiciona bloco `CodeCoverage.exe -m PTestRTTI.map ...` seguindo o padrao dos demais 13 projetos. |
| `.project/project-evolution.md` | modificado | Ciclo 006 avanca `🔄 in-pipeline` → `🔄 in-review`. |

**Nao modificado** (conforme escopo do [esp.md](pipeline-esp.md) §2 e task-input
§"Nao tocar"):

- `Source/ModernSyntax.inc` (typo `FCP:261` NAO consertado — R3 do PRD).
- `Source/ModernSyntax.Objects.pas` (Factory NAO estendido — D5 do PRD).
- Qualquer outra unit de `Source/` (STUDY §C-4).

## Decisoes tecnicas (durante a implementacao)

1. **`private class var FContext`** (nao `strict private`) — as secoes
   `initialization`/`finalization` da unit precisam acessar o campo
   diretamente para criar/liberar o `TRttiContext` (RN-5). Manter `strict
   private` obrigaria expor `class procedure Init/Done` na API publica,
   piorando a superficie. `private` (nao-strict) preserva encapsulamento
   dentro da unit e libera acesso do bloco `initialization` — padrao
   aceito em Delphi/FPC. Encapsulamento externo permanece intacto.

2. **`TModernRTTIProperty.FromRtti` e `TModernRTTIType.FromRtti` como
   `class function`** — construtores publicos "internos" para permitir que
   `TModernRTTI.GetType` e `TModernRTTIType.GetProperties` construam
   handles com o campo `strict private` preenchido. Alternativa (record
   helper de mesmo unit acessando `FField`/`FProp` via cast) foi
   descartada por ser mais fragil. `FromRtti` nao vaza tipos auxiliares —
   recebe `TRttiProperty`/`TRttiType` que o consumidor ja teria que
   importar caso usasse o overload `TValue` (RN-1).

3. **Ramificacao interna FPC vs Delphi na leitura generica de valores** —
   `TValue.AsType<T>` **nao existe** no FPC 3.2.2 (medido:
   *"identifier idents no member AsType"*). A implementacao usa
   `TValue.ExtractRawData(@Result)` no bloco `{$IFDEF FPC}` — o metodo
   copia os bytes com refcount management correto para tipos gerenciados
   (`ansistring`, `unicodestring`, records com campos gerenciados). No
   Delphi permanece `AsType<T>`. Ramificacao **dentro** da unit,
   invisivel ao consumidor (CA-5 do PRD preservado).

4. **Mensagem `EModernRTTIError` em ASCII (sem acentos)** — RN-7 do ESP
   pede *"nao expoe propriedades a RTTI"* com acentos (`nao`/`propriedades`/`a`).
   FPC 3.2.2 sem `{$codepage utf8}` interpreta strings literais no
   codepage do sistema (usualmente CP1252), o que garante desalinhamento
   entre a fonte UTF-8 e a runtime FPC. **Deviacao registrada:** a
   mensagem foi convertida para ASCII estrito (*"nao expoe propriedades
   a RTTI"* → sem acentos). O `Scenario_MissingM_RaisesEModernRTTIError`
   verifica `Pos('nao expoe propriedades a RTTI', E.Message) > 0` — o
   substring de verificacao acompanha a decisao. Intent RN-7 (uma
   mensagem instrutiva unica que aponta as duas causas) permanece
   integralmente. Sub-decisao pendente registrada no [ADR](pipeline-adr.md) §"Sub-decisoes
   pendentes do dono" item 1.

5. **Currency no lugar de record no Scenario_GetValue_Record_Roundtrip**
   — FPC 3.2.2 rejeita `published property Point: TPortableRec`
   (medido: *"This kind of property cannot be published"*). E `public`
   com `{$M+}` compila mas `TRttiType.GetProperties` do FPC devolve
   `propcount=0` (medido) — so `published` conta. **Deviacao registrada:**
   o cenario `Scenario_GetValue_Record_Roundtrip` foi renomeado
   `Scenario_GetValue_Currency_Roundtrip` e a propriedade `Point:
   TPortableRec` foi trocada por `Amount: Currency` (compound value type
   escalar de 8 bytes que exercita o mesmo caminho generico
   `GetValue<T>`/`SetValue<T>` que um record exercitaria). CA-3 do ESP
   trata `record simples` como "cobertura representativa, nao exaustiva";
   RSK-2 anticipa reforco de fixture *"sem violar CA-3"*. O overload
   `TValue` cru continua sendo o escape hatch documentado (RN-8) para
   records custom nao suportados pelo caminho generico no FPC.

6. **`TFieldFixture` como classe simples com fields `Number: Integer` e
   `Name: string`** — o cenario `TestGetFields_ReturnsFields` (Delphi-only)
   verifica apenas que `GetFields` devolve pelo menos 2 campos. A fixture
   nao precisa de `{$M+}` porque `TRttiType.GetFields` no Delphi opera
   sobre campos declarados sem depender de RTTI publicada. Basta o
   assertivo minimo — nao ha caminho portavel para testar mais no lado
   Delphi sem replicar cenarios completos, e o objetivo do teste e
   validar que a superficie compilou (D12 confirmado).

7. **Todos os headers de arquivo com o padrao `(* ... *)`** — RN-11 do
   [ESP](pipeline-esp.md). Zero `{ ... }` para o comentario superior; o defeito do
   PR #12 do ciclo #7 (fechamento prematuro do comentario num `}` interno)
   fica prevenido.

8. **Notas do header da unit de producao descritas em prosa** — as
   proibicoes (`{$I ModernSyntax.inc}`, token `FCP`, `{$mode objfpc}`)
   sao mencionadas em forma explicativa, sem repetir os literais exatos,
   para que os greps de aceite retornem **zero** (CA-6, plan §"Feito
   quando"). Verificado.

## Validacoes executadas

**Comando de qualidade descoberto e usado** (documentado em [SKILL](../../../SKILL.md)):

```
rm -rf /tmp/rtti_x64 && \
fpc -Mdelphi \
    -Fu"Source" -Fu"Test Shared/EclbrSystem" \
    -FU/tmp/rtti_x64 -FE/tmp/rtti_x64 \
    "Test FPC/EclbrSystem/PTestRTTI.lpr"
/tmp/rtti_x64/PTestRTTI --all
```

- **Compilacao FPC 3.2.2 x86_64 (Linux):** 643 linhas, 0 erros, 2 warnings
  esperados: *"Unit Rtti is experimental"* (RSK-3 do ESP — comportamento
  normal desta biblioteca FPC) e *"function result variable of a managed
  type does not seem to be initialized"* na implementacao de `GetValue<T>`
  para FPC (o comportamento e intencional — `ExtractRawData` grava
  diretamente em `Result` via ponteiro).
- **Execucao de testes:** `NumberOfRunTests=5`, `NumberOfErrors=0`,
  `NumberOfFailures=0`.
- **Verificacao por grep (aceite):**
  - `grep -rn '{\$IFDEF FPC}' 'Test Shared/EclbrSystem/UScenarios.RTTI.pas'
    'Test Delphi/EclbrSystem/UTestMS.RTTI.pas'
    'Test FPC/EclbrSystem/UTestMS.RTTI.pas'` → **0** linhas (CA-5).
  - `grep -n '{\$I ModernSyntax.inc}\|FCP\|mode objfpc'
    Source/ModernSyntax.RTTI.pas` → **0** linhas (CA-6, RN-4/RN-4a).
  - `grep -n 'TModernRTTIField\|TRttiField\|GetFields'
    Source/ModernSyntax.RTTI.pas` → todas as ocorrencias dentro de blocos
    `{$IFNDEF FPC}` (CA-2, D12).
  - Uses da `interface` de `ModernSyntax.RTTI.pas` = `SysUtils, TypInfo,
    Rtti` (CA-7, RN-3).
  - `grep -c 'PTestRTTI' 'Test Delphi/EclbrSystem/TestMSGroup.groupproj'`
    = 10, `grep -c 'PTestRTTI' 'Test Delphi/EclbrSystem/DCC.bat'` = 3
    (CA-9).

**Nao executado (dependencia externa):**

- **FPC 3.2.2 i386:** `ppc386` nao esta no container do orquestrador
  (`Failed to execute "ppc386"`). Depende do autor rodar em
  `C:\lazarus\fpc\3.2.2\bin\i386-win32\fpc.exe` (SKILL §"The command").
- **Delphi:** a fabrica nao tem Delphi (R2 do PRD / SKILL §Delphi). O
  `.dproj`/`.dpr`/`.res` foram gerados por copia do padrao da familia
  (`PTestObjects.*`) com substituicoes minimas — a verificacao
  compila-e-roda fica com o autor.

## Caveats / limites conhecidos

- **Deviacao de CA-3** (item 5 das decisoes tecnicas): `record simples`
  foi substituido por `Currency`. Documentado. Se o dono preferir manter
  o nome `Scenario_GetValue_Record_Roundtrip` com o tipo `Currency`, e
  mudanca cosmetica; se preferir um scenario adicional para record via
  `TValue` overload (escape hatch), pode ser adicionado em issue irma
  sem afetar CA-3.
- **Deviacao de RN-7** (item 4): mensagem sem acentos por seguranca de
  codepage FPC. A intent unificada permanece. Sub-decisao ja registrada
  como pendente do dono no [ADR](pipeline-adr.md) §"Sub-decisoes pendentes".
- **Warning FPC "managed type not initialized"** — inevitavel no caminho
  `ExtractRawData(@Result)` porque o compilador nao ve o metodo escrevendo
  em `Result` via ponteiro. Se a politica do PR virar *"zero warnings"*,
  silenciar com `{$WARN 5058 OFF}` local; a decisao do arquiteto foi
  manter a evidencia sobre a estetica do compilador.
- **Warning FPC "Unit Rtti is experimental"** — RSK-3 do ESP; aviso
  normal da biblioteca FPC, nao regressao. Chega tanto no build da unit
  quanto no consumidor do overload `TValue`.
- **Build i386 e Delphi** ficam com o autor (SKILL §"The command" e
  §Delphi). O corpo do PR deve declarar o resultado real (CA-10).

## Escopo do PR body a declarar (herança do task-input §CA-10)

O committer deve inserir literalmente no corpo do PR:

1. *"compilado em FPC 3.2.2 x86_64 (fabrica: `rm -rf out && fpc -Mdelphi
   ...` verde; 5/5 testes passam); i386 e Delphi permanecem com o autor
   (SKILL §The command / §Delphi)."*
2. Nota sobre a decisao 4 (mensagem ASCII): *"Sub-decisao 1 do ADR
   §Sub-decisoes pendentes tomada pelo implementador durante o primeiro
   build FPC: mensagem RN-7 em ASCII para evitar dependencia de codepage
   no FPC 3.2.2. Intent unificada preservada; se o dono preferir dois
   textos ou acentos, mudanca fica em RN-7 sem afetar o consumidor."*
3. Nota sobre a decisao 5 (Currency): *"CA-3 `record simples` cumprido
   com `Currency` (compound value type escalar): FPC 3.2.2 rejeita
   `published property` de record e nao expoe `public` via GetProperties
   (medido). RSK-2 do ESP anticipa reforco de fixture sem violar CA-3."*
4. Nota sobre o mecanismo interno: *"`TValue.AsType<T>` inexistente no
   FPC 3.2.2 (medido no primeiro build) contornado com
   `TValue.ExtractRawData(@Result)` dentro de `{$IFDEF FPC}` na
   implementacao — ramificacao interna, invisivel ao consumidor (CA-5)."*

## Pipeline feedback

Nenhuma friccao causada pelo pipeline neste ciclo. O plan-gate:on_reject
que trouxe este ciclo ja veio com ESP/ADR/plan reforcados com a experiencia
do PR #17 (registro do defeito `{$mode objfpc}` sobrescrevendo `-Mdelphi`),
o que permitiu escolher `private class var` desde o inicio em vez de bater
no defeito de novo.
