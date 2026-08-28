---
type: conventions
title: "SKILL: ModernSyntax — toolchain and quality commands"
description: The executable build and test recipe for this project, per compiler, plus the two traps that make a green result lie. Read this before running anything.
status: stable
tags: [toolchain, build, test, fpc, lazarus, delphi, dunitx, fpcunit, quality-gates]
---

# Toolchain and quality commands

This project targets **two compilers with different capabilities**. A command that
is correct for one is wrong for the other. Read the whole file before running
anything — two of the notes below exist because a green result lied.

## Delphi — the incumbent, and the one this repository was built for

**Build system:** Embarcadero MSBuild (`.dproj`). **Test framework:** DUnitX.

⚠️ **DUnitX is NOT vendored in this repository.** `find . -iname "DUnitX*.pas"` returns
**0**; it ships with the Delphi IDE, which is why the `PTest*.dpr` files can write
`uses DUnitX.TestFramework` with no relative path.

**Consequence:** Delphi builds require a Delphi installation. Neither the Aefos
factory container nor the orchestrator has one — **the author is the only party who
can compile the Delphi side.** Every PR must say so explicitly rather than implying
both compilers were exercised.

## FPC / Lazarus — the new target

**Compiler:** FPC **3.2.2**. **Test framework:** **FPCUnit**, which is *native* to
FPC 3.2.2 — `units/<arch>/fcl-fpcunit/` carries `fpcunit.ppu`, `consoletestrunner.ppu`
and `digesttestreport.ppu`. **Never DUnitX on the FPC side**; see the trap below.

### The command

```
fpc -Mdelphi \
    -Fu"<repo>/Source" \
    -Fu"<repo>/Test Shared/EclbrSystem" \
    -FU<out> -FE<out> \
    PTest<Name>.lpr
```

Run it for **both** bitnesses; a PR is only proven when both are green:

| target | compiler |
|---|---|
| `x86_64` | `fpc` (Linux container) / `C:\lazarus64\fpc\3.2.2\bin\x86_64-win64\fpc.exe` |
| `i386` | `C:\lazarus\fpc\3.2.2\bin\i386-win32\fpc.exe` |

`lazbuild` is deliberately **absent** from the factory container: it reads `.lpi`,
plain `fpc` reads `.lpr`/`.pas` with `-Fu`, and Debian only ships `lazbuild` inside
the full graphical `lazarus-ide` package. **Write the `.lpr` and pass `-Fu`.**

## ⚠️ Two traps that make a green result lie

### 1. NEVER compile all of `Source/` to prove a change

**Measured on FPC 3.2.2, one unit at a time: 0 of 16 units in `Source/` compile.**

| reason | units |
|---|---|
| `Declaration of generic inside another generic is not allowed` | `Currying`, `Option`, `ResultPair`, `Tuple` |
| `identifier … no member "Create"` / `"AsType"` | `ArrowFun`, `Crypt`, `DotEnv`, `Match`, `Std`, `ModernSyntax` |
| Delphi-only RTL unit absent in FPC | `Async`, `Coroutine` (`Threading`), `RegExpression` (`RegularExpressions`) |
| `ENDIF without IF(N)DEF` | `Objects`, `Stream` |
| `Identifier not found "TFunc"` | `Safetry` |

**This is expected, not a defect.** The owner's standing decision: *existing code is
NOT retrofitted for FPC; a unit is made portable only when a feature actually needs
it, inside that feature's own issue.*

So a build that throws the whole tree at the compiler reports the repository as
broken **every time**, and that red says nothing about the change under test.
**Compile the feature's test project**, which pulls in via `uses` only what the
feature actually reaches.

### 2. ALWAYS clean the output directory before compiling

FPC reuses cached `.ppu` files and **will report green over stale code**. Measured:

```
suite green (1 test, 0 failures)
mutate the test so it must fail   →  mutation confirmed on disk with grep
recompile WITHOUT clearing -FU    →  still 0 failures        ← the lie
rm -rf <out> && recompile         →  1 failure               ← the truth
```

Every proving build starts with `rm -rf <out>`.

## What a PR must declare

Because no single party can compile both sides, the PR body states, in words:

> compiled on FPC 3.2.2 x86_64 and i386; **not** compiled on Delphi

…or the converse. **Silence is not a claim of success** — the two rejected PRs on
this repository (#11 and #12) both passed a green pipeline while failing to build.

## History — why this file exists

Written after two consecutive delivery cycles shipped code that does not compile:

- **#11** produced a Lazarus project targeting **DUnitX** (99 hits in the diff, zero
  FPCUnit) — a framework FPC does not have and this repository does not vendor.
- **#12** shipped `Global Generic template references static symtable`, an error no
  amount of reading finds: the code looks correct, and the constraint only surfaces
  when a compiler expands the generic.

Both were closed unmerged. Both failed on the FPC side. Recorded as issue **#4**.

Related: `analysis/02-stack.md` (stack and build system), `strategy/2026-08-27-modernrtti/PRD.md` (why FPC became a target).

---

## Toolchain & quality commands (agent-discovered 2026-08-28)

Descobertos ao rodar o ciclo 004 (implementer da issue #7). Uteis para
qualquer ciclo que toque `Source/*.pas` ou `Test FPC/`.

- **FPC disponivel na fabrica:** `fpc -iV` → `3.2.2`, target
  `x86_64-linux` (`fpc -iTP`). **NAO ha** cross-compiler i386
  (`ppc386` retorna `127`) e **NAO ha** `lazbuild`. Validacao i386 e
  Lazarus fica com o autor.
- **Compilar uma unit isoladamente (recomendado):**
  ```
  mkdir -p /tmp/fpcbuild
  rm -f /tmp/fpcbuild/*.o /tmp/fpcbuild/*.ppu
  fpc -Mdelphi -FU/tmp/fpcbuild Source/ModernSyntax.<Unit>.pas
  ```
  Limpe o diretorio de saida antes de cada build — build incremental
  do FPC reporta verde sobre .ppu velhos.
- **Compilar o binario de testes FPCUnit fora do lazbuild:**
  ```
  rm -f /tmp/fpcbuild/*.o /tmp/fpcbuild/*.ppu
  fpc -Mdelphi -FU/tmp/fpcbuild \
      -Fu"Source" -Fu"Test Shared/EclbrSystem" -Fu"Test FPC/EclbrSystem" \
      -o/tmp/fpcbuild/<Programa> "Test FPC/EclbrSystem/<Programa>.lpr"
  /tmp/fpcbuild/<Programa> --all -a --format=plain
  ```
  A flag `-Mdelphi` e obrigatoria: as units usam sintaxe Delphi e o
  `.lpi` do lado FPC seta `SyntaxMode Value="Delphi"` (equivalente
  quando compilado pelo `lazbuild`).
- **NAO compilar `Source/*.pas` inteiro.** Medido: 0 de 16 units da
  arvore compilam no FPC 3.2.2 estavel — a maioria depende de
  `reference to` ou do `.inc` bugado (ADR/plan do ciclo 004, D-A5).
- **Zero cobertura Delphi na fabrica.** Compilacao Delphi
  (`dcc32`/`bcc32`) permanece com o autor humano. `.dproj` e escrito no
  padrao dos `PTest*.dpr` existentes.

## Include paths — PTestAttributes (agent-discovered 2026-08-28)

`PTestAttributes.lpr` inclui `UTestMS.Attributes.Symbols.inc` via
`{$I UTestMS.Attributes.Symbols.inc}`. O `.lpi` registra o diretorio
correto, mas `plain fpc` nao le o `.lpi`. Sem o flag `-Fi`, o compilador
aborta com `Cannot open include file`.

Adicionar `-Fi"Test Shared/EclbrSystem"` resolve. Comando completo:

```
rm -rf /tmp/fpcbuild
mkdir -p /tmp/fpcbuild
fpc -Mdelphi \
    -FU/tmp/fpcbuild \
    -Fu"Source" \
    -Fu"Test Shared/EclbrSystem" \
    -Fu"Test FPC/EclbrSystem" \
    -Fi"Test Shared/EclbrSystem" \
    -o/tmp/fpcbuild/PTestAttributes \
    "Test FPC/EclbrSystem/PTestAttributes.lpr"
/tmp/fpcbuild/PTestAttributes --all -a --format=plain
```

Outros projetos de teste nao requerem `-Fi` adicional (nao tem `.inc`
no diretorio compartilhado).
