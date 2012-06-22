unit pfHeader;

interface

uses
    SysUtils, StrUtils, Math;

type
    TEngine = class;

    // сетевой пакет
    PPacket = ^TPacket;
    TPacket = record
        data : ansistring;
        index : Integer;

        function Size : Integer;
        function Reset(const p : string = ''; i : Integer = 0) : PPacket;
        // скопировать данные из другого пакета в себя
        procedure Clone(p : TPacket);

        function ReadC : Byte;
        function ReadH : word;
        function ReadD : Integer;
        function ReadQ : Int64;
        function ReadF : Double;
        function ReadS : string;

        procedure Skip(bytes_count : Integer);
        procedure SkipS;

        function Write(v : string) : PPacket;
        function WriteS(v : string) : PPacket;
        function WriteC(v : byte) : PPacket;
        function WriteH(v : word) : PPacket;
        function WriteD(v : Integer) : PPacket;
        function WriteQ(v : Int64) : PPacket;
        function WriteF(v : Double) : PPacket;

        procedure SendToClient(cname : string);
        procedure SendToServer(cname : string);
    end;

    TVec3i = record
        X, Y, Z : Integer;
        function toString: string;
        procedure fromString(s : string);
        procedure Reset;
        function DistEx(p : TVec3i) : Extended;
        function Dist(p : TVec3i) : Integer;
        procedure Read(var p : TPacket);
    end;

    // базовый клсс от которого наследуются все длл
    TPluginDll = class
    private
        function getLinkedCharName: string;
        function getmyID : Integer;
        function getmyPos : TVec3i;
    public
        procedure Init; virtual;
        procedure Finit; virtual;
        procedure ProcessPacket(var pck : AnsiString; FromServer : Boolean; ConnectName : string; Engine : TEngine); virtual; abstract;
        function CallFunction(a : Integer; Params : Variant) : Integer; virtual;
        procedure onTimer(id : Integer); virtual;

        function myEngine : TEngine;
        procedure LogPrint(m : string);
        function getAppPath : string;

        procedure TimerStart(id : Integer; interval : Integer);
        procedure TimerStop(id : Integer);
        function isTimerEnabled(id : Integer) : Boolean;

        property AppPath : string read getAppPath;
        property LinkedCharName : string read getLinkedCharName;
        property myID : Integer read getmyID;
        property myPos : TVec3i read getmyPos;
    end;

    TL2DropItem = record
        objid : Integer;
        player_id : Integer;
        pos : TVec3i;
        item_id : Integer;
        count : Integer;

        procedure Reset;
    end;

    TL2Drop = class
    protected
        procedure HandlePacket(pck : string; FromServer : Boolean); virtual; abstract;

        function getCount : Integer; virtual; abstract;
        function getItems(idx : Integer) : TL2DropItem; virtual; abstract;
        function getAdenaReceived : Integer; virtual; abstract;
    public
        // найти мой ближайший дроп
        function myNear(radius : Integer = 1000) : Integer; virtual; abstract;
        // подобрать мой ближайший дроп если он есть. если нет вернет ложь
        function PickupMyNearest : Boolean; virtual; abstract;

        property Count : Integer read getCount;
        property Items[idx : Integer] : TL2DropItem read getItems; default;
        // сколько адены получено за время коннекта
        property AdenaReceived : Integer read getAdenaReceived;
    end;

    // npc mob
    TL2Npc = record
        objid : Integer;
        pos : TVec3i;
        npc_type : Integer;
        is_mob : Boolean;
        is_agro : Boolean;
        is_dead : Boolean;
        is_in_combat : Boolean;
        is_sweepable : Boolean;

        procedure Reset;
    end;

    TL2NpcMobs = class
    protected
        procedure HandlePacket(pck : string; FromServer : Boolean); virtual; abstract;

        function getCount : Integer; virtual; abstract;
        function getItems(idx : Integer) : TL2Npc; virtual; abstract;
        function getItemsByObjID(objid : Integer) : TL2Npc; virtual; abstract;
    public
        function getNearMob(agro : Boolean = False; mobid : Integer = 0; radius : Integer = 3000) : Integer; virtual; abstract;

        property Count : Integer read getCount;
        property Items[idx : Integer] : TL2Npc read getItems; default;
        property ItemsByObjID[objid : Integer] : TL2Npc read getItemsByObjID;
    end;

    // player
    TL2Char = record
        objid : Integer;
        name : string;
        pos : TVec3i;

        procedure Reset;
    end;

    TL2Players = class
    protected
        procedure HandlePacket(pck : string; FromServer : Boolean); virtual; abstract;

        function getCount : Integer; virtual; abstract;
        function getItems(idx : Integer) : TL2Char; virtual; abstract;
        function getPlayerByName(n : string) : TL2Char; virtual; abstract;
    public
        property Count : Integer read getCount;
        property Items[idx : Integer] : TL2Char read getItems; default;
        property PlayerByName[n : string] : TL2Char read getPlayerByName;
    end;

    TL2Skill = record
        id : Integer;
        level : Integer;
        is_disabled : Boolean;
        is_passive : Boolean;
        enchant_level : Byte;
        // когда скилл будет готов
        reuse_ready_time : Cardinal;

        procedure Reset;
        function isReady : Boolean;
    end;

    TL2Buff = record
        id : Integer;
        level : Integer;
        // когда баф кончится
        end_time : Cardinal;

        procedure Reset;
    end;

    // мой чар -----------------------------------------------------------------
    TL2UserInfo = class
    protected
        procedure HandlePacket(pck : string; FromServer : Boolean); virtual; abstract;

        function getObjID : Integer; virtual; abstract;
        function getPos : TVec3i; virtual; abstract;
        function getName : string; virtual; abstract;

        function getHp : Integer; virtual; abstract;
        function getMp : Integer; virtual; abstract;
        function getCp : Integer; virtual; abstract;
        function getMaxHp : Integer; virtual; abstract;
        function getMaxMp : Integer; virtual; abstract;
        function getMaxCp : Integer; virtual; abstract;
        function getHppc : Integer; virtual; abstract;
        function getMppc : Integer; virtual; abstract;
        function getCppc : Integer; virtual; abstract;

        function getLevel : Integer; virtual; abstract;
        function getExp : Int64; virtual; abstract;
        function getCurrentTarget : Integer; virtual; abstract;

        function getCurrentLoad : Integer; virtual; abstract;
        function getMaxLoad : Integer; virtual; abstract;
        function getLoadpc : Integer; virtual; abstract;

        function getSkill(id : Integer) : TL2Skill; virtual; abstract;
        function getBuff(id : Integer) : TL2Buff; virtual; abstract;
        function getWeaponEquipped : Integer; virtual; abstract; // item id
        function getDeathPenaltyLevel : Integer; virtual; abstract;
        function getisUsingSkill : Boolean; virtual; abstract;
    public
        function HaveSkill(id : Integer) : Boolean; virtual; abstract;
        function HaveBuff(id : Integer) : Boolean; virtual; abstract;
        function isSoulshotEnabled(item_id : Integer) : Boolean; virtual; abstract;
        procedure EnableAutoSoulshot(item_id : Integer); virtual; abstract;
        
        procedure TargetCancel; virtual; abstract;
        procedure UseSkill(skill_id : Integer; is_ctrl : Boolean = false; is_shift : boolean = false); virtual; abstract;
        procedure Action(objid : Integer); virtual; abstract;
        procedure ActionUse(id : Integer; is_ctrl : Boolean = False; is_shift : Boolean = False); virtual; abstract;
        procedure MoveBackwardToLocation(toPos : TVec3i); virtual; abstract;
        procedure SayToChat(channel : Integer; msg : string); virtual; abstract;

        property ObjID : Integer read getObjID;
        property Pos : TVec3i read getPos;
        property Name : string read getName;
        property DeathPenaltyLevel : Integer read getDeathPenaltyLevel;

        property Hp : Integer read getHp;
        property Mp : Integer read getMp;
        property Cp : Integer read getCp;
        property MaxHp : Integer read getMaxHp;
        property MaxMp : Integer read getMaxMp;
        property MaxCp : Integer read getMaxCp;
        // percent
        property Hppc : Integer read getHppc;
        property Mppc : Integer read getMppc;
        property Cppc : Integer read getCppc;
        // уровень
        property Level : Integer read getLevel;
        property Exp : Int64 read getExp;
        // ид текущей цели
        property CurrentTarget : Integer read getCurrentTarget;
        // загрузка по весу
        property CurrentLoad : Integer read getCurrentLoad;
        property MaxLoad : Integer read getMaxLoad;
        property Loadpc : Integer read getLoadpc;
        // оружие в руках (item id)
        property WeaponEquipped : Integer read getWeaponEquipped;

        property Skills[id : Integer] : TL2Skill read getSkill;
        property Buffs[id : Integer] : TL2Buff read getBuff;
        // используем какой либо скилл (висит прогрессбар над чаром)
        property isUsingSkill : Boolean read getisUsingSkill;
    end;

    // инвентарь ---------------------------------------------------------------
    TL2InvItem = record
        objid : Integer;
        item_id : Integer;
        count : Int64;
        enchant_level : Integer;
        is_equipped : Boolean;

        procedure Reset;
    end;

    TL2Inventory = class
    protected
        procedure HandlePacket(pck : string; FromServer : Boolean); virtual; abstract;

        function getCount : Integer; virtual; abstract;
        function getItem(index : Integer) : TL2InvItem; virtual; abstract;
        function getItemId(item_id : Integer) : TL2InvItem; virtual; abstract;
    public
        function ItemExist(item_id : Integer) : Boolean; virtual; abstract;
        procedure UseItem(item_id : Integer; is_ctrl : Boolean = false); virtual; abstract;
        property Count : Integer read getCount;
        property ItemsIdx[index : Integer] : TL2InvItem read getItem; default;
        property Items[item_id : Integer] : TL2InvItem read getItemId;
    end;

    // пати --------------------------------------------------------------------
    TL2PartyMember = record
        objid : Integer;
        mp, max_mp, hp, max_hp, cp, max_cp : Integer;
        name : string;
        class_id : Integer;
        level : Integer;

        procedure Reset;
    end;

    TL2Party = class
    protected
        procedure HandlePacket(pck : string; FromServer : Boolean); virtual; abstract;

        function getCount : Integer; virtual; abstract;
        function getItem(index : Integer) : TL2PartyMember; virtual; abstract;
        function getLeader : TL2PartyMember; virtual; abstract;
    public
        // выйти из пати
        procedure Leave; virtual; abstract;
        // пригласить в пати
        procedure Invite(name : string; loot_type : Integer = 0); virtual; abstract;
        // пригласить в комманд чанел
        procedure InviteCommandChannel(name : string); virtual; abstract;
        // исключить из пати
        procedure Dismiss(name : string); virtual; abstract;
        // проверить существует ли член пати с таким именем (регистро не зависим)
        function Exist(name : string) : Boolean; virtual; abstract;
        // дать ответ на запрос пати
        procedure JoinAnswer(ack : Boolean); virtual; abstract;

        property Count : Integer read getCount;
        property Items[index : Integer] : TL2PartyMember read getItem; default;
        property Leader : TL2PartyMember read getLeader;
    end;

    // ядро --------------------------------------------------------------------
    TCore = class
    protected
        function getTime : Cardinal; virtual; abstract;
    public
        function isConnectionExist(charname : string) : Boolean; virtual; abstract;
        // получить движок определенного коннекта
        function getEngine(CharName : string) : TEngine; virtual; abstract;
        // имя чара к которому привязан плагин
        function getLinkedCharName(dll : TPluginDll): string; overload; virtual; abstract;
        function getLinkedCharName(dll_name : string): string; overload; virtual; abstract; 
        // вывести строку в лог
        procedure LogPrint(p : TPluginDll; m : string); virtual; abstract;
        // получить путь запуска программы
        function getAppPath : string; virtual; abstract;
        // вызвать функцию из другого плагина
        function PluginCallFunction(plugin_name : string; a : Integer; Params : Variant) : Integer; virtual; abstract;

        procedure TimerStart(dll : TPluginDll; id : Integer; interval : Integer); virtual; abstract;
        procedure TimerStop(dll : TPluginDll; id : Integer); virtual; abstract;
        function isTimerEnabled(dll : TPluginDll; id : Integer) : Boolean; virtual; abstract;

        property Time : Cardinal read getTime;
    end;

    // бот движок коннекта -----------------------------------------------------
    TEngine = class
    protected
        function getInventory : TL2Inventory; virtual; abstract;
        function getParty : TL2Party; virtual; abstract;
        function getDrop : TL2Drop; virtual; abstract;
        function getMobs : TL2NpcMobs; virtual; abstract;
        function getPlayers : TL2Players; virtual; abstract;
        function getMe : TL2UserInfo; virtual; abstract;
    public
        // обработать пакет. вызывается в пф
        procedure HandlePacket(pck : string; FromServer : Boolean); virtual; abstract;
        // отправить пакет (подставляется длина и шифруется если надо)
        procedure SendToServer(pck : string); virtual; abstract;
        procedure SendToClient(pck : string); virtual; abstract;
        // сказать от имени бота в чат клиента
        procedure botSay(msg : string; channel : Integer = 0); virtual; abstract;
        // хтмл чат в клиент
        procedure NpcHtmlMsg(body : string); virtual; abstract;

        property Inventory : TL2Inventory read getInventory;
        property Party : TL2Party read getParty;
        property Drop : TL2Drop read getDrop;
        property Mobs : TL2NpcMobs read getMobs;
        property Players : TL2Players read getPlayers;
        property Me : TL2UserInfo read getMe;
    end;
    //--------------------------------------------------------------------------
var
    Core : TCore;
    
//------------------------------------------------------------------------------
procedure CoreInit(CoreObj : TCore); stdcall;
//------------------------------------------------------------------------------
procedure WriteC(var pck: string; const v: Byte;        index: integer = -1);
procedure WriteH(var pck: string; const v: Word;        index: integer = -1);
procedure WriteD(var pck: string; const v: Integer;     index: integer = -1);
procedure WriteQ(var pck: string; const v: Int64;       index: integer = -1);
procedure WriteF(var pck: string; const v: Double;      index: integer = -1);
procedure WriteS(var pck: string; const v: string;      index: integer = -1);
//------------------------------------------------------------------------------
function ReadC(const pck:string; const index:integer):Byte;
function ReadH(const pck:string; const index:integer):Word;
function ReadD(const pck:string; const index:integer):Integer;
function ReadQ(const pck:string; const index:integer):Int64;
function ReadF(const pck:string; const index:integer):Double;
function ReadS(const pck:string; const index:integer):string;
procedure SkipS(const pck:string; var offset : Integer);
//------------------------------------------------------------------------------
procedure SendToClientEx(pck : AnsiString; cname : string); overload;
procedure SendToClientEx(pck : TPacket; cname : string); overload;
procedure SendToServerEx(pck : AnsiString; cname : string); overload;
procedure SendToServerEx(pck : TPacket; cname : string); overload;
//------------------------------------------------------------------------------
function Vec3i(x,y,z : Integer) : TVec3i;

implementation

function Vec3i(x,y,z : Integer) : TVec3i;
begin
    Result.X := x;
    Result.Y := y;
    Result.Z := z;
end;

procedure CoreInit(CoreObj : TCore); stdcall;
begin
  Core := CoreObj;
end;

procedure WriteC(var pck: string; const v: byte; index: integer);
const
  dt_size = 1;
begin
  if index=-1 then index:=Length(pck)+1;
  if index+dt_size-1>Length(pck) then SetLength(pck,index+dt_size-1);
  Move(v,pck[index],dt_size);
end;

procedure WriteH(var pck: string; const v: word; index: integer);
const
  dt_size = 2;
begin
  if index=-1 then index:=Length(pck)+1;
  if index+dt_size-1>Length(pck) then SetLength(pck,index+dt_size-1);
  Move(v,pck[index],dt_size);
end;

procedure WriteD(var pck: string; const v: Integer; index: integer);
const
  dt_size = 4;
begin
  if index=-1 then index:=Length(pck)+1;
  if index+dt_size-1>Length(pck) then SetLength(pck,index+dt_size-1);
  Move(v,pck[index],dt_size);
end;

procedure WriteQ(var pck: string; const v: Int64; index: integer);
const
  dt_size = 8;
begin
  if index=-1 then index:=Length(pck)+1;
  if index+dt_size-1>Length(pck) then SetLength(pck,index+dt_size-1);
  Move(v,pck[index],dt_size);
end;

procedure WriteF(var pck: string; const v: Double; index: integer);
const
  dt_size = 8;
begin
  if index=-1 then index:=Length(pck)+1;
  if index+dt_size-1>Length(pck) then SetLength(pck,index+dt_size-1);
  Move(v,pck[index],dt_size);
end;

procedure WriteS(var pck: string; const v: string; index: integer);
var
  temp: WideString;
  dt_size: Word;
begin
  dt_size:=Length(v)*2+2;
  temp:=v+#0;
  if index=-1 then index:=Length(pck)+1;
  if index+dt_size-1>Length(pck) then SetLength(pck,index+dt_size-1);
  Move(temp[1],pck[index],dt_size);
end;

function ReadC;
begin
  Result:=0;
  if index>Length(pck) then Exit;
  Result:=Byte(pck[index]);
end;

function ReadH;
begin
  Result:=0;
  if index+1>Length(pck) then Exit;
  Move(pck[index],Result,2);
end;


function ReadD;
begin
  Result:=0;
  if index+3>Length(pck) then Exit;
  Move(pck[index],Result,4);
end;

function ReadQ;
begin
  Result:=0;
  if index+7>Length(pck) then Exit;
  Move(pck[index],Result,8);
end;

function ReadF;
begin
  Result:=0;
  if index+7>Length(pck) then Exit;
  Move(pck[index],Result,8);
end;

function ReadS;
var
  temp: WideString;
  d: Integer;
begin
  d:=PosEx(#0#0,pck,index)-index;
  if (d mod 2)=1 then Inc(d);
  SetLength(temp,d div 2);
  if d>=2 then Move(pck[index],temp[1],d);
  Result:=temp;
end;

procedure SkipS(const pck:string; var offset : Integer);
begin
    while ((offset+1) <= Length(pck)) and ((pck[offset] <> #0) or (pck[offset+1] <> #0)) do
    begin
        Inc(offset, 2);
    end;

    Inc(offset, 2);
end;

procedure SendToClientEx(pck : AnsiString; cname : string);
var
    e : TEngine;
begin
    e := core.getEngine(cname);
    if e <> nil then e.SendToClient(pck);
end;

procedure SendToClientEx(pck : TPacket; cname : string);
var
    e : TEngine;
begin
    e := core.getEngine(cname);
    if e <> nil then e.SendToClient(pck.data);
end;

procedure SendToServerEx(pck : AnsiString; cname : string);
var
    e : TEngine;
begin
    e := core.getEngine(cname);
    if e <> nil then e.SendToServer(pck);
end;

procedure SendToServerEx(pck : TPacket; cname : string);
var
    e : TEngine;
begin
    e := core.getEngine(cname);
    if e <> nil then e.SendToServer(pck.data);
end;

{ TPacket }

procedure TPacket.Clone(p: TPacket);
begin
    data := p.data;
    index := p.index;
end;

function TPacket.ReadC: Byte;
begin
  Result:=0;
  if index>Length(data) then Exit;
  Result:=Byte(data[index]);
  Inc(index);
end;

function TPacket.ReadD: Integer;
begin
  Result:=0;
  if index+3>Length(data) then Exit;
  Move(data[index],Result,4);
  Inc(index, 4);
end;

function TPacket.ReadF: Double;
begin
  Result:=0;
  if index+7>Length(data) then Exit;
  Move(data[index],Result,8);
  Inc(index, 8);
end;

function TPacket.ReadH: word;
begin
  Result:=0;
  if index+1>Length(data) then Exit;
  Move(data[index],Result,2);
  Inc(index, 2);
end;

function TPacket.ReadQ: Int64;
begin
  Result:=0;
  if index+7>Length(data) then Exit;
  Move(data[index],Result,8);
  Inc(index, 8);
end;

function TPacket.ReadS: string;
var
  temp: WideString;
  d: Integer;
begin
    d := index;
    while ((d+1) <= Length(data)) and ((data[d] <> #0) or (data[d+1] <> #0)) do
    begin
        Inc(d, 2);
    end;

  d:=d-index;
  SetLength(temp,d div 2);
  if d>=2 then Move(data[index],temp[1],d);
  Result:=temp;
  Inc(index, d+2);
end;

function TPacket.Reset;
begin
    index := i;
    data := Copy(p, 1, Length(p));
    Result := @self;
end;

procedure TPacket.SendToClient(cname: string);
begin
    SendToClientEx(data, cname);
end;

procedure TPacket.SendToServer(cname: string);
begin
    SendToServerEx(data, cname);
end;

function TPacket.Size: Integer;
begin
    Result := Length(data);
end;

procedure TPacket.Skip(bytes_count: Integer);
begin
    Inc(index, bytes_count);
end;

procedure TPacket.SkipS;
begin
    while ((index+1) <= Length(data)) and ((data[index] <> #0) or (data[index+1] <> #0)) do
    begin
        Inc(index, 2);
    end;
    Inc(index, 2);
end;

function TPacket.Write(v: string): PPacket;
begin
    data := data+v;
    Result := @self;
end;

function TPacket.WriteC(v: byte): PPacket;
const
  dt_size = 1;
begin
  index:=Length(data)+1;
  SetLength(data,index);
  Move(v,data[index],dt_size);
    Result := @self;
end;

function TPacket.WriteD(v: Integer): PPacket;
const
  dt_size = 4;
begin
  index:=Length(data)+1;
  SetLength(data,index+dt_size-1);
  Move(v,data[index],dt_size);
    Result := @self;
end;

function TPacket.WriteF(v: Double): PPacket;
const
  dt_size = 8;
begin
  index:=Length(data)+1;
  SetLength(data,index+dt_size-1);
  Move(v,data[index],dt_size);
    Result := @self;
end;

function TPacket.WriteH(v: word): PPacket;
const
  dt_size = 2;
begin
  index:=Length(data)+1;
  SetLength(data,index+dt_size-1);
  Move(v,data[index],dt_size);
    Result := @self;
end;

function TPacket.WriteQ(v: Int64): PPacket;
const
  dt_size = 8;
begin
  index:=Length(data)+1;
  SetLength(data,index+dt_size-1);
  Move(v,data[index],dt_size);
    Result := @self;
end;

function TPacket.WriteS(v: string): PPacket;
var
  temp: WideString;
  dt_size: Word;
begin
  dt_size:=Length(v)*2+2;
  temp:=v+#0;
  index:=Length(data)+1;
  SetLength(data,index+dt_size-1);
  Move(temp[1],data[index],dt_size);
    Result := @self;
end;

{ TVec3i }

function TVec3i.DistEx(p: TVec3i): Extended;
begin
    Result := Sqrt( Sqr(X-p.X) + Sqr(Y-p.Y) + Sqr(Z-p.Z) );
end;

procedure TVec3i.fromString(s: string);
var
  a, S2: string;
  i: Integer;
  const delm = ',';
begin
  i := 0;
  S2 := S + delm;
  repeat
    try
      a := Copy(S2, 0, Pos(delm, S2) - 1);
      case i of
            0 : X := StrToInt(a);
            1 : Y := StrToInt(a);
            2 : Z := StrToInt(a);
      end;
    except
    end;
    Delete(S2, 1, Length(a + delm));
    Inc(i);
  until S2 = '';
end;

function TVec3i.Dist(p: TVec3i): Integer;
var
    sm : Integer;
begin
    sm := Round(Sqr(X-p.X) + Sqr(Y-p.Y) + Sqr(Z-p.Z));
    if sm <= 1 then begin Result := 0; Exit; end;
    Result := Round(Sqrt( sm ));
end;

procedure TVec3i.Read(var p: TPacket);
begin
    X := p.ReadD;
    Y := p.ReadD;
    Z := p.ReadD;
end;

procedure TVec3i.Reset;
begin
    X := 0;
    Y := 0;
    Z := 0;
end;

function TVec3i.toString: string;
begin
    Result := inttostr(X)+', '+inttostr(Y)+', '+inttostr(Z);
end;

{ TL2Buff }

procedure TL2Buff.Reset;
begin
    id := 0;
    level := 0;
    end_time := 0;
end;

{ TL2Skill }

function TL2Skill.isReady: Boolean;
begin
    Result := ((reuse_ready_time > 0) and (reuse_ready_time <= core.Time)) or (reuse_ready_time = 0);
end;

procedure TL2Skill.Reset;
begin
    id := 0;
    level := 0;
    is_disabled := false;
    is_passive := false;
    enchant_level := 0;
    reuse_ready_time := 0;
end;

{ TL2InvItem }

procedure TL2InvItem.Reset;
begin
    objid := 0;
    item_id := 0;
    count := 0;    
end;

{ TL2PartyMember }

procedure TL2PartyMember.Reset;
begin
    objid := 0;
    name := '';
end;

{ TPluginDll }

function TPluginDll.CallFunction(a: Integer; Params: Variant): Integer;
begin
    Result := 0;
end;

procedure TPluginDll.Finit;
begin
end;

function TPluginDll.getAppPath: string;
begin
    Result := Core.getAppPath;
end;

function TPluginDll.getLinkedCharName: string;
begin
    Result := core.getLinkedCharName(self);
end;

function TPluginDll.getmyID: Integer;
begin
    Result := myEngine.Me.ObjID;
end;

function TPluginDll.getmyPos: TVec3i;
begin
    Result := myEngine.Me.Pos;
end;

procedure TPluginDll.Init;
begin
end;

function TPluginDll.isTimerEnabled(id: Integer): Boolean;
begin
    Result := Core.isTimerEnabled(self, id);
end;

procedure TPluginDll.LogPrint(m: string);
begin
    core.LogPrint(self, m);
end;

function TPluginDll.myEngine: TEngine;
begin
    Result := Core.getEngine( Core.getLinkedCharName(Self) );
end;

procedure TPluginDll.onTimer(id: Integer);
begin
end;

procedure TPluginDll.TimerStart(id, interval: Integer);
begin
    Core.TimerStart(Self, id, interval);
end;

procedure TPluginDll.TimerStop(id: Integer);
begin
    Core.TimerStop(Self, id);
end;

{ TL2DropItem }

procedure TL2DropItem.Reset;
begin
    objid := 0;
    item_id := 0;
    pos.Reset;
    count := 0;
    player_id := 0;
end;

{ TL2Npc }

procedure TL2Npc.Reset;
begin
    objid := 0;
    pos.Reset;
    npc_type := 0;
    is_mob := false;
    is_in_combat := false;
end;

{ TL2Char }

procedure TL2Char.Reset;
begin
    objid := 0;
    name := '';
    pos.Reset;
end;

end.
