object fMap: TfMap
  Left = 0
  Top = 0
  Caption = 'fMap'
  ClientHeight = 479
  ClientWidth = 705
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnResize = FormResize
  PixelsPerInch = 96
  TextHeight = 13
  object img_map: TImage
    Left = 0
    Top = 0
    Width = 705
    Height = 479
    Align = alClient
    ExplicitLeft = -264
    ExplicitTop = -396
    ExplicitWidth = 899
    ExplicitHeight = 733
  end
  object tb_scale: TTrackBar
    Left = 8
    Top = 0
    Width = 25
    Height = 321
    Max = 100
    Orientation = trVertical
    Position = 40
    TabOrder = 0
    OnChange = tb_scaleChange
  end
  object chk_active: TCheckBox
    Left = 39
    Top = 8
    Width = 97
    Height = 17
    Caption = 'Active'
    TabOrder = 1
    OnClick = chk_activeClick
  end
  object tm_redraw: TTimer
    Enabled = False
    Interval = 333
    OnTimer = tm_redrawTimer
    Left = 104
    Top = 120
  end
end
