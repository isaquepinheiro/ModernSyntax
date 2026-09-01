---
type: implement-report
kind: artifact
title: "IMPLEMENT-REPORT — TModernRTTIEnumerationType (issue #43)"
description: "Implementacao entregue conforme plan/adr: casca publica com record + fabrica + seis metodos que delegam; backend FPC com seis funcoes livres, guards por Kind, guards M-1 (faixa em GetName) e M-2 (raise em GetValue com -1), tres resourcestring novas; backend Delphi com paridade de assinatura e guards espelhados; fixtures TCor+TDia e quatro cenarios compartilhados; quatro metodos published (FPC) e [Test] (Delphi); PTestRTTI compila FPC x86_64 verde (34/34); mutacao MaxValue-1 provada vermelha (Length=6 esperado 7) e revertida verde."
status: stable
cycle: "016"
agent: developer
workflow: equipe-feature
node: implement
resource: aefos://run/9ac0699c1b65c18950220f022dfbb179
tags: [modernrtti, implement-report, issue-43, fpc, delphi, enumeration]
generated:
  by: "equipe-feature@node:implement"
  at: "2026-09-01T00:00:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — issue #43"
  - id: adr
    resource: "adr.md"
    title: "ADR — issue #43"
  - id: plan
    resource: "plan.md"
    title: "PLAN — issue #43 em 3 slices"
  - id: task-input
    resource: "task-input.md"
    title: "TASK-INPUT — issue #43"
---

# IMPLEMENT-REPORT — issue #43 (TModernRTTIEnumerationType)

## Resumo

Implementadas as 3 slices do [plan](pipeline-plan.md) em uma unica passada:

1. **Casca publica** (`Source/ModernSyntax.RTTI.pas`) — declarado
   `TModernRTTIEnumerationType` com `strict private FToken: PTypeInfo`,
   `class function FromTypeInfo` que **nao valida `Kind`** (D-43.1) e seis
   metodos que delegam direto ao backend (`EnumName`, `EnumMinValue`,
   `EnumMaxValue`, `EnumGetName`, `EnumGetValue`, `EnumGetNames`). XMLDoc
   `///` em cada membro publico com o contrato de erros (CA-14).
2. **Backend FPC** (`Source/ModernSyntax.RTTI.FPC.pas`) — seis funcoes
   livres em novo grupo `// --- Enumeration (issue #43) ---`. Cada funcao
   abre com `if (P = nil) or (P^.Kind <> tkEnumeration) then
   EnumRaiseWrongKind(P);` (D-4/D-43.2). `EnumGetName` valida
   `[MinValue..MaxValue]` antes de `TypInfo.GetEnumName` (D-43.3, M-1).
   `EnumGetValue` captura `TypInfo.GetEnumValue` e levanta em `-1`
   (D-43.4, M-2). Tres `resourcestring` novas no bloco existente
   (`SEnumWrongKind`, `SEnumOrdinalOutOfRange`, `SEnumNameUnknown`) —
   D-43.5.
3. **Backend Delphi** (`Source/ModernSyntax.RTTI.Delphi.pas`) — seis
   funcoes com **paridade estrita de assinatura** (D-2/D-43.6). Guards
   de M-1/M-2 espelhados **antes** de delegar a `TRttiEnumerationType`
   via `TRttiContext` local. Bloco `resourcestring` novo criado neste
   backend (nao existia — a unit so tinha delegacao pura); as tres
   constantes duplicadas com texto identico ao do FPC para paridade de
   mensagem.
4. **Cenarios compartilhados** (`Test Shared/EclbrSystem/UScenarios.RTTI.pas`)
   — `TypInfo` adicionado a `uses` da `interface` (nao estava presente);
   `TCor = (cA, cB, cC)` e `TDia = (dSeg..dDom)` declarados no `type` da
   `interface` apos `TColor`. Quatro procedures:
   `Scenario_EnumerationType_NameAndBounds`,
   `Scenario_EnumerationType_GetNameGetValue`,
   `Scenario_EnumerationType_GetNames_LengthAndPresence`,
   `Scenario_EnumerationType_OutOfRangeAndUnknownRaises`. Todas sobre
   `TDia` (7 elementos — D-43.7/M-4 para matar a mutacao). Zero
   `{$IFDEF}` (CA-5 do repo). `Fail(...)` sempre; nunca `Assert`. O
   cenario negativo tem **tres afirmacoes independentes** com
   `try/except on EModernRTTIError do; ... Fail(...)`.
5. **Cascas de teste** — quatro `published` em `Test FPC/EclbrSystem/UTestMS.RTTI.pas`
   e quatro `[Test]` em `Test Delphi/EclbrSystem/UTestMS.RTTI.pas`, mesmos
   nomes, cada metodo chamando o cenario correspondente (linha unica).

## Arquivos modificados

| Arquivo | Natureza | Detalhe |
|---------|----------|---------|
| `Source/ModernSyntax.RTTI.pas` | edicao | `TModernRTTIEnumerationType` record com XMLDoc + implementacoes; **zero `{$IFDEF}` novo** (CA-6) |
| `Source/ModernSyntax.RTTI.FPC.pas` | edicao | seis funcoes livres + tres `resourcestring` + helper `EnumRaiseWrongKind` |
| `Source/ModernSyntax.RTTI.Delphi.pas` | edicao | seis funcoes livres com guards espelhados + bloco `resourcestring` novo (nao existia neste backend) + helper `EnumRaiseWrongKind` |
| `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | edicao | `TypInfo` em `uses` da `interface`, `TCor` + `TDia` no `type`, quatro procedures compartilhadas |
| `Test FPC/EclbrSystem/UTestMS.RTTI.pas` | edicao | quatro `published` chamando os cenarios |
| `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` | edicao | quatro `[Test]` chamando os cenarios |
| `.project/project-evolution.md` | edicao | flip do ciclo 016 para `🔄 in-review` |

Nenhum arquivo novo, nenhum arquivo removido.

## Decisoes tecnicas durante a implementacao

- **Helper `EnumRaiseWrongKind`.** Cada uma das seis funcoes abre com a
  guarda literal `if (P = nil) or (P^.Kind <> tkEnumeration) then
  EnumRaiseWrongKind(P);` — respeitando D-4/D-43.2 (guarda por metodo).
  O helper NAO e a guarda: e apenas a construcao da mensagem, que precisa
  distinguir `P = nil` (nome `'<nil>'`, kind 0) de `P` nao-nil mas Kind
  errado (nome real, Kind real). Sem o helper, cada funcao teria seis
  linhas de `raise` duplicadas.
- **Backend Delphi acessa `TRttiEnumerationType` via `TRttiContext` local.**
  `TModernRTTI.FContext` esta em `private` (nao `strict private`), mas
  `private` sem `strict` limita visibilidade a **unit** da declaracao —
  o backend Delphi mora em outra unit, entao nao pode ler `FContext`.
  Padrao ja usado em `FieldEnumerate`/`MethodEnumerate` do mesmo backend:
  criar `LCtx := TRttiContext.Create` local. `TRttiContext.Create` no
  Delphi partilha pool global; nao ha custo real de criar/liberar.
- **Bloco `resourcestring` novo no backend Delphi.** Este backend nunca
  teve `resourcestring` antes — toda sua logica era delegacao pura ao
  `TRttiField/TRttiMethod`. Como D-43.6 exige guards espelhados com
  mensagens identicas ao FPC, criei o bloco `resourcestring` na
  `implementation` (imediatamente apos `implementation` e antes do
  primeiro grupo `// --- TValueOps ---`). Padrao vigente do repo: cada
  backend tem seu proprio bloco.
- **`EnumGetName` no backend Delphi usa `TypInfo.GetEnumName` para o
  retorno.** Poderia usar `LType.GetNames[AOrdinal - LType.MinValue]`
  do `TRttiEnumerationType`, mas `TypInfo.GetEnumName(P, AOrdinal)` da
  o mesmo resultado sem construir array intermediario. O `LType` do
  Delphi e usado APENAS para ler `MinValue`/`MaxValue` do guard.

## Validacoes executadas (comandos de qualidade)

Toolchain per `.project/SKILL.md` (§"Toolchain & quality commands"): FPC
3.2.2 na fabrica (nao ha `lazbuild`, nao ha cross-compiler i386, Delphi
fica com o autor).

### Compilacao + execucao (verde)

```
rm -rf /tmp/fpcbuild && mkdir -p /tmp/fpcbuild
fpc -Mdelphi \
    -Fu"Source" -Fu"Test Shared/EclbrSystem" -Fu"Test FPC/EclbrSystem" \
    -Fi"Test Shared/EclbrSystem" \
    -FU/tmp/fpcbuild -FE/tmp/fpcbuild \
    -o/tmp/fpcbuild/PTestRTTI \
    "Test FPC/EclbrSystem/PTestRTTI.lpr"
/tmp/fpcbuild/PTestRTTI --all -a --format=plain
```

Resultado:

```
Number of run tests: 34
Number of errors:    0
Number of failures:  0
```

Os 30 testes preexistentes seguem verdes; os quatro novos
(`TestEnumerationType_NameAndBounds`, `TestEnumerationType_GetNameGetValue`,
`TestEnumerationType_GetNames_LengthAndPresence`,
`TestEnumerationType_OutOfRangeAndUnknownRaises`) sao verdes.

### Mutacao de sanidade obrigatoria (D-43.8 / CA-12)

**Diff aplicado** em `Source/ModernSyntax.RTTI.FPC.pas`, `EnumGetNames`:

```diff
-  LMax := LTD^.MaxValue;
+  LMax := LTD^.MaxValue - 1;  // MUTACAO temporaria D-43.8
```

**Executado** com `rm -rf /tmp/fpcbuild` antes (SKILL Trap #2). Log
vermelho:

```
List of errors:
  Error:
    Message:           TTestModernRTTI.TestEnumerationType_GetNames_LengthAndPresence:
                       GetNames devolveu 6 nomes; esperado exatamente 7 para TDia
    Exception class:   ETestScenarioFailed
    Exception message: GetNames devolveu 6 nomes; esperado exatamente 7 para TDia
```

Exatamente o cenario esperado (`GetNames_LengthAndPresence`) — e nao
outros: o `Length=6` mata este porque a fixture `TDia` tem 7 elementos
(off-by-one no fim ficaria verde com `TCor` de 3 elementos — M-4).

**Reverti** e recompilei com `rm -rf`; suite volta a 34/34 verde.

### Nao compilado

- **FPC i386** — cross-compiler ausente na fabrica (`ppc386` = 127).
  Validacao i386 permanece com o autor humano (SKILL §Toolchain).
- **Delphi (dcc32/bcc32)** — Delphi nao esta disponivel na fabrica
  Aefos. Compilacao Delphi permanece com o autor.

Ambas as ausencias sao **conhecidas e documentadas** em `.project/SKILL.md`
(§"agent-discovered 2026-08-28"). O PR body vai declarar explicitamente:
"compilado em FPC 3.2.2 x86_64; nao compilado em i386 (cross ausente);
nao compilado em Delphi neste ambiente" (SKILL §"What a PR must declare").

## Caveats

- **Cross-bitness i386**: o CA-13 do ESP pede "compila FPC 3.2.2 nos
  dois bitness". A fabrica so tem x86_64; o autor deve validar i386
  antes do merge (mesmo perfil do ciclo 015).
- **Delphi**: os quatro cenarios sao portaveis por construcao (zero
  `{$IFDEF}`), mas nao executados aqui. Se o guarda de M-1 no Delphi
  ficar "morto" porque `TRttiEnumerationType.GetName(-1)` do Delphi ja
  levantar por conta propria, o cenario negativo continua verde no
  Delphi (o esperado e um raise; nao importa quem o levantou). O guarda
  espelhado esta la para paridade por construcao (D-43.6): a mutacao
  `MaxValue-1` funciona tambem no Delphi.
- **`TypInfo.GetEnumName`** no backend Delphi: usei a funcao livre do
  `TypInfo` em vez de `TRttiEnumerationType.GetNames`. Ambas devolvem
  o mesmo nome; a funcao livre nao aloca `TArray<string>` intermediario.

## Convencoes verificadas

- **CA-1..CA-11** — todos verificados na implementacao (declaracao com
  `strict private FToken: PTypeInfo`, fabrica sem guarda de `Kind`, seis
  funcoes com guarda, guards de M-1/M-2 nos dois backends, cenarios com
  fixture `TDia`, tres afirmacoes independentes no negativo).
- **CA-12** — mutacao executada e documentada (vermelho + revert +
  verde).
- **CA-13** — parcial: compila FPC 3.2.2 **x86_64** verde; i386 e Delphi
  ficam com o autor (declarado explicitamente).
- **CA-14** — XMLDoc `///` em cada membro publico novo declarando o
  contrato de erros.

## Referencias

- Spec: [esp](pipeline-esp.md)
- Decisao: [adr](pipeline-adr.md)
- Plano de execucao: [plan](pipeline-plan.md)
- Handoff: [task-input](pipeline-task-input.md)
