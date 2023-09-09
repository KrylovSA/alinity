object dmMain: TdmMain
  OldCreateOrder = False
  Height = 113
  Width = 160
  object msSaveData: TMSSQL
    Connection = no_moss
    CommandTimeout = 0
    Left = 64
    Top = 24
  end
  object no_moss: TMSConnection
    Database = 'no_moss'
    Options.PersistSecurityInfo = True
    Options.Provider = prSQL
    Username = 'dev'
    Password = 'cooldev2011'
    Server = 'sql'
    Connected = True
    LoginPrompt = False
    Left = 24
    Top = 24
  end
end
