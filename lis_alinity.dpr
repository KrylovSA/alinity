program lis_alinity;

uses
  Forms,
  main in 'main.pas' {fmMain},
  sys_functions in 'sys_functions.pas',
  uDmservMain in 'uDmservMain.pas' {DmServMain: TDataModule};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfmMain, fmMain);
  Application.CreateForm(TDmServMain, DmServMain);
  Application.Run;
end.
