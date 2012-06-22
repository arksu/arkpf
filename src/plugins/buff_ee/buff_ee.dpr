library buff_ee;

uses
  SysUtils,
  Windows,
  pfHeader in '..\..\pfHeader.pas',
  plg_buff_ee in 'plg_buff_ee.pas',
  buffer in '..\buffer.pas',
  ark_bots in '..\ark_bots.pas';

procedure MyDLLProc(Reason: Integer);
begin
        if Reason = DLL_PROCESS_DETACH then plugin_impl.free;
end;

function init(CoreObj : TCore) : TPluginDll; stdcall;
begin
  // �������������� ����
  pfHeader.CoreInit(CoreObj);
  // ���������� ������ �� ����� ���
  Result := plugin_impl;
end;

//==============================================================================
exports
  init;

begin
  DLLProc := @MyDLLProc;
  plugin_impl := TPluginImpl.create;
end.
