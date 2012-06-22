unit plg_test;

interface

uses
    pfHeader, Variants, SysUtils;

type
    TDLLImpl = class(TPluginDll)
    public
        procedure Init; override;
        procedure ProcessPacket(var pck: AnsiString; FromServer: Boolean; ConnectName : string; Engine : TEngine); override;
        destructor Destroy; override;
        procedure onTimer(id: Integer); override;
    end;

var
    dll_impl : TDLLImpl;

    WaitPickupDrop : Boolean;

implementation

{ TDLLImpl }

destructor TDLLImpl.Destroy;
begin

  inherited;
end;

procedure TDLLImpl.Init;
var
    s : string;
begin
    s := core.getLinkedCharName(Self);
    LogPrint( 'linked char: '+ s );
    LogPrint( 'inited' );

    // timers
//    TimerStart(1, 1000);

    WaitPickupDrop := false;
end;


procedure TDLLImpl.onTimer(id: Integer);
begin
    LogPrint( 'on timer id : '+inttostr(id) );
    TimerStop(id);
end;

procedure TDLLImpl.ProcessPacket(var pck: AnsiString; FromServer: Boolean; ConnectName : string; Engine : TEngine);
var
    p : TPacket;
//    v : Variant;

begin
    if FromServer then case pck[1] of
        // get item
        #$17 : begin
            if ReadD(pck, 2) = Engine.Me.ObjID then begin
                if WaitPickupDrop then
                begin
                    WaitPickupDrop := myEngine.Drop.PickupMyNearest;
                    Engine.botSay( 'next drop: '+inttostr(Byte(WaitPickupDrop)) );
                end;
            end;
        end;

        // tutorial
        #$a6 : begin
            pck := '';
            Engine.botSay( 'tutorial dropped' );
        end;
        // play sound
        #$9e : begin
            pck := '';
            Engine.botSay( 'sound dropped' );
        end;
    end;


    if not FromServer then
        case pck[1] of
            // social action
            #$56 : begin
                // say in client chat
                p.Reset(#$4A).
                    WriteD(0).
                    WriteD(0).
                    WriteS('bot').
                    Write(#$FF#$FF#$FF#$FF).
                    WriteS('social detected : '+inttostr(ReadD(pck, 2))).
                SendToClient(ConnectName);
                

                // test call func in other plugin
//                v := Core.PluginCallFunction( 'test_call', 1, Unassigned );
//                LogPrint( 'test call: ' + v );

                //Core.getEngine('garminn').Me.UseSkill(1177, true);

                // engine party
                //if Engine.Party.Exist('garminn') then LogPrint( 'garminn in party') else LogPrint('garminn not in party');

                // advance - начинаем собирать весь свой дроп
//                if ReadD(pck, 2) = 14 then begin
//                   WaitPickupDrop := Engine.Drop.PickupMyNearest;
//                   Engine.botSay( 'pickup drop... '+inttostr(Byte(WaitPickupDrop)) );
//                end;

                // dont send to server
                pck := '';
            end;

        end;


end;

end.
