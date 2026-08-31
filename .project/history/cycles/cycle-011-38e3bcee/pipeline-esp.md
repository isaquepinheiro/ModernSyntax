---
type: spec
kind: artifact
title: "ESP — TModernValue.AsType<T>: o membro mais usado do TValue (issue #26)"
description: "TModernValue envolve TValue nos dois compiladores e entrega AsType<T> onde falta; no FPC exige tipo exato e levanta EModernRTTIError nomeando origem e destino; alargamento fica fora, vira issue própria; CA-5 preservado."
status: draft
cycle: "011"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/38e3bcee8cdc184a2977006358812748
tags: [modernrtti, rtti, spec, issue-26, fpc, delphi, tvalue, astype]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-08-31T00:00:00Z"
sources:
  - id: issue-26
    title: "Issue #26 — TModernValue.AsType<T>: o membro mais usado do TValue, e o único ausente no FPC"
  - id: api-map
    resource: "/strategy/2026-08-27-modernrtti/API-MAP.md"
    title: "ModernRTTI API-MAP (§2 TValue, §7 arquitetura física)"
  - id: skill
    resource: "/SKILL.md"
    title: "SKILL — toolchain, receita FPC, traps"
---

# ESP — TModernValue.AsType<T> (issue #26)

## 1. Objetivo

Introduzir `TModernValue`, um record que envolve o `TValue` dos dois
compiladores e entrega `AsType<T>` — o único membro do `TValue` medido
como AUSENTE no FPC 3.2.2 (`API-MAP.md:96`). No Delphi, delega ao nativo.
No FPC, converte a partir de `TypeInfo(T)` para o `T` pedido, levantando
`EModernRTTIError` com mensagem que nomeia **origem** e **destino** quando
a conversão não for possível — nunca lixo silencioso.

De passagem, fechar o único drift restante do §7 do
[API-MAP](../../../strategy/2026-08-27-modernrtti/API-MAP.md) na unit pública:
o bloco `{$IFDEF FPC}...{$ELSE}...{$ENDIF}` de
`TModernRTTIProperty.GetValue<T>` (linhas 385–397 de
`Source/ModernSyntax.RTTI.pas`) desagua em `TModernValue.AsType<T>` e some.

## 2. Escopo

Inclui:

- Novo tipo público `TModernValue` em `Source/ModernSyntax.RTTI.pas`
  com superfície **mínima**: `class function From<T>(const AValue: T)`,
  `class function FromValue(const AValue: TValue)`, `function AsType<T>`.
  Estado privado neutro (`FValue: TValue` — `TValue` existe nos dois).
- Novo record `TValueOps` em **cada** backend
  (`ModernSyntax.RTTI.Delphi.pas` e `ModernSyntax.RTTI.FPC.pas`) com
  assinatura idêntica: `class function AsType<T>(const AValue: TValue): T; static`.
  Delphi: delegação pura ao nativo. FPC: `IsType(TypeInfo(T))` +
  `ExtractRawData` com raise nomeando origem e destino.
- Uma nova `resourcestring` no backend FPC:
  `SModernValueIncompatibleType = 'incompativel: origem=%s destino=%s'`.
- Reescrita de `TModernRTTIProperty.GetValue<T>` (linhas 385–397) para uma
  linha via `TModernValue.FromValue(LValue).AsType<T>`. Remove o único
  `{$IFDEF FPC}` que ainda vive fora da cláusula `uses` na unit pública.
- Sete cenários compartilhados novos em
  `Test Shared/EclbrSystem/UScenarios.RTTI.pas` — **todos de tipo exato**,
  zero `{$IFDEF}` — para os cinco tipos do CA (`string`, `Integer`,
  `Boolean`, `Double`, `TObject`) + `record` + `enum`.
- Sete `published`/`[Test]` em cada runner (FPC e Delphi) delegando aos
  cenários compartilhados; **mais um `published` local ao FPC** para o
  caso de exceção (mensagem contém origem e destino), documentado como
  "asserção específica do backend FPC até issue de alargamento ser
  resolvida".

Fora de escopo:

- Envolver qualquer outro membro do `TValue` (`IsEmpty`, `TypeInfo`,
  `Kind`, `ToString`, `AsObject`, `AsString`, `AsInteger`, `IsObject`,
  `From<T>` já foram medidos "OK" no FPC — API-MAP.md:94 — e o consumidor
  segue usando `TValue` nativo para eles).
- **Alargamento / conversão entre tipos diferentes** (Integer→Int64,
  Boolean→Integer, etc.) no FPC. Vira issue própria com matriz medida no
  `dcc32` como pré-requisito. Ver §6 (riscos) e o XMLDoc obrigatório.
- Retrofit de qualquer outra unit do `Source/` para o FPC.
- `TModernRTTIField.GetValue<T>` — **não é tocado**.
- Runners (`PTestRTTI.lpr`, `PTestRTTI.dpr`) e `.lpi` — inalterados.

## 3. Regras de negócio

- **§7 do API-MAP é lei:** tipo público **jamais** sob `{$IFDEF}` de
  compilador; corpo de método idem. O único `{$IFDEF}` da unit pública
  fica na cláusula `uses` (já estabelecido pela família da #21/#25). O
  `TValueOps` — um por backend, mesmo nome — é a peça que permite ao
  corpo de `TModernValue.AsType<T>` na unit pública ser **uma linha sem
  condicional**.
- **Superfície mínima:** `From<T>`, `FromValue`, `AsType<T>`. Nada mais.
  Os outros 9 membros do `TValue` estão OK no FPC nativo e não passam por
  esta camada.
- **Paridade de assinatura e paridade de CASO EXATO — não paridade de
  conversão.** No Delphi, herda a semântica nativa (incluindo
  alargamento). No FPC, exige tipo exato via `IsType(TypeInfo(T))` +
  `ExtractRawData`, que cobre 10/10 dos casos exatos medidos nos dois
  bitness (incluindo `record` e `enum`). A divergência é declarada em
  voz alta no XMLDoc.
- **`V.IsType(TypeInfo(T))`, não `V.IsType<T>`.** A forma genérica não
  compila dentro de função genérica no FPC 3.2.2 e depende do
  `{$ifndef NoGenericMethods}` da RTL. A forma não-genérica é imune aos
  dois problemas.
- **Uma resourcestring, não duas.** `V.TypeInfo^.Name` dá a origem,
  `PTypeInfo(TypeInfo(T))^.Name` dá o destino. CA-2 sai desse par.
- **Exceção única:** `EModernRTTIError` (não introduzir
  `EModernValueError`). Padrão da unit.
- **CA-5: zero `{$IFDEF FPC}` no código de teste compartilhado**
  (`Test Shared/EclbrSystem/UScenarios.RTTI.pas`). O cenário de exceção
  fica **local** ao runner FPC — não passa pelo shared.
- **Sem `Assert(...)` em cenários; sem `Exception` bruta.** Cenários
  levantam `ETestScenarioFailed` via `Fail(...)` (padrão fixado na #25 e
  disponível em `UScenarios.RTTI.pas:168` — a linha 168 é a que a
  discussão referenciou; **verificar no primeiro edit se o número
  bateu** — se não bateu, o padrão continua o mesmo). SKILL.md:37 não
  passa `-Sa`; `Assert` vira no-op silencioso, `Exception` engolida
  devolveu exit 0 sobre vermelho na #35.
- **Nenhum dispatch por `Kind`, nenhuma tabela.** `ExtractRawData` cobre
  os casos exatos por completo — provado nos dois bitness pelo analista
  na volta 1 (10/10, incluindo record e enum).

## 4. Critérios de aceitação

- [ ] `TModernValue` declarado na `interface` de
      `Source/ModernSyntax.RTTI.pas`, ao lado de `TModernRTTI`, com
      estado privado neutro (`FValue: TValue`) e a superfície mínima
      (`From<T>`, `FromValue`, `AsType<T>`). **Zero `{$IFDEF}` na
      declaração pública.**
- [ ] Corpo de `TModernValue.AsType<T>` na unit pública é uma linha:
      `Result := TValueOps.AsType<T>(FValue);`. **Zero `{$IFDEF}` no
      corpo.**
- [ ] XMLDoc de `TModernValue.AsType<T>` declara a divergência em voz
      alta, tom da #21:
      *"No Delphi, `AsType<T>` herda a semântica de conversão do `TValue`
      nativo, incluindo alargamento de ordinais. No FPC 3.2.2, exige tipo
      exato. Conversão entre tipos diferentes não é garantida nos dois
      compiladores; use o tipo exato para código portável."*
- [ ] `Source/ModernSyntax.RTTI.Delphi.pas` declara `TValueOps` com
      `class function AsType<T>(const AValue: TValue): T; static`;
      implementação é `Result := AValue.AsType<T>`.
- [ ] `Source/ModernSyntax.RTTI.FPC.pas` declara `TValueOps` com a mesma
      assinatura; implementação é: `if not AValue.IsType(TypeInfo(T))
      then raise EModernRTTIError.CreateFmt(SModernValueIncompatibleType,
      [string(AValue.TypeInfo^.Name),
      string(PTypeInfo(TypeInfo(T))^.Name)]);
      AValue.ExtractRawData(@Result);`.
- [ ] Uma **única** nova `resourcestring` no backend FPC:
      `SModernValueIncompatibleType = 'incompativel: origem=%s destino=%s'`
      — junta-se às 8 já existentes (linhas 82–114 atuais).
- [ ] `TModernRTTIProperty.GetValue<T>` (hoje 380–398 em
      `Source/ModernSyntax.RTTI.pas`) passa a ser:
      `Result := TModernValue.FromValue(FProp.GetValue(AInstance)).AsType<T>;`.
      **O bloco `{$IFDEF FPC}...{$ELSE}...{$ENDIF}` (linhas 385–397 hoje)
      some.** Após a edição, `grep -n "{\$IFDEF" Source/ModernSyntax.RTTI.pas`
      deve mostrar apenas a diretiva da cláusula `uses` da `implementation`.
- [ ] `TModernRTTIField.GetValue<T>` **não é tocado.**
- [ ] `AsType<T>` funciona nos **dois** compiladores para os cinco tipos
      básicos: `string`, `Integer`, `Boolean`, `Double`, `TObject`
      (critério explícito do enunciado da issue).
- [ ] `AsType<T>` funciona também para `record` e `enum` — prova viva
      de que `ExtractRawData` é universal, e toca a #21 (herança) e a #38
      (multiplicidade 2+ no mesmo nível) na fixture enum.
- [ ] No FPC, conversão para tipo diferente levanta `EModernRTTIError` e
      a mensagem contém o **nome do tipo de origem** e o **nome do tipo
      de destino** (asserção por `Pos`, não match exato — a discussão
      fixou nesse nível de precisão).
- [ ] Sete cenários novos em
      `Test Shared/EclbrSystem/UScenarios.RTTI.pas`:
      `Scenario_ModernValue_AsType_String`,
      `Scenario_ModernValue_AsType_Integer`,
      `Scenario_ModernValue_AsType_Boolean`,
      `Scenario_ModernValue_AsType_Double`,
      `Scenario_ModernValue_AsType_Object`,
      `Scenario_ModernValue_AsType_Record`,
      `Scenario_ModernValue_AsType_Enum`. Todos usam `Fail(...)`
      (levanta `ETestScenarioFailed`), **nunca** `Assert`, **nunca**
      `Exception` bruta.
- [ ] `grep -c "IFDEF" "Test Shared/EclbrSystem/UScenarios.RTTI.pas"`
      não aumenta em relação ao baseline (CA-5 preservado).
- [ ] `Test FPC/EclbrSystem/UTestMS.RTTI.pas` recebe sete `published`
      delegando aos cenários acima **+ um `published` extra local**:
      `TestModernValue_AsType_DifferentType_RaisesWithOriginAndDestination`
      — afirma que levanta `EModernRTTIError` e que `Pos(nome-origem,
      Message) > 0` e `Pos(nome-destino, Message) > 0`. Documentado como
      "válido até issue de alargamento ser resolvida".
- [ ] `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` recebe sete `[Test]`
      delegando aos mesmos cenários compartilhados. **Nenhum equivalente
      ao teste de exceção do FPC** — no Delphi tipo diferente pode passar
      por alargamento nativo, e testar "levanta OU converte" não vale
      nada.
- [ ] Um teste que use `TModernValue.AsType<T>` compila **sem
      `{$IFDEF FPC}` no código do teste** (CA-5, critério explícito do
      enunciado).
- [ ] `Test FPC/EclbrSystem/PTestRTTI.lpr` compila e passa nos dois
      bitness (x86_64 na fábrica, i386 declarado pelo autor).
- [ ] Compilação Delphi confirmada pelo autor — em especial que
      `TValueOps` como record com `class function ... static` genérico
      compila no Delphi 12 (é o único ponto não medido do desenho, ver
      Risco R1).
- [ ] Prova de mutação declarada no corpo do PR (padrão SKILL.md:92–97):
      trocar `if not AValue.IsType(TypeInfo(T))` por `if False` no
      backend FPC faz `TestModernValue_AsType_DifferentType_...` falhar.
      Se não falhar, o cenário de exceção não vale nada.

## 5. Restrições

- **Sem alterar `ModernSyntax.Invoker.pas`.**
- **Sem tocar `TModernRTTIField.GetValue<T>`.**
- **Sem enumeradores novos** — §3 do API-MAP fica para issue própria.
- **Sem introduzir uma terceira unit que faça `uses` das duas
  `ModernSyntax.RTTI.Delphi` e `ModernSyntax.RTTI.FPC`** — `TValueOps`
  é intencionalmente homônimo entre backends; a exclusividade é dada
  pelo `{$IFDEF}` da `uses` de `ModernSyntax.RTTI.pas`. Uma terceira
  unit puxando as duas quebraria por colisão de nome.
- **Sem rotinas livres genéricas em `Source/`.** O framework inteiro tem
  zero delas — Delphi não suporta rotina livre genérica. Genérico vive
  em método de tipo (`TValueOps.AsType<T>`, `TModernValue.AsType<T>`).
- **Sem alterar `.lpi` de `PTestRTTI`** — o `-Fu"Source"` acha os
  backends já existentes; nada novo em runner.

## 6. Riscos

- **R1 — `TValueOps` como record com `class function ... static`
  genérico no Delphi 12:** único ponto não medido do desenho. Evidência
  forte por analogia (6 casos análogos em `Source/`; padrão universal do
  repo), mas evidência por analogia não é medição. Registrar literal no
  PR: *"assumido pelo padrão do repo; primeira coisa a confirmar no
  build Delphi do ciclo de implementação"* — sem suavizar.
- **R2 — comportamento de `GetValue<T>` no FPC muda:** antes rejeitava
  por `DataSize <> SizeOf(T)` com mensagem de tamanho; passa a rejeitar
  por `not IsType(TypeInfo(T))` com mensagem de origem/destino.
  Consumidor FPC que dependesse da mensagem antiga vê a nova. Regressão
  nula esperada nos três roundtrips existentes
  (`TestGetValue_Integer_Roundtrip`, `TestGetValue_String_Roundtrip`,
  `TestGetValue_Currency_Roundtrip`) — todos leem no mesmo tipo que
  escrevem.
- **R3 — consumidor FPC que dependa de alargamento via `GetValue<T>`:**
  agora recebe `EModernRTTIError` com mensagem clara. Consumidor Delphi
  equivalente continua funcionando por delegação nativa. Divergência
  DECLARADA no XMLDoc (não silenciosa) e vira issue própria com matriz
  medida.
- **R4 — armadilha de nome `TValueOps`:** homônimo entre os dois
  backends por construção. Correto hoje (só um entra por `{$IFDEF}` da
  `uses`). Armadilha se um dia uma terceira unit fizer `uses` das duas.
  Mitigação: linha explícita no ADR proibindo.
- **R5 — issue de alargamento fica pendente sem programa de medição:**
  o rodapé da conversa deixou o `.dpr` pronto (`TMeasure` record) para o
  autor rodar no `dcc32`. Escopo desta issue **não** inclui esse programa
  — a decisão de onde ele mora foi delegada pela conversa ao "plano
  formal de implementação". O plano (ver `plan.md`) opta por **não
  entregá-lo aqui**: cabe à issue de alargamento nascer com o fonte e a
  matriz medida como pré-requisito, não a esta.
- **R6 — mutação obrigatória:** cenário de exceção sob mutação
  `if not AValue.IsType(TypeInfo(T))` → `if False` deve fazer o teste
  falhar. Sem essa prova, o teste não vale nada. Registrar a execução
  no corpo do PR (padrão SKILL.md:92–97).
