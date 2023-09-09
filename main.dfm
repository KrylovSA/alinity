object fmMain: TfmMain
  Left = 0
  Top = 0
  Caption = #1051#1048#1057' fdoctor.ru (alinity)'
  ClientHeight = 153
  ClientWidth = 605
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Memo1: TMemo
    Left = 0
    Top = 0
    Width = 605
    Height = 125
    Align = alClient
    Lines.Strings = (
      'Memo1')
    TabOrder = 0
    Visible = False
  end
  object sb: TdxStatusBar
    Left = 0
    Top = 125
    Width = 605
    Height = 28
    Panels = <
      item
        PanelStyleClassName = 'TdxStatusBarTextPanelStyle'
        Width = 300
      end
      item
        PanelStyleClassName = 'TdxStatusBarTextPanelStyle'
        PanelStyle.Color = clSilver
        Width = 200
      end>
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
  end
end
