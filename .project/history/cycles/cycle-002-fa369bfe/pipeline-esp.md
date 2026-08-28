---
type: spec
kind: artifact
title: "ESP — Pilar 1 da ModernRTTI: leitura de RTTI (Type / Property / Field)"
description: "Especifica a nova unit ModernSyntax.RTTI expondo TModernRTTIType/TModernRTTIProperty/TModernRTTIField com a mesma API no Delphi e no FPC, adaptando {$M+}/published no FPC e detectando ausencia."
status: draft
cycle: "002"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/fa369bfebcbab23d74f445cede226eb0
tags: [modernrtti, rtti, fpc, delphi, pilar-1, spec, issue-8]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-08-28T00:50:00Z"
sources:
  - id: prd
    resource: "../strategy/2026-08-27-modernrtti/PRD.md"
    title: "ModernRTTI PRD"
  - id: study
    resource: "../strategy/2026-08-27-modernrtti/STUDY.md"
    title: "ModernRTTI Study (medicoes de dia zero)"
  - id: arch
    resource: "../analysis/03-architecture.md"
    title: "03 Architecture — ModernSyntax"
---

# ESP — Pilar 1: Leitura de RTTI

## 1. Objetivo

Entregar a primeira camada da biblioteca **ModernRTTI**: tres tipos de leitura
(`TModernRTTIType`, `TModernRTTIProperty`, `TModernRTTIField`) que expoem a
**mesma API** no Delphi e no Lazarus/FPC 3.2.2, com o ponto de entrada
`ModernRTTI.GetType(T)`. No Delphi e reexportacao quase 1:1 sobre
`System.Rtti`; no FPC adapta `{$M+}` e `published` sem forcar ramificacao no
codigo do consumidor (D2 do [PRD](../../../strategy/2026-08-27-modernrtti/PRD.md)).

## 2. Escopo

Entra nesta entrega:

- Nova unit `Source/ModernSyntax.RTTI.pas` contendo:
  - Registro/classe estatica `ModernRTTI` com `GetType<T>` e `GetType(AClass)`.
  - `TModernRTTIType` — wrapper sobre `TRttiType` com pelo menos:
    `Name`, `IsClass`, `GetProperties`, `GetProperty(Name)`, `GetFields`,
    `GetField(Name)`.
  - `TModernRTTIProperty` — wrapper sobre `TRttiProperty` com pelo menos:
    `Name`, `PropertyType`, `IsReadable`, `IsWritable`, `GetValue(Instance)`,
    `SetValue(Instance, Value)`.
  - `TModernRTTIField` — wrapper sobre `TRttiField` com pelo menos:
    `Name`, `FieldType`, `GetValue(Instance)`, `SetValue(Instance, Value)`.
  - Excecao dedicada `EModernRTTIError` para os erros da camada.
- `TRttiContext` compartilhado, com inicializacao e finalizacao no
  `initialization`/`finalization` da unit (segue o padrao ja usado em
  [Objects.pas:191-201](../../../analysis/03-architecture.md)).
- Ramificacao Delphi/FPC feita com `{$IFDEF FPC}` **direto na unit**, sem
  incluir `ModernSyntax.inc` (evita o bug `FCP` de `ModernSyntax.inc:256`
  descrito em R3 do PRD).
- Deteccao e reporte da ausencia de `{$M+}` no FPC: quando o tipo e classe
  e nao ha metadata RTTI publicada, `GetProperties` **levanta**
  `EModernRTTIError` com mensagem acionavel; nunca devolve lista vazia
  silenciosa (R4).
- Testes DUnitX cobrindo: leitura de propriedade e campo em Delphi;
  leitura de propriedade `published` em FPC; deteccao de classe sem
  `{$M+}` no FPC.
- Registro do projeto Lazarus dos testes: se o `.lpi` criado pela issue
  de callbacks (#7) ja existir, os testes deste pilar sao adicionados
  a ele; se ainda nao existir, este ciclo cria um `.lpi` **minimo**
  apenas para os testes do Pilar 1 (ver plan.md, fatia 3).

## 3. Fora de escopo

- Leitura de atributos (`GetAttributes`) — e o Pilar 2 (issue #9).
- Invocacao de metodo (`TModernInvoker`) — e o Pilar 3 (issue #10).
- Callbacks unificados (`IMSFunc`/`IMSProc`) — issue #7.
- Extensao de `TModernObject.Factory` (D5 do PRD).
- Correcao do `{$IFDEF FCP}` em `ModernSyntax.inc:256` (fora do PRD; a
  unit deste pilar contorna nao incluindo o `.inc`).
- Correcao dos imports de `Windows` em `Std.pas`/`DotEnv.pas`. A nova
  unit usa apenas `Rtti`, `TypInfo`, `SysUtils`, `Classes`,
  `Generics.Collections` — nao toca nenhuma unit contaminada.
- Enumeracao de propriedades de classes sem `{$M+}` no FPC sem aviso
  (proibido por R4).

## 4. Regras de negocio

- **RN-1.** A chamada `ModernRTTI.GetType(T).GetProperties` retorna a
  mesma sequencia de propriedades **legivel** para uma mesma classe
  `T` nos dois compiladores, quando `T` esta declarada com o marcador
  adequado (Delphi: qualquer classe descendente de `TObject` com
  propriedades `public`/`published`; FPC: classe com `{$M+}` e
  propriedades `published`).
- **RN-2.** No codigo do consumidor **e proibido** o uso de
  `{$IFDEF FPC}`, `{$IFDEF DELPHI}` ou qualquer variante para chamar
  esta API (D2 do PRD, CA-5).
- **RN-3.** A unit `ModernSyntax.RTTI` **nao inclui**
  `ModernSyntax.inc`. Ramifica com `{$IFDEF FPC}` direto (R3).
- **RN-4.** Ausencia de `{$M+}` em uma classe passada a esta API no
  FPC **e um erro reportado**, nao uma lista vazia. A mensagem
  identifica a classe e diz o que falta.
- **RN-5.** A API nao expoe `TRttiType`/`TRttiProperty`/`TRttiField`
  cruas ao consumidor; a superficie publica e exclusivamente
  `TModernRTTI*`. Isso preserva o contrato de "mesma API" (D2) e
  permite que futuras adaptacoes fiquem contidas.

## 5. Criterios de aceitacao

- **CA-1.** `ModernRTTI.GetType(T).GetProperties` retorna as
  propriedades de `T` no Delphi e no FPC com a **mesma chamada** no
  codigo do consumidor. (do PRD e do issue)
- **CA-2.** Ausencia de `{$M+}` no FPC e detectada e reportada;
  `GetProperties` **nunca** retorna lista vazia silenciosa. (R4)
- **CA-3.** A unit `ModernSyntax.RTTI` usa `{$IFDEF FPC}` diretamente
  e **nao** contem `{$I ModernSyntax.inc}`. (R3)
- **CA-4.** **Nenhum** arquivo de teste desta entrega contem
  `{$IFDEF FPC}` no codigo do consumidor. (CA-5 do PRD)
- **CA-5.** Testes DUnitX cobrem no minimo: leitura de propriedade;
  leitura de campo; erro claro para classe sem `{$M+}` no FPC.
- **CA-6.** Existe um `.lpi` (novo ou existente) que compila os
  testes deste pilar no lazbuild (verificacao pelo orquestrador na
  maquina do autor).
- **CA-7.** O PR declara explicitamente: **compilado em FPC 3.2.2
  x86_64 e i386; nao compilado em Delphi** (R2 do PRD; a fabrica
  nao tem compilador Pascal).
- **CA-8.** A superficie publica de `ModernRTTI` nao vaza tipos de
  `System.Rtti` para o consumidor (RN-5).

## 6. Restricoes

- **Alvo FPC:** 3.2.2 estavel, 32 e 64 bits (`i386` e `x86_64`).
- **Alvo Delphi:** as versoes atualmente suportadas pela biblioteca
  (compilacao verificada pelo autor).
- **A fabrica nao compila Pascal** — nao ha Delphi nem FPC no
  container. Toda verificacao aqui e por **leitura**; compilacao e
  responsabilidade do orquestrador na maquina do autor (R2).
- Unidades e simbolos permitidos na `uses`: `Rtti`, `TypInfo`,
  `SysUtils`, `Classes`, `Generics.Collections`. Nada de `Windows`,
  `System.Threading`, nem qualquer unit atualmente marcada como
  bloqueada em [03-architecture.md](../../../analysis/03-architecture.md).

## 7. Riscos

- **RSK-1 — API do FPC `Rtti` e experimental.** O compilador emite
  `Warning: Unit "Rtti" is experimental` (R1). Assumido; o
  encapsulamento em `TModernRTTI*` (RN-5) e justamente a mitigacao.
- **RSK-2 — Sem compilador na fabrica (R2).** A revisao aqui pode
  passar codigo que nao compile. Mitigacao: teste minimo `.lpi` no
  proprio ciclo e declaracao explicita no PR de qual compilador foi
  usado onde.
- **RSK-3 — Dependencia da issue #7 (callbacks).** O PRD e o issue
  supoem um `.lpi` de testes criado ali. Se #7 nao estiver mergeado
  quando este ciclo entrar, este ciclo cria um `.lpi` proprio,
  minimo, para nao bloquear.
- **RSK-4 — Deteccao de `{$M+}` no FPC.** No FPC, uma classe sem
  metadata publicada retorna simplesmente lista vazia. A deteccao
  precisa distinguir "classe sem propriedades" de "classe sem
  `{$M+}`". Estrategia proposta em adr.md.
- **RSK-5 — Diferencas de assinatura em `TRttiProperty.SetValue`
  entre Delphi e FPC nao foram medidas.** Se aparecerem, ficam
  contidas dentro da unit (RN-5 protege o consumidor).
