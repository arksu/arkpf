unit plg_buff_wc;

interface

uses
    pfHeader, SysUtils, Classes, buffer, ark_bots;

type
    TPluginImpl = class(TPluginDll)
    protected
        fBuffer : TBuffer;
        active : Boolean;

        procedure creature_say(var pck : AnsiString);

        procedure BuffCOV;
    public
        procedure Init; override;
        procedure ProcessPacket(var pck: AnsiString; FromServer: Boolean; ConnectName : string; Engine : TEngine); override;
        destructor Destroy; override;
        procedure onTimer(id: Integer); override;
        function CallFunction(a: Integer; Params: Variant): Integer; override;
    end;

var
    plugin_impl : TPluginImpl;

const
    COMMAND_BUFF = 'rebuff';
    COMMAND_CHANNEL = 3;
    BUFF_DONE_MSG = 'wc_done';

    COV_SKILL = 1363;

implementation

{ TPluginImpl }

procedure TPluginImpl.Init;
begin
    fBuffer := TBuffer.Create(self);
    fBuffer.LeaderPlugin := LEADER_PLUGIN;
    fBuffer.LeaderFuncId := FUNC_BUFF_DONE;
    fBuffer.LeaderFuncVar := BUFF_DONE_MSG;

    fBuffer.AddBuff(1002); // acum
    fBuffer.AddBuff(1284); // revenge, deflect dmg
    fBuffer.AddBuff(1309); // accuracy
    fBuffer.AddBuff(1006); // mdef
    fBuffer.AddBuff(1461); // chant of protection (decrease crit)
    fBuffer.AddBuff(1535); // chant movement
    fBuffer.AddBuff(1562); // bers
    fBuffer.AddBuff(1518); // chant crit
    fBuffer.AddBuff(1517); // chant combat
    fBuffer.AddBuff(1390); // add patk
    fBuffer.AddBuff(1519); // blood awakening
    
    active := true;
end;

procedure TPluginImpl.BuffCOV;
begin
    if myEngine.Me.Skills[COV_SKILL].isReady then
        myEngine.Me.UseSkill(COV_SKILL);
end;

function TPluginImpl.CallFunction(a: Integer; Params: Variant): Integer;
begin
    case a of
        FUNC_REQUEST_COV : BuffCOV;    
    end;
    Result := 0;
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

    if (ch =3) and (msg = 'cov') then
    begin
        BuffCOV;
    end;    
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

