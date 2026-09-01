---
type: plan
kind: artifact
title: "PLAN — TModernVisibility em 3 slices sequenciais (issue #42)"
description: "Tres slices sequenciais e interdependentes (nao mergeaveis isoladamente): (1) enum publico + tipo de retorno em Method + declaracao/implementacao em Property, na casca; (2) backends Delphi (case novo em Method + PropertyVisibility novo) e FPC (assinatura Method + PropertyVisibility novo + reescrita de SFPCNoVisibility); (3) tres cenarios em UScenarios.RTTI.pas + duas cascas de teste + mutacao de sanidade documentada. Compilacao FPC nos dois bitness fecha o ciclo. Escopo confirmado 'fits' pelo split guard: 6 arquivos, mudancas tightly coupled, nenhum slice deploya sozinho."
status: draft
cycle: "015"
agent: architect
workflow: equipe-feature
node: plan-gate:on_reject
resource: aefos://run/bb89abe1aa455add801745cb2a527e99
tags: [modernrtti, plan, issue-42, fpc, delphi, visibility]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-09-01T00:00:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — TModernVisibility (issue #42)"
  - id: adr
    resource: "adr.md"
    title: "ADR — TModernVisibility (issue #42)"
  - id: skill
    resource: "/SKILL.md"
    title: "SKILL — receita FPC, mutacao, traps"
---

# PLAN — issue #42 (TModernVisibility)

## Verdict do split guard

**`fits`** — 3 slices tightly coupled em 6 arquivos, nenhuma slice
mergeavel sozinha (a slice 1 quebra o build ate a slice 2 aterrissar;
a slice 3 nao afirma nada sem a 2). Ver [`esp.md`](pipeline-esp.md) §2 para o
escopo completo e [`adr.md`](pipeline-adr.md) para a racional das decisoes.

- **Test 1 (SIZE):** 6 arquivos, ~300 linhas de mudanca liquida
  estimada, uma resourcestring nova + uma reescrita. Um `implement` cobre
  com folga.
- **Test 2 (INDEPENDENCE):** nao. Cada slice deixa a arvore quebrada se
  as seguintes nao aterrissarem no mesmo commit. Nao ha corte natural
  em sub-issues.

## Slice 1 — Casca publica: enum + assinaturas

**Arquivo:** `Source/ModernSyntax.RTTI.pas`.

**O que muda:**

1. Declarar `TModernVisibility = (mvPrivate, mvProtected, mvPublic, mvPublished);`
   no bloco `type` da `interface`, antes de `TModernRTTIField`
   (entre `:57` e `:59`, ancoras do relatorio).
2. Trocar `TModernRTTIMethod.Visibility` de `TMemberVisibility` para
   `TModernVisibility`:
   - Declaracao em `:279`.
   - Implementacao em `:866–869` (corpo `Result := MethodVisibility(FOwner, FToken);`
     permanece; so o tipo de retorno muda).
3. Adicionar `function Visibility: TModernVisibility;` na secao `public`
   de `TModernRTTIProperty` (`:104–126`). Implementacao no bloco
   `{ TModernRTTIProperty }` (termina em `:644`):
   `Result := PropertyVisibility(Pointer(FProp));`. `FProp` e `strict
   private` mas visivel na `implementation` da mesma unit.
4. XMLDoc `///`:
   - `TModernRTTIMethod.Visibility` mantem clausula "no FPC levanta
     `EModernRTTIError`".
   - `TModernRTTIProperty.Visibility` **nao** carrega essa clausula.
     Deixar explicito na doc que devolve valor real nos dois compiladores.

**Estado ao fim da slice:** casca compila **somente** com a slice 2
aterrissada; caso contrario as chamadas a `PropertyVisibility` /
`MethodVisibility` referem simbolo com assinatura errada. Nao commitar
isoladamente.

**Convencao verificada:** D-25.1 (sem `{$IFDEF}` em tipo publico).

## Slice 2 — Backends Delphi + FPC

**Arquivos:** `Source/ModernSyntax.RTTI.Delphi.pas` e `Source/ModernSyntax.RTTI.FPC.pas`.

### Delphi (`RTTI.Delphi.pas`)

1. `MethodVisibility` (`:74` interface, `:236–239` impl):
   - Assinatura passa a `function MethodVisibility(AOwner: TObject; const AToken: TVmtMethodEntry): TModernVisibility;`
     (respeitando o formato ja usado no arquivo).
   - Corpo substituido por `case TRttiMethod(AToken).Visibility of`
     com **exatamente 4 ramos** (`mvPrivate`, `mvProtected`, `mvPublic`,
     `mvPublished`) — **sem ramo `mvAutomated`**, sem `else` levantando.
2. Novo `PropertyVisibility(AToken: Pointer): TModernVisibility` na secao
   `--- Properties ---` (em torno de `:74`, interface + impl).
   - Mesmo `case` de **exatamente 4 ramos** sobre
     `TRttiProperty(AToken).Visibility` — **sem ramo `mvAutomated`**.
3. **Nenhum bloco `resourcestring` novo** no backend Delphi.

**Nota:** `mvAutomated` nao foi verificado neste ambiente (sem `dcc32`;
zero ocorrencias no repo). Opcao (b) do revisor: `case` de quatro nos
dois backends; se o Delphi tiver um quinto valor, o compilador acusa no
primeiro build — que e o detector que D-42.2 comprou.

### FPC (`RTTI.FPC.pas`)

1. `MethodVisibility` (`:96` interface, `:356–360` impl):
   - Assinatura passa a `function MethodVisibility(AOwner: TObject; const AToken: TVmtMethodEntry): TModernVisibility;`
     (paridade formal com o Delphi).
   - Corpo continua levantando `EModernRTTIError.Create(SFPCNoVisibility)`.
   - **Reescrever `SFPCNoVisibility`** (`:134–137`) segundo D-42.5 do
     ADR: expor a raiz `vmtMethodTable` e a referencia a #25.
2. Novo `PropertyVisibility(AToken: Pointer): TModernVisibility`:
   - Interface e impl.
   - Corpo: `case` de **exatamente 4 ramos** (`mvPrivate`, `mvProtected`,
     `mvPublic`, `mvPublished`) sobre `TRttiProperty(AToken).Visibility`.
     **Sem ramo `mvAutomated`** — esse identificador nao existe em
     `TMemberVisibility` do FPC 3.2.2 (`rtti.pp:308`); inclui-lo nao
     compila no FPC. Os quatro ramos esgotam o enum; sem `else` levantando.
   - **Sem raise incondicional, sem `SFPCNoPropertyVisibility`**.

**Estado ao fim da slice:** casca + backends compilam. Suite existente
nao acusa regressao. Suite nova ainda nao existe.

**Convencao verificada:** `case` explicito, nunca `Ord` (D-42.2 do ADR).

## Slice 3 — Cenarios + cascas de teste + mutacao

**Arquivos:** `Test Shared/EclbrSystem/UScenarios.RTTI.pas`,
`Test FPC/EclbrSystem/UTestMS.RTTI.pas`,
`Test Delphi/EclbrSystem/UTestMS.RTTI.pas`.

### `UScenarios.RTTI.pas` (compartilhado, zero `{$IFDEF}` por CA-5)

1. `Scenario_Method_Visibility_FPC_Raises`:
   - Fixture local (padrao vigente `:269–278`): classe simples com um
     metodo `published`.
   - Corpo: `try LMethod.Visibility; Fail('esperava EModernRTTIError');
     except on EModernRTTIError do end;`.
2. `Scenario_Method_Visibility_Delphi_Returns_mvPublished`:
   - Mesma fixture.
   - Corpo: `if LMethod.Visibility <> mvPublished then Fail(...);`.
3. `Scenario_Property_Visibility_Returns_mvPublished` (cross-compiler):
   - Fixture local com pelo menos **uma propriedade `published`** em
     classe `{$M+}` (sem isso, o cenario nao afirma nada real).
   - Corpo: `if LProperty.Visibility <> mvPublished then Fail(...);`.

### `Test FPC/EclbrSystem/UTestMS.RTTI.pas` (casca FPC, FPCUnit)

- `TestMethod_Visibility_FPC_Raises` → publica cenario 1.
- `TestProperty_Visibility_Returns_mvPublished` → publica cenario 3.

### `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` (casca Delphi, DUnitX)

- `TestMethod_Visibility_Delphi_Returns_mvPublished` → publica cenario 2.
- `TestProperty_Visibility_Returns_mvPublished` → publica cenario 3.

### Mutacao de sanidade (CA-9)

Antes de fechar o PR, rodar o experimento:

1. Rodar suite FPC verde (`rm -rf out && fpc ...` conforme SKILL).
2. Trocar em `RTTI.FPC.pas` (ou `.Delphi.pas`) a linha
   `mvPublished: Result := mvPublished;` do `case` de `PropertyVisibility`
   por `Result := mvPrivate;`.
3. `rm -rf out && fpc ...` novamente. `Scenario_Property_Visibility_Returns_mvPublished`
   deve ficar **vermelho**.
4. Reverter a mutacao e confirmar suite verde outra vez.
5. Registrar o resultado no PR body.

**Estado ao fim da slice:** compila FPC nos dois bitness; suite verde;
mutacao documentada no PR.

## Portao de compilacao

Para cada bitness FPC:

```
rm -rf out && \
  fpc -Mdelphi \
      -Fu"<repo>/Source" \
      -Fu"<repo>/Test Shared/EclbrSystem" \
      -FUout -FEout \
      "Test FPC/PTestRTTI.lpr"
```

O binario gerado corre a suite completa (nao apenas os cenarios novos)
para provar zero regressao. Trap #2 do SKILL: **sempre `rm -rf out`**.
Trap #1 nao se aplica — nao compilamos a arvore inteira.

## Files impactados (resumo)

| Arquivo | Slice | Natureza |
|---------|-------|----------|
| `Source/ModernSyntax.RTTI.pas` | 1 | edicao |
| `Source/ModernSyntax.RTTI.Delphi.pas` | 2 | edicao |
| `Source/ModernSyntax.RTTI.FPC.pas` | 2 | edicao + reescrita de resourcestring |
| `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | 3 | edicao (3 cenarios novos) |
| `Test FPC/EclbrSystem/UTestMS.RTTI.pas` | 3 | edicao (2 metodos published) |
| `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` | 3 | edicao (2 metodos [Test]) |
