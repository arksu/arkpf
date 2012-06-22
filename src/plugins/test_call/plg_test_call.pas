unit plg_test_call;

interface

uses
    pfHeader;

type
    TPluginImpl = class(TPluginDll)
    public
        procedure Init; override;
        procedure ProcessPacket(var pck: AnsiString; FromServer: Boolean; ConnectName : string; Engine : TEngine); override;
        destructor Destroy; override;
        function CallFunction(a: Integer; Params: Variant): Integer; override;
    end;

var
    plugin_impl : TPluginImpl;

implementation

{ TDLLImpl }

function TPluginImpl.CallFunction(a: Integer; Params: Variant): Integer;
begin
    if a = 1 then Result := 1 else Result := 0;
end;

destructor TPluginImpl.Destroy;
begin
  inherited;
end;

procedure TPluginImpl.Init;
begin
end;


procedure TPluginImpl.ProcessPacket(var pck: AnsiString; FromServer: Boolean; ConnectName : string; Engine : TEngine);
begin
end;

end.
