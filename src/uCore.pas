unit uCore;

interface

uses
    Windows, SysUtils,
    pfHeader, uConnect, uL2GS_Connect;

type
    TL2PFCoreImpl = class(TCore)
    protected
        function getTime : Cardinal; override;
    public
        function isConnectionExist(charname: string): Boolean; override;
        function getEngine(CharName: string): TEngine; override;
        function getLinkedCharName(dll: TPluginDll): string; override;
        function getLinkedCharName(dll_name: string): string; override;
        procedure LogPrint(p : TPluginDll; m : string); override;
        function PluginCallFunction(plugin_name: string; a: Integer; Params: Variant): Integer; override;
        function getAppPath: string; override;
        procedure TimerStart(dll: TPluginDll; id: Integer; interval: Integer); override;
        procedure TimerStop(dll: TPluginDll; id: Integer); override;
        function isTimerEnabled(dll: TPluginDll; id: Integer): Boolean; override;
    end;


implementation

uses
    uMain, uPlugins, uGlobal, uLog;

{ TL2PFCoreImpl }

function TL2PFCoreImpl.getAppPath: string;
begin
    Result := AppPath;
end;

function TL2PFCoreImpl.getEngine(CharName: string): TEngine;
var
    c : TL2GS_Connect;
begin
    for c in Connections do
        if c.getCharName = CharName then
        begin
          Result := c.getEngine;
          Exit;
        end;
    Result := nil;
end;

function TL2PFCoreImpl.getLinkedCharName(dll_name: string): string;
var
    i : Integer;
begin
    for i := 0 to Plugins.Count - 1 do
        if {(TPlugin(Plugins[i]).Loaded) and }(LowerCase(TPlugin(Plugins[i]).Name) = LowerCase(dll_name)) then
        begin
            Result := TPlugin(Plugins[i]).CharName;
            exit;
        end;

    Result := '';
end;

function TL2PFCoreImpl.getLinkedCharName(dll: TPluginDll): string;
var
    i : Integer;
begin
    for i := 0 to Plugins.Count - 1 do
        if TPlugin(Plugins[i]).DllImpl = dll then
        begin
            Result := TPlugin(Plugins[i]).CharName;
            exit;
        end;

    Result := '';
end;

function TL2PFCoreImpl.getTime: Cardinal;
begin
    Result := GetTickCount;
end;

function TL2PFCoreImpl.isConnectionExist(charname: string): Boolean;
var
    c : TL2GS_Connect;
begin
    if charname = '' then begin
        Result := False;
        exit;
    end;
    
    for c in Connections do
        if LowerCase( c.getCharName ) = LowerCase( charname ) then begin
            Result := True;
            exit;
        end;

    Result := false;
end;

function TL2PFCoreImpl.isTimerEnabled(dll: TPluginDll; id: Integer): Boolean;
var
    i : Integer;
begin
    for i := 0 to Plugins.Count-1 do
        if TPlugin(Plugins[i]).DllImpl = dll then begin
            Result := TPlugin(Plugins[i]).TimerExist(id);
            Exit;
        end;
    Result := False;
end;

procedure TL2PFCoreImpl.LogPrint(p : TPluginDll; m: string);
var
    i : Integer;
begin
    for i := 0 to Plugins.Count-1 do
        if TPlugin(Plugins[i]).DllImpl = p then begin
            uLog.LogPrint('<'+TPlugin(Plugins[i]).Name+'> : ' + m);
            exit;
        end;

    uLog.LogPrint('Warning! unknown plugin say : ' + m);
end;

function TL2PFCoreImpl.PluginCallFunction(plugin_name: string; a: Integer;
  Params: Variant): Integer;
var
    struct : tCallFuncStruct;
begin
//    uLog.LogPrint('call func <'+plugin_name+'> a='+inttostr(a)+' params='+Params);

    struct.plugin_name := plugin_name;
    struct.a := a;
    struct.params := Params;
    Result := uMain.PluginCallFunc( struct );
end;

procedure TL2PFCoreImpl.TimerStart(dll: TPluginDll; id, interval: Integer);
var
    i : Integer;
begin
    for i := 0 to Plugins.Count - 1 do
        if (TPlugin(Plugins[i]).DllImpl = dll) then TPlugin(Plugins[i]).AddTimer(id, interval);
end;

procedure TL2PFCoreImpl.TimerStop(dll: TPluginDll; id: Integer);
var
    i : Integer;
begin
    for i := 0 to Plugins.Count - 1 do
        if (TPlugin(Plugins[i]).DllImpl = dll) then TPlugin(Plugins[i]).DeleteTimer(id);
end;

end.
