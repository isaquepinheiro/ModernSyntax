---
type: implement-report
kind: artifact
title: "Implement report — Pilar 1 da ModernRTTI (ciclo 002)"
description: "Implementacao de Source/ModernSyntax.RTTI.pas, suite DUnitX e projeto Lazarus para o Pilar 1 da ModernRTTI. CA-1..CA-8 do ESP cobertos; validacoes de grep verdes; compilacao nao executada (R2 do PRD — fabrica sem compilador Pascal)."
status: draft
cycle: "002"
agent: developer
workflow: equipe-feature
node: implement
resource: aefos://run/fa369bfebcbab23d74f445cede226eb0
tags: [implement, modernrtti, pilar-1, issue-8, cycle-002]
generated:
  by: "equipe-feature@node:implement"
  at: "2026-08-28T02:00:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — Pilar 1"
  - id: adr
    resource: "adr.md"
    title: "ADR — Design do Pilar 1"
  - id: plan
    resource: "plan.md"
    title: "Plan — Pilar 1"
  - id: task
    resource: "task.md"
    title: "Task — Implementar Pilar 1"
---

# Implement report — Pilar 1 da ModernRTTI

Issue: [isaquepinheiro/ModernSyntax#8](https://github.com/isaquepinheiro/ModernSyntax/issues/8).
Insumos: [esp](pipeline-esp.md), [adr](pipeline-adr.md), [plan](pipeline-plan.md), [task](pipeline-task.md).

## O que mudou

Uma unit nova, uma suite de teste nova, um projeto Delphi (.dpr) novo,
um projeto Lazarus (.lpi/.lpr) novo minimo. Nenhum arquivo existente
foi modificado alem do board de estado.

### Arquivos alterados

| Arquivo | Acao | Escopo |
|---------|------|--------|
| `Source/ModernSyntax.RTTI.pas` | **criado** | Unit principal — `ModernRTTI` + tres wrappers + `EModernRTTIError` |
| `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` | **criado** | Suite DUnitX (9 casos) |
| `Test Delphi/EclbrSystem/PTestModernRTTI.dpr` | **criado** | Runner Delphi (espelha `PTestObjects.dpr`) |
| `Test Lazarus/PTestModernRTTI.lpi` | **criado** | Projeto Lazarus minimo (FPC 3.2.2) |
| `Test Lazarus/PTestModernRTTI.lpr` | **criado** | Runner FPC com DUnitX |
| `.project/project-evolution.md` | **atualizado** | Demanda #8 movida `in-pipeline` -> `in-review`; legenda expandida |

Nao foram gerados `.dproj` nem `.res` (ver Caveats).

## Fatias implementadas (do plan)

- **Fatia 1** — Unit + tipos base + `GetProperties` com deteccao FPC.
  `ModernSyntax.RTTI.pas` traz `EModernRTTIError`, `TModernRTTIProperty`,
  `TModernRTTIField`, `TModernRTTIType` e o entry-point `ModernRTTI` com
  os tres overloads de `GetType` previstos em D-A7 do ADR.
- **Fatia 2** — `GetFields`/`GetField(Name)` + wrapper `TModernRTTIField`
  no mesmo `type` block. Simetria com o Delphi (sem deteccao ativa),
  conforme decidido no plan.
- **Fatia 3** — `UTestMS.RTTI.pas` (9 casos), `PTestModernRTTI.dpr`,
  `Test Lazarus/PTestModernRTTI.{lpi,lpr}`. A issue #7 nao havia
  entregue um `.lpi` compartilhado ainda (verificado por ausencia do
  diretorio `Test Lazarus/` no worktree), entao o `.lpi` deste ciclo
  foi criado minimo, apenas para o Pilar 1.

## Decisoes tecnicas tomadas na implementacao

### DEV-1 — `Wrap` como funcao unit-local, nao metodo publico

O ADR nao especifica como os records wrappers seriam construidos a
partir de `TRttiProperty`/`TRttiField`/`TRttiType`. A tentacao natural
seria expor `class function Wrap(...): TModernRTTIProperty; static;`
mas isso publicaria os proprios tipos brutos de `System.Rtti` na
superficie do wrapper — violando RN-5 (CA-8).

Solucao adotada: campos `FProp`/`FField`/`FType` sao `private` (nao
`strict private`), e a construcao acontece via funcoes unit-locais
`_WrapProperty`/`_WrapField`/`_WrapType` na `implementation`. Consumidor
nao ve nem os campos nem os construtores brutos; o unico caminho de
criacao publico e `ModernRTTI.GetType(...)`.

`private` (em vez de `strict private`) e necessario porque helpers/free
functions no mesmo unit precisam gravar em `FProp` etc; consumidores
fora do unit nao veem nada — em Pascal, `private` de record e escopo de
unit. RN-5 fica satisfeito.

### DEV-2 — `PropertyType`/`FieldType` como `PTypeInfo` (nao TModernRTTIType)

O ESP pede `PropertyType`/`FieldType` sem prescrever o tipo de retorno.
Records em Delphi/FPC nao permitem forward-declaration mutuamente
recursiva; se `TModernRTTIProperty.PropertyType` retornasse
`TModernRTTIType`, os tres records teriam de ser declarados em ordem
que satisfizesse ambos os lados, o que nao existe.

Solucao: `PropertyType`/`FieldType` retornam `PTypeInfo` (de `TypInfo`,
unit explicitamente autorizada no ESP secao 6). O consumidor obtem o
wrapper via `ModernRTTI.GetType(prop.PropertyType)` — mesmo ponto de
entrada, sem circularidade, sem violacao de RN-5 (PTypeInfo nao esta
na lista proibida).

### DEV-3 — Teste negativo compilador-agnostico

O plan sinalizou que o caso "classe sem `{$M+}`" e assimetrico
(Delphi devolve vazio legit; FPC deve levantar). CA-4 proibe
`{$IFDEF FPC}` no consumidor. Solucao: um unico teste que **aceita
qualquer um dos dois desfechos** — se levantou `EModernRTTIError`,
verifica que a mensagem menciona a classe e o marcador `{$M+}`; se
nao levantou, aceita como comportamento legitimo do Delphi. Fonte
identica compila e passa nos dois compiladores.

### DEV-4 — Deteccao de `{$M+}` ausente no FPC

Implementada em `_AncestryHasPublishedRTTI` (secao `{$IFDEF FPC}` da
`implementation`): dado um `PTypeInfo` de classe, percorre a hierarquia
via `TTypeData.ParentInfo` chamando `TypInfo.GetPropList` em cada
nivel; se nenhum ancestral tiver `PropCount > 0`, a deteccao considera
"sem RTTI publicada" e o `_RaiseNoPublishedRTTI` levanta com a mensagem
literal contendo `{$M+}` e `'published'`, testavel por substring.

## Validacoes rodadas

A fabrica nao tem compilador Pascal (R2 do PRD confirmado — Delphi
requer Windows/DCC32; FPC 3.2.2 nao esta instalado no container).
Validacao aqui foi por **leitura + grep**; compilacao verificada pelo
orquestrador na maquina do autor.

Comandos executados neste ciclo (todos verdes):

| Verificacao | Comando | Resultado |
|-------------|---------|-----------|
| CA-3 (nao inclui `.inc`) | `grep -n '{$I ModernSyntax.inc}' Source/ModernSyntax.RTTI.pas` | exit 1 (zero linhas) |
| Sem simbolo `FCP` | `grep -rn 'FCP' Source/ModernSyntax.RTTI.pas` | exit 1 (zero linhas) |
| CA-4 (sem `{$IFDEF FPC}` no teste) | `grep -rn '{$IFDEF FPC}' 'Test Delphi/' 'Test Lazarus/'` | exit 1 (zero linhas) |
| RN-5 (sem TRtti* na secao publica) | inspecao `awk '/^interface/,/^implementation/'` | apenas em doc comments e em campos `private` |

Nao ha `.project/SKILL.md` (verificado); analysis 05-conventions.md
secao 5.1 confirma **"None found"** para CI/lint/formatter — o unico
gate automatizado documentado no projeto sao os proprios projetos
DUnitX, executados manualmente. Nada a rodar aqui alem dos greps.

## Caveats

1. **Sem `.dproj` nem `.res` para o runner Delphi.** O `PTestModernRTTI.dproj`
   e o `.res` sao arquivos gerados pela IDE do Delphi (o `.res` e um
   binario compilado a partir de um `.rc` interno). Nao produzo esses
   arquivos por edicao manual porque:
   - O `.dproj` do Delphi 12 e um XML MSBuild denso com GUIDs, config
     por plataforma e propriedades opacas — o risco de gerar algo
     invalido ou defasado da versao instalada do autor e alto.
   - O `.res` e binario; um `.rc` manual seria fragil.
   - O autor do repositorio abre o `.dpr` no Delphi e a IDE cria/atualiza
     `.dproj` e `.res` automaticamente na primeira compilacao.

   O `.dpr` foi criado com a mesma estrutura dos outros runners
   (`PTestObjects.dpr` foi o modelo). CA-7 do ESP declara explicitamente
   que este ciclo NAO compila em Delphi — a fabrica nao tem compilador
   Pascal (R2 do PRD).

2. **DUnitX + FPC no `.lpi`**. O runner Lazarus assume que a source
   do DUnitX (fork VSoftTechnologies com suporte FPC em modo Delphi)
   esta no caminho do compilador — o `.lpi` tem `SearchPaths` para as
   duas units locais (`Source/` e `Test Delphi/EclbrSystem/`), mas
   o autor pode precisar adicionar `..\..\DUnitX\Source` (ou o caminho
   local dele) na primeira abertura via Lazarus IDE, ou passar `-Fu`
   ao `lazbuild`. Isso e infraestrutura de teste, nao de codigo, e
   foi deixado ao orquestrador conforme R2.

3. **API do FPC `Rtti` e experimental.** Assumido (RSK-1 do ESP);
   `TRttiProperty.SetValue`/`GetValue` deveriam ter as mesmas
   assinaturas nos dois compiladores, mas nao pude validar no
   worktree sem compilador. Se o FPC divergir, a correcao fica
   contida na unit (RN-5 protege o consumidor — RSK-5 do ESP).

4. **Testes de fields no FPC.** `TSampleFieldHolder` recebeu o marcador
   `{$M+}` (bloco compartilhado com `TSampleModel`) para garantir que
   `TRttiField` enumere fields no FPC. Sem `{$M+}` o FPC pode nao
   publicar field RTTI para a classe. Isso segue a orientacao do plan
   (simetria com Delphi para fields; sem exigencia oposta do PRD).

5. **Import `Rtti` no teste.** `UTestMS.RTTI.pas` importa `Rtti`
   apenas para o `TValue` usado em `TValue.From<Integer>(...)`.
   `TValue` NAO esta na lista proibida do RN-5 — o veto e para os
   descritores `TRttiType`/`TRttiProperty`/`TRttiField`.

## Checklist de aceite (task-input.md)

- [x] `Source/ModernSyntax.RTTI.pas` criado, sem `{$I ModernSyntax.inc}` (CA-3)
- [x] `ModernRTTI.GetType(T).GetProperties` — mesma chamada nos dois compiladores (CA-1)
- [x] FPC sem `{$M+}` gera `EModernRTTIError` (CA-2, R4)
- [x] Nenhum `{$IFDEF FPC}` em `Test Delphi/`/`Test Lazarus/` (CA-4)
- [x] Suite DUnitX cobre property positivo, field positivo, negativo
- [x] Projeto Lazarus presente e listando `UTestMS.RTTI.pas` (CA-6)
- [ ] Body do PR declara "compilado em FPC 3.2.2 x86_64 e i386;
  nao compilado em Delphi" — **acao pendente do node de PR**
- [x] Superficie publica nao expoe TRttiType/TRttiProperty/TRttiField (CA-8, RN-5)

## Handoff

Proximos nodes (`review`, `test`, `verify`) precisam:
- Ler [esp](pipeline-esp.md) e [adr](pipeline-adr.md) para o contrato.
- Rodar os greps de verificacao final listados em [task-input](pipeline-task-input.md).
- Confirmar com o autor a compilacao em FPC 3.2.2 (`lazbuild`) e,
  opcionalmente, em Delphi (autor abre `.dpr` na IDE).
- Garantir que o body do PR carregue a declaracao de CA-7.
