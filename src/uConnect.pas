unit uConnect;

interface

uses
    SysUtils, IdMappedPortTCP, pfHeader, IdGlobal, uPortForwarder;

type
    TConnect = class
    private
        fname : string;
        fsocket_id : Integer;
        fbufServer : AnsiString;
        fbufClient : AnsiString;
        fContext : TarkMappedPortContext;
    protected
        fPacketsCount : Integer;
        // ������� �����
        Packet : TPacket;
        // ����������� ���������� ������� � ������ ������������ (��� ��� ��������)
        procedure OnPacket(FromServer : Boolean); virtual; abstract;
        procedure Decode(FromServer : Boolean); virtual; abstract;
        procedure Encode(FromServer : Boolean); virtual; abstract;

    public
        procedure Init; virtual;
        constructor Create(context : TarkMappedPortContext);

        // �������� ����� �� ������
        procedure HandlePacket(FromServer : Boolean);

        // ������ ������� ������ � ����� (��� ����� �����)
        procedure SendToServer(p : AnsiString);
        procedure SendToClient(p : AnsiString);

        // ��� ��������
        function getName : string;
        // �� ������
        function getSocketID : Integer;
        // ��������
        function getContext : TarkMappedPortContext;
        // ���������� ��������� �������
        function getPacketCount: Integer;   
        
    end;

implementation

uses
    uGlobal, uLog;

{ TConnect }

constructor TConnect.Create(context : TarkMappedPortContext);
begin
    fname := context.Connection.Socket.Binding.PeerIP+' : '+inttostr(context.Connection.Socket.Binding.PeerPort);
    fsocket_id := context.Connection.Socket.Binding.Handle;
    fbufServer := '';
    fbufClient := '';
    fContext := context;
    fPacketsCount := 0;
end;

function TConnect.getContext: TarkMappedPortContext;
begin
    Result := fContext;
end;

function TConnect.GetName: string;
begin
    Result := fname;
end;

function TConnect.getPacketCount: Integer;
begin
    Result := fPacketsCount;
end;

function TConnect.GetSocketID: Integer;
begin
    Result := fsocket_id;
end;

procedure TConnect.HandlePacket(FromServer : Boolean);
var
    len : word;
    net : AnsiString;
begin
    net := StringFromBytes( fContext.NetData );
    if FromServer then begin
        // ��������� ������ � �����
        fbufServer := fbufServer + net;
        // ���� � ������ ���� ������
        while (Length(fbufServer) >= 2) do begin
            // �������� �����
            Move(fbufServer[1], len, 2);
            if GlobalOptions.FullPacketsLog then LogPrint('pck len='+inttostr(len));
            // ���� ����� ���� � ������
            if (len <= Length(fbufServer)) then begin
                // ������ �����
                SetLength(Packet.data, len-2);
                Move(fbufServer[3], Packet.data[1], len-2);

                // ������� ����� �� ������
                Delete(fbufServer, 1, len);
                Inc(fPacketsCount);

                // ���������� �����
                Decode(FromServer);
                // ������������
                OnPacket(FromServer);

                // ���� ����� ��� ���� � ������ - �������� � ����
                if Packet.Size > 0 then begin
                    Encode(FromServer);

                    // ��������� ����� �� ��������
                    SendToClient(Packet.data);
                end;

            end else Break;
        end;
    end else begin
        // ��������� ������ � �����
        fbufClient := fbufClient + net;
        // ���� � ������ ���� ������
        while (Length(fbufClient) >= 2) do begin
            // �������� �����
            Move(fbufClient[1], len, 2);
            if GlobalOptions.FullPacketsLog then LogPrint('pck len='+inttostr(len));
            // ���� ����� ���� � ������
            if (len <= Length(fbufClient)) then begin
                // ������ �����
                SetLength(Packet.data, len-2);
                Move(fbufClient[3], Packet.data[1], len-2);

                // ������� ����� �� ������
                Delete(fbufClient, 1, len);
                Inc(fPacketsCount);

                // ���������� �����
                Decode(FromServer);
                // ������������
                OnPacket(FromServer);

                // ���� ����� ��� ���� � ������ - �������� � ����
                if Packet.Size > 0 then begin
                    Encode(FromServer);

                    // ��������� ����� �� ��������
                    SendToServer(Packet.data);
                end;

            end else Break;
        end;   
    end;
end;

procedure TConnect.Init;
begin
end;

procedure TConnect.SendToClient(p: AnsiString);
var
    tmp : AnsiString;
    h : word;
begin
    // ��������� ����� ������
    SetLength(tmp, 2);
    h := Length(p)+2;
    Move(h, tmp[1], 2);


    fContext.Connection.IOHandler.Write( StringToBytes(tmp+p) );
end;

procedure TConnect.SendToServer(p: AnsiString);
var
    tmp : string;
    h : word;
begin
    // ��������� ����� ������
    SetLength(tmp, 2);
    h := Length(p)+2;
    Move(h, tmp[1], 2);

    fContext.OutboundClient.IOHandler.Write( StringToBytes(tmp+p) );
end;

end.
