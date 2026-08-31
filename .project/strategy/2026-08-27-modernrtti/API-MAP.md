---
type: strategy
title: "ModernRTTI — mapa da API: a RTTI nova do Delphi espelhada, medida no FPC 3.2.2"
description: A superfície completa da System.Rtti do Delphi, tipo a tipo e membro a membro, com o caminho de implementação medido no FPC 3.2.2 para cada um. É o documento que define o que a camada entrega e como.
status: stable
tags: [modernrtti, rtti, fpc, delphi, lazarus, api-map, portability]
---

# ModernRTTI — o mapa da API

## O que esta camada é

**A RTTI nova do Delphi, inteira, com o prefixo `Modern` — e disponível igual nos dois compiladores.**

Cada tipo é implementado **com o recurso que cada linguagem oferece**. O Delphi usa a `System.Rtti` direto. O Lazarus tem quase tudo, só **de forma diferente e mais verbosa** — e é exatamente essa verbosidade que a camada existe para absorver, entregando ao consumidor a simplicidade da RTTI do Delphi.

**A regra que governa tudo:** ramificar **dentro** da biblioteca é permitido; no código do consumidor, nunca (D2/CA-5 do PRD). Se um tipo existe, ele existe **nos dois** — o que muda é o que roda por baixo.

**Consequência direta, e é o erro que já cometemos uma vez:** um tipo público **jamais** fica sob `{$IFDEF}` de compilador. Se ele sumir num dos lados, o consumidor é obrigado a ramificar só para *declarar* uma variável — e aí a camada deixou de fazer o que existe para fazer.

## Método deste documento

Todo "existe / não existe" abaixo foi **medido compilando** no FPC 3.2.2 x86_64 do autor, um símbolo por vez. Nada aqui é leitura de documentação.

---

## 1. Tipos — o que o FPC 3.2.2 tem

| tipo do Delphi | FPC 3.2.2 | tipo Modern | como se implementa no FPC |
|---|---|---|---|
| `TRttiContext` | **existe** | `TModernRTTIContext` | envolve direto; completa `GetTypes`/`FindType` |
| `TRttiObject` | existe | — (base interna) | — |
| `TRttiNamedObject` | existe | — (base interna) | — |
| `TRttiType` | **existe** | `TModernRTTIType` | envolve; completa campos e atributos |
| `TRttiInstanceType` | existe | `TModernRTTIInstanceType` | envolve |
| `TRttiMember` | existe | — (base interna) | — |
| `TRttiProperty` | **existe** | `TModernRTTIProperty` | envolve direto — **superfície completa** |
| **`TRttiField`** | **AUSENTE** | `TModernRTTIField` | **`vmtFieldTable` + `FieldAddress`** |
| `TRttiMethod` | **existe** | `TModernRTTIMethod` | tipo e membros existem; **o dado vem do `vmtMethodTable`** |
| `TRttiParameter` | existe | `TModernRTTIParameter` | envolve |
| `TRttiInterfaceType` | existe | `TModernRTTIInterfaceType` | envolve |
| **`TRttiRecordType`** | AUSENTE | `TModernRTTIRecordType` | próprio, sobre `TypInfo` |
| **`TRttiArrayType`** | AUSENTE | `TModernRTTIArrayType` | próprio, sobre `TypInfo` |
| **`TRttiEnumerationType`** | AUSENTE | `TModernRTTIEnumerationType` | próprio, sobre `GetEnumName`/`GetEnumValue` |
| `TRttiPointerType` | existe | `TModernRTTIPointerType` | envolve |
| **`TRttiSetType`** | AUSENTE | `TModernRTTISetType` | próprio, sobre `TypInfo` |
| `TValue` | **existe** | `TModernValue` | envolve; **acrescenta `AsType<T>`** |
| **`TRttiVisibility`** | AUSENTE | `TModernVisibility` | enum próprio |
| **`TCustomAttribute`** | AUSENTE | `TModernAttribute` | **já entregue** (Pilar 2) |
| **`TRttiIndexedProperty`** | AUSENTE | `TModernRTTIIndexedProperty` | próprio, sobre `TypInfo` |

**13 de 20 existem.** Os 7 ausentes têm caminho; nenhum é impossível.

---

## 2. Membros — medidos um a um

### `TRttiContext` → `TModernRTTIContext`

| membro | FPC | no Modern |
|---|---|---|
| `Create` / `Free` | OK | envolve |
| `GetType` | OK | envolve |
| **`GetTypes`** | ausente | **implementar** — enumerar via `TypInfo` |
| **`FindType`** | ausente | **implementar** — busca por nome qualificado |
| `GetPackages` | ausente | **fora de escopo** — conceito de pacote do Delphi não tem par no FPC; declarar |

### `TRttiType` → `TModernRTTIType`

| membro | FPC | no Modern |
|---|---|---|
| `GetProperties` / `GetProperty` | OK | envolve |
| **`GetFields` / `GetField`** | **ausente** | **`vmtFieldTable`** |
| `GetMethods` / `GetMethod` | API OK, **devolve 0** | **`vmtMethodTable`** |
| `GetDeclaredMethods` | OK | envolve |
| **`GetDeclaredProperties`** | ausente | filtrar `GetProperties` por `Parent` |
| **`GetAttributes`** | ausente | **`ModernAttributes.GetAttributes`** — já entregue |
| `TypeKind`, `Handle`, `Name`, `BaseType` | OK | envolve |
| `IsInstance`, `AsInstance`, `IsRecord`, `TypeSize` | OK | envolve |
| **`QualifiedName`** | ausente | compor `UnitName + '.' + Name` |

### `TRttiProperty` → `TModernRTTIProperty`

`GetValue`, `SetValue`, `PropertyType`, `IsReadable`, `IsWritable`, `Name`, `Visibility`, `Parent` — **todos OK**. Envolvimento direto, sem trabalho extra.

### `TRttiMethod` → `TModernRTTIMethod`

`Invoke`, `GetParameters`, `ReturnType`, `IsConstructor`, `IsClassMethod`, `IsStatic`, `Name`, `Visibility` — **todos OK**.

⚠️ **O problema não é a API, é o dado:** `TRttiType.GetMethods` devolve **0** no FPC. A lista vem do `vmtMethodTable`, e a invocação, do `MethodAddress` — que é o mecanismo já entregue no Pilar 3.

### `TValue` → `TModernValue`

`From<T>`, `IsEmpty`, `TypeInfo`, `Kind`, `AsObject`, `AsString`, `AsInteger`, `IsObject`, `ToString` — **todos OK**.

| **`AsType<T>`** | **ausente** | **implementar** — é o membro mais usado da API |

---

## 3. Enumerators — parte do produto, não enfeite

A verbosidade que a camada existe para matar aparece justamente aqui. O consumidor tem de escrever:

```pascal
for LField in LType.Fields do
  WriteLn(LField.Name);
```

…nos **dois** compiladores, sem saber que por baixo um lê `TRttiField` e o outro percorre a `vmtFieldTable`.

**Cada coleção expõe um enumerator:** `Fields`, `Properties`, `Methods`, `Parameters`, `Attributes`, `Types`.

Isso é além do Delphi, que devolve `TArray<T>` cru. **Aqui a camada não só iguala — ela melhora**, e é o ponto do produto: simplicidade de RTTI do Delphi, com ergonomia melhor, nos dois compiladores.

---

## 4. O limite honesto, para declarar e não esconder

No FPC, a seção `published` **só aceita campo de tipo classe**:

```
Error: Symbol cannot be published, can be only a class
```

Então `GetFields` enxerga menos campos no FPC que no Delphi. **Isso é sobre quais campos são visíveis, não sobre o tipo existir** — o `TModernRTTIField` existe nos dois, e a diferença de conjunto vai em XMLDoc, com a palavra "no FPC".

Mesma coisa para métodos: só `published` entra no `vmtMethodTable`.

**Regra de declaração:** onde o conjunto de dados diferir entre compiladores, isso é documentado **e coberto por teste que prova a diferença** — nunca escondido atrás de uma lista vazia.

---

## 5. A lição que este mapa incorpora

**Duas vezes uma conclusão de "não existe no FPC" se revelou "existe por outro caminho":**

| | o que "não existe" | o que resolveu |
|---|---|---|
| Pilar 3 | `TRttiMethod.Invoke` (`GetMethods` → 0) | `TObject.MethodAddress` |
| Pilar 1 | `TRttiField`, `GetFields` | `vmtFieldTable` / `FieldAddress` |

A primeira medição responde *"a API X existe?"*. A segunda tem de perguntar *"existe outro caminho para o mesmo resultado?"* — e é ela que decide o desenho.

**Neste documento, nenhum "ausente" virou "impossível".** Os sete tipos e os oito membros ausentes têm caminho medido ou identificado.

---

## 6. Ordem de implementação

1. **Corrigir o `TModernRTTIField`** — hoje sob `{$IFNDEF FPC}`, tem de existir nos dois (issue #21).
2. **`TModernRTTIMethod`** — a API existe; popular pelo `vmtMethodTable`.
3. **`TModernValue.AsType<T>`** — membro mais usado, ausente no FPC.
4. **`TModernRTTIContext`** — `GetTypes` e `FindType`.
5. **Enumerators** em todas as coleções.
6. **Os tipos de categoria** — `Record`, `Array`, `Enumeration`, `Set`, `IndexedProperty`, `Visibility`.

Cada passo entra como issue própria, com o critério de sempre: **compila e passa nos dois bitness do FPC, e o autor confirma o Delphi.**

---

## 7. Arquitetura física — `{$IFDEF}` só para REDIRECIONAR

Decisão do dono, e ela governa a implementação inteira:

> *"Cria uma abstração, as sintaxes dos tipos em units distintas para ficar melhor e não ficar tanto IFDEF com blocos enormes neles, use só para redirecionar."*

### As três units

```
Source/ModernSyntax.RTTI.pas            <- API PUBLICA. Zero {$IFDEF} nos tipos.
Source/ModernSyntax.RTTI.Delphi.pas     <- backend Delphi: System.Rtti direto
Source/ModernSyntax.RTTI.FPC.pas        <- backend FPC: vmtFieldTable, vmtMethodTable, TypInfo
```

**O único `{$IFDEF}` da unit pública fica na cláusula `uses`:**

```pascal
implementation

uses
  {$IFDEF FPC}
  ModernSyntax.RTTI.FPC;
  {$ELSE}
  ModernSyntax.RTTI.Delphi;
  {$ENDIF}
```

Três linhas de redirecionamento. Nenhum bloco condicional envolvendo corpo de método, e **nenhum envolvendo declaração de tipo**.

### Como o tipo público fica sem ramificação

O truque é o estado privado ser **neutro** — não citar nenhum tipo que exista só de um lado:

```pascal
TModernRTTIField = record
strict private
  FOwner: TClass;
  FName: string;
  FToken: Pointer;      // Delphi: o TRttiField. FPC: a entrada da vmtFieldTable.
public
  function Name: string;
  function GetValue<T>(const AInstance: TObject): T;
  procedure SetValue<T>(const AInstance: TObject; const AValue: T);
end;
```

`FToken` é opaco: **a unit pública nunca o interpreta**, só repassa ao backend. Por isso ela não precisa saber o que ele é, e por isso não precisa de `{$IFDEF}`.

### O contrato entre a unit pública e os backends

Os dois backends expõem **a mesma superfície de unit** — mesmos nomes, mesmas assinaturas. É o que permite trocar um pelo outro por `uses`:

```pascal
function  FieldToken(AOwner: TClass; const AName: string): Pointer;
function  FieldTokens(AOwner: TClass): TArray<Pointer>;
function  FieldName(AToken: Pointer): string;
function  FieldRead(AToken: Pointer; AInstance: TObject): TModernValue;
procedure FieldWrite(AToken: Pointer; AInstance: TObject; const AValue: TModernValue);
```

…e o equivalente para propriedades, métodos e parâmetros.

**Se um backend divergir do outro na assinatura, o build quebra** — a compilação é o portão que garante que os dois lados continuam iguais. Não depende de disciplina.

### Por que assim, e não `{$IFDEF}` espalhado

1. **O consumidor nunca vê ramificação** — CA-5/D2 atendidos por construção, não por vigilância.
2. **Cada backend se lê como código normal**, sem condicional no meio. Quem for mexer no lado FPC lê Pascal do FPC, e ponto.
3. **A armadilha do `{ }` que não aninha some**, porque diretiva em prosa deixa de aparecer perto de bloco condicional grande — foi o defeito que derrubou os PRs #12 e #16.
4. **O dialeto se resolve por unit.** Cada backend declara o próprio `{$mode delphi}` — foi a ausência disso que derrubou o PR #17.

### Vale para a família inteira

O mesmo padrão se aplica onde houver diferença de mecanismo:

```
ModernSyntax.Attributes.pas   +  .Delphi / .FPC   (nativo x registry)
ModernSyntax.Invoker.pas      +  .Delphi / .FPC   (se divergir; hoje MethodAddress serve aos dois)
```

Onde **não** houver divergência real — como o Invoker hoje, que usa `MethodAddress` nos dois — **não se cria backend**. Divisão sem diferença é custo sem ganho.
