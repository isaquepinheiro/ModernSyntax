---
type: implement-report
kind: artifact
title: "Implement report — TModernRTTIField portável nos dois compiladores (issue #21)"
description: "Três arquivos tocados conforme plan; FPC x86_64 verde (6 testes, 0 falhas) incluindo o novo TestGetFields_EnumeratesInheritedPublishedClassFields; i386 não coberto na fábrica (sem ppc386) — fica com o autor."
status: stable
cycle: "008"
agent: developer
workflow: equipe-feature
node: implement
resource: aefos://run/e4baa827945b3dd3a372629b831d73a9
tags: [modernrtti, implement, issue-21, fpc, delphi]
generated:
  by: "equipe-feature@node:implement"
  at: "2026-08-31T00:00:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — issue #21"
  - id: adr
    resource: "adr.md"
    title: "ADR — issue #21"
  - id: plan
    resource: "plan.md"
    title: "Plan — issue #21"
  - id: task-input
    resource: "task-input.md"
    title: "Task input — issue #21"
---

# Implement report — TModernRTTIField portável (issue #21)

## O que mudou

Três arquivos, uma entrega — F1/F2/F3 do [plan](pipeline-plan.md) aplicadas em
sequência.

### Arquivos modificados

| Arquivo | Fatia | Delta |
|---|---|---|
| `Source/ModernSyntax.RTTI.pas` | F1 | 6 pontos: remoção do `{$IFNDEF FPC}` externo sobre `TModernRTTIField` e `GetFields`; ramificação em `strict private` (FPC: `FOwner/FName/FOffset`; Delphi: `FField`); factories privadas com nomes distintos por branch (`FromRaw` no FPC, `FromRtti` no Delphi); XMLDoc reescrito em voz de contrato com "no FPC" e "ordem não especificada"; implementação por offset absoluto no FPC (`Move`/`PPointer`) e loop de herança em `GetFields` FPC via `PVmt(Pointer(LCur))^.vFieldTable` tipada + `LTab^.Field[LI]` (property) + `string(LEntry^.Name)` (cast ShortString) + `ClassParent`. |
| `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | F2 | Nova fixture com herança `TInner`/`TBase`/`TPortableFieldFixture` (`{$M+}...{$M-}`); nova procedure `Scenario_GetFields_EnumeratesInheritedPublishedClassFields` com assertiva de contagem EXATA (`Length = 2`) e busca por nome (sem dependência de ordem, D10 do [adr](pipeline-adr.md)). |
| `Test FPC/EclbrSystem/UTestMS.RTTI.pas` | F3 | Removida a linha 16 (comentário-mentira "TModernRTTIField é Delphi-only"); adicionada casca fina `TestGetFields_EnumeratesInheritedPublishedClassFields` (uma linha útil, sem `if`/`Assert` na casca). |

Adicionalmente, marcador do ciclo em `.project/project-evolution.md`
avançado de 🔄 in-pipeline para 🔄 in-review (exigência do próprio nó
`implement`, não é código de produto — CA-6 sobre delivery permanece
íntegro).

### Arquivos NÃO tocados (por design)

- `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` — permanece com o
  `TestGetFields_ReturnsFields` sobre `TFieldFixture` (campos `public`
  escalares), cobertura Delphi-only real que a `vmtFieldTable` do FPC
  não veria (§2 do [esp](pipeline-esp.md)).
- `Source/ModernSyntax.inc` — R3 do PRD (contornar o typo `FCP`, não
  consertar).
- Qualquer outra unit de `Source/` — nota da issue.

## Decisões técnicas aplicadas (rastreabilidade 1-para-1)

- **D2 do [adr](pipeline-adr.md):** ramificação vive apenas em `strict private` do
  record e na `implementation`. Nenhum `{$IFDEF FPC}` na assinatura
  pública. Verificado por grep sobre a região das declarações.
- **D3:** duas factories privadas com nomes distintos por branch.
  Colocadas em `private` (não `strict`) para que `TModernRTTIType.GetFields`
  possa chamá-las na mesma unit — igual padrão do
  `TModernRTTIProperty.FromRtti` existente. Consumidor externo não vê.
- **D4:** `PVmtFieldTable(PVmt(Pointer(LCur))^.vFieldTable)` — via
  `PVmt`/`TVmt` (`objpash.inc`) e `PVmtFieldTable` (`TypInfo`, já no
  `uses`). Sem aritmética `PByte + vmtFieldTable`.
- **D5:** iteração pela property `LTab^.Field[LI]` (tamanho variável de
  `TVmtFieldEntry.Name: ShortString`).
- **D6:** subida por `ClassParent` com duas passadas (contar → alocar →
  preencher). Elos com `vFieldTable = nil` são pulados, não geram erro.
- **D7:** cadeia inteira sem campos devolve array vazio (`Result := nil`
  antes do `SetLength`).
- **D8:** cast explícito `string(LEntry^.Name)`.
- **D9:** overload `TValue` no FPC usa `TValue.From<TObject>` no leitor e
  `Pointer(AValue.AsObject)` no gravador. O custo (`uses Rtti` +
  warning `experimental`) já estava pago pela unit.
- **D10:** XMLDoc de `GetFields` declara "ordem NÃO é especificada —
  consumidores devem buscar por nome, não indexar por posição". O
  cenário respeita isso (busca por nome, `LFoundA`/`LFoundB`).
- **D11:** palavra "no FPC" aparece 5 vezes na produção (XMLDoc
  reescrito em voz de contrato, sem lamento de limite).
- **D12:** fixture forma B (`TInner` nomeado) com herança; assertiva
  `Length = 2` exata (não `>= 1`).
- **D13:** `TModernRTTIField` público incondicional; consumidores antigos
  protegidos por `{$IFDEF FPC}` continuam compilando (o guard fica
  desnecessário mas não quebra).

## Validações executadas

### Toolchain descoberto (documentado em [SKILL](../../../SKILL.md))

Seção *"Toolchain & quality commands (agent-discovered 2026-08-28)"*
já contém a receita FPC — este ciclo a usou sem retoques adicionais,
então **não** houve enriquecimento novo do SKILL.

- **FPC 3.2.2 x86_64 — compilação verde.**
  ```
  rm -rf /tmp/rtti21_x64 && mkdir -p /tmp/rtti21_x64 && \
  fpc -Mdelphi \
      -Fu"Source" -Fu"Test Shared/EclbrSystem" -Fu"Test FPC/EclbrSystem" \
      -FU/tmp/rtti21_x64 -FE/tmp/rtti21_x64 \
      "Test FPC/EclbrSystem/PTestRTTI.lpr"
  ```
  → `812 lines compiled, 0.3 sec, 2 warning(s) issued` (nenhum erro).

  As duas warnings são pré-existentes: (i) `Unit "Rtti" is experimental`
  (herança do `uses Rtti` original da unit — o custo já estava pago), e
  (ii) `function result variable of a managed type does not seem to be
  initialized` em `GetProperties` (código que este ciclo NÃO tocou).

- **Execução dos testes FPC x86_64 — 6/6 verdes.**
  ```
  /tmp/rtti21_x64/PTestRTTI --all -a --format=plain
  ```
  Saída:
  ```
    TTestModernRTTI Time:00.000 N:6 E:0 F:0 I:0
      TestGetProperties_ReturnsPublishedProps
      TestGetValue_Integer_Roundtrip
      TestGetValue_String_Roundtrip
      TestGetValue_Currency_Roundtrip
      TestMissingM_RaisesEModernRTTIError
      TestGetFields_EnumeratesInheritedPublishedClassFields   ← novo (CA-3)
  Number of run tests: 6 / Number of errors: 0 / Number of failures: 0
  ```

- **FPC i386 — NÃO executado na fábrica** (limite conhecido de
  [SKILL](../../../SKILL.md): `ppc386` retorna `127`, não há cross-compiler).
  Fica com o autor no ambiente Windows — declarado no corpo do PR
  conforme CA-8 do [esp](pipeline-esp.md).

- **Delphi (`dcc32`) — não executado** (fábrica não tem Delphi).
  Fica com o autor. Declarado no corpo do PR (CA-8).

### Greps de aceite (do [plan](pipeline-plan.md) §"Verificações finais")

- `grep -n 'TModernRTTIField\|GetFields' Source/ModernSyntax.RTTI.pas`
  → nenhuma ocorrência dentro de `{$IFNDEF FPC}` (CA-1 ✓).
- `grep -rn '{\$IFDEF FPC}\|{\$IFNDEF FPC}' <3 arquivos de teste>` →
  zero linhas (CA-2 ✓).
- `grep -n 'no FPC' Source/ModernSyntax.RTTI.pas` → 5 ocorrências
  (CA-4 ✓, > 2 exigido).
- `grep -n 'ordem' Source/ModernSyntax.RTTI.pas` → 1 ocorrência no
  XMLDoc de `GetFields` (CA-4 ✓).
- `grep -n 'Sem TestGetFields aqui' 'Test FPC/EclbrSystem/UTestMS.RTTI.pas'`
  → vazio (CA-7 ✓).
- Diff de código-fonte: apenas os três arquivos listados (CA-6 ✓;
  mudanças em `.project/` são pipeline, fora do escopo do CA-6).

## Caveats / riscos residuais

- **RSK-1 — fixture com herança não medida em `dcc32` neste ciclo.**
  Sintaxe padrão `{$M+} class end` com herança; risco baixo. Se falhar
  em Delphi, o fallback do [esp](pipeline-esp.md) §6 é reduzir o `{$M+}` a
  bloco isolado de `TInner`. Não altera o contrato.
- **RSK-2 — `TValue.From<TObject>` no FPC 3.2.2** pode falhar para `T`
  genérico complexo. O overload `TValue` cru é o caminho recomendado
  para esses casos. Não exercitado no cenário deste ciclo (só campo
  `TInner`), então caveat teórico.
- **Warning pré-existente em `GetProperties`.** A mensagem sobre
  "managed type not initialized" está no `SetLength(Result, ...)` do
  `GetProperties` — código não tocado neste ciclo. Correção fora do
  escopo (issue #21 restringe a `TModernRTTIField`/`GetFields`).
- **`AOwner` guarda o elo declarante** (RN-8/D6), não a classe raiz. Por
  ora este campo é apenas informativo (útil para debug); nenhum método
  público o expõe — mas está preservado para futuras diagnósticos sem
  quebrar layout.

## Handoff

- CA-1 a CA-7 medidos aqui. CA-5 (i386) e CA-8 (declaração no corpo do
  PR) ficam com o `committer` / autor.
- Board local: `project-evolution.md` avançado de 🔄 in-pipeline para
  🔄 in-review.

## Referências

- [esp](pipeline-esp.md)
- [adr](pipeline-adr.md)
- [plan](pipeline-plan.md)
- [task-input](pipeline-task-input.md)
- [SKILL](../../../SKILL.md)
