---
type: plan
kind: artifact
title: "PLAN — issue #56 em slice unico (Attributes nil-handle + uniformizacao do cenario)"
description: "Slice unico: guarda de nil em PropAttributes + uniformizacao dos cinco blocos de assert (Pos para igualdade estrita) + sexto bloco (Attributes) no cenario compartilhado. Dois arquivos, mudancas localizadas. Verdict: fits."
status: draft
cycle: "021"
agent: architect
workflow: equipe-bug
node: architect
resource: aefos://run/09743779c7c9860b5fa380f6979d94ca
tags: [plan, issue-56, nil-handle, modernrtti, rtti, fpc, bug]
generated:
  by: "equipe-bug@node:architect"
  at: "2026-09-02T15:40:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — issue #56"
  - id: adr
    resource: "adr.md"
    title: "ADR — issue #56"
---

# PLAN — Issue #56 (`Attributes` nil-handle + uniformizacao)

## Veredicto de escopo

**`fits` — slice unico.**

- **Teste 1 (tamanho):** implementacao inteira: 2-3 linhas inseridas em
  `Source/ModernSyntax.RTTI.pas` e ~28 linhas alteradas/inseridas em
  `Test Shared/EclbrSystem/UScenarios.RTTI.pas`. Nao chega perto do
  orçamento de implementacao; dois arquivos, zero novos tipos, zero novas
  strings.
- **Teste 2 (independencia):** os tres passos (guarda + uniformizacao +
  sexto bloco) dependem uns dos outros para fazer sentido — a guarda sem
  o sexto bloco deixa o cenario incompleto; o sexto bloco sem a guarda nao
  passa. Nao ha dois slices que possam ser mergeados independentemente.

Conclusao: e um pedaco de trabalho coeso, pequeno, dois arquivos. Um slice,
um ciclo.

---

## Slice 1 (unico) — Commit de guarda + uniformizacao + sexto bloco

**Arquivos:**
- `Source/ModernSyntax.RTTI.pas`
- `Test Shared/EclbrSystem/UScenarios.RTTI.pas`

**Passo 1 — `Source/ModernSyntax.RTTI.pas`, corpo de `PropAttributes` (linha 1124)**

Inserir antes do comentario `// Issue #27:` (linha 1126 atual):
```pascal
  if FType = nil then
    raise EModernRTTIError.CreateFmt(SModernRTTINilHandle, ['Attributes']);
```

O comentario `// Issue #27:` (linhas 1126-1128) desce para colar em
`if (FType is TRttiInstanceType)`. O ramo `else Result := nil`
permanece intacto (vazio legitimo para nao-classe).

Referencia: `SModernRTTINilHandle` existe em linhas 892-893; nenhuma
`resourcestring` nova.

**Passo 2 — `Test Shared/EclbrSystem/UScenarios.RTTI.pas`, uniformizacao**

Em cada um dos cinco blocos existentes, trocar as duas linhas de assert
(`if` + `Fail`):

| Bloco | Linha `if` | Linha `Fail` | `<nome>` |
|-------|-----------|-------------|---------|
| Name | 1461 | 1462 | `'Name'` |
| GetProperties | 1478 | 1479-1480 | `'GetProperties'` |
| GetFields | 1497 | 1498 | `'GetFields'` |
| GetMethods | 1514 | 1515-1516 | `'GetMethods'` |
| GetMethod | 1532 | 1533-1534 | `'GetMethod'` |

Padrao antes (Pos):
```pascal
if Pos('<nome>', LMsg) = 0 then
  Fail(Format('Mensagem de <nome> nao cita o membro chamado: "%s"', [LMsg]));
```

Padrao depois (igualdade estrita):
```pascal
if LMsg <> Format(SModernRTTINilHandle, ['<nome>']) then
  Fail(Format('Mensagem de <nome> incorreta: "%s"', [LMsg]));
```

**Passo 3 — `Test Shared/EclbrSystem/UScenarios.RTTI.pas`, sexto bloco**

Inserir apos linha 1534 (ultima linha do quinto bloco), antes do `end;`
em linha 1535:

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

**Verificacao — build e execucao FPC x86_64:**

```bash
rm -rf /tmp/fpcbuild && mkdir -p /tmp/fpcbuild
fpc -Mdelphi \
    -Fu"Source" -Fu"Test Shared/EclbrSystem" -Fu"Test FPC/EclbrSystem" \
    -FU/tmp/fpcbuild -FE/tmp/fpcbuild \
    "Test FPC/EclbrSystem/PTestRTTI.lpr"
/tmp/fpcbuild/PTestRTTI --all -a --format=plain
```

Esperado: verde (0 falhas). Confirmar que `Scenario_NilHandle_AllMembers_Raises`
passa com os seis membros.

**Verificacao do vazio legitimo (nao-regressao):**

O implementador verifica que `Attributes` sobre um handle valido de tipo
nao-classe (ex.: record) continua devolvendo vazio sem excecao. O baseline
medido na investigacao e `len=0, sem levantar` para record — esse
comportamento deve ser preservado.

**Commit — mensagem sugerida:**

```
fix(rtti): Attributes herda contrato de nil-handle da #49 (#56)

PropAttributes levantava EModernRTTIError ao FType = nil — mesmo
defeito que Name/GetProperties/GetFields/GetMethods/GetMethod exibiam
antes da #49. Adiciona guarda identica como primeira instrucao do corpo.
Uniformiza os seis blocos de assert em Scenario_NilHandle_AllMembers_Raises:
Pos(...) -> igualdade estrita + mensagem de Fail padrao unica.
Handle valido nao-classe continua devolvendo vazio sem excecao.
```

**Fronteira de verificacao declarada no PR (D-56.6):**

Secao propria (nao nota de rodape):

> *"Acceptance item 'dois compiladores × dois bitness': o ciclo cobre
> 1 de 4 (FPC x86_64). Os 3 restantes (FPC i386, Delphi Win32, Delphi
> Win64) exigem toolchain ausente da fabrica e ficam com o mantenedor.
> Padrao herdado da serie #43–#49."*
