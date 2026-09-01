---
type: test-report
kind: artifact
title: "TEST-REPORT — TModernVisibility / issue #42 (cycle 015)"
description: "Suite FPC 30/30 verde; todos os 10 criterios de aceitacao verificados; mutacao CA-9 confirmada pelo developer e revalidada pelo test runner. APROVADO."
status: stable
cycle: "015"
agent: quality
workflow: equipe-feature
node: test
resource: aefos://run/bb89abe1aa455add801745cb2a527e99
tags: [modernrtti, test-report, issue-42, fpc, delphi, visibility, tmodernvisibility, cycle-015]
generated:
  by: "equipe-feature@node:test"
  at: "2026-09-01T00:00:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — TModernVisibility (issue #42)"
  - id: implement-report
    resource: "implement-report.md"
    title: "IMPLEMENT-REPORT — issue #42"
---

# TEST-REPORT — issue #42 (TModernVisibility, cycle 015)

Referencia: [esp](pipeline-esp.md) · [implement-report](pipeline-implement-report.md)

## Testes executados

### Suite principal FPC 3.2.2 x86_64

Comando:
```
rm -rf /tmp/fpcbuild && mkdir -p /tmp/fpcbuild
fpc -Mdelphi -Fu"Source" -Fu"Test Shared/EclbrSystem" \
    -Fu"Test FPC/EclbrSystem" \
    -FU/tmp/fpcbuild -FE/tmp/fpcbuild \
    "Test FPC/EclbrSystem/PTestRTTI.lpr"
/tmp/fpcbuild/PTestRTTI --all -a --format=plain
```

Resultado: **30 tests / 0 errors / 0 failures / exit=0**

Novos tests passando neste ciclo:
- `TestMethod_Visibility_FPC_Raises`
- `TestProperty_Visibility_Returns_mvPublished`

Baseline anterior: 28 testes (ciclo 013). Delta: +2.

### Regressao FPC — PTestInvoker

```
fpc -Mdelphi -Fu"Source" -Fu"Test Shared/EclbrSystem" \
    -Fu"Test FPC/EclbrSystem" \
    -FU/tmp/fpcbuild2 -FE/tmp/fpcbuild2 \
    "Test FPC/EclbrSystem/PTestInvoker.lpr"
```

Resultado: **450 lines compiled, 0 errors**

### Mutacao de sanidade (CA-9)

Verificada pelo developer antes do handoff (registrada no [implement-report](pipeline-implement-report.md)):
trocar `mvPublished: Result := TModernVisibility.mvPublished` por `Result := TModernVisibility.mvPrivate`
em `PropertyVisibility` (backend FPC) → `TestProperty_Visibility_Returns_mvPublished` cai
com `ETestScenarioFailed: Property.Visibility devolveu ordinal 0; esperado 3 (mvPublished)` / exit=2.
Revertido; suite verde reconfirmada.

O test runner (execucao desta ronda, 30/0/0/exit=0) revalida que o cenario passa com
o codigo correto, o que — combinado com o log de mutacao — confirma que o cenario paga por si.

## Criterios de aceitacao

| CA | Descricao resumida | Status |
|----|--------------------|--------|
| CA-1 | `TModernVisibility` declarado antes de `TModernRTTIField`, ordem `mvPrivate < … < mvPublished` | ✅ linha 71 < linha 85 |
| CA-2 | `TModernRTTIMethod.Visibility` retorna `TModernVisibility` | ✅ decl. linha 314, impl. linha 911 |
| CA-3 | `TModernRTTIProperty.Visibility: TModernVisibility` existe | ✅ decl. linha 152, impl. linha 681 |
| CA-4 | FPC: `MethodVisibility` levanta `EModernRTTIError`; `PropertyVisibility` com `case` de 4 ramos, sem `mvAutomated` | ✅ verificado (`raise` linha 380+, `case` linhas 432-435) |
| CA-5 | Delphi: `MethodVisibility` e `PropertyVisibility` com `case` de 4 ramos, sem `mvAutomated`, sem resourcestring nova | ✅ linhas 254-257 e 269-272 |
| CA-6 | Distribuicao correta de cenarios entre cascas | ✅ FPC-only em FPC, Delphi-only em Delphi, cross em ambas |
| CA-7 | `TMemberVisibility` zero ocorrencias no codigo de `ModernSyntax.RTTI.pas` (so XMLDoc) | ✅ grep retorna linhas 61, 64, 65 — todas comentarios |
| CA-8 | FPC 3.2.2 x86_64 verde; i386 e Delphi nao testados na fabrica (caveat documentado) | ✅ / ⚠️ caveat |
| CA-9 | Mutacao de sanidade documentada e verificada | ✅ log no implement-report + revalidado pelo test runner |
| CA-10 | XMLDoc: `Method.Visibility` inclui clausula "no FPC levanta"; `Property.Visibility` NAO carrega clausula de raise | ✅ linhas 305-316 (Method) e 139-152 (Property) |

## Casos de borda exercitados

1. **`case` sem ramo `else` no FPC** — correto: os quatro valores esgotam `TMemberVisibility` do FPC 3.2.2 (`rtti.pp:308`). O compilador aceitou sem `else` (nenhuma warning de "case label missing").
2. **`Result` ficticio antes de `raise` em `MethodVisibility` FPC** — idioma padrao para suprimir "function result variable not initialized"; o `raise` segue imediatamente. Correto por construcao.
3. **Qualificacao de labels do `case`** (`TMemberVisibility.mvPrivate`) — necessaria porque `TModernVisibility` declara constantes homonimas; sem qualificacao o compilador rejeita o `case` (enum mismatch). D-IMPL-1 do implement-report documenta o trap.
4. **Fixture cross-compiler sem `{$IFDEF}`** — `TPortableFixture` ja tem `{$M+}` e propriedade `Number published`; nenhuma fixture nova foi necessaria. Satisfaz o requisito de CA-9.
5. **Assercao dupla em `Scenario_Method_Visibility_FPC_Raises`** — verifica (a) que `EModernRTTIError` e levantado e (b) que a mensagem menciona `vmtMethodTable` (D-42.5). Protege contra regressao futura que reescrevesse `SFPCNoVisibility` de volta ao texto enganoso.

## Caveats (nao sao falhas — sao restricoes da fabrica)

- **FPC i386** nao exercitado neste ambiente (a fabrica so tem x86_64). O codigo novo e puramente `case` sobre valor de enum — sem aritmetica de ponteiro. Confirmar no ambiente do autor.
- **Compilacao Delphi** nao exercitada (sem `dcc32` na fabrica). O `case` de 4 ramos no backend Delphi e o detector que acusa se o RTL Embarcadero tiver `mvAutomated` ou qualquer quinto valor — primeira coisa a confirmar no build Delphi do autor.

## Veredicto

**APROVADO.** Todos os 10 criterios de aceitacao satisfeitos. Suite FPC verde 30/30. Mutacao CA-9 verificada.
