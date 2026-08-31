---
type: plan
kind: artifact
title: "PLAN — TModernRTTIMethod (issue #25)"
description: "Quatro slices coordenadas: (1) split arquitetural + Field portado; (2) TModernRTTIMethod/Parameter e backends com vmtMethodTable; (3) cirurgia do Fail em UScenarios.RTTI.pas (Closes #35); (4) fixtures e published tests com prova de mutação."
status: stable
cycle: "009"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/af5fcd28da98e98892fbe66e544b6b5c
tags: [modernrtti, plan, issue-25, fpc, delphi]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-08-31T00:00:00Z"
---

# PLAN — issue #25

**Escopo:** um único PR. Slices são **passos ordenados dentro do mesmo
commit-set**, não entregas independentes — o build só volta a passar
quando todas fecham. Ordem escolhida para deixar o compilador falar em
cada etapa: se algo quebra, a slice em curso é a culpada.

Todas as decisões vêm do [adr](pipeline-adr.md). Todos os critérios de
`Aceito quando` estão no [esp](pipeline-esp.md).

## Slice 1 — split arquitetural e port de `TModernRTTIField`

**Fim:** a §7 do [API-MAP](../../../strategy/2026-08-27-modernrtti/API-MAP.md)
passa a valer em `Source/ModernSyntax.RTTI.pas`: casca pública sem
`{$IFDEF}` nos tipos, e os campos e métodos de `TModernRTTIField`
migram para backends.

**Arquivos:**

- `Source/ModernSyntax.RTTI.pas` — refactor:
  - `strict private` de `TModernRTTIField` (61-68): remover os três
    campos condicionais; deixar `FOwner: TClass; FName: string;
    FToken: Pointer`.
  - Factories condicionais (72-76): substituir por
    `class function FromToken(AOwner: TClass; const AName: string;
    AToken: Pointer): TModernRTTIField; static;`.
  - `implementation.uses`: adicionar o único `{$IFDEF}` da unit
    (`{$IFDEF FPC} ModernSyntax.RTTI.FPC; {$ELSE} ModernSyntax.RTTI.Delphi; {$ENDIF}`).
  - Corpos de `TModernRTTIField` migram para chamadas às funções
    livres dos backends.
- `Source/ModernSyntax.RTTI.Delphi.pas` — **NOVO** (esqueleto):
  `FieldToken`, `FieldTokens`, `FieldName`, `FieldRead`, `FieldWrite`
  saem do arquivo público e passam a viver aqui. Símbolos
  `TRttiField` ficam confinados nesta unit.
- `Source/ModernSyntax.RTTI.FPC.pas` — **NOVO** (esqueleto): mesmas
  assinaturas; corpos usam `vmtFieldTable`/`FieldAddress` (já provados
  no ciclo 006/008).

**Aceito quando:** `PTestRTTI` verde com apenas os cenários existentes,
sem qualquer mudança em teste — o slice é refactor puro.

## Slice 2 — `TModernRTTIMethod` e `TModernRTTIParameter` em ambos os backends

**Fim:** os oito membros de `TModernRTTIMethod` e os dois membros de
`TModernRTTIParameter` compilam nos dois compiladores e produzem dado
real onde a fonte permite.

**Arquivos:**

- `Source/ModernSyntax.RTTI.pas`:
  - Declarar `TModernRTTIParameter` (records com `strict private`
    neutro).
  - Declarar `TModernRTTIMethod` com os oito membros: `Name`, `Invoke`
    (assinatura `TSignature<T>` — D-25.9), `GetParameters`,
    `ReturnType`, `IsConstructor`, `IsClassMethod`, `IsStatic`,
    `Visibility`. Campos neutros (`FOwner`, `FName`, `FToken`).
  - Adicionar em `TModernRTTIType`:
    `function GetMethods: TArray<TModernRTTIMethod>;` e
    `function GetMethod(const AName: string): TModernRTTIMethod;`
    (levanta `EModernRTTIError` se não achar).
  - XMLDoc — D-25.5: divergência de cobertura em `GetMethods`; os
    seis membros sem fonte no FPC declaram o `raise EModernRTTIError`.
  - Corpos delegam funções livres dos backends.
- `Source/ModernSyntax.RTTI.Delphi.pas`: adicionar `MethodTokens`,
  `MethodToken`, `MethodName`, `MethodInvoke`, `MethodIsConstructor`,
  `MethodIsClassMethod`, `MethodIsStatic`, `MethodVisibility`,
  `MethodReturnType`, `MethodGetParameters`, `ParameterName`,
  `ParameterType`. Todos envolvem `System.Rtti` direto.
- `Source/ModernSyntax.RTTI.FPC.pas`:
  - `MethodTokens(AClass)`: loop por `ClassParent`; iteração via
    `LTab^.Entry[i]` (D-25.2). **Nenhuma aritmética de ponteiro
    literal.**
  - `MethodToken(AClass, AName)`: uma linha, delega a `MethodAddress`
    (D-25.3). Handle devolvido pode ser `nil` no caminho
    `MethodAddress` — `Invoke` não depende dele.
  - `MethodName(AToken)`: `string(PVmtMethodEntry(AToken)^.Name^)`
    (deref explícito — F-3 do STUDY).
  - `MethodInvoke`: delega ao mecanismo de
    `ModernSyntax.Invoker.pas:83-90` usando `FOwner` + `FName`.
  - `MethodIsConstructor`, `MethodIsClassMethod`, `MethodIsStatic`,
    `MethodVisibility`, `MethodReturnType`, `MethodGetParameters`,
    `ParameterName`, `ParameterType`: cada uma
    `raise EModernRTTIError.CreateFmt(...)` com mensagem instrutiva
    apontando `vmtMethodTable` e `TIntfMethodEntry`.

**Aceito quando:** `Test FPC/EclbrSystem/PTestRTTI.lpr` compila em
x86_64 sem erro. Testes ainda não mudaram — verde por proteção dos
cenários existentes.

## Slice 3 — cirurgia do `Fail` em `UScenarios.RTTI.pas` (Closes #35)

**Fim:** `PTestRTTI` passa a devolver `exit != 0` sobre vermelho,
condição para a prova de mutação da Slice 4 valer alguma coisa em CI.

**Arquivos:**

- `Test Shared/EclbrSystem/UScenarios.RTTI.pas`:
  - No bloco `type` da `interface`: adicionar
    `ETestScenarioFailed = class(Exception);` (padrão
    `UTestMS.Attributes.Scenarios.pas:31` e
    `UTestMS.Callback.Scenarios.pas:42`).
  - Linha 95: `raise Exception.Create(AMsg);` →
    `raise ETestScenarioFailed.Create(AMsg);`.

**Aceito quando:** `PTestRTTI` continua verde (nenhum cenário mudou);
autor confirma manualmente que forçar um cenário a falhar agora
resulta em `exit != 0` (medida a repetir em Delphi + FPC).

## Slice 4 — fixture com herança, três cenários novos, published tests

**Fim:** os cenários que provam `GetMethods`/`GetMethod`/`Invoke` no FPC
existem, protegem contra as mutações M1/M2, e ficam expostos como
published tests nos dois runners.

**Arquivos:**

- `Test Shared/EclbrSystem/UScenarios.RTTI.pas`:
  - Fixture nova (após linha 243):
    ```pascal
    {$M+}
    TMethodBase = class published procedure Alpha; end;
    TMethodDerived = class(TMethodBase) published procedure Gama; end;
    {$M-}
    ```
    Corpos: `Alpha` e `Gama` incrementam um contador de módulo (efeito
    colateral observável).
  - Cenário `Scenario_GetMethods_CountsPublishedInherited_Exact`:
    `Length(GetMethods) = 2`, presença de `Alpha` e `Gama` por nome.
  - Cenário `Scenario_GetMethod_ByName_FindsInherited`:
    `GetMethod('Alpha')` de `TMethodDerived` acha e invoca com sucesso.
  - Cenário `Scenario_Method_Invoke_NoArgs`: chama `Alpha` via `Invoke`
    e verifica efeito colateral.
  - Todos usam `Fail(...)` (que agora levanta `ETestScenarioFailed`).
    Zero `Assert`. Zero `{$IFDEF FPC}` (CA-5).
- `Test FPC/EclbrSystem/UTestMS.RTTI.pas` (após linha 75): três
  published tests, uma linha útil cada, delegando aos cenários
  compartilhados.
- `Test Delphi/EclbrSystem/UTestMS.RTTI.pas`:
  - Após linha 115: três published tests correspondentes.
  - Linha 59: corrigir comentário stale ("TModernRTTIField e
    GetFields não existem no FPC 3.2.2" — falso desde a #21).

**Aceito quando:**

- `PTestRTTI` verde nos dois compiladores; contagem exata em
  `TMethodDerived` = 2.
- Prova de mutação declarada no corpo do PR:
  - M1 (desligar `ClassParent` em `MethodTokens`) → cenário `_Exact`
    falha.
  - M2 (trocar `Entry[i]` por aritmética literal) → falha em i386
    (declarada pelo autor).
- PR body: `Closes #25` e `Closes #35`.

## Impactos consolidados

| arquivo | ação |
|---|---|
| `Source/ModernSyntax.RTTI.pas` | refactor — Field neutro, adiciona Method/Parameter, casca delega |
| `Source/ModernSyntax.RTTI.Delphi.pas` | **NOVO** — backend Delphi |
| `Source/ModernSyntax.RTTI.FPC.pas` | **NOVO** — backend FPC (vmtMethodTable, MethodAddress, raises) |
| `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | ETestScenarioFailed + fixture + 3 cenários |
| `Test FPC/EclbrSystem/UTestMS.RTTI.pas` | 3 published tests |
| `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` | 3 published tests + fix comentário linha 59 |

## O que este plano NÃO faz

- Não toca `ModernSyntax.Invoker.pas`.
- Não altera `.lpi` de `PTestRTTI` (o `-Fu"Source"` acha os backends).
- Não retrofita outra unit do `Source/` para o FPC.
- Não introduz enumeradores de `Methods`/`Parameters` (API-MAP §3,
  fica para issue própria).
