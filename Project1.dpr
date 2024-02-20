program Project1;

uses
  FastMM5,
  Vcl.Forms,
  Unit1 in 'Unit1.pas' {MainForm},
  FAT32Struct in 'FAT32Struct.pas',
  FAT32 in 'FAT32.pas',
  ID3Struct in 'ID3Struct.pas',
  ID3 in 'ID3.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
