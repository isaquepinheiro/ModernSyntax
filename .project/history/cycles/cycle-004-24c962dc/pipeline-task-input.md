---
type: task-input
kind: artifact
title: "Task input — implementar Source/ModernSyntax.Callback.pas e os três projetos de teste"
description: "Handoff operacional para o implementador: criar a unit de callbacks portáveis, a unit comum de cenários, e as duas cascas finas de teste (DUnitX + FPCUnit) com projetos .dproj e .lpi."
status: draft
cycle: "004"
agent: architect
workflow: equipe-feature
node: "plan-gate:on_reject"
resource: aefos://run/24c962dcc2be1819336ca1fea18ae949
tags: [task-input, modernrtti, callbacks, issue-7, feature]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-08-28T13:30:00Z"
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
---

# Task input — Callbacks transversais (issue #7)

**Issue:** [isaquepinheiro/ModernSyntax#7](https://github.com/isaquepinheiro/ModernSyntax/issues/7)
**Tipo:** feature
**Labels:** `feature`, `aefos:running`

## Objetivo (uma frase)

Criar `Source/ModernSyntax.Callback.pas` com três interfaces
(`IModernFunc<T,R>`, `IModernProc<T>`, `IModernPredicate<T>`) e o factory
`Callback.Of` (só método de objeto neste ciclo), compilando idêntico no
Delphi e no FPC 3.2.2, com testes cobrindo os dois compiladores via uma
unit comum de cenários e duas cascas finas (DUnitX + FPCUnit).

## Divergência **declarada** do texto da issue

A issue #7 e o PRD mencionam **`IMSFunc<T,R>`**, **`IMSProc<T>`**,
**`IMSPredicate<T>`**. Este ciclo entrega os contratos com o nome
**`IModernFunc<T,R>`**, **`IModernProc<T>`**, **`IModernPredicate<T>`**.
Motivo, medido: em 9 interfaces públicas do repositório, apenas 1 usa
prefixo `IMS` e é código morto (`IMSObserver`). O padrão vivo é
`IModern*` (precedente `IModernObject`). Decisão de gate no
[adr, D-A9](pipeline-adr.md). O corpo do PR **declara** a renomeação.

## Escopo

Ver [esp](pipeline-esp.md) seções 2 e 3. Em resumo:

- Uma unit nova em `Source/`.
- Uma unit comum de cenários em `Test Shared/EclbrSystem/` (diretório
  novo — terceira pasta neutra, sem framework).
- Uma casca fina DUnitX + `.dproj` em `Test Delphi/EclbrSystem/`.
- Uma casca fina FPCUnit + `.lpi` + `.lpr` em `Test FPC/EclbrSystem/`
  (diretório novo).

**Fora deste ciclo:** conversão dos 415 usos existentes de `TProc`/`TFunc`
(D4 do PRD; correção do 451 para 415 medida no [adr](pipeline-adr.md) D-A10),
sobrecarga `TFunc<T,R>` do factory, procedure global, correção do bug
`{$IFDEF FCP}` em `ModernSyntax.inc:256`.

## Checklist de aceite

- [ ] `Source/ModernSyntax.Callback.pas` criado; a `interface` usa
  **apenas** `SysUtils` (RN-5 do esp).
- [ ] Cabeçalho da unit em `(* ... *)` — nenhuma diretiva `{$...}`
  dentro de comentário `{ }` (D-A12 do adr; quebra nos dois compiladores).
- [ ] Três interfaces genéricas **sem GUID** (D-A2 do adr).
- [ ] Factory `Callback` com **três** sobrecargas `Of` — método de
  objeto para func/proc/predicate. **Nenhuma** sobrecarga `TFunc<T,R>`
  neste ciclo (D-A6 do adr).
- [ ] Três classes wrapper (`TFuncOfObjectWrapper<T,R>`,
  `TProcOfObjectWrapper<T>`, `TPredicateOfObjectWrapper<T>`) declaradas
  na **`interface`**, não na `implementation` (D-A13 do adr; erro FPC:
  "Global Generic template references static symtable").
- [ ] `Source/ModernSyntax.Callback.pas` **não** contém
  `{$I ModernSyntax.inc}` nem o token `FCP` (D-A5/D-A11 do adr).
- [ ] `Test Shared/EclbrSystem/UTestMS.Callback.Scenarios.pas` existe,
  não usa nenhum framework de teste, não contém `{$IFDEF}`.
- [ ] Casca DUnitX (`Test Delphi/EclbrSystem/UTestMS.Callback.pas`)
  com cada método contendo **até uma linha útil** que delega ao
  cenário (D-A7 do adr).
- [ ] `PTestModernCallback.dpr` + `.dproj` criados no padrão dos
  `PTest*.dpr` existentes; `.dproj` inclui `..\..\Test Shared\EclbrSystem`
  em `<DCC_UnitSearchPath>` (Q2 do relatório, resolvida aqui).
- [ ] Casca FPCUnit (`Test FPC/EclbrSystem/UTestMS.Callback.pas`)
  com cada método delegando ao cenário; `initialization` registra a
  `TTestCase` via `RegisterTest`.
- [ ] `Test FPC/EclbrSystem/PTestModernCallback.lpr` usa
  `consoletestrunner`; `.lpi` tem dois build modes (`Debug-i386` e
  `Debug-x86_64`) e `<OtherUnitFiles>` apontando para `../../Source` e
  `../../Test Shared/EclbrSystem`.
- [ ] `grep -rn '{\$IFDEF FPC}' 'Test Shared/' 'Test Delphi/' 'Test FPC/'` → 0
  (CA-4 do esp).
- [ ] Body do PR declara literalmente: *"compilado em FPC 3.2.2
  x86_64 e i386; não compilado em Delphi — Delphi permanece com o
  autor"* (CA-7 do esp, R2 do PRD).

## Arquivos prováveis impactados

**Criados (novos):**

- `Source/ModernSyntax.Callback.pas`
- `Test Shared/EclbrSystem/UTestMS.Callback.Scenarios.pas` (diretório
  novo — `Test Shared/` não existia)
- `Test Delphi/EclbrSystem/UTestMS.Callback.pas`
- `Test Delphi/EclbrSystem/PTestModernCallback.dpr`
  (+ `.dproj` e `.res` no mesmo padrão dos `PTest*.dpr` existentes)
- `Test FPC/EclbrSystem/UTestMS.Callback.pas` (diretório novo)
- `Test FPC/EclbrSystem/PTestModernCallback.lpr`
- `Test FPC/EclbrSystem/PTestModernCallback.lpi`

**Não tocar nesta issue:**

- Nenhum dos 415 sites existentes de `TProc`/`TFunc` (D4 do PRD).
- `Source/ModernSyntax.Objects.pas` (D5 do PRD).
- `Source/ModernSyntax.inc` (R3 — bug do `FCP` fica para outra linha).
- `Source/ModernSyntax.Std.pas`, `Source/ModernSyntax.DotEnv.pas`.
- Fixtures DUnitX existentes em `Test Delphi/EclbrSystem/`.

## Notas de implementação

- **`uses` da unit nova:** somente `SysUtils`. Trazer outra unit da
  biblioteca reintroduz `reference to` ou o `.inc` transitivamente.
- **Ramificação:** `{$IFDEF FPC} ... {$ELSE} ... {$ENDIF}` **direto**
  no arquivo, **jamais** via `{$I ModernSyntax.inc}` (R3 do PRD).
- **Wrappers de método de objeto:** DEVEM estar declarados na seção
  `interface`, não na `implementation` (D-A13 do adr). O FPC 3.2.2
  expande o template genérico no ponto de uso do factory — símbolos da
  `implementation` não são visíveis nesse ponto; o erro resultante é
  "Global Generic template references static symtable". Guardar o
  `TMethod` (ou ponteiro de método tipado) em campo privado da classe.
  Herdar de `TInterfacedObject` para ARC via interface. O factory
  instancia e devolve pela interface — o consumidor nunca vê a classe
  wrapper.
- **Cenários em `Test Shared/`:** funções top-level, sem estado global.
  Falha = exceção. Nenhuma dependência de framework.
- **Classe helper de captura:** declarada dentro da própria unit de
  cenários como demonstração canônica, para servir de referência ao
  consumidor que precisar de captura (CA-3 do esp — CA-4 do PRD).
- **DUnitX vs FPCUnit:** DUnitX não está vendorizado (medido); FPCUnit
  é nativo do FPC 3.2.2 (medido). A unificação está na unit de cenários,
  não no framework.

## Dependências externas

Nenhuma. Este ciclo cria o `.lpi` próprio dos testes desta unit; não
depende de outro ciclo/issue já ter criado infraestrutura Lazarus.

## Verificação final (checklist de PR)

- [ ] `grep -n '{\$I ModernSyntax.inc}' Source/ModernSyntax.Callback.pas` → 0
- [ ] `grep -n 'FCP' Source/ModernSyntax.Callback.pas` → 0
- [ ] `grep -rn '{\$IFDEF' 'Test Shared/EclbrSystem/'` → 0
- [ ] `grep -rn '{\$IFDEF FPC}' 'Test Delphi/EclbrSystem/UTestMS.Callback.pas' 'Test FPC/EclbrSystem/UTestMS.Callback.pas'` → 0
- [ ] FPC 3.2.2 compilou `Source/ModernSyntax.Callback.pas` sem erros
  em x86_64 **e** i386. Limpar diretório de saída antes de cada build;
  não compilar `Source/*.pas` inteiro. Evidência (stdout do compilador)
  no corpo do PR.
- [ ] `lazbuild --build-mode=Debug-i386 "Test FPC/EclbrSystem/PTestModernCallback.lpi"` compila e FPCUnit passa todos os casos.
- [ ] `lazbuild --build-mode=Debug-x86_64 "Test FPC/EclbrSystem/PTestModernCallback.lpi"` idem. Evidência no corpo do PR.
- [ ] Delphi compila `PTestModernCallback.dproj` (pelo autor).
- [ ] Body do PR carrega a declaração do CA-7 do esp.
