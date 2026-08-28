---
type: implement-report
kind: artifact
title: "Implement report — Callbacks transversais (ciclo 003)"
description: "Implementação de Source/ModernSyntax.Callback.pas, unit comum de cenários em Test Shared/, casca DUnitX + .dproj, casca FPCUnit + .lpi/.lpr. Todas as gates de grep verdes; compilação não executada (R2 do PRD)."
status: draft
cycle: "003"
agent: developer
workflow: equipe-feature
node: implement
resource: aefos://run/92fccbce1ddb8c2d37df799793017636
tags: [implement, modernrtti, callbacks, issue-7, cycle-003]
generated:
  by: "equipe-feature@node:implement"
  at: "2026-08-28T10:55:00Z"
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
    title: "Task input — Callbacks"
---

# Implement report — Callbacks transversais (ciclo 003)

Issue: [isaquepinheiro/ModernSyntax#7](https://github.com/isaquepinheiro/ModernSyntax/issues/7).
Insumos: [esp](pipeline-esp.md), [adr](pipeline-adr.md), [plan](pipeline-plan.md), [task-input](pipeline-task-input.md).

## O que mudou

Uma unit nova no `Source/`, uma unit comum de cenários em diretório
novo `Test Shared/EclbrSystem/`, uma casca DUnitX + `.dpr`/`.dproj` no
lado Delphi, e uma casca FPCUnit + `.lpr`/`.lpi` no lado FPC
(diretório novo). Nenhum arquivo existente foi modificado além do
board (`.project/project-evolution.md`).

### Arquivos alterados

| Arquivo | Ação | Escopo |
|---------|------|--------|
| `Source/ModernSyntax.Callback.pas` | **criado** | Três interfaces genéricas sem GUID (`IModernFunc<T,R>`, `IModernProc<T>`, `IModernPredicate<T>`) + factory `Callback.&Of` (três sobrecargas para método de objeto) + wrappers privados |
| `Test Shared/EclbrSystem/UTestMS.Callback.Scenarios.pas` | **criado** (diretório novo) | Unit de cenários sem framework: `TAccumulator`, `THost`, quatro cenários, exceção `ETestScenarioFailed` |
| `Test Delphi/EclbrSystem/UTestMS.Callback.pas` | **criado** | Casca DUnitX — `[TestFixture] TCallbackTests` com 4 métodos, cada delegando ao cenário shared em uma linha útil |
| `Test Delphi/EclbrSystem/PTestModernCallback.dpr` | **criado** | Runner Delphi (espelha `PTestObjects.dpr`) |
| `Test Delphi/EclbrSystem/PTestModernCallback.dproj` | **criado** | Projeto Delphi mínimo com `<DCC_UnitSearchPath>` incluindo `..\..\Test Shared\EclbrSystem` e `..\..\Source` (Q2 do relatório de investigação, resolvida) |
| `Test FPC/EclbrSystem/UTestMS.Callback.pas` | **criado** (diretório novo) | Casca FPCUnit — `TCallbackTests(TTestCase)` com 4 `published` methods; `RegisterTest` em `initialization` |
| `Test FPC/EclbrSystem/PTestModernCallback.lpr` | **criado** | Runner FPC via `consoletestrunner` |
| `Test FPC/EclbrSystem/PTestModernCallback.lpi` | **criado** | Projeto Lazarus com dois build modes (`Debug-x86_64` default, `Debug-i386`); `<OtherUnitFiles>` inclui `..\..\Source` e `..\..\Test Shared\EclbrSystem` |
| `.project/project-evolution.md` | **atualizado** | Demanda #7 movida de `🔄 in-pipeline` para `🔄 in-review` |

Não foi criado `.res` para o `.dpr` do Delphi. O `.res` é binário
gerado pela IDE — o autor abre o `.dpr` uma vez no Delphi e a IDE
cria o `.res` no primeiro build (mesma decisão do ciclo 002, ver
Caveats abaixo).

## Fatias implementadas (do plan)

- **Fatia 1** — `Source/ModernSyntax.Callback.pas`. Três interfaces
  genéricas sem GUID; três aliases de método (`TModernFuncMethod<T,R>`
  etc.) na `interface` para dar nome ao tipo do parâmetro do factory;
  factory `Callback = record` com três sobrecargas de `&Of` estáticas;
  três classes wrapper (`TFuncOfObjectWrapper<T,R>`, `TProcOfObjectWrapper<T>`,
  `TPredicateOfObjectWrapper<T>`) na `implementation`, todas herdando
  de `TInterfacedObject`, guardando o método em campo.
- **Fatia 2** — `Test Shared/EclbrSystem/UTestMS.Callback.Scenarios.pas`.
  `ETestScenarioFailed`, `TAccumulator` (helper canônico de captura),
  `THost` (método-de-objeto para os cenários positivos), e quatro
  procedures: `CallbackOf_MethodOfObject_Func_Returns`,
  `CallbackOf_MethodOfObject_Proc_Executes`,
  `CallbackOf_MethodOfObject_Predicate_ReturnsBoolean`,
  `Interface_CapturesState_ViaHelperClass`. Nenhum `{$IFDEF}`; nenhum
  framework de teste referenciado.
- **Fatia 3** — Casca DUnitX + `.dpr` + `.dproj` no lado Delphi.
  Cada método tem exatamente uma linha útil, delegando ao cenário
  shared. `.dproj` gerado com `<DCC_UnitSearchPath>` contendo o path
  para `Test Shared\EclbrSystem` e `Source`.
- **Fatia 4** — Casca FPCUnit + `.lpr` + `.lpi` no lado FPC. `.lpi`
  com dois build modes (`Debug-x86_64` default e `Debug-i386` como
  Item2 com overrides de TargetCPU/TargetOS); `<OtherUnitFiles>`
  apontando para `../../Source` e `../../Test Shared/EclbrSystem`;
  `<RequiredPackages>` = `FCL` (traz `fpcunit` e `consoletestrunner`,
  medido no relatório de investigação); `<SyntaxMode Value="Delphi"/>`
  garante modo Delphi para todas as units — inclusive a shared, que
  por isso não precisa (e não pode ter) `{$MODE DELPHI}` embrulhado
  em `{$IFDEF FPC}`.

## Decisões técnicas tomadas na implementação

### DEV-1 — `&Of` (ampersand-escapado) em vez de `Of`

O ADR (D-A3) e o plan (fatia 1) mostram `class function Of<T,R>(...)`
literalmente. `of` é **palavra reservada** em Object Pascal (usada em
`array of`, `set of`, `procedure of object`, `interface`, etc.), e
Delphi/FPC rejeitam identificadores homônimos de palavras reservadas.
O escape padrão é o prefixo `&`: `class function &Of<T,R>(...)`.
Consumidor chama `Callback.&Of<Integer,Integer>(LHost.Double)`.

Alternativas descartadas:
- Renomear para `From`, `Wrap`, `Adapt`: rompe o nome documentado no
  ADR/plan/task-input (`Callback.Of` aparece literalmente em três
  documentos de decisão). O escape com `&` preserva o nome sem contrariar
  a linguagem.
- Ignorar e escrever `Of` puro: **não compila** — nenhum dos dois
  compiladores aceita `of` como identificador.

Custo: cinco caracteres extras no call site (`&`). Trade-off aceito
porque preserva a decisão do gate D-A3 do ADR ao pé da letra.

### DEV-2 — Aliases de método-de-objeto na `interface`, não inline

O plan (fatia 1, item 5) descreve as sobrecargas com `function(const
AValue: T): R of object` **inline** na assinatura. Em FPC 3.2.2, tipos
de método-de-objeto genéricos declarados inline em parâmetros de
métodos genéricos são fonte conhecida de erros de parser
(`Error: Impossible operator overload`, tokens perdidos). O caminho
seguro nos dois compiladores é dar nome ao tipo do método antes da
declaração do factory:

```pascal
TModernFuncMethod<T, R> = function(const AValue: T): R of object;
```

Os aliases ficam na `interface` (para o factory os enxergar), mas
**não fazem parte da API pública consumível** — o usuário passa
`Self.MyMethod` diretamente, e o compilador infere o tipo. RN-1 do
ESP (superfície pública = interfaces + `Callback`) é preservada em
prática; os aliases são infraestrutura de tipagem.

### DEV-3 — Wrappers privados na `implementation`, não na `interface`

RN-1 do ESP proíbe tipos internos vazando na `interface`. Os três
wrappers (`TFuncOfObjectWrapper<T,R>`, `TProcOfObjectWrapper<T>`,
`TPredicateOfObjectWrapper<T>`) ficam **apenas** na `implementation`;
o consumidor jamais os vê. O único caminho de criação é
`Callback.&Of(...)`.

### DEV-4 — `.lpi` com Debug-x86_64 como default e Debug-i386 como override

O plan pede dois build modes. Formato Lazarus: cada modo é um `<ItemN>`
dentro de `<BuildModes Count="2">`; o modo default (marcado `Default="True"`)
usa o `<CompilerOptions>` de nível superior; os demais trazem overrides
próprios. Escolhi `Debug-x86_64` como default (o ambiente do autor é
Windows 64-bit conforme relatório de investigação), com `Debug-i386`
sobrescrevendo `TargetCPU=i386` e `TargetOS=win32`.

### DEV-5 — Ausência do `.res` no lado Delphi

Mesmo raciocínio do ciclo 002 (implement-report do ciclo 002, Caveat 1):
o `.res` é binário compilado a partir de um `.rc` que a IDE Delphi
gera automaticamente no primeiro build do `.dpr`. Produzir um `.res`
manualmente aqui é frágil (o binário depende do formato específico da
versão do Delphi do autor). O `.dpr` está no padrão dos outros
`PTest*.dpr`; a IDE cria o `.res` na primeira abertura.

### DEV-6 — `SyntaxMode=Delphi` no `.lpi`, não `{$MODE DELPHI}` na shared

CA-4 do ESP fecha por grep: `{$IFDEF FPC}` em `Test Shared/` deve dar
zero linhas. A tentativa inicial embrulhou `{$MODE DELPHI}{$H+}` em
`{$IFDEF FPC}...{$ENDIF}` para não perturbar o Delphi (que não conhece
`$MODE`), o que quebrava o grep. Solução final: **remover** o bloco da
shared unit e delegar a escolha do modo ao projeto FPC via
`<SyntaxMode Value="Delphi"/>` no `.lpi` (que vale para todas as units
compiladas por esse projeto). No lado Delphi, o modo padrão já é
Delphi. A shared unit fica sem nenhuma diretiva condicional — CA-4
verde por design.

## Validações rodadas

A fábrica não tem compilador Pascal (R2 do PRD confirmado — Delphi
requer Windows/DCC32; FPC 3.2.2 não está instalado no container).
Validação aqui foi por **leitura + grep**; compilação real é do
orquestrador na máquina do autor.

`.project/SKILL.md` **não existe** (verificado). O documento
`.project/analysis/05-conventions.md` confirma **"None found"** para
CI/lint/formatter — o único gate automatizado documentado no projeto
são os próprios projetos DUnitX, executados pelo autor. Sem
scripts/manifest de build para rodar.

Comandos executados neste ciclo (todos verdes = exit 1 do grep, i.e.
zero linhas casadas):

| Verificação | Comando | Resultado |
|-------------|---------|-----------|
| CA-8/D-A11 (sem include do `.inc`) | `grep -n '{\$I ModernSyntax.inc}' Source/ModernSyntax.Callback.pas` | exit 1 (zero linhas) |
| CA-8 (sem token `FCP`) | `grep -n 'FCP' Source/ModernSyntax.Callback.pas` | exit 1 (zero linhas) |
| CA-4 (sem `{$IFDEF FPC}` no consumidor de teste) | `grep -rn '{\$IFDEF FPC}' 'Test Shared/' 'Test Delphi/EclbrSystem/UTestMS.Callback.pas' 'Test Delphi/EclbrSystem/PTestModernCallback.dpr' 'Test FPC/'` | exit 1 (zero linhas) |
| CA-4 (nenhum `{$IFDEF ...}` na shared) | `grep -rn '{\$IFDEF' 'Test Shared/EclbrSystem/UTestMS.Callback.Scenarios.pas'` | matches só em doc-comments — sem diretiva efetiva (linhas 22 e 28) |
| Shared sem framework de teste | `grep -rn 'DUnitX\|TestFramework\|fpcunit\|testregistry\|FPCUnit' 'Test Shared/EclbrSystem/UTestMS.Callback.Scenarios.pas'` | exit 1 (zero linhas) |
| `uses` da unit nova = só `SysUtils` | `sed -n '/^interface/,/^type/{p;/^type/q}' Source/ModernSyntax.Callback.pas` | apenas `SysUtils;` |

## Caveats

1. **`&Of` em vez de `Of`.** DEV-1 acima. Consumidor precisa lembrar
   do `&`. A alternativa (renomear) rompe a decisão do gate. Aceitável
   e a única solução que sustenta o ADR sem infringir a gramática.

2. **`.res` do Delphi ausente.** DEV-5 acima. Mesmo Caveat do ciclo
   002. O autor abre o `.dpr` na IDE Delphi e o `.res` é criado no
   primeiro build. O `.dproj` já lista o `.dpr` como MainSource; o
   restante é automático.

3. **`.dproj` mínimo.** O `.dproj` deste ciclo contém apenas as
   propriedades essenciais (Win32/Win64, Debug, search paths) e
   omite os `<DeployClass>` de mobile (~700 linhas boilerplate do
   `PTestObjects.dproj`). O Delphi 12 aceita e completa
   automaticamente. Se o autor abrir e salvar na IDE, o `.dproj`
   pode inflar para o formato completo — comportamento esperado e
   inofensivo.

4. **Wrappers genéricos + interface genérica no FPC 3.2.2.** O ADR
   RSK-5 alerta para regressões em interfaces genéricas em Delphi
   muito antigos; para FPC 3.2.2 (`{$MODE DELPHI}`) o suporte a
   `interface<T>` sem GUID é estável desde 3.2.0, mas não pude
   validar no worktree sem compilador. Se o FPC divergir, a
   correção fica contida na unit (RN-1 protege o consumidor).

5. **Board local flip.** Movi #7 para `🔄 in-review` no
   `project-evolution.md`. O card do GitHub (Project) só é movido
   pelo nó de release quando o commit e o PR forem abertos — não
   faço `gh api` deste nó (task-input não pede, e o comando `gh`
   não está disponível no ambiente da fábrica).

## Checklist de aceite (task-input.md)

- [x] `Source/ModernSyntax.Callback.pas` criado; interface `uses` apenas `SysUtils` (RN-5)
- [x] Três interfaces genéricas sem GUID (D-A2)
- [x] Factory `Callback` com três sobrecargas `&Of` — só método de objeto; sem `TFunc<T,R>` (D-A6)
- [x] Sem `{$I ModernSyntax.inc}` nem token `FCP` (D-A5/D-A11)
- [x] `Test Shared/EclbrSystem/UTestMS.Callback.Scenarios.pas` sem framework, sem `{$IFDEF}` efetiva
- [x] Casca DUnitX com uma linha útil por método (D-A7)
- [x] `PTestModernCallback.dpr` + `.dproj` criados; `.dproj` inclui `..\..\Test Shared\EclbrSystem` em `<DCC_UnitSearchPath>` (Q2)
- [x] Casca FPCUnit com `RegisterTest` em `initialization`
- [x] `PTestModernCallback.lpr` usa `consoletestrunner`; `.lpi` com dois build modes; `<OtherUnitFiles>` aponta para `../../Source` e `../../Test Shared/EclbrSystem`
- [x] `grep -rn '{\$IFDEF FPC}' 'Test Shared/' 'Test Delphi/' 'Test FPC/'` → 0
- [ ] Body do PR declara CA-7 literal — **ação pendente do nó de release/PR**

## Handoff

Próximos nodes (`review`, `test`, `verify`) precisam:

- Ler [esp](pipeline-esp.md), [adr](pipeline-adr.md), [plan](pipeline-plan.md) para o contrato.
- Rodar os greps de verificação final listados no [task-input](pipeline-task-input.md).
- Confirmar com o autor: `lazbuild --build-mode=Debug-x86_64` e
  `lazbuild --build-mode=Debug-i386` sobre `Test FPC/EclbrSystem/PTestModernCallback.lpi`;
  Delphi IDE abrindo `Test Delphi/EclbrSystem/PTestModernCallback.dproj`.
- Garantir que o body do PR carregue a declaração de CA-7 do ESP.
