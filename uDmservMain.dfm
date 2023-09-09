object DmServMain: TDmServMain
  OldCreateOrder = False
  OnCreate = DataModuleCreate
  OnDestroy = DataModuleDestroy
  Height = 223
  Width = 343
  object no_moss: TMSConnection
    Database = 'no_moss'
    Options.PersistSecurityInfo = True
    Options.Provider = prSQL
    Username = 'dev'
    Password = 'cooldev2011'
    Server = 'sql'
    LoginPrompt = False
    Left = 16
    Top = 24
  end
  object Server: TServerSocket
    Active = False
    Port = 5555
    ServerType = stNonBlocking
    OnListen = ServerListen
    OnClientConnect = ServerClientConnect
    OnClientDisconnect = ServerClientDisconnect
    OnClientRead = ServerClientRead
    Left = 64
    Top = 24
  end
  object IdHTTPServer: TIdHTTPServer
    Bindings = <>
    OnCommandGet = IdHTTPServerCommandGet
    Left = 72
    Top = 88
  end
  object tmSaveData: TTimer
    OnTimer = tmSaveDataTimer
    Left = 112
    Top = 24
  end
  object qPatFIO: TMSQuery
    Connection = no_moss
    SQL.Strings = (
      'declare @pid int'
      'select @pid = dbo.fn_GetPID_Barcode(:BarCode) '
      ''
      'select '
      ' @pid [pid],'
      ' no_moss.[dbo].[fnTransliterator](p.FIO_short) [fio_short]'
      'from _moss_patients p (nolock)'
      'where pid = @pid')
    Left = 16
    Top = 88
    ParamData = <
      item
        DataType = ftWideString
        Name = 'BarCode'
        ParamType = ptInput
      end>
    object qPatFIOfio_short: TStringField
      FieldName = 'fio_short'
      ReadOnly = True
      Size = 150
    end
    object qPatFIOpid: TIntegerField
      FieldName = 'pid'
      ReadOnly = True
    end
  end
  object msSaveData: TMSSQL
    Connection = no_moss
    SQL.Strings = (
      'declare @js_data nvarchar(max) = :js_data'
      ''
      'insert into no_moss.dbo._moss_lab_Arch_data('
      '  [SpecimenID] ,'
      '  [SpecimenName] ,'
      '  [SpecDateTime] ,'
      '  [AssayID] ,'
      '  [AssayName] ,'
      '  [Result] ,'
      '  [id_analyser] ,'
      '  [Units] ,'
      '  [PID]'
      '  )'
      ' select'
      '  t.[SpecimenID] ,'
      '  pats.FIO_Short,'
      '  t.[SpecDateTime] ,'
      '  t.[AssayID] ,'
      '  t.[AssayName] ,'
      '  t.[Result] ,'
      '  t.[id_analyser] ,'
      '  t.[Units] ,'
      '  t.[PID]'
      ' from openjson(@js_data) '
      ' with( '
      '  [SpecimenID] int '#39'$.SpecimenID'#39','
      '  [SpecDateTime] datetime '#39'$.SpecDateTime'#39','
      '  [AssayID] int '#39'$.AssayID'#39','
      '  [AssayName] varchar(50) '#39'$.AssayName'#39','
      '  [Result] varchar(100) '#39'$.Result'#39','
      '  [id_analyser] int '#39'$.id_analyser'#39','
      '  [Units] varchar(15) '#39'$.Units'#39','
      '  [PID] int '#39'$.PID'#39
      '  ) t'
      
        '  join no_moss.dbo._moss_patients pats (nolock) on pats.pid = t.' +
        'pid')
    CommandTimeout = 0
    Left = 128
    Top = 96
    ParamData = <
      item
        DataType = ftWideString
        Name = 'js_data'
        ParamType = ptInput
      end>
  end
  object qWorkListOrders: TMSQuery
    Connection = no_moss
    SQL.Strings = (
      'select'
      #9'l.id,'
      #9'l.barcode,'
      #9'dbo.fnTransliterator(p.LastName) [pat_fio],'
      #9'l.pid,'
      #9'l.StrCode,'
      #9'l.IntCode'
      'from lr_worklist l'
      'join _moss_patients p on p.pid = l.pid'
      'where l.id_analyser = :id_analyser'
      #9#9'and l.status_id = 0'
      'order by l.dt_create desc')
    BeforeOpen = qWorkListOrdersBeforeOpen
    Left = 16
    Top = 144
    ParamData = <
      item
        DataType = ftInteger
        Name = 'id_analyser'
        ParamType = ptInput
        Value = 20
      end>
    object qWorkListOrderspid: TIntegerField
      FieldName = 'pid'
    end
    object qWorkListOrdersStrCode: TStringField
      FieldName = 'StrCode'
      Size = 50
    end
    object qWorkListOrdersIntCode: TIntegerField
      FieldName = 'IntCode'
    end
    object qWorkListOrdersid: TIntegerField
      AutoGenerateValue = arAutoInc
      FieldName = 'id'
      ReadOnly = True
    end
    object qWorkListOrderspat_fio: TStringField
      FieldName = 'pat_fio'
      ReadOnly = True
      Size = 150
    end
    object qWorkListOrdersbarcode: TStringField
      FieldName = 'barcode'
      Size = 50
    end
  end
  object tmWorkList: TTimer
    Enabled = False
    OnTimer = tmWorkListTimer
    Left = 160
    Top = 24
  end
  object msSetOrderStatus: TMSSQL
    Connection = no_moss
    SQL.Strings = (
      'declare @ids varchar(max) = :ids'
      'update l set'
      ' status_id = 1,'
      ' dt_status = getdate()'
      'from lr_worklist l'
      
        'where l.id in (select cast([Value] as int) [id] from string_spli' +
        't(@ids,'#39','#39'))')
    CommandTimeout = 0
    Left = 128
    Top = 144
    ParamData = <
      item
        DataType = ftWideString
        Name = 'ids'
        ParamType = ptInput
      end>
  end
end
