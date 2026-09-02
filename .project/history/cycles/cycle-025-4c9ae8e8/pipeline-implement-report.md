---
type: implement-report
kind: artifact
title: "IMPLEMENT #60 — else raise no PropertyVisibility do backend FPC"
description: "Quatro edicoes cirurgicas em 2 arquivos Pascal: resourcestring SFPCUnknownVisibility, else raise, comentario reescrito, XMLDoc corrigido. FPC 3.2.2 x86_64 verde 42/42."
status: stable
cycle: "025"
agent: developer
workflow: equipe-bug
node: implement
resource: aefos://run/4c9ae8e8f3b0ca77a166f343e7d3f098
tags: [cycle-025, issue-60, bug, fpc, rtti, visibility, fail-loud]
generated:
  by: "equipe-bug@node:implement"
  at: "2026-09-02T00:00:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — Issue #60"
  - id: adr
    resource: "adr.md"
    title: "ADR — Issue #60"
  - id: plan
    resource: "plan.md"
    title: "PLAN — Issue #60"
  - id: task-input
    resource: "task-input.md"
    title: "TASK-INPUT — Issue #60"
---

# IMPLEMENT-REPORT — Issue #60

## O que mudou

Quatro pontos cirúrgicos em dois arquivos Pascal (`Source/ModernSyntax.RTTI.FPC.pas`,
`Source/ModernSyntax.RTTI.pas`), um único commit lógico. Ordem exatamente a do
[plan](pipeline-plan.md): resourcestring → comentário → `else raise` → XMLDoc.

A única linha executável nova é o `else raise EModernRTTIError.CreateFmt(...)`
dentro do `case` de `PropertyVisibility`. As outras três edições são
resourcestring da `implementation` (invisível na interface pública), comentário
interno e XMLDoc.

| # | Arquivo | Local | Natureza |
|---|---------|-------|----------|
| 1 | `Source/ModernSyntax.RTTI.FPC.pas` | após bloco `SFPCNoParamType` (~linha 193) | + `resourcestring SFPCUnknownVisibility` na `implementation` |
| 2 | `Source/ModernSyntax.RTTI.FPC.pas` | comentário de `PropertyVisibility` (ex-474–487) | reescrita: sai "codigo morto"; entra medição+linhagem #51↔#60 |
| 3 | `Source/ModernSyntax.RTTI.FPC.pas` | corpo do `case` de `PropertyVisibility` | + `else raise EModernRTTIError.CreateFmt(SFPCUnknownVisibility, [Ord(...), 'PropertyVisibility'])` |
| 4 | `Source/ModernSyntax.RTTI.pas` | XMLDoc de `TModernVisibility` (79–85) | reescrita: dois backends após guardas + medição no passado + D-51.1/D-60.1 |

## Tabela de arquivos modificados

| Arquivo | Âmbito | Delta |
|---------|--------|-------|
| `Source/ModernSyntax.RTTI.FPC.pas` | Produção (backend FPC) | +24 / −11 |
| `Source/ModernSyntax.RTTI.pas` | Produção (superfície pública, só XMLDoc) | +9 / −7 |
| `.project/project-evolution.md` | Board local | linha 025: `🔄 in-pipeline` → `🔄 in-review` |

## Decisões técnicas

### Edição 1 — `SFPCUnknownVisibility` na `implementation` (D-60.2)

Colocada **após** `SFPCNoParamType` (o último bloco `SFPCNo*` da unit),
formando o grupo #60. Comentário-cabeçalho explicita a nova convenção
(D-60.3): `SFPCNo*` = feature indisponível; `SFPCUnknown*` = enum
mapeado mas sem ramo. Cita a simetria com `SDelphiUnknownVisibility` em
`RTTI.Delphi.pas:163-165`.

Texto da mensagem é **cópia literal** de `SDelphiUnknownVisibility`
trocando apenas `issue #51` → `issue #60`, conforme D-60.4. O
discriminante entre sites (e entre backends) é o `%s` do nome da função,
não variação textual — divergir a prosa seria drift novo.

Zero símbolo novo na interface, verificado pelo diff: o bloco vive dentro
do `implementation` (após `implementation` na linha 149 e antes de
qualquer `function`/`procedure` de topo).

### Edições 2 e 3 — comentário reescrito + `else raise` (D-60.1 + D-60.6)

Feitas em um único Edit ancorado no cabeçalho do procedimento
(`function PropertyVisibility(AToken: Pointer): TModernVisibility;`) para
evitar dependência de contagem de linha após a edição 1 no mesmo arquivo.

**Comentário — o que sai / o que entra:**

- SAI: "Os quatro ramos esgotam o enum; `else` levantando seria código
  morto." (era baseado na premissa falsa de exaustividade — ADR D-60,
  supercede D-51.8).
- ENTRA: prosa que
  - Cita D-51.1 estendida à #60 como segundo movimento da mesma decisão.
  - Enquadra a medição (sem erro, sem warning, sem hint; 229/i386,
    0 = `mvPrivate`/x86_64) **no passado**, como razão histórica da
    guarda.
  - Preserva a nota de que **não há ramo `mvAutomated`** em
    `TMemberVisibility` do FPC 3.2.2 (`rtti.pp:308`).
  - Preserva a disciplina de labels qualificados
    (`TMemberVisibility.` para o `case`, `TModernVisibility.` para o
    `Result`).

Comentário foi transliterado para ASCII (sem acentos, sem `**bold**`) para
alinhar ao padrão do arquivo — os demais comentários de
`RTTI.FPC.pas` usam ASCII (D-62 já debateu isso; o padrão do arquivo é
ASCII sem markdown). O plano trazia o texto acordado como *exemplo de
prosa aprovada*; adaptei à convenção de encoding do arquivo, preservando
todo o conteúdo semântico exigido pelo ADR (D-60.6).

**`else raise` — cópia literal do Delphi:**

```pascal
else
  raise EModernRTTIError.CreateFmt(SFPCUnknownVisibility,
    [Ord(TRttiProperty(AToken).Visibility), 'PropertyVisibility']);
```

Idêntica ao Delphi (`RTTI.Delphi.pas:374-377`) trocando apenas o nome da
resourcestring. Sem `AOwner` (D-51.5) — `PropertyVisibility(AToken)` não
recebe `AOwner`; o `%s` recebe `'PropertyVisibility'` (nome da função,
não do owner).

### Edição 4 — XMLDoc de `TModernVisibility` (D-60.5)

Substituição do bloco que ia da linha 78 ("Se `TMemberVisibility`...") até
a linha 85 ("Ver #60."). O parágrafo aberto do `<summary>` (linhas 71–77)
ficou **intacto** — só a cláusula que afirmava "no FPC os 4 ramos esgotam
o enum, então o `case` sem `else` é correto **hoje**" foi reescrita.

Prosa nova:

- Descreve o que os **dois** backends fazem *após* as guardas: ambos
  levantam `EModernRTTIError` no primeiro chamador.
- Cita D-51.1 (issue #51, Delphi) e D-60.1 (issue #60, FPC).
- Coloca a medição no passado: "antes das guardas o comportamento
  observado era: Delphi emitia W1035 e devolvia lixo (204/16/252/16 nos
  4 alvos); FPC 3.2.2 compilava sem erro, sem warning e sem hint, e o
  valor não mapeado vinha como ordinal 229 no i386 e 0 no x86_64 — e 0 é
  `mvPrivate`, um valor semanticamente plausível".
- **Não** faz nenhuma afirmação sobre exaustividade em compile-time no
  FPC.

XMLDoc mantém acentos (padrão histórico da unit pública RTTI.pas — a
edição de #62 já introduziu acentos aqui) mas retirei o `**bold**` do
texto substituído porque a nova prosa não precisa de ênfase (a asserção
"tampouco faz análise de exaustividade" saiu inteira; ficou o que os dois
backends *fazem*, factual).

## Validações rodadas

### Toolchain (por SKILL.md)

Segui `.project/SKILL.md` seções "Toolchain and quality commands" e
"Toolchain & quality commands (agent-discovered 2026-08-28)". Nenhum
comando novo descoberto — todos os que usei já estão documentados. Sem
`SKILL.md` para atualizar.

### Compilar unit isolada (verificação de sintaxe)

```
mkdir -p /tmp/fpcbuild
rm -f /tmp/fpcbuild/*.o /tmp/fpcbuild/*.ppu
fpc -Mdelphi -FU/tmp/fpcbuild Source/ModernSyntax.RTTI.FPC.pas
```

- **2714 lines compiled, 0.8 sec** — link limpo.
- **10 warnings, 6 notes** — TODOS pré-existentes; nenhum introduzido.
  Os warnings do FPC (`Unit "Rtti" is experimental` na linha 45 de
  `RTTI.FPC.pas`, `function result variable of a managed type does not
  seem to be initialized` em `RTTI.FPC.pas:598,844` e `RTTI.pas:1088`)
  são os mesmos do `main`. **Zero warning novo** — confirma o corpo do PR
  ("não há redução de warning; o FPC nunca emitiu warning para este
  padrão"; simetricamente, esta fix também não adiciona warning).

### Suite FPCUnit x86_64

```
rm -f /tmp/fpcbuild/*.o /tmp/fpcbuild/*.ppu
fpc -Mdelphi -FU/tmp/fpcbuild \
    -Fu"Source" -Fu"Test Shared/EclbrSystem" -Fu"Test FPC/EclbrSystem" \
    -Fi"Test Shared/EclbrSystem" \
    -o/tmp/fpcbuild/PTestRTTI "Test FPC/EclbrSystem/PTestRTTI.lpr"
/tmp/fpcbuild/PTestRTTI --all -a --format=plain
```

- **4659 lines compiled, 1.2 sec** — link limpo.
- **Number of run tests: 42 | Number of errors: 0 | Number of failures: 0**
- Cenário mais relevante: `Scenario_Property_Visibility_Returns_mvPublished`
  (via `TestProperty_Visibility_Returns_mvPublished`) — passa,
  confirmando que o único ramo alcançável por dado real (`mvPublished`)
  não regrediu. A contagem permanece **42**, conforme D-60.8.

### Build FPC 3.2.2 i386

**NÃO executado na fábrica.** `SKILL.md` registra que `ppc386` retorna
`127` no container Aefos ("NÃO ha cross-compiler i386"). Validação i386
fica com o autor humano — declarado no PR body conforme D-60.7.

### Build Delphi

**NÃO executado na fábrica.** `SKILL.md` registra que Delphi só compila
no ambiente do autor. Backend Delphi **intocado** por esta fix — `git
diff Source/ModernSyntax.RTTI.Delphi.pas` retorna vazio; regressão do
Delphi seria impossível.

### Guard-rail: superfície de interface (D-60.2)

Verificado que `SFPCUnknownVisibility` está dentro do `implementation`:

- O bloco `implementation` começa em `RTTI.FPC.pas:149`.
- O `resourcestring SFPCUnknownVisibility` é adjacente a
  `SFPCNoParamType` (linha ~193), bem depois de `implementation` e antes
  de qualquer `function`/`procedure` de topo.
- `grep` da `interface` para `SFPCUnknownVisibility`: zero hits.

Zero símbolo novo na interface pública, conforme critério de aceitação
do [esp](pipeline-esp.md).

### Guard-rail: backend Delphi intocado

```
git diff --stat Source/ModernSyntax.RTTI.Delphi.pas
```

Sem output — arquivo não modificado. `RTTI.Delphi.pas` sem diff, conforme
checklist do [task-input](pipeline-task-input.md).

## Advance do board

- `.project/project-evolution.md` linha do ciclo 025:
  `🔄 in-pipeline` → `🔄 in-review`.
- Card no GitHub project board: mesma restrição do ciclo 024 — não há
  ProjectV2 configurado; `aefos_gh_move_card` não aplicável.

## Caveats

- **Comentário do `PropertyVisibility` em ASCII, não com acentos.** O plano
  ([plan](pipeline-plan.md) item 2) trazia o texto acordado com acentos como
  *exemplo de prosa aprovada*. Adaptei à convenção histórica do arquivo
  (`RTTI.FPC.pas` só usa comentários ASCII, sem acentos e sem markdown),
  preservando o conteúdo semântico exigido pelo ADR (D-60.6): linhagem
  #51↔#60, medição no passado, `mvAutomated` inexistente, disciplina de
  labels qualificados. Se o reviewer preferir a prosa verbatim com
  acentos, ajusto em commit de fixup.
- **XMLDoc de `TModernVisibility` em `RTTI.pas`** mantém acentos, pois o
  arquivo público já os usa (a edição de #62 introduziu acentos ali,
  intencional para XMLDoc renderizado). Consistência interna preservada:
  RTTI.pas com acentos, RTTI.FPC.pas em ASCII.
- **`**bold**` retirado do XMLDoc.** A prosa nova é factual (o que os dois
  backends fazem após as guardas); não precisa de ênfase markdown. A
  ênfase existia no texto antigo para destacar a afirmação falsa ("**hoje**",
  "**tampouco**"); a afirmação saiu, a ênfase saiu com ela.
- **i386 e os 4 alvos Delphi ficam com o autor.** Fronteira declarada no
  PR body, não simulada — mesma disciplina de D-60.7 / D-62.4.
- **Warnings pré-existentes** de `function result variable of a managed
  type does not seem to be initialized` continuam em três locais;
  **não são consequência deste PR** e são fora de escopo (a fix
  introduz **zero linhas** que possam gerar esse warning).
