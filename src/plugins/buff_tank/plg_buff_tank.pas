unit plg_buff_tank;

interface

uses
    pfHeader, SysUtils, Classes, buffer, ark_bots;

type
    TPluginImpl = class(TPluginDll)
    protected
        fBuffer : TBuffer;

        procedure creature_say(var pck : AnsiString);
    public
        procedure Init; override;
        procedure ProcessPacket(var pck: AnsiString; FromServer: Boolean; ConnectName : string; Engine : TEngine); override;
        destructor Destroy; override;
        procedure onTimer(id: Integer); override;
    end;

var
    plugin_impl : TPluginImpl;

const
    COMMAND_BUFF = 'rebuff';
    COMMAND_CHANNEL = 3;
    BUFF_DONE_MSG = 'tank_done';

implementation

{ TPluginImpl }

procedure TPluginImpl.Init;
begin
    fBuffer := TBuffer.Create(self);
    fBuffer.LeaderPlugin := LEADER_PLUGIN;
    fBuffer.LeaderFuncId := FUNC_BUFF_DONE;
    fBuffer.LeaderFuncVar := BUFF_DONE_MSG;

    fBuffer.AddBuff(982); // combat aura
    
end;

procedure TPluginImpl.creature_say;
var
    ch : Integer;
    name, msg : string;
    p : TPacket;
begin
    p.Reset(pck, 2);
    p.ReadD;
    ch := p.ReadD;
    name := p.ReadS;
    p.Skip(4);
    msg := p.ReadS;

    if (ch = COMMAND_CHANNEL) and (msg = COMMAND_BUFF) then begin
        fBuffer.Start;
    end;

    if (msg = 'd') then
        fBuffer.Stop;    
end;

destructor TPluginImpl.Destroy;
begin
    fBuffer.Free;
    inherited;
end;

procedure TPluginImpl.onTimer(id: Integer);
begin
    if id = BUFFER_TIMER_ID then fBuffer.onTimer;
    
end;

procedure TPluginImpl.ProcessPacket(var pck: AnsiString; FromServer: Boolean;
  ConnectName: string; Engine: TEngine);
var
    p : TPacket;
    s : string;
begin
    fBuffer.ProcessPacket(pck, FromServer, ConnectName, Engine);

    p.Reset(pck, 2);
    if FromServer then
    case pck[1] of
            // creature say
            #$4a : creature_say(pck);
            // join party
            #$39: begin
                s := LowerCase( ReadS(pck, 2) );
                if (Core.isConnectionExist(s)) or (isFriend(s)) then begin
                    pck := '';
                    Engine.Party.JoinAnswer(true);
                end
                else
                    LogPrint( 'unknown party request from '+s);
            end;
            // command channel
            #$fe : begin
                if ReadH(pck, 2) = 26 then begin
                    pck := '';
                    p.Reset(#$D0#$07#$00#$01#$00#$00#$00#$00#$00#$56#$00).
                    SendToServer(ConnectName);
                end;
            end;
    end;

end;

end.

