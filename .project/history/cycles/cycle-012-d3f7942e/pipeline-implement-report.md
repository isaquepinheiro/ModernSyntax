---
type: implement-report
kind: artifact
title: "IMPLEMENT-REPORT — Enumerators nas coleções: for..in sobre Fields/Properties/Methods/Parameters/Attributes (issue #27)"
description: "Cinco properties alias no TModernRTTITypeHelper + Parameters em TModernRTTIMethod; sete cenarios compartilhados + seis wrappers em cada casca. FPC 3.2.2 x86_64 verde 23/23 (exit=0). Prova de mutacao: PropFields devolvendo nil derruba TestFields_ForIn_IteratesFields (exit=2). Trap medido no FPC 3.2.2: property de record helper com `read <Metodo>` nao resolve metodos do tipo alvo — remediado com tres forwarders internos strict private."
status: stable
cycle: "012"
agent: developer
workflow: equipe-feature
node: implement
resource: aefos://run/d3f7942e59d0ba69094d93420fef84db
tags: [modernrtti, implement-report, issue-27, fpc, delphi, enumerators, for-in]
generated:
  by: "equipe-feature@node:implement"
  at: "2026-08-31T00:00:00Z"
---

# IMPLEMENT-REPORT — issue #27

## Resumo executivo

Slice 1 (unit publica) + Slice 2 (cenarios + cascas + mutacao) do
[plan](pipeline-plan.md) num unico commit-set. `PTestRTTI.lpr` compila e passa na
fabrica x86_64-linux com **23 testes / 0 errors / 0 failures / exit=0**
(sete a mais que o baseline de 17). Regressao verde nos outros tres
runners FPC (`PTestAttributes`, `PTestInvoker`, `PTestModernCallback`).
Prova de mutacao (D-9 do [adr](pipeline-adr.md) / SKILL.md:79-89): substituir
`PropFields` (forwarder do helper) por `Result := nil` faz
`TestFields_ForIn_IteratesFields` cair com
`ETestScenarioFailed: for..in Fields visitou 0 campos; esperado
exatamente 2` e o runner devolve **`exit=2`**. Revertido antes do handoff;
build final verde reconfirmado.

## Arquivos modificados

| arquivo | ação |
|---|---|
| `Source/ModernSyntax.RTTI.pas` (interface uses) | adicionado `ModernSyntax.Attributes` — unica aresta nova de dependencia (R1 do ESP validado: sem ciclo) |
| `Source/ModernSyntax.RTTI.pas` (`TModernRTTIMethod`) | +1 property publica `Parameters: TArray<TModernRTTIParameter> read GetParameters` com XMLDoc D-6 declarando literal *"No FPC, acessar `Parameters` levanta `EModernRTTIError` — a assinatura de método de classe não existe no FPC 3.2.2"* |
| `Source/ModernSyntax.RTTI.pas` (`TModernRTTITypeHelper`) | +4 properties publicas (`Fields`, `Properties`, `Methods`, `Attributes`) + 3 forwarders internos strict private (`PropFields`, `PropProperties`, `PropAttributes`) — ver D-IMPL-1 |
| `Source/ModernSyntax.RTTI.pas` (implementation) | +3 corpos triviais dos forwarders; `PropFields`/`PropProperties` delegam via `Self.<Metodo>`; `PropAttributes` delega a `ModernAttributes.GetAttributes(TRttiInstanceType(FType).MetaclassType)` com guarda `is TRttiInstanceType` (retorna nil quando nao aplicavel) |
| `Test Shared/EclbrSystem/UScenarios.RTTI.pas` (interface) | `uses` +`ModernSyntax.Attributes`; +3 fixtures novas (`TAttrForIn` : TModernAttribute + `TAlvoForInAttrs` para o cenario Attributes; `TEmptyForIn` para o cenario EmptyCollection; `TMethodWithParams` com `Beta(AArg: Integer; const AText: string)` published para o par Parameters); +7 declaracoes `Scenario_*` |
| `Test Shared/EclbrSystem/UScenarios.RTTI.pas` (implementation) | +7 corpos `Scenario_*`; ZERO `{$IFDEF}` — CA-5 preservado |
| `Test FPC/EclbrSystem/UTestMS.RTTI.pas` | +6 `published` procedures (5 comuns + `TestParameters_ForIn_RaisesOnFPC`); nao publica o irmao que itera |
| `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` | +6 `[Test]` methods (5 comuns + `TestParameters_ForIn_IteratesRealParameters`); nao publica o irmao que espera excecao |
| `.project/project-evolution.md` | flip do marker do ciclo 012 / issue #27: `🔄 in-pipeline` → `🔄 in-review` |

Runners (`PTestRTTI.lpr`, `PTestRTTI.dpr`, `.lpi`), backends
(`ModernSyntax.RTTI.Delphi.pas`, `ModernSyntax.RTTI.FPC.pas`) e
`ModernSyntax.Attributes.pas`: **inalterados** — a issue nao exige
funcao nova de backend (`AttributeEnumerate` foi descartado no ADR).

## Decisoes tecnicas tomadas na implementacao

### D-IMPL-1 — Trap medido: property de record helper com `read <Metodo>` no FPC 3.2.2

O plan e o ADR previam:
```pascal
property Fields:     TArray<TModernRTTIField>    read GetFields;
property Properties: TArray<TModernRTTIProperty> read GetProperties;
```
onde `GetFields`/`GetProperties` sao metodos do tipo alvo
(`TModernRTTIType`), NAO do helper. **Medido:** o FPC 3.2.2 recusa:

```
ModernSyntax.RTTI.pas(334,52) Error: Unknown class field or method identifier "GetFields"
ModernSyntax.RTTI.pas(339,59) Error: Unknown class field or method identifier "GetProperties"
```

Diferente do Delphi, o compilador FPC nao resolve `<Nome>` no `read` de
property de helper contra metodos do tipo alvo — so contra membros do
proprio helper. Solucao mantida DENTRO do escopo do plan:

- Tres forwarders internos, **strict private**, no proprio helper:
  `PropFields`, `PropProperties`, `PropAttributes`. Corpo trivial:
  `Result := Self.GetFields;` (e analogos). `PropAttributes` mantem a
  chamada a `ModernAttributes.GetAttributes(TRttiInstanceType(FType).MetaclassType)`
  — o D-3 do ADR pede caminho (a) com essa chamada; o Metaclass e o que
  `ModernAttributes.GetAttributes(AClass: TClass)` aceita (a assinatura
  em `Attributes.pas:111`).
- As quatro properties publicas ficam INTACTAS na superficie do
  consumidor: `LType.Fields`, `LType.Properties`, `LType.Methods`,
  `LType.Attributes`. `Methods` continua com `read GetMethods` porque
  `GetMethods` mora no proprio helper (issue #25).

Nenhuma decisao do ADR e alterada. Os forwarders sao **strict private**
— nao aparecem no consumidor. XMLDoc dentro da secao strict private
documenta a razao no arquivo para o proximo mantenedor.

Segunda opcao considerada: mover `Fields`, `Properties`, `Attributes`
para o proprio `TModernRTTIType` (o plan poe todas no helper). Nao
adotada porque `Methods` obrigatoriamente vive no helper (por causa da
ordem estatica dos records), e ter duas properties em `TModernRTTIType`
e duas no helper para expor "as coleções do tipo" quebra a coesao que a
issue pede. Com forwarders, todas as quatro ficam no mesmo lugar e o
consumidor ve superficie coesa.

### D-IMPL-2 — Guard `is TRttiInstanceType` no forwarder de Attributes

`PropAttributes` inclui `if (FType is TRttiInstanceType)` antes de
chamar `ModernAttributes.GetAttributes(...)` porque a fachada aceita
`TClass` e so faz sentido para tipo classe. Comportamento sobre tipo
nao-classe: devolve `nil` (mesma politica de `TModernRTTIType.GetFields`
para nao-classe). Nenhum cenario deste PR exercita esse caminho — a
issue e sobre coleções de tipos-classe — mas a defensiva evita AV se um
consumidor futuro cair aqui.

### D-IMPL-3 — Fixture do cenario de `Attributes` com registro por ModernAttributes

O cenario compartilhado `Scenario_Attributes_ForIn_IteratesAttributes`
registra UMA instancia de `TAttrForIn('for-in')` contra `TAlvoForInAttrs`
via `ModernAttributes.Register`, itera `LType.Attributes` e valida que:
1. `LCount >= 1` (nao `= 1` — no Delphi, um atributo nativo adicional
   poderia entrar por regra 2 do ADENDO do ciclo 004; o cenario
   compartilhado nao pode assumir ausencia total no Delphi);
2. Ha pelo menos UM elemento `is TAttrForIn` com `Tag = 'for-in'`.

Esta forma torna o cenario robusto nos dois compiladores. Mutacao no
`PropAttributes` (devolver nil) faria `LCount = 0` e o cenario cai.

### D-IMPL-4 — Fixture `TEmptyForIn` distinta de `TNoRttiFixture`

`TEmptyForIn = class(TObject);` — sem NENHUM campo declarado. O plan
inicialmente sugeria "classe sem published"; `TNoRttiFixture` (usada
por `Scenario_MissingM_RaisesEModernRTTIError`) tem `FSilent: Integer`
private, e no Delphi `TRttiType.GetFields` enumera private/protected —
usaria 1 campo, quebrando a asserção `Length = 0`. Fixture propria
elimina o risco. O cenario itera 0 vezes nos dois compiladores.

### D-IMPL-5 — Fixture `TMethodWithParams` isolada de `TMethodBase`/`TMethodDerived`

Novo `TMethodWithParams` published com `Beta(AArg: Integer; const AText: string)`
serve o par `Parameters`. Nao herdar de `TMethodBase`/`TMethodDerived`
evita alterar o count `= 2` de
`Scenario_GetMethods_CountsPublishedInherited_Exact`. O corpo de `Beta`
e vazio; a asserção observa apenas `GetMethod('Beta').Parameters` (2
parametros no Delphi; raise no FPC).

## Validacoes executadas (comandos de qualidade)

Comandos discovered em `.project/SKILL.md` — secoes principais e
"agent-discovered 2026-08-28".

1. Build + run principal (`PTestRTTI` — x86_64 fabrica):
   ```
   rm -rf /tmp/fpcbuild && mkdir -p /tmp/fpcbuild
   fpc -Mdelphi -Fu"Source" -Fu"Test Shared/EclbrSystem" \
       -Fu"Test FPC/EclbrSystem" \
       -FU/tmp/fpcbuild -FE/tmp/fpcbuild \
       "Test FPC/EclbrSystem/PTestRTTI.lpr"
   /tmp/fpcbuild/PTestRTTI --all -a --format=plain
   ```
   → **23 tests / 0 errors / 0 failures / exit=0** (baseline era 17).

2. Prova de mutacao (D-9 do ADR / SKILL.md:79-89): `PropFields` retornando
   `nil` em vez de `Self.GetFields`:
   → **1 error / 0 failures / exit=2** — `TestFields_ForIn_IteratesFields`
   cai com `ETestScenarioFailed: for..in Fields visitou 0 campos; esperado
   exatamente 2`. Mutacao revertida; rebuild verde reconfirmado.

3. Regressao dos outros runners FPC (nao devem quebrar por causa das novas
   properties, do novo `uses`, nem das novas fixtures):
   - `PTestAttributes.lpr` — **545 lines compiled, ok**
   - `PTestInvoker.lpr` — **450 lines compiled, ok**
   - `PTestModernCallback.lpr` — **513 lines compiled, ok**

4. `grep -c "IFDEF" "Test Shared/EclbrSystem/UScenarios.RTTI.pas"` →
   **0** (baseline pre-issue preservado; CA-5 respeitado).

5. `grep -n "{\$IFDEF" Source/ModernSyntax.RTTI.pas` (fora de comentarios)
   → APENAS `{$IFDEF FPC}` na clausula `uses` da `implementation`
   (linha 429). Todos os demais hits sao em COMENTARIOS descritivos
   (linhas 19, 20, 373, 374, 425, 465, 466, 496) — nenhuma diretiva de
   compilador nova na unit publica. O ganho da #26 nao regride.

6. `grep -rn "AssertException" "Test Shared/" "Test FPC/" "Test Delphi/"`
   → **vazio** (padrao literal try/except + `Fail(...)` usado).

## Caveats

- **Compilacao Delphi (R4 do ESP / R1 do plan): NAO exercitada** — a
  fabrica nao tem `dcc32` (SKILL.md:16-27). Assumido pelo padrao do
  repo que property alias `read <Metodo>` no Delphi 12 compila
  (o compilador Delphi resolve `read <Metodo>` de helper contra o
  tipo alvo, diferente do FPC); a decisao do plan/ADR (properties com
  read GetX) foi ADAPTADA para o FPC via forwarders internos, mas do
  ponto de vista do consumidor e da superficie publica NADA muda. Se o
  Delphi 12 reclamar do padrao, os forwarders continuam validos ali (o
  Delphi tambem aceita `read PropFields`) — o mesmo codigo compila nos
  dois compiladores. **Primeira coisa a confirmar no build Delphi.**

- **Compilacao FPC i386: NAO exercitada** — a fabrica so tem
  `x86_64-linux` (SKILL.md:122-124). O autor confirma i386 no Windows.

- **`{$M+}` em torno de `TMethodWithParams`** — necessario para o
  metodo `Beta` aparecer em `vmtMethodTable` no FPC (a semantica ja usada
  para as fixtures da issue #25). O `Beta` no FPC nao serve para iterar
  parametros (o cenario `RaisesOnFPC` verifica o raise antes disso), mas
  precisa aparecer em `GetMethod('Beta')` para o teste chegar ao
  `Parameters`.

## Auto-enriquecimento SKILL.md

Nao apliquei APPEND novo. Os comandos usados neste ciclo ja estao
documentados em `.project/SKILL.md` (secoes principal +
"agent-discovered 2026-08-28" + "agent-discovered 2026-08-31"). O trap
"Global Generic template references static symtable" ja consta ali; o
NOVO trap medido neste ciclo — "property de record helper com
`read <Metodo>` nao resolve metodos do tipo alvo no FPC 3.2.2" — e
documentado inline no arquivo (`Source/ModernSyntax.RTTI.pas` na secao
strict private do helper) e nesta secao D-IMPL-1. Cabe ao autor
humano decidir se promove para o SKILL.md como agent-discovered
2026-08-31 (a redacao dentro do codigo ja e explicita); prefiro nao
tocar o SKILL.md sem essa avaliacao editorial.

## Referencias

- [esp](pipeline-esp.md) — criterios formais e checklist.
- [adr](pipeline-adr.md) — decisao e o que foi descartado.
- [plan](pipeline-plan.md) — ordem de execucao em 2 slices.
- [task-input](pipeline-task-input.md) — handoff operacional.
