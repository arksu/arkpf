object fPFilter: TfPFilter
  Left = 364
  Top = 258
  BorderStyle = bsSizeToolWin
  Caption = #1060#1080#1083#1100#1090#1088' '#1087#1072#1082#1077#1090#1086#1074
  ClientHeight = 458
  ClientWidth = 326
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object PageControl2: TPageControl
    Left = 0
    Top = 0
    Width = 326
    Height = 407
    ActivePage = TabSheet1
    Align = alClient
    TabOrder = 0
    object TabSheet1: TTabSheet
      Caption = #1054#1090' '#1089#1077#1088#1074#1077#1088#1072
      object ListView1: TJvListView
        Left = 0
        Top = 0
        Width = 318
        Height = 379
        Align = alClient
        Checkboxes = True
        Columns = <
          item
            Caption = 'Id'
            Width = 80
          end
          item
            AutoSize = True
            Caption = 'Name'
          end>
        GridLines = True
        ReadOnly = True
        RowSelect = True
        TabOrder = 0
        ViewStyle = vsReport
        ColumnsOrder = '0=80,1=234'
        Groups = <>
        ExtendedColumns = <
          item
          end
          item
          end>
      end
    end
    object TabSheet7: TTabSheet
      Caption = #1054#1090' '#1082#1083#1080#1077#1085#1090#1072
      ImageIndex = 1
      object ListView2: TJvListView
        Left = 0
        Top = 0
        Width = 318
        Height = 379
        Align = alClient
        Checkboxes = True
        Columns = <
          item
            Caption = 'Id'
            Width = 80
          end
          item
            Caption = 'Name'
            Width = 260
          end>
        GridLines = True
        ReadOnly = True
        RowSelect = True
        TabOrder = 0
        ViewStyle = vsReport
        ColumnsOrder = '0=80,1=260'
        Groups = <>
        ExtendedColumns = <
          item
          end
          item
          end>
      end
    end
  end
  object Panel17: TPanel
    Left = 0
    Top = 407
    Width = 326
    Height = 51
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object Button1: TButton
      Left = 8
      Top = 27
      Width = 150
      Height = 19
      Caption = #1042#1099#1076#1077#1083#1080#1090#1100' '#1074#1089#1105
      TabOrder = 0
      OnClick = Button1Click
    end
    object Button13: TButton
      Left = 160
      Top = 27
      Width = 150
      Height = 19
      Caption = #1048#1085#1074#1077#1088#1090#1080#1088#1086#1074#1072#1090#1100
      TabOrder = 1
      OnClick = Button13Click
    end
    object UpdateBtn: TButton
      Left = 8
      Top = 5
      Width = 302
      Height = 19
      Caption = #1055#1088#1080#1084#1077#1085#1080#1090#1100
      TabOrder = 2
      OnClick = UpdateBtnClick
    end
  end
end
