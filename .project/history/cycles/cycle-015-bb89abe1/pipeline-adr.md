---
type: adr
kind: decision
title: "ADR — TModernVisibility: enum proprio, MethodVisibility FPC levanta pela raiz D-25 (issue #42)"
description: "Restatement da decisao acordada no relatorio de investigacao da issue #42 (run e7efef2f8eb436a389aef737d1640c95, volta 1): TModernVisibility como enum publico proprio de 4 constantes; case explicito nos dois backends (nunca Ord); PropertyVisibility no FPC devolve dado real (mvPublished medido em rtti.pp:308,340,3776 nos dois bitness) e NAO levanta; MethodVisibility no FPC continua levantando, mas por motivo distinto do STUDY original — a camada enumera metodos por vmtMethodTable (D-25) e TVmtMethodEntry so carrega Name+CodeAddress, entao TRttiMethod.Visibility esta fora do caminho escolhido; SFPCNoVisibility reescrita para expor essa raiz; mvAutomated no Delphi levanta EModernRTTIError com resourcestring nova (default seguro: nunca silencie o caso ausente); assinatura de PropertyVisibility e (AToken: Pointer) puro; cenario de Property e cross-compiler (afirma mvPublished nos dois), so o par de Method fica assimetrico."
status: stable
cycle: "015"
agent: architect
workflow: equipe-feature
node: plan-gate:on_reject
resource: aefos://run/bb89abe1aa455add801745cb2a527e99
tags: [modernrtti, adr, issue-42, fpc, delphi, visibility, tmodernvisibility, d25]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-09-01T00:00:00Z"
sources:
  - id: issue-42-report
    title: "REPORT — Issue #42 (run e7efef2f8eb436a389aef737d1640c95) — PRESENT"
  - id: adr-025
    resource: "/history/cycles/cycle-010-a36e1364/pipeline-adr.md"
    title: "D-25 — vmtMethodTable e Fail(...)/dois cenarios distintos"
  - id: skill
    resource: "/SKILL.md"
    title: "SKILL — receita FPC, mutacao, traps"
---

# ADR — issue #42 (TModernVisibility)

Este documento **deriva do relatorio de investigacao** que fechou a
discussao da issue #42 (uma volta, run
`e7efef2f8eb436a389aef737d1640c95`), reproduzido verbatim no prompt do
ciclo. Ele registra a decisao **em vigor**, nos termos que a conversa
acertou. **Nao ha divergencia de merito** entre este ADR e o relatorio;
todos os deltas da volta 1 estao absorvidos.

## Contexto medido (do relatorio)

- **`TMemberVisibility` do `TypInfo` vaza hoje** na superficie publica
  de `TModernRTTIMethod.Visibility` (`Source/ModernSyntax.RTTI.pas:279`),
  contradizendo a politica da unit de nao expor tipos do RTL de cada
  compilador.
- **`TModernRTTIProperty.Visibility` esta ausente** do codigo, embora
  prometido pela API-MAP §2 (`strategy/2026-08-27-modernrtti/API-MAP.md:84`).
- **`TRttiProperty.Visibility` EXISTE no FPC 3.2.2** — declarado em
  `rtti.pp:340`, getter em `rtti.pp:3776`, `TMemberVisibility` em
  `rtti.pp:308` com os mesmos 4 valores e mesma ordem do Delphi.
  Execucao nos dois bitness com classe `{$M+}` e duas propriedades
  `published` devolveu `mvPublished`. Um raise sobre dado que existe
  esta errado.
- **`TRttiMember.Visibility` tambem EXISTE no FPC 3.2.2** (`rtti.pp:317`),
  herdado por `TRttiMethod`. Nao e por ausencia da RTL que
  `MethodVisibility` no FPC ficaria sem fonte.
- **A raiz real:** a decisao da #25 enumerou metodos por `vmtMethodTable`,
  e `TVmtMethodEntry` so carrega `Name`+`CodeAddress`. A visibilidade
  existe na RTL mas fora do caminho escolhido pela camada. Reescolher
  para `TRttiMethod` daria visibilidade "de graca" e perderia a
  enumeracao por heranca que a #25 provou.

## Decisao

### D-42.1 — Enum publico proprio (fecha vazamento)

Declarar `TModernVisibility = (mvPrivate, mvProtected, mvPublic, mvPublished);`
em `Source/ModernSyntax.RTTI.pas`, no bloco `type` da `interface`, antes
de `TModernRTTIField`. Ordem espelha `TMemberVisibility`.

Consequencias:
- `TModernRTTIMethod.Visibility` passa a retornar `TModernVisibility`.
- `TModernRTTIProperty.Visibility` **passa a existir**, retornando
  `TModernVisibility`.
- `TMemberVisibility` sai da superficie publica; `TypInfo` **permanece**
  na `uses` da `interface` porque outros simbolos continuam sendo usados
  (`PTypeInfo`, `TTypeData`, `GetTypeData`).

Governado por **D-25.1** (casca publica sem `{$IFDEF}` em declaracao de
tipo).

### D-42.2 — `case` explicito nos dois backends, nunca `Ord`

O mapeamento entre `TMemberVisibility` do RTL e `TModernVisibility` da
casca usa `case` explicito em **todo** local onde ha dado real (Delphi
Method, Delphi Property, FPC Property). **`TModernVisibility(Ord(RttiValue))`
esta proibido** — se um compilador acrescentar valor novo a enumeracao,
o `Ord` devolve lixo em silencio; o `case` explicito quebra o build.

Ambos os backends usam **exatamente 4 ramos** (`mvPrivate`,
`mvProtected`, `mvPublic`, `mvPublished`) em todo local onde ha dado
real (Delphi Method, Delphi Property, FPC Property). Nenhum backend
inclui ramo `mvAutomated`. Se `TMemberVisibility` do Delphi contiver
esse ou qualquer outro valor fora dos quatro, o `case` sem `else`
acusa erro de compilacao no primeiro build Delphi — que e exatamente o
detector pretendido. O FPC 3.2.2 tem os mesmos quatro valores
(`rtti.pp:308`), e o `case` de 4 os esgota sem `else`.

Governado pela politica da unit **"nunca silencie o caso ausente"**
(materializada em `MethodIsConstructor/IsClassMethod/IsStatic` no FPC).

### D-42.3 — Nenhum backend inclui ramo `mvAutomated`

O revisor escolheu a **opcao (b)**: tirar o ramo `mvAutomated` dos dois
backends e deixar `case` de quatro em ambos. Racional: `mvAutomated`
nao foi verificado neste ambiente (sem `dcc32`; `grep mvAutomated`
retorna zero em todo o repo); incluir um ramo nao confirmado como fato
introduziria o mesmo risco invisivel que o ciclo anterior rejeitou no
FPC.

Se o `TMemberVisibility` do Delphi tiver `mvAutomated` (ou qualquer
outro valor alem dos quatro), o `case` sem `else` acusara erro de
compilacao no primeiro build Delphi — que e exatamente o detector que
D-42.2 comprou ao proibir `Ord`. **Nenhuma resourcestring nova e criada
no backend Delphi.**

### D-42.4 — `PropertyVisibility` no FPC devolve dado real (NAO levanta)

Backend FPC implementa `PropertyVisibility(AToken: Pointer): TModernVisibility`
com `case` de **exatamente 4 ramos** (`mvPrivate`, `mvProtected`,
`mvPublic`, `mvPublished`) sobre `TRttiProperty(AToken).Visibility`.
**Sem ramo `mvAutomated`** (inexistente no FPC), sem `else` levantando,
**sem raise, sem resourcestring nova.**

Racional medido: `TRttiProperty.Visibility` existe no FPC 3.2.2 e
devolve dado real (`mvPublished` verificado nos dois bitness). Levantar
sobre dado que existe e errado, e a proposta original do STUDY
(`SFPCNoPropertyVisibility`) e revogada aqui.

**Este ADR nao governa D-25.4.** D-25.4 se aplica quando o membro nao
tem fonte no FPC pelo caminho escolhido; aqui, `TRttiProperty` **e** o
caminho escolhido (nao ha alternativa via `vmtPropertyTable` no escopo
desta camada).

### D-42.5 — `MethodVisibility` no FPC continua levantando, com raiz reescrita

Backend FPC mantem `MethodVisibility` levantando `EModernRTTIError`,
mas a resourcestring **`SFPCNoVisibility` e reescrita**. O texto atual
(`Source/ModernSyntax.RTTI.FPC.pas:134–137`) diz "visibilidade fina nao
e enumeravel pela RTTI de classe" — e falso agora. A redacao nova, dentro
destas balizas (redacao final por decisao do implementador):

> A visibilidade `TRttiMember.Visibility` existe na RTL do FPC 3.2.2
> (`rtti.pp:317`), mas esta camada enumera metodos por `vmtMethodTable`
> (decisao da issue #25) e `TVmtMethodEntry` so carrega `Name` e
> `CodeAddress`. `TRttiMethod` fica fora do caminho escolhido; trocar
> para ele reintroduziria dependencia de `TRttiContext.GetType` e
> perderia a enumeracao por heranca.

Racional: sem essa reescrita, o proximo ciclo tenta "consertar de graca"
trocando para `TRttiMethod` e desfaz a enumeracao por heranca que a #25
provou.

### D-42.6 — Assinatura de `PropertyVisibility` e `(AToken: Pointer)` puro

Rejeitada simetria com `MethodVisibility(AOwner, AToken)`. `TRttiProperty`
e auto-contido; `AOwner` seria parametro morto. Simetria por simetria
adiciona ruido a superficie do backend.

### D-42.7 — Cenario de Property e cross-compiler, so par de Method fica assimetrico

`Test Shared/EclbrSystem/UScenarios.RTTI.pas` ganha **3 cenarios** (nao
4 como o STUDY previa):

1. `Scenario_Method_Visibility_FPC_Raises` — Method FPC-only, afirma
   raise via `try/except + Fail(...)`.
2. `Scenario_Method_Visibility_Delphi_Returns_mvPublished` — Method
   Delphi-only, afirma `mvPublished`.
3. `Scenario_Property_Visibility_Returns_mvPublished` — cross-compiler,
   publicado nas duas cascas, afirma `mvPublished` nos dois.

Racional: como o FPC devolve dado real para Property, um cenario unico
cross-compiler afirma o mesmo nos dois lados, reduz cerimonia sem perder
cobertura. O padrao "dois cenarios distintos + duas cascas" continua
governando apenas o par de Method.

Fixture: locais por cenario (`UScenarios.RTTI.pas:269–278`, padrao
vigente). A fixture do cenario cross-compiler precisa incluir ao menos
uma propriedade `published` em classe `{$M+}` — sem isso, o cenario nao
afirma nada real.

### D-42.8 — Cenario cobre so `mvPublished`; outros 3 valores por inspecao

O cenario cross-compiler afirma **apenas `mvPublished`**. Os outros 3
valores do `case` (`mvPrivate`, `mvProtected`, `mvPublic`) ficam
cobertos por inspecao. Isso cobre o acceptance da issue e mantem a
fixture minima.

### D-42.9 — Mutacao de sanidade obrigatoria

O implementador **deve** validar `Scenario_Property_Visibility_Returns_mvPublished`
com mutacao: trocar o `case` de `PropertyVisibility` (em qualquer dos
backends) por valor fixo (ex.: `Result := mvPrivate;`) → o cenario deve
ficar vermelho. `Fail(...)` sempre, nunca `Assert`. Sem essa validacao
o cenario nao paga por si e pode passar por caminho errado (fixture sem
`published`, por exemplo).

## Descartado, e o motivo medido

- **`PropertyVisibility` no FPC levantando com `SFPCNoPropertyVisibility`**
  (proposta original do STUDY). Recusado: `TRttiProperty.Visibility`
  existe no FPC (`rtti.pp:340,3776`) e devolve dado real.
- **Par FPC-only/Delphi-only para Property** (STUDY previa 4 cenarios).
  Recusado: cenario unico cross-compiler cobre o mesmo, reduz cerimonia.
- **`TModernVisibility(Ord(RttiValue))`**. Recusado: silencia valor novo
  do compilador em runtime; `case` explicito quebra o build.
- **`SFPCNoVisibility` com texto atual** (`RTTI.FPC.pas:134–137`).
  Recusado: mede errado a raiz — a visibilidade **e** enumeravel na RTL;
  o que nao a expoe e o caminho `vmtMethodTable` desta camada.
- **`PropertyVisibility(AOwner, AToken)`**. Recusado: `AOwner` seria
  parametro morto; `TRttiProperty` e auto-contido.
- **Ramo `mvAutomated` no backend Delphi + `SDelphiVisibilityAutomated`**
  (opcao a do ciclo anterior). Recusado pelo revisor: `mvAutomated` nao
  foi verificado neste ambiente (zero ocorrencias no repo; sem `dcc32`);
  admiti-lo como fato introduziria risco invisivel simetrico ao que foi
  rejeitado no FPC. Opcao (b) escolhida: `case` de quatro nos dois
  backends; compilador Delphi descobre o quinto valor, se existir.

## Perguntas em aberto

- **Confirmacao editorial de `SFPCNoVisibility`.** O conteudo (raiz
  `vmtMethodTable`, referencia a #25) esta acordado; a redacao final e
  decisao do implementador dentro das balizas de D-42.5.
- **`mvAutomated` no Delphi:** fechado — opcao (b) escolhida pelo
  revisor (D-42.3). Nenhum ramo; compilador Delphi detecta.
- **Atualizacao da API-MAP §2:** incluir no mesmo PR ou em PR sucessor?
  A issue nao obriga; decisao do proximo agente (plan).
