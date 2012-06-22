unit buffer;

interface

uses
    pfHeader, SysUtils;

const
    BUFFER_TIMER_ID = 1000;
    
type
    TBufferActionType = (baTarget, baBuff, baLeaveParty, baInviteParty);

    TBufferAction = record
        buff_type : TBufferActionType;
        skill_id : Integer;
        name : string;
    end;
    
    TBuffer = class
    protected
        fPlugin : TPluginDll;
        fItems : array of TBufferAction;
        p : TPacket;
        main_state : Integer;
        wait_skill : Integer;
        buffs_index : Integer;

        procedure join_party;
        procedure magic_skill_launched;
        procedure NextBuff;
        function getNextBuff : Integer;
    public
        LeaderPlugin : string;
        LeaderFuncId : Integer;
        LeaderFuncVar : Variant;

        constructor Create(aPlugin : TPluginDll);
        destructor Destroy; override;

        procedure onTimer;
        procedure ProcessPacket(var pck: AnsiString; FromServer: Boolean; ConnectName : string; Engine : TEngine); 

        procedure Add(action : TBufferAction);
        procedure AddBuff(skill_id : Integer);
        procedure AddSetTarget(name : string);
        procedure AddLeaveParty;

        procedure Start;
        procedure Stop;
    end;

implementation

const
    ST_IDLE = 0;
    ST_WAIT_PARTY_INVITE = 1;
    ST_WAIT_SKILL_USE = 2;

{ TBuffer }

procedure TBuffer.Add(action: TBufferAction);
begin
    SetLength(fItems, Length(fItems)+1);
    fItems[High(fItems)] := action;
end;

procedure TBuffer.AddBuff(skill_id: Integer);
var
    b : TBufferAction;
begin
    b.buff_type := baBuff;
    b.skill_id := skill_id;

    Add( b );
end;

procedure TBuffer.AddLeaveParty;
var
    b : TBufferAction;
begin
    b.buff_type := baLeaveParty;

    Add( b );
end;

procedure TBuffer.AddSetTarget(name: string);
var
    b : TBufferAction;
begin
    b.buff_type := baTarget;
    b.name := name;

    Add( b );
end;

constructor TBuffer.Create(aPlugin: TPluginDll);
begin
    fItems := nil;
    fPlugin := aPlugin;
    buffs_index := 0;
    main_state := ST_IDLE;

    LeaderPlugin := '';
    LeaderFuncId := 0;
end;

destructor TBuffer.Destroy;
begin
    fItems := nil;
    inherited;
end;

function TBuffer.getNextBuff: Integer;
var
    tt : integer;
begin
    Result := 0;
    if buffs_index >= Length(fItems) then begin
        Exit;
    end;

    fPlugin.myEngine.botSay( 'buff do next['+inttostr(buffs_index)+']: '+inttostr(Ord(fItems[buffs_index].buff_type)));

    case fItems[buffs_index].buff_type of
        baTarget : begin
            fPlugin.myEngine.botSay( 'target='+fItems[buffs_index].name);
            if fItems[buffs_index].name = fPlugin.LinkedCharName then
                tt := fPlugin.myEngine.Me.ObjID
            else
                tt := fPlugin.myEngine.Players.PlayerByName[fItems[buffs_index].name].objid;

            if tt = 0 then begin
                fPlugin.myEngine.botSay( 'target not found!');
                Result := 0;
                exit;
            end;


            if tt <> fPlugin.myEngine.Me.CurrentTarget then begin
                fPlugin.myEngine.botSay( 'set target='+inttostr(tt));
                fPlugin.myEngine.Me.Action( tt );
            end
            else
                fPlugin.myEngine.botSay( 'target already set');

            Inc(buffs_index);
            Result := getNextBuff;
        end;

        baLeaveParty : begin
            fPlugin.myEngine.Party.Leave;
            Inc(buffs_index);
            Result := getNextBuff;
        end;

        baInviteParty : begin
            fPlugin.myEngine.Party.Invite( fItems[buffs_index].name );
            Inc(buffs_index);
            Result := -1;
            exit;
        end;

        baBuff : begin
            // если у нас вообще есть такой скилл
            if fPlugin.myEngine.Me.HaveSkill(fItems[buffs_index].skill_id) then begin

                // если скилл готов
                if fPlugin.myEngine.Me.Skills[fItems[buffs_index].skill_id].isReady then
                begin
                    fPlugin.myEngine.Me.UseSkill( fItems[buffs_index].skill_id );
                    Result := fItems[buffs_index].skill_id;
                    Inc(buffs_index);
                    exit;
                end else begin
                    // ждем готовности скилла
                    fPlugin.myEngine.botSay( 'skill not ready! : '+inttostr( fItems[buffs_index].skill_id ));

                    fPlugin.TimerStart( BUFFER_TIMER_ID, 500 );
                    Result := fItems[buffs_index].skill_id;
                    Inc(buffs_index);
                    exit;
                end;
            end else begin
                // такого скилла ваще нет у нас
                fPlugin.myEngine.botSay( 'havnt skill! : '+inttostr( fItems[buffs_index].skill_id ));
                Inc(buffs_index);
                Result := getNextBuff;
                exit;
            end;
        end;

    end;
end;

procedure TBuffer.join_party;
begin
    if main_state = ST_WAIT_PARTY_INVITE then
        NextBuff;
end;

procedure TBuffer.magic_skill_launched;
var
    id, sk : Integer;
begin
    id := p.ReadD;
    sk := p.ReadD;

    if (id = fPlugin.myID) and (main_state = ST_WAIT_SKILL_USE) and (sk = wait_skill) then
    begin
        NextBuff;
    end;
end;


procedure TBuffer.NextBuff;
var
    i : Integer;
begin
    i := getNextBuff;
    fPlugin.myEngine.botSay('next buff: '+inttostr(i));
    case i of
        0 : begin
            main_state := ST_IDLE;
            // говорим в окно лидера - что бафы все выполнены
            fPlugin.myEngine.botSay('buffs done ['+fPlugin.LinkedCharName+']');

            // говорим лидеру что баф завершен
            if LeaderPlugin <> '' then
                Core.PluginCallFunction( LeaderPlugin, LeaderFuncId, LeaderFuncVar );
        end;
        -1 : main_state := ST_WAIT_PARTY_INVITE;
        else begin
            main_state := ST_WAIT_SKILL_USE;
            wait_skill := i;
        end;
    end;

end;

procedure TBuffer.onTimer;
begin
    fPlugin.myEngine.botSay('buffer timer');
    
    if fPlugin.myEngine.Me.Skills[wait_skill].isReady then
    begin
        fPlugin.myEngine.Me.UseSkill( wait_skill );
        fPlugin.TimerStop(BUFFER_TIMER_ID);
    end;
end;

procedure TBuffer.ProcessPacket(var pck: AnsiString; FromServer: Boolean;
  ConnectName: string; Engine: TEngine);
begin
    if FromServer then begin
        p.Reset(pck, 2);
        case pck[1] of
            #$3a : join_party;
            #$54 : magic_skill_launched;
        end;
    end;    
end;

procedure TBuffer.Start;
begin
    buffs_index := 0;
    NextBuff;
end;

procedure TBuffer.Stop;
begin
    fPlugin.TimerStop(BUFFER_TIMER_ID);
    main_state := ST_IDLE;
end;

end.
