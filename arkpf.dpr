program arkpf;

uses
  Forms,
  uMain in 'src\uMain.pas' {fMain},
  uLog in 'src\uLog.pas' {fLog},
  uGlobal in 'src\uGlobal.pas',
  uL2GS_Connect in 'src\uL2GS_Connect.pas',
  uConnect in 'src\uConnect.pas',
  uOptions in 'src\uOptions.pas' {fOptions},
  pfHeader in 'src\pfHeader.pas',
  uCore in 'src\uCore.pas',
  uEngine in 'src\uEngine.pas',
  uPlugins in 'src\uPlugins.pas' {fPlugins},
  uPacketVisual in 'src\uPacketVisual.pas' {fVisual: TFrame},
  uPacketView in 'src\uPacketView.pas' {fPView: TFrame},
  uFilterForm in 'src\uFilterForm.pas' {fPFilter},
  uMap in 'src\uMap.pas' {fMap},
  uPortForwarder in 'src\uPortForwarder.pas';

{$R *.res}

begin
  Core := TL2PFCoreImpl.Create;
  GlobalInit;

  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.ProcessMessages;
  Application.CreateForm(TfMain, fMain);
  Application.CreateForm(TfLog, fLog);
  Application.CreateForm(TfOptions, fOptions);
  Application.CreateForm(TfPlugins, fPlugins);
  Application.CreateForm(TfPFilter, fPFilter);
  Application.CreateForm(TfMap, fMap);
  fMain.Init;
  fPlugins.Init;
  fPFilter.LoadPacketsIni;


  Application.Run;
  GlobalFinit;
end.
