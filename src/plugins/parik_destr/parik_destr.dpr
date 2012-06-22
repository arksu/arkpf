library parik_destr;

uses
  SysUtils,
  Windows,
  pfHeader in '..\..\pfHeader.pas',
  plg_parik_destr in 'plg_parik_destr.pas',
  ark_bots in '..\ark_bots.pas',
  l2_utils in '..\l2_utils.pas';

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
