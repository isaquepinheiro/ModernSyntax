---
type: adr
kind: artifact
title: "ADR — Design da unit ModernSyntax.RTTI (Pilar 1)"
description: "Decisoes de arquitetura para a leitura de RTTI: superficie fechada, ramificacao contida, TRttiContext compartilhado, deteccao de {$M+} no FPC."
status: draft
cycle: "002"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/fa369bfebcbab23d74f445cede226eb0
tags: [adr, modernrtti, rtti, fpc, delphi, pilar-1, issue-8]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-08-28T00:50:00Z"
sources:
  - id: prd
    resource: "../strategy/2026-08-27-modernrtti/PRD.md"
    title: "ModernRTTI PRD"
  - id: study
    resource: "../strategy/2026-08-27-modernrtti/STUDY.md"
    title: "ModernRTTI Study"
  - id: arch
    resource: "../analysis/03-architecture.md"
    title: "03 Architecture — ModernSyntax"
---

# ADR — Design do Pilar 1 da ModernRTTI

> Investigation report: **NONE** (o issue #8 nao passou por investigacao
> humana). Este ADR e decidido aqui, dentro do quadro ja fixado pelo
> [PRD](../../../strategy/2026-08-27-modernrtti/PRD.md) e pelas medicoes do
> [Study](../../../strategy/2026-08-27-modernrtti/STUDY.md).

## Contexto

O codigo atual tem **zero** `GetProperties`/`GetFields`/`TRttiProperty`
(medido: STUDY.md). O unico uso vivo de RTTI e o construtor generico
em `TModernObject.Factory` ([Objects.pas:208-241](../../../analysis/03-architecture.md)).
O PRD (Pilar 1) pede tres tipos novos com API identica nos dois
compiladores, adaptando `{$M+}`/`published` no FPC.

## Decisoes

### D-A1 — Unit nova, superficie fechada

Cria-se `Source/ModernSyntax.RTTI.pas`. Nao se estende
`ModernSyntax.Objects.pas` (D5 do PRD). A unit expoe APENAS
`ModernRTTI`, `TModernRTTIType`, `TModernRTTIProperty`,
`TModernRTTIField` e `EModernRTTIError`. Tipos de `System.Rtti`
ficam contidos na implementacao.

**Descartado — reexportar `TRttiType`/`TRttiProperty` diretamente:**
economiza codigo mas rompe D2 do PRD — qualquer divergencia futura
entre Delphi e FPC vaza para o consumidor.

**Descartado — colocar dentro de `ModernSyntax.Objects.pas`:**
mistura RAII/factory com leitura de RTTI. D5 do PRD veta.

### D-A2 — Ramificacao com `{$IFDEF FPC}` direto, sem `.inc`

A unit **nao inclui** `ModernSyntax.inc` e **nao usa** simbolos
derivados (`DELPHI14_UP` etc). Todo condicional e escrito como
`{$IFDEF FPC} ... {$ELSE} ... {$ENDIF}`.

**Motivo:** [ModernSyntax.inc:256](../../../analysis/03-architecture.md)
escreve `{$IFDEF FCP}` — bug documentado no PRD (R3) e no STUDY.
Enquanto o bug nao for corrigido (fora do escopo deste pilar), qualquer
unit que inclua o `.inc` herda um ramo Lazarus **morto**. Escrever
`{$IFDEF FPC}` direto e imune ao bug.

**Descartado — corrigir o `.inc` no mesmo ciclo:** o PRD exclui
essa correcao do escopo desta linha de trabalho. Fazer aqui expande
a mudanca sem necessidade.

### D-A3 — `TRttiContext` compartilhado por unit

A unit mantem um `TRttiContext` privado (`class var` em uma classe
estatica ou variavel de implementacao), inicializado em
`initialization` e liberado em `finalization`. E o padrao ja usado
em [ModernSyntax.Objects.pas:191-201](../../../analysis/03-architecture.md);
manter o mesmo padrao facilita revisao.

**Descartado — instanciar `TRttiContext` a cada `GetType`:**
funciona, mas invalida caches internos do Delphi entre chamadas.
O padrao existente na propria biblioteca ja escolheu compartilhar.

**Descartado — reusar `TModernObject.Context` (`Objects.pas:41`):**
cria acoplamento entre uma unit de RTTI e uma unit de factory/RAII.
Cada uma tem seu ciclo de vida.

### D-A4 — `TModernRTTIType` como wrapper, nao heranca

`TModernRTTIType` **e um record** carregando um `TRttiType` interno
(nao publicado). Seus metodos delegam para o `TRttiType`. Mesma
escolha para property/field.

**Motivo:** manter valor-tipo (o resto da biblioteca e todo baseado
em `record`, ver secao 5.5 de [03-architecture.md](../../../analysis/03-architecture.md)),
sem lifecycle proprio (a memoria e do `TRttiContext`).

**Descartado — classe:** exigiria gerenciamento de lifetime; nao ha
o que possuir alem do ponteiro.

**Descartado — interface:** poderia dar ARC, mas adiciona overhead
sem beneficio.

### D-A5 — Deteccao de `{$M+}` no FPC via `TypInfo`

No FPC, quando o tipo passado a `GetType` e classe (`tkClass`) e:
- o `PTypeInfo` retornado por `TypInfo.PTypeInfo(TypeInfo(T))` nao
  tem `PropCount > 0` **em nenhum ancestral** ate `TObject`, **e**
- o `TRttiContext.GetType` devolve zero propriedades para o tipo,

entao a classe muito provavelmente esta **sem `{$M+}`**. Nesse caso
`GetProperties` levanta `EModernRTTIError` com a mensagem:

  `Class <Name> has no published RTTI. On FPC, mark it with {$M+} `
  `and declare properties as 'published' (see ModernRTTI docs).`

**Ha ambiguidade:** uma classe com `{$M+}` mas realmente sem
`published` tambem devolve zero. A deteccao trata os dois casos como
"nao existe metadata legivel"; a mensagem sugere ambas as causas. O
requisito do PRD (R4) e nao devolver **lista vazia silenciosa**, e
essa exigencia e atendida.

**Descartado — sempre devolver `TArray<TModernRTTIProperty>` vazio:**
viola R4 explicitamente.

**Descartado — heuristica por bit `tkClass` sem checar type info:**
falsos positivos para classes de fato sem propriedades.

### D-A6 — Comportamento no Delphi para GetProperties vazio

No Delphi, `GetProperties` pode retornar `nil` legitimamente para
classes sem propriedades. **Nao levantamos excecao** nesse caso: o
suporte a atributos e publicacao no Delphi nao precisa de `{$M+}`.
Devolvemos array vazio.

Isto e assimetrico com o FPC por **decisao**: a assimetria vem do
FPC exigir marcador; o consumidor que quer o mesmo comportamento
usa a mesma marcacao (ver `TObject` vs `TPersistent`), e a
mensagem no FPC ensina isso.

### D-A7 — API do consumidor

```pascal
type
  ModernRTTI = record
  public
    class function GetType<T>: TModernRTTIType; overload; static;
    class function GetType(const AClass: TClass): TModernRTTIType; overload; static;
    class function GetType(const ATypeInfo: PTypeInfo): TModernRTTIType; overload; static;
  end;
```

Tres overloads para cobrir os tres modos de acesso ja usados na
biblioteca (ver STUDY.md, tabela de sites RTTI). No FPC os tres
funcionam identicos porque `TRttiContext.GetType` tambem os aceita.

### D-A8 — Namespace e nome da unit

Nome: `ModernSyntax.RTTI` (arquivo `Source/ModernSyntax.RTTI.pas`).
Segue a convencao das outras units (`ModernSyntax.<area>.pas`).

O tipo publico chama-se `ModernRTTI` (sem prefixo `T` — e um
"static class"/record de metodos de classe, do mesmo estilo que
`TCurrying` ou `TArrow`, mas neste caso o nome sem `T` foi escolhido
pelo PRD e pelo texto do issue: `ModernRTTI.GetType(T)`).

### D-A9 — Nao ha ADR sobre configuracao de teste

O `.lpi` dos testes e artefato de infraestrutura (plan.md, fatia 3),
nao decisao arquitetural. Fica no plan.

## Consequencias

- Consumidor escreve `ModernRTTI.GetType(TFoo).GetProperties` e nao
  se importa com o compilador (cumpre CA-1/CA-5 do PRD).
- Divergencias futuras (ex: se o FPC 3.4 mudar a API do `Rtti`) sao
  absorvidas dentro da unit; o consumidor nao muda (RSK-1 do ESP).
- Pilares 2 (atributos) e 3 (invocacao) reusam a mesma `TRttiContext`
  privada ou criam a propria; nao ha acoplamento decidido aqui.
