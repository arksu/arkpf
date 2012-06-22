unit plg_buff_kot;

interface

uses
    pfHeader, SysUtils, Classes, ark_bots;

type
    TPluginImpl = class(TPluginDll)
    protected
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
    BUFF_DONE_MSG = 'kot_done';

    KOT_SUMMON_SKILL = 1331;
    KOT_BUFF_SKILL = 1007;

implementation

{ TPluginImpl }

procedure TPluginImpl.creature_say(var pck: AnsiString);
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
        myEngine.Me.ActionUse( 52 ); // unsummon
        myEngine.Me.UseSkill( KOT_SUMMON_SKILL );

        // говорим лидеру что баф завершен
        if LEADER_PLUGIN <> '' then
            Core.PluginCallFunction( LEADER_PLUGIN, FUNC_BUFF_DONE, BUFF_DONE_MSG );
    end;

    if (ch =3) and (msg = 'kot!') then
    begin
        myEngine.Me.ActionUse( 52 ); // unsummon
        myEngine.Me.UseSkill( KOT_SUMMON_SKILL );
    end;

    if (ch =3) and ((msg = 'kot') or (msg = 'ds')) then
    begin
        myEngine.Me.ActionUse( KOT_BUFF_SKILL );
    end;    
end;

destructor TPluginImpl.Destroy;
begin

  inherited;
end;

procedure TPluginImpl.Init;
begin
  inherited;

end;

procedure TPluginImpl.onTimer(id: Integer);
begin
  inherited;

end;

procedure TPluginImpl.ProcessPacket(var pck: AnsiString; FromServer: Boolean;
  ConnectName: string; Engine: TEngine);
var
    p : TPacket;
    s : string;
begin
    if FromServer then
    case pck[1] of
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

