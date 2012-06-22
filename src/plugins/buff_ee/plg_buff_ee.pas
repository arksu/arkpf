unit plg_buff_ee;

interface

uses
    pfHeader, SysUtils, Classes, buffer, ark_bots;

type
    TPluginImpl = class(TPluginDll)
    protected
        fBuffer : TBuffer;

        procedure creature_say(var pck : AnsiString);
        procedure client_say(var pck : AnsiString);
        procedure mob_die(var pck : AnsiString);
    public
        active : Boolean;
        myTarget : Integer;

        procedure Init; override;
        procedure ProcessPacket(var pck: AnsiString; FromServer: Boolean; ConnectName : string; Engine : TEngine); override;
        destructor Destroy; override;
        procedure onTimer(id: Integer); override;

        procedure RequestHeal(id : Integer);
        procedure RequestMP(id : Integer);
        procedure RequestRes(id : Integer);
        function CallFunction(a: Integer; Params: Variant): Integer; override;
    end;

var
    plugin_impl : TPluginImpl;

const
    COMMAND_BUFF = 'rebuff';
    COMMAND_CHANNEL = 3;
    BUFF_DONE_MSG = 'ee_done';

    HP_SKILL = 1401;
    MP_SKILL = 1013;
    RES_SKILL = 1016;

implementation

{ TPluginImpl }

procedure TPluginImpl.Init;
begin
    fBuffer := TBuffer.Create(self);
    fBuffer.LeaderPlugin := LEADER_PLUGIN;
    fBuffer.LeaderFuncId := FUNC_BUFF_DONE;
    fBuffer.LeaderFuncVar := BUFF_DONE_MSG;

    LogPrint('leader name : '+core.getLinkedCharName( LEADER_PLUGIN ));
    fBuffer.AddSetTarget(core.getLinkedCharName( LEADER_PLUGIN ));
    fBuffer.AddBuff(1257); // decrease weight
    fBuffer.AddBuff(1044); // regen
//    fBuffer.AddBuff(1393); // resist dark
//    fBuffer.AddBuff(1259); // resist shock
//    fBuffer.AddBuff(1353); // divine protection
//    fBuffer.AddBuff(1043); // holy weapon

    // self
//    fBuffer.AddSetTarget( Core.getLinkedCharName(Self) );
//    fBuffer.AddBuff(1257); // decrese weight
//    fBuffer.AddBuff(1259); // resist shock

    active := true;
    myTarget := 0;
end;

function TPluginImpl.CallFunction(a: Integer; Params: Variant): Integer;
begin
    case a of
        FUNC_REQUEST_HP : RequestHeal(Params);
        FUNC_REQUEST_MP : RequestMP(Params);
        FUNC_REQUEST_RES : RequestRes(Params);
    end;
    Result := 0;
end;

procedure TPluginImpl.client_say(var pck: AnsiString);
var
    msg : string;
//    ch : Integer;
    p : TPacket;
begin
    p.Reset(pck, 2);
    msg := p.ReadS;
//    ch := p.ReadD;

    if msg = 'a' then begin
        active := true;
        pck := '';
    end;

    if msg = 'd' then begin
        fBuffer.Stop;
        active := false;
        pck := '';
    end;
end;

procedure TPluginImpl.creature_say;
var
    ch, id : Integer;
    name, msg : string;
    p : TPacket;
begin
    p.Reset(pck, 2);
    id := p.ReadD;
    ch := p.ReadD;
    name := p.ReadS;
    p.Skip(4);
    msg := p.ReadS;

    if (ch = COMMAND_CHANNEL) and (msg = COMMAND_BUFF) then begin
        fBuffer.Start;         
    end;

    if (ch =2) and (msg = 'hp mne') then begin
        RequestHeal(id);
    end;
end;

destructor TPluginImpl.Destroy;
begin
    fBuffer.Free;
    inherited;
end;

procedure TPluginImpl.mob_die;
var
    p : TPacket;
begin
    p.Reset(pck, 2);
    if p.ReadD = myEngine.Me.ObjID then begin
        myEngine.botSay('epic fail....');
        active := false;
        fBuffer.Stop;
    end;
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
//             creature say
            #$4a : creature_say(pck);
            #$00 : mob_die(pck);
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

    if not FromServer then
    case pck[1] of
        #$49 : client_say(pck);
    end;

end;

procedure TPluginImpl.RequestHeal(id: Integer);
begin
    if id = 0 then exit;

    if (myEngine.Me.CurrentTarget <> id) then
    begin
        myEngine.Me.Action(id);
    end;

    if (not myEngine.Me.isUsingSkill) then myEngine.me.UseSkill(HP_SKILL)
    else myEngine.botSay('hp skill in use...');

end;

procedure TPluginImpl.RequestMP(id: Integer);
begin
    if id = 0 then exit;

    if (myEngine.Me.CurrentTarget <> id) then
    begin
        myEngine.Me.Action(id);
    end;

    if (not myEngine.Me.isUsingSkill) then myEngine.me.UseSkill(MP_SKILL)
    else myEngine.botSay('mp skill in use...');
end;

procedure TPluginImpl.RequestRes(id: Integer);
begin
    if id = 0 then exit;

    if (myEngine.Me.CurrentTarget <> id) then
    begin
        myEngine.Me.Action(id);
    end;

    if (not myEngine.Me.isUsingSkill) then myEngine.me.UseSkill(RES_SKILL)
    else myEngine.botSay('res skill in use...');
end;

end.
