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

end.
