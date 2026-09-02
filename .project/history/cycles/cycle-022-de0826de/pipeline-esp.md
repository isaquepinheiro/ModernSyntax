---
type: spec
kind: artifact
title: "ESP — case sem else no backend Delphi devolve lixo em runtime (issue #51)"
description: "Substituir o case de 4 ramos sem else nos dois sites de Visibility do backend Delphi por else raise EModernRTTIError, zerando os 2 W1035 e entregando fail-loud real."
status: draft
cycle: "022"
agent: architect
workflow: equipe-bug
node: architect
resource: aefos://run/de0826deb51365cb442a8acd3e0fd103
tags: [modernrtti, rtti, spec, issue-51, bug, delphi, visibility, emodernrttierror]
generated:
  by: "equipe-bug@node:architect"
  at: "2026-09-02T00:00:00Z"
sources:
  - id: issue-51
    resource: "https://github.com/isaquepinheiro/ModernSyntax/issues/51"
    title: "Issue #51 — O case de 4 ramos sem else no backend Delphi nao protege"
  - id: investigation
    title: "Relatorio de investigacao — Issue #51 (run 2e4913d83ea2e1f06b3d8e8589bcbc4f) — PRESENT"
  - id: adr
    resource: "adr.md"
    title: "ADR D-51.1 — issue #51"
  - id: plan
    resource: "plan.md"
    title: "PLAN — issue #51"
  - id: task-input
    resource: "task-input.md"
    title: "TASK-INPUT — issue #51"
---

# ESP — issue #51 (case sem else no backend Delphi)

## 1. Objetivo

Corrigir a premissa falsa de D-42.2 no backend Delphi: o `case` de 4 ramos
sem `else` em `MethodVisibility` e `PropertyVisibility`
(`Source/ModernSyntax.RTTI.Delphi.pas`) **não** provoca erro de compilação
quando `TMemberVisibility` ganha um valor adicional — gera W1035 e devolve
lixo indeterminado em runtime (ordinal 204/16/252/16 nos 4 alvos medidos,
variando por bitness e por compilador).

O objetivo é:

1. Eliminar os 2 W1035 permanentes que impedem um build limpo nos 4 alvos
   Delphi (23.0/37.0 × Win32/Win64).
2. Substituir o comportamento de "lixo silencioso" por `EModernRTTIError`
   nomeada — o único caminho que entrega o fail-loud que D-42.2 prometia.
3. Corrigir o comentário embutido e o XML-doc público de `TModernVisibility`
   que ainda afirmam o comportamento medido como falso.

| Condição | Comportamento atual | Comportamento exigido |
|----------|--------------------|-----------------------|
| Visibility = valor conhecido (4 ramos) | `TModernVisibility` correto | **preservado** |
| Visibility = valor desconhecido (futuro) | lixo (64/204/16/252) | `EModernRTTIError` nomeando ordinal + função |
| Build nos 4 alvos Delphi | 2 × W1035 | zero warning |

---

## 2. Escopo

### 2.1 `Source/ModernSyntax.RTTI.Delphi.pas`

**Passo 0 — resourcestring privada** (seção `implementation`):

```pascal
resourcestring
  SDelphiUnknownVisibility =
    'TMemberVisibility desconhecido (Ord=%d) em %s — ' +
    'TModernVisibility precisa de novo ramo (issue #51).';
```

Segue o padrão de `SFPCNoVisibility` / `SFPCNoReturnType`: escopo
`implementation`, nunca promovida à `interface`.

**Passo 1 — `MethodVisibility` (linhas 310-315)**:

Inserir antes do `end;`:

```pascal
  else
    raise EModernRTTIError.CreateFmt(
      SDelphiUnknownVisibility,
      [Ord(TRttiMethod(AToken).Visibility), 'MethodVisibility']);
```

**Passo 2 — `PropertyVisibility` (linhas 325-330)**:

Inserir antes do `end;`:

```pascal
  else
    raise EModernRTTIError.CreateFmt(
      SDelphiUnknownVisibility,
      [Ord(TRttiProperty(AToken).Visibility), 'PropertyVisibility']);
```

**Passo 3 — comentário de `MethodVisibility` (linhas 299-304)**:

Reescrever removendo a afirmação falsa ("o compilador acusa erro no
primeiro build"). Novo framing: ambos os candidatos (cast + else, raise
+ else) matam W1035 igualmente nos 4 alvos; o critério de desempate é
fail-loud vs. errado-em-silêncio. Referência ADR muda de `D-42.2` para
`D-51.1`.

**Passo 4 — comentário de `PropertyVisibility` (linhas 320-324)**:

Mesma reescrita, mesmo framing, mesma troca `D-42.2` → `D-51.1`.
Preservar a nota sobre `AOwner` ("seria ruído — AOwner ficaria morto")
— continua válida e justifica por que a mensagem leva `%s` com o nome
da função, não com o owner.

### 2.2 `Source/ModernSyntax.RTTI.pas`

**Passo 5 — XML-doc de `TModernVisibility` (linhas 71-81)**:

Reescrever a frase que hoje diz "o `case` explícito nos backends
(D-42.2) acusa erro no primeiro build". Nova redação:

> "Se `TMemberVisibility` de algum compilador vier a incluir valor
> adicional, o backend Delphi levanta `EModernRTTIError` no primeiro
> chamador (D-51.1); o backend FPC valida exaustividade em compile-time
> (case de 4 ramos, sem else necessário)."

### 2.3 Fora de escopo (out-of-scope, explícito)

- `Source/ModernSyntax.RTTI.FPC.pas` — **não muda**. O `case` de 4
  ramos FPC é correto: o compilador confirma exaustividade
  (`TMemberVisibility` do FPC tem 4 valores em `rtti.pp:308`) e não
  reclama. A decisão original é válida lá.
- Testes (`Test Shared/`, `Test Delphi/`, `Test FPC/`) — **não mudam**.
  Os 2 cenários de Visibility (`UScenarios.RTTI.pas:1070-1110`)
  exercitam apenas o ramo `mvPublished`, continuam verdes.
- Novo cenário para o ramo `else raise` — **fora de escopo**. O ramo é
  inalcançável por dado real enquanto `TMemberVisibility` do Delphi
  tiver 4 valores (`System.TypInfo.pas:232`). Documentado como tal.
- `TModernVisibility` público (4 valores) — **não muda**. Contrato
  público preservado.
- Promoção de `SDelphiUnknownVisibility` para a `interface` — **fora
  de escopo**. Sem teste externo que justifique ampliar a superfície
  pública (contraste com PR #58).

---

## 3. Regras de negócio

- **B-51.1** — Quando `TRttiMethod(AToken).Visibility` não corresponde
  a nenhum dos 4 ramos conhecidos, `MethodVisibility` levanta
  `EModernRTTIError.CreateFmt(SDelphiUnknownVisibility,
  [Ord(Visibility), 'MethodVisibility'])`.
- **B-51.2** — Idem para `PropertyVisibility`, com `%s =
  'PropertyVisibility'`.
- **B-51.3** — O ramo `else raise` é inalcançável com o RTL atual
  (4 valores em `System.TypInfo.pas:232`). Documentado no comentário
  como "inalcançável por dado real, não testado".
- **B-51.4** — `SDelphiUnknownVisibility` permanece na seção
  `implementation`. Padrão: `SFPCNoVisibility` / `SFPCNoReturnType`.
  Não promover sem justificativa de teste externo.
- **B-51.5** — Os comentários embutidos não afirmam que o compilador
  Delphi detecta `case` não-exaustivo em tempo de compilação. Afirmam o
  que foi medido: W1035 em runtime; desempate por semântica, não por
  warning.
- **B-51.6** — Backend FPC não muda. A decisão de D-42.2 sobre o FPC
  está correta e medida.

---

## 4. Critérios de aceitação

- [ ] Os 4 alvos Delphi (23.0/37.0 × Win32/Win64) compilam
      `ModernSyntax.RTTI.Delphi.pas` com **zero** warning W1035 (e zero
      outros warnings novos).
- [ ] O comentário em `RTTI.Delphi.pas` não afirma mais que o
      compilador Delphi acusa erro em `case` não-exaustivo.
- [ ] `MethodVisibility` e `PropertyVisibility` levantam
      `EModernRTTIError` quando recebem um valor de
      `TMemberVisibility` fora dos 4 conhecidos (verificável por teste
      manual com enum estendido ou por leitura do código).
- [ ] O XML-doc de `TModernVisibility` em `ModernSyntax.RTTI.pas`
      enuncia corretamente o comportamento: Delphi levanta, FPC
      valida em compile-time.
- [ ] Backend FPC compila e roda sem alteração (zero-warning como
      antes).
- [ ] Os cenários de Visibility existentes (`UScenarios.RTTI.pas`)
      continuam verdes nos dois compiladores.
- [ ] PR declara literalmente: "ciclo rodou FPC x86_64 no container.
      i386 e os 4 alvos Delphi ficam com o mantenedor antes do merge."

---

## 5. Restrições (constraints)

- **CA-5** — Zero `{$IFDEF}` em `UScenarios.RTTI.pas` — não afetado
  por esta mudança.
- **D-42.1** — `TModernVisibility` permanece o tipo público; `TMemberVisibility`
  não vaza para a interface. Preservado.
- **FPC intocado** — decisão explícita da issue, confirmada pelo estudo.
- **resourcestring privada** — padrão do módulo; promoção só quando
  teste externo justifica (precedente PR #58).
- Fabrica: FPC 3.2.2 x86_64 disponível; Delphi fica com o mantenedor.

---

## 6. Riscos

- **R-51.1** — Reescrita do comentário apaga acidentalmente a nota
  sobre `AOwner` em `PropertyVisibility`. **Mitigação:** B-51.4 e
  plan §2 exigem preservar essa nota; o reviewer verifica no diff.
- **R-51.2** — Enum usado no `Ord(...)` do `else raise` é o
  `TRttiMethod.Visibility` (correto), não o `TModernVisibility`. Erro
  aqui produziria ordinal errado na mensagem. **Mitigação:** plan e
  task-input especificam `Ord(TRttiMethod(AToken).Visibility)` e
  `Ord(TRttiProperty(AToken).Visibility)` explicitamente.
- **R-51.3** — `SDelphiUnknownVisibility` promovida para `interface`
  por analogia equivocada com PR #58. **Mitigação:** B-51.4 e ADR
  registram explicitamente que a promoção não tem justificativa aqui.
