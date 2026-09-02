---
type: plan
kind: artifact
title: "PLAN — issue #51: else raise nos dois sites de Visibility do backend Delphi (slice unico)"
description: "Slice unico: resourcestring privada + else raise em MethodVisibility e PropertyVisibility + reescrita dos 2 comentarios + reescrita do XML-doc de TModernVisibility. Dois arquivos, commit unico. Verdict: fits."
status: draft
cycle: "022"
agent: architect
workflow: equipe-bug
node: architect
resource: aefos://run/de0826deb51365cb442a8acd3e0fd103
tags: [plan, modernrtti, rtti, issue-51, bug, delphi, visibility]
generated:
  by: "equipe-bug@node:architect"
  at: "2026-09-02T00:00:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — issue #51"
  - id: adr
    resource: "adr.md"
    title: "ADR D-51.1 — issue #51"
---

# PLAN — issue #51 (else raise nos dois sites de Visibility)

## Veredicto de escopo

**`fits` — slice unico.**

- **TESTE 1 (tamanho):** ~15 linhas de codigo alteradas em 2 arquivos.
  Nao esgota o budget de implementacao. Passa.
- **TESTE 2 (independencia):** Os 6 passos formam uma unidade logica
  atomica — o `else raise` referencia a resourcestring e o ADR D-51.1;
  a reescrita dos comentarios referencia o codigo novo; o XML-doc
  referencia ambos os backends. Nenhum subconjunto e entregavel sozinho
  de forma coerente. Nao ha dois slices independentes; splitting pagaria
  overhead duplo para uma unica correcao. Fails.

**Conclusao:** `fits`. Um commit, dois arquivos.

---

## Slice 1 — Fix: Delphi backend visibility — zero-warning, fail-loud

### Arquivos tocados

| Arquivo | O que muda |
|---------|-----------|
| `Source/ModernSyntax.RTTI.Delphi.pas` | resourcestring + else raise (x2) + reescrita de 2 comentarios |
| `Source/ModernSyntax.RTTI.pas` | reescrita do XML-doc de `TModernVisibility` |

### Passo 0 — resourcestring privada

Em `ModernSyntax.RTTI.Delphi.pas`, secao `implementation`, antes das
funcoes `MethodVisibility` / `PropertyVisibility` (ou no bloco
`resourcestring` existente mais proximo), adicionar:

```pascal
resourcestring
  SDelphiUnknownVisibility =
    'TMemberVisibility desconhecido (Ord=%d) em %s — ' +
    'TModernVisibility precisa de novo ramo (issue #51).';
```

Escopo: `implementation`. Nao promover para `interface` (D-51.3).

### Passo 1 — MethodVisibility: else raise (linhas 310-315)

No `case` de `MethodVisibility`, inserir antes do `end;` da linha 315:

```pascal
  else
    raise EModernRTTIError.CreateFmt(
      SDelphiUnknownVisibility,
      [Ord(TRttiMethod(AToken).Visibility), 'MethodVisibility']);
```

O enum usado no `Ord(...)` e `TRttiMethod(AToken).Visibility` — o
`TMemberVisibility` do RTL, nao o `TModernVisibility` da casca.

### Passo 2 — PropertyVisibility: else raise (linhas 325-330)

Identico ao passo 1, no `case` de `PropertyVisibility`:

```pascal
  else
    raise EModernRTTIError.CreateFmt(
      SDelphiUnknownVisibility,
      [Ord(TRttiProperty(AToken).Visibility), 'PropertyVisibility']);
```

### Passo 3 — Comentario de MethodVisibility: reescrita (linhas 299-304)

Substituir o bloco que comeca em "D-42.2 do ADR issue #42: `case`
explicito..." pelo texto que enuncia o framing correto:

- Os dois candidatos (cast + else, raise + else) matam W1035 igualmente
  nos 4 alvos Delphi.
- O criterio de desempate e fail-loud vs. errado-em-silencio (medido:
  lixo 204/16/252/16 por bitness — indeterminado e nao reprodutivel).
- Referencia ADR: `D-51.1 do ADR issue #51` (substituindo `D-42.2 do
  ADR issue #42`).

Preservar o paragrafo sobre qualificacao dos labels (`TMemberVisibility.`
e `TModernVisibility.`), que continua valido.

### Passo 4 — Comentario de PropertyVisibility: reescrita (linhas 320-324)

Mesma reescrita do passo 3, mesma troca `D-42.2` -> `D-51.1`.

**Preservar obrigatoriamente** a nota sobre `AOwner`: "simetria formal
com `MethodVisibility(AOwner, AToken)` seria ruido (AOwner ficaria
morto). D-51.1 do ADR." — ela justifica por que a mensagem usa `%s`
com o nome da funcao, nao com o owner.

### Passo 5 — XML-doc de TModernVisibility (RTTI.pas linhas 71-81)

Em `Source/ModernSyntax.RTTI.pas`, reescrever a frase:

**Antes:**
> "Se `TMemberVisibility` de algum compilador vier a incluir valor
> adicional (ex.: `mvAutomated` no Delphi), o `case` explicito nos
> backends (D-42.2) acusa erro no primeiro build — nunca
> `TModernVisibility(Ord(...))`, que silenciaria em runtime."

**Depois:**
> "Se `TMemberVisibility` de algum compilador vier a incluir valor
> adicional (ex.: `mvAutomated` no Delphi), o backend Delphi levanta
> `EModernRTTIError` no primeiro chamador (D-51.1 do ADR issue #51);
> o backend FPC valida exaustividade em compile-time — o `case` de 4
> ramos sem `else` e correto la (4 valores em `rtti.pp:308`)."

### Criterio de conclusao do slice

- `Source/ModernSyntax.RTTI.Delphi.pas` compila nos 4 alvos Delphi
  sem W1035 (verificavel pelo mantenedor).
- `Source/ModernSyntax.RTTI.pas` compila no FPC 3.2.2 x86_64 da fabrica.
- Os 2 cenarios de Visibility em `UScenarios.RTTI.pas` continuam verdes
  (FPC x86_64 na fabrica).
- PR declara o que foi e o que nao foi provado na fabrica.

---

## O que NAO entra neste commit

- `Source/ModernSyntax.RTTI.FPC.pas` — intocado.
- `Test Shared/EclbrSystem/UScenarios.RTTI.pas` — intocado.
- `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` — intocado.
- `Test FPC/EclbrSystem/UTestMS.RTTI.pas` — intocado.
- Novo cenario para o ramo `else raise` (inalcancavel por dado real).
- `.project/project-evolution.md` (D-42.2 preservado intocado).
