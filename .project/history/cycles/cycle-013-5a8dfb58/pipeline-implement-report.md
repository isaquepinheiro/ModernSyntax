---
type: implement-report
kind: artifact
title: "IMPLEMENT-REPORT — TModernRTTIContext: Create/Free/GetType/GetTypes/FindType, IInterface token, sem GetPackages (issue #28)"
description: "Slice 1 + Slice 2 + Slice 3 num unico commit-set. IModernRTTIContextToken opaco (so GUID), TModernRTTIContext record com FToken: IInterface, cinco funcoes livres Context* nos dois backends com paridade estrita, TFPCContextToken com registry per-instancia (TList de PTypeInfo), TDelphiContextToken delegando ao TRttiContext nativo per-instancia. ContextFree eliminado — refcount libera. TModernRTTIType.IsNil (Result := FType = nil) para inspecionar resposta legitima de FindType. FPC 3.2.2 x86_64 verde 28/28 (baseline era 23). Mutacao verificada: remover raise em ContextGetTypes torna Scenario_Context_GetTypes_EmptyRegistry_Raises vermelho (exit=2)."
status: stable
cycle: "013"
agent: developer
workflow: equipe-feature
node: implement
resource: aefos://run/5a8dfb58a24f74263fa58fa581f465c4
tags: [modernrtti, implement-report, issue-28, fpc, delphi, context, iinterface, registry]
generated:
  by: "equipe-feature@node:implement"
  at: "2026-09-01T00:00:00Z"
---

# IMPLEMENT-REPORT — issue #28

## Resumo executivo

Todas as tres slices do [plan](pipeline-plan.md) num unico commit-set, na ordem
prescrita (unit publica → backends em paridade → cenarios + wrappers).
`PTestRTTI.lpr` compila e passa na fabrica x86_64-linux com
**28 testes / 0 errors / 0 failures / exit=0** (cinco a mais que o
baseline de 23 do ciclo 012). Mutacao obrigatoria (D-28.10 do
[adr](pipeline-adr.md)) verificada: **remover** `raise EModernRTTIError.Create(
SModernRTTIError_EmptyRegistry)` de `ContextGetTypes` no backend FPC
faz `Scenario_Context_GetTypes_EmptyRegistry_Raises` cair com
`ETestScenarioFailed: GetTypes sobre registry vazio nao levantou
EModernRTTIError — proteção D-28.4 silenciada`; o runner devolve
**`exit=2`**. Revertido antes do handoff; build final verde reconfirmado.
Regressao verde nos demais runners FPC (`PTestInvoker`,
`PTestModernCallback` — compilam sem erros).

## Arquivos modificados

| arquivo | ação |
|---|---|
| `Source/ModernSyntax.RTTI.pas` (interface) | +`IModernRTTIContextToken` (interface vazia, so GUID `{9D4E0C7C-2F0D-4E0A-9C7A-2D5F1A028E13}`); +`TModernRTTIContext` record publico com `FToken: IModernRTTIContextToken` e sete membros publicos (`Create`, `Free`, `GetType` x2, `RegisterType`, `GetTypes`, `FindType`); +`TModernRTTIType.IsNil` predicado; +XMLDoc de `TModernRTTI.GetType(AClass)` declarando que nao alimenta `TModernRTTIContext.GetTypes` |
| `Source/ModernSyntax.RTTI.pas` (implementation) | +`TModernRTTIType.IsNil` (`Result := FType = nil`); +bloco `{ TModernRTTIContext }` com corpos delegando `Create/Free/GetType/RegisterType/GetTypes/FindType` a `Context*` do backend |
| `Source/ModernSyntax.RTTI.Delphi.pas` | +5 declaracoes `Context*` no `interface` (paridade estrita); +classe privada `TDelphiContextToken = class(TInterfacedObject, IModernRTTIContextToken)` com `FContext: TRttiContext` alocado per-instancia; +corpos delegando ao nativo (`ContextGetTypes` mapeia `TRttiContext.GetTypes`; `ContextFindType` delega ao `FindType` nativo; `ContextRegisterType` no-op logico) |
| `Source/ModernSyntax.RTTI.FPC.pas` | +5 declaracoes `Context*` no `interface` (paridade estrita); +`uses Classes` na `implementation`; +resourcestring `SModernRTTIError_EmptyRegistry`; +classe privada `TFPCContextToken = class(TInterfacedObject, IModernRTTIContextToken)` com `FContext: TRttiContext` + `FRegistry: TList` alimentado por `RegistryEnsure`; +`ContextGetTypes` que levanta `EModernRTTIError` sobre registry vazio; +`ContextFindType` ramificando por `Kind` e resolvendo **so** `tkClass` (`GetTypeData(P)^.UnitName + '.' + P^.Name`); nao encontrado → `TModernRTTIType.FromRtti(nil)` |
| `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | +5 declaracoes de cenarios no `interface`; +helper `CtxHasTypeByName`; +5 corpos `Scenario_Context_*` (padrao `try/except on E: EModernRTTIError` + `Fail(...)`; zero `{$IFDEF}`, zero `Assert`, zero `Exception` generica, zero `AssertException`). Cenario 5 afirma **quatro** coisas encadeadas (D-28.10) |
| `Test FPC/EclbrSystem/UTestMS.RTTI.pas` | +5 `published` procedures cobrindo os cinco cenarios (inclui `TestContext_GetTypes_EmptyRegistry_Raises` — FPC-only) |
| `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` | +4 `[Test]` methods (todos menos `TestContext_GetTypes_EmptyRegistry_Raises` — o pool nativo do Delphi torna registry-vazio impossivel de simular) |
| `.project/project-evolution.md` | flip do marker do ciclo 013 / issue #28: `🔄 in-pipeline` → `🔄 in-review` |

Runners (`PTestRTTI.lpr`, `PTestRTTI.dpr`, `.lpi`) e `PTestRTTI.lpi`:
**inalterados** — a nova `TFPCContextToken` mora dentro de
`ModernSyntax.RTTI.FPC.pas`, ja incluida pelo runner via `uses` transitivo.

## Decisoes tecnicas tomadas na implementacao

### D-IMPL-1 — `TRttiContext` do FPC nao expoe `Free` publico

O plan sugeria `Destroy` do `TFPCContextToken` fazendo `FContext.Free;`.
**Medido**: no FPC 3.2.2, `TRttiContext` e um record com `FContextToken:
IInterface` e o refcount libera automaticamente ao sair de escopo do
objeto que o carrega. Nao ha metodo `Free` publico no `TRttiContext` do
FPC (medido: `Error: identifier idents no member "Free"` quando invocado
sobre `FContext`). Solucao mantida DENTRO do escopo do plan: `Destroy` do
`TFPCContextToken` libera apenas `FRegistry.Free`; o `FContext` (record
valor) e liberado pelo próprio scope do objeto. No lado Delphi
(`TDelphiContextToken.Destroy`), a chamada `FContext.Free` **e** valida
(`TRttiContext.Free` publico da RTL Embarcadero) e foi mantida — a
divergencia esta ancorada em API real dos dois compiladores, nao em
decisao arbitraria.

Consequencia sobre o cenario 5 (`_CopyByValue_SharesState_NoUseAfterFree`):
inalterada — o teste bate no `FRegistry` (que **e** liberado
explicitamente) e nas afirmacoes de compartilhamento/refcount, que
funcionam identicamente nos dois backends.

### D-IMPL-2 — `RegistryEnsure` como helper interno

Extraido para uma funcao helper na `implementation` do FPC porque
`ContextGetType` **e** `ContextRegisterType` fazem exatamente a mesma
coisa (adicionar ao registry se ausente, devolver o handle). Duplicar
seria pedir para as duas divergirem em manutencao futura. `RegistryEnsure`
usa `TList.IndexOf` (comparacao por Pointer — o proprio identificador
`PTypeInfo` e imutavel), evitando laco manual.

### D-IMPL-3 — Cenario 5 (`_CopyByValue_SharesState_NoUseAfterFree`) afirma quatro coisas

O ADR (D-28.10) fala em "tres coisas encadeadas" no texto do relatorio,
mas o proprio comentario do task-input pede **quatro** (enxerga
bidirecional; sobrevive ao Free da outra copia; B.Free posterior nao
levanta). Optei pelas quatro — a (b) especificamente (estado
compartilhado nos DOIS sentidos: B registra, A ve) e a que mata o desenho
`FHandle: Pointer` mais direto que qualquer outra: com Pointer, LB seria
uma copia independente e (b) falharia antes de (c). Sem (b), o cenario
passaria verde sobre um desenho em que LB e alias de LA mas as duas
"tabelas" divergem.

### D-IMPL-4 — Qualified name montado como `UnitName + '.' + Name`

Confirmado com o cenario `_FindType_Class_Found` compilando e passando
verde no FPC: `TPortableFixture` declarada em `unit UScenarios.RTTI`
resolve por `'UScenarios.RTTI.TPortableFixture'` — o `UnitName` retornado
por `GetTypeData(P)^.UnitName` inclui o namespace pontuado exatamente
como declarado. Nenhum tratamento especial de dot-separator no meio do
UnitName foi necessario.

## Validacoes executadas (comandos de qualidade)

Comandos discovered em `.project/SKILL.md` (secoes principal + agent-discovered).

1. **Build + run principal** (`PTestRTTI` — x86_64 fabrica):
   ```
   rm -rf /tmp/fpcbuild && mkdir -p /tmp/fpcbuild
   fpc -Mdelphi -Fu"Source" -Fu"Test Shared/EclbrSystem" \
       -Fu"Test FPC/EclbrSystem" \
       -FU/tmp/fpcbuild -FE/tmp/fpcbuild \
       "Test FPC/EclbrSystem/PTestRTTI.lpr"
   /tmp/fpcbuild/PTestRTTI --all -a --format=plain
   ```
   → **28 tests / 0 errors / 0 failures / exit=0** (baseline era 23; +5).

2. **Mutacao obrigatoria** (D-28.10 do ADR / SKILL.md:79-89):
   remover `raise EModernRTTIError.Create(SModernRTTIError_EmptyRegistry)`
   em `ContextGetTypes` do backend FPC:
   → **28 tests / 1 error / 0 failures / exit=2** —
   `TestContext_GetTypes_EmptyRegistry_Raises` cai com `ETestScenarioFailed:
   GetTypes sobre registry vazio nao levantou EModernRTTIError — proteção
   D-28.4 silenciada`. Mutacao revertida; rebuild verde reconfirmado
   (28/0/0/exit=0).

3. **Regressao dos outros runners FPC** (nao devem quebrar por causa de
   `Classes` novo na `uses` da `implementation` do backend FPC nem das
   novas Context*):
   - `PTestInvoker.lpr` → **450 lines compiled, 0 errors**
   - `PTestModernCallback.lpr` → **513 lines compiled, 0 errors**

4. **Guardrails de arquitetura**:
   - `grep -n "\{\$IFDEF" Source/ModernSyntax.RTTI.pas` (fora de
     comentarios) → APENAS `{$IFDEF FPC}` da `uses` da `implementation`
     (linha 552). Todos os demais hits sao em COMENTARIOS descritivos.
     API-MAP §7 preservado.
   - `grep -c "^function Context" Source/ModernSyntax.RTTI.FPC.pas`
     = `grep -c "^function Context" Source/ModernSyntax.RTTI.Delphi.pas`
     = **10** (5 declaracoes no interface + 5 implementacoes) — paridade
     estrita.
   - `grep -n "\{\$IFDEF FPC" "Test Shared/EclbrSystem/UScenarios.RTTI.pas"`
     → sem novas ocorrencias (CA-5 preservado).
   - `grep -nE "AssertException|Assert\(|raise Exception\." "Test Shared/EclbrSystem/UScenarios.RTTI.pas"`
     nos novos cenarios → sem ocorrencias.

## Caveats

- **Compilacao Delphi (R5 do ESP): NAO exercitada** — a fabrica nao tem
  `dcc32` (SKILL.md:16-27). O padrao segue o desenho consagrado da RTL do
  Delphi (`TRttiContext.FContextToken: IInterface` no proprio `rtti.pas`
  da Embarcadero), e a classe `TDelphiContextToken(TInterfacedObject,
  IModernRTTIContextToken)` com `FContext: TRttiContext` per-instancia e
  padrao trivial de RTL. **Primeira coisa a confirmar no build Delphi.**

- **Compilacao FPC i386: NAO exercitada** — a fabrica so tem
  `x86_64-linux` (SKILL.md:122-124). O autor confirma i386 no Windows.
  Layout de `TTypeData` para `tkClass` (`UnitName` como primeiro campo
  variavel) e simetrico entre bitness — nenhuma aritmetica literal de
  ponteiro foi introduzida.

- **`TRttiContext.Free` no destructor Delphi vs. FPC**: no Delphi
  `TRttiContext.Free` e publico e foi chamado no `Destroy`; no FPC nao
  ha `Free` publico e o record e liberado ao sair de escopo do objeto
  que o hospeda (`TFPCContextToken`) — comportamento assimetrico
  ancorado em API real (nao em decisao), documentado no D-IMPL-1
  acima. Nao afeta a semantica de refcount na superficie publica.

## Auto-enriquecimento SKILL.md

Nao apliquei APPEND novo. Os comandos usados neste ciclo ja estao em
`.project/SKILL.md` (secoes principal + "agent-discovered 2026-08-28" +
"agent-discovered 2026-08-31"). O trap D-IMPL-1 ("TRttiContext do FPC
nao expoe `Free` publico") e semantica RTL, nao trap de toolchain —
cabe ao autor humano promover se preferir.

## Referencias

- [esp](pipeline-esp.md) — criterios formais e checklist.
- [adr](pipeline-adr.md) — decisoes D-28.1 a D-28.11 e o que foi descartado.
- [plan](pipeline-plan.md) — ordem de execucao em 3 slices.
- [task-input](pipeline-task-input.md) — handoff operacional.
