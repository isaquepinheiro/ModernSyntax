---
type: plan
kind: artifact
title: "PLAN #60 — 4 edicoes em 2 arquivos, slice unico"
description: "Slice unico: resourcestring + else raise + comentario reescrito + XMLDoc corrigido. Verdict: fits."
cycle: "025"
agent: architect
workflow: equipe-bug
node: architect
resource: aefos://run/4c9ae8e8f3b0ca77a166f343e7d3f098
generated:
  by: "equipe-bug@node:architect"
  at: "2026-09-02T00:00:00Z"
tags: [plan, fpc, rtti, visibility, bug, issue-60, modernrtti, cycle-025]
---

# PLAN — Issue #60: `else raise` no `PropertyVisibility` do backend FPC

**Verdict: `fits`** — 4 edições em 2 arquivos, todas necessárias para que a fix seja
completa e o XMLDoc público não publique afirmação falsa. Um commit, um PR.

- **Teste de tamanho:** 4 substituições/inserções cirúrgicas. Custo real < $3. Não
  exaure o orçamento de implementação.
- **Teste de independência:** as 4 edições compõem um único mecanismo (guarda fail-loud
  no FPC + documentação consistente). Entregar só a resourcestring sem o `else raise`
  não faz sentido; entregar a guarda sem corrigir o XMLDoc publica afirmação falsa.
  Não são independentes.

---

## Slice 1 — 4 edições, um commit

### Ordem de execução

**1. `Source/ModernSyntax.RTTI.FPC.pas` — bloco `resourcestring` (após linha 193)**

Adicionar `SFPCUnknownVisibility` na seção `resourcestring` da `implementation`,
após `SFPCNoParamType`, formando o grupo #60:

```pascal
// Issue #60 — extensão da D-51.3 ao backend FPC. Prefixo `SFPCUnknown*`
// (não `SFPCNo*`): `SFPCNo*` = feature indisponível (dado não existe no
// RTTI); aqui o dado existe, só não bate com nenhum ramo mapeado.
// Simetria com `SDelphiUnknownVisibility` (RTTI.Delphi.pas:163-165).
SFPCUnknownVisibility =
  'TMemberVisibility desconhecido (Ord=%d) em %s — ' +
  'TModernVisibility precisa de novo ramo (issue #60).';
```

**2. `Source/ModernSyntax.RTTI.FPC.pas:474–487` — reescrita do comentário de `PropertyVisibility`**

Sai: *"Os quatro ramos esgotam o enum; `else` levantando seria código morto."*

Entra: comentário que (a) cita D-51.1 estendida à #60 como segundo movimento da
mesma decisão; (b) enquadra a medição (sem erro, sem warning, sem hint; ordinal 229
no i386, 0 = `mvPrivate` no x86_64) como razão histórica da guarda, no passado —
não como afirmação de estado atual; (c) preserva a nota de que não há ramo
`mvAutomated` no `TMemberVisibility` do FPC 3.2.2 (`rtti.pp:308`); (d) preserva a
disciplina de labels qualificados (`TMemberVisibility.` para o `case`,
`TModernVisibility.` para `Result`).

Exemplo de prosa aprovada na investigação:

```
// D-51.1 do ADR issue #51 estendida à issue #60 ao backend FPC:
// `case` de 4 ramos + `else raise EModernRTTIError`. Substitui
// parcialmente D-42.2 + D-42.4 do ADR issue #42 (intenção fail-loud
// preservada; mecanismo trocado). #51 corrigiu o Delphi primeiro; #60
// alinha o FPC aqui — segundo movimento da mesma decisão.
//
// A guarda existe porque, antes dela, o FPC 3.2.2 aceitava o `case`
// sem `else` sem erro, sem warning, sem hint (Delphi ao menos emitia
// W1035). Valor não mapeado por ele mesmo vinha como ordinal 229 no
// i386 e 0 no x86_64 — e 0 é `mvPrivate`, um `TModernVisibility`
// semanticamente plausível. Silencioso e convincente é o pior modo
// de falha; por isso fail-loud.
//
// SEM ramo `mvAutomated` — esse identificador NÃO existe em
// `TMemberVisibility` do FPC 3.2.2 (`rtti.pp:308`); incluí-lo não
// compila. Case labels QUALIFICADOS com `TMemberVisibility.` (do
// Rtti/TypInfo), Result com `TModernVisibility.` (da casca), porque
// os dois enums declaram constantes homônimas — mesma disciplina do
// backend Delphi.
```

**3. `Source/ModernSyntax.RTTI.FPC.pas` — corpo do `case` (antes do `end;` em ~493)**

Inserir literalmente:

```pascal
else
  raise EModernRTTIError.CreateFmt(SFPCUnknownVisibility,
    [Ord(TRttiProperty(AToken).Visibility), 'PropertyVisibility']);
```

Cópia literal do Delphi (`RTTI.Delphi.pas:374-377`) trocando apenas o nome da
resourcestring.

**4. `Source/ModernSyntax.RTTI.pas:79–85` — reescrita do XMLDoc de `TModernVisibility`**

A prosa atual afirma que o `case` sem `else` no FPC é correto. Após a fix, isso
é falso. Nova prosa:

- Descreve o que os dois backends fazem *após* as guardas (ambos levantam
  `EModernRTTIError` no primeiro chamador).
- Cita D-51.1 (issue #51, Delphi) e D-60.1 (issue #60, FPC).
- Coloca a medição como passado histórico: "antes das guardas, o comportamento
  observado era: Delphi emitia W1035 e devolvia lixo (204/16/252/16 nos 4 alvos);
  FPC 3.2.2 compilava sem erro, sem warning e sem hint, e o valor não mapeado
  vinha como ordinal 229 no i386 e 0 no x86_64 — e 0 é `mvPrivate`, um valor
  semanticamente plausível."
- Não faz nenhuma afirmação sobre exaustividade em compile-time no FPC.

### PR body

Frase declarativa — **sem checklist de combinações**:

> Compilado em FPC 3.2.2 x86_64. i386 e os 4 alvos Delphi ficam com o autor.
>
> O ramo `else raise` é inalcançável por dado real (valor vem de
> `TRttiProperty(AToken).Visibility`, RTTI real, não injetável). Não há
> redução de warning — o FPC nunca emitiu warning para este padrão.

### O que não tocar

- `MethodVisibility` do FPC — já levanta com `SFPCNoVisibility` por design.
- `Source/ModernSyntax.RTTI.Delphi.pas` — PR #59 já cobriu.
- Suite de testes — contagem FPC permanece 42.
- `Scenario_Property_Visibility_Returns_mvPublished` (`UScenarios.RTTI.pas:1086`) —
  único ramo alcançável por dado real; não tocar.

### Verificação na fábrica

```bash
mkdir -p /tmp/fpcbuild
rm -f /tmp/fpcbuild/*.o /tmp/fpcbuild/*.ppu
fpc -Mdelphi -FU/tmp/fpcbuild Source/ModernSyntax.RTTI.FPC.pas
# Esperado: zero erros, zero warnings
```

Suite completa (após build do binário de testes):

```bash
rm -f /tmp/fpcbuild/*.o /tmp/fpcbuild/*.ppu
fpc -Mdelphi -FU/tmp/fpcbuild \
    -Fu"Source" -Fu"Test Shared/EclbrSystem" -Fu"Test FPC/EclbrSystem" \
    -o/tmp/fpcbuild/PTestRTTI "Test FPC/EclbrSystem/PTestRTTI.lpr"
/tmp/fpcbuild/PTestRTTI --all -a --format=plain
# Esperado: 42 testes, todos passando
```
