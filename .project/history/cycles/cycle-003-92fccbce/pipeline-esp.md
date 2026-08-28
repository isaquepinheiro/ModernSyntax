---
type: spec
kind: artifact
title: "ESP — Transversal ModernRTTI: callbacks portáveis (unit ModernSyntax.Callback)"
description: "Especifica a unit nova ModernSyntax.Callback com três interfaces de contrato para func/proc/predicate e um factory Callback.Of, compilando idêntico no Delphi XE+ e no FPC 3.2.2 sem exigir ramificação no consumidor."
status: draft
cycle: "003"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/92fccbce1ddb8c2d37df799793017636
tags: [modernrtti, callbacks, fpc, delphi, transversal, spec, issue-7]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-08-28T10:40:00Z"
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
de interface (`IMSFunc<T,R>`, `IMSProc<T>`, `IMSPredicate<T>` — nome
sujeito à decisão do ADR, seção D-N) e um factory `Callback.Of` como
atalho para o caso simples de método de objeto. A mesma API compila no
Delphi XE+ e no **FPC 3.2.2 estável**, sem que o consumidor escreva
`{$IFDEF FPC}` em ponto algum (D2/D3 do
[PRD](../../../strategy/2026-08-27-modernrtti/PRD.md)).

Medido no [STUDY](../../../strategy/2026-08-27-modernrtti/STUDY.md) e reafirmado
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
  o número 451 do PRD estava desatualizado).
- Pré-processamento, macro, geração de código ou qualquer passo antes
  do compile (D3 do PRD).
- Sobrecarga de `Callback.Of` aceitando `TFunc<T,R>` no Delphi. A
  investigação (D-4) recusou: cria API que **parece** portável e não é.
  Se vier, virá em issue própria com aviso em voz alta.
- Suporte a procedure global no factory. Fora desta entrega (D-4).
- Correção do bug `{$IFDEF FCP}` em `ModernSyntax.inc:256` (R3 do PRD
  fecha esse item; a unit contorna não incluindo o `.inc`).
- Correção de `Windows` em interface de `Std.pas`/`DotEnv.pas`. A
  unit nova só faz `uses SysUtils` (justificado na investigação —
  qualquer outra unit da biblioteca traz transitivamente `reference to`
  ou o `.inc`).
- Conversão dos testes existentes em Delphi para o novo formato de
  cascas finas. Só vale para o que **este** ciclo entrega.

## 3. Regras de negócio

- **RN-1.** A unit expõe apenas os três contratos e o factory
  `Callback`. Nenhum tipo interno de wrapper vaza para a `interface`.
- **RN-2.** As três interfaces **não têm GUID**. São contrato de
  chamada, não de descoberta (D-5). Isto **exige** que o consumidor
  passe a interface pelo tipo declarado (`IModernFunc<Integer,String>`),
  nunca por `IInterface` genérico com `Supports`.
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
  passa a instância. Esta é a mesma forma nos dois compiladores; é isto
  que satisfaz CA-4 **e** CA-5 do PRD ao mesmo tempo (D-3 da
  investigação: o CA-5 proíbe **ramificação**, não **verbosidade**).

## 4. Critérios de aceitação

Vinculam CA-4/CA-5/CA-6/CA-7/R2 do
[PRD](../../../strategy/2026-08-27-modernrtti/PRD.md) ao entregável concreto:

- **CA-1.** As três interfaces (`IModernFunc<T,R>`, `IModernProc<T>`,
  `IModernPredicate<T>` — nomes fixados no [adr](pipeline-adr.md), D-N) compilam
  no Delphi e no FPC 3.2.2 **sem modificação** no código do consumidor.
- **CA-2.** `Callback.Of(Self.MinhaProc)` funciona como atalho para
  método de objeto nos dois compiladores. Vai coberto por caso positivo
  em `UTestMS.Callback.Scenarios.pas`.
- **CA-3.** Callback com **captura de variável** funciona nos dois
  compiladores via classe helper que implementa `IModernFunc<T,R>`
  (CA-4 do PRD). Caso positivo em `UTestMS.Callback.Scenarios.pas`.
- **CA-4.** `grep -rn "{\$IFDEF FPC}" "Test Shared/" "Test Delphi/"
  "Test FPC/"` retorna **zero linhas** (CA-5 do PRD).
- **CA-5.** A entrega inclui `Test FPC/EclbrSystem/PTestModernCallback.lpi`
  (ou `.lpr`) que **o FPC 3.2.2 constrói** para esta unit (CA-6 do PRD).
  Se o consumidor precisar de ajuste de search path no `.dproj`
  (Delphi) para achar `Test Shared/`, o ajuste vai neste ciclo — está
  entre as perguntas em aberto da investigação (Q2) e resolve-se em
  implementação, não em spec.
- **CA-6.** Os testes compilam e passam nos dois compiladores: FPC
  3.2.2 x86_64 e i386 (pelo orquestrador na máquina do autor) e Delphi
  (pelo autor). O ciclo **não** compila (R2 do PRD — a fábrica não tem
  Pascal).
- **CA-7.** O corpo do PR declara literalmente: *"compilado em FPC
  3.2.2 x86_64 e i386; não compilado em Delphi — Delphi permanece com o
  autor"* (R2 do PRD).
- **CA-8.** A unit `Source/ModernSyntax.Callback.pas` não contém
  `{$I ModernSyntax.inc}` **nem** o token `FCP`. Verificável por grep.

## 5. Restrições

- **Alvo FPC:** 3.2.2 estável, 32 e 64 bits (`i386` e `x86_64`). Não é
  trunk, não é 3.3 (PRD, D3).
- **Alvo Delphi:** as versões atualmente suportadas pela biblioteca
  (XE+ conforme intake), compilação verificada pelo autor.
- **Fábrica sem compilador Pascal.** Revisão aqui é por leitura;
  compilação real é do orquestrador na máquina do autor (R2).
- **`uses` permitidos na unit nova:** `SysUtils`. Só. Adicionar
  qualquer outra unit da própria biblioteca reintroduz transitivamente
  `reference to` ou o `.inc`.
- **Convenção de diretório espelhado** por compilador: `Test Delphi/…`
  e `Test FPC/…` (D-1 da investigação). Nada de misturar projetos FPC
  dentro de `Test Delphi/`.
- **Sem DUnitX no lado FPC.** DUnitX não está vendorizado no repositório
  (medido: `find . -iname "DUnitX*.pas"` → 0). FPCUnit é nativo (medido:
  `fpcunit.ppu` em `units/x86_64-win64/fcl-fpcunit/`). D-2 da
  investigação fecha essa escolha para a família ModernRTTI inteira.

## 6. Riscos

- **RSK-1 — Divergência de cenários entre lados.** A investigação
  recusou fixtures duplicadas por este risco: teste que diverge em
  silêncio é pior que código que diverge. Mitigação obrigatória: a
  lógica dos cenários mora **uma vez** em `Test Shared/`. Cascas finas
  não podem crescer `if/then` de asserção — se crescerem, volta para
  discussão (D-2).
- **RSK-2 — Nome dos contratos como decisão de gate.** A investigação
  levanta explicitamente que `IMS*` **não é** convenção do repositório
  (medido: 1 em 9 interfaces públicas, e a única é código morto —
  `IMSObserver`). O padrão dominante é `IModern<Nome>`. Este risco é
  **arquitetural**, resolvido no [adr](pipeline-adr.md), decisão D-N. Trocar
  depois de espalhar pela API é caro; agora é uma linha.
- **RSK-3 — Search path do `.dproj` para `Test Shared/`.** Não medido.
  Cai na implementação; caso o `.dproj` novo precise apontar para
  `..\..\Test Shared\EclbrSystem`, entra no mesmo commit.
- **RSK-4 — Configuração de saída do FPCUnit para CI.** Não medido. O
  lado Delphi usa logger NUnit XML; o lado FPC tem `consoletestrunner`
  nativo (medido: `consoletestrunner.ppu`) e `digesttestreport.ppu`
  para relatório em texto. A escolha de formato vira issue de CI
  separada se for necessária; **não bloqueia** este entregável.
- **RSK-5 — Interface genérica sem GUID no Delphi antigo.** Em versões
  muito antigas do Delphi já houve regressões em interfaces genéricas.
  A entrega alvo é XE+, coberto. Se aparecer regressão, fica contida
  na unit (RN-1 protege o consumidor).
- **RSK-6 — R3 do PRD (bug `{$IFDEF FCP}` no `.inc`).** Mitigação
  direta pela RN-4: a unit não inclui o `.inc`.
- **RSK-7 — Só método de objeto neste ciclo (D-4).** Consumidor Delphi
  vai continuar tentando passar `TFunc<...>` e receber erro de
  compilação. Aceito: a alternativa (aceitar `TFunc` sob `{$IFNDEF FPC}`)
  cria armadilha pior — código que **parece** portável e não é.
