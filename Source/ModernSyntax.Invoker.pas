(*
  ------------------------------------------------------------------------------
  ModernSyntax.Invoker — Pilar 3 do ModernRTTI (issues #10 + #13)

  SPDX-License-Identifier: MIT
  Copyright (c) 2025-2026 Isaque Pinheiro

  Superficie publica: TModernInvoker (record) com DUAS superficies:

    1. Invoke<TSignature>(TObject|TClass, string): TSignature — portavel,
       sobre TObject.MethodAddress. Nucleo entregue pela #10; comportamento
       identico em Delphi e FPC 3.2.2, medido.

    2. Invoke(TObject, string, array of TValue, PTypeInfo): TValue —
       dinamico, assinatura identica cross-compiler, mecanismo divergente:
       * Delphi: TRttiContext.GetType(...).GetMethod(...).Invoke(AInstance, AArgs)
       * FPC 3.2.2: TObject.MethodAddress + Rtti.Invoke livre (rtti.pp:583)
       Alcance: public + published no Delphi; published apenas no FPC.
       Assimetria deliberada (cada compilador entrega o que pode); testes
       Case_InvokeDynamic_PublicWithoutMPlus_{RaisesOnFPC,OKOnDelphi} fixam.

  Limite explicito da guarda SizeOf (overload portavel):
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

  FRONTEIRA POR ALVO — Rtti.Invoke livre depende de SystemInvoke em
  assembly (packages/rtl-objpas/src/<arch>/invoke.inc). No FPC 3.2.2
  esse assembly SO existe para Windows (x86_64-win64, i386-win32). Em
  outros alvos (ex.: x86_64-linux, SysV AMD64), o fallback levanta
  ENotImplemented com SErrInvokeNotImplemented literal
  (rtti.pp:583 + packages/rtl-objpas/src/<arch>/invoke.inc). Nao
  mascaramos; o XMLDoc da declaracao publica documenta as tres classes
  de alvo, e os testes de retorno de valor ramificam com
  {$IF defined(FPC) and defined(CPUX86_64) and defined(UNIX)}.

  Fronteira metodica (todos os alvos): ccReg apenas; construtor levanta
  ENotImplemented na RTL do FPC (rtti.pp:2334, marcado como TODO pelo
  proprio compilador); record grande por referencia oculta nao coberto.
  ------------------------------------------------------------------------------
*)

unit ModernSyntax.Invoker;

interface

uses
  SysUtils,
  TypInfo,
  Rtti;

type
  TModernInvoker = record
  public
    class function Invoke<TSignature>(const AInstance: TObject;
      const AMethodName: string): TSignature; overload; static;
    class function Invoke<TSignature>(const AClass: TClass;
      const AMethodName: string): TSignature; overload; static;
    /// <summary>
    ///   Invoca dinamicamente <c>AMethodName</c> em <c>AInstance</c>,
    ///   passando <c>AArgs</c> como argumentos e retornando o valor
    ///   como <c>TValue</c>. Assinatura identica nos dois compiladores;
    ///   mecanismo e fronteira de execucao dependem do ALVO.
    /// </summary>
    /// <remarks>
    ///   Alcance por compilador:
    ///   - Delphi: <c>public</c> + <c>published</c>, via
    ///     <c>TRttiContext.GetType(AInstance.ClassType).GetMethod(AName)</c>.
    ///   - FPC 3.2.2: <c>published</c> apenas, via
    ///     <c>TObject.MethodAddress(AName)</c> + <c>Rtti.Invoke</c>
    ///     livre (<c>rtti.pp:583</c>).
    ///
    ///   Fronteira POR ALVO (o overload nao promete alem disso):
    ///   - Delphi (Win32/Win64/Linux/etc): invocacao viva; alcance
    ///     <c>public</c> + <c>published</c>.
    ///   - FPC 3.2.2 Windows (Win32/Win64): invocacao viva via
    ///     <c>SystemInvoke</c> em assembly
    ///     (<c>packages/rtl-objpas/src/x86_64/invoke.inc</c> e
    ///     <c>i386/invoke.inc</c>); alcance <c>published</c>.
    ///   - FPC 3.2.2 outros alvos (ex.: <c>x86_64-linux</c>, SysV AMD64):
    ///     <c>SystemInvoke</c> AUSENTE na RTL; qualquer chamada real
    ///     propaga <c>ENotImplemented</c> com mensagem literal da RTL
    ///     (<c>Invoke functionality is not implemented</c>,
    ///     <c>SErrInvokeNotImplemented</c>). Limite da RTL, nao escolha
    ///     desta unit — nao mascaramos, nao re-embrulhamos.
    ///
    ///   Fronteira metodica (todos os alvos):
    ///   - Convencao de chamada: <c>ccReg</c> apenas. Metodos
    ///     <c>stdcall</c>, <c>cdecl</c> ou <c>pascal</c> nao sao
    ///     cobertos.
    ///   - Construtor: chamar construtor via este overload levanta
    ///     <c>ENotImplemented</c> no FPC (limite da RTL,
    ///     <c>rtti.pp:2334</c>, marcado como TODO pelo proprio
    ///     compilador).
    ///   - Record grande passado por referencia oculta (ABI-dependente):
    ///     nao coberto.
    ///
    ///   Em metodo <c>public</c> nao-<c>published</c>, o FPC levanta
    ///   com a mensagem instrutiva reusada do overload portavel (cita
    ///   <c>{$M+}</c> e <c>published</c>). Assimetria deliberada — cada
    ///   compilador entrega o que pode.
    /// </remarks>
    class function Invoke(const AInstance: TObject; const AMethodName: string;
      const AArgs: array of TValue;
      const AResultType: PTypeInfo = nil): TValue; overload; static;
  end;

implementation

class function TModernInvoker.Invoke<TSignature>(const AInstance: TObject;
  const AMethodName: string): TSignature;
var
  LAddress: Pointer;
  LMethod: TMethod;
begin
  if SizeOf(TSignature) <> SizeOf(TMethod) then
    raise Exception.Create('TSignature nao e um tipo de metodo-de-objeto');
  if AInstance = nil then
    raise Exception.Create('AInstance e nil');
  LAddress := AInstance.MethodAddress(AMethodName);
  if LAddress = nil then
    raise Exception.CreateFmt(
      'metodo "%s" nao encontrado em %s; no FPC isso exige {$M+} e secao published',
      [AMethodName, AInstance.ClassName]);
  LMethod.Code := LAddress;
  LMethod.Data := AInstance;
  Move(LMethod, Result, SizeOf(TMethod));
end;

class function TModernInvoker.Invoke<TSignature>(const AClass: TClass;
  const AMethodName: string): TSignature;
var
  LAddress: Pointer;
  LMethod: TMethod;
begin
  if SizeOf(TSignature) <> SizeOf(TMethod) then
    raise Exception.Create('TSignature nao e um tipo de metodo-de-objeto');
  if AClass = nil then
    raise Exception.Create('AClass e nil');
  LAddress := AClass.MethodAddress(AMethodName);
  if LAddress = nil then
    raise Exception.CreateFmt(
      'metodo "%s" nao encontrado em %s; no FPC isso exige {$M+} e secao published',
      [AMethodName, AClass.ClassName]);
  LMethod.Code := LAddress;
  LMethod.Data := Pointer(AClass);
  Move(LMethod, Result, SizeOf(TMethod));
end;

class function TModernInvoker.Invoke(const AInstance: TObject;
  const AMethodName: string; const AArgs: array of TValue;
  const AResultType: PTypeInfo): TValue;
{$IFDEF FPC}
var
  LAddress: CodePointer;
  LArgs: TValueArray;
  I: Integer;
begin
  if AInstance = nil then
    raise Exception.Create('AInstance e nil');
  LAddress := AInstance.MethodAddress(AMethodName);
  if LAddress = nil then
    raise Exception.CreateFmt(
      'metodo "%s" nao encontrado em %s; no FPC isso exige {$M+} e secao published',
      [AMethodName, AInstance.ClassName]);
  SetLength(LArgs, Length(AArgs) + 1);
  LArgs[0] := TValue.From<TObject>(AInstance);
  for I := 0 to High(AArgs) do
    LArgs[I + 1] := AArgs[I];
  // Rtti.Invoke qualificado — evita colisao com o metodo estatico local.
  // Em alvo sem SystemInvoke (ex.: x86_64-linux), esta linha propaga
  // ENotImplemented (SErrInvokeNotImplemented) da propria RTL. NAO
  // mascarar (D-13.2 / D-29.1).
  Result := Rtti.Invoke(LAddress, LArgs, ccReg, AResultType, False, False);
end;
{$ELSE}
var
  LCtx: TRttiContext;
  LType: TRttiType;
  LMethod: TRttiMethod;
begin
  if AInstance = nil then
    raise Exception.Create('AInstance e nil');
  LCtx := TRttiContext.Create;
  try
    LType := LCtx.GetType(AInstance.ClassType);
    LMethod := LType.GetMethod(AMethodName);
    if LMethod = nil then
      raise Exception.CreateFmt(
        'metodo "%s" nao encontrado em %s; no FPC isso exige {$M+} e secao published',
        [AMethodName, AInstance.ClassName]);
    // Materializa Result DENTRO do try (D-13.4): TValue copia o
    // conteudo e sobrevive ao .Free do contexto; TRttiMethod nao.
    // AResultType ignorado no Delphi — LMethod carrega o tipo de
    // retorno. Parametro existe por paridade de assinatura (D-13.1) e
    // porque o FPC precisa dele.
    Result := LMethod.Invoke(AInstance, AArgs);
  finally
    LCtx.Free;
  end;
end;
{$ENDIF}

end.
