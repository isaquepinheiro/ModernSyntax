---
type: adr
kind: artifact
title: "ADR #13 (cycle 029) — TModernInvoker.Invoke dinamico com fronteira POR ALVO"
description: "Decisoes fechadas para o overload dinamico TValue-based do TModernInvoker; carrega adiante D-13.1..D-13.13 do ciclo 028 e adiciona D-29.1..D-29.3 para ancorar a fronteira em ALVO (SystemInvoke) em vez de BITNESS, conforme CORRECAO 2 registrada no proprio corpo da issue #13."
cycle: "029"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/c26861e980aa5045a4f8b7de8b2207c2
generated:
  by: "equipe-feature@node:architect"
  at: "2026-09-03T00:00:00Z"
tags: [adr, rtti, invoker, fpc, delphi, dynamic-invoke, tvalue, per-target, systeminvoke, issue-13, cycle-029, d-29-1, d-29-3]
sources:
  - id: issue-13-body
    resource: "https://github.com/isaquepinheiro/ModernSyntax/issues/13"
    title: "Issue #13 — corpo, secao 'CORRECAO 2 — 03/09/2026, medida DENTRO da fabrica'"
  - id: invoker-current
    resource: "Source/ModernSyntax.Invoker.pas"
    title: "ModernSyntax.Invoker.pas atual (portavel Invoke<TSignature>, sem overload dinamico)"
  - id: adr-028
    resource: "../history/cycles/cycle-028-3973e0a8/pipeline-adr.md"
    title: "ADR ciclo 028 — desenho original do overload dinamico (D-13.1..D-13.13)"
  - id: implement-028
    resource: "../history/cycles/cycle-028-3973e0a8/pipeline-implement-report.md"
    title: "Implement report ciclo 028 — 10/14 verdes + 4 ENotImplemented (medido dentro da fabrica)"
  - id: skill
    resource: ".project/SKILL.md"
    title: "SKILL.md — toolchain e quality commands do projeto"
---

> **Fonte:** o relatorio de investigacao **nao existe** (status NONE — a #13
> chegou a esta fabrica com 1 comentario; nenhum abre com marcador
> `investigate`). O **corpo da propria issue** carrega, em secao datada
> **2026-09-03** e assinada pelo dono, um bloco chamado *"CORRECAO 2 —
> 03/09/2026, medida DENTRO da fabrica"* que **corrige a correcao anterior**
> e estabelece os criterios que este ADR honra. As decisoes D-13.1..D-13.13
> do ciclo 028 continuam validas; este ADR as **carrega adiante** e
> adiciona D-29.1..D-29.3 para ancorar a fronteira em **ALVO** (existencia
> de `SystemInvoke`) em vez de **BITNESS**.

# ADR #13 (cycle 029) — `TModernInvoker.Invoke` dinamico, fronteira por alvo

## Contexto

O ciclo 028 (run `3973e0a8`) desenhou o overload dinamico e foi implementado
com sucesso — **compilacao limpa na fabrica**, `21 lines compiled, 0.2 sec`,
zero erros, zero warnings. Suite: `N:14 E:4 F:0 I:0`. Os 10 verdes cobrem
regressao zero (`Invoke<TSignature>` intocado) + as tres guardas do overload
dinamico + o assimetrico `PublicWithoutMPlus_RaisesOnFPC`. Os 4 em
`ENotImplemented` sao os que chamam `Rtti.Invoke` livre de verdade
(`ReturnsRecordIntegerAndString`, `ReturnsDouble`, `ReturnsManagedString`,
`ProcedureVoid_SideEffect`).[^implement-028]

Ainda assim, o ciclo foi rejeitado **nove vezes** com `REJECTED · causa: spec
· node blamed: architect` (e `target: implement` no rework — o no que nao
podia consertar spec). A rejeicao estava CERTA; o **defeito estava em dois
criterios do ESP anterior**, ambos impossiveis de satisfazer no ambiente da
fabrica:[^issue-13-body]

1. *"Prova nos DOIS bitness do FPC (i386 e x86_64)"* — a fabrica nao tem
   `ppc386` (`SKILL.md` "FPC disponivel na fabrica": *"NAO ha cross-compiler
   i386 (`ppc386` retorna `127`)"*).[^skill]
2. *"O backend FPC invoca metodo `published` e assere valor de retorno"* —
   `SystemInvoke` da RTL do FPC 3.2.2 nao esta implementado para SysV AMD64
   (`x86_64-linux`, que e o alvo da fabrica). Medido: o `Rtti.Invoke` livre
   cai em `raise Exception.Create(SErrInvokeNotImplemented)`
   (`strings rtti.ppu | grep SErrInvokeNotImplemented` confirma o resource
   string ativo).

A propria issue registra o certo:
- *"Backend FPC em alvo COM `SystemInvoke` (win32/win64): invoca `published`
  e o teste confere o valor de retorno. Prova e do **autor** — a fabrica nao
  tem esse alvo."*
- *"Backend FPC em alvo SEM `SystemInvoke` (x86_64-linux / SysV AMD64 no
  3.2.2): o `ENotImplemented` da RTL **aflora**, e o teste **assere isso
  por alvo**. E limite do FPC, nao escolha nossa..."*
- *"O teste **ramifica por alvo**, nao por bitness: onde ha `SystemInvoke`,
  assere valor; onde nao ha, assere `ENotImplemented`. Um
  `{$IF defined(CPUX86_64) and defined(UNIX)}` resolve, e o XMLDoc repete a
  mesma fronteira em prosa."*

Este ADR **honra literalmente** esse desenho. As decisoes D-13.1..D-13.13
do ciclo 028[^adr-028] continuam validas com uma unica adaptacao: onde D-13.8
falava em *"XMLDoc por compilador"*, D-29.1 abaixo o **estende** para
*"XMLDoc por alvo"* (Delphi | FPC-Windows | FPC-Linux). D-29.2 registra a
ramificacao dos testes de valor por alvo. D-29.3 registra o novo padrao de
prova da fabrica.

---

## Decisoes carregadas do ciclo 028 (D-13.1..D-13.13)

As trece decisoes do ciclo 028 continuam validas **na integra**. Lista curta
para rastreio; texto completo em [`../history/cycles/cycle-028-3973e0a8/pipeline-adr.md`](../cycle-028-3973e0a8/pipeline-adr.md).

| ID | Decisao |
|----|---------|
| D-13.1 | Assinatura publica identica cross-compiler, sem `{$IFDEF}` na superficie; corpo diverge por IFDEF |
| D-13.2 | Sem excecao "nao suportado" INVENTADA por nos como comportamento principal — a `ENotImplemented` da RTL aflora naturalmente |
| D-13.3 | Alcance por compilador (Delphi: `public`+`published`; FPC: `published`) — opcao (a) da issue |
| D-13.4 | Backend Delphi cria `TRttiContext` local com `try/finally .Free`; `Result` materializado dentro do bloco |
| D-13.5 | Backend FPC monta `TValueArray` com Self primeiro (`SErrMissingSelfParam`) |
| D-13.6 | Convencao de chamada: `ccReg` |
| D-13.7 | Os tres blocos superados do cabecalho da unit caem na mesma edicao (`:12-18`, `:20-25`, `:44-51`) |
| D-13.9 | Guarda `AInstance = nil` reusa mensagem literal do portavel |
| D-13.10 | Guarda `LAddress = nil` / `LMethod = nil` reusa mensagem instrutiva literal do portavel — **nos dois backends** |
| D-13.11 | Fixture com `Integer + string` (SizeOf=8 i386, 16 x86_64) e `Double`; NUNCA `Int64+string` |
| D-13.12 | PR body carrega frase declarativa de plataforma, sem checklist bloqueante — estendida em D-29.3 |
| D-13.13 | Overload portavel `Invoke<TSignature>` da #10 NAO muda (byte-por-byte identico) |

**Substituida:** D-13.8 (XMLDoc por compilador) e ESTENDIDA por D-29.1 abaixo
(XMLDoc por alvo). O conteudo por compilador continua la; o que muda e que
a linha do FPC vira TRES linhas — uma por classe de alvo.

---

## D-29.1 — XMLDoc declara alcance E fronteira POR ALVO (nao so por compilador)

**Decidido:** o XMLDoc na declaracao publica leva TRES linhas de fronteira,
uma por alvo, em vez de uma linha unica "FPC 3.2.2":

```
/// <summary>
///   Invoca dinamicamente <c>AMethodName</c> em <c>AInstance</c>,
///   passando <c>AArgs</c> como argumentos e retornando o valor como
///   <c>TValue</c>. Assinatura identica nos dois compiladores; mecanismo
///   e fronteira de execucao dependem do ALVO.
/// </summary>
/// <remarks>
///   Alcance por compilador:
///   - Delphi: <c>public</c> + <c>published</c>, via
///     <c>TRttiContext.GetType(AInstance.ClassType).GetMethod(AName)</c>.
///   - FPC 3.2.2: <c>published</c> apenas, via
///     <c>TObject.MethodAddress(AName)</c> + <c>Rtti.Invoke</c> livre
///     (<c>rtti.pp:583</c>).
///
///   Fronteira POR ALVO (o overload nao promete alem disso):
///   - Delphi (Win32/Win64/Linux/etc): invocacao viva; alcance
///     <c>public</c> + <c>published</c>.
///   - FPC 3.2.2 Windows (Win32/Win64): invocacao viva via
///     <c>SystemInvoke</c> em assembly
///     (<c>packages/rtl-objpas/src/x86_64/invoke.inc</c> e
///     <c>i386/invoke.inc</c>); alcance <c>published</c>.
///   - FPC 3.2.2 outros alvos (ex.: <c>x86_64-linux</c>, SysV AMD64):
///     <c>SystemInvoke</c> AUSENTE na RTL; qualquer chamada real
///     propaga <c>ENotImplemented</c> com mensagem literal da RTL:
///     <c>Invoke functionality is not implemented</c>
///     (<c>SErrInvokeNotImplemented</c>). Isto e LIMITE DA RTL do FPC,
///     nao escolha desta unit — nao mascaramos, nao re-embrulhamos.
///
///   Fronteira metodica (comum a todos os alvos):
///   - Convencao de chamada: <c>ccReg</c> apenas. Metodos <c>stdcall</c>,
///     <c>cdecl</c> ou <c>pascal</c> nao sao cobertos.
///   - Construtor: chamar construtor via este overload levanta
///     <c>ENotImplemented</c> no FPC (limite da RTL:
///     <c>rtti.pp:2334</c>, marcado como TODO pelo proprio compilador).
///   - Record grande passado por referencia oculta (ABI-dependente):
///     nao coberto.
///
///   Em <c>public</c> nao-<c>published</c>, o FPC levanta com a mensagem
///   instrutiva reusada do overload portavel (cita <c>{$M+}</c> e
///   <c>published</c>). Esta assimetria e deliberada (cada compilador
///   entrega o que pode — D-13.3).
/// </remarks>
```

**Motivo:** o texto original do ciclo 028 dizia *"FPC 3.2.2: published apenas
via MethodAddress + Rtti.Invoke"* como se essa afirmacao valesse em todo alvo
FPC. A medicao dentro da fabrica (secao "CORRECAO 2" da issue) provou que
`SystemInvoke` **nao esta implementado para SysV AMD64** no FPC 3.2.2 — e
o consumidor precisa saber ANTES de rodar. Uma frase generica "FPC 3.2.2"
esconde exatamente a informacao operacional que decide se o codigo do
consumidor vai rodar ou vai levantar.

**Descartado:**
- **XMLDoc por compilador apenas** (redacao original D-13.8): esconde a
  divergencia por alvo, que e a fronteira real.
- **Uma nota curta "consulte X ao portar"**: obriga o consumidor a caçar. O
  XMLDoc e ferramenta de tempo-de-compilacao — a fronteira vem dentro.
- **Enumerar todos os alvos possiveis**: infinito. Tres classes
  (Delphi | FPC-Windows | FPC-outros) cobre a divergencia real medida.

---

## D-29.2 — Testes de retorno de valor ramificam POR ALVO com `{$IF defined(CPUX86_64) and defined(UNIX)}`

**Decidido:** os quatro `Case_InvokeDynamic_Returns...` que chamam
`Rtti.Invoke` de verdade **ramificam por alvo** no arquivo compartilhado
`.Cases.pas`:

```pascal
procedure Case_InvokeDynamic_ReturnsDouble;
var
  o: TSubject;
  v: TValue;
{$IF defined(FPC) and defined(CPUX86_64) and defined(UNIX)}
  raised: Boolean;
  msg: string;
{$ELSE}
  r: Double;
{$ENDIF}
begin
  o := TSubject.Create;
  try
{$IF defined(FPC) and defined(CPUX86_64) and defined(UNIX)}
    raised := False;
    msg := '';
    try
      v := TModernInvoker.Invoke(o, 'GimmeAngle', [], TypeInfo(Double));
    except
      on E: Exception do
      begin
        raised := True;
        msg := E.Message;
      end;
    end;
    if not raised then
      Fail('esperava ENotImplemented da RTL em alvo FPC sem SystemInvoke');
    if Pos('not implemented', msg) = 0 then
      Fail('mensagem RTL inesperada: ' + msg);
{$ELSE}
    v := TModernInvoker.Invoke(o, 'GimmeAngle', [], TypeInfo(Double));
    r := v.AsExtended;
    if Abs(r - 3.14159265358979) > 1e-12 then
      Fail('GimmeAngle inesperado: ' + FloatToStr(r));
{$ENDIF}
  finally
    o.Free;
  end;
end;
```

Aplicado igual para: `ReturnsRecordIntegerAndString`, `ReturnsManagedString`,
`ProcedureVoid_SideEffect`.

**Guardar de `defined(FPC)`**: o Delphi tambem tem `CPUX86_64` e roda em Linux;
o alvo sem `SystemInvoke` e especificamente o FPC 3.2.2 SysV AMD64. Sem o
`defined(FPC)`, um Delphi Linux (LSB, existe) rodaria no ramo errado.

**Cenarios que NAO ramificam** (a guarda dispara antes da RTL):
- `Case_InvokeDynamic_NilInstance_Raises` — nossa guarda.
- `Case_InvokeDynamic_MethodNotFound_RaisesInstructive` — nossa guarda.
- `Case_InvokeDynamic_PublicWithoutMPlus_RaisesOnFPC` — `MethodAddress = nil`
  para `public` sem `{$M+}` no FPC; nossa guarda dispara.
- `Case_InvokeDynamic_PublicWithoutMPlus_OKOnDelphi` — nao chega ao FPC; a
  casca DUnitX o registra e o FPCUnit nao.

**Motivo:** ancorar em ALVO (existencia de `SystemInvoke` na RTL) e a
fronteira REAL medida — nao ha correspondencia 1-para-1 entre bitness e
existencia de `SystemInvoke`. `x86_64-win64` tem; `x86_64-linux` nao tem;
`i386-win32` tem; hipoteticos alvos futuros teriam ou nao dependendo do
port. Ramificar por alvo cobre exatamente o que a RTL cobre.

**Descartado:**
- **Ramificar por bitness (`{$IFDEF CPU32}` / `{$IFDEF CPU64}`)**: erro do
  ciclo 028; nao corresponde a existencia de `SystemInvoke` na RTL.
- **Ramificar por sistema operacional apenas (`{$IFDEF UNIX}`)**: pega
  Delphi Linux (LSB) por engano; obriga `defined(FPC)`.
- **`{$IFDEF FPC}` em torno da chamada inteira**: viola CA-5 (bundle) e
  perde a semantica do teste (o Delphi tambem deve exercitar a chamada e
  asserir valor).
- **Um Case por alvo (`Case_..._WhenSystemInvokePresent`, `_WhenAbsent`)**:
  dobra a superficie de teste por nada — a bifurcacao mora onde deve
  morar, dentro do proprio Case.
- **`try..except on E: ENotImplemented`**: `ENotImplemented` e do RTL
  Delphi/FPC; em ambos e `class(Exception)`. Casar `Exception` + checar
  `Pos('not implemented', E.Message)` e portavel e nao vaza tipo especifico.

---

## D-29.3 — Fabrica prova o que o ambiente dela permite: compilacao limpa + suite verde POR ALVO

**Decidido:** o gate de qualidade da fabrica exige:

1. **Compilacao limpa** do `PTestInvoker.lpr` em FPC 3.2.2 x86_64-linux:
   zero erros, zero warnings novos (o `Unit "Rtti" is experimental` — se
   o compilador o emitir — ja e emitido pela unit `RTTI.FPC.pas:45` e nao
   e "novo").
2. **Suite verde `14/14`** — os 4 cenarios de valor passam **verdes
   asserindo `ENotImplemented`** (D-29.2), nao passam com valor de retorno
   (impossivel neste alvo).
3. **`grep -c "{\$IFDEF FPC}"` no `.Cases.pas` = 0** (CA-5 preservado).

**O que a fabrica NAO prova, e nao mente sobre:**
- FPC i386 (`ppc386` ausente na fabrica — `SKILL.md`).
- FPC Windows Win32/Win64 (o alvo COM `SystemInvoke`; unico onde o path
  vivo prova valor de retorno).
- Delphi Win32/Win64 (autor — `SKILL.md`).

O **PR body** carrega **frase declarativa de alvo** (extensao de D-13.12):

> *"compilado em FPC 3.2.2 x86_64-linux (fabrica, com o path RTL vivo caindo
> em ENotImplemented — comportamento documentado); Delphi (Win32/Win64) e
> FPC Windows (Win32/Win64) ficam com o autor."*

Log da execucao FPC da fabrica em `<details>` — os 14 testes com os 4
`ENotImplemented` visiveis.

**Motivo:** o defeito da rodada anterior foi promover "prova em i386 +
retorno de valor" a criterio da fabrica — a fabrica **nao pode** cumprir
esse criterio. Rebaixar esses criterios para "fica com o autor" e retirar
divergencia inventada entre o que a esteira exige e o que ela pode fazer.
Consistente com D-60.7 / D-62.4 do bundle: **fabrica entrega, autor prova
depois**. Nao inverter.

**Descartado:**
- **Manter o criterio de i386 na fabrica** (redacao do ciclo 028): impossivel
  de satisfazer; foi a causa das 9 rejeicoes.
- **Instalar `ppc386` na fabrica**: fora do escopo desta issue (mudar
  infraestrutura da esteira nao pertence a uma issue de feature).
- **Rodar `qemu-user` para simular i386**: complexidade injustificada; a
  divergencia relevante (existencia de `SystemInvoke` para SysV AMD64) nao
  se resolve com simulacao.
- **Skip dos 4 testes de valor na fabrica**: perde a assertiva de que
  `ENotImplemented` **realmente aflora** — que e a prova de que a nossa
  camada nao esta mascarando. Ramificar por alvo (D-29.2) e a alternativa
  que preserva a assertiva onde ela e possivel.

---

## Convencoes governantes

| ID | Fonte | O que governa nesta issue |
|----|-------|---------------------------|
| D-1 (bundle) | `Source/ModernSyntax.RTTI.pas:18-22` | Nenhum `resourcestring` novo — mensagens de guarda literais |
| D-2 (bundle) | `Source/ModernSyntax.RTTI.FPC.pas:14-16`; `Delphi.pas:14-18` | Assinatura publica IDENTICA cross-compiler |
| D-4 (bundle) | `Source/ModernSyntax.RTTI.FPC.pas:634-639` | Guardas de entrada primeiro |
| D-7 (bundle) | `UScenarios/UTestMS` | Cenario compartilhado; cascas de uma linha |
| D-53.9 | ADR ciclo 027 | Corrigir doc superado no MESMO commit da mudanca de comportamento |
| D-53.12 | ADR ciclo 027 | Frase declarativa de plataforma no PR |
| D-60.7 / D-62.4 | ADRs anteriores | Fronteira "fabrica entrega, autor prova depois" — nao inverter |
| CA-5 | `UTestMS.Invoker.pas` (FPC) | Zero `{$IFDEF FPC}` em `.Cases.pas`; ramificar por ALVO se preciso, nao por compilador |

## Alternativas descartadas (novas neste ciclo)

| Alternativa | Por que descartada |
|-------------|--------------------|
| Manter "prova em i386" como criterio da fabrica | Impossivel de satisfazer — `ppc386` ausente na fabrica; foi a causa de 9 rejeicoes — D-29.3 |
| Manter "asserir valor de retorno no FPC" como criterio da fabrica | Impossivel — `SystemInvoke` ausente em SysV AMD64 no FPC 3.2.2 — D-29.3 |
| Skip dos 4 testes de valor na fabrica | Perde a assertiva de que `ENotImplemented` realmente aflora — mascaramento silencioso — D-29.3 |
| Ramificar teste por bitness (`{$IFDEF CPU32/64}`) | Nao corresponde a existencia de `SystemInvoke`; `x86_64-linux` e `x86_64-win64` divergem — D-29.2 |
| Ramificar por SO apenas (`{$IFDEF UNIX}`) | Pega Delphi Linux (LSB) por engano — precisa `defined(FPC)` — D-29.2 |
| `{$IFDEF FPC}` em torno do teste inteiro | Viola CA-5; perde assertiva do lado Delphi — D-29.2 |
| Um Case por alvo (dobrar quantidade de cenarios) | Dobra superficie sem beneficio — D-29.2 |
| XMLDoc por compilador apenas | Esconde divergencia real por alvo (`SystemInvoke` ausente) — D-29.1 |
| Mascarar `ENotImplemented` da RTL com texto proprio | Viola D-13.2 (nao inventar excecao); perde rastro da RTL — D-29.1 |
| Instalar `ppc386` na fabrica ou usar `qemu-user` | Mudanca de infraestrutura; nao pertence a uma issue de feature — D-29.3 |

## Consequencias

- `TModernInvoker` passa a expor tres `class function`s publicos: dois
  generic (inalterados da #10) e um novo `TValue`-based (dinamico).
- Superficie publica cresce em uma assinatura; corpo interno passa a ter
  `{$IFDEF FPC}` — deliberado (D-13.1).
- `uses` da `interface` acrescenta `Rtti`. Warning `Unit "Rtti" is
  experimental` do FPC pode passar a aparecer para consumidores desta unit
  tambem (ja aparece em `RTTI.FPC.pas:45`).
- Cabecalho da unit reescrito — os tres blocos superados saem juntos
  (D-13.7).
- Contagem de testes: FPC 7 → **14**; Delphi correspondente sobe em 7.
- Assimetria deliberada em teste executavel:
  `Case_InvokeDynamic_PublicWithoutMPlus_RaisesOnFPC` (registrado so no
  FPC) e `_OKOnDelphi` (registrado so no Delphi); CA-5 preservado.
- **Fronteira POR ALVO documentada em XMLDoc** (D-29.1) e **assercada em
  teste** (D-29.2): `{$IF defined(FPC) and defined(CPUX86_64) and
  defined(UNIX)}` marca o alvo sem `SystemInvoke`.
- Fabrica compila e prova x86_64-linux (com `ENotImplemented` visivel). FPC
  Windows e Delphi ficam com o autor (D-29.3).
- **Zero mudanca de infraestrutura na esteira** — `ppc386` continua
  ausente, `qemu-user` nao entra, tudo o que muda mora no repositorio.

[^issue-13-body]: Corpo da issue #13, secao *"CORRECAO 2 — 03/09/2026, medida
DENTRO da fabrica"* — a medicao do `ENotImplemented` da RTL x86_64-linux, a
ausencia de `ppc386` na fabrica, e a formulacao dos criterios que
substituem os anteriores.

[^invoker-current]: `Source/ModernSyntax.Invoker.pas` atual (113 linhas) —
carrega os tres blocos superados no cabecalho e apenas os dois overloads
`Invoke<TSignature>` da #10.

[^adr-028]: ADR do ciclo 028 — decisoes D-13.1..D-13.13, todas carregadas
adiante neste ADR.

[^implement-028]: Implement report do ciclo 028 — mede `SystemInvoke`
ausente em `x86_64-linux` no FPC 3.2.2, com `SErrInvokeNotImplemented`
confirmado por `strings rtti.ppu`.

[^skill]: `.project/SKILL.md`, secao "Toolchain & quality commands
(agent-discovered 2026-08-28)" — *"NAO ha cross-compiler i386 (`ppc386`
retorna `127`) e NAO ha `lazbuild`. Validacao i386 e Lazarus fica com o
autor."*
