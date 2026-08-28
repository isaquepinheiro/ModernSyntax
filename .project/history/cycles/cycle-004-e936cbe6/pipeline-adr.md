---
type: adr
kind: artifact
title: "ADR — Design de ModernSyntax.Attributes (Pilar 2 do ModernRTTI)"
description: "Decisões arquiteturais para TModernAttribute, TAttributeRecord, ownership por origem, dedup por classe do lado registrado (regra 2 do ADENDO), guarda de include em .pas e include search path do projeto."
status: draft
cycle: "004"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/e936cbe6a17a8e76ec8ca9a02ec30735
tags: [adr, modernrtti, attributes, fpc, delphi, issue-9]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-08-28T13:30:00Z"
sources:
  - id: prd
    resource: "../strategy/2026-08-27-modernrtti/PRD.md"
    title: "ModernRTTI PRD"
  - id: study
    resource: "../strategy/2026-08-27-modernrtti/STUDY.md"
    title: "ModernRTTI Study"
  - id: adr-callbacks
    resource: "../history/cycles/cycle-003-92fccbce/pipeline-adr.md"
    title: "ADR ciclo #7 — Callbacks (D-A7/D-A8: convenção de teste da família)"
---

# ADR — Design da unit ModernSyntax.Attributes

> Investigation report: **PRESENT** (run `17ad5323`, comentário na issue #9,
> incluindo ADENDO do orquestrador anexado depois da conversa fechar). Este
> ADR **deriva** desse relatório e restaura as decisões nos mesmos termos
> que a discussão fechou, incorporando o ADENDO como parte integral do
> plano. Onde este ADR **estende** o relatório, é para documento formal
> (numeração D-A, cross-links OKF) — sem divergência silenciosa. Onde
> discordar, está dito com todas as letras.

## Contexto

O PRD ([ModernRTTI](../../../strategy/2026-08-27-modernrtti/PRD.md), D1) pede que a biblioteca ofereça
`ModernAttributes.Register` **nos dois compiladores** e `GetAttributes` unificando as duas
origens. O STUDY mediu: `TCustomAttribute` **não existe** no FPC 3.2.2 (0 ocorrências em
`packages/rtl-objpas/src/inc/rtti.pp`) e a sintaxe nativa `[MyAttr]` não compila. A biblioteca
atual **não usa nenhum atributo** (medido: 0 resultados em
`grep -rn 'TCustomAttribute|GetAttribute|Attribute\]' Source/*.pas`), portanto o Pilar 2 é
uma extensão pura, sem regressão possível.

A convenção de teste da família ModernRTTI foi fixada no ciclo #7
([ADR cycle-003, D-A7/D-A8](../cycle-003-92fccbce/pipeline-adr.md)):
diretório por compilador (`Test Shared/`, `Test Delphi/`, `Test FPC/`), FPCUnit no lado FPC,
cenários compartilhados sem framework, cascas finas. Este ADR **herda** aquela decisão sem
reabrir — cita como convenção da família, aplica.

## Decisões

### D-A1 — Unit nova, `uses` mínimo e ramificação por compilador

Cria-se `Source/ModernSyntax.Attributes.pas`. `uses` da `interface`: `SysUtils`,
`Generics.Collections`, `SyncObjs`. `Rtti` entra **apenas no Delphi**, sob `{$IFNDEF FPC}` — o
FPC não lê nada nativo, então não precisa da unit `Rtti` (que é `experimental` no FPC 3.2.2 e
emite warning a cada build, R1 do PRD).

**Motivo.** Zero acoplamento com outras units da biblioteca (evita o custo transitivo do
STUDY §C-4 — importar `Objects.pas` inicializa `Objects.pas` como efeito colateral). `TRttiContext`
é **próprio da unit**, criado na `initialization` e liberado na `finalization`.

**Descartado — reutilizar `TModernObject.Context` (Objects.pas:41,178):** recusado no
relatório (§Descartado) pelo custo transitivo. Um consumidor de `Attributes.pas` que não use
`Objects.pas` inicializaria a segunda como efeito colateral.

### D-A2 — `TModernAttribute` é base **real e obrigatória** para atributo portável

```pascal
type
{$IFDEF FPC}
  TModernAttribute = class(TObject);
{$ELSE}
  TModernAttribute = class(TCustomAttribute);
{$ENDIF}
```

Consumidor escreve `TMyAttr = class(TModernAttribute)` **idêntico nos dois compiladores**. No
Delphi, `[MyAttr]` nativo aceita `TMyAttr` por descendência transitiva de `TCustomAttribute`.

**Motivo (Q3 do relatório, decidido volta 1).** Não é escolha de política; é forçado pela
mecânica da linguagem. Sem base fornecida pela biblioteca, o consumidor cai em três saídas
todas ruins: `class(TCustomAttribute)` não compila no FPC; `class(TObject)` compila mas perde
a sintaxe nativa no Delphi; `{$IFDEF FPC}` na declaração viola CA-5 e D2 do PRD **no código
do consumidor**. D2 autoriza a ramificação dentro da biblioteca — a biblioteca absorve.

**Descartado — `TModernAttribute` como alias/sugestão apenas:** o consumidor que quisesse
`[MyAttr]` no Delphi caía em uma das três saídas ruins acima.

### D-A3 — Estrutura interna da registry: `TDictionary<TClass, TAttributeRecord>`

```pascal
type
  TAttributeRecord = record
    Owned: TArray<TObject>;  // instâncias que a registry possui (vieram por Register)
  end;

// implementation-adjacent, mas TAttributeRecord vive na interface por R-FPC-Generic:
var
  FRegistry: TDictionary<TClass, TAttributeRecord>;
  FLock: TCriticalSection;
{$IFNDEF FPC}
  FContext: TRttiContext;
{$ENDIF}
```

**`TAttributeRecord` vai na `interface`** por R-FPC-Generic (D-A9 abaixo).

**Motivo (Q2 do relatório).** A distinção "atributo dono" (chegou por `Register`) vs "atributo
emprestado" (chegou pela RTTI do Delphi) tem que sobreviver até a `finalization`. Um
`TArray<TObject>` cru apaga essa informação e leva a AV no shutdown (libera instância que
pertence ao `TRttiContext`).

**Descartado — `TArray<TObject>` cru:** perde a origem. Descartado no relatório com o motivo
exato acima.

### D-A4 — Ownership por origem; `GetAttributes` devolve **vista emprestada**

- `Register` **toma posse** de cada instância em `AAttrs` (RN-3 do esp).
- `GetAttributes` retorna um array cujas instâncias são gerenciadas pela registry (para as
  registradas) ou pelo `TRttiContext` interno (para as vindas de `[MyAttr]` nativo). O
  chamador **nunca** libera. Contrato escrito em XMLDoc na assinatura pública.
- `finalization` libera **apenas** `Owned` de cada `TAttributeRecord`; depois `FRegistry.Free`,
  `FLock.Free`, `FContext.Free`. O `FContext.Free` derruba as instâncias vindas da RTTI.

**Motivo (Q2 do relatório).** Sem essa separação, o `finalization` libera referência da RTTI
e o processo cai com AV no shutdown — o pior lugar para depurar.

**Descartado — devolver a instância que o consumidor possa liberar:** o consumidor passa a
disputar posse com a RTTI e com a registry. Segurança de memória vira loteria.

### D-A5 — `Register`: append com dedup por **identidade de referência**

Mesma instância registrada duas vezes conta uma; duas instâncias distintas da mesma classe
contam duas.

**Motivo (Q4 do relatório).** Substituição (replace) tornaria o resultado dependente da ordem
de carga das units — uma unit destruiria em silêncio o registro de outra. É exatamente a
classe de falha que D-A4 existe para impedir.

**Descartado — replace por classe:** motivo acima. **Descartado — dedup por igualdade
estrutural do atributo:** custo alto por benefício zero neste ciclo (atributos são geralmente
sentinelas ou pequenos records; comparar campo a campo em Pascal genérico é caro e frágil).

### D-A6 — `GetAttributes` **no Delphi**: fusão nativo + registrado com **regra 2 do ADENDO**

> Esta é a decisão que o ADENDO do orquestrador adicionou depois da conversa fechar. Sem ela,
> o próprio cenário chamado "prova viva de CA-2" (uma classe com `[MyAttr]` nativo **e**
> `Register(..., [TMyAttr.Create])`) **quebraria** CA-2: dedup por identidade não funde as
> duas instâncias (a criada pelo Delphi e a criada pelo consumidor são objetos diferentes),
> então o Delphi devolveria 2 e o FPC devolveria 1.

Regra:

1. **Dentro de `Owned`** (tudo que veio por `Register`): dedup por **identidade de referência**
   (D-A5, sem mudança).
2. **Ao fundir nativo + `Owned`** (só acontece no Delphi): uma instância vinda da RTTI nativa
   é **descartada** se `Owned` contém qualquer instância cuja `ClassType` seja igual à
   `ClassType` da nativa. **O registrado prevalece por classe.**

Resultado: `[MyAttr]` nativo + `Register(..., [TMyAttr.Create])` devolve **1 entrada nos dois
compiladores** — a registrada. CA-2 vale na letra, sem reescrever o critério.

**Motivo (ADENDO do orquestrador).** O registrado é o **único** que existe nos dois
compiladores. Deixar o nativo vencer faria o resultado do Delphi depender de algo que o FPC
não tem como reproduzir — que é a definição do defeito.

**Descartado — nativo vence:** faz o Delphi observar comportamento que o FPC nunca pode
reproduzir. É o defeito que estamos evitando.

**Descartado — não deduplicar entre nativo e Owned:** o cenário "prova viva de CA-2" quebra
o próprio CA-2 (medido no ADENDO).

**Verificação pendente do lado Delphi (não bloqueante para a fábrica).** Se, na prática, o
Delphi devolvesse a **mesma referência** de instância entre chamadas de `GetAttributes`
(e não instância nova a cada leitura), a dedup por identidade **já bastaria** e a regra 2
seria inofensiva — não quebra nada nesse caso. A regra 2 é **a escolha segura sob as duas
hipóteses**. O autor confirma no PR.

### D-A7 — Convenção de teste herdada da família: cenários em `Test Shared/` + duas cascas

Herda D-A7 e D-A8 do [ADR cycle-003](../cycle-003-92fccbce/pipeline-adr.md):

- `Test Shared/EclbrSystem/UTestMS.Attributes.Scenarios.pas` — unit de cenários **sem
  framework**. Cada cenário é uma `procedure`/`function` que executa e levanta `Exception` na
  falha. Nenhum `if/then` de asserção vaza para a casca.
- `Test Delphi/EclbrSystem/UTestMS.Attributes.pas` — casca fina DUnitX.
- `Test FPC/EclbrSystem/UTestMS.Attributes.pas` — casca fina FPCUnit.

**Descartado — `Test Lazarus/`**: recusado pela convenção da família (diretório por
**compilador**, não por IDE). Já não existe no ciclo #7; não vai passar a existir aqui.

**Descartado — DUnitX no lado FPC**: não vendorizado (medido: `find . -iname "DUnitX*.pas"` → 0).
FPCUnit é nativo (`fpcunit.ppu` medido). Ciclo #7 fechou isto.

### D-A8 — Guarda de include: `.inc` define **um de dois** símbolos; guarda vive na **casca `.pas`**

`Test Shared/EclbrSystem/UTestMS.Attributes.Symbols.inc`, uma linha:

```pascal
{$IFDEF FPC}{$DEFINE NO_NATIVE_ATTRS}{$ELSE}{$DEFINE HAS_NATIVE_ATTRS}{$ENDIF}
```

**Cada casca `.pas`** abre com:

```pascal
{$I UTestMS.Attributes.Symbols.inc}
{$IF NOT DEFINED(HAS_NATIVE_ATTRS) AND NOT DEFINED(NO_NATIVE_ATTRS)}
  {$MESSAGE FATAL 'UTestMS.Attributes.Symbols.inc nao foi incluido'}
{$IFEND}
```

**Motivo (volta 2 da conversa, medido pelo autor no FPC 3.2.2).** `{$DEFINE}` tem escopo de
**unidade de compilação**. Um `.dpr` **não enxerga** símbolo definido dentro de uma casca
`.pas` que ele compila. Portanto:

- Guarda no `.dpr` esperando símbolo vindo da casca **dispararia em toda build**, sempre.
- Guarda no `.dpr` **com `{$I}` também no `.dpr`** vira tautologia: quem esquece o include
  esquece a guarda, é o mesmo gesto.
- Guarda **na casca**, testando que **nenhum de dois símbolos** está definido, funciona:
  ausência do `{$I}` = nenhum dos dois = erro de compilação **no arquivo onde o problema está**.

**Descartado — `{$DEFINE HAS_NATIVE_ATTRS}` dentro de cada `.dpr`:** se o próximo projeto
esquece a linha, o teste some sem sinal. Silêncio.

**Descartado — `{$MESSAGE FATAL}` no `.dpr` com símbolo vindo da casca:** medido, não
funciona (escopo por unidade). Se "consertado" com `{$I}` no `.dpr`, vira tautologia.

**Efeito colateral bom:** some o `{$IFNDEF FPC}` que estaria no `.dpr` e some a "interpretação
de D-5" que a volta 1 marcou como frágil. A única ramificação de compilador do lado de teste
vive dentro do `.inc` compartilhado — infra, um lugar só, o que D2 do PRD autoriza sem
interpretação.

**Registro didático (do relatório):** esta armadilha entra no relatório como "mecanismo de
segurança que não mede o que promete medir" — mesma família dos defeitos dos PRs #11 e #12.
Nomear a família ajuda a próxima issue a reconhecer.

### D-A9 — R-FPC-Generic: tipo instanciado por método público da `interface` **deve** ser declarado na `interface`

Motivo medido: PR #12 do ciclo #7 quebrou com `Global Generic template references static
symtable`. O FPC expande templates no ponto de uso, onde símbolos da `implementation` não são
visíveis.

Aplicação a esta issue: `TAttributeRecord` **é público** na `interface` de
`ModernSyntax.Attributes.pas`, apesar de preferirmos privado. Custo declarado, não escondido.

**Descartado — deixar `TAttributeRecord` na `implementation`:** quebra a compilação no FPC
com o erro acima.

### D-A10 — R-Comment-Nest: header SPDX escrito com `(* ... *)`; sem `{$...}` dentro de `{ }`

Motivo medido: `}` da diretiva fecha o comentário externo (defeito medido no PR #12 do ciclo
#7). Nenhuma diretiva `{$...}` aparece dentro de comentário `{ }` em `ModernSyntax.Attributes.pas`.

### D-A11 — Include path via `{$I}` sem caminho; diretório no search path do projeto

- Casca: `{$I UTestMS.Attributes.Symbols.inc}` — **sem caminho, sem contrabarra**.
- `.lpi`: `-Fi"$(ProjPath)../../Test Shared/EclbrSystem"` em
  `<CompilerOptions><Parsing><IncludeFiles>`.
- `.dproj`: "Search path" apontando para `..\..\Test Shared\EclbrSystem` (equivalente do `-Fi`).
  **Sintaxe exata do `.dproj` é verificação pendente do lado Delphi** — o autor confirma.

**Motivo (volta 2).** Contrabarra não resolve em FPC fora do Windows; caminho relativo longo
quebra na reorganização de diretório que **é** este ciclo (nasce `Test FPC/`). Um lugar para
consertar quando a árvore mudar.

**Descartado — `{$I ..\..\Test Shared\EclbrSystem\UTestMS.Attributes.Symbols.inc}` na casca:**
motivo acima. Descartado no relatório volta 2.

### D-A12 — Zero stub de `ModernSyntax.RTTI.pas` neste ciclo

API pública desta issue é `ModernAttributes.GetAttributes(TFoo)`. CA-2 **na letra**
(`ModernRTTI.GetType(T).GetAttributes`) fica para a issue #8 delegar.

**Motivo (Q1 do relatório).** Duas issues criando o mesmo arquivo colidem no merge. #8 tem
contexto que esta não tem. Ordem de entrega: #9 entrega implementação; #8 entrega fachada.

**Registro no PR:** "não é CA-2 redefinido — é ordem de entrega." Declarado em voz alta para
que a próxima leitura não interprete como CA-2 diluído.

## Consequências

- **CA-2 do PRD** satisfeito **no espírito** por `ModernAttributes.GetAttributes` (mesmo
  resultado observável nos dois compiladores para o conjunto de metadados portável). CA-2 na
  letra fica para a #8, com delegação explícita.
- **Convenção da família ModernRTTI** aplicada sem reabrir: `Test FPC/EclbrSystem/`,
  `Test Shared/EclbrSystem/`, FPCUnit, cascas finas. Este ciclo cria a **segunda** aplicação
  da convenção (a primeira foi a #7); a família passa a ter dois exemplos.
- **`TAttributeRecord` público na interface** por R-FPC-Generic. Não é ideal, é o custo
  medido de contornar o `Global Generic template` do FPC.
- **Divergência silenciosa `[MyAttr]` nativo sem `Register`** entre Delphi (retorna) e FPC
  (retorna vazio) permanece — é comportamento documentado. Mitigada por testes específicos
  de capacidade e por linha de fronteira no PR (CA-8 do esp).
- **Verificações pendentes do lado Delphi** (registradas para o autor):
  (a) `[MyAttr]` aceita descendente transitivo de `TCustomAttribute`;
  (b) sintaxe do `.dproj` para "Search path" de include;
  (c) `TRttiType.GetAttributes` devolve instância nova ou mesma referência entre chamadas
      (afeta se a regra 2 é indispensável ou redundante — segura sob as duas hipóteses).
- **Ordem de inicialização (Q2 do PRD)** declarada: leitura antes do registro devolve vazio,
  não exceção. Comportamento novo que consumidores futuros precisam entender.
- **`DCC.bat` sem `PTestAttributes`**: gap conhecido pós-entrega, não bloqueante.
