unit main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ScktComp,   dxStatusBar, uStructures,
  DB,MSAccess,HotLog,DateUtils,ExtCtrls, cxGraphics, cxControls,
  cxLookAndFeels, cxLookAndFeelPainters, dxSkinsCore,
  dxSkinOffice2010Black, dxSkinOffice2010Blue, dxSkinOffice2010Silver,
  dxSkinsdxStatusBarPainter, DBAccess, MemDS;





type
  TfmMain = class(TForm)
    Memo1: TMemo;
    sb: TdxStatusBar;
    procedure FormShow(Sender: TObject);
  private
    sDebugBuffer:String;
    sLine:String;
    TotalReceivedBytes :Cardinal;
    bEOT,bProcessingData:Boolean;
    LAstModif:TDateTime;
    bHostConnected:Boolean;
    procedure LogWrite(s: String);
    { Private declarations }
  public
    { Public declarations }
  end;


var
  fmMain: TfmMain;

implementation

{$R *.dfm}

procedure TfmMain.FormShow(Sender: TObject);
begin
   memo1.Lines.Clear;
   bHostConnected:=False;
end;

procedure TfmMain.LogWrite(s:String);
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


end.
