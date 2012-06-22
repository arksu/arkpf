unit uPortForwarder;

{
    idMappedPortTCP remake by arksu
}

interface

{$i IdCompilerDefines.inc}

uses
  Classes,
  IdAssignedNumbers,
  IdContext,
  IdCustomTCPServer,
  IdGlobal, IdStack, IdTCPConnection, IdTCPServer, IdYarn, SysUtils;

type
  TarkMappedPortTCP = class;

  TarkMappedPortContext = class(TIdServerContext)
  protected
    FOutboundClient: TIdTCPConnection;//was TIdTCPClient
    FReadList: TIdSocketList;
    FDataAvailList: TIdSocketList;
    FConnectTimeOut: Integer;
    FNetData: TIdBytes;
    FServer : TarkMappedPortTCP;
    //
    procedure CheckForData(DoRead: Boolean); virtual;
    procedure HandleLocalClientData; virtual;
    procedure HandleOutboundClientData; virtual;
    procedure OutboundConnect; virtual;
  public
    constructor Create(
      AConnection: TIdTCPConnection;
      AYarn: TIdYarn;
      AList: TThreadList = nil
      ); override;
    destructor Destroy; override;
    //
    property  Server : TarkMappedPortTCP Read FServer write FServer;
    property  ConnectTimeOut: Integer read FConnectTimeOut write FConnectTimeOut default IdTimeoutDefault;
    property  NetData: TIdBytes read FNetData write FNetData;
    property  OutboundClient: TIdTCPConnection read FOutboundClient write FOutboundClient;
  end;//TarkMappedPortContext

  TarkMappedPortTCP = class(TIdCustomTCPServer)
  protected
    FMappedHost: string;
    FMappedPort: TIdPort;
    FOnBeforeConnect: TIdServerThreadEvent;

    //AThread.Connection.Server & AThread.OutboundClient
    FOnOutboundConnect: TIdServerThreadEvent;
    FOnOutboundData: TIdServerThreadEvent;
    FOnOutboundDisConnect: TIdServerThreadEvent;
    //
    procedure ContextCreated(AContext:TIdContext); override;
    procedure DoBeforeConnect(AContext: TIdContext); virtual;
    procedure DoConnect(AContext: TIdContext); override;
    function  DoExecute(AContext: TIdContext): boolean; override;
    procedure DoDisconnect(AContext: TIdContext); override; //DoLocalClientDisconnect
    procedure DoLocalClientConnect(AContext: TIdContext); virtual;
    procedure DoLocalClientData(AContext: TIdContext); virtual;//APR: bServer

    procedure DoOutboundClientConnect(AContext: TIdContext); virtual;
    procedure DoOutboundClientData(AContext: TIdContext); virtual;
    procedure DoOutboundDisconnect(AContext: TIdContext); virtual;
    function  GetOnConnect: TIdServerThreadEvent;
    function  GetOnExecute: TIdServerThreadEvent;
    procedure SetOnConnect(const Value: TIdServerThreadEvent);
    procedure SetOnExecute(const Value: TIdServerThreadEvent);
    function  GetOnDisconnect: TIdServerThreadEvent;
    procedure SetOnDisconnect(const Value: TIdServerThreadEvent);
    procedure InitComponent; override;
  published
    property  OnBeforeConnect: TIdServerThreadEvent read FOnBeforeConnect write FOnBeforeConnect;
    property  MappedHost: String read FMappedHost write FMappedHost;
    property  MappedPort: TIdPort read FMappedPort write FMappedPort;
    //
    property  OnConnect: TIdServerThreadEvent read GetOnConnect write SetOnConnect; //OnLocalClientConnect
    property  OnOutboundConnect: TIdServerThreadEvent read FOnOutboundConnect write FOnOutboundConnect;

    property  OnExecute: TIdServerThreadEvent read GetOnExecute write SetOnExecute;//OnLocalClientData
    property  OnOutboundData: TIdServerThreadEvent read FOnOutboundData write FOnOutboundData;

    property  OnDisconnect: TIdServerThreadEvent read GetOnDisconnect write SetOnDisconnect;//OnLocalClientDisconnect
    property  OnOutboundDisconnect: TIdServerThreadEvent read FOnOutboundDisconnect write FOnOutboundDisconnect;
  End;//TarkMappedPortTCP

Implementation

uses
  IdException,
  IdIOHandler, IdIOHandlerSocket, IdResourceStrings,IdStackConsts, IdTCPClient;

procedure TarkMappedPortTCP.InitComponent;
begin
  inherited InitComponent;
  FContextClass := TarkMappedPortContext;
end;

procedure TarkMappedPortTCP.ContextCreated(AContext: TIdContext);
begin
  TarkMappedPortContext(AContext).Server := Self;
end;

procedure TarkMappedPortTCP.DoBeforeConnect(AContext: TIdContext);
begin
  if Assigned(FOnBeforeConnect) then begin
    FOnBeforeConnect(AContext);
  end;
end;

procedure TarkMappedPortTCP.DoLocalClientConnect(AContext: TIdContext);
begin
  if Assigned(FOnConnect) then begin
    FOnConnect(AContext);
  end;
end;

procedure TarkMappedPortTCP.DoOutboundClientConnect(AContext: TIdContext);
begin
  if Assigned(FOnOutboundConnect) then begin
    FOnOutboundConnect(AContext);
  end;
end;

procedure TarkMappedPortTCP.DoLocalClientData(AContext: TIdContext);
begin
  if Assigned(FOnExecute) then begin
    FOnExecute(AContext);
  end;
end;

procedure TarkMappedPortTCP.DoOutboundClientData(AContext: TIdContext);
begin
  if Assigned(FOnOutboundData) then begin
    FOnOutboundData(AContext);
  end;
end;

procedure TarkMappedPortTCP.DoDisconnect(AContext: TIdContext);
begin
  inherited DoDisconnect(AContext);
  //check for loop
  if Assigned(TarkMappedPortContext(AContext).FOutboundClient) and
    TarkMappedPortContext(AContext).FOutboundClient.Connected then
  begin
    TarkMappedPortContext(AContext).FOutboundClient.Disconnect;
  end;
end;

procedure TarkMappedPortTCP.DoOutboundDisconnect(AContext: TIdContext);
begin
  if Assigned(FOnOutboundDisconnect) then begin
    FOnOutboundDisconnect(AContext);
  end;
  AContext.Connection.Disconnect; //disconnect local
end;

procedure TarkMappedPortTCP.DoConnect(AContext: TIdContext);
begin
  DoBeforeConnect(AContext);

  //WARNING: Check TIdTCPServer.DoConnect and synchronize code. Don't call inherited!=> OnConnect in OutboundConnect    {Do not Localize}
  TarkMappedPortContext(AContext).OutboundConnect;

  //cache
  with TarkMappedPortContext(AContext).FReadList do begin
    Clear;
    Add(AContext.Connection.Socket.Binding.Handle);
    Add(TarkMappedPortContext(AContext).FOutboundClient.Socket.Binding.Handle);
  end;
end;

function TarkMappedPortTCP.DoExecute(AContext: TIdContext): Boolean;
begin
  with TarkMappedPortContext(AContext) do begin
    try
      CheckForData(True);
    finally
      if not FOutboundClient.Connected then begin
        Result := False;
        DoOutboundDisconnect(AContext); //&Connection.Disconnect
      end else begin;
        Result := AContext.Connection.Connected;
      end;
    end;
  end;
end;

function TarkMappedPortTCP.GetOnConnect: TIdServerThreadEvent;
begin
  Result := FOnConnect;
end;

function TarkMappedPortTCP.GetOnExecute: TIdServerThreadEvent;
begin
  Result := FOnExecute;
end;

function TarkMappedPortTCP.GetOnDisconnect: TIdServerThreadEvent;
begin
  Result := FOnDisconnect;
end;

procedure TarkMappedPortTCP.SetOnConnect(const Value: TIdServerThreadEvent);
begin
  FOnConnect := Value;
end;

procedure TarkMappedPortTCP.SetOnExecute(const Value: TIdServerThreadEvent);
begin
  FOnExecute := Value;
end;

procedure TarkMappedPortTCP.SetOnDisconnect(const Value: TIdServerThreadEvent);
begin
  FOnDisconnect := Value;
end;


{ TarkMappedPortContext }

constructor TarkMappedPortContext.Create(
  AConnection: TIdTCPConnection;
  AYarn: TIdYarn;
  AList: TThreadList = nil
  );
begin
  inherited Create(AConnection, AYarn, AList);
  FReadList := TIdSocketList.CreateSocketList;
  FDataAvailList := TIdSocketList.CreateSocketList;
  FConnectTimeOut := IdTimeoutDefault;
end;

destructor TarkMappedPortContext.Destroy;
begin
  FreeAndNil(FOutboundClient);
  FreeAndNIL(FReadList);
  FreeAndNIL(FDataAvailList);
  inherited Destroy;
end;

procedure TarkMappedPortContext.CheckForData(DoRead: Boolean);
begin
  if DoRead then
  begin
    if FReadList.SelectReadList(FDataAvailList, IdTimeoutInfinite) then
    begin
      //1.LConnectionHandle
      if FDataAvailList.ContainsSocket(Connection.Socket.Binding.Handle) then
      begin
        // TODO: WSAECONNRESET (Exception [EIdSocketError] Socket Error # 10054 Connection reset by peer)
        Connection.IOHandler.CheckForDataOnSource(0);
      end;
      //2.LOutBoundHandle
      if FDataAvailList.ContainsSocket(FOutboundClient.Socket.Binding.Handle) then
      begin
        FOutboundClient.IOHandler.CheckForDataOnSource(0);
      end;
    end;        
  end;
  if not Connection.IOHandler.InputBufferIsEmpty then
  begin
    HandleLocalClientData;
  end;
  if not FOutboundClient.IOHandler.InputBufferIsEmpty then
  begin
    HandleOutboundClientData;
  end;
end;

procedure TarkMappedPortContext.HandleLocalClientData;
begin
  SetLength(FNetData, 0);
  Connection.IOHandler.InputBuffer.ExtractToBytes(FNetData);
  Server.DoLocalClientData(Self);
  FOutboundClient.IOHandler.Write(FNetData);
end;

procedure TarkMappedPortContext.HandleOutboundClientData;
begin
  SetLength(FNetData, 0);
  FOutboundClient.IOHandler.InputBuffer.ExtractToBytes(FNetData);
  Server.DoOutboundClientData(Self);
  Connection.IOHandler.Write(FNetData);
end;

procedure TarkMappedPortContext.OutboundConnect;
begin
  FOutboundClient := TIdTCPClient.Create(nil);
  with TarkMappedPortTCP(Server) do
  begin
    try
      with TIdTcpClient(FOutboundClient) do
      begin
        Port := MappedPort;
        Host := MappedHost;
      end;
      DoLocalClientConnect(Self);

      with TIdTcpClient(FOutboundClient) do
      begin
        ConnectTimeout := Self.FConnectTimeOut;
        Connect;
      end;
      DoOutboundClientConnect(Self);

      //APR: buffer can contain data from prev (users) read op.
      CheckForData(False);
    except
      on E: Exception do
      begin
        Self.DoException(E);// DONE: Handle connect failures
        Connection.Disconnect; //req IdTcpServer with "Stop this thread if we were disconnected"
        raise;
      end;
    end;
  end;
end;

end.
