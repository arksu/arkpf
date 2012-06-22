unit plg_parik_destr;

interface

uses
    pfHeader, SysUtils, Classes, ark_bots, IniFiles, l2_utils;

type
    TPathPoint = record
        pos : TVec3i;
        mob_atk : Integer; // тип моба для атаки. если 0 просто проходим точку
    end;

    TMovePath = array of TPathPoint;
    PMovePath = ^TMovePath;

    TPluginImpl = class(TPluginDll)
    private
        main_state : Integer;
        state_timer : Integer;
        parik_kill_timer : Integer;
        next_move_state : Integer;
        active : Boolean;
        kills_count, total_kills_count : Integer;
        parik_attack_count : Integer; // сколько раз нас ударил парик
        my_parik_attack_count : Integer; // сколько раз я ударил парик
        myDrop : Integer;
        CurrentResp : Integer; // номер текущего респа. если несколько путей
        buffers : array [0..10] of string; // сообщения от баферов

        // CONFIG --------------------------------------------------------------
        // выполнять сонги дансы раздельно. сначала свс потом бд
        ds_serapate : Boolean;

        // необходимый состав пати
        ee_name, wc_name, kot_name, tank_name, bd_name, sws_name, spoiler_name : string;
        // члены пати для прокачки. которые ничего не делают
        name1, name2, name3, name4 : string;

        // сколько раз нас должен ударить парик перед началом атаки
        parik_atk_required : Integer;
        // сколько мобов на респе надо для начала атаки
        min_mobs_resp : Integer;
        // точка и радиус респа
        resp1_point : TVec3i;
        resp1_radius_point : TVec3i;
        resp2_point : TVec3i;
        resp2_radius_point : TVec3i;
        // точка базирования, пати-спот
        base_point : TVec3i;
        // пути для сбора мобов
        path1 : TMovePath;
        path2 : TMovePath;
        // пути чтобы вернутся на базу
        path1_base : TMovePath;
        path2_base : TMovePath;
        // точки корректировки дропа
        drop1_point : TVec3i;
        drop2_point : TVec3i;
        // скилл для патаки в начале убивания парика
        rage_skill : Integer;
        // скилл для агра. если 0 значит будем бить чтобы заагрить
        provoke_skill : Integer;
        // скил юзаем во время данса
        ds_skill : Integer;
        // итем ид сосок
        soulshot_id : Integer;
        // сколько респов используем
        resp_count : Integer;
        // настройка пати на кач
        sws_offparty, bd_offparty, wc_offparty, ee_offparty, tank_offparty,
        spoiler_offparty, kot_offparty : Boolean;
        // итем ид хп бутылки
        hp_bottle : Integer;
        // сколько раз мы должны ударить моба на контрольной точке
        atk_required_chk_point : Integer;
        // ждать конца дс
        wait_ds_off : Boolean;
        //----------------------------------------------------------------------
        // текущая точка пути
        path_index : Integer;
        // текущий путь по которому бежим
        path : TMovePath;
        // текущая точка куда движемся
        current_move_point : TVec3i;
        // дистанция до контрольной точки пути, когда будет засчитано прохождение точки
        CurrentPointDist : Integer;
        myTarget : Integer;
        buff_timer : Integer;

        // итем ид оружия чтобы добивать
        SwordItemID : Integer;
        // итем ид пики
        SpearItemID : Integer;

    protected
        function  getPartyFull : string;
        function  getPartyDS : string;
        function  getPartyDance : string;

        // сколько мобов на респе
        function  getMobsRespCount : Integer;
        // получить радиус респа мобов
        function  getRespRadius : Integer;

        procedure StartFightMode;
        procedure StopFightMode;

        procedure LoadOptions;
        procedure SaveOptions;
        function  getIniFileName : string;
        procedure ShowOptions;
        procedure UpdateNames;
        procedure LoadPath(pn : Integer);
        procedure SavePath(pn : Integer);
        procedure ShowOptionsPath(pn : Integer);
        procedure ShowOptionsSoulshot;
        function  getPath(pn : Integer) : PMovePath;
        function  getPathName(pn : Integer) : string;
        procedure gotoTestPath(pn : Integer);
        procedure MoveNextPoint;
        procedure PrepareToFight;
        procedure AttackMobParik(mobid : Integer);
        procedure SendAttack(objid : Integer);
        procedure WaitMobsResp;
        procedure Rebuff;
        procedure Songs;
        procedure Dance;
        procedure gotoCollectParik;
        procedure gotoBase;
        procedure BeginFight;
        procedure SpotNext;
        procedure RequestMP;
        procedure RequestRes;
        procedure RequestCov;
        procedure PickUpParikDrop;
        procedure BuffDone(msg : string);
        function  AllBuffsDone : Boolean;
        function  getNextParikTarget: Integer;
        function  getAgroCount : Integer;
        function  CheckHPNeedRestore : Boolean;
        function  isDsOff : Boolean;

        function Palevo : string;

        procedure html_select(var pck : AnsiString);
        procedure onClientChatSay(var pck : AnsiString);
        procedure validate_pos(pck : AnsiString);
        procedure mob_attack(var pck : AnsiString);
        procedure join_party(var pck : AnsiString);
        procedure mob_die(var pck : AnsiString);
        procedure confirm_dlg(var pck : AnsiString; cn : string);
        procedure magic_skill_launched(var pck : AnsiString);
        procedure system_message(var pck : AnsiString);
        procedure get_item(var pck: AnsiString);
        procedure revive(var pck : AnsiString);
    public
        procedure Init; override;
        procedure ProcessPacket(var pck: AnsiString; FromServer: Boolean; ConnectName : string; Engine : TEngine); override;
        destructor Destroy; override;
        procedure onTimer(id: Integer); override;
        function  CallFunction(a: Integer; Params: Variant): Integer; override;

        procedure say(m : string);
    end;

var
    plugin_impl : TPluginImpl;

const
    ST_IDLE                         = 0;
    ST_PARTY_REBUFF                 = 1;
    ST_PARTY_DS                     = 2;
    ST_PARTY_DANCE                  = 3;
    ST_MOVE_BY_PATH                 = 4;
    ST_SPOT                         = 5;
    ST_KILL_PLACE                   = 6;
    ST_WAIT_PARIK_ATTACK            = 7;
    ST_WAIT_MY_ATTACK_CHECKPOINT    = 8;
    ST_KILL_PARIK                   = 9;
    ST_DROP_PARIK                   = 10;
    ST_DROP_PARIK_WAIT              = 11;
    ST_WAIT_MOBS_RESP               = 12;
    ST_DIE                          = 13;
    ST_WAIT_PARTY_FULL              = 14;
    ST_REBUFF                       = 15;
    ST_WAIT_PARTY_DS                = 16;
    ST_WAIT_PARTY_BD                = 17;
    ST_SONGS                        = 18;
    ST_DANCE                        = 19;
    ST_WAIT_PROVOKE                 = 20;
    ST_WAIT_DS_OFF                  = 21;

    TAR_BEETLE = 1018804; // гребаный жук посреди комнаты FOG

    SPEAR_ACCURACY = 422;


implementation

function NumHuman(s : string) : string;
var
    i, p : Integer;
begin
    i := Length(s);
    p := 1;
    Result := '';
    while i >= 1 do
    begin
        if (((p-1) mod 3) = 0) and (p>1) then Result := ' '+Result;
        Result := s[i] + Result;
        Dec(i);
        inc(p);
    end;
end;

{ TPluginImpl }

function TPluginImpl.AllBuffsDone: Boolean;
var
    i : Integer;
begin
    for i := 0 to 10 do
        if buffers[i] <> '' then begin
            Result := false;
            Exit;
        end;
    Result := true;
end;

procedure TPluginImpl.AttackMobParik(mobid: Integer);
var
    t : Integer;
begin
    // ищем моба в радиусе
    t := myEngine.Mobs.getNearMob(False, mobid, 500);
    say('atk: '+inttostr(t));
    if t <> 0 then
    begin
        myTarget := t;
        // начинаем атаку ближайшей цели
        SendAttack(myTarget);
        // надо дождатся успешной атаки на него. тобишь с дамагом
        main_state := ST_WAIT_MY_ATTACK_CHECKPOINT;
        my_parik_attack_count := 0;
        state_timer := 0;
    end else
        MoveNextPoint;
end;

procedure TPluginImpl.BeginFight;
var
    t : Integer;
begin
    if not active then Exit;

    say( 'begin fight ms='+inttostr(main_state));

    t := 0; //GetNextPrio;
//    if (t=0) and (need_getNearTarget > 0) then t := GetNextNearTarget;
    if t = 0 then t := GetNextParikTarget;
    if t = 0 then t := myEngine.Mobs.getNearMob(True);


  //  if (t = 0) and (main_state <> ST_KILL_PARIK) then t := GetNextTtarget;

    if t <> 0 then begin
        // еще есть кого атаковать
        myTarget := t;

        // смотрим сколько рядом со мной агромобов
        if (GetAgroCount < 4) and (myEngine.Me.WeaponEquipped <> SwordItemID) and (SwordItemID <> 0) then
            // если мобов уже осталось мало - оденем двуручник
            myEngine.Inventory.UseItem(SwordItemID);

        if (GetAgroCount <= 3) then begin
            if not myEngine.Me.HaveBuff(312) then myEngine.Me.UseSkill(312); // vicious stance (crit dmg)
//            if not myEngine.Me.HaveBuff(317) then myEngine.Me.UseSkill(317); // focus attack
        end;

        if (GetAgroCount >= 4) and (myEngine.Me.WeaponEquipped <> SpearItemID) and (SpearItemID <> 0) then
            myEngine.Inventory.UseItem(SpearItemID);

        // атакуем его!
        say('attack new target! '+inttostr(myTarget));
        SendAttack(myTarget);
        parik_kill_timer := 0;
    end else begin
        // всех убили
        if main_state = ST_KILL_PARIK then begin
            // абсурдная ситуация. должны убивать парик - но не кого атаковать
            say('******* no parik to kill! *********');
            
                        // убири парик. ждем дроп с него
                        main_state := ST_DROP_PARIK_WAIT;
                        state_timer := 0;

//            StopFightMode;
        end else begin
            say('no mobs, wait target *************');
        end;
    end;
end;

procedure TPluginImpl.BuffDone(msg: string);
var
    i : Integer;
begin
    say('other bot say: '+msg+', ms='+inttostr(main_state));
    if not active then exit;

    if msg = 'bd_done' then begin
        if bd_offparty then
            myEngine.Party.Dismiss(bd_name);

        // на момент когда бд даст данс - кот уже даст баф
        if kot_offparty and ds_serapate then
            myEngine.Party.Dismiss( Kot_name);

        if wc_offparty and (myEngine.Party.Exist(wc_name)) and ds_serapate then
            myEngine.Party.Dismiss( WC_name );
    end;
    
    if msg = 'sws_done' then begin
        if (sws_offparty) then
            myEngine.Party.Dismiss(SWS_name);
        if ds_serapate then Dance;
    end;

    if msg = 'ee_done' then begin
        if (ee_offparty) and (myEngine.Party.Exist(EE_name)) then
            myEngine.Party.Dismiss(EE_name);
    end;

    if main_state = ST_REBUFF then
    begin
        for i := 0 to 10 do
            if buffers[i] = msg then buffers[i] := '';
        if AllBuffsDone then begin
            // ребаф получен! даем сонг данс
            Songs;
        end;
    end;

    if main_state = ST_SONGS then begin
        for i := 0 to 10 do
            if buffers[i] = msg then buffers[i] := '';

        if AllBuffsDone and (not ds_serapate) then begin
        // на момент когда бд даст данс - кот уже даст баф
            if kot_offparty then
                myEngine.Party.Dismiss( Kot_name);

            if wc_offparty and (myEngine.Party.Exist(wc_name)) then
                myEngine.Party.Dismiss( WC_name );

            say('ds done!------------------------');
            kills_count := 0;
            gotoCollectParik;
        end;
    end;

    if main_state = ST_DANCE then begin
        for i := 0 to 10 do
            if buffers[i] = msg then buffers[i] := '';

        if AllBuffsDone then begin
            //sendmsg('ds done!!!!!!!!!!!');
            // начинаем убивать мобов
            say('ds done!------------------------');
            kills_count := 0;
            gotoCollectParik;
        end;
    end;

end;

function TPluginImpl.CallFunction(a: Integer; Params: Variant): Integer;
begin
    case a of
        FUNC_BUFF_DONE : begin
            BuffDone(Params);
        end;
    end;
    Result := 0;
end;

function TPluginImpl.CheckHPNeedRestore: Boolean;
begin
    Result := (
        ((next_move_state = ST_KILL_PLACE) and (myEngine.Me.Hppc < 95)) or (myEngine.Me.Hppc < 85)
        )
     and active and (hp_bottle > 0);
end;

procedure TPluginImpl.confirm_dlg(var pck: AnsiString; cn : string);
var
    p : TPacket;
begin
    if not active then exit;

    // меня ресают
    if ReadD(pck, 2) = 1510 then begin
        pck := '';
        // answer=1 id 1510
        p.Reset(#$C6#$E6#$05#$00#$00#$01#$00#$00#$00#$00#$00#$00#$00);
        p.SendToServer(cn);
        say('res! '+LinkedCharName);
    end;
end;

procedure TPluginImpl.Dance;
var
    n : string;
    i : Integer;
begin
    say('dance begin!');
    n := getPartyDance;
    if n <> '' then begin
        // берем в пати всех
        myEngine.Party.Invite(n);
        main_state := ST_WAIT_PARTY_BD;
    end else begin
        myEngine.Me.SayToChat(3, 'bd');

        for i := 0 to 10 do buffers[i] := '';
        main_state := ST_DANCE;
        buffers[0] := 'bd_done';

        RequestCov;
    end;
end;

destructor TPluginImpl.Destroy;
begin
    path1 := nil;
    path2 := nil;
    path1_base := nil;
    path2_base := nil;
    path := nil;
    
    inherited;
end;

function TPluginImpl.getAgroCount: Integer;
var
    i : Integer;
begin
    Result := 0;
    for i := 0 to myEngine.Mobs.Count - 1 do
        if (myEngine.Mobs[i].is_mob)
        and (not myEngine.Mobs[i].is_dead)
        and (myEngine.Mobs[i].is_agro)
        then
            Inc(result);
end;

function TPluginImpl.getIniFileName: string;
begin
    Result := AppPath + 'ini\destr_'+LinkedCharName+'.ini';
end;

function TPluginImpl.getMobsRespCount: Integer;
var
    d,  i : integer;
    r : Integer;
begin
    Result := 0;
    r := getRespRadius;

    for i := 0 to myEngine.Mobs.Count-1 do
    if myEngine.Mobs[i].is_mob
    and (not myEngine.Mobs[i].is_dead)
    then
    begin
        case CurrentResp of
            1 : d := resp1_point.Dist( myEngine.Mobs[i].pos );
            2 : d := resp2_point.Dist( myEngine.Mobs[i].pos );
            else d := 10000;
        end;

        if
        (d < r)
//        and (not IsIgnore(MobsID[ii]))
        then
        begin
            Result := Result+1
        end;
    end;
end;

function TPluginImpl.getNextParikTarget: Integer;
var
    min, min_dist, d, i : integer;
    mobs_ax, mobs_ay, mobs_acount : Integer;
    pv : TVec3i;
begin
    say('GetNextParikTarget count : '+inttostr(myEngine.Mobs.Count));
    mobs_acount := 0;
    mobs_ax := 0;
    mobs_ay := 0;

    for i := 0 to myEngine.Mobs.Count-1 do begin
        if (myEngine.Mobs[i].is_agro) and
        (not myEngine.Mobs[i].is_dead) and
        (myEngine.Mobs[i].is_mob) and
        (myEngine.Mobs[i].pos.Dist(myPos) < 150) and
        (myEngine.Mobs[i].npc_type <> TAR_BEETLE) // гребаный жук посреди комнаты
        then begin
            mobs_ax := mobs_ax + (myEngine.Mobs[i].pos.X - myPos.X);
            mobs_ay := mobs_ay + (myEngine.Mobs[i].pos.Y - myPos.Z);
            Inc(mobs_acount);
        end;
    end;

    say('mobs_acount : '+inttostr(mobs_acount));
    if mobs_acount = 0 then
    begin
        Result := 0;
        exit;
    end;

    mobs_ax := myPos.X + Round(mobs_ax / mobs_acount);
    mobs_ay := myPos.Y + Round(mobs_ay / mobs_acount);
    say('mobs point: '+inttostr(mobs_ax)+' '+inttostr(mobs_ay));

    min := 0;
    min_dist := 1000;

    for i := 0 to myEngine.Mobs.Count-1 do begin
        pv.X := mobs_ax;
        pv.Y := mobs_ay;
        pv.Z := myPos.Z;

        d := pv.Dist(myEngine.Mobs[i].pos);// get_mob_dist(i, mobs_ax, mobs_ay, myZ);
        if (myEngine.Mobs[i].is_agro) and
        (not myEngine.Mobs[i].is_dead) and
        (myEngine.Mobs[i].is_mob) and
        (myEngine.Mobs[i].pos.Dist(myPos) < 150) and
        (myEngine.Mobs[i].npc_type <> TAR_BEETLE) and // гребаный жук посреди комнаты
        (d < min_dist) then
        begin
            min := myEngine.Mobs[i].objid;
            min_dist := d;
        end;
    end;

    Result := min;
end;

function TPluginImpl.getPartyDance: string;
begin
    if (BD_name <> '') and (not myEngine.Party.Exist(BD_name)) then begin Result := BD_name; Exit; end;

    Result := '';
end;

function TPluginImpl.getPartyDS: string;
begin
    if (SWS_name <> '') and (not myEngine.Party.Exist(SWS_name)) then begin Result := SWS_name; Exit; end;
    if not ds_serapate then
    if (BD_name <> '') and (not myEngine.Party.Exist(BD_name)) then begin Result := BD_name; Exit; end;

    if (Kot_name <> '') and (not myEngine.Party.Exist(Kot_name)) then begin Result := Kot_name; Exit; end;
    if (wc_name <> '') and (not myEngine.Party.Exist(wc_name)) then begin Result := wc_name; Exit; end;
    Result := '';
end;

function TPluginImpl.getPartyFull: string;
begin
    if (SWS_name <> '') and (not myEngine.Party.Exist(SWS_name)) then begin Result := SWS_name; Exit; end;
    if (BD_name <> '') and (not myEngine.Party.Exist(BD_name)) then begin Result := BD_name; Exit; end;
    if (Kot_name <> '') and (not myEngine.Party.Exist(Kot_name)) then begin Result := Kot_name; Exit; end;
    if (wc_name <> '') and (not myEngine.Party.Exist(wc_name)) then begin Result := wc_name; Exit; end;
    if (ee_name <> '') and (not myEngine.Party.Exist(ee_name)) then begin Result := ee_name; Exit; end;
    if (tank_name <> '') and (not myEngine.Party.Exist(tank_name)) then begin Result := tank_name; Exit; end;
    if (spoiler_name <> '') and (not myEngine.Party.Exist(spoiler_name)) then begin Result := spoiler_name; Exit; end;

    if (Name1 <> '') and (not myEngine.Party.Exist(Name1)) then begin Result := Name1; Exit; end;
    if (Name2 <> '') and (not myEngine.Party.Exist(Name2)) then begin Result := Name2; Exit; end;
    if (Name3 <> '') and (not myEngine.Party.Exist(Name3)) then begin Result := Name3; Exit; end;
    if (Name4 <> '') and (not myEngine.Party.Exist(Name4)) then begin Result := Name4; Exit; end;

    Result := '';
end;

function TPluginImpl.getPath(pn: Integer): PMovePath;
begin
    case pn of
        1 : Result := @path1;
        2 : Result := @path2;
        3 : Result := @path1_base;
        4 : Result := @path2_base;
        else Result := @path1;
    end;
end;

function TPluginImpl.getPathName(pn: Integer): string;
begin
    case pn of
        1 : Result := 'path1';
        2 : Result := 'path2';
        3 : Result := 'path1_base';
        4 : Result := 'path2_base';
        else Result := 'path1';
    end;
end;

function TPluginImpl.getRespRadius: Integer;
begin
    case CurrentResp of
        1 : Result := resp1_point.Dist( resp1_radius_point );
        2 : Result := resp2_point.Dist( resp2_radius_point );
        else Result := resp1_point.Dist( resp1_radius_point );
    end;
end;

procedure TPluginImpl.get_item(var pck: AnsiString);
var
    id : Integer;
begin
    if not active then exit;

   // 2 player  id
   // вещь поднял я
   if ReadD(pck, 2) = myID then begin
        // 6 - obj id
//        id := ReadD(pck, 6);

        id := myEngine.Drop.myNear;
        // берем следующий дроп
        if main_state = ST_DROP_PARIK then
        begin
            state_timer := 0;
            say('next parik drop: '+inttostr(id));
        end;

        // если поднимать больше нечего
        if id = 0 then begin
            say('get item: all drop collected ms='+inttostr(main_state));
            if main_state <> ST_KILL_PARIK then
                GoToBase
        end
        else begin
            myDrop := id;
            //main_state := ST_DROP_UP;
            // есть что поднять - идем и подбираем
            myEngine.Me.Action(myDrop);
        end;
   end;
end;

procedure TPluginImpl.gotoBase;
var
    i : Integer;
    pm : PMovePath;
begin
    say('go to base ms='+inttostr(main_state));
    
    if myEngine.Me.HaveBuff(312) then myEngine.Me.UseSkill(312); // vicious stance (crit dmg)
    if myEngine.Me.HaveBuff(317) then myEngine.Me.UseSkill(317); // focus attack
    if myEngine.Me.HaveBuff(SPEAR_ACCURACY) then myEngine.Me.UseSkill(SPEAR_ACCURACY); 

    path := nil;
    pm := getPath(2+CurrentResp);
    active := true;

    SetLength( path, Length(pm^) );
    for i := 0 to Length(pm^)-1 do
    begin
        path[i] := pm^[i];
    end;

    if spoiler_name <> '' then
        core.PluginCallFunction(SPOILER_PLUGIN_NAME, FUNC_GOTO_BASE, 0);

    CurrentPointDist := 100;
    path_index := -1;
    next_move_state := ST_SPOT;
    MoveNextPoint;

end;

procedure TPluginImpl.gotoCollectParik;
var
    i : Integer;
    pm : PMovePath;

begin
    say('go to collect parik ms='+inttostr(main_state));
//    exit;

    path := nil;
    pm := getPath(CurrentResp);
    active := true;

    SetLength( path, Length(pm^) );
    for i := 0 to Length(pm^)-1 do
    begin
        path[i] := pm^[i];
    end;

    // одеваем двуручник чтобы заагрить моба
    if (myEngine.Me.WeaponEquipped <> SwordItemID) and (SwordItemID <> 0) then
        myEngine.Inventory.UseItem(SwordItemID);

    CurrentPointDist := 150;
    path_index := -1;
    next_move_state := ST_KILL_PLACE;
    MoveNextPoint;
end;

procedure TPluginImpl.gotoTestPath(pn: Integer);
var
    i : Integer;
    pm : PMovePath;
begin
    say('go to path '+inttostr(pn)+' ms='+inttostr(main_state));
    // строим путь для движения
    path := nil;
    pm := getPath(pn);
    active := true;

    SetLength( path, Length(pm^) );
    for i := 0 to Length(pm^)-1 do
    begin
        path[i] := pm^[i];
    end;

    path_index := -1;
    next_move_state := ST_IDLE;
    MoveNextPoint;
end;

procedure TPluginImpl.html_select(var pck : AnsiString);
var
    sn, sp, ps : string;
    sk, pn, i, j : Integer;
    pm : PMovePath;
    function get_sint : Integer;
    begin
        sp := sn;
        if Pos(' ', sp) > 0 then begin
            Delete(sp, 1, Pos(' ', sp));
            sk := StrToIntDef(sp, 0);
        end else sk := 0;
        Result := sk;
    end;
begin
sn := ReadS(pck, 2);

// все что начинается с bb - игнорим и не шлем серверу чтобы не палится
if (sn[1] = 'b') and (sn[2] = 'b') then begin
    pck := '';
    myEngine.botSay( 'html sel : '+sn );

    if sn = 'bb_soulshot' then begin
        ShowOptionsSoulshot;
    end;


    if sn = 'bb_show_resp1_mobs' then begin
        j := CurrentResp;
        CurrentResp := 1;
        myEngine.botSay('mobs='+inttostr(GetMobsRespCount));
        CurrentResp := j;
        ShowOptions;
    end;
    if sn = 'bb_show_resp2_mobs' then begin
        j := CurrentResp;
        CurrentResp := 2;
        myEngine.botSay('mobs='+inttostr(GetMobsRespCount));
        CurrentResp := j;
        ShowOptions;
    end;

    if Pos('_enable', sn) > 0 then begin
        pn := Pos('_enable', sn);
        Delete(sn, pn, Length(sn)-pn+1);
        Delete(sn, 1, 3);
        say('sn='+sn);
        if sn='sws_off' then sws_offparty := True;
        if sn='bd_off' then bd_offparty := True;
        if sn='ee_off' then ee_offparty := True;
        if sn='wc_off' then wc_offparty := True;
        if sn='kot_off' then kot_offparty := True;
        if sn='tank_off' then tank_offparty := True;
        if sn='spoiler_off' then spoiler_offparty := True;
        if sn='ds_serapate' then ds_serapate := True;
        if sn='wait_ds_off' then wait_ds_off := True;

        SaveOptions;
        ShowOptions;
    end;
    if Pos('_disable', sn) > 0 then begin
        pn := Pos('_disable', sn);
        Delete(sn, pn, Length(sn)-pn+1);
        Delete(sn, 1, 3);
        say('sn='+sn);
        if sn='sws_off' then sws_offparty := False;
        if sn='bd_off' then bd_offparty := False;
        if sn='ee_off' then ee_offparty := False;
        if sn='wc_off' then wc_offparty := False;
        if sn='kot_off' then kot_offparty := False;
        if sn='tank_off' then tank_offparty := False;
        if sn='spoiler_off' then spoiler_offparty := False;
        if sn='ds_serapate' then ds_serapate := False;
        if sn='wait_ds_off' then wait_ds_off := False;
        
        SaveOptions;
        ShowOptions;
    end;


    if Pos('bb_set_atkrequired', sn) > 0 then begin
        parik_atk_required := get_sint;
        SaveOptions;
        ShowOptions;
    end;

    if Pos('bb_set_sword_id', sn) > 0 then begin
        SwordItemID := get_sint;
        SaveOptions;
        ShowOptions;
    end;
    if Pos('bb_set_spear_id', sn) > 0 then begin
        SpearItemID := get_sint;
        SaveOptions;
        ShowOptions;
    end;

    if Pos('bb_set_minmobs', sn) > 0 then begin
        min_mobs_resp := get_sint;
        SaveOptions;
        ShowOptions;
    end;

    if Pos('bb_set_rageskill', sn) > 0 then begin
        rage_skill := get_sint;
        SaveOptions;
        ShowOptions;
    end;
    if Pos('bb_set_provokeskill', sn) > 0 then begin
        provoke_skill := get_sint;
        SaveOptions;
        ShowOptions;
    end;
    if Pos('bb_set_dsskill', sn) > 0 then begin
        ds_skill := get_sint;
        SaveOptions;
        ShowOptions;
    end;
    if Pos('bb_set_resp_count', sn) > 0 then begin
        resp_count := get_sint;
        SaveOptions;
        ShowOptions;
    end;
    if Pos('set_atkchk', sn) > 0 then begin
        atk_required_chk_point := get_sint;
        SaveOptions;
        ShowOptions;
    end;
    if Pos('bb_set_hpbottle', sn) > 0 then begin
        hp_bottle := get_sint;
        SaveOptions;
        ShowOptions;
    end;
    //-----------
    if sn = 'bb_goto_resp1' then begin
        myEngine.Me.MoveBackwardToLocation( resp1_point );
//        ShowOptions;
    end;

    if sn = 'bb_set_resp1' then begin
        resp1_point := myPos;
        SaveOptions;
//        ShowOptions;
    end;
    if sn = 'bb_set_resp1_radius' then begin
        resp1_radius_point := myPos;
        SaveOptions;
//        ShowOptions;
    end;
    if sn = 'bb_goto_resp1_radius' then begin
        myEngine.Me.MoveBackwardToLocation(resp1_radius_point);
//        ShowOptions;
    end;
    //-----------
    if sn = 'bb_goto_resp2' then begin
        myEngine.Me.MoveBackwardToLocation( resp2_point );
//        ShowOptions;
    end;
    if sn = 'bb_set_resp2' then begin
        resp2_point := myPos;
        SaveOptions;
//        ShowOptions;
    end;
    if sn = 'bb_set_resp2_radius' then begin
        resp2_radius_point := myPos;
        SaveOptions;
//        ShowOptions;
    end;
    if sn = 'bb_goto_resp2_radius' then begin
        myEngine.Me.MoveBackwardToLocation(resp2_radius_point);
//        ShowOptions;
    end;
    //---------
    if sn = 'bb_goto_drop1' then begin
        myEngine.Me.MoveBackwardToLocation(drop1_point);
//        ShowOptions;
    end;

    if sn = 'bb_set_drop1' then begin
        drop1_point := myPos;
        SaveOptions;
//        ShowOptions;
    end;
    //---------
    if sn = 'bb_goto_drop2' then begin
        myEngine.Me.MoveBackwardToLocation(drop2_point);
//        ShowOptions;
    end;

    if sn = 'bb_set_drop2' then begin
        drop2_point := myPos;
        SaveOptions;
//        ShowOptions;
    end;

    // soulshots ----------------------------------------
    if Pos('bb_ss_select', sn) > 0 then begin
        ps := sn;
        Delete(ps, 1, 13);
        pn := strtoint(ps);
        soulshot_id := pn;
        say('ss selected : '+inttostr(soulshot_id));
        ShowOptionsSoulshot;
        SaveOptions;
    end;


    // path1 -------------
    if Pos('bb_path', sn) > 0 then begin
        ps := sn;
        Delete(ps, 1, 7);
        Delete(ps, 2, Length(ps) -1 );
        pn := strtoint(ps);
        pm := getPath(pn);
        Delete(sn, 1, 8);
        say('bb path num: '+inttostr(pn) + ' action='+sn);

        if sn = '_reload' then begin
            LoadPath(pn);
            ShowOptionsPath(pn);
        end;

        if sn = '_run' then begin
            GoToTestPath(pn);
        end;
        if sn = '_edit' then begin
            ShowOptionsPath(pn);
        end;

        if Pos('_goto', sn) > 0 then begin
            Delete(sn, 1, 6);
            say('path '+inttostr(pn)+' goto:'+sn);
            sk := strtoint(sn);

            myEngine.Me.MoveBackwardToLocation( pm^[sk].pos );
            ShowOptionsPath(pn);
        end;

        if Pos('_replace', sn) > 0 then begin
            Delete(sn, 1, 9);
            say('path '+inttostr(pn)+' replace:'+sn);
            sk := strtoint(sn);

            pm^[sk].pos := myPos;
            if myEngine.Me.CurrentTarget <> 0 then begin
                if myEngine.Me.CurrentTarget = myID then
                    pm^[sk].mob_atk := 1
                else
                    pm^[sk].mob_atk := myEngine.Mobs.ItemsByObjID[ myEngine.Me.CurrentTarget ].npc_type;
            end else
                pm^[sk].mob_atk := 0;

            SavePath(pn);
            ShowOptionsPath(pn);
        end;

        if Pos('_add', sn) > 0 then begin
            SetLength(pm^, Length(pm^)+1);
            i := High(pm^);
            pm^[i].pos := myPos;
            if myEngine.Me.CurrentTarget <> 0 then
                pm^[i].mob_atk := myEngine.Mobs.ItemsByObjID[ myEngine.Me.CurrentTarget ].npc_type
            else
                pm^[i].mob_atk := 0;

            SavePath(pn);
            ShowOptionsPath(pn);
        end;

        if Pos('_delete', sn) > 0 then begin
            Delete(sn, 1, 8);
            say( 'path 1 delete:'+sn);
            sk := strtoint(sn);

            for i := sk+1 to Length(pm^)-1 do
            begin
                pm^[i-1] := pm^[i];
            end;
            SetLength(pm^, length(pm^)-1);

            SavePath(pn);
            ShowOptionsPath(pn);
        end;
    end;
end;
end;

procedure TPluginImpl.Init;
begin
    main_state := ST_IDLE;
    active := false;
    state_timer := 0;

    name1 := '';
    name2 := '';
    name3 := '';
    name4 := '';

    kills_count := 0;
    total_kills_count := 0;
    CurrentPointDist := 100;
    soulshot_id := 0;

    UpdateNames;
    LoadOptions;
end;

function TPluginImpl.isDsOff: Boolean;
begin
    Result := False;
    if myEngine.Me.HaveBuff(271) then exit;
    if myEngine.Me.HaveBuff(274) then exit;
    if myEngine.Me.HaveBuff(275) then exit;
    if myEngine.Me.HaveBuff(310) then exit;
    if myEngine.Me.HaveBuff(366) then exit;
    if myEngine.Me.HaveBuff(915) then exit;
    if myEngine.Me.HaveBuff(276) then exit;
    if myEngine.Me.HaveBuff(272) then exit;
    if myEngine.Me.HaveBuff(349) then exit;
    if myEngine.Me.HaveBuff(364) then exit;
    if myEngine.Me.HaveBuff(304) then exit;
    if myEngine.Me.HaveBuff(267) then exit;
    if myEngine.Me.HaveBuff(269) then exit;
    if myEngine.Me.HaveBuff(264) then exit;
    if myEngine.Me.HaveBuff(268) then exit;
    if myEngine.Me.HaveBuff(363) then exit;

    Result := True;
end;

procedure TPluginImpl.join_party(var pck: AnsiString);
begin
    // если в пати вошел ктото и мы ждем фулл пати - запускаем ребаф
    if main_state = ST_WAIT_PARTY_FULL then Rebuff;

    if main_state = ST_WAIT_PARTY_DS then Songs;
    if main_state = ST_WAIT_PARTY_BD then Dance;
end;

procedure TPluginImpl.LoadOptions;
var
    ini : TIniFile;
begin
    ini := TIniFile.Create( getIniFileName );

    ds_serapate := ini.ReadBool('main', 'ds_serapate', true);
    wait_ds_off := ini.ReadBool('main', 'wait_ds_off', false);
    resp1_point.fromString( ini.ReadString('main','resp1_point', '0, 0, 0') );
    resp1_radius_point.fromString( ini.ReadString('main','resp1_radius_point', '0, 0, 0') );
    resp2_point.fromString( ini.ReadString('main','resp2_point', '0, 0, 0') );
    resp2_radius_point.fromString( ini.ReadString('main','resp2_radius_point', '0, 0, 0') );
    base_point.fromString( ini.ReadString('main','base_point', '0, 0, 0') );
    drop1_point.fromString( ini.ReadString('main','drop1_point', '0, 0, 0') );
    drop2_point.fromString( ini.ReadString('main','drop2_point', '0, 0, 0') );

    sws_offparty := ini.ReadBool('main', 'sws_offparty', false);
    bd_offparty := ini.ReadBool('main', 'bd_offparty', false);
    wc_offparty := ini.ReadBool('main', 'wc_offparty', false);
    ee_offparty := ini.ReadBool('main', 'ee_offparty', false);
    kot_offparty := ini.ReadBool('main', 'kot_offparty', false);
    spoiler_offparty := ini.ReadBool('main', 'spoiler_offparty', false);
    tank_offparty := ini.ReadBool('main', 'tank_offparty', false);


    SwordItemID := ini.ReadInteger('main', 'sword_item_id', 0);
    SpearItemID := ini.ReadInteger('main', 'spear_item_id', 0);
    min_mobs_resp := ini.ReadInteger('main', 'min_mobs_resp', 0);
    parik_atk_required := ini.ReadInteger('main', 'parik_atk_required', 0);
    rage_skill := ini.ReadInteger('main', 'rage_skill', 0);
    provoke_skill := ini.ReadInteger('main', 'provoke_skill', 0);
    ds_skill := ini.ReadInteger('main', 'ds_skill', 0);
    resp_count := ini.ReadInteger('main', 'resp_count', 1);
    atk_required_chk_point := ini.ReadInteger('main', 'atk_required_chk_point', 1);
    hp_bottle := ini.ReadInteger('main', 'hp_bottle', 0);
    soulshot_id := ini.ReadInteger('main', 'soulshot_id', 0);

    ini.Free;
    
    LoadPath(1);
    LoadPath(2);
    LoadPath(3);
    LoadPath(4);
end;

procedure TPluginImpl.LoadPath(pn: Integer);
var
    ini : TIniFile;
    c, i : Integer;
    pname : string;
    pm : PMovePath;
begin
    ini := TIniFile.Create( getIniFileName );
    pname := getPathName(pn);
    pm := getPath(pn);
    // load path 
    c := ini.ReadInteger(pname, 'count', 0);
    SetLength(pm^, c);
    for i := 0 to c - 1 do
    begin
        pm^[i].pos.fromString( ini.ReadString(pname,'point'+inttostr(i)+'_p', '0, 0, 0') );
        pm^[i].mob_atk := ini.ReadInteger(pname,'point'+inttostr(i)+'_atk', 0);
    end;
    ini.Free;
end;

procedure TPluginImpl.magic_skill_launched(var pck: AnsiString);
var
    skill : Integer;
begin
    if ReadD(pck, 2) = myID then begin
        skill := ReadD(pck, 6);
        if (skill = RAGE_SKILL) and (skill <> 0)
        and (main_state in [ST_KILL_PARIK, ST_DROP_PARIK, ST_DROP_PARIK_WAIT]) then begin
            BeginFight;
        end;

        // если заюзали агр - бежим дальше
        if (main_state = ST_WAIT_PROVOKE) and (skill = PROVOKE_SKILL) then
        begin
            MoveNextPoint;
        end;
    end;
end;

procedure TPluginImpl.mob_attack(var pck: AnsiString);
var
    id, t : Integer;
begin
    // 2 who
    id := ReadD(pck, 2);
    // 6 target
    t := ReadD(pck, 6);

    // моб атакует меня
    if t = myID then begin

        if main_state = ST_WAIT_PARIK_ATTACK then begin
            parik_attack_count := parik_attack_count + 1;
            say('parik atk me : '+inttostr(parik_attack_count));
            // если парик ударил нас больше раз, начинаем его хуярить
            if (parik_attack_count >= parik_atk_required) or (myEngine.Me.Hppc < 40) then begin
                say('my hp : '+inttostr(myEngine.Me.Hppc));
                main_state := ST_KILL_PARIK;
                BeginFight;
            end;
        end;

        if (main_state in [ST_DROP_PARIK, ST_DROP_PARIK_WAIT, ST_WAIT_MOBS_RESP])
        or ((main_state = ST_MOVE_BY_PATH) and (next_move_state = ST_SPOT))
        then begin
            // парик таки привели. ща надо его убить
            main_state := ST_KILL_PARIK;
            say('begin fight when drop...');
            BeginFight;
        end;

        // ждем удара моба на контрольной точке
//        if (main_state = ST_WAIT_MY_ATTACK_CHECKPOINT) and (id = myTarget) then begin
//            MoveNextPoint;
//        end;

    end;

    // если атакую я, и нанес дамагу
    if (id = myID) and (ReadD(pck, 10) > 0) then begin

        if (main_state = ST_KILL_PARIK) and (spoiler_name <> '') then begin
            inc(my_parik_attack_count);
        end;
        
        // ждем удара моба на контрольной точке
        if (main_state = ST_WAIT_MY_ATTACK_CHECKPOINT) then begin
            inc(my_parik_attack_count);
            if (my_parik_attack_count > atk_required_chk_point) then
                MoveNextPoint;
        end;
    end;
end;

procedure TPluginImpl.mob_die(var pck: AnsiString);
var
    id, t : Integer;
begin
    id := ReadD(pck, 2);

    if id = myID then begin
        // мы сдохли))
        state_timer := 0;
        main_state := ST_DIE;

//        StopFightMode;
        say( 'epic fail......');
    end else begin
        Inc(kills_count);
        inc(total_kills_count);
    end;

    if (id = myTarget) and (active) then begin
        if ( //(main_state = ST_KILL) or
        (main_state = ST_KILL_PARIK) ) then
        begin
    //        t := 0;//GetNextPrio;
            t := getNextParikTarget;
            if t = 0 then t := myEngine.Mobs.getNearMob(True);
            if (t <> 0) then BeginFight
            else begin
                    // всех убили
                    say( 'all killed! '+inttostr(kills_count)+' / '+inttostr(total_kills_count));
                    // нет больше агро мобов рядом, можно собирать лут
                    if main_state = ST_KILL_PARIK then begin
                        // убири парик. ждем дроп с него
                        main_state := ST_DROP_PARIK_WAIT;
                        state_timer := 0;
                    end else begin
                        t := myEngine.Drop.myNear;
                        if (t = 0) then  begin
                            // собрали весь дроп
                            BeginFight;
                        end
                        else begin
                            // еще есть не собранный дроп. надо бы его собрать
                            say('pick up my drop...');
                            state_timer := 0;
                            myDrop := t;
                            // собираем дроп с парика
                            PickUpParikDrop;
                        end;
                    end;
            end;
        end;
        
        if (main_state = ST_WAIT_MY_ATTACK_CHECKPOINT) then
        begin
            MoveNextPoint;
        end;
        
    end;
end;

procedure TPluginImpl.MoveNextPoint;
begin
    if not active then Exit;

    Inc(path_index);
    if path_index >= Length(path) then
    begin
        say( 'path end');
        // прибежали на место

        if next_move_state = ST_SPOT then begin
//            if havebuff(312) then MagicSkillUse(name, 312); // vicious stance (crit dmg)
//            if havebuff(422) then MagicSkillUse(name, 422); // accuracy

            CurrentResp := CurrentResp+1;
            if CurrentResp > resp_count then CurrentResp := 1;

            // пришли на спот.
            WaitMobsResp;
        end;

        if next_move_state = ST_KILL_PLACE then
        begin
            main_state := ST_WAIT_PARIK_ATTACK;
            parik_attack_count := 0;

            // одеваем копье для убивания парика
            if (myEngine.Me.WeaponEquipped <> SpearItemID) and (SpearItemID <> 0) then
                myEngine.Inventory.UseItem(SpearItemID);

//            if not havebuff(312) then MagicSkillUse(name, 312); // vicious stance (crit dmg)
//            if not havebuff(422) then MagicSkillUse(name, 422); // accuracy

            if not myEngine.Me.HaveBuff(SPEAR_ACCURACY) then myEngine.Me.UseSkill(SPEAR_ACCURACY); 
            if (rage_skill <> 0) and (not myEngine.Me.HaveBuff(rage_skill)) then PrepareToFight;
        end;

        if next_move_state = ST_IDLE then
        begin
            StopFightMode;
        end;

        next_move_state := ST_IDLE;

    end else begin
        // если это последняя точка пути - надо остановится точно в нужной точке
        if path_index >= (Length(path)-1) then
            CurrentPointDist := 50;

        main_state := ST_MOVE_BY_PATH;
        current_move_point := path[path_index].pos;
        state_timer := 0;
        myEngine.Me.MoveBackwardToLocation(current_move_point);
    end;

end;

procedure TPluginImpl.onClientChatSay(var pck: AnsiString);
var
    msg : string;
//    ch : Integer;
begin
    msg := ReadS(pck, 2);
//    ch := ReadD(pck, 6);

    if msg='.a' then StartFightMode;
    if msg='.d' then StopFightMode;
    if msg='.o' then ShowOptions;

    if msg[1]='.' then pck := '';
end;

procedure TPluginImpl.onTimer(id: Integer);
var
    t, i, item_id : Integer;
    sp : string;
    f : Boolean;
begin
    if (id=1) then begin
        if not active then exit;
        buff_timer := buff_timer + 500;

        if (myEngine.Me.Hppc < 65) 
        and (not (main_state in [ST_DIE, ST_MOVE_BY_PATH, ST_WAIT_MY_ATTACK_CHECKPOINT])) then
        if myEngine.Me.Skills[121].isReady then
            myEngine.Me.UseSkill(121); // battle roar

        if (myEngine.Me.Hppc < 29) and (main_state <> ST_DIE) then
        if myEngine.Me.Skills[139].isReady then
            myEngine.Me.UseSkill(139); // guts
        //    if (h < 20) and (SpoilerScript <> '') and (main_state = ST_KILL_PARIK) then
        //        CallSF(SpoilerScript, 'FakeDeath', nil);

        sp := Palevo;
        if sp <> '' then begin
            myEngine.botSay( 'WARNING! palevo : '+sp, 18);
            StopFightMode;
            exit;
        end;
    case main_state of

        ST_KILL_PARIK : begin
            Inc(parik_kill_timer);
            if parik_kill_timer > 3 then begin
                BeginFight;
            end;

            if spoiler_name <> '' then
            begin
                if my_parik_attack_count > 8 then begin
                    my_parik_attack_count := 0;
                    if spoiler_name <> '' then core.PluginCallFunction(SPOILER_PLUGIN_NAME, FUNC_SPOIL_FESTIVAL, myTarget);
                end;
            end;


            if (rage_skill <> 0) and (not myEngine.Me.HaveBuff(RAGE_SKILL)) then PrepareToFight;
        end;

        ST_WAIT_MY_ATTACK_CHECKPOINT : begin
            Inc(state_timer);
            // если мы так и не смогли ударить моба - бежим дальше
            if (state_timer > 7) and (my_parik_attack_count = 0) then
                MoveNextPoint
            else
                SendAttack(myTarget);
        end;

        ST_DROP_PARIK : begin
            f := false;
            for i := 0 to myEngine.Drop.Count - 1 do
                if myEngine.Drop.Items[i].objid = myDrop then begin
                    f := True;
                    Break;
                end;

            // дроп не найден. возможно удален объект
            if not f then begin
                item_id := myEngine.Drop.myNear;
                // берем следующий дроп
                state_timer := 0;
                say('next parik drop: '+inttostr(item_id));

                // если поднимать больше нечего
                if item_id = 0 then begin
                    say('get item: all drop collected ms='+inttostr(main_state));
                    if main_state <> ST_KILL_PARIK then
                        GoToBase
                end else begin
                    myDrop := item_id;
                    myEngine.Me.Action(myDrop);
                end;
            end else
                myEngine.Me.Action(myDrop);

            Inc(state_timer);
            say( 'wait drop '+inttostr(state_timer));
            if state_timer > 5 then begin
                    case CurrentResp of
                        1 : myEngine.Me.MoveBackwardToLocation(drop1_point);
                        2 : myEngine.Me.MoveBackwardToLocation(drop2_point);
                    end;
                    state_timer := 0;
            end;
        end;

        ST_DROP_PARIK_WAIT : begin
            inc(state_timer);
            say('wait parik drop: '+inttostr(state_timer));
            if state_timer > 2 then begin
                t := myEngine.Drop.myNear;
                if t > 0 then begin
                    myDrop := t;
                    PickUpParikDrop;
                end else begin
                    GoToBase;
                end;
            end;

        end;

        ST_MOVE_BY_PATH : begin
            Inc(state_timer);
            say('move timer: '+inttostr(state_timer));
            if state_timer > 2 then begin
                state_timer := 0;
                say('retry move point');
                myEngine.me.MoveBackwardToLocation( current_move_point );
            end;

        end;

        ST_WAIT_MOBS_RESP : begin
            t := GetMobsRespCount;
            say('wait mobs : ' + inttostr(t));
            if t >= min_mobs_resp then SpotNext;

            if myEngine.Me.Mppc < 90 then RequestMP;
        end;

        ST_DIE : begin
            Inc(state_timer);
            say('die wait : '+inttostr(state_timer));
            if state_timer > 360 then begin
                RequestRes;
            end;
        end;

        ST_WAIT_DS_OFF : begin
            say('wait ds off...');
            if isDsOff then WaitMobsResp;
        end;
    end;
    end;

    // hp timer
    if id =2 then begin
        if CheckHPNeedRestore then
            myEngine.Inventory.UseItem(hp_bottle)
        else
            TimerStop(2);
    end;
end;

procedure TPluginImpl.SaveOptions;
var
    ini : TIniFile;
begin
    ini := TIniFile.Create( getIniFileName );

    ini.WriteBool('main', 'ds_serapate', ds_serapate);
    ini.WriteBool('main', 'wait_ds_off', wait_ds_off);

    ini.WriteString('main','resp1_point', resp1_point.toString);
    ini.WriteString('main','resp1_radius_point', resp1_radius_point.toString);
    ini.WriteString('main','resp2_point', resp2_point.toString);
    ini.WriteString('main','resp2_radius_point', resp2_radius_point.toString);
    ini.WriteString('main','base_point', base_point.toString);
    ini.WriteString('main','drop1_point', drop1_point.toString);
    ini.WriteString('main','drop2_point', drop2_point.toString);

    ini.WriteBool('main', 'sws_offparty', sws_offparty);
    ini.WriteBool('main', 'bd_offparty', bd_offparty);
    ini.WriteBool('main', 'ee_offparty', ee_offparty);
    ini.WriteBool('main', 'wc_offparty', wc_offparty);
    ini.WriteBool('main', 'kot_offparty', kot_offparty);
    ini.WriteBool('main', 'tank_offparty', tank_offparty);
    ini.WriteBool('main', 'spoiler_offparty', spoiler_offparty);


    ini.WriteInteger('main', 'sword_item_id', SwordItemID);
    ini.WriteInteger('main', 'spear_item_id', SpearItemID);
    ini.WriteInteger('main', 'min_mobs_resp', min_mobs_resp);
    ini.WriteInteger('main', 'parik_atk_required', parik_atk_required);
    ini.WriteInteger('main', 'rage_skill', rage_skill);
    ini.WriteInteger('main', 'provoke_skill', provoke_skill);
    ini.WriteInteger('main', 'ds_skill', ds_skill);
    ini.WriteInteger('main', 'resp_count', resp_count);
    ini.WriteInteger('main', 'atk_required_chk_point', atk_required_chk_point);
    ini.WriteInteger('main', 'hp_bottle', hp_bottle);
    ini.WriteInteger('main', 'soulshot_id', soulshot_id);

    ini.Free;
end;

procedure TPluginImpl.SavePath(pn: Integer);
var
    ini : TIniFile;
    i : Integer;
    pname : string;
    pm : PMovePath;
begin
    ini := TIniFile.Create( getIniFileName );
    pname := getPathName(pn);
    pm := getPath(pn);

    // load path
    ini.WriteInteger(pname, 'count', Length(pm^));
    for i := 0 to Length(pm^) - 1 do
    begin
        ini.WriteString(pname,'point'+inttostr(i)+'_p', pm^[i].pos.toString);
        ini.WriteInteger(pname,'point'+inttostr(i)+'_atk', pm^[i].mob_atk);
    end;
    ini.Free;
end;

procedure TPluginImpl.say(m: string);
begin
    myEngine.botSay(m);
end;

procedure TPluginImpl.SendAttack(objid: Integer);
begin
    myEngine.Me.Action(objid);
    myEngine.Me.Action(objid);
end;

procedure TPluginImpl.ShowOptions;
var
    ss, col : string;

    procedure show_bool(name : string; val : Boolean; bb_name : string);
    begin
        if val then
            col := 'FFFFFF'
        else
            col := '606066';

        ss := ss+
        '<table><tr><td width=90 height=32><font color="'+col+'">'+name+'</font></td>';

        if val then
            ss := ss+'<td><button action="bypass bb_'+bb_name+'_disable" value="Disable"'+
            'width=70 height=25 back="L2UI_CT1.Button_DF_Down" fore="L2UI_CT1.Button_DF"></td></tr>'
        else
            ss := ss+'<td><button action="bypass bb_'+bb_name+'_enable" value="Enable"'+
            'width=70 height=25 back="L2UI_CT1.Button_DF_Down" fore="L2UI_CT1.Button_DF"></td></tr>';
        ss := ss + '</table>';
    end;

    procedure show_int(name : string; val : Integer; bb_val, bb_name : string);
    begin
        ss := ss+
        '<table><tr><td width=150 height=32>'+name+' '+inttostr(val)+'</td>'+
        '<td><edit var='+bb_val+' width=40 type=number></td>'+

        '<td><button action="bypass bb_'+bb_name+' $'+bb_val+'" value="Set"'+
        'width=50 height=25 back="L2UI_CT1.Button_DF_Down" fore="L2UI_CT1.Button_DF"></td></tr></table>';
    end;

    procedure show_path(name : string; bb_name : string);
    begin
        ss :=ss +
        '<table><tr><td width=100>'+name+'</td>'+

        '<td><button action="bypass bb_'+bb_name+'_run" value="Run"'+
        'width=50 height=25 back="L2UI_CT1.Button_DF_Down" fore="L2UI_CT1.Button_DF"></td>'+

        '<td><button action="bypass bb_'+bb_name+'_edit" value="Edit"'+
        'width=50 height=25 back="L2UI_CT1.Button_DF_Down" fore="L2UI_CT1.Button_DF"></td>'+
        '</tr></table>';
    end;

    procedure show_point(name, bb_name : string);
    begin
        ss :=ss +
        '<table><tr><td width=100>'+name+'</td>'+

        '<td><button action="bypass bb_goto_'+bb_name+'" value="GoTo"'+
        'width=50 height=25 back="L2UI_CT1.Button_DF_Down" fore="L2UI_CT1.Button_DF"></td>'+

        '<td><button action="bypass bb_set_'+bb_name+'" value="Set"'+
        'width=50 height=25 back="L2UI_CT1.Button_DF_Down" fore="L2UI_CT1.Button_DF"></td>'+
        '</tr></table>';
    end;

    procedure show_btn(name, bb_name : string);
    begin
        ss :=ss +
        '<table><tr>'+

        '<td><button action="bypass bb_'+bb_name+'" value="'+name+'"'+
        'width=100 height=25 back="L2UI_CT1.Button_DF_Down" fore="L2UI_CT1.Button_DF"></td>'+

        '</tr></table>';
    end;

begin
    ss := '<html><body>'+
    '<title>Parik killer</title>';

//-------
    ss := ss + 'kills : '+ inttostr(kills_count)+' / '+inttostr(total_kills_count) +
    '   weapon : '+inttostr(myEngine.Me.WeaponEquipped)+
    '  adena : '+NumHuman(inttostr(myEngine.Drop.AdenaReceived));


//----------
    show_point('Resp 1', 'resp1');
    show_point('Resp 1 radius', 'resp1_radius');
    show_point('Resp 2', 'resp2');
    show_point('Resp 2 radius', 'resp2_radius');
//--------------------------------
    ss :=ss +
    '<br><button action="bypass bb_show_resp1_mobs" value="Mobs on resp 1?"'+
    'width=150 height=25 back="L2UI_CT1.Button_DF_Down" fore="L2UI_CT1.Button_DF">';
    ss :=ss +
    '<br><button action="bypass bb_show_resp2_mobs" value="Mobs on resp 2?"'+
    'width=150 height=25 back="L2UI_CT1.Button_DF_Down" fore="L2UI_CT1.Button_DF">';
//-----------
    show_point('Drop 1', 'drop1');
    show_point('Drop 2', 'drop2');
//----------
    show_path('Path 1', 'path1');
    show_path('Path 2', 'path2');
    show_path('Path 1 base', 'path3');
    show_path('Path 2 base', 'path4');
//-------
    show_int( 'resp mobs', min_mobs_resp, 'respm', 'set_minmobs');
    show_int( 'atks required', parik_atk_required, 'atks', 'set_atkrequired');
    show_int( 'sword item id', SwordItemID, 'swordid', 'set_sword_id');
    show_int( 'spear item id', SpearItemID, 'spearid', 'set_spear_id');
    show_int( 'rage skill', rage_skill, 'rages', 'set_rageskill');
    show_int( 'provoke skill', provoke_skill, 'provs', 'set_provokeskill');
    show_int( 'ds skill', ds_skill, 'dsskill', 'set_dsskill');
    show_int( 'resps count', resp_count, 'respcount', 'set_resp_count');
    show_int( 'chk point atks', atk_required_chk_point, 'provs', 'set_atkchk');
    show_int( 'hp bottle', hp_bottle, 'hpbottle', 'set_hpbottle');

    show_btn('Soulshot', 'soulshot');
//---------------------------
    show_bool('ds separate', ds_serapate, 'ds_serapate');
    show_bool('wait ds off', wait_ds_off, 'wait_ds_off');

    show_bool('sws offparty', sws_offparty, 'sws_off');
    show_bool('bd offparty', bd_offparty, 'bd_off');
    show_bool('ee offparty', ee_offparty, 'ee_off');
    show_bool('wc offparty', wc_offparty, 'wc_off');
    show_bool('kot offparty', kot_offparty, 'kot_off');
    show_bool('tank offparty', tank_offparty, 'tank_off');
    show_bool('spoil offparty', spoiler_offparty, 'spoil_off');
//----------------
    ss :=ss +
    '<br><button action="bypass -h bb_close" value="Close"'+
    'width=70 height=25 back="L2UI_CT1.Button_DF_Down" fore="L2UI_CT1.Button_DF">';
    
    ss := ss +
    '</body></html>';

    myEngine.NpcHtmlMsg(ss);
end;

procedure TPluginImpl.ShowOptionsPath(pn: Integer);
var
    ss, sm, p : string;
    i : Integer;
    pm : PMovePath;
begin
    p := 'path'+inttostr(pn);
    ss := '<html><body>'+
    '<title>'+p+' route</title>'+
    '<table>';
    pm := getPath(pn);

    for i := 0 to Length(pm^)-1 do begin
        if pm^[i].mob_atk <> 0 then sm := ' ['+inttostr(pm^[i].mob_atk)+']' else sm := '';

        ss := ss+
        '<tr><td width=120 height=10><font color="FFFFFF">point: '+inttostr(i)+sm+'</font></td>';

        ss := ss+'<td><button action="bypass bb_'+p+'_goto '+inttostr(i)+'" value="GoTo"'+
            'width=50 height=25 back="L2UI_CT1.Button_DF_Down" fore="L2UI_CT1.Button_DF"></td>';

        ss := ss+'<td><button action="bypass bb_'+p+'_replace '+inttostr(i)+'" value="Replace"'+
            'width=50 height=25 back="L2UI_CT1.Button_DF_Down" fore="L2UI_CT1.Button_DF"></td>';

        ss := ss+'<td><button action="bypass bb_'+p+'_delete '+inttostr(i)+'" value="Delete"'+
            'width=50 height=25 back="L2UI_CT1.Button_DF_Down" fore="L2UI_CT1.Button_DF"></td>';

        ss := ss + 'tr';
    end;

    ss := ss + '</table>';

    ss :=ss +
    '<br><button action="bypass bb_'+p+'_add" value="Add current point"'+
    'width=150 height=25 back="L2UI_CT1.Button_DF_Down" fore="L2UI_CT1.Button_DF">';

    ss :=ss +
    '<br><button action="bypass bb_'+p+'_reload" value="Reload"'+
    'width=150 height=25 back="L2UI_CT1.Button_DF_Down" fore="L2UI_CT1.Button_DF">';

    ss :=ss +
    '<br><button action="bypass -h bb_close" value="Close"'+
    'width=70 height=25 back="L2UI_CT1.Button_DF_Down" fore="L2UI_CT1.Button_DF">';

    ss := ss +
    '</body></html>';
    myEngine.NpcHtmlMsg(ss);
end;

procedure TPluginImpl.ShowOptionsSoulshot;
var
    ss : string;
    col : string;
    sel : Boolean;
    procedure show_grade_ss(grade : Char; item_id : Integer);
    begin
        sel := item_id = soulshot_id;
        if sel then
            col := 'FFFFFF'
        else
            col := '606066';

        ss := ss+
        '<tr><td height=38><img src="Icon.'+get_shot_iconname(grade)+'" width=32 height=32></td>'+
        '<td width=80><font color="'+col+'">'+UpperCase(grade)+' grade</font></td>';

        if not sel then
            ss := ss+'<td><button action="bypass bb_ss_select '+inttostr(item_id)+'" value="Select"'+
            'width=70 height=25 back="L2UI_CT1.Button_DF_Down" fore="L2UI_CT1.Button_DF"></td>';
        ss := ss + '</tr>';
    end;
begin
    ss := '<html><body>'+
    '<title>Soulshots ['+LinkedCharName+']</title>'+
    '<table>';

    show_grade_ss('s', 1467);
    show_grade_ss('a', 1466);
    show_grade_ss('b', 1465);
    show_grade_ss('c', 1464);
    show_grade_ss('d', 1463);

    ss :=ss +
    '<tr><td><button action="bypass -h bb_close" value="Close"'+
    'width=70 height=25 back="L2UI_CT1.Button_DF_Down" fore="L2UI_CT1.Button_DF"></td></tr>';

    ss := ss +
    '</body></html>';

    myEngine.NpcHtmlMsg(ss);

end;

procedure TPluginImpl.Songs;
var
    n : string;
    i : Integer;
begin
    say('songs!');
    // если бд в пати на сонги - кикнем его
    if ds_serapate then
    if (myEngine.Party.Exist(BD_name)) then myEngine.Party.Dismiss( BD_name);

    n := GetPartyDS;
    if n <> '' then begin
        // берем в пати всех
        myEngine.Party.Invite( n);
        main_state := ST_WAIT_PARTY_DS;
    end else begin
        myEngine.Me.SayToChat(3, 'ds');
        // use dark form
        if DS_SKILL <> 0 then myEngine.Me.UseSkill( DS_SKILL);
        myEngine.Me.UseSkill(421);

        for i := 0 to 10 do buffers[i] := '';
        main_state := ST_SONGS;
        buffers[0] := 'sws_done';
        if not ds_serapate then begin
            buffers[1] := 'bd_done';
            RequestCov;
        end;
    end;
end;

procedure TPluginImpl.SpotNext;
begin
    say('spot next buff time: '+inttostr(buff_timer div 60000));
    // 16 min
    if buff_timer > 16 * 60 * 1000 then begin
//        if (CurrentResp > resp_count) and (resp_count > 1) then begin
            CurrentResp := 1;
//            WaitMobsResp;
//        end else
            Rebuff;
    end else begin
        if (CurrentResp > 1) and (not wait_ds_off) then
            gotoCollectParik
        else
            Songs;
    end;
end;

procedure TPluginImpl.StartFightMode;
begin
    say('StartFightMode');
    active := True;
    TimerStart(1, 500);
    UpdateNames;
    LoadOptions;
    buff_timer := 10000000;
    CurrentResp := 1;

    if (soulshot_id <> 0) and (not myEngine.Me.isSoulshotEnabled(soulshot_id)) then
        myEngine.Me.EnableAutoSoulshot(soulshot_id);

    WaitMobsResp;
//    Rebuff;
end;

procedure TPluginImpl.StopFightMode;
begin
    TimerStop(1);
    active := false;
    say('STOP ********************');
end;

procedure TPluginImpl.system_message(var pck: AnsiString);
var
    msg_id,
    size,
    sk, tp, skill_id
    : Integer;
    p : TPacket;
begin
    msg_id := ReadD(pck, 2);
    size := ReadD(pck, 6);

    // effect has been removed
    // некий скил спал с меня
    if msg_id = 749 then begin
        p.Reset(pck, 10);
        for sk := 1 to size do begin
            tp := p.ReadD; // type
            skill_id := p.ReadD; // skill id
            p.ReadD; // level

            // если с меня сошел слип кинутый мобом
            if (tp = 4) and (skill_id = 4046) and active then case main_state of
                ST_KILL_PARIK : begin
                    // передвинемся чуток и начнем атаку моей цели
                    myEngine.Me.MoveBackwardToLocation(
                    Vec3i(myPos.X+RndPoint(100), myPos.Y+RndPoint(100), myPos.Z+RndPoint(100)));
                    SendAttack(myTarget);
                end;

                ST_MOVE_BY_PATH : begin
                    myEngine.Me.MoveBackwardToLocation( current_move_point );
                end;
            end;
        end;
    end;

    // restart server
    if (msg_id = 1) and (ReadD(pck,14) < 240) then begin
        StopFightMode;
    end;

    // cant see target
    if (msg_id = 181) then begin
        // корявая геодата..... не видим цель. отбежим чуток в сторонку может и сможет атаковать
        case CurrentResp of
            1 : myEngine.Me.MoveBackwardToLocation( drop1_point );
            2 : myEngine.Me.MoveBackwardToLocation( drop2_point );
        end;
    end;
end;

procedure TPluginImpl.UpdateNames;
begin
    wc_name :=      Core.getLinkedCharName( WC_PLUGIN_NAME );
    ee_name :=      Core.getLinkedCharName( EE_PLUGIN_NAME );
    kot_name :=     Core.getLinkedCharName( KOT_PLUGIN_NAME );
    tank_name :=    Core.getLinkedCharName( TANK_PLUGIN_NAME );
    sws_name :=     Core.getLinkedCharName( SWS_PLUGIN_NAME );
    bd_name :=      Core.getLinkedCharName( BD_PLUGIN_NAME );
    spoiler_name := Core.getLinkedCharName( SPOILER_PLUGIN_NAME );

    if not core.isConnectionExist(wc_name) then wc_name := '';
    if not core.isConnectionExist(ee_name) then ee_name := '';
    if not core.isConnectionExist(kot_name) then kot_name := '';
    if not core.isConnectionExist(tank_name) then tank_name := '';
    if not core.isConnectionExist(sws_name) then sws_name := '';
    if not core.isConnectionExist(bd_name) then bd_name := '';
    if not core.isConnectionExist(spoiler_name) then spoiler_name := '';
end;

procedure TPluginImpl.validate_pos(pck: AnsiString);
var
    a : Integer;
begin
    if (main_state = ST_MOVE_BY_PATH) and active then begin
        a := current_move_point.Dist( myPos );
        if a < CurrentPointDist then begin
            case path[path_index].mob_atk of
                // не надо никого атаковать. просто бежим дальше
                0 : begin
                    say( 'dist='+inttostr(a));
                    MoveNextPoint;
                end;
                // атакуем ближайшего не агро моба
                1 : begin
                    say( 'atk near dist='+inttostr(a));
                    // указан моб - надо взять на таргет и бить его
                    AttackMobParik(0);
                end
            else
                // атакуем моба указанного типа
                begin
                    say( 'atk dist='+inttostr(a));
                    // указан моб - надо взять на таргет и бить его
                    if PROVOKE_SKILL <> 0 then begin
                        say('use provoke skill');
                        myEngine.Me.UseSkill(provoke_skill);
                        main_state := ST_WAIT_PROVOKE;
                        MoveNextPoint;
                    end
                    else
                        AttackMobParik(Path[path_index].mob_atk);
                end;
            end;
        end else begin
            say('validate pos dist = '+inttostr(a));
        end;
    end;
end;

procedure TPluginImpl.WaitMobsResp;
begin
    if (wait_ds_off) and (not isDsOff) then begin
        main_state := ST_WAIT_DS_OFF;
        state_timer := 0;
        say('ds not off, wait');
    end else begin
        LogPrint( 'next spot ' +
        'kills : '+ inttostr(kills_count)+' / '+inttostr(total_kills_count) +
        '   weapon : '+inttostr(myEngine.Me.WeaponEquipped)+
        '  adena : '+NumHuman(inttostr(myEngine.Drop.AdenaReceived))
        );

        say('WaitMobsResp');

        if (soulshot_id <> 0) and (myEngine.Inventory.Items[soulshot_id].count < 500) then begin
            StopFightMode;
        end else begin
            main_state := ST_WAIT_MOBS_RESP;
        end;
    end;
end;

function TPluginImpl.Palevo: string;
var
    i : Integer;
begin
    for i := 0 to myEngine.Players.Count - 1 do
        if (myEngine.Players[i].pos.Dist(myPos) < 1200) and (not Core.isConnectionExist(myEngine.Players[i].name)) then
        begin
            Result := myEngine.Players[i].name;
            exit;
        end;

    Result := '';        
end;

procedure TPluginImpl.PickUpParikDrop;
begin
    say('pickup parik drop');
    main_state := ST_DROP_PARIK;
    myEngine.Me.Action(myDrop);
end;

procedure TPluginImpl.PrepareToFight;
begin
    if rage_skill <> 0 then
        myEngine.Me.UseSkill(rage_skill);
end;

procedure TPluginImpl.Rebuff;
var
    n : string;
    i : Integer;
begin
    if not active then exit;


    say('rebuff ms='+inttostr(main_state));
    n := GetPartyFull;
    if n <> '' then begin
        // берем в пати всех
        say('rebuff invite : '+n);
        myEngine.Party.Invite(n);
        main_state := ST_WAIT_PARTY_FULL;
    end else begin
        LogPrint('rebuff -----------------------------');
        // даем команду на ребаф в пати чат
        myEngine.Me.SayToChat(3, 'rebuff');
        buff_timer := 0;

        for i := 0 to 10 do buffers[i] := '';
        // чего ждем от ботов баферов
        if wc_name <> '' then buffers[0] := 'wc_done';
        if ee_name <> '' then buffers[1] := 'ee_done';
        if tank_name <> '' then buffers[2] := 'tank_done';

        // ждем когда получим баф
        main_state := ST_REBUFF;
    end;
end;

procedure TPluginImpl.RequestCov;
begin
    say('request cov');
    Core.PluginCallFunction( WC_PLUGIN_NAME, FUNC_REQUEST_COV, myID );
end;

procedure TPluginImpl.RequestMP;
begin
    say('request mp');
    Core.PluginCallFunction( EE_PLUGIN_NAME, FUNC_REQUEST_MP, myID );
end;

procedure TPluginImpl.RequestRes;
begin
    say('request res');
    Core.PluginCallFunction( EE_PLUGIN_NAME, FUNC_REQUEST_RES, myID );
end;

procedure TPluginImpl.revive(var pck: AnsiString);
begin
    if not active then exit;

    if ReadD(pck, 2) = myID then begin
        buff_timer := 1000000000;
        main_state := ST_DROP_PARIK_WAIT;
        state_timer := 0;

//        if myEngine.Me.DeathPenaltyLevel > 0 then
//            myEngine.Inventory.UseItem(RecoveryScroll);

//        MagicSkillUse(name, 422); // spear accuracy
    end;
end;

procedure TPluginImpl.ProcessPacket(var pck: AnsiString; FromServer: Boolean;
  ConnectName: string; Engine: TEngine);
var
    p : TPacket;
    s : string;
begin
    if FromServer then begin
        case pck[1] of
            // creature say
            #$00 : mob_die(pck);
            #$01 : revive(pck);
            #$17 : get_item(pck);
            #$33 : mob_attack(pck);
            #$4f : join_party(pck);
            #$f3 : confirm_dlg(pck, ConnectName);
            #$54 : magic_skill_launched(pck);
            #$62 : system_message(pck);
            #$18: begin
                    if (ReadD(pck, 2) = myID) and CheckHPNeedRestore and (not isTimerEnabled(2)) then begin
                        myEngine.Inventory.UseItem(hp_bottle);
                        TimerStart(2, 13500);
                    end;
            end;
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
            #$23 : html_select(pck);
            // validate position
            #$59: validate_pos(pck);
        end;
    end;
end;

end.
