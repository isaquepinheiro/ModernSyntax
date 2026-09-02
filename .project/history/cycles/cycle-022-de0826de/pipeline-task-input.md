---
type: task-input
kind: artifact
title: "TASK-INPUT — issue #51: else raise nos dois sites de Visibility do backend Delphi"
description: "Handoff operacional para o implementador: resourcestring privada + else raise em MethodVisibility e PropertyVisibility + reescrita de 2 comentarios + reescrita de 1 XML-doc. Dois arquivos, commit unico, build FPC x86_64."
status: draft
cycle: "022"
agent: architect
workflow: equipe-bug
node: architect
resource: aefos://run/de0826deb51365cb442a8acd3e0fd103
tags: [task-input, modernrtti, rtti, issue-51, bug, delphi, visibility]
generated:
  by: "equipe-bug@node:architect"
  at: "2026-09-02T00:00:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — issue #51"
  - id: plan
    resource: "plan.md"
    title: "PLAN — issue #51"
  - id: adr
    resource: "adr.md"
    title: "ADR D-51.1 — issue #51"
---

# TASK-INPUT — issue #51

## Titulo da issue

**Fix: Delphi backend visibility — W1035 + lixo em runtime no case sem else**

## Tipo e labels

- **Tipo:** bug
- **Labels:** `bug`, `delphi`, `rtti`, `aefos:running`
- **Fecha:** `Closes #51`

## Escopo da implementacao

Dois arquivos em um commit unico:

1. `Source/ModernSyntax.RTTI.Delphi.pas` — 5 mudancas localizadas
2. `Source/ModernSyntax.RTTI.pas` — 1 reescrita de XML-doc

**Nao tocam** (proibido sem nova issue): `ModernSyntax.RTTI.FPC.pas`,
qualquer arquivo de teste, `.project/project-evolution.md`.

## Checklist de acceptance

- [ ] **W1035 zerado nos 4 alvos Delphi.**
      Os 4 alvos (Delphi 23.0/37.0 × Win32/Win64) compilam
      `ModernSyntax.RTTI.Delphi.pas` com **zero** warnings. Verificar
      log de compilacao antes de abrir o PR.

- [ ] **else raise em MethodVisibility.**
      `ModernSyntax.RTTI.Delphi.pas`: o `case` de `MethodVisibility`
      tem ramo `else raise EModernRTTIError.CreateFmt(SDelphiUnknownVisibility,
      [Ord(TRttiMethod(AToken).Visibility), 'MethodVisibility'])` antes do
      `end;`. O `Ord(...)` usa `TRttiMethod(AToken).Visibility` (o
      `TMemberVisibility` do RTL), nao `TModernVisibility`.

- [ ] **else raise em PropertyVisibility.**
      Identico, com `TRttiProperty(AToken).Visibility` e `'PropertyVisibility'`.

- [ ] **resourcestring SDelphiUnknownVisibility na implementation.**
      Declarada na secao `implementation` de `ModernSyntax.RTTI.Delphi.pas`,
      **nao** na `interface`. Formato:
      `'TMemberVisibility desconhecido (Ord=%d) em %s — TModernVisibility
      precisa de novo ramo (issue #51).'`

- [ ] **Comentario de MethodVisibility reescrito.**
      Nenhuma afirmacao de que o compilador Delphi detecta `case`
      nao-exaustivo em compile-time. Referencia a `D-51.1 do ADR issue #51`
      (nao mais `D-42.2`). Paragrafo de qualificacao dos labels preservado.

- [ ] **Comentario de PropertyVisibility reescrito.**
      Mesma reescrita. Nota sobre `AOwner` ("seria ruido — AOwner ficaria
      morto") **preservada** — ela justifica por que a mensagem usa o nome
      da funcao, nao o owner.

- [ ] **XML-doc de TModernVisibility reescrito.**
      `Source/ModernSyntax.RTTI.pas` linhas 71-81: frase que dizia "o `case`
      explicito nos backends (D-42.2) acusa erro no primeiro build"
      substituida por "o backend Delphi levanta `EModernRTTIError` no
      primeiro chamador (D-51.1 do ADR issue #51); o backend FPC valida
      exaustividade em compile-time".

- [ ] **Backend FPC intocado.**
      `Source/ModernSyntax.RTTI.FPC.pas` sem nenhuma alteracao.

- [ ] **Cenarios de Visibility verdes no FPC x86_64.**
      `UScenarios.RTTI.pas:1070-1110` (os 2 cenarios de Visibility)
      continuam verdes. Build FPC 3.2.2 x86_64 na fabrica, output zero
      falhas.

- [ ] **PR declara o que foi e o que nao foi provado:**
      > "ciclo rodou FPC x86_64 no container. i386 e os 4 alvos Delphi
      > nao foram executados nesta fabrica — ficam com o mantenedor antes
      > do merge."

## Arquivos provavelmente impactados

| Arquivo | Linhas de referencia | Mudancas |
|---------|----------------------|----------|
| `Source/ModernSyntax.RTTI.Delphi.pas` | 299-330 + impl | resourcestring (passo 0) + else raise x2 (passos 1-2) + reescrita comentarios x2 (passos 3-4) |
| `Source/ModernSyntax.RTTI.pas` | 71-81 | reescrita XML-doc TModernVisibility (passo 5) |

## Notas para o implementador

1. **Ordem dos passos:** fazer os 5 passos de `RTTI.Delphi.pas` antes
   de tocar `RTTI.pas`. Se a build FPC falhar por outro motivo, o diff
   ainda e revisavel.

2. **Enum no Ord(...):** confirmar que e o `TMemberVisibility` do RTL
   Delphi (resultado de `.Visibility` na propriedade do `TRtti*`), nao
   o `TModernVisibility` da casca. O tipo correto torna a mensagem util
   (informa qual ordinal o RTL passou).

3. **Ramo inalcancavel:** o `else raise` nao e atingivel com os
   `TMemberVisibility` atuais (4 valores em `System.TypInfo.pas:232`).
   Nenhum teste novo e necessario; o comentario documentara isso.

4. **Build FPC:** compilar `Source/ModernSyntax.RTTI.pas` isoladamente
   na fabrica e rodar `PTestRTTI.lpr` (FPCUnit) para confirmar os
   cenarios de Visibility. Seguir a receita de SKILL.md (rm -rf do
   diretorio de saida antes de compilar).
