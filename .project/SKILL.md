---
type: skill
title: "ModernSyntax — bundle skill notes"
description: "Notas operacionais para agentes trabalhando no bundle .project/ do repositorio ModernSyntax."
tags: [skill, modernsyntax, toolchain]
---

# ModernSyntax — bundle skill notes

Notas operacionais para agentes que atuam neste bundle. Conteudo
autorizado por humano (base minima); agentes podem APENAS APENDER
secoes marcadas com `agent-discovered <data>`.

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
