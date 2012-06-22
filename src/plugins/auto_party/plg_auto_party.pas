unit plg_auto_party;

interface

uses
    pfHeader, SysUtils;

type
    TPluginImpl = class(TPluginDll)
    public
        procedure Init; override;
        procedure ProcessPacket(var pck: AnsiString; FromServer: Boolean; ConnectName : string; Engine : TEngine); override;
        destructor Destroy; override;
    end;

var
    plugin_impl : TPluginImpl;

implementation

function isFriend(s : string) : Boolean;
var
    n : string;
begin
    n := Lowercase(s);
    Result := false;

    if n = 'sambo'              then result := true;
    if n = 'veera'              then result := true;
    if n = 'm00r'               then result := true;
    if n = '29a'                then result := true;
    if n = 'beautyhorror'       then result := true;
    if n = 'zariche'            then result := true;
    if n = 'wamah'              then result := true;
    if n = 'murbella'           then result := true;
    if n = 'zaken'              then result := true;
    if n = 'tor'                then result := true;
    if n = 'bok'                then result := true;


    if n = 'hoop'               then result := true;
    if n = 'silverman'          then result := true;
    if n = 'makoffka'           then result := true;
    if n = 'viskanderv'         then result := true;

    if n = 'german2006'         then result := true;
    if n = 'indomitable'        then result := true;

    if n = 'adskiysrakozerg'    then result := true;
    if n = 'godward'            then result := true;
    if n = 'qtek'               then result := true;
    if n = 'orcwaman'           then result := true;
    if n = 'makoffka'           then result := true;
    if n = 'discodancer'        then result := true;
    if n = 'pa3tep3atop'        then result := true;
    if n = 'ssman'              then result := true;

end;

{ TPluginImpl }

destructor TPluginImpl.Destroy;
begin

  inherited;
end;

procedure TPluginImpl.Init;
begin
  inherited;

end;

procedure TPluginImpl.ProcessPacket(var pck: AnsiString; FromServer: Boolean;
  ConnectName: string; Engine: TEngine);
var
    s : string;
    p : TPacket;
begin
    if FromServer then
        case pck[1] of
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
end;

end.
