unit sys_functions;

interface
uses SysUtils;

function SearchBuf(p:Pointer;Len:Integer;b:Byte):Integer;
function ExtractWord_(n:Integer;s:String;Chrs:TSysCharSet):String;

implementation
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

end.
