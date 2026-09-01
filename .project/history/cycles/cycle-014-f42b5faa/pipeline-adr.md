---
type: adr
kind: decision
title: "ADR — Tipos de categoria: FToken PTypeInfo, properties nunca *Ref, guarda por Kind, IndexedProperty adiada (issue #29)"
description: "Restatement da decisao que fechou a discussao da issue #29 (uma volta com oito medicoes M-1..M-8 do humano + resposta do agente): TModernVisibility como enum proprio para nao vazar TMemberVisibility; seis records de forma com FToken: PTypeInfo (nao FType: TRttiType — as subclasses Enum/Record/Array/Set nao existem no FPC 3.2.2); backend FPC sempre pelas properties (CompType, ElType2, ElType, RefType), nunca pelos campos *Ref crus; guarda por Kind em cada funcao (D-27 novo — TTypeData e variante); TModernRTTIArrayType ramifica na superficie publica por IsDynamic e Length levanta EModernRTTIError em dinamico nos dois compiladores; TModernRTTIRecordType sai com Name+Size apenas (sem GetFields); TModernRTTIIndexedProperty sai desta issue e vira issue propria com blocked:fpc-3.4; D-28.2 preservado — todos os FToken apontam para PTypeInfo estatico do binario, nao donos de heap."
status: stable
cycle: "014"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/f42b5faad0107a1daea308f52bd50ed4
tags: [modernrtti, adr, issue-29, fpc, delphi, visibility, enumeration, pointer, record, array, set, kind-guard, ptypeinfo]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-09-01T00:00:00Z"
sources:
  - id: issue-29-report
    title: "REPORT — Issue #29 (run 92a207d48a895a4eee7c18abae08aea8) — PRESENT"
  - id: api-map
    resource: "/strategy/2026-08-27-modernrtti/API-MAP.md"
    title: "ModernRTTI API-MAP (§1, §2, §7)"
  - id: adr-025
    resource: "/history/cycles/cycle-010-a36e1364/pipeline-adr.md"
    title: "D-25.4 — membros sem fonte no FPC levantam"
  - id: adr-026
    resource: "/history/cycles/cycle-011-38e3bcee/pipeline-adr.md"
    title: "D-26 — nao silenciar divergencia"
  - id: adr-028
    resource: "/history/cycles/cycle-013-5a8dfb58/pipeline-adr.md"
    title: "D-28.2 — Pointer em record e seguro enquanto o record nao e dono"
  - id: skill
    resource: "/SKILL.md"
    title: "SKILL — receita FPC, mutacao, traps"
---

# ADR — issue #29

Este documento **deriva do relatorio de investigacao** que fechou a
discussao da issue #29 (uma volta, oito medicoes do humano — M-1 a M-8
— e a resposta do agente aceitando delta a delta, run
`92a207d48a895a4eee7c18abae08aea8`). Ele registra a decisao em vigor,
nos termos que a conversa acertou.

**Nao ha divergencia de merito** entre este ADR e o relatorio. As
oito medicoes ja estao absorvidas — em particular a troca de
`FType: TRttiType` por `FToken: PTypeInfo` (M-1), a proibicao de campos
`*Ref` crus (M-2), a assimetria estatico/dinamico do `ElType` (M-3/M-4),
o `raise` em `ArrayTypeLength` dinamico (M-5 + D-26), o corte de
`TModernRTTIIndexedProperty` para issue propria (M-7), a confirmacao da
seguranca de `FToken: PTypeInfo` sob D-28.2 (M-8), e o corte de
`TModernRTTIRecordType.GetFields` (F-3 do estudo). Este ADR so restata;
a decisao ficou.

## Contexto medido (do relatorio)

- **`TRttiEnumerationType`, `TRttiRecordType`, `TRttiArrayType`,
  `TRttiSetType` NAO EXISTEM no FPC 3.2.2** (M-1). A lista completa
  de `TRtti*Type = class` do `rtti.pp` foi enumerada: apenas
  `TRttiFloatType, TRttiOrdinalType, TRttiStringType, TRttiPointerType,
  TRttiInvokableType, TRttiMethodType, TRttiProcedureType,
  TRttiStructuredType, TRttiInterfaceType, TRttiInstanceType,
  TRttiRefCountedInterfaceType, TRttiRawInterfaceType`.
- **`IndexedProperty` nao aparece uma vez** em `rtti.pp` (M-1/M-7).
- **`GetType` no FPC devolve `TRttiType` generico** para enum, set,
  record, array; so `tkPointer` devolve subclasse (`TRttiPointerType`).
  Nao ha downcast possivel.
- **Campos `*Ref` sao `TypeInfoPtr` NAO resolvido** (M-2). Medido:
  `TD^.CompType^^.Name` → `Error: Illegal qualifier`; `TD^.CompType^.Name`
  → funciona. Ler cru sai errado sem erro de compilacao (mesmo modo
  de falha do `UnitName` da issue #28 M-B).
- **`ElType` em array DINAMICO da Access Violation quando o elemento
  e nao-managed** (M-3):
  ```
  TArray<Integer>: elSize=4 | ElType2 → LongInt    | ElType → nil       ← AV no deref
  TArray<string> : elSize=8 | ElType2 → AnsiString | ElType → AnsiString
  ```
- **Assimetria entre estatico e dinamico com mesmo nome de campo**
  (M-4): `tkArray.ArrayData.ElType` e SEMPRE preenchido;
  `tkDynArray.ElType` e NIL se nao-managed. Cenario com `TArray<Integer>`
  obriga o teste a pegar a assimetria.
- **`RecSize` medido nos dois bitness** (M-6): `16` (x86_64) / `12` (i386)
  para o mesmo record; `array of string` da `Size=24/12`; `array of
  Integer` da `Size=20/20`. Teste afirma **relacao** (`= SizeOf(T)`),
  nunca numero absoluto.
- **`TTypeData` e registro variante** (M-5): ler o campo do Kind errado
  devolve lixo sem erro de compilacao.
- **`grep -rn "\.Visibility" "Test*"` = 0 resultados** — nenhum teste
  existente quebra ao trocar a assinatura de `TModernRTTIMethod.Visibility`.
- **API-MAP §2 afirma que `TModernRTTIProperty.Visibility` esta "todos
  OK"; o codigo nao tem o membro** (F-2 do estudo).

## Decisoes

### D-29.1 — `TModernVisibility` como enum proprio; assinatura de `Method.Visibility` muda; `Property.Visibility` adicionado

O enum `TModernVisibility = (mvPrivate, mvProtected, mvPublic,
mvPublished)` e declarado no bloco `type` da `interface` de
`Source/ModernSyntax.RTTI.pas`, **antes de `TModernRTTIField`**.

`TModernRTTIMethod.Visibility` **muda de `TMemberVisibility` (do
`TypInfo`) para `TModernVisibility`** — fecha o vazamento F-1 (a API
publica nao pode citar tipo interno do RTL do compilador). Backend
Delphi mapeia 4 cases 1-para-1; backend FPC levanta `EModernRTTIError`
(mantido — hoje ja levanta, so muda o tipo do `Result`).

`TModernRTTIProperty.Visibility: TModernVisibility` **e adicionado**
(F-2): a API-MAP §2 promete o membro e o codigo nao tem. Backend Delphi
delega ao RTTI nativo; backend FPC levanta (paridade estrita com
`MethodVisibility` — mesma familia de dado, mesma limitacao).

**Por que:** um enum publico proprio isola a superficie da camada da
`System.TypInfo` do compilador; sem ele, um consumidor teria que dar
`uses TypInfo` so para atribuir `Visibility` a uma variavel — exatamente
o que o produto existe para eliminar (§1 do API-MAP: "a RTTI nova do
Delphi espelhada e disponivel igual nos dois compiladores").

**Descartado:** manter `TMemberVisibility` como tipo publico. Motivo:
vaza o compilador na assinatura da camada; falha o objetivo da abstracao.

**Descartado:** enum com nomes diferentes (`vPrivate`/`vProtected`/etc.).
Motivo: alinhamento com `TypInfo.TMemberVisibility` (mesma ordem,
`mv`-prefix) preserva mapeamento 1-para-1 no backend Delphi — zero
translacao alem do cast.

### D-29.2 — Seis records de forma com `FToken: PTypeInfo`, nao `FType: TRttiType`

Os seis novos records (`TModernRTTIEnumerationType`,
`TModernRTTIPointerType`, `TModernRTTIRecordType`, `TModernRTTIArrayType`,
`TModernRTTISetType`) guardam `FToken: PTypeInfo` — **nao**
`FType: TRttiType`.

**Por que:** medido em M-1. `TRttiEnumerationType`, `TRttiRecordType`,
`TRttiArrayType`, `TRttiSetType` **nao existem** no FPC 3.2.2. `GetType`
devolve `TRttiType` generico; downcast e impossivel. Backend FPC le
tudo via `GetTypeData(P)`.

`TModernRTTIPointerType` **tambem** adota `FToken: PTypeInfo`, embora
`TRttiPointerType` exista no FPC. Coerencia: fixar duas convencoes na
mesma unit convida bug. Se um dia a implementacao interna precisar da
subclasse, o backend Delphi cast internamente com
`TRttiPointerType(Rtti.GetType(FToken))` — sem alterar a superficie
publica.

**Consequencia (aceita na volta 1):** duas fabricas convivem na
unit — `TModernRTTIType.FromRtti(TRttiType)` (inalterada) e
`FromTypeInfo(P: PTypeInfo)` nos seis novos records. Custo de dez
linhas por record no `interface`.

**Descartado:** `FType: TRttiType` unico. Motivo: **medido** (M-1)
que a subclasse nao existe. Downcast so no `tkPointer`. Aplicar a
convencao unica quebraria os cinco records restantes.

**Descartado:** `TModernRTTIPointerType` com convencao propria
(`FType: TRttiType`). Motivo: duas convencoes na mesma unit convidam
bug (M-1).

### D-29.3 — Frase-fronteira D-28.2 preservada: `FToken: PTypeInfo` e seguro

Todos os seis `FToken` apontam para `PTypeInfo` **estatico do binario**
— o RTTI vive na imagem do executavel; ninguem aloca, ninguem libera,
nenhuma copia gera dono duplicado.

**Por que:** confirma a fronteira D-28.2 do ciclo 013 — *"Pointer em
record e seguro enquanto o record nao e dono; vira bomba no instante em
que passa a ser."* Estes seis records nao possuem heap; sao referencias
nao-donas, como `TModernRTTIField.FToken` (offset) e
`TModernRTTIProperty.FToken` (referencia ao objeto RTTI vivo). O
precedente D-28.2 explicitamente cobre este caso.

**Confirmado um por um** (M-8):
- `TModernRTTIEnumerationType.FToken` → `PTypeInfo` estatico do enum
  no binario. Nao-dono. Seguro.
- `TModernRTTIPointerType.FToken` → `PTypeInfo` estatico do pointer.
  Nao-dono. Seguro.
- `TModernRTTIRecordType.FToken` → `PTypeInfo` estatico do record.
  Nao-dono. Seguro.
- `TModernRTTIArrayType.FToken` → `PTypeInfo` estatico do array.
  Nao-dono. Seguro.
- `TModernRTTISetType.FToken` → `PTypeInfo` estatico do set. Nao-dono.
  Seguro.

**Consequencia futura:** se algum membro (ex.: `GetFields` de
`TModernRTTIRecordType`, quando entrar em issue propria) precisar
materializar array proprio, o array segue as regras de `TArray<T>`
(owned pelo caller no idioma Delphi/FPC); o record continua nao-dono.

### D-29.4 — Backend FPC sempre pelas properties, nunca pelos campos `*Ref` crus

`CompType`, `ElType2`, `ElType`, `RefType` — as **properties** —
resolvem o `TypeInfoPtr` e devolvem `PTypeInfo`. Ler os campos crus
`CompTypeRef`, `elType2Ref`, `elTypeRef`, `RefTypeRef` sai errado
**sem erro de compilacao** (M-2).

**Por que:** medido — `TD^.CompType^^.Name` → `Error: Illegal
qualifier` (dois deref, um a mais); `TD^.CompType^.Name` → funciona
(um deref, resolve como esperado). Mesmo modo de falha do `UnitName`
da issue #28 M-B: silencio venenoso.

**Regra:** cada acesso no backend FPC usa a property, com o nome
literal `RefType`/`CompType`/`ElType2`/`ElType` — **nunca**
`RefTypeRef`/`CompTypeRef`/`elTypeRef`/`elType2Ref`. Cenarios 5
(`_PointerType_ReferredType_Matches`) e 10 (`_SetType_ElementType_
Is_UnderlyingEnum`) declaram no comentario a mutacao obrigatoria
(property → campo cru → vermelho ou AV).

**Descartado:** ler campos crus. Motivo: modo de falha silencioso
medido em M-2 (mesma familia do #28 M-B). Estritamente proibido.

### D-29.5 — Backend FPC ramifica por `Kind` em CADA funcao (D-27 novo)

Cada uma das catorze funcoes livres do backend FPC (mais
`MethodVisibility` e `PropertyVisibility`) **comeca** com uma guarda:
```pascal
if P^.Kind <> tk<Esperado> then
  raise EModernRTTIError.CreateFmt(
    '<Nome da funcao>: esperava tk<X>, veio %d', [Ord(P^.Kind)]);
```
(A mensagem exata fica com o implementador — o padrao e nomear a funcao
e o kind esperado.)

Casos:
- `EnumTypeMinValue/MaxValue/GetNames/GetName/GetValue/EnumTypeName` →
  `tkEnumeration`.
- `PointerTypeReferredType` → `tkPointer`.
- `RecordTypeName/RecordTypeSize` → `tkRecord`.
- `ArrayType*` → `tkArray` OR `tkDynArray` (ramifica internamente
  por qual dos dois; qualquer outro kind levanta).
- `SetTypeElementType` → `tkSet`.

**Por que:** `TTypeData` e registro variante (M-5). Ler o campo de outro
kind acessa memoria em posicao diferente da esperada — lixo silencioso
ou AV. Sem erro de compilacao, sem sinal em runtime que o kind estava
errado. A guarda pega o erro no lugar do erro.

**Por que ADR novo (D-27):** este e o primeiro ciclo em que multiplas
funcoes livres do backend FPC leem `GetTypeData` em kinds diferentes
proximos uns dos outros. Antes desta issue, uma unica funcao por kind
era a norma; o risco de trocar kinds era baixo. Com catorze funcoes em
seis kinds distintos entrando de uma so vez, a regra vale a pena
escrita e ganha nome.

**Descartado:** guarda opcional ("se der tempo"). Motivo: falha
silenciosa em runtime e proibida (D-26 — nao silenciar divergencia).
Guarda ausente e regressao potencial de qualquer feature dependente.

### D-29.6 — `TModernRTTIArrayType` ramifica na superficie publica; `Length` levanta em dinamico

O predicado `IsDynamic: Boolean` esta na superficie publica —
consumidor discrimina sem apanhar excecao. `Length: Integer` no
`tkDynArray` **levanta** `EModernRTTIError` nos dois compiladores.

**Por que:** capacidade de array dinamico e **run-time**, nao RTTI. O
consumidor conhece o `Length(oarray)` do valor, nao do tipo. Nome
`Length` no tipo mente se devolver `0` silencioso; D-26 proibe.
Semantica identica FPC/Delphi mantida — nao ha razao para o Delphi
devolver um numero e o FPC levantar quando o significado do numero e
nulo nos dois casos.

**Consumidor** faz:
```pascal
if not LArrType.IsDynamic then
  ShowMessage(IntToStr(LArrType.Length))
else
  // usar System.Length(oarray) sobre o valor
```

**Descartado:** `Result := 0` no dinamico. Motivo: D-26. Zero e
indistinguivel de "array estatico de zero elementos" (que existe,
e valido, e informativo).

**Descartado:** `Length` so no `TModernRTTIArrayType` estatico e
propriedade ausente no dinamico. Motivo: superficie publica assimetrica
(dois records de array) violaria a promessa de "a RTTI do Delphi, igual
nos dois compiladores". O consumidor teria que ramificar por tipo do
record — exatamente o que a camada existe para nao pedir. `IsDynamic`
+ `Length` que levanta e o padrao consagrado do #28 (`FindType` que
devolve `nil`, com `IsNil` para discriminar).

### D-29.7 — `TModernRTTIRecordType` sai com `Name` + `Size` apenas; sem `GetFields`

O Diretor mediu `RecSize` mas **nao mediu** `TRecordElement.Name` no
FPC 3.2.2 (F-3 do estudo). Interpretacao: se nao mediu, nao vai. A
superficie de `TModernRTTIRecordType` fica em `Name` + `Size`.

**`GetFields` fica para issue propria**, condicionada a medir
`TRecordElement.Name` num FPC vivo — se o campo existir e for legivel,
`GetFields` entra; se nao, a issue propria decide se leva D-25.4 no
FPC ou volta para o backlog.

**Por que:** o padrao consagrado do repositorio (F-3, mesmo padrao de
`TModernRTTIIndexedProperty` em M-7 e de `TModernRTTIField.GetFields`
no ciclo 003) — nao entregar o que nao foi medido. A funcao nao vai
"num galho" atras dela; ela entra quando o dado esta la.

**Descartado:** `GetFields` que levanta no FPC. Motivo: 100% da
superficie publica levantaria — mesma logica de M-7 sobre
`IndexedProperty`. Diferenca qualitativa entre "membro sem dado no FPC
que ja entrega noutros lugares" (D-25.4 aceito) e "tipo inteiro sem
dado no FPC" (issue propria).

### D-29.8 — `TModernRTTIIndexedProperty` sai desta issue; issue propria com `blocked:fpc-3.4`

`IndexedProperty` **nao aparece uma vez** em `rtti.pp` do FPC 3.2.2
(M-7). 100% da superficie publica levantaria D-25.4 no FPC. Isso e
qualitativamente diferente dos outros seis, que entregam fonte real
nos dois compiladores em pelo menos um membro.

**Vira issue propria** com label `blocked:fpc-3.4` — dependente do
FPC 3.4 (ou de uma decisao explicita de "so-Delphi com raise no FPC",
tomada la, nao aqui). A API-MAP §1 recebe nota "adiada" na linha do
IndexedProperty.

**Por que:** a issue #29 tem no cabecalho "compila e funciona nos
dois compiladores" — um tipo inteiro que so levanta no FPC viola o
espirito da issue. Melhor um corte declarado e uma issue propria do
que uma entrega parcial que subverte o contrato.

**Descartado (alternativa considerada):** `TModernRTTIIndexedProperty`
com todos os metodos levantando `EModernRTTIError` no FPC, so-Delphi
em pratica. Motivo: o consumidor no FPC nao teria como usar a classe
inteira; `IsAvailable: Boolean` no tipo? — cria outra ramificacao que
o consumidor teria que codificar. Postergar a issue e mais honesto.

### D-29.9 — Cenarios: dois pares FPC-only/Delphi-only para visibilidade; oito cenarios compartilhados

- **Fase 1 (Visibility):** dois cenarios FPC-only (levantam) e dois
  Delphi-only (devolvem `mvPublished`/`mvPublic`). Padrao "dois
  cenarios distintos" da #25 (D-25). Sem `{$IFDEF FPC}` no cenario;
  a casca escolhe o que publica.
- **Fase 2 (Enumeration):** dois cenarios compartilhados (3 e 4).
- **Fase 3 (Pointer):** um cenario compartilhado (5) com comentario
  de mutacao obrigatoria (`RefType` → `RefTypeRef`).
- **Fase 4 (Record):** um cenario compartilhado (6) afirmando
  `Size = SizeOf(TFixture)` (relacao, nao numero — M-6).
- **Fase 5 (Array + Set):** quatro cenarios compartilhados (7, 8, 9,
  10). O cenario 8 e o que separa `ElType2` (certo) de `ElType`
  (AV) com `TArray<Integer>` (M-3/M-4) — comentario de mutacao
  obrigatoria (`ElType2` → `ElType`). O cenario 10 tem mutacao
  obrigatoria (`CompType` → `CompTypeRef` — mesmo padrao de M-2).

**Padrao (RB-6 preservado):** `try/except on E: EModernRTTIError` +
`Fail(...)` sempre; **nunca `Assert`**; **nunca `Exception` generica**;
`AssertException` nao existe.

**Multiplicidade obrigatoria:** enum com >= 3 constantes; record com
>= 2 campos; array com contagem definida.

### D-29.10 — API-MAP §1 recebe nota "adiada" para IndexedProperty

Edicao em prosa (nao muda arquitetura) — atualizar a tabela de tipos
para refletir que `TModernRTTIIndexedProperty` foi adiada. Redacao
sugerida na linha do `TRttiIndexedProperty`:

> AUSENTE | `TModernRTTIIndexedProperty` | **adiada** — issue propria com `blocked:fpc-3.4` (M-7 do ciclo 014). `IndexedProperty` nao existe em `rtti.pp` do FPC 3.2.2.

## Consequencias

- **Ganho estrutural:** seis tipos publicos que fecham a **categoria de
  forma** da ModernRTTI. O consumidor consegue reflexao sobre enum,
  record, array e set nos dois compiladores, com a semantica identica
  onde possivel (visibilidade levanta no FPC — divergencia declarada).
- **Vazamento `TMemberVisibility` fechado** — a superficie publica da
  camada nao cita mais tipo interno do RTL do compilador.
- **Portao de compilacao entre backends** preservado: cada nova funcao
  livre entra em paridade estrita nos dois `.pas`; adicionar em um so
  quebra o build (API-MAP §7).
- **API-MAP §2 fica consistente** — a promessa de "Visibility todos OK"
  passa a ser verdade (F-2 fechado).
- **Fronteira D-28.2 confirmada** — seis novos records nao donos de
  heap; frase-fronteira vale para toda a familia `TModernRTTI*Type` de
  forma daqui em diante.
- **D-27 novo:** guarda por `Kind` em CADA funcao do backend FPC.
  Passa a ser regra do repositorio, nao so desta issue.
- **Zero regressao** nos 23+ cenarios existentes de `UScenarios.RTTI.pas`
  — nenhum toca os tipos novos nem `TModernRTTIMethod.Visibility` (o
  `grep -rn "\.Visibility" Test*` = 0 do relatorio confirma).
- **Contrato binario interno alterado:** `TModernRTTIMethod.Visibility`
  muda de `TMemberVisibility` para `TModernVisibility`. Consumidor
  externo (fora do repo) que atribuisse a variavel `TMemberVisibility`
  precisa atualizar. Sendo interno ate aqui, impacto zero fora do repo.
- **`IndexedProperty` postergada** — API-MAP §1 recebe nota; issue
  propria com `blocked:fpc-3.4` abrira quando este PR fechar.
- **`GetFields` de `TModernRTTIRecordType` postergada** — vira issue
  propria condicionada a medir `TRecordElement.Name`.

## Fontes

- [investigation report — issue #29] (INVESTIGATION REPORT reproduzido
  no prompt deste no).
- [/strategy/2026-08-27-modernrtti/API-MAP.md](/strategy/2026-08-27-modernrtti/API-MAP.md)
  §§1, 2, 7.
- [/history/cycles/cycle-010-a36e1364/pipeline-adr.md](/history/cycles/cycle-010-a36e1364/pipeline-adr.md)
  — D-25.4.
- [/history/cycles/cycle-011-38e3bcee/pipeline-adr.md](/history/cycles/cycle-011-38e3bcee/pipeline-adr.md)
  — D-26.
- [/history/cycles/cycle-013-5a8dfb58/pipeline-adr.md](/history/cycles/cycle-013-5a8dfb58/pipeline-adr.md)
  — D-28.2.
- [/SKILL.md](/SKILL.md) — receita FPC, mutacao, traps.
