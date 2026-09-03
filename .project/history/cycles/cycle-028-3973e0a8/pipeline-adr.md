---
type: adr
kind: artifact
title: "ADR #13 — TModernInvoker.Invoke dinamico: assinatura identica cross-compiler, mecanismo divergente, alcance por compilador"
description: "Decisoes fechadas para o overload dinamico TValue-based do TModernInvoker, alinhadas a correcao de premissa registrada no proprio corpo da issue #13 em 2026-09-03."
cycle: "028"
agent: architect
workflow: equipe-feature
node: "plan-gate:on_reject"
resource: aefos://run/3973e0a8a9fb319c0e20e1154e93d8d3
generated:
  by: "equipe-feature@node:architect"
  at: "2026-09-03T00:00:00Z"
tags: [adr, rtti, invoker, fpc, delphi, dynamic-invoke, tvalue, issue-13, cycle-028, d-13-1, d-13-13]
sources:
  - id: issue-13-body
    resource: "https://github.com/isaquepinheiro/ModernSyntax/issues/13"
    title: "Issue #13 — corpo, incluindo secao 'CORRECAO DE PREMISSA — 03/09/2026, medida rodando'"
  - id: invoker-current
    resource: "Source/ModernSyntax.Invoker.pas"
    title: "ModernSyntax.Invoker.pas atual (portavel Invoke<TSignature>, sem overload dinamico)"
  - id: adr-issue-10
    resource: "history/cycles/cycle-004-9a5f8b9e/pipeline-adr.md"
    title: "ADR issue #10 — nucleo portavel do Invoker via MethodAddress"
  - id: skill
    resource: ".project/SKILL.md"
    title: "SKILL.md — toolchain e quality commands do projeto"
---

> **Fonte:** o relatorio de investigacao **nao existe** (status NONE — a #13
> chegou a esta fabrica com **zero comentarios**; nenhum comentario abre com
> marcador `investigate`). Mas o **corpo da propria issue** carrega, em
> secao datada **2026-09-03** e assinada pelo dono, um bloco chamado
> *"CORRECAO DE PREMISSA — 03/09/2026, medida rodando"* que **derruba** os
> criterios 1 e 2 do texto original e registra as decisoes das tres voltas
> de discussao que o `investigate` (run c172b535) morreu sem preservar.
> Este ADR **decide** conforme o rito de status NONE **e** honra o desenho
> ja acordado ali; onde o corpo da issue e explicito, este ADR o cita
> literal e registra o motivo; onde o corpo abre espaco de decisao, este
> ADR fecha com motivo tecnico proprio.

# ADR #13 — `TModernInvoker.Invoke` dinamico cross-compiler

## Contexto

A #10 entregou o nucleo portavel do `TModernInvoker` (`Invoke<TSignature>`
sobre `MethodAddress`). O cabecalho da unit afirma em `Source/ModernSyntax.Invoker.pas:44-51`:

> *"Nao existe `Invoke(obj, 'Nome', [args]): TValue` nesta entrega — no FPC
> 3.2.2 nao ha de onde ler os tipos dos parametros para montar a chamada
> (`GetMethods = 0` para qualquer classe, medido)."*[^invoker-current]

A afirmacao **conflaciona duas coisas**: *ler os tipos por RTTI*
(descoberta, que de fato e vazia no FPC 3.2.2, `GetMethods = 0`) e *montar
a chamada* (invocacao, que **existe** via funcao livre `rtti.pp:583`).

**Medicao registrada no corpo da issue #13 em 2026-09-03**, executada nos
dois bitness do FPC 3.2.2:[^issue-13-body]

```
                                        i386        x86_64
Somar(2,3) via array of TValue          = 5         = 5
Concat('id-', 42)                       = id-42     = id-42
SemRetorno(6) -> efeito colateral       = 42        = 42
SoPublic (public nao-published)         levanta     levanta
```

Caminho:

```pascal
LAddr := AInstance.MethodAddress(AName);        // published (D-13.3)
SetLength(LArgs, Length(AArgs) + 1);
LArgs[0] := TValue.From<TObject>(AInstance);    // Self primeiro
for I := 0 to High(AArgs) do LArgs[I+1] := AArgs[I];
Result := Invoke(LAddr, LArgs, ccReg, AResultType, False, False);
```

`SystemInvoke` esta em assembly por arquitetura
(`packages/rtl-objpas/src/x86_64/invoke.inc:126` e o par em `i386/invoke.inc`);
`TRttiMethod.Invoke` do FPC tambem existe (`rtti.pp:466-468`). A funcao
`Invoke` livre **nao le tipo nenhum** — os `TValue` de entrada ja carregam
`TypeInfo` e `aResultType` vem do consumidor.

Isso derruba os criterios originais 1 e 2 da issue (que exigiam ausencia
sob `{$IFDEF}`) e habilita o desenho decidido abaixo.

---

## D-13.1 — Assinatura publica identica cross-compiler, sem `{$IFDEF}` na superficie

**Decidido:** o overload dinamico e declarado UMA UNICA VEZ, sem
`{$IFDEF}` em torno da declaracao:

```pascal
class function Invoke(const AInstance: TObject; const AMethodName: string;
  const AArgs: array of TValue;
  const AResultType: PTypeInfo = nil): TValue; overload; static;
```

O CORPO diverge por `{$IFDEF FPC} ... {$ELSE} ... {$ENDIF}` na
`implementation`.

**Motivo (medido no corpo da issue e no historico do bundle):**

- **Opcao rejeitada 1 — declaracao sob `{$IFDEF}` de capacidade
  (ausente no FPC).** Era o criterio original 1 da issue. A medicao do
  FPC 3.2.2 provou que a invocacao FUNCIONA no FPC — a ausencia seria
  desperdicio deliberado.
- **Opcao rejeitada 2 — assinaturas diferentes (retorno diferente por
  compilador).** Viola D-2 do bundle (paridade de assinatura). Consumidor
  cross-compiler nao conseguiria escrever codigo unico.
- **Opcao escolhida — assinatura unica, corpo divergente.** Codigo do
  consumidor identico nos dois. Divergencia mora onde deve morar (dentro
  da unit).

Pedido literal do dono no corpo da issue: *"preciso da mesma sintaxe como
internamente cada um poderia fazer"*.

---

## D-13.2 — Sem excecao "nao suportado" como comportamento principal no FPC

**Decidido:** o FPC **executa** o overload dinamico. Nao ha `raise
Exception.Create('nao suportado no FPC')` como comportamento normal. As
unicas excecoes que o FPC devolve por fronteira sao:

1. `AInstance = nil` — mensagem reusada do portavel (D-13.9).
2. `LAddress = nil` — mensagem instrutiva reusada do portavel (D-13.10),
   citando `{$M+}` e `published`.
3. Excecoes que a propria `Rtti.Invoke` levantar (por exemplo, construtor
   nao implementado: `rtti.pp:2334`).

**Motivo:** o defeito n.1 do PRD (fechado pelos PRs #11 e #12) e
*divergencia silenciosa em runtime*. Uma excecao "nao suportado"
introduzida quando a RTL do FPC **implementa** o caminho seria
divergencia inventada — o oposto do que o projeto vem eliminando.

**Descartado:** stub que levanta `ENotSupportedException` no FPC. Alem de
inventar divergencia, esconderia a capacidade real do compilador do
consumidor.

---

## D-13.3 — Alcance por compilador: `public` + `published` no Delphi, `published` apenas no FPC — opcao (a) da issue

**Decidido:** o Delphi mantem o alcance maior (`public` + `published`), via
`TRttiContext.GetType(AInstance.ClassType).GetMethod(AName)`. O FPC 3.2.2
cobre **`published` apenas**, via `TObject.MethodAddress(AName)`. Cada
compilador entrega o que **pode**.

**Motivo:** pedido literal do dono no corpo da issue: *"cada um faz o que
PODE"*. Achatar a capacidade do Delphi para caber no FPC seria jogar fora
poder real do compilador mais forte. A **assimetria remanescente** e
aceitavel por tres razoes registradas no corpo:

1. **Nao e superficie nova.** Os dois `Invoke<TSignature>` da #10 **ja** se
   comportam assim: `published` invoca no FPC (`Somar(2,3)=5` nos dois
   bitness, medido em 2026-09-03), `public` levanta com mensagem
   instrutiva.
2. **A mensagem instrui.** *"metodo "%s" nao encontrado em %s; no FPC isso
   exige {$M+} e secao published"* — o consumidor sabe o que fazer no
   primeiro uso.
3. **O escape e local e trivial:** marcar `published` (com `{$M+}` na
   classe) resolve.

**Descartado:**
- **Opcao (b) — achatar Delphi para `published` apenas.** Joga fora
  capacidade medida do Delphi.
- **Opcao (c) — via `TRttiContext` nos dois** (com stub de erro no FPC
  para `public`). Adiciona overhead de contexto no FPC sem beneficio; o
  FPC ja da a mesma resposta via `MethodAddress = nil`.
- **Opcao (d) — expor um flag/`enum` `ReachLevel`** no retorno para o
  consumidor consultar. Complica a superficie por especulacao.

---

## D-13.4 — Backend Delphi cria `TRttiContext` local com `try/finally .Free`, materializa `Result` dentro do bloco

**Decidido:** o corpo Delphi cria `LCtx: TRttiContext := TRttiContext.Create`,
faz **toda** a enumeracao (`GetType`, `GetMethod`, `LMethod.Invoke`)
**dentro** do `try/finally LCtx.Free;`, e devolve `Result` (que ja e um
`TValue` proprio, com conteudo copiado).

**Motivo:** o `TValue` sobrevive ao `.Free` do contexto (ele copia seu
conteudo). Mas o `TRttiMethod` NAO sobrevive — se o consumidor guardar
referencia, deu-se conta cedo demais. Toda a enumeracao dentro do bloco
elimina a ambiguidade. Mesmo padrao ja aplicado em `RecordTypeName` /
`RecordGetFields` (`RTTI.Delphi.pas`, ADR #53).

**Descartado:** contexto de vida longa (campo do record) — recordes sao
value types; nao ha `Destroy`. Cria contexto orfao no primeiro uso.

---

## D-13.5 — Backend FPC monta `TValueArray` com Self primeiro (`SErrMissingSelfParam`)

**Decidido:** o corpo FPC monta o `LArgs: TValueArray` com **Self como
primeiro elemento**, seguido dos `AArgs` do consumidor em ordem:

```pascal
SetLength(LArgs, Length(AArgs) + 1);
LArgs[0] := TValue.From<TObject>(AInstance);
for I := 0 to High(AArgs) do LArgs[I+1] := AArgs[I];
Result := Invoke(LAddress, LArgs, ccReg, AResultType, False, False);
```

`aIsStatic = False`, `aIsConstructor = False` para este overload.

**Motivo:** `SErrMissingSelfParam` do proprio `rtti.pp` explicita a
obrigatoriedade quando `aIsStatic = False`. Nao passar Self dispara a
mensagem — divergencia entre backends por descuido.

**Descartado:** interpretar Self como implicito. Nao e — a funcao livre
`Invoke` do FPC nao trata metodo de forma diferente de procedure; o Self
e argumento como qualquer outro.

---

## D-13.6 — Convencao de chamada: `ccReg`

**Decidido:** `aCallConv = ccReg` no FPC. XMLDoc declara essa
frontera explicitamente.

**Motivo:** `ccReg` e o padrao de metodo no FPC (medido). Outras
convencoes (`ccCdecl`, `ccStdCall`, `ccPascal`) **nao foram medidas** e
ficam fora — vira issue propria se demanda aparecer.

**Descartado:**
- Detectar convencao por RTTI: `GetMethods = 0` no FPC; nao ha de onde
  ler.
- Expor parametro `ACallConv` no overload: expande superficie por
  especulacao. Se algum consumidor precisar, vira issue.

---

## D-13.7 — Os tres blocos superados do cabecalho caem na mesma edicao

**Decidido:** remover, no mesmo commit, os tres blocos do cabecalho de
`Source/ModernSyntax.Invoker.pas` que contradizem o desenho novo:

- **`:12-18`** (*"`uses SysUtils;` apenas / `Rtti` e `TypInfo` nao sao
  necessarios"*): superado. `TValue` na assinatura obriga `Rtti` nos dois.
- **`:20-25`** (*"nao ha ramificacao por compilador"*): superado. O corpo
  do novo overload diverge por IFDEF; a assinatura nao.
- **`:44-51`** (*"Nao existe `Invoke(obj, ...): TValue`"*): superado. E
  a afirmacao falsa que originou os criterios 1 e 2 desta issue.

XMLDoc novo cobre o alcance por compilador (D-13.8).

**Motivo:** mergear com afirmacao superada custou uma issue inteira em
#62. Consertar junto e barato; consertar depois vira issue. Consistente
com D-53.9.

**Descartado:** deixar como "TODO" ou comentar fora. Rasto que envelhece
igual.

---

## D-13.8 — XMLDoc declara alcance POR COMPILADOR, nao frase generica

**Decidido:** a declaracao publica leva XMLDoc dizendo, em prosa:

```
/// <summary>
///   Invoca dinamicamente <c>AMethodName</c> em <c>AInstance</c>,
///   passando <c>AArgs</c> como argumentos e retornando o valor como
///   <c>TValue</c>. Assinatura identica nos dois compiladores; o
///   mecanismo interno diverge.
/// </summary>
/// <remarks>
///   Alcance:
///   - Delphi: <c>public</c> + <c>published</c>, via
///     <c>TRttiContext.GetType(AInstance.ClassType).GetMethod(AName)</c>.
///   - FPC 3.2.2: <c>published</c> apenas, via
///     <c>TObject.MethodAddress(AName)</c> + <c>Rtti.Invoke</c> livre
///     (<c>rtti.pp:583</c>).
///
///   Fronteira medida (nao promete alem disso):
///   - Convencao de chamada: <c>ccReg</c> apenas. Metodos <c>stdcall</c>,
///     <c>cdecl</c> ou <c>pascal</c> nao sao cobertos por este overload.
///   - Construtor: chamar construtor via este overload levanta
///     <c>ENotImplemented</c> no FPC (limite da RTL:
///     <c>rtti.pp:2334</c>, marcado como TODO pelo proprio compilador).
///   - Record grande passado por referencia oculta (ABI-dependente):
///     nao coberto.
///
///   Em <c>public</c> nao-<c>published</c>, o FPC levanta com a mensagem
///   instrutiva reusada do overload portavel (cita <c>{$M+}</c> e
///   <c>published</c>). Esta assimetria e deliberada (cada compilador
///   entrega o que pode).
/// </remarks>
```

**Motivo:** frase generica ("cross-compiler; algumas diferencas podem
ocorrer") deixa o consumidor adivinhar. Alcance explicito por compilador
+ fronteira medida evita a classe de defeito "eu pensei que funcionava".

---

## D-13.9 — Guarda `AInstance = nil` reusa mensagem do portavel

**Decidido:** mensagem `'AInstance e nil'`, literal — a mesma do
portavel (`:82`). Simetria de mensagem entre os overloads faz o consumidor
tratar como uma coisa.

**Motivo:** overloads da mesma unit falhando com textos diferentes para
o mesmo defeito e ruido — o consumidor cria dois handlers para uma
condicao. Mesma mensagem, mesmo teste, mesma resposta.

---

## D-13.10 — Guarda `LAddress = nil` reusa mensagem instrutiva do portavel

**Decidido:** mensagem literal:

```
'metodo "%s" nao encontrado em %s; no FPC isso exige {$M+} e secao published'
```

Aplicada nos DOIS backends do overload dinamico:

- **FPC**: quando `AInstance.MethodAddress(AName) = nil`.
- **Delphi**: quando `LCtx.GetType(AInstance.ClassType).GetMethod(AName) = nil`.

**Motivo:** simetria de mensagem entre backends do overload dinamico
(D-2) e entre overloads da unit (D-13.9). A mensagem instrui o
consumidor a marcar `published` — verdade nos dois compiladores (no
Delphi para captura por `TRttiContext` sem `RTTI`-atribuido; no FPC como
unica secao alcancavel).

**Descartado:** mensagem diferente no Delphi ("adicione `{$RTTI EXPLICIT
METHODS}` ou marque `published`"). Mais informacao, mais barulho — o
consumidor testa `published` primeiro e resolve.

---

## D-13.11 — Fixture com layouts que DIVERGEM entre i386 e x86_64: `Integer+string` e `Double`

**Decidido:** os retornos das fixtures do teste executam **valores** cuja
ABI de retorno diverge entre i386 e x86_64:

- Record com `Integer + string` (managed).
- `Double`.
- Nao `Int64 + string` — layout medido e IDENTICO nos dois bitness.

Nomes das fixtures: `TDateAndTag = record Stamp: Integer; Tag: string; end;`,
metodo `function GimmeStamp(ATag: string): TDateAndTag`; metodo
`function GimmeAngle: Double`; `procedure StampNow(AValue: Integer)`
para void.

Layout medido nos dois bitness (ciclo 028, 2026-09-03):

| Fixture | i386 | x86_64 |
|---------|------|---------|
| `Integer + string` (escolhido) | SizeOf=8, Integer@0, string@4 | SizeOf=16, Integer@0, string@8 |
| `Int64 + string` (rejeitado) | SizeOf=16, Int64@0, string@8 | SizeOf=16, Int64@0, string@8 |

**Motivo:** `Int64 + string` foi a proposta original do ADR, mas medicao
provou que o `Int64` (8 bytes) ja ocupa 8 e o ponteiro de string cai em
offset 8 com padding identico nos dois bitness — SizeOf=16 em ambos.
Uma fixture que nao diverge entre bitness passaria verde num backend que
ignore bitness, exatamente o que ela deveria detectar. `Integer + string`
diverge: SizeOf=8 no i386, SizeOf=16 no x86_64 — exercita ABI diferente.

**Descartado:**
- Record com `Int64 + string`: SizeOf identico em i386 e x86_64 (medido);
  nao exercita divergencia ABI por bitness.
- Metodo devolvendo `Integer` sozinho: cabe em registrador nos dois;
  nao exercita ABI de retorno.
- Metodo devolvendo `TObject`: sempre ponteiro, sem divergencia por
  bitness na propria ABI de retorno.
- Metodo devolvendo record enorme: cai na fronteira "record por
  referencia oculta" que este ciclo declara FORA.

---

## D-13.12 — PR body carrega log das duas execucoes do FPC, sem checklist bloqueante

**Decidido:** PR carrega frase declarativa:

> *"compilado em FPC 3.2.2 x86_64 (fabrica) e i386 (autor); Delphi
> (Win32/Win64) fica com o autor — verificados antes do merge."*

Mais o log das duas execucoes do FPC (x86_64 pela fabrica; i386 pelo
autor), colados em `<details>`. Sem checklist de combinacoes.

**Motivo:** pedido literal da issue original: *"O PR declara em qual
Delphi foi compilado — o autor, porque nem a fabrica nem o orquestrador
tem Delphi"*. E fronteira registrada em D-60.7 / D-62.4. Fabrica entrega,
autor prova depois. Nao inverter.

**Descartado:** checklist bloqueante de 4 combinacoes Delphi na esteira.
Ninguem na esteira tem Delphi — a promessa nao teria como ser cumprida.

---

## D-13.13 — Overload portavel `Invoke<TSignature>` da #10 NAO muda

**Decidido:** os dois overloads generic `Invoke<TSignature>` (linhas 73-91
e 93-111 do arquivo atual) permanecem **byte-por-byte identicos** apos
esta edicao. Nao renomear, nao reordenar, nao "otimizar".

**Motivo:** eles ja foram provados pela #10 e continuam sendo exercitados
pelos 7 cenarios existentes em `UTestMS.Invoker.Cases.pas`. Regressao
zero.

**Descartado:** unificar os tres em uma implementacao "elegante" que usa
`TRttiContext` no Delphi tambem para os generic. Expande escopo e
introduz risco onde nao ha demanda.

---

## Convencoes governantes

| ID | Fonte | O que governa nesta issue |
|----|-------|---------------------------|
| D-1 (bundle) | `Source/ModernSyntax.RTTI.pas:18-22` | Nenhum `resourcestring` novo — as mensagens de guarda sao literais |
| D-2 (bundle) | `Source/ModernSyntax.RTTI.FPC.pas:14-16`; `Delphi.pas:14-18` | Assinatura publica IDENTICA cross-compiler — compilacao e o portao |
| D-4 (bundle) | `Source/ModernSyntax.RTTI.FPC.pas:634-639` | Guardas de entrada primeiro; sem trabalho antes das guardas |
| D-7 (bundle) | `UScenarios/UTestMS` | Cenario compartilhado; cascas de uma linha |
| D-53.9 | ADR ciclo 027 | Corrigir doc superado no MESMO commit da mudanca de comportamento |
| D-53.12 | ADR ciclo 027 | Frase declarativa de plataforma no PR; sem checklist bloqueante |
| D-60.7 / D-62.4 | ADRs anteriores | Fronteira "fabrica entrega, autor prova depois" — nao inverter |
| CA-5 | `UTestMS.Invoker.pas` (FPC) | Zero `{$IFDEF FPC}` em `UTestMS.Invoker.Cases.pas`; assimetrias de teste ficam na CASCA |

## Alternativas descartadas

| Alternativa | Por que descartada |
|-------------|--------------------|
| Declaracao sob `{$IFDEF}` de capacidade (ausente no FPC) | Medicao 2026-09-03 provou que FPC EXECUTA — ausencia seria desperdicio — D-13.1 |
| Excecao "nao suportado" no FPC como comportamento principal | Introduz divergencia inventada; PRs #11 e #12 morreram exatamente por isso — D-13.2 |
| Achatar Delphi para `published` apenas | Joga fora capacidade medida do Delphi; "cada um faz o que PODE" — D-13.3 |
| `TRttiContext` no FPC (uniformidade) | `GetMethods = 0` no FPC; contexto vazio e overhead sem beneficio — D-13.3 |
| Enum `ReachLevel` no retorno | Complica superficie por especulacao — D-13.3 |
| Contexto Delphi de vida longa (campo do record) | Records sao value types; sem `Destroy` — vaza contexto no primeiro uso — D-13.4 |
| Self implicito na TValueArray do FPC | `SErrMissingSelfParam` obriga; nao interpretar como implicito — D-13.5 |
| Parametro `ACallConv` publico | Especulacao; sem demanda — D-13.6 |
| Deixar os tres blocos superados do cabecalho para depois | Padrao #62 (doc superado gera issue nova) — D-13.7 |
| Frase generica de XMLDoc ("cross-compiler; algumas diferencas") | Deixa consumidor adivinhar; XMLDoc por compilador e explicito — D-13.8 |
| Mensagens de guarda diferentes entre overloads | Ruido; consumidor cria dois handlers para uma condicao — D-13.9 |
| Mensagem `LAddress = nil` diferente entre Delphi e FPC | Simetria D-2 + D-13.9; "published" e verdade cross-compiler para este proposito — D-13.10 |
| Fixture com `Int64 + string` | SizeOf identico em i386 e x86_64 (medido); nao diverge por bitness — D-13.11 |
| Fixture com `Integer` sozinho | Cabe em registrador; nao exercita ABI de retorno divergente — D-13.11 |
| Fixture com record enorme (referencia oculta) | Cai na fronteira declarada FORA do escopo — D-13.11 |
| Checklist bloqueante de 4 combinacoes Delphi na esteira | Ninguem na esteira tem Delphi — promessa impossivel — D-13.12 |
| Refatorar os dois generic overloads no mesmo commit | Expande escopo, risco de regressao onde ha zero demanda — D-13.13 |

## Consequencias

- `TModernInvoker` passa a expor tres `class function`s publicos: dois
  generic (inalterados da #10) e um novo `TValue`-based (dinamico).
- Superficie publica **cresce em uma assinatura**; corpo interno passa a
  ter `{$IFDEF FPC}` — deliberado, motivo em D-13.1.
- `uses` da `interface` acrescenta `Rtti`. Warning `Unit "Rtti" is
  experimental` do FPC passa a aparecer para consumidores desta unit
  tambem (ja aparece em `RTTI.FPC.pas:45`).
- Cabecalho da unit reescrito — os tres blocos superados saem juntos
  (D-13.7).
- Contagem de testes: FPC 7 → 14 (7 cenarios `InvokeDynamic_...`);
  Delphi correspondente sobe em 7.
- Assimetria deliberada em teste executavel:
  `Case_InvokeDynamic_PublicWithoutMPlus_RaisesOnFPC_OKOnDelphi` e
  **partido em dois** pela casca — Case FPC assere `Raises`, Case Delphi
  assere valor de retorno. CA-5 preservado (a assimetria mora na casca,
  nao no cenario compartilhado).
- Frontera do FPC 3.2.2 documentada em XMLDoc: `ccReg` apenas;
  construtor levanta na RTL; record por referencia oculta nao coberto.
- Fabrica compila e prova x86_64. i386 e os 4 alvos Delphi ficam com o
  autor (D-13.12).

[^issue-13-body]: Corpo da issue #13, secao "CORRECAO DE PREMISSA —
03/09/2026, medida rodando" — a medicao de invocacao FPC, o caminho
`rtti.pp:583`, o pedido do dono ("preciso da mesma sintaxe...", "cada um
faz o que PODE") e a lista dos tres blocos do cabecalho a remover.

[^invoker-current]: `Source/ModernSyntax.Invoker.pas:44-51` — a afirmacao
superada que originou os criterios 1 e 2 da issue.
