---
type: spec
kind: artifact
title: "ESP — Transversal ModernRTTI: callbacks portáveis (unit ModernSyntax.Callback)"
description: "Especifica a unit nova ModernSyntax.Callback com três interfaces de contrato para func/proc/predicate e um factory Callback.Of, compilando idêntico no Delphi XE+ e no FPC 3.2.2 sem exigir ramificação no consumidor."
status: draft
cycle: "004"
agent: architect
workflow: equipe-feature
node: "plan-gate:on_reject"
resource: aefos://run/24c962dcc2be1819336ca1fea18ae949
tags: [modernrtti, callbacks, fpc, delphi, transversal, spec, issue-7]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-08-28T13:30:00Z"
sources:
  - id: prd
    resource: "../strategy/2026-08-27-modernrtti/PRD.md"
    title: "ModernRTTI PRD"
  - id: study
    resource: "../strategy/2026-08-27-modernrtti/STUDY.md"
    title: "ModernRTTI Study — medições de dia zero"
  - id: arch
    resource: "../analysis/03-architecture.md"
    title: "03 Architecture — ModernSyntax"
---

# ESP — Callbacks transversais da ModernRTTI (issue #7)

## 1. Objetivo

Entregar a **fundação de callbacks** da camada ModernRTTI: três contratos
de interface (`IModernFunc<T,R>`, `IModernProc<T>`, `IModernPredicate<T>`
— nome fixado no [adr](pipeline-adr.md), decisão D-A9) e um factory `Callback.Of`
como atalho para o caso simples de método de objeto. A mesma API compila
no Delphi XE+ e no **FPC 3.2.2 estável**, sem que o consumidor escreva
`{$IFDEF FPC}` em ponto algum (D2/D3 do
[PRD](/strategy/2026-08-27-modernrtti/PRD.md)).

Medido no [STUDY](/strategy/2026-08-27-modernrtti/STUDY.md) e reafirmado
na investigação: o FPC 3.2.2 **não tem** `reference to` nem os
modeswitches `functionreferences`/`anonymousfunctions`. Portanto, isto
não é abstrair duas formas do mesmo recurso — é **implementar o recurso
onde ele não existe**, via interface + objeto de captura.

## 2. Escopo

Entra nesta entrega:

- Nova unit `Source/ModernSyntax.Callback.pas` contendo:
  - Três interfaces genéricas de contrato (`Invoke` como único método),
    **sem GUID** (D-5 da investigação).
  - Um factory `Callback` (record de métodos de classe) com o método
    `Of` sobrecarregado para os três formatos, aceitando **método de
    objeto** (`function of object` / `procedure of object`) e devolvendo
    a interface correspondente.
  - Implementação interna de wrappers que adaptam método de objeto para
    a interface — invisível ao consumidor.
- Ramificação **contida na unit**: `{$IFDEF FPC}` direto no arquivo,
  **sem** `{$I ModernSyntax.inc}` (R3 do PRD).
- Testes que **provam** portabilidade em ambos os compiladores.

Entra também a nova convenção de teste, que a investigação já fixou como
válida para toda a família ModernRTTI (D-1/D-2):

- `Test Shared/EclbrSystem/UTestMS.Callback.Scenarios.pas` — unit de
  cenários **sem framework de teste**: funções que executam o caso e
  levantam exceção na falha. **Escrita uma única vez**, consumida pelos
  dois lados.
- `Test Delphi/EclbrSystem/UTestMS.Callback.pas` — casca fina DUnitX
  (~5 linhas por caso) que chama o cenário e deixa a exceção virar
  `Fail`; projeto `PTestModernCallback.dpr` espelhando os outros.
- `Test FPC/EclbrSystem/UTestMS.Callback.pas` — casca fina **FPCUnit**
  (nativo do FPC 3.2.2, medido) que chama o mesmo cenário; projeto
  `Test FPC/EclbrSystem/PTestModernCallback.lpi` + `.lpr` que o
  `lazbuild` constrói (CA-6).

Fora do escopo:

- Converter os **415 usos** de `TProc`/`TFunc` já espalhados na
  biblioteca (D4 do PRD; medição do STUDY corrigida na investigação —
  o número 451 do PRD estava desatualizado; ver [adr](pipeline-adr.md) D-A10).
- Pré-processamento, macro, geração de código ou qualquer passo antes
  do compile (D3 do PRD).
- Sobrecarga de `Callback.Of` aceitando `TFunc<T,R>` no Delphi. A
  investigação (D-4) recusou: cria API que **parece** portável e não é.
- Suporte a procedure global no factory. Fora desta entrega (D-4).
- Correção do bug `{$IFDEF FCP}` em `ModernSyntax.inc:256` (R3 do PRD
  fecha esse item; a unit contorna não incluindo o `.inc`).
- Correção de `Windows` em interface de `Std.pas`/`DotEnv.pas`.

## 3. Regras de negócio

- **RN-1.** A unit expõe os três contratos, o factory `Callback` e as
  três classes wrapper de implementação. As classes wrapper são
  declaradas na `interface` **por exigência do FPC 3.2.2** (D-A13 do
  [adr](pipeline-adr.md)): o compilador expande o template genérico no ponto de
  uso do factory declarado na `interface`, onde os símbolos da
  `implementation` não são visíveis. O consumidor nunca instancia os
  wrappers diretamente — o único ponto de entrada é `Callback.Of`.
- **RN-2.** As três interfaces **não têm GUID**. São contrato de
  chamada, não de descoberta (D-5). O consumidor passa a interface pelo
  tipo declarado (`IModernFunc<Integer,String>`), nunca por
  `IInterface` genérico com `Supports`.
- **RN-3.** Ramificação `{$IFDEF FPC}` é permitida **dentro** da
  `ModernSyntax.Callback.pas` e proibida em qualquer arquivo que
  represente código do consumidor: `UTestMS.Callback.Scenarios.pas`,
  `UTestMS.Callback.pas` (Delphi e FPC), `.dpr`, `.lpr` (CA-5 do PRD).
- **RN-4.** A unit **não inclui** `ModernSyntax.inc` (R3 do PRD). Todo
  guard é `{$IFDEF FPC}` direto.
- **RN-5.** A unit nasce **autocontida**: `uses SysUtils;` e nada mais.
  Justificativa medida na investigação: qualquer outra unit da própria
  biblioteca traz `reference to` ou o `.inc` transitivamente.
- **RN-6.** Captura de variável é atendida via **classe helper** que o
  consumidor declara com o estado em campo, implementa a interface, e
  passa a instância. É a mesma forma nos dois compiladores; é isto
  que satisfaz CA-4 **e** CA-5 do PRD ao mesmo tempo.

## 4. Critérios de aceitação

Vinculam CA-4/CA-5/CA-6/CA-7/R2 do
[PRD](/strategy/2026-08-27-modernrtti/PRD.md) ao entregável concreto:

- **CA-1.** As três interfaces (`IModernFunc<T,R>`, `IModernProc<T>`,
  `IModernPredicate<T>` — nomes fixados no [adr](pipeline-adr.md), D-A9) compilam
  no Delphi e no FPC 3.2.2 **sem modificação** no código do consumidor.
- **CA-2.** `Callback.Of(Self.MinhaProc)` funciona como atalho para
  método de objeto nos dois compiladores. Coberto por caso positivo
  em `UTestMS.Callback.Scenarios.pas`.
- **CA-3.** Callback com **captura de variável** funciona nos dois
  compiladores via classe helper que implementa `IModernFunc<T,R>`
  (CA-4 do PRD). Caso positivo em `UTestMS.Callback.Scenarios.pas`.
- **CA-4.** `grep -rn "{\$IFDEF FPC}" "Test Shared/" "Test Delphi/"
  "Test FPC/"` retorna **zero linhas** (CA-5 do PRD).
- **CA-5.** A entrega inclui `Test FPC/EclbrSystem/PTestModernCallback.lpi`
  (ou `.lpr`) que **o FPC 3.2.2 constrói** para esta unit (CA-6 do PRD).
  Se o `.dproj` do lado Delphi precisar de ajuste de search path para
  achar `Test Shared/`, o ajuste vai no mesmo commit.
- **CA-6.** Os testes compilam e passam nos dois compiladores: FPC
  3.2.2 x86_64 e i386 (pelo implementador — FPC 3.2.2 disponível na
  fábrica; evidência obrigatória no corpo do PR) e Delphi (pelo autor).
  Não há entrega válida sem compilação FPC confirmada.
- **CA-7.** O corpo do PR declara literalmente: *"compilado em FPC
  3.2.2 x86_64 e i386; não compilado em Delphi — Delphi permanece com o
  autor"* (R2 do PRD).
- **CA-8.** A unit `Source/ModernSyntax.Callback.pas` não contém
  `{$I ModernSyntax.inc}` **nem** o token `FCP`. Verificável por grep.

## 5. Restrições

- **Alvo FPC:** 3.2.2 estável, 32 e 64 bits (`i386` e `x86_64`). Não é
  trunk, não é 3.3.
- **Alvo Delphi:** XE+ (conforme intake), compilação verificada pelo
  autor.
- **FPC 3.2.2 na fábrica; Delphi com o autor.** O implementador compila
  e executa FPCUnit no FPC 3.2.2 x86_64 e i386 antes de abrir o PR.
  Compilação Delphi permanece com o autor.
- **Cabeçalho das units em `(* ... *)`.** Diretivas `{$...}` não podem
  aparecer dentro de comentário `{ }` — o `}` da diretiva fecha o
  comentário (regra da linguagem Pascal, não diferença de compilador;
  D-A12 do [adr](pipeline-adr.md)). Citar diretiva em prosa: escrever
  `IFDEF FPC` sem chaves.
- **`uses` permitidos na unit nova:** `SysUtils`. Só.
- **Convenção de diretório espelhado** por compilador: `Test Delphi/…`
  e `Test FPC/…` (D-1 da investigação).
- **Sem DUnitX no lado FPC.** DUnitX não está vendorizado (medido:
  `find . -iname "DUnitX*.pas"` → 0). FPCUnit é nativo (medido:
  `fpcunit.ppu` em `units/x86_64-win64/fcl-fpcunit/`).

## 6. Riscos

- **RSK-1 — Divergência de cenários entre lados.** Fixtures duplicadas
  divergem em silêncio, e teste que diverge é pior que código que
  diverge. Mitigação obrigatória: lógica dos cenários mora **uma vez**
  em `Test Shared/`. Cascas finas não podem crescer `if/then` de
  asserção (D-2).
- **RSK-2 — Nome dos contratos.** `IMS*` **não é** convenção do
  repositório (medido: 1 em 9 interfaces públicas, e a única é código
  morto — `IMSObserver`). Padrão dominante é `IModern<Nome>`. Decisão
  arquitetural resolvida no [adr](pipeline-adr.md), D-A9.
- **RSK-3 — Search path do `.dproj` para `Test Shared/`.** Não medido.
  Resolvido em implementação, no mesmo commit.
- **RSK-4 — Configuração de saída do FPCUnit para CI.** Não medido.
  Não bloqueia esta entrega.
- **RSK-5 — Interface genérica sem GUID no Delphi antigo.** Delphi XE+
  coberto.
- **RSK-6 — R3 do PRD (bug `{$IFDEF FCP}`).** Mitigado pela RN-4.
- **RSK-7 — Só método de objeto neste ciclo (D-4).** Consumidor Delphi
  vai continuar tentando passar `TFunc<...>` e receber erro de
  compilação. Aceito: alternativa criaria armadilha pior (código que
  **parece** portável e não é).
