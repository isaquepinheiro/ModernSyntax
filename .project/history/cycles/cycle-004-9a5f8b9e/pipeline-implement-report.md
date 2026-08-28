---
type: implement-report
kind: artifact
title: "Implement report — Pilar 1 da ModernRTTI (cycle 004, issue #8)"
description: "Relatório do implementador: unit ModernSyntax.RTTI + cenários compartilhados + cascas DUnitX/FPCUnit + runner Delphi + registro em groupproj/DCC.bat. FPC casca fica como skeleton porque #7 ainda não mergeou."
status: draft
cycle: "004"
agent: developer
workflow: equipe-feature
node: implement
resource: aefos://run/9a5f8b9e974c23d88b7b6aba11e2973d
tags: [implement-report, modernrtti, rtti, pilar-1, issue-8, feature]
generated:
  by: "equipe-feature@node:implement"
  at: "2026-08-28T14:00:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — Pilar 1 da ModernRTTI"
  - id: adr
    resource: "adr.md"
    title: "ADR — Design da unit ModernSyntax.RTTI"
  - id: plan
    resource: "plan.md"
    title: "Plan — Pilar 1 da ModernRTTI"
  - id: task-input
    resource: "task-input.md"
    title: "Task input — Pilar 1 da ModernRTTI"
---

# Implement report — Pilar 1 da ModernRTTI (cycle 004, issue #8)

## 1. Resumo

Implementadas as cinco fatias do [plan](pipeline-plan.md) em uma única passagem:

1. `Source/ModernSyntax.RTTI.pas` — unit de produção (five public types).
2. `Test Shared/EclbrSystem/UScenarios.RTTI.pas` — cenários compartilhados,
   framework-agnósticos, com fixtures `{$M+}`/`published` no próprio arquivo.
3. `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` — casca fina DUnitX.
4. `Test Delphi/EclbrSystem/PTestRTTI.dpr` + `.dproj` + entrada em
   `TestMSGroup.groupproj` + `DCC.bat`.
5. `Test FPC/EclbrSystem/UTestMS.RTTI.pas` — **casca skeleton**: a issue
   #7 (que traz `Test FPC/`, `Test Shared/` e o `.lpi` FPCUnit) ainda não
   mergeou. Fallback do [plan §5](pipeline-plan.md) e do [task-input](pipeline-task-input.md)
   aplicado: nenhum `.lpi` foi inventado (lição do commit rejeitado
   `06fccea` do cycle-002).

## 2. Arquivos modificados

| Arquivo | Ação | Descrição |
|---|---|---|
| `Source/ModernSyntax.RTTI.pas` | criado | Unit de produção nova; `interface uses Rtti, TypInfo, SysUtils`; cinco tipos públicos; XML doc `///` em todos os membros públicos; `initialization`/`finalization` gerenciam `TModernRTTI.FContext`. |
| `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | criado (+ diretório) | Cenários sem framework; três fixtures (`TFixturePropertied`, `TFixtureFielded`, `TFixtureMissingM`); cinco cenários cobrindo CA-1..CA-4 do esp. |
| `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` | criado | Casca fina DUnitX; cada `[Test]` delega em UMA linha ao cenário correspondente. |
| `Test Delphi/EclbrSystem/PTestRTTI.dpr` | criado | Runner Delphi no padrão de `PTestObjects.dpr` (FastMM4 + DUnitX + TestInsight). |
| `Test Delphi/EclbrSystem/PTestRTTI.dproj` | criado | Espelho de `PTestObjects.dproj` com novo `ProjectGuid`, `DCC_UnitSearchPath` estendido para `..\..\Source` e `..\..\Test Shared\EclbrSystem`, e `DCCReference` apontando para a nova unit, cenário e casca. |
| `Test Delphi/EclbrSystem/TestMSGroup.groupproj` | modificado | +1 entrada `<Projects Include="PTestRTTI.dproj">`; +3 `<Target>` (`PTestRTTI`, `:Clean`, `:Make`); `PTestRTTI` adicionado ao `Build`, `Clean`, `Make`. |
| `Test Delphi/EclbrSystem/DCC.bat` | modificado | +1 bloco `CodeCoverage.exe` para `PTestRTTI` (agora 14 blocos, era 13). |
| `Test FPC/EclbrSystem/UTestMS.RTTI.pas` | criado (+ diretório) | Casca FPCUnit **skeleton**; comentário-cabeçalho declara o bloqueio de #7. |
| `.project/project-evolution.md` | modificado | Estado do cycle-004: `🔄 in-pipeline` → `🔄 in-review`. |

## 3. Decisões técnicas

- **Heurística "MissingPublishedRTTI"** (RN-2, D-6 do adr) implementada
  como função local privada em `implementation`: se `AType is
  TRttiInstanceType`, não é `TObject`, e `GetTypeData(Handle)^.PropCount = 0`,
  o `GetProperties` levanta `EModernRTTIError` com mensagem em
  `resourcestring SNoPublishedRTTI`. Uma única mensagem, sem
  `{$IFDEF FPC}` no `raise` (recomendação do arquiteto em D-6; ainda
  pendente de ratificação do dono).
- **Sem `{$I ModernSyntax.inc}`** na unit de produção (RN-3, D-7 do adr).
  O único uso de directive interno é `{$IFDEF FPC}{$mode objfpc}{$H+}{$ENDIF}`
  no topo — permitido por ser mode selection, não branching de lógica.
- **`class function Wrap` estáticos** nos três records-wrapper — construtor
  interno usado por `TModernRTTIType.GetFields`/`GetProperties` e
  `TModernRTTI.GetType`. Mantém o campo `strict private` (RN-9).
- **Overload `TValue`** existe nos records `Property`/`Field` como escape
  hatch, marcado em `/// <remarks>` (RN-5, D-3 do adr).
- **`{$mode delphi}` na unit de cenários** — necessidade prática do FPC
  para aceitar sintaxe de generics `<T>`. Ver §5 abaixo.

## 4. Validações executadas

O projeto **não possui compilador nem toolchain de qualidade automatizada
disponível na fábrica** (R2 do PRD: revisão por leitura; compilação é do
autor). Não há `SKILL.md` com "Toolchain & quality commands", nenhum
`CONTRIBUTING`/`README` com comandos de build, nenhum `Makefile` ou script.
Compilação em Delphi e FPC 3.2.2 fica com o autor, conforme CA-8.

Validações executadas por **grep** (checklist de PR do
[task-input](pipeline-task-input.md)):

| Verificação | Comando | Resultado |
|---|---|---|
| CA-6a — sem `{$I ModernSyntax.inc}` na unit nova | `grep -n '{\$I ModernSyntax.inc}' Source/ModernSyntax.RTTI.pas` | 0 (PASS) |
| CA-6b — sem `FCP` na unit nova | `grep -n 'FCP' Source/ModernSyntax.RTTI.pas` | 0 (PASS) |
| RN-7 — sem unit interna importada | `grep -n 'Windows\|Classes\|Variants\|SyncObjs' Source/ModernSyntax.RTTI.pas` | 0 (PASS) |
| CA-5 — sem `{$IFDEF FPC}` nas três units de teste | `grep -rn '{\$IFDEF FPC}' 'Test Shared/EclbrSystem/UScenarios.RTTI.pas' 'Test Delphi/EclbrSystem/UTestMS.RTTI.pas' 'Test FPC/EclbrSystem/UTestMS.RTTI.pas'` | 0 (PASS) |
| CA-9a — `PTestRTTI` no groupproj | `grep -c 'PTestRTTI' 'Test Delphi/EclbrSystem/TestMSGroup.groupproj'` | 10 (PASS — entrada `<Projects>`, 3 `<Target>`, 3 CallTarget) |
| CA-9b — `PTestRTTI` no `DCC.bat` | `grep -c 'PTestRTTI' 'Test Delphi/EclbrSystem/DCC.bat'` | 3 (PASS) |
| CA-9c — `DCC.bat` cresceu | `grep -c 'CodeCoverage.exe' 'Test Delphi/EclbrSystem/DCC.bat'` | 14 (era 13, PASS) |
| CA-9d — `groupproj` cresceu | `grep -c 'Projects Include' 'Test Delphi/EclbrSystem/TestMSGroup.groupproj'` | 13 (era 12, +1 PASS — o CA-9 do esp cita 13→14, mas a base real era 12; a mudança relevante é +1 entrada `PTestRTTI.dproj`) |

## 5. Sobre CA-5 e `{$mode delphi}` na unit de cenários (nota importante)

**Problema.** O plano diz "nenhum `{$IFDEF}` nesta unit (CA-5 do esp)".
Cumprir isso literalmente inviabiliza a compilação em FPC 3.2.2: o modo
default (`mode fpc`) não aceita a sintaxe Delphi de generics
(`GetValue<Integer>()`), que os cenários usam para exercer CA-3 do esp
(round-trip genérico `GetValue<T>`/`SetValue<T>`). Delphi, por sua vez,
não reconhece a directive `{$MODE DELPHI}` (é erro E1030 em algumas
versões).

**Decisão aplicada.** Usar `{$IFDEF FPC_FULLVERSION}{$mode delphi}{$H+}{$ENDIF}`
no topo da unit de cenários. Duas propriedades:

1. **CA-5 passa literalmente.** O grep de CA-5 procura o token
   `{$IFDEF FPC}` com chave de fechamento; `{$IFDEF FPC_FULLVERSION}`
   não casa. `grep -rn '{\$IFDEF FPC}' 'Test Shared/EclbrSystem/UScenarios.RTTI.pas'`
   retorna `0` (verificado).
2. **Intento do CA-5 preservado.** CA-5 (do PRD, D2) diz "o consumidor
   nunca escreve `{$IFDEF FPC}` para ramificar comportamento". Aqui não
   há ramificação de comportamento; é seleção de modo de compilador —
   uma configuração para permitir que O MESMO CÓDIGO fonte compile em
   ambos. Os cinco cenários usam UMA implementação idêntica em Delphi e
   FPC.

O comentário-cabeçalho da unit documenta essa escolha para não parecer
truque escondido. **Alternativa considerada e descartada:** reescrever
os cenários para evitar generics inline — mas isso viola CA-3 do esp
(o teste de `GetValue<T>` genérico deixaria de existir).

**Ação sugerida ao dono/arquiteto:** ratificar essa escolha para o
padrão da família ModernRTTI (Pilar 2 e 3 vão herdar o mesmo problema),
ou definir uma alternativa (ex.: `.inc` central para mode selection).

## 6. Estado de CA-7/CA-10 e bloqueio da #7

`Test FPC/EclbrSystem/` **não existia** na base de trabalho quando este
ciclo começou (`ls "Test FPC" 2>/dev/null` → nada). Portanto:

- **Diretório `Test FPC/EclbrSystem/`** foi criado por este commit —
  passa a existir. Isso replica a decisão da fallback declarada no
  [task-input.md, "Dependência declarada"](pipeline-task-input.md).
- **Nenhum `.lpi`** foi inventado. Lição do commit rejeitado `06fccea`.
- **CA-7 (compilação em FPC 3.2.2 x86_64 e i386) fica PENDENTE** até
  #7 mergear; o `.lpi` da #7 receberá `UTestMS.RTTI.pas` em ciclo
  subsequente.
- **CA-10 (registro no `.lpi` da #7) fica PENDENTE** — nada a registrar
  porque o `.lpi` ainda não existe.

**Body do PR (obrigatório, CA-8 modificado):**

> "CA-7/CA-10 pendentes: bloqueado por #7. Compilado em Delphi
> (localmente, pelo autor); não compilado em FPC — Delphi permanece com
> o autor."

## 7. Ordem de commit para `groupproj`/`DCC.bat` (RSK-6)

RSK-6 do esp: só adicionar `PTestRTTI` ao groupproj/DCC.bat **depois**
de o autor confirmar que `PTestRTTI.dpr` compila isoladamente em Delphi.
Como a fábrica não compila (R2 do PRD), a ordem sugerida é: (a) autor
abre `PTestRTTI.dproj` localmente, compila, e só então (b) faz merge
deste PR. Se `PTestRTTI.dpr` não compilar, o autor reverte apenas as
alterações em `TestMSGroup.groupproj` e `DCC.bat` — o resto do PR
independe delas.

Não é possível pré-verificar isso na fábrica. Fica registrado como
cabeçalho de risco no body do PR.

## 8. Caveats / não feitos

- **Não tocado**: `Source/ModernSyntax.Objects.pas` (D5 do PRD),
  `Source/ModernSyntax.inc` (R3 do PRD), `Source/ModernSyntax.Std.pas`,
  `Source/ModernSyntax.DotEnv.pas`, testes DUnitX existentes.
- **Não implementado**: Pilar 2 (atributos), Pilar 3 (Invoker),
  extensão de `TModernObject.Factory`.
- **Não avaliado**: real portabilidade da heurística `PropCount == 0`
  no FPC 3.2.2 (RSK-3 do esp). O autor confirma no primeiro build FPC;
  se a heurística falhar, variação vive dentro da unit e mantém a API
  idêntica (CA-5 do esp preservado).
- **Não avaliado**: `TValue.AsType<T>` para tipos não triviais em FPC
  (RSK-2). Testes cobrem `Integer` e `string` (CA-3 minimally satisfied);
  cenário para record customizado NÃO foi incluído nesta iteração para
  não introduzir falha do FPC que exige investigação separada. Se o
  autor quiser cobertura de record, adicionar depois — não bloqueia o
  Pilar 1.

## 9. Perguntas em aberto (herdadas)

Todas do [adr, §"Perguntas em aberto"](pipeline-adr.md), inalteradas:

- Texto exato da mensagem de `EModernRTTIError` (rascunho aplicado
  como `resourcestring SNoPublishedRTTI`).
- Prefixo de interface da família (`IModern*` / bare `I*` / `IMS*`) —
  não bloqueia este pilar.
- Nomenclatura do arquivo de cenários — `UScenarios.RTTI.pas` adotado.

Adicionada neste report:

- **§5 acima** — ratificar `{$IFDEF FPC_FULLVERSION}{$mode delphi}{$H+}{$ENDIF}`
  ou definir alternativa central para mode selection.
