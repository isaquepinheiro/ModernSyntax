(*
  ------------------------------------------------------------------------------
  ModernSyntax.Invoker — Pilar 3 do ModernRTTI (issue #10)

  SPDX-License-Identifier: MIT
  Copyright (c) 2025-2026 Isaque Pinheiro

  Superficie publica: TModernInvoker (record) com dois overloads
    class function Invoke<TSignature>(TObject|TClass, string): TSignature;
  sobre TObject.MethodAddress.

  Por que esta unit e autocontida (`uses SysUtils;` apenas):
    Nenhuma das 16 units de Source/ compila hoje em FPC 3.2.2 (medido; ver
    .project/SKILL.md, "Two traps" #1). Importar qualquer uma contamina a
    compilacao com um defeito que nao tem nada a ver com o Invoker. Rtti e
    TypInfo nao sao necessarios: o mecanismo escolhido e MethodAddress,
    simbolo comum da RTL basica, com a mesma assinatura em Delphi e FPC
    3.2.2 (medido na volta 1 da investigacao da issue #10).

  Por que nao ha ramificacao por compilador nem inclusao do .inc do
  repositorio:
    TObject.MethodAddress e o mesmo simbolo nos dois compiladores; nao ha
    divergencia a acomodar. O include compartilhado do repositorio traz
    um bloco morto (ver ModernSyntax.inc linha ~256) que R3 do PRD proibe
    carregar.

  Limite explicito da guarda SizeOf:
    SizeOf(TSignature) = SizeOf(TMethod) e 16 no x86_64 e 8 no i386. A
    guarda pega o erro real (passar Integer, string, Boolean como
    TSignature) e transforma corrupcao silenciosa de memoria em excecao
    alta. Ela NAO distingue "metodo-de-objeto" de "outro tipo qualquer com
    o mesmo tamanho de TMethod" — dois records de mesmo SizeOf passariam.
    Custo aceito; teste Case_Invoke_NonMethodSignature_Raises fixa o
    comportamento visivel.

  Por que o corpo do generico so toca TMethod (nao tipo local desta unit):
    A armadilha "Global Generic template references static symtable" (Free
    Pascal 3.2.2, medida no PR #12 do ciclo #7) dispara quando o corpo de um
    generico instancia um tipo declarado na implementation. Aqui o corpo
    so instancia TMethod, tipo da RTL declarado em System. Se um mantenedor
    precisar auxiliar a implementacao com um tipo local, esse tipo tem de
    nascer na interface ou o corpo do generico nao pode instancia-lo.

  Contrato tipado (custo estrutural de mecanismo unico):
    MethodAddress devolve ponteiro, nao metadado. Consumidor declara
    `type TFn = function(...) : T of object;` antes de invocar, e recebe
    o metodo ja tipado. Nao existe `Invoke(obj, 'Nome', [args]): TValue`
    nesta entrega — no FPC 3.2.2 nao ha de onde ler os tipos dos
    parametros para montar a chamada (GetMethods = 0 para qualquer classe,
    medido). Divergencia silenciosa em runtime seria o defeito n.1 do PRD;
    divergencia declarada por compilacao fica para issue irma.
  ------------------------------------------------------------------------------
*)

unit ModernSyntax.Invoker;

interface

uses
  SysUtils;

type
  TModernInvoker = record
  public
    class function Invoke<TSignature>(const AInstance: TObject;
      const AMethodName: string): TSignature; overload; static;
    class function Invoke<TSignature>(const AClass: TClass;
      const AMethodName: string): TSignature; overload; static;
  end;

implementation

class function TModernInvoker.Invoke<TSignature>(const AInstance: TObject;
  const AMethodName: string): TSignature;
var
  addr: Pointer;
  m: TMethod;
begin
  if SizeOf(TSignature) <> SizeOf(TMethod) then
    raise Exception.Create('TSignature nao e um tipo de metodo-de-objeto');
  if AInstance = nil then
    raise Exception.Create('AInstance e nil');
  addr := AInstance.MethodAddress(AMethodName);
  if addr = nil then
    raise Exception.CreateFmt(
      'metodo "%s" nao encontrado em %s; no FPC isso exige {$M+} e secao published',
      [AMethodName, AInstance.ClassName]);
  m.Code := addr;
  m.Data := AInstance;
  Move(m, Result, SizeOf(TMethod));
end;

class function TModernInvoker.Invoke<TSignature>(const AClass: TClass;
  const AMethodName: string): TSignature;
var
  addr: Pointer;
  m: TMethod;
begin
  if SizeOf(TSignature) <> SizeOf(TMethod) then
    raise Exception.Create('TSignature nao e um tipo de metodo-de-objeto');
  if AClass = nil then
    raise Exception.Create('AClass e nil');
  addr := AClass.MethodAddress(AMethodName);
  if addr = nil then
    raise Exception.CreateFmt(
      'metodo "%s" nao encontrado em %s; no FPC isso exige {$M+} e secao published',
      [AMethodName, AClass.ClassName]);
  m.Code := addr;
  m.Data := Pointer(AClass);
  Move(m, Result, SizeOf(TMethod));
end;

end.
