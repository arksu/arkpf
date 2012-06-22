unit plg_voin;

interface

uses
    pfHeader, SysUtils, Classes, ark_bots;

type
    TPluginImpl = class(TPluginDll)
    public
        procedure Init; override;
        procedure ProcessPacket(var pck: AnsiString; FromServer: Boolean; ConnectName : string; Engine : TEngine); override;
        destructor Destroy; override;
        procedure onTimer(id: Integer); override;

        procedure onClientChatSay(var pck : AnsiString);
        function CheckDrop(item_id : Integer) : Boolean;
        // дистанция от моба до центра кача
        function get_fight_dist(idx : Integer) : Integer;
        // дистанция от моба до меня
        function get_cur_dist(idx : Integer) : Integer;
        procedure BeginFight;
        function get_next_target : Integer;
        procedure StartFightMode;
        procedure StopFightMode;
        procedure mob_die(pck : AnsiString);
        procedure mob_attack(pck : AnsiString);
        procedure get_item(pck : AnsiString);
        procedure status_update(pck : AnsiString);
        function CheckHPNeedRestore : Boolean;
        procedure SendAttack(id : Integer);

        procedure AddTarget(id : Integer);
        function MobInTargets(id : Integer) : Boolean;
        
    end;

var
    plugin_impl : TPluginImpl;

//------------------------------------------------------------------------------
const
    ST_NONE = 0;
    ST_WAIT_TARGET = 1; // ждем появления цели для атаки
    ST_WAIT_ATTACK = 2; // ждем начала атаки на моба
    ST_ATTACK = 3;      // атакуем моба. убиваем его
    ST_DROP_UP = 4;     // подбираем дроп

    FIGHT_RADIUS = 1600;

    HP_BOTTLE = 1061; // ghp 1539   hp 1061  lesser 1060
    HP_MINRESTORE = 80;

    TIMER_ID_FIGHT = 1;
    TIMER_ID_HP = 2;
    TIMER_HP_INTERVAL = 13500;

var
    FightPos : TVec3i;
    main_state : Integer;
    active : Boolean;
    myTarget : Integer;
    wait_attack_timer : Integer;
    wait_drop_timer : Integer;
    state_timer : integer;
    targets : array of Integer; // mob types to attack

implementation

{ TPluginImpl }

procedure TPluginImpl.AddTarget(id: Integer);
var
    i : Integer;
begin
    if id = 0 then exit;

    for i in targets do
        if i = id then exit;

    SetLength(targets, length(targets)+1);
    targets[High(targets)] := id;
    myEngine.botSay('add target : '+inttostr(id));
end;

procedure TPluginImpl.BeginFight;
var
    t : Integer;
begin
    myEngine.botSay( 'try begin fight');
    t := myEngine.Mobs.getNearMob(True); //get_next_agro;
    if t = 0 then t := get_next_target;

    if t <> 0 then begin
        myTarget := t;
        // начинаем атаку ближайшей цели
        SendAttack(myTarget);
        main_state := ST_WAIT_ATTACK;
        wait_attack_timer := 0;
    end else begin
        main_state := ST_WAIT_TARGET;
    end;
end;

function TPluginImpl.CheckDrop(item_id: Integer): Boolean;
begin
    Result := true;
end;

function TPluginImpl.CheckHPNeedRestore: Boolean;
begin
    Result := (myEngine.Me.Hppc < HP_MINRESTORE) and active;
end;

destructor TPluginImpl.Destroy;
begin

  inherited;
end;

function TPluginImpl.get_cur_dist(idx: Integer): Integer;
var
    pos, mb : TVec3i;
begin
    pos := myEngine.Me.Pos;
    mb := myEngine.Mobs[idx].pos;
    Result := Round(sqrt( Sqr(pos.X-mb.X) + Sqr(pos.Y-mb.Y) + Sqr(pos.Y-mb.Y) ));
end;

function TPluginImpl.get_fight_dist(idx: Integer): Integer;
var
    pos, mb : TVec3i;
begin
    pos := FightPos;
    mb := myEngine.Mobs[idx].pos;
    Result := Round(sqrt( Sqr(pos.X-mb.X) + Sqr(pos.Y-mb.Y) + Sqr(pos.Y-mb.Y) ));
end;

procedure TPluginImpl.get_item(pck: AnsiString);
//var
//    id : Integer;
begin
   // 2 player  id
    if (main_state = ST_DROP_UP) and (ReadD(pck, 2) = myEngine.Me.ObjID) then begin
       // 6 - obj id

        if not myEngine.Drop.PickupMyNearest then
            BeginFight;

        myEngine.botSay( 'adena : '+inttostr(myEngine.Drop.AdenaReceived) );
    end;
end;

function TPluginImpl.get_next_target: Integer;
var
    min, min_dist, d, df, i : integer;
begin
    min := 0;
    min_dist := 10000;
    df := 0;

    for i := 0 to myEngine.Mobs.Count-1 do begin
        d := get_cur_dist(i);
        df := get_fight_dist(i);
        if
//        (not myEngine.Mobs[i].is_agro) and
        (not myEngine.Mobs[i].is_dead) and
        (myEngine.Mobs[i].is_mob) and
        (MobInTargets(myEngine.Mobs[i].npc_type)) and
        (d < min_dist) and
        (df < FIGHT_RADIUS)
//        (not IsIgnore(MobsID[i]))
        then
        begin
            min := myEngine.Mobs[i].objid;
            min_dist := d;
        end;
    end;

    myEngine.botSay('d='+inttostr(min)+' df='+inttostr(df));
    Result := min;
end;

procedure TPluginImpl.Init;
begin
    main_state := ST_NONE;
    active := False;
    myTarget := 0;
    targets := nil;
end;

function TPluginImpl.MobInTargets(id: Integer): Boolean;
var
    i : Integer;
begin
    if Length(targets) = 0 then begin
        Result := True;
        exit;
    end
    else begin
        for i := 0 to Length(targets) - 1 do
            if targets[i] = id then
            begin
                Result := true;
                exit;
            end;
    end;
    Result := False;    
end;

procedure TPluginImpl.mob_attack(pck: AnsiString);
var
    id : Integer;
begin
    if not active then Exit;
    
    // 2 who
    id := ReadD(pck, 2);
    // 6 target


    // если атакую я - переходим в состояние атаки
    if (id = myEngine.Me.ObjID) and (main_state = ST_WAIT_ATTACK) then begin
        main_state := ST_ATTACK;
        myEngine.botSay( 'attack mode!');
    end;
end;

procedure TPluginImpl.mob_die;
var
    id, t : Integer;
begin
    id := ReadD(pck, 2);

    if id = myEngine.Me.ObjID then begin
        // мы сдохли))
        StopFightMode;
        myEngine.botSay('epic fail......');
    end;

    if (id = myTarget) and (active) then
    begin
        t := myEngine.Mobs.getNearMob(True);
        if t <> 0 then begin
            myTarget := t;
            // начинаем атаку ближайшей цели
            SendAttack(myTarget);
            main_state := ST_WAIT_ATTACK;
            wait_attack_timer := 0;
        end else begin
            // нет больше агро мобов рядом, можно собирать лут
            main_state := ST_DROP_UP;
            if not myEngine.Drop.PickupMyNearest then begin
                BeginFight;
            end
            else begin
                myEngine.botSay( 'pick up my drop...');
                wait_drop_timer := 0;
                main_state := ST_DROP_UP;
            end;


        end;
    end;
end;

procedure TPluginImpl.onClientChatSay(var pck: AnsiString);
var
    msg : string;
//    ch : Integer;
begin
    msg := ReadS(pck, 2);
//    ch := ReadD(pck, 6);

    if (msg = 'a') then begin
        pck := '';
        StartFightMode;
    end;

    if (msg = 'd') then begin
        pck := '';
        StopFightMode;
    end;

    if msg = 't' then begin
        pck := '';
        AddTarget( myEngine.Mobs.ItemsByObjID[ myEngine.Me.CurrentTarget ].npc_type );
    end;

end;

procedure TPluginImpl.onTimer(id: Integer);
begin
    case id of
        TIMER_ID_HP : begin
            if CheckHPNeedRestore then
                myEngine.Inventory.UseItem( HP_BOTTLE)
            else
                TimerStop(TIMER_ID_HP);
        end;

        TIMER_ID_FIGHT : if active then case main_state of
            ST_WAIT_TARGET : begin
                myEngine.botSay('wait target');
                BeginFight;
            end;

            ST_WAIT_ATTACK : begin
                Inc(wait_attack_timer);

                if (wait_attack_timer mod 5) = 0 then
                begin
                    SendAttack(myTarget);
                    myEngine.botSay('try retry attack');
                end;


                myEngine.botSay( 'wait attack '+inttostr(wait_attack_timer));
                // не дождались атаки, заносим цель в список игнора и ищем следующую
                if wait_attack_timer > 100 then begin
                    BeginFight;
                end;
            end;

            ST_ATTACK : begin
                inc(state_timer);
                if (state_timer mod 3) = 0 then
                begin
                    SendAttack(myTarget);
                    myEngine.botSay('try retry attack');
                end;
                
            end;

            ST_DROP_UP : begin
                Inc(wait_drop_timer);
                myEngine.botSay( 'wait drop '+inttostr(wait_drop_timer));
                if wait_drop_timer > 20 then begin
                    BeginFight;
                end;
            end;
        end;
    end;
end;

procedure TPluginImpl.SendAttack(id: Integer);
begin
    myEngine.Me.Action(id);
    myEngine.Me.Action(id);
end;

procedure TPluginImpl.StartFightMode;
begin
        myEngine.botSay( 'begin fight');
        active := true;
        TimerStart( TIMER_ID_FIGHT, 500 );
        myEngine.Me.TargetCancel;
        FightPos := myEngine.Me.Pos;
        BeginFight;
end;

procedure TPluginImpl.status_update(pck: AnsiString);
begin
    if (ReadD(pck, 2) = myEngine.Me.ObjID) then begin

        if CheckHPNeedRestore and (not isTimerEnabled( TIMER_ID_HP )) then begin
            myEngine.Inventory.UseItem( HP_BOTTLE );
            TimerStart( TIMER_ID_HP, TIMER_HP_INTERVAL );
        end;
    end;
end;

procedure TPluginImpl.StopFightMode;
begin
    TimerStop(TIMER_ID_FIGHT);
    active := False;
    myEngine.botSay('STOP! **************');
end;

procedure TPluginImpl.ProcessPacket(var pck: AnsiString; FromServer: Boolean;
  ConnectName: string; Engine: TEngine);
var
    p : TPacket;
    s : string;
begin
    if FromServer then begin
        case pck[1] of
            #$00 : mob_die(pck);
            #$33: mob_attack(pck);
            #$17: get_item(pck);
            #$18: status_update(pck);

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
    end else begin
        case pck[1] of
            // chat say
            #$49 : onClientChatSay(pck);
        end;
    end;
end;

end.
