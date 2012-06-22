unit plg_skills_learn;

interface

uses
    pfHeader, SysUtils;

type
    TSkillInfo = record
        id : Integer;
        next_level : Integer;
    end;

    TPluginImpl = class(TPluginDll)
    protected
        main_state : Integer;
        skills_info : array of TSkillInfo;
        current_skill : Integer;
        state_timer : Integer;
        skill_type : Integer;
    public
        procedure Init; override;
        procedure ProcessPacket(var pck: AnsiString; FromServer: Boolean; ConnectName : string; Engine : TEngine); override;
        destructor Destroy; override;
        procedure onTimer(id: Integer); override;
    end;

var
    plugin_impl : TPluginImpl;


const
    ST_IDLE = 0;
    ST_WAIT_LIST = 1;
    ST_REQUEST_SKILL_INFO = 2;
    ST_WAIT_SKILL_INFO = 3;
    ST_REQUEST_SKILL = 4;

    CYCLES_WAIT = 1;

implementation

{ TPluginImpl }

destructor TPluginImpl.Destroy;
begin
    skills_info := nil;
  inherited;
end;

procedure TPluginImpl.Init;
begin
  inherited;
  skills_info := nil;
  current_skill := 0;
  TimerStart(1, 500);
  skill_type := 0;
end;

procedure TPluginImpl.onTimer(id: Integer);
var
    p : TPacket;
    i : Integer;
    f : Boolean;
begin
    if id = 1 then
    case main_state of
        ST_REQUEST_SKILL_INFO : begin
            Inc(state_timer);
            myEngine.botSay('ST_REQUEST_SKILL_INFO : '+IntToStr(state_timer));
            if state_timer > CYCLES_WAIT then begin
                f := false;
                for i := 0 to Length(skills_info) - 1 do
                    if skills_info[i].id = current_skill then
                    begin
                        f := True;
                        p.Reset(#$73).
                        WriteD(current_skill).
                        WriteD(skills_info[i].next_level).
                        WriteD(skill_type).
                        SendToServer( LinkedCharName );

                        main_state := ST_WAIT_SKILL_INFO;
                    end;
                if not f then begin
                    myEngine.botSay('skill not found!');
                    main_state := ST_IDLE;
                    current_skill := 0;
                end;
            end;
        end;

        ST_REQUEST_SKILL : begin
            Inc(state_timer);
            myEngine.botSay('ST_REQUEST_SKILL : '+IntToStr(state_timer));
            if state_timer > CYCLES_WAIT then begin
                f := false;
                for i := 0 to Length(skills_info) - 1 do
                    if skills_info[i].id = current_skill then
                    begin
                        f := True;
                        myEngine.botSay('next level : '+IntToStr(skills_info[i].next_level));
                        p.Reset(#$7c).
                        WriteD(current_skill).
                        WriteD(skills_info[i].next_level).
                        WriteD(skill_type).
                        SendToServer( LinkedCharName );

                        main_state := ST_WAIT_LIST;
                    end;
                if not f then
                    myEngine.botSay('skill not found!');

            end;

        end;
    end;
end;

procedure TPluginImpl.ProcessPacket(var pck: AnsiString; FromServer: Boolean;
  ConnectName: string; Engine: TEngine);
var
    i : Integer;
    p : TPacket;
begin
    if FromServer then
    case pck[1] of
        #$90 : begin
            p.Reset(pck, 10);
            skill_type := ReadD(pck, 2);
            i := ReadD(pck, 6);
            SetLength(skills_info, i);
            while i > 0 do
            begin
                Dec(i);
                skills_info[i].id := p.ReadD;
                skills_info[i].next_level := p.ReadD;

                p.Skip(3*4);
                if skill_type = 3 then p.Skip(4);
            end;

            // если мы выбрали скилл для изучения
            if (current_skill <> 0) and (main_state = ST_WAIT_LIST) then
            begin
                main_state := ST_REQUEST_SKILL_INFO;
                state_timer := 0;
            end;
        end;

        #$91 : begin
            if (main_state = ST_WAIT_SKILL_INFO) and (ReadD(pck, 2) = current_skill) then
            begin
                pck := '';
                myEngine.botSay('skill info');
                main_state := ST_REQUEST_SKILL;
                state_timer := 0;
            end;
        end;

        // sys msg
        #$62 : begin
            if (ReadD(pck, 2) = 750) or (ReadD(pck, 2) = 278) then
            begin
                main_state := ST_IDLE;
                current_skill := 0;
                myEngine.botSay('all skills learned!');
            end;            
        end;
    end;
    
    if not FromServer then
    case pck[1] of
        #$7c : begin
            current_skill := ReadD(pck, 2);
            myEngine.botSay('select current skill : '+IntToStr(current_skill));
            main_state := ST_WAIT_LIST;
        end;

    end;
end;

end.
