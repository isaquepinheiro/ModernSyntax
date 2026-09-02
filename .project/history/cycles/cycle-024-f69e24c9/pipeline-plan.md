---
type: plan
kind: artifact
title: "PLAN #62 — sete edições documentais em 4 arquivos, slice único"
description: "Slice único: sete pontos cirúrgicos em quatro arquivos (XMLDoc + comentários). Um commit, um PR. Verdict: fits."
cycle: 24
agent: architect
workflow: equipe-chore
node: architect
generated:
  by: equipe-chore@node:architect
  at: "2026-09-02T00:00:00Z"
tags: [cycle-024, issue-62, chore, documentation]
---

# PLAN — Issue #62: sete edições documentais

**Verdict: `fits`** — documentação pura, sete edições de comentário/XMLDoc em quatro
arquivos, nenhuma linha executável. Um commit, um PR.

- **Teste de tamanho:** sete substituições de texto. Custo real < $5. Não exaure o
  orçamento de implementação.
- **Teste de independência:** todas as sete edições compõem um único tema
  ("reconciliar documentação com realidade medida"). Entregar metade deixaria
  documentação interna contraditória — não são independentes e não devem ser separadas.

---

## Slice 1 — sete edições, um commit

### Ordem de execução (determinada para não recontar linhas)

**1. `Test Shared/EclbrSystem/UScenarios.RTTI.pas:145`**

Âncora de linha → âncora de texto. Sai **primeiro** para não depender de contagem
de linha das edições seguintes no mesmo arquivo.

- Localizar: `// cenario 10 da #46 (`TSetCor46 = set of TCor`, assercao em :1419-1422).`
  (ou trecho equivalente com `:1419-1422`)
- Substituir `:1419-1422` por `Scenario_SetType_ElementType`
- Resultado: ponteiro imune a crescimento do arquivo.

**2. `Test Shared/EclbrSystem/UScenarios.RTTI.pas:318-320`**

Comentário da declaração de `Scenario_NilHandle_AllMembers_Raises`:

- "cinco" → "seis"
- Acrescentar `Attributes` à lista dos membros
- "cita o nome do membro chamado" → "é exatamente `Format(SModernRTTINilHandle, [<membro>])`"

**3. `Test Shared/EclbrSystem/UScenarios.RTTI.pas:1452-1457`**

Cabeçalho do corpo do mesmo cenário — exatamente as mesmas duas correções do item 2.

**4. `Test Delphi/EclbrSystem/UTestMS.RTTI.pas:171`**

Âncora: frase inteira *"nos cinco membros afetados"* (nunca "cinco" solto — há dois
"cinco" na casca; `:97` é correto e não deve ser tocado).

- Substituir: "nos cinco membros afetados" → "nos seis membros afetados"

**5. `Test FPC/EclbrSystem/UTestMS.RTTI.pas:105`**

Idem ao item 4. Âncora pela mesma frase inteira. `:56` intacto.

**6. `Source/ModernSyntax.RTTI.pas:80-82`**

`<summary>` de `TModernVisibility` — substituir as três linhas pelo texto verbatim
da §1 da issue (com acentos, com "Ver #60." ao final). Não reencodar o arquivo —
encoding vigente é UTF-8 sem BOM.

**7. `Source/ModernSyntax.RTTI.pas:427-433`**

Inserir bloco `<remarks>` entre `</summary>` e `property Attributes`:

```
/// <remarks>Quando <c>IsNil = True</c>, levanta <c>EModernRTTIError</c>;
/// verifique <c>IsNil</c> antes de chamar.</remarks>
```

Cópia literal dos cinco irmãos. Sem mencionar `PropAttributes` nem `strict private`.

### PR body

Frase declarativa — **sem checklist**:

> Compilado em FPC 3.2.2 x86_64. i386 e os 4 alvos Delphi ficam com o mantenedor.

### O que não tocar (confirmado na consolidação)

- `case` de `PropertyVisibility` no backend FPC → **#60**
- Corpo do bloco `Attributes` em `:1550-1565` → já correto
- `raise` em `:1138` → já existe
- As duas published `TestNilHandle_AllMembers_Raises` → delegam com uma linha, sem mudança
- Comentários de `for..in` em `:97`/`:56` → corretos (#27)
- Encoding dos arquivos `.pas` → UTF-8 sem BOM, não reencodar
