unit plg_auto_sws;

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
        procedure onChatSay(pck : AnsiString);
        procedure onSysMsg(pck : AnsiString);
        procedure onHtmlSelect(var pck : AnsiString);
        procedure onSkillsList;
        procedure ShowOptions;
        procedure StartDS;
        procedure LoadOptions;
        procedure SaveOptions;
        procedure HtmlSelect(sn : string);

        procedure AddSkill(id : Integer; n : string);
        function isSkillEnabled(id : Integer) : Boolean;
        procedure doNextSkill;
    end;

    tDSSkill = record
        id : Integer;
        enabled : Boolean;
        name : string;
    end;

var
    plugin_impl : TPluginImpl;

const
    // по какому слову в чате показываем диалог настроек
    OPTIONS_COMMAND = 'sws';
    // что говорим главному боту, если пусто - ничего не говорим и не пытаемся вызывать его функции
    BUFF_DONE_MSG = 'sws_done';

var
    Skills : array of tDSSkill;
    ds_index : Integer;
    SkillsReady : Boolean;
    OptionsFname : string;
    Active : Boolean;

implementation

{ TPluginImpl }

procedure TPluginImpl.onSkillsList;
begin
    Skills := nil;

    SkillsReady := false;
    if myEngine.Me.HaveSkill(349) then begin
        AddSkill( 349, 'Renewal' ); SkillsReady := true;
    end;
    if myEngine.Me.HaveSkill(364) then begin
        AddSkill( 364, 'Champion' ); SkillsReady := true;
    end;
    if myEngine.Me.HaveSkill(304) then begin
        AddSkill( 304, 'Vitality' ); SkillsReady := true;
    end;
    if myEngine.Me.HaveSkill(267) then begin
        AddSkill( 267, 'Warding' ); SkillsReady := true;
    end;
    if myEngine.Me.HaveSkill(269) then begin
        AddSkill( 269, 'Hunter' ); SkillsReady := true;
    end;
    if myEngine.Me.HaveSkill(264) then begin
        AddSkill( 264, 'Earth' ); SkillsReady := true;
    end;
    if myEngine.Me.HaveSkill(268) then begin
        AddSkill( 268, 'Wind' ); SkillsReady := true;
    end;
    if myEngine.Me.HaveSkill(363) then begin
        AddSkill( 363, 'Meditation' ); SkillsReady := true;
    end;
    LoadOptions;
end;

procedure TPluginImpl.AddSkill(id: Integer; n: string);
begin
    SetLength( Skills, length(skills)+1 );
    Skills[High(Skills)].id := id;
    Skills[High(Skills)].enabled := False;
    Skills[High(Skills)].name := n;
end;

destructor TPluginImpl.Destroy;
begin
    Skills := nil;
    inherited;
end;

procedure TPluginImpl.doNextSkill;
begin
    if (not active) or (not SkillsReady) then begin
        myEngine.botSay( 'not activated!');
        exit;
    end;

    // пока еще есть не пройденные скилы
    while (ds_index < Length(Skills)) do begin
        // перейдем на следующий
        ds_index := ds_index + 1;

        if ds_index >= Length(Skills) then break;

        if skills[ds_index].id = 0 then Continue;
        if not skills[ds_index].enabled then Continue;

        // если скилл корректен
        if (skills[ds_index].id > 0) then begin
            myEngine.Me.UseSkill( skills[ds_index].id );
            // выходим
            exit;
        end;
    end;

    // скиллы кончились.
   ds_index := 1000;
   myEngine.botSay( 'ds Done!');
   if (BUFF_DONE_MSG <> '') and (LEADER_PLUGIN <> '') then
        Core.PluginCallFunction( LEADER_PLUGIN, FUNC_BUFF_DONE, BUFF_DONE_MSG );

end;

procedure TPluginImpl.HtmlSelect(sn: string);
var
    sk, j : Integer;
begin
    if Pos('bb_skill_disable', sn) > 0 then begin
        Delete(sn, 1, 17);
        myEngine.botSay( 'skill disable:'+sn);
        sk := strtoint(sn);

        for j := 0 to Length(Skills) - 1 do
            if skills[j].id = sk then begin
                skills[j].enabled := false;
            end;
            
        SaveOptions;
        ShowOptions;
    end;

    if Pos('bb_skill_enable', sn) > 0 then begin
        Delete(sn, 1, 16);
        myEngine.botSay( 'skill enable:'+sn);
        sk := strtoint(sn);

        for j := 0 to Length(Skills) - 1 do
            if skills[j].id = sk then begin
                skills[j].enabled := True;
            end;

        SaveOptions;
        ShowOptions;
    end;
end;

procedure TPluginImpl.Init;
begin
    inherited;

    ds_index := 1000;
    Skills := nil;
    SkillsReady := false;
    Active := LinkedCharName <> '';
    OptionsFname := AppPath + 'ini\auto_sws_'+core.getLinkedCharName(Self)+'.txt';

    if core.isConnectionExist(LinkedCharName) then begin
        onSkillsList;
    end;
    LoadOptions;

    LogPrint( 'options='+OptionsFname );
end;

function TPluginImpl.isSkillEnabled(id: Integer): Boolean;
var
    i : tDSSkill;
begin
    for i in Skills do
        if i.id = id then begin
            Result := true;
            exit;
        end;

    Result := false;
end;

procedure TPluginImpl.LoadOptions;
var
    st : tstringlist;
    i, j : Integer;
begin
    for i := 0 to Length(Skills)-1 do begin
        Skills[i].enabled := false;
    end;

    if not FileExists(OptionsFname) then Exit;

    st := tstringlist.create;
    try
        st.loadfromfile(OptionsFname);
        for i := 0 to st.count - 1 do
            for j := 0 to Length(skills) - 1 do
                if Skills[j].id = strtoint(st[i]) then
                    Skills[j].enabled := true;
    finally
        st.free;
    end;
end;

procedure TPluginImpl.onChatSay(pck: AnsiString);
var
    p : TPacket;
    ch : Integer;
    n, msg : string;
begin
    p.Reset(pck, 6);
    ch := p.ReadD;
    n := p.ReadS;
    p.Skip(4);
    msg := p.ReadS;

    if (ch = 3) and (msg = 'ds') then begin
        StartDS;
    end;

    if (ch = 3) and (msg = 'ren') then begin
        myEngine.Me.UseSkill(349);
    end;
    if (ch = 3) and (msg = 'wind') then begin
        myEngine.Me.UseSkill(268);
    end;

    if (ch = 3) and (msg = 'sws+') then begin
        Active := True;
        myEngine.botSay('sws on');
    end;
    if (ch = 3) and (msg = 'sws-') then begin
        Active := false;
        ds_index := 1000;
        myEngine.botSay('sws off');
    end;

end;

procedure TPluginImpl.onClientChatSay;
var
    msg : string;
    ch : Integer;
    p : TPacket;
begin
    p.Reset(pck, 2);
    msg := p.ReadS;
    ch := p.ReadD;

    if (msg = OPTIONS_COMMAND) and (ch = 0) then begin
        pck := '';
        ShowOptions;
    end;

    if (msg = 'a') then begin
        Active := true;
        pck := '';
        onSkillsList;
        LoadOptions;
        myEngine.botSay( 'sws activated' );
    end;

    if (msg = 'd') then begin
        Active := False;
        pck := '';
        myEngine.botSay( 'sws deactivated' );
    end;
end;

procedure TPluginImpl.onHtmlSelect(var pck: AnsiString);
var
    s : string;
begin
    s := ReadS(pck, 2);
    // все что начинается с bb - игнорим и не шлем серверу чтобы не палится
    if (s[1] = 'b') and (s[2] = 'b') then begin
        HtmlSelect(s);
        pck := '';
    end;
end;

procedure TPluginImpl.onSysMsg(pck: AnsiString);
var
    a, c, i, sk : Integer;
    p : TPacket;
begin
    p.Reset(pck, 2);
    // msg id
    a := p.ReadD;
    // получили эффект скилла на себя
    if (a = 110) then begin
        c := p.ReadD; // count

        for i := 1 to c do begin
            // type
            if (p.ReadD = 4) then begin
                sk := p.ReadD; // skill id
                // только если уже запущены сонги и дансы
                if (ds_index >= 0) and (ds_index < Length(Skills)) then
                    if (sk = skills[ds_index].id) then doNextSkill();
                p.Skip(4); // skill level
            end else begin
                p.ReadD;
                p.ReadD;
            end;
        end;
    end;

    // кончилось мп
    if (a = 24) then begin
        ds_index := 1000;
        myEngine.botSay( 'mp off!');
        if (BUFF_DONE_MSG <> '') and (LEADER_PLUGIN <> '') then
            core.PluginCallFunction( LEADER_PLUGIN, FUNC_BUFF_DONE, BUFF_DONE_MSG );
    end;

    // еще сколько то времени до отката скилла. значит дать скилл не удалось. должны дать следующий
    if (a = 2304) then begin
        if (ds_index >= 0) and (ds_index < Length(Skills)) then
            if (ReadD(pck, 14) = skills[ds_index].id) then doNextSkill();
    end;
end;

procedure TPluginImpl.onTimer(id: Integer);
begin
    if id = 1 then begin
        myEngine.Me.UseSkill( 366 );
        TimerStop(1);
    end;
end;

procedure TPluginImpl.SaveOptions;
var
    st : tstringlist;
    j : Integer;
begin
    st := tstringlist.create;
    try
        for j := 0 to Length(skills) - 1 do
            if Skills[j].enabled then st.Add( IntToStr(skills[j].id) );
        st.SaveToFile( OptionsFname );
    finally
        st.free;
    end;
end;

procedure TPluginImpl.ShowOptions;
var
    ss, sk, col : string;
    j : Integer;
begin
    ss := '<html><body>'+
    '<title>Auto SWS by arksu ['+LinkedCharName+']</title>'+
    '<table>';

    for j := 0 to Length(Skills)-1 do begin
        sk := inttostr(skills[j].id);
        while Length(sk) < 4 do sk := '0'+sk;

        if skills[j].enabled then
            col := 'FFFFFF'
        else
            col := '606066';

        ss := ss+
        '<tr><td height=38><img src="Icon.skill'+sk+'" width=32 height=32></td><td width=80><font color="'+col+'">'+skills[j].name+'</font></td>';

        if skills[j].enabled then
            ss := ss+'<td><button action="bypass bb_skill_disable '+inttostr(skills[j].id)+'" value="Disable"'+
            'width=70 height=25 back="L2UI_CT1.Button_DF_Down" fore="L2UI_CT1.Button_DF"></td></tr>'
        else
            ss := ss+'<td><button action="bypass bb_skill_enable '+inttostr(skills[j].id)+'" value="Enable"'+
            'width=70 height=25 back="L2UI_CT1.Button_DF_Down" fore="L2UI_CT1.Button_DF"></td></tr>';
    end;

    ss := ss + '</table>';


    ss :=ss +
    '<br><button action="bypass -h bb_close" value="Close"'+
    'width=70 height=25 back="L2UI_CT1.Button_DF_Down" fore="L2UI_CT1.Button_DF">';

    ss := ss +
    '</body></html>';

    myEngine.NpcHtmlMsg(ss);
end;

procedure TPluginImpl.StartDS;
begin
    myEngine.botSay( 'start ds' );
    ds_index := -1;
    doNextSkill();
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
            #$4a : onChatSay(pck);
            #$5f : onSkillsList;
            #$62 : onSysMsg(pck);
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
            #$23 : onHtmlSelect(pck);
        end;
    end;
end;

end.
