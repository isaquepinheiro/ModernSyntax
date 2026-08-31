---
type: plan
kind: artifact
title: "Plan — TModernRTTIField portável nos dois compiladores (issue #21)"
description: "Três fatias sequenciais: produção (Source/ModernSyntax.RTTI.pas com 6 pontos de mudança), cenário compartilhado (nova fixture com herança + procedure de contagem exata), casca FPC (remover linha 16 e adicionar TestGetFields_EnumeratesInheritedPublishedClassFields)."
status: draft
cycle: "008"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/e4baa827945b3dd3a372629b831d73a9
tags: [modernrtti, plan, issue-21, fpc, delphi]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-08-31T00:00:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — issue #21"
  - id: adr
    resource: "adr.md"
    title: "ADR — issue #21"
---

# Plan — TModernRTTIField portável (issue #21)

Três fatias sequenciais para revisibilidade. **Uma única entrega** — as
fatias existem para tornar o diff legível por seção, não para permitir
merge independente: sem a produção, os testes não linkam; sem o cenário
compartilhado, a casca FPC não tem o que chamar.

## Fatia 1 — Produção: `Source/ModernSyntax.RTTI.pas`

**Objetivo:** aplicar os 6 pontos de mudança na unit de produção. O
arquivo é o **único** de produção tocado.

**Arquivos:** `Source/ModernSyntax.RTTI.pas` — MODIFICAR.

**Pontos de mudança (mapeados do REPORT):**

1. **`:50-78` (A1) — declaração ramificada.** Remove `{$IFNDEF FPC}`
   externo. `TModernRTTIField` público incondicional. Ramificação em
   `strict private`:
   ```pascal
   {$IFDEF FPC}
   FOwner: TClass; FName: string; FOffset: PtrUInt;
   {$ELSE}
   FField: TRttiField;
   {$ENDIF}
   ```
   Factories privadas: `FromRaw` no FPC (`class function FromRaw(AOwner:
   TClass; const AName: string; AOffset: PtrUInt): TModernRTTIField;
   static;`), `FromRtti` no Delphi (`class function FromRtti(const AField:
   TRttiField): TModernRTTIField; static;`) — D3 do [ADR](pipeline-adr.md).

2. **`:53-57` (A2) — XMLDoc de `TModernRTTIField`.** Remove
   "Superfície Delphi-only...". Substitui por texto em voz de contrato,
   com a palavra **"no FPC"** — D11 do [ADR](pipeline-adr.md), CA-4 do
   [ESP](pipeline-esp.md).

3. **`:119-128` (A4) — remarks de ownership.** Remove o parêntese "(e
   TModernRTTIField no Delphi)" — o tipo passa a existir nos dois.

4. **`:135-143` (A3) — interface de `GetFields`.** Remove `{$IFNDEF FPC}`
   externo. Assinatura preservada: `function GetFields: TArray<TModernRTTIField>;`.
   XMLDoc ganha (i) descrição portável, (ii) linha do contrato "ordem
   não especificada — consumidores devem buscar por nome, não indexar por
   posição" (D10 do ADR), (iii) nota "no FPC" sobre cobertura de campos.

5. **`:234-264` (A5) — implementação de `TModernRTTIField`.** Remove
   `{$IFNDEF FPC}` externo. Cada método ganha ramificação interna:
   - `Name`: FPC devolve `FName`; Delphi devolve `FField.Name`.
   - `GetValue<T>`: FPC lê por offset (`Move((PByte(AInstance) + FOffset)^,
     Result, SizeOf(T))`); Delphi mantém `FField.GetValue(AInstance).AsType<T>`.
   - `SetValue<T>`: FPC escreve por offset (`Move(AValue, (PByte(AInstance)
     + FOffset)^, SizeOf(T))`); Delphi mantém
     `FField.SetValue(AInstance, TValue.From<T>(AValue))`.
   - `GetValue: TValue` FPC: `TValue.From<TObject>(PPointer(PByte(AInstance)
     + FOffset)^)` — D9 do ADR.
   - `SetValue(TValue)` FPC: `PPointer(PByte(AInstance) + FOffset)^ :=
     TObject(AValue.AsObject)` — D9.
   - `FromRaw`/`FromRtti` conforme ponto 1.

6. **`:303-314` (A6) — `TModernRTTIType.GetFields`.** Remove `{$IFNDEF FPC}`
   externo. Delphi (`{$ELSE}`) mantém `FType.GetFields` chamando
   `TModernRTTIField.FromRtti(LFields[LIdx])`. FPC (`{$IFDEF FPC}`) faz o
   **loop de herança** — D6 do ADR:
   ```pascal
   LCur := TClass(FType.AsInstance.MetaclassType);
   while LCur <> nil do
   begin
     LTab := PVmtFieldTable(PVmt(LCur)^.vFieldTable);   // D4 (tipado)
     if LTab <> nil then                                 // D7 (nil = pula)
       for LI := 0 to LTab^.Count - 1 do
       begin
         LEntry := LTab^.Field[LI];                      // D5 (property)
         Append(TModernRTTIField.FromRaw(LCur,
                string(LEntry^.Name),                    // D8 (cast ShortString)
                LEntry^.FieldOffset));
       end;
     LCur := LCur.ClassParent;                           // D6 (sobe)
   end;
   ```
   `AOwner := LCur` guarda o elo declarante — D6/RN-8.

**Regras aplicáveis:** RN-1 a RN-12 do [esp](pipeline-esp.md); D1 a D11, D13 do
[adr](pipeline-adr.md).

**Atenção — armadilhas do FPC (medidas):**
- **Nunca aritmética** `PByte(LClass) + vmtFieldTable` — usar `PVmt(LClass)^.vFieldTable`.
- **Nunca `LTab^.Fields[i]`** como array — usar a property `LTab^.Field[i]`.
- **Sempre** `string(LEntry^.Name)` — `TVmtFieldEntry.Name` é `ShortString`.
- **Sempre** subir por `ClassParent` — sem isso, Delphi/FPC divergem em
  silêncio.

**Feito quando:**
- `grep -n '{\$IFNDEF FPC}' Source/ModernSyntax.RTTI.pas` **não mostra**
  ocorrências envolvendo `TModernRTTIField` ou `GetFields`.
- `grep -n 'FromRaw\|FromRtti' Source/ModernSyntax.RTTI.pas` mostra as
  duas factories, cada uma no seu branch.
- `grep -n 'no FPC' Source/ModernSyntax.RTTI.pas` mostra ao menos duas
  ocorrências (XMLDoc de `TModernRTTIField` e de `GetFields`).
- `grep -n 'ordem' Source/ModernSyntax.RTTI.pas` mostra a linha "ordem
  não especificada" no XMLDoc de `GetFields`.
- Cabeçalho `(* … *)` intacto; nenhum `{$mode objfpc}`; nenhum
  `{$I ModernSyntax.inc}`.

## Fatia 2 — Cenário compartilhado: fixture com herança

**Objetivo:** dar ao teste algo **load-bearing** que prove a subida por
`ClassParent`. Sem herança, o cenário passaria verde com D6 quebrada.

**Arquivos:** `Test Shared/EclbrSystem/UScenarios.RTTI.pas` — MODIFICAR.

**Adicionar:**

```pascal
{$M+}
TInner  = class end;
TBase   = class
  InnerA: TInner;
end;
TPortableFieldFixture = class(TBase)
  InnerB: TInner;
end;
{$M-}

procedure Scenario_GetFields_EnumeratesInheritedPublishedClassFields;
var
  LFields: TArray<TModernRTTIField>;
  LIdx: Integer;
  LFoundA, LFoundB: Boolean;
begin
  LFields := TModernRTTI.GetType(TPortableFieldFixture).GetFields;
  Assert(Length(LFields) = 2, 'esperava 2 campos, obtive ' +
    IntToStr(Length(LFields)));
  LFoundA := False; LFoundB := False;
  for LIdx := 0 to High(LFields) do
  begin
    if LFields[LIdx].Name = 'InnerA' then LFoundA := True;
    if LFields[LIdx].Name = 'InnerB' then LFoundB := True;
  end;
  Assert(LFoundA, 'campo InnerA não encontrado');
  Assert(LFoundB, 'campo InnerB não encontrado');
end;
```

**Regras aplicáveis:** RN-13, RN-14, RN-15 do [esp](pipeline-esp.md); D12 do
[adr](pipeline-adr.md).

**Feito quando:**
- `grep -n 'TPortableFieldFixture\|Scenario_GetFields_EnumeratesInherited'
  'Test Shared/EclbrSystem/UScenarios.RTTI.pas'` mostra o novo bloco.
- `grep -n '{\$IFDEF FPC}\|{\$IFNDEF FPC}' 'Test Shared/EclbrSystem/UScenarios.RTTI.pas'`
  → zero linhas (CA-2 do ESP).
- Assertiva `Length(LFields) = 2` **exata** (não `>= 1`).
- Verificação dos nomes por busca, **sem depender de ordem**.

## Fatia 3 — Casca FPC: remover mentira, adicionar teste

**Objetivo:** casca fina FPC que chama a linha útil da fatia 2 e
remover a linha 16 (comentário que agora é falso).

**Arquivos:** `Test FPC/EclbrSystem/UTestMS.RTTI.pas` — MODIFICAR.

**Ações:**

1. **Remover a linha 16** (comentário "Sem TestGetFields aqui:
   TModernRTTIField é Delphi-only (D12 do ADR)"). Deixa de ser verdade.
2. **Adicionar** o método publicado à `TTestRTTI`:
   ```pascal
   procedure TestGetFields_EnumeratesInheritedPublishedClassFields; published;
   ```
   Implementação: uma única linha útil.
   ```pascal
   procedure TTestRTTI.TestGetFields_EnumeratesInheritedPublishedClassFields;
   begin
     Scenario_GetFields_EnumeratesInheritedPublishedClassFields;
   end;
   ```

**Regras aplicáveis:** RN-13 do [esp](pipeline-esp.md); D9 do
[ADR ciclo 006](/history/cycles/cycle-006-0432fa58/pipeline-adr.md), D12 do [adr](pipeline-adr.md).

**Feito quando:**
- `grep -n 'TestGetFields_EnumeratesInheritedPublishedClassFields' \
  'Test FPC/EclbrSystem/UTestMS.RTTI.pas'` mostra a declaração e a
  implementação (linha única útil).
- `grep -n 'Sem TestGetFields aqui' 'Test FPC/EclbrSystem/UTestMS.RTTI.pas'` → vazio.
- `grep -n '{\$IFDEF FPC}\|{\$IFNDEF FPC}' 'Test FPC/EclbrSystem/UTestMS.RTTI.pas'` → vazio.
- `grep -n 'if\|Assert\|then' 'Test FPC/EclbrSystem/UTestMS.RTTI.pas'`
  **não mostra** ramificação/asserção na casca (só o `procedure Test…
  begin Scenario_… end`).

## Dependência entre fatias

- **F1 → F2:** F2 depende de `TModernRTTIField` público existir para
  compilar em qualquer alvo; e depende do `GetFields` FPC subir cadeia
  para a assertiva `= 2` bater.
- **F2 → F3:** F3 chama `Scenario_GetFields_EnumeratesInheritedPublishedClassFields`;
  sem F2, F3 não linka.

Por isso este plano é **fits, não split**: as três fatias formam um
todo coerente que só entrega sentido merged juntas.

## Verificações finais do PR (checklist executável)

Antes de abrir o PR, o implementador roda (na raiz do repo):

```bash
# CA-2 do ESP — zero {$IFDEF FPC} nos três arquivos de teste
grep -rn '{\$IFDEF FPC}\|{\$IFNDEF FPC}' \
  'Test Shared/EclbrSystem/UScenarios.RTTI.pas' \
  'Test Delphi/EclbrSystem/UTestMS.RTTI.pas' \
  'Test FPC/EclbrSystem/UTestMS.RTTI.pas'
# → zero linhas

# CA-1 — declarações públicas fora de {$IFNDEF FPC}
grep -n 'TModernRTTIField\|GetFields' Source/ModernSyntax.RTTI.pas
# → nenhuma ocorrência dentro de {$IFNDEF FPC}

# CA-4 — palavra "no FPC" no XMLDoc
grep -n 'no FPC' Source/ModernSyntax.RTTI.pas
# → ao menos duas ocorrências (TModernRTTIField e GetFields)

# CA-7 — comentário-mentira removido
grep -n 'Sem TestGetFields aqui' 'Test FPC/EclbrSystem/UTestMS.RTTI.pas'
# → vazio

# RN-4/RN-4a herdadas — sem .inc, sem FCP, sem mode objfpc na produção
grep -n '{\$I ModernSyntax.inc}\|FCP\|mode objfpc' Source/ModernSyntax.RTTI.pas
# → vazio

# CA-5 — build FPC nos dois bitness (LIMPAR output ANTES)
rm -rf /tmp/rtti21_x64 && fpc -Mdelphi \
    -Fu"Source" -Fu"Test Shared/EclbrSystem" \
    -FU/tmp/rtti21_x64 -FE/tmp/rtti21_x64 \
    "Test FPC/EclbrSystem/PTestRTTI.lpr"
# → 0 errors

rm -rf /tmp/rtti21_i386 && fpc -Mdelphi -Pi386 \
    -Fu"Source" -Fu"Test Shared/EclbrSystem" \
    -FU/tmp/rtti21_i386 -FE/tmp/rtti21_i386 \
    "Test FPC/EclbrSystem/PTestRTTI.lpr"
# → 0 errors

# CA-6 — só três arquivos tocados
git diff --name-only origin/main...HEAD
# → apenas:
#   Source/ModernSyntax.RTTI.pas
#   Test Shared/EclbrSystem/UScenarios.RTTI.pas
#   Test FPC/EclbrSystem/UTestMS.RTTI.pas
```

Declara no corpo do PR (CA-8): *"Compilado em FPC 3.2.2 x86_64 e i386 —
verde nos dois; não compilado em Delphi — Delphi permanece com o autor."*
