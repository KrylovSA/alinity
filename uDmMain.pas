unit uDmMain;

interface

uses
  SysUtils, Classes, DB, DBAccess, MSAccess;

type
  TdmMain = class(TDataModule)
    msSaveData: TMSSQL;
    no_moss: TMSConnection;
  private
    { Private declarations }
  public
    { Public declarations }
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


var
  dmMain: TdmMain;

implementation

{$R *.dfm}

end.
