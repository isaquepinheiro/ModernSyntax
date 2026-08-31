---
type: adr
kind: decision
title: "ADR — TModernValue.AsType<T>: paridade de assinatura e caso exato, alargamento como issue própria (issue #26)"
description: "Restatement da decisão que fechou a discussão da issue #26: superfície mínima; TValueOps record em cada backend com class function ... static genérico; delegação pura no Delphi; IsType(TypeInfo(T))+ExtractRawData no FPC; uma resourcestring nomeando origem/destino; alargamento fora de escopo com XMLDoc declarando em voz alta; CA-5 preservado com cenário de exceção local ao FPC."
status: stable
cycle: "011"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/38e3bcee8cdc184a2977006358812748
tags: [modernrtti, adr, issue-26, fpc, delphi, tvalue, astype]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-08-31T00:00:00Z"
sources:
  - id: issue-26-report
    title: "REPORT — Issue #26 (run e34527b70259d01ff46bef0971b2d033)"
  - id: api-map
    resource: "/strategy/2026-08-27-modernrtti/API-MAP.md"
    title: "ModernRTTI API-MAP (§2, §7)"
  - id: adr-021
    resource: "/history/decisions/"
    title: "ADR #21 — não se promete paridade que não foi medida"
  - id: skill
    resource: "/SKILL.md"
    title: "SKILL — toolchain e traps"
---

# ADR — issue #26

Este documento **deriva do relatório de investigação** que fechou a
discussão da issue #26 (quatro voltas, humano + agente, run
`e34527b70259d01ff46bef0971b2d033`). Ele registra a decisão em vigor,
nos termos que a conversa acertou. Não reabre nada — o próximo portão é
escrever código.

Onde eu (arquiteto) diverjo do relatório, digo explicitamente. **Não há
divergência de mérito**; apenas dois ajustes editoriais:

1. O relatório referencia `UScenarios.RTTI.pas:168` como sede do padrão
   `Fail(...)` → `ETestScenarioFailed`. Registrei o mesmo no ESP com a
   nota "verificar no primeiro edit se o número da linha bateu" — o
   padrão é o mesmo mesmo se o número tiver drift. Não é divergência,
   é robustez do handoff.
2. O programa de medição para a issue de alargamento (o `.dpr` com
   `TMeasure` record) NÃO é entregue nesta issue. A conversa (volta 3
   e rodapé) deixou o fonte pronto no relatório e delegou "onde ele
   mora" ao plano formal de implementação. Registro aqui a resposta:
   fica com a **issue de alargamento** quando ela abrir, não com esta.
   Motivo: nasce lá com a matriz medida como pré-requisito, no lugar
   onde o dado importa; carregá-lo aqui aumenta a superfície da #26
   sem retorno.

Tudo o mais é restatement da decisão acordada.

## Contexto medido

- `TValue.AsType<T>` é o membro mais usado da RTTI do Delphi e o
  **único** medido AUSENTE no FPC 3.2.2 (`API-MAP.md:96`; corpo da
  issue confirma "9 de 10").
- Os outros 9 membros do `TValue` (`From<T>`, `IsEmpty`, `TypeInfo`,
  `Kind`, `ToString`, `AsObject`, `AsString`, `AsInteger`, `IsObject`)
  estão OK no FPC — não passam por esta camada.
- Único `{$IFDEF FPC}` que ainda vive fora da `uses` na unit pública é
  o bloco 385–397 de `TModernRTTIProperty.GetValue<T>` — drift da §7
  do API-MAP. Fecha nesta issue.
- Analista compilou e executou a cadeia inteira do desenho
  (`TValueOps` record + `TModernValue` record + delegação
  atravessando as duas camadas) no FPC 3.2.2 nos dois bitness
  (x86_64 e i386). Provado: a forma compila e roda; record e enum
  passam por `IsType(TypeInfo(T)) + ExtractRawData` sem código extra;
  a mensagem CA-2 sai com origem e destino reais.
- **NÃO medido:** se `TValueOps` como record com
  `class function ... static` genérico compila no Delphi 12. Assumido
  pelo padrão do repo (6 casos análogos em `Source/`); **primeira coisa
  a confirmar no build Delphi do ciclo de implementação**. Registrar
  literal no PR, sem suavizar.

## Decisão

### D-1. Superfície pública mínima

`TModernValue` expõe **exatamente** três membros:

```pascal
class function From<T>(const AValue: T): TModernValue; static;
class function FromValue(const AValue: TValue): TModernValue; static;
function AsType<T>: T;
```

Estado privado neutro: `FValue: TValue` (`TValue` existe nos dois
compiladores, `API-MAP.md:94`). Os outros 9 membros do `TValue` não são
wrapados — o consumidor os usa direto no `TValue` nativo, onde estão OK
no FPC.

### D-2. Arquitetura: `TValueOps` record em cada backend

O genérico vive em **dois pontos**, ambos "método de tipo":

- `TValueOps.AsType<T>` — record com `class function AsType<T>(const AValue: TValue): T; static`,
  um em `ModernSyntax.RTTI.Delphi.pas`, um em `ModernSyntax.RTTI.FPC.pas`
  (backends split por `{$IFDEF}` na `uses`).
- `TModernValue.AsType<T>` — método do record público. Corpo é
  **uma linha**: `Result := TValueOps.AsType<T>(FValue);`. Zero
  `{$IFDEF}` no corpo.

**Por que `TValueOps` em vez de mover a lógica para
`TModernValue.AsType<T>` com dispatch `{$IFDEF}`:** o §7 do API-MAP
permite `{$IFDEF}` apenas na cláusula `uses`. A backend split faz o
trabalho — a unit pública chama `TValueOps.AsType<T>` sem saber qual
backend está em cena.

**Por que record com `class function ... static` genérico em vez de
função livre genérica:** o Delphi **não suporta rotina livre genérica**
— generics no Delphi vivem em tipos e em métodos de tipos. `Source/`
inteiro tem zero rotinas livres genéricas (medido); é o padrão que a
linguagem mais restritiva impõe. Foi a lição da volta 3 da discussão.

### D-3. Backend Delphi — delegação pura ao nativo

```pascal
class function TValueOps.AsType<T>(const AValue: TValue): T;
begin
  Result := AValue.AsType<T>;
end;
```

Alargamento herdado do `TValue` nativo do Delphi. Nenhuma tabela,
nenhuma validação prévia. Consumidor Delphi de `LProp.GetValue<Int64>`
sobre propriedade `Integer` continua funcionando como sempre — sem
regressão possível.

### D-4. Backend FPC — tipo exato, mensagem nomeando origem e destino

```pascal
class function TValueOps.AsType<T>(const AValue: TValue): T;
begin
  if not AValue.IsType(TypeInfo(T)) then
    raise EModernRTTIError.CreateFmt(SModernValueIncompatibleType,
      [string(AValue.TypeInfo^.Name),
       string(PTypeInfo(TypeInfo(T))^.Name)]);
  AValue.ExtractRawData(@Result);
end;
```

Uma nova `resourcestring`:
`SModernValueIncompatibleType = 'incompativel: origem=%s destino=%s'`.
Junta-se às 8 já existentes no backend FPC. `V.TypeInfo^.Name` dá a
origem; `PTypeInfo(TypeInfo(T))^.Name` dá o destino. CA-2 sai dessa
única string.

**`V.IsType(TypeInfo(T))`, não `V.IsType<T>`.** A forma genérica não
compila dentro de função genérica no FPC 3.2.2 (medido:
`astype2.lpr(8,22) Error: Illegal expression`) e depende do
`{$ifndef NoGenericMethods}` da RTL. A forma não-genérica é imune aos
dois problemas.

`ExtractRawData` cobre **10/10** dos casos exatos (medido nos dois
bitness, incluindo `record` e `enum`) — dispensa dispatch por `Kind`.

### D-5. Alargamento fica FORA — vira issue própria

Paridade real de conversão (Integer→Int64, Boolean→Integer, etc.)
exigiria uma tabela `Kind × Kind` **medida contra o `dcc32`**. `dcc32`
é Windows-only, na máquina do dono; ninguém neste ciclo pôde medir.
Regra da casa fixada no ADR da #21: **não se promete paridade que não
foi medida**. Uma tabela deduzida seria pior que a ausência dela, porque
o consumidor confia.

O Delphi resolve sozinho por delegação pura (D-3). A tabela existiria
**só** para o FPC imitar algo não medido, o que é pior do que não
imitar.

Alargamento vira **issue própria**, com matriz medida no `dcc32` como
pré-requisito — não como "ação para o próximo ciclo" solta em rodapé.
O programa de medição (fonte pronto no relatório, `TMeasure` record)
nasce **lá**, não aqui.

### D-6. XMLDoc de `TModernValue.AsType<T>` declara em voz alta

Texto obrigatório, tom da #21:

> No Delphi, `AsType<T>` herda a semântica de conversão do `TValue`
> nativo, incluindo alargamento de ordinais. No FPC 3.2.2, exige tipo
> exato. Conversão entre tipos diferentes não é garantida nos dois
> compiladores; use o tipo exato para código portável.

### D-7. Fechar o drift do §7 na unit pública

`TModernRTTIProperty.GetValue<T>` (linhas 385–397 hoje) passa a ser:

```pascal
Result := TModernValue.FromValue(FProp.GetValue(AInstance)).AsType<T>;
```

O bloco `{$IFDEF FPC}...{$ELSE}...{$ENDIF}` some. Após a mudança, o
único `{$IFDEF}` de `Source/ModernSyntax.RTTI.pas` é a diretiva da
cláusula `uses` da `implementation`. `TModernRTTIField.GetValue<T>`
**não é tocado**.

### D-8. Exceção única

`EModernRTTIError`. Não introduzir `EModernValueError`. Não há
consumidor pedindo pesca fina.

### D-9. Testes — CA-5 preservado com cenário de exceção LOCAL ao FPC

- **Sete cenários compartilhados** em `UScenarios.RTTI.pas`, todos de
  **tipo exato**, zero `{$IFDEF}`:
  `Scenario_ModernValue_AsType_String`, `_Integer`, `_Boolean`,
  `_Double`, `_Object`, `_Record`, `_Enum`.
- **Sete `published`/`[Test]`** em cada runner delegando aos
  compartilhados.
- **Um `published` extra**, LOCAL ao runner FPC:
  `TestModernValue_AsType_DifferentType_RaisesWithOriginAndDestination`.
  Não passa por `UScenarios.RTTI.pas` — o CA-5 do compartilhado é
  preservado.
- **Nenhum equivalente Delphi** ao teste de exceção: no Delphi tipo
  diferente pode passar por alargamento nativo; "levanta OU converte"
  não vale nada como teste.
- **`Fail(...)` (levanta `ETestScenarioFailed`), nunca `Assert`, nunca
  `Exception` bruta.** Padrão fixado na #25.
- **Cenário `From<Integer>(42).AsType<Int64>` = 42 (widening) é
  REMOVIDO** — testava a promessa que a #26 está deixando de fazer.
- **Cobertura record e enum na fixture** — prova que `ExtractRawData`
  é universal, e o enum toca #21 (herança) e #38 (multiplicidade 2+ no
  mesmo nível) de graça.
- **Mutação obrigatória:** trocar `if not AValue.IsType(TypeInfo(T))`
  por `if False` no backend FPC → cenário de exceção falha.
  Executar antes de fechar o PR (SKILL.md:92–97).

### D-10. Armadilha de nome — proibição explícita

`TValueOps` nasce homônimo entre os dois backends. Correto hoje pelo
`{$IFDEF}` da `uses` de `ModernSyntax.RTTI.pas`. **Proibido introduzir
uma terceira unit que faça `uses` das duas** — colisão de nome, quebra
compilação. Registrado aqui para o próximo não descobrir compilando.

## O que foi descartado, e a medição que derrubou

- **Dispatch por `Kind` com 5 casos** (`string`/`Integer`/`Boolean`/
  `Double`/`TObject`). Descartado na volta 1: `ExtractRawData` cobre
  10/10 dos casos exatos, incluindo `record` e `enum`, que o dispatch
  não cobriria. Medido no FPC 3.2.2 nos dois bitness.
- **`V.IsType<T>` (forma genérica).** Descartado na volta 1: não compila
  dentro de função genérica no FPC 3.2.2, e depende do
  `{$ifndef NoGenericMethods}` da RTL. `V.IsType(TypeInfo(T))` resolve.
- **Plano B "virar método de record se função livre não compilar".**
  Descartado na volta 1 (medição FPC), depois retomado na volta 3 —
  motivo não é técnico-FPC, é técnico-Delphi + regra da casa
  (Delphi não suporta rotina livre genérica; `Source/` tem zero delas).
- **Tabela de alargamento `Kind × Kind`.** Descartada na volta 2:
  `dcc32` é Windows-only, ninguém no ciclo mediu. Repetiria o erro da
  #21. Vira issue própria com matriz medida como pré-requisito.
- **Cascata `AsOrdinal`/`AsInt64`/`AsExtended`/`AsCurrency` como
  fallback controlado.** Descartada na volta 1 pelo próprio arquiteto —
  "vê no que dá" é como se produz lixo silencioso, que a issue proíbe
  explicitamente.
- **`TryCast(ATypeInfo, LCast)` no Delphi como equivalente
  não-genérico.** Cogitado e recuado na volta 3: substituir uma chamada
  nativa comprovada por composição cuja equivalência semântica não pode
  ser medida hoje é pior do que a solução de record com método genérico.
- **`{$IFDEF}` no corpo de `TModernValue.AsType<T>` para dispatch entre
  backends.** Descartado por construção: `{$IFDEF}` fica na `uses`;
  `TValueOps` homônimo em cada backend faz o dispatch.
- **Cenário `From<Integer>(42).AsType<Int64>` = 42.** Descartado na
  volta 2: testava a promessa (alargamento) que está sendo deixada de
  fazer. Substituído por asserção de exceção no shell FPC apenas.
- **Programa de medição com `procedure Try_<TDest>` livre.** Corrigido
  na volta 3: vira `class procedure TMeasure.Try_<TDest> static` de um
  record auxiliar. Sem isso, o dono não conseguiria rodar a matriz no
  `dcc32`. **Sede desse programa é a issue de alargamento, não esta.**

## Regras registradas nesta discussão para próximos ciclos

- **Medir no FPC NÃO autoriza descartar uma alternativa se ela foi
  motivada pelo Delphi.** Ordem correta: identificar qual compilador é
  o mais restritivo para a feature em questão, medir esse (ou declarar
  que não pode), e só então decidir. O arquiteto violou isso na volta 1
  ao mandar descartar o "plano B" com base só em medição FPC.
- **Não se promete paridade que não foi medida** (regra herdada da #21,
  reforçada aqui na volta 2). Vale para alargamento; vale para qualquer
  paridade futura entre os dois `TValue`.

## Impacto e reversibilidade

- Ninguém publica ABI. Nenhum consumidor externo conhecido usa
  `TModernValue` (o tipo não existe ainda).
- `TModernRTTIProperty.GetValue<T>` no FPC muda **mensagem** de erro
  (de "tamanho incompativel" para "incompativel: origem=... destino=...").
  Nenhuma regressão esperada nos três roundtrips existentes (leem no
  mesmo tipo que escrevem). Consumidor FPC que dependesse da mensagem
  antiga vê a nova; consumidor Delphi não vê diferença (delegação nativa
  mantém o comportamento).
- Reversão: apagar os três arquivos-alvo (`TModernValue` da unit pública,
  `TValueOps` dos dois backends) e restaurar o bloco `{$IFDEF FPC}` em
  `TModernRTTIProperty.GetValue<T>`. Simples.

## Referências

- [esp](pipeline-esp.md) — critérios formais e checklist.
- [plan](pipeline-plan.md) — ordem de execução.
- [task-input](pipeline-task-input.md) — handoff operacional.
- [API-MAP §2 (`TValue`) e §7 (arquitetura)](../../../strategy/2026-08-27-modernrtti/API-MAP.md)
- [SKILL — receita FPC + traps](../../../SKILL.md)
