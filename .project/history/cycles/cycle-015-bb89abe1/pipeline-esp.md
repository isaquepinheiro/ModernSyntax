---
type: spec
kind: artifact
title: "ESP — TModernVisibility: enum proprio, fecha vazamento em Method.Visibility, adiciona Property.Visibility (issue #42)"
description: "Especificacao da introducao do enum publico TModernVisibility na casca de RTTI, troca de tipo em TModernRTTIMethod.Visibility (hoje vaza TMemberVisibility de TypInfo), e adicao de TModernRTTIProperty.Visibility (prometido pela API-MAP §2, hoje ausente). Backend Delphi devolve dado real via case explicito nos dois membros. Backend FPC: MethodVisibility continua levantando por conta do caminho vmtMethodTable (D-25) que nao passa por TRttiMethod; PropertyVisibility devolve dado real via case explicito porque TRttiProperty.Visibility existe no FPC 3.2.2 e devolve mvPublished para propriedades published em classes {$M+}. Tres cenarios em UScenarios.RTTI.pas (par Method FPC-only/Delphi-only + Property cross-compiler)."
status: draft
cycle: "015"
agent: architect
workflow: equipe-feature
node: plan-gate:on_reject
resource: aefos://run/bb89abe1aa455add801745cb2a527e99
tags: [modernrtti, rtti, spec, issue-42, fpc, delphi, visibility, tmodernvisibility]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-09-01T00:00:00Z"
sources:
  - id: issue-42
    resource: "https://github.com/isaquepinheiro/ModernSyntax/issues/42"
    title: "Issue #42 — TModernVisibility: enum proprio, fecha vazamento em Method.Visibility, adiciona Property.Visibility"
  - id: issue-29-parent
    resource: "https://github.com/isaquepinheiro/ModernSyntax/issues/29"
    title: "Issue #29 — parent (tipos de categoria RTTI)"
  - id: api-map
    resource: "/strategy/2026-08-27-modernrtti/API-MAP.md"
    title: "ModernRTTI API-MAP §2"
  - id: skill
    resource: "/SKILL.md"
    title: "SKILL — receita FPC, mutacao, traps"
---

# ESP — TModernVisibility (issue #42)

## 1. Objetivo

Fechar o vazamento de `TMemberVisibility` (do `TypInfo`) na superficie
publica da unit `ModernSyntax.RTTI` e entregar a promessa da API-MAP §2
sobre `TModernRTTIProperty.Visibility` (hoje ausente do codigo). O
resultado e um enum publico proprio da casca — `TModernVisibility` — que
padroniza os quatro valores de visibilidade e desacopla a superficie
publica de tipos do RTL de cada compilador.

## 2. Escopo

Em `Source/ModernSyntax.RTTI.pas` (casca publica, sem `{$IFDEF}` em tipo
por D-25.1):

- Declarar `TModernVisibility = (mvPrivate, mvProtected, mvPublic, mvPublished);`
  no bloco `type` da `interface`, antes de `TModernRTTIField`.
- Trocar `TModernRTTIMethod.Visibility` de `TMemberVisibility` para
  `TModernVisibility` (declaracao e implementacao). Corpo permanece
  delegando ao backend.
- Adicionar `TModernRTTIProperty.Visibility: TModernVisibility` como
  membro publico novo (declaracao e implementacao no bloco correspondente).

Em `Source/ModernSyntax.RTTI.Delphi.pas` (backend Delphi):

- `MethodVisibility` passa a retornar `TModernVisibility`; o corpo usa
  `case` explicito de **exatamente 4 ramos** (`mvPrivate`, `mvProtected`,
  `mvPublic`, `mvPublished`) sobre `TRttiMethod(AToken).Visibility`.
  **Sem ramo `mvAutomated`** — nao verificado se existe em
  `TMemberVisibility` do Delphi neste ambiente; se existir, o proprio
  compilador Delphi acusara no primeiro build (que e o beneficio que
  D-42.2 comprou ao escolher `case` em vez de `Ord`).
- Novo `PropertyVisibility(AToken: Pointer): TModernVisibility`, `case`
  explicito de **exatamente 4 ramos** (`mvPrivate`, `mvProtected`,
  `mvPublic`, `mvPublished`) sobre `TRttiProperty(AToken).Visibility`.
  **Sem ramo `mvAutomated`**, pelo mesmo motivo. **Sem resourcestring
  nova no backend Delphi.**

Em `Source/ModernSyntax.RTTI.FPC.pas` (backend FPC):

- `MethodVisibility` passa a retornar `TModernVisibility`; o corpo
  **continua levantando** `EModernRTTIError`, mas a resourcestring
  `SFPCNoVisibility` e **reescrita** para expor a raiz verdadeira: esta
  camada enumera metodos por `vmtMethodTable` (D-25) e `TVmtMethodEntry`
  so carrega `Name`+`CodeAddress`; a visibilidade existe em
  `TRttiMember.Visibility` mas fora do caminho escolhido.
- Novo `PropertyVisibility(AToken: Pointer): TModernVisibility` com
  `case` de **exatamente 4 ramos** (`mvPrivate`, `mvProtected`, `mvPublic`,
  `mvPublished`) sobre `TRttiProperty(AToken).Visibility`. **Sem ramo
  `mvAutomated`** — esse identificador nao existe em `TMemberVisibility`
  do FPC 3.2.2 (`rtti.pp:308`); inclui-lo nao compila no FPC. Os quatro
  ramos esgotam o enum; sem `else` levantando. **Sem raise, sem
  resourcestring nova.** `TRttiProperty.Visibility` existe no FPC 3.2.2
  (`rtti.pp:340,3776`) e devolve dado real.

Em `Test Shared/EclbrSystem/UScenarios.RTTI.pas` (unit compartilhada,
zero diretiva por compilador — CA-5):

- `Scenario_Method_Visibility_FPC_Raises` — tenta `LMethod.Visibility`,
  espera `EModernRTTIError`, uso de `Fail(...)` (nunca `Assert`).
- `Scenario_Method_Visibility_Delphi_Returns_mvPublished` — afirma
  `Result = mvPublished` para metodo `published`.
- `Scenario_Property_Visibility_Returns_mvPublished` — cross-compiler:
  afirma `mvPublished` no Delphi e no FPC. A fixture inclui pelo menos
  uma propriedade `published` em classe `{$M+}` (sem isso, o cenario
  cross-compiler nao afirma nada real).

Em `Test FPC/EclbrSystem/UTestMS.RTTI.pas`:

- `TestMethod_Visibility_FPC_Raises` → publica `Scenario_Method_Visibility_FPC_Raises`.
- `TestProperty_Visibility_Returns_mvPublished` → publica cenario cross-compiler.

Em `Test Delphi/EclbrSystem/UTestMS.RTTI.pas`:

- `TestMethod_Visibility_Delphi_Returns_mvPublished` → publica cenario Delphi-only.
- `TestProperty_Visibility_Returns_mvPublished` → publica cenario cross-compiler.

## 3. Out of scope

- Trocar a estrategia de enumeracao de metodos por `TRttiMethod` (perderia
  a enumeracao por heranca da #25).
- Alterar API-MAP: pode ser feito no mesmo PR, mas nao e requisito da issue.
- Atacar as demais promessas de tipo de categoria (Enumeration, Pointer,
  Record, Array, Set) — cada uma tem sua propria sub-issue (#43–#46).
- Atacar o Trap #1 do SKILL (compilacao da arvore inteira em FPC) — nao
  e ambicao deste PR.

## 4. Regras de negocio (contratos publicos)

- **R1.** Ordem do enum: `mvPrivate < mvProtected < mvPublic < mvPublished`.
  A ordem espelha `TMemberVisibility` do Delphi/FPC e permite comparacoes
  lineares se o consumidor quiser (nao sao contrato, so consequencia).
- **R2.** `TModernRTTIMethod.Visibility` no FPC **levanta**
  `EModernRTTIError`; no Delphi devolve o valor real. Assimetria deliberada,
  documentada em XMLDoc `///`.
- **R3.** `TModernRTTIProperty.Visibility` devolve dado real nos dois
  compiladores. Assimetria com `TModernRTTIMethod.Visibility` e deliberada;
  o XMLDoc **nao** carrega clausula "no FPC levanta".
- **R4.** Nos dois backends que devolvem valor real (Delphi para Method
  e Property; FPC para Property), o mapeamento usa `case` explicito, nunca
  `TModernVisibility(Ord(...))` — pega valor novo do compilador em build
  time em vez de silenciar em runtime.
- **R5.** Nenhum backend inclui ramo `mvAutomated`. Se `TMemberVisibility`
  do Delphi contiver esse ou qualquer outro valor fora dos quatro declarados,
  o `case` sem `else` acusara erro de compilacao no primeiro build Delphi —
  que e exatamente o comportamento esperado de D-42.2.

## 5. Criterios de aceitacao

- [ ] **CA-1.** Enum publico `TModernVisibility` declarado com quatro
  constantes na ordem `mvPrivate < mvProtected < mvPublic < mvPublished`,
  no bloco `type` da `interface`, antes de `TModernRTTIField`.
- [ ] **CA-2.** `TModernRTTIMethod.Visibility` retorna `TModernVisibility`
  (declaracao e implementacao).
- [ ] **CA-3.** `TModernRTTIProperty.Visibility: TModernVisibility` existe
  (declaracao e implementacao).
- [ ] **CA-4.** Backend FPC: `MethodVisibility` levanta `EModernRTTIError`
  em ambos os fluxos; `PropertyVisibility` devolve dado real via `case`
  de **exatamente 4 ramos** (sem ramo `mvAutomated`, inexistente no FPC).
- [ ] **CA-5.** Backend Delphi: `MethodVisibility` e `PropertyVisibility`
  devolvem o valor correto por `case` explicito de **exatamente 4 ramos**
  (`mvPrivate`, `mvProtected`, `mvPublic`, `mvPublished`) — sem ramo
  `mvAutomated`, sem resourcestring nova. Se o Delphi tiver valor
  adicional, o compilador acusa no primeiro build.
- [ ] **CA-6.** Cenario `Scenario_Method_Visibility_FPC_Raises` publicado
  apenas na casca FPC; cenario `Scenario_Method_Visibility_Delphi_Returns_mvPublished`
  publicado apenas na casca Delphi; cenario
  `Scenario_Property_Visibility_Returns_mvPublished` publicado nas duas
  cascas.
- [ ] **CA-7.** `grep -rn "TMemberVisibility" Source/ModernSyntax.RTTI.pas`
  retorna zero hits fora da `uses` da `implementation` (a `uses` de
  interface mantem `TypInfo` porque outros simbolos permanecem —
  `PTypeInfo`, `TTypeData`, `GetTypeData`).
- [ ] **CA-8.** Compila FPC 3.2.2 nos dois bitness (x86_64 e i386) sem
  erro; suites verdes. Delphi: compilado apenas pelo autor (nao pelo
  container Aefos) — o PR declara explicitamente o que foi compilado.
- [ ] **CA-9.** Mutacao de sanidade documentada: trocar o `case` de
  `PropertyVisibility` (em qualquer dos backends) por valor fixo (ex.:
  `Result := mvPrivate;`) → `Scenario_Property_Visibility_Returns_mvPublished`
  fica vermelho. Confirma que o cenario paga por si.
- [ ] **CA-10.** XMLDoc `///` em membros publicos novos ou alterados:
  `TModernRTTIMethod.Visibility` mantem clausula "no FPC levanta
  EModernRTTIError"; `TModernRTTIProperty.Visibility` **nao** carrega
  essa clausula.

## 6. Convencoes que governam

- **D-25.1** — casca publica sem `{$IFDEF}` em declaracao de tipo. Governa
  a declaracao incondicional de `TModernVisibility` (`Source/ModernSyntax.RTTI.pas:18–23`).
- **D-25.4** — membros sem fonte no FPC levantam `EModernRTTIError` com
  mensagem instrutiva (`Source/ModernSyntax.RTTI.FPC.pas:29–31`). Governa
  `MethodVisibility` FPC; **nao** governa `PropertyVisibility` FPC (que
  tem fonte).
- **CA-5 (padrao do repo)** — zero diretiva por compilador em
  `UScenarios.RTTI.pas` (`Test Shared/EclbrSystem/UScenarios.RTTI.pas:16`).
  Governa a escrita dos 3 cenarios: `try/except + Fail(...)`, sem `{$IFDEF}`.
- **Padrao "dois cenarios distintos + duas cascas"** — descrito em
  `Test FPC/EclbrSystem/UTestMS.RTTI.pas:58,65–68`. Governa **apenas** o
  par de Method (`_FPC_Raises` / `_Delphi_Returns_mvPublished`); o cenario
  de Property e cross-compiler e publicado nas duas cascas.
- **Nomenclatura** — [conventions](../../../analysis/05-conventions.md) §1.3:
  prefixo `mv` no enum, `L` em locais, `A` em parametros; XMLDoc `///` em
  membros publicos novos (§4.3).
- **Nunca silencie o caso ausente** — politica da unit ja materializada em
  `MethodIsConstructor/IsClassMethod/IsStatic` no FPC. Governa o ramo
  `mvAutomated` do Delphi e o `case` explicito (nao `Ord`).

## 7. Riscos

- **R-1.** Quebra de compilacao em consumidores externos que atribuam o
  retorno de `TModernRTTIMethod.Visibility` a variavel `TMemberVisibility`.
  **Mitigacao interna:** `grep -rn "\.Visibility" "Test Shared/" "Test Delphi/" "Test FPC/"`
  retorna zero — nenhum caller no repo. Fora do repo e obrigacao de
  changelog no proximo release.
- **R-2.** Divergencia futura entre os valores enumerados em Delphi e FPC
  se um compilador acrescentar visibilidade nova. **Mitigacao:** `case`
  explicito ambos os lados quebra o build ao ver um valor fora dos 4.
- **R-3.** Confusao futura sobre por que `MethodVisibility` FPC continua
  levantando (tentacao de "consertar de graca" trocando para `TRttiMethod`).
  **Mitigacao:** `SFPCNoVisibility` reescrita expondo a raiz verdadeira
  (D-25 vmtMethodTable) + ADR desta issue registrando a mesma justificativa.
- **R-4.** Cenario cross-compiler que passa por caminho errado (fixture
  sem propriedade `published` em classe `{$M+}`). **Mitigacao:** CA-9
  (mutacao de sanidade) obriga o cenario a pagar por si.

## 8. Restricoes

- Nenhuma diretiva de compilador em declaracao de tipo publico
  (D-25.1, reafirmado).
- Zero `{$IFDEF FPC}` em `UScenarios.RTTI.pas` (CA-5 do repo).
- PR unico fechando `#42` inteiro (decidido em volta 1 da conversa).
- Toolchain FPC 3.2.2 nos dois bitness, com `rm -rf` do output antes de
  cada build (Trap #2 do SKILL).
