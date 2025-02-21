object frmOSSServerMonitorMain: TfrmOSSServerMonitorMain
  Left = 0
  Top = 0
  ActiveControl = btnConnectDisconnect
  Caption = 'OOS Server Monitor'
  ClientHeight = 323
  ClientWidth = 804
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnActivate = FormActivate
  OnClose = FormClose
  OnCloseQuery = FormCloseQuery
  OnDestroy = FormDestroy
  TextHeight = 15
  object pgcMain: TPageControl
    Left = 0
    Top = 57
    Width = 804
    Height = 247
    ActivePage = TabSheet1
    Align = alClient
    TabOrder = 0
    object TabSheet1: TTabSheet
      Caption = 'OSS'
      ImageIndex = 3
      object lvOSS: TListView
        Left = 0
        Top = 0
        Width = 796
        Height = 217
        Align = alClient
        Columns = <
          item
            Caption = 'Index'
            Width = -1
            WidthType = (
              -1)
          end
          item
            Caption = 'Client'
            Width = -1
            WidthType = (
              -1)
          end
          item
            Caption = 'UserName'
            Width = -1
            WidthType = (
              -1)
          end
          item
            Caption = 'LoginName'
            Width = -1
            WidthType = (
              -1)
          end
          item
            Caption = 'ClientId'
            Width = -1
            WidthType = (
              -1)
          end>
        HideSelection = False
        ReadOnly = True
        RowSelect = True
        TabOrder = 0
        ViewStyle = vsReport
      end
    end
    object tabLog: TTabSheet
      Caption = 'Log'
      ImageIndex = 2
      object lvLog: TListView
        Left = 0
        Top = 0
        Width = 796
        Height = 217
        Align = alClient
        Columns = <
          item
            Caption = 'Time'
            Width = 80
          end
          item
            Caption = 'Application'
            Width = 180
          end
          item
            Caption = 'User'
            Width = 100
          end
          item
            Caption = 'MessageType'
            Width = 100
          end
          item
            Caption = 'Size'
            Width = 80
          end
          item
            AutoSize = True
            Caption = 'Data'
          end>
        ReadOnly = True
        RowSelect = True
        TabOrder = 0
        ViewStyle = vsReport
      end
    end
  end
  object statusBottom: TStatusBar
    Left = 0
    Top = 304
    Width = 804
    Height = 19
    Panels = <
      item
        Text = 'Oss'
        Width = 75
      end
      item
        Text = 'Events'
        Width = 78
      end
      item
        Text = 'Max size'
        Width = 60
      end>
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 804
    Height = 57
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 2
    object Label1: TLabel
      Left = 16
      Top = 16
      Width = 137
      Height = 23
      AutoSize = False
      Caption = 'Host (IP / DNS-Name)'
      Layout = tlCenter
    end
    object Label2: TLabel
      Left = 432
      Top = 16
      Width = 33
      Height = 23
      AutoSize = False
      Caption = 'Port'
      Layout = tlCenter
    end
    object btnConnectDisconnect: TButton
      Left = 576
      Top = 16
      Width = 75
      Height = 25
      Action = actConnect
      TabOrder = 0
    end
    object edHost: TEdit
      Left = 160
      Top = 16
      Width = 234
      Height = 23
      TabOrder = 1
      Text = '127.0.0.1'
    end
    object edPort: TEdit
      Left = 472
      Top = 18
      Width = 69
      Height = 23
      TabOrder = 2
      Text = '5090'
    end
  end
  object ActionList1: TActionList
    Left = 488
    Top = 160
    object actConnect: TAction
      Caption = 'Verbinden'
      OnExecute = actConnectExecute
      OnUpdate = actConnectUpdate
    end
  end
end
