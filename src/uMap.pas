unit uMap;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, ExtCtrls,

  pfHeader;

type
  TfMap = class(TForm)
    img_map: TImage;
    tb_scale: TTrackBar;
    chk_active: TCheckBox;
    tm_redraw: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure chk_activeClick(Sender: TObject);
    procedure tm_redrawTimer(Sender: TObject);
    procedure tb_scaleChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormResize(Sender: TObject);
  private
    Scale : single;
    FMapActive: Boolean;

    fEngine : TEngine;
  protected
    procedure CreateParams(var Params : TCreateParams); override;
  public
    procedure RedrawObj;
    procedure DrawObj(ox, oy, t, o : Integer);
  end;

var
  fMap: TfMap;

const
  OT_MOB = 0;
  OT_MOB_AGRO = 4;
  OT_DEAD = 5;
  OT_DROP = 1;
  OT_PLAYER = 2;
  OT_OFFZONE = 3;

procedure Finit(aEngine : TEngine);
procedure Init(aEngine : TEngine);

implementation

uses
    uGlobal;

{$R *.dfm}

procedure Init(aEngine : TEngine);
begin
    fMap.fEngine := aEngine;
    fMap.tm_redraw.Enabled := true;
    fMap.chk_active.Checked := true;
    fMap.FMapActive := True;
    fMap.Show;
end;

procedure Finit(aEngine : TEngine);
begin
    if aEngine = fMap.fEngine then begin
        fMap.fEngine := nil;
        fMap.tm_redraw.Enabled := false;
        fMap.FMapActive := false;
        fMap.Hide;
    end;
end;

procedure TfMap.chk_activeClick(Sender: TObject);
begin
    if fMap.fEngine = nil then begin
        FMapActive := false;
        tm_redraw.Enabled := false;
        chk_active.Checked := false;
        exit;
    end;

    FMapActive := chk_active.Checked;
    tm_redraw.Enabled := FMapActive;
end;

procedure TfMap.CreateParams(var Params: TCreateParams);
begin
  inherited;
//  Params.ExStyle := Params.ExStyle OR WS_EX_APPWINDOW;
end;

procedure TfMap.DrawObj;
var
  s, px, py, dx, dy : Integer;
  c : tcolor;

const
  CREST_SIZE = 12;

  procedure crest;
  begin
    img_map.Canvas.Pen.Color := clRed;
    img_map.Canvas.PenPos := Point(px-CREST_SIZE, py-1);
    img_map.Canvas.LineTo(px+CREST_SIZE, py);
    img_map.Canvas.PenPos := Point(px-1, py-CREST_SIZE);
    img_map.Canvas.LineTo(px, py+CREST_SIZE);
  end;

begin
    if not FMapActive then exit;
    

    dx := img_map.Width div 2;
    dy := img_map.Height div 2;

    case t of
      OT_MOB : begin
        c := clBlue;
        s := 4;
      end;

      OT_MOB_AGRO : begin
        c := clMaroon;
        s := 4;
      end;

      OT_DEAD : begin
        c := clGray;
        s := 4;
      end;

      OT_OFFZONE : begin
        c := clSilver;
        s := 4;
      end;
          
      OT_DROP : begin
        c := clTeal;
        s := 2;
      end;

      OT_PLAYER : begin
        c := clGreen;
        s := 4;
      end;

      else begin
        c := clBlue;
        s := 4;
      end;
    end;

    px := Round( (ox - fEngine.Me.Pos.X) * SCALE) + dx;
    py := Round( (oy - fEngine.Me.Pos.Y) * SCALE) + dy;

    img_map.Canvas.Brush.Color := c;
    img_map.Canvas.FillRect( Bounds( px-(s div 2), py-(s div 2), s, s ) );

    if o = fEngine.Me.CurrentTarget then crest;
end;

procedure TfMap.FormClose(Sender: TObject; var Action: TCloseAction);
begin
    FMapActive := false;
    chk_active.Checked := false;
end;

procedure TfMap.FormCreate(Sender: TObject);
begin
    LoadControlPosition(Self);

    Scale := 40 / 230;
    FMapActive := false;
end;

procedure TfMap.FormDestroy(Sender: TObject);
begin
    SaveControlPosition(Self);
end;

procedure TfMap.FormResize(Sender: TObject);
begin
    img_map.Picture.Bitmap.Width := img_map.Width;
    img_map.Picture.Bitmap.Height := img_map.Height;
end;

procedure TfMap.RedrawObj;
var
    dx, dy, i, t : Integer;
begin
    if not FMapActive then exit;

    PatBlt(img_map.Canvas.Handle, 0, 0, img_map.Width, img_map.Height, WHITENESS);

    for i := 0 to fEngine.Mobs.Count - 1 do begin
        if Abs(fEngine.Mobs[i].pos.Z - fEngine.Me.Pos.Z) > 700 then t := OT_OFFZONE else
        if fEngine.Mobs[i].is_dead then t := OT_DEAD else
        if fEngine.Mobs[i].is_agro then t := OT_MOB_AGRO else t := OT_MOB;
        DrawObj( fEngine.Mobs[i].pos.X, fEngine.Mobs[i].pos.Y, t, fEngine.Mobs[i].objid );
    end;

    for i := 0 to fEngine.Players.Count - 1 do begin
        DrawObj( fEngine.Players[i].pos.X, fEngine.Players[i].pos.Y, OT_PLAYER, fEngine.Players[i].objid );
    end;

    for i := 0 to fEngine.Drop.Count - 1 do
        DrawObj( fEngine.Drop[i].pos.X, fEngine.Drop[i].pos.Y, OT_DROP, fEngine.Drop[i].objid );


    dx := img_map.Width div 2;
    dy := img_map.Height div 2;

    img_map.Canvas.Brush.Color := clRed;
    img_map.Canvas.FillRect( Bounds( dx-2, dy-2, 4, 4 ) );
end;

procedure TfMap.tb_scaleChange(Sender: TObject);
begin
  if not FMapActive then exit;

  Scale := tb_scale.Position / 230;

  RedrawObj;
end;

procedure TfMap.tm_redrawTimer(Sender: TObject);
begin
    if not FMapActive then Exit;
    
    if fEngine = nil then begin
        FMapActive := false;
        tm_redraw.Enabled := false;
    end;

    Caption := 'Map ['+fEngine.Me.Name+']';

    RedrawObj;
end;

end.
