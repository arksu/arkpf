object fOptions: TfOptions
  Left = 0
  Top = 0
  Caption = 'Options'
  ClientHeight = 327
  ClientWidth = 497
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object btnCancel: TButton
    Left = 406
    Top = 285
    Width = 75
    Height = 25
    Caption = 'Cancel'
    TabOrder = 0
    OnClick = btnCancelClick
  end
  object btnOk: TButton
    Left = 313
    Top = 285
    Width = 75
    Height = 25
    Caption = 'OK'
    TabOrder = 1
    OnClick = btnOkClick
  end
  object PageControl1: TPageControl
    Left = 8
    Top = 8
    Width = 473
    Height = 257
    ActivePage = TabNetwork
    TabOrder = 2
    object TabNetwork: TTabSheet
      Caption = 'Network'
      object boxGameServer: TGroupBox
        Left = 8
        Top = 8
        Width = 241
        Height = 169
        Caption = 'Game Server'
        TabOrder = 0
        object Label1: TLabel
          Left = 8
          Top = 71
          Width = 22
          Height = 13
          Caption = 'Host'
        end
        object Label2: TLabel
          Left = 8
          Top = 117
          Width = 20
          Height = 13
          Caption = 'Port'
        end
        object lbl1: TLabel
          Left = 8
          Top = 24
          Width = 47
          Height = 13
          Caption = 'Local port'
        end
        object btn_GS_Start: TButton
          Left = 143
          Top = 41
          Width = 75
          Height = 25
          Caption = 'Start'
          TabOrder = 0
        end
        object ed_GS_host: TEdit
          Left = 8
          Top = 90
          Width = 121
          Height = 21
          TabOrder = 1
          Text = '195.58.1.100'
        end
        object ed_gs_local_port: TJvSpinEdit
          Left = 8
          Top = 43
          Width = 121
          Height = 21
          MaxValue = 65535.000000000000000000
          Value = 7888.000000000000000000
          TabOrder = 2
        end
        object ed_GS_port: TJvSpinEdit
          Left = 8
          Top = 136
          Width = 121
          Height = 21
          Value = 7777.000000000000000000
          TabOrder = 3
        end
      end
      object RadioGroup1: TRadioGroup
        Left = 255
        Top = 8
        Width = 185
        Height = 49
        Caption = 'Protocol'
        ItemIndex = 0
        Items.Strings = (
          'Lineage II')
        TabOrder = 1
      end
      object rgL2Proto: TRadioGroup
        Left = 255
        Top = 63
        Width = 185
        Height = 114
        Caption = 'Lineage II proto'
        ItemIndex = 1
        Items.Strings = (
          'Freya'
          'High Five'
          'GoD')
        TabOrder = 2
      end
    end
    object TabMisc: TTabSheet
      Caption = 'Misc'
      ImageIndex = 1
      object Label3: TLabel
        Left = 3
        Top = 56
        Width = 89
        Height = 13
        AutoSize = False
        Caption = 'Timer interval (ms)'
      end
      object chk_Full_packet_log: TCheckBox
        Left = 3
        Top = 3
        Width = 97
        Height = 17
        Caption = 'Full packets log'
        TabOrder = 0
      end
      object chk_Packets_log: TCheckBox
        Left = 3
        Top = 26
        Width = 97
        Height = 17
        Caption = 'Packets log'
        TabOrder = 1
      end
      object edTimerInterval: TJvSpinEdit
        Left = 3
        Top = 75
        Width = 121
        Height = 21
        TabOrder = 2
      end
      object chk_DelInactive: TCheckBox
        Left = 168
        Top = 3
        Width = 177
        Height = 17
        Caption = 'Delete inactive visual packets'
        TabOrder = 3
      end
    end
  end
end
