---
type: implement-report
kind: artifact
title: "IMPLEMENT-REPORT — issue #56: Attributes herda contrato de nil-handle da #49"
description: "Slice unico entregue: guarda de nil em PropAttributes (Source/ModernSyntax.RTTI.pas), uniformizacao dos cinco blocos existentes de Scenario_NilHandle_AllMembers_Raises (Pos → igualdade estrita + mensagem de Fail padronizada) e sexto bloco (Attributes) apos o quinto (Test Shared/EclbrSystem/UScenarios.RTTI.pas); SModernRTTINilHandle promovida ao interface para permitir Format(SModernRTTINilHandle, ...) no cenario compartilhado (friction anotada em FLOW-FEEDBACK); build FPC 3.2.2 x86_64 verde, 42 testes/0 falhas/0 erros, TestNilHandle_AllMembers_Raises presente."
status: stable
cycle: "021"
agent: developer
workflow: equipe-bug
node: implement
resource: aefos://run/09743779c7c9860b5fa380f6979d94ca
tags: [implement, issue-56, nil-handle, modernrtti, rtti, attributes, fpc, bug]
generated:
  by: "equipe-bug@node:implement"
  at: "2026-09-02T16:20:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — issue #56"
  - id: adr
    resource: "adr.md"
    title: "ADR — issue #56"
  - id: plan
    resource: "plan.md"
    title: "PLAN — issue #56"
  - id: task-input
    resource: "task-input.md"
    title: "TASK-INPUT — issue #56"
---

# IMPLEMENT-REPORT — Issue #56 (`Attributes` — resíduo do nil-handle)

## 1. O que foi feito

Slice unico entregue, respeitando o plano ([plan](pipeline-plan.md)) e o ADR
([adr](pipeline-adr.md)):

1. **Guarda de nil em `PropAttributes`** — inserida como primeira
   instrucao visivel do corpo, antes do comentario `// Issue #27:`
   (D-56.1 do ADR).
2. **Uniformizacao dos cinco blocos existentes** em
   `Scenario_NilHandle_AllMembers_Raises` — trocado `Pos(...)` por
   igualdade estrita nos seis (D-56.2) e reescrita a mensagem do `Fail`
   para `'Mensagem de X incorreta: "%s"'` (D-56.3).
3. **Sexto bloco (`Attributes`)** — appendado apos o quinto bloco em
   ordem cronologica (D-56.4).
4. **Ajuste operacional necessario para o passo 2** — a `resourcestring
   SModernRTTINilHandle` estava em `implementation`; foi promovida ao
   `interface` de `ModernSyntax.RTTI.pas` para que o cenario possa
   compilar `Format(SModernRTTINilHandle, ['<nome>'])`. Sem esse
   movimento o padrao especificado no ESP/ADR nao compila. Documentado
   em [FLOW-FEEDBACK](FLOW-FEEDBACK.md).

Tudo em um unico commit (D-56.5) — pendente ao committer.

## 2. Arquivos modificados

| Arquivo | Mudanca | Linhas |
|---------|---------|--------|
| `Source/ModernSyntax.RTTI.pas` | Guarda `if FType = nil then raise EModernRTTIError.CreateFmt(SModernRTTINilHandle, ['Attributes']);` como primeira instrucao de `PropAttributes` | +2 no corpo (linhas ~1126-1127) |
| `Source/ModernSyntax.RTTI.pas` | Promocao de `SModernRTTINilHandle` de `resourcestring` de `implementation` para `resourcestring` de `interface` (com XMLDoc explicando a exposicao) | +11 no interface (bloco novo apos `EModernRTTIError`), -2 em implementation |
| `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | Uniformizacao dos cinco blocos (`Name`, `GetProperties`, `GetFields`, `GetMethods`, `GetMethod`): `Pos → <>` + reescrita da mensagem do `Fail` | 5 blocos × 2 linhas alteradas |
| `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | Sexto bloco (`Attributes`) inserido apos o quinto, antes do `end;` do procedimento | +17 |
| `.project/project-evolution.md` | Marker do ciclo 021 flipado de `in-pipeline` para `in-review` | 1 linha |

**Nao mudou:** cascas de teste FPC/Delphi (o cenario compartilhado ja e
delegado em uma linha por cada casca, e o sexto bloco entra automaticamente
pela chamada existente — convencao D-7 "um cenario, duas cascas").

## 3. Decisoes tecnicas encontradas na implementacao

### 3.1 Promocao de `SModernRTTINilHandle` ao `interface`

**Situacao:** o ESP/ADR/plan pedem `Format(SModernRTTINilHandle, ['<nome>'])`
no cenario compartilhado, mas a `resourcestring` estava em `implementation`
(linhas 892-893 originais) — invisivel ao consumidor. O build FPC
retornou seis erros `Identifier not found "SModernRTTINilHandle"` no
primeiro rebuild.

**Escolha:** promover apenas essa `resourcestring` para o `interface`
(bloco novo apos `EModernRTTIError`), deixando as outras strings
privadas no bloco de `implementation`. Justificativa:

- E a mensagem que o cenario compartilhado agora compara por igualdade
  estrita (D-56.2/D-56.3) — passou a ser contrato observavel, nao
  detalhe interno.
- Reduz a mudanca de superficie ao minimo (uma string, com XMLDoc que
  explica por que foi promovida).
- Preserva a intencao do ESP ("nenhuma `resourcestring` nova") — nao
  foi criada string nova, apenas mudou o escopo de uma existente.

**Alternativas descartadas:**

- Repetir o literal `'handle nao inicializado...'` no cenario — quebra
  a fonte unica de verdade; qualquer edicao futura da mensagem exige
  editar dois lugares (o oposto da uniformidade que D-56.2/D-56.3
  procuram).
- Deixar `Pos(...)` no lugar — contradiz D-56.2 (uniformidade dos seis
  blocos) e D-56.3 (mensagem de `Fail` correspondente).

Anotado em `FLOW-FEEDBACK.md` como friction do pipeline: o ADR/ESP
podiam ter previsto essa consequencia; o node de architect nao tinha
como confirmar isso sem tentar compilar.

### 3.2 Ramo `else Result := nil` intacto

Preservado exatamente como estava — vazio legitimo para handle valido
nao-classe (record, enum). Confirma B-56.2 do ESP e o padrao herdado do
`GetFields` da #49.

### 3.3 Estrutura final de `PropAttributes`

```pascal
function TModernRTTITypeHelper.PropAttributes: TArray<TObject>;
begin
  if FType = nil then
    raise EModernRTTIError.CreateFmt(SModernRTTINilHandle, ['Attributes']);
  // Issue #27: alias para a coleção ja existente do Pilar 2. Delega direto
  // — a fusao nativa+registrada (Delphi) e a copia de `Owned` (FPC) vivem
  // dentro de `ModernAttributes.GetAttributes`. Nenhum estado novo aqui.
  if (FType is TRttiInstanceType) then
    Result := ModernAttributes.GetAttributes(TRttiInstanceType(FType).MetaclassType)
  else
    Result := nil;
end;
```

Uniforme com os outros cinco membros: guarda primeiro, comentario
`// Issue #27:` colado ao `if (FType is TRttiInstanceType)`, ramo
`else` intacto.

## 4. Validacoes executadas (comandos de qualidade rodados)

Descoberta em `.project/SKILL.md` (secao "Toolchain & quality
commands", ja registrada, marcada agent-discovered 2026-08-28): comando
canonico para FPC x86_64.

```bash
rm -rf /tmp/fpcbuild && mkdir -p /tmp/fpcbuild
fpc -Mdelphi \
    -Fu"Source" -Fu"Test Shared/EclbrSystem" -Fu"Test FPC/EclbrSystem" \
    -FU/tmp/fpcbuild -FE/tmp/fpcbuild \
    "Test FPC/EclbrSystem/PTestRTTI.lpr"
/tmp/fpcbuild/PTestRTTI --all -a --format=plain
```

**Resultado:**

- Compilacao: 4621 linhas, 1.2s, 10 warnings (todos pre-existentes:
  `Rtti` experimental, `managed type not initialized` em pontos
  historicos, `unreachable code` em `ModernSyntax.Invoker`) e 6 notes
  (todas pre-existentes de `generics.collections`).
- Testes: **42 rodados, 0 erros, 0 falhas.** `TestNilHandle_AllMembers_Raises`
  presente na lista e passou.
- Baseline nao-regressao: `TestAttributes_ForIn_IteratesAttributes`
  continua verde — exercicio de `Attributes` sobre handle valido de
  classe funciona; e `TestRecordType_NameAndSize` (record valido nao-classe)
  continua verde — o ramo `else Result := nil` segue devolvendo vazio.

## 5. Fronteira do ciclo (para o PR)

**O ciclo rodou apenas FPC x86_64** no container (unico toolchain
disponivel na fabrica — `ppc386` retorna `error code: 127`;
`/usr/lib/fpc/3.2.2/units/i386-linux` nao existe; `dcc32` ausente).
Os alvos FPC i386, Delphi Win32 e Delphi Win64 ficam com o mantenedor
antes do merge (D-56.6 do ADR, padrao herdado da serie #43–#49).

Committer deve incluir literalmente no PR:

> *"ciclo rodou FPC x86_64 no container (compila e roda). i386 e os 4
> alvos Delphi nao foram executados nesta fabrica — ficam com o
> mantenedor antes do merge."*

Secao propria (nao nota de rodape):

> *"Acceptance item 'dois compiladores × dois bitness': o ciclo cobre
> 1 de 4 (FPC x86_64). Os 3 restantes (FPC i386, Delphi Win32, Delphi
> Win64) exigem toolchain ausente da fabrica e ficam com o mantenedor.
> Padrao herdado da serie #43–#49."*

## 6. Caveats

- **Superficie publica cresceu por uma `resourcestring`.** A mensagem
  `SModernRTTINilHandle` agora e observavel de fora da unit. Isso
  formaliza o contrato de erro que o cenario ja verifica por igualdade
  estrita. Reversao futura exigiria voltar tanto a string quanto os
  seis blocos de assert para `Pos(...)` ou para literal duplicado.
- **`resourcestring` no `interface` esta em bloco proprio.** Nao havia
  bloco de `resourcestring` no `interface` de `ModernSyntax.RTTI.pas`
  antes; o `type` seguinte foi reaberto com um novo `type` keyword —
  esta correto em Pascal (multiplos blocos alternando).
- **Nenhum sabor de compilador i386/Delphi provado.** Ver §5 (fronteira
  declarada). A guarda e Pascal puro, mesma sintaxe nos dois alvos.

## 7. Referencias cruzadas

- Spec e escopo: [esp](pipeline-esp.md)
- Decisoes acordadas: [adr](pipeline-adr.md)
- Slice: [plan](pipeline-plan.md)
- Handoff: [task-input](pipeline-task-input.md)
- Board local: [project-evolution](../../../project-evolution.md)
- Toolchain: [SKILL](../../../SKILL.md)
