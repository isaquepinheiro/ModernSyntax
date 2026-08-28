---
type: adr
kind: artifact
title: "ADR — Design de ModernSyntax.Invoker (Pilar 3 do ModernRTTI)"
description: "Decisões arquiteturais para TModernInvoker sobre TObject.MethodAddress: record com dois overloads Invoke<TSignature>, guarda SizeOf primeira linha, mensagem acionável, header (*..*), autocontenção e API dinâmica Delphi-only recolocada em issue irmã."
status: draft
cycle: "005"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/2ef372d993ff75b8dcd8c707bb79d636
tags: [adr, modernrtti, invoker, fpc, delphi, issue-10]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-08-28T14:15:00Z"
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
  - id: adr-attrs
    resource: "../history/cycles/cycle-004-e936cbe6/pipeline-adr.md"
    title: "ADR ciclo #8 — Atributos (regra 2 do ADENDO; guarda de include na casca)"
  - id: investigation
    title: "Relatório de investigação da issue #10 (run 96cd7df3aafbc7ce615f0fe5b2cb4ab8, comentário na issue #10)"
---

# ADR — Design da unit `ModernSyntax.Invoker`

> Investigation report: **PRESENT** (run `96cd7df3aafbc7ce615f0fe5b2cb4ab8`, comentário na
> issue #10). Este ADR **deriva** desse relatório: as decisões abaixo são as que a discussão
> fechou (voltas 1 e 2), reescritas em forma de decisão numerada com cross-links OKF. Onde
> este ADR **estende** o relatório, é para documento formal — sem divergência silenciosa.
> Se este ciclo alguma vez precisar contrariar o relatório, fica dito com todas as letras.

## Contexto

O PRD ([ModernRTTI](../../../strategy/2026-08-27-modernrtti/PRD.md), D5) pede que o Invoker nasça
em **unit própria**, não como extensão de `TModernObject.Factory` (`Objects.pas:208-241`).
O STUDY havia proposto `TRttiContext.GetType(...).GetMethod(...).Invoke` como mecanismo
principal, respondendo Q1 do PRD com uma leitura do **`main` do FPC**.

**A investigação mediu no alvo** (FPC 3.2.2 x86_64, `{$mode delphi}{$M+}`, seção
`published`) e mostrou que essa premissa é **falsa em 3.2.2**:

- `t.GetMethods = 0` para qualquer classe;
- `t.GetMethod('Echo') = nil` para qualquer nome;
- a unit `Rtti` é marcada `experimental` pelo próprio compilador.

Portanto, `TRttiMethod` **não existe** no FPC 3.2.2 — não é caso de borda. A saída medida
que **funciona nos dois compiladores** é `TObject.MethodAddress`, símbolo comum e idêntico
em Delphi e FPC 3.2.2. Este ADR registra a decisão de usá-lo, e as consequências.

A convenção de teste da família ModernRTTI foi fixada nos ciclos #7 e #8
([ADR cycle-003](../cycle-003-92fccbce/pipeline-adr.md) D-A7/D-A8,
[ADR cycle-004](../cycle-004-e936cbe6/pipeline-adr.md) D-A7): diretório por
**compilador** (`Test Shared/`, `Test Delphi/`, `Test FPC/`), FPCUnit no lado FPC, cenários
compartilhados sem framework, cascas finas. Este ADR **herda** a convenção sem reabrir.

## Decisões

### D-A1 — Unit nova e autocontida, `uses SysUtils;` apenas

Cria-se `Source/ModernSyntax.Invoker.pas`. `uses` da `interface`: **exclusivamente `SysUtils`**.
Não `Rtti`, não `TypInfo`, não `Windows`, não nenhuma unit de `Source/`.

**Motivo (volta 1 da investigação, confirmada pelo dono).** Nenhuma das 16 units de
`Source/` compila em FPC 3.2.2 hoje (medido; ver [SKILL](../../../SKILL.md) §"Two traps" #1).
Importar qualquer uma delas contamina a compilação com um defeito que **não tem nada a ver
com o Invoker**. E `Rtti`/`TypInfo` são desnecessários — o mecanismo escolhido é
`TObject.MethodAddress`, RTL básica.

**Descartado — reutilizar `TModernObject.FContext` (Objects.pas:41)**: recusado no
relatório. Não usar `TRttiContext` para nada é o que sustenta D-A1.

**Descartado — importar `System.TypInfo` para inspeção de `PTypeInfo(TSignature)`**: no FPC
3.2.2, `PTypeInfo` de um parâmetro genérico não devolve informação estável entre
compiladores; a guarda `SizeOf` (D-A5) cobre o erro real com uma linha.

### D-A2 — Mecanismo: `TObject.MethodAddress`, **não** `TRttiMethod.Invoke`

`MethodAddress` existe em `System.TObject` **nos dois compiladores**, com a mesma
assinatura (`function MethodAddress(const AName: string): Pointer;`). Devolve o `Code` do
método `published` do nome pedido, ou `nil`. Também funciona **pela classe** e acha
`class function`/`class procedure` (medido pelo dono na volta 1).

**Motivo.** Medição do dono no alvo: `TRttiContext.GetType(...).GetMethod(...)` devolve
`nil` para qualquer classe no FPC 3.2.2 (`GetMethods = 0`). O caminho do STUDY não é
degradação — é ausência.

**Consequência estrutural.** `MethodAddress` devolve **ponteiro**, não metadado. Para
chamar, alguém tem de saber a **assinatura** e fazer o cast do `TMethod`. Não existe, no
FPC 3.2.2, como montar uma chamada a partir de `array of TValue` arbitrário — não há de
onde ler os tipos dos parâmetros. Isto força D-A3 (API tipada por assinatura).

**Descartado — saída (C) do relatório: RTTI completa no Delphi + `MethodAddress` no FPC.**
Recusada pelo dono e pelo arquiteto na volta 1: produziria API que **compila nos dois e
se comporta diferente** (`Invoke(obj,'Echo',[1,'x'])` funciona no Delphi, falha no FPC).
É literalmente o defeito nº 1 do PRD, o que derrubou #11/#12 e o que a #9 gastou três
voltas para fechar.

**Descartado — saída (B) do relatório: `Register(TFoo, 'Echo', @TFoo.Echo)`.** Recusada
para esta issue: CA-3 dependeria de "o consumidor lembrar de registrar" — disciplina, não
garantia. Fica para issue irmã se aparecer caso de **dispatch aberto** (parser, script
bridge). Não é o que a #10 pede.

### D-A3 — API pública: `record` com dois overloads `Invoke<TSignature>`

```pascal
TModernInvoker = record
public
  class function Invoke<TSignature>(const AInstance: TObject;
    const AMethodName: string): TSignature; overload; static;
  class function Invoke<TSignature>(const AClass: TClass;
    const AMethodName: string): TSignature; overload; static;
end;
```

**Motivo (Q1 do relatório, decidido volta 1, provado por binário na volta 2).** `record`
sem estado por instância é coerente com `TMatch<T>`/`TAsync`. O dono compilou e rodou
esse desenho no FPC 3.2.2 x86_64 na volta 2 (61 → 66 linhas com a guarda) — três
propriedades ficaram **provadas por binário**: (i) `record` com class functions estáticas
genéricas compila; (ii) overload de `TClass` funciona com `m.Data := Pointer(AClass)`;
(iii) a armadilha "static symtable" **não dispara** neste desenho.

**Descartado — `IModernInvoker` (interface).** Sem estado, interface só existe para
"parecer OO". `record` é honesto.

**Descartado — `Invoke(obj, 'Echo', [args]): TValue` como API pública.** Recusada: no FPC
3.2.2 não há de onde ler os tipos dos parâmetros para montar a chamada. O consumidor
declara o tipo (`type TEchoFn = function(const s: string): string of object;`) — é o
**custo estrutural** de mecanismo único (não pode ser desviado).

**Descartado — só o overload de `TObject`.** Q3 do relatório (volta 1): `MethodAddress`
funciona pela classe e acha método de classe (medido). O segundo overload custa pouco e
cobre um caso real.

### D-A4 — Corpo dos overloads: guarda → `MethodAddress` → cast tipado

Depois da guarda `SizeOf` (D-A5), o corpo dos dois overloads é o mesmo shape:

```pascal
addr := AInstance.MethodAddress(AMethodName);          // ou AClass.MethodAddress(...)
if addr = nil then
  raise Exception.CreateFmt(
    'metodo "%s" nao encontrado em %s; no FPC isso exige {$M+} e secao published',
    [AMethodName, AInstance.ClassName]);                // ou AClass.ClassName
m.Code := addr;
m.Data := AInstance;                                    // ou Pointer(AClass)
Move(m, Result, SizeOf(TMethod));
```

**Motivo (herança da família #8).** Mensagem de erro que **ensina o que fazer** vale mais
do que mensagem que só diz o que houve. A herança é literal: a decisão que #8 tomou para
"a classe X não expõe propriedades à RTTI" está sendo aplicada a "a classe X não expõe o
método Y".

**Descartado — devolver `nil`/`false` para "não encontrado".** Q5 do relatório fechada em
volta 1: falha de exposição no FPC exige `{$M+}` e não pode ser ignorada em silêncio.
Uma API que devolve `false` convida o consumidor a ignorar; **e ignorar aqui é caro**.

### D-A5 — **Guarda `SizeOf` como primeira linha** dos dois overloads

```pascal
if SizeOf(TSignature) <> SizeOf(TMethod) then
  raise Exception.Create('TSignature nao e um tipo de metodo-de-objeto');
```

**Motivo (volta 2 da investigação, medido pelo dono).** Sem essa guarda,
`Move(m, Result, SizeOf(TMethod))` copia **16 bytes** para `Result` sem ninguém verificar
que `TSignature` é um método-de-objeto. `Invoke<Integer>(o, 'Echo')` escreveria 16 bytes
em cima de um `Integer` de 4 — **corrupção silenciosa de memória**, o pior defeito
possível. `SizeOf` sobre parâmetro genérico **compila no FPC 3.2.2** (medido: 66 lines
compiled) e transforma corrupção silenciosa em exceção alta.

**Limite explícito, registrado no header da unit.** A guarda não fecha 100% — dois tipos
diferentes com o mesmo `SizeOf` de `TMethod` passariam. Cobre o erro real (passar
`Integer`, `string`, `Boolean`), não cobre coincidência de tamanho. Aceito, com o teste
`Case_Invoke_NonMethodSignature_Raises` fixando o comportamento.

**Descartado — checar `PTypeInfo(TypeInfo(TSignature))^.Kind = tkMethod`**: no FPC 3.2.2,
`TypeInfo` sobre parâmetro genérico não é estável entre compiladores. `SizeOf` é.

**Descartado — sem guarda, confiando no compilador.** Compilador não reclama; medido,
gera corrupção sem aviso.

### D-A6 — Header SPDX em `(* ... *)`; zero `{$IFDEF FPC}` na unit; zero `{$I ModernSyntax.inc}`

- **Header SPDX-MIT em `(* ... *)`.** Motivo medido (defeito no PR #12 do ciclo #7): se um
  dia aparecer `{$...}` dentro do comentário `{ }`, o `}` da diretiva **fecha o comentário**
  e quebra o arquivo. `(* ... *)` aninha; `{ }` não.
- **Zero `{$IFDEF FPC}`.** `MethodAddress` é o mesmo símbolo com a mesma assinatura nos
  dois compiladores (medido). Não há divergência a acomodar.
- **Zero `{$I ModernSyntax.inc}`.** R3 do PRD; o `.inc` tem `{$IFDEF FCP}` em
  `ModernSyntax.inc:256` (bloco morto).

Estes três pontos, juntos, respondem **Q1 do PRD** no relatório do PR: *Q1 não exigiu
`{$IFDEF}` interno; a divergência que forçou o replaneamento foi `GetMethods = 0` no FPC
3.2.2, não a assinatura de `TRttiMethod.Invoke`.*

### D-A7 — R-FPC-Generic evitado **por desenho**, não por regra

O corpo do genérico `Invoke<TSignature>` só instancia **`TMethod`** — tipo da RTL,
declarado em `System`. Nenhum tipo declarado na `implementation` de
`ModernSyntax.Invoker.pas` é instanciado pelo corpo do genérico. Portanto, a armadilha
*"Global Generic template references static symtable"* (medida no PR #12 do ciclo #7)
**não dispara**, e isso ficou **provado por binário** quando o dono compilou o desenho
na volta 2.

**Registro para o futuro mantenedor.** Se um dia alguém precisar auxiliar a implementação
com tipo local, esse tipo tem de nascer na `interface` ou o corpo do genérico não pode
instanciá-lo. Não é regra a lembrar — é propriedade estrutural desta unit.

### D-A8 — Convenção de teste herdada da família: cenários em `Test Shared/` + duas cascas finas

Herda D-A7/D-A8 do [ADR cycle-003](../cycle-003-92fccbce/pipeline-adr.md)
e D-A7 do [ADR cycle-004](../cycle-004-e936cbe6/pipeline-adr.md):

- `Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas` — cenários **sem framework**. Cada
  caso é uma `procedure` que executa e levanta `Exception` na falha. Classes-alvo locais
  com `{$M+}` e seção `published`. **Sem `Assert`; sem `{$IFDEF}`.**
- `Test Delphi/EclbrSystem/UTestMS.Invoker.pas` + `PTestInvoker.dpr` (+ `.dproj` + `.res`)
  — casca fina DUnitX. Um `[Test]` por caso, delegando em uma linha.
- `Test FPC/EclbrSystem/UTestMS.Invoker.pas` + `PTestInvoker.lpr` + `PTestInvoker.lpi` —
  casca fina FPCUnit (`TTestCase`, `RegisterTest`). `.lpr` com `consoletestrunner`.

**Descartado — `Test Lazarus/`.** Recusado pela convenção da família (por **compilador**,
não por IDE). Nem existe no #7/#8; não vai passar a existir aqui.

**Descartado — DUnitX no lado FPC.** Não vendorizado (medido: `find . -iname "DUnitX*.pas"`
→ 0). FPCUnit é nativo. Foi o que matou o PR #11.

**Nota sobre a guarda de include (D-A8 do ciclo #8).** Esta issue **não usa** símbolo de
capacidade (`HAS_NATIVE_ATTRS`/`NO_NATIVE_ATTRS`): não há divergência de capacidade entre
Delphi e FPC no que o Invoker testa (`MethodAddress` funciona igual nos dois, e todos os
cenários são portáveis). Portanto, **não há `.inc` de símbolos** nesta entrega, e a
guarda `{$MESSAGE FATAL 'inc nao foi incluido'}` não se aplica.

### D-A9 — API dinâmica no padrão da RTTI nova do Delphi: **Delphi-only, em issue irmã**

O dono pediu na volta 2 o padrão da RTTI nova do Delphi
(`GetType(T).GetMethod('X').Invoke(obj, [args]): TValue`) e delegou a avaliação.

**Avaliação medida:** esse padrão **não pode** ser o mecanismo portável — no FPC 3.2.2
`GetMethods = 0` para qualquer classe. Não é degradação; é ausência.

**Decisão (volta 2).** A forma aceitável é oferecê-lo como **superfície declaradamente
Delphi-only ausente por compilação no FPC** (`{$IFDEF DELPHI}` na declaração inteira).
Divergência que **quebra o build** é honesta; divergência que devolve outro número em
runtime é o defeito nº 1 do PRD. E — isto é o que faz a decisão caber neste ADR sem
transbordar — essa API **não entra nesta issue**: vai para **issue irmã**, por dois
motivos que o próprio dono autorizou (*"se ficar muito para uma rodada única, pode ser
em outro"*): dobra a superfície de teste, e **ninguém neste ciclo tem Delphi para provar**.

**Descartado — entregar a API dinâmica junto com o núcleo portável.** Entregar aqui seria
somar a única parte que ninguém consegue verificar à única parte que já está provada.
Recomendação para o dono registrada no `REPORT-architect.md` deste ciclo.

### D-A10 — Renomear `Case_Invoke_WithArgs_PassesThemThrough` → `Case_TypedMethod_CalledWithArgs_ReturnsExpected`

**Motivo (volta 2 da investigação).** O `Invoke` do desenho A **não recebe args** — os
argumentos vão na chamada do método já tipado. O nome anterior sugeria que o `Invoke`
recebe args; o nome novo descreve o que o teste de fato prova: que o `TMethod` montado é
chamável com args e devolve o esperado.

Nome de teste que descreve API que não existe é como comentário desatualizado.

## Consequências

- **CA-3 do PRD** satisfeito **por construção**: o mecanismo é o mesmo símbolo nos dois
  compiladores (`TObject.MethodAddress`). O consumidor escreve a mesma chamada; a
  compilação e o runtime respondem igual.
- **Convenção da família ModernRTTI** aplicada sem reabrir: `Test FPC/EclbrSystem/`,
  `Test Shared/EclbrSystem/`, FPCUnit, cascas finas. Esta é a **terceira** aplicação da
  convenção (ciclos #7, #8, #10) — dois exemplos anteriores viram tradição.
- **API tipada por assinatura** é o preço estrutural: consumidor declara
  `type TFn = function(...) : T of object;` antes de invocar. Registrado no header da
  unit; sem esse contrato, não há mecanismo único.
- **Guarda `SizeOf` incompleta por natureza** (RSK-1 do esp) — cobre o erro real, não a
  coincidência de tamanho. Custo aceito; limite documentado; teste fixa o comportamento
  visível.
- **Nenhum código existente é modificado.** `grep -rn "Invoker\|ModernInvoker" Source/`
  = 0. Nenhuma unit de `Source/` importa a Invoker. Nenhum consumidor atual quebra.
- **Objects.pas intocado** (D5 do PRD). `TModernObject.Factory` continua fazendo
  `GetType → GetMethod → Invoke` no Delphi; a Invoker é entrega paralela em unit própria.
- **Superfície Delphi-only da RTTI nova** vai para **issue irmã**, com o argumento
  gravado neste ADR (D-A9) e no `REPORT-architect.md`. Se essa issue irmã não for aberta,
  a decisão fica no bundle para o próximo leitor entender por quê.
- **Verificações que dependem de Delphi**: apenas *o autor* pode confirmar. A fábrica não
  compila em Delphi (R2 do PRD; [SKILL](../../../SKILL.md) §"Delphi"). O PR declara literalmente
  o escopo compilado.
