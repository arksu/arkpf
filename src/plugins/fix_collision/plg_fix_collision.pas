unit plg_fix_collision;

interface

uses
    pfHeader, SysUtils;

type
    TPluginImpl = class(TPluginDll)
    public
        procedure ProcessPacket(var pck: AnsiString; FromServer: Boolean; ConnectName : string; Engine : TEngine); override;
    end;

var
    plugin_impl : TPluginImpl;

implementation

{ TPluginImpl }

procedure TPluginImpl.ProcessPacket(var pck: AnsiString; FromServer: Boolean;
  ConnectName: string; Engine: TEngine);
var
     p : TPacket;
     ps : AnsiString;
begin
    (*
      todo: хранить все npc info при переключении режима высылать по новой
      при этом в пакетах ставить координаты из движка
    *)
    if FromServer then case pck[1] of
        // npc info
        #$0c : begin
            // collsision fix
            if (ReadD(pck, 10) = 1) and (pck[127] = #$00) and (pck[128] = #$00) then begin
                ps := pck;
                ps[90] := #$00;
                ps[91] := #$00;
                ps[92] := #$00;
                ps[93] := #$00;
                ps[94] := #$00;
                ps[95] := #$00;
                ps[96] := #$00;
                ps[97] := #$00;
                pck := '';
                SendToClientEx(ps, ConnectName);
            end;
        end;

        // user info
        #$32 : begin
            // collsision fix
            ps := pck;
            p.Reset(ps, 22);
            p.skipS;
            p.skip(504);
            ps[p.index] := #$00;
            ps[p.index+1] := #$00;
            ps[p.index+2] := #$00;
            ps[p.index+3] := #$00;
            ps[p.index+4] := #$00;
            ps[p.index+5] := #$00;
            ps[p.index+6] := #$00;
            ps[p.index+7] := #$00;
            pck := '';
            SendToClientEx(ps, ConnectName);
        end;
    end;
end;

end.
