unit uL2GS_Connect;

interface

uses
    pfHeader, uConnect, Math, SysUtils, ComCtrls, uPacketVisual;

type
    L2Xor = class
    private
        keyLen: Byte;
    public
        GKeyS,GKeyR:array[0..15] of Byte;
        constructor Create;
        procedure InitKey(const XorKey : AnsiString; Interlude: Byte = 0);
        procedure DecryptGP(var p : TPacket);
        procedure EncryptGP(var p : TPacket);
        procedure PreDecrypt(var p : TPacket);
        procedure PostEncrypt(var p : TPacket);

        function getKeyLen : Integer;
    end;

    TL2GS_Connect = class(tConnect)
    private
        xorC, xorS: L2Xor;
        XorInited : Boolean;
        FCharName : string;
        fEngine : TEngine;
    protected
        procedure OnPacket(FromServer : Boolean); override;

        procedure Decode(FromServer: Boolean); override;
        procedure Encode(FromServer: Boolean); override;

    public
        AssignedTabSheet : TTabSheet;
        Visual : TfVisual;
        procedure Init; override;
        procedure Finit;
        destructor Destroy; override;
        procedure EncodeAndSend(pck : string; FromServer : Boolean);

        function getCharName : string;
        procedure updCharName;
        function getEngine : TEngine;
    end;
    
const
  KeyConst2: array[0..63] of Char = 'nKO/WctQ0AVLbpzfBkS6NevDYT8ourG5CRlmdjyJ72aswx4EPq1UgZhFMXH?3iI9';

implementation

uses
    uLog, uGlobal, uEngine, uMain, uMap, IdSync;


{ L2Xor }

constructor L2Xor.Create;
begin
  FillChar(GKeyS[0], SizeOf(GKeyS), 0);
  FillChar(GKeyR[0], SizeOf(GKeyR), 0);
  keyLen := 0;
end;

procedure L2Xor.DecryptGP;
var
  i:integer;
  k,d:byte;
begin
  k:=0;
  for i:=0 to Length(p.data)-1 do
  begin
    d := Ord(p.Data[i+1]);
    p.Data[i+1] := Chr( d xor GKeyR[i and keyLen] xor k );
    k:=d;
  end;
  Inc(PCardinal(@GKeyR[keyLen-7])^, Length(p.data));
end;

procedure L2Xor.EncryptGP;
var
  i:integer;
  k,d:byte;
begin
  k:=0;
  for i:=0 to Length(p.data)-1 do
  begin
    d := Ord(p.Data[i+1]);
    d:=d xor GKeyS[i and keyLen] xor k;
    p.Data[i+1] := Chr(d);
    k:=d;
  end;
  Inc(PCardinal(@GKeyS[keyLen-7])^, Length(p.data));
end;

function L2Xor.getKeyLen: Integer;
begin
    Result := keyLen;
end;

procedure L2Xor.InitKey(const XorKey : AnsiString; Interlude: Byte);
const
  KeyConst: array[0..3] of Byte = ($A1,$6C,$54,$87);
  KeyConstInterlude: array[0..7] of Byte = ($C8,$27,$93,$01,$A1,$6C,$31,$97);
var
  key2:array[0..15] of Byte;
begin
  case Interlude of
    0:begin   //C4
      keyLen:=7;
      Move(XorKey[1], key2, 4);
      Move(KeyConst, key2[4], 4);
    end;
    1:begin   //Interlude - Gracia - GoD
      keyLen:=15;
      Move(XorKey[1], key2[0], 8);
      Move(KeyConstInterlude, key2[8], 8);
    end;
  end;
  Move(key2, GKeyS, 16);
  Move(key2, GKeyR, 16);
  inherited;          
end;

procedure L2Xor.PostEncrypt;
begin
//Ќичего не делаем, ибо ничего делать и не надо.
end;

procedure L2Xor.PreDecrypt;
begin
//Ќичего не делаем, ибо ничего делать и не надо.
end;

{ TL2GS_Connect }

procedure TL2GS_Connect.Decode(FromServer: Boolean);
begin
    XorInited := ((xorS as L2Xor).getKeyLen > 0);

    if not XorInited then Exit;

    if FromServer then begin
          xorS.DecryptGP(packet);
          if GlobalOptions.FullPacketsLog then begin
              LogPrint('S decoded packet------------------------');
              LogPacket(Packet);
          end;
    end else begin
          xorC.DecryptGP(packet);
          if GlobalOptions.FullPacketsLog then begin
              LogPrint('C decoded packet------------------------');
              LogPacket(Packet);
          end;
    end;

end;

destructor TL2GS_Connect.Destroy;
begin
    xorC.Free;
    xorS.Free;
    fEngine.Free;

    inherited;
end;

procedure TL2GS_Connect.Encode(FromServer: Boolean);
begin
    if not XorInited then Exit;

    if FromServer then begin
        xorS.EncryptGP(Packet);
        if GlobalOptions.FullPacketsLog then begin
            LogPrint('S encoded packet------------------------');
            LogPacket(Packet);
        end;
    end else begin
        xorC.EncryptGP(Packet);
        if GlobalOptions.FullPacketsLog then begin
            LogPrint('C encoded packet------------------------');
            LogPacket(Packet);
        end;
    end;
end;

procedure TL2GS_Connect.EncodeAndSend(pck: string; FromServer: Boolean);
var
    ps : tpck_struct;
begin
    if Length(pck) <= 0 then exit;
    
    Packet.data := pck;
    inc(fPacketsCount);
    
    if (GlobalOptions.PacketsLog) then begin
        ps.p := Packet;
        ps.from_server := FromServer;
        ps.flags := PCK_NEW;
        ps.caller := Self;
        ps.pck_num := getPacketCount;
        PckVisual(Visual, ps);
    end;

    Encode(FromServer);

    if FromServer then
        SendToClient(packet.data)
    else
        SendToServer(packet.data);
        
    Packet.Reset;
end;

procedure TL2GS_Connect.Finit;
begin
    if not GlobalDestroy then begin
        uMap.Finit(fEngine);
        if GlobalOptions.DeleteInactiveVisual then begin
            Visual.finit;
            Visual.Free;

            AssignedTabSheet.Free;
        end;
    end;
end;

function TL2GS_Connect.getCharName: string;
begin
    Result := FCharName;
end;

function TL2GS_Connect.getEngine: TEngine;
begin
    Result := fEngine;
end;

procedure TL2GS_Connect.Init;
begin
    inherited;
    xorC := L2Xor.Create;
    xorS := L2Xor.Create;
    XorInited := false;
    
    FCharName := '';
    fEngine := TEngineImpl.Create(Self);

    AssignedTabSheet := TTabSheet.Create(fMain.pcClientsConnection);
    AssignedTabSheet.PageControl := fMain.pcClientsConnection;
    fMain.pcClientsConnection.ActivePage := AssignedTabSheet;
    AssignedTabSheet.Show;
    AssignedTabSheet.PageControl := fMain.pcClientsConnection;
    AssignedTabSheet.Caption := '#'+inttostr(getSocketID);
    fMain.pcClientsConnectionChange(nil);
    if not fMain.pcClientsConnection.Visible then fMain.pcClientsConnection.Visible  := true;

    Visual := TfVisual.Create(AssignedTabSheet);
    Visual.Parent := AssignedTabSheet;
    Visual.Connect := self;
    Visual.init;
    Visual.CreateTime := now;
end;

procedure TL2GS_Connect.OnPacket(FromServer: Boolean);
var
    isInterlude : Boolean;
    key : AnsiString;
    len : word;
    WStr: WideString;
    i : Integer;
    pck, pck_orig : AnsiString;
    ps : tpck_struct;
begin
    if packet.Size <= 0 then exit;

    if FromServer then begin
        // CryptInit and isOk
        if (not XorInited) and (Packet.Data[1] = #$2E) and (Packet.Data[2] = #$01) then begin
            isInterlude:=(Packet.Size>19);
            SetLength(key, 8);
            Move(packet.data[3], key[1], 8);
            xorC.InitKey(key, Byte(isInterlude));
            xorS.InitKey(key, Byte(isInterlude));
        end;

        // char selected
        if (Packet.data[1] = #$0B) then begin
            len := 0;
            while not ((Packet.Data[len+2] = #00) and (Packet.Data[len + 3] = #00)) do Inc(len,2);
            SetLength(WStr, len div 2);
            Move(Packet.Data[2], WStr[1], len);
            FCharName := WideStringToString(WStr);
            TIdSync.SynchronizeMethod( updCharName );
            LogPrint('connect ['+inttostr(getsocketid)+'] char name : '+FCharName);
        end;
    end else begin

    end;

    //--------------------------------------------------------------------------
    pck := Packet.data;
    pck_orig := pck;

    fEngine.HandlePacket(pck, FromServer);

    for i := 0 to Plugins.Count - 1 do
        if (TPlugin(Plugins[i]).Loaded) and (Length(pck) > 0)
        and ( (LowerCase(TPlugin(Plugins[i]).CharName) = LowerCase(FCharName)) or (TPlugin(Plugins[i]).CharName = '') ) then
        begin
            TPlugin(Plugins[i]).DllImpl.ProcessPacket( pck, FromServer, getCharName, fEngine );
            if pck = '' then break;
//            else begin
//                SetLength(pss, Length(pck));
//                Move(pck[1], pss[1], Length(pck));
//                pss := pck + '';
//                pck := pss;
//            end;
        end;

    Packet.data := pck;
    
    if (GlobalOptions.PacketsLog) then begin
        if pck = '' then Packet.data := pck_orig;
        ps.p := Packet;
        ps.from_server := FromServer;
        if pck = '' then ps.flags := PCK_DROPPED
        else if pck <> pck_orig then ps.flags := PCK_CHANGED
        else ps.flags := PCK_NORMAL;
        ps.caller := Self;
        ps.pck_num := getPacketCount;
        PckVisual(Visual, ps);
    end;
    
    Packet.data := pck;
end;

procedure TL2GS_Connect.updCharName;
begin
    if Assigned(AssignedTabSheet) then AssignedTabSheet.Caption := FCharName;
end;

end.
