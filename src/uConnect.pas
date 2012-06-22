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
        // текущий пакет
        Packet : TPacket;
        // обработчики полученных пакетов с учетом фрагментации (тут уже склееные)
        procedure OnPacket(FromServer : Boolean); virtual; abstract;
        procedure Decode(FromServer : Boolean); virtual; abstract;
        procedure Encode(FromServer : Boolean); virtual; abstract;

    public
        procedure Init; virtual;
        constructor Create(context : TarkMappedPortContext);

        // получаем пакет из сокета
        procedure HandlePacket(FromServer : Boolean);

        // прямая отсылка данных в сокет (без учета длины)
        procedure SendToServer(p : AnsiString);
        procedure SendToClient(p : AnsiString);

        // имя коннекта
        function getName : string;
        // ид сокета
        function getSocketID : Integer;
        // контекст
        function getContext : TarkMappedPortContext;
        // количество прошедших пакетов
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
        // добавляем данные в буфер
        fbufServer := fbufServer + net;
        // пока в буфере есть данные
        while (Length(fbufServer) >= 2) do begin
            // получаем длину
            Move(fbufServer[1], len, 2);
            if GlobalOptions.FullPacketsLog then LogPrint('pck len='+inttostr(len));
            // если пакет весь в буфере
            if (len <= Length(fbufServer)) then begin
                // читаем пакет
                SetLength(Packet.data, len-2);
                Move(fbufServer[3], Packet.data[1], len-2);

                // удаляем пакет из буфера
                Delete(fbufServer, 1, len);
                Inc(fPacketsCount);

                // декодируем пакет
                Decode(FromServer);
                // обрабатываем
                OnPacket(FromServer);

                // если чтото еще есть в пакете - отсылаем в сеть
                if Packet.Size > 0 then begin
                    Encode(FromServer);

                    // формируем пакет на отправку
                    SendToClient(Packet.data);
                end;

            end else Break;
        end;
    end else begin
        // добавляем данные в буфер
        fbufClient := fbufClient + net;
        // пока в буфере есть данные
        while (Length(fbufClient) >= 2) do begin
            // получаем длину
            Move(fbufClient[1], len, 2);
            if GlobalOptions.FullPacketsLog then LogPrint('pck len='+inttostr(len));
            // если пакет весь в буфере
            if (len <= Length(fbufClient)) then begin
                // читаем пакет
                SetLength(Packet.data, len-2);
                Move(fbufClient[3], Packet.data[1], len-2);

                // удаляем пакет из буфера
                Delete(fbufClient, 1, len);
                Inc(fPacketsCount);

                // декодируем пакет
                Decode(FromServer);
                // обрабатываем
                OnPacket(FromServer);

                // если чтото еще есть в пакете - отсылаем в сеть
                if Packet.Size > 0 then begin
                    Encode(FromServer);

                    // формируем пакет на отправку
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
    // заполняем длину пакета
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
    // заполняем длину пакета
    SetLength(tmp, 2);
    h := Length(p)+2;
    Move(h, tmp[1], 2);

    fContext.OutboundClient.IOHandler.Write( StringToBytes(tmp+p) );
end;

end.
