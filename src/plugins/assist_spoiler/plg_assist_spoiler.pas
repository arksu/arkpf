unit plg_assist_spoiler;

interface

uses
    pfHeader, SysUtils, Classes;

type
    TPluginImpl = class(TPluginDll)
    private
        // засвипаные мобы. их надо собрать
        sweeped : array of Integer;
        myTarget : Integer;
        active : Boolean;
        main_state : Integer;
        state_timer : Integer;

        procedure say(s : string);
    protected
        procedure AddSweeped(id : Integer);
        procedure DelSweeped(id : Integer);
        procedure Sweep(id : Integer);
        procedure SpoilFestival(id : Integer);
        procedure SweepNext;

        procedure mob_die(var pck : AnsiString);
        procedure magic_skill_launched(var pck : AnsiString);
    public
        procedure Init; override;
        procedure ProcessPacket(var pck: AnsiString; FromServer: Boolean; ConnectName : string; Engine : TEngine); override;
        destructor Destroy; override;
        procedure onTimer(id: Integer); override;
        procedure Finit; override;
    end;

var
    plugin_impl : TPluginImpl;

const
    SWEEP_SKILL = 42;
    SPOIL_FESTIVAL_SKILL = 302;
    SPOIL_SKILL = 254;

    ST_IDLE = 0;
    ST_DIE = 1;
    ST_USE_SWEEP = 2;
    ST_USE_SPOIL_FESTIVAL = 3;


implementation

{ TPluginImpl }

procedure TPluginImpl.AddSweeped(id: Integer);
var
    i : Integer;
begin
    for i := 0 to Length(sweeped) - 1 do
        if sweeped[i] = id then exit;

    SetLength(sweeped, Length(sweeped) + 1);
    sweeped[High(sweeped)] := id;
end;

procedure TPluginImpl.DelSweeped(id: Integer);
var
    i, j : Integer;
begin
    for i := 0 to Length(sweeped) - 1 do
        if sweeped[i] = id then begin
            for j := i to Length(sweeped) - 2 do
                sweeped[j] := sweeped[j+1];
            SetLength(sweeped, Length(sweeped) - 1);
        end;
end;

destructor TPluginImpl.Destroy;
begin

  inherited;
end;

procedure TPluginImpl.Finit;
begin
  inherited;
    sweeped := nil;
end;

procedure TPluginImpl.Init;
begin
  inherited;
    active := false;
    myTarget := 0;
    sweeped := nil;
end;

procedure TPluginImpl.magic_skill_launched(var pck: AnsiString);
begin

end;

procedure TPluginImpl.mob_die(var pck: AnsiString);
var
    id : Integer;
begin
    id := ReadD(pck, 2);

    if id = myID then begin
        // мы сдохли))
        state_timer := 0;
        main_state := ST_DIE;
        active := false;

//        StopFightMode;
        say( 'epic fail......');
    end else begin
    end;

    // sweepable
    if (ReadD(pck, 22) = 1) and (active) then begin
        AddSweeped(id);

        if main_state = ST_IDLE then
            Sweep(id);
    end;

end;

procedure TPluginImpl.onTimer(id: Integer);
begin
    if id = 1 then case main_state of
    
        ST_USE_SWEEP : begin
            Inc(state_timer);
            if state_timer > 10 then
            begin
                // превышено время ожидания свипа моба
                // удаляем моба. не будем его больше свипать
                DelSweeped(myTarget);
                
                // пытаемся засвипать следующего если есть
                SweepNext;
            end;
            
        end;

        ST_USE_SPOIL_FESTIVAL : begin
            Inc(state_timer);

        end;                      

    end;

end;

procedure TPluginImpl.ProcessPacket(var pck: AnsiString; FromServer: Boolean;
  ConnectName: string; Engine: TEngine);
begin
    if FromServer then
    begin
        case pck[1] of
            // delete obj
            #$08 : begin
                DelSweeped( ReadD(pck, 2) );
                // если тот кого пытаемся засвипать уже исчез
                if (main_state = ST_USE_SWEEP) and (ReadD(pck, 2) = myTarget) then
                begin
                    SweepNext;
                end;
                
            end;

            #$00 : mob_die(pck);
            #$54 : magic_skill_launched(pck);

        end;
    end;

end;

procedure TPluginImpl.say(s: string);
begin
    myEngine.botSay(s);
end;

procedure TPluginImpl.SpoilFestival(id: Integer);
begin
    myEngine.Me.Action(id);
    myEngine.Me.UseSkill(SPOIL_FESTIVAL_SKILL);
    state_timer := 0;
    main_state := ST_USE_SPOIL_FESTIVAL;
end;

procedure TPluginImpl.Sweep(id: Integer);
begin
    myTarget := id;
    myEngine.Me.Action(id);
    myEngine.Me.UseSkill(SWEEP_SKILL);
    state_timer := 0;
    main_state := ST_USE_SWEEP;
end;

procedure TPluginImpl.SweepNext;
var
    i, d, t : Integer;
    m : TL2Npc;
begin
    if Length(sweeped) = 0 then
    begin
        main_state := ST_IDLE;
        Exit;
    end;

    d := 1000;
    t := 0;
    for i := 0 to Length(sweeped) - 1 do
    begin
        m := myEngine.Mobs.ItemsByObjID[sweeped[i]];
        if m.objid <> 0 then begin
            if myPos.Dist(m.pos) < d then begin
                d := myPos.Dist(m.pos);
                t := m.objid;
            end;
        end;
    end;

    if t <> 0 then begin
        Sweep(t);
    end else begin
        main_state := ST_IDLE;
    end;
end;

end.

