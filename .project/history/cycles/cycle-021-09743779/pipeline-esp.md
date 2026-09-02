---
type: spec
kind: artifact
title: "ESP — Attributes fora do contrato de nil-handle (issue #56)"
description: "PropAttributes recebe a mesma guarda de nil dos outros cinco membros de TModernRTTIType; sexto bloco no cenario compartilhado; assertivas uniformizadas para igualdade estrita."
status: draft
cycle: "021"
agent: architect
workflow: equipe-bug
node: architect
resource: aefos://run/09743779c7c9860b5fa380f6979d94ca
tags: [modernrtti, rtti, spec, issue-56, bug, nil-handle, emodernrttierror, fpc, attributes]
generated:
  by: "equipe-bug@node:architect"
  at: "2026-09-02T15:40:00Z"
sources:
  - id: issue-56
    resource: "https://github.com/isaquepinheiro/ModernSyntax/issues/56"
    title: "Issue #56 — TModernRTTIType.Attributes fora do contrato de nil-handle da #49"
  - id: investigation
    title: "Relatorio de investigacao — Issue #56 (run c85a5115026d0a220da0a27064774fdd) — PRESENT"
  - id: adr
    resource: "adr.md"
    title: "ADR — issue #56"
  - id: plan
    resource: "plan.md"
    title: "PLAN — issue #56"
  - id: task-input
    resource: "task-input.md"
    title: "TASK-INPUT — issue #56"
  - id: esp-49
    resource: "https://github.com/isaquepinheiro/ModernSyntax/issues/49"
    title: "Issue #49 — contrato de nil-handle (PR #55)"
  - id: skill
    resource: "/SKILL.md"
    title: "SKILL — receita FPC, traps"
  - id: conventions
    resource: "/analysis/05-conventions.md"
    title: "05 Conventions — ModernSyntax"
---

# ESP — issue #56 (`TModernRTTIType.Attributes` — resíduo do nil-handle)

## 1. Objetivo

Fechar o residuo que a issue #49 (PR #55) deixou em aberto: a property
`Attributes` de `TModernRTTIType` nao levanta `EModernRTTIError` sobre um
handle com `IsNil = True` — devolve vazio silenciosamente, comportamento
indistinguivel de "o tipo nao tem atributos".

O objetivo e aplicar em `PropAttributes` a mesma guarda ja usada nos outros
cinco membros (`Name`, `GetProperties`, `GetFields`, `GetMethods`,
`GetMethod`) e acrescentar o sexto bloco ao cenario compartilhado
`Scenario_NilHandle_AllMembers_Raises`, aproveitando o commit para
uniformizar as assertivas dos cinco blocos existentes.

| Membro | Comportamento atual | Comportamento exigido |
|--------|--------------------|-----------------------|
| `Attributes` (IsNil=True) | vazio silencioso | `EModernRTTIError` nomeando `'Attributes'` |
| `Attributes` (handle valido nao-classe: record, enum) | vazio | **vazio — preservado** |

Nenhuma outra API muda. A `resourcestring SModernRTTINilHandle` ja existe
(`Source/ModernSyntax.RTTI.pas:892-893`) e ja e parametrizada por `%s`.

---

## 2. Escopo

### 2.1 `Source/ModernSyntax.RTTI.pas`

**Guarda em `PropAttributes`** (linha de referencia: 1124-1133).

Inserir como **primeira instrucao do corpo** (antes do comentario `// Issue #27:`):

```pascal
if FType = nil then
  raise EModernRTTIError.CreateFmt(SModernRTTINilHandle, ['Attributes']);
```

O comentario `// Issue #27:` (hoje linhas 1126-1128) desce para ficar
colado a `if (FType is TRttiInstanceType)` — permanece intacto em texto,
so muda de posicao. O ramo `else Result := nil` (linha 1131-1132) nao e
tocado: e o vazio legitimo para handle valido nao-classe.

**Estrutura final de `PropAttributes`:**

```pascal
function TModernRTTITypeHelper.PropAttributes: TArray<TObject>;
begin
  if FType = nil then
    raise EModernRTTIError.CreateFmt(SModernRTTINilHandle, ['Attributes']);
  // Issue #27: alias para a coleção ja existente do Pilar 2. Delega direto
  // — a fusao nativa+registrada (Delphi) e a copia de `Owned` (FPC) vivem
  // dentro de `ModernAttributes.GetAttributes`. Nenhum estado novo aqui.
  if (FType is TRttiInstanceType) then
    Result := ModernAttributes.GetAttributes(TRttiInstanceType(FType).MetaclassType)
  else
    Result := nil;
end;
```

### 2.2 `Test Shared/EclbrSystem/UScenarios.RTTI.pas`

**Passo A — uniformizacao dos cinco blocos existentes** (linhas 1447-1534).

Em cada um dos cinco blocos (`Name`, `GetProperties`, `GetFields`,
`GetMethods`, `GetMethod`), substituir o assert baseado em `Pos(...)` por
igualdade estrita e reescrever a mensagem do `Fail` correspondente:

| Bloco | Linha do `if` | Linha do `Fail` |
|-------|--------------|-----------------|
| `Name` | 1461 | 1462 |
| `GetProperties` | 1478 | 1479-1480 |
| `GetFields` | 1497 | 1498 |
| `GetMethods` | 1514 | 1515-1516 |
| `GetMethod` | 1532 | 1533-1534 |

**Antes (padrao Pos):**
```pascal
if Pos('<nome>', LMsg) = 0 then
  Fail(Format('Mensagem de <nome> nao cita o membro chamado: "%s"', [LMsg]));
```

**Depois (igualdade estrita):**
```pascal
if LMsg <> Format(SModernRTTINilHandle, ['<nome>']) then
  Fail(Format('Mensagem de <nome> incorreta: "%s"', [LMsg]));
```

Total: 5 blocos × 2 linhas alteradas (o `if` e o `Fail`). Mesmo
procedimento, mesmo commit.

**Passo B — sexto bloco (`Attributes`) — append puro.**

Inserir **apos linha 1534**, antes do `end;` do procedimento (linha 1535),
em ordem cronologica (a posicao documenta que `Attributes` foi o membro
que a #49 nao pegou):

```pascal

  // Attributes (sexto membro — issue #56)
  LRaised := False;
  LMsg := '';
  try
    LType.Attributes;
  except
    on E: EModernRTTIError do
    begin
      LRaised := True;
      LMsg := E.Message;
    end;
  end;
  if not LRaised then
    Fail('Attributes sobre handle nil nao levantou EModernRTTIError.');
  if LMsg <> Format(SModernRTTINilHandle, ['Attributes']) then
    Fail(Format('Mensagem de Attributes incorreta: "%s"', [LMsg]));
```

As variaveis locais `LRaised` e `LMsg` ja existem no escopo do
procedimento — nao ha nova declaracao (convencao D.3, prefixo `L` para
locais, §1.3 de conventions).

### 2.3 Fora de escopo (out-of-scope, explicito)

- Membros de `TModernRTTIType` alem dos seis nominados — fora desta issue.
- Tipos derivados (`TModernRTTIEnumerationType`, `TModernRTTIPointerType`,
  `TModernRTTIRecordType`, `TModernRTTIArrayType`, `TModernRTTISetType`)
  — esses records usam `FToken: PTypeInfo`, nao `FType: TRttiType`.
- Novos testes de "wrong-kind" para outros tipos — fora de escopo.
- XMLDoc adicionado em `PropAttributes`/`Attributes` — nao coberto pela
  acceptance da issue nem pelo relatorio de investigacao; pode entrar em
  issue de documentacao separada.
- Casca FPC (`Test FPC/EclbrSystem/UTestMS.RTTI.pas`) e casca Delphi
  (`Test Delphi/EclbrSystem/UTestMS.RTTI.pas`): estas cascas ja delegam
  `Scenario_NilHandle_AllMembers_Raises` em uma linha; como o cenario
  compartilhado ganha o sexto bloco, as cascas ficam automaticamente
  cobertas sem alteracao propria (convencao D-7 "um cenario, duas cascas").

---

## 3. Regras de negocio

- **B-56.1** — Quando `FType = nil` (`IsNil = True`), `PropAttributes`
  levanta `EModernRTTIError.CreateFmt(SModernRTTINilHandle, ['Attributes'])`.
  O consumidor recebe `EModernRTTIError`, nao vazio silencioso.
- **B-56.2** — Quando `FType <> nil` mas o tipo nao e `TRttiInstanceType`
  (record, enum), `PropAttributes` continua devolvendo `nil` (vazio)
  silenciosamente. O ramo `else Result := nil` permanece intacto.
- **B-56.3** — A guarda de nil e a **primeira instrucao visivel** de
  `PropAttributes`, antes do comentario `// Issue #27:`. Uniformidade
  com os outros cinco membros.
- **B-56.4** — Os seis blocos de `Scenario_NilHandle_AllMembers_Raises`
  usam assertiva por **igualdade estrita**:
  `LMsg <> Format(SModernRTTINilHandle, ['<nome>'])`. Nenhum `Pos`.
- **B-56.5** — O sexto bloco aparece em **ordem cronologica** (apos o
  quinto), documentando que `Attributes` foi o residuo da #49.
- **B-56.6** — Nenhuma `resourcestring` nova, nenhum tipo novo, nenhuma
  mudanca de API publica.

---

## 4. Criterios de aceitacao

- [ ] `Attributes` sobre handle com `IsNil = True` levanta `EModernRTTIError`
      e a mensagem e exatamente `Format(SModernRTTINilHandle, ['Attributes'])`.
- [ ] `Attributes` sobre handle valido nao-classe (record, enum) continua
      devolvendo vazio sem levantar — contrato preservado.
- [ ] `Scenario_NilHandle_AllMembers_Raises` ganha sexto bloco com
      `on E: EModernRTTIError` e assertiva de igualdade estrita da mensagem.
- [ ] Os cinco blocos existentes (Name, GetProperties, GetFields, GetMethods,
      GetMethod) usam `<>` + `'Mensagem de X incorreta: "%s"'` — nenhum `Pos`.
- [ ] Build FPC 3.2.2 x86_64 verde na fabrica (compila e roda sem falha).
- [ ] PR declara literalmente: "ciclo rodou FPC x86_64 no container. i386 e
      os 4 alvos Delphi nao foram executados nesta fabrica — ficam com o
      mantenedor antes do merge."

---

## 5. Restricoes (constraints)

- **CA-5** — Zero `{$IFDEF FPC}` em `UScenarios.RTTI.pas`; a guarda
  `if FType = nil` e Pascal puro, identico nos dois compiladores.
- **D-7** — "Um cenario, duas cascas": corpo em `UScenarios.RTTI.pas`,
  cascas finas em `Test FPC/.../UTestMS.RTTI.pas` e
  `Test Delphi/.../UTestMS.RTTI.pas`. O sexto bloco entra so no cenario
  compartilhado; as cascas existentes cobrem automaticamente.
- Construcao do handle nil sempre pelo **caminho publico**
  (`TModernRTTIContext.Create` + `FindType` de nome inexistente).
- `SModernRTTINilHandle` ja existe — nao ha string nova a adicionar.
- Fabrica: so FPC 3.2.2 x86_64 disponivel (`ppc386` ausente, `dcc32`
  ausente). Acceptance "dois compiladores × dois bitness" cobertura 1 de 4
  pelo ciclo; os 3 restantes ficam com o mantenedor.

---

## 6. Riscos

- **R-56.1** — Guarda inserida APOS o comentario `// Issue #27:` em vez
  de antes, quebrando a uniformidade com os outros cinco.
  **Mitigacao:** B-56.3 e plan §2 fixam a posicao como primeira instrucao
  visivel; acceptance verifica o comportamento resultante.
- **R-56.2** — Vazio legitimo de handle valido nao-classe colapsado
  inadvertidamente. **Mitigacao:** B-56.2 exige preservar o ramo
  `else Result := nil`; o ciclo prove mede o baseline.
- **R-56.3** — Assertivas uniformizadas trocam a mensagem do `Fail` mas
  introduzem erro de formato (ex.: nome do membro errado no `Format`).
  **Mitigacao:** acceptance verifica igualdade estrita da mensagem inteira.
- **R-56.4** — Declarar no PR que i386 ou Delphi foram provados quando a
  fabrica nao tem esses toolchains. **Mitigacao:** A-56.6 e decisao D-56.6
  (ADR) fixam o texto literal do PR.
