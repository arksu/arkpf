unit uEngine;
// движок для бота. работа со всеми параметрами текущего коннекта (мобы, нпц, пати, статы и прочее)

interface

uses
    pfHeader, uL2GS_Connect, StrUtils, SysUtils;

type
    TL2DropImpl = class(TL2Drop)
    protected
        fEngine : TEngine;
        fItems : array of TL2DropItem;
        fAdenaReceived : Integer;

        procedure HandlePacket(pck: string; FromServer: Boolean); override;
        function getCount: Integer; override;
        function getItems(idx: Integer): TL2DropItem; override;
        function getAdenaReceived: Integer; override;
    public
        constructor Create(aEngine : TEngine);
        destructor Destroy; override;
        function PickupMyNearest: Boolean; override;
        function myNear(radius : Integer = 1000): Integer; override;
    end;

    TL2PlayersImpl = class(TL2Players)
    protected
        fEngine : TEngine;
        fItems : array of TL2Char;

        procedure HandlePacket(pck: string; FromServer: Boolean); override;
        function getCount: Integer; override;
        function getItems(idx: Integer): TL2Char; override;
        function getPlayerByName(n: string): TL2Char; override;
    public
        constructor Create(aEngine : TEngine);
        destructor Destroy; override;
    end;

    TL2NpcMobsImpl = class(TL2NpcMobs)
    protected
        fEngine : TEngine;
        fItems : array of TL2Npc;

        procedure HandlePacket(pck: string; FromServer: Boolean); override;
        function getCount: Integer; override;
        function getItems(idx: Integer): TL2Npc; override;
        function getItemsByObjID(objid: Integer): TL2Npc; override;
    public
        constructor Create(aEngine : TEngine);
        destructor Destroy; override;
        function getNearMob(agro: Boolean = False; mobid : Integer = 0; radius : Integer = 3000): Integer; override;
    end;

    TL2PartyImpl = class(TL2Party)
    protected
        fEngine : TEngine;
        fItems : array of TL2PartyMember;
        fLeaderObjID : Integer;

        procedure HandlePacket(pck: string; FromServer: Boolean); override;
        function getCount: Integer; override;
        function getItem(index: Integer): TL2PartyMember; override;
        function getLeader: TL2PartyMember; override;
    public
        constructor Create(aEngine : TEngine);
        destructor Destroy; override;

        procedure Leave; override;
        function Exist(name: string): Boolean; override;
        procedure Invite(name: string; loot_type : Integer = 0); override;
        procedure InviteCommandChannel(name: string); override;
        procedure Dismiss(name: string); override;
        procedure JoinAnswer(ack: Boolean); override;
    end;

    TL2InventoryImpl = class(TL2Inventory)
    protected
        fEngine : TEngine;
        fItems : array of TL2InvItem;

        function getCount: Integer; override;
        procedure HandlePacket(pck: string; FromServer: Boolean); override;
        function getItem(index: Integer): TL2InvItem; override;
        function getItemId(item_id: Integer): TL2InvItem; override;
    public
        constructor Create(aEngine : TEngine);
        destructor Destroy; override;
        function ItemExist(item_id: Integer): Boolean; override;
        procedure UseItem(item_id: Integer; is_ctrl : Boolean = false); override;
    end;

    TL2UserInfoImpl = class(TL2UserInfo)
    protected
        fEngine : TEngine;
        fObjID : Integer;
        fPos : TVec3i;
        fCp : Integer;
        fMaxCp : Integer;
        fHp : Integer;
        fMaxHp : Integer;
        fMp : Integer;
        fMaxMp : Integer;
        fExp : Int64;
        fLevel : Integer;
        fCurrentTarget : Integer;
        fCurrentLoad : Integer;
        fMaxLoad : Integer;
        fSp : Integer;
        fWeaponItemID : Integer;
        fName : string;
        fSkills : array of TL2Skill;
        fBuffs : array of TL2Buff;
        fDeathPenaltyLevel : Integer;
        IgnoreValidatePos : Boolean;
        fGaugeReadyTime : Cardinal;
        fSoulshotsEnabled : array of Integer;

        procedure HandlePacket(pck: string; FromServer: Boolean); override;
        function getCp: Integer; override;
        function getCppc: Integer; override;
        function getExp: Int64; override;
        function getCurrentTarget: Integer; override;
        function getHp: Integer; override;
        function getHppc: Integer; override;
        function getMaxCp: Integer; override;
        function getLevel: Integer; override;
        function getMaxHp: Integer; override;
        function getMaxMp: Integer; override;
        function getMp: Integer; override;
        function getObjID: Integer; override;
        function getPos: TVec3i; override;
        function getMppc: Integer; override;
        function getName: string; override;
        function getCurrentLoad: Integer; override;
        function getLoadpc: Integer; override;
        function getMaxLoad: Integer; override;
        function getBuff(id: Integer): TL2Buff; override;
        function getSkill(id: Integer): TL2Skill; override;
        function getWeaponEquipped: Integer; override;
        function getDeathPenaltyLevel: Integer; override;
        function getisUsingSkill: Boolean; override;                    
    public
        constructor Create(aEngine : TEngine);
        destructor Destroy; override;

        function HaveBuff(id: Integer): Boolean; override;
        function HaveSkill(id: Integer): Boolean; override;
        procedure TargetCancel; override;
        procedure UseSkill(skill_id: Integer; is_ctrl : Boolean = false; is_shift : boolean = false); override;
        procedure Action(objid: Integer); override;
        procedure ActionUse(id: Integer; is_ctrl : Boolean = False; is_shift : Boolean = False); override;
        procedure MoveBackwardToLocation(toPos: TVec3i); override;
        procedure SayToChat(channel : Integer; msg : string); override;
        function isSoulshotEnabled(item_id: Integer): Boolean; override;
        procedure EnableAutoSoulshot(item_id: Integer); override;
    end;

    TEngineImpl = class(TEngine)
    private
        fConnect : TL2GS_Connect;
        fUserInfo : TL2UserInfoImpl;
        fInventory : TL2InventoryImpl;
        fParty : TL2PartyImpl;
        fMobs : TL2NpcMobsImpl;
        fDrop : TL2DropImpl;
        fPlayers : TL2PlayersImpl;
    protected
        function getInventory: TL2Inventory; override;
        function getParty: TL2Party; override;
        function getMe: TL2UserInfo; override;
        function getDrop: TL2Drop; override;
        function getMobs: TL2NpcMobs; override;
        function getPlayers: TL2Players; override;

        procedure reInit; 
    public
        constructor Create(connect : TL2GS_Connect);
        destructor Destroy; override;

        procedure SendToClient(pck: string); override;
        procedure SendToServer(pck: string); override;
        procedure HandlePacket(pck: string; FromServer : Boolean); override;

        procedure NpcHtmlMsg(body: string); override;
        procedure botSay(msg: string; channel: Integer = 0); override;

    end;

implementation

{ TEngineImpl }

procedure TEngineImpl.botSay(msg: string; channel: Integer);
var
    p : TPacket;
begin
    p.Reset(#$4a);
    p.WriteD(0);
    p.WriteD(channel);
    p.WriteS('bot');
    p.Write(#$FF#$FF#$FF#$FF);
    p.WriteS(msg);
    SendToClient(p.data);
end;

constructor TEngineImpl.Create(connect: TL2GS_Connect);
begin
    fConnect := connect;
    fUserInfo := TL2UserInfoImpl.Create(self);
    fInventory := TL2InventoryImpl.Create(self);
    fParty := TL2PartyImpl.Create(self);
    fDrop := TL2DropImpl.Create(self);
    fPlayers := TL2PlayersImpl.Create(self);
    fMobs := TL2NpcMobsImpl.Create(self);
end;

destructor TEngineImpl.Destroy;
begin
    fInventory.Free;
    fParty.Free;
    fUserInfo.Free;
    fDrop.Free;
    fMobs.Free;
    fPlayers.Free;
    inherited;
end;

function TEngineImpl.getDrop: TL2Drop;
begin
    Result := fDrop;
end;

function TEngineImpl.getInventory: TL2Inventory;
begin
    Result := fInventory;
end;

function TEngineImpl.getMe: TL2UserInfo;
begin
    Result := fUserInfo;
end;

function TEngineImpl.getMobs: TL2NpcMobs;
begin
    Result := fMobs;
end;

function TEngineImpl.getParty: TL2Party;
begin
    Result := fParty;
end;

function TEngineImpl.getPlayers: TL2Players;
begin
    Result := fPlayers;
end;

procedure TEngineImpl.HandlePacket(pck: string; FromServer : Boolean);
begin
    if FromServer and (pck[1] = #$0b) then reInit;    

    fUserInfo.HandlePacket( pck, FromServer );
    fInventory.HandlePacket( pck, FromServer );
    fParty.HandlePacket( pck, FromServer );
    fDrop.HandlePacket( pck, FromServer );
    fPlayers.HandlePacket( pck, FromServer );
    fMobs.HandlePacket( pck, FromServer );
end;

procedure TEngineImpl.NpcHtmlMsg(body: string);
var
    p : TPacket;
begin
    p.Reset(#$19);
    p.WriteD(0);
    p.WriteS(body);
    p.WriteD(0);
    SendToClient(p.data);
end;

procedure TEngineImpl.reInit;
begin
    fUserInfo.Free;
    fUserInfo := TL2UserInfoImpl.Create(self);

    fInventory.Free;
    fInventory := TL2InventoryImpl.Create(self);

    fParty.Free;
    fParty := TL2PartyImpl.Create(self);

    fMobs.Free;
    fMobs := TL2NpcMobsImpl.Create(self);

    fPlayers.Free;
    fPlayers := TL2PlayersImpl.Create(self);

    fDrop.Free;
    fDrop := TL2DropImpl.Create(self);
end;

procedure TEngineImpl.SendToClient(pck: string);
var
    tmp : AnsiString;
begin
    HandlePacket(pck, True);

    tmp := pck;
    fConnect.EncodeAndSend( tmp, true );
end;

procedure TEngineImpl.SendToServer(pck: string);
var
    tmp : AnsiString;
begin
    HandlePacket(pck, false);

    tmp := pck;
    fConnect.EncodeAndSend( tmp, false );
end;

{ TL2UserInfoImpl }

procedure TL2UserInfoImpl.TargetCancel;
begin
    fEngine.SendToServer(#$48#$00#$00);
end;

procedure TL2UserInfoImpl.UseSkill(skill_id: Integer; is_ctrl : Boolean = false; is_shift : boolean = false);
var
    p : TPacket;
begin
    if (not HaveSkill(skill_id)) or (skill_id = 0) then exit;

    p.Reset(#$39);
    p.WriteD(skill_id);
    
    if is_ctrl then
        p.WriteD(1)
    else
        p.WriteD(0);

    if is_shift then
        p.WriteC(1)
    else
        p.WriteC(0);
        
    fEngine.SendToServer(p.data);
end;

procedure TL2UserInfoImpl.Action(objid: Integer);
var
    p : TPacket;
begin
    if (fPos.X = 0) or (fPos.Y = 0) or (fPos.Z = 0) then Exit;

    p.Reset(#$1f);
    p.WriteD(objid);
    p.WriteD(fpos.X);
    p.WriteD(fpos.Y);
    p.WriteD(fpos.Z);
    p.WriteC(0); // action id
    fEngine.SendToServer(p.data);
end;

procedure TL2UserInfoImpl.ActionUse(id: Integer; is_ctrl : Boolean = False; is_shift : Boolean = False);
var
    p : TPacket;
begin
    p.Reset(#$56);
    p.WriteD(id);

    if is_ctrl then
        p.WriteD(1)
    else
        p.WriteD(0); // ctrl

    if is_shift then
        p.WriteC(1)
    else
        p.WriteC(0); // shift
    fEngine.SendToServer(p.data);
end;

constructor TL2UserInfoImpl.Create(aEngine: TEngine);
begin
    fEngine := aEngine;
    fObjID := 0;
    fPos.Reset;
    fSkills := nil;
    fBuffs := nil;
    IgnoreValidatePos := false;
    fDeathPenaltyLevel := 0;
    fGaugeReadyTime := 0;
    fSoulshotsEnabled := nil;
end;

destructor TL2UserInfoImpl.Destroy;
begin
    fSkills := nil;
    fBuffs := nil;
    fSoulshotsEnabled := nil;
    inherited;
end;

procedure TL2UserInfoImpl.EnableAutoSoulshot(item_id: Integer);
var
    p : TPacket;
begin
    p.Reset(#$d0);
    p.WriteH($0d);
    p.WriteD(item_id);
    p.WriteD(1);

    fEngine.SendToServer(p.data);
end;

function TL2UserInfoImpl.getBuff(id: Integer): TL2Buff;
var
    i : TL2Buff;
begin
    for i in fBuffs do
        if i.id = id then begin
            Result := i;
            Exit;
        end;
    Result.Reset;
end;

function TL2UserInfoImpl.getCp: Integer;
begin
    Result := fCp;
end;

function TL2UserInfoImpl.getCppc: Integer;
begin
    Result := Round( (fCp / fMaxCp) * 100 );
end;

function TL2UserInfoImpl.getCurrentLoad: Integer;
begin
    Result := fCurrentLoad;
end;

function TL2UserInfoImpl.getCurrentTarget: Integer;
begin
    Result := fCurrentTarget;
end;

function TL2UserInfoImpl.getDeathPenaltyLevel: Integer;
begin
    Result := fDeathPenaltyLevel;
end;

function TL2UserInfoImpl.getExp: Int64;
begin
    Result := fExp;
end;

function TL2UserInfoImpl.getHp: Integer;
begin
    Result := fHp;
end;

function TL2UserInfoImpl.getHppc: Integer;
begin
    Result := Round( (fHp / fMaxHp) * 100 );
end;

function TL2UserInfoImpl.getisUsingSkill: Boolean;
begin
    Result := fGaugeReadyTime >= Core.Time;
end;

function TL2UserInfoImpl.getLevel: Integer;
begin
    Result := fLevel;
end;

function TL2UserInfoImpl.getLoadpc: Integer;
begin
    Result := Round( (fCurrentLoad / fMaxLoad) * 100 );
end;

function TL2UserInfoImpl.getMaxCp: Integer;
begin
    Result := fMaxCp;
end;

function TL2UserInfoImpl.getMaxHp: Integer;
begin
    Result := fMaxHp;
end;

function TL2UserInfoImpl.getMaxLoad: Integer;
begin
    Result := fMaxLoad;
end;

function TL2UserInfoImpl.getMaxMp: Integer;
begin
    Result := fMaxMp;
end;

function TL2UserInfoImpl.getMp: Integer;
begin
    Result := fMp;
end;

function TL2UserInfoImpl.getMppc: Integer;
begin
    Result := Round( (fMp / fMaxMp) * 100 );
end;

function TL2UserInfoImpl.getName: string;
begin
    Result := fName;
end;

function TL2UserInfoImpl.getObjID: Integer;
begin
    Result := fObjID;
end;

function TL2UserInfoImpl.getPos: TVec3i;
begin
    Result := fPos;
end;

function TL2UserInfoImpl.getSkill(id: Integer): TL2Skill;
var
    i : TL2Skill;
begin
    for i in fSkills do
        if i.id = id then begin
            Result := i;
            Exit;
        end;
    Result.Reset;
end;

function TL2UserInfoImpl.getWeaponEquipped: Integer;
begin
    Result := fWeaponItemID;
end;

procedure TL2UserInfoImpl.HandlePacket(pck: string; FromServer: Boolean);
var
    p : TPacket;
    i, j, k : Integer;
    subid : word;
    f : Boolean;
begin
    if FromServer then
        case pck[1] of
            // user info
            #$32 : begin
                p.Reset(pck, 2);
                fPos.Read(p);
                fObjID := ReadD( pck, 18 );

                p.Reset(pck, 22);
                fName := p.ReadS;

                p.Skip(4 + 4 + 4);
                fLevel := p.ReadD;
                fExp := p.ReadQ;

                p.Skip(8 + 6*4);
                fMaxHp := p.ReadD;
                fHp := p.ReadD;
                fMaxMp := p.ReadD;
                fMp := p.ReadD;
                fSp := p.ReadD;
                fCurrentLoad := p.ReadD;
                fMaxLoad := p.ReadD;

                p.Skip(136);
                fWeaponItemID := p.ReadD;

                p.Skip(312);
                p.SkipS;
                p.Skip(61);
                fMaxCp := p.ReadD;
                fCp := p.ReadD;
            end;

            // teleport to location
            #$22 : begin
                if ReadD(pck, 2) = fObjID then begin
                    IgnoreValidatePos := true;
                    fPos.X := ReadD(pck, 6);
                    fPos.Y := ReadD(pck, 10);
                    fPos.Z := ReadD(pck, 14);
                end;
            end;

            // status update
            #$18 : begin
                p.Reset(pck, 2);
                if p.ReadD = fObjID then begin
                    i := p.ReadD;
                    while i > 0 do begin
                        Dec(i);
                        case p.ReadD of
                            $01 : fLevel := p.ReadD;
                            $02 : fExp := p.ReadQ;
                            $09 : fHp := p.ReadD;
                            $0A : fMaxHp := p.ReadD;
                            $0B : fMp := p.ReadD;
                            $0C : fMaxMp := p.ReadD;
                            $0D : fSp := p.ReadD;
                            $0E : fCurrentLoad := p.ReadD;
                            $0F : fMaxLoad := p.ReadD;
                            $21 : fCp := p.ReadD;
                            $22 : fMaxCp := p.ReadD;
                            else p.ReadD;
                        end;
                    end;
                end;
            end;

            // target selected
            #$23 : begin
                p.Reset(pck, 2);
                if p.ReadD = fObjID then begin
                    fCurrentTarget := p.ReadD;
                    fPos.Read(p);
                end;
            end;

            // my target selected
            #$B9 : begin
                p.Reset(pck, 2);
                fCurrentTarget := p.ReadD;
            end;

            // target unselected
            #$24 : begin
                p.Reset(pck, 2);
                if p.ReadD = fObjID then begin
                    fCurrentTarget := 0;
                    fPos.Read(p);
                end;
            end;

            // skills list
            #$5F : begin
                p.Reset(pck, 2);
                i := p.ReadD;
                SetLength(fSkills, i);
                while i > 0 do begin
                    Dec(i);
                    fSkills[i].is_passive       := p.ReadD = 1;
                    fSkills[i].level            := p.ReadD;
                    fSkills[i].id               := p.ReadD;
                    fSkills[i].is_disabled      := p.ReadC = 1;
                    fSkills[i].enchant_level    := p.ReadC;
                    fSkills[i].reuse_ready_time := Core.Time;
                end;
            end;

            // magic skill use
            #$48 : begin
                p.Reset(pck, 2);
                if p.ReadD = fObjID then begin
                    i := ReadD(pck, 10);
                    for j := 0 to Length(fSkills)-1 do
                        if fSkills[j].id = i then begin
                            {$WARNINGS OFF}
                            fSkills[j].reuse_ready_time := Core.Time + ReadD(pck, 22);
                            {$WARNINGS ON}
                            Break;
                        end;
                end;
            end;

            // magic effect icons
            #$85 : begin
                p.Reset(pck, 2);
                i := p.ReadH;
                SetLength(fBuffs, i);
                while i > 0 do begin
                    Dec(i);
                    fBuffs[i].id := p.ReadD;
                    fBuffs[i].level := p.ReadH;
                    {$WARNINGS OFF}
                    fBuffs[i].end_time := Core.Time + p.ReadD;
                    {$WARNINGS ON}
                end;

            end;

            // etc status update
            #$f9 : begin
                fDeathPenaltyLevel := ReadD(pck, 30);
            end;

            // setup gauge
            #$6b : begin
                p.Reset(pck, 2);
                if p.ReadD = fObjID then begin
                    p.Skip(4);
                    {$WARNINGS OFF}
                    fGaugeReadyTime := Core.Time + p.ReadD;
                    {$WARNINGS ON}
                end;
            end;

            #$fe : begin
                p.Reset(pck, 2);
                subid := p.ReadH;
                if subid = $0C then begin
                    j := p.ReadD; // item id
                    if p.ReadD = 1 then begin
                        f := False;
                        for i in fSoulshotsEnabled do
                            if i = j then begin
                                f := true;
                                break;
                            end;
                        if not f then begin
                            SetLength(fSoulshotsEnabled, Length(fSoulshotsEnabled)+1);
                            fSoulshotsEnabled[High(fSoulshotsEnabled)] := j;
                        end;
                    end else begin
                        for i := 0 to Length(fSoulshotsEnabled) - 1 do
                            if fSoulshotsEnabled[i] = j then begin
                                for k := i to Length(fSoulshotsEnabled) - 2 do
                                    fSoulshotsEnabled[k] := fSoulshotsEnabled[k+1];
                                SetLength(fSoulshotsEnabled, Length(fSoulshotsEnabled)-1);
                            end;
                    end;
                end;
            end;
        end
    else
        case pck[1] of
            // validate position
            #$59 : if not IgnoreValidatePos then begin
                p.Reset(pck, 2);
                fPos.Read(p);
            end;

            // appearing
            #$3a : IgnoreValidatePos := false;
        end;

end;

function TL2UserInfoImpl.HaveBuff(id: Integer): Boolean;
var
    i : TL2Buff;
begin
    for i in fBuffs do
        if i.id = id then begin
            Result := true;
            exit;
        end;
    Result := false;
end;

function TL2UserInfoImpl.HaveSkill(id: Integer): Boolean;
var
    i : TL2Skill;
begin
    for i in fSkills do
        if i.id = id then begin
            Result := true;
            exit;
        end;
    Result := false;
end;

function TL2UserInfoImpl.isSoulshotEnabled(item_id: Integer): Boolean;
var
    i : Integer;
begin
    for i := 0 to Length(fSoulshotsEnabled) - 1 do
        if fSoulshotsEnabled[i] = item_id then
        begin
            Result := true;
            exit;
        end;

    Result := false;        
end;

procedure TL2UserInfoImpl.MoveBackwardToLocation(toPos: TVec3i);
var
    p : TPacket;
begin
    p.Reset(#$0f);

    p.WriteD(toPos.X);
    p.WriteD(toPos.Y);
    p.WriteD(toPos.Z);

    p.WriteD(fPos.X);
    p.WriteD(fPos.Y);
    p.WriteD(fPos.Z);

    p.WriteD(1);

    fEngine.SendToServer(p.data);
end;

procedure TL2UserInfoImpl.SayToChat(channel: Integer; msg: string);
var
    p : TPacket;
begin
    p.Reset(#$49);
    p.WriteS(msg);
    p.WriteD(channel);
    fEngine.SendToServer(p.data);
end;

{ TL2InventoryImpl }

constructor TL2InventoryImpl.Create(aEngine: TEngine);
begin
    fEngine := aEngine;
    fItems := nil;
end;

destructor TL2InventoryImpl.Destroy;
begin
    fItems := nil;
    inherited;
end;

function TL2InventoryImpl.getCount: Integer;
begin
    Result := Length(fItems);
end;

function TL2InventoryImpl.getItem(index: Integer): TL2InvItem;
begin
    if (index < 0) or (index >= Length(fItems)) then begin
        Result.Reset;
        exit;
    end;

    Result := fItems[index];
end;

function TL2InventoryImpl.getItemId(item_id: Integer): TL2InvItem;
var
    i : TL2InvItem;
begin
    for i in fItems do
        if i.item_id = item_id then begin
            Result := i;
            exit;
        end;

    Result.Reset;        
end;

procedure TL2InventoryImpl.HandlePacket(pck: string; FromServer: Boolean);
var
    p : TPacket;
    i, j, k, a, id : Integer;
    found : Boolean;
begin
    if FromServer then case pck[1] of
        // item list
        #$11 : begin
            p.Reset(pck, 4);
            i := p.ReadH;
            SetLength(fItems, i);
            while i > 0 do begin
                Dec(i);
                fItems[i].objid := p.ReadD;
                fItems[i].item_id := p.ReadD;
                p.Skip(4);
                fItems[i].count := p.ReadQ;
                p.Skip(4);
                fItems[i].is_equipped := p.ReadH = 1;
                p.Skip(4);
                fItems[i].enchant_level := p.ReadH;
                p.Skip(36);
            end;
        end;

        // inventory update
        #$21 : begin
            p.Reset(pck, 2);
            i := p.ReadH;
            while i > 0 do begin
                Dec(i);
                a := p.ReadH; 
                case a of
                    // add
                    1 : begin
                        SetLength( fItems, Length(fItems)+1 );
                        j := High(fItems);
                        fItems[j].item_id := p.ReadD;
                        p.Skip(4);
                        fItems[j].count := p.ReadQ;
                        p.Skip(4);
                        fItems[j].is_equipped := p.ReadH = 1;
                        p.Skip(4);
                        fItems[j].enchant_level := p.ReadH;
                        p.Skip(36);
                    end;
                    // mod
                    2 : begin
                        id := p.ReadD;
                        found := false;
                        for j := 0 to Length(fItems) - 1 do
                            if fItems[j].objid = id then begin
                                found := True;
                                fItems[j].item_id := p.ReadD;
                                p.Skip(4);
                                fItems[j].count := p.ReadQ;
                                p.Skip(4);
                                fItems[j].is_equipped := p.ReadH = 1;
                                p.Skip(4);
                                fItems[j].enchant_level := p.ReadH;
                                p.Skip(36);

                                Break;
                            end;

                        if not found then p.Skip(64);
                    end;
                    // remove
                    3 : begin
                        id := p.ReadD;
                        for j := 0 to Length(fItems) - 1 do
                            if fItems[j].objid = id then begin
                                for k := j to Length(fItems) - 2 do
                                    fItems[k] := fItems[k+1];
                                SetLength(fItems, Length(fItems)-1);
                                Break;
                            end;
                    end;
                end;
            end;
        end;
    end;

end;

function TL2InventoryImpl.ItemExist(item_id: Integer): Boolean;
var
    i : TL2InvItem;
begin
    for i in fItems do
        if i.item_id = item_id then begin
            Result := true;
            exit;
        end;
    Result := false;        
end;

procedure TL2InventoryImpl.UseItem(item_id: Integer; is_ctrl : Boolean = false);
var
    p : TPacket;
begin
    if not ItemExist(item_id) then exit;

    p.Reset(#$19);
    p.WriteD( getItemId(item_id).objid );
    if is_ctrl then
        p.WriteD(1)
    else
        p.WriteD(0);
    fEngine.SendToServer(p.data);
end;

{ TL2PartyImpl }

constructor TL2PartyImpl.Create(aEngine: TEngine);
begin
    fEngine := aEngine;
    fItems := nil;
end;

destructor TL2PartyImpl.Destroy;
begin
    fItems := nil;
    inherited;
end;

procedure TL2PartyImpl.Dismiss(name: string);
var
    p : TPacket;
begin
    p.Reset(#$45);
    p.WriteS(name);
    fEngine.SendToServer(p.data);
end;

function TL2PartyImpl.Exist(name: string): Boolean;
var
    i : TL2PartyMember;
begin
    for i in fItems do
        if i.name = name then begin
            Result := True;
            Exit;
        end;

    Result := false;        
end;

function TL2PartyImpl.getCount: Integer;
begin
    Result := Length(fItems);
end;

function TL2PartyImpl.getItem(index: Integer): TL2PartyMember;
begin
    Result := fItems[index];
end;

function TL2PartyImpl.getLeader: TL2PartyMember;
var
    i : TL2PartyMember;
begin
    for i in fItems do
        if i.objid = fLeaderObjID then
        begin
            Result := i;
            exit;
        end;

    Result.Reset;        
end;

procedure TL2PartyImpl.HandlePacket(pck: string; FromServer: Boolean);
var
    p : TPacket;
    i, j, id : Integer;
begin
    if FromServer then case pck[1] of
        // party small window all
        #$4e : begin
            p.Reset(pck, 2);
            fLeaderObjID := p.ReadD;
            p.Skip(4); // loot
            i := p.ReadD;
            SetLength(fItems, i);
            while i > 0 do begin
                Dec(i);
                fItems[i].objid := p.ReadD;
                fItems[i].name := p.ReadS;
                fItems[i].cp := p.ReadD;
                fItems[i].max_cp := p.ReadD;
                fItems[i].hp := p.ReadD;
                fItems[i].max_hp := p.ReadD;
                fItems[i].mp := p.ReadD;
                fItems[i].max_mp := p.ReadD;
                fItems[i].level := p.ReadD;
                fItems[i].class_id := p.ReadD;
                p.Skip(16);
                // pet id
                if p.ReadD <> 0 then begin
                    p.Skip(4);
                    p.SkipS;
                    p.Skip(20);
                end;
            end;
        end;

        // party small window add
        #$4f : begin
            p.Reset(pck, 2);
            fLeaderObjID := p.ReadD;
            p.Skip(4); // loot
            SetLength(fItems, Length(fItems)+1);
            i := High(fItems);
            fItems[i].objid := p.ReadD;
            fItems[i].name := p.ReadS;
            fItems[i].cp := p.ReadD;
            fItems[i].max_cp := p.ReadD;
            fItems[i].hp := p.ReadD;
            fItems[i].max_hp := p.ReadD;
            fItems[i].mp := p.ReadD;
            fItems[i].max_mp := p.ReadD;
            fItems[i].level := p.ReadD;
            fItems[i].class_id := p.ReadD;
        end;

        // party small window delete all
        #$50 : begin
            fItems := nil;
        end;

        // party small window delete
        #$51 : begin
            id := ReadD(pck, 2);
            for i := 0 to Length(fItems) - 1 do
                if fItems[i].objid = id then begin
                    for j := i to Length(fItems)-2 do
                        fItems[j] := fItems[j+1];
                    SetLength(fItems, Length(fItems)-1);
                    Break;
                end;
        end;

        // party small window update
        #$52 : begin
            p.Reset(pck, 2);
            id := p.ReadD;
            for i := 0 to Length(fItems) - 1 do
                if fItems[i].objid = id then begin
                    fItems[i].name := p.ReadS;
                    fItems[i].cp := p.ReadD;
                    fItems[i].max_cp := p.ReadD;
                    fItems[i].hp := p.ReadD;
                    fItems[i].max_hp := p.ReadD;
                    fItems[i].mp := p.ReadD;
                    fItems[i].max_mp := p.ReadD;
                    fItems[i].level := p.ReadD;
                    fItems[i].class_id := p.ReadD;
                end;
        end;
    end;

end;

procedure TL2PartyImpl.Invite(name: string; loot_type : Integer = 0);
var
    p : TPacket;
begin
    p.Reset(#$42);
    p.WriteS(name);
    p.WriteD(loot_type);
    fEngine.SendToServer(p.data);
end;

procedure TL2PartyImpl.InviteCommandChannel(name: string);
var
    p : TPacket;
begin
    p.Reset( #$d0#$06#$00 );
    p.WriteS(name);
    fEngine.SendToServer(p.data);
end;

procedure TL2PartyImpl.JoinAnswer(ack: Boolean);
var
    p : TPacket;
begin
    p.Reset(#$43);
    if ack then
        p.WriteD(1)
    else
        p.WriteD(0);

    fEngine.SendToServer(p.data);
end;

procedure TL2PartyImpl.Leave;
begin
    fEngine.SendToServer(#$44);
end;

{ TL2DropImpl }

constructor TL2DropImpl.Create(aEngine: TEngine);
begin
    fEngine := aEngine;
    fItems := nil;
    fAdenaReceived := 0;
end;

destructor TL2DropImpl.Destroy;
begin
    fItems := nil;

    inherited;
end;

function TL2DropImpl.getAdenaReceived: Integer;
begin
    Result := fAdenaReceived;
end;

function TL2DropImpl.getCount: Integer;
begin
    Result := Length(fItems);
end;

function TL2DropImpl.getItems(idx: Integer): TL2DropItem;
begin
    if (idx >= 0) and (idx < Length(fItems)) then
        Result := fItems[idx]
    else
        Result.Reset;
end;

procedure TL2DropImpl.HandlePacket(pck: string; FromServer: Boolean);
var
    i, j, id : Integer;
    p : TPacket;
begin
    if FromServer then case pck[1] of
        // drop item
        #$16 : begin
            p.Reset(pck, 2);
            SetLength(fItems, length(fItems)+1);
            i := High(fItems);
            fItems[i].player_id := p.ReadD;
            fItems[i].objid := p.ReadD;
            fItems[i].item_id := p.ReadD;
            fItems[i].pos.Read(p);
            p.Skip(4);
            fItems[i].count := p.ReadQ;
        end;

        // spawn item
        #$05 : begin
            p.Reset(pck, 2);
            SetLength(fItems, length(fItems)+1);
            i := High(fItems);
            fItems[i].player_id := 0;
            fItems[i].objid := p.ReadD;
            fItems[i].item_id := p.ReadD;
            fItems[i].pos.Read(p);
            p.Skip(4);
            fItems[i].count := p.ReadQ;
        end;

        // get item
        #$17 : begin
            id := ReadD(pck, 6);
            for i := 0 to Length(fItems)-1 do
                if fItems[i].objid = id then
                begin
                    // если подняли мы
                    if (ReadD(pck, 2) = fEngine.Me.ObjID) and (fItems[i].item_id = 57) then
                    begin
                        Inc(fAdenaReceived, fItems[i].count);
                    end;

                    for j := i to Length(fItems) - 2 do
                        fItems[j] := fItems[j+1];
                    SetLength(fItems, Length(fItems)-1);
                end;


            
        end;

        // delete object
        #$08 : begin
            id := ReadD(pck, 2);
            for i := 0 to Length(fItems)-1 do
                if fItems[i].objid = id then
                begin
                    for j := i to Length(fItems) - 2 do
                        fItems[j] := fItems[j+1];
                    SetLength(fItems, Length(fItems)-1);
                end;
        end;
    end;
end;

function TL2DropImpl.myNear(radius : Integer = 1000): Integer;
var
    i : TL2DropItem;
    min, d : Integer;
begin
    Result := 0;
    if Length(fItems) = 0 then Exit;

    min := radius;
    for i in fItems do
    begin
        d := i.pos.Dist(fEngine.Me.Pos);
        if d < min then begin
            Result := i.objid;
            min := d;
        end;
    end;
end;

function TL2DropImpl.PickupMyNearest: Boolean;
var
    id : Integer;
begin
    id := myNear;
    if id <> 0 then begin
        fEngine.Me.Action( id );
        Result := true;
    end else
        Result := false;
end;

{ TL2PlayersImpl }

constructor TL2PlayersImpl.Create(aEngine: TEngine);
begin
    fEngine := aEngine;
    fItems := nil;
end;

destructor TL2PlayersImpl.Destroy;
begin
    fItems := nil;

    inherited;
end;

function TL2PlayersImpl.getCount: Integer;
begin
    Result := Length(fItems);
end;

function TL2PlayersImpl.getItems(idx: Integer): TL2Char;
begin
    if (idx >= 0) and (idx < Length(fItems)) then
        Result := fItems[idx]
    else
        Result.Reset;
end;

function TL2PlayersImpl.getPlayerByName(n: string): TL2Char;
var
    i : Integer;
begin
    for i := 0 to Length(fItems) - 1 do
        if LowerCase( fItems[i].name ) = LowerCase(n) then begin
            Result := fItems[i];
            exit;
        end;
    Result.Reset;
end;

procedure TL2PlayersImpl.HandlePacket(pck: string; FromServer: Boolean);
var
    p : TPacket;
    id, idx, i, j : Integer;
begin
    if FromServer then
    case pck[1] of
        // char info
        #$31 : begin
            id := ReadD(pck, 18);

            p.Reset(pck, 2);
            idx := -1;
            for i := 0 to Length(fItems)-1 do
                if fItems[i].objid = id then
                begin
                    idx := i;
                    Break;
                end;
            if idx < 0 then begin
                SetLength(fItems, Length(fItems)+1);
                idx := High(fItems);
                fItems[idx].objid := id;
            end;

            fItems[idx].pos.Read(p);
            p.Skip(8);
            fItems[idx].name := p.ReadS;
        end;

        // move to location
        #$2f : begin
            id := ReadD(pck, 2);
            for i := 0 to Length(fItems)-1 do
                if fItems[i].objid = id then
                begin
                    fItems[i].pos.X := ReadD(pck, 6);
                    fItems[i].pos.Y := ReadD(pck, 10);
                    fItems[i].pos.Z := ReadD(pck, 14);
                    break;
                end;
        end;
        
        // stop move
        #$47 : begin
            id := ReadD(pck, 2);
            for i := 0 to Length(fItems)-1 do
                if fItems[i].objid = id then
                begin
                    fItems[i].pos.X := ReadD(pck, 6);
                    fItems[i].pos.Y := ReadD(pck, 10);
                    fItems[i].pos.Z := ReadD(pck, 14);
                    break;
                end;
        end;

        // delete object
        #$08 : begin
            id := ReadD(pck, 2);
            for i := 0 to Length(fItems)-1 do
                if fItems[i].objid = id then
                begin
                    for j := i to Length(fItems) - 2 do
                        fItems[j] := fItems[j+1];
                    SetLength(fItems, Length(fItems)-1);
                end;
        end;
    end;
end;

{ TL2NpcMobsImpl }

constructor TL2NpcMobsImpl.Create(aEngine: TEngine);
begin
    fEngine := aEngine;
    fItems := nil;
end;

destructor TL2NpcMobsImpl.Destroy;
begin
    fItems := nil;

    inherited;
end;

function TL2NpcMobsImpl.getCount: Integer;
begin
    Result := Length(fItems);
end;

function TL2NpcMobsImpl.getItems(idx: Integer): TL2Npc;
begin
    if (idx >= 0) and (idx < Length(fItems)) then
        Result := fItems[idx]
    else
        Result.Reset;
end;

function TL2NpcMobsImpl.getItemsByObjID(objid: Integer): TL2Npc;
var
    i : TL2Npc;
begin
    for i in fItems do
        if i.objid = objid then
        begin
            Result := i;
            exit;
        end;

    Result.Reset;        
end;

function TL2NpcMobsImpl.getNearMob(agro: Boolean; mobid : Integer; radius : Integer): Integer;
var
    i : TL2Npc;
    min, d : Integer;
begin
    Result := 0;
    if Length(fItems) = 0 then Exit;

    min := radius;
    for i in fItems do begin
        if (i.is_mob) and (i.is_agro = agro) and (not i.is_dead)
        and ( (mobid=0) or ( (mobid <> 0) and (i.npc_type = mobid) ) )
        then
        begin
            d := i.pos.Dist(fEngine.Me.Pos);
            if (d < min) then begin
                Result := i.objid;
                min := d;
            end;
        end;
    end;
end;

procedure TL2NpcMobsImpl.HandlePacket(pck: string; FromServer: Boolean);
var
    p : TPacket;
    i, j, id, idx, t1, t2 : Integer;
begin
    if FromServer then case pck[1] of
        // delete object
        #$08 : begin
            id := ReadD(pck, 2);
            for i := 0 to Length(fItems)-1 do
                if fItems[i].objid = id then
                begin
                    for j := i to Length(fItems) - 2 do
                        fItems[j] := fItems[j+1];
                    SetLength(fItems, Length(fItems)-1);
                end;
        end;

        // npc info
        #$0C : begin
            p.Reset(pck, 2);
            id := p.ReadD;
            idx := -1;
            for i := 0 to Length(fItems)-1 do
                if fItems[i].objid = id then
                begin
                    idx := i;
                    Break;
                end;
            if idx < 0 then begin
                SetLength(fItems, Length(fItems)+1);
                idx := High(fItems);
                fItems[idx].objid := id;
            end;

            fItems[idx].npc_type := p.ReadD;
            fItems[idx].is_mob := (p.ReadD = 1);
            fItems[idx].pos.Read(p);
            fItems[idx].is_dead := pck[121] <> #0;
            fItems[idx].is_agro := false;
            fItems[idx].is_in_combat := pck[120] <> #0;
            fItems[idx].is_sweepable := false;
        end;

        // die
        #$00 : begin
            id := ReadD(pck, 2);
            // me die
            if id = fEngine.Me.ObjID then begin
                for i := 0 to Length(fItems)-1 do
                    fItems[i].is_agro := false;
            end else
            // die mob
            for i := 0 to Length(fItems)-1 do
                if fItems[i].objid = id then
                begin
                    fItems[i].is_dead := True;
                    fItems[i].is_sweepable := ReadD(pck, 22) = 1;
                    break;
                end;
        end;

        // attack
        #$33 : begin
            t1 := ReadD(pck, 2);
            t2 := ReadD(pck, 6);

            // my attack and dmg > 0
            if (t1 = fEngine.Me.ObjID) and (ReadD(pck, 10) <> 0) then
            for i := 0 to Length(fItems)-1 do
                if fItems[i].objid = t2 then
                begin
                    fItems[i].is_agro := true;
                    Break;
                end;

            // me under attack
            if (t2 = fEngine.Me.ObjID) then
            for i := 0 to Length(fItems)-1 do
                if fItems[i].objid = t1 then
                begin
                    fItems[i].is_agro := true;
                    Break;
                end;
        end;

        // move to location
        #$2f : begin
            id := ReadD(pck, 2);
            for i := 0 to Length(fItems)-1 do
                if fItems[i].objid = id then
                begin
                    fItems[i].pos.X := ReadD(pck, 6);
                    fItems[i].pos.Y := ReadD(pck, 10);
                    fItems[i].pos.Z := ReadD(pck, 14);
                    break;
                end;
        end;
        
        // stop move
        #$47 : begin
            id := ReadD(pck, 2);
            for i := 0 to Length(fItems)-1 do
                if fItems[i].objid = id then
                begin
                    fItems[i].pos.X := ReadD(pck, 6);
                    fItems[i].pos.Y := ReadD(pck, 10);
                    fItems[i].pos.Z := ReadD(pck, 14);
                    break;
                end;
        end;

        // magic skill use
        #$48 : begin
            id := ReadD(pck, 2);
            if id <> fEngine.Me.ObjID then
            for i := 0 to Length(fItems)-1 do
                if fItems[i].objid = id then
                begin
                    fItems[i].pos.X := ReadD(pck, 26);
                    fItems[i].pos.Y := ReadD(pck, 30);
                    fItems[i].pos.Z := ReadD(pck, 34);
                    break;
                end;
        end;

        // move to pawn
        #$72 : begin
            id := ReadD(pck, 2);
            if ReadD(pck, 6) = fEngine.Me.ObjID then
            for i := 0 to Length(fItems)-1 do
                if fItems[i].objid = id then begin
                    fItems[i].is_agro := true;
                end;
            
        end;
    end;
end;

end.
