---
type: implement-report
kind: artifact
title: "IMPLEMENT-REPORT — TModernVisibility publico, fecha vazamento em Method.Visibility, adiciona Property.Visibility (issue #42)"
description: "Slice 1 + Slice 2 + Slice 3 num unico commit-set. TModernVisibility declarado antes de TModernRTTIField; TModernRTTIMethod.Visibility troca tipo (permanece delegando ao backend); TModernRTTIProperty.Visibility adicionado. Backend Delphi: MethodVisibility com case de 4 ramos qualificados + novo PropertyVisibility. Backend FPC: MethodVisibility continua levantando com SFPCNoVisibility reescrita (D-42.5) + novo PropertyVisibility com case de 4 ramos qualificados (dado real). Tres cenarios novos em UScenarios.RTTI.pas + wrappers nas duas cascas. Mutacao CA-9 verificada (vermelho exit=2 sobre mvPrivate; verde exit=0 apos reverter). FPC 3.2.2 x86_64 verde 30/30 (baseline 28)."
status: stable
cycle: "015"
agent: developer
workflow: equipe-feature
node: implement
resource: aefos://run/bb89abe1aa455add801745cb2a527e99
tags: [modernrtti, implement-report, issue-42, fpc, delphi, visibility, tmodernvisibility]
generated:
  by: "equipe-feature@node:implement"
  at: "2026-09-01T00:00:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — TModernVisibility (issue #42)"
  - id: adr
    resource: "adr.md"
    title: "ADR — TModernVisibility (issue #42)"
  - id: plan
    resource: "plan.md"
    title: "PLAN — TModernVisibility em 3 slices (issue #42)"
  - id: task-input
    resource: "task-input.md"
    title: "TASK-INPUT — Implementar TModernVisibility (issue #42)"
---

# IMPLEMENT-REPORT — issue #42 (TModernVisibility)

## Resumo executivo

Todas as tres slices do [plan](pipeline-plan.md) num unico commit-set, na ordem
prescrita (casca publica → backends em paridade → cenarios + wrappers).
`PTestRTTI.lpr` compila e passa na fabrica FPC 3.2.2 x86_64-linux com
**30 tests / 0 errors / 0 failures / exit=0** (dois a mais que o
baseline de 28 do ciclo 013).

Mutacao obrigatoria (D-42.9 / CA-9) verificada: **trocar** em
`Source/ModernSyntax.RTTI.FPC.pas` a linha
`TMemberVisibility.mvPublished: Result := TModernVisibility.mvPublished;`
do `case` de `PropertyVisibility` por `Result := TModernVisibility.mvPrivate;`
faz `TestProperty_Visibility_Returns_mvPublished` cair com
`ETestScenarioFailed: Property.Visibility devolveu ordinal 0; esperado
3 (mvPublished)`; o runner devolve **`exit=2`**. Revertido antes do
handoff; rebuild verde reconfirmado (30/0/0/exit=0).

Regressao verde nos demais runners FPC (`PTestInvoker` — 450 linhas
compiladas, 0 errors; `PTestModernCallback` — 513 linhas compiladas, 0
errors).

## Arquivos modificados

| arquivo | acao |
|---|---|
| `Source/ModernSyntax.RTTI.pas` (interface) | +`TModernVisibility = (mvPrivate, mvProtected, mvPublic, mvPublished)` declarado ANTES de `TModernRTTIField` (D-42.1); troca de retorno em `TModernRTTIMethod.Visibility` de `TMemberVisibility` para `TModernVisibility` com XMLDoc reescrita explicitando a RAIZ (`vmtMethodTable` + D-25) em vez da mentira anterior; +`TModernRTTIProperty.Visibility: TModernVisibility` declarado como membro publico novo com XMLDoc que NAO carrega clausula "no FPC levanta" (CA-10 do ESP) |
| `Source/ModernSyntax.RTTI.pas` (implementation) | troca de tipo em `TModernRTTIMethod.Visibility` (corpo continua `Result := MethodVisibility(FOwner, FToken)`); +`TModernRTTIProperty.Visibility` delegando `Result := PropertyVisibility(Pointer(FProp))` |
| `Source/ModernSyntax.RTTI.Delphi.pas` | troca de assinatura de `MethodVisibility` (interface `:74` + impl); reescrita do corpo com `case` explicito de EXATAMENTE 4 ramos qualificados (`TMemberVisibility.mvPrivate → TModernVisibility.mvPrivate` etc.); +`PropertyVisibility(AToken: Pointer): TModernVisibility` (interface + impl) com mesmo `case` de 4 ramos sobre `TRttiProperty(AToken).Visibility` — SEM ramo `mvAutomated`, SEM resourcestring nova (D-42.3) |
| `Source/ModernSyntax.RTTI.FPC.pas` | troca de assinatura de `MethodVisibility` (interface + impl); corpo continua levantando `EModernRTTIError`; +`SFPCNoVisibility` reescrita segundo D-42.5 (menciona `vmtMethodTable`, `rtti.pp:317`, D-25); +`PropertyVisibility(AToken: Pointer): TModernVisibility` (interface + impl) com `case` de 4 ramos qualificados sobre `TRttiProperty(AToken).Visibility` — SEM ramo `mvAutomated` (inexistente em `rtti.pp:308` do FPC 3.2.2), SEM raise, SEM resourcestring nova (D-42.4) |
| `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | +3 declaracoes de cenarios no `interface`; +3 corpos: `Scenario_Method_Visibility_FPC_Raises` (fixture `TMethodBase`; padrao `try/except on EModernRTTIError` + `Fail(...)`; assercao ADICIONAL sobre a mensagem — deve conter `vmtMethodTable`), `Scenario_Method_Visibility_Delphi_Returns_mvPublished` (mesma fixture; assercao `LVis = mvPublished`), `Scenario_Property_Visibility_Returns_mvPublished` (fixture `TPortableFixture` — ja tem `{$M+}` + `Number` published; assercao `LVis = mvPublished`) |
| `Test FPC/EclbrSystem/UTestMS.RTTI.pas` | +2 `published` procedures FPCUnit — `TestMethod_Visibility_FPC_Raises` (par FPC-only) e `TestProperty_Visibility_Returns_mvPublished` (cross-compiler). NAO publica `TestMethod_Visibility_Delphi_Returns_mvPublished` — Delphi-only |
| `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` | +2 `[Test]` methods DUnitX — `TestMethod_Visibility_Delphi_Returns_mvPublished` (par Delphi-only) e `TestProperty_Visibility_Returns_mvPublished` (cross-compiler). NAO publica o irmao FPC-only |
| `.project/project-evolution.md` | flip do marker do ciclo 015 / issue #42: `🔄 in-pipeline` → `🔄 in-review` |

Runners (`PTestRTTI.lpr`, `PTestRTTI.dpr`, `.lpi`): **inalterados** — a
mudanca vive dentro das units ja incluidas por `uses` transitivo.

Nenhum arquivo novo. Nenhum arquivo removido.

## Decisoes tecnicas tomadas na implementacao

### D-IMPL-1 — `case` labels qualificados com `TMemberVisibility.<n>`, Result qualificado com `TModernVisibility.<n>`

O ESP e o plan pedem "`case` explicito de exatamente 4 ramos". Ao
adicionar `TModernVisibility` na casca publica com constantes
homonimas as de `TMemberVisibility` (`mvPrivate`, `mvProtected`,
`mvPublic`, `mvPublished`), qualquer identificador NAO-qualificado
`mvPrivate` no backend passa a resolver contra o enum "mais proximo"
por ordem de `uses` — e como `ModernSyntax.RTTI` e o ULTIMO `uses` dos
backends, `mvPrivate` cru referiria `TModernVisibility.mvPrivate`
enquanto o selector do `case` e `TMemberVisibility`. Compilador
recusa.

Solucao: **qualificar tudo** — labels com `TMemberVisibility.mvPrivate`
(do RTL, tipo do selector) e Result com `TModernVisibility.mvPrivate`
(da casca, tipo do retorno). Ambas as formas compilam no FPC 3.2.2
`-Mdelphi` e em Delphi modernos. Depender de shadowing por ordem de
`uses` seria fragil — bastaria um refactor futuro reordenar
`uses` para o backend passar a devolver o enum errado sem alarme.

Aplicado nos DOIS backends por simetria (D-42.2 exige o mesmo padrao).

### D-IMPL-2 — Fixture do cenario cross-compiler reusa `TPortableFixture`

Nenhuma fixture nova. `TPortableFixture` (`UScenarios.RTTI.pas:56–65`)
ja e classe com `{$M+}` e tres propriedades `published` (`Number`,
`Name`, `Amount`) — satisfaz o requisito de D-42.7 ("fixture inclui pelo
menos uma propriedade `published` em classe `{$M+}`"). O cenario le
`Number` porque foi a primeira; qualquer das tres serviria.

Adicionar fixture nova gastaria linhas sem cobrir nada mais.

### D-IMPL-3 — Cenario Method_Visibility_FPC_Raises afirma DUAS coisas

Alem de exigir o raise (`try/except on EModernRTTIError`), o cenario
verifica que a mensagem contem `vmtMethodTable`. Racional: sem essa
segunda assercao, uma regressao futura que reescrevesse `SFPCNoVisibility`
para o texto antigo enganoso ("visibilidade fina nao e enumeravel pela
RTTI de classe") passaria o cenario verde — a mensagem serve o proposito
pedagogico de D-42.5, entao vale afirmar. Padrao ja usado em outros
cenarios com `Pos(...) = 0` (`Scenario_Context_GetTypes_EmptyRegistry_Raises`
verifica mencao a `RegisterType`).

Nao adiciona custo cognitivo — a assercao vive no mesmo `try/except`.

## Validacoes executadas (comandos de qualidade)

Comandos descobertos em `.project/SKILL.md` (secoes principal +
"agent-discovered 2026-08-28" + "agent-discovered 2026-08-31").

1. **Build + run principal** (`PTestRTTI` — x86_64 fabrica):
   ```
   rm -rf /tmp/fpcbuild && mkdir -p /tmp/fpcbuild
   fpc -Mdelphi -Fu"Source" -Fu"Test Shared/EclbrSystem" \
       -Fu"Test FPC/EclbrSystem" \
       -FU/tmp/fpcbuild -FE/tmp/fpcbuild \
       "Test FPC/EclbrSystem/PTestRTTI.lpr"
   /tmp/fpcbuild/PTestRTTI --all -a --format=plain
   ```
   → **30 tests / 0 errors / 0 failures / exit=0** (baseline era 28; +2).

2. **Mutacao obrigatoria** (D-42.9 / CA-9 do ESP):
   trocar `mvPublished: Result := mvPublished` por `Result := mvPrivate`
   em `PropertyVisibility` do backend FPC:
   → **30 tests / 1 error / 0 failures / exit=2** —
   `TestProperty_Visibility_Returns_mvPublished` cai com
   `ETestScenarioFailed: Property.Visibility devolveu ordinal 0;
   esperado 3 (mvPublished)`. Mutacao revertida; rebuild verde
   reconfirmado (30/0/0/exit=0).

3. **Regressao dos outros runners FPC**:
   - `PTestInvoker.lpr` → **450 lines compiled, 0 errors**
   - `PTestModernCallback.lpr` → **513 lines compiled, 0 errors**

4. **Guardrails de arquitetura**:
   - `grep -n "TMemberVisibility" Source/ModernSyntax.RTTI.pas` →
     APENAS 3 hits, TODOS em XMLDoc/comentarios (linhas 61, 64, 65);
     ZERO no codigo (CA-7 do ESP).
   - Paridade de assinatura entre backends:
     `grep -c "^function PropertyVisibility" Source/ModernSyntax.RTTI.FPC.pas`
     = `grep -c "^function PropertyVisibility" Source/ModernSyntax.RTTI.Delphi.pas`
     = **2** (1 declaracao no interface + 1 implementacao).
   - `grep -n "{\$IFDEF FPC" "Test Shared/EclbrSystem/UScenarios.RTTI.pas"`
     nos cenarios novos → sem ocorrencias (CA-5 do repo preservado).
   - `grep -nE "AssertException|Assert\(|raise Exception\." "Test Shared/EclbrSystem/UScenarios.RTTI.pas"`
     nos cenarios novos → sem ocorrencias.
   - `grep -n "mvAutomated" Source/` → ZERO ocorrencias em toda a
     Source/ (CA-4 + CA-5 do ESP).

## Caveats

- **Compilacao Delphi (CA-8 do ESP): NAO exercitada** — a fabrica nao
  tem `dcc32` (SKILL.md:16-27). O padrao segue o desenho consagrado:
  `case` de 4 ramos qualificados sobre `TRttiProperty.Visibility` e
  `TRttiMethod.Visibility` do RTL Embarcadero. **Primeira coisa a
  confirmar no build Delphi do autor** — se `TMemberVisibility` de
  Delphi tiver `mvAutomated` (ou qualquer outro valor alem dos 4), o
  compilador acusa erro no primeiro build, que e exatamente o detector
  que D-42.2 comprou.

- **Compilacao FPC i386: NAO exercitada** — a fabrica so tem
  `x86_64-linux` (SKILL.md:122-124). O autor confirma i386 no Windows.
  Nenhuma aritmetica literal de ponteiro nova foi introduzida — o
  codigo novo e puramente `case` sobre valor de enum + retorno de
  enum. Simetria x86_64/i386 mantida.

- **XMLDoc de `TModernRTTIMethod`** (comentario multi-line em
  `Source/ModernSyntax.RTTI.pas:221-227`) ainda menciona
  "Visibility" na lista dos "seis membros que levantam" — nao foi
  atualizado porque o comportamento nao mudou (Method.Visibility no
  FPC continua levantando por D-42.5); apenas a XMLDoc especifica de
  `Visibility` foi reescrita para expor a raiz correta. Se o revisor
  preferir explicitar tambem no comentario coletivo, e edit trivial
  no proximo commit.

## Auto-enriquecimento SKILL.md

Nao apliquei APPEND novo. Os comandos usados neste ciclo ja estao em
`.project/SKILL.md` (secoes principal + "agent-discovered 2026-08-28" +
"agent-discovered 2026-08-31"). O trap D-IMPL-1 ("case labels
qualificados quando enum publico da casca tem constantes homonimas ao
enum do RTL") e semantica de linguagem, nao trap de toolchain — cabe
ao autor humano promover se preferir.

## Referencias

- [esp](pipeline-esp.md) — 10 criterios de aceitacao e regras de negocio.
- [adr](pipeline-adr.md) — decisoes D-42.1 a D-42.9 e o que foi descartado.
- [plan](pipeline-plan.md) — ordem de execucao em 3 slices.
- [task-input](pipeline-task-input.md) — handoff operacional e checklist para PR body.
