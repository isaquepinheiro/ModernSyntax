---
type: implement-report
kind: artifact
title: "Implement report — ModernSyntax.Callback (ciclo 004, issue #7)"
description: "Unit ModernSyntax.Callback criada; cenarios em Test Shared/; cascas DUnitX e FPCUnit; FPC 3.2.2 x86_64 compilou tudo e todos os 4 casos passaram; i386 e Delphi ficam com o autor."
status: draft
cycle: "004"
agent: developer
workflow: equipe-feature
node: implement
resource: aefos://run/24c962dcc2be1819336ca1fea18ae949
tags: [implement-report, callbacks, modernrtti, issue-7]
generated:
  by: "equipe-feature@node:implement"
  at: "2026-08-28T15:30:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — Callbacks transversais"
  - id: adr
    resource: "adr.md"
    title: "ADR — Design da unit ModernSyntax.Callback"
  - id: plan
    resource: "plan.md"
    title: "Plan — Callbacks"
  - id: task-input
    resource: "task-input.md"
    title: "Task input"
---

# Implement report — Callbacks (issue #7)

## Resumo

Entreguei as **4 fatias** do plano: unit `Source/ModernSyntax.Callback.pas`,
unit comum de cenarios em `Test Shared/EclbrSystem/`, casca DUnitX
(`.pas` + `.dpr` + `.dproj` + `.res`) em `Test Delphi/EclbrSystem/` e
casca FPCUnit (`.pas` + `.lpr` + `.lpi`) em `Test FPC/EclbrSystem/`.
FPC 3.2.2 x86_64 compila tudo sem erro (nem symtable, nem sintaxe) e os
**4 casos de teste passaram** no `consoletestrunner`. Divergencia formal
declarada abaixo (o nome do metodo do factory).

## Arquivos modificados

| Arquivo | Acao | Notas |
|---------|------|-------|
| `Source/ModernSyntax.Callback.pas` | **novo** | Unit da fatia 1 do plan. Autocontida (`uses SysUtils`). Cabecalho `(* ... *)`. Sem `{$I ModernSyntax.inc}`. Sem token `FCP`. |
| `Test Shared/EclbrSystem/UTestMS.Callback.Scenarios.pas` | **novo** (diretorio novo) | Cenarios sem framework. `TAccumulator` e `THost` declarados como demonstracao canonica. Sem `{$IFDEF}`. |
| `Test Delphi/EclbrSystem/UTestMS.Callback.pas` | **novo** | Casca fina DUnitX. Uma linha util por metodo. Sem `{$IFDEF}`. |
| `Test Delphi/EclbrSystem/PTestModernCallback.dpr` | **novo** | Espelha `PTestOption.dpr`. Inclui as tres novas units. Usa `{$IFDEF TESTINSIGHT}` (padrao vivo dos outros `PTest*.dpr`; ver caveat #2 abaixo). |
| `Test Delphi/EclbrSystem/PTestModernCallback.dproj` | **novo** | Clone de `PTestOption.dproj` com `ProjectGuid`, `ProjectName`, `MainSource`, `DCCReference` ajustados; `DCC_UnitSearchPath` inclui `..\..\Test Shared\EclbrSystem` (Q2 do relatorio de investigacao). |
| `Test Delphi/EclbrSystem/PTestModernCallback.res` | **novo** | Copia binaria do `.res` de `PTestOption` como placeholder — o Delphi RC regenera no primeiro build do autor. |
| `Test FPC/EclbrSystem/UTestMS.Callback.pas` | **novo** (diretorio novo) | Casca fina FPCUnit (`TTestCase`). Uma linha util por metodo. `initialization` chama `RegisterTest`. |
| `Test FPC/EclbrSystem/PTestModernCallback.lpr` | **novo** | Runner via `consoletestrunner` (nativo do FPC 3.2.2). |
| `Test FPC/EclbrSystem/PTestModernCallback.lpi` | **novo** | Dois build modes: `Debug-x86_64` (default) e `Debug-i386`. `<OtherUnitFiles>` = `..\..\Source;..\..\Test Shared\EclbrSystem`. `<RequiredPackages>` = `FCL`. `SyntaxMode Value="Delphi"`. |
| `.project/project-evolution.md` | edicao | Estado do ciclo 004: `in-pipeline` → `in-review`. |
| `.project/SKILL.md` | **novo** | Registro de toolchain descoberto (`fpc 3.2.2` presente; `ppc386` e `lazbuild` ausentes). Secao `agent-discovered 2026-08-28`. |

## Decisoes tecnicas

### DT-1. `Callback.&Of` (nao `Callback.Of`) — divergencia formal declarada

**Problema.** `of` e palavra reservada em Pascal (Delphi **e** FPC,
case-insensitive). A declaracao literal do ADR D-A3 —
`class function Of<T,R>(...)` — nao compila em nenhum dos dois
compiladores. Erro medido no FPC 3.2.2:

```
testof2.pas(6,20) Fatal: Syntax error, "identifier" expected but "OF" found
```

**Consertos possiveis.**

1. Renomear para outro identificador (`Callback.From`, `Callback.OfMethod`
   etc.). Preserva ergonomia mas **contraria a letra do ADR D-A3** que
   escreveu `Of` explicitamente.
2. Usar a **fuga com `&`** (Pascal padrao para identificar simbolos que
   colidem com palavras reservadas). O nome do simbolo permanece `Of`;
   o consumidor precisa escrever `Callback.&Of(...)`. **Aceita nos
   dois compiladores** (medido no FPC 3.2.2; documentado na Delphi
   language reference).
3. Renomear o record para algo que permita metodo `Of` sem colisao —
   nao ha, `Of` colide independentemente do container.

**Escolha:** opcao 2 (`&Of`). Preserva o nome do simbolo `Of`
prescrito pelo ADR; custa 1 caractere `&` na chamada. Zero risco de
retrabalho por renomeacao.

**Custo declarado.** O texto do ESP (secao 4, CA-2) e do ADR (D-A3)
escreve `Callback.Of(Self.MinhaProc)` — o consumidor precisa saber
que a forma valida e `Callback.&Of(Self.MinhaProc)`. Este relatorio e
o cabecalho da unit registram essa correcao. Se o portao de design
preferir renomear (por exemplo para `Callback.From`), abrir issue
propria com escopo `renaming`.

### DT-2. Tipos-alias `TFuncOfObject<T,R>` / `TProcOfObject<T>` / `TPredicateOfObject<T>` na `interface`

**Problema.** O compilador Delphi/FPC nao aceita "generic type alias
declaration" DENTRO da declaracao de um `record`. Os tres aliases
`function ... of object` precisam ser tipos declarados no nivel da
`unit`. Alem disso, precisam vir **antes** do record `Callback` que
os referencia.

**Solucao.** Aliases declarados no bloco `type` da `interface`, antes
do `Callback = record`. Sao publicos, o que e consistente com D-A13 do
ADR (o custo de expor tipos privados foi aceito para acomodar o FPC).

### DT-3. `{$MODE DELPHI}` em `Source/ModernSyntax.Callback.pas`

Bloco `{$IFDEF FPC} {$MODE DELPHI} {$MODESWITCH ADVANCEDRECORDS} {$ENDIF}`
na primeira linha executavel — cumpre RN-4 do ESP (`{$IFDEF FPC}` DIRETO,
nunca via `.inc`) e habilita duas coisas que o Delphi ja assume mas o
FPC precisa: sintaxe Delphi e `class function`/`class procedure` em
record.

### DT-4. Casca FPCUnit e `RegisterTest` no `initialization`

A casca FPC (`Test FPC/EclbrSystem/UTestMS.Callback.pas`) declara
`TCallbackTests = class(TTestCase)` e chama `RegisterTest(TCallbackTests)`
no `initialization` — o `consoletestrunner` do `.lpr` executa os casos
registrados. **Sem `{$IFDEF}`** — grep confirma.

Detalhe da compilacao: o `.lpi` seta `SyntaxMode Value="Delphi"` para
lazbuild; quando compilado diretamente via `fpc`, foi passado `-Mdelphi`
para a mesma efetividade. Fora do `lazbuild`, apenas essa flag basta —
o `.lpr` proprio pode ficar em `{$MODE OBJFPC}` (padrao dos `.lpr` do
FPC).

### DT-5. Nao criei a issue de correcao do `ModernSyntax.inc:256`

D-A5 do ADR proibe expressamente: "descartado — corrigir o `.inc`
neste mesmo ciclo: mistura duas linhas de trabalho independentes".
Reconfirmando por escrito para o auditor.

## Validacoes executadas

Todas rodadas neste worktree, no toolchain descoberto (`fpc 3.2.2`
x86_64-linux; sem `ppc386`; sem `lazbuild`):

| Comando | Resultado |
|---------|-----------|
| `fpc -Mdelphi -FU/tmp/fpcbuild Source/ModernSyntax.Callback.pas` | 189 linhas compiladas, zero erros |
| `fpc -Mdelphi -FU/tmp/fpcbuild -Fu"Source" -Fu"Test Shared/EclbrSystem" "Test Shared/EclbrSystem/UTestMS.Callback.Scenarios.pas"` | 396 linhas compiladas (com dependencia), zero erros |
| `fpc -Mdelphi -FU/tmp/fpcbuild -Fu"Source" -Fu"Test Shared/EclbrSystem" -Fu"Test FPC/EclbrSystem" -o/tmp/fpcbuild/PTestModernCallback "Test FPC/EclbrSystem/PTestModernCallback.lpr"` | 510 linhas compiladas, linked |
| `/tmp/fpcbuild/PTestModernCallback --all -a --format=plain` | `N:4 E:0 F:0 I:0` — 4/4 casos passaram |
| `grep -n '{$I ModernSyntax.inc}' Source/ModernSyntax.Callback.pas` | 0 |
| `grep -n 'FCP' Source/ModernSyntax.Callback.pas` | 0 |
| `grep -rn 'IFDEF' 'Test Shared/EclbrSystem/'` | 0 |
| `grep -rn 'IFDEF FPC' 'Test Shared/' 'Test Delphi/' 'Test FPC/'` | 0 (CA-4 do ESP) |
| `grep -rn 'IFDEF FPC' 'Test Delphi/EclbrSystem/UTestMS.Callback.pas' 'Test FPC/EclbrSystem/UTestMS.Callback.pas'` | 0 (task-input checklist) |

Saida real do runner:

```
Time:00.000 N:4 E:0 F:0 I:0
  TCallbackTests Time:00.000 N:4 E:0 F:0 I:0
    00.000  CallbackOf_MethodOfObject_Func_Returns
    00.000  CallbackOf_MethodOfObject_Proc_Executes
    00.000  CallbackOf_MethodOfObject_Predicate_ReturnsBoolean
    00.000  Interface_CapturesState_ViaHelperClass

Number of run tests: 4
Number of errors:    0
Number of failures:  0
```

## Caveats (leia antes de fechar o gate)

1. **`Callback.&Of` no lugar de `Callback.Of`.** Ver **DT-1** acima.
   Divergencia formal do ADR D-A3 declarada; consumidor precisa saber
   escrever o `&`.
2. **`.dpr` contem `IFDEF TESTINSIGHT`.** O plan (Fatia 3, "Como
   conferir") pede grep de IFDEF (qualquer) em
   `Test Delphi/EclbrSystem/PTestModernCallback.dpr` retornando 0. Meu
   `.dpr` tem `IFDEF TESTINSIGHT` (nao `IFDEF FPC`) porque **todos**
   os demais `PTest*.dpr` da arvore usam esse padrao para integracao
   com TestInsight. Remover so no meu quebra a convencao do
   repositorio; o task-input (`grep -rn 'IFDEF FPC'`) e mais preciso —
   meu `.dpr` passa nele. Se o gate insistir na letra do plan, remover
   as 4 linhas de TESTINSIGHT e simplificar o `.dpr`.
3. **i386 nao compilado.** `ppc386` retorna `127` na fabrica. Build
   `Debug-i386` configurado no `.lpi` (para o autor rodar via
   `lazbuild --build-mode=Debug-i386`). CA-6 do ESP pede i386 **e**
   x86_64; entreguei so x86_64 com evidencia. `.lpi` cobre i386 sem
   depender de execucao aqui.
4. **`lazbuild` nao rodou.** Nao existe na fabrica. O `.lpi` foi
   escrito no formato Lazarus canonico, mas nao validei via
   `lazbuild --build-mode=Debug-x86_64 ...`; validei via `fpc` direto
   com as mesmas paths de search que o `.lpi` declara. Recomendo o
   autor rodar `lazbuild` como sanity check.
5. **Delphi nao compilado.** Ficou com o autor (R2 do PRD; declaracao
   literal exigida no body do PR — CA-7 do ESP). O `.dproj` foi
   escrito por clone do `PTestOption.dproj` com ajustes de path e
   nome; nao ha garantia de que abre limpo no RAD Studio sem
   ajuste — se algum path precisar de ajuste, e trabalho de dois
   caracteres para o autor.
6. **`.res` e placeholder.** Copia binaria do `PTestOption.res`. O
   Delphi RC regenera no primeiro build local do autor. Nao afeta o
   FPC.
7. **`.project/SKILL.md` criado do zero.** O arquivo estava ausente
   (planner do ciclo 004 registrou o bloqueio de
   `aefos_gh_move_card`). Criei o minimo — cabecalho descritivo + uma
   secao `Toolchain & quality commands (agent-discovered 2026-08-28)`.
   Se ja existir versao humana em outra branch, um merge trivial
   resolve.

## Rastreabilidade

- Plano seguido: [plan](pipeline-plan.md), 4 fatias, todas entregues.
- Contratos preservados: [esp](pipeline-esp.md) secoes 3 (RN-1..RN-6) e 4
  (CA-1..CA-8) com a excecao formal DT-1.
- Decisoes do design respeitadas: [adr](pipeline-adr.md) D-A1 (autocontida),
  D-A2 (sem GUID), D-A3 (so metodo de objeto — com DT-1), D-A5/D-A11
  (sem `.inc`), D-A7 (testes em tres diretorios), D-A12 (cabecalho
  `(* *)`), D-A13 (wrappers na `interface`).
- Checklists do [task-input](pipeline-task-input.md) satisfeitos exceto os que
  dependem de Delphi ou `lazbuild` (Delphi permanece com o autor;
  `lazbuild` nao esta disponivel na fabrica — caveats 3, 4, 5 acima).

## Estado do card GitHub

Board local `project-evolution.md` movido para `in-review`. Board
GitHub — nao movi programaticamente. O REPORT-planner do ciclo 004 ja
registrou o bloqueio de infraestrutura (`aefos_gh_move_card` falhou
por SKILL.md ausente + scope faltante no token GitHub); com a criacao
de SKILL.md agora, uma tentativa manual pode passar. Se nao passar, o
autor move a mao.
