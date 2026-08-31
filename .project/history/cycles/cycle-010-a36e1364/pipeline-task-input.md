---
type: task-input
kind: artifact
title: "TASK-INPUT — TModernRTTIMethod pela vmtMethodTable (issue #25)"
description: "Handoff operacional: adicionar TModernRTTIMethod/TModernRTTIParameter e alimentar GetMethods/GetMethod nos dois compiladores; refatorar TModernRTTIField para split de backends; fechar #35 com cirurgia do Fail; três cenários com prova de mutação declarada."
status: stable
cycle: "010"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/a36e13649de2fc026303074567d63275
tags: [modernrtti, task-input, issue-25, fpc, delphi, feature]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-08-31T00:00:00Z"
---

# TASK-INPUT — issue #25

## Título

`TModernRTTIMethod`: enumerar `published` pela `vmtMethodTable`, com falha
honesta onde não há dado.

## Tipo / labels

- `type: feature`
- `route: feature`
- labels: `enhancement`, `rtti`, `fpc`, `delphi`, `pilar-4`

## Escopo curto

Adicionar `TModernRTTIMethod` (`Name`, `Invoke`, `GetParameters`,
`ReturnType`, `IsConstructor`, `IsClassMethod`, `IsStatic`, `Visibility`)
e `TModernRTTIParameter` (`Name`, `ParamType`), com
`TModernRTTIType.GetMethods` e `TModernRTTIType.GetMethod` alimentados
nos dois compiladores.

No FPC, enumeração é pela `vmtMethodTable` iterada com `LTab^.Entry[i]`
(sem aritmética literal); lookup por nome usa `TObject.MethodAddress`
(sem laço próprio); os seis membros sem fonte no FPC levantam
`EModernRTTIError` com mensagem instrutiva.

De passagem, refatorar `TModernRTTIField` para remover o `{$IFDEF}` do
`strict private` (pré-condição arquitetural — §7 do API-MAP) e criar os
backends `ModernSyntax.RTTI.Delphi.pas` e `ModernSyntax.RTTI.FPC.pas`.

Fechar #35 com a cirurgia do `Fail` em `UScenarios.RTTI.pas` (declarar
`ETestScenarioFailed` e usá-la).

## Checklist de aceitação

- [ ] `TModernRTTIMethod` e `TModernRTTIParameter` compilam em Delphi e
      FPC; zero `{$IFDEF}` na declaração pública.
- [ ] `Source/ModernSyntax.RTTI.pas` tem o único `{$IFDEF}` da unit na
      `uses` da `implementation`.
- [ ] `Source/ModernSyntax.RTTI.Delphi.pas` e
      `Source/ModernSyntax.RTTI.FPC.pas` existem e expõem a mesma
      superfície de funções livres.
- [ ] `TModernRTTIField` foi migrado para o novo desenho (campos
      neutros, `FromToken`).
- [ ] `MethodTokens` no backend FPC itera com `LTab^.Entry[i]`; nenhum
      `PByte(LTab) + N` ou `i * SizeOf(TVmtMethodEntry)` no código.
- [ ] `MethodToken(AClass, AName)` no backend FPC é uma linha usando
      `MethodAddress`; sem laço próprio por `ClassParent`.
- [ ] Seis membros sem fonte no FPC levantam `EModernRTTIError` com
      mensagem apontando `vmtMethodTable` + `TIntfMethodEntry`.
- [ ] `TModernRTTIParameter.Name`/`.ParamType` levantam
      `EModernRTTIError` no FPC.
- [ ] XMLDoc de `GetMethods` declara a divergência de cobertura (Delphi:
      `public`+`published`; FPC: só `published`).
- [ ] `UScenarios.RTTI.pas` declara `ETestScenarioFailed = class(Exception);`
      e o `Fail` da linha 95 levanta essa classe.
- [ ] Fixture com herança `TMethodBase`/`TMethodDerived`
      (só `published`).
- [ ] Três cenários compartilhados:
      `Scenario_GetMethods_CountsPublishedInherited_Exact`,
      `Scenario_GetMethod_ByName_FindsInherited`,
      `Scenario_Method_Invoke_NoArgs`. Zero `Assert`. Zero `{$IFDEF FPC}`
      (CA-5).
- [ ] `Test FPC/EclbrSystem/UTestMS.RTTI.pas` e
      `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` recebem três published
      tests cada.
- [ ] `Test Delphi/EclbrSystem/UTestMS.RTTI.pas:59` — comentário stale
      corrigido.
- [ ] `PTestRTTI` compila e passa em x86_64 (fábrica) e i386 (autor).
- [ ] Corpo do PR: `Closes #25` e `Closes #35`.
- [ ] Corpo do PR declara as mutações M1 (desligar `ClassParent`) e M2
      (aritmética literal no i386) que os cenários pegam.

## Arquivos provavelmente impactados

- `Source/ModernSyntax.RTTI.pas` — refactor.
- `Source/ModernSyntax.RTTI.Delphi.pas` — **NOVO**.
- `Source/ModernSyntax.RTTI.FPC.pas` — **NOVO**.
- `Test Shared/EclbrSystem/UScenarios.RTTI.pas` — cirurgia + fixture +
  cenários.
- `Test FPC/EclbrSystem/UTestMS.RTTI.pas` — três published tests.
- `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` — três published tests +
  fix linha 59.

`Test FPC/EclbrSystem/PTestRTTI.lpr` **não muda** (o `-Fu"Source"` já
acha os backends).

## Comandos de verificação (fábrica x86_64)

```
rm -rf /tmp/fpcbuild
mkdir -p /tmp/fpcbuild
fpc -Mdelphi \
    -Fu"Source" -Fu"Test Shared/EclbrSystem" -Fu"Test FPC/EclbrSystem" \
    -FU/tmp/fpcbuild -FE/tmp/fpcbuild \
    "Test FPC/EclbrSystem/PTestRTTI.lpr"
/tmp/fpcbuild/PTestRTTI --all -a --format=plain ; echo "exit=$?"
```

Espera-se `exit=0` no verde e `exit != 0` sob mutação M1.

## Referências

- [esp](pipeline-esp.md) — critérios formais.
- [adr](pipeline-adr.md) — decisões e o que foi descartado.
- [plan](pipeline-plan.md) — ordem de execução em 4 slices.
- [API-MAP §§1,2,4,7](/strategy/2026-08-27-modernrtti/API-MAP.md)
- [SKILL](/SKILL.md) — receita FPC + traps.
