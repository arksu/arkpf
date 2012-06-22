unit l2_utils;

interface

function get_shot_iconname(grade : Char) : string;
function RndPoint(sz : Integer) : Integer;

implementation

function get_shot_iconname(grade : Char) : string;
begin
    case grade of
        's' : result := 'etc_spirit_bullet_gold_i00';
        'a' : result := 'etc_spirit_bullet_silver_i00';
        'b' : result := 'etc_spirit_bullet_red_i00';
        'c' : result := 'etc_spirit_bullet_green_i00';
        'd' : result := 'etc_spirit_bullet_blue_i00';
    end;
end;

function RndPoint(sz : Integer) : Integer;
begin
    Result := Random(sz) - (sz div 2);
end;

end.
