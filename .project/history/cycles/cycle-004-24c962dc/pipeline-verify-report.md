---
type: verify-report
kind: artifact
title: "Verify report — ModernSyntax.Callback (ciclo 004, issue #7)"
description: "Analise estatica, compilacao FPC 3.2.2 e execucao FPCUnit para a unit ModernSyntax.Callback: 0 erros, 4/4 testes passados."
status: stable
cycle: "004"
agent: quality
workflow: equipe-feature
node: verify
resource: aefos://run/24c962dcc2be1819336ca1fea18ae949
tags: [verify-report, callbacks, modernrtti, issue-7, fpc]
generated:
  by: "equipe-feature@node:verify"
  at: "2026-08-28T16:00:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — Callbacks transversais"
  - id: implement-report
    resource: "implement-report.md"
    title: "Implement report — developer"
---

# Verify report — ModernSyntax.Callback (ciclo 004)

## Toolchain

- **FPC:** 3.2.2+dfsg-46 (x86_64-linux) — disponivel na fabrica
- **ppc386 / lazbuild:** ausentes (retornam 127) — nao cobertos aqui
- **Delphi:** ausente na fabrica; compilacao permanece com o autor

## Checks executados

### 1. Compilacao da unit principal

```
mkdir -p /tmp/fpcbuild && rm -f /tmp/fpcbuild/*.o /tmp/fpcbuild/*.ppu
fpc -Mdelphi -FU/tmp/fpcbuild Source/ModernSyntax.Callback.pas
```

**Resultado:** `190 lines compiled, 0.0 sec` — sem erros, sem warnings.

### 2. Compilacao e execucao FPCUnit (x86_64)

```
rm -f /tmp/fpcbuild/*.o /tmp/fpcbuild/*.ppu
fpc -Mdelphi -FU/tmp/fpcbuild \
    -Fu"Source" -Fu"Test Shared/EclbrSystem" -Fu"Test FPC/EclbrSystem" \
    -o/tmp/fpcbuild/PTestModernCallback \
    "Test FPC/EclbrSystem/PTestModernCallback.lpr"
/tmp/fpcbuild/PTestModernCallback --all -a --format=plain
```

**Resultado de compilacao:** `513 lines compiled, 0.2 sec` — sem erros.

**Resultado dos testes:**
```
Time:00.000 N:4 E:0 F:0 I:0
  TCallbackTests Time:00.000 N:4 E:0 F:0 I:0
    00.000  CallbackOf_MethodOfObject_Func_Returns
    00.000  CallbackOf_MethodOfObject_Proc_Executes
    00.000  CallbackOf_MethodOfObject_Predicate_ReturnsBoolean
    00.000  Interface_CapturesState_ViaHelperClass

Number of run tests: 4
Number of errors:    0
Number of failures:  0
```

**Veredicto parcial:** ✅ 4/4 casos passados.

### 3. Grep checks de conformidade (CA-4, CA-8)

| Verificacao | Comando | Resultado |
|-------------|---------|-----------|
| CA-4: sem IFDEF FPC em Test Shared/Delphi/FPC | `grep -rn '{$IFDEF FPC}' "Test Shared/" "Test Delphi/" "Test FPC/"` | **0 linhas** ✅ |
| CA-8a: sem `{$I ModernSyntax.inc}` na unit | `grep -n '{$I ModernSyntax.inc}' Source/ModernSyntax.Callback.pas` | **0 linhas** ✅ |
| CA-8b: sem token `FCP` na unit | `grep -n 'FCP' Source/ModernSyntax.Callback.pas` | **0 linhas** ✅ |

**Observacao sobre IFDEF TESTINSIGHT:** O `PTestModernCallback.dpr` contem `{$IFDEF TESTINSIGHT}` — identico a todos os demais `PTest*.dpr` do repositorio. Nao e `{$IFDEF FPC}` e e convencao estabelecida no repositorio. Nao e violacao da CA-4 nem da CA-5 do PRD.

**Observacao sobre "IFDEF" em comentarios:** As units `UTestMS.Callback.Scenarios.pas`, `UTestMS.Callback.pas` (Delphi) e `UTestMS.Callback.pas` (FPC) mencionam a palavra "IFDEF" SEM chaves, em prosa de comentario (descrevendo o que o grep deve retornar). Isso e documentacao, nao diretivas de compilador. Nao viola nenhum criterio.

### 4. Divergencia formal DT-1 — `Callback.&Of`

O metodo do factory foi declarado como `&Of` em vez de `Of` porque `of` e palavra reservada em Pascal (Delphi e FPC, case-insensitive). O implementador mediu o erro:

```
testof2.pas(6,20) Fatal: Syntax error, "identifier" expected but "OF" found
```

A fuga com `&` e o mecanismo padrao Pascal para usar palavras reservadas como identificadores. O NOME do simbolo permanece `Of`; o consumidor escreve `Callback.&Of(...)`. Esta solucao e aceita em ambos os compiladores. O ADR D-A3 escreveu `Of` sem prever a colisao com palavra reservada — a solucao do implementador e a mais proxima da letra do ADR que a linguagem permite.

**Avaliacao:** Divergencia formal declarada, justificada e inevitavel. Nao e erro do implementador; e restricao da linguagem.

### 5. i386 — nao testado nesta execucao

`ppc386` retorna 127 na fabrica. O `.lpi` declara o build mode `Debug-i386` para o autor executar via `lazbuild`. CA-6 do ESP exige i386 — esta validacao permanece com o autor.

## Resumo de conformidade

| Criterio | Status | Notas |
|----------|--------|-------|
| CA-1: interfaces compilam sem modificacao consumidor | ✅ | FPC 3.2.2 x86_64 confirmado |
| CA-2: `Callback.&Of` funciona para method-of-object | ✅ | Coberto pelos 4 casos de teste |
| CA-3: captura via classe helper | ✅ | `Interface_CapturesState_ViaHelperClass` passou |
| CA-4: zero `{$IFDEF FPC}` em Test Shared/Delphi/FPC | ✅ | grep retornou 0 |
| CA-5: `.lpi` para FPC 3.2.2 entregue | ✅ | `Test FPC/EclbrSystem/PTestModernCallback.lpi` presente |
| CA-6: FPC x86_64 | ✅ | Compilado e 4/4 testes passaram |
| CA-6: FPC i386 | ⚠️ ENV | `ppc386` ausente na fabrica — com o autor |
| CA-7: declaracao literal no PR body | ⏳ | Responsabilidade do node committer/release |
| CA-8: sem `{$I ...inc}` nem token `FCP` | ✅ | grep confirmado |
| RN-5: `uses SysUtils` apenas | ✅ | Verificado no fonte |

## Veredicto

**PASSED** — a entrega compila e todos os testes FPCUnit x86_64 passam. As lacunas
restantes (i386, Delphi, declaracao no PR body) sao responsabilidades do autor ou de
nodes subsequentes, devidamente documentadas nos caveats do implement-report.
