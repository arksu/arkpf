library test;

uses
  Windows,
  SysUtils,
  pfHeader in '..\..\pfHeader.pas',
  plg_test in 'plg_test.pas';

procedure MyDLLProc(Reason: Integer);
begin
        if Reason = DLL_PROCESS_DETACH then dll_impl.free;
end;

function init(CoreObj : TCore) : TPluginDll; stdcall;
begin
  // инициализируем ядро
  pfHeader.CoreInit(CoreObj);
  // возвращаем ссылку на класс длл
  Result := dll_impl;
end;

//==============================================================================
exports
  init;

begin
  DLLProc := @MyDLLProc;
  dll_impl := TDLLImpl.create;
end.
