unit uDmservMain;

interface

uses
  SysUtils, Classes, DB, DBAccess, MSAccess, Forms, Stdctrls,
  Windows, IniFiles, IdSocketHandle, IdBaseComponent, IdComponent,
  IdCustomTCPServer, IdCustomHTTPServer,IdGlobal,IdContext,
  IdHTTPServer, ScktComp, HotLog, ExtCtrls, DateUtils, MemDS;

const HEADER = 'H|\^&||||||||||||%s';
const PAT_INFO = 'P|1|%d|||%s||||||||||||||||||||||||||||';
const WORKPLACE = 'M|1|O|0|%s|||%d|0|%s|0||0|||';
const TERM = 'L|1|N';
const ANS_WAIT_TMOUT = 5;
const json_data_line_tmpl = '{"SpecimenID":%d,"SpecDateTime":"%s","AssayID":%d,"AssayName":"%s","Result":"%s","id_analyser":%d,"Units":"%s","PID":%d}';
const ID_ANALYSER = 20;
const
     ArchHeader= 'H|\^&||||||||||P|1';
     // Patient Information Record
     // 1- Sequence number (1-65535)
     // 2 - Practice assigned Patient ID (string[20])
     // 3 - Laboratory assigned Patient ID (string[20])
     // 2 - Patient ID (string[20])
     // 4 - Patient name (last (20), first (20), middle (12))
     ArchPatientInfo = 'P|%d|%s|%s|%s|%s^%s^%s|||U';
     // Test order record
     // 1- Sequence number (1-65535)
     // 2 - Specimen ID string[20]
     // 3 - ID исследований(^^^601\^^^2000 итд)
     ArchTestOrderInfo = 'O|%d|%s^P%s^%d||%s|R||||||N||||||||||||||O';
     // Message Termination Record
     ArchTermRecord = 'L|1';
     // ожидание ответа анализатора
     // AnswerTimeout=1000;

type
  TDmServMain = class(TDataModule)
    no_moss: TMSConnection;
    Server: TServerSocket;
    IdHTTPServer: TIdHTTPServer;
    tmSaveData: TTimer;
    qPatFIO: TMSQuery;
    qPatFIOfio_short: TStringField;
    qPatFIOpid: TIntegerField;
    msSaveData: TMSSQL;
    qWorkListOrders: TMSQuery;
    qWorkListOrderspid: TIntegerField;
    qWorkListOrdersStrCode: TStringField;
    qWorkListOrdersIntCode: TIntegerField;
    tmWorkList: TTimer;
    qWorkListOrdersid: TIntegerField;
    qWorkListOrderspat_fio: TStringField;
    msSetOrderStatus: TMSSQL;
    qWorkListOrdersbarcode: TStringField;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure ServerClientConnect(Sender: TObject;
      Socket: TCustomWinSocket);
    procedure ServerClientDisconnect(Sender: TObject;
      Socket: TCustomWinSocket);
    procedure tmSaveDataTimer(Sender: TObject);
    procedure ServerListen(Sender: TObject; Socket: TCustomWinSocket);
    procedure ServerClientRead(Sender: TObject; Socket: TCustomWinSocket);
    procedure IdHTTPServerCommandGet(AContext: TIdContext;
      ARequestInfo: TIdHTTPRequestInfo;
      AResponseInfo: TIdHTTPResponseInfo);
    procedure tmWorkListTimer(Sender: TObject);
    procedure qWorkListOrdersBeforeOpen(DataSet: TDataSet);
  private
    { Private declarations }
    Memo1:TStringList;//TMemo;
    sDebugBuffer:String;
    TotalReceivedBytes :Cardinal;
    bEOT,bProcessingData:Boolean;
    LAstModif:TDateTime;
    bHostConnected:Boolean;
    FSocket: TCustomWinSocket;
    bAnswer:AnsiChar;
    DebugMode:Boolean;

    procedure ReadSettings;
    function InitDB: Boolean;
    procedure LogWrite(s: String);
    procedure Memo1Change(Sender: TObject);
    procedure ProcessData(sl_raw_data:TStringList);
    procedure SendWorkListAlinity;
  public
    { Public declarations }
  end;

function _getcurrentdir:String ;
function SearchBuf(p:Pointer;Len:Integer;b:Byte):Integer;
//function ExtractWord_(n:Integer;s:String;Chrs:TSysCharSet):String;

var
  DmServMain: TDmServMain;

implementation
uses uUtils, uStructures;
{$R *.dfm}

function _getcurrentdir:String ;
var
   p:array [0..255] of Char;
   lpFileName:PChar;
   nSize:DWORD;
begin
 lpFileName := @p[0];
 nSize  := 255;
 Result := '';
 if GetModuleFileName(0,lpFileName,nSize ) > 0 then
	result := String(ExtractFilePath(lpFileName));

end;


procedure TDmServMain.DataModuleCreate(Sender: TObject);
begin
    // инициализация лог-файла
   hLog.hlWriter.hlFileDef.path :=  _getcurrentdir;
   hLog.hlWriter.hlFileDef.gdgMax := 10;
   hLog.hlWriter.hlFileDef.UseFileSizeLimit := True;
   hLog.hlWriter.hlFileDef.LogFileMaxSize := TenMegabyte;
   hLog.SetErrorCaption('****** Error ******','*',True);
   hLog.SetErrorViewStyle(vsExtended);
   hLog.StartLogging;
   hLog.Add(hLog.header);

   Memo1 := TStringList.Create; // TMemo.Create(Self);

   DebugMode := False;
   Self.ReadSettings;

   if Self.InitDB then
    hLog.Add(DatetimeToStr(now) + ': соединение с базой установлено.');

   Server.Active := True;
   hLog.Add('ЛИС активен, порт ' + IntToStr(Server.Port));
   FSocket := nil;

   IdHTTPServer.Active := True;
   hLog.Add('HealthCheck активен, порт ' + IntToStr(IdHTTPServer.Bindings.DefaultPort));

   Memo1.OnChange := Self.Memo1Change;
   Self.LastModif := now;

end;

procedure TDmServMain.DataModuleDestroy(Sender: TObject);
begin
 if Server.Active then
  Server.Active := False;
 if idHTTPServer.Active then
  idHTTPServer.Active := False;
 if no_moss.Connected then
  no_moss.Close;
 if Assigned(Memo1) then
  Memo1.Free;

 hLog.Add('Программа завершила работу.');
 Hlog.Add(hLog.footer);
end;

procedure TDmServMain.ReadSettings;
 var
  f_settings:TIniFile;
  f_name:String;
  f_port:Integer;
  f_bind:TIdSocketHandle;
begin
  f_name :=  _getcurrentdir; //ExtractFilePath(Application.ExeName);
  f_name := IncludeTrailingPathDelimiter(f_name) + 'alinity.ini';
  f_settings := TIniFile.Create(f_name);
  f_port := f_settings.ReadInteger('Main','Port',5555);
  Server.port := f_port;

  f_port := f_settings.ReadInteger('Main','HealthPort',8080);
  IdHTTPServer.Bindings.Clear;
  IdHTTPServer.Bindings.DefaultPort := f_port;
  f_bind := IdHTTPServer.Bindings.Add;
  f_bind.SetBinding('0.0.0.0', f_port, idGlobal.Id_IPv4);
end;

procedure TDmServMain.SendWorkListAlinity;
var
 sLine:String;
 sPatient_Id:string;//[12]
 sPatientName:String;//[16];
 sAssay:string;
 AssayID:Integer;
// nTry:Integer;
 nFrame:Integer;
// AssayIni:TIniFile;
 Rack:String;
 nProbe:Integer; // контейнер и пробирка
 nSent:Integer;
 sIDs:String;
begin

 if not Assigned(Self.FSocket) then
   Exit;

 try
	Rack := '090';
        nProbe := 1;
        nSent := 0;
        sIDs := '';
        qWorkListOrders.First;
	while not qWorkListOrders.Eof do
	begin
	 sPatient_Id := qWorkListOrderspid.AsString;
	 sPatientName := qWorkListOrderspat_fio.AsString;
         sAssay := qWorkListOrdersStrCode.AsString;
         AssayID := qWorkListOrdersintCode.AsInteger;
	 // <ENQ>
         nFrame := 1;
	 Self.FSocket.SendText(Chr(ENQ));
	 LogWrite(DateTimeToStr(now) + ':' + '--> ENQ');
         sleep(100);
//         ans := ReadCharTmOut(vaComm,AnswerTimeout);
//	 WriteLn(Log,DateTimeToStr(now) + ':' + GetResponse(ans));
//	 if ans=#0 then
//		raise Exception.Create('Ошибка связи с анализатором !');
	 // Header
	 sLine := composeStr(nFrame,ArchHeader);
	 LogWrite(DateTimeToStr(now) + ':' + '--> ' + sLine);
	 Self.FSocket.SendText(AnsiString(sLine));
         sleep(100);
//         ans := ReadCharTmOut(vaComm,AnswerTimeout);
//	 LogWrite(DateTimeToStr(now) + ':' + GetResponse(ans));
//	 if ans=#0 then
//		raise Exception.Create('Ошибка связи с анализатором !');
	 Inc(nFrame);
	 //nFrame := GetNextFrameNo(nFrame);
	 // Patient Info
	 sline := Format(ArchPatientInfo,[1,sPatient_Id,sPatient_Id,sPatient_Id,sPatientName,'','']);
	 sLine := ComposeStr(nFrame,sLine);
	 LogWrite(DateTimeToStr(now) + ':' + '--> ' + sLine);
	 Self.FSocket.SendText(AnsiString(sLine));
         sleep(100);
//	 ans := ReadCharTmOut(vaComm,AnswerTimeout);
//	 LogWrite(DateTimeToStr(now) + ':' + GetResponse(ans));
//	 if ans=#0 then
//		raise Exception.Create('Ошибка связи с анализатором !');
	 Inc(nFrame);
	 // Формируем строку с параметрами исследования
         sLine := Format('^^^%d^%s',[AssayID,sAssay]);
	 sLine := Format(ArchTestOrderInfo,[1,sPatient_Id,Rack,nProbe,sLine]);
	 sLine:= Composestr(nFrame,sLine);
	 LogWrite(DateTimeToStr(now) + ':' + '--> ' + sLine);
	 self.FSocket.SendText(AnsiString(sLine));
         sleep(100);
//    ans := ReadCharTmOut(vaComm,AnswerTimeout);
//	LogWrite(DateTimeToStr(now) + ':' + GetResponse(ans));
//	if ans=#0 then
//	 raise Exception.Create('Ошибка связи с анализатором !');
	Inc(nFrame);
	sLine := Composestr(nFrame,ArchTermRecord);
	LogWrite(DateTimeToStr(now) + ':' + '--> ' + sLine);
        Self.FSocket.SendText(AnsiString(sLine));
        sleep(100);
   //ans := ReadCharTmOut(vaComm,AnswerTimeout);
//	LogWrite(DateTimeToStr(now) + ':' + GetResponse(ans));
//	 if ans=#0 then
//		raise Exception.Create('Ошибка связи с анализатором !');
	 Self.FSocket.SendText(Chr(EOT));
	 LogWrite(DateTimeToStr(now) + ':' + '--> <EOT>');

         sIDs := sIDs + qWorkListOrdersid.AsString + ',';

	 Inc(nSent);
         qWorkListOrders.Next;
	 // пишем в таблицу результатов
	 // определяем положение пробирки (контейнер+место)
	 Inc(nProbe);
	 if nProbe > 5 then
	 begin
		nProbe := 1;
		Rack := IntToStr(StrToInt(Rack) + 1);
		if Length(Rack) < 3 then
		 Rack :='0' + Rack;
	 end;
	end;  // while not qWorkListOrders.EOF do

        // обновляем статусы заказов (отправлено на прибор)
        if Length(sIDs) > 0 then
         Delete(sIDs,LEngth(sIDs),1);
        msSetOrderStatus.ParamByName('ids').AsString := sIDs;
        msSetOrderStatus.Execute();

        LogWrite(Format('Отправка заказов завершена, отправлено записей: %d',[nSent]));
        except
         On E:Exception do
	        LogWrite(Format('Ошибка: <%s>',[E.Message]));
        end;
end;


procedure TDmServMain.ServerClientConnect(Sender: TObject;
  Socket: TCustomWinSocket);
var
 sHost:String;
begin
 if Socket.RemoteHost <> '' then
  sHost := Socket.RemoteHost
 else
  sHost := Socket.RemoteAddress;
 LogWrite(Format('%s:%d соединение установлено',[sHost,socket.RemotePort]));
 bHostConnected := True;
 Self.FSocket := Socket;

 tmWorkList.Enabled := True;
end;

procedure TDmServMain.ServerClientDisconnect(Sender: TObject;
  Socket: TCustomWinSocket);
begin
 LogWrite('Соединение с клиентом потеряно...');
 bHostConnected := False;
 FSocket := nil;
 tmWorkList.Enabled := False;
end;


procedure TDmServMain.ServerClientRead(Sender: TObject;
  Socket: TCustomWinSocket);
var
 sIN:AnsiString;
 Buffer:PAnsiChar;
 nEnd:Integer;
begin
 sIn :=  Socket.ReceiveText;
 LastModif := now;
 Memo1.text := Memo1.text + String(sIn);
 sDebugBuffer := sDebugBuffer + sIn;
 nEnd := Pos(#13#10,sDebugBuffer);
 if (nEnd > 0)  then
 begin
   hLog.Add('<--' + ConvertResponse(Copy(sDebugBuffer,1,nEnd+1)));
   Delete(sDebugBuffer, 1, nEnd + 1);
 end;

 Buffer := PAnsiChar(sIn);
 if SearchBuf(Buffer,Length(sIn),ENQ) >= 0 then
 begin
  if not bProcessingData then
  begin
   socket.SendText(Chr(ACK));
   LogWrite(Chr(ACK));
  end
  else
  begin
   socket.SendText(Chr(NAK)); // не готовы принимать, идет обработка
   LogWrite(Chr(NAK));
  end;
 end;

 if SearchBuf(Buffer,Length(sIN),Ord(ETX)) >= 0 then
 begin
   socket.SendText(Chr(ACK));
   LogWrite(Chr(ACK));
 end;
 // флаг наличия конца передачи
 if SearchBuf(Buffer,Length(sIN),EOT) >= 0 then
 begin
  bEOT := True;
  LogWrite(Chr(ENQ));
  socket.SendText(Chr(ENQ));
  TotalReceivedBytes := TotalReceivedBytes + Cardinal(Length(sIN));
 end;

 if SearchBuf(Buffer,Length(sIN),ACK) >= 0 then
 begin
  bAnswer := AnsiChar(ACK);
  LogWrite(Chr(ACK));
 end;

 if SearchBuf(Buffer,Length(sIN),NAK) >= 0 then
 begin
  bAnswer := AnsiChar(NAK);
  LogWrite(Chr(NAK));
 end;

end;


procedure TDmServMain.ServerListen(Sender: TObject;
  Socket: TCustomWinSocket);
begin
 hLog.Add(DateTimeToStr(now) + Format(': %s:%d порт открыт...',[Socket.LocalAddress,Socket.LocalPort]));
end;

procedure TDmServMain.tmSaveDataTimer(Sender: TObject);
begin
 if bHostConnected and (SecondsBetween(now,LastModif) >= 1) then
 begin
  tmSaveData.OnTimer := nil;
  try
   if memo1.count > 0 then
   begin
    ProcessData(memo1);
    memo1.Clear;
   end;
  finally
   tmSaveData.OnTimer := tmSaveDataTimer;
  end;
 end;

end;

procedure TDmServMain.tmWorkListTimer(Sender: TObject);
begin

 if bProcessingData then
  Exit;

 tmWorkList.OnTimer := nil;

 try

 if qWorkListOrders.Active then
  qWorkListOrders.Close;
 qWorkListOrders.Open;

 if qWorkListOrders.RecordCount > 0 then
  Self.SendWorkListAlinity;

 finally
  tmWorkList.OnTimer := tmWorkListTimer;
 end;
end;

procedure TDmServMain.Memo1Change(Sender: TObject);
begin
 LastModif := now;
end;

procedure TDmServMain.ProcessData(sl_raw_data:TStringList);
var
 sData:String;
 s:String;
 pid:Integer;
 sResult:String;
 sAssayID:Integer;
 sAssayName:String;
 sSpecDateTime:String;
 iLine:Integer;
 i,n:Integer;
 nRec:Integer;
 str_js_data:String;
 sUnits:String;
 StartPos:Integer;

begin
 if not Self.InitDB then
  Exit;

 bProcessingData := True;
 iLine := 0;
 nRec := 0;
 pid := 0;
 str_js_data := '';

 try
 try

 while iLine < sl_raw_data.count do
 begin
 sData := sl_raw_data[iLine];
 // чистим от служебных символов
 startPos := Pos(STX,sData);
// EndPos := Pos(Chr(CR),sData);

 if (StartPos > 0) {and (EndPos > 0)} then
   sData := Copy(sData,StartPos+ 2,Length(sData) - startPos - 2)
 else
 begin
  inc(iLine);
  Continue;
 end;

 if Length(sData) = 0 then
 begin
  inc(iLine);
  Continue;
 end;

 // завершение передачи
 if sData[1] = 'L' then
 begin
	PID := 0;
 end;
 // Данные пациента
 if sData[1] = 'O' then
 begin
	s := ExtractWord(3,sData,['|']);
	PID :=	StrToIntDef(Trim(s),0);
 end; // if sData[1] = 'O' then
 // Результат
 if sData[1] = 'R' then
 begin
	s := ExtractWord(3,sData,['|']);
	// Выясняем тип результата
	if (s[Length(s)] = 'F') and (PID <> 0) then
	begin
	 sAssayID := StrToInt(ExtractWord(1,s,['^']));
	 sAssayName := ExtractWord(2,s,['^']);
	 sResult := ExtractWord(4,sData,['|']);
         sUnits := ExtractWord(5,sData,['|']);
	 // Дата/Время (отсчитываем от начала строки 12 '|')
	 i := 1;
         n := 0;
	 while (n < 12) and (i <= Length(sData)) do
	 begin
		if sdata[i] = '|' then
		 Inc(n);
		Inc(i);
	 end;
	 if n < 12 then
		Exit;
	 s := Copy(sdata,i,14);//ExtractWord(10,sData,['|']);
	 sSpecDateTime := Format('%s%s%s %s:%s:%s',[Copy(s,1,4),Copy(s,5,2),Copy(s,7,2),
                          Copy(s,9,2),Copy(s,11,2),Copy(s,13,2)]);
	 // проверяем наличие такой же записи и сохраняем
         if str_js_data <> '' then
          str_js_data := str_js_data + ',' + Format(json_data_line_tmpl,[pid,sSpecDateTime,sAssayID,sAssayName,
                                                    sResult,ID_ANALYSER,sUnits,pid])
         else
          str_js_data := Format(json_data_line_tmpl,[pid,sSpecDateTime,sAssayID,sAssayName,
                                                    sResult,ID_ANALYSER,sUnits,pid]);

         inc(nRec);
	end;
  end; // if sData[1] = 'R' then
  inc(iLine);
 end; //  while iLine < sl_raw_data.count do

 except
	on E:Exception do
	begin
          LogWrite('=======================================');
          LogWrite(sData);
          LogWrite(E.Message);
          LogWrite('=======================================');
        end;
 end;

   msSaveData.ParamByName('js_data').AsString := '[' + str_js_data + ']';
   try
    msSaveData.Execute;
    LogWrite(DateTimeToStr(now) +  ':Обработка закончена, найдено ' + IntToStr(nRec) + ' записей.');
   except
    on E:Exception do
    begin
     LogWrite(DateTimeToStr(now) + ':Ошибка при обработке:' + e.message);
    end;
   end;

 finally
   bProcessingData := False;
 end;
end;

procedure TDmServMain.qWorkListOrdersBeforeOpen(DataSet: TDataSet);
begin
 qWorkListOrders.ParamByName('id_analyser').AsInteger := ID_ANALYSER;
end;

procedure TDmServMain.IdHTTPServerCommandGet(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
begin
  AResponseInfo.ContentType := 'text/html; charset=windows-1251';
  AResponseInfo.ContentText := '<HTML><Body>OK</Body></HTML>';
  hLog.Add(DateTimeToStr(Now) + ': HealthCheck OK');
end;

function TDmServMain.InitDB:Boolean;
begin
 result := False;
try
 if not no_moss.Connected then
  no_moss.Connect;

 no_moss.ExecSQL('select getdate()',[]);
 Result := True;
except
 on E:Exception do
 begin
  LogWrite(DateTimeToStr(now) + ':Ошибка базы:' + E.Message);
  no_moss.close;
 end;
end;
end;

procedure TDmServMain.LogWrite(s:String);
begin
 if Assigned(hLog) {and FDeBugmode} then
 begin
  if sDebugBuffer <> '' then
  begin
    hLog.Add('<--' + ConvertResponse(sDebugBuffer));
    sDebugBuffer := '';
  end;
  hLog.Add('-->' + ConvertResponse(s));
 end;
end;


function ExtractWord_(n:Integer;s:String;Chrs:TSysCharSet):String;
var
 n1,n2:Integer;
begin
 Result := '';
 n1 := 1;
 if n > 1 then
 begin
  while (n > 0) do
  begin
   if n1 > Length(s) then
    Exit;
   if CharInSet(s[n1],chrs) then
    Dec(n);
   Inc(n1);
  end;
  n2 := n1 ;
 end
 else
  n2 := 1;

 while (n2 <= Length(s)) do
 begin
  if CharInSet(s[n2],chrs) then
   Break;
  result := Result + s[n2];
  Inc(n2);
 end;

end;

// ищем в буфере p символ b
function SearchBuf(p:Pointer;Len:Integer;b:Byte):Integer;
var
 i:Integer;
begin
 Result:= -1;
 for i:=0 to Len - 1 do
 begin
	if Byte(Pointer(Cardinal(p) + i)^) = b then
	begin
	 Result := i;
	 Break;
	end;
 end;
end;


end.
