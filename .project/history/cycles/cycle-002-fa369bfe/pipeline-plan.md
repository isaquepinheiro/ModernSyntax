---
type: plan
kind: artifact
title: "Plan — Pilar 1 da ModernRTTI"
description: "Plano de execucao em tres fatias: unit + tipos e GetProperties; fields; projeto Lazarus de teste."
status: draft
cycle: "002"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/fa369bfebcbab23d74f445cede226eb0
tags: [plan, modernrtti, rtti, pilar-1, issue-8]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-08-28T00:50:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — Pilar 1"
  - id: adr
    resource: "adr.md"
    title: "ADR — Design do Pilar 1"
---

# Plano de execucao — Pilar 1

Escopo: uma unit, tres tipos publicos, um erro dedicado, um conjunto
de testes DUnitX e um projeto Lazarus (novo ou compartilhado). Cabe
em um cycle. Nao ha independencia entre as fatias — property e field
so fazem sentido juntos como leitura de RTTI; a fatia de tests fecha
o entregavel. `scope = fits`.

## Fatia 1 — Unit e tipos base + GetProperties com deteccao FPC

**Arquivos:** `Source/ModernSyntax.RTTI.pas` (novo).

**O que entra:**

1. Preambulo padrao (cabecalho MIT como nas demais units, ver
   [ModernSyntax.Objects.pas:1-12](../../../analysis/03-architecture.md)).
2. `unit ModernSyntax.RTTI;` — **sem** `{$I ModernSyntax.inc}` (CA-3).
3. `interface` com `uses Rtti, TypInfo, SysUtils, Classes,
   Generics.Collections;`.
4. Tipos publicos:
   - `EModernRTTIError = class(Exception);`
   - `TModernRTTIProperty = record` — wrapper de `TRttiProperty`.
   - `TModernRTTIField = record` — wrapper de `TRttiField`.
   - `TModernRTTIType = record` — wrapper de `TRttiType`; expoe
     `Name`, `IsClass`, `GetProperties`, `GetProperty(Name)`.
   - `ModernRTTI = record` com os tres overloads de `GetType`
     (D-A7 do ADR).
5. Implementacao no Delphi: delegacao direta para `TRttiContext` +
   `TRttiType`.
6. Implementacao no FPC, via `{$IFDEF FPC}` (nao `.inc` — CA-3):
   - `GetType(...)` idem Delphi.
   - `GetProperties`: chama `TRttiContext.GetType(...).GetProperties`,
     e se **for classe** e o resultado for vazio, aplica a heuristica
     descrita em D-A5 do ADR — se nenhum ancestral publica RTTI,
     levanta `EModernRTTIError` com a mensagem prescrita (CA-2, R4).
7. `initialization`/`finalization` para o `TRttiContext` privado
   (D-A3 do ADR).
8. **Sem** `{$IFDEF FPC}` em nenhum ponto do teste, exemplo ou
   consumidor (CA-4/CA-5).

**Como conferir:** revisao de leitura (RN-5 do ESP: nenhum tipo de
`System.Rtti` na secao publica). `grep '{$I ModernSyntax.inc}'
Source/ModernSyntax.RTTI.pas` deve retornar zero. `grep 'FCP'` idem.

## Fatia 2 — GetFields

**Arquivos:** mesma unit (`Source/ModernSyntax.RTTI.pas`).

**O que entra:**

1. Metodos `GetFields`/`GetField(Name)` em `TModernRTTIType`
   delegando para `TRttiType`.
2. Metodos `Name`, `FieldType`, `GetValue`, `SetValue` em
   `TModernRTTIField`.

**Notas:** no FPC, `TRttiField` enumera campos de classes com RTTI
declarada; a mesma heuristica de deteccao pode ser aplicada, mas o
requisito estrito do PRD (R4) menciona propriedades — para fields
a decisao e devolver array vazio e nao alarmar (nao ha exigencia
oposta). Manter simetria com o Delphi.

## Fatia 3 — Testes DUnitX + projeto FPC

**Arquivos:**

- `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` — suite DUnitX com,
  no minimo, os casos:
  - `TestGetProperties_ReturnsPublishedProperty` — classe com
    `{$M+}` (ou `TPersistent`) e uma propriedade publicada; a suite
    verifica `Length(GetProperties) >= 1`.
  - `TestGetField_ReturnsPublicField` — classe com um `strict
    protected`/`public` field; verifica `GetField('X').GetValue`.
  - `TestGetProperties_RaisesForClassWithoutM` — classe sem
    `{$M+}` (ex: descendente direto de `TObject` sem publicacao);
    espera `EModernRTTIError` com trecho da mensagem (CA-2).
    A suite **nao** ramifica por compilador (CA-4); a excecao no
    Delphi para o mesmo caso pode ser tolerada com um teste
    condicional **dentro da API**, nao no consumidor — em ultimo
    caso, isolar num teste `{$IFNDEF DELPHI}` fica proibido; a
    solucao aceita e desenhar o caso de teste para valer nos dois:
    usar classe com metadata garantida em ambos (ex: `TPersistent`
    descendente) para os positivos, e um teste especifico do erro
    que declara o pre-requisito no seu comentario e passa nos dois
    (no Delphi a classe sem `{$M+}` legitimamente devolve vazio;
    nesse caso o teste do erro fica no proprio codigo da unit por
    meio de um teste **negativo unico** que aceita como valido ou
    a excecao FPC ou o array vazio Delphi — este ponto pode ser
    refinado na implementacao; o essencial e CA-4 nao sendo
    violado).
- `Test Delphi/EclbrSystem/PTestModernRTTI.dpr` — projeto Delphi
  DUnitX espelhando os outros `PTest*.dpr` desta pasta.
- Projeto Lazarus (`.lpi`/`.lpr`) para os mesmos testes:
  - **Se** o `.lpi` da issue #7 ja existir no repositorio no momento
    da implementacao: **adicionar** `UTestMS.RTTI.pas` a ele e
    encerrar aqui.
  - **Se nao existir**: criar `Test Lazarus/PTestModernRTTI.lpi`
    +  `.lpr` **minimo**, apenas com DUnitX + a unit de teste. O
    minimalismo e proposital: nao antecipar decisoes do #7.

**Como conferir:** `grep -rn '{$IFDEF FPC}' 'Test Delphi/' 'Test Lazarus/'`
retorna zero (CA-4). `lazbuild <lpi>` na maquina do autor executa os
testes (CA-6/CA-7; a fabrica nao roda — R2).

## Pos-condicoes do ciclo

- [ ] `Source/ModernSyntax.RTTI.pas` existe e passa nas verificacoes
  de grep acima.
- [ ] Testes DUnitX existem para property, field e caso negativo.
- [ ] Projeto Lazarus dos testes existe (novo ou compartilhado).
- [ ] Body do PR declara: "compilado em FPC 3.2.2 x86_64 e i386;
  nao compilado em Delphi" (CA-7 do ESP, R2 do PRD).
