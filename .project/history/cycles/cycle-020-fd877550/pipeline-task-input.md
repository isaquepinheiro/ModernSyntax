---
type: task-input
kind: artifact
title: "TASK-INPUT — issue #49: contrato unico de handle nil em TModernRTTIType (cinco membros, EModernRTTIError, SModernRTTINilHandle)"
description: "Handoff operacional para o implementador: cinco guardas identicas (if FType = nil then raise EModernRTTIError.CreateFmt(SModernRTTINilHandle, [membro])) em Name/GetProperties/GetFields/GetMethods/GetMethod; GetFields guarda ANTES do is TRttiInstanceType check; XMLDoc em cinco declaracoes; cenario Scenario_NilHandle_AllMembers_Raises pelo caminho publico com verificacao de mensagem; desbloqueio D-44.6; duas cascas de uma linha."
status: draft
cycle: "020"
agent: architect
workflow: equipe-bug
node: architect
resource: aefos://run/fd87755097391831d283adc83e6b8813
tags: [modernrtti, task-input, issue-49, bug, nil-handle, fpc, delphi]
generated:
  by: "equipe-bug@node:architect"
  at: "2026-09-02T00:00:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — issue #49"
  - id: adr
    resource: "adr.md"
    title: "ADR — issue #49"
  - id: plan
    resource: "plan.md"
    title: "PLAN — issue #49"
  - id: skill
    resource: "/SKILL.md"
    title: "SKILL — receita FPC, traps"
---

# TASK-INPUT — issue #49

## Titulo

`#49 — nil-handle contract for TModernRTTIType (Name, GetProperties, GetFields, GetMethods, GetMethod)`

## Tipo / Labels

`bug`

## Escopo em uma linha

Cinco guardas identicas de nil + resourcestring + XMLDocs em `ModernSyntax.RTTI.pas`;
um cenario compartilhado + desbloqueio de divida em `UScenarios.RTTI.pas`;
duas cascas de uma linha cada.

## Arquivos provavelmente impactados

| Arquivo | O que muda |
|---------|-----------|
| `Source/ModernSyntax.RTTI.pas` | `resourcestring SModernRTTINilHandle`; cinco guardas `if FType = nil`; cinco XMLDoc `<remarks>` |
| `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | Novo `Scenario_NilHandle_AllMembers_Raises`; desbloqueio D-44.6 em `Scenario_PointerType_ReferredType_Nil_ForBarePointer` |
| `Test FPC/EclbrSystem/UTestMS.RTTI.pas` | `published TestNilHandle_AllMembers_Raises` de uma linha |
| `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` | `[Test] TestNilHandle_AllMembers_Raises` de uma linha |

## Instrucoes criticas para o implementador

### 1. `Source/ModernSyntax.RTTI.pas`

**Adicionar `resourcestring`** no bloco existente (`:860-873`, onde vivem
`SModernRTTIMissingProps` e `SModernRTTIGetMethodsNotClass`):

```pascal
SModernRTTINilHandle =
  'handle nao inicializado (IsNil = True). Verifique IsNil antes de chamar %s.';
```

**Cinco guardas — identicas, uma por membro:**

```pascal
if FType = nil then
  raise EModernRTTIError.CreateFmt(SModernRTTINilHandle, ['<NomeDoProcedimento>']);
```

| Onde inserir | Linha de referencia | Parametro `%s` |
|---|---|---|
| `TModernRTTIType.Name` | antes de `Result := FType.Name` (`:1022`) | `'Name'` |
| `TModernRTTIType.GetProperties` | antes de `LProps := FType.GetProperties` (`:1033`) | `'GetProperties'` |
| `TModernRTTIType.GetFields` | **antes do `is TRttiInstanceType` check** (`:1053`) | `'GetFields'` |
| `TModernRTTITypeHelper.GetMethods` | antes do `is` check (`:1067`) | `'GetMethods'` |
| `TModernRTTITypeHelper.GetMethod` | antes das referencias a `FType.Name` nos `raise` (`:1074`) | `'GetMethod'` |

> **CRITICO para `GetFields`:** a guarda precede o `is TRttiInstanceType`.
> Nao altere a logica que se segue ao `is` check — records e enums com
> `FType <> nil` continuam retornando `nil` silenciosamente, e isso esta
> correto.

**Cinco XMLDocs `<remarks>`** em declaracoes da `interface`:

Para cada uma das cinco declaracoes abaixo, adicionar (ou somar ao
`<remarks>` existente) o texto:

```
/// <remarks>
/// Quando <c>IsNil = True</c>, levanta <c>EModernRTTIError</c>;
/// verifique <c>IsNil</c> antes de chamar.
/// </remarks>
```

| Declaracao | Linha de referencia | Observacao |
|---|---|---|
| `Name` | `:176` | |
| `GetProperties` | `:193` | |
| `GetFields` | `:205` | |
| `GetMethods` | `:373` | |
| `GetMethod` | `:380` | SOMA ao `<remarks>` existente sobre `MethodAddress`/D-25.3; nao substitui |

### 2. `Test Shared/EclbrSystem/UScenarios.RTTI.pas`

**Declarar na `interface`** (perto de `:305-311`, apos cenarios #44/#45):

```pascal
procedure Scenario_NilHandle_AllMembers_Raises;
```

**Implementar na `implementation`:**

```pascal
procedure Scenario_NilHandle_AllMembers_Raises;
var
  LCtx: TModernRTTIContext;
  LType: TModernRTTIType;
begin
  LCtx := TModernRTTIContext.Create;
  LType := LCtx.FindType('TipoQueNaoExiste_Issue49');
  if not LType.IsNil then
    raise ETestScenarioFailed.Create('Esperado IsNil = True para tipo inexistente.');

  // Name
  try
    LType.Name;
    raise ETestScenarioFailed.Create('Name nao levantou sobre handle nil.');
  except
    on E: EModernRTTIError do
      if Pos('Name', E.Message) = 0 then
        raise ETestScenarioFailed.Create('Mensagem de Name nao cita o membro.');
  end;

  // GetProperties
  try
    LType.GetProperties;
    raise ETestScenarioFailed.Create('GetProperties nao levantou sobre handle nil.');
  except
    on E: EModernRTTIError do
      if Pos('GetProperties', E.Message) = 0 then
        raise ETestScenarioFailed.Create('Mensagem de GetProperties nao cita o membro.');
  end;

  // GetFields
  try
    LType.GetFields;
    raise ETestScenarioFailed.Create('GetFields nao levantou sobre handle nil.');
  except
    on E: EModernRTTIError do
      if Pos('GetFields', E.Message) = 0 then
        raise ETestScenarioFailed.Create('Mensagem de GetFields nao cita o membro.');
  end;

  // GetMethods
  try
    LType.GetMethods;
    raise ETestScenarioFailed.Create('GetMethods nao levantou sobre handle nil.');
  except
    on E: EModernRTTIError do
      if Pos('GetMethods', E.Message) = 0 then
        raise ETestScenarioFailed.Create('Mensagem de GetMethods nao cita o membro.');
  end;

  // GetMethod
  try
    LType.GetMethod('AnyName');
    raise ETestScenarioFailed.Create('GetMethod nao levantou sobre handle nil.');
  except
    on E: EModernRTTIError do
      if Pos('GetMethod', E.Message) = 0 then
        raise ETestScenarioFailed.Create('Mensagem de GetMethod nao cita o membro.');
  end;
end;
```

**Desbloqueio de divida D-44.6** em `Scenario_PointerType_ReferredType_Nil_ForBarePointer`
(`:1254-1269`):

1. Remover o comentario "NAO tocar em `LReferred.Name`" (e qualquer
   anotacao `D-44.6 / R-4` que o acompanha).
2. Substituir pela asserção:
   ```pascal
   try
     LReferred.Name;
     raise ETestScenarioFailed.Create('Name sobre Pointer nil nao levantou.');
   except
     on EModernRTTIError do { pass — contrato correto };
   end;
   ```
3. Reescrever comentarios `D-44.6 / R-4` em `:310-311` para citar
   "#49 resolvido" em vez de "NAO tocar" / "bloqueado por #49".

### 3. `Test FPC/EclbrSystem/UTestMS.RTTI.pas`

Adicionar apos `TestPointerType_ReferredType_Nil_ForBarePointer` (`:329-331`):

```pascal
published
procedure TestTModernRTTI.TestNilHandle_AllMembers_Raises;
begin
  Scenario_NilHandle_AllMembers_Raises;
end;
```

### 4. `Test Delphi/EclbrSystem/UTestMS.RTTI.pas`

Adicionar apos `:364-366`:

```pascal
[Test]
procedure TestNilHandle_AllMembers_Raises;
begin
  Scenario_NilHandle_AllMembers_Raises;
end;
```

## Checklist de aceitacao

- [ ] `grep -n 'SModernRTTINilHandle' Source/ModernSyntax.RTTI.pas` →
      1 declaracao + 5 usos = 6 linhas.
- [ ] `grep -c 'if FType = nil then' Source/ModernSyntax.RTTI.pas` → 5.
- [ ] `GetFields` sobre handle de record ou enum com `FType <> nil`
      retorna `nil` (nao levanta). Verificar manualmente ou por cenario
      existente de iteracao vazia.
- [ ] `Scenario_NilHandle_AllMembers_Raises` verde em FPC 3.2.2 x86_64
      na fabrica.
- [ ] `Scenario_PointerType_ReferredType_Nil_ForBarePointer` verde (sem
      o "NAO tocar", com a nova asserção de `EModernRTTIError`).
- [ ] Nenhum `{$IFDEF FPC}` novo em `UScenarios.RTTI.pas`.
- [ ] PR body declara resultado de i386 e Delphi (nao compilados na
      fabrica, mas pelo autor humano).
- [ ] PR fecha `Closes #49`.

## Traps a evitar

- **NAO** inserir a guarda de `GetFields` APOS o `is TRttiInstanceType`
  check — isso quebraria o contrato para records/enums validos.
- **NAO** usar `{$IFDEF FPC}` no cenario — a guarda `if FType = nil then`
  e Pascal puro.
- **NAO** compilar `Source/*.pas` inteiro — 0 de 16 units compilam no
  FPC 3.2.2; compile so o projeto de teste (ver [/SKILL.md](/SKILL.md)).
- **Limpar o diretorio `-FU` antes de recompilar** — FPC reutiliza
  `.ppu` e reporta verde sobre codigo velho.
- **NAO** omitir `GetMethod` (singular) — e o quinto membro medido com
  o mesmo defeito.

## Comando de build FPC (referencia rapida)

```bash
rm -rf /tmp/fpcbuild && mkdir -p /tmp/fpcbuild
fpc -Mdelphi \
    -Fu"Source" \
    -Fu"Test Shared/EclbrSystem" \
    -Fu"Test FPC/EclbrSystem" \
    -FU/tmp/fpcbuild -FE/tmp/fpcbuild \
    "Test FPC/EclbrSystem/PTestRTTI.lpr"
/tmp/fpcbuild/PTestRTTI --all -a --format=plain
```

(Ajustar o nome do `.lpr` conforme o arquivo de entrada real do projeto
de teste RTTI — ver a convencao `PTest<Feature>.lpr` em [/SKILL.md](/SKILL.md).)
