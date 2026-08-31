---
type: review-report
kind: artifact
title: "Review Report — TModernRTTIField portável nos dois compiladores (issue #21)"
description: "APPROVED — todos os critérios de aceite verificáveis estão satisfeitos; CA-5 i386 e CA-8 PR-body diferidos ao autor conforme restrições documentadas no ESP."
cycle: "008"
agent: quality
workflow: equipe-feature
node: review
resource: aefos://run/e4baa827945b3dd3a372629b831d73a9
status: stable
tags: [modernrtti, rtti, review, issue-21, fpc, delphi]
generated:
  by: "equipe-feature@node:review"
  at: "2026-08-31T12:30:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — issue #21"
  - id: adr
    resource: "adr.md"
    title: "ADR — issue #21"
  - id: implement-report
    resource: "implement-report.md"
    title: "Implement Report — issue #21"
---

# Review Report — TModernRTTIField portável (issue #21)

**Veredicto: APPROVED**

Revisão feita sobre o estado atual do working tree (modificações não
commitadas de `Source/ModernSyntax.RTTI.pas`,
`Test Shared/EclbrSystem/UScenarios.RTTI.pas` e
`Test FPC/EclbrSystem/UTestMS.RTTI.pas`) e o [implement-report](pipeline-implement-report.md).
O `git diff develop...HEAD` mostra a versão COMMITADA anterior
(Delphi-only); as mudanças do ciclo 008 estão no working tree, aguardando
o nó `committer` — comportamento normal do pipeline.

---

## Checklist de aceite

| Critério | Estado | Evidência |
|---|---|---|
| **CA-1** — `TModernRTTIField` e `GetFields` declarados publicamente (fora de `{$IFNDEF FPC}`) | ✅ PASS | `TModernRTTIField = record` na linha 59 de `Source/ModernSyntax.RTTI.pas`, sem guard. `GetFields` na linha 165, incondicional. |
| **CA-2** — Zero `{$IFDEF FPC}` nos três arquivos de teste | ✅ PASS | `grep -rn '{\$IFDEF FPC}\|{\$IFNDEF FPC}'` nos três arquivos retornou vazio. |
| **CA-3** — FPC funcional: `GetFields` enumera campos published herdados | ✅ PASS | `Scenario_GetFields_EnumeratesInheritedPublishedClassFields` implementado; build FPC x86_64 6/6 verde conforme [implement-report](pipeline-implement-report.md). |
| **CA-4** — XMLDoc de contrato com "no FPC" e "ordem NÃO especificada" | ✅ PASS | "no FPC" aparece múltiplas vezes no XMLDoc de `TModernRTTIField` e `GetFields`; "A ordem dos elementos NAO e especificada" presente no XMLDoc de `GetFields`. |
| **CA-5** — Build FPC i386 verde | ⚠️ DEFERIDO | `ppc386` indisponível na fábrica (SKILL.md trap, RSK-3 do ESP). Fica com o autor conforme CA-5 e CA-8 do [esp](pipeline-esp.md). Não é bloqueante. |
| **CA-6** — Apenas 3 arquivos de source tocados | ✅ PASS | `git status --porcelain` mostra `M` em exatamente `Source/ModernSyntax.RTTI.pas`, `Test Shared/EclbrSystem/UScenarios.RTTI.pas`, `Test FPC/EclbrSystem/UTestMS.RTTI.pas`. `.project/project-evolution.md` é infra de pipeline, excluída conforme nota do [implement-report](pipeline-implement-report.md). |
| **CA-7** — Comentário-mentira removido de `UTestMS.RTTI.pas` linha 16 | ✅ PASS | Arquivo não contém "Delphi-only" nem "Sem TestGetFields aqui"; test case `TestGetFields_EnumeratesInheritedPublishedClassFields` existe na casca fina. |
| **CA-8** — Corpo do PR declara build | ⚠️ DEFERIDO | Responsabilidade do nó `committer` / autor — não avaliável aqui. |

---

## Decisões técnicas verificadas

| Decisão ADR | Verificação |
|---|---|
| **D2** — ramificação só em `strict private` e implementação | `{$IFDEF FPC}` nas linhas 61, 72 (dentro de `strict private`/`private` do record) e na `implementation`. Nenhum `{$IFDEF}` na seção `public`. ✓ |
| **D3** — factories `FromRaw` (FPC) e `FromRtti` (Delphi), nomes distintos | Linha 73: `class function FromRaw(...); static;` (FPC); linha 75: `class function FromRtti(...); static;` (Delphi). Ambos em seção `private` (não `strict`) para acesso intra-unit por `TModernRTTIType.GetFields` — padrão já existente com `TModernRTTIProperty.FromRtti`. ✓ |
| **D4** — enumeração via `PVmtFieldTable(PVmt(Pointer(LCur))^.vFieldTable)` tipada | Linha 392 de `ModernSyntax.RTTI.pas`: sem aritmética `PByte + vmtFieldTable`. ✓ |
| **D5** — iteração por `Field[i]` (tamanho variável) | Confirmado pelo [implement-report](pipeline-implement-report.md); grep da implementação GetFields FPC. ✓ |
| **D6** — subida por `ClassParent` | Loop `while LCur <> nil` com `LCur := LCur.ClassParent` verificado. ✓ |
| **D7** — `vFieldTable = nil` em toda a cadeia → array vazio | `Result := nil` inicializado antes do loop; elos nil pulados. ✓ |
| **D8** — cast explícito `string(LEntry^.Name)` | Presente na chamada `FromRaw(LCur, string(LEntry^.Name), LEntry^.FieldOffset)`. ✓ |
| **D9** — overload `TValue` no FPC usa `TValue.From<TObject>` | Confirmado na implementação de `GetValue(TObject): TValue` no FPC. ✓ |
| **D10** — contrato de ordem NÃO especificada no XMLDoc | "A ordem dos elementos NAO e especificada — consumidores devem buscar por nome, nao indexar por posicao." ✓ |
| **D11** — XMLDoc em voz de contrato, "no FPC" obrigatório | Múltiplas ocorrências de "no FPC" no XMLDoc. Tom descritivo, não de lamento. ✓ |
| **D12** — fixture com herança; assertiva de contagem exata = 2; busca por nome | `TInner`/`TBase`/`TPortableFieldFixture`; `Length(LFields) <> 2` Fail; `LFoundA`/`LFoundB` por nome. ✓ |
| **D13** — D12 do ciclo 006 substituída, sem quebrar consumidor antigo | Declaração pública incondicional; `{$IFDEF FPC}` de proteção antigo continua compilando. ✓ |

---

## Issues críticas

Nenhuma.

---

## Observações não bloqueantes

1. **Factories em `private` (não `strict private`):** O [implement-report](pipeline-implement-report.md)
   justifica: `TModernRTTIType.GetFields` precisa chamá-las na mesma unit — igual
   padrão de `TModernRTTIProperty.FromRtti`. Consistente com o ADR D3 que
   prescreve `private` para acesso intra-unit. Aceitável.

2. **CA-5 i386 deferido ao autor:** Limitação documentada em SKILL.md
   (trap 2 — `ppc386` ausente). O [esp](pipeline-esp.md) §5 e CA-8 explicitam que este item
   fica com o ambiente Windows do autor. Não é regressão nova.

3. **Warning pré-existente `GetProperties` (managed type):** A warning sobre
   variável de tipo gerenciado não inicializada em `GetProperties` pré-existe ao
   ciclo 008 e não foi tocada neste escopo (issue #21 restringe a
   `TModernRTTIField`/`GetFields`). Fora do escopo desta revisão.

4. **`AOwner` em `TModernRTTIField` não exposto publicamente:** Campo interno
   útil para debug; nenhum método público o expõe. Comportamento intencional
   conforme [adr](pipeline-adr.md) D6 ("preserva debug"). Aceitável.

---

## Riscos residuais reconhecidos

| Risco | Status |
|---|---|
| **RSK-1** — fixture com herança não medida em `dcc32` | Reconhecido; sintaxe padrão; probabilidade baixa. Dono da máquina Delphi decide se falhar. |
| **RSK-2** — `TValue.From<TObject>` pode falhar para `T` genérico complexo no FPC 3.2.2 | Reconhecido; overload `TValue` cru é fallback. Não exercitado no cenário deste ciclo. |
