---
type: plan
kind: artifact
title: "PLAN #66 — 2 edicoes em 1 arquivo, slice unico"
description: "Slice unico: reescrita do remarks publico + alinhamento de citacao ADR. Verdict: fits."
cycle: "026"
agent: architect
workflow: equipe-bug
node: architect
resource: aefos://run/a2c4f4bd7a43e634bf43104b21a56468
generated:
  by: "equipe-bug@node:architect"
  at: "2026-09-02T00:00:00Z"
tags: [plan, rtti, xmldoc, documentation, bug, issue-66, modernrtti, cycle-026]
---

# PLAN — Issue #66: Corrigir `<remarks>` falso de `TModernRTTIProperty.Visibility`

**Verdict: `fits`** — 2 edições em 1 arquivo, ambas em bloco `///`. Um commit,
um PR. Zero linhas executáveis mudam.

- **Teste de tamanho:** 2 substituições textuais em comentários. Custo real < $2.
  Não exaure o orçamento de implementação.
- **Teste de independência:** as duas edições tocam a mesma unidade conceitual
  (descrição de Visibility e sua linhagem de ADR). Reverter `:161-167` sem reverter
  `:987-990` deixaria a citação de ADR incoerente; não são independentes.

---

## Slice 1 — 2 edições, um commit

### Pré-condição

O PR #65 deve estar mergeado em `main` antes de abrir o PR desta issue. As
duas edições pressupõem o estado pós-#65 (`else raise` em `RTTI.FPC.pas:505-507`
e `RTTI.pas:79-81` descrevendo ambos os backends como fail-loud). Se o #65 não
estiver mergeado, este PR conflita com ele.

### Ordem de execução

**1. `Source/ModernSyntax.RTTI.pas:161-167` — reescrita do `<remarks>` público**

Sai: o bloco que afirma "aqui NAO ha raise no FPC" e cita apenas D-42.2.

Entra: bloco que (a) descreve a assimetria estruturalmente — `TModernRTTIMethod.Visibility`
levanta SEMPRE no FPC (o dado não existe no `vmtMethodTable`); `TModernRTTIProperty.Visibility`
levanta APENAS no ramo `else`, inalcançável com o `TMemberVisibility` atual
(4 valores, `rtti.pp:308`); (b) cita `D-42.2/D-51.1/D-60.1 do ADR issues #42/#51/#60`;
(c) não menciona `SFPCNoVisibility` nem qualquer símbolo interno do backend.

Exemplo de prosa aprovada na investigação:

```
/// <remarks>
///   Assimetria deliberada com <c>TModernRTTIMethod.Visibility</c> (que no
///   FPC levanta SEMPRE — o dado não existe no <c>vmtMethodTable</c>): aqui
///   o levantamento ocorre APENAS no ramo <c>else</c> do <c>case</c>,
///   inalcançável com o <c>TMemberVisibility</c> atual (4 valores,
///   <c>rtti.pp:308</c>). Para todo dado real devolve o valor mapeado.
///   (D-42.2/D-51.1/D-60.1 do ADR issues #42/#51/#60)
/// </remarks>
```

O texto exato pode variar em pontuação; o que é mandatório:
- Não afirmar ausência de raise no FPC.
- Distinguir "Method levanta SEMPRE" de "Property levanta APENAS no else".
- Ancorar os 4 valores em `rtti.pp:308`.
- Citar `D-42.2/D-51.1/D-60.1 do ADR issues #42/#51/#60`.
- Não citar `SFPCNoVisibility`.

**2. `Source/ModernSyntax.RTTI.pas:987-990` — atualização da citação de ADR**

Substituição cirúrgica dentro do comentário de implementação existente:

```
sai:  (D-42.2 do ADR issue #42)
entra: (D-42.2/D-51.1/D-60.1 do ADR issues #42/#51/#60)
```

O corpo da frase que descreve o comportamento por dado real não muda.

### Varredura de aceitação (antes de abrir o PR)

```bash
grep -rn "NAO ha raise\|nao levanta\|nunca levanta\|sem raise" Source/
```

**Alvo: zero** linhas contaminadas relacionadas ao sítio Visibility.

As linhas sadias já mapeadas (`RTTI.pas:536`, `:578`, `:675`, `RTTI.FPC.pas:868`)
tratam de outros membros e permanecem — não são o alvo desta varredura. Se o grep
devolver apenas essas linhas, a varredura passou.

Qualquer achado inesperado fora do escopo desta issue:
- **Não entrar no diff** desta issue.
- **Registrar no corpo do PR** como "Achado — nova issue".

### O que não tocar

- `Source/ModernSyntax.RTTI.FPC.pas` — intocado; o `else raise` de `RTTI.FPC.pas:505-507`
  é o PR #65; não re-editar.
- `Source/ModernSyntax.RTTI.Delphi.pas` — intocado.
- `RTTI.pas:155-160` — bloco `<summary>` de `TModernRTTIProperty.Visibility`;
  segue verdadeiro; não tocar.
- Suite de testes — contagem FPC permanece 42.

### Verificação na fábrica

Compilar a unit isolada para confirmar que os `///` não introduziram erro de sintaxe
Pascal:

```bash
mkdir -p /tmp/fpcbuild
rm -f /tmp/fpcbuild/*.o /tmp/fpcbuild/*.ppu
fpc -Mdelphi -FU/tmp/fpcbuild Source/ModernSyntax.RTTI.pas
# Esperado: zero erros, zero warnings
```

Suite completa (prova que o cenário do único ramo alcançável permanece verde):

```bash
rm -f /tmp/fpcbuild/*.o /tmp/fpcbuild/*.ppu
fpc -Mdelphi -FU/tmp/fpcbuild \
    -Fu"Source" -Fu"Test Shared/EclbrSystem" -Fu"Test FPC/EclbrSystem" \
    -o/tmp/fpcbuild/PTestRTTI "Test FPC/EclbrSystem/PTestRTTI.lpr"
/tmp/fpcbuild/PTestRTTI --all -a --format=plain
# Esperado: 42 testes, todos passando
```
