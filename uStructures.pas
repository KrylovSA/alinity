unit uStructures;

interface
uses
 Sysutils,Messages,registry,Windows;

 const
 STX=Chr($2);
 ETX=Chr($3);
 ACK=$6;
 NAK=$15;
 DEL=$7F;
 CAN=$18;
 ENQ=$5;
 EOT=$4;
 CR=$0D;
 LF=$0A;
 GS=$1D; // Vitek2
 RS=$1E; // Vitek2
 ETB= Chr($17);// End text briefly


 MSG_READ_DATA = WM_USER + 100;
 MaxBufSize= 1024;
 MSG_TIMEOUT = 10 * 1000; // 10 sec
 MaxIdleTime = 500;
 RECEARCH_FOLDER = 'ПИСК Не удалять!\RecearchData\';

 CD3700_Mode = 0;
 ARCH_Mode = 1; // режимы работы
 Rida_MODE = 2;
 // дефолтные имена файлов данных
 DEF_CD3700_DATA = 'cd3700.dat';
 DEF_ARCH_DATA = 'Arch.dat';

 // текущее состояние для Architect

Type
 TSystemPath=(Desktop,StartMenu,Programs,Startup,Personal, winroot, winsys);

// ------------- Hematology Mode -----------------
// Message Identification Segment
type
 PMesageIDSegment = ^TMesageIDSegment;
 TMesageIDSegment = packed record
 MsgType:array[1..5] of Char;
 SequenceNumber:array [1..4] of char;
 VetPackageOn:Char;
 SpecimenType:Char;
 SpecimenID:array[1..14] of Char;
 Name:array [1..18] of Char;
 OperatorID:array[1..5] of Char;
 SpecimenDate:array [1..10] of Char;
 SpecimenTime:array [1..7] of char
end;

// Results Segment of a Histogram Message
type
 PResultHistogram = ^TResultHistogram;
 TResultHistogram = packed record
 ScaleFactor:array[1..5] of Char; // всегда 00000
 ChannelData:array [1..64*3] of Char ; // каждый 4-й из 256 каналов, по 3 символа на канал (т.е. 64*3 байта)
 CheckSum:array[1..2] of Char; // сумма байтов сообщения по модулю 256
end;
// Results Segment of a Count Data Message
type
 PResultCount = ^TResultCount;
 TResultCount = packed record
 // Float поля
 WBCCount:array [1..5] of Char;
 NEUCount:array [1..5] of Char;
 LYMCount:array [1..5] of Char;
 MONOCount:array [1..5] of Char;
 EOSCount:array [1..5] of Char;
 BASOCount:array [1..5] of Char;
 RBCCount:array [1..5] of Char;
 HGBValue:array [1..5] of Char;
 HCTValue:array [1..5] of Char;
 MCVValue:array [1..5] of Char;
 MCHValue:array [1..5] of Char;
 MCHCValue:array [1..5] of Char;
 RDWValue:array [1..5] of Char;
 PLTCount:array [1..5] of Char;
 MPVValue:array [1..5] of Char;
 PCTValue:array [1..5] of Char;
 PDWValue:array [1..5] of Char;
 NEUPercentValue:array [1..5] of Char;
 LYMPercentValue:array [1..5] of Char;
 MONOPercentValue:array [1..5] of Char;
 EOSPercentValue:array [1..5] of Char;
 BASOPercentValue:array [1..5] of Char;
 // Флаги
 MovingAverageFlag:Char;
 DFLTFlag:Char;
 Blastflag:Char;
 VariantLymFlag:Char;
 DFLTFlagNeutrophilQualifier:Char;
 DFLTFlagEosinophilQualifier:Char;
 DFLTFlagLymphocyteQualifier:Char;
 IGFlag:Char;
 Bandflag:Char;
 DFLTFlagMonocyteQualifier:Char;
 DFLTFlagBasophilQualifier:Char;
 IG_BandFlag:Char;
 FWBCFlag:Char;
 WBCCountFlag:Char;
 NucleatedRBCFlag:Char;
 DLTAFlag:Char;
 NWBCFlag:Char;
 RBCMORPHFlag:Char;
 RRBCFlag:Char;
 SpareFlag_1:Char;
 PlateletRecountFlag:Char;
 SpareFlag_2:Char;
 LRIFlag:Char;
 URIFlag:Char;
 // Integer поля
 RBCCountTime:array [1..5] of Char;
 RBCUpperMeniscusTime:array [1..5] of Char;
 RBCRecountUpperTime:array [1..5] of Char;
 RBCRecountUpperMeniscusTime:array [1..5] of Char;
 WICCountTime:array [1..5] of Char;
 WICUpperMeniscusTime:array [1..5] of Char;
 SpareField_1:array [1..5] of Char;
 SpareField_2:array [1..5] of Char;
 WICWBCConcentration:array [1..5] of Char;
 WOCWBCConcentration:array [1..5] of Char;
 // Флаги принимающие несколько значений
 LimitsSet:Char;
 SampleMode:Char;
 RBCMeteringFaultFlag:Char;
 WICMeteringFaultFlag:Char;
 SamplingError_IncompleteAspirationFlag:Char;
 CheckSum:array[1..2] of Char;

end;
// Закачка work-list в анализатор
type // короткий формат
 PShortWorkList = ^TShortWorkList;
 TShortWorkList = packed record
 barcode:array[1..6] of Char;
 specimen_ID:array [1..14] of Char;
 specimen_Name:array [1..18] of Char;
 limit_set:Char;
 parameter_set:char;
 checksum:array [1..2] of char;
end;

type // длинный формат
 PLongWorkList = ^TLongWorkList;
 TLongWorkList = packed record
 barcode:array[1..6] of Char;
 specimen_ID:array [1..14] of Char;
 specimen_Name:array [1..18] of Char;
 limit_set:Char;
 parameter_set:char;
 doctor_name:array [1..24] of Char;
 date_of_birth:array [1..10] of Char;
 checksum:array [1..2] of char
end;

// структура записи для architect
type
 PArchData = ^TArchData;
 TArchData = packed record
	SeqNumber:String;
	SpecimenID:Integer;
	SpecimenName:String;
	SpecDateTime:TDateTime;
	AssayID:Integer;
	AssayName:string;
	Result:String;
  Units:String;
  PID:Integer;
end;
var Parity :array[0..4] of String = ('none','odd','even','mark','space');
var Databits :array[0..4] of String = ('4','5','6','7','8');
var StopBits :array[0..2] of String = ('1','1.5','2');

function CalcCheckSum(sMsg:String):String;
Function GetSystemPath(SystemPath:TSystemPath):string;
function ComposeStr(nFrame:Integer;s:String):String;
function GetNextFrameNo(nFrame:Integer):Integer;
function GetResponse(ans:ansichar):String;
function ConvertResponse(sData:string):String;
implementation

function CalcCheckSum(sMsg:String):String;
var
 i:Integer;
 Ostatok, Sum : integer;
begin
 sum := 0;
 for i:=1 to Length(sMsg) do
	Sum:=Sum+Byte(sMsg[i]);
 Ostatok:=Sum MOD 256;
 {
 if Ostatok = 0 then
	CRC:=0
 else
	CRC:=256-Ostatok;}
 Result := IntToHex(Ostatok, 2);
end;

Function GetSystemPath(SystemPath:TSystemPath):string;
var p:pchar;
begin
with TRegistry.Create do
try
RootKey := HKEY_CURRENT_USER;
OpenKey('\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders', True);
case SystemPath of
Desktop: Result:=ReadString('Desktop');
StartMenu:Result:=ReadString('Start Menu');
Programs:Result:=ReadString('Programs');
Startup:Result:=ReadString('Startup');
Personal:Result:=ReadString('Personal');
Winroot:begin
GetMem(p,255);
GetWindowsDirectory(p,254);
result:=Strpas(p);
Freemem(p);
end;
WinSys:begin
GetMem(p,255);
GetSystemDirectory(p,254);
result:=Strpas(p);
Freemem(p);
end;
end;
finally
CloseKey;
free;
end;
Result := IncludeTrailingPathDelimiter(Result);
end;

function ComposeStr(nFrame:Integer;s:String):String;
var
 crc:String[2];
begin
  Result :=  IntToStr(nFrame) + s + chr(CR) + ETX;
  crc := CalcCheckSum(Result);
  Result := STX + IntToStr(nFrame) + s + chr(CR) + ETX + crc + chr(CR) + Chr(LF);
end;

function GetNextFrameNo(nFrame:Integer):Integer;
begin
 Result := nFrame + 1;
 if Result > 7 then
	Result:= 0;
end;

function GetResponse(ans:AnsiChar):String;
begin
 case ans of
	Chr($2):Result:='<STX>';
	Chr($3):Result:='<ETX>';
	Chr($6):Result:='<ACK>';
	Chr($15):Result:='<NAK>';
	Chr($7F):Result:='<DEL>';
	Chr($18):Result:='<CAN>';
	Chr($5):Result:='<ENQ>';
	Chr($4):Result:='<EOT>';
	Chr($0D):Result:='<CR>';
	Chr($0A):Result:='<LF>';
	else
	 Result := '<???>';
 end;
 Result := '<-- ' + Result;
end;

function ConvertResponse(sData:string):String;
var
 s:String;
 i:Integer;
begin
Result := '';
for i := 1 to Length(sData) do
begin
 s := '';
 case sData[i] of
 	Chr($2):s:='<STX>';
	Chr($3):s:='<ETX>';
	Chr($6):s:='<ACK>';
	Chr($15):s:='<NAK>';
	Chr($7F):s:='<DEL>';
	Chr($18):s:='<CAN>';
	Chr($5):s:='<ENQ>';
	Chr($4):s:='<EOT>';
	Chr($0D):s:='<CR>';
	Chr($0A):s:='<LF>'
 end; // case
 if s <> '' then
  Result := Result + s
 else
  Result := Result + sData[i];
end; // for
end;

end.
