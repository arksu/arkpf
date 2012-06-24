unit ark_bots;

interface

uses
    SysUtils;

const
    LEADER_PLUGIN = 'parik_destr'; // плагин для описания лидера

    EE_PLUGIN_NAME = 'buff_ee';
    WC_PLUGIN_NAME = 'buff_wc';
    KOT_PLUGIN_NAME = 'buff_kot';
    TANK_PLUGIN_NAME = 'buff_tank';
    BD_PLUGIN_NAME = 'auto_bd';
    SWS_PLUGIN_NAME = 'auto_sws';
    SPOILER_PLUGIN_NAME = '';

    FUNC_BUFF_DONE = 1; // бафф закончен
//    FUNC_GET_LEADER_CHARNAME = 2; // получить имя лидера
    FUNC_REQUEST_HP = 3;
    FUNC_REQUEST_MP = 4;
    FUNC_REQUEST_RES = 5;
    FUNC_REQUEST_COV = 6; // запросить бафнуть КОВ
    FUNC_GOTO_BASE = 7; // идти на базу
    FUNC_SPOIL_FESTIVAL = 8;

function isFriend(s : string) : Boolean;

implementation

function isFriend(s : string) : Boolean;
var
    n : string;
begin
    n := Lowercase(s);
    Result := false;

    if n = 'lordblaze'              then result := true;

end;

end.
