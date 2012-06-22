unit uGlobal;

interface

uses
    Windows,
    Forms,
    SysUtils,
    Classes,
    inifiles,
    Controls,
    ComCtrls,
    pfHeader,
    IdGlobal,
    Messages;

const
    WMM_OFFSET =        WM_APP;
    WM_ADD_LOG =        WMM_OFFSET + 1;
    WM_VISUAL_PACKET =  WMM_OFFSET + 2;
    WM_CALL_FUNC =      WMM_OFFSET + 3;
    WM_CLIENT_PACKET =  WMM_OFFSET + 4;
    WM_SERVER_PACKET =  WMM_OFFSET + 5;
    WM_DISCONNECT_GS =  WMM_OFFSET + 6;
    WM_CONNECT_GS =     WMM_OFFSET + 7;


type
    TProcInit = function (obj : TCore) : TPluginDLL; stdcall;
    
    TGlobalOptions = record
        GameServerLocalPort : Integer;
        GameServerHost : string;
        GameServerPort : Integer;
        L2Proto : Integer;
        FullPacketsLog : Boolean;
        PacketsLog : Boolean;
        EngineTimerInterval : Integer;
        DeleteInactiveVisual : Boolean;

        procedure Load;
        procedure Save;
    end;

    TPluginTimer = record
        // нужный интервал работы таймера
        Interval : Integer;
        // аккумулятор времени
        TimeAcc : Integer;
        // ид таймера
        Id : Integer;
    end;

    TPlugin = class
    private
        Timers : array of TPluginTimer;
    public
        FileName : string;
        // имя по которому в плагине можно вызывать события из других плагинов
        Name : string;
        Loaded: Boolean;
        hLib: Cardinal;
        onInit : TProcInit;
        DllImpl : TPluginDll;
        CharName : string;

        procedure Load;
        procedure Unload;
        procedure onTimer(dt : Integer);
        procedure AddTimer(id, interval : Integer);
        procedure DeleteTimer(id : Integer);
        function TimerExist(id : Integer) : Boolean;

        constructor Create(fname : string);
        destructor Destroy; override;
    end;

    tCallFuncStruct = packed record
        plugin_name : string;
        a : Integer;
        params : Variant;
    end;
    pCallFuncStruct = ^tCallFuncStruct;

var
    AppPath : String;
    Options : TMemIniFile;
    GlobalOptions : TGlobalOptions;
    Plugins : TList;
    GlobalDestroy : Boolean;

    PacketsNames, PacketsFromS, PacketsFromC : TStringList;
    //для Lineage II
    SysMsgIdList,  //от сель
    ItemsList, 
    NpcIdList, 
    ClassIdList, 
    AugmentList, 
    SkillList : TStringList;
    PacketsINI : TMemIniFile;
    filterS, filterC : string; //строка фильтров

procedure GlobalInit;
procedure GlobalFinit;
procedure SaveControlPosition(Control : TControl);
procedure LoadControlPosition(Control : TControl);
function HexToString(Hex : String) : String;
function StringToHex(str1, Separator : String) : String;
function WideStringToString(const ws : WideString; codePage : Word = 1251) : AnsiString;
procedure FindFiles(path:string; files:TStrings);
Function GetPacketName(var id : byte; var subid, sub2id : word; FromServer : boolean; var pname : string; var isshow : boolean) : boolean;
function GetNamePacket(s : string) : string;
function PrepareVisualPacket(p : TPacket; fromserver : Boolean) : string;
function ByteArrayToHex(str1 : array of Byte; size : Word) : String;
procedure LoadIniFiles;
procedure ListViewExchangeItems(lv: TListView; const i, j: Integer);
function StringFromBytes(const b : TIdBytes) : AnsiString;
function StringToBytes(const s : AnsiString) : TIdBytes;

const
    //коэфф преобразования NpcID, необходим для правильного определения имени НПЦ
    kNpcID = 1000000;

implementation

uses uFilterForm, uLog;

procedure GlobalInit;
begin
    GlobalDestroy := false;
    {$WARNINGS OFF}
    AppPath := IncludeTrailingBackslash(extractfilepath(paramstr(0)));
    {$WARNINGS ON}
    Options := TMemIniFile.Create(AppPath + 'settings\options.ini');
    GlobalOptions.Load;
end;

procedure GlobalFinit;
begin
    Options.UpdateFile;
    Options.Free;
    Options := nil;

    core.Free;
end;

procedure SaveControlPosition(Control : TControl);
var
    ini : Tinifile;
begin
    ini := TIniFile.Create(AppPath+'settings\windows.ini');
    ini.WriteInteger(Control.ClassName, 'top', Control.Top);
    ini.WriteInteger(Control.ClassName, 'left', Control.Left);
    ini.WriteInteger(Control.ClassName, 'width', Control.Width);
    ini.WriteInteger(Control.ClassName, 'height', Control.Height);
    ini.Destroy;
end;

procedure LoadControlPosition(Control : TControl);
var
  ini : Tinifile;
begin
  if not FileExists(AppPath+'settings\windows.ini') then exit;
  ini := TIniFile.Create(AppPath+'settings\windows.ini');
  if not ini.SectionExists(Control.ClassName) then
  begin
    ini.Destroy;
    exit;
  end;
  if(ini.ReadInteger(Control.ClassName, 'width', control.Width) -
     ini.ReadInteger(Control.ClassName, 'left', control.Left) >= screen.WorkAreaWidth)
     and
    (ini.ReadInteger(Control.ClassName, 'height', control.height) -
     ini.ReadInteger(Control.ClassName, 'top', control.Top) >= Screen.WorkAreaHeight) then
  begin
    //форма была максимизирована...
    //не загружаем
    if TForm(Control).Visible then
    begin
      ShowWindow(TForm(Control).Handle, SW_MAXIMIZE);
    end
    else
    begin
      ShowWindow(TForm(Control).Handle, SW_MAXIMIZE);
      ShowWindow(TForm(Control).Handle, SW_HIDE);
    end;
  end
  else
  begin
    control.Top := ini.ReadInteger(Control.ClassName, 'top', control.Top);
    control.Left := ini.ReadInteger(Control.ClassName, 'left', control.Left);
    control.Width := ini.ReadInteger(Control.ClassName, 'width', control.Width);
    control.height := ini.ReadInteger(Control.ClassName, 'height', control.height);
  end;
  ini.Destroy;
end;

function StringFromBytes(const b : TIdBytes) : AnsiString;
var
    i : Integer;
begin
    if Length(b) > 0 then begin
        SetLength(Result, Length(b));
        for i := 0 to Length(b) - 1 do
            Result[i+1] := Chr(b[i]);
    end else Result := '';
end;

function StringToBytes(const s : AnsiString) : TIdBytes;
var
    i : Integer;
begin
    if Length(s) > 0 then begin
        SetLength(Result, Length(s));
        for i := 0 to Length(s) - 1 do
            Result[i] := Ord(s[i+1]);
    end else SetLength(Result , 0);
end;

function SymbolEntersCount(s : string) : string;
var
  i : integer;
begin
  Result := '';
  for i := 1 to Length(s) do
  begin
    if not(s[i] in [' ', #10, #13]) then  Result := Result+s[i];
  end;
end;

//превращаем HEX строку символов в набор цифр
function HexToString(Hex : String) : String;
var
  bt : Byte;
  i : Integer;
begin
  Result := '';
  Hex := SymbolEntersCount(UpperCase(Hex));
  for i := 0 to (Length(Hex) div 2)-1 do
  begin
    bt := 0;
    if (Byte(hex[i*2+1])>$2F)and(Byte(hex[i*2+1])<$3A)then bt := Byte(hex[i*2+1])-$30;
    if (Byte(hex[i*2+1])>$40)and(Byte(hex[i*2+1])<$47)then bt := Byte(hex[i*2+1])-$37;
    if (Byte(hex[i*2+2])>$2F)and(Byte(hex[i*2+2])<$3A)then bt := bt*16+Byte(hex[i*2+2])-$30;
    if (Byte(hex[i*2+2])>$40)and(Byte(hex[i*2+2])<$47)then bt := bt*16+Byte(hex[i*2+2])-$37;
    Result := Result+char(bt);
  end;
end;

function StringToHex(str1, Separator : String) : String;
var
  i : Integer;
begin
  Result := '';
  for i := 1 to Length(str1) do begin
    Result := Result+IntToHex(Byte(str1[i]), 2)+Separator;
  end;
end;

function WideStringToString(const ws : WideString; codePage : Word) : AnsiString;
var
  l : integer;
begin
  if ws = '' then
    Result := ''
  else
  begin
    l := WideCharToMultiByte(codePage, WC_COMPOSITECHECK or WC_DISCARDNS or WC_SEPCHARS or WC_DEFAULTCHAR, @ws[1], -1, nil, 0, nil, nil);
    SetLength(Result, l - 1);
    if l > 1 then
      WideCharToMultiByte(codePage,WC_COMPOSITECHECK or WC_DISCARDNS or WC_SEPCHARS or WC_DEFAULTCHAR,
        @ws[1], -1, @Result[1], l - 1, nil, nil);
  end;
end;

procedure FindFiles(path:string; files:TStrings);
var SR:TSearchrec;
begin
  if FindFirst(path, faAnyFile, sr) = 0 then
    begin
      repeat
        if ((sr.Attr and faDirectory)<> faDirectory) and (sr.Name[1]<>'.') then
          files.Add(sr.Name)
      until FindNext(sr) <> 0;
      FindClose(sr);
    end;
end;

{ TGlobalOptions }

procedure TGlobalOptions.Load;
begin
    GameServerLocalPort     := Options.ReadInteger('main','gs_local_port', 7888);
    GameServerHost          := Options.ReadString('main', 'gs_host', '0.0.0.0');
    GameServerPort          := Options.ReadInteger('main','gs_port', 7777);
    L2Proto                 := Options.ReadInteger('main','l2_proto', 1);
    FullPacketsLog          := Options.ReadBool('main', 'full_pck_log', false);
    PacketsLog              := Options.ReadBool('main', 'pck_log', True);
    EngineTimerInterval     := Options.ReadInteger('main', 'timer_interval', 250);
    DeleteInactiveVisual    := Options.ReadBool('main', 'del_inactive', true);
end;

procedure TGlobalOptions.Save;
begin
    Options.WriteInteger(   'main', 'gs_local_port',    GameServerLocalPort);
    Options.WriteInteger(   'main', 'gs_port',          GameServerPort);
    Options.WriteString(    'main', 'gs_host',          GameServerHost);
    Options.WriteInteger(   'main', 'l2_proto',         L2Proto);
    Options.WriteBool(      'main', 'full_pck_log',     FullPacketsLog);
    Options.WriteBool(      'main', 'pck_log',          PacketsLog);
    Options.WriteInteger(   'main', 'timer_interval',   EngineTimerInterval);
    Options.WriteBool(      'main', 'del_inactive',     DeleteInactiveVisual);

    Options.UpdateFile;
end;

{ TPlugin }

procedure TPlugin.AddTimer(id, interval: Integer);
var
    i : Integer;
begin
    for i := 0 to Length(Timers) - 1 do
        if Timers[i].Id = id then
        begin
            Timers[i].TimeAcc := 0;
            Timers[i].Interval := interval;
            exit;
        end;
        
    SetLength(Timers, Length(Timers)+1);
    Timers[High(Timers)].Id := id;
    Timers[High(Timers)].Interval := interval;
    Timers[High(Timers)].TimeAcc := 0;        
end;

constructor TPlugin.Create(fname: string);
var
    p : Integer;
begin
    Timers := nil;
    FileName := fname;
    Name := ExtractFileName( FileName );
    p := Pos('.', name);
    if (p > 0) then Delete(name, p, Length(Name)-p+1);    

    Loaded := false;
    hLib := 0;
    Plugins.Add(self);
    CharName := '';
end;

procedure TPlugin.DeleteTimer(id: Integer);
var
    i, j : Integer;
begin
    for i := 0 to Length(Timers) - 1 do
        if Timers[i].Id = id then begin
            for j := i to Length(Timers) - 2 do
                Timers[j] := Timers[j+1];
            SetLength(Timers, Length(Timers)-1);
            exit;
        end;
end;

destructor TPlugin.Destroy;
var
    i : integer;
begin
    Timers := nil;

    i := 0;
    while i < Plugins.Count do
    begin
      if TPlugin(Plugins[i]) = self then
        begin
            Plugins.Delete(i);
            break;
        end;
      inc(i);
    end;

    if Loaded then begin
        DllImpl.Finit;
        FreeLibrary(hLib);
    end;
    inherited;
end;

procedure TPlugin.Load;
begin
    if Loaded then exit;

    LogPrint('Load plugin : '+Name);

    hLib := LoadLibrary(PChar(filename));
    Loaded := true;

    @onInit := GetProcAddress(hLib, 'init');
    DllImpl := onInit(Core);
    DllImpl.Init;
end;

procedure TPlugin.onTimer(dt: Integer);
var
    i : Integer;
begin
    if not Loaded then Exit;

    for i := 0 to Length(Timers) - 1 do
    begin
        Timers[i].TimeAcc := Timers[i].TimeAcc + dt;
        if Timers[i].TimeAcc >= Timers[i].Interval then begin
            Timers[i].TimeAcc := 0;
            DllImpl.onTimer( Timers[i].Id );
        end;
    end;
end;

function  TPlugin.TimerExist(id: Integer) : Boolean;
var
    i : Integer;
begin
    for i := 0 to Length(Timers) - 1 do
        if Timers[i].Id = id then begin
            Result := True;
            exit;
        end;
    Result := false;
end;

procedure TPlugin.Unload;
begin
    if not Loaded then Exit;

    LogPrint('Unload plugin : '+Name);
    DllImpl.Finit;
    FreeLibrary(hLib);
    hLib := 0;
    Loaded := false;
    DllImpl := nil;
    onInit := nil;
end;

Function GetPacketName(var id : byte; var subid, sub2id : word; FromServer : boolean; var pname : string; var isshow : boolean) : boolean;
var
  i : integer;
begin
  result := false; //во всех unknown убрал эту строчку
  isshow := true;
  //------------------------------------------------------------------------
  //расшифровываем коды пакетов и вносим неизвестные в списки пакетов
  if FromServer then
  begin
    //от сервера
//    if (GlobalProtocolVersion=AION)then // для Айон 2.1 - 2.6
//    begin
//      i := PacketsFromS.IndexOfName(IntToHex(id, 2));
//      if i=-1 then
//        pname := 'Unknown'+IntToHex(id, 2)
//      else
//      begin
//        pname := fPacketFilter.ListView1.Items.Item[i].SubItems[0];
//        isshow := fPacketFilter.ListView1.Items.Item[i].Checked;
//        result := true;
//      end;
//    end
//    else
    begin
//      if (GlobalProtocolVersion=AION27)then // для Айон 2.7
//      begin
//        //ищем сначала двухбайтное ID
//        i := PacketsFromS.IndexOfName(IntToHex(subid, 4));
//        if i=-1 then
//        begin
//          //затем однобайтное ID
//          i := PacketsFromS.IndexOfName(IntToHex(id, 2));
//          subid := 0; //сообщаем, что однобайтное ID
//          if i=-1 then
//          begin
//            //все равно не нашли, значит Unknown
//            pname := 'Unknown'+IntToHex(id, 2);
//          end
//          else
//          begin
//            pname := fPacketFilter.ListView1.Items.Item[i].SubItems[0];
//            isshow := fPacketFilter.ListView1.Items.Item[i].Checked;
//            result := true;
//          end;
//        end
//        else
//        begin
//          pname := fPacketFilter.ListView1.Items.Item[i].SubItems[0];
//          isshow := fPacketFilter.ListView1.Items.Item[i].Checked;
//          result := true;
//        end;
//      end
//      else
      begin
//        if (GlobalProtocolVersion>AION27)then // для LineageII
        begin  //server four ID packets: c(ID)h(subID)h(sub2ID)
          if (subid=$FE97) or (subid=$FE98) or (subid=$FEB7) then
          begin
            //находим индекс пакета
            i := PacketsFromS.IndexOfName(IntToHex(subid, 4)+IntToHex(sub2id, 4));
            if i=-1 then
            begin
              //неизвестный пакет от сервера
              pname := 'Unknown'+IntToHex(subid, 4)+IntToHex(sub2id, 4);
            end
            else
            begin
              pname := fPFilter.ListView1.Items.Item[i].SubItems[0];
              isshow := fPFilter.ListView1.Items.Item[i].Checked;
              result := true;
            end;
          end
          else
          begin
            if id=$FE then //server two ID packets: c(ID)h(subID)
            begin
              //находим индекс пакета
              i := PacketsFromS.IndexOfName(IntToHex(subid, 4));
              if i=-1 then
              begin
                //неизвестный пакет от сервера
                pname := 'Unknown'+IntToHex(subid, 4);
              end
              else
              begin
                pname := fPFilter.ListView1.Items.Item[i].SubItems[0];
                isshow := fPFilter.ListView1.Items.Item[i].Checked;
                result := true;
              end;
            end
            else  //server one ID packets: c(ID)
            begin
              subid := 0;
              i := PacketsFromS.IndexOfName(IntToHex(id, 2));
              if i=-1 then
                pname := 'Unknown'+IntToHex(id, 2)
              else
              begin
                pname := fPFilter.ListView1.Items.Item[i].SubItems[0];
                isshow := fPFilter.ListView1.Items.Item[i].Checked;
                result := true;
              end;
            end;
          end;
        end;
      end;
    end;
  end
  else
  begin
    //от клиента
//    if (GlobalProtocolVersion=AION)then // для Айон 2.1 - 2.6
//    begin
//      i := PacketsFromC.IndexOfName(IntToHex(id, 2));
//      if i=-1 then
//      begin
//        pname := 'Unknown'+IntToHex(id, 2);
//      end
//      else
//      begin
//        pname := fPacketFilter.ListView2.Items.Item[i].SubItems[0];
//        isshow := fPacketFilter.ListView2.Items.Item[i].Checked;
//        result := true;
//      end;
//    end
//    else
    begin
//      if (GlobalProtocolVersion=AION27)then // для Айон 2.7
//      begin
//        //ищем сначала двухбайтное ID
//        i := PacketsFromC.IndexOfName(IntToHex(subid, 4));
//        if i=-1 then
//        begin
//          //затем однобайтное ID
//          i := PacketsFromC.IndexOfName(IntToHex(id, 2));
//          subid := 0; //сообщаем, что однобайтное ID
//          if i=-1 then
//          begin
//            //все равно не нашли, значит Unknown
//            pname := 'Unknown'+IntToHex(id, 2);
//          end
//          else
//          begin
//            pname := fPacketFilter.ListView2.Items.Item[i].SubItems[0];
//            isshow := fPacketFilter.ListView2.Items.Item[i].Checked;
//            result := true;
//          end;
//        end
//        else
//        begin
//          pname := fPacketFilter.ListView2.Items.Item[i].SubItems[0];
//          isshow := fPacketFilter.ListView2.Items.Item[i].Checked;
//          result := true;
//        end;
//      end
//      else
      begin
//        if (GlobalProtocolVersion<GRACIA) then
//        begin
//          //фиксим пакет 39 для хроник C4-C5-Interlude
//          if (id in [$39, $D0]) then
//            begin
//              i := PacketsFromC.IndexOfName(IntToHex(subid, 4));
//              if i=-1 then
//                pname := 'Unknown'+IntToHex(subid, 4)
//              else
//              begin
//                pname := fPacketFilter.ListView2.Items.Item[i].SubItems[0];
//                isshow := fPacketFilter.ListView2.Items.Item[i].Checked;
//                result := true;
//              end;
//            end
//          else
//          begin
//            i := PacketsFromC.IndexOfName(IntToHex(id, 2));
//            if i=-1 then
//            begin
//              pname := 'Unknown'+IntToHex(id, 2);
//              end
//            else
//            begin
//              pname := fPacketFilter.ListView2.Items.Item[i].SubItems[0];
//              isshow := fPacketFilter.ListView2.Items.Item[i].Checked;
//              result := true;
//            end;
//          end;
//        end
//        else    // Lineage II для хроник от Gracia и выше
        begin  //client three ID packets: c(ID)h(subID)
          if (id=$D0) and (((subid>=$5100) and (subid<=$5105)) or (subid=$5A00)) then
          begin
            //находим индекс пакета
            i := PacketsFromC.IndexOfName(IntToHex(id, 2)+IntToHex(sub2id, 4));
            if i=-1 then
            begin
              //неизвестный пакет от сервера
              pname := 'Unknown'+IntToHex(id, 2)+IntToHex(sub2id, 4);
            end
            else
            begin
              pname := fPFilter.ListView2.Items.Item[i].SubItems[0];
              isshow := fPFilter.ListView2.Items.Item[i].Checked;
              result := true;
            end;
          end
          else
          begin
            if (id=$D0) then
            begin
              i := PacketsFromC.IndexOfName(IntToHex(subid, 4));
              if i=-1 then
                pname := 'Unknown'+IntToHex(subid, 4)
              else
              begin
                pname := fPFilter.ListView2.Items.Item[i].SubItems[0];
                isshow := fPFilter.ListView2.Items.Item[i].Checked;
                result := true;
              end;
            end
            else
            begin
              subid := 0;
              i := PacketsFromC.IndexOfName(IntToHex(id, 2));
              if i=-1 then
                pname := 'Unknown'+IntToHex(id, 2)
              else
              begin
                pname := fPFilter.ListView2.Items.Item[i].SubItems[0];
                isshow := fPFilter.ListView2.Items.Item[i].Checked;
                result := true;
              end;
            end;
          end;
        end;
      end;
    end;
  end;
end;

function GetNamePacket(s : string) : string;
var
  ik : Word;
begin
  // ищем конец имени пакета
  ik := Pos(':', s);
  if ik=0 then
    Result:=s
  else
    Result := copy(s, 1, ik-1);
end;

function ByteArrayToHex(str1 : array of Byte; size : Word) : String;
var
  buf : String;
  i : Integer;
begin
  buf := '';
  for i := 0 to size-1 do
  begin
    buf := buf+IntToHex(str1[i], 2);
  end;
  Result := buf;
end;


function PrepareVisualPacket(p : TPacket; fromserver : Boolean) : string;
var
  TimeStep : TDateTime;
  TimeStepB: array [0..7] of Byte;
  apendix : string;
  arr : array[0..$FFFF] of byte;
  len : array[0..1] of byte;
  sz : word;
begin
    Result := '';
  if p.Size = 0 then exit;
  //на серве - апендикс 04, на клиент = 03
  if FromServer then
    apendix := '03'
  else
    apendix := '04';

  TimeStep := now;
  Move(TimeStep,TimeStepB,8);

  Move(p.data[1], arr[0], p.Size);

  sz := p.Size+2;
  Move(sz, len, 2);

  Result :=
           Apendix +
           ByteArrayToHex(TimeStepB,8) +
           ByteArrayToHex(len,2) +
           ByteArrayToHex(arr, p.Size);

end;

procedure ListViewExchangeItems(lv: TListView; const i, j: Integer);
var
  tempLI: TListItem;
  bi, bj : Boolean;
begin
  lv.Items.BeginUpdate;
  try
    bi := lv.Items.Item[i].Checked;
    bj := lv.Items.Item[j].Checked;
    tempLI := TListItem.Create(lv.Items);
    tempLI.Assign(lv.Items.Item[i]);

    lv.Items.Item[i].Assign(lv.Items.Item[j]);
    lv.Items.Item[i].Checked := bj;

    lv.Items.Item[j].Assign(tempLI);
    lv.Items.Item[j].Checked := bi;
    tempLI.Free;
  finally
    lv.Items.EndUpdate
  end;
end;

procedure LoadIniFiles;
begin
    // для Lineage II
    SysMsgIdList.Clear;
    AugmentList.Clear;
    SkillList.Clear;
    ClassIdList.Clear;
    NpcIdList.Clear;
    ItemsList.Clear;

    SysMsgIdList.LoadFromFile(AppPath+'settings\en\sysmsgid.ini');
    ItemsList.LoadFromFile(AppPath+'settings\en\itemsid.ini');
    NpcIdList.LoadFromFile(AppPath+'settings\en\npcsid.ini');
    ClassIdList.LoadFromFile(AppPath+'settings\en\classid.ini');
    SkillList.LoadFromFile(AppPath+'settings\en\skillsid.ini');
    AugmentList.LoadFromFile(AppPath+'settings\en\augmentsid.ini');
end;


end.
