---
type: prd
kind: artifact
title: "ModernRTTI — RTTI, Invoker e callbacks com a mesma API no Delphi e no Lazarus/FPC"
description: "Uma camada que da a MESMA API de leitura de RTTI, invocacao de metodo e callbacks nos dois compiladores, para viabilizar o porte dos frameworks Delphi do autor para o Lazarus. Atributos entram com declaracao assimetrica e leitura identica."
status: stable
tags: [modernrtti, fpc, lazarus, rtti, invoker, callbacks, prd]
generated:
  by: "orquestrador (o product-strategist falhou no round 3 por queda de stream do provedor; o desenho foi fechado na conversa e escrito a mao)"
  at: "2026-08-27"
sources:
  - id: study
    resource: "./STUDY.md"
    title: "Study — medicao de dia zero do ModernSyntax"
  - id: conversa
    title: "Conversa de desenho, 3 voltas (as duas primeiras registradas; a terceira perdida na falha)"
---

# ModernRTTI

## Problema

O autor mantem frameworks em Delphi que dependem de RTTI e de metodos anonimos, e quer **leva-los para o Lazarus/FPC sem reescrever o codigo de chamada**. Hoje isso nao e possivel: os dois compiladores expoem RTTI de formas diferentes, e o FPC 3.2.2 **nao tem metodos anonimos nem atributos**.

O objetivo nao e "suportar Lazarus" no abstrato — e **ter uma unica forma de escrever** codigo que use RTTI, invocacao e callbacks, e que compile nos dois.

## O que ficou decidido na conversa

Estas decisoes foram acordadas com o autor e sao o contrato deste PRD.

### D1 — Atributos: declaracao assimetrica, leitura identica

`[MyAttr]` **nao compila no FPC 3.2.2** (medido: `Fatal: Syntax error, "BEGIN" expected but "[" found`), e `TCustomAttribute` **nao existe na RTL** (medido: 0 ocorrencias em `packages/rtl-objpas/src/inc/rtti.pp` e em toda a RTL). Nao ha o que abstrair.

**Decisao:** a biblioteca oferece `ModernAttributes.Register(TFoo, [MyAttr.Create])` **nos dois compiladores**. No Delphi e **opcional** — quem quiser continua usando `[MyAttr]` nativo. No FPC e o unico caminho.

**Alternativas recusadas, com o motivo:**
- **Obrigar `Register` nos dois** foi recusada porque faz o programador Delphi pagar por uma limitacao do FPC. O Delphi e a plataforma principal desta biblioteca; degradar o lado bom para igualar o lado ruim e o pior negocio disponivel.
- **Tirar atributos do escopo** foi recusada porque nao adia custo: o pilar de RTTI **precisa saber como os atributos chegam** para desenhar `GetAttributes`. Empurrar para outro PRD deixa um buraco no meio deste.

### D2 — Zero ramificacao obrigatoria no consumidor

A assimetria e permitida **na declaracao** e proibida em todo o resto. **O consumidor nunca escreve `{$IFDEF}` por causa desta biblioteca.** Quem quiser um codigo unico usa `Register` nos dois lados e nao ramifica nada.

### D3 — Callbacks: interface + objeto de captura como fundacao

FPC 3.2.2 **nao tem `reference to`** nem os modeswitches `functionreferences`/`anonymousfunctions` (medido: *"Illegal compiler switch"*). O alvo e o **3.2.2 estavel**, nao o trunk — o autor nao vai exigir compilador de desenvolvimento dos usuarios dele.

**Decisao:** `IMSFunc<T,R>`, `IMSProc<T>` e `IMSPredicate<T>` como contrato, com `Callback.Of(Self.MinhaProc)` como atalho para o caso simples.

**Por que a interface e a fundacao e nao o atalho:** so ela da **captura de variavel**, e captura e metade do valor de um metodo anonimo. Metodo de objeto carrega apenas o `Self`.

**Recusado explicitamente:** macro, expressao como string, ou qualquer passo de pre-processamento. Se a solucao exigir uma etapa antes do compile, deixa de ser biblioteca e vira ferramenta de build — e ai nao cabe neste repositorio.

### D4 — Escopo dos callbacks e a nova API, nao a biblioteca inteira

Os 451 usos de `TProc`/`TFunc`/`TPredicate` em 10 units **nao entram**. A DSL cobre apenas o que a **nova API** expoe e recebe — algo entre 10 e 15 assinaturas.

Isto rebaixa o pilar de "reescrever a biblioteca" para "desenhar uma duzia de tipos de callback", e e a diferenca entre um projeto de meses e um de semanas.

### D5 — O Invoker e unit nova, nao extensao do que existe

`TModernObject.Factory` (`Objects.pas:208-241`) ja faz `GetType -> GetMethod -> Invoke`, mas mora numa unit 100% Delphi. **O Invoker nasce em unit propria**, sobre `TRttiContext.GetType(...).GetMethod(...).Invoke`, com `{$IFDEF}` apenas se for medida divergencia de assinatura no FPC.

## O que vamos construir

**A `System.Rtti` do Delphi INTEIRA, espelhada com o prefixo `Modern`, disponivel igual nos dois compiladores.**

Decisao do dono em 28/08: *"A camada e a System.Rtti inteira com Modern. ISSO"*. Cada tipo e implementado **com o recurso que cada linguagem oferece** — o Delphi usa a `System.Rtti` direto; o Lazarus tem quase tudo, so de forma mais verbosa, e **e essa verbosidade que a camada existe para absorver**. Enumerators incluidos, que o Delphi nem oferece.

A superficie completa, tipo a tipo e membro a membro, com o caminho de implementacao **medido** no FPC 3.2.2, esta em **`API-MAP.md`**, ao lado deste documento. **13 dos 20 tipos existem no FPC; os 7 ausentes tem caminho, e nenhum e impossivel.**

Os quatro primeiros blocos, ja entregues e no `main`, foram:

**Pilar 1 — Leitura de RTTI.** `TModernRTTIType`, `TModernRTTIProperty`, `TModernRTTIField`, sobre `TRttiContext`. No Delphi e reexportacao quase 1:1; no FPC adapta `{$M+}` e `published`.

**Pilar 2 — Atributos.** `ModernAttributes.Register` nos dois compiladores, e `GetAttributes` unificando as duas origens.

**Pilar 3 — Invocacao.** `TModernInvoker`, unit nova.

**Transversal — Callbacks.** `IModernFunc`/`IModernProc`/`IModernPredicate` e `Callback.Of`, usados pelos tres pilares.

**O resto da superficie esta aberto em issues** — ver o EPIC **#32**, que carrega o objetivo e lista as filhas. Daqui em diante o trabalho e conduzido **pelas issues**, nao por este documento: o PRD e o retrato da conversa que originou as issues, e nao deve ser a fonte operacional depois disso.

## Fora de escopo

- **Consertar `Windows` na secao interface** de `Std.pas:21` e `DotEnv.pas:22`, que hoje derruba 6 de 16 units no FPC. **Nao bloqueia**: a `ModernRTTI` usa apenas `System.Rtti`/`TypInfo`/`SysUtils` e nao toca nenhuma unit contaminada. Vira pre-requisito **so** quando alguem quiser portar as units afetadas.
- **Converter os 451 `TProc`/`TFunc` existentes** (D4).
- **Estender `TModernObject.Factory`** (D5).
- **Portar `Async`, `Coroutine` e `Stream`**, que dependem de `System.Threading` (`ITask`/`TTask`), sem equivalente no FPC.
- **Consertar o `{$IFDEF FCP}`** de `ModernSyntax.inc:256`. Ver R3.

## Criterios de aceite

**CA-1.** `ModernRTTI.GetType(T).GetProperties` devolve as propriedades de `T` no Delphi e no FPC, com a mesma chamada no codigo do consumidor.

**CA-2 — o criterio que define o pilar de atributos.** `ModernRTTI.GetType(T).GetAttributes` devolve **o mesmo resultado nos dois compiladores** para o mesmo conjunto de metadados, independente de terem chegado por `[MyAttr]` nativo ou por `Register`. **Se isto nao for verdade, o pilar falhou**, por mais coerente que a API pareca.

**CA-3.** `TModernInvoker` invoca um metodo por nome nos dois compiladores, com a mesma chamada.

**CA-4.** Um callback com **captura de variavel** funciona nos dois via `IMSFunc<T,R>`.

**CA-5.** Nenhum arquivo de exemplo ou de teste desta entrega contem `{$IFDEF FPC}` **no codigo do consumidor**. Ramificacao dentro da biblioteca e permitida; no consumidor, nao (D2).

**CA-6 — sem isto nada pode ser verificado.** A entrega inclui **projeto que o FPC constroi** (`.lpi` ou `.lpr`) para os testes novos. Hoje o repositorio tem **14 `.dproj` e zero `.lpi`/`.lpr`**, e o `lazbuild` nao le `.dproj`.

**CA-7.** Os testes novos compilam e passam **nos dois compiladores**: Delphi (pelo autor) e FPC 3.2.2 32 e 64 bits (pelo orquestrador, na maquina do autor).

## Riscos, e o que eles quebram

**R1 — A unit `Rtti` do FPC e marcada `experimental`.** O compilador emite `Warning: Unit "Rtti" is experimental` a cada build. Risco assumido: se o FPC 3.4 mexer na API, a camada absorve o choque. **Este e um argumento a favor da camada existir**, nao contra.

**R2 — ~~A fabrica nao compila Pascal~~ — SUPERADO EM 28/08.** ⚠️ **A fabrica COMPILA.** O FPC **3.2.2** foi declarado no `Dockerfile` da imagem (aefos-studio#358, mergeado) e esta provado no runtime: compila, roda FPCUnit e **reprova quando o teste e mutado**, tudo como `appuser` dentro do container. A receita executavel esta em **`.project/SKILL.md`**.

**Por que esta linha ficou aqui em vez de ser apagada:** a redacao anterior dizia que *"as lentes de qualidade julgam por leitura"*, e uma lente **citou este R2** para aprovar o PR #11 sem construir — *"Analise estatica (leitura; sem compilador na fabrica — R2 do PRD)"*. Aquele PR nao compilava e foi fechado sem merge. **Uma linha de risco virou licenca escrita para nao compilar**, e o registro disso vale mais que a linha limpa.

**O que continua valendo:** o **Delphi** permanece com o autor — nem a fabrica nem o orquestrador tem `dcc32`. Todo PR desta linha declara o que foi e o que nao foi compilado; **silencio nao e afirmacao de sucesso**.

⚠️ **Nao ha cross-compiler i386 no container** (`ppc386` retorna 127) nem `lazbuild` — medido pela propria fabrica. A validacao i386 e a de `.lpi` ficam com o orquestrador.

**R3 — O ramo Lazarus do `.inc` esta morto.** `ModernSyntax.inc:256` escreve `{$IFDEF FCP}`; o simbolo do FPC e `FPC`. O bloco **nunca disparou**, e o comentario que documenta isso existe **apenas na branch `main`** — na `develop`, que e a base de trabalho, ele nao esta. **Se a nova unit usar `{$IFDEF FPC}` direto, contorna. Se fizer `{$I ModernSyntax.inc}` e depender do simbolo, herda o bug.**

⚠️ **ATUALIZADO EM 28/08:** a base de trabalho **deixou de ser a `develop`**. Medido: ela esta **22.855 linhas atras** do `main` (584 so em `Source/`, 1.910 em `Test Delphi/`), e no repositorio original o `develop` esta 26 commits atras — os 8 PRs mergeados la foram todos para `main`. **O tronco e o `main`**, e e nele que o comentario do autor sobre o `FCP` existe, terminando com *"Fix it together with a real FPC target and a build that proves it"*.

**R4 — `GetProperties` no FPC exige `{$M+}` e `published`.** Uma classe de consumidor sem isso devolve lista vazia **sem erro**. A camada precisa **detectar e reportar**, nunca devolver vazio silencioso.

## Perguntas em aberto

**Q1 — A assinatura de `TRttiMethod.Invoke` do FPC e igual a do Delphi?** Nao medido. Decide se o pilar 3 leva `{$IFDEF}` ou nao.

**Q2 — Como o `Register` sobrevive a ordem de inicializacao das units?** Se um consumidor le atributos no `initialization` de uma unit que carrega antes da que registrou, ve lista vazia. Precisa de politica declarada.

**Q3 — A DSL de callbacks tera geracao de codigo auxiliar?** O autor recusou pre-processamento; falta decidir se havera algum helper de declaracao ou se o consumidor escreve a classe de captura a mao.

## Nota sobre a origem deste documento

Este PRD **nao** foi escrito pelo no `prd` do `/product-strategist`. A run `23b95baf` falhou na volta 3 com `Node 'converse:round-3' produced no assistant output — the provider stream closed without yielding content`, e o `commit-proof` detectou que o `committer` **reportou sucesso sem ter commitado**.

O `STUDY.md` ao lado **e o original produzido pela run**, integro. As decisoes D1 a D5 vieram das tres voltas da conversa; as medicoes de FPC foram feitas pelo orquestrador no compilador do autor. As duas primeiras voltas estao registradas no banco; **a terceira se perdeu na falha** e foi reconstituida a partir da resposta enviada.
