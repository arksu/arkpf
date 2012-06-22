object fPlugins: TfPlugins
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  Caption = 'Plugins'
  ClientHeight = 389
  ClientWidth = 613
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 408
    Top = 0
    Width = 4
    Height = 389
    Align = alRight
    ResizeStyle = rsUpdate
    ExplicitLeft = 445
  end
  object pnlPlugins: TPanel
    Left = 0
    Top = 0
    Width = 408
    Height = 389
    Align = alClient
    TabOrder = 0
    object lvPlugins: TListView
      Left = 1
      Top = 1
      Width = 406
      Height = 387
      Align = alClient
      Checkboxes = True
      Columns = <
        item
          AutoSize = True
          Caption = 'Name'
        end
        item
          Caption = 'Charname'
          Width = 150
        end>
      ColumnClick = False
      GridLines = True
      HideSelection = False
      ReadOnly = True
      RowSelect = True
      TabOrder = 0
      ViewStyle = vsReport
      OnChange = lvPluginsChange
      OnClick = lvPluginsClick
    end
  end
  object pnlEdit: TPanel
    Left = 412
    Top = 0
    Width = 201
    Height = 389
    Align = alRight
    TabOrder = 1
    object Label1: TLabel
      Left = 6
      Top = 88
      Width = 52
      Height = 13
      Caption = 'Char name'
    end
    object edCharname: TEdit
      Left = 6
      Top = 107
      Width = 121
      Height = 21
      Hint = #1048#1084#1103' '#1095#1072#1088#1072'. '#1077#1089#1083#1080' '#1087#1091#1089#1090#1086' '#1090#1086' '#1076#1083#1103' '#1074#1089#1077#1093' '#1082#1086#1085#1085#1077#1082#1090#1086#1074
      TabOrder = 0
    end
    object btnRefresh: TButton
      Left = 6
      Top = 8
      Width = 75
      Height = 25
      Caption = 'Refresh list'
      TabOrder = 1
      OnClick = btnRefreshClick
    end
    object btnUp: TButton
      Left = 87
      Top = 8
      Width = 42
      Height = 25
      Caption = 'Up'
      TabOrder = 2
      OnClick = btnUpClick
    end
    object btnDown: TButton
      Left = 135
      Top = 8
      Width = 42
      Height = 25
      Caption = 'Down'
      TabOrder = 3
      OnClick = btnDownClick
    end
    object btnSet: TButton
      Left = 133
      Top = 105
      Width = 52
      Height = 25
      Caption = 'Set'
      TabOrder = 4
      OnClick = btnSetClick
    end
    object btnSaveOrder: TButton
      Left = 6
      Top = 39
      Width = 171
      Height = 25
      Caption = 'Save order'
      TabOrder = 5
      OnClick = btnSaveOrderClick
    end
  end
end
