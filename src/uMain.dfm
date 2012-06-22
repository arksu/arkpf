object fMain: TfMain
  Left = 1247
  Top = 671
  Caption = 'ark port forwarder'
  ClientHeight = 413
  ClientWidth = 551
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Menu = MainMenu1
  OldCreateOrder = False
  Position = poDesigned
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object pcClientsConnection: TJvPageControl
    Left = 0
    Top = 0
    Width = 551
    Height = 413
    Align = alClient
    TabOrder = 0
    Visible = False
    OnChange = pcClientsConnectionChange
    ClientBorderWidth = 1
  end
  object XPManifest1: TXPManifest
    Left = 336
    Top = 56
  end
  object MainMenu1: TMainMenu
    Left = 272
    Top = 56
    object Main1: TMenuItem
      Caption = 'File'
      object nDisconnectAll: TMenuItem
        Caption = 'Disconnect all'
        ShortCut = 16452
        OnClick = nDisconnectAllClick
      end
      object nOptions: TMenuItem
        Caption = 'Options'
        ShortCut = 16463
        OnClick = nOptionsClick
      end
      object nReload: TMenuItem
        Caption = 'Reload *.ini files'
        ShortCut = 16466
        OnClick = nReloadClick
      end
      object nExit: TMenuItem
        Caption = 'Exit'
        OnClick = nExitClick
      end
    end
    object nView: TMenuItem
      Caption = 'View'
      object nPlugins: TMenuItem
        Caption = 'Plugins'
        ShortCut = 16464
        OnClick = nPluginsClick
      end
      object nLog: TMenuItem
        Caption = 'Log'
        ShortCut = 16455
        OnClick = nLogClick
      end
      object nFilter: TMenuItem
        Caption = 'Filter'
        ShortCut = 16454
        OnClick = nFilterClick
      end
      object nLogpackets: TMenuItem
        Caption = 'Visual packets'
        ShortCut = 16470
        OnClick = nLogpacketsClick
      end
    end
  end
  object ActionList1: TActionList
    Left = 304
    Top = 56
  end
  object timerUnused: TTimer
    Enabled = False
    Interval = 333
    OnTimer = timerUnusedTimer
    Left = 272
    Top = 168
  end
  object EngineTimer: TTimer
    Interval = 250
    OnTimer = EngineTimerTimer
    Left = 112
    Top = 184
  end
end
