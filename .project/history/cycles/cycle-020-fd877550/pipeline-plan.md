---
type: plan
kind: artifact
title: "PLAN — issue #49 em slice unico (contrato nil-handle em TModernRTTIType, cinco membros)"
description: "Slice unico: nova resourcestring SModernRTTINilHandle com %s + cinco guardas em Name/GetProperties/GetFields/GetMethods/GetMethod + cinco XMLDocs + cenario Scenario_NilHandle_AllMembers_Raises pelo caminho publico + desbloqueio D-44.6 + duas cascas de teste. Quatro arquivos, mudancas localizadas. Verdict: fits (uma guarda de nil repetida cinco vezes; nenhum slice e mergeavel sozinho sem o par producao/teste)."
status: draft
cycle: "020"
agent: architect
workflow: equipe-bug
node: architect
resource: aefos://run/fd87755097391831d283adc83e6b8813
tags: [modernrtti, plan, issue-49, bug, nil-handle, fpc, delphi]
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
  - id: skill
    resource: "/SKILL.md"
    title: "SKILL — receita FPC, traps"
---

# PLAN — issue #49 (contrato de handle nil em `TModernRTTIType`)

## Veredicto de tamanho (split guard)

**`fits`** — um unico slice.

- **TEST 1 (SIZE):** Quatro arquivos, mudancas localizadas: uma
  `resourcestring`, cinco guardas identicas `if FType = nil then raise`,
  cinco XMLDocs, um cenario, duas cascas de uma linha, desbloqueio de
  divida. Nenhum desses itens exige mais que uma fracao do budget de
  implementacao.
- **TEST 2 (INDEPENDENCE):** Producao (guardas + `resourcestring`) e
  testes (cenario + cascas) nao sao mergeaveis separadamente — guardas
  sem testes ficam sem cobertura, testes sem guardas ficam com AV.
  Sao um unico pedaco de trabalho.

## Slice 1 (unico) — Nil-handle contract

### Objetivo

Aplicar o contrato definido em [esp](pipeline-esp.md) e [adr](pipeline-adr.md) nos quatro
arquivos afetados, em ordem de dependencia.

### Ordem de execucao recomendada

**Passo 1 — `Source/ModernSyntax.RTTI.pas`** (producao)

1. Adicionar `resourcestring SModernRTTINilHandle` no bloco de strings
   existente (`:860-873`):
   ```pascal
   SModernRTTINilHandle =
     'handle nao inicializado (IsNil = True). Verifique IsNil antes de chamar %s.';
   ```

2. Inserir guarda antes de `Result := FType.Name` em `:1022`
   (`TModernRTTIType.Name`):
   ```pascal
   if FType = nil then
     raise EModernRTTIError.CreateFmt(SModernRTTINilHandle, ['Name']);
   ```

3. Inserir guarda antes de `LProps := FType.GetProperties` em `:1033`
   (`TModernRTTIType.GetProperties`):
   ```pascal
   if FType = nil then
     raise EModernRTTIError.CreateFmt(SModernRTTINilHandle, ['GetProperties']);
   ```

4. Inserir guarda em `:1053` (`TModernRTTIType.GetFields`), **antes**
   do `is TRttiInstanceType` check (ADR D-49.4):
   ```pascal
   if FType = nil then
     raise EModernRTTIError.CreateFmt(SModernRTTINilHandle, ['GetFields']);
   ```

5. Inserir guarda em `:1067` (`TModernRTTITypeHelper.GetMethods`), antes
   do `is` check e antes do `raise SModernRTTIGetMethodsNotClass` que
   contem `FType.Name` sem guarda:
   ```pascal
   if FType = nil then
     raise EModernRTTIError.CreateFmt(SModernRTTINilHandle, ['GetMethods']);
   ```

6. Inserir guarda em `:1074` (`TModernRTTITypeHelper.GetMethod`), antes
   das duas referencias a `FType.Name` dentro dos `raise` em `:1075`
   e `:1077`:
   ```pascal
   if FType = nil then
     raise EModernRTTIError.CreateFmt(SModernRTTINilHandle, ['GetMethod']);
   ```

7. Adicionar `<remarks>` XMLDoc em cinco declaracoes da `interface`:
   - `:176` (`Name`)
   - `:193` (`GetProperties`)
   - `:205` (`GetFields`)
   - `:373` (`GetMethods`)
   - `:380` (`GetMethod`) — soma ao bloco existente, nao substitui.

**Passo 2 — `Test Shared/EclbrSystem/UScenarios.RTTI.pas`** (cenario)

1. Declarar `Scenario_NilHandle_AllMembers_Raises` na `interface`
   (perto de `:305-311`).

2. Implementar na `implementation`: construir o handle via
   `TModernRTTIContext.Create` + `FindType('TipoQueNaoExiste_Issue49')`,
   e afirmar `EModernRTTIError` nos cinco membros com verificacao de
   mensagem em cada `except`.

3. Em `Scenario_PointerType_ReferredType_Nil_ForBarePointer` (`:1254-1269`):
   remover o comentario "NAO tocar em `LReferred.Name`"; adicionar o
   bloco `try/except` que afirma `EModernRTTIError` em `LReferred.Name`.

4. Reescrever comentarios `D-44.6 / R-4` em `:310-311` e `:1259-1265`
   para citar #49 como resolvido.

**Passo 3 — `Test FPC/EclbrSystem/UTestMS.RTTI.pas`** (casca FPC)

Adicionar `published TestNilHandle_AllMembers_Raises` de uma linha apos
o padrao de `:329-331`:

```pascal
procedure TestTModernRTTI.TestNilHandle_AllMembers_Raises;
begin
  Scenario_NilHandle_AllMembers_Raises;
end;
```

**Passo 4 — `Test Delphi/EclbrSystem/UTestMS.RTTI.pas`** (casca Delphi)

Adicionar `[Test] TestNilHandle_AllMembers_Raises` de uma linha apos
`:364-366`:

```pascal
[Test]
procedure TestNilHandle_AllMembers_Raises;
begin
  Scenario_NilHandle_AllMembers_Raises;
end;
```

### Arquivos impactados

| # | Arquivo | Mudanca |
|---|---------|---------|
| A1 | `Source/ModernSyntax.RTTI.pas` | `resourcestring SModernRTTINilHandle` |
| A2 | `Source/ModernSyntax.RTTI.pas` | Guarda em `Name` (`:1022`) |
| A3 | `Source/ModernSyntax.RTTI.pas` | Guarda em `GetProperties` (`:1033`) |
| A4 | `Source/ModernSyntax.RTTI.pas` | Guarda em `GetFields` (`:1053`, antes do `is`) |
| A5 | `Source/ModernSyntax.RTTI.pas` | Guarda em `GetMethods` (`:1067`) |
| A6 | `Source/ModernSyntax.RTTI.pas` | Guarda em `GetMethod` (`:1074`) |
| A7 | `Source/ModernSyntax.RTTI.pas` | XMLDoc `<remarks>` em `:176`, `:193`, `:205`, `:373`, `:380` |
| B1 | `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | `Scenario_NilHandle_AllMembers_Raises` |
| B2 | `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | Desbloqueio D-44.6 (`:1254-1269`) |
| B3 | `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | Reescrever comentarios D-44.6/R-4 |
| C1 | `Test FPC/EclbrSystem/UTestMS.RTTI.pas` | `TestNilHandle_AllMembers_Raises` |
| D1 | `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` | `TestNilHandle_AllMembers_Raises` |

### Criterios de done (check rapido)

- [ ] `grep -n 'SModernRTTINilHandle' Source/ModernSyntax.RTTI.pas` →
      pelo menos 6 linhas (1 declaracao + 5 usos).
- [ ] `grep -n 'if FType = nil then' Source/ModernSyntax.RTTI.pas` →
      exatamente 5 resultados.
- [ ] FPC x86_64 compila e suite verde (factory). i386 e Delphi:
      declarado no PR.
- [ ] `GetFields` sobre handle de record valido → `nil` (contrato
      preservado; nao levanta).
