---
type: adr
kind: artifact
title: "ADR #53 — Contrato de GetFields no record: tipo + offset cross-compiler, tipo proprio novo"
description: "Decisoes fechadas para o contrato publico de GetFields no TModernRTTIRecordType, derivadas do relatorio de investigacao da issue #53."
cycle: "027"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/2fd5bdc50ab343e460eeca5becd7afbf
generated:
  by: "equipe-feature@node:architect"
  at: "2026-09-03T00:00:00Z"
tags: [adr, rtti, fpc, delphi, record, get-fields, issue-53, cycle-027, d-53-1, d-53-2]
sources:
  - id: investigation-53
    resource: "aefos://run/b3a9b3f28bf31199daa9dc3328d95100"
    title: "Relatorio de investigacao — Issue #53 (run b3a9b3f28bf31199daa9dc3328d95100)"
  - id: adr-45
    resource: "/history/cycles/cycle-018-d9ace4ff/pipeline-adr.md"
    title: "ADR issue #45 — TModernRTTIRecordType (Name + Size)"
---

> **Fonte:** este ADR **deriva** do relatorio de investigacao da issue #53
> (run `b3a9b3f28bf31199daa9dc3328d95100`, status PRESENT). O relatorio
> deixou explicitamente **tres perguntas em aberto** (Q1 = nome do array
> em `TRecordInitData`; Q2 = tipo de retorno; Q3 = contrato a/b/c) e
> pediu que fossem decididas no plano formal. Este ADR **fecha** essas
> tres decisoes, alinhado a recomendacao da propria issue (opcao c) e a
> medicao ali registrada. **Nao ha divergencia** com o relatorio — o que
> o relatorio disse esta reafirmado; o que ele deixou aberto esta agora
> fechado, com o motivo medido.

# ADR #53 — Contrato de `GetFields` no `TModernRTTIRecordType`

## Contexto

O ciclo 018 (issue #45, PR #52, ADR issue #45[^adr-45]) entregou
`TModernRTTIRecordType` **so com `Name` e `Size`**. `GetFields` ficou
cortado por falta de medicao. A #53 fecha essa lacuna.

A medicao no corpo da #53 mostrou:

- `TRecordElement` **nao existe** como API consumivel no FPC 3.2.2
  (`typinfo.pp` nao o expoe; so aparece em `rtl/inc/rttidecl.inc`,
  declaracao interna do compilador).
- `TManagedField` (`typinfo.pp:270-283`) carrega **apenas** `TypeRef` e
  `FldOffset` — nao ha `Name` na estrutura.
- `GetTypeData(P)^.TotalFieldCount` (campo de `TTypeData` direta, **NAO**
  de `RecInitData^`) + caminhada por `PManagedField` enumera **todos** os
  campos (managed + unmanaged) com tipo e offset corretos nos dois bitness
  (medido com `TRecMisto`). `RecInitData^.ManagedFieldCount` entregaria
  apenas 2 de 4 campos — descartaria A e B em silencio (medido em FPC 3.2.2
  i386/x86_64).

A issue elencou tres saidas para o contrato — (a) levantar, (b) devolver
sem `Name`, (c) cortar `Name` cross-compiler — e disse "⚠ A decisao NAO
esta tomada". O relatorio de investigacao registrou tres perguntas em
aberto (Q1, Q2, Q3) e passou o portao vazio. Este ADR as fecha.

---

## D-53.1 — Contrato publico: opcao (c) — tipo + offset cross-compiler, sem `Name`

**Decidido:** `TModernRTTIRecordType.GetFields` devolve
`TArray<TModernRTTIRecordField>` com **tipo e offset apenas**. `Name`
nao e exposto — nem no FPC (onde nao existe) nem no Delphi (onde existe,
mas seria assimetria).

**Motivo (medido, opcoes rejeitadas com motivo):**

- **Opcao (a) — levantar no FPC.** Joga fora dado real: `TotalFieldCount`
  entrega tipo e offset limpos, medidos, corretos nos dois bitness.
  Levantar mata o que existe.
- **Opcao (b) — devolver com `Name = ''` no FPC, `Name` real no Delphi.**
  Cria `TModernRTTIField` que se comporta diferente por compilador. E a
  assimetria exata que este projeto vem eliminando issue apos issue (D-2
  do bundle: paridade de assinatura entre backends). Cliente que apoiasse
  em `Name` funcionaria em um lado e falharia silenciosamente no outro.
- **Opcao (c) — sem `Name`.** Contrato identico nos dois backends. Segue
  o principio ja aplicado em `EnumMinValue`/`EnumMaxValue`: o menor
  denominador cross-compiler e o contrato publico; assimetrias ficam
  fora ate serem removiveis por ambos os lados.

A opcao (c) e a que o relatorio recomendou e a que a medicao autoriza.

**Descartado:** opcoes (a) e (b), com motivo medido acima.

---

## D-53.2 — Tipo de retorno: novo `TModernRTTIRecordField` (nao reusar `TModernRTTIField`)

**Decidido:** criar `TModernRTTIRecordField` **novo**, com **dois** membros
publicos:

```pascal
TModernRTTIRecordField = record
strict private
  FFieldType: PTypeInfo;
  FOffset: Integer;
public
  class function Create(AFieldType: PTypeInfo; AOffset: Integer): TModernRTTIRecordField; static;
  property FieldType: PTypeInfo read FFieldType;
  property Offset: Integer read FOffset;
end;
```

Nao reusar `TModernRTTIField`.

**Motivo (medido em `origin/main @ d566cd1`):** `TModernRTTIField` e
**class-bound por construcao** — a factory `FromToken` exige
`AOwner: TClass` e os metodos `GetValue<T>`/`SetValue<T>` exigem
`AInstance: TObject`. Record nao tem `TClass` (nao existe metaclasse de
record) nem `TObject` (a "instancia" seria `Pointer` para a memoria do
record). Reusar `TModernRTTIField` para records tornaria `GetValue`/
`SetValue` **interface enganosa**: chamar com `AInstance: TObject` sobre
um campo vindo de record e comportamento indefinido.

O novo tipo elimina a ambiguidade por construcao: sem `GetValue`/
`SetValue`, sem `AOwner`, sem `Name`. So o dado que existe cross-compiler
e faz sentido para record: tipo e offset.

**Descartado:**
- Reusar `TModernRTTIField` com `FName = ''` e `FOwner = nil`: contamina
  a semantica de todos os consumidores existentes de `TModernRTTIField`
  com um caso especial silencioso.
- Novo tipo com `GetValue<T>(APointer: Pointer)`: expande escopo. Vira
  issue propria se um consumidor precisar.

---

## D-53.3 — `Name` vira issue-filha condicionada a FPC >= 3.3

**Decidido:** abrir issue-filha desta #53 para expor `Name` nos campos
quando o compilador suportar. Labels: `enhancement` + `blocked`. **NAO**
levar `aefos:queue` — a issue nao entra na fila enquanto nao houver FPC
3.3 disponivel no ambiente.

Corpo da issue-filha carrega:
- A medicao desta #53 (o que o FPC 3.2.2 nao entrega e por que).
- O criterio de desbloqueio: FPC >= 3.3 / trunk expondo `Name` na
  estrutura de campo de record.
- Referencia a esta ADR e ao PR desta #53 como origem.

**Motivo:** ADR nao e varrido pela fila; `gh issue list` e. Sem
`aefos:queue`, a issue nao consome ciclo enquanto nao houver FPC 3.3.
Registra o compromisso sem produzir trabalho premature.

**Descartado:** deixar o `Name` como "TODO no XMLDoc" sem issue formal —
padrao que ja custou a #53 ser aberta com premissa errada no titulo.

---

## D-53.4 — Uma fixture MISTA (nao reusar `TRecordFixture45`/`TRecordFixture45M`)

**Decidido:** nova fixture `TRecordFixture53 = record A: Integer; S: string;
B: Double; T: string; end;` na secao `type` da `interface` de
`UScenarios.RTTI.pas`. Nao reusar as fixtures da #45.

**Motivo:** o modo de falha aqui e OUTRO (ordem/offset/tipo), e so
aparece com tipos MISTURADOS em posicoes que exercitam padding.

- `TRecordFixture45` tem `FieldA, FieldB: Integer` — dois campos do
  mesmo tipo, sem padding relevante. Nao exercita ordem por tipo
  distinto nem padding cross-bitness.
- `TRecordFixture45M` tem `S: string; I: Integer` — dois tipos distintos,
  mas so dois campos: nao exercita ordem no meio do record, e nao expoe
  o padding entre managed e unmanaged em posicoes interiores.
- `TRecordFixture53` (Integer / string / Double / string) foi o proprio
  record da medicao no corpo da issue. Offsets provados:

  ```
  alvo               A    S    B    T
  i386               0    4    8   16
  x86_64             0    8   16   24
  ```

  Quatro campos, tres tipos distintos, offsets divergentes por bitness em
  tres das quatro posicoes. Mata mutacao "backend devolve ordem fixa",
  "backend nao le padding", "backend confunde managed com contagem".

**Nota sobre o motivo do #45 exigir DUAS fixtures:** la o vetor de
falha era "backend constante 8" (unmanaged) — precisava de fixture
managed que divergisse por bitness para nao passar por coincidencia. Aqui
o vetor e outro (ordem/offset/tipo), coberto por UMA fixture mista com
quatro campos. Duas fixtures homogeneas nao acrescentariam matriz — so
peso.

**Descartado:**
- Reusar `TRecordFixture45`/`TRecordFixture45M`: nao exercitam o vetor
  de falha desta issue.
- Duas fixtures novas para "simetria com #45": ceremonia sem exercicio
  novo.

---

## D-53.5 — Assertiva de offset: `NativeInt(@R.<campo>) - NativeInt(@R)`

**Decidido:** o cenario compara `Campo.Offset` contra o offset
**calculado do proprio record em runtime**:

```pascal
var R: TRecordFixture53;
LEspA := NativeInt(@R.A) - NativeInt(@R);
if LFields[0].Offset <> LEspA then Fail(...);
```

Nao usar:
- literal por bitness (`if LFields[1].Offset <> 8 then ...`),
- `{$IFDEF CPU64}` para trocar literais,
- `SizeOf` acumulado.

**Motivo (medido no corpo da issue, matriz 6 alvos):** essa assertiva e
EXATA nos seis alvos, sem diretiva de compilador, e mata mutacao em
constante em qualquer bitness.

- Literal por bitness: exige duas escritas, `{$IFDEF}` e mantem um alvo
  sempre desligado — CA-5 quebra.
- `SizeOf` acumulado: **quebra**. `SizeOf(A) = 4`, mas `S` esta em **8**
  no x86_64 (padding). A tabela medida prova.
- Estritamente crescente (`Offset[i] > Offset[i-1]`): aceita
  `0, 1, 2, 3` — cresce e esta errado.

Comparar contra o que **o proprio compilador em uso** diz sobre o
proprio record e o mesmo principio ja usado para nomes de RTL
(`TModernRTTI.GetType(TypeInfo(Integer)).Name` no cenario 7 — D-57.3).

---

## D-53.6 — Assertiva de tipo: identidade de handle contra `TypeInfo(<tipo>)`

**Decidido:** comparar `Campo.FieldType` por **identidade de ponteiro**
contra `TypeInfo(<tipo>)`. Nao comparar `Name` do `PTypeInfo` (Delphi
diz `Integer`, FPC diz `LongInt` — mesma pegadinha da #57).

```pascal
if LFields[0].FieldType <> TypeInfo(Integer) then Fail(...);
if LFields[1].FieldType <> TypeInfo(string) then Fail(...);
```

**Motivo:** identidade de handle e cross-compiler; nome nao e. Mesmo
principio da D-57.2.

**Pegadinha medida:** `BoolToStr` tem assinatura diferente entre
compiladores (FPC aceita dois textos posicionais; Delphi da `E2010
Incompatible types`). Nas mensagens de erro do cenario, usar
`if ... then ... else` explicito — nao `BoolToStr`.

---

## D-53.7 — Ordem exata dos campos assertada

**Decidido:** o cenario assere ordem **posicional exata**
(`LFields[0]` = A, `LFields[1]` = S, `LFields[2]` = B, `LFields[3]` = T),
nao apenas conjunto. Ordem e propriedade observavel do contrato.

**Motivo:** cliente que iterar `GetFields` espera ordem de declaracao.
Assercao por conjunto (`Contains(...)`) permitiria backend que devolvesse
a ordem invertida, ou reordenasse managed-first, passar verde. Mesma
regra que o D-45 aplicou para `Name`/`Size`: o observavel e o contrato.

---

## D-53.8 — Q1 FECHADA: `TotalFieldCount` vive em `TTypeData`, NAO em `RecInitData^`

**Decidido:** Q1 (antes marcada como "fica com o implementador") esta
**fechada** com medicao verificada em FPC 3.2.2 i386 e x86_64.

`TotalFieldCount` e campo de `TTypeData` direta — **nao** de
`RecInitData^`. `TRecInitData` (`typinfo.pp:433-445`) declara apenas:
`Terminator`, `Size`, `InitOffsetOp`, `ManagementOp`, `ManagedFieldCount`
e o array de campos MANAGED. O campo correto para contar TODOS os campos
e `TTypeData.TotalFieldCount`.

Medicao com `TRecMisto = record A: Integer; S: string; B: Double; T: string; end`:

```
                              i386   x86_64
TypeData.TotalFieldCount        4       4     <- todos os campos
RecInitData^.ManagedFieldCount  2       2     <- so os managed (S e T)
```

O array de `TManagedField` com TODOS os campos (managed e unmanaged) fica
imediatamente apos `TotalFieldCount` na memoria de `TTypeData`. Caminhada
correta:

```pascal
D  := GetTypeData(P);
N  := D^.TotalFieldCount;
MF := PManagedField(PByte(@D^.TotalFieldCount) + SizeOf(Integer));
for I := 0 to N - 1 do begin
  { MF^.TypeRef, MF^.FldOffset }
  Inc(MF);
end;
```

Verificado nos seis alvos. O implementador nao precisa consultar
`typinfo.pp` para esta questao.

**Descartado:** caminho por `RecInitData^.<array>` — entregaria 2 de 4
campos na fixture mista, descartando A e B em silencio. A afirmacao
anterior ("Arquiteto adivinhar o nome") tambem descartada: a medicao
foi realizada e o caminho esta fixado acima.

---

## D-53.9 — XMLDoc de `TModernRTTIRecordType` entra no PR

**Decidido:** reescrever o XMLDoc em `Source/ModernSyntax.RTTI.pas:722-738`.

Remover a frase superada:
> Esta entrega cobre `Name` e `Size` apenas; `GetFields` fica para
> issue propria condicionada a medir `TRecordElement.Name` num FPC
> vivo.

Nova prosa (esboco):
- `TModernRTTIRecordType` cobre `Name`, `Size` e `GetFields`.
- `GetFields` devolve `TArray<TModernRTTIRecordField>` com tipo e offset
  de cada campo. `Name` do campo **nao** e exposto — vive na
  issue-filha #<NN> (criada por este ciclo), condicionada a FPC >= 3.3.
- Contrato cross-compiler: mesmo shape nos dois backends. Segue o
  padrao "menor denominador" ja aplicado em `EnumMinValue`/`EnumMaxValue`.
- `record end` (Size = 0) continua valido.

**Motivo:** mergear com XMLDoc contendo afirmacao superada custou uma
issue inteira em #62. Consertar junto e barato; consertar depois vira
issue.

---

## D-53.10 — Nenhum toque em `UScenarios.RTTI.pas:1241-1242`

**Decidido:** nao editar, nao mover, nao referenciar `:1241-1242`
neste ciclo.

**Motivo:** o item ja foi consumido fora da #53, em commit `e81a5a8`
(issue #57 / ciclo 023). Verificado no proprio corpo da issue e no
relatorio de investigacao. Editar de novo produz mudanca sem causa.

**Nota operacional ao implementador:** o corpo da issue chama atencao
para 4 citacoes de linha ao PROPRIO repo (`:38`, `:39`, `:844`, `:1336`)
como classe da #64. **Nao corrigir agora**; apenas **nao acrescentar
citacao nova ao proprio repo** nas novas linhas escritas por este PR.
Citar simbolo, ou citar RTL externa.

---

## D-53.11 — Contagem de teste FPC sobe 42 → 43; contagem Delphi sobe em 1

**Decidido:** `grep -c "procedure Test" "Test FPC/EclbrSystem/UTestMS.RTTI.pas"`
deve retornar **43** apos o PR. Contagem Delphi correspondente sobe em 1.

**Motivo:** ancoragem por contagem verificavel, na tradicao de D-60.8.

---

## D-53.12 — PR body declara plataforma, sem checklist bloqueante

**Decidido:** PR carrega frase declarativa:
> compilado em FPC 3.2.2 x86_64; **i386 e os 4 alvos Delphi ficam com o
> autor** — verificados antes do merge.

Sem checklist de combinacoes.

**Motivo:** fronteira da fabrica ja registrada em D-60.7 / D-62.4.
Fabrica entrega, autor prova depois. Nao inverter.

---

## Convencoes governantes

| ID | Fonte | O que governa nesta issue |
|----|-------|---------------------------|
| D-1 | `Source/ModernSyntax.RTTI.pas:18-22` | Nenhum `resourcestring` novo na casca publica — se algum motivo aparecer, vai no backend |
| D-2 | `Source/ModernSyntax.RTTI.FPC.pas:14-16`; `Delphi.pas:14-18` | `RecordGetFields(P: PTypeInfo): TArray<TModernRTTIRecordField>` identico nos dois |
| D-4 | `Source/ModernSyntax.RTTI.FPC.pas:634-639` | `RecordGetFields` chama `RecordRaiseWrongKind(P)` como primeira instrucao |
| D-7 | `UScenarios.RTTI.pas` (cenario) + `UTestMS.RTTI.pas` (cascas) | Cenario compartilhado; cascas de uma linha |
| D-45.5 | `RTTI.FPC.pas:640`; `RTTI.Delphi.pas:564` | Helper `RecordRaiseWrongKind` reusado — sem guarda inline nova |
| D-45.7 / D-45.8 | `RTTI.FPC.pas:656-659` | Proibicao de `ManagedFldCount`; `record end` (Size = 0) valido |
| D-57.2 / D-57.3 | `UScenarios.RTTI.pas:1340-1344` | Assertiva por identidade de handle; nome de RTL via `GetType(TypeInfo(...)).Name` |
| CA-5 | `Test FPC/EclbrSystem/UTestMS.RTTI.pas:16-17` | Zero `{$IFDEF FPC}` em `UScenarios.RTTI.pas` |

## Alternativas descartadas

| Alternativa | Por que descartada |
|-------------|--------------------|
| Opcao (a) — `GetFields` levanta no FPC | Joga fora tipo+offset que existem — D-53.1 |
| Opcao (b) — `Name` no Delphi, vazio no FPC | Assimetria cross-compiler; falha silenciosa no cliente — D-53.1 |
| Reusar `TModernRTTIField` | Class-bound; `GetValue<T>(AInstance: TObject)` vira enganoso — D-53.2 |
| Novo tipo com `GetValue<T>(APointer: Pointer)` | Amplia escopo; vira issue propria — D-53.2 |
| Reusar `TRecordFixture45`/`TRecordFixture45M` | Nao exercitam ordem/tipo/padding — D-53.4 |
| Literal por bitness com `{$IFDEF CPU64}` | Quebra CA-5 — D-53.5 |
| `SizeOf` acumulado como esperado do offset | Quebra por padding (medido) — D-53.5 |
| Comparar `Campo.FieldType.Name` contra `'Integer'` | Delphi vs FPC divergem (`Integer` vs `LongInt`) — D-53.6 |
| Assertar apenas conjunto de campos (sem ordem) | Backend que reordenasse passaria verde — D-53.7 |
| Arquiteto adivinhar o nome do array em `TRecordInitData` | Nenhuma fonte no bundle; adivinhar e defeito — D-53.8 |
| Deixar XMLDoc como follow-up | Mergearia afirmacao superada; custaria issue nova (padrao #62) — D-53.9 |
| Reeditar `UScenarios.RTTI.pas:1241-1242` | Ja consumido por #57 / e81a5a8 — D-53.10 |
| Levar `aefos:queue` na issue-filha do `Name` | Consumiria ciclo antes de haver FPC 3.3 — D-53.3 |

## Consequencias

- `TModernRTTIRecordType` passa a expor `GetFields` cross-compiler,
  paridade estrita.
- Novo tipo publico `TModernRTTIRecordField` (dois membros, sem
  `GetValue`/`SetValue`). Amplia a superficie publica em um tipo,
  deliberadamente.
- XMLDoc de `TModernRTTIRecordType` corrigido — a afirmacao superada sai.
- Contagem FPC: 42 → 43.
- `Source/ModernSyntax.RTTI.pas`, `RTTI.FPC.pas`, `RTTI.Delphi.pas`,
  `UScenarios.RTTI.pas`, ambas as cascas de teste editados. Nada mais em
  `Source/*.pas` toca.
- Nenhum cenario existente altera comportamento. `Scenario_RecordType_NameAndSize`
  continua exercitando `Name`/`Size` das fixtures da #45 sem drift.
- Issue-filha do `Name` aberta com labels `enhancement` + `blocked`,
  sem `aefos:queue`.
