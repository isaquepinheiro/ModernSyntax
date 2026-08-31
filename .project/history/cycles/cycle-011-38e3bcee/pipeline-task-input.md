---
type: task-input
kind: artifact
title: "TASK-INPUT — TModernValue.AsType<T> (issue #26)"
description: "Handoff operacional: adicionar TValueOps em cada backend, TModernValue na unit pública, fechar o drift do §7 em TModernRTTIProperty.GetValue<T>, e cobrir com 7 cenários compartilhados + 1 published local FPC para o caso de exceção. Alargamento fica fora — vira issue própria."
status: stable
cycle: "011"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/38e3bcee8cdc184a2977006358812748
tags: [modernrtti, task-input, issue-26, fpc, delphi, tvalue, feature]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-08-31T00:00:00Z"
---

# TASK-INPUT — issue #26

## Título

`TModernValue.AsType<T>`: o membro mais usado do `TValue`, envolvido nos
dois compiladores com paridade de assinatura e paridade de caso exato.

## Tipo / labels

- `type: feature`
- `route: feature`
- labels: `enhancement`, `rtti`, `fpc`, `delphi`, `pilar-4`

## Escopo curto

Adicionar `TModernValue` (record na unit pública com `From<T>`,
`FromValue`, `AsType<T>`) e `TValueOps` (record com
`class function AsType<T> ... static` em cada backend). No Delphi,
delegação pura ao `TValue.AsType<T>` nativo. No FPC,
`IsType(TypeInfo(T))` + `ExtractRawData` com raise
`EModernRTTIError` nomeando **origem** e **destino** quando o tipo
diferir.

De passagem, reescrever `TModernRTTIProperty.GetValue<T>` (linhas
385–397 hoje em `Source/ModernSyntax.RTTI.pas`) para uma linha via
`TModernValue.FromValue(...).AsType<T>` — fecha o único drift do §7 do
API-MAP na unit pública.

Alargamento (Integer→Int64, Boolean→Integer, etc.) **fora de escopo** —
vira issue própria com matriz medida no `dcc32` como pré-requisito.
XMLDoc declara a divergência em voz alta.

## Checklist de aceitação

- [ ] `TModernValue` declarado na `interface` de
      `Source/ModernSyntax.RTTI.pas` com superfície mínima (`From<T>`,
      `FromValue`, `AsType<T>`); estado privado neutro `FValue: TValue`;
      **zero `{$IFDEF}` na declaração pública**.
- [ ] XMLDoc de `TModernValue.AsType<T>` carrega o texto exato do D-6
      do [adr](pipeline-adr.md) (divergência declarada em voz alta, tom da #21).
- [ ] Corpo de `TModernValue.AsType<T>` é uma linha:
      `Result := TValueOps.AsType<T>(FValue);` (zero `{$IFDEF}`).
- [ ] `Source/ModernSyntax.RTTI.Delphi.pas` declara record `TValueOps`
      com `class function AsType<T>(const AValue: TValue): T; static`;
      corpo é `Result := AValue.AsType<T>`.
- [ ] `Source/ModernSyntax.RTTI.FPC.pas` declara `TValueOps` com
      assinatura idêntica; corpo faz `IsType(TypeInfo(T))` +
      `ExtractRawData` + raise `EModernRTTIError` com
      `SModernValueIncompatibleType` formatada com
      `V.TypeInfo^.Name` e `PTypeInfo(TypeInfo(T))^.Name`.
- [ ] Uma **única** `resourcestring` nova no backend FPC:
      `SModernValueIncompatibleType = 'incompativel: origem=%s destino=%s'`.
- [ ] `TModernRTTIProperty.GetValue<T>` (hoje 380–398) passa a ser uma
      linha via `TModernValue.FromValue(...).AsType<T>`; o bloco
      `{$IFDEF FPC}...{$ELSE}...{$ENDIF}` some.
- [ ] Após a edição, `grep -n "{\$IFDEF" Source/ModernSyntax.RTTI.pas`
      mostra APENAS a diretiva da `uses` da `implementation`.
- [ ] `TModernRTTIField.GetValue<T>` **não é tocado**.
- [ ] Sete cenários novos em
      `Test Shared/EclbrSystem/UScenarios.RTTI.pas`:
      `Scenario_ModernValue_AsType_String`,
      `_Integer`, `_Boolean`, `_Double`, `_Object`, `_Record`, `_Enum`.
      Todos usam `Fail(...)` (levanta `ETestScenarioFailed`), zero
      `Assert`, zero `Exception` bruta, **zero `{$IFDEF FPC}`** (CA-5).
- [ ] `grep -c "IFDEF" "Test Shared/EclbrSystem/UScenarios.RTTI.pas"`
      não aumenta em relação ao baseline pré-issue.
- [ ] `Test FPC/EclbrSystem/UTestMS.RTTI.pas` recebe **oito** published:
      sete delegando aos cenários compartilhados + um LOCAL
      `TestModernValue_AsType_DifferentType_RaisesWithOriginAndDestination`
      (asserção `Pos(nome-origem, Message) > 0` e `Pos(nome-destino, ...)
      > 0`).
- [ ] `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` recebe **sete**
      `[Test]` delegando aos cenários compartilhados. **Nenhum
      equivalente** do teste de exceção do FPC.
- [ ] `PTestRTTI` compila e passa em x86_64 (fábrica). Autor confirma
      i386 e Delphi 12.
- [ ] Um teste que use `TModernValue.AsType<T>` compila **sem
      `{$IFDEF FPC}` no código do teste**.
- [ ] Corpo do PR: `Closes #26`.
- [ ] Corpo do PR declara a mutação executada: `if not AValue.IsType
      (TypeInfo(T))` → `if False` no backend FPC faz o
      `TestModernValue_AsType_DifferentType_...` falhar (exit != 0).
      Sem essa prova, o teste não vale nada.
- [ ] Corpo do PR declara, sem suavizar: *"assumido pelo padrão do
      repo que `TValueOps` como record com `class function ... static`
      genérico compila no Delphi 12; primeira coisa a confirmar no
      build Delphi"* — se falhar, `TValueOps` vira `class` (mudança
      contida ao Slice 1 do plan).
- [ ] Corpo do PR: linha registrando a próxima issue a abrir —
      **alargamento** (matriz medida no `dcc32` como pré-requisito,
      programa `TMeasure` record disponível no relatório desta issue).

## Arquivos provavelmente impactados

- `Source/ModernSyntax.RTTI.pas` — adiciona `TModernValue`; reescreve
  `TModernRTTIProperty.GetValue<T>`; remove `{$IFDEF FPC}` das linhas
  385–397.
- `Source/ModernSyntax.RTTI.Delphi.pas` — adiciona `TValueOps`.
- `Source/ModernSyntax.RTTI.FPC.pas` — adiciona `TValueOps` + 1
  resourcestring.
- `Test Shared/EclbrSystem/UScenarios.RTTI.pas` — 7 cenários +
  fixture record/enum.
- `Test FPC/EclbrSystem/UTestMS.RTTI.pas` — 8 published (7 delegando +
  1 local).
- `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` — 7 `[Test]`.

**Runners não mudam:** `Test FPC/EclbrSystem/PTestRTTI.lpr` e
`Test Delphi/EclbrSystem/PTestRTTI.dpr` inalterados; `.lpi`
inalterado; `-Fu"Source"` já acha os backends.

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

Espera-se `exit=0` no verde. Sob a mutação `if False` no backend FPC,
espera-se `exit != 0` (prova de que o teste de exceção não é decorativo).

## Referências

- [esp](pipeline-esp.md) — critérios formais.
- [adr](pipeline-adr.md) — decisão e o que foi descartado.
- [plan](pipeline-plan.md) — ordem de execução em 3 slices.
- [API-MAP §§2, 7](../../../strategy/2026-08-27-modernrtti/API-MAP.md)
- [SKILL — receita FPC + traps](../../../SKILL.md)
