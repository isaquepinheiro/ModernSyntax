---
type: cycle-report
kind: report
cycle: "004"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/e936cbe6a17a8e76ec8ca9a02ec30735
title: "Cycle 004 — architect report (issue #9, ModernRTTI Pilar 2 — atributos)"
description: "Especificação, decisões e plano para ModernSyntax.Attributes com TModernAttribute obrigatório, registry ownership-por-origem, regra 2 do ADENDO (registrado prevalece por classe) e reuso da convenção Test Shared/Test FPC/Test Delphi fixada no ciclo #7."
status: stable
tags: [architect, cycle-report, modernrtti, attributes, issue-9]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-08-28T13:30:00Z"
---

# Architect — cycle 004 (issue #9)

Demanda: **[maestro repo=isaquepinheiro/ModernSyntax issue=9]** — Pilar 2 do
ModernRTTI. Investigação para esta issue: **PRESENT** (run `17ad5323`,
comentário no issue), **incluindo ADENDO do orquestrador anexado depois
da conversa fechar**.

## O que foi produzido neste ciclo

Quatro artefatos em `.project/pipeline/`:

- [pipeline-esp](pipeline-esp.md) — especificação formal (objetivo, escopo,
  RN, critérios, restrições, riscos).
- [pipeline-adr](pipeline-adr.md) — 12 decisões arquiteturais, derivadas do
  relatório da investigação **e do ADENDO**; onde este ADR estende, é para
  formalização OKF.
- [pipeline-plan](pipeline-plan.md) — cinco fatias sequenciais no mesmo
  ciclo (`scope = fits`).
- [pipeline-task-input](pipeline-task-input.md) — handoff operacional com
  checklist granular e PR body mandatório.

## Decisões que este ciclo fecha

1. **`TModernAttribute` obrigatório** (D-A2 do ADR). A ramificação por
   compilador vive dentro da biblioteca; o consumidor escreve
   `class(TModernAttribute)` idêntico nos dois compiladores. D2/CA-5 do PRD
   respeitados sem interpretação.
2. **Ownership por origem** via `TAttributeRecord.Owned` (D-A3/D-A4).
   `finalization` libera **apenas** o que a registry possui; nunca instâncias
   vindas da RTTI do Delphi. Elimina AV no shutdown.
3. **Regra 2 do ADENDO** (D-A6). No Delphi, `GetAttributes` descarta a
   instância nativa se `Owned` contém alguma da mesma `ClassType`. **O
   registrado prevalece por classe.** Sem esta regra, o próprio cenário
   "prova viva de CA-2" quebraria CA-2 (dedup por identidade não funde
   instância criada pelo Delphi com instância criada pelo consumidor).
4. **Guarda de include vive na casca `.pas`, não no `.dpr`** (D-A8). O `.inc`
   define **um de dois** símbolos (`HAS_NATIVE_ATTRS` XOR `NO_NATIVE_ATTRS`)
   e a guarda `{$IF NOT DEFINED(...) AND NOT DEFINED(...)}{$MESSAGE FATAL}`
   fica após o `{$I}` na própria casca. Motivo medido: `{$DEFINE}` tem
   escopo por unidade de compilação — `.dpr` não enxerga símbolo definido
   na casca `.pas` que ele compila. Consequência: some o `{$IFNDEF FPC}` do
   `.dpr` e some a "interpretação de D-5" que estaria frágil.
5. **`{$I}` sem caminho, include search path no projeto** (D-A11). Contrabarra
   não resolve fora do Windows; caminho relativo longo quebra na
   reorganização de diretório que **é** este ciclo (nasce `Test FPC/`).
6. **Zero stub de `ModernSyntax.RTTI.pas`** (D-A12). API pública desta issue
   é `ModernAttributes.GetAttributes(TFoo)`. CA-2 na letra fica para a #8
   delegar. Ordem de entrega, não CA-2 diluído; declarado em voz alta no PR.
7. **Convenção da família herdada** (D-A7). Aplica sem reabrir o desenho
   fixado no [ADR cycle-003, D-A7/D-A8](../cycle-003-92fccbce/pipeline-adr.md):
   `Test Shared/EclbrSystem/` + `Test Delphi/EclbrSystem/` + `Test FPC/EclbrSystem/`,
   FPCUnit no lado FPC, cascas finas.

## Restrições operacionais registradas em voz alta

- **R-FPC-Generic** (D-A9). Tipo instanciado por método público da `interface`
  deve estar na `interface`. `TAttributeRecord` é promovido a público apesar
  de preferirmos privado. Custo declarado, aceito. Motivo medido: PR #12 do
  ciclo #7 quebrou com `Global Generic template references static symtable`.
- **R-Comment-Nest** (D-A10). Header SPDX escrito com `(* ... *)`; nenhuma
  `{$...}` dentro de `{ }`. Motivo medido: PR #12.
- **Armadilha do `{$DEFINE}` que não atravessa fronteira de arquivo** (D-A8).
  Registrada como "mecanismo de segurança que não mede o que promete medir"
  — mesma família dos defeitos dos PRs #11 e #12. Nomear a família ajuda a
  próxima issue a reconhecer.

## Scope estimate

`scope = fits`, cinco fatias sequenciais.

- **Test 1 (SIZE):** unit de produção enxuta (uma classe base + um record de
  fachada + registry + fusão nativo/registrado). Testes são cascas finas com
  uma unit compartilhada. Cabe em um orçamento normal de implementação.
- **Test 2 (INDEPENDENCE):** nenhuma fatia é mergeável sozinha. Sem a unit,
  cenários não compilam; sem cenários, cascas divergem; sem casca FPC,
  CA-5/CA-6 do esp falham; sem regra 2 do ADENDO na §1, "prova viva de
  CA-2" quebra CA-2. Split violaria a fundação.

## Riscos relevantes elevados no dossiê

- **RSK-1** (esp): divergência silenciosa entre compiladores para `[MyAttr]`
  nativo sem `Register`. Mitigada por dois testes específicos de capacidade
  (`TestDelphi_NativeAlone`, `TestFPC_NativeAlone`) e por linha de fronteira
  no PR.
- **RSK-2** (esp): AV no shutdown por liberar referência da RTTI.
  Mitigada por ownership por origem (D-A4) + `ReportMemoryLeaksOnShutdown`
  no `.dpr` (CA-6).
- **RSK-3/4** (esp): verificações pendentes do lado Delphi (search path do
  `.dproj`; aceitação de descendente transitivo em `[MyAttr]`; instância
  nova vs mesma referência em `GetAttributes` — regra 2 é segura sob as
  duas hipóteses).
- **RSK-5/6** (esp): R-FPC-Generic e R-Comment-Nest — restrições
  operacionais.
- **RSK-7** (esp): `{$DEFINE}` sem escopo cross-file — resolvido pela guarda
  na casca.
- **RSK-8** (esp): thread-safety básica via `TCriticalSection`. Registro
  esperado em `initialization`; leitura majoritária depois.

## Cross-links do bundle

- [PRD ModernRTTI](../../../strategy/2026-08-27-modernrtti/PRD.md) — D1, D2, R2, R3, CA-2, CA-5, CA-7, Q2.
- [STUDY ModernRTTI](../../../strategy/2026-08-27-modernrtti/STUDY.md) — medição de zero atributos no codebase atual.
- [ADR ciclo #7 (callbacks)](../cycle-003-92fccbce/pipeline-adr.md) — D-A7/D-A8 (convenção da família herdada); R-FPC-Generic e R-Comment-Nest (medidas no PR #12 daquele ciclo).
- [analysis conventions](../../../analysis/05-conventions.md) — nomes de unit, prefixos, header SPDX, DUnitX.
