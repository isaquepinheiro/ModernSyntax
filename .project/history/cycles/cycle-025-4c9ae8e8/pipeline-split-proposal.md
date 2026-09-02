---
type: split-proposal
kind: artifact
title: "SPLIT — Issue #29 em cinco sub-issues, uma por tipo (Visibility, Enumeration, Pointer, Record, Array+Set)"
description: "Cinco sub-issues derivadas dos cinco slices do plano. Cada uma stand-alone: propria acceptance, propria mutacao obrigatoria onde aplicavel, propria receita SKILL. A ordem sugerida e a mesma da issue original (Visibility primeiro por destravar producao; Array+Set por ultimo por concentrar as armadilhas). Justificativa do split: seis tipos publicos, cinco slices genuinamente independentes; a propria issue #29 sugere '5 ciclos pequenos e provados' preferidos a 'um grande e parcial'. IndexedProperty NAO entra em nenhuma sub-issue — vira issue propria separada com blocked:fpc-3.4."
status: stable
cycle: "014"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/f42b5faad0107a1daea308f52bd50ed4
tags: [modernrtti, split, issue-29, backlog, fpc, delphi]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-09-01T00:00:00Z"
---

# SPLIT — Issue #29 em sub-issues

**Recomendacao:** dividir #29 em cinco sub-issues + uma issue separada
para `TModernRTTIIndexedProperty` (adiada). Motivos, em ordem:

- **SIZE:** seis tipos publicos, catorze funcoes novas por backend
  (mais duas para Visibility), fixtures de teste em quatro categorias
  distintas (enum, pointer, record, array/set) — implementacao unica
  exigiria mais de ~5 slices reviewaveis e provavelmente esgotaria um
  budget de implement.
- **INDEPENDENCE:** cada tipo entrega valor por si. O consumidor pode
  reflect sobre enum sem que array exista; pode reflect sobre pointer
  sem enum; etc. Cada sub-issue tem sua propria acceptance, seu
  proprio conjunto de cenarios, e nao **depende** das outras para
  compilar/passar. Slice 1 (Visibility) e claramente autonoma —
  destrava dois membros ja entregues.
- **A propria issue #29 sugere:** *"Se ficar grande demais para uma
  rodada, quebre em issues proprias por tipo — melhor cinco ciclos
  pequenos e provados que um grande e parcial."*
- **Risco de PR unico:** as armadilhas concentradas no slice 5
  (assimetria estatico/dinamico, mutacao `ElType2`, `TArray<Integer>`
  obrigatorio) podem derrubar todo o PR se algo escapar. Isolar em
  sub-issue permite red-green localizado.

Cada sub-issue abaixo e **mergeable por si** — pode entrar em qualquer
ordem, embora a **ordem sugerida** siga o plano da issue #29 (Visibility
primeiro, Array+Set por ultimo).

---

## Sub-issue 1 — `TModernVisibility`: enum proprio, fix F-1 (Method) + add F-2 (Property)

**Titulo:** `TModernVisibility`: enum proprio, fecha vazamento
`TMemberVisibility` em `Method.Visibility` e adiciona `Property.Visibility`.

**Escopo:**
- Declarar `TModernVisibility = (mvPrivate, mvProtected, mvPublic,
  mvPublished);` em `Source/ModernSyntax.RTTI.pas`, no bloco `type` da
  `interface`, **antes de `TModernRTTIField`**.
- Trocar `TModernRTTIMethod.Visibility` de `TMemberVisibility` (do
  `TypInfo`) para `TModernVisibility`.
- Adicionar `TModernRTTIProperty.Visibility: TModernVisibility` (hoje
  ausente; API-MAP §2 promete e o codigo nao entrega).
- Backend Delphi (`Source/ModernSyntax.RTTI.Delphi.pas`): assinaturas
  de `MethodVisibility` e nova `PropertyVisibility` retornam
  `TModernVisibility`; corpo mapeia 4 cases 1-para-1.
- Backend FPC (`Source/ModernSyntax.RTTI.FPC.pas`): mesmas assinaturas;
  ambos os corpos **levantam** `EModernRTTIError` (D-25.4 preservado).
- Cenarios: dois pares FPC-only/Delphi-only em `UScenarios.RTTI.pas`
  (padrao "dois cenarios distintos" do D-25).

**Acceptance:**
- [ ] Enum publico declarado com quatro constantes na ordem
      `mvPrivate < mvProtected < mvPublic < mvPublished`.
- [ ] `TModernRTTIMethod.Visibility` retorna `TModernVisibility`.
- [ ] `TModernRTTIProperty.Visibility: TModernVisibility` **existe**.
- [ ] Backend FPC levanta em ambos.
- [ ] Backend Delphi devolve o valor correto (cenario Delphi-only afirma
      `mvPublished` para metodo `published`).
- [ ] Cenarios `_FPC_Raises` publicados so na casca FPC; cenarios
      `_Delphi_Returns_*` publicados so na casca Delphi.
- [ ] `grep -rn "TMemberVisibility" Source/ModernSyntax.RTTI.pas`
      retorna zero fora da `uses` da implementation.
- [ ] Compila e passa nos dois bitness FPC; PR declara o que foi compilado.

**Labels sugeridos:** `enhancement`, `rtti`, `fpc`, `delphi`, `pilar-4`,
`api-cleanup`.

**Por que sozinho:** destrava dois membros ja em producao. Nao depende
de nenhum outro tipo desta issue. Sai por si com valor imediato (fecha
drift entre API-MAP §2 e codigo).

---

## Sub-issue 2 — `TModernRTTIEnumerationType`: Name, GetNames, GetName, GetValue, MinValue, MaxValue

**Titulo:** `TModernRTTIEnumerationType`: nome, valores e nomes de
constantes nos dois compiladores.

**Escopo:**
- Declarar `TModernRTTIEnumerationType` em
  `Source/ModernSyntax.RTTI.pas` com `FToken: PTypeInfo`,
  `FromTypeInfo`, e os seis metodos.
- Backend Delphi: delega a `TRttiEnumerationType(Rtti.GetType(P))`.
- Backend FPC: seis funcoes livres com guarda por `Kind = tkEnumeration`;
  `MinValue/MaxValue` de `GetTypeData(P)^`; `GetName/Value` via
  `TypInfo.GetEnumName/Value`; `GetNames` itera de `MinValue` a
  `MaxValue`; `Name` via `string(P^.Name)`.
- Cenarios: dois compartilhados em `UScenarios.RTTI.pas`. Fixture
  `TCor = (cA, cB, cC)`. Afirmacoes por relacao (M-6).

**Acceptance:**
- [ ] Record declarado com `FToken: PTypeInfo` (nao `FType: TRttiType`).
- [ ] `FromTypeInfo(P: PTypeInfo)` publico.
- [ ] Backend FPC comeca cada funcao com guarda por `Kind`.
- [ ] Cenario 3 verde: `GetName(1) = 'cB'`, `GetValue('cC') = 2`,
      `MaxValue - MinValue + 1 = Length(GetNames)`, todos os tres nomes
      presentes no array.
- [ ] Cenario 4 verde: `Name = 'TCor'`.
- [ ] Zero `{$IFDEF}` novo na unit publica.
- [ ] Compila e passa nos dois bitness.

**Labels:** `enhancement`, `rtti`, `fpc`, `delphi`, `pilar-4`.

**Por que sozinho:** enum e o tipo de forma mais usado na pratica.
Nao depende dos outros tipos. Um padrao `FToken: PTypeInfo` +
`FromTypeInfo` fica ancorado em um caso real; as sub-issues seguintes
herdam.

---

## Sub-issue 3 — `TModernRTTIPointerType`: ReferredType

**Titulo:** `TModernRTTIPointerType`: `ReferredType` nos dois
compiladores; mutacao obrigatoria `RefType` → `RefTypeRef`.

**Escopo:**
- Declarar `TModernRTTIPointerType` com `FToken: PTypeInfo` e
  `ReferredType: TModernRTTIType`.
- Backend Delphi: delega a `TRttiPointerType(Rtti.GetType(P)).ReferredType`.
- Backend FPC: `PointerTypeReferredType` com guarda por `Kind = tkPointer`;
  corpo usa `GetTypeData(P)^.RefType^` (**property `RefType`, nunca
  `RefTypeRef`**).
- Um cenario compartilhado (`Scenario_PointerType_ReferredType_Matches`)
  com fixture `type PInteger = ^Integer;` e comentario declarando a
  mutacao obrigatoria.

**Acceptance:**
- [ ] Record declarado com o padrao consagrado (`FToken: PTypeInfo`).
- [ ] Backend FPC usa property `RefType`.
- [ ] Cenario verde nos dois compiladores.
- [ ] **Mutacao verificada** — no PR, comentario/log mostrando que
      trocar `RefType` por `RefTypeRef` no backend FPC deixa o cenario
      vermelho ou AV.
- [ ] Zero `{$IFDEF}` novo na unit publica.

**Labels:** `enhancement`, `rtti`, `fpc`, `delphi`, `pilar-4`.

**Por que sozinho:** o tipo mais simples do lote (um metodo). Nao
depende de nenhum outro. Sai por si com valor (permite reflexao sobre
ponteiros tipados nos dois compiladores).

---

## Sub-issue 4 — `TModernRTTIRecordType`: Name + Size (sem GetFields)

**Titulo:** `TModernRTTIRecordType`: `Name` + `Size` apenas nos dois
compiladores; `GetFields` fica para issue propria.

**Escopo:**
- Declarar `TModernRTTIRecordType` com `FToken: PTypeInfo`,
  `FromTypeInfo`, `Name`, `Size`.
- **Sem `GetFields`** — o Diretor mediu `RecSize` mas nao mediu
  `TRecordElement.Name` no FPC 3.2.2 (F-3 do estudo). Ver a nota final
  desta sub-issue.
- Backend Delphi: delega a `TRttiRecordType(Rtti.GetType(P))` para
  `Name`; usa `TypInfo.GetTypeData(P)^.RecSize` (ou equivalente Delphi)
  para `Size`.
- Backend FPC: `RecordTypeName` retorna `string(P^.Name)`;
  `RecordTypeSize` retorna `GetTypeData(P)^.RecSize`. Guarda por
  `Kind = tkRecord`.
- Um cenario compartilhado com fixture record de >= 2 campos; afirma
  `Size = SizeOf(TFixture)` (relacao — M-6).

**Acceptance:**
- [ ] Record declarado com `FToken: PTypeInfo`, `Name`, `Size` **e
      nada mais**.
- [ ] XMLDoc de `TModernRTTIRecordType` declara: *"esta entrega cobre
      `Name` e `Size` apenas; `GetFields` fica para issue propria
      condicionada a medir `TRecordElement.Name` num FPC vivo"*.
- [ ] Cenario verde nos dois compiladores e bitness (`Size` casa nos
      dois lados como `SizeOf(TFixture)`).
- [ ] Zero `{$IFDEF}` novo na unit publica.

**Nota:** abrir **issue separada** para
`TModernRTTIRecordType.GetFields` com titulo *"`TModernRTTIRecordType.GetFields`:
medir `TRecordElement.Name` no FPC 3.2.2 antes de entregar"* e labels
`enhancement`, `rtti`, `fpc`, `blocked:medicao`.

**Labels:** `enhancement`, `rtti`, `fpc`, `delphi`, `pilar-4`.

**Por que sozinho:** dois metodos apenas; nao depende de nada. Serve
como marco de "o padrao esta consolidado" — se aqui esta certo, as
outras sub-issues confirmam.

---

## Sub-issue 5 — `TModernRTTIArrayType` + `TModernRTTISetType`

**Titulo:** `TModernRTTIArrayType` (`ElementType`, `Size`, `Length`,
`IsDynamic`) + `TModernRTTISetType` (`ElementType`) nos dois
compiladores; duas mutacoes obrigatorias.

**Escopo:**
- Declarar `TModernRTTIArrayType` e `TModernRTTISetType` com padrao
  `FToken: PTypeInfo`.
- **`TModernRTTIArrayType` ramifica na superficie publica** por
  `IsDynamic`. `Length` **levanta** `EModernRTTIError` em dinamico
  **nos dois compiladores** (paridade semantica; capacidade e run-time,
  nao RTTI). `Size` no dinamico retorna `elSize` (tamanho do elemento),
  no estatico retorna `ArrayData.Size`.
- Backend FPC (array):
  - Guarda por `Kind in [tkArray, tkDynArray]`.
  - `ArrayTypeElementType`: **`ElType2^` no dinamico**, `ArrayData.ElType^`
    no estatico (property, **nunca** `elTypeRef`/`elType2Ref` crus).
  - `ArrayTypeLength` no `tkDynArray`: `raise EModernRTTIError.Create(...)`.
- Backend FPC (set): `CompType^` (property, **nunca** `CompTypeRef`);
  guarda por `Kind = tkSet`.
- Backend Delphi: delega a `TRttiArrayType`/`TRttiSetType` nativos;
  `ArrayTypeLength` no dinamico **tambem levanta** (paridade).
- Quatro cenarios compartilhados:
  - Cenario 7: `TStat = array[0..4] of Integer;` — estatico, `Length = 5`.
  - Cenario 8: **`TArray<Integer>`** (nao-managed) — o unico que separa
    `ElType2` (certo) de `ElType` (AV). Afirma `Length` levanta.
    **Mutacao obrigatoria** declarada no comentario (`ElType2 → ElType`).
  - Cenario 9: `TArray<string>` (managed) — outro lado da assimetria.
  - Cenario 10: `set of TCor` — afirma `ElementType.Name = 'TCor'`.
    **Mutacao obrigatoria** (`CompType → CompTypeRef`).

**Acceptance:**
- [ ] Ambos os records declarados com `FToken: PTypeInfo`.
- [ ] `ArrayType.IsDynamic` predicado publico.
- [ ] `ArrayType.Length` no dinamico **levanta** nos dois compiladores.
- [ ] Backend FPC usa properties `ElType2`/`ElType`/`CompType`; **zero
      leitura de `elType2Ref`/`elTypeRef`/`CompTypeRef`** (`grep` na
      unit retorna zero).
- [ ] Cenario 8 verde: `TArray<Integer>` funciona, `Length` levanta.
- [ ] **Mutacao 1 verificada** (cenario 8): trocar `ElType2` por
      `ElType` no backend FPC deixa o cenario vermelho/AV — PR anexa
      log.
- [ ] **Mutacao 2 verificada** (cenario 10): trocar `CompType` por
      `CompTypeRef` no backend FPC deixa o cenario vermelho/AV — PR
      anexa log.
- [ ] Zero `{$IFDEF}` novo na unit publica.

**Labels:** `enhancement`, `rtti`, `fpc`, `delphi`, `pilar-4`,
`test:mutacao-obrigatoria`.

**Por que sozinho:** e a sub-issue mais delicada (armadilhas
concentradas). Isolada, permite red-green localizado — se algo escapar,
so este PR e afetado. Set entra junto porque compartilha a familia
`GetTypeData^.<property>^` e o padrao de mutacao (`property` vs
`campo cru`); dividir mais so aumentaria overhead sem ganho.

---

## Issue separada (fora do split): `TModernRTTIIndexedProperty` — adiada

**Titulo:** `TModernRTTIIndexedProperty`: aguardar FPC 3.4 ou decidir
so-Delphi (M-7 do ciclo 014).

**Escopo:** nao entra em nenhuma das cinco sub-issues acima.
`IndexedProperty` **nao aparece uma vez** em `rtti.pp` do FPC 3.2.2
(medido em M-1/M-7). 100% da superficie publica seria D-25.4 no FPC —
qualitativamente diferente dos outros seis tipos.

**Labels:** `enhancement`, `rtti`, `blocked:fpc-3.4`, `pilar-4`.

**Acao imediata:** ao fechar as cinco sub-issues acima, editar a
API-MAP §1 marcando `TRttiIndexedProperty` como "adiada" (redacao no
[adr](pipeline-adr.md) D-29.10).

---

## Nota do arquiteto

O `split` aqui **e** o formato certo desta issue — nao e ceremonia. A
propria discussao ja sugere ("melhor cinco ciclos pequenos e provados
que um grande e parcial"). A cada sub-issue fechada, um valor concreto
entrega, e um padrao arquitetural (D-29.2 `FToken: PTypeInfo`, D-29.5
guarda por `Kind`, D-29.4 properties nunca `*Ref`) fica exercitado
por mais um caso. O risco distribui — nao concentra em um PR unico
que passa ou falha inteiro.
