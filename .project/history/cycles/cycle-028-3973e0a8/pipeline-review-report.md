---
type: review-report
kind: artifact
title: "Review Report #13 (iteracao 9) — TModernInvoker.Invoke dinamico cross-compiler"
description: "Implementacao Pascal correta em todos os D-13.x. AC-10 do ESP incompativel com a fabrica: diz 13/13 sem qualificar OS; fabrica entrega 10/14 (ENotImplemented RTL FPC 3.2.2 x86_64-linux). Nona rejeicao identica."
cycle: "028"
agent: quality
workflow: equipe-feature
node: review
resource: aefos://run/3973e0a8a9fb319c0e20e1154e93d8d3
generated:
  by: "equipe-feature@node:review"
  at: "2026-09-03T00:00:00Z"
tags: [review-report, rtti, invoker, fpc, delphi, dynamic-invoke, tvalue, issue-13, cycle-028, iteration-9]
---

# Review Report #13 — Iteracao 9

**Veredicto: REJECTED**
**Causa:** `spec`
**Node blamed:** `architect`

---

## Sumario

A implementacao Pascal entregue em `Source/ModernSyntax.Invoker.pas`,
`Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas`,
`Test FPC/EclbrSystem/UTestMS.Invoker.pas` e
`Test Delphi/EclbrSystem/UTestMS.Invoker.pas` esta **correta e conforme ao
ESP/ADR em todos os aspectos**.

O criterio de aceitacao AC-10 do [esp.md](pipeline-esp.md) exige
`--all passa 13/13` na fabrica FPC 3.2.2 x86_64. A fabrica entrega
**10/14** (4 `ENotImplemented` do limite RTL do FPC para SysV AMD64). O
AC nao qualifica target OS e conta errado (13 em vez de 14).

Esta e a **nona rejeicao consecutiva** com diagnostico identico.

---

## Checklist de criterios de aceitacao

| Criterio | Status | Observacao |
|----------|--------|------------|
| AC-1: assinatura unica sem `{$IFDEF}` em torno | ✅ | Declaracao unica, `{$IFDEF}` so no corpo |
| AC-2: `uses` acrescenta `Rtti` | ✅ | `Rtti` e `TypInfo` presentes na interface |
| AC-3: corpo dividido por `{$IFDEF FPC}` | ✅ | FPC: MethodAddress+Rtti.Invoke; Delphi: TRttiContext |
| AC-4: tres blocos superados removidos; XMLDoc por compilador | ✅ | Header reescrito; XMLDoc cobre alcance+fronteiras |
| AC-5: overload portavel `Invoke<TSignature>` intocado | ✅ | Diff zero nos generics |
| AC-6: Cases.pas com TDateAndTag, fixtures published, 8 cenarios | ✅ | GimmeStamp, GimmeAngle, StampNow, Stamped; 8 Case_InvokeDynamic_... |
| AC-7: casca FPC com 7 novos published (7→14) | ✅ | RaisesOnFPC registrado; OKOnDelphi ausente |
| AC-8: casca Delphi com 7 novos [Test] | ✅ | OKOnDelphi registrado; RaisesOnFPC ausente |
| AC-9: regressao zero nos 7 cenarios existentes | ✅ | 10/14 incluem os 7 antigos todos verdes |
| **AC-10: `PTestInvoker --all` passa N/N na fabrica** | ❌ | **10/14 (E:4): ENotImplemented RTL FPC 3.2.2 x86_64-linux** |
| AC-11: PR body com log das duas execucoes FPC | N/A | PR ainda nao criado |
| AC-12: PR body declara fabrica+autor | N/A | PR ainda nao criado |
| CA-5: zero `{$IFDEF FPC}` no Cases.pas | ✅ | grep = 0 confirmado |
| D-1: sem resourcestring novo | ✅ | Mensagens sao literais |
| D-13.9: guarda AInstance=nil mensagem reusada | ✅ | 'AInstance e nil' literal |
| D-13.10: guarda LAddress=nil mensagem instrutiva reusada | ✅ | Mensagem com {$M+}+published |

---

## Problema critico (bloqueante)

### AC-10 — Contagem errada e sem qualificacao de target OS

O ESP (secao 6, ultimo criterio de aceitacao) diz:

> `PTestInvoker.lpr` compila limpo no FPC 3.2.2 x86_64; `--all` passa `13/13`.

Dois defeitos no spec:

1. **Contagem errada:** a implementacao tem 14 testes (7 existentes + 7 novos),
   nao 13. O ADR (Consequencias) documenta corretamente "7 → 14"; a ESP ficou
   com o numero errado.

2. **Sem qualificacao de OS:** `x86_64-linux` (SysV AMD64 ABI) != `x86_64-win64`
   (Microsoft x64 ABI). `SystemInvoke` — o backend assembly de `Rtti.Invoke` livre
   (`rtti.pp:583`) — foi portado apenas para `x86_64-win64`. Em `x86_64-linux` o
   fallback e `raise Exception.Create(SErrInvokeNotImplemented)`.

**Resultado na fabrica Debian Linux x86_64:**
```
N:14  E:4  F:0  I:0
```
Os 4 erros sao os testes que efetivamente atingem `Rtti.Invoke`:
- `InvokeDynamic_ReturnsRecordIntegerAndString`
- `InvokeDynamic_ReturnsDouble`
- `InvokeDynamic_ReturnsManagedString`
- `InvokeDynamic_ProcedureVoid_SideEffect`

A excecao e emitida pela RTL do FPC antes de qualquer codigo da nossa unit.
O developer nao pode tornar esses 4 verdes sem violar D-13.2 (proibicao de
excecao "nao suportado" inventada) ou CA-5 (`{$IFDEF LINUX}` na casca compartilhada).

---

## Rework necessario (no architect — zero Pascal)

Tres edicoes redatorias nos artefatos do architect:

1. **ESP AC-10:** qualificar por target OS — "fabrica prova compilacao + guardas
   (10/14 com nota explicita no PR body); invocacao viva (`Rtti.Invoke` path)
   delegada ao autor em `x86_64-win64`, analogamente a D-13.12 que ja delega
   i386/Delphi ao autor." Remover o numero "13" e escrever "14" na contagem.

2. **ESP AC-10:** alinhar contagem de 13 para 14.

3. **ADR (Contexto + D-13.2):** adicionar erratum: "a medicao citada no corpo
   da issue #13 foi executada em `x86_64-win64` (MS x64 ABI); a fabrica e
   `x86_64-linux` (SysV AMD64 ABI), onde `SystemInvoke` nao foi portado na
   FPC 3.2.2. Os 4 testes de invocacao real ficam com o autor (Win64), analogo
   a D-13.12."

**O codigo do developer NAO deve ser alterado.**

---

## Observacoes nao-bloqueantes

- `.project/SKILL.md` foi atualizado corretamente com secao sobre `Rtti.Invoke`
  em FPC 3.2.2 x86_64-linux (agent-discovered 2026-09-03). Conforme.
- `project-evolution.md` atualizado com linha do ciclo 028. Conforme.
- OKF frontmatter de todos os artefatos do pipeline conforme.

---

## Nota de escalacao (CRITICA — NONA ITERACAO)

Esta e a **nona rejeicao consecutiva** de review com diagnostico identico.
O FLOW-FEEDBACK.md registra 17+ achados recomendando escalacao automatica.
O architect nao incorporou a correcao em nenhuma das 8 iteracoes anteriores.

O ciclo NAO pode convergir sem input externo. Opcoes para o humano:

- **Opcao A (recomendada):** architect qualifica AC-10 por OS e corrige contagem.
- **Opcao B:** humano mantem AC 14/14 como requisito absoluto (bloqueia merge ate FPC trunk/3.3.x).
- **Opcao C:** humano aceita 10/14 como verde e documenta delta no PR body.
