---
type: adr
kind: artifact
title: "ADR — TModernRTTIField portável: um tipo, dois mecanismos por dentro (issue #21)"
description: "Substitui D12 do ADR do ciclo 006. TModernRTTIField e TModernRTTIType.GetFields deixam de ser Delphi-only por ausência de compilação e passam a ter superfície pública única nos dois compiladores, com a mecânica FPC via vmtFieldTable tipada, iteração pela property Field[i], subida por ClassParent, factories privadas com nomes distintos por branch, contrato de ordem NÃO especificada, vmtFieldTable=nil devolve array vazio, cast explícito ShortString→string."
status: stable
cycle: "008"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/e4baa827945b3dd3a372629b831d73a9
tags: [modernrtti, rtti, adr, issue-21, fpc, delphi]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-08-31T00:00:00Z"
sources:
  - id: investigation
    title: "REPORT — Issue #21 (investigate run aed3171c29de093b8b839c7e0c028bff)"
  - id: prd
    resource: "/strategy/2026-08-27-modernrtti/PRD.md"
    title: "ModernRTTI PRD"
  - id: adr-006
    resource: "/history/cycles/cycle-006-0432fa58/pipeline-adr.md"
    title: "ADR — Pilar 1 ModernRTTI (D12 substituída por esta)"
  - id: esp
    resource: "esp.md"
    title: "ESP — TModernRTTIField portável (issue #21)"
---

# ADR — TModernRTTIField portável (issue #21)

> **Este ADR DERIVA do REPORT — Issue #21 do `investigate` run
> `aed3171c29de093b8b839c7e0c028bff`**, entregue verbatim no prompt do
> `architect`. Na conversa em 3 voltas, dono e agente fixaram cada uma das
> decisões abaixo — este ADR **as registra**, sem substituir. **Nenhuma
> divergência** desta arquitetura em relação ao REPORT.

## Contexto

- **Estado medido do repositório (entrega do Pilar 1, ciclo 006):**
  `Source/ModernSyntax.RTTI.pas` traz `TModernRTTIField` e
  `TModernRTTIType.GetFields` **ausentes por compilação no FPC** via
  `{$IFNDEF FPC}` externo. O consumidor que declarar `var LField:
  TModernRTTIField;` **não compila no FPC** — precisa `{$IFDEF FPC}` no
  seu próprio código para contornar. Isso viola CA-5 e D2 do
  [PRD](/strategy/2026-08-27-modernrtti/PRD.md).
- **A justificativa do D12** era que `TRttiField` e
  `TRttiType.GetFields` não existem no FPC 3.2.2. **Continua verdade e é
  irrelevante:** o FPC oferece caminho alternativo público e tipado —
  `vmtFieldTable` para enumerar, offset para ler/escrever, `TObject.FieldAddress`
  para buscar por nome. A camada ModernRTTI existe exatamente para
  absorver essa diferença.
- **Este é o segundo caso da família** em que "o recurso não existe no
  FPC" se revelou "o recurso existe por outro caminho". O primeiro foi o
  Pilar 3 (issue #10, ciclo 005), onde `TRttiMethod.Invoke` não existe e
  `TObject.MethodAddress` resolveu.
- **Enquadramento do dono (volta 1):** a RTTI do FPC é **poderosa, só
  burocrática** — o Object Inspector do Lazarus mostra tudo por
  `TypInfo`/`GetPropInfo`/`GetPropList` (`propedits.pp` do Lazarus tem
  9332 linhas). ModernRTTI leva ao Lazarus o **padrão da RTTI nova do
  Delphi absorvendo essa burocracia** — não trata o FPC como pobre.

## Decisões

### D1 — `TModernRTTIField` deixa de ser Delphi-only

O record `TModernRTTIField` e o membro `TModernRTTIType.GetFields`
passam a ter **declaração pública incondicional**, existir e compilar
nos dois compiladores. O `{$IFNDEF FPC}` externo é **removido** de
`Source/ModernSyntax.RTTI.pas:50-78`, `:135-143` e `:234-264`, `:303-314`.

**Substitui D12 do [ADR do ciclo 006](/history/cycles/cycle-006-0432fa58/pipeline-adr.md).**
D12 permanece intocada no histórico; esta decisão é a nova em vigor.

### D2 — Um tipo, dois mecanismos por dentro (superfície única)

A ramificação por compilador vive **apenas** em `strict private` do
record e no corpo dos métodos da `implementation`:

```pascal
TModernRTTIField = record
strict private
  {$IFDEF FPC}
  FOwner: TClass; FName: string; FOffset: PtrUInt;
  {$ELSE}
  FField: TRttiField;
  {$ENDIF}
public
  function Name: string;
  function GetValue<T>(const AInstance: TObject): T; overload;
  procedure SetValue<T>(const AInstance: TObject; const AValue: T); overload;
  function GetValue(const AInstance: TObject): TValue; overload;
  procedure SetValue(const AInstance: TObject; const AValue: TValue); overload;
end;
```

Zero `{$IFDEF FPC}` na declaração pública. D2 do
[PRD](/strategy/2026-08-27-modernrtti/PRD.md) autoriza ramificação
**dentro** da biblioteca (é o que se faz aqui).

### D3 — Factories privadas com nomes distintos por branch

Duas factories privadas, nomes diferentes por branch, para o
implementador não confundir assinaturas sob `{$IFDEF}`:

- **FPC:** `class function FromRaw(AOwner: TClass; const AName: string; AOffset: PtrUInt): TModernRTTIField; static;`
- **Delphi:** `class function FromRtti(const AField: TRttiField): TModernRTTIField; static;`

**Descartada** (volta 1, revertida na volta 3): factory unificada
`FromRtti` nos dois branches com assinaturas diferentes sob `{$IFDEF}`.
Nomes iguais + assinaturas diferentes = receita para chamada errada
descoberta só no compilador.

### D4 — No FPC, enumeração via `vmtFieldTable` **tipada e pública**

`PVmtFieldTable(PVmt(LCur)^.vFieldTable)` — não `PVmtFieldTable(Pointer(PByte(LClass) + vmtFieldTable))^`.
Caminho tipado e público: `PVmt`/`TVmt` em `objpash.inc:99-108`,
`PVmtFieldTable`/`TVmtFieldTable` em `typinfo.pp:212-227`, com precedente
de produção na própria RTL do FPC (`reader.inc:588`).

**Descartada:** aritmética de ponteiro com a constante `vmtFieldTable`
(M1 do REPORT). Desnecessária e frágil quando existe caminho tipado
público de nível equivalente.

### D5 — No FPC, iteração pela property `Field[i]`

Entradas `TVmtFieldEntry` têm **tamanho variável** (o campo `Name:
ShortString`). O comentário da própria RTL alerta em `typinfo.pp:224-226`:
*"should be array[Word] of TFieldInfo; but Elements have variant size!"*
Use `LTab^.Field[i]` (a property que caminha corretamente por
`GetField`), **não** `LTab^.Fields[i]` como array.

**Descartada:** indexação `LTab^.Fields[i]` como array (M2 do REPORT).
Lê lixo a partir da segunda entrada.

### D6 — No FPC, subir a cadeia por `ClassParent`

`vmtFieldTable` do FPC **não é recursiva** (`jitclass.pas:1187-1188`);
`TRttiType.GetFields` do Delphi **inclui herdados**. Sem subida, mesma
classe entrega Delphi 2 campos / FPC 1 — divergência silenciosa entre
compiladores. Conserto medido (M3 do REPORT com `TBase`/`TDerived`/`TDerived2`):

```pascal
LCur := LClass;
while LCur <> nil do
begin
  LTab := PVmtFieldTable(PVmt(LCur)^.vFieldTable);
  if LTab <> nil then
    for LI := 0 to LTab^.Count - 1 do
    begin
      LEntry := LTab^.Field[LI];
      Append(TModernRTTIField.FromRaw(LCur, string(LEntry^.Name),
                                       LEntry^.FieldOffset));
    end;
  LCur := LCur.ClassParent;
end;
```

`vFieldTable = nil` num elo é **rotina**, não erro — pular o elo, não
interromper (visto no `TDerived` sem campo próprio mas herdando `InnerA`).
`AOwner` guarda o **elo declarante** (não a classe raiz) — preserva debug.

### D7 — `vmtFieldTable = nil` na cadeia inteira devolve array vazio

Sem exceção. Simetria com o comportamento do Delphi (classe sem campos
enumeráveis também devolve vazio). A medição do `TDerived`
(`vFieldTable = nil` mas com campo herdado válido) prova que `nil` num
elo é rotina; levantar em `nil` transformaria o normal em erro.

**Descartada:** `raise` quando `vmtFieldTable = nil` (Q2 do REPORT,
ratificada na volta 2). Paralelismo com o `raise` de `GetProperties` (que
existe para `{$M+}` ausente, erro do consumidor) pesa menos que a
simetria de comportamento entre compiladores.

### D8 — Cast explícito `string(LEntry^.Name)` (`ShortString`)

`TVmtFieldEntry.Name` é `ShortString` (`typinfo.pp:205-210`). A factory
`FromRaw(AOwner, const AName: string, AOffset)` recebe `string`. A
chamada deve ser `FromRaw(LCur, string(LEntry^.Name), LEntry^.FieldOffset)`.
Sem o cast, warning de compilador ou perda em não-ASCII.

### D9 — Overload `TValue` no FPC: opção (a) `TValue.From<TObject>`

`GetValue: TValue` no FPC: `TValue.From<TObject>(PPointer(PByte(AInstance) + FOffset)^)`.
`SetValue(TValue)` no FPC: `PPointer(PByte(AInstance) + FOffset)^ := TObject(AValue.AsObject)`.
Sempre classe (limite `published` do FPC — só aceita tipo classe).

O custo teórico (`uses Rtti` + warning `experimental`) **já está pago**:
a unit hoje faz `uses Rtti` e o warning `Warning: Unit "Rtti" is
experimental` já sai nos dois bitness em cada build.

**Descartadas** (Q1 do REPORT, volta 1):
- **(b) `raise` no overload FPC** — viola "mesma superfície";
- **(c) `{$IFDEF}` isolado no overload público FPC** — tipo público
  jamais sob `{$IFDEF}` de compilador (regra do dono).

### D10 — Contrato de ordem: **NÃO especificada**

O array retornado por `GetFields` **não tem ordem promissível**.
Consumidores devem **buscar por nome, não indexar por posição**, em
ambos os compiladores. O XMLDoc de `GetFields` declara em voz de
contrato.

**Motivo:** ninguém mediu `dcc32` neste ciclo (o dono não tem `dcc32`, o
agente não tem Delphi no container). Prometer paridade de ordem sem
medição é falso — e o cenário compartilhado já busca por nome sem
depender de ordem. Coerência com o teste, honesto quanto ao que foi
medido.

**Descartada** (volta 2, revertida na volta 3): "coincide com o que o
Delphi devolve na prática (`GetFields` inclui herdados após os
declarados)". Afirmação não medida — retirada.

### D11 — XMLDoc em voz de contrato; "no FPC" obrigatório

O tom da doc muda de "limite do compilador FPC 3.2.2" para **contrato
da abstração**: *"GetFields enumera os campos que a RTTI de cada
compilador reconhece como enumeráveis; no Delphi, por visibilidade RTTI;
no FPC, campos `published` de tipo classe"*. A palavra **"no FPC"** é
obrigatória (critério de aceite herdado do PRD).

**Motivo (volta 1):** a RTTI do FPC é poderosa (Object Inspector do
Lazarus prova). Descrição de contrato, não lamento de limite.

### D12 — Fixture com herança e assertiva de contagem exata

A fixture do cenário compartilhado é forma **B** (`TInner` nomeado):

```pascal
{$M+}
TInner  = class end;
TBase   = class InnerA: TInner; end;
TPortableFieldFixture = class(TBase) InnerB: TInner; end;
{$M-}
```

Motivos medidos (voltas 2/M4 e 2/M5):
1. **Sem herança**, recursivo e não-recursivo dariam o mesmo número — o
   teste passaria cego para D6.
2. **Forma A (`TObject` cru inline)** esconderia no teste a regra "só
   tipo classe". Forma B com `TInner` nomeado torna a regra visível.

Assertiva: `Length(GetFields) = 2` **exato** (para pegar regressão de D6
ou duplicação); nomes `InnerA` e `InnerB` conferidos por busca no
array, **sem depender de ordem** (D10).

### D13 — D12 do ADR do ciclo 006 é **substituída**, não revertida

O ADR histórico do ciclo 006 permanece intocado. Esta decisão é a nova
em vigor. Consumidores que se protegiam com `{$IFDEF FPC}` para não
referenciar `TModernRTTIField` continuam compilando (o `{$IFDEF}` fica
desnecessário, mas não quebra).

## Convergências herdadas (cross-check do REPORT)

- **D8 do [ADR ciclo 006](/history/cycles/cycle-006-0432fa58/pipeline-adr.md) — `{$IFDEF FPC}` direto, sem `.inc`** —
  respeitado (produção **não** inclui `ModernSyntax.inc`).
- **D9 do [ADR ciclo 006](/history/cycles/cycle-006-0432fa58/pipeline-adr.md) — casca fina, cenário compartilhado** —
  respeitado (a lógica vive em `UScenarios.RTTI.pas`; casca FPC = uma
  linha útil).
- **D10 do [ADR ciclo 006](/history/cycles/cycle-006-0432fa58/pipeline-adr.md) — cabeçalho `(* … *)`** — respeitado
  (mudança não toca no header).
- **Limite `published` só aceita tipo classe no FPC** — não é convenção
  de projeto, é comportamento do compilador (erro medido no ciclo 006:
  *"Symbol cannot be published, can be only a class"*).
- **Escopo `Q5` permissivo (REPORT):** só os três arquivos de teste
  podem ser tocados; produção fica só em `ModernSyntax.RTTI.pas`.

**Divergências em relação ao REPORT do investigate:** nenhuma.

## Consequências

**Positivas:**
- Consumidor escreve o mesmo código nos dois compiladores para campos
  (CA-5 do PRD). O tipo existe nos dois; a mecânica interna difere.
- Silêncio venenoso do FPC (divergência recursivo/não-recursivo, D6) é
  eliminado por medição — não fica dependente de leitura por revisão.
- Substitui D12 do ciclo 006 sem quebrar código consumidor existente
  (protegido por `{$IFDEF FPC}` continua compilando).
- XMLDoc em voz de contrato eleva a percepção da RTTI do FPC de
  "limite" para "padrão vivo" — corrige uma assimetria de tom que a
  volta 1 detectou.

**Negativas / aceitas:**
- **Fixture com herança não medida em Delphi** neste ciclo (RSK-1 do
  ESP). Sintaxe padrão, risco baixo mas não zero; o dono da máquina
  Delphi decide entre `{$M+}...{$M-}` em bloco vs `{$M+}` só em `TInner`
  se falhar.
- **`vmtFieldTable` no FPC só vê `published` de tipo classe** — regra do
  compilador, não escolha nossa. Documentada em XMLDoc em voz de
  contrato ("no FPC, só campos `published` de tipo classe").
- **`TValue.From<TObject>` no FPC 3.2.2** pode falhar para `T` genérico
  complexo (limite conhecido da `Rtti` FPC — motivo do `experimental`).
  Fallback: overload `TValue` cru é o caminho recomendado para esses
  casos (RSK-2 do ESP).
- **Ordem não especificada** no contrato público — consumidor que
  indexasse por posição (não há caso conhecido) precisaria migrar para
  busca por nome. Ganho: nada de promessa não medida.

## Sub-decisões pendentes do dono (registradas, não bloqueantes)

Nenhuma no relatório de investigação. As três correções da volta 3 são
aplicadas neste ADR (D3, D8, D10).
