---
type: task
kind: artifact
title: "TASK-022 — Fix: else raise nos dois sites de Visibility do backend Delphi (issue #51)"
description: "resourcestring privada SDelphiUnknownVisibility + else raise em MethodVisibility e PropertyVisibility + reescrita de 2 comentarios + reescrita de 1 XML-doc. Dois arquivos, commit unico, build FPC x86_64."
cycle: "022"
agent: planner
workflow: equipe-bug
node: task
resource: aefos://run/de0826deb51365cb442a8acd3e0fd103
status: draft
tags: [task, modernrtti, issue-51, bug, delphi, visibility, cycle-022]
generated:
  by: "equipe-bug@node:task"
  at: "2026-09-02T00:00:00Z"
sources:
  - id: task-input
    resource: "task-input.md"
    title: "TASK-INPUT — issue #51"
  - id: gh-51
    resource: "https://github.com/isaquepinheiro/ModernSyntax/issues/51"
    title: "Issue #51 — else raise nos dois sites de Visibility do backend Delphi"
---

# TASK-022 — Issue #51: else raise nos dois sites de Visibility do backend Delphi

## Tracking

- **Modo:** MAESTRO MODE
- **Issue original:** [#51](https://github.com/isaquepinheiro/ModernSyntax/issues/51)
  (demanda criada pelo maestro — `aefos:running`)
- **Epic:** nenhum Epic preexistente identificado; nenhum criado (MAESTRO MODE)
- **Board:** issue #51 ja carrega `aefos:running`

## Demanda em uma linha

O `case` de 4 ramos sem `else` em `MethodVisibility` e `PropertyVisibility` no backend
Delphi nao protege contra valores desconhecidos de `TMemberVisibility`: o compilador emite
W1035 e devolve lixo em runtime. A premissa do D-42.2 era falsa. Este ciclo adiciona
`else raise EModernRTTIError` nos dois sites, declara uma `resourcestring` privada para a
mensagem, reescreve os dois comentarios e atualiza o XML-doc de `TModernVisibility`.

## Escopo

Dois arquivos, commit unico. Nenhuma alteracao em FPC, testes ou demais fontes.

| Arquivo | Linhas de referencia | Mudancas |
|---------|----------------------|----------|
| `Source/ModernSyntax.RTTI.Delphi.pas` | 299-330 + impl | resourcestring (passo 0) + else raise x2 (passos 1-2) + reescrita comentarios x2 (passos 3-4) |
| `Source/ModernSyntax.RTTI.pas` | 71-81 | reescrita XML-doc TModernVisibility (passo 5) |

**Proibido sem nova issue:** `ModernSyntax.RTTI.FPC.pas`, arquivos de teste,
`.project/project-evolution.md`.

## Cinco passos (commit unico)

### Passo 0 — resourcestring SDelphiUnknownVisibility

Declarar na secao `implementation` de `ModernSyntax.RTTI.Delphi.pas` (nao na `interface`):

```pascal
resourcestring
  SDelphiUnknownVisibility =
    'TMemberVisibility desconhecido (Ord=%d) em %s — TModernVisibility ' +
    'precisa de novo ramo (issue #51).';
```

### Passo 1 — else raise em MethodVisibility

Adicionar ramo `else` ao `case` de `MethodVisibility`:

```pascal
else
  raise EModernRTTIError.CreateFmt(SDelphiUnknownVisibility,
    [Ord(TRttiMethod(AToken).Visibility), 'MethodVisibility']);
```

O `Ord(...)` usa `TRttiMethod(AToken).Visibility` (o `TMemberVisibility` do RTL Delphi),
nao `TModernVisibility`.

### Passo 2 — else raise em PropertyVisibility

Identico, com `TRttiProperty(AToken).Visibility` e `'PropertyVisibility'`.

### Passo 3 — Reescrita do comentario de MethodVisibility

Remover a afirmacao de que o compilador Delphi detecta `case` nao-exaustivo em compile-time.
Referenciar `D-51.1 do ADR issue #51` (nao mais `D-42.2`). Preservar o paragrafo de
qualificacao dos labels.

### Passo 4 — Reescrita do comentario de PropertyVisibility

Mesma reescrita. Preservar a nota sobre `AOwner` ("seria ruido — AOwner ficaria morto")
que justifica por que a mensagem usa o nome da funcao, nao o owner.

### Passo 5 — Reescrita do XML-doc de TModernVisibility

`Source/ModernSyntax.RTTI.pas` linhas 71-81: substituir a frase que dizia "o `case`
explicito nos backends (D-42.2) acusa erro no primeiro build" por "o backend Delphi
levanta `EModernRTTIError` no primeiro chamador (D-51.1 do ADR issue #51); o backend
FPC valida exaustividade em compile-time".

## Criterios de aceite

- [ ] W1035 zerado nos 4 alvos Delphi (Delphi 23.0/37.0 x Win32/Win64).
- [ ] else raise presente em MethodVisibility com `TRttiMethod(AToken).Visibility`.
- [ ] else raise presente em PropertyVisibility com `TRttiProperty(AToken).Visibility`.
- [ ] SDelphiUnknownVisibility declarada na secao implementation (nao interface).
- [ ] Comentario de MethodVisibility reescrito; referencia `D-51.1`, sem afirmacao de compile-time.
- [ ] Comentario de PropertyVisibility reescrito; nota sobre AOwner preservada.
- [ ] XML-doc de TModernVisibility reescrito conforme passo 5.
- [ ] Backend FPC (`ModernSyntax.RTTI.FPC.pas`) intocado.
- [ ] Cenarios de Visibility (UScenarios.RTTI.pas:1070-1110) verdes no FPC x86_64.
- [ ] PR declara fronteira: FPC x86_64 (fabrica); i386 + Delphi (mantenedor).
- [ ] PR fecha `Closes #51`.

## Notas para o implementador

1. **Ordem:** executar os 5 passos de `RTTI.Delphi.pas` antes de tocar `RTTI.pas`.
2. **Tipo correto no Ord(...):** confirmar que e `TMemberVisibility` do RTL (resultado
   de `.Visibility` na propriedade do `TRtti*`), nao `TModernVisibility` da casca.
3. **Ramo inalcancavel:** o `else raise` nao e atingivel com os 4 valores atuais de
   `TMemberVisibility` em `System.TypInfo.pas:232`. Nenhum teste novo e necessario.
4. **Build FPC:** compilar `Source/ModernSyntax.RTTI.pas` isoladamente na fabrica e rodar
   `PTestRTTI.lpr` (FPCUnit) para confirmar os cenarios de Visibility. Seguir a receita
   de SKILL.md (rm -rf do diretorio de saida antes de compilar).
