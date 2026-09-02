---
type: review-report
kind: artifact
title: "REVIEW-REPORT — issue #56: Attributes nil-handle (ciclo 021)"
description: "Revisao de qualidade do ciclo 021: guarda de nil em PropAttributes, uniformizacao dos cinco blocos, sexto bloco Attributes — APROVADO com uma observacao nao-bloqueante."
cycle: "021"
agent: quality
workflow: equipe-bug
node: review
resource: aefos://run/09743779c7c9860b5fa380f6979d94ca
tags: [review, issue-56, nil-handle, modernrtti, rtti, fpc, cycle-021]
generated:
  by: "equipe-bug@node:review"
  at: "2026-09-02T17:10:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — issue #56"
  - id: adr
    resource: "adr.md"
    title: "ADR — issue #56"
  - id: implement-report
    resource: "implement-report.md"
    title: "IMPLEMENT-REPORT — issue #56"
  - id: skill
    resource: "/SKILL.md"
    title: "SKILL — toolchain e quality commands"
---

# REVIEW-REPORT — Issue #56 (`TModernRTTIType.Attributes` — nil-handle)

## 1. Resumo

O ciclo 021 entregou exatamente o que o ESP §2 e o ADR prescreveram:
guarda de nil como primeira instrucao de `PropAttributes`, uniformizacao
dos cinco blocos de `Scenario_NilHandle_AllMembers_Raises` (Pos → igualdade
estrita), e sexto bloco (`Attributes`) em ordem cronologica. O build FPC
3.2.2 x86_64 passou com 42 testes e 0 falhas. A unica divergencia do
ESP foi a promocao de `SModernRTTINilHandle` para o `interface` — decisao
tecnicamente necessaria, coerente com o ADR, e devidamente documentada
pelo developer no [FLOW-FEEDBACK](FLOW-FEEDBACK.md).

**Veredicto: APROVADO.**

---

## 2. Checklist de aceitacao (ESP §4)

| Criterio | Status | Evidencia |
|----------|--------|-----------|
| `Attributes` sobre handle nil levanta `EModernRTTIError` com mensagem `Format(SModernRTTINilHandle, ['Attributes'])` | OK | Guarda inserida como primeira instrucao de `PropAttributes`; bloco de teste com igualdade estrita passa (42/0) |
| `Attributes` sobre handle valido nao-classe continua devolvendo vazio | OK | Ramo `else Result := nil` intacto no diff; baselines verdes |
| `Scenario_NilHandle_AllMembers_Raises` tem sexto bloco com `on E: EModernRTTIError` e igualdade estrita | OK | Diff `UScenarios.RTTI.pas`: +22 linhas apos o quinto bloco |
| Cinco blocos existentes usam `<>` + `'Mensagem de X incorreta'` | OK | Diff: 5 x 2 linhas substituidas, nenhum `Pos` remanescente |
| Build FPC 3.2.2 x86_64 verde na fabrica | OK | 42 rodados / 0 erros / 0 falhas (implement-report §4) |
| PR declara fronteira de cobertura (FPC x86_64 unico) | PENDENTE | PR nao aberto ainda; template correto no implement-report §5; responsabilidade do committer |

---

## 3. Verificacao de convencoes

| Convencao | Status | Observacao |
|-----------|--------|------------|
| CA-5: Zero `{$IFDEF FPC}` em `UScenarios.RTTI.pas` | OK | Diff confirmado: nenhum bloco condicional de compilador |
| D-7: Cascas FPC/Delphi nao alteradas | OK | Nenhuma mudanca em `Test FPC/` ou `Test Delphi/` |
| D-56.1: Guarda antes de `// Issue #27:` | OK | Diff confirma: `if FType = nil then raise` e a primeira instrucao |
| D-56.3: Mensagens de `Fail` reescritas (`'Mensagem de X incorreta: "%s"'`) | OK | Todos os cinco blocos convertidos |
| D-56.4: Sexto bloco em ordem cronologica (append apos o quinto) | OK | Inserido antes do `end;` do procedimento |
| D-56.5: Commit unico | PENDENTE | Pendente ao committer (unico diff, sem commits intermediarios) |
| B-56.6: Nenhuma API publica nova / nenhuma `resourcestring` nova | NOTA | Ver observacao nao-bloqueante 5.1 |
| Prefixo `L` para variaveis locais (`LRaised`, `LMsg`) | OK | Reutiliza variaveis ja declaradas no escopo |
| Nenhuma declaracao nova de variavel | OK | Confirmado pelo diff |

---

## 4. Criticas bloqueantes

**Nenhuma.**

---

## 5. Observacoes nao-bloqueantes

### 5.1 — Promocao de `SModernRTTINilHandle` ao `interface`

**O que aconteceu:** a `resourcestring SModernRTTINilHandle` estava em
`implementation` (privada). O ADR pede `Format(SModernRTTINilHandle, ...)` no
cenario compartilhado, o que exige que o simbolo seja visivel ao consumidor.
O developer promoveu a string para o `interface` com XMLDoc explicando a
exposicao. Seis erros de `Identifier not found` no primeiro build confirmam
que nao havia alternativa viavel sem violar o ADR.

**Por que nao bloqueia:** a decisao e coerente com o ADR (D-56.2/D-56.3) —
sem a promocao o padrao de igualdade estrita especificado nao compila. A
mudanca de superficie foi a minima necessaria (uma string, nenhuma API de
codigo). O FLOW-FEEDBACK foi preenchido; o architect pode incorporar a
checklist sugerida nos proximos ciclos.

**Documentacao:** [implement-report §3.1](pipeline-implement-report.md) e
[FLOW-FEEDBACK](FLOW-FEEDBACK.md).

### 5.2 — Texto do `project-evolution.md` ligeiramente impreciso

O texto do ciclo 021 em `project-evolution.md` diz: "Nenhuma
resourcestring nova — SModernRTTINilHandle ja existe em linha 892."
Isso e verdade quanto a criacao, mas omite a promocao ao interface;
leitores futuros podem nao entender por que a string agora e publica.
Nao e bloqueante; o committer pode complementar o texto no PR.

---

## 6. Evidencia de build

- Comando canonico em [SKILL.md](../../../SKILL.md) (secao "Toolchain & quality commands")
- Resultado citado em [implement-report §4](pipeline-implement-report.md): 42 testes, 0 erros, 0 falhas
- `TestNilHandle_AllMembers_Raises` presente e verde
- Baselines `TestAttributes_ForIn_IteratesAttributes` e `TestRecordType_NameAndSize` continuam verdes
- Nao-regressao confirmada: nenhum teste existente quebrou

---

## 7. Fronteira da revisao

Esta revisao cobre apenas o diff deste ciclo (`git diff main...HEAD`) e os
arquivos nao rastreados criados em ciclo 021. A cobertura i386/Delphi nao
foi exercida na fabrica — o committer declara isso no PR per D-56.6 e
[implement-report §5](pipeline-implement-report.md).
