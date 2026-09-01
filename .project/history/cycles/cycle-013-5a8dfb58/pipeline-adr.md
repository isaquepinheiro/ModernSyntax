---
type: adr
kind: decision
title: "ADR — TModernRTTIContext: IInterface token, registry per-instancia no FPC, sem GetPackages (issue #28)"
description: "Restatement da decisao que fechou a discussao da issue #28 (2 voltas): TModernRTTIContext usa IModernRTTIContextToken (opaco, so GUID) — refcount agrega copias de record, use-after-free e double-free impossiveis por construcao; registry per-instancia no FPC alimentado por GetType/RegisterType; GetTypes com registry vazio LEVANTA EModernRTTIError; FindType so resolve tkClass no FPC; GetPackages fora com motivo em XMLDoc; ContextFree eliminado, Free publico opcional; frase-fronteira registrada: 'Pointer em record e seguro enquanto o record nao e dono; vira bomba no instante em que passa a ser'."
status: stable
cycle: "013"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/5a8dfb58a24f74263fa58fa581f465c4
tags: [modernrtti, adr, issue-28, fpc, delphi, context, iinterface, refcount, pointer-boundary]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-09-01T00:00:00Z"
sources:
  - id: issue-28-report
    title: "REPORT — Issue #28 (run ca7057571a6e684f698e54f8a1d8721e) — PRESENT"
  - id: api-map
    resource: "/strategy/2026-08-27-modernrtti/API-MAP.md"
    title: "ModernRTTI API-MAP (§1, §2, §7)"
  - id: adr-026
    resource: "/history/cycles/cycle-011-38e3bcee/pipeline-adr.md"
    title: "D-26 — nao silenciar divergencia"
  - id: adr-025
    resource: "/history/cycles/cycle-010-a36e1364/pipeline-adr.md"
    title: "D-25 — Fail(...) sempre; dois cenarios distintos"
  - id: prd
    resource: "/strategy/2026-08-27-modernrtti/PRD.md"
    title: "PRD — CA-5"
  - id: skill
    resource: "/SKILL.md"
    title: "SKILL — receita FPC, mutacao, traps"
---

# ADR — issue #28

Este documento **deriva do relatorio de investigacao** que fechou a
discussao da issue #28 (duas voltas, humano + agente, run
`ca7057571a6e684f698e54f8a1d8721e`). Ele registra a decisao em vigor,
nos termos que a conversa acertou.

**Nao ha divergencia de merito** entre este ADR e o relatorio. As
correcoes das duas voltas ja estao absorvidas — em particular a escolha
final da **opcao (a)** para a superficie publica do token
(interface vazia, so GUID) e a **eliminacao de `ContextFree`** por
refcount. Este ADR so restata; a decisao ficou.

## Contexto medido (do relatorio)

- **`TRttiContext.GetTypes` esta COMENTADO** em
  `packages/rtl-objpas/src/inc/rtti.pp` do FPC 3.2.2; `FindType` nao
  existe (`Error: identifier idents no member "FindType"`).
- **Nao ha registro global enumeravel** para contornar: `ClassList:
  TThreadList` em `classes.inc:26` e **privada da implementacao**, sem
  acessor publico. `GetClass(inexistente) = nil`, `FindClass(...)`
  levanta `EClassNotFound`, iterar **e impossivel**.
- **`TRttiContext` nativo do FPC** ja usa
  `FContextToken: IInterface` (linha do proprio `rtti.pp`) — o
  precedente do desenho correto esta a RTL de origem.
- **Cast por kind medido kind a kind** (x86_64 e i386): `UnitName` so
  existe para `tkClass`. Ler `GetTypeData(P)^.UnitName` de outros
  kinds acessa campo inexistente naquele layout — lixo ou AV
  **sem erro de compilacao**.
- **Prova executada do `FHandle: Pointer` + `ContextCreate/ContextFree`**
  pelo reviewer: `B := A; A.Free;` deixa `B.Count = 1` onde havia `2`
  (use-after-free silencioso); `B.Free` posterior levanta
  `EInvalidPointer` (double-free). Nos dois bitness.
- **Prova executada do desenho `IInterface`** pelo reviewer:
  `A.Count=2; B:=A; B.Count=2; B.Add(3); A.Count=3; A.Free; B.Count=3;
  B.Free` — sem use-after-free, sem double-free.

## Decisoes

### D-28.1 — `IModernRTTIContextToken` opaco (so GUID), campo do record

O `TModernRTTIContext` guarda `FToken: IModernRTTIContextToken` (nao
`Pointer`). A interface e declarada na unit publica e **vazia de
membros publicos** — so o GUID (opcao (a)). O backend recupera o
estado tipado via cast `AToken as TFPCContextToken` /
`AToken as TDelphiContextToken` (classes privadas de cada backend).

**Por que:** o refcount da interface agrega N copias do record e o
ultimo decremento libera. Use-after-free e double-free ficam
**impossiveis por construcao**. Opcao (a) escolhida na volta 2 porque
`InternalHandle: Pointer` reintroduziria no vocabulario publico
exatamente o que M-E acabou de expulsar.

**Descartado (M-E do relatorio):** `FHandle: Pointer` +
`ContextCreate: Pointer` / `ContextFree(Pointer)`. Motivo: **medido
executando**, produz use-after-free silencioso (`B.Count = 1` onde
havia `2`) e double-free (`EInvalidPointer` no segundo `Free`), nos
dois bitness. Record copia por valor; copiar `Pointer` cria dois donos
do mesmo heap.

**Descartado (volta 2):** `IModernRTTIContextToken` com `function
InternalHandle: Pointer` na interface publica; e casca (b)
(interface declarada nos backends com forward na unit publica). A (a)
tem menos superficie publica e menos jeito de errar; (b) exigiria mais
encanamento sem ganho.

### D-28.2 — Frase-fronteira: quando `Pointer` em record vira bomba

> ***"`Pointer` em record e seguro enquanto o record nao e dono; vira
> bomba no instante em que passa a ser."***

Esta e a decisao **nomeada** desta issue, e ela vale alem dela.
Justifica por que os `FToken: Pointer` existentes **continuam
validos** — `TModernRTTIField.FToken: Pointer` e offset;
`TModernRTTIProperty.FToken: Pointer` e referencia nao-dona ao objeto
RTTI vivo do compilador; `TModernRTTIMethod.FToken: Pointer` idem.
Nenhum desses records **possui** heap. `TModernRTTIContext` **seria o
primeiro** — e por isso e o unico que precisa de `IInterface`.

Ganhamos essa fronteira porque o arquiteto foi verificar por que os
`FToken: Pointer` existentes eram seguros **antes** de aceitar a
critica do reviewer. Deixar a frase escrita evita que outro record
proprietario de heap, daqui a seis meses, copie o padrao `Pointer` "por
analogia" e reintroduza a mesma bomba.

### D-28.3 — Registry per-instancia no FPC (nao global)

`TFPCContextToken` carrega `FContext: TRttiContext` **e** `FRegistry:
TList` (de `PTypeInfo`). Cada `TModernRTTIContext.Create` produz um
registry **novo**. `ContextGetType` e `ContextRegisterType` alimentam
o registry sem duplicar.

**Por que:** registry global tornaria o cenario "empty raises"
ordem-dependente (qualquer cenario anterior sujaria a global e o
`raise` nao dispararia). Per-instancia, cada contexto nasce vazio e a
mutacao e trivialmente detectavel.

**Alternativa unica considerada e descartada:** consultar registro
global de `Classes` (`ClassList`) — porta fechada, e privada da
implementacao (M-A do relatorio).

### D-28.4 — `GetTypes` com registry vazio **levanta** `EModernRTTIError`

No FPC, `ContextGetTypes` com `FRegistry.Count = 0` levanta
`EModernRTTIError` com a mensagem instrutiva
`SModernRTTIError_EmptyRegistry`.

**Por que:** o **nome** `GetTypes` promete "todos os tipos". Array
vazio silencioso e indistinguivel de "esqueci de registrar"; a
divergencia com Delphi (que enumera pool nativo) seria sistematica sem
erro. Isso e exatamente o que D-26 do ciclo 011 proibe.

Distincao vs. `ModernAttributes`: la o consumidor **sabe** que atributo
so existe registrado. Aqui o nome mente — por isso levanta.

### D-28.5 — `FindType` no FPC ramifica por `Kind`; so resolve `tkClass`

`ContextFindType` percorre `FRegistry`; **so** para `P^.Kind =
tkClass` monta `GetTypeData(P)^.UnitName + '.' + P^.Name` e compara.
Outros kinds sao pulados. Nao achou → `TModernRTTIType.FromRtti(nil)`.
XMLDoc de `FindType` declara a divergencia de cobertura.

**Por que:** medido kind a kind — `UnitName` so existe para `tkClass`
naquele layout de `TTypeData`. Ler para outros kinds e lixo ou AV
silencioso.

**Descartado:** fallback por nome simples. O Delphi nativo so bate
qualificado; comparacao simples empurraria `{$IFDEF}` para o consumidor.

### D-28.6 — `ContextFree` eliminado; `Free` publico opcional

`ContextFree` **deixa de existir** nos dois backends — o refcount
libera. `TModernRTTIContext.Free` publico vira `FToken := nil` e e
**opcional**, mantido so por paridade com `TRttiContext.Free` do
Delphi. XMLDoc diz isso em voz alta.

**Consequencia sobre a interface do consumidor:** `try/finally
Ctx.Free` deixa de ser obrigatorio. Isso e ganho, nao regressao —
consumidor esquecer `Free` deixou de ter custo.

### D-28.7 — `RegisterType` publico com XMLDoc do no-op no Delphi

`RegisterType(ATypeInfo)` esta na superficie publica de
`TModernRTTIContext`. **No Delphi e no-op** (delega ao `GetType`
nativo por consistencia); **no FPC alimenta o registry**. XMLDoc do
metodo carrega essa divergencia; o XMLDoc do `GetTypes` carrega a
outra metade (a divergencia de conteudo). **Separados de proposito**
(M-D) — o consumidor le o metodo que chama, nao o vizinho.

### D-28.8 — `GetPackages` fora, motivo em XMLDoc do tipo

`GetPackages` **nao entra** na superficie publica. Nao ha primitiva
no FPC — o conceito de "pacote" e do Delphi. Motivo registrado em
XMLDoc do proprio `TModernRTTIContext` (precedente:
`TModernRTTIMethod.GetParameters` em `ModernSyntax.RTTI.pas:247`).

### D-28.9 — `TModernRTTIType.IsNil` como predicado

`function IsNil: Boolean;` em `TModernRTTIType` (corpo `Result :=
FType = nil;`) torna inspecionavel a resposta "nao encontrado" que
`FindType` produz via `TModernRTTIType.FromRtti(nil)`. **`nil` aqui e
resposta verdadeira**, nao falha escondida (RB-5 do [esp](pipeline-esp.md)).

### D-28.10 — Cinco cenarios, um FPC-only na casca, cenario 5 afirma tres coisas

- Cinco cenarios em `Test Shared/EclbrSystem/UScenarios.RTTI.pas`
  (Pascal puro, `try/except` + `Fail(...)`).
- Cenario 1 (`_EmptyRegistry_Raises`) e publicado **so pela casca
  FPC** — padrao "dois cenarios distintos" da #25.
- Cenario 5 (`_CopyByValue_SharesState_NoUseAfterFree`) afirma **tres**
  coisas encadeadas (enxerga, sobrevive ao `Free` da outra com
  contagem certa por busca por nome, `B.Free` posterior nao levanta).
  Afirmar so a (1) passa verde com o `Pointer` de volta e mata a
  proteção.
- **Mutacao obrigatoria** documentada no comentario do cenario 1:
  remover o `raise` do backend deve tornar o cenario vermelho.

### D-28.11 — Padrao de teste (reforcado)

- `try/except on E: EModernRTTIError` + `Fail(...)` **sempre**.
- **Nunca `Assert`** — o compilador REMOVE sem `-Sa`, e
  `.project/SKILL.md:37` nao usa `-Sa`.
- **Nunca `Exception` generica** — o runner devolve **exit 0 sobre
  vermelho** (ModernSyntax#35).
- **`AssertException` NAO EXISTE** — foi inventado uma vez na #27.
- **Multiplicidade exata quando possivel** (licao da #38): cenario 2
  registra dois tipos e verifica ambos por busca por nome.

## Consequencias

- **Ganho estrutural:** `TModernRTTIContext` copiavel por valor com
  seguranca — `B := A`, passagem por valor, `Result := ...`, campo de
  outro record, todos preservam invariante. Consumidor nao precisa de
  `try/finally`.
- **Portao de compilacao entre backends** preservado: cinco funcoes
  `Context*` com assinatura identica; adicionar em so um lado quebra o
  build.
- **`TModernRTTI.GetType` global** intocado, com uma linha de XMLDoc
  dizendo que **nao alimenta** o `GetTypes` de nenhuma instancia.
- **Zero regressao** nos 23 cenarios existentes — nenhum toca
  `TModernRTTIContext`, `GetTypes` ou `FindType`.
- **Fronteira nomeada (D-28.2) governa a arquitetura daqui em diante:**
  qualquer record novo que passe a **possuir** heap tem que usar
  `IInterface`, nao `Pointer`.

## Fontes

- [investigation report — issue #28] (INVESTIGATION REPORT reproduzido
  no prompt deste no).
- [/strategy/2026-08-27-modernrtti/API-MAP.md](/strategy/2026-08-27-modernrtti/API-MAP.md)
  §§1, 2, 7.
- [/history/cycles/cycle-011-38e3bcee/pipeline-adr.md](/history/cycles/cycle-011-38e3bcee/pipeline-adr.md)
  — D-26.
- [/history/cycles/cycle-010-a36e1364/pipeline-adr.md](/history/cycles/cycle-010-a36e1364/pipeline-adr.md)
  — D-25 (Fail sempre; dois cenarios distintos).
- [/SKILL.md](/SKILL.md) — toolchain, mutacao, traps.
