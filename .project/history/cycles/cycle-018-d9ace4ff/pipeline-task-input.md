---
type: task-input
kind: artifact
title: "TASK-INPUT — Implementar TModernRTTIRecordType Name + Size nos dois compiladores, duas fixtures obrigatorias, helper RecordRaiseWrongKind (issue #45)"
description: "Handoff operacional para o implementador: record publico TModernRTTIRecordType em ModernSyntax.RTTI.pas (FToken PTypeInfo, FromTypeInfo sem guarda de Kind, Name, Size — e nada mais); backend FPC com RecordTypeName (string(P^.Name)) e RecordTypeSize (GetTypeData(P)^.RecSize), resourcestring SRecordWrongKind, helper RecordRaiseWrongKind guardando so nil/Kind; backend Delphi com paridade, LCtx local com try/finally em RecordTypeName delegando a TRttiRecordType, GetTypeData(P)^.RecSize em RecordTypeSize (sem contexto), texto de erro identico ao FPC; DUAS fixtures obrigatorias (TRecordFixture45 unmanaged + TRecordFixture45M managed); um cenario compartilhado com QUATRO asserções (Name+Size por fixture), so por igualdade; uma procedure em cada casca; XMLDoc do record traz a frase-verbatim do acceptance; abrir issue-filha de GetFields FORA do commit."
status: draft
cycle: "018"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/d9ace4ff9a3af56be91a8f0373cb9475
tags: [modernrtti, task-input, issue-45, fpc, delphi, record, feature]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-09-02T00:00:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — TModernRTTIRecordType (issue #45)"
  - id: adr
    resource: "adr.md"
    title: "ADR — TModernRTTIRecordType (issue #45)"
  - id: plan
    resource: "plan.md"
    title: "PLAN — TModernRTTIRecordType em 3 slices (issue #45)"
  - id: skill
    resource: "/SKILL.md"
    title: "SKILL — receita FPC, traps"
---

# TASK-INPUT — issue #45 (TModernRTTIRecordType)

## Titulo (para commit / PR)

`feat(rtti): TModernRTTIRecordType com Name + Size nos dois compiladores (Closes #45, parte de #29)`

## Tipo / labels

- Tipo: `feature`
- Labels sugeridos: `enhancement`, `rtti`, `fpc`, `delphi`
- Milestone / parent: `Parte de #29`
- Fecha: `Closes #45`

## Escopo (o que muda, arquivo por arquivo)

| Arquivo | Natureza | Delta |
|---|---|---|
| `Source/ModernSyntax.RTTI.FPC.pas` | edicao | +2 declaracoes na `interface` (apos :123), +1 `resourcestring` (bloco apos `SPointerWrongKind`), +1 helper `RecordRaiseWrongKind` na `implementation` (apos :586, antes de `// --- Context`), +2 corpos (`RecordTypeName`, `RecordTypeSize`) |
| `Source/ModernSyntax.RTTI.Delphi.pas` | edicao | +2 declaracoes na `interface` (apos :101), +1 `resourcestring` local (texto identico ao FPC), +1 helper `RecordRaiseWrongKind` na `implementation` (apos :481), +2 corpos (`RecordTypeName` com `LCtx` local + `try/finally`; `RecordTypeSize` com `GetTypeData` direto sem contexto) |
| `Source/ModernSyntax.RTTI.pas` | edicao | +record `TModernRTTIRecordType` (apos :680, antes do `///` de :682); XMLDoc do record com frase-verbatim do acceptance; +3 corpos na `implementation` (`FromTypeInfo`, `Name`, `Size`); zero `{$IFDEF}` novo |
| `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | edicao | +2 fixtures publicas (`TRecordFixture45`, `TRecordFixture45M`) apos :199, +1 declaracao (apos cenarios #44), +1 implementacao (`Scenario_RecordType_NameAndSize`) com 4 asserções |
| `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` | edicao | +1 procedure `[Test]` (apos :149), corpo de uma linha |
| `Test FPC/EclbrSystem/UTestMS.RTTI.pas` | edicao | +1 procedure `published` (apos :89), corpo de uma linha |

**Nenhum arquivo novo. Nenhum arquivo removido.**

## Checklist de aceitacao (14 itens)

- [ ] `TModernRTTIRecordType` declarado apos `TModernRTTIPointerType`
      (:680), com `strict private FToken: PTypeInfo`, `FromTypeInfo`,
      `Name`, `Size` — **e nada mais**.
- [ ] XMLDoc `///` do record contem a frase-verbatim do acceptance:
      *"esta entrega cobre `Name` e `Size` apenas; `GetFields` fica para
      issue propria condicionada a medir `TRecordElement.Name` num FPC
      vivo"*.
- [ ] `FromTypeInfo` **nao** valida `Kind` (padrao consagrado
      D-1/D-43.1). Apenas `Result.FToken := P`.
- [ ] Backend FPC: `RecordTypeName` e `RecordTypeSize` declaradas na
      `interface` (apos :123); implementadas apos `PointerTypeReferredType`
      (apos :586), antes de `// --- Context`.
- [ ] Backend FPC: `resourcestring SRecordWrongKind` adicionado apos
      `SPointerWrongKind`.
- [ ] Backend FPC: helper `RecordRaiseWrongKind` com guarda
      `(P = nil) or (P^.Kind <> tkRecord)` — **sem** condicao sobre
      `Size`. Cada uma das duas funcoes livres chama o helper como
      primeira instrucao.
- [ ] Backend FPC: `RecordTypeName` retorna `string(P^.Name)`;
      `RecordTypeSize` retorna `GetTypeData(P)^.RecSize`.
- [ ] Backend Delphi: assinaturas espelhadas (`interface` apos :101);
      `resourcestring SRecordWrongKind` no bloco local com **texto
      identico** ao do FPC (D-2/D-43.6); helper `RecordRaiseWrongKind`
      com mesma guarda.
- [ ] Backend Delphi: `RecordTypeName` usa `LCtx: TRttiContext` **local**
      com `try/finally LCtx.Free`; corpo
      `Result := TRttiRecordType(LCtx.GetType(P)).Name;`. **Nao** usar
      `FContext` global.
- [ ] Backend Delphi: `RecordTypeSize` usa `GetTypeData(P)^.RecSize`
      direto (sem `TRttiContext`).
- [ ] `UScenarios.RTTI.pas`: **duas** fixtures publicas na secao `type`
      da `interface` apos `PInt44`:
      - `TRecordFixture45 = record FieldA, FieldB: Integer end;`
      - `TRecordFixture45M = record S: string; I: Integer end;`
      Ambas obrigatorias; **uma so nao passa** (D-45.4).
- [ ] `UScenarios.RTTI.pas`: `Scenario_RecordType_NameAndSize` com
      **quatro** asserções por igualdade (`Name`+`Size` por fixture),
      padrao de falha `raise ETestScenarioFailed.Create(...)`.
      **So igualdade** (`Size = SizeOf(T)`) — nao usar `>=`.
- [ ] Cascas FPC e Delphi cada uma com **uma unica** procedure publicada
      (`TestRecordType_NameAndSize`), corpo de uma linha delegando ao
      cenario compartilhado.
- [ ] Zero `{$IFDEF}` novo em `ModernSyntax.RTTI.pas`; zero
      `{$IFDEF FPC}` em `UScenarios.RTTI.pas` (CA-4, CA-5).
- [ ] Build FPC 3.2.2 x86_64 e i386 verdes (rodados pelo implementador,
      com `rm -rf /tmp/fpcbuild` antes de cada compilacao).
- [ ] PR body declara: `compiled on FPC 3.2.2 x86_64 e i386; Delphi
      23.0/37.0 x Win32/Win64 compilado pelo Diretor` (nao "assumido");
      fecha `Closes #45`; mantem `Parte de #29`.

## Fora do commit da entrega (obrigatorio, apos merge)

- [ ] Abrir issue-filha *"`TModernRTTIRecordType.GetFields`: medir
      `TRecordElement.Name` no FPC 3.2.2 antes de entregar"* com labels
      `enhancement`, `rtti`, `fpc`, `blocked:medicao`. Descricao carrega
      o caveto:
      > `ManagedFldCount` **nao** vale para `tkRecord` puro. Medicao no
      > FPC: `TPlain` (zero campos managed) devolve
      > `ManagedFldCount = 2`. Leitura da uniao do `TTypeData`, mesma
      > familia de bug do `ElType` (#29) e do `RefTypeRef` (#44).
      >
      > Bloqueio para entregar: medir `TRecordElement.Name` num FPC
      > 3.2.2 vivo (limitacao F-3 do estudo). Sem medicao, nao entregar.

## Convencoes obrigatorias

- **CA-4 / D-1 / D-25.1** — nenhum `{$IFDEF}` novo em
  `Source/ModernSyntax.RTTI.pas` (declaracao ou implementacao).
  `resourcestring` de guarda vive no backend, nao na unit publica.
- **D-2 / D-43.6** — paridade de assinatura entre
  `ModernSyntax.RTTI.FPC.pas` e `ModernSyntax.RTTI.Delphi.pas`; texto
  do `SRecordWrongKind` **identico**.
- **D-4** — guarda por `Kind` no ponto de uso; aqui centralizada em
  `RecordRaiseWrongKind` (padrao `EnumRaiseWrongKind`
  `Source/ModernSyntax.RTTI.FPC.pas:473`).
- **CA-5** — nenhum `{$IFDEF FPC}` em teste.
- **D-5** — fixture com `TypeInfo()` na secao `type` da `interface` de
  `UScenarios.RTTI.pas`.
- **D-7** — "um cenario, duas cascas".
- **Prefixos:** `T` tipo/record, `A` parametros, `L` locais.
- **XMLDoc `///`** em todos os membros publicos novos.
- **`rm -rf /tmp/fpcbuild`** antes de cada compilacao (SKILL trap #2).
- **Nunca `Assert`; nunca `raise Exception` generica.** Usar
  `raise ETestScenarioFailed.Create(...)` em teste;
  `raise EModernRTTIError.Create(...)` em backend.
- **Piso Delphi 23.0** — **nao** adicionar `{$IF CompilerVersion >= ...}`.

## Provaveis pontos de fricao (dicas do arquiteto)

- **Fixture unica e a armadilha maior.** Se o implementador achar
  "duas fixtures e overkill" e simplificar para `TRecordFixture45`
  sozinho, a asserção `Size = SizeOf(TRecordFixture45)` passa por
  **coincidencia** — a constante 8 casa nos seis alvos. **Regra:** as
  duas fixtures **sempre** entram; a managed e a que prova leitura de
  layout. Ver [`adr.md`](pipeline-adr.md) §D-45.4.
- **Tentacao de rejeitar `record end` (Size = 0).** `record end` e um
  record valido nos seis alvos, com `Size = 0`. Nao adicionar
  `if GetTypeData(P)^.RecSize = 0 then raise...`. Ver [`adr.md`](pipeline-adr.md)
  §D-45.8.
- **`ManagedFldCount` mente para `tkRecord`.** Medido:
  `TPlain` (zero campos managed) retorna `ManagedFldCount = 2`. **Nao
  usar** esse campo para derivar nada em record puro. E leitura da
  uniao. Se aparecer no seu codigo, revisar. Caveto vai na descricao da
  issue-filha; nao volta como pull deste ciclo.
- **`FContext` global no Delphi e ceremonia morta.** Padrao do backend
  Delphi ja e `LCtx` local com `try/finally` (`EnumMinValue` :364-377).
  Se autocompletar sugerir `FContext.GetType(P)`, ignorar.
- **`RecordTypeSize` no Delphi nao cria contexto.** Use
  `GetTypeData(P)^.RecSize` direto — mais barato, paridade objetiva com
  o FPC. Se voce escrever `TRttiRecordType(FContext.GetType(P)).TypeSize`,
  compila mas leva contexto onde ele nao precisa estar.
- **Texto do `SRecordWrongKind` tem que casar byte a byte.** Copiar-colar
  do FPC para o Delphi (nao redigitar). Se divergir, D-2/D-43.6 quebra
  em silencio e testes de guarda futuros ficam fragilizados.
- **Uma so procedure publicada por casca.** Nao criar `Test_*_Name` e
  `Test_*_Size` separadas — uma so `TestRecordType_NameAndSize`, com
  quatro asserções internas. Se voce quebrar em duas, D-7 ("um cenario,
  duas cascas") passa a ler "dois cenarios, quatro cascas", que e ruido.
- **Ordem dos arquivos.** Fazer backends primeiro (slice 1), depois
  casca publica (slice 2), depois testes (slice 3). Ordem inversa
  polui o backend com dependencia de tipo que ainda nao existe.
- **`rm -rf /tmp/fpcbuild` antes de cada `make`/`fpc`.** SKILL trap #2.
  Sem isso, `.ppu` stale do ciclo anterior faz o FPC reportar verde
  em cima de codigo antigo — falso positivo classico.

## Fontes

- [esp](pipeline-esp.md) — especificacao formal.
- [adr](pipeline-adr.md) — nove decisoes derivadas do relatorio de investigacao.
- [plan](pipeline-plan.md) — tres slices com codigo de referencia.
- [/SKILL.md](/SKILL.md) — receita FPC, traps.
- [/analysis/05-conventions.md](/analysis/05-conventions.md) — D-1,
  D-2, D-4, D-25.1, CA-5.
