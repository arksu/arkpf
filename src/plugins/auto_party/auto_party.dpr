library auto_party;

uses
  Windows,
  SysUtils,
  pfHeader in '..\..\pfHeader.pas',
  plg_auto_party in 'plg_auto_party.pas';

procedure MyDLLProc(Reason: Integer);
begin
        if Reason = DLL_PROCESS_DETACH then plugin_impl.free;
end;

function init(CoreObj : TCore) : TPluginDll; stdcall;
begin
  // инициализируем ядро
  pfHeader.CoreInit(CoreObj);
  // возвращаем ссылку на класс длл
  Result := plugin_impl;
end;

//==============================================================================
exports
  init;

begin
  DLLProc := @MyDLLProc;
  plugin_impl := TPluginImpl.create;
end.
