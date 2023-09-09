unit uUtils;

interface

uses SysUtils, Controls, Dialogs;

function GetTranslit(sText: string): string;

const
  NL = #13#10;
  NLS = #10; // Мягкий разделитель (Unix-like).

// Выделяем из строки S слово с порядковым номером N.
// Разделитель слов - WordDelims.
function ExtractWord(N: Integer; const S: string;
  const WordDelims: TSysCharSet): string;
// Узнаем позицию слова с порядковым номером N в строке S.
// Разделитель слов - WordDelims.
function WordPosition(const N: Integer; const S: string;
  const WordDelims: TSysCharSet): Integer;

function MakeStr(C: Char; N: Integer): string;
function AddChar(C: Char; const S: string; N: Integer): string;
{ AddChar return a string left-padded to length N with characters C. }

function Confirm(AText: String): Boolean;
function ToCorrectFileName(const AFileName: String): String;

implementation

function GetTranslit(sText: string): string;
var
  aChar:array [char] of string;

  function GetChar(c: char): string;
  begin
    Result := '';
    if (c = 'Ь') or (c = 'Ъ') then Exit;
    Result := c;
    if not CharInSet(c, ['A'..'Z', '0'..'9', '.']) then
      Result := aChar[c];
  end;

  function ToEnglish(ast: string): string;
  var i: integer;
      st: string;
  begin
    i := 1; Result := '';
    while i <= Length(ast) do
    begin
      if i < Length(ast) then
      begin
        st := ast[i] + ast[i+1];
        if (st = 'КС') then begin Result := Result+'X'; i := i + 2; Continue; end;
        if (st = 'ЬЯ') or (st = 'ИЯ') then begin Result := Result + 'IA'; i := i + 2; Continue; end;
        if (st = 'ИЙ') then begin Result := Result + 'Y'; i := i + 2; Continue; end;
        if (st = 'ЫЙ') then begin Result := Result + 'YY'; i := i + 2; Continue; end;
      end;
      Result := Result + GetChar(ast[i]);
      Inc(i);
    end;
  end;
begin
  sText := Trim(AnsiUpperCase(sText));
  aChar['А'] := 'A';
  aChar['Б'] := 'B';
  aChar['В'] := 'V';
  aChar['Г'] := 'G';
  aChar['Д'] := 'D';
  aChar['Е'] := 'E';
  aChar['Ё'] := 'E';
  aChar['Ж'] := 'ZH';
  aChar['З'] := 'Z';
  aChar['И'] := 'I';
  aChar['Й'] := 'Y';
  aChar['К'] := 'K';
  aChar['Л'] := 'L';
  aChar['М'] := 'M';
  aChar['Н'] := 'N';
  aChar['О'] := 'O';
  aChar['П'] := 'P';
  aChar['Р'] := 'R';
  aChar['С'] := 'S';
  aChar['Т'] := 'T';
  aChar['У'] := 'U';
  aChar['Ф'] := 'F';
  aChar['Х'] := 'KH';
  aChar['Ц'] := 'TS';
  aChar['Ч'] := 'CH';
  aChar['Ш'] := 'SH';
  aChar['Щ'] := 'SHCH';
  aChar['Ъ'] := '';
  aChar['Ы'] := 'Y';
  aChar['Ь'] := '';
  aChar['Э'] := 'E';
  aChar['Ю'] := 'YU';
  aChar['Я'] := 'YA';

  Result := ToEnglish(sText)
end;



function WordPosition(const N: Integer; const S: string;
  const WordDelims: TSysCharSet): Integer;
var
  Count, i: Integer;
begin
  Count := 0;
  i := 1;
  Result := 0;
  while (i <= Length(S)) and (Count <> N) do
  begin
    while (i <= Length(S)) and (CharInSet(S[i], WordDelims)) do
      Inc(i);
    if (i <= Length(S)) then
      Inc(Count);
    if (Count <> N) then
      while (i <= Length(S)) and not (CharInSet(S[i], WordDelims)) do
        Inc(i)
    else
      Result := i;
  end;
end;

function ExtractWord(N: Integer; const S: string;
  const WordDelims: TSysCharSet): string;
var
  i: Integer;
  Len: Integer;
begin
  Len := 0;
  i := WordPosition(N, S, WordDelims);
  if (i <> 0) then
    while (i <= Length(S)) and not(CharInSet(S[i], WordDelims)) do
    begin
      Inc(Len);
      SetLength(Result, Len);
      Result[Len] := S[i];
      Inc(i);
    end;
  SetLength(Result, Len);
end;

function AddChar(C: Char; const S: string; N: Integer): string;
begin
  if Length(S) < N then
    Result := MakeStr(C, N - Length(S)) + S
  else Result := S;
end;

function MakeStr(C: Char; N: Integer): string;
begin
  if N < 1 then Result := ''
  else begin
{$IFNDEF WIN32}
    if N > 255 then N := 255;
{$ENDIF WIN32}
    SetLength(Result, N);
    FillChar(Result[1], Length(Result), C);
  end;
end;

function Confirm(AText: String): Boolean;
begin
  Result:= (MessageDlg(AText, mtConfirmation, [mbYes, mbCancel], 0) = mrYes);
end;

function ToCorrectFileName(const AFileName: String): String;
var
  st: String;
begin
  st := AFileName;
  st := StringReplace(st, '\', '-', [rfReplaceAll, rfIgnoreCase]);
  st := StringReplace(st, '/', '-', [rfReplaceAll, rfIgnoreCase]);
  st := StringReplace(st, ':', '-', [rfReplaceAll, rfIgnoreCase]);
  st := StringReplace(st, '*', '-', [rfReplaceAll, rfIgnoreCase]);
  st := StringReplace(st, '.', '-', [rfReplaceAll, rfIgnoreCase]);
  st := StringReplace(st, '?', '-', [rfReplaceAll, rfIgnoreCase]);
  st := StringReplace(st, '"', '-', [rfReplaceAll, rfIgnoreCase]);
  st := StringReplace(st, '<', '-', [rfReplaceAll, rfIgnoreCase]);
  st := StringReplace(st, '>', '-', [rfReplaceAll, rfIgnoreCase]);
  st := StringReplace(st, '|', '-', [rfReplaceAll, rfIgnoreCase]);
  st := StringReplace(st, #9, '-', [rfReplaceAll, rfIgnoreCase]);
  st := StringReplace(st, #8, '-', [rfReplaceAll, rfIgnoreCase]);
  st := StringReplace(st, #10, '-', [rfReplaceAll, rfIgnoreCase]);
  st := StringReplace(st, #13, '-', [rfReplaceAll, rfIgnoreCase]);
  Result := st;
end;



end.
