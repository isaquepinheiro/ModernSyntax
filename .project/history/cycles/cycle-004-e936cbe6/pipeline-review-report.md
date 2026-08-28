---
type: review-report
kind: artifact
title: "Review report — Cycle 004: ModernSyntax.Attributes (Pilar 2 ModernRTTI)"
description: "Quality review of cycle-004 deliverables against esp.md, adr.md, and project conventions. Verdict: APPROVED with non-blocking observations."
cycle: "004"
agent: quality
workflow: equipe-feature
node: review
resource: aefos://run/e936cbe6a17a8e76ec8ca9a02ec30735
status: stable
tags: [review, cycle-004, modernrtti, attributes, issue-9]
generated:
  by: "equipe-feature@node:review"
  at: "2026-08-28T14:30:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — Atributos portaveis"
  - id: adr
    resource: "adr.md"
    title: "ADR — Design da unit ModernSyntax.Attributes"
  - id: implement-report
    resource: "implement-report.md"
    title: "Implement report — Atributos portaveis"
---

# Review report — Cycle 004

Issue: [isaquepinheiro/ModernSyntax#9](https://github.com/isaquepinheiro/ModernSyntax/issues/9).
Insumos: [esp](pipeline-esp.md), [adr](pipeline-adr.md), [implement-report](pipeline-implement-report.md).

## Verdict

**APPROVED** — all critical spec requirements are met; observations below are non-blocking.

---

## Summary

The implementation delivers the full Pillar 2 scope:

- `Source/ModernSyntax.Attributes.pas` — `TModernAttribute` (bifurcada), `TAttributeRecord`
  na `interface` (R-FPC-Generic), `ModernAttributes.Register` / `GetAttributes` com regra 2
  do ADENDO, registry + lock + `TRttiContext` proprio, `finalization` segura.
- `Test Shared/EclbrSystem/UTestMS.Attributes.Symbols.inc` — uma linha exata.
- `Test Shared/EclbrSystem/UTestMS.Attributes.Scenarios.pas` — cinco cenarios portaveis,
  sem framework, sem `{$IFDEF}`.
- Casca DUnitX + `.dpr` + `.dproj` em `Test Delphi/EclbrSystem/`, com dois testes
  Delphi-only (`TClasseNativa` + regra 2) atras de `{$IFDEF HAS_NATIVE_ATTRS}`.
- Casca FPCUnit + `.lpr` + `.lpi` em `Test FPC/EclbrSystem/`, com dois build modes
  (`Debug-x86_64` default, `Debug-i386`).

Compilacao pelo FPC e pelo autor (Delphi) sao responsabilidade do autor, per R2 do PRD.

---

## Checklist de revisao

### Spec — RN / CA

| Check | Status | Evidence |
|-------|--------|---------|
| RN-2: TModernAttribute bifurcada por IFDEF FPC | OK | Source/ModernSyntax.Attributes.pas linhas 51-54 |
| RN-3: Register toma posse, dedup por identidade | OK | Implementado; ignora nil (DEV-2, coerente com RN-4/CA-3) |
| RN-4: GetAttributes FPC = copia de Owned; Delphi = Owned + Native filtrado (regra 2) | OK | Ramos IFDEF FPC / ELSE no GetAttributes |
| RN-5: XMLDoc vista emprestada na assinatura publica | OK | XMLDoc palavra-por-palavra em GetAttributes |
| RN-6: sem ModernSyntax.inc, sem token FCP | OK | grep saida 1 (zero linhas) |
| RN-7: header SPDX em comentario bloco, sem diretivas dentro de comentario inline | OK | Todos os arquivos novos usam (* ... *) |
| RN-8: uses da interface correto | OK | Confirmado; Rtti sob IFNDEF FPC |
| RN-9: finalization libera so Owned; ordem correta | OK | FreeRegistryOwned > FRegistry.Free > FLock.Free > FContext.Free |
| CA-4: zero IFDEF FPC nos tres arquivos de teste | OK | grep saida 1 |
| CA-5: lpi com dois build modes (Debug-i386, Debug-x86_64) | OK | PTestAttributes.lpi confirmado |
| CA-6: ReportMemoryLeaksOnShutdown True no inicio do begin do dpr | OK | PTestAttributes.dpr linha 1 de begin |
| CA-8: PR body com tres declaracoes mandatorias | PENDENTE | Responsabilidade do no de release/PR (task-input secao fora-deste-ciclo) |
| CA-9: sem ModernSyntax.inc, sem FCP em Source/ModernSyntax.Attributes.pas | OK | grep saida 1 |

### ADR — decisoes

| D-A | Descricao resumida | Status |
|-----|-------------------|--------|
| D-A1 | Unit nova, uses minimo, TRttiContext proprio | OK |
| D-A2 | TModernAttribute base real, bifurcada | OK |
| D-A3 | TDictionary<TClass, TAttributeRecord> + TCriticalSection | OK |
| D-A4 | Ownership por origem; vista emprestada | OK |
| D-A5 | Dedup por identidade de referencia no Register | OK |
| D-A6 | Regra 2 do ADENDO em GetAttributes Delphi | OK |
| D-A7 | Convencao Test Shared / Test Delphi / Test FPC herdada do ciclo 7 | OK |
| D-A8 | Guarda MESSAGE FATAL na casca .pas, nao no .dpr; sem IFNDEF FPC no .dpr | OK |
| D-A9 | TAttributeRecord na interface por R-FPC-Generic | OK |
| D-A10 | R-Comment-Nest: nenhuma diretiva dentro de comentario inline | OK |
| D-A11 | include sem caminho; include search path no projeto | OK — lpi IncludeFiles; dproj DCC_UnitSearchPath |
| D-A12 | Zero stub de ModernSyntax.RTTI.pas; scope delimitado | OK |

### Verificacoes grep independentes (rodadas pelo reviewer)

| Gate | Resultado |
|------|-----------|
| IFDEF FPC nos tres arquivos de teste | exit 1 OK |
| ModernSyntax.inc em Source/ModernSyntax.Attributes.pas | exit 1 OK |
| FCP em Source/ModernSyntax.Attributes.pas | exit 1 OK |
| DUnitX em Test FPC | exit 1 OK |

---

## Criticas bloqueantes

Nenhuma.

---

## Observacoes nao-bloqueantes

### OBS-1 — Nome do cenario Scenario_NativePlusRegister_IsIdentical e semanticamente otimista

O cenario portavel afirma apenas o resultado do lado Register
(TAlvoNativePlusRegister nao carrega anotacao nativa no arquivo shared, por CA-4). O
**teste real** de native+registered vive no Delphi shell
(`TestDelphi_NativeSuppressedByRegistered_ReturnsRegisteredOnly`).
O codigo documenta a intencao nos comentarios, mas o nome pode ser confuso para
futuros leitores. Sugestao: `Scenario_Register_PreservesResult_AcrossCompilers`.

### OBS-2 — Estado global da registry nao e resetado entre testes

O FRegistry e um singleton de processo. Os cenarios usam classes-alvo distintas,
garantindo isolamento em uma execucao normal. Contudo, se qualquer cenario for
invocado mais de uma vez no mesmo processo (re-run de um teste isolado), as
afirmacoes de contagem falharao porque a segunda chamada a Register com uma
instancia nova acumula no registro global. Documentar como caveat no PR body.

### OBS-3 — RTTI call sob lock em GetAttributes

FContext.GetType(AClass).GetAttributes e executado enquanto o TCriticalSection
esta adquirido. Serializa leitores concorrentes. Aceito per RSK-8 do esp;
sem acao requerida neste ciclo.

### OBS-4 — TestDelphi_NativeAlone depende de RSK-4

A afirmacao Length(LResult) >= 1 depende de que o Delphi aceite [TMyAttr('nat')]
em TClasseNativa por descender transitivamente de TCustomAttribute. Isso e RSK-4
do esp — verificacao pendente com o autor no PR. Nenhuma acao requerida aqui.

### OBS-5 — lpi PathDelim backslash vs paths com barra normal

O arquivo lpi tem PathDelim Value="\" (heranca de edicao no Windows), mas os
valores dos caminhos de busca usam / como separador. Lazarus/FPC em Linux
interpreta corretamente ambos. Inofensivo.

---

## Itens pendentes (nao-bloqueantes, responsabilidade do autor/release node)

- [ ] Compilacao real no FPC 3.2.2 x86_64 e i386 (lazbuild) — R2 do PRD
- [ ] Compilacao e testes no Delphi — R2 do PRD + RSK-3, RSK-4
- [ ] PR body com as tres declaracoes mandatorias (CA-8 do esp)
- [ ] DCC.bat incluindo PTestAttributes — gap pos-entrega declarado
