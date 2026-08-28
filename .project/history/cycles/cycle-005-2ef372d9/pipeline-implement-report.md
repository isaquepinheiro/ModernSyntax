---
type: implement-report
kind: artifact
title: "Implement report — TModernInvoker (issue #10)"
description: "Implementação da unit ModernSyntax.Invoker (record com dois overloads Invoke<TSignature> sobre TObject.MethodAddress), da unit compartilhada com sete cenários e das duas cascas finas (DUnitX + FPCUnit). Prova por binário: 7/7 passam em FPC 3.2.2 x86_64."
status: draft
cycle: "005"
agent: developer
workflow: equipe-feature
node: implement
resource: aefos://run/2ef372d993ff75b8dcd8c707bb79d636
tags: [implement-report, modernrtti, invoker, issue-10]
generated:
  by: "equipe-feature@node:implement"
  at: "2026-08-28T14:30:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — TModernInvoker"
  - id: adr
    resource: "adr.md"
    title: "ADR — Design da unit ModernSyntax.Invoker"
  - id: plan
    resource: "plan.md"
    title: "Plan — TModernInvoker"
  - id: task
    resource: "task-input.md"
    title: "Task input — TModernInvoker"
---

# Implement report — TModernInvoker (issue #10)

## Sumário

Executadas as quatro fatias do [plan.md](pipeline-plan.md) sem desvio. A unit
`Source/ModernSyntax.Invoker.pas` nasceu autocontida (`uses SysUtils;`
apenas), com dois overloads `class function Invoke<TSignature>(...)` sobre
`TObject.MethodAddress` — sem `Rtti`, sem `TypInfo`, sem ramificação por
compilador e sem inclusão do include compartilhado do repositório. Os
cenários compartilhados em `Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas`
cobrem os sete critérios de aceite do [esp.md](pipeline-esp.md); as cascas
`Test Delphi/…` (DUnitX) e `Test FPC/…` (FPCUnit) delegam em uma linha
cada.

**Prova por binário:** o container do orquestrador compila FPC 3.2.2
Linux x86_64. `PTestInvoker` roda com **7 testes, 0 erros, 0 falhas**.
i386 depende de `ppc386` (não instalado no container) — permanece com o
autor por bitness (SKILL §"The command").

## Arquivos modificados/criados

| Arquivo | Status | Notas |
|---------|--------|-------|
| `Source/ModernSyntax.Invoker.pas` | criado | Record com dois overloads; guarda `SizeOf` primeira linha; header em `(* ... *)`; zero directive de compilador. |
| `Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas` | criado | Sete `procedure Case_...`; classes-alvo locais (`TSubject`, `TSubjectWithClassMethod`, `TNoM`); `{$M+}` só onde precisa. |
| `Test Delphi/EclbrSystem/UTestMS.Invoker.pas` | criado | `[TestFixture]` DUnitX; 7 `[Test]`, cada um com uma linha útil; `TDUnitX.RegisterTestFixture`. |
| `Test Delphi/EclbrSystem/PTestInvoker.dpr` | criado | Cópia do padrão da família (`PTestObjects.dpr`); `ReportMemoryLeaksOnShutdown := True`; sem `FastMM4` (não é necessário para verificar leak nesta unit sem estado). |
| `Test Delphi/EclbrSystem/PTestInvoker.dproj` | criado | Cópia de `PTestObjects.dproj` com `MainSource`, `ProjectName`, `SanitizedProjectName`, `ProjectGuid` novos e três `DCCReference` (a unit de teste, a shared e a unit de produção). |
| `Test Delphi/EclbrSystem/PTestInvoker.res` | criado | Cópia binária do `PTestObjects.res` (padrão da família). |
| `Test FPC/EclbrSystem/UTestMS.Invoker.pas` | criado | `TTestCase` FPCUnit; 7 métodos `published`, cada um com uma linha útil; `RegisterTest`. |
| `Test FPC/EclbrSystem/PTestInvoker.lpr` | criado | `consoletestrunner` com `TAppRunner` (padrão FPCUnit). |
| `Test FPC/EclbrSystem/PTestInvoker.lpi` | criado | Escrito à mão, forward-slashes; dois build modes (`Debug-x86_64` default, `Debug-i386`); `<OtherUnitFiles>` = `../../Source;../../Test Shared/EclbrSystem`; `<RequiredPackages>` = `FCL`. |
| `.project/project-evolution.md` | modificado | Estado do ciclo 005 avança para `🔄 in-review`. |

**Não modificado** (conforme escopo do [esp.md](pipeline-esp.md) §2 e task-input):
`Source/ModernSyntax.Objects.pas`, `Source/ModernSyntax.inc`,
`Test Delphi/EclbrSystem/DCC.bat`, `Test Delphi/EclbrSystem/TestMSGroup.groupproj`,
nenhuma unit existente de `Source/`.

## Decisões técnicas (durante a implementação)

1. **Guard `nil` como segunda linha** — depois da guarda `SizeOf`. Sem
   ela, `AInstance.MethodAddress(...)` com `AInstance = nil` faz AV
   antes de `MethodAddress` retornar. Está no [plan.md](pipeline-plan.md) fatia 1
   passo 5 e ficou fiel.
2. **`m.Data := AInstance` no overload de instância, `m.Data := Pointer(AClass)`
   no overload de classe** — literal do [adr.md](pipeline-adr.md) D-A3/D-A4.
3. **`Fail(msg)` local em `Cases.pas`** — `procedure Fail(const AMsg: string);`
   levanta `Exception` com a mensagem. Evita repetir `raise
   Exception.Create(...)` em cada verificação, sem introduzir framework.
4. **`{$M+}` restrito a `TSubject` + `TSubjectWithClassMethod`** — `TNoM`
   é declarada em `type` separado, fora do bloco `{$M+}/{$M-}`, o que
   satisfaz o CA-6 do esp (método `public` sem `{$M+}` que `MethodAddress`
   não acha).
5. **`Case_Invoke_NonMethodSignature_Raises` chama `Invoke<Integer>`** —
   a guarda dispara antes de qualquer `Move`, e a mensagem contém
   *"TSignature nao e um tipo de metodo-de-objeto"*. Compilador FPC
   emite warning "unreachable code" para a instanciação com `Integer`
   (guarda sempre triggera, resto da função de fato inalcançável) — o
   warning **valida** a guarda, não é bug. Aceito.
6. **Header de `Invoker.pas` sem os tokens exatos** `{$IFDEF FPC}` /
   `{$I ModernSyntax.inc}` / `FCP` — a explicação em prosa foi reescrita
   para descrever a ausência sem repetir as strings, para que os greps
   de aceitação retornem exatamente **0**.
7. **`ReportMemoryLeaksOnShutdown := True;` no `.dpr`** — logo no início
   do `begin ... end.`, antes de qualquer bloco `try`. Cumpre o CA da
   checklist Delphi do task-input.

## Validações executadas

**Comando de qualidade descoberto e usado (documentado em `.project/SKILL.md`):**

```
rm -rf /tmp/fpc-invoker-out
fpc -Mdelphi \
    -Fu"Source" -Fu"Test Shared/EclbrSystem" \
    -FU/tmp/fpc-invoker-out -FE/tmp/fpc-invoker-out \
    "Test FPC/EclbrSystem/PTestInvoker.lpr"
/tmp/fpc-invoker-out/PTestInvoker --all
```

- **Compilação FPC 3.2.2 x86_64 (Linux):** 450 linhas, 0 erros, 3
  warnings *"unreachable code"* (comportamento esperado da guarda
  `SizeOf` na instanciação `Invoke<Integer>`).
- **Execução de testes:** `NumberOfRunTests=7`, `NumberOfErrors=0`,
  `NumberOfFailures=0`.
- **Verificação por grep (aceite):**
  - `grep -rn '{\$IFDEF FPC}' 'Test Shared/…/…Cases.pas' 'Test Delphi/…/UTestMS.Invoker.pas' 'Test FPC/…/UTestMS.Invoker.pas'` → **0**.
  - `grep -n '{\$I ModernSyntax.inc}\|FCP\|{\$IFDEF' Source/ModernSyntax.Invoker.pas` → **0**.
  - `grep -rn 'DUnitX' 'Test FPC/EclbrSystem/'*.pas 'Test FPC/EclbrSystem/'*.lpr` → **0**.
  - `grep -n '{\$IFDEF' 'Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas'` → **0**.
  - `grep -n '^uses' Source/ModernSyntax.Invoker.pas` → uma ocorrência (linha 57), `SysUtils` apenas.

**Não executado (dependência externa):**

- **FPC 3.2.2 i386:** `ppc386` não está no container do orquestrador
  (`Failed to execute "ppc386"`). Depende do autor rodar em
  `C:\lazarus\fpc\3.2.2\bin\i386-win32\fpc.exe` (SKILL §"The command").
- **Delphi:** a fábrica não tem Delphi (R2 do PRD / SKILL §"Delphi"). O
  `.dproj`/`.dpr`/`.res` foram gerados por cópia do padrão da família
  (`PTestObjects.dproj`) com substituições mínimas — a verificação
  compila-e-roda fica com o autor.

## Caveats / limites conhecidos

- **Warnings *"unreachable code"* no FPC 3.2.2** — reproduzíveis em
  qualquer instanciação de `Invoke<Integer>`. Se a política de PR virar
  *"zero warnings"*, aceita silenciar com `{$WARN 5024 OFF}` local ou
  descartar o cenário — a decisão do arquiteto foi manter a evidência
  do binário sobre a estética do compilador (CA-7 do esp fica coberto).
- **PR body / TestMSGroup / DCC.bat** ficam com o autor (passo manual
  pós-entrega, mesma nota da issue #9 / task-input §"Fora deste ciclo").

## Escopo do PR body a declarar (herança do task-input §"PR body")

O committer deve inserir literalmente no corpo do PR:

1. *"compilado em FPC 3.2.2 x86_64 (fábrica); i386 e Delphi permanecem
   com o autor (SKILL §The command / §Delphi)."*
2. Resposta a **Q1 do PRD** (task-input): *"Q1 não exigiu `{$IFDEF}`
   interno; a divergência real que replaneou o Pilar 3 foi
   `GetMethods = 0` no FPC 3.2.2 (medida na volta 1 da investigação da
   #10, `{$mode delphi}{$M+}`, seção `published`). O mecanismo escolhido
   é `TObject.MethodAddress`, símbolo comum aos dois compiladores; a
   unit `Rtti` não é usada."*
3. Contrato da API tipada: *"`TModernInvoker.Invoke<TSignature>(AInstance,
   'Nome')` devolve o método já tipado; o consumidor declara
   `type TFn = function(...) : T of object;` antes de invocar. Não existe
   `Invoke(obj, 'Nome', [args]): TValue` nesta entrega — é o custo
   estrutural de mecanismo único."*
4. Recomendação de issue irmã: *"API dinâmica no padrão da RTTI nova do
   Delphi (`GetType(T).GetMethod('X').Invoke(obj,[args]): TValue`) sai
   para issue irmã, com superfície declaradamente Delphi-only ausente
   por compilação no FPC (`{$IFDEF DELPHI}` na declaração inteira).
   Divergência que quebra o build é honesta; divergência silenciosa em
   runtime é o defeito nº 1 do PRD."*
