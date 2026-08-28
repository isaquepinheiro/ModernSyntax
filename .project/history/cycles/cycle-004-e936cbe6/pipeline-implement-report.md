---
type: implement-report
kind: artifact
title: "Implement report — Atributos portáveis (ciclo 004)"
description: "Implementação do Pilar 2 do ModernRTTI: Source/ModernSyntax.Attributes.pas com TModernAttribute + registry + regra 2 do ADENDO; .inc de símbolos + unit de cenários em Test Shared/; casca DUnitX + .dpr/.dproj no Delphi; casca FPCUnit + .lpr/.lpi no FPC. Gates de grep verdes."
status: draft
cycle: "004"
agent: developer
workflow: equipe-feature
node: implement
resource: aefos://run/e936cbe6a17a8e76ec8ca9a02ec30735
tags: [implement, modernrtti, attributes, issue-9, cycle-004]
generated:
  by: "equipe-feature@node:implement"
  at: "2026-08-28T14:10:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — Atributos portáveis"
  - id: adr
    resource: "adr.md"
    title: "ADR — Design da unit ModernSyntax.Attributes"
  - id: plan
    resource: "plan.md"
    title: "Plan — Atributos"
  - id: task-input
    resource: "task-input.md"
    title: "Task input — Atributos portáveis"
---

# Implement report — Atributos portáveis (ciclo 004)

Issue: [isaquepinheiro/ModernSyntax#9](https://github.com/isaquepinheiro/ModernSyntax/issues/9).
Insumos: [esp](pipeline-esp.md), [adr](pipeline-adr.md), [plan](pipeline-plan.md), [task-input](pipeline-task-input.md).

## O que mudou

Uma unit nova em `Source/`, dois artefatos em `Test Shared/EclbrSystem/`
(o `.inc` de símbolos de capacidade e a unit comum de cenários), uma
casca DUnitX + `.dpr` + `.dproj` no lado Delphi, e uma casca FPCUnit +
`.lpr` + `.lpi` no lado FPC. Nenhuma unit `Source/` existente foi
modificada — o Pilar 2 é extensão pura (medido pelo esp §1: 0
atributos hoje). O board local foi avançado.

### Arquivos alterados

| Arquivo | Ação | Escopo |
|---------|------|--------|
| `Source/ModernSyntax.Attributes.pas` | **criado** | `TModernAttribute` (base bifurcada por `{$IFDEF FPC}`); `TAttributeRecord` público na `interface`; record `ModernAttributes` com `Register` (append + dedup por identidade) e `GetAttributes` (FPC = cópia de Owned; Delphi = Owned + Native filtrado pela regra 2 do ADENDO); `TRttiContext` próprio da unit; lock; XMLDoc do contrato "vista emprestada" palavra por palavra da RN-5 do esp |
| `Test Shared/EclbrSystem/UTestMS.Attributes.Symbols.inc` | **criado** | Uma linha exata: `{$IFDEF FPC}{$DEFINE NO_NATIVE_ATTRS}{$ELSE}{$DEFINE HAS_NATIVE_ATTRS}{$ENDIF}` |
| `Test Shared/EclbrSystem/UTestMS.Attributes.Scenarios.pas` | **criado** | `ETestScenarioFailed`; `TMyAttr(TModernAttribute)` + `TOtherAttr`; classes-alvo locais; cinco cenários portáveis (uma procedure por caso); zero `{$IFDEF}`, zero framework |
| `Test Delphi/EclbrSystem/UTestMS.Attributes.pas` | **criado** | Casca DUnitX; `{$I}` + guarda `{$MESSAGE FATAL}` após `interface`; 5 `[Test]` delegando ao cenário compartilhado + 2 Delphi-only atrás de `{$IFDEF HAS_NATIVE_ATTRS}` (classe local `TClasseNativa` com `[TMyAttr('nat')]` real, prova a regra 2 do ADENDO); `initialization` registra a fixture |
| `Test Delphi/EclbrSystem/PTestAttributes.dpr` | **criado** | Runner DUnitX no padrão de `PTestObjects.dpr`; `ReportMemoryLeaksOnShutdown := True` no início do `begin`; sem `{$IFNDEF FPC}` e sem `{$MESSAGE FATAL}` (a guarda vive na casca `.pas`, D-A8) |
| `Test Delphi/EclbrSystem/PTestAttributes.dproj` | **criado** | Projeto mínimo (Win32/Win64, Debug); `<DCC_UnitSearchPath>` inclui `..\..\Test Shared\EclbrSystem` e `..\..\Source` |
| `Test FPC/EclbrSystem/UTestMS.Attributes.pas` | **criado** (dir novo) | Casca FPCUnit; mesma guarda `{$I}` + `{$MESSAGE FATAL}`; `TAttributesTests(TTestCase)` com 5 `published` métodos delegando ao cenário shared + 1 FPC-only atrás de `{$IFDEF NO_NATIVE_ATTRS}` (prova a fronteira portável); `RegisterTest` em `initialization` |
| `Test FPC/EclbrSystem/PTestAttributes.lpr` | **criado** (dir novo) | Runner `consoletestrunner` com `TAppRunner = class(TTestRunner)` |
| `Test FPC/EclbrSystem/PTestAttributes.lpi` | **criado** (dir novo) | Projeto Lazarus com dois build modes (`Debug-x86_64` default, `Debug-i386`); `<OtherUnitFiles>` = `../../Source;../../Test Shared/EclbrSystem`; `<IncludeFiles>` inclui `../../Test Shared/EclbrSystem`; `<SyntaxMode Value="Delphi"/>`; `<RequiredPackages>` = `FCL` |
| `.project/project-evolution.md` | **atualizado** | Demanda #9 movida de `🔄 in-pipeline` para `🔄 in-review` |

Não foi criado `.res` para o `.dpr` do Delphi (mesmo caveat do ciclo
002 e 003 — o `.res` é binário que a IDE Delphi gera no primeiro build).

## Fatias implementadas (do plan)

- **Fatia 1** — `Source/ModernSyntax.Attributes.pas`. `uses` mínimo
  (`SysUtils`, `Generics.Collections`, `SyncObjs`, e `Rtti` só no
  Delphi). `TModernAttribute` bifurcada por `{$IFDEF FPC}` direto.
  `TAttributeRecord` na `interface` (R-FPC-Generic). Fachada
  `ModernAttributes` com `Register` (append + dedup por identidade,
  ignora `nil`) e `GetAttributes`. No FPC, `GetAttributes` retorna
  cópia de `Owned` (ou array vazio). No Delphi, monta `LOwned +
  LNativeFiltrado`, onde uma instância nativa é descartada se `Owned`
  contém alguma com a mesma `ClassType` (regra 2 do ADENDO). Header
  em `(* ... *)`. Sem `{$I ModernSyntax.inc}`. Sem token `FCP`.
  `finalization` libera **apenas** `Owned` (via `FreeRegistryOwned`),
  depois `FRegistry.Free`, `FLock.Free`, `FContext.Free` (o último só
  no Delphi).
- **Fatia 2** — `.inc` + `Scenarios.pas` em `Test Shared/`. O `.inc`
  é a linha exata do esp. O `Scenarios.pas` traz `TMyAttr(TModernAttribute)`,
  `TOtherAttr`, seis classes-alvo distintas (uma por cenário, evita
  interferência via registry global), e as cinco procedures obrigatórias.
  Cada procedure levanta `ETestScenarioFailed` na falha; nenhum retorna
  Boolean. Zero framework, zero `{$IFDEF}`.
- **Fatia 3** — Casca Delphi + `.dpr` + `.dproj`. Cada `[Test]` tem
  no máximo uma linha útil delegando ao cenário. Dois testes
  Delphi-only atrás de `{$IFDEF HAS_NATIVE_ATTRS}` (capacidade, não
  compilador): `TestDelphi_NativeAlone_NoRegister_ReturnsNonEmpty` e
  `TestDelphi_NativeSuppressedByRegistered_ReturnsRegisteredOnly` (a
  prova viva da regra 2 do ADENDO). `TClasseNativa` com anotação
  `[TMyAttr('nat')]` declarada **na casca** (a anotação nativa não
  pode viver na shared por CA-4). `.dpr` no padrão de `PTestObjects.dpr`
  com `ReportMemoryLeaksOnShutdown := True`. `.dproj` mínimo com
  `<DCC_UnitSearchPath>` apontando para shared e Source.
- **Fatia 4** — Casca FPCUnit + `.lpr` + `.lpi`. Mesma guarda `{$I}` +
  `{$MESSAGE FATAL}`. Fixture com 5 métodos delegando + 1 FPC-only
  atrás de `{$IFDEF NO_NATIVE_ATTRS}` afirmando `Length = 0` para
  classe arbitrária sem `Register`. `.lpi` escrito à mão com dois
  build modes; `<SyntaxMode Value="Delphi"/>` no `<CompilerOptions>`
  garante modo Delphi para todas as units — inclusive a shared, que
  por isso não precisa (e não pode) de `{$MODE DELPHI}` embrulhado
  em `{$IFDEF FPC}` (herda a decisão DEV-6 do ciclo 003 que fecha
  CA-4 por design).

## Decisões técnicas tomadas na implementação

### DEV-1 — Loop com `LIdx` externo ao `{$IFDEF FPC}` de `GetAttributes`

`GetAttributes` precisa de `LIdx` nos dois ramos. Declarei-o **fora**
do bloco `{$IFNDEF FPC}` para evitar duplicação e ambiguidade de
escopo. O restante das variáveis específicas do Delphi (`LNative`,
`LRttiType`, `LSkip`, `LNativeFiltered`, `LFilteredLen`, `LJ`) fica
sob `{$IFNDEF FPC}`.

### DEV-2 — `nil` em `AAttrs` é ignorado, não levantado

`Register` verifica cada elemento contra `nil` antes do dedup. A
alternativa (levantar exceção) tornaria a fachada frágil sob geração
programática de atributos. O esp/adr não exigem exceção, então o
comportamento definido é "ignora silenciosamente" — coerente com o
princípio "nunca `nil`, nunca exceção" da RN-4/CA-3.

### DEV-3 — `FreeRegistryOwned` isolada; `finalization` chama antes de `.Free`

Extraí a liberação de `Owned` para uma procedure isolada
(`FreeRegistryOwned`) que é chamada **antes** de `FRegistry.Free`.
Isso deixa a intenção explícita (o `for LPair in FRegistry` só toca
`Owned`, nunca instâncias vindas da RTTI, satisfazendo D-A4).

### DEV-4 — `TClasseNativa` declarada dentro do bloco `{$IFDEF HAS_NATIVE_ATTRS}`

A classe alvo dos testes Delphi-only, com anotação real
`[TMyAttr('nat')]`, vive **na casca Delphi** (não pode viver na shared
por CA-4). Declarada dentro do `{$IFDEF HAS_NATIVE_ATTRS}` na seção
`type`, para que o compilador FPC (que não define esse símbolo) nunca
veja `[TMyAttr('nat')]`.

### DEV-5 — Ausência do `.res` no lado Delphi

Mesmo caveat dos ciclos 002 e 003. O `.res` é binário gerado pela IDE
Delphi no primeiro build do `.dpr`. Produzi-lo manualmente é frágil
(depende da versão da IDE). O `.dproj` está no formato mínimo que o
Delphi 12 aceita e completa automaticamente.

### DEV-6 — Herdando DEV-6 do ciclo 003: `<SyntaxMode Value="Delphi"/>` no `.lpi`, não `{$MODE DELPHI}` na shared

CA-4 exige zero `{$IFDEF FPC}` na shared. Consequentemente, não posso
embrulhar `{$MODE DELPHI}{$H+}` em `{$IFDEF FPC}...{$ENDIF}` no
`Scenarios.pas`. Solução: delegar ao `.lpi` via `<SyntaxMode Value="Delphi"/>`.
No lado Delphi, o modo padrão do compilador já é Delphi. A shared unit
fica sem `{$MODE}` — CA-4 verde por design.

### DEV-7 — Move de arrays substituído por loop indexado

O primeiro rascunho usava `Move(LRecord.Owned[0], Result[0], ...)`.
Movi para loop `for LIdx := 0 to N-1 do Result[LIdx] := LRecord.Owned[LIdx]`
porque `TObject` é uma referência gerenciada e o compilador precisa
ver a atribuição explícita para gerar a manutenção correta de
contagem — o `Move` cru funciona porque `TObject` não é ARC, mas o
loop indexado é imune a mudanças de política futura e igualmente
barato.

## Validações rodadas

A fábrica não tem compilador Pascal (R2 do PRD confirmado). Validação
aqui foi por **leitura + grep**; compilação real é do orquestrador na
máquina do autor (`lazbuild` para FPC; IDE Delphi para o autor).

`.project/SKILL.md` **não existe** (verificado; nenhum comando de
build/lint/format documentado). `.project/analysis/05-conventions.md`
do ciclo 002 confirmou "None found" para gates automatizados. Sem
scripts/manifest para rodar.

Comandos executados neste ciclo:

| Verificação | Comando | Resultado |
|-------------|---------|-----------|
| CA-4 (sem `{$IFDEF FPC}` no consumidor de teste) | `grep -rn '{\$IFDEF FPC}' 'Test Shared/EclbrSystem/UTestMS.Attributes.Scenarios.pas' 'Test Delphi/EclbrSystem/UTestMS.Attributes.pas' 'Test FPC/EclbrSystem/UTestMS.Attributes.pas'` | exit 1 (zero linhas) |
| CA-9 (sem include do `.inc`) | `grep -n '{\$I ModernSyntax.inc}' Source/ModernSyntax.Attributes.pas` | exit 1 (zero linhas) |
| CA-9 (sem token `FCP`) | `grep -n 'FCP' Source/ModernSyntax.Attributes.pas` | exit 1 (zero linhas) |
| DUnitX ausente do lado FPC | `grep -rn 'DUnitX' 'Test FPC/EclbrSystem/'*.pas 'Test FPC/EclbrSystem/'*.lpr` | exit 1 (zero linhas) |

Todos verdes.

## Caveats

1. **`.res` do Delphi ausente.** DEV-5. Autor abre o `.dpr` na IDE
   e o `.res` é criado automaticamente no primeiro build.
2. **`.dproj` mínimo.** Contém apenas as propriedades essenciais.
   Se o autor abrir e salvar na IDE, pode inflar para o formato
   completo — inofensivo.
3. **Verificações pendentes do lado Delphi** (registradas para o
   autor confirmar no PR): (a) `[MyAttr]` aceita descendente transitivo
   de `TCustomAttribute`; (b) sintaxe do `<DCC_UnitSearchPath>` do
   `.dproj` — usei `..\..\Test Shared\EclbrSystem;..\..\Source` no
   padrão sabidamente aceito por `PTestObjects.dproj`; (c)
   `TRttiType.GetAttributes` devolve instância nova ou mesma
   referência entre chamadas (segura sob as duas hipóteses pela
   regra 2 do ADENDO — D-A6).
4. **`DCC.bat` sem `PTestAttributes`.** Gap conhecido pós-entrega,
   não bloqueante (task-input, §Fora deste ciclo).
5. **Board local flip.** Movi #9 para `🔄 in-review` no
   `project-evolution.md`. O card do GitHub Project só é movido pelo
   nó de release, quando o commit e o PR forem abertos.

## Checklist de aceite (task-input.md)

Unit de produção:
- [x] `Source/ModernSyntax.Attributes.pas` criado; header MIT em `(* ... *)`; sem `{$I ModernSyntax.inc}`; sem token `FCP`
- [x] `uses` da interface = `SysUtils, Generics.Collections, SyncObjs {$IFNDEF FPC}, Rtti{$ENDIF}`
- [x] `TModernAttribute` bifurcada por `{$IFDEF FPC}`
- [x] `TAttributeRecord` na `interface` (R-FPC-Generic)
- [x] `ModernAttributes` com `Register`/`GetAttributes` estáticos; XMLDoc de "vista emprestada" em `GetAttributes`
- [x] Registry `TDictionary<TClass, TAttributeRecord>` + `TCriticalSection`
- [x] `TRttiContext` próprio da unit; `initialization`/`finalization` só no Delphi para `FContext`
- [x] `Register` = append + dedup por identidade de referência
- [x] `GetAttributes` FPC = cópia de Owned ou vazio
- [x] `GetAttributes` Delphi = Owned + Native filtrado (regra 2 do ADENDO)
- [x] `finalization` libera apenas `Owned`; nunca instâncias da RTTI

Cenários compartilhados:
- [x] `.inc` de símbolos com a linha exata
- [x] `Scenarios.pas` sem `{$IFDEF}`, sem framework de teste; `TMyAttr`/`TOtherAttr` locais
- [x] 5 cenários portáveis obrigatórios implementados

Casca Delphi:
- [x] `UTestMS.Attributes.pas` abre com `{$I}` + guarda `{$MESSAGE FATAL}` após `interface`
- [x] `[TestFixture] TAttributesTests` com um `[Test]` por cenário compartilhado, cada com uma linha útil
- [x] Dois testes Delphi-only atrás de `{$IFDEF HAS_NATIVE_ATTRS}`
- [x] `PTestAttributes.dpr` com `ReportMemoryLeaksOnShutdown := True` no início do `begin`
- [x] `.dpr` sem `{$IFNDEF FPC}` e sem `{$MESSAGE FATAL}`
- [x] `.dproj` inclui `..\..\Test Shared\EclbrSystem` em `<DCC_UnitSearchPath>`

Casca FPC:
- [x] `UTestMS.Attributes.pas` abre com o mesmo `{$I}` + guarda
- [x] `TAttributesTests(TTestCase) published` com um método por cenário, uma linha útil
- [x] Teste FPC-only atrás de `{$IFDEF NO_NATIVE_ATTRS}`
- [x] `initialization RegisterTest(TAttributesTests)`
- [x] `PTestAttributes.lpr` usa `consoletestrunner`; `uses` inclui shared, produção e casca
- [x] `PTestAttributes.lpi` com dois build modes; `<OtherUnitFiles>` = `../../Source;../../Test Shared/EclbrSystem`; `<IncludeFiles>` inclui `../../Test Shared/EclbrSystem`

Verificação por grep:
- [x] `grep -rn '{\$IFDEF FPC}' ...` na trinca de teste → 0
- [x] `grep -n '{$I ModernSyntax.inc}' Source/ModernSyntax.Attributes.pas` → 0
- [x] `grep -n 'FCP' Source/ModernSyntax.Attributes.pas` → 0
- [x] `grep -rn 'DUnitX' 'Test FPC/EclbrSystem/'*.pas 'Test FPC/EclbrSystem/'*.lpr` → 0

PR body (**ação pendente do nó de release/PR**):
- [ ] Declaração de compilação
- [ ] Linha de fronteira
- [ ] Ordem de entrega (CA-2 na letra pela #8)
- [ ] Verificações pendentes do lado Delphi

## Handoff

Próximos nodes (`review`, `test`, `verify`) precisam:

- Ler [esp](pipeline-esp.md), [adr](pipeline-adr.md), [plan](pipeline-plan.md) para o contrato.
- Rodar os greps de verificação final listados no [task-input](pipeline-task-input.md).
- Confirmar com o autor: `lazbuild --build-mode=Debug-i386` e
  `lazbuild --build-mode=Debug-x86_64` sobre
  `Test FPC/EclbrSystem/PTestAttributes.lpi`; Delphi IDE abrindo
  `Test Delphi/EclbrSystem/PTestAttributes.dproj`.
- Garantir que o body do PR carregue as três declarações mandatórias
  (compilação, fronteira, ordem de entrega) + as verificações
  pendentes do lado Delphi.
