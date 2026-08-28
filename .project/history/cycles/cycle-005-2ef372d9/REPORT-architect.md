---
type: cycle-report
kind: report
title: "Cycle #10 (005) — architect report — TModernInvoker (issue #10)"
description: "Derivou dossiê da issue #10 do relatório de investigação PRESENTE: TModernInvoker sobre TObject.MethodAddress (não TRttiContext.GetMethod), record com dois overloads Invoke<TSignature>, guarda SizeOf, mensagem acionável, unit autocontida; API dinâmica no padrão da RTTI nova do Delphi vai para issue irmã."
status: stable
cycle: "005"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/2ef372d993ff75b8dcd8c707bb79d636
tags: [architect, invoker, modernrtti, issue-10, cycle-005]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-08-28T14:15:00Z"
sources:
  - id: esp
    resource: "pipeline-esp.md"
    title: "ESP — TModernInvoker (cópia da mirror)"
  - id: adr
    resource: "pipeline-adr.md"
    title: "ADR — Design da unit ModernSyntax.Invoker (cópia da mirror)"
  - id: plan
    resource: "pipeline-plan.md"
    title: "Plan — TModernInvoker (cópia da mirror)"
  - id: task-input
    resource: "pipeline-task-input.md"
    title: "Task input — TModernInvoker (cópia da mirror)"
  - id: investigation
    title: "Relatório de investigação da issue #10 (run 96cd7df3aafbc7ce615f0fe5b2cb4ab8)"
---

# Cycle #10 (005) — Architect report

## O que foi decidido

Derivei o dossiê da issue #10 do relatório de investigação (status **PRESENT** —
run `96cd7df3aafbc7ce615f0fe5b2cb4ab8`, duas voltas, decisão em vigor). Nada foi
adicionado nem tirado em silêncio — o ADR restaura as decisões nos termos que a discussão
fechou, e o esp/plan/task-input traduzem a decisão em contrato, execução e handoff.

**Núcleo da decisão** (D-A2/D-A3/D-A5 do [adr](pipeline-adr.md)):

- **Mecanismo:** `TObject.MethodAddress`, **não** `TRttiContext.GetType(...).GetMethod(...)`.
  Motivo medido na volta 1: no FPC 3.2.2, `GetMethods = 0` para qualquer classe (mesmo com
  `{$M+}` e `published`); `Rtti` é `experimental`. `TRttiMethod` **não existe** no alvo —
  não é degradação, é ausência. O STUDY lera o `main` do FPC, não o 3.2.2.
- **API:** `record` com dois overloads
  `class function Invoke<TSignature>(TObject|TClass, string): TSignature; static;`.
  Consumidor declara `type TFn = function(...) : T of object;` antes de invocar. Não há
  `array of TValue` — no FPC 3.2.2 não há de onde ler os tipos dos parâmetros.
- **Guarda `SizeOf` como primeira linha** dos dois corpos: cobre corrupção silenciosa
  quando `TSignature` não é método-de-objeto (16 bytes copiados por `Move` em cima de,
  ex., `Integer`). Limite documentado: não cobre "outro tipo qualquer de 16 bytes".
- **Mensagem acionável** de "não encontrado" cita `{$M+}` **e** `published` — herança
  literal da decisão da família #8: falha de exposição vira exceção que **ensina**, não
  silêncio.
- **Autocontenção:** `uses SysUtils;` apenas; zero `{$IFDEF FPC}`; zero `{$I ModernSyntax.inc}`;
  zero import de `Source/`. Nenhuma das 16 units existentes de `Source/` compila em FPC
  3.2.2 hoje (medido pelo dono; [SKILL](../../SKILL.md) §"Two traps" #1).
- **Convenção de teste da família** aplicada sem reabrir (D-A8 do adr): cenários em
  `Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas` (7 casos, sem framework), casca
  fina DUnitX em `Test Delphi/…`, casca fina FPCUnit em `Test FPC/…`. **Sem `.inc` de
  símbolos** — a Invoker se comporta igual nos dois compiladores, então não há capacidade
  a bifurcar; a guarda `{$MESSAGE FATAL}` que a #9 usou não se aplica aqui.

**Rename explícito** (D-A10 do adr): `Case_Invoke_WithArgs_PassesThemThrough` →
`Case_TypedMethod_CalledWithArgs_ReturnsExpected`. O `Invoke` do desenho A não recebe args;
o nome novo descreve o que o teste **de fato** prova.

**Resposta explícita de Q1 do PRD** (CA-12 do esp; item obrigatório do PR body):
*"Q1 não exigiu `{$IFDEF}` interno. A divergência que replaneou o Pilar 3 foi
`GetMethods = 0` no FPC 3.2.2, não a assinatura de `TRttiMethod.Invoke`. Mecanismo é
`TObject.MethodAddress`, símbolo comum aos dois compiladores."*

## Recomendação para o dono (fora do escopo desta issue)

Abrir **issue irmã** da API dinâmica no padrão da RTTI nova do Delphi
(`GetType(T).GetMethod('X').Invoke(obj, [args]): TValue`):

- **Alvo:** Delphi ≥ 10.4.
- **Superfície:** declaradamente Delphi-only, **ausente por compilação no FPC**
  (`{$IFDEF DELPHI}` na declaração inteira). Divergência que **quebra o build** é honesta;
  divergência silenciosa em runtime é o defeito nº 1 do PRD.
- **Motivo do recorte:** (a) padrão pedido pelo dono na volta 2 da investigação;
  (b) medido como impossível no FPC 3.2.2 (`GetMethods = 0`); (c) ninguém neste ciclo tem
  Delphi para provar; (d) entregar o núcleo provado + um anexo não provado seria misturar
  o que caiu de pé com o que cai de joelho.

Registrada em `D-A9` do [adr](pipeline-adr.md) e em `RSK-6` do [esp](pipeline-esp.md).

## Escopo do ciclo

`scope = fits`. Test 1 (SIZE) e Test 2 (INDEPENDENCE) analisados em detalhe no
[plan](pipeline-plan.md) §"Scope estimate":

- **SIZE:** unit de produção com ~70 linhas (o dono compilou 66 linhas com a guarda na
  volta 2), duas cascas finas de teste, um `.lpi` escrito à mão. Cabe folgado.
- **INDEPENDENCE:** nenhuma fatia é mergeável sozinha — sem a unit, os cenários não
  compilam; sem cenários compartilhados, as cascas divergem; sem a casca FPC, não há
  CA-9 do esp/CA-7 do PRD.

## Artefatos entregues neste ciclo

- [esp](pipeline-esp.md) — especificação com 12 CAs e 6 riscos.
- [adr](pipeline-adr.md) — 10 decisões (D-A1..D-A10), herdando D-A7/D-A8 dos ADRs dos
  ciclos #7 e #8 (referência via `history/cycles/…`).
- [plan](pipeline-plan.md) — 4 fatias sequenciais + pós-condições do ciclo.
- [task-input](pipeline-task-input.md) — handoff operacional com checklist de aceite,
  arquivos criados/proibidos, notas de implementação, PR body mandatório.

## Notas de conformidade

- Não escrevi código de produção; escrevi apenas em `.project/`.
- Todos os documentos abrem com frontmatter OKF com `type` não-vazio, `kind: artifact`
  (`kind: report` neste report), `cycle: "005"`, `agent: architect`, `workflow`, `node`
  e `resource` no topo (não aninhado sob `producer:`).
- Cross-links internos ao ciclo usam nomes de irmão (`pipeline-esp.md`), como manda a
  regra OKF-authoring §4 (o `mirror` renomeia; o autor acerta o próprio lado).
- Cross-links para o bundle usam forma absoluta-do-bundle (`../strategy/…`, `../SKILL.md`,
  `../history/cycles/…`) — como os ADRs #7 e #8 já faziam. Nenhum link aponta para
  `.project/pipeline/` (git-ignored).
- Não abri `FLOW-FEEDBACK.md`: o handoff da issue #10 chegou completo e o relatório de
  investigação estava íntegro; sem fricção de pipeline a registrar.
