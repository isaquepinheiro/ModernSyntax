---
type: implement-report
kind: artifact
title: "IMPLEMENT-REPORT — TModernValue.AsType<T> (issue #26)"
description: "Implementado TValueOps nos dois backends (Delphi delega ao nativo; FPC exige tipo exato com raise nomeando origem e destino), TModernValue publico com surface minima, GetValue<T> de TModernRTTIProperty em uma linha (drift §7 fechado), 7 cenarios compartilhados + 1 published local FPC. PTestRTTI verde em x86_64: 17 tests / 0 errors / 0 failures. Prova de mutacao executada e revertida (exit=2 sob mutacao)."
status: stable
cycle: "011"
agent: developer
workflow: equipe-feature
node: implement
resource: aefos://run/38e3bcee8cdc184a2977006358812748
tags: [modernrtti, implement-report, issue-26, fpc, delphi, tvalue, astype]
generated:
  by: "equipe-feature@node:implement"
  at: "2026-08-31T00:00:00Z"
---

# IMPLEMENT-REPORT — issue #26

## Resumo executivo

Implementadas as tres slices do [plan](pipeline-plan.md) num unico commit-set. `PTestRTTI`
compila e passa no `x86_64-linux` da fabrica com **17 testes, 0 erros, 0 falhas**.
A prova de mutacao (D-4 do [adr](pipeline-adr.md) / SKILL.md:92-97) foi executada: trocar
`if not AValue.IsType(TypeInfo(T))` por `if False` em
`Source/ModernSyntax.RTTI.FPC.pas` faz o
`TestModernValue_AsType_DifferentType_RaisesWithOriginAndDestination` falhar
(EAccessViolation na finalizacao do AnsiString extraido a partir de bytes de
TPonto) e o runner devolve **`exit=2`**. Mutacao revertida antes do handoff.

## Arquivos modificados

| arquivo | acao |
|---|---|
| `Source/ModernSyntax.RTTI.pas` | adicionado record publico `TModernValue` (surface minima: `From<T>`, `FromValue`, `AsType<T>`) com XMLDoc D-6 declarando a divergencia de alargamento em voz alta; reescrito `TModernRTTIProperty.GetValue<T>` para uma linha; removido o bloco `{$IFDEF FPC}...{$ELSE}...{$ENDIF}` das linhas 385–397; `TModernRTTIField.GetValue<T>` intacto |
| `Source/ModernSyntax.RTTI.Delphi.pas` | adicionado record `TValueOps` (interface) com `class function AsType<T>(const AValue: TValue): T; static` que delega puramente ao nativo `AValue.AsType<T>` |
| `Source/ModernSyntax.RTTI.FPC.pas` | adicionado record `TValueOps` com `class procedure RaiseIncompatible(...) static` + `class function AsType<T>(...) static`; adicionada 1 resourcestring `SModernValueIncompatibleType`; implementacao usa `IsType(TypeInfo(T))` + `ExtractRawData` |
| `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | +3 fixtures (`TPonto`, `TColor`, `TValueObj` + constructor); +7 cenarios `Scenario_ModernValue_AsType_*` (String/Integer/Boolean/Double/Object/Record/Enum); `Math` adicionado ao uses da implementation (SameValue para Double); ZERO `{$IFDEF}` |
| `Test FPC/EclbrSystem/UTestMS.RTTI.pas` | +8 published: 7 delegando aos cenarios + 1 LOCAL `TestModernValue_AsType_DifferentType_RaisesWithOriginAndDestination` que constroi TValue.From<TPonto>, chama AsType<string>, checa `EModernRTTIError` com `Pos('TPonto', ...) > 0` e `Pos('AnsiString', ...) > 0` |
| `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` | +7 `[Test]` delegando aos cenarios; SEM equivalente ao teste de excecao FPC (D-9 do ADR) |
| `.project/project-evolution.md` | flip do marker da issue #26: `🔄 in-pipeline` → `🔄 in-review` |

## Decisoes tecnicas tomadas na implementacao

### D-IMPL-1 — Trap medido: "Global Generic template references static symtable"

O corpo do ADR mostra o backend FPC como:

```pascal
class function TValueOps.AsType<T>(const AValue: TValue): T;
begin
  if not AValue.IsType(TypeInfo(T)) then
    raise EModernRTTIError.CreateFmt(SModernValueIncompatibleType,
      [string(AValue.TypeInfo^.Name), string(PTypeInfo(TypeInfo(T))^.Name)]);
  AValue.ExtractRawData(@Result);
end;
```

Essa forma quebra a compilacao no FPC 3.2.2 com:
`Error: Global Generic template references static symtable`. O motivo e o
mesmo trap do issue #12 (SKILL.md:99-104): um metodo generico declarado
dentro de um record no `interface` nao pode referenciar simbolos que morem
no static symtable da `implementation` — `SModernValueIncompatibleType` (resourcestring
no `implementation`) e a raiz da falha. Um helper `procedure` livre declarado
tambem no `implementation` reproduz o mesmo erro (medido).

Solucao aplicada: expor uma segunda funcao NAO-generica no proprio record,
`class procedure TValueOps.RaiseIncompatible(AOrigin, ADestination: PTypeInfo); static`,
e delegar o raise a ela. Como a assinatura esta no `interface`, o simbolo e
publico; o corpo (na `implementation`) resolve resourcestring e excecao
livremente. A `AsType<T>` generica passa apenas dois `PTypeInfo` para o
helper — nao toca simbolo estatico. Compila. `RaiseIncompatible` esta
documentada como "interno — nao faz parte da API publica de
ModernSyntax.RTTI" (o consumidor nao ve o `TValueOps` do backend; so ve
`TModernValue`). Nenhuma decisao do ADR e alterada.

O backend Delphi NAO precisa dessa quebra: sua `AsType<T>` e literalmente
`Result := AValue.AsType<T>`, sem qualquer referencia a resourcestring
propria da unit.

### D-IMPL-2 — Double comparison com epsilon

O plan previa `SameValue(..., 3.14)` para o cenario `_Double`. Isso e
necessario: no FPC 3.2.2, `TValue.From<Double>(3.14)` armazena o literal
como Extended internamente; a extracao para Double via `ExtractRawData`
devolve `3.1400000000000001`, que difere bit-a-bit do literal Double `3.14`
usado na comparacao (medido — comparacao `<>` falhou). `SameValue` com
tolerancia epsilon padrao do Double resolve. `Math` foi adicionado ao uses
da implementation de `UScenarios.RTTI.pas`.

### D-IMPL-3 — Fixture `TValueObj` no shared

Para o cenario `_Object`, foi criada `TValueObj = class` com propriedade
`Tag` e constructor `Create(ATag)`. Fica no `interface` de `UScenarios.RTTI.pas`
sem `{$M+}` (nao precisa — o cenario roundtripa a referencia, nao inspeciona
propriedades). O cenario cria uma instancia, encapsula via
`TModernValue.From<TObject>(LObj).AsType<TObject>`, verifica que devolve a
MESMA referencia e que `Tag` continua `7`. Deteccao de mutacao dupla:
identidade de referencia + estado do objeto.

## Validacoes executadas (comandos de qualidade)

Comandos discovered em `.project/SKILL.md` (secoes "Toolchain & quality
commands" e "agent-discovered 2026-08-28"):

1. Build + run principal (`PTestRTTI` — x86_64 fabrica):
   ```
   rm -rf /tmp/fpcbuild && mkdir -p /tmp/fpcbuild
   fpc -Mdelphi -Fu"Source" -Fu"Test Shared/EclbrSystem" \
       -Fu"Test FPC/EclbrSystem" \
       -FU/tmp/fpcbuild -FE/tmp/fpcbuild \
       "Test FPC/EclbrSystem/PTestRTTI.lpr"
   /tmp/fpcbuild/PTestRTTI --all -a --format=plain
   ```
   → **17 tests / 0 errors / 0 failures / exit=0**.

2. Prova de mutacao (`if not AValue.IsType(TypeInfo(T))` → `if False`):
   → **1 error / 0 failures / exit=2**. Mutacao revertida.

3. Regressao dos outros runners FPC (nao devem quebrar por causa da nova
   `TValueOps` nem por causa do novo `TModernValue`):
   - `PTestAttributes.lpr` — **545 lines compiled, ok**
   - `PTestInvoker.lpr` — **450 lines compiled, ok** (link ok)
   - `PTestModernCallback.lpr` — **513 lines compiled, ok** (link ok)

4. `grep -c "IFDEF" "Test Shared/EclbrSystem/UScenarios.RTTI.pas"` → **0**
   (baseline preservado; CA-5 respeitado).

5. `grep -n "\{\$IFDEF" Source/ModernSyntax.RTTI.pas` (fora de comentarios)
   → APENAS `{$IFDEF FPC}` na clausula `uses` da `implementation` (linha 376).
   Todos os outros hits sao ocorrencias EM COMENTARIOS (linhas 19, 20, 320,
   321, 372, 412, 413, 443) que descrevem a regra ou o dispatch — nao
   diretivas de compilador.

## Caveats

- **Compilacao Delphi (R1 do ESP): NAO exercitada** — a fabrica nao tem
  DUnitX/dcc32 (SKILL.md:16-27). O risco de que `TValueOps` como record com
  `class function AsType<T>(...) static` compile no Delphi 12 permanece
  aberto; se falhar, o remedio esta previsto no Slice 1 do plan
  (transformar `TValueOps` em `class` na mesma unit). Registrar literal
  no corpo do PR, sem suavizar.

- **Compilacao FPC i386: NAO exercitada** — a fabrica so tem `x86_64-linux`
  (SKILL.md:122-124). O autor confirma i386 no Windows.

- **`consoletestrunner` exit code sob "errors"** — durante a prova de
  mutacao observei que uma primeira leitura do stdout via `tail` mostrou
  `exit=0`, mas a reexecucao com redirecionamento para arquivo
  (`> /tmp/mut_out.txt`) trouxe `exit=2` consistente. O comportamento e o
  esperado; a leitura inicial parecia inconsistente apenas por confusao
  de shell (o exit=0 anterior era da etapa de compilacao). Documentado
  aqui para o proximo agente nao tropecar.

## Auto-enriquecimento SKILL.md

Nao apliquei APPEND novo — todos os comandos usados neste ciclo ja constam
de `.project/SKILL.md` (secoes principal + "agent-discovered 2026-08-28"
+ "agent-discovered 2026-08-31"). O trap "Global Generic template
references static symtable" ja aparece em SKILL.md:99-104 (historico da
issue #12) — nomear ali a solucao "helper NAO-generico no mesmo record" e
uma decisao editorial que cabe melhor ao autor humano; deixei o passo-a-passo
completo aqui e no comentario dentro do backend FPC.

## Referencias

- [esp](pipeline-esp.md) — criterios formais.
- [adr](pipeline-adr.md) — decisao e o que foi descartado.
- [plan](pipeline-plan.md) — ordem de execucao.
- [task-input](pipeline-task-input.md) — handoff operacional.
