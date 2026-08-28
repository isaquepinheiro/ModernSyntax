---
type: adr
kind: artifact
title: "ADR — Pilar 1 ModernRTTI: unit greenfield ModernSyntax.RTTI (issue #8)"
description: "Deriva do REPORT — Issue #8: unit nova greenfield ModernSyntax.RTTI, entry point TModernRTTI, GetValue<T>/SetValue<T> genéricos, exceção obrigatória para {$M+} ausente, TModernRTTIField Delphi-only (TRttiField ausente no FPC 3.2.2 — medido), FPC project standalone (.lpr+.lpi) seguindo o padrão do commit 7114cdc da issue #7, {$mode delphi} obrigatório (nunca objfpc) na unit de produção."
status: stable
cycle: "006"
agent: architect
workflow: equipe-feature
node: plan-gate:on_reject
resource: aefos://run/0432fa58eb504d5fa522f3e710649a41
tags: [modernrtti, rtti, adr, issue-8, pilar-1, fpc, delphi]
generated:
  by: "equipe-feature@node:plan-gate:on_reject"
  at: "2026-08-28T16:00:00Z"
sources:
  - id: investigation
    title: "REPORT — Issue #8 (investigate run 6326ac737a7550e0c239b5b28be40624)"
  - id: prd
    resource: "../strategy/2026-08-27-modernrtti/PRD.md"
    title: "ModernRTTI PRD"
  - id: study
    resource: "../strategy/2026-08-27-modernrtti/STUDY.md"
    title: "ModernRTTI Study"
  - id: esp
    resource: "esp.md"
    title: "ESP — Pilar 1"
  - id: adr-attrs
    resource: "../history/cycles/cycle-004-e936cbe6/pipeline-adr.md"
    title: "ADR — Pilar 2 (issue #9)"
  - id: adr-invoker
    resource: "../history/cycles/cycle-005-2ef372d9/pipeline-adr.md"
    title: "ADR — Pilar 3 (issue #10)"
---

# ADR — Pilar 1 ModernRTTI: `ModernSyntax.RTTI` (issue #8)

> **Este ADR deriva do REPORT — Issue #8 do `investigate` run
> `6326ac737a7550e0c239b5b28be40624`**, entregue verbatim no prompt do
> `architect`. As decisões abaixo já foram acordadas com o dono na volta 1
> daquela conversa; este ADR **as registra**, não as substitui. **Nenhuma
> divergência** desta arquitetura em relação ao REPORT — todas as escolhas
> abaixo são a instância exata das travadas lá.

## Contexto

- **Estado medido do repositório (STUDY §"Mapa de arquivos"):** 0 chamadas a
  `GetProperties`/`GetFields`/`TRttiProperty`/`TRttiField` em `Source/*.pas`.
  O único ponto de RTTI vivo é `TModernObject.Factory`
  (`Source/ModernSyntax.Objects.pas:208-241`), que só invoca construtor.
- **Bloqueios estruturais medidos:** (a) `{$IFDEF FCP}` em
  `Source/ModernSyntax.inc:261` (em `main`; linhas 251-260 trazem comentário
  do autor sobre o typo deliberado) é um bug — símbolo do FPC é `FPC` — logo o
  ramo Lazarus do `.inc` **nunca dispara**; (a2) `TRttiField` e
  `TRttiType.GetFields` **não existem** no FPC 3.2.2 (medido: erro de compilador
  `"Identifier not found TRttiField"` — não é ajuste, é ausência); (a3)
  `{$mode objfpc}` dentro de `{$IFDEF FPC}` na unit de produção derruba
  `strict private` em records e sobrescreve `-Mdelphi` da CLI (defeito medido
  no PR #17, causa direta do não-build); (b) `Rtti` no FPC 3.2.2 é
  marcada `experimental`; (c) `TModernObject.FContext`
  (`Source/ModernSyntax.Objects.pas:41`) mora numa unit que arrasta
  `SyncObjs`/`Variants`/`Classes`/`TProc<T>`; (d) commit rejeitado `06fccea`
  do ciclo anterior desta mesma issue #8 importava DUnitX no FPC (que não
  existe em 3.2.2, não está vendorizado) — PR fechado sem merge.
- **Convenções ativas** ([05-conventions](../../../analysis/05-conventions.md)):
  `ModernSyntax.<Feature>.pas`, prefixos `A`/`L`/`F`/`T`/`I`/`E`,
  `strict private`, header SPDX-MIT, XML doc `///`.
- **Família ModernRTTI já entregou:** Pilar 2 (issue #9,
  [ADR](../cycle-004-e936cbe6/pipeline-adr.md)) e Pilar 3
  (issue #10, [ADR](../cycle-005-2ef372d9/pipeline-adr.md)).
  Esta issue é o Pilar 1 do mesmo PRD.

## Decisões

### D1 — Unit nova greenfield `Source/ModernSyntax.RTTI.pas`

Nome do arquivo `ModernSyntax.RTTI.pas`, entry point `TModernRTTI` (record
com `class function GetType`). Segue o padrão das 16 units existentes
([05-conventions §1.1](../../../analysis/05-conventions.md)).

**Alternativas descartadas (medidas):**
- `ModernSyntax.ModernRTTI.pas` — repete "Modern", não acrescenta, quebra
  economia da convenção.
- `ModernRTTI.pas` (sem prefixo) — quebra 16/16 units.
- **Reusar `TModernObject.FContext`** — importar `ModernSyntax.Objects`
  arrasta `SyncObjs`/`Variants`/`Classes`/`TProc<T>` (STUDY §C-3;
  `Source/ModernSyntax.Objects.pas:340` usa `TProc<T>`, ilegal no FPC 3.2.2).

### D2 — `TRttiContext` próprio da unit

`class var TModernRTTI.FContext`, criado em `initialization`, liberado em
`finalization`. Padrão idêntico ao de
`Source/ModernSyntax.Objects.pas:195,601`.

### D3 — Exceção obrigatória em vez de lista vazia silenciosa (R4 do PRD)

`TModernRTTIType.GetProperties` (e `GetFields`) **detecta** o caso "classe
sem propriedades expostas quando deveria ter" e **levanta**
`EModernRTTIError`. **Não é opt-in.**

**Motivo medido:** lista vazia silenciosa é exatamente a classe de defeito
que a família ModernRTTI existe para prevenir. O consumidor Delphi (RTTI lê
`public`) recebe lista cheia; o mesmo código no FPC, sem `{$M+}`, recebe
`[]` — e conclui *"a classe não tem propriedades"*, não *"esqueci
`{$M+}`"*. Opt-in transfere para o consumidor a obrigação de lembrar de
uma diferença entre compiladores, que é o oposto do CA-5 do PRD.

**Descartadas:**
- Parâmetro `AStrict` (opt-in) — recriaria a assimetria que CA-5 elimina.
- Retornar array vazio silencioso — o defeito da família.

### D4 — Mensagem instrutiva unificada

Texto único, não ramifica por compilador (RN-7 do [ESP](pipeline-esp.md)):

> *"A classe %s não expõe propriedades à RTTI. No Delphi isso indica
> ausência real de propriedades `public`/`published`; no FPC exige
> `{$M+}` antes da declaração da classe e uma seção `published` com as
> propriedades desejadas. Adicione ambos e recompile."*

**Motivo:** coerente com "verificação uniforme dentro da unit".
Ramificar por compilador (permitido pela D2 do PRD porque é interno)
pouparia poucas palavras em Delphi ao custo de duas versões da mesma
frase. **Sub-decisão registrada como pendente do dono** no REPORT — se
ele preferir ramificar, o `raise` ganha um `{$IFDEF FPC}` interno; a
mudança é contida em RN-7 e invisível ao consumidor.

### D5 — API pública em genéricos, `TValue` como escape hatch

`GetValue<T>: T` e `SetValue<T>(const AValue: T)` como caminho recomendado
em `TModernRTTIProperty` (portável) e em `TModernRTTIField` (Delphi-only —
ver D12). Overload `TValue` cru existe, marcado `/// <remarks>` como escape
hatch.

**Motivo medido:** (a) obrigar `uses Rtti` no consumidor vaza implementação
pela API pública; (b) a unit `Rtti` do FPC 3.2.2 é marcada `experimental`
(aviso a cada build — R1 do PRD). Uma camada de absorção **não pode**
arrastar o consumidor para a unit instável.

**Consequência aceita:** se `TValue.AsType<T>` do FPC 3.2.2 falhar para
algum `T` não trivial (limitação real da `Rtti` FPC — motivo do
`experimental`), o overload `TValue` cru passa a ser o caminho
**recomendado** para esses tipos. Decisão fica com o autor no primeiro
build FPC (R2 do PRD). O escape hatch já existe exatamente para este
cenário.

### D6 — Retorno `TArray<T>` com contrato de ownership explícito

`GetProperties: TArray<TModernRTTIProperty>` e
`GetFields: TArray<TModernRTTIField>`. Handles leves; consumidor **não
libera**; retenção após shutdown é undefined. Contrato registrado em
`<remarks>` de `GetType`/`GetProperties`/`GetFields` — texto integral em
RN-9 do [ESP](pipeline-esp.md).

**Motivo medido:** `for … in TArray<T>` funciona nos dois compiladores.
Enumerator adicionaria tipo público, arquivo e docs por ganho puramente
estético — custo real por benefício zero. Padrão herdado do
`TResultPair.Dispose` da #7.

### D7 — FPC project standalone; esta issue **cria** `.lpr` e `.lpi`

A issue #7 (commit `7114cdc`) já entregou o padrão. Esta issue segue o mesmo
padrão e **cria seus próprios arquivos** (não depende de merge da #7):
- `Test Shared/EclbrSystem/UScenarios.RTTI.pas` — cenários portáveis.
- `Test FPC/EclbrSystem/UTestMS.RTTI.pas` — casca FPCUnit.
- `Test FPC/EclbrSystem/PTestRTTI.lpr` — runner (padrão
  `PTestModernCallback.lpr` do commit `7114cdc`).
- `Test FPC/EclbrSystem/PTestRTTI.lpi` — projeto Lazarus (padrão
  `PTestModernCallback.lpi`; `<SyntaxMode Value="Delphi"/>` em ambos os
  build modes).

**Motivo da mudança:** D7 anterior assumia que a #7 criaria a infra. A #7
entregou; o padrão existe. Não há razão para depender do merge de outra issue
quando podemos replicar o padrão documentado. CA-8/CA-11 do ESP não ficam
mais pendentes por causa da #7.

### D8 — Zero `{$I ModernSyntax.inc}`; `{$IFDEF FPC}` / `{$IFNDEF FPC}` direto (R3 do PRD)

A unit não inclui o `.inc` (que tem o typo `FCP` em
`ModernSyntax.inc:261` em `main`). Toda ramificação é `{$IFDEF FPC}` /
`{$IFNDEF FPC}` direto e permanece **dentro** da unit (invisível ao
consumidor — CA-5).

**Diretiva de modo FPC:** a unit de produção **não inclui `{$mode objfpc}`**
dentro de bloco `{$IFDEF FPC}`. `{$mode objfpc}` derruba `strict private` em
records e sobrescreve `-Mdelphi` da linha de comando (defeito medido no PR
#17). Se o implementador precisar de diretiva de modo explícita na unit,
usa `{$mode delphi}{$H+}`. O `.lpr` do runner FPC pode usar `{$MODE OBJFPC}`
(é apenas o programa de entrada, sem records `strict private`); o `.lpi`
usa `<SyntaxMode Value="Delphi"/>` em ambos os build modes.

### D9 — Casca de teste fina, cenário compartilhado sem framework

Padrão herdado da #7/#9/#10:
- `Test Shared/EclbrSystem/UScenarios.RTTI.pas` — procedures livres,
  asserts nativos, fixtures com `{$M+}` + `published` no próprio arquivo.
- `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` — DUnitX, `[Test]` chama uma
  linha útil.
- `Test FPC/EclbrSystem/UTestMS.RTTI.pas` — FPCUnit, `procedure Test…`
  chama a mesma linha útil.
- **Zero `{$IFDEF FPC}` em qualquer um dos três arquivos de teste** —
  CA-5 binário (grep manda).

**Runner Delphi novo (`PTestRTTI.dpr` + `.dproj`) desta issue.** Runner FPC:
`PTestRTTI.lpr` + `PTestRTTI.lpi` criados por esta issue (padrão commit
`7114cdc`). `TestMSGroup.groupproj` (13 → 14) e `DCC.bat` (13 → 14)
ganham a entrada aditiva.

### D10 — Cabeçalho SPDX-MIT em `(* … *)`

Não usar `{ … }`. Defeito medido no PR #12 do ciclo #7: um `{$…}` dentro
de `{ }` fecha o comentário no primeiro `}`. RN-8 do
[ESP #10](../cycle-005-2ef372d9/pipeline-esp.md), RN-7 do
[ESP #9](../cycle-004-e936cbe6/pipeline-esp.md). Aplicado
aqui como RN-11 do [ESP](pipeline-esp.md).

### D11 — Prefixo de interface pendente do dono; **não bloqueia** esta issue

Medições registradas no REPORT: 7 bare `I*` vivas / 1 `IModern*` viva /
1 `IMS*` morta (`IMSObserver` em `Source/ModernSyntax.pas:27`).
**Pilar 1 não introduz interface pública** (só records e uma exceção),
então o prefixo não afeta esta entrega. Registra-se aqui que a **próxima**
issue da família que introduzir interface **trava** até o dono ratificar
`IModern*` (herdando a #7) vs `IMS*` (dead-code) vs bare `I*` (padrão
majoritário vivo).

### D12 — `TModernRTTIField` e `GetFields` Delphi-only (opção 1)

**Decisão:** `TModernRTTIField` e `TModernRTTIType.GetFields` são superfície
Delphi-only, **ausentes por compilação** no FPC via `{$IFNDEF FPC}…{$ENDIF}`.
O consumidor FPC que tentar usá-los recebe erro de compilação — não
comportamento silencioso em runtime.

**Motivo medido:** `TRttiField` não existe no FPC 3.2.2 (erro:
`"Identifier not found TRttiField"`). `TRttiType.GetFields` também ausente.
Não é limitação contornável: é ausência de símbolo na `Rtti` do FPC 3.2.2.
`TObject.FieldAddress` existe mas só funciona para campo publicado de tipo
classe (campo `string` ou `Integer` sequer compila como `published` no FPC).
Não há caminho portável geral para campos no FPC 3.2.2.

**Padrão:** mesmo padrão da RTTI dinâmica decidido na issue #13.

**Alternativas avaliadas:**
- **(2) Sair do Pilar 1 e virar issue própria** — defensável se o Pilar 1
  precisar ficar mais limpo (só propriedades como entregável cross-platform).
  Descartada porque a entrega parcial Delphi-only é coerente com o padrão da
  família e custa menos scope do que abrir uma issue irmã agora.
- **(3) `FieldAddress` limitado** — só funciona para campo publicado de tipo
  classe; campo `string`/`Integer` não compila como `published`. Não é API
  geral; docuementar a limitação seria mais confuso que a ausência explícita.

**Custo aceito:** consumidor FPC não acessa campos de instância por RTTI nesta
versão. Esse custo é menor que expor uma API que parece portável mas não é.

## Convergências herdadas (cross-check do REPORT)

- **FPCUnit no lado FPC** — herdado da #7 e #10.
- **`Test Shared/` para cenários** — herdado da #7 e #9 e #10.
- **Casca fina** — herdado da #7/#9/#10.
- **Sem `{$I ModernSyntax.inc}`** — R3 do PRD.
- **Sem importar unit interna do projeto** — STUDY §C-4.
- **Número de callbacks/tokens = 415** — adota-se a medição da #7
  (`TProc`/`TFunc` distintos, não tokens brutos como `TProcedure`).
- **FPC project standalone** — padrão do commit `7114cdc` da #7; esta issue
  cria seus próprios `.lpr`/`.lpi` (D7 revisado).
- **`{$mode delphi}` — nunca `{$mode objfpc}` — na unit de produção** — D8.

**Divergências em relação ao REPORT do investigate:** nenhuma.

## Consequências

- **Positivas:**
  - Entrega 100% aditiva: 0 impacto nas 431 asserts existentes
    (STUDY §C-1: grep dos tipos novos em `Source/` retorna vazio).
  - Consumidor escreve o mesmo código nos dois compiladores para propriedades
    (CA-1, CA-5). Campos: Delphi-only por ausência limpa de símbolo (D12).
  - Silêncio venenoso do FPC (lista vazia sem `{$M+}`) vira exceção
    instrutiva (R4, D3).
  - Overload `TValue` documentado dá saída para casos em que `AsType<T>`
    do FPC falhar (RSK-2 do ESP).
  - FPC project standalone: CA-8 não depende de merge da #7.

- **Negativas / aceitas:**
  - Consumidor FPC não acessa campos de instância por RTTI (D12). Custo
    declarado no ADR; consumidor recebe erro de compilação explícito.
  - `Rtti` marcada `experimental` gera aviso em cada build da unit e em
    cada consumidor do overload `TValue` (RSK-3 do ESP).
  - Verificação exata do sinal `PropCount == 0` no FPC 3.2.2 depende do
    primeiro build (R2 do PRD, RSK-1 do ESP). Ramificação, se necessária,
    fica dentro da unit.

## Sub-decisões pendentes do dono (registradas, não bloqueantes)

1. **Texto exato da mensagem R4** — RN-7/D4 tem rascunho unificado; se o
   dono preferir dois textos separados, o `raise` ganha `{$IFDEF FPC}`
   interno. Não bloqueia esta issue.
2. **Prefixo `IModern*` vs bare `I*` vs `IMS*`** — não afeta Pilar 1
   (D11). Trava a próxima issue com interface.
3. **Portabilidade real da verificação `PropCount == 0`** — o
   implementador confirma no primeiro build FPC (R2 do PRD).
4. **Limites de `TValue.AsType<T>` no FPC 3.2.2 para `T` complexo** — se
   falhar, o overload `TValue` cru vira o caminho recomendado para esses
   `T`. Decisão do autor no primeiro build.
5. **`TModernRTTIField` em issue futura dedicada** — D12 opta por
   Delphi-only agora. Se o dono quiser campos portáveis no futuro, uma
   issue irmã pode introduzir uma API alternativa (ex.: via FieldAddress
   limitado a campo de tipo classe, com limitação declarada em voz alta).
   Não bloqueia esta entrega.
