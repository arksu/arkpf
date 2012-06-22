unit uMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, JvSpin, IdBaseComponent, IdComponent, StdCtrls, Mask, JvExMask,
  IdCustomTCPServer, IdTCPServer, IdContext, IdMappedPortTCP, IdTCPConnection,
  IdSimpleServer, XPMan, Menus, JvMenus, ActnList, uL2GS_Connect, ComCtrls,
  JvExComCtrls, JvComCtrls, ExtCtrls, uGlobal, SyncObjs, IdGlobal, uPortForwarder;

type
  TfMain = class(TForm)
    XPManifest1: TXPManifest;
    MainMenu1: TMainMenu;
    Main1: TMenuItem;
    nExit: TMenuItem;
    nLog: TMenuItem;
    ActionList1: TActionList;
    nOptions: TMenuItem;
    nView: TMenuItem;
    nPlugins: TMenuItem;
    pcClientsConnection: TJvPageControl;
    timerUnused: TTimer;
    nFilter: TMenuItem;
    nLogpackets: TMenuItem;
    nReload: TMenuItem;
    EngineTimer: TTimer;
    nDisconnectAll: TMenuItem;
    procedure pf_GameServerConnect(AContext: TIdContext);
    procedure pf_GameServerOutboundData(AContext: TIdContext);
    procedure FormDestroy(Sender: TObject);
    procedure pf_GameServerDisconnect(AContext: TIdContext);
    procedure pf_GameServerExecute(AContext: TIdContext);
    procedure FormCreate(Sender: TObject);
    procedure nLogClick(Sender: TObject);
    procedure nOptionsClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure nPluginsClick(Sender: TObject);
    procedure timerUnusedTimer(Sender: TObject);
    procedure pcClientsConnectionChange(Sender: TObject);
    procedure nFilterClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure nLogpacketsClick(Sender: TObject);
    procedure nReloadClick(Sender: TObject);
    procedure EngineTimerTimer(Sender: TObject);
    procedure nExitClick(Sender: TObject);
    procedure nDisconnectAllClick(Sender: TObject);
  private
    procedure InitNetwork;
  protected
    procedure CreateParams (var Params : TCreateParams); override;
    procedure CallFunc(var msg: TMessage); Message WM_CALL_FUNC;

    procedure onClientPacket(var msg: TMessage); Message WM_CLIENT_PACKET;
    procedure onServerPacket(var msg: TMessage); Message WM_SERVER_PACKET;
    procedure onDisconnectGS(var msg: TMessage); Message WM_DISCONNECT_GS;
    procedure onConnectGS(var msg: TMessage); Message WM_CONNECT_GS;
  public
    pf_GameServer : TarkMappedPortTCP;
    procedure Init;
  end;

var
    fMain: TfMain;
    Connections : array of TL2GS_Connect;

function PluginCallFunc(struct : tCallFuncStruct) : Integer;

implementation

uses
    uLog, uOptions, uPlugins, uPacketVisual, IdSync, uFilterForm, pfHeader;

{$R *.dfm}

function PluginCallFunc(struct : tCallFuncStruct) : Integer;
begin
    Result := SendMessage(fMain.Handle, WM_CALL_FUNC, 0, Integer( @struct ) );
end;

procedure TfMain.CallFunc(var msg: TMessage);
var
    p : pCallFuncStruct;
    i : Integer;
    r : Integer;
begin
    p := Pointer(msg.LParam);

    for i := 0 to Plugins.Count - 1 do
        if (TPlugin(Plugins[i]).Name = p.plugin_name) and ( TPlugin(Plugins[i]).Loaded ) and
        ( (TPlugin(Plugins[i]).CharName = '') or ( (TPlugin(Plugins[i]).CharName <> '') and (Core.isConnectionExist(TPlugin(Plugins[i]).CharName)) ) )
        then
        begin
            r := TPlugin(Plugins[i]).DllImpl.CallFunction( p.a, p.Params );
            msg.Result := r;
            exit;
        end;

    msg.Result := 0;
end;

procedure TfMain.CreateParams(var Params: TCreateParams);
begin
  inherited;
  
  with Params do
    ExStyle := ExStyle OR WS_EX_APPWINDOW or WS_EX_CONTROLPARENT;
  Params.WinClassName := 'some_sss';
end;

procedure TfMain.EngineTimerTimer(Sender: TObject);
var
    i : Integer;
begin
        for i := 0 to Plugins.Count - 1 do begin
            if
            (  (TPlugin(Plugins[i]).CharName <> '') and
            (Core.isConnectionExist(TPlugin(Plugins[i]).CharName))  ) or
            (TPlugin(Plugins[i]).CharName = '')
            then
                TPlugin(Plugins[i]).onTimer( EngineTimer.Interval );
        end;
end;

procedure TfMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var
    c : TL2GS_Connect;
    cs : array of TL2GS_Connect;
    i : Integer;
begin
    timerUnused.Enabled := false;
    EngineTimer.Enabled := false;

    SetLength(cs, Length(Connections));
    for i := 0 to Length(Connections) - 1 do
        cs[i] := Connections[i];

    for c in cs do
        c.getContext.OutboundClient.Disconnect;

    GlobalDestroy := true;
    pf_GameServer.Active := false;
    Application.Terminate;
end;

procedure TfMain.FormCreate(Sender: TObject);
begin
    InitNetwork;

    LoadControlPosition(self);

    SysMsgIdList := TStringList.Create;
    ItemsList := TStringList.Create;
    NpcIdList := TStringList.Create;
    ClassIdList := TStringList.Create;
    SkillList := TStringList.Create;
    AugmentList := TStringList.Create;
    LoadIniFiles;

    EngineTimer.Interval := GlobalOptions.EngineTimerInterval;

    nLogpackets.Checked := GlobalOptions.PacketsLog;
end;

procedure TfMain.FormDestroy(Sender: TObject);
begin
    SaveControlPosition(Self);
end;

procedure TfMain.FormShow(Sender: TObject);
begin
    nLogClick(nil);
    nPluginsClick(nil);
end;

procedure TfMain.Init;
begin
    pf_GameServer.DefaultPort := GlobalOptions.GameServerLocalPort;
    pf_GameServer.MappedHost := GlobalOptions.GameServerHost;
    pf_GameServer.MappedPort := GlobalOptions.GameServerPort;
    pf_GameServer.Active := true;
    LogPrint('Game Server listener started');
end;

procedure TfMain.InitNetwork;
begin
    pf_GameServer := TarkMappedPortTCP.Create( fMain );
    pf_GameServer.OnConnect := fMain.pf_GameServerConnect;
    pf_GameServer.OnExecute := fMain.pf_GameServerExecute;
    pf_GameServer.OnOutboundData := fMain.pf_GameServerOutboundData;
    pf_GameServer.OnDisconnect := fMain.pf_GameServerDisconnect;
end;

procedure TfMain.nDisconnectAllClick(Sender: TObject);
var
    i : TL2GS_Connect;
begin
    for i in Connections do
        i.getContext.OutboundClient.Disconnect;
end;

procedure TfMain.nExitClick(Sender: TObject);
begin
    Close;
end;

procedure TfMain.nFilterClick(Sender: TObject);
begin
  if GetForegroundWindow = fPFilter.Handle then
    fPFilter.Hide
  else
    fPFilter.Show;
end;

procedure TfMain.nLogClick(Sender: TObject);
begin
  if GetForegroundWindow = fLog.Handle then
    fLog.Hide
  else
    fLog.Show;
end;

procedure TfMain.nLogpacketsClick(Sender: TObject);
begin
    nLogpackets.Checked := not nLogpackets.Checked;

    GlobalOptions.PacketsLog := nLogpackets.Checked;
    GlobalOptions.Save;
end;

procedure TfMain.nOptionsClick(Sender: TObject);
begin
  if GetForegroundWindow = fOptions.Handle then
    fOptions.Hide
  else
    fOptions.Show;
end;

procedure TfMain.nPluginsClick(Sender: TObject);
begin
  if GetForegroundWindow = fPlugins.Handle then
    fPlugins.Hide
  else
    fPlugins.Show;
end;

procedure TfMain.nReloadClick(Sender: TObject);
begin
    LoadIniFiles;
    fPFilter.LoadPacketsIni;
end;

procedure TfMain.onClientPacket(var msg: TMessage);
var
    c : TarkMappedPortContext;
    connect : TL2GS_Connect;
begin
    c := Pointer(msg.LParam);
    if GlobalOptions.FullPacketsLog then begin
        LogPrint('C ['+inttostr(c.Connection.Socket.Binding.Handle)+']'+
        'size: '+IntToStr(Length(c.NetData))+' ###################################################################');
    end;
    for connect in Connections do
        if connect.getContext = c then connect.HandlePacket(False);
end;

procedure TfMain.onConnectGS(var msg: TMessage);
var
    cname : string;
    cc : TL2GS_Connect;
    connect : TL2GS_Connect;
    c : TarkMappedPortContext;
begin
    c := Pointer(msg.LParam);
    cname := c.Connection.Socket.Binding.PeerIP+' : '+inttostr(c.Connection.Socket.Binding.PeerPort);
    LogPrint('connected '+cname+
    ' ['+inttostr(c.Connection.Socket.Binding.Handle)+']');


    for cc in Connections do
        if cc.GetName = cname then begin
            LogPrint('connect exist!');
            exit;
        end;

    // создаем и добавляем коннект
    SetLength(Connections, length(Connections)+1);
    connect := TL2GS_Connect.Create(c);
    Connections[High(Connections)] := connect;

    connect.Init;
end;

procedure TfMain.onDisconnectGS(var msg: TMessage);
var
    cname : string;
    i, j : Integer;
    c : TarkMappedPortContext;
begin
    c := Pointer(msg.LParam);
    cname := c.Connection.Socket.Binding.PeerIP+' : '+inttostr(c.Connection.Socket.Binding.PeerPort);
    LogPrint('disconnected '+c.Connection.Socket.Binding.PeerIP+' : '+inttostr(c.Connection.Socket.Binding.PeerPort)+
    ' ['+inttostr(c.Connection.Socket.Binding.Handle)+']');

    for i := 0 to Length(Connections) - 1 do
        if Connections[i].getContext = c then begin
            Connections[i].Finit;
            Connections[i].Free;
            for j := i to Length(Connections) - 2 do
                Connections[j] := Connections[j+1];
            SetLength(Connections, Length(Connections)-1);
            Break;
        end;
end;

procedure TfMain.onServerPacket(var msg: TMessage);
var
    c : TarkMappedPortContext;
    connect : TL2GS_Connect;
begin
    c := Pointer(msg.LParam);
    if GlobalOptions.FullPacketsLog then begin
        LogPrint('S ['+inttostr(c.Connection.Socket.Binding.Handle)+']'+
        'size: '+IntToStr(Length(c.NetData))+' ###################################################################');
    end;
    for connect in Connections do
        if connect.getContext = c then connect.HandlePacket(true);
end;

procedure TfMain.pcClientsConnectionChange(Sender: TObject);
begin
  if Assigned(pcClientsConnection.ActivePage) then
    if pcClientsConnection.ActivePage.ComponentCount > 0 then
    begin
      TfVisual(pcClientsConnection.ActivePage.Components[0]).show;
      TfVisual(pcClientsConnection.ActivePage.Components[0]).Repaint;
      TfVisual(pcClientsConnection.ActivePage.Components[0]).Invalidate;
    end;
end;

procedure TfMain.pf_GameServerConnect(AContext: TIdContext);
begin
    SendMessage( Handle, WM_CONNECT_GS, 0, Integer( AContext) );
end;

procedure TfMain.pf_GameServerDisconnect(AContext: TIdContext);
begin
    if GlobalDestroy then exit;
    SendMessage( Handle, WM_DISCONNECT_GS, 0, Integer( AContext) );

end;

procedure TfMain.pf_GameServerExecute(AContext: TIdContext);
var
    context : TarkMappedPortContext;
    b : TIdBytes;
begin
    SendMessage( Handle, WM_CLIENT_PACKET, 0, Integer( AContext) );
    context := (AContext as TarkMappedPortContext);
    SetLength(b, 0);
    context.NetData := b;
end;

procedure TfMain.pf_GameServerOutboundData(AContext: TIdContext);
var
    context : TarkMappedPortContext;
    b : TIdBytes;
begin
    SendMessage( Handle, WM_SERVER_PACKET, 0, Integer( AContext) );
    context := (AContext as TarkMappedPortContext);
    SetLength(b, 0);
    context.NetData := b;
end;

procedure TfMain.timerUnusedTimer(Sender: TObject);
begin
  if pcClientsConnection.Visible then
    if pcClientsConnection.ActivePage = nil then
      pcClientsConnection.Hide;
end;

end.
